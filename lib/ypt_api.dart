import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'models.dart';

/// YPT API 클라이언트. RE 스펙(YPT_API_SPEC_FINAL.md) 기반.
/// base=https://pi.tgclab.com, 인증=Authorization: JWT <token>.
class YptApi {
  static const String base = 'https://pi.tgclab.com';
  static const Duration requestTimeout = Duration(seconds: 15);

  static String get deviceModel {
    if (kIsWeb) return 'YPT Web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.linux => 'YPT Linux',
      TargetPlatform.macOS => 'YPT macOS',
      TargetPlatform.windows => 'YPT Windows',
      TargetPlatform.android => 'YPT Android',
      TargetPlatform.iOS => 'YPT iOS',
      TargetPlatform.fuchsia => 'YPT Client',
    };
  }

  final http.Client _client;
  String? jwt;

  YptApi({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers({bool auth = true}) => {
        'Content-Type': 'application/json',
        'Accept-Encoding': 'gzip',
        if (auth && jwt != null) 'authorization': 'JWT $jwt',
      };

  Uri _u(String path) => Uri.parse('$base$path');

  Future<http.Response> _get(String path) =>
      _client.get(_u(path), headers: _headers()).timeout(requestTimeout);

  Future<http.Response> _post(
    String path,
    Map<String, Object?> body, {
    bool auth = true,
  }) =>
      _client
          .post(_u(path), headers: _headers(auth: auth), body: jsonEncode(body))
          .timeout(requestTimeout);

  Map<String, dynamic> _decodeObject(http.Response r) {
    final decoded = jsonDecode(utf8.decode(r.bodyBytes));
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
    throw const FormatException('Expected a JSON object response.');
  }

  void _ensureOk(http.Response r, String endpoint) {
    if (r.statusCode != 200) {
      throw YptApiException('$endpoint HTTP ${r.statusCode}');
    }
  }

  void close() {
    _client.close();
  }

  /// POST /user/sign-in-jwt — 이메일 로그인. 성공 시 jwt 저장.
  Future<SignInResult> signIn(String email, String password) async {
    final r = await _post(
        '/user/sign-in-jwt',
        {
          'email': email,
          'password': password,
          'loginProvider': 'Email',
          'new': true,
          'getx': true,
          'language': 'en',
        },
        auth: false);
    if (r.statusCode != 200) return SignInError('http_${r.statusCode}');
    final j = _decodeObject(r);
    if (j['s'] == true) {
      final token = j['jwt']?.toString();
      if (token == null || token.isEmpty) return SignInError('missing_jwt');
      jwt = token;
      return SignInOk(UserData.fromJson(j));
    }
    return SignInError(j['c']?.toString() ?? 'unknown');
  }

  /// POST /user/v2/reload/info — 프로필/과목/오늘로그 갱신.
  /// 바디: {pv, cd:{su,sbu,cu,eu,du,tu 동기화 시각}}. 오래된 시각을 보내 전체 데이터 수신.
  Future<UserData> reloadInfo() async {
    const old = '2019-01-01T00:00:00+00:00';
    final r = await _post('/user/v2/reload/info', {
      'pv': 2,
      'cd': {'su': old, 'sbu': old, 'cu': old, 'eu': old, 'du': old, 'tu': old},
    });
    _ensureOk(r, 'reload/info');
    final j = _decodeObject(r);
    return UserData.fromJson(j);
  }

  /// GET /logs/my-category-rank — 내 카테고리 등수. 응답 {s, mr}.
  Future<int?> myCategoryRank(int categoryId, int countryId) async {
    final r = await _get(
        '/logs/my-category-rank?category_id=$categoryId&country_id=$countryId');
    _ensureOk(r, 'logs/my-category-rank');
    final j = _decodeObject(r);
    if (j['s'] == true) return intOrNull(j['mr']);
    return null;
  }

  /// GET /logs/category/member/ranks — 카테고리 랭킹 멤버 (type=day/week/month).
  /// 응답 {s, ms:[{n,sd,ud,si,...}], tc}. sd=공부ms, n=닉네임, si=studiconID.
  Future<List<RankMember>> categoryRanks(int categoryId, int countryId,
      {String type = 'day', int page = 1, required String date}) async {
    final r = await _get(
        '/logs/category/member/ranks?date=$date&categoryID=$categoryId&countryID=$countryId&page=$page&type=$type');
    _ensureOk(r, 'logs/category/member/ranks');
    final j = _decodeObject(r);
    final ms = j['ms'] is List ? j['ms'] as List : const [];
    return ms
        .whereType<Map<String, dynamic>>()
        .map(RankMember.fromJson)
        .toList();
  }

  /// GET /logs/day?date= — 오늘 과목별 공부시간 (dayLog.ls).
  /// API 버전에 따라 과목 식별자가 제목 또는 id 계열 키로 내려올 수 있다.
  Future<SubjectTimeSnapshot> dayLogSubjects(String date) async {
    final r = await _get('/logs/day?date=$date');
    _ensureOk(r, 'logs/day');
    final j = _decodeObject(r);
    final dl = j['dl'];
    final subjectBooks = mapListValue(j['sbs']);
    final titleByIndex = <int, String>{};
    for (var i = 0; i < subjectBooks.length; i++) {
      final title = firstStringValue(subjectBooks[i], const ['t', 'title']);
      if (title != null && title.trim().isNotEmpty) titleByIndex[i] = title;
    }

    final byId = <int, int>{};
    final byTitle = <String, int>{};

    void merge(SubjectTimeSnapshot snapshot) {
      for (final entry in snapshot.byId.entries) {
        byId[entry.key] = (byId[entry.key] ?? 0) + entry.value;
      }
      for (final entry in snapshot.byTitle.entries) {
        byTitle[entry.key] = (byTitle[entry.key] ?? 0) + entry.value;
      }
    }

    if (dl is Map<String, dynamic>) {
      merge(subjectTimeSnapshotFromJson(dl, titleByIndex: titleByIndex));
    }
    merge(subjectTimeSnapshotFromJson(j, titleByIndex: titleByIndex));

    return SubjectTimeSnapshot(byId: byId, byTitle: byTitle);
  }

  /// GET /group/list-new-2 — 둘러보기(신규) 그룹 목록. 응답 {s, gs:[...]}.
  Future<List<Group>> browseGroups(int countryId, {int page = 1}) async {
    final r = await _get(
        '/group/list-new-2?category_id=0&order_type=promotedAt&only_available=false&only_open=false&only_cam=false&page=$page&country_id=$countryId&p=true');
    _ensureOk(r, 'group/list-new-2');
    final j = _decodeObject(r);
    final gs = j['gs'] is List ? j['gs'] as List : const [];
    return gs.whereType<Map<String, dynamic>>().map(Group.fromJson).toList();
  }

  /// GET /group/groups/v2 — 내가 속한 그룹. 응답 {s, gs, ms, cs, ps} 4개 배열에 분산.
  Future<List<Group>> myGroups() async {
    final r = await _get('/group/groups/v2');
    _ensureOk(r, 'group/groups/v2');
    final j = _decodeObject(r);
    final out = <Group>[];
    final seen = <int>{};
    for (final key in ['gs', 'ms', 'cs', 'ps']) {
      final list = j[key] is List ? j[key] as List : const [];
      for (final item in list.whereType<Map<String, dynamic>>()) {
        final g = Group.fromJson(item);
        if (g.title.isNotEmpty && seen.add(g.id)) out.add(g);
      }
    }
    return out;
  }

  /// GET /logs/group/members/v2 — 그룹 멤버(공부 현황). 응답 {s, ms:[...]}.
  Future<List<GroupMember>> groupMembers(int groupId, int countryId) async {
    final r = await _get(
        '/logs/group/members/v2?groupID=$groupId&countryID=$countryId&isLooking=true&version=810046');
    _ensureOk(r, 'logs/group/members/v2');
    final j = _decodeObject(r);
    final ms = j['ms'] is List ? j['ms'] as List : const [];
    return ms
        .whereType<Map<String, dynamic>>()
        .map(GroupMember.fromJson)
        .toList();
  }

  /// POST /study/start — 타이머 시작. 응답에 dayLog 포함.
  Future<DayLog?> studyStart(String subject, {int? taskId}) async {
    final r = await _post('/study/start',
        {'subject': subject, 'deviceModel': deviceModel, 'taskId': taskId});
    _ensureOk(r, 'study/start');
    final j = _decodeObject(r);
    if (j['s'] == true && j['dl'] is Map<String, dynamic>) {
      return DayLog.fromJson(j['dl']);
    }
    throw YptApiException(j['c']?.toString() ?? 'study/start failed');
  }

  /// POST /study/stop — 타이머 정지. startedAt=시작 epoch(ms).
  Future<DayLog?> studyStop(int startedAtMs) async {
    final r = await _post(
        '/study/stop', {'startedAt': startedAtMs, 'deviceModel': deviceModel});
    _ensureOk(r, 'study/stop');
    final j = _decodeObject(r);
    if (j['s'] == true && j['dl'] is Map<String, dynamic>) {
      return DayLog.fromJson(j['dl']);
    }
    throw YptApiException(j['c']?.toString() ?? 'study/stop failed');
  }
}

class YptApiException implements Exception {
  final String message;
  const YptApiException(this.message);

  @override
  String toString() => message;
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
    case 'missing_jwt':
      return 'Sign in failed — the server did not return a session token.';
    default:
      if (code.startsWith('http_')) {
        return 'Request failed (HTTP ${code.substring(5)}).';
      }
      return 'Error (code: $code)';
  }
}
