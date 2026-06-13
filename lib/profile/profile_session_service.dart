import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../public_stats_scoring.dart';
import '../training_record_rules.dart';

class ProfileSessionEntry {
  final String mode;
  final int totalItems;
  final int correctItems;
  final int timeSeconds;
  final DateTime date;

  /// Memorization (encoding) time in milliseconds. 0 if not recorded.
  final int encodingMs;

  /// Recall time in milliseconds. 0 if not recorded.
  final int recallMs;

  /// Per-item correctness pattern (0 / 1), length == totalItems when present.
  /// Empty when older sessions or not tracked.
  final List<int> correctnessPattern;

  /// Digits / bits / items used for record comparison (0 = derive from mode).
  final int recordScore;

  const ProfileSessionEntry({
    required this.mode,
    required this.totalItems,
    required this.correctItems,
    required this.timeSeconds,
    required this.date,
    this.encodingMs = 0,
    this.recallMs = 0,
    this.correctnessPattern = const <int>[],
    this.recordScore = 0,
  });

  double get accuracy => totalItems <= 0 ? 0 : correctItems / totalItems;
  double get speed => correctItems <= 0 ? 9999 : timeSeconds / correctItems;

  /// Legacy efficiency metric (items×accuracy/time). Not used for "best result".
  double get score {
    if (timeSeconds <= 0 || totalItems <= 0 || correctItems <= 0) return 0;
    return (correctItems * accuracy) / timeSeconds;
  }

  int get effectiveRecordScore => recordScore > 0
      ? recordScore
      : PublicStatsScoring.scoreFromItems(
          mode: mode,
          correctItems: correctItems,
        );

  SessionRecord toSessionRecord() => SessionRecord(
        displayScore: effectiveRecordScore,
        memMs: encodingMs,
        totalItems: totalItems,
        correctItems: correctItems,
        accuracyPct: accuracy * 100.0,
      );

  /// efficiency = accuracy / speed.
  /// Higher value means better efficiency.
  double get efficiency {
    if (speed <= 0 || speed > 9000) return 0;
    return accuracy / speed;
  }

  double get encodingSpeed {
    if (totalItems <= 0 || encodingMs <= 0) return 0;
    return (encodingMs / 1000.0) / totalItems;
  }

  double get recallSpeed {
    if (totalItems <= 0 || recallMs <= 0) return 0;
    return (recallMs / 1000.0) / totalItems;
  }

  bool get hasPattern =>
      correctnessPattern.length == totalItems && totalItems > 0;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'mode': mode,
        'total_items': totalItems,
        'correct_items': correctItems,
        'time_seconds': timeSeconds,
        'score': score,
        if (recordScore > 0) 'record_score': recordScore,
        'date': date.toIso8601String(),
        if (encodingMs > 0) 'encoding_ms': encodingMs,
        if (recallMs > 0) 'recall_ms': recallMs,
        if (correctnessPattern.isNotEmpty) 'pattern': correctnessPattern,
      };

  static ProfileSessionEntry fromJson(Map<String, dynamic> raw) {
    final pattern = <int>[];
    final rawPattern = raw['pattern'];
    if (rawPattern is List) {
      for (final v in rawPattern) {
        if (v is num) pattern.add(v.toInt() == 0 ? 0 : 1);
      }
    }
    return ProfileSessionEntry(
      mode: (raw['mode'] ?? '').toString(),
      totalItems: (raw['total_items'] as num?)?.toInt() ?? 0,
      correctItems: (raw['correct_items'] as num?)?.toInt() ?? 0,
      timeSeconds: max(1, (raw['time_seconds'] as num?)?.toInt() ?? 1),
      date: DateTime.tryParse((raw['date'] ?? '').toString()) ?? DateTime.now(),
      encodingMs: TrainingRecordRules.normalizeTimedWindowMemMs(
        max(0, (raw['encoding_ms'] as num?)?.toInt() ?? 0),
      ),
      recallMs: max(0, (raw['recall_ms'] as num?)?.toInt() ?? 0),
      correctnessPattern: pattern,
      recordScore: max(0, (raw['record_score'] as num?)?.toInt() ?? 0),
    );
  }
}

