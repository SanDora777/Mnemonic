import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'training_history_service.dart';
import 'training_record_rules.dart';

/// Converts per-session element counts into public leaderboard stats:
/// numbers → digits, binary triplets → bits (×3).
class PublicStatsScoring {
  static const List<String> modes = [
    'standard',
    'binary',
    'words',
    'images',
    'cards',
    'faces',
  ];

  static int scoreFromItems({
    required String mode,
    required int correctItems,
    List<String> data = const <String>[],
    List<String> answers = const <String>[],
  }) {
    switch (mode) {
      case 'standard':
        if (data.isNotEmpty) {
          var digits = 0;
          for (var i = 0; i < data.length; i++) {
            final expected = data[i];
            final digitCount = RegExp(r'\d').allMatches(expected).length;
            if (digitCount <= 0) continue;
            final answer = i < answers.length ? answers[i].trim() : '';
            if (answer.isNotEmpty &&
                answer.toLowerCase() == expected.toLowerCase()) {
              digits += digitCount;
            }
          }
          if (digits > 0 || correctItems == 0) return digits;
        }
        return correctItems;
      case 'binary':
        if (data.isNotEmpty) {
          var bits = 0;
          for (var i = 0; i < data.length; i++) {
            final expected = data[i];
            final answer = i < answers.length ? answers[i].trim() : '';
            if (answer.isNotEmpty && answer == expected) {
              bits += expected.length;
            }
          }
          if (bits > 0 || correctItems == 0) return bits;
        }
        return correctItems * 3;
      default:
        return correctItems;
    }
  }

  static int scoreFromCompactRow(String mode, Map<String, dynamic> row) {
    final stored = (row['ds'] as num?)?.toInt();
    if (stored != null && stored >= 0) return stored;
    final c = (row['c'] as num?)?.toInt() ?? 0;
    if (mode == 'binary') return c * 3;
    return c;
  }

  static int scoreFromTrainingEntry(TrainingHistoryEntry entry) {
    return scoreFromItems(
      mode: entry.mode,
      correctItems: entry.correctItems,
      data: entry.data,
      answers: entry.answers,
    );
  }

  static SessionRecord recordFromCompact(
      String mode, Map<String, dynamic> row) {
    final n = (row['n'] as num?)?.toInt() ?? 0;
    final c = (row['c'] as num?)?.toInt() ?? 0;
    final memMs = TrainingRecordRules.normalizeTimedWindowMemMs(
      (row['memMs'] as num?)?.toInt() ?? 0,
    );
    final pct = (row['pct'] as num?)?.toDouble();
    return SessionRecord(
      displayScore: scoreFromCompactRow(mode, row),
      memMs: memMs,
      totalItems: n,
      correctItems: c,
      accuracyPct: TrainingRecordRules.accuracyPercent(
        correctItems: c,
        totalItems: n,
        storedPercent: pct,
      ),
    );
  }

  static SessionRecord recordFromTrainingEntry(TrainingHistoryEntry entry) {
    return SessionRecord(
      displayScore: scoreFromTrainingEntry(entry),
      memMs: entry.memorizationMs,
      totalItems: entry.totalItems,
      correctItems: entry.correctItems,
      accuracyPct: entry.accuracy * 100.0,
    );
  }

  static Map<String, dynamic> buildModeStats({
    required Iterable<SessionRecord> sessions,
  }) {
    var best1m = 0;
    var best5m = 0;
    var maxMem = 0;

    for (final s in sessions) {
      if (s.qualifiesForMax && s.displayScore > maxMem) maxMem = s.displayScore;
      if (s.qualifiesForBest1m && s.displayScore > best1m) {
        best1m = s.displayScore;
      }
      if (s.qualifiesForBest5m && s.displayScore > best5m) {
        best5m = s.displayScore;
      }
    }

    return {
      'best1m': best1m,
      'best5m': best5m,
      'maxMem': maxMem,
    };
  }

  static String _sessionKey({
    required int timeMs,
    required int memMs,
    required int totalItems,
    required int correctItems,
    required int displayScore,
  }) =>
      '${timeMs ~/ 1000}|$memMs|$totalItems|$correctItems|$displayScore';

