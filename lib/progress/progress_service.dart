import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'user_progress.dart';
import 'progress_events.dart';

class ProgressService {
  ProgressService._();

  static final ProgressService instance = ProgressService._();

  static const _kXp = 'progress_xp';
  static const _kLevel = 'progress_level';
  static const _kCurrentLevelXp = 'progress_current_level_xp';
  static const _kXpToNextLevel = 'progress_xp_to_next_level';
  static const _kStreak = 'progress_streak';
  static const _kLastActiveDate = 'progress_last_active_date';
  static const _kLastLoginDate = 'progress_last_login_date';
  static const _kXpSystemVersion = 'progress_xp_system_version';

  final ValueNotifier<UserProgress> progress = ValueNotifier(UserProgress.initial());
  
  final StreamController<ProgressEvent> _eventController = StreamController<ProgressEvent>.broadcast();
  Stream<ProgressEvent> get events => _eventController.stream;
  Future<void> _xpQueue = Future<void>.value();

  static const int _kCurrentXpSystemVersion = 2;
  static const int _kMaxLevel = 10;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getInt(_kXpSystemVersion) ?? 1;
    if (storedVersion < _kCurrentXpSystemVersion) {
      // Keep existing XP on APK upgrade — cloud/local merge uses max(); zeroing here
      // caused progress loss when cloud pull happened after this reset.
      await prefs.setInt(_kXpSystemVersion, _kCurrentXpSystemVersion);
    }
    final xp = prefs.getInt(_kXp) ?? 0;
    final derived = _deriveFromXp(xp);
    progress.value = derived.copyWith(
      xp: prefs.getInt(_kXp) ?? 0,
      streak: prefs.getInt(_kStreak) ?? 0,
      lastActiveDate: _readDate(prefs, _kLastActiveDate),
      lastLoginDate: _readDate(prefs, _kLastLoginDate),
    );
    final normalized = _normalizeStreak(progress.value, DateTime.now());
    if (_isProgressChanged(progress.value, normalized)) {
      progress.value = normalized;
      await _persist(prefs, normalized);
    }
  }

  Future<void> onAppOpened() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final normalized = _normalizeStreak(progress.value, now);
    if (_isProgressChanged(progress.value, normalized)) {
      progress.value = normalized;
      await _persist(prefs, normalized);
    }
    final lastLogin = _readDate(prefs, _kLastLoginDate);
    if (lastLogin == null) {
      // First app open: record date only — new accounts must start at 0 XP.
      await _writeDate(prefs, _kLastLoginDate, now);
    } else if (!UserProgress.isSameDay(lastLogin, now)) {
      await _writeDate(prefs, _kLastLoginDate, now);
      // Returning user, new calendar day: +5 XP (doesn't affect streak by itself).
      await addXP(5, countForStreak: false);
    }
  }

  Future<void> addXP(int amount, {bool countForStreak = true}) async {
    final op = _xpQueue.then((_) => _addXpInternal(amount, countForStreak: countForStreak));
    _xpQueue = op.catchError((_) {});
    return op;
  }

  Future<void> _addXpInternal(int amount, {required bool countForStreak}) async {
    if (amount <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    var p = progress.value;

    if (countForStreak) {
      p = _applyStreak(p, now);
    }

    final xp = p.xp + amount;
    final derived = _deriveFromXp(xp);
    
    final levelIncreased = derived.level > p.level;
    
    p = derived.copyWith(
      xp: xp,
      streak: p.streak,
      lastActiveDate: countForStreak ? now : p.lastActiveDate,
      lastLoginDate: p.lastLoginDate,
    );

    progress.value = p;
    await _persist(prefs, p);

    _eventController.add(XpGained(amount));
    if (levelIncreased) {
      _eventController.add(LevelUp(p.level));
    }
  }

  void emitQuestCompleted(QuestCompletedEvent event) {
    _eventController.add(event);
  }

  Future<int> awardMemorization({required int memorizedCount}) async {
    final n = max(0, memorizedCount);
    final amount = n;
    await addXP(amount, countForStreak: true);
    return amount;
  }

  Future<void> awardDailyTaskCompleted() async {
    await addXP(1, countForStreak: true);
  }

  Map<String, dynamic> toCloudJson() {
    final p = progress.value;
    return <String, dynamic>{
      'xp': p.xp,
      'level': p.level,
      'currentLevelXp': p.currentLevelXp,
      'xpToNextLevel': p.xpToNextLevel,
      'streak': p.streak,
      'lastActiveDate': p.lastActiveDate?.toIso8601String(),
      'lastLoginDate': p.lastLoginDate?.toIso8601String(),
    };
  }

  Future<void> applyCloudJson(Map<String, dynamic> raw) async {
    final prefs = await SharedPreferences.getInstance();
    final local = progress.value;

    final cloudXp = (raw['xp'] as num?)?.toInt() ?? 0;
    final xp = max(local.xp, cloudXp);
    final derived = _deriveFromXp(xp);

    final cloudLastActive = _parseDate(raw['lastActiveDate']);
    final cloudLastLogin = _parseDate(raw['lastLoginDate']);
    final cloudStreak = (raw['streak'] as num?)?.toInt() ?? 0;
    final lastActiveDate = _latestDate(local.lastActiveDate, cloudLastActive);
    final lastLoginDate = _latestDate(local.lastLoginDate, cloudLastLogin);
    final streak = _mergeStreakValue(
      localStreak: local.streak,
      localLastActive: local.lastActiveDate,
      cloudStreak: cloudStreak,
      cloudLastActive: cloudLastActive,
    );

    final merged = derived.copyWith(
      xp: xp,
      streak: streak,
      lastActiveDate: lastActiveDate,
      lastLoginDate: lastLoginDate,
    );
    final p = _normalizeStreak(merged, DateTime.now());
    progress.value = p;
    await _persist(prefs, p);
  }

  static DateTime? _latestDate(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  Future<void> resetLocalProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final initial = UserProgress.initial();
    progress.value = initial;
    await _persist(prefs, initial);
    await prefs.setInt(_kXpSystemVersion, _kCurrentXpSystemVersion);
  }

  String getLevelTitleLabel() {
    final l = progress.value.level;
    switch (l) {
      case 1:
        return 'Slow Mind';
      case 2:
        return 'Thinking';
      case 3:
        return 'Remembering';
      case 4:
        return 'Linking';
      case 5:
        return 'Fast Recall';
      case 6:
        return 'Sharp Mind';
      case 7:
        return 'Rapid Memory';
      case 8:
        return 'Flash Recall';
      case 9:
        return 'Instant Recall';
      default:
        return 'Perfect Memory';
    }
  }

  UserProgress _deriveFromXp(int xp) {
    final x = max(0, xp);
    final thresholds = <int>[0, 50, 150, 300, 600, 1000, 1600, 2500, 4000, 6500, 10000];

    int level = _kMaxLevel;
    for (int i = 0; i < thresholds.length - 1; i++) {
      if (x < thresholds[i + 1]) {
        level = i + 1;
        break;
      }
    }

    final isMax = level >= _kMaxLevel || x >= thresholds.last;
    final levelStartXp = thresholds[level - 1];
    final nextLevelXp = isMax ? 0 : thresholds[level] - levelStartXp;
    final currentLevelXp = isMax ? 0 : (x - levelStartXp).clamp(0, nextLevelXp);
    final xpToNextLevel = nextLevelXp;

    return UserProgress(
      xp: x,
      level: level,
      currentLevelXp: currentLevelXp,
      xpToNextLevel: xpToNextLevel,
      streak: 0,
      lastActiveDate: null,
      lastLoginDate: null,
    );
  }

  UserProgress _applyStreak(UserProgress p, DateTime now) {
    final last = p.lastActiveDate;
    final today = DateTime(now.year, now.month, now.day);

    if (last == null) {
      return p.copyWith(streak: 1, lastActiveDate: now);
    }

    if (UserProgress.isSameDay(last, now)) {
      return p.copyWith(lastActiveDate: now);
    }

    final lastDay = DateTime(last.year, last.month, last.day);
    final diffDays = today.difference(lastDay).inDays;
    if (diffDays == 1) {
      return p.copyWith(streak: p.streak + 1, lastActiveDate: now);
    }

    // Missed day(s)
    return p.copyWith(streak: 1, lastActiveDate: now);
  }

  /// Keeps streak only while the user trained today or yesterday (calendar days).
  UserProgress _normalizeStreak(UserProgress p, DateTime now) {
    if (p.streak <= 0) return p.streak == 0 ? p : p.copyWith(streak: 0);

    final last = p.lastActiveDate;
    if (last == null) return p.copyWith(streak: 0);

    final today = _dateOnly(now);
    final lastDay = _dateOnly(last);
    final diffDays = today.difference(lastDay).inDays;
    if (diffDays <= 1) return p;

    return p.copyWith(streak: 0);
  }

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static int _mergeStreakValue({
    required int localStreak,
    required DateTime? localLastActive,
    required int cloudStreak,
    required DateTime? cloudLastActive,
  }) {
    if (localLastActive == null && cloudLastActive == null) {
      return max(localStreak, cloudStreak);
    }
    if (localLastActive == null) return cloudStreak;
    if (cloudLastActive == null) return localStreak;

    final localDay = _dateOnly(localLastActive);
    final cloudDay = _dateOnly(cloudLastActive);
    if (localDay.isAfter(cloudDay)) return localStreak;
    if (cloudDay.isAfter(localDay)) return cloudStreak;
    return max(localStreak, cloudStreak);
  }

  bool _isProgressChanged(UserProgress a, UserProgress b) {
    final sameLastActive = (a.lastActiveDate == null && b.lastActiveDate == null) ||
        (a.lastActiveDate != null && b.lastActiveDate != null && a.lastActiveDate!.isAtSameMomentAs(b.lastActiveDate!));
    final sameLastLogin = (a.lastLoginDate == null && b.lastLoginDate == null) ||
        (a.lastLoginDate != null && b.lastLoginDate != null && a.lastLoginDate!.isAtSameMomentAs(b.lastLoginDate!));
    return a.xp != b.xp ||
        a.level != b.level ||
        a.currentLevelXp != b.currentLevelXp ||
        a.xpToNextLevel != b.xpToNextLevel ||
        a.streak != b.streak ||
        !sameLastActive ||
        !sameLastLogin;
  }

  Future<void> _persist(SharedPreferences prefs, UserProgress p) async {
    await prefs.setInt(_kXp, p.xp);
    await prefs.setInt(_kLevel, p.level);
    await prefs.setInt(_kCurrentLevelXp, p.currentLevelXp);
    await prefs.setInt(_kXpToNextLevel, p.xpToNextLevel);
    await prefs.setInt(_kStreak, p.streak);
    await _writeDate(prefs, _kLastActiveDate, p.lastActiveDate);
    await _writeDate(prefs, _kLastLoginDate, p.lastLoginDate);
  }

  static DateTime? _readDate(SharedPreferences prefs, String key) {
    final s = prefs.getString(key);
    if (s == null || s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _writeDate(SharedPreferences prefs, String key, DateTime? date) async {
    if (date == null) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, date.toIso8601String());
  }
}

