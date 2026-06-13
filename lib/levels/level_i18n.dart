import '../recovered_app.dart' show AppLanguage, appLanguage;
import 'level_definitions.dart';

String levelTxt(Map<AppLanguage, String> m) =>
    m[appLanguage.value] ?? m[AppLanguage.ru] ?? m.values.first;

String tierLabel(LevelTier tier) {
  switch (tier) {
    case LevelTier.beginner:
      return levelTxt({
        AppLanguage.ru: 'Новичок',
        AppLanguage.en: 'Beginner',
        AppLanguage.de: 'Anfänger',
      });
    case LevelTier.student:
      return levelTxt({
        AppLanguage.ru: 'Студент',
        AppLanguage.en: 'Student',
        AppLanguage.de: 'Schüler',
      });
    case LevelTier.mnemonist:
      return levelTxt({
        AppLanguage.ru: 'Мнемонист',
        AppLanguage.en: 'Mnemonist',
        AppLanguage.de: 'Mnemonist',
      });
    case LevelTier.expert:
      return levelTxt({
        AppLanguage.ru: 'Эксперт',
        AppLanguage.en: 'Expert',
        AppLanguage.de: 'Experte',
      });
    case LevelTier.master:
      return levelTxt({
        AppLanguage.ru: 'Мастер',
        AppLanguage.en: 'Master',
        AppLanguage.de: 'Meister',
      });
  }
}

String pathTitle(LevelPath path) {
  switch (path) {
    case LevelPath.numbers:
      return levelTxt({
        AppLanguage.ru: 'УРОВНИ · ЧИСЛА',
        AppLanguage.en: 'LEVELS · NUMBERS',
        AppLanguage.de: 'STUFEN · ZAHLEN',
      });
    case LevelPath.images:
      return levelTxt({
        AppLanguage.ru: 'УРОВНИ · ОБРАЗЫ',
        AppLanguage.en: 'LEVELS · IMAGES',
        AppLanguage.de: 'STUFEN · BILDER',
      });
    case LevelPath.cards:
      return levelTxt({
        AppLanguage.ru: 'УРОВНИ · КАРТЫ',
        AppLanguage.en: 'LEVELS · CARDS',
        AppLanguage.de: 'STUFEN · KARTEN',
      });
    case LevelPath.words:
      return levelTxt({
        AppLanguage.ru: 'УРОВНИ · СЛОВА',
        AppLanguage.en: 'LEVELS · WORDS',
        AppLanguage.de: 'STUFEN · WÖRTER',
      });
    case LevelPath.faces:
      return levelTxt({
        AppLanguage.ru: 'УРОВНИ · ЛИЦА',
        AppLanguage.en: 'LEVELS · FACES',
        AppLanguage.de: 'STUFEN · GESICHTER',
      });
  }
}

String elementUnitLabel(LevelPath path, int count) {
  switch (path) {
    case LevelPath.numbers:
      return levelTxt({
        AppLanguage.ru: '$count цифр',
        AppLanguage.en: '$count digits',
        AppLanguage.de: '$count Ziffern',
      });
    case LevelPath.images:
      return levelTxt({
        AppLanguage.ru: '$count образов',
        AppLanguage.en: '$count images',
        AppLanguage.de: '$count Bilder',
      });
    case LevelPath.cards:
      return levelTxt({
        AppLanguage.ru: '$count карт',
        AppLanguage.en: '$count cards',
        AppLanguage.de: '$count Karten',
      });
    case LevelPath.words:
      return levelTxt({
        AppLanguage.ru: '$count слов',
        AppLanguage.en: '$count words',
        AppLanguage.de: '$count Wörter',
      });
    case LevelPath.faces:
      return levelTxt({
        AppLanguage.ru: '$count лиц',
        AppLanguage.en: '$count faces',
        AppLanguage.de: '$count Gesichter',
      });
  }
}

String levelGoalTitle(TrainerLevelDef level) {
  if (level.titleOverride != null) {
    final lang = appLanguage.value.name;
    return level.titleOverride![lang] ??
        level.titleOverride!['en'] ??
        level.titleOverride!.values.first;
  }
  switch (level.kind) {
    case LevelChallengeKind.speedMemorize:
      return levelTxt({
        AppLanguage.ru: 'Скорость · ${level.elementCount}',
        AppLanguage.en: 'Speed · ${level.elementCount}',
        AppLanguage.de: 'Tempo · ${level.elementCount}',
      });
    case LevelChallengeKind.abstractImages:
      return levelTxt({
        AppLanguage.ru: 'Абстрактные образы',
        AppLanguage.en: 'Abstract images',
        AppLanguage.de: 'Abstrakte Bilder',
      });
    case LevelChallengeKind.fastReveal:
      return levelTxt({
        AppLanguage.ru: 'Быстрый показ',
        AppLanguage.en: 'Fast reveal',
        AppLanguage.de: 'Schnelle Anzeige',
      });
    case LevelChallengeKind.multiImageScreen:
      return levelTxt({
        AppLanguage.ru: 'Несколько на экране',
        AppLanguage.en: 'Multi-image screen',
        AppLanguage.de: 'Mehrere pro Bildschirm',
      });
    case LevelChallengeKind.timedDeck:
      return levelTxt({
        AppLanguage.ru: 'Колода на время',
        AppLanguage.en: 'Timed deck',
        AppLanguage.de: 'Koloda mit Zeit',
      });
    case LevelChallengeKind.speedDeck:
      return levelTxt({
        AppLanguage.ru: 'Скоростная колода',
        AppLanguage.en: 'Speed deck',
        AppLanguage.de: 'Tempo-Koloda',
      });
    case LevelChallengeKind.dualCardEncoding:
      return levelTxt({
        AppLanguage.ru: 'Двойное кодирование',
        AppLanguage.en: 'Dual card encoding',
        AppLanguage.de: 'Doppel-Kodierung',
      });
    case LevelChallengeKind.competitionSimulation:
      return levelTxt({
        AppLanguage.ru: 'Соревновательный режим',
        AppLanguage.en: 'Competition simulation',
        AppLanguage.de: 'Wettkampf-Simulation',
      });
    default:
      return levelTxt({
        AppLanguage.ru: 'Запомнить ${elementUnitLabel(level.path, level.elementCount)}',
        AppLanguage.en: 'Memorize ${elementUnitLabel(level.path, level.elementCount)}',
        AppLanguage.de: '${elementUnitLabel(level.path, level.elementCount)} merken',
      });
  }
}
