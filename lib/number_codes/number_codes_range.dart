/// Mnemonic code ranges supported by the codes editor and trainer.
enum NumberCodesRange {
  /// 00–99 (100 codes).
  pair99,

  /// 000–999 (1000 codes).
  triple999,
}

extension NumberCodesRangeConfig on NumberCodesRange {
  int get codeCount => this == NumberCodesRange.pair99 ? 100 : 1000;

  int get digitPadding => this == NumberCodesRange.pair99 ? 2 : 3;

  int get maxCode => codeCount - 1;

  String get titleLabel =>
      this == NumberCodesRange.pair99 ? '00 - 99' : '000 - 999';

  String get txtRangeLabel =>
      this == NumberCodesRange.pair99 ? '00-99' : '000-999';

  String get imagesPrefsPrefix => this == NumberCodesRange.pair99
      ? 'number_pair_images_v1'
      : 'number_triple_images_v1';

  String get trainerCountPrefsKey => this == NumberCodesRange.pair99
      ? 'number_pair_trainer_count_v1'
      : 'number_triple_trainer_count_v1';

  String get trainerDirectionPrefsKey => this == NumberCodesRange.pair99
      ? 'number_pair_trainer_direction_v1'
      : 'number_triple_trainer_direction_v1';

  String? get legacyStatsSuffix => this == NumberCodesRange.pair99
      ? 'number_pair_trainer_stats_v1_'
      : null;

  int get defaultTrainerCount => 20;

  int get maxTrainerCount => codeCount;

  int get minTrainerCount => 5;

  int get gridColumns => this == NumberCodesRange.pair99 ? 10 : 5;

  double get gridAspectRatio => this == NumberCodesRange.pair99 ? 0.92 : 1.05;

  double get codeDisplayFontSize => this == NumberCodesRange.pair99 ? 56 : 44;

  String recordModeKey(NumberCodesTrainerDirection direction) {
    final base = this == NumberCodesRange.pair99
        ? 'number_pairs'
        : 'number_triples';
    return direction == NumberCodesTrainerDirection.reverse
        ? '${base}_rev'
        : base;
  }

  String formatCode(int code) =>
      code.clamp(0, maxCode).toString().padLeft(digitPadding, '0');
}

/// [forward]: number → image; [reverse]: image → number.
enum NumberCodesTrainerDirection {
  forward,
  reverse,
}

@Deprecated('Use NumberCodesTrainerDirection')
typedef NumberPairTrainerDirection = NumberCodesTrainerDirection;
