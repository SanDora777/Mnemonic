import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../recovered_app.dart' show AppLanguage;
import 'number_codes_range.dart';

/// Storage, trainer prefs, and stats for a [NumberCodesRange].
class NumberCodesService {
  const NumberCodesService(this.range);

  final NumberCodesRange range;

  static const pair99 = NumberCodesService(NumberCodesRange.pair99);
  static const triple999 = NumberCodesService(NumberCodesRange.triple999);

  /// Legacy alias for 00–99.
  static const instance = pair99;

  static NumberCodesService forRange(NumberCodesRange range) =>
      range == NumberCodesRange.triple999 ? triple999 : pair99;

  int get codeCount => range.codeCount;

  String formatCode(int code) => range.formatCode(code);

  String _imagesKey(AppLanguage lang) => '${range.imagesPrefsPrefix}_${lang.name}';

  String _statsKey(AppLanguage lang, NumberCodesTrainerDirection direction) {
    final tag = direction == NumberCodesTrainerDirection.reverse ? 'rev' : 'fwd';
    final band = range == NumberCodesRange.pair99 ? 'pair' : 'triple';
    return 'number_${band}_trainer_stats_${tag}_v1_${lang.name}';
  }

  String recordModeKey(NumberCodesTrainerDirection direction) =>
      range.recordModeKey(direction);