  static Map<String, dynamic> buildPublicStatsSnapshot(
      SharedPreferences prefs) {
    final out = <String, dynamic>{};
    for (final mode in modes) {
      final byKey = <String, SessionRecord>{};

      final compact =
          prefs.getStringList('game_history_$mode') ?? const <String>[];
      for (final item in compact) {
        try {
          final m = jsonDecode(item) as Map<String, dynamic>;
          final memMs = (m['memMs'] as num?)?.toInt() ?? 0;
          final t = (m['t'] as num?)?.toInt() ?? 0;
          final record = recordFromCompact(mode, m);
          final key = _sessionKey(
            timeMs: t,
            memMs: memMs,
            totalItems: record.totalItems,
            correctItems: record.correctItems,
            displayScore: record.displayScore,
          );
          byKey[key] = record;
        } catch (_) {}
      }

      final detailedRaw =
          prefs.getStringList('training_history_$mode') ?? const <String>[];
      for (final item in detailedRaw) {
        try {
          final entry = TrainingHistoryEntry.fromJson(
            Map<String, dynamic>.from(jsonDecode(item) as Map),
          );
          final record = recordFromTrainingEntry(entry);
          final key = _sessionKey(
            timeMs: entry.date.millisecondsSinceEpoch,
            memMs: entry.memorizationMs,
            totalItems: entry.totalItems,
            correctItems: entry.correctItems,
            displayScore: record.displayScore,
          );
          final detailed = !entry.isBriefProfileBackfill &&
              entry.data.any((d) => d.trim().isNotEmpty);
          final existing = byKey[key];
          if (existing == null || detailed) {
            byKey[key] = record;
          }
        } catch (_) {}
      }

      out[mode] = buildModeStats(sessions: byKey.values);
    }
    out['v'] = 3;
    return out;
  }

  /// Adjusts values loaded from cloud when older snapshots used element counts.
  static int displayValue({
    required String mode,
    required int raw,
    required int statsVersion,
  }) {
    if (statsVersion >= 2) return raw;
    if (mode == 'binary') return raw * 3;
    return raw;
  }

  /// Picks the index of the best qualifying session for profile analytics.
  static int pickBestSessionIndex(List<SessionRecord> sessions) {
    var bestIdx = -1;
    for (var i = 0; i < sessions.length; i++) {
      final s = sessions[i];
      if (!s.qualifiesForMax) continue;
      if (bestIdx < 0) {
        bestIdx = i;
        continue;
      }
      final b = sessions[bestIdx];
      if (TrainingRecordRules.compareRecords(
            scoreA: s.displayScore,
            accuracyA: s.accuracyPct,
            memMsA: s.memMs,
            scoreB: b.displayScore,
            accuracyB: b.accuracyPct,
            memMsB: b.memMs,
          ) >
          0) {
        bestIdx = i;
      }
    }
    return bestIdx;
  }
}

class SessionRecord {
  final int displayScore;
  final int memMs;
  final int totalItems;
  final int correctItems;
  final double accuracyPct;

  const SessionRecord({
    required this.displayScore,
    required this.memMs,
    required this.totalItems,
    required this.correctItems,
    required this.accuracyPct,
  });

  bool get qualifiesForMax => TrainingRecordRules.qualifiesForMaxRecord(
        displayScore: displayScore,
        correctItems: correctItems,
        totalItems: totalItems,
        accuracyPct: accuracyPct,
        memMs: memMs,
      );

  bool get qualifiesForBest1m => TrainingRecordRules.qualifiesForBest1m(
        displayScore: displayScore,
        correctItems: correctItems,
        totalItems: totalItems,
        accuracyPct: accuracyPct,
        memMs: memMs,
      );

  bool get qualifiesForBest5m => TrainingRecordRules.qualifiesForBest5m(
        displayScore: displayScore,
        correctItems: correctItems,
        totalItems: totalItems,
        accuracyPct: accuracyPct,
        memMs: memMs,
      );
}
