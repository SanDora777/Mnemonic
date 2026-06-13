import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile/profile_session_service.dart';
import 'public_stats_scoring.dart';
import 'training_record_rules.dart';

/// Synthetic history rows reconstructed from profile sessions when detailed
/// [training_history_*] payloads were missing (e.g. after cloud sync).
const String kTrainingHistoryProfileBackfillPrefix = 'profile_session_';

extension TrainingHistoryEntryReplay on TrainingHistoryEntry {
  /// No memorized items / answers were persisted for this row — opening a replay UI is unsupported.
  bool get isBriefProfileBackfill =>
      id.startsWith(kTrainingHistoryProfileBackfillPrefix);
}

const List<String> trainingHistoryModes = [
  'standard',
  'binary',
  'words',
  'images',
  'cards',
  'faces',
];

class TrainingHistoryEntry {
  final String id;
  final String mode;
  final DateTime date;
  final int totalItems;
  final int correctItems;
  final int memorizationMs;
  final int recallMs;
  final int xpEarned;
  final List<String> data;
  final List<String> answers;
  final List<int?> imageAnswerOrder;
  final List<int> memorizationMsByElement;
  final List<int> correctnessPattern;
  final List<String> lociBindings;

  const TrainingHistoryEntry({
    required this.id,
    required this.mode,
    required this.date,
    required this.totalItems,
    required this.correctItems,
    required this.memorizationMs,
    required this.recallMs,
    required this.xpEarned,
    required this.data,
    required this.answers,
    required this.imageAnswerOrder,
    required this.memorizationMsByElement,
    required this.correctnessPattern,
    this.lociBindings = const <String>[],
  });

  double get accuracy => totalItems <= 0 ? 0 : correctItems / totalItems;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'mode': mode,
        'date': date.toIso8601String(),
        'totalItems': totalItems,
        'correctItems': correctItems,
        'memorizationMs': memorizationMs,
        'recallMs': recallMs,
        'xpEarned': xpEarned,
        'data': data,
        'answers': answers,
        'imageAnswerOrder': imageAnswerOrder,
        'memorizationMsByElement': memorizationMsByElement,
        'correctnessPattern': correctnessPattern,
        'lociBindings': lociBindings,
      };

  static TrainingHistoryEntry fromJson(Map<String, dynamic> raw) {
    List<String> strings(dynamic value) {
      if (value is List)
        return value.map((e) => e.toString()).toList(growable: false);
      return const <String>[];
    }

    List<int> ints(dynamic value) {
      if (value is List) {
        return value.map((e) {
          if (e is num) return e.toInt();
          return int.tryParse(e.toString()) ?? 0;
        }).toList(growable: false);
      }
      return const <int>[];
    }

    List<int?> nullableInts(dynamic value) {
      if (value is List) {
        return value.map((e) {
          if (e == null) return null;
          if (e is num) return e.toInt();
          return int.tryParse(e.toString());
        }).toList(growable: false);
      }
      return const <int?>[];
    }

    final data = strings(raw['data']);
    final total = max(1, (raw['totalItems'] as num?)?.toInt() ?? data.length);
    final dynamic rawDate = raw['date'];
    final DateTime parsedDate = rawDate is Timestamp
        ? rawDate.toDate()
        : (rawDate is DateTime
            ? rawDate
            : DateTime.tryParse(rawDate?.toString() ?? '') ?? DateTime.now());
    final memMsRaw = max(0, (raw['memorizationMs'] as num?)?.toInt() ?? 0);
    return TrainingHistoryEntry(
      id: (raw['id'] ?? '').toString().isEmpty
          ? 'history_${DateTime.now().microsecondsSinceEpoch}'
          : raw['id'].toString(),
      mode: (raw['mode'] ?? 'standard').toString(),
      date: parsedDate,
      totalItems: total,
      correctItems: max(0, (raw['correctItems'] as num?)?.toInt() ?? 0),
      memorizationMs: TrainingRecordRules.normalizeTimedWindowMemMs(memMsRaw),
      recallMs: max(0, (raw['recallMs'] as num?)?.toInt() ?? 0),
      xpEarned: max(0, (raw['xpEarned'] as num?)?.toInt() ?? 0),
      data: data,
      answers: strings(raw['answers']),
      imageAnswerOrder: nullableInts(raw['imageAnswerOrder']),
      memorizationMsByElement: ints(raw['memorizationMsByElement']),
      correctnessPattern: ints(raw['correctnessPattern']),
      lociBindings: strings(raw['lociBindings']),
    );
  }
}

