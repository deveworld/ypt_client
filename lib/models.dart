import 'package:flutter/material.dart';

/// YPT API 응답 모델. 키 해독은 RE 스펙(key_dictionary) 기반.
/// 응답은 축약 키를 쓴다: s=success, jwt=토큰, ss=과목배열, dl=오늘로그, p=프로필.

int intValue(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? intOrNull(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String stringValue(Object? value) => value?.toString() ?? '';

String? firstStringValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null) return stringValue(value);
  }
  return null;
}

int firstIntValue(Map<String, dynamic> json, List<String> keys,
    {int fallback = 0}) {
  for (final key in keys) {
    final value = intOrNull(json[key]);
    if (value != null) return value;
  }
  return fallback;
}

bool boolValue(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
  }
  return fallback;
}

List<Map<String, dynamic>> mapListValue(Object? value) {
  final list = value is List ? value : const [];
  return list.whereType<Map<String, dynamic>>().toList();
}

SubjectTimeSnapshot subjectTimeSnapshotFromJson(
  Map<String, dynamic> json, {
  Map<int, String> titleByIndex = const {},
}) {
  final byId = <int, int>{};
  final byTitle = <String, int>{};

  void addEntries(Object? value) {
    for (final entry in mapListValue(value)) {
      final studyMs = _studyMsFromLog(entry);
      if (studyMs <= 0) continue;
      final id = _subjectIdFromLog(entry);
      final title = _subjectTitleFromLog(entry, titleByIndex);
      if (id != null && id > 0) byId[id] = (byId[id] ?? 0) + studyMs;
      if (title != null && title.trim().isNotEmpty) {
        byTitle[title] = (byTitle[title] ?? 0) + studyMs;
      }
    }
  }

  addEntries(json['ls']);
  addEntries(json['ss']);
  addEntries(json['ts']);
  return SubjectTimeSnapshot(byId: byId, byTitle: byTitle);
}

int? _subjectIdFromLog(Map<String, dynamic> json) {
  final direct = intOrNull(json['si']) ??
      intOrNull(json['sid']) ??
      intOrNull(json['subjectId']) ??
      intOrNull(json['subjectID']) ??
      intOrNull(json['id']);
  if (direct != null) return direct;
  final sb = json['sb'];
  return sb is String ? null : intOrNull(sb);
}

String? _subjectTitleFromLog(
  Map<String, dynamic> json,
  Map<int, String> titleByIndex,
) {
  final direct = firstStringValue(json, const [
    'subject',
    'subjectName',
    'subjectTitle',
    'title',
    'tt',
    't',
  ]);
  if (direct != null && direct.trim().isNotEmpty) return direct;
  final sb = json['sb'];
  if (sb is String && sb.trim().isNotEmpty) return sb;
  final index = intOrNull(json['sbi']) ??
      intOrNull(json['subjectIndex']) ??
      intOrNull(json['subjectBookIndex']) ??
      intOrNull(sb);
  if (index != null) return titleByIndex[index];
  return null;
}

int _studyMsFromLog(Map<String, dynamic> json) {
  final direct = firstIntValue(json, const [
    'sm',
    'studyMs',
    'studyMS',
    'studyTime',
    'todayStudyMs',
    'todayStudyMS',
    'todayStudyTime',
    'todayMs',
    'durationMs',
    'duration',
    'ms',
    'sd',
  ]);
  if (direct > 0) return direct;

  final start = firstIntValue(json, const [
    'startedAt',
    'startAt',
    'start',
    'st',
    'from',
  ]);
  final end = firstIntValue(json, const [
    'endedAt',
    'endAt',
    'end',
    'et',
    'to',
  ]);
  final elapsed = end - start;
  if (start > 0 && elapsed > 0 && elapsed <= 24 * 60 * 60 * 1000) {
    return elapsed;
  }
  return 0;
}

class Subject {
  final int id;
  final String title; // tt
  final int studyMs; // sm — 오늘 이 과목 공부 ms
  final int order; // or
  final int colorValue; // co — ARGB int
  final bool archived; // dl(이 문맥) — 보관 여부 추정

  Subject({
    required this.id,
    required this.title,
    required this.studyMs,
    required this.order,
    required this.colorValue,
    required this.archived,
  });

  factory Subject.fromJson(Map<String, dynamic> j) => Subject(
        id: firstIntValue(j, const [
          'id',
          'sid',
          'subjectId',
          'subjectID',
          'si',
        ]),
        title: firstStringValue(j, const [
              'tt',
              't',
              'title',
              'subject',
              'subjectName',
              'subjectTitle',
            ]) ??
            '',
        studyMs: firstIntValue(j, const [
          'sm',
          'studyMs',
          'studyMS',
          'studyTime',
          'todayStudyMs',
          'todayStudyMS',
          'todayStudyTime',
          'todayMs',
          'totalStudyMs',
          'ms',
        ]),
        order: intValue(j['or']),
        colorValue: firstIntValue(j, const ['co', 'c'], fallback: 0xFF888888),
        archived: boolValue(j['dl']),
      );

