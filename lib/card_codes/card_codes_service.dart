import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../recovered_app.dart' show AppLanguage;
import 'card_codes_deck.dart';

/// Storage, trainer prefs, and stats for playing-card mnemonic images.
class CardCodesService {
  const CardCodesService();

  static const instance = CardCodesService();

  String _imagesKey(AppLanguage lang) =>
      '${CardCodesDeck.imagesPrefsPrefix}_${lang.name}';

  String _statsKey(AppLanguage lang, CardCodesTrainerDirection direction) {
    final tag =
        direction == CardCodesTrainerDirection.reverse ? 'rev' : 'fwd';
    return 'card_codes_trainer_stats_${tag}_v1_${lang.name}';
  }

  String recordModeKey(CardCodesTrainerDirection direction) =>
      CardCodesDeck.recordModeKey(direction);

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

  Future<void> saveImage(AppLanguage lang, String cardCode, String text) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await loadImages(lang);
    final key = cardCode.toLowerCase();
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      all.remove(key);
    } else {
      all[key] = trimmed;
    }
    await prefs.setString(_imagesKey(lang), jsonEncode(all));
  }

  Future<int> filledCount(AppLanguage lang) async {
    final all = await loadImages(lang);
    return all.values.where((v) => v.isNotEmpty).length;
  }

  Future<List<String>> cardsWithImages(AppLanguage lang) async {
    final all = await loadImages(lang);
    final out = <String>[];
    for (final code in CardCodesDeck.allCodes()) {
      final img = all[code];
      if (img != null && img.isNotEmpty) out.add(code);
    }
    return out;
  }

  Future<int> loadTrainerCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(CardCodesDeck.trainerCountPrefsKey) ??
            CardCodesDeck.defaultTrainerCount)
        .clamp(CardCodesDeck.minTrainerCount, CardCodesDeck.maxTrainerCount);
  }

  Future<void> saveTrainerCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      CardCodesDeck.trainerCountPrefsKey,
      count.clamp(
        CardCodesDeck.minTrainerCount,
        CardCodesDeck.maxTrainerCount,
      ),
    );
  }

  Future<CardCodesTrainerDirection> loadTrainerDirection() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(CardCodesDeck.trainerDirectionPrefsKey);
    if (raw == CardCodesTrainerDirection.reverse.name) {
      return CardCodesTrainerDirection.reverse;
    }
    return CardCodesTrainerDirection.forward;
  }

  Future<void> saveTrainerDirection(CardCodesTrainerDirection direction) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(CardCodesDeck.trainerDirectionPrefsKey, direction.name);
  }

  Future<void> recordReactionTimes(
    AppLanguage lang,
    List<({String card, int ms})> samples, {
    CardCodesTrainerDirection direction = CardCodesTrainerDirection.forward,
  }) async {
    if (samples.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final stats = await _loadStats(lang, direction);
    for (final s in samples) {
      if (s.ms <= 0) continue;
      final key = s.card.toLowerCase();
      final prev = stats[key];
      if (prev == null) {
        stats[key] = _CardCodeStats(totalMs: s.ms, count: 1);
      } else {
        stats[key] = _CardCodeStats(
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

  Future<List<({String card, String image, int avgMs})>> weakestOverall(
    AppLanguage lang, {
    CardCodesTrainerDirection direction = CardCodesTrainerDirection.forward,
    int limit = 3,
    int minSamples = 2,
  }) =>
      _rankedBySpeed(
        lang,
        direction: direction,
        limit: limit,
        minSamples: minSamples,
        slowest: true,
      );

  Future<List<({String card, String image, int avgMs})>> strongestOverall(
    AppLanguage lang, {
    CardCodesTrainerDirection direction = CardCodesTrainerDirection.forward,
    int limit = 3,
    int minSamples = 2,
  }) =>
      _rankedBySpeed(
        lang,
        direction: direction,
        limit: limit,
        minSamples: minSamples,
        slowest: false,
      );

  Future<List<({String card, String image, int avgMs})>> _rankedBySpeed(
    AppLanguage lang, {
    required CardCodesTrainerDirection direction,
    required int limit,
    required int minSamples,
    required bool slowest,
  }) async {
    final images = await loadImages(lang);
    final stats = await _loadStats(lang, direction);
    final rows = <({String card, String image, int avgMs})>[];
    stats.forEach((key, st) {
      if (st.count < minSamples) return;
      final img = images[key];
      if (img == null || img.isEmpty) return;
      rows.add((card: key, image: img, avgMs: st.avgMs));
    });
    rows.sort((a, b) =>
        slowest ? b.avgMs.compareTo(a.avgMs) : a.avgMs.compareTo(b.avgMs));
    return rows.take(limit).toList(growable: false);
  }

  Future<Map<String, _CardCodeStats>> _loadStats(
    AppLanguage lang,
    CardCodesTrainerDirection direction,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_statsKey(lang, direction));
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map(
        (k, v) => MapEntry(
          k,
          _CardCodeStats.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      );
    } catch (_) {
      return {};
    }
  }
}

class _CardCodeStats {
  const _CardCodeStats({required this.totalMs, required this.count});

  final int totalMs;
  final int count;

  int get avgMs => count <= 0 ? 0 : (totalMs / count).round();

  Map<String, dynamic> toJson() => {'ms': totalMs, 'n': count};

  factory _CardCodeStats.fromJson(Map<String, dynamic> json) => _CardCodeStats(
        totalMs: (json['ms'] as num?)?.toInt() ?? 0,
        count: (json['n'] as num?)?.toInt() ?? 0,
      );
}