class TrainingHistoryService {
  TrainingHistoryService._();
  static final TrainingHistoryService instance = TrainingHistoryService._();

  // Keep long history per discipline (effectively "all" for normal usage).
  static const int _maxPerMode = 5000;
  static const String _deletedFingerprintsKey =
      'training_history_deleted_fps_v1';
  static const int _maxDeletedFingerprints = 800;

  String _key(String mode) => 'training_history_$mode';

  Future<Set<String>> _loadDeletedFingerprints() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_deletedFingerprintsKey) ?? const <String>[])
        .toSet();
  }

  Future<void> _persistDeletedFingerprints(Set<String> fps) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = fps.take(_maxDeletedFingerprints).toList(growable: false);
    await prefs.setStringList(_deletedFingerprintsKey, trimmed);
  }

  /// Prevents profile-session backfill and cloud merge from resurrecting a deleted row.
  Future<void> markSessionDeleted(TrainingHistoryEntry entry) async {
    final fps = await _loadDeletedFingerprints();
    if (fps.add(_sessionFingerprint(entry))) {
      await _persistDeletedFingerprints(fps);
    }
  }

  bool _isDeleted(TrainingHistoryEntry entry, Set<String> deletedFps) =>
      deletedFps.contains(_sessionFingerprint(entry));

  Future<void> record(TrainingHistoryEntry entry) async {
    final sessions = await loadMode(entry.mode);
    sessions.removeWhere((e) => e.id == entry.id);
    sessions.insert(0, entry);
    await _saveMode(entry.mode, _dedupePreferDetailed(sessions));
  }

  Future<List<TrainingHistoryEntry>> loadMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    final deletedFps = await _loadDeletedFingerprints();
    final raw = prefs.getStringList(_key(mode)) ?? const <String>[];
    var merged = <TrainingHistoryEntry>[];
    var normalizedAny = false;
    for (final item in raw) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        final oldMemMs = max(0, (map['memorizationMs'] as num?)?.toInt() ?? 0);
        final normalizedMemMs =
            TrainingRecordRules.normalizeTimedWindowMemMs(oldMemMs);
        if (oldMemMs != normalizedMemMs) {
          map['memorizationMs'] = normalizedMemMs;
          normalizedAny = true;
        }
        final entry = TrainingHistoryEntry.fromJson(map);
        if (!_isDeleted(entry, deletedFps)) {
          merged.add(entry);
        }
      } catch (_) {}
    }
    var dirty = merged.length != raw.length || normalizedAny;

    if (merged.isEmpty) {
      merged = _migrateLegacyGameHistory(mode, prefs)
          .where((e) => !_isDeleted(e, deletedFps))
          .toList(growable: false);
      if (merged.isNotEmpty) {
        dirty = true;
      }
    }

    final beforeAppend = merged.length;
    merged = [
      ...merged,
      ...await _missingProfileOnlyEntries(mode, merged, deletedFps),
    ];
    if (merged.length != beforeAppend) {
      dirty = true;
    }

    final deduped = _dedupePreferDetailed(merged);
    if (deduped.length != merged.length) {
      dirty = true;
    }
    merged = deduped;

    merged.sort((a, b) => b.date.compareTo(a.date));
    if (dirty) {
      await _saveMode(mode, merged);
    }
    return merged;
  }

  String _sessionFingerprint(TrainingHistoryEntry e) =>
      '${e.mode}|${e.date.millisecondsSinceEpoch}|${e.totalItems}|${e.correctItems}|${e.memorizationMs}|${e.recallMs}';

  List<TrainingHistoryEntry> _dedupePreferDetailed(
      List<TrainingHistoryEntry> sessions) {
    final byFp = <String, TrainingHistoryEntry>{};
    for (final e in sessions) {
      final fp = _sessionFingerprint(e);
      final prev = byFp[fp];
      if (prev == null) {
        byFp[fp] = e;
        continue;
      }
      byFp[fp] = _preferDetailedHistoryEntry(prev, e);
    }
    return byFp.values.toList();
  }

  TrainingHistoryEntry _preferDetailedHistoryEntry(
      TrainingHistoryEntry a, TrainingHistoryEntry b) {
    final aBrief = a.isBriefProfileBackfill;
    final bBrief = b.isBriefProfileBackfill;
    if (aBrief && !bBrief) return b;
    if (!aBrief && bBrief) return a;
    return a.date.isAfter(b.date) ? a : b;
  }

  TrainingHistoryEntry _entryFromProfileSession(ProfileSessionEntry s) {
    final n = max(1, s.totalItems);
    final pattern = s.hasPattern
        ? List<int>.from(s.correctnessPattern)
        : List<int>.filled(n, 0, growable: false);
    return TrainingHistoryEntry(
      id: '$kTrainingHistoryProfileBackfillPrefix${s.mode}_${s.date.millisecondsSinceEpoch}_${s.totalItems}_${s.correctItems}_${s.encodingMs}_${s.recallMs}',
      mode: s.mode,
      date: s.date,
      totalItems: n,
      correctItems: s.correctItems,
      memorizationMs: s.encodingMs,
      recallMs: s.recallMs,
      xpEarned: 0,
      data: List<String>.filled(n, '', growable: false),
      answers: List<String>.filled(n, '', growable: false),
      imageAnswerOrder: List<int?>.filled(n, null, growable: false),
      memorizationMsByElement: List<int>.filled(
          n, n <= 0 ? 0 : (s.encodingMs / n).round(),
          growable: false),
      correctnessPattern: pattern,
      lociBindings: const <String>[],
    );
  }

  Future<List<TrainingHistoryEntry>> _missingProfileOnlyEntries(
    String mode,
    List<TrainingHistoryEntry> existing,
    Set<String> deletedFps,
  ) async {
    final fps = existing.map(_sessionFingerprint).toSet();
    final out = <TrainingHistoryEntry>[];
    final profile = await ProfileSessionService.instance.loadSessions();
    for (final s in profile) {
      if (s.mode != mode) continue;
      final e = _entryFromProfileSession(s);
      final fp = _sessionFingerprint(e);
      if (_isDeleted(e, deletedFps)) continue;
      if (fps.add(fp)) {
        out.add(e);
      }
    }
    return out;
  }

  List<TrainingHistoryEntry> _migrateLegacyGameHistory(
    String mode,
    SharedPreferences prefs,
  ) {
    final legacy =
        prefs.getStringList('game_history_$mode') ?? const <String>[];
    if (legacy.isEmpty) return const <TrainingHistoryEntry>[];
    final out = <TrainingHistoryEntry>[];
    for (final raw in legacy) {
      try {
        final m = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        final t =
            (m['t'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;
        final n = max(1, (m['n'] as num?)?.toInt() ?? 1);
        final c = max(0, (m['c'] as num?)?.toInt() ?? 0);
        final memMs = max(0, (m['memMs'] as num?)?.toInt() ?? 0);
        final recMs = max(0, (m['recMs'] as num?)?.toInt() ?? 0);
        final legacyId = (m['thId'] ?? '').toString();
        final id = legacyId.isNotEmpty
            ? legacyId
            : 'legacy_${mode}_${t}_${out.length}';
        out.add(
          TrainingHistoryEntry(
            id: id,
            mode: mode,
            date: DateTime.fromMillisecondsSinceEpoch(t),
            totalItems: n,
            correctItems: c,
            memorizationMs: memMs,
            recallMs: recMs,
            xpEarned: 0,
            data: List<String>.filled(n, '', growable: false),
            answers: List<String>.filled(n, '', growable: false),
            imageAnswerOrder: List<int?>.filled(n, null, growable: false),
            memorizationMsByElement: List<int>.filled(
                n, n <= 0 ? 0 : (memMs / n).round(),
                growable: false),
            correctnessPattern: List<int>.filled(n, 0, growable: false),
            lociBindings: const <String>[],
          ),
        );
      } catch (_) {}
    }
    out.sort((a, b) => b.date.compareTo(a.date));
    return out;
  }

  Future<void> mergeFromCloud(
      String mode, List<TrainingHistoryEntry> cloudEntries) async {
    final deletedFps = await _loadDeletedFingerprints();
    final merged = <String, TrainingHistoryEntry>{};
    for (final e in await loadMode(mode)) {
      merged[e.id] = e;
    }
    for (final e in cloudEntries.where(
      (e) => e.mode == mode && !_isDeleted(e, deletedFps),
    )) {
      final prev = merged[e.id];
      merged[e.id] = prev == null ? e : _preferDetailedHistoryEntry(prev, e);
    }
    final union = merged.values.toList();
    final deduped = _dedupePreferDetailed(union);
    deduped.sort((a, b) => b.date.compareTo(a.date));
    await _saveMode(mode, deduped);
  }

  Future<void> removeAllLocal() async {
    final prefs = await SharedPreferences.getInstance();
    for (final mode in trainingHistoryModes) {
      await prefs.remove(_key(mode));
    }
  }

  Future<void> removeById(String mode, String id) async {
    if (id.isEmpty) return;
    final sessions = await loadMode(mode);
    sessions.removeWhere((e) => e.id == id);
    await _saveMode(mode, sessions);
  }

  /// Removes detailed history, matching compact [game_history_$mode] row, and
  /// recomputes per-mode totals (sessions count, average %, best score, best speed).
  Future<void> removeLocalSessionAndDisciplineAggregates(
      TrainingHistoryEntry entry) async {
    await markSessionDeleted(entry);
    await removeById(entry.mode, entry.id);
    final prefs = await SharedPreferences.getInstance();
    final key = 'game_history_${entry.mode}';
    final raw = List<String>.from(prefs.getStringList(key) ?? []);
    final kept = <String>[];
    for (final r in raw) {
      try {
        final m = Map<String, dynamic>.from(jsonDecode(r) as Map);
        if (_gameHistoryRowMatchesEntry(m, entry)) continue;
      } catch (_) {}
      kept.add(r);
    }
    await prefs.setStringList(key, kept);
    await _recomputeDisciplineAggregates(prefs, entry.mode);
  }

  bool _gameHistoryRowMatchesEntry(
      Map<String, dynamic> m, TrainingHistoryEntry e) {
    final thId = (m['thId'] ?? '').toString();
    if (thId.isNotEmpty && thId == e.id) return true;
    final t = (m['t'] as num?)?.toInt();
    if (t == null) return false;
    if ((t - e.date.millisecondsSinceEpoch).abs() > 8000) return false;
    if ((m['n'] as num?)?.toInt() != e.totalItems) return false;
    if ((m['c'] as num?)?.toInt() != e.correctItems) return false;
    return true;
  }

  Future<void> _recomputeDisciplineAggregates(
      SharedPreferences prefs, String modeKey) async {
    final historyKey = 'game_history_$modeKey';
    final bestSpeedKey = 'best_avg_ms_per_el_$modeKey';
    final historyRaw = prefs.getStringList(historyKey) ?? const <String>[];
    if (historyRaw.isEmpty) {
      await prefs.remove('total_games_$modeKey');
      await prefs.remove('avg_percentage_$modeKey');
      await prefs.setInt('best_score_$modeKey', 0);
      await prefs.remove(bestSpeedKey);
      return;
    }
    var games = 0;
    var sumPct = 0.0;
    var bestScore = 0;
    int? bestAvgMs;
    for (final item in historyRaw) {
      try {
        final m = jsonDecode(item) as Map<String, dynamic>;
        games++;
        sumPct += (m['pct'] as num?)?.toDouble() ?? 0.0;
        final record = PublicStatsScoring.recordFromCompact(modeKey, m);
        if (record.qualifiesForMax && record.displayScore > bestScore) {
          bestScore = record.displayScore;
        }
        final avgMem = (m['avgMemMsPerEl'] as num?)?.toInt() ?? 0;
        if (avgMem > 0 && (bestAvgMs == null || avgMem < bestAvgMs))
          bestAvgMs = avgMem;
      } catch (_) {}
    }
    await prefs.setInt('total_games_$modeKey', games);
    await prefs.setDouble(
        'avg_percentage_$modeKey', games > 0 ? sumPct / games : 0.0);
    await prefs.setInt('best_score_$modeKey', bestScore);
    if (bestAvgMs != null) {
      await prefs.setInt(bestSpeedKey, bestAvgMs);
    } else {
      await prefs.remove(bestSpeedKey);
    }
  }

  Future<void> _saveMode(
      String mode, List<TrainingHistoryEntry> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = sessions.take(_maxPerMode).toList(growable: false);
    await prefs.setStringList(
      _key(mode),
      trimmed.map((e) => jsonEncode(e.toJson())).toList(growable: false),
    );
  }
}
