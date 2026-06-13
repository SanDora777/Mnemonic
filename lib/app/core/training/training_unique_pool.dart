part of 'package:flutter_application_1/recovered_app.dart';

const String _kTrainingUsedWordsPrefsPrefix = 'training_used_words_v1_';
const String _kTrainingUsedImageSeedsPrefsKey = 'training_used_image_seeds_v1';
const String _kTrainingWordsLanguagePrefsKey = 'training_words_language_v1';
const int _kTrainingImagePoolSize = 2000;
const int _kMaxPersistedUsedItems = 8000;

/// Picks up to [count] unique items from [pool], avoiding [persistedUsed] keys.
/// When the unused pool is smaller than [count], persisted used keys are cleared
/// and the full pool is reshuffled. If [count] still exceeds [pool].length, the
/// remainder is filled with random picks (last resort for oversized sessions).
Future<List<T>> pickUniqueTrainingItems<T>({
  required List<T> pool,
  required int count,
  required Random random,
  required String prefsKey,
  required String Function(T item) itemKey,
}) async {
  if (pool.isEmpty || count <= 0) return const [];

  final prefs = await SharedPreferences.getInstance();
  final persistedUsed = Set<String>.from(prefs.getStringList(prefsKey) ?? []);

  var available =
      pool.where((e) => !persistedUsed.contains(itemKey(e))).toList();
  if (available.length < count) {
    persistedUsed.clear();
    available = List<T>.from(pool);
  }

  available.shuffle(random);
  final picked = <T>[];

  for (final item in available) {
    if (picked.length >= count) break;
    final key = itemKey(item);
    picked.add(item);
    persistedUsed.add(key);
  }

  while (picked.length < count) {
    final item = pool[random.nextInt(pool.length)];
    picked.add(item);
  }

  final trimmed = persistedUsed.toList();
  if (trimmed.length > _kMaxPersistedUsedItems) {
    trimmed.removeRange(0, trimmed.length - _kMaxPersistedUsedItems);
  }
  await prefs.setStringList(prefsKey, trimmed);

  return picked;
}

Future<List<String>> pickWordsForTraining({
  required int count,
  required AppLanguage language,
  required List<String> fallback,
  required Random random,
}) async {
  final words = await loadWordsForLanguage(language, fallback: fallback);
  if (words.isEmpty) return const [];
  return pickUniqueTrainingItems<String>(
    pool: words,
    count: count,
    random: random,
    prefsKey: '$_kTrainingUsedWordsPrefsPrefix${language.name}',
    itemKey: (w) => w,
  );
}

Future<List<String>> pickImageUrlsForTraining({
  required int count,
  required Random random,
}) async {
  final seeds = List.generate(_kTrainingImagePoolSize, (i) => i + 1);
  final pickedSeeds = await pickUniqueTrainingItems<int>(
    pool: seeds,
    count: count,
    random: random,
    prefsKey: _kTrainingUsedImageSeedsPrefsKey,
    itemKey: (id) => id.toString(),
  );
  return pickedSeeds
      .map((id) => 'https://picsum.photos/seed/$id/400/300')
      .toList(growable: false);
}

Future<AppLanguage?> loadSavedWordsTrainingLanguage() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kTrainingWordsLanguagePrefsKey);
  if (raw == null) return null;
  return AppLanguage.values
      .cast<AppLanguage?>()
      .firstWhere((l) => l!.name == raw, orElse: () => null);
}

Future<void> persistWordsTrainingLanguage(AppLanguage language) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kTrainingWordsLanguagePrefsKey, language.name);
}

Future<int> wordsCountForLanguage(AppLanguage language) async {
  final words = await loadWordsForLanguage(language, fallback: const []);
  return words.length;
}
