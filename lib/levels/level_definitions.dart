import '../recovered_app.dart' show TrainingMode;

/// Discipline progression paths (solo trainer).
enum LevelPath {
  numbers,
  images,
  cards,
  words,
  faces,
}

enum LevelTier {
  beginner,
  student,
  mnemonist,
  expert,
  master,
}

/// Optional challenge modifiers — UI guidance only; user keeps full trainer settings.
enum LevelChallengeKind {
  none,
  speedMemorize,
  randomRecall,
  accuracyChallenge,
  abstractImages,
  fastReveal,
  multiImageScreen,
  timedDeck,
  speedDeck,
  dualCardEncoding,
  competitionSimulation,
}

class TrainerLevelDef {
  const TrainerLevelDef({
    required this.id,
    required this.path,
    required this.tier,
    required this.displayNumber,
    required this.elementCount,
    required this.requiredAccuracy,
    this.memTimeLimitSec,
    this.recallTimeLimitSec,
    this.kind = LevelChallengeKind.none,
    this.titleOverride,
  });

  final String id;
  final LevelPath path;
  final LevelTier tier;
  final int displayNumber;
  final int elementCount;
  final double requiredAccuracy;
  final int? memTimeLimitSec;
  final int? recallTimeLimitSec;
  final LevelChallengeKind kind;

  /// Shown instead of auto title for special challenges.
  final Map<String, String>? titleOverride;

  bool get isSpeedChallenge => kind == LevelChallengeKind.speedMemorize;

  /// Numbers path levels count **digits**, not encoded pairs.
  bool get countsAsDigits => path == LevelPath.numbers;
}

class LevelDefinitions {
  LevelDefinitions._();

  static TrainingMode trainingModeForPath(LevelPath path) {
    switch (path) {
      case LevelPath.numbers:
        return TrainingMode.standard;
      case LevelPath.images:
        return TrainingMode.images;
      case LevelPath.cards:
        return TrainingMode.cards;
      case LevelPath.words:
        return TrainingMode.words;
      case LevelPath.faces:
        return TrainingMode.faces;
    }
  }

  static LevelPath? pathForTrainingMode(TrainingMode mode) {
    switch (mode) {
      case TrainingMode.standard:
        return LevelPath.numbers;
      case TrainingMode.images:
        return LevelPath.images;
      case TrainingMode.cards:
        return LevelPath.cards;
      case TrainingMode.words:
        return LevelPath.words;
      case TrainingMode.faces:
        return LevelPath.faces;
      case TrainingMode.binary:
        return null;
    }
  }

  static int maxElementsForPath(LevelPath path) {
    final levels = levelsForPath(path);
    var max = 1;
    for (final l in levels) {
      if (l.elementCount > max) max = l.elementCount;
    }
    return max;
  }

  static final List<TrainerLevelDef> numbers = _buildNumbers();
  static final List<TrainerLevelDef> images = _buildImages();
  static final List<TrainerLevelDef> cards = _buildCards();
  static final List<TrainerLevelDef> words = _buildWords();
  static final List<TrainerLevelDef> faces = _buildFaces();

  static List<TrainerLevelDef> levelsForPath(LevelPath path) {
    switch (path) {
      case LevelPath.numbers:
        return numbers;
      case LevelPath.images:
        return images;
      case LevelPath.cards:
        return cards;
      case LevelPath.words:
        return words;
      case LevelPath.faces:
        return faces;
    }
  }

  static TrainerLevelDef? byId(String id) {
    for (final path in LevelPath.values) {
      for (final l in levelsForPath(path)) {
        if (l.id == id) return l;
      }
    }
    return null;
  }

  static double accuracyForTier(LevelTier tier) {
    switch (tier) {
      case LevelTier.beginner:
        return 70;
      case LevelTier.student:
        return 80;
      case LevelTier.mnemonist:
        return 85;
      case LevelTier.expert:
        return 90;
      case LevelTier.master:
        return 95;
    }
  }

  static List<TrainerLevelDef> _buildNumbers() {
    final out = <TrainerLevelDef>[];
    var n = 0;
    void addTier(LevelTier tier, List<int> counts, {List<LevelChallengeKind>? kinds}) {
      for (var i = 0; i < counts.length; i++) {
        n++;
        final kind = kinds != null && i < kinds.length ? kinds[i] : LevelChallengeKind.none;
        var memLimit = kind == LevelChallengeKind.speedMemorize ? _speedMemSec(counts[i]) : null;
        out.add(TrainerLevelDef(
          id: 'numbers_$n',
          path: LevelPath.numbers,
          tier: tier,
          displayNumber: n,
          elementCount: counts[i],
          requiredAccuracy: accuracyForTier(tier),
          memTimeLimitSec: memLimit,
          kind: kind,
        ));
      }
    }

    addTier(LevelTier.beginner, [5, 10, 15, 20, 30, 50]);
    addTier(LevelTier.student, [75, 100, 150, 200, 250, 300]);
    addTier(LevelTier.mnemonist, [400, 500, 700, 1000, 1500]);
    addTier(LevelTier.expert, [2000, 3000, 5000]);
    addTier(LevelTier.master, [100, 300, 500], kinds: [
      LevelChallengeKind.speedMemorize,
      LevelChallengeKind.speedMemorize,
      LevelChallengeKind.speedMemorize,
    ]);
    n++;
    out.add(TrainerLevelDef(
      id: 'numbers_$n',
      path: LevelPath.numbers,
      tier: LevelTier.master,
      displayNumber: n,
      elementCount: 150,
      requiredAccuracy: 92,
      kind: LevelChallengeKind.randomRecall,
      titleOverride: const {
        'en': 'Random Recall',
        'ru': 'Случайное воспроизведение',
        'de': 'Zufälliges Abrufen',
      },
    ));
    n++;
    out.add(TrainerLevelDef(
      id: 'numbers_$n',
      path: LevelPath.numbers,
      tier: LevelTier.master,
      displayNumber: n,
      elementCount: 200,
      requiredAccuracy: 98,
      kind: LevelChallengeKind.accuracyChallenge,
      titleOverride: const {
        'en': 'Accuracy Challenge',
        'ru': 'Точность',
        'de': 'Genauigkeit',
      },
    ));
    return out;
  }

