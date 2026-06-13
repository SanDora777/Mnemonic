/// Standard 52-card French deck codes used across the app (`h2`, `da`, `s10`).
class CardCodesDeck {
  const CardCodesDeck._();

  static const suits = ['h', 'd', 'c', 's'];
  static const ranks = [
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    'j',
    'q',
    'k',
    'a',
  ];

  static const int codeCount = 52;
  static const int minTrainerCount = 5;
  static const int defaultTrainerCount = 13;
  static const int maxTrainerCount = codeCount;

  static const imagesPrefsPrefix = 'card_codes_images_v1';
  static const trainerCountPrefsKey = 'card_codes_trainer_count_v1';
  static const trainerDirectionPrefsKey = 'card_codes_trainer_direction_v1';

  static List<String> allCodes() => [
        for (final suit in suits)
          for (final rank in ranks) '$suit$rank',
      ];

  static List<String> codesForSuit(String suit) =>
      [for (final rank in ranks) '$suit$rank'];

  static String? suitOf(String code) {
    if (code.isEmpty) return null;
    final s = code[0].toLowerCase();
    return suits.contains(s) ? s : null;
  }

  static String displayRank(String code) {
    final rank = code.length > 1 ? code.substring(1) : '';
    return rank.toUpperCase();
  }

  static String recordModeKey(CardCodesTrainerDirection direction) =>
      direction == CardCodesTrainerDirection.reverse
          ? 'card_codes_rev'
          : 'card_codes';
}

/// [forward]: card → mnemonic; [reverse]: mnemonic → card.
enum CardCodesTrainerDirection {
  forward,
  reverse,
}
