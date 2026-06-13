import 'package:flutter/material.dart';

import '../recovered_app.dart' show AppLanguage;

/// Declarative vertical curriculum for Academy (display order only).
/// Lesson prerequisites and completion remain in [SkillTreeScreen] logic.
class AcademySectionDefinition {
  const AcademySectionDefinition({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.lessonNodeIds,
    this.isPlaceholder = false,
    this.unlockAfterNodeIds = const <String>[],
  });

  final String id;
  final Map<AppLanguage, String> title;
  final Map<AppLanguage, String> subtitle;
  final IconData icon;

  /// Skill node ids from `_kSkillTree` (same strings as [SkillNode.id]).
  final List<String> lessonNodeIds;

  /// Section shown with empty-state copy (no lesson rows).
  final bool isPlaceholder;

  /// All listed skill nodes must be completed before the section opens.
  final List<String> unlockAfterNodeIds;

  int lessonCount() => lessonNodeIds.length;
}

String academyTranslate(
  Map<AppLanguage, String> map,
  AppLanguage lang,
) {
  return map[lang] ?? map[AppLanguage.en] ?? map.values.first;
}

/// Fixed order: one vertical path, Duolingo-style chapters.
const List<AcademySectionDefinition> kAcademySections =
    <AcademySectionDefinition>[
  AcademySectionDefinition(
    id: 'foundation',
    title: {
      AppLanguage.ru: 'Основа',
      AppLanguage.en: 'Foundation',
      AppLanguage.de: 'Grundlagen',
    },
    subtitle: {
      AppLanguage.ru: 'Мнемотехника, образы, связи',
      AppLanguage.en: 'Mnemonics, imagery, linking',
      AppLanguage.de: 'Mnemonik, Bilder, Verknüpfungen',
    },
    icon: Icons.psychology_alt_outlined,
    lessonNodeIds: <String>[
      'm1',
      'intro1',
      'intro2',
      'm2',
      'task_strawberry',
      'image_types',
      'm3',
      'task_association',
    ],
  ),
  AcademySectionDefinition(
    id: 'memory_architecture',
    title: {
      AppLanguage.ru: 'Архитектура памяти',
      AppLanguage.en: 'Memory architecture',
      AppLanguage.de: 'Gedächtnisarchitektur',
    },
    subtitle: {
      AppLanguage.ru: 'Дворец памяти',
      AppLanguage.en: 'Memory palace',
      AppLanguage.de: 'Gedächtnispalast',
    },
    icon: Icons.account_balance_outlined,
    unlockAfterNodeIds: <String>['m3', 'task_association'],
    lessonNodeIds: <String>[
      'm4',
      'palace_create',
      'palace_place_images',
      'palace_mistakes',
    ],
  ),
  AcademySectionDefinition(
    id: 'numbers',
    title: {
      AppLanguage.ru: 'Числа',
      AppLanguage.en: 'Numbers',
      AppLanguage.de: 'Zahlen',
    },
    subtitle: {
      AppLanguage.ru: 'Система и длинные последовательности',
      AppLanguage.en: 'Coding system and long sequences',
      AppLanguage.de: 'System und lange Folgen',
    },
    icon: Icons.calculate_outlined,
    lessonNodeIds: <String>[
      'numbers_intro',
      'disc_numbers',
      'numbers_speed',
      'numbers_long',
    ],
  ),
  AcademySectionDefinition(
    id: 'pictures',
    title: {
      AppLanguage.ru: 'Картинки',
      AppLanguage.en: 'Pictures',
      AppLanguage.de: 'Bilder',
    },
    subtitle: {
      AppLanguage.ru: 'Запоминание изображений',
      AppLanguage.en: 'Memorizing images',
      AppLanguage.de: 'Bilder merken',
    },
    icon: Icons.image_outlined,
    lessonNodeIds: <String>[
      'disc_imagery',
      'imagery_main_object',
      'imagery_encoding',
      'imagery_picture_errors',
    ],
  ),
  AcademySectionDefinition(
    id: 'cards',
    title: {
      AppLanguage.ru: 'Карты',
      AppLanguage.en: 'Cards',
      AppLanguage.de: 'Karten',
    },
    subtitle: {
      AppLanguage.ru: 'Колоды и системы',
      AppLanguage.en: 'Decks and systems',
      AppLanguage.de: 'Decks und Systeme',
    },
    icon: Icons.style_rounded,
    lessonNodeIds: <String>[
      'disc_cards',
      'cards_suit_categories',
      'cards_major_system',
      'cards_pao',
      'cards_practice_speed',
    ],
  ),
  AcademySectionDefinition(
    id: 'words',
    title: {
      AppLanguage.ru: 'Слова',
      AppLanguage.en: 'Words',
      AppLanguage.de: 'Wörter',
    },
    subtitle: {
      AppLanguage.ru: 'Лексика и кодирование',
      AppLanguage.en: 'Vocabulary and coding',
      AppLanguage.de: 'Wortschatz und Kodierung',
    },
    icon: Icons.short_text_rounded,
    lessonNodeIds: <String>[
      'disc_words',
      'words_abstract',
      'words_fast_coding',
    ],
  ),
  AcademySectionDefinition(
    id: 'languages',
    title: {
      AppLanguage.ru: 'Языки',
      AppLanguage.en: 'Languages',
      AppLanguage.de: 'Sprachen',
    },
    subtitle: {
      AppLanguage.ru: 'Иностранные языки',
      AppLanguage.en: 'Foreign languages',
      AppLanguage.de: 'Fremdsprachen',
    },
    icon: Icons.translate_rounded,
    lessonNodeIds: <String>['disc_languages'],
  ),
  AcademySectionDefinition(
    id: 'texts',
    title: {
      AppLanguage.ru: 'Тексты',
      AppLanguage.en: 'Texts',
      AppLanguage.de: 'Texte',
    },
    subtitle: {
      AppLanguage.ru: 'Линейный дворец и техники',
      AppLanguage.en: 'Linear palace and techniques',
      AppLanguage.de: 'Linearer Palast und Techniken',
    },
    icon: Icons.article_outlined,
    lessonNodeIds: <String>[
      'disc_texts',
      'texts_l2',
      'texts_l3',
      'texts_l4',
    ],
  ),
  AcademySectionDefinition(
    id: 'speed',
    title: {
      AppLanguage.ru: 'Скорость',
      AppLanguage.en: 'Speed',
      AppLanguage.de: 'Tempo',
    },
    subtitle: {
      AppLanguage.ru: 'Темп и работа на время',
      AppLanguage.en: 'Pace and timed drills',
      AppLanguage.de: 'Tempo und Zeitdrill',
    },
    icon: Icons.speed_rounded,
    lessonNodeIds: <String>[
      'numbers_speed',
      'numbers_clock',
    ],
  ),
  AcademySectionDefinition(
    id: 'practice',
    title: {
      AppLanguage.ru: 'Практика',
      AppLanguage.en: 'Practice',
      AppLanguage.de: 'Praxis',
    },
    subtitle: {
      AppLanguage.ru: 'Дополнительные тренировки',
      AppLanguage.en: 'Extra drills',
      AppLanguage.de: 'Zusätzliches Training',
    },
    icon: Icons.fitness_center_rounded,
    lessonNodeIds: <String>[],
    isPlaceholder: true,
  ),
  AcademySectionDefinition(
    id: 'endgame',
    title: {
      AppLanguage.ru: 'Endgame',
      AppLanguage.en: 'Endgame',
      AppLanguage.de: 'Endgame',
    },
    subtitle: {
      AppLanguage.ru: 'Финальные вызовы',
      AppLanguage.en: 'Final challenges',
      AppLanguage.de: 'Finale Herausforderungen',
    },
    icon: Icons.emoji_events_outlined,
    lessonNodeIds: <String>[
      'texts_l5',
    ],
  ),
];