  static int _speedMemSec(int digits) {
    if (digits <= 100) return 300;
    if (digits <= 300) return 900;
    return 1500;
  }

  static List<TrainerLevelDef> _buildImages() {
    final out = <TrainerLevelDef>[];
    var n = 0;
    void add(LevelTier tier, int count, {LevelChallengeKind kind = LevelChallengeKind.none}) {
      n++;
      out.add(TrainerLevelDef(
        id: 'images_$n',
        path: LevelPath.images,
        tier: tier,
        displayNumber: n,
        elementCount: count,
        requiredAccuracy: accuracyForTier(tier),
        kind: kind,
      ));
    }

    for (final c in [5, 10, 15, 20]) add(LevelTier.beginner, c);
    for (final c in [30, 50, 75]) add(LevelTier.student, c);
    for (final c in [100, 150, 200]) add(LevelTier.mnemonist, c);
    add(LevelTier.expert, 100, kind: LevelChallengeKind.abstractImages);
    add(LevelTier.expert, 75, kind: LevelChallengeKind.fastReveal);
    add(LevelTier.expert, 50, kind: LevelChallengeKind.multiImageScreen);
    return out;
  }

  static List<TrainerLevelDef> _buildCards() {
    final specs = <(LevelTier, int, LevelChallengeKind)>[
      (LevelTier.beginner, 5, LevelChallengeKind.none),
      (LevelTier.beginner, 10, LevelChallengeKind.none),
      (LevelTier.beginner, 20, LevelChallengeKind.none),
      (LevelTier.beginner, 26, LevelChallengeKind.none),
      (LevelTier.beginner, 52, LevelChallengeKind.none),
      (LevelTier.student, 52, LevelChallengeKind.timedDeck),
      (LevelTier.student, 52, LevelChallengeKind.speedDeck),
      (LevelTier.mnemonist, 52, LevelChallengeKind.dualCardEncoding),
      (LevelTier.expert, 52, LevelChallengeKind.competitionSimulation),
    ];
    var n = 0;
    return [
      for (final s in specs)
        TrainerLevelDef(
          id: 'cards_${++n}',
          path: LevelPath.cards,
          tier: s.$1,
          displayNumber: n,
          elementCount: s.$2,
          requiredAccuracy: accuracyForTier(s.$1),
          kind: s.$3,
          memTimeLimitSec: s.$3 == LevelChallengeKind.timedDeck ? 600 : null,
        ),
    ];
  }

  static List<TrainerLevelDef> _buildWords() {
    final tiers = <LevelTier, List<int>>{
      LevelTier.beginner: [5, 10, 20, 30],
      LevelTier.student: [50, 75, 100],
      LevelTier.mnemonist: [150, 200],
      LevelTier.expert: [250, 300, 400],
    };
    final out = <TrainerLevelDef>[];
    var n = 0;
    for (final tier in [
      LevelTier.beginner,
      LevelTier.student,
      LevelTier.mnemonist,
      LevelTier.expert,
    ]) {
      for (final count in tiers[tier]!) {
        n++;
        out.add(TrainerLevelDef(
          id: 'words_$n',
          path: LevelPath.words,
          tier: tier,
          displayNumber: n,
          elementCount: count,
          requiredAccuracy: accuracyForTier(tier),
        ));
      }
    }
    return out;
  }

  static List<TrainerLevelDef> _buildFaces() {
    final counts = [5, 10, 20, 30, 50, 75, 100];
    return [
      for (var i = 0; i < counts.length; i++)
        TrainerLevelDef(
          id: 'faces_${i + 1}',
          path: LevelPath.faces,
          tier: i < 4
              ? LevelTier.beginner
              : i < 6
                  ? LevelTier.student
                  : LevelTier.mnemonist,
          displayNumber: i + 1,
          elementCount: counts[i],
          requiredAccuracy: accuracyForTier(
            i < 4
                ? LevelTier.beginner
                : i < 6
                    ? LevelTier.student
                    : LevelTier.mnemonist,
          ),
        ),
    ];
  }

  static List<(LevelTier, String)> tiersForPath(LevelPath path) {
    final hasMaster = path == LevelPath.numbers;
    final tiers = <(LevelTier, String)>[
      (LevelTier.beginner, '🌱'),
      (LevelTier.student, '⚡'),
      (LevelTier.mnemonist, '🧠'),
      (LevelTier.expert, '🔥'),
    ];
    if (hasMaster) tiers.add((LevelTier.master, '👑'));
    return tiers;
  }

  static List<TrainerLevelDef> levelsInTier(LevelPath path, LevelTier tier) {
    return levelsForPath(path).where((l) => l.tier == tier).toList();
  }
}
