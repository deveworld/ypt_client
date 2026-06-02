import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

/// YPT API 클라이언트. RE 스펙(YPT_API_SPEC_FINAL.md) 기반.
/// base=https://pi.tgclab.com, 인증=Authorization: JWT <token>.
class YptApi {
  static const String base = 'https://pi.tgclab.com';
  static const String deviceModel = 'YPT Desktop';

  String? jwt;

  Map<String, String> _headers({bool auth = true}) => {
        'Content-Type': 'application/json',
        'Accept-Encoding': 'gzip',
        if (auth && jwt != null) 'authorization': 'JWT $jwt',
      };

  Uri _u(String path) => Uri.parse('$base$path');

  /// POST /user/sign-in-jwt — 이메일 로그인. 성공 시 jwt 저장.
  Future<SignInResult> signIn(String email, String password) async {
    final r = await http.post(
      _u('/user/sign-in-jwt'),
      headers: _headers(auth: false),
      body: jsonEncode({
        'email': email,
        'password': password,
        'loginProvider': 'Email',
        'new': true,
        'getx': true,
        'language': 'en',
      }),
    );
    final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    if (j['s'] == true) {
      jwt = j['jwt'] as String?;
      return SignInOk(UserData.fromJson(j));
    }
    return SignInError(j['c']?.toString() ?? 'unknown');
  }

  /// POST /user/v2/reload/info — 프로필/과목/오늘로그 갱신.
  /// 바디: {pv, cd:{su,sbu,cu,eu,du,tu 동기화 시각}}. 오래된 시각을 보내 전체 데이터 수신.
  Future<UserData> reloadInfo() async {
    const old = '2019-01-01T00:00:00+00:00';
    final r = await http.post(
      _u('/user/v2/reload/info'),
      headers: _headers(),
      body: jsonEncode({
        'pv': 2,
        'cd': {'su': old, 'sbu': old, 'cu': old, 'eu': old, 'du': old, 'tu': old},
      }),
    );
    if (r.statusCode != 200) {
      throw Exception('reload/info HTTP ${r.statusCode}');
    }
    final text = utf8.decode(r.bodyBytes);
    final j = jsonDecode(text) as Map<String, dynamic>;
    return UserData.fromJson(j);
  }

  /// GET /logs/my-category-rank — 내 카테고리 등수. 응답 {s, mr}.
  Future<int?> myCategoryRank(int categoryId, int countryId) async {
    final r = await http.get(
        _u('/logs/my-category-rank?category_id=$categoryId&country_id=$countryId'),
        headers: _headers());
    if (r.statusCode != 200) return null;
    final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    if (j['s'] == true) return j['mr'] as int?;
    return null;
  }

  /// GET /logs/category/member/ranks — 카테고리 랭킹 멤버 (type=day/week/month).
  /// 응답 {s, ms:[{n,sd,ud,si,...}], tc}. sd=공부ms, n=닉네임, si=studiconID.
  Future<List<RankMember>> categoryRanks(int categoryId, int countryId,
      {String type = 'day', int page = 1, required String date}) async {
    final r = await http.get(
        _u('/logs/category/member/ranks?date=$date&categoryID=$categoryId&countryID=$countryId&page=$page&type=$type'),
        headers: _headers());
    if (r.statusCode != 200) return [];
    final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    final ms = (j['ms'] as List?) ?? const [];
    return ms.whereType<Map<String, dynamic>>().map(RankMember.fromJson).toList();
  }

  /// GET /logs/day?date= — 오늘 과목별 공부시간 (dayLog.ls). {sb:과목, sm:ms}.
  Future<Map<String, int>> dayLogSubjects(String date) async {
    final r = await http.get(_u('/logs/day?date=$date'), headers: _headers());
    if (r.statusCode != 200) return {};
    final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    final ls = (j['dl'] is Map<String, dynamic>)
        ? (j['dl']['ls'] as List?) ?? const []
        : const [];
    final out = <String, int>{};
    for (final e in ls.whereType<Map<String, dynamic>>()) {
      final sb = e['sb'] as String?;
      final sm = (e['sm'] ?? 0) as int;
      if (sb != null) out[sb] = (out[sb] ?? 0) + sm;
    }
    return out;
  }

  /// GET /group/list-new-2 — 둘러보기(신규) 그룹 목록. 응답 {s, gs:[...]}.
  Future<List<Group>> browseGroups(int countryId, {int page = 1}) async {
    final r = await http.get(
        _u('/group/list-new-2?category_id=0&order_type=promotedAt&only_available=false&only_open=false&only_cam=false&page=$page&country_id=$countryId&p=true'),
        headers: _headers());
    if (r.statusCode != 200) return [];
    final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    final gs = (j['gs'] as List?) ?? const [];
    return gs.whereType<Map<String, dynamic>>().map(Group.fromJson).toList();
  }

  /// GET /group/groups/v2 — 내가 속한 그룹. 응답 {s, gs, ms, cs, ps} 4개 배열에 분산.
  Future<List<Group>> myGroups() async {
    final r = await http.get(_u('/group/groups/v2'), headers: _headers());
    if (r.statusCode != 200) return [];
    final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    final out = <Group>[];
    final seen = <int>{};
    for (final key in ['gs', 'ms', 'cs', 'ps']) {
      final list = (j[key] as List?) ?? const [];
      for (final item in list.whereType<Map<String, dynamic>>()) {
        final g = Group.fromJson(item);
        if (g.title.isNotEmpty && seen.add(g.id)) out.add(g);
      }
    }
    return out;
  }

  /// GET /logs/group/members/v2 — 그룹 멤버(공부 현황). 응답 {s, ms:[...]}.
  Future<List<GroupMember>> groupMembers(int groupId, int countryId) async {
    final r = await http.get(
        _u('/logs/group/members/v2?groupID=$groupId&countryID=$countryId&isLooking=true&version=810046'),
        headers: _headers());
    if (r.statusCode != 200) return [];
    final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    final ms = (j['ms'] as List?) ?? const [];
    return ms.whereType<Map<String, dynamic>>().map(GroupMember.fromJson).toList();
  }

  /// POST /study/start — 타이머 시작. 응답에 dayLog 포함.
  Future<DayLog?> studyStart(String subject, {int? taskId}) async {
    final r = await http.post(_u('/study/start'),
        headers: _headers(),
        body: jsonEncode({'subject': subject, 'deviceModel': deviceModel, 'taskId': taskId}));
    final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    if (j['s'] == true && j['dl'] is Map<String, dynamic>) return DayLog.fromJson(j['dl']);
    return null;
  }

  /// POST /study/stop — 타이머 정지. startedAt=시작 epoch(ms).
  Future<DayLog?> studyStop(int startedAtMs) async {
    final r = await http.post(_u('/study/stop'),
        headers: _headers(),
        body: jsonEncode({'startedAt': startedAtMs, 'deviceModel': deviceModel}));
    final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    if (j['s'] == true && j['dl'] is Map<String, dynamic>) return DayLog.fromJson(j['dl']);
    return null;
  }
}

/// 로그인 에러코드 → 사람이 읽을 메시지 (RE 스펙 에러카탈로그)
String errorMessage(String code) {
  switch (code) {
    case '113':
      return 'Sign in failed — incorrect email or password.';
    case '112':
      return 'Authentication failed — check your account.';
    case '104':
      return 'Request rejected.';
    case 'alert_server_error_msg':
      return 'A server error occurred.';
    default:
      return 'Error (code: $code)';
  }
}