class ModeProfileSummary {
  final String mode;
  final int bestCorrectItems;
  final int bestRecordScore;
  final double bestAccuracy;
  final double bestSpeed;
  final double bestScore;
  final int bestTime;
  final int totalSessions;
  final List<ProfileSessionEntry> sessions;
  final int bestSessionIndex;

  const ModeProfileSummary({
    required this.mode,
    required this.bestCorrectItems,
    required this.bestRecordScore,
    required this.bestAccuracy,
    required this.bestSpeed,
    required this.bestScore,
    required this.bestTime,
    required this.totalSessions,
    required this.sessions,
    required this.bestSessionIndex,
  });
}

class ProfileSessionService {
  ProfileSessionService._();
  static final ProfileSessionService instance = ProfileSessionService._();

  static const String _kSessions = 'profile_sessions_v1';
  static const int _kMaxSessions = 800;

  Future<void> recordSession({
    required String mode,
    required int totalItems,
    required int correctItems,
    required int timeSeconds,
    DateTime? date,
    int encodingMs = 0,
    int recallMs = 0,
    List<int> correctnessPattern = const <int>[],
    int recordScore = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await loadSessions();
    sessions.insert(
      0,
      ProfileSessionEntry(
        mode: mode,
        totalItems: max(1, totalItems),
        correctItems: max(0, correctItems),
        timeSeconds: max(1, timeSeconds),
        date: date ?? DateTime.now(),
        encodingMs: max(0, encodingMs),
        recallMs: max(0, recallMs),
        correctnessPattern: correctnessPattern.length == max(1, totalItems)
            ? List<int>.unmodifiable(
                correctnessPattern.map((v) => v == 0 ? 0 : 1))
            : const <int>[],
        recordScore: recordScore > 0
            ? recordScore
            : PublicStatsScoring.scoreFromItems(
                mode: mode,
                correctItems: max(0, correctItems),
              ),
      ),
    );
    if (sessions.length > _kMaxSessions) {
      sessions.removeRange(_kMaxSessions, sessions.length);
    }
    final encoded =
        sessions.map((e) => jsonEncode(e.toJson())).toList(growable: false);
    await prefs.setStringList(_kSessions, encoded);
  }

  Future<List<ProfileSessionEntry>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kSessions) ?? const <String>[];
    final out = <ProfileSessionEntry>[];
    var needsRewrite = false;
    for (final item in raw) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        final oldEncodingMs =
            max(0, (map['encoding_ms'] as num?)?.toInt() ?? 0);
        final normalizedEncodingMs =
            TrainingRecordRules.normalizeTimedWindowMemMs(oldEncodingMs);
        if (oldEncodingMs != normalizedEncodingMs) {
          map['encoding_ms'] = normalizedEncodingMs;
          needsRewrite = true;
        }
        out.add(ProfileSessionEntry.fromJson(map));
      } catch (_) {}
    }
    if (needsRewrite) {
      final encoded = out
          .take(_kMaxSessions)
          .map((e) => jsonEncode(e.toJson()))
          .toList(growable: false);
      await prefs.setStringList(_kSessions, encoded);
    }
    return out;
  }

  Future<Map<String, dynamic>> toCloudJson() async {
    final sessions = await loadSessions();
    return <String, dynamic>{
      'sessions': sessions
          .take(_kMaxSessions)
          .map((e) => e.toJson())
          .toList(growable: false),
    };
  }

  Future<void> applyCloudJson(Map<String, dynamic> raw) async {
    final rawSessions = raw['sessions'];
    if (rawSessions is! List) return;

    final cloudSessions = <ProfileSessionEntry>[];
    for (final item in rawSessions) {
      try {
        if (item is Map<String, dynamic>) {
          cloudSessions.add(ProfileSessionEntry.fromJson(item));
        } else if (item is Map) {
          cloudSessions.add(
              ProfileSessionEntry.fromJson(Map<String, dynamic>.from(item)));
        }
      } catch (_) {}
    }

    if (cloudSessions.isEmpty) return;

    final merged = <String, ProfileSessionEntry>{};
    for (final session in await loadSessions()) {
      final key = _sessionKey(session);
      merged[key] = session;
    }
    for (final session in cloudSessions) {
      final key = _sessionKey(session);
      final existing = merged[key];
      merged[key] =
          existing == null ? session : _preferRicherSession(existing, session);
    }
    final union = merged.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final prefs = await SharedPreferences.getInstance();
    final encoded = union
        .take(_kMaxSessions)
        .map((e) => jsonEncode(e.toJson()))
        .toList(growable: false);
    await prefs.setStringList(_kSessions, encoded);
  }

  Future<void> removeAllLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSessions);
  }

  /// Drops the profile session row created together with this training history entry.
  Future<void> removeSessionMatchingTrainingHistory({
    required String mode,
    required DateTime date,
    required int totalItems,
    required int correctItems,
    required int memorizationMs,
    required int recallMs,
  }) async {
    final sessions = await loadSessions();
    final before = sessions.length;
    final targetMs = date.millisecondsSinceEpoch;
    sessions.removeWhere((s) {
      if (s.mode != mode) return false;
      if (s.totalItems != totalItems || s.correctItems != correctItems) {
        return false;
      }
      if (s.encodingMs != memorizationMs || s.recallMs != recallMs) {
        return false;
      }
      return (s.date.millisecondsSinceEpoch - targetMs).abs() <= 1500;
    });
    if (sessions.length == before) return;
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        sessions.map((e) => jsonEncode(e.toJson())).toList(growable: false);
    await prefs.setStringList(_kSessions, encoded);
  }

  ProfileSessionEntry _preferRicherSession(
    ProfileSessionEntry a,
    ProfileSessionEntry b,
  ) {
    if (a.hasPattern && !b.hasPattern) return a;
    if (!a.hasPattern && b.hasPattern) return b;
    final aDetail = a.encodingMs + a.recallMs + a.correctnessPattern.length;
    final bDetail = b.encodingMs + b.recallMs + b.correctnessPattern.length;
    if (aDetail != bDetail) return aDetail > bDetail ? a : b;
    return a.date.isAfter(b.date) ? a : b;
  }

  String _sessionKey(ProfileSessionEntry session) {
    return [
      session.mode,
      session.date.toIso8601String(),
      session.totalItems,
      session.correctItems,
      session.timeSeconds,
      session.encodingMs,
      session.recallMs,
    ].join('|');
  }

  Future<Map<String, ModeProfileSummary>> buildModeSummaries() async {
    final all = await loadSessions();
    const modes = ['standard', 'binary', 'words', 'images', 'cards', 'faces'];
    final byMode = <String, List<ProfileSessionEntry>>{
      for (final m in modes) m: <ProfileSessionEntry>[],
    };
    for (final s in all) {
      if (byMode.containsKey(s.mode)) byMode[s.mode]!.add(s);
    }

    final result = <String, ModeProfileSummary>{};
    for (final mode in modes) {
      final sessions = byMode[mode] ?? const <ProfileSessionEntry>[];
      if (sessions.isEmpty) {
        result[mode] = ModeProfileSummary(
          mode: mode,
          bestCorrectItems: 0,
          bestRecordScore: 0,
          bestAccuracy: 0,
          bestSpeed: 0,
          bestScore: 0,
          bestTime: 0,
          totalSessions: 0,
          sessions: const [],
          bestSessionIndex: -1,
        );
        continue;
      }
      final records =
          sessions.map((s) => s.toSessionRecord()).toList(growable: false);
      final picked = PublicStatsScoring.pickBestSessionIndex(records);
      if (picked < 0) {
        result[mode] = ModeProfileSummary(
          mode: mode,
          bestCorrectItems: 0,
          bestRecordScore: 0,
          bestAccuracy: 0,
          bestSpeed: 0,
          bestScore: 0,
          bestTime: 0,
          totalSessions: sessions.length,
          sessions: sessions,
          bestSessionIndex: -1,
        );
        continue;
      }
      final best = sessions[picked];
      result[mode] = ModeProfileSummary(
        mode: mode,
        bestCorrectItems: best.correctItems,
        bestRecordScore: records[picked].displayScore,
        bestAccuracy: best.accuracy,
        bestSpeed: best.speed,
        bestScore: best.score,
        bestTime: best.timeSeconds,
        totalSessions: sessions.length,
        sessions: sessions,
        bestSessionIndex: picked,
      );
    }
    return result;
  }
}
