import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ypt_api.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  final YptApi api = YptApi();
  UserData? user;
  bool loading = false;
  String? errorText;

  // 타이머 상태
  Subject? activeSubject;
  int? _startedAtMs;
  Timer? _ticker;
  Duration elapsed = Duration.zero;

  // 과목별 오늘 공부시간 (title -> ms), /logs/day 의 dl.ls 에서
  Map<String, int> subjectTimes = {};

  Future<void> refreshSubjectTimes() async {
    try {
      subjectTimes = await api.dayLogSubjects(_todayStr());
      notifyListeners();
    } catch (_) {}
  }

  // 통계 상태
  int? myRank;
  List<RankMember> ranks = [];
  bool statsLoading = false;

  // 그룹 상태
  List<Group> groups = [];
  List<Group> joinedGroups = [];
  bool groupsLoading = false;

  Future<void> loadGroups() async {
    if (user == null) return;
    groupsLoading = true;
    notifyListeners();
    try {
      joinedGroups = await api.myGroups();
      groups = await api.browseGroups(user!.countryId);
    } catch (_) {}
    groupsLoading = false;
    notifyListeners();
  }

  Future<List<GroupMember>> fetchMembers(int groupId) =>
      api.groupMembers(groupId, user!.countryId);

  bool get loggedIn => user != null && api.jwt != null;
  bool get studying => activeSubject != null;

  static String _todayStr() {
    final d = DateTime.now();
    return '${d.year}-${d.month}-${d.day}';
  }

  Future<void> loadStats() async {
    if (user == null) return;
    statsLoading = true;
    notifyListeners();
    try {
      myRank = await api.myCategoryRank(user!.categoryId, user!.countryId);
      ranks = await api.categoryRanks(user!.categoryId, user!.countryId,
          date: _todayStr(), type: 'day');
    } catch (_) {}
    statsLoading = false;
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final sp = await SharedPreferences.getInstance();
    final t = sp.getString('jwt');
    if (t == null) return;
    api.jwt = t;
    loading = true;
    notifyListeners();
    try {
      user = await api.reloadInfo();
      refreshSubjectTimes(); // 과목별 오늘 시간
    } catch (_) {
      api.jwt = null; // 만료/오류
    }
    loading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    loading = true;
    errorText = null;
    notifyListeners();
    try {
      final res = await api.signIn(email, password);
      switch (res) {
        case SignInOk(:final data):
          user = data;
          final sp = await SharedPreferences.getInstance();
          await sp.setString('jwt', data.jwt ?? '');
          refreshSubjectTimes(); // 과목별 오늘 시간
          loading = false;
          notifyListeners();
          return true;
        case SignInError(:final code):
          errorText = errorMessage(code);
      }
    } catch (e) {
      errorText = 'Network error: $e';
    }
    loading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    stopTimer(silent: true);
    final sp = await SharedPreferences.getInstance();
    await sp.remove('jwt');
    api.jwt = null;
    user = null;
    notifyListeners();
  }

  Future<void> startTimer(Subject s) async {
    if (studying) await stopTimer();
    activeSubject = s;
    _startedAtMs = DateTime.now().millisecondsSinceEpoch;
    elapsed = Duration.zero;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsed += const Duration(seconds: 1);
      notifyListeners();
    });
    notifyListeners();
    await api.studyStart(s.title, taskId: null);
  }

  Future<void> stopTimer({bool silent = false}) async {
    final started = _startedAtMs;
    _ticker?.cancel();
    _ticker = null;
    activeSubject = null;
    _startedAtMs = null;
    elapsed = Duration.zero;
    notifyListeners(); // 멈추는 즉시 UI 갱신 (네트워크 기다리지 않음)
    if (!silent && started != null) {
      final dl = await api.studyStop(started);
      if (dl != null) {
        user = await api.reloadInfo(); // 오늘 총시간 갱신
        notifyListeners();
        refreshSubjectTimes(); // 과목별 시간 갱신
      }
    }
  }
}
