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
  bool timerLoading = false;
  String? timerErrorText;

  // 과목별 오늘 공부시간 (title -> ms), /logs/day 의 dl.ls 에서
  Map<String, int> subjectTimes = {};

  Future<void> refreshSubjectTimes() async {
    subjectTimes = await api.dayLogSubjects(todayStr());
    notifyListeners();
  }

  // 통계 상태
  int? myRank;
  List<RankMember> ranks = [];
  bool statsLoading = false;
  String? statsErrorText;

  // 그룹 상태
  List<Group> groups = [];
  List<Group> joinedGroups = [];
  bool groupsLoading = false;
  String? groupsErrorText;

  Future<void> loadGroups() async {
    if (user == null) return;
    groupsLoading = true;
    groupsErrorText = null;
    notifyListeners();
    try {
      joinedGroups = await api.myGroups();
      groups = await api.browseGroups(user!.countryId);
    } catch (e) {
      groupsErrorText = 'Could not load groups: ${_readableError(e)}';
    }
    groupsLoading = false;
    notifyListeners();
  }

  Future<List<GroupMember>> fetchMembers(int groupId) =>
      api.groupMembers(groupId, user!.countryId);

  bool get loggedIn => user != null && api.jwt != null;
  bool get studying => activeSubject != null;

  static String todayStr() {
    final d = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  Future<void> loadStats() async {
    if (user == null) return;
    statsLoading = true;
    statsErrorText = null;
    notifyListeners();
    try {
      await refreshSubjectTimes();
      myRank = await api.myCategoryRank(user!.categoryId, user!.countryId);
      ranks = await api.categoryRanks(user!.categoryId, user!.countryId,
          date: todayStr(), type: 'day');
    } catch (e) {
      statsErrorText = 'Could not load stats: ${_readableError(e)}';
    }
    statsLoading = false;
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final sp = await SharedPreferences.getInstance();
    final t = sp.getString('jwt');
    if (t == null || t.isEmpty) return;
    api.jwt = t;
    loading = true;
    notifyListeners();
    try {
      user = await api.reloadInfo();
      await _refreshSubjectTimesQuietly(); // 과목별 오늘 시간
    } catch (_) {
      api.jwt = null; // 만료/오류
      user = null;
      await sp.remove('jwt');
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
          await sp.setString('jwt', data.jwt!);
          await _refreshSubjectTimesQuietly(); // 과목별 오늘 시간
          loading = false;
          notifyListeners();
          return true;
        case SignInError(:final code):
          errorText = errorMessage(code);
      }
    } catch (e) {
      errorText = 'Network error: ${_readableError(e)}';
    }
    loading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await stopTimer(silent: true);
    final sp = await SharedPreferences.getInstance();
    await sp.remove('jwt');
    api.jwt = null;
    user = null;
    subjectTimes = {};
    myRank = null;
    ranks = [];
    groups = [];
    joinedGroups = [];
    errorText = null;
    timerErrorText = null;
    statsErrorText = null;
    groupsErrorText = null;
    notifyListeners();
  }

  Future<void> startTimer(Subject s) async {
    if (timerLoading) return;
    if (studying) await stopTimer();
    if (studying) return;
    final startedAtMs = DateTime.now().millisecondsSinceEpoch;
    timerLoading = true;
    timerErrorText = null;
    notifyListeners();
    try {
      await api.studyStart(s.title, taskId: null);
      activeSubject = s;
      _startedAtMs = startedAtMs;
      _startTicker();
    } catch (e) {
      timerErrorText = 'Could not start timer: ${_readableError(e)}';
    }
    timerLoading = false;
    notifyListeners();
  }

  Future<void> stopTimer({bool silent = false}) async {
    if (timerLoading && !silent) return;
    final previousSubject = activeSubject;
    final started = _startedAtMs;
    if (previousSubject == null || started == null) {
      _clearTimer();
      return;
    }
    _clearTimer();
    if (silent) {
      notifyListeners();
      return;
    }
    timerLoading = true;
    timerErrorText = null;
    notifyListeners(); // 멈추는 즉시 UI 갱신 (네트워크 기다리지 않음)
    try {
      await api.studyStop(started);
      user = await api.reloadInfo(); // 오늘 총시간 갱신
      await _refreshSubjectTimesQuietly(); // 과목별 시간 갱신
    } catch (e) {
      activeSubject = previousSubject;
      _startedAtMs = started;
      _startTicker();
      timerErrorText = 'Could not stop timer: ${_readableError(e)}';
    }
    timerLoading = false;
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _syncElapsed();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _syncElapsed();
      notifyListeners();
    });
  }

  void _syncElapsed() {
    final started = _startedAtMs;
    if (started == null) {
      elapsed = Duration.zero;
      return;
    }
    final current = DateTime.now().millisecondsSinceEpoch - started;
    elapsed = Duration(milliseconds: current < 0 ? 0 : current);
  }

  void _clearTimer() {
    _ticker?.cancel();
    _ticker = null;
    activeSubject = null;
    _startedAtMs = null;
    elapsed = Duration.zero;
  }

  Future<void> _refreshSubjectTimesQuietly() async {
    try {
      await refreshSubjectTimes();
    } catch (_) {}
  }

  static String _readableError(Object e) {
    final text = e.toString();
    if (text.startsWith('TimeoutException')) return 'request timed out';
    if (text.startsWith('Exception: ')) return text.substring(11);
    return text;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    api.close();
    super.dispose();
  }
}
