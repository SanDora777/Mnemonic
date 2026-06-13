part of 'package:flutter_application_1/recovered_app.dart';

const int _kMaxHistoryPerMode = 5000;
const String _kLociRoutesPrefsKey = 'loci_routes_v1';
const String _kElementStatsHintCountPrefsKey = 'element_stats_hint_count_v1';
/// 0 = без лимита; иначе секунды на фазу запоминания (тренажёр).
const String _kTrainingSessionMemCapSecPrefsKey = 'training_session_mem_cap_sec_v1';
const String _kTrainingTotalCountPerModePrefsPrefix = 'training_total_count_per_mode_v1_';
const String _kTrainingChunkCountPerModePrefsPrefix = 'training_chunk_count_per_mode_v1_';
const Map<AppLanguage, String> _kWordsAssetByLanguage = {
  AppLanguage.ru: 'worsgenerator/ru/words.txt',
  AppLanguage.en: 'worsgenerator/en/words.txt',
  AppLanguage.de: 'worsgenerator/de/words.txt',
};

final Map<AppLanguage, List<String>> _wordsCache = {};

Future<List<String>> loadWordsForLanguage(
  AppLanguage language, {
  required List<String> fallback,
}) async {
  final cached = _wordsCache[language];
  if (cached != null && cached.isNotEmpty) {
    return cached;
  }

  final path = _kWordsAssetByLanguage[language];
  if (path == null) return fallback;
  try {
    final raw = await rootBundle.loadString(path);
    final words = raw
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    if (words.isNotEmpty) {
      _wordsCache[language] = words;
      return words;
    }
  } catch (_) {
    // Use fallback if language file is missing or malformed.
  }
  return fallback;
}