  Future<Map<String, String>> loadImages(AppLanguage lang) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_imagesKey(lang));
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, (v ?? '').toString().trim()));
    } catch (_) {
      return {};
    }
  }

  Future<String?> imageFor(AppLanguage lang, int code) async {
    final all = await loadImages(lang);
    return all[formatCode(code)];
  }

  Future<void> saveImage(AppLanguage lang, int code, String text) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await loadImages(lang);
    final key = formatCode(code);
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      all.remove(key);
    } else {
      all[key] = trimmed;
    }
    await _writeImages(prefs, lang, all);
  }

  Future<void> _writeImages(
    SharedPreferences prefs,
    AppLanguage lang,
    Map<String, String> all,
  ) async {
    await prefs.setString(_imagesKey(lang), jsonEncode(all));
  }

  Future<NumberCodesImportApplyResult> applyTxtImport({
    required Map<AppLanguage, Map<String, String>> entries,
    bool merge = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final applied = <AppLanguage, int>{};

    for (final e in entries.entries) {
      if (e.value.isEmpty) continue;
      final lang = e.key;
      final next = merge ? await loadImages(lang) : <String, String>{};
      for (final row in e.value.entries) {
        final image = row.value.trim();
        if (image.isEmpty) {
          next.remove(row.key);
        } else {
          next[row.key] = image;
        }
      }
      await _writeImages(prefs, lang, next);
      applied[lang] = e.value.length;
    }

    return NumberCodesImportApplyResult(appliedPerLanguage: applied);
  }

  Future<Map<AppLanguage, Map<String, String>>> loadAllLanguages() async {
    final out = <AppLanguage, Map<String, String>>{};
    for (final lang in AppLanguage.values) {
      out[lang] = await loadImages(lang);
    }
    return out;
  }

  Future<int> filledCount(AppLanguage lang) async {
    final all = await loadImages(lang);
    return all.values.where((v) => v.isNotEmpty).length;
  }

  Future<List<int>> codesWithImages(AppLanguage lang) async {
    final all = await loadImages(lang);
    final out = <int>[];
    for (var i = 0; i < codeCount; i++) {
      final img = all[formatCode(i)];
      if (img != null && img.isNotEmpty) out.add(i);
    }
    return out;
  }

  Future<int> loadTrainerCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(range.trainerCountPrefsKey) ?? range.defaultTrainerCount)
        .clamp(range.minTrainerCount, range.maxTrainerCount);
  }

  Future<void> saveTrainerCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      range.trainerCountPrefsKey,
      count.clamp(range.minTrainerCount, range.maxTrainerCount),
    );
  }

  Future<NumberCodesTrainerDirection> loadTrainerDirection() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(range.trainerDirectionPrefsKey);
    if (raw == NumberCodesTrainerDirection.reverse.name) {
      return NumberCodesTrainerDirection.reverse;
    }
    return NumberCodesTrainerDirection.forward;
  }

  Future<void> saveTrainerDirection(NumberCodesTrainerDirection direction) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(range.trainerDirectionPrefsKey, direction.name);
  }

  Future<void> recordReactionTimes(
    AppLanguage lang,
    List<({int code, int ms})> samples, {
    NumberCodesTrainerDirection direction = NumberCodesTrainerDirection.forward,
  }) async {
    if (samples.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final stats = await _loadStats(lang, direction);
    for (final s in samples) {
      if (s.ms <= 0) continue;
      final key = formatCode(s.code);
      final prev = stats[key];
      if (prev == null) {
        stats[key] = _CodeStats(totalMs: s.ms, count: 1);
      } else {
        stats[key] = _CodeStats(
          totalMs: prev.totalMs + s.ms,
          count: prev.count + 1,
        );
      }
    }
    await prefs.setString(
      _statsKey(lang, direction),
      jsonEncode(stats.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  Future<List<({int code, String image, int avgMs})>> weakestOverall(
    AppLanguage lang, {
    NumberCodesTrainerDirection direction = NumberCodesTrainerDirection.forward,
    int limit = 3,
    int minSamples = 2,
  }) async {
    return _rankedBySpeed(lang, direction: direction, limit: limit, minSamples: minSamples, slowest: true);
  }

  Future<List<({int code, String image, int avgMs})>> strongestOverall(
    AppLanguage lang, {
    NumberCodesTrainerDirection direction = NumberCodesTrainerDirection.forward,
    int limit = 3,
    int minSamples = 2,
  }) async {
    return _rankedBySpeed(lang, direction: direction, limit: limit, minSamples: minSamples, slowest: false);
  }

  Future<List<({int code, String image, int avgMs})>> _rankedBySpeed(
    AppLanguage lang, {
    required NumberCodesTrainerDirection direction,
    required int limit,
    required int minSamples,
    required bool slowest,
  }) async {
    final images = await loadImages(lang);
    final stats = await _loadStats(lang, direction);
    final rows = <({int code, String image, int avgMs})>[];
    stats.forEach((key, st) {
      if (st.count < minSamples) return;
      final img = images[key];
      if (img == null || img.isEmpty) return;
      final code = int.tryParse(key);
      if (code == null) return;
      rows.add((code: code, image: img, avgMs: st.avgMs));
    });
    rows.sort((a, b) =>
        slowest ? b.avgMs.compareTo(a.avgMs) : a.avgMs.compareTo(b.avgMs));
    return rows.take(limit).toList(growable: false);
  }

  Future<Map<String, _CodeStats>> _loadStats(
    AppLanguage lang,
    NumberCodesTrainerDirection direction,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    var raw = prefs.getString(_statsKey(lang, direction));
    final legacy = range.legacyStatsSuffix;
    if (direction == NumberCodesTrainerDirection.forward &&
        (raw == null || raw.isEmpty) &&
        legacy != null) {
      raw = prefs.getString('$legacy${lang.name}');
    }
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map(
        (k, v) => MapEntry(
          k,
          _CodeStats.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      );
    } catch (_) {
      return {};
    }
  }
}

class NumberCodesImportApplyResult {
  const NumberCodesImportApplyResult({required this.appliedPerLanguage});

  final Map<AppLanguage, int> appliedPerLanguage;

  int get total => appliedPerLanguage.values.fold(0, (a, b) => a + b);
}

@Deprecated('Use NumberCodesImportApplyResult')
typedef NumberPairImportApplyResult = NumberCodesImportApplyResult;

@Deprecated('Use NumberCodesService')
typedef NumberPairImagesService = NumberCodesService;

class _CodeStats {
  const _CodeStats({required this.totalMs, required this.count});

  final int totalMs;
  final int count;

  int get avgMs => count <= 0 ? 0 : (totalMs / count).round();

  Map<String, dynamic> toJson() => {'ms': totalMs, 'n': count};

  factory _CodeStats.fromJson(Map<String, dynamic> json) => _CodeStats(
        totalMs: (json['ms'] as num?)?.toInt() ?? 0,
        count: (json['n'] as num?)?.toInt() ?? 0,
      );
}