  Color get color => Color(colorValue == 0 ? 0xFF888888 : colorValue);
}

class DayLog {
  final int studyMs; // sm
  final int restMs; // rm
  final int maxStudyMs; // mm
  final int addedMs; // ad
  final String date; // dt
  final SubjectTimeSnapshot subjectTimes;

  DayLog({
    required this.studyMs,
    required this.restMs,
    required this.maxStudyMs,
    required this.addedMs,
    required this.date,
    required this.subjectTimes,
  });

  factory DayLog.fromJson(Map<String, dynamic> j) => DayLog(
        studyMs: intValue(j['sm']),
        restMs: intValue(j['rm']),
        maxStudyMs: intValue(j['mm']),
        addedMs: intValue(j['ad']),
        date: stringValue(j['dt']),
        subjectTimes: subjectTimeSnapshotFromJson(j),
      );
}

class SubjectTimeSnapshot {
  final Map<int, int> byId;
  final Map<String, int> byTitle;

  const SubjectTimeSnapshot({
    this.byId = const {},
    this.byTitle = const {},
  });
}

/// 로그인/리로드 응답 묶음 (sign-in-jwt, reload/info 공통 구조)
class UserData {
  final String? jwt; // jwt (로그인 시에만)
  final String nickname; // n
  final String category; // ct (예: HS11)
  final String? email; // e
  final List<Subject> subjects; // ss
  final DayLog? dayLog; // dl
  final int categoryId; // ci
  final int countryId; // coid

  UserData({
    this.jwt,
    required this.nickname,
    required this.category,
    this.email,
    required this.subjects,
    this.dayLog,
    this.categoryId = 0,
    this.countryId = 0,
  });

  factory UserData.fromJson(Map<String, dynamic> j) {
    final ssList = j['ss'] is List ? j['ss'] as List : const [];
    final subjects = ssList
        .whereType<Map<String, dynamic>>()
        .map(Subject.fromJson)
        .where((s) => !s.archived)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    DayLog? dl;
    if (j['dl'] is Map<String, dynamic>) dl = DayLog.fromJson(j['dl']);
    return UserData(
      jwt: j['jwt'] == null ? null : stringValue(j['jwt']),
      nickname: stringValue(j['n']),
      category: stringValue(j['ct']),
      email: j['e'] == null ? null : stringValue(j['e']),
      subjects: subjects,
      dayLog: dl,
      categoryId: intValue(j['ci']),
      countryId: intValue(j['coid']),
    );
  }
}

/// 카테고리 랭킹 멤버 (/logs/category/member/ranks 의 ms 항목)
class RankMember {
  final String nickname; // n
  final int userId; // ud
  final int studyMs; // dl.sm
  final int studiconId; // si

  RankMember({
    required this.nickname,
    required this.userId,
    required this.studyMs,
    required this.studiconId,
  });

  factory RankMember.fromJson(Map<String, dynamic> j) {
    int sm = 0;
    if (j['dl'] is Map<String, dynamic>) sm = intValue(j['dl']['sm']);
    return RankMember(
      nickname: stringValue(j['n']),
      userId: intValue(j['ud']),
      studyMs: sm,
      studiconId: intValue(j['si']),
    );
  }
}

/// 스터디 그룹 (/group/list-new-2, /group/groups/v2 의 gs 항목)
class Group {
  final int id; // gd (groupID)
  final String title; // t
  final String category; // c
  final String owner; // on (방장 닉네임)
  final String slogan; // sn
  final int memberCount; // mc

  Group({
    required this.id,
    required this.title,
    required this.category,
    required this.owner,
    required this.slogan,
    required this.memberCount,
  });

  factory Group.fromJson(Map<String, dynamic> j) => Group(
        id: intValue(j['id'] ?? j['gd']), // groupID = id (멤버 API가 쓰는 값)
        title: stringValue(j['t']),
        category: stringValue(j['c']),
        owner: stringValue(j['on']),
        slogan: stringValue(j['sn']),
        memberCount: intValue(j['mc']),
      );
}

/// 그룹 멤버 (/logs/group/members/v2 의 ms 항목)
class GroupMember {
  final int userId; // ud
  final String nickname; // n
  final String category; // ct
  final int studyMs; // dl.sm — 오늘 공부시간
  final bool studying; // im

  GroupMember({
    required this.userId,
    required this.nickname,
    required this.category,
    required this.studyMs,
    required this.studying,
  });

  factory GroupMember.fromJson(Map<String, dynamic> j) {
    int sm = 0;
    if (j['dl'] is Map<String, dynamic>) sm = intValue(j['dl']['sm']);
    return GroupMember(
      userId: intValue(j['ud']),
      nickname: stringValue(j['n']),
      category: stringValue(j['ct']),
      studyMs: sm,
      studying: boolValue(j['im']),
    );
  }
}

/// 로그인 결과
sealed class SignInResult {}

class SignInOk extends SignInResult {
  final UserData data;
  SignInOk(this.data);
}

class SignInError extends SignInResult {
  final String code; // c — 113=계정/비번오류 등
  SignInError(this.code);
}
