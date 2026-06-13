import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/core/ui_feedback.dart';
import '../premium/premium_screen.dart';
import '../recovered_app.dart'
    show
        AppLanguage,
        AppPalette,
        AppTexts,
        appAccentColor,
        appLanguage,
        appPalette;
import 'imagery_lesson.dart';
import 'linking_lesson.dart';
import 'association_trainer_screen.dart';
import 'memory_palace_lesson.dart';
import 'mnemonics_extras_lesson.dart';
import 'mnemonics_intro_lesson.dart';
import 'number_coding_lesson.dart';
import 'numbers_intro_lesson.dart';
import 'numbers_extended_lessons.dart';
import 'imagery_track_lessons.dart';
import 'cards_track_lessons.dart';
import 'words_track_lessons.dart';
import 'text_memorization_lessons.dart';

import '../app_creator.dart';
import '../premium/premium_service.dart';
import 'academy_curriculum.dart';
import 'academy_editor_screen.dart';
import 'academy_remote_service.dart';
import 'academy_section_layout.dart';
import 'academy_icon_registry.dart';
import 'custom_academy_lesson_screen.dart';

const MethodChannel _kAcademyDisplayChannel = MethodChannel('mneem/academy_display');

// =====================================================================
//  ACADEMY — вертикальный путь, expandable секции, ThemeData + accent.
//  Уроки: [_kSkillTree] + [_openLesson]. Прогресс: SharedPreferences.
// =====================================================================

enum SkillBranch {
  core,
  intro,
  imagery,
  palace,
  numbers,
  disciplineImagery,
  cards,
  words,
  languages,
  texts,
}

enum SkillNodeStatus { locked, unlocked, completed }

class SkillNode {
  const SkillNode({
    required this.id,
    required this.title,
    required this.icon,
    required this.xFraction,
    required this.row,
    required this.branch,
    required this.isMain,
    required this.parentIds,
    required this.status,
  });

  final String id;
  final Map<AppLanguage, String> title;
  final IconData icon;

  /// Горизонтальная позиция как доля от доступной ширины (0..1).
  final double xFraction;

  /// Вертикальная позиция в «строках» (умножается на [_kRowHeight]).
  final double row;

  final SkillBranch branch;
  final bool isMain;
  final List<String> parentIds;
  final SkillNodeStatus status;
}

const double _kLeftBranch = 0.22;
const double _kRightBranch = 0.78;

/// Правее обычной правой ветки — для узла «Типы образов» у m2.
const double _kRightBranchImageryTypes = 0.90;

/// Колонки шести направлений после «Локи» (слева направо).
/// Равномерный шаг ~0.17, чтобы подписи в `_kSlotWidth` не смешивались.
const double _kDiscNumbers = 0.07;
const double _kDiscImageryTrack = 0.24;
const double _kDiscCards = 0.41;
const double _kDiscWords = 0.58;
const double _kDiscLanguages = 0.75;
const double _kDiscTextsRoot = 0.91;

const double _kCenter = 0.5;
// Лёгкий зигзаг главного пути: соседние main-узлы смещены чуть вправо/влево
// от центра, чтобы дерево не выглядело как прямая линия.
const double _kMainRight = 0.66;
const double _kMainLeft = 0.34;
const String _prefsSkillTreeCompletedKey = 'academy_completed_nodes_v1';

/// Столбцы без собственного урока — только «ворота» после дворца (см. [SkillNode.id]).
const Set<String> _kStemDisciplineIds = <String>{
  'disc_languages',
};

// ---------------------------------------------------------------------
//  Декларативное дерево. Контента уроков нет — только структура и
//  заголовки. Пройденность пока хардкод (для демо UI), позже
//  подменяется реальным сервисом прогресса.
// ---------------------------------------------------------------------
const List<SkillNode> _kSkillTree = <SkillNode>[
  // Главный путь
  SkillNode(
    id: 'm1',
    title: {
      AppLanguage.ru: 'Что такое мнемотехника',
      AppLanguage.en: 'What is mnemonics',
      AppLanguage.de: 'Was ist Mnemotechnik',
    },
    icon: Icons.psychology_outlined,
    xFraction: _kCenter,
    row: 2,
    branch: SkillBranch.core,
    isMain: true,
    parentIds: [],
    status: SkillNodeStatus.completed,
  ),
  SkillNode(
    id: 'm2',
    title: {
      AppLanguage.ru: 'Образы',
      AppLanguage.en: 'Imagery',
      AppLanguage.de: 'Bilder',
    },
    icon: Icons.palette_outlined,
    xFraction: _kMainRight,
    row: 4,
    branch: SkillBranch.core,
    isMain: true,
    parentIds: ['m1'],
    status: SkillNodeStatus.unlocked,
  ),
  SkillNode(
    id: 'm3',
    title: {
      AppLanguage.ru: 'Связи',
      AppLanguage.en: 'Linking',
      AppLanguage.de: 'Verbinden',
    },
    icon: Icons.link_rounded,
    xFraction: _kMainLeft,
    row: 6,
    branch: SkillBranch.core,
    isMain: true,
    parentIds: ['m2'],
    status: SkillNodeStatus.unlocked,
  ),
  SkillNode(
    id: 'm4',
    title: {
      AppLanguage.ru: 'Дворец',
      AppLanguage.en: 'Memory Palace',
      AppLanguage.de: 'Gedächtnispalast',
    },
    icon: Icons.account_balance_outlined,
    xFraction: _kCenter,
    row: 8,
    branch: SkillBranch.core,
    isMain: true,
    parentIds: ['m3', 'task_association'],
    status: SkillNodeStatus.locked,
  ),

  // Шесть параллельных треков (от каждого позже можно вешать подветки).
  SkillNode(
    id: 'numbers_intro',
    title: {
      AppLanguage.ru: 'Введение в числа',
      AppLanguage.en: 'Introduction to numbers',
      AppLanguage.de: 'Einführung in Zahlen',
    },
    icon: Icons.calculate_outlined,
    xFraction: _kDiscNumbers,
    row: 11.35,
    branch: SkillBranch.numbers,
    isMain: true,
    parentIds: ['palace_mistakes'],
    status: SkillNodeStatus.locked,
  ),
  // Первый «столбцовый» урок после введения — система кодирования.
  SkillNode(
    id: 'disc_numbers',
    title: {
      AppLanguage.ru: 'Система кодирования',
      AppLanguage.en: 'Number coding',
      AppLanguage.de: 'Zahlencodierung',
    },
    icon: Icons.vpn_key_rounded,
    xFraction: _kDiscNumbers,
    row: 12.05,
    branch: SkillBranch.numbers,
    isMain: true,
    parentIds: ['numbers_intro'],
    status: SkillNodeStatus.locked,
  ),
  SkillNode(
    id: 'disc_imagery',
    title: {
      AppLanguage.ru: 'Картинки · основы',
      AppLanguage.en: 'Pictures · basics',
      AppLanguage.de: 'Bilder · Grundlagen',
    },
    icon: Icons.image_outlined,
    xFraction: _kDiscImageryTrack,
    row: 12.05,
    branch: SkillBranch.disciplineImagery,
    isMain: true,
    parentIds: ['palace_mistakes'],
    status: SkillNodeStatus.locked,
  ),
  SkillNode(
    id: 'disc_cards',
    title: {
      AppLanguage.ru: 'Введение в карты',
      AppLanguage.en: 'Cards introduction',
      AppLanguage.de: 'Einführung Karten',
    },
    icon: Icons.style_rounded,
    xFraction: _kDiscCards,
    row: 12.05,
    branch: SkillBranch.cards,
    isMain: true,
    parentIds: ['palace_mistakes'],
    status: SkillNodeStatus.locked,
  ),
  SkillNode(
    id: 'disc_words',
    title: {
      AppLanguage.ru: 'Введение · слова',
      AppLanguage.en: 'Words introduction',
      AppLanguage.de: 'Einführung Wörter',
    },
    icon: Icons.short_text_rounded,
    xFraction: _kDiscWords,
    row: 12.05,
    branch: SkillBranch.words,
    isMain: true,
    parentIds: ['palace_mistakes'],
    status: SkillNodeStatus.locked,
  ),
  SkillNode(
    id: 'disc_languages',
    title: {
      AppLanguage.ru: 'Иностранные языки',
      AppLanguage.en: 'Languages',
      AppLanguage.de: 'Fremdsprachen',
    },
    icon: Icons.translate_rounded,
    xFraction: _kDiscLanguages,
    row: 12.05,
    branch: SkillBranch.languages,
    isMain: true,
    parentIds: ['palace_mistakes'],
    status: SkillNodeStatus.locked,
  ),
  SkillNode(
    id: 'disc_texts',
    title: {
      AppLanguage.ru: 'Подготовка · линейный дворец',
      AppLanguage.en: 'Prep · linear palace',
      AppLanguage.de: 'Vorbereitung · linearer Palast',
    },
    icon: Icons.route_rounded,
    xFraction: _kDiscTextsRoot,
    row: 12.05,
    branch: SkillBranch.texts,
    isMain: true,
    parentIds: ['palace_mistakes'],
    status: SkillNodeStatus.locked,
  ),
  SkillNode(
    id: 'numbers_speed',
    title: {
      AppLanguage.ru: 'Скорость запоминания',
      AppLanguage.en: 'Memorization speed',
      AppLanguage.de: 'Merkgeschwindigkeit',
    },
    icon: Icons.speed_rounded,
    xFraction: _kDiscNumbers,
    row: 14.15,
    branch: SkillBranch.numbers,
    isMain: false,
    parentIds: ['disc_numbers'],
    status: SkillNodeStatus.locked,
  ),
  SkillNode(
    id: 'numbers_long',
    title: {
      AppLanguage.ru: 'Длинные числа',
      AppLanguage.en: 'Long numbers',
      AppLanguage.de: 'Lange Zahlen',
    },
    icon: Icons.straighten_rounded,
    xFraction: _kDiscNumbers,
    row: 15.45,
    branch: SkillBranch.numbers,
    isMain: false,
    parentIds: ['numbers_speed'],
    status: SkillNodeStatus.locked,
  ),
  SkillNode(
    id: 'numbers_clock',
    title: {
      AppLanguage.ru: 'Числа на время',
      AppLanguage.en: 'Against the clock',
      AppLanguage.de: 'Auf Zeit',
    },
    icon: Icons.timer_rounded,
    xFraction: _kDiscNumbers,
    row: 16.75,
    branch: SkillBranch.numbers,
    isMain: false,
    parentIds: ['numbers_long'],
    status: SkillNodeStatus.locked,
  ),
  SkillNode(
    id: 'imagery_main_object',
    title: {
      AppLanguage.ru: 'Главный объект',
      AppLanguage.en: 'Main object',
      AppLanguage.de: 'Hauptobjekt',
    },
    icon: Icons.center_focus_strong_rounded,
    xFraction: _kDiscImageryTrack,
    row: 13.65,
    branch: SkillBranch.disciplineImagery,
    isMain: false,
    parentIds: ['disc_imagery'],
    status: SkillNodeStatus.locked,
  ),
  SkillNode(
    id: 'imagery_encoding',
    title: {
      AppLanguage.ru: 'Кодировка',
      AppLanguage.en: 'Encoding',
      AppLanguage.de: 'Kodierung',
    },
    icon: Icons.transform_rounded,
    xFraction: _kDiscImageryTrack,
    row: 14.95,
    branch: SkillBranch.disciplineImagery,
    isMain: false,
    parentIds: ['imagery_main_object'],
    status: SkillNodeStatus.locked,
  ),
  SkillNode(
    id: 'imagery_picture_errors',
    title: {
      AppLanguage.ru: 'Типичные ошибки',
      AppLanguage.en: 'Common mistakes',
      AppLanguage.de: 'Typische Fehler',
    },
    icon: Icons.warning_amber_rounded,
    xFraction: _kDiscImageryTrack,
    row: 16.25,
    branch: SkillBranch.disciplineImagery,
    isMain: false,
    parentIds: ['imagery_encoding'],
    status: SkillNodeStatus.locked,
  ),
  SkillNode(
    id: 'cards_suit_categories',
    title: {
      AppLanguage.ru: 'Категории мастей',
      AppLanguage.en: 'Suit categories',
      AppLanguage.de: 'Farbkategorien',
    },
    icon: Icons.category_rounded,
    xFraction: _kDiscCards,
    row: 13.65,
    branch: SkillBranch.cards,
    isMain: false,
    parentIds: ['disc_cards'],
    status: SkillNodeStatus.locked,
  ),
  SkillNode(
    id: 'cards_major_system',
    title: {
      AppLanguage.ru: 'Major System',
      AppLanguage.en: 'Major System',
      AppLanguage.de: 'Major-System',
    },
    icon: Icons.pin_outlined,
    xFraction: _kDiscCards,
    row: 14.95,
    branch: SkillBranch.cards,
    isMain: false,
    parentIds: ['cards_suit_categories'],
    status: SkillNodeStatus.locked,
  ),
  SkillNode(
    id: 'cards_pao',
    title: {
      AppLanguage.ru: 'PAO-система',
      AppLanguage.en: 'PAO system',
      AppLanguage.de: 'PAO-System',
    },
    icon: Icons.groups_rounded,
    xFraction: _kDiscCards,
    row: 16.25,
    branch: SkillBranch.cards,
    isMain: false,
    parentIds: ['cards_major_system'],
    status: SkillNodeStatus.locked,
  ),
  SkillNode(
    id: 'cards_practice_speed',
    title: {
      AppLanguage.ru: 'Практика и скорость',
      AppLanguage.en: 'Practice and speed',
      AppLanguage.de: 'Praxis und Tempo',
    },
    icon: Icons.fitness_center_rounded,
    xFraction: _kDiscCards,
    row: 17.55,
    branch: SkillBranch.cards,
    isMain: false,
    parentIds: ['cards_pao'],
    status: SkillNodeStatus.locked,
  ),
  SkillNode(
    id: 'words_abstract',
    title: {
      AppLanguage.ru: 'Абстрактные слова',
      AppLanguage.en: 'Abstract words',
      AppLanguage.de: 'Abstrakte Wörter',
    },
    icon: Icons.psychology_outlined,
    xFraction: _kDiscWords,
    row: 13.65,
    branch: SkillBranch.words,
    isMain: false,
    parentIds: ['disc_words'],
    status: SkillNodeStatus.locked,
  ),
  SkillNode(
    id: 'words_fast_coding',
    title: {
      AppLanguage.ru: 'Быстрое кодирование',
      AppLanguage.en: 'Fast coding',
      AppLanguage.de: 'Schnelles Kodieren',
    },
    icon: Icons.bolt_rounded,
    xFraction: _kDiscWords,
    row: 14.95,
    branch: SkillBranch.words,
    isMain: false,
    parentIds: ['words_abstract'],
    status: SkillNodeStatus.locked,
  ),

  // Ветка: INTRO — два независимых мини-урока «крыльями» от m1.
  // intro1 слева (Что она может), intro2 справа (История).
  SkillNode(
    id: 'intro1',
    title: {
      AppLanguage.ru: 'Что она может',
      AppLanguage.en: 'What it can do',
      AppLanguage.de: 'Was sie kann',
    },
    icon: Icons.bolt_rounded,
    xFraction: _kLeftBranch,
    row: 1.6,
    branch: SkillBranch.intro,
    isMain: false,
    parentIds: ['m1'],
    status: SkillNodeStatus.unlocked,
  ),
  SkillNode(
    id: 'intro2',
    title: {
      AppLanguage.ru: 'История',
      AppLanguage.en: 'History',
      AppLanguage.de: 'Geschichte',
    },
    icon: Icons.history_edu_rounded,
    xFraction: _kRightBranch,
    row: 1.6,
    branch: SkillBranch.intro,
    isMain: false,
    parentIds: ['m1'],
    status: SkillNodeStatus.unlocked,
  ),

  // Ветка: IMAGERY — два независимых мини-урока «крыльями» от m2.
  // Слева — практическое задание, справа — теория-справочник.
  SkillNode(
    id: 'task_strawberry',
    title: {
      AppLanguage.ru: 'Задание · Клубника',
      AppLanguage.en: 'Task · Strawberry',
      AppLanguage.de: 'Übung · Erdbeere',
    },
    icon: Icons.psychology_alt_outlined,
    xFraction: _kLeftBranch,
    row: 3.6,
    branch: SkillBranch.imagery,
    isMain: false,
    parentIds: ['m2'],
    status: SkillNodeStatus.unlocked,
  ),
  SkillNode(
    id: 'image_types',
    title: {
      AppLanguage.ru: 'Типы образов',
      AppLanguage.en: 'Image types',
      AppLanguage.de: 'Bildarten',
    },
    icon: Icons.category_outlined,
    xFraction: _kRightBranchImageryTypes,
    row: 3.6,
    branch: SkillBranch.imagery,
    isMain: false,
    parentIds: ['m2'],
    status: SkillNodeStatus.unlocked,
  ),
  SkillNode(
    id: 'task_association',
    title: {
      AppLanguage.ru: 'Задание 2 · Связки',
      AppLanguage.en: 'Task 2 · Linking',
      AppLanguage.de: 'Übung 2 · Verknüpfen',
    },
    icon: Icons.device_hub_outlined,
    xFraction: _kLeftBranch,
    row: 6.9,
    branch: SkillBranch.imagery,
    isMain: false,
    parentIds: ['m3'],
    status: SkillNodeStatus.unlocked,
  ),

  // Ветка: PALACE — три компактных доп-урока «лучами» расходятся от m4.
  // Визуально все три цепляются прямо к Дворцу (parentIds=['m4']),
  // открываются строго по очереди через _prerequisitesFor.
  SkillNode(
    id: 'palace_create',
    title: {
      AppLanguage.ru: 'Создать дворец',
      AppLanguage.en: 'Create a palace',
      AppLanguage.de: 'Palast erstellen',
    },
    icon: Icons.foundation_outlined,
    xFraction: _kLeftBranch,
    row: 8.7,
    branch: SkillBranch.palace,
    isMain: false,
    parentIds: ['m4'],
    status: SkillNodeStatus.locked,
  ),
  SkillNode(
    id: 'palace_place_images',
    title: {
      AppLanguage.ru: 'Размещать образы',
      AppLanguage.en: 'Place images',
      AppLanguage.de: 'Bilder platzieren',
    },
    icon: Icons.add_location_alt_outlined,
    xFraction: 0.34,
    row: 9.7,
    branch: SkillBranch.palace,
    isMain: false,
    parentIds: ['m4'],
    status: SkillNodeStatus.locked,
  ),
  SkillNode(
    id: 'palace_mistakes',
    title: {
      AppLanguage.ru: 'Ошибки в локи',
      AppLanguage.en: 'Loci mistakes',
      AppLanguage.de: 'Loci-Fehler',
    },
    icon: Icons.error_outline_rounded,
    xFraction: 0.66,
    row: 9.7,
    branch: SkillBranch.palace,
    isMain: false,
    parentIds: ['m4'],
    status: SkillNodeStatus.locked,
  ),

  SkillNode(
    id: 'texts_l2',
    title: {
      AppLanguage.ru: 'Техника первых букв',
      AppLanguage.en: 'First letters',
      AppLanguage.de: 'Anfangsbuchstaben',
    },
    icon: Icons.text_fields_rounded,
    xFraction: _kDiscTextsRoot,
    row: 13.35,
    branch: SkillBranch.texts,
    isMain: false,
    parentIds: ['disc_texts'],
    status: SkillNodeStatus.locked,
  ),
  SkillNode(
    id: 'texts_l3',
    title: {
      AppLanguage.ru: 'Образы и связки',
      AppLanguage.en: 'Keywords · fillers',
      AppLanguage.de: 'Schlüsselbilder',
    },
    icon: Icons.hub_rounded,
    xFraction: _kDiscTextsRoot,
    row: 14.65,
    branch: SkillBranch.texts,
    isMain: false,
    parentIds: ['texts_l2'],
    status: SkillNodeStatus.locked,
  ),
  SkillNode(
    id: 'texts_l4',
    title: {
      AppLanguage.ru: 'Построчный метод',
      AppLanguage.en: 'Line-by-line',
      AppLanguage.de: 'Zeile für Zeile',
    },
    icon: Icons.view_week_rounded,
    xFraction: _kDiscTextsRoot,
    row: 15.95,
    branch: SkillBranch.texts,
    isMain: false,
    parentIds: ['texts_l3'],
    status: SkillNodeStatus.locked,
  ),
  SkillNode(
    id: 'texts_l5',
    title: {
      AppLanguage.ru: 'Эмоциональный резонанс',
      AppLanguage.en: 'Emotional resonance',
      AppLanguage.de: 'Emotionale Resonanz',
    },
    icon: Icons.auto_awesome_rounded,
    xFraction: _kDiscTextsRoot,
    row: 17.25,
    branch: SkillBranch.texts,
    isMain: false,
    parentIds: ['texts_l4'],
    status: SkillNodeStatus.locked,
  ),
];

// =====================================================================
//  SCREEN
// =====================================================================

class SkillTreeScreen extends StatefulWidget {
  const SkillTreeScreen({super.key});

  @override
  State<SkillTreeScreen> createState() => _SkillTreeScreenState();
}

class _SkillTreeScreenState extends State<SkillTreeScreen>
    with TickerProviderStateMixin {
  /// Мягкий пульс для текущего урока (accent, theme-aware).
  late final AnimationController _ambient;

  String? _expandedSectionId;
  final Set<String> _completedNodeIds = <String>{};
  bool _loadingProgress = true;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    _loadProgress();
    AcademyRemoteService.instance.startWatching();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_preferAcademyDisplayRefresh());
    });
  }

  List<AcademySectionDefinition> get _sections =>
      AcademyRemoteService.instance.mergeSections(kAcademySections);

  List<SkillNode> _allTreeNodes() {
    final extra = AcademyRemoteService.instance.extraLessons();
    if (extra.isEmpty) return _kSkillTree;
    final remoteNodes = extra
        .map(
          (l) => SkillNode(
            id: l.id,
            title: l.title,
            icon: AcademyIconRegistry.resolve(l.iconName),
            xFraction: 0.5,
            row: 0,
            branch: SkillBranch.core,
            isMain: false,
            parentIds: l.prerequisiteNodeIds,
            status: SkillNodeStatus.locked,
          ),
        )
        .toList(growable: false);
    return <SkillNode>[..._kSkillTree, ...remoteNodes];
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final saved =
        prefs.getStringList(_prefsSkillTreeCompletedKey) ?? const <String>[];
    if (!mounted) return;
    final next = <String>{...saved};
    final didMigrate = _migrateMergedDisciplineProgress(next);
    final didMigrateIntro = _migrateNumbersIntroProgress(next);
    final didMigrateTexts = _migrateTextsBranchNodeIds(next);
    final didMigrateM5 = _migrateRemovedM5Node(next);
    final didMigrateM0 = _migrateRemovedM0Node(next);
    final didMigrateNumbersBinary = _migrateRemovedNumbersBinaryNode(next);
    final didMigrateCards = _migrateCardsTrackNodeIds(next);
    setState(() {
      _completedNodeIds
        ..clear()
        ..addAll(next);
      _loadingProgress = false;
    });
    _syncExpandedWithProgress();
    if (didMigrate ||
        didMigrateIntro ||
        didMigrateTexts ||
        didMigrateM5 ||
        didMigrateM0 ||
        didMigrateNumbersBinary ||
        didMigrateCards) {
      await prefs.setStringList(
        _prefsSkillTreeCompletedKey,
        _completedNodeIds.toList(growable: false),
      );
    }
  }

  /// Узел m5 «Направления» убран — чистим id из сохранений.
  bool _migrateRemovedM5Node(Set<String> ids) => ids.remove('m5');

  /// Узел m0 «Старт» убран — чистим id из сохранений.
  bool _migrateRemovedM0Node(Set<String> ids) => ids.remove('m0');

  /// Урок «Бинарные числа» убран — чистим id из сохранений.
  bool _migrateRemovedNumbersBinaryNode(Set<String> ids) =>
      ids.remove('numbers_binary');

  /// Устаревший плейсхолдер t2 убран из дерева — выкидываем id из сохранений.
  bool _migrateTextsBranchNodeIds(Set<String> ids) {
    return ids.remove('t2');
  }

  /// После добавления узла numbers_intro помечаем его пройденным, если уже
  /// пройдена любая более поздняя ступень числовой ветки.
  bool _migrateNumbersIntroProgress(Set<String> ids) {
    if (ids.contains('numbers_intro')) return false;
    const downstream = <String>{
      'disc_numbers',
      'numbers_speed',
      'numbers_long',
      'numbers_clock',
    };
    if (downstream.any(ids.contains)) {
      ids.add('numbers_intro');
      return true;
    }
    return false;
  }

  /// Старые id ветки «Карты» → новые id после обновления курса.
  bool _migrateCardsTrackNodeIds(Set<String> ids) {
    const renames = <String, String>{
      'cards_dominic': 'cards_suit_categories',
      'cards_full_deck': 'cards_major_system',
      'cards_acceleration': 'cards_pao',
      'cards_tournament': 'cards_practice_speed',
    };
    var changed = false;
    for (final e in renames.entries) {
      if (ids.remove(e.key)) {
        ids.add(e.value);
        changed = true;
      }
    }
    return changed;
  }

  /// Старые id первого ряда столбцов → новые id узлов disc_* после слияния.
  bool _migrateMergedDisciplineProgress(Set<String> ids) {
    const merged = <String, String>{
      'numbers_coding': 'disc_numbers',
      'imagery_pictures_intro': 'disc_imagery',
      'cards_basics': 'disc_cards',
      'words_memorizing': 'disc_words',
      't1': 'disc_texts',
    };
    var changed = false;
    for (final e in merged.entries) {
      if (ids.remove(e.key)) {
        ids.add(e.value);
        changed = true;
      }
    }
    return changed;
  }

  Future<void> _markCompleted(String nodeId) async {
    if (_completedNodeIds.contains(nodeId)) return;
    _completedNodeIds.add(nodeId);
    if (mounted) setState(() {});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsSkillTreeCompletedKey,
      _completedNodeIds.toList(growable: false),
    );
  }

  bool _isCompleted(String nodeId) => _completedNodeIds.contains(nodeId);

  bool _allCompleted(Iterable<String> ids) => ids.every(_isCompleted);

  bool _isSectionUnlocked(AcademySectionDefinition section) {
    final prereqs = section.unlockAfterNodeIds;
    if (prereqs.isEmpty) return true;
    return _allCompleted(prereqs);
  }

  List<String> _prerequisitesFor(SkillNode node) {
    final remote = AcademyRemoteService.instance.prerequisitesFor(node.id);
    if (remote != null) return remote;
    switch (node.id) {
      case 'intro1':
      case 'intro2':
        return const <String>['m1'];
      case 'm2':
        return const <String>['m1', 'intro1', 'intro2'];
      case 'task_strawberry':
      case 'image_types':
        return const <String>['m2'];
      case 'm3':
        return const <String>['m2', 'task_strawberry', 'image_types'];
      case 'task_association':
        return const <String>['m3'];
      case 'm4':
        return const <String>['m3', 'task_association'];
      case 'palace_create':
        return const <String>['m4'];
      case 'palace_place_images':
        return const <String>['m4', 'palace_create'];
      case 'palace_mistakes':
        return const <String>[
          'm4',
          'palace_create',
          'palace_place_images',
        ];
      case 'numbers_intro':
        return const <String>['palace_mistakes'];
      case 'disc_numbers':
        return const <String>['palace_mistakes', 'numbers_intro'];
      case 'disc_imagery':
      case 'disc_cards':
      case 'disc_words':
      case 'disc_texts':
        return const <String>['palace_mistakes'];
      case 'disc_languages':
        return const <String>['palace_mistakes'];
      case 'numbers_speed':
        return const <String>['palace_mistakes', 'disc_numbers'];
      case 'numbers_long':
        return const <String>['palace_mistakes', 'numbers_speed'];
      case 'numbers_clock':
        return const <String>['palace_mistakes', 'numbers_long'];
      case 'imagery_main_object':
        return const <String>['palace_mistakes', 'disc_imagery'];
      case 'imagery_encoding':
        return const <String>['palace_mistakes', 'imagery_main_object'];
      case 'imagery_picture_errors':
        return const <String>['palace_mistakes', 'imagery_encoding'];
      case 'cards_suit_categories':
        return const <String>['palace_mistakes', 'disc_cards'];
      case 'cards_major_system':
        return const <String>['palace_mistakes', 'cards_suit_categories'];
      case 'cards_pao':
        return const <String>['palace_mistakes', 'cards_major_system'];
      case 'cards_practice_speed':
        return const <String>['palace_mistakes', 'cards_pao'];
      case 'words_abstract':
        return const <String>['palace_mistakes', 'disc_words'];
      case 'words_fast_coding':
        return const <String>['palace_mistakes', 'words_abstract'];
      case 'texts_l2':
        return const <String>['palace_mistakes', 'disc_texts'];
      case 'texts_l3':
        return const <String>['palace_mistakes', 'texts_l2'];
      case 'texts_l4':
        return const <String>['palace_mistakes', 'texts_l3'];
      case 'texts_l5':
        return const <String>['palace_mistakes', 'texts_l4'];
      default:
        return node.parentIds;
    }
  }

  SkillNodeStatus _statusFor(SkillNode node) {
    // disc_languages: только открытость после дворца, без галочки «пройдено».
    if (_kStemDisciplineIds.contains(node.id)) {
      final open = _allCompleted(_prerequisitesFor(node));
      return open ? SkillNodeStatus.unlocked : SkillNodeStatus.locked;
    }
    if (_isCompleted(node.id)) return SkillNodeStatus.completed;
    final prereqs = _prerequisitesFor(node);
    return _allCompleted(prereqs)
        ? SkillNodeStatus.unlocked
        : SkillNodeStatus.locked;
  }

  List<SkillNode> _resolvedTree() {
    return _allTreeNodes()
        .map(
          (n) => SkillNode(
            id: n.id,
            title: n.title,
            icon: n.icon,
            xFraction: n.xFraction,
            row: n.row,
            branch: n.branch,
            isMain: n.isMain,
            parentIds: n.parentIds,
            status: _statusFor(n),
          ),
        )
        .toList(growable: false);
  }

  void _syncExpandedWithProgress() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nodes = _resolvedTree();
      final active = _activeNodeId(nodes);
      final sections = _sections;
      final sid = _sectionIdForNode(active, sections) ?? sections.first.id;
      final section = sections.firstWhere(
        (s) => s.id == sid,
        orElse: () => sections.first,
      );
      setState(() {
        _expandedSectionId =
            _isSectionUnlocked(section) ? section.id : sections.first.id;
      });
    });
  }

  String? _sectionIdForNode(String? nodeId, [List<AcademySectionDefinition>? sections]) {
    if (nodeId == null) return null;
    final list = sections ?? _sections;
    for (final s in list) {
      if (s.lessonNodeIds.contains(nodeId)) return s.id;
    }
    return null;
  }

  SkillNode? _nodeById(List<SkillNode> nodes, String id) {
    for (final n in nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  ({int done, int total}) _sectionProgress(
    AcademySectionDefinition section,
    List<SkillNode> nodes,
  ) {
    var done = 0;
    var total = 0;
    for (final id in section.lessonNodeIds) {
      final n = _nodeById(nodes, id);
      if (n == null) continue;
      total++;
      if (n.status == SkillNodeStatus.completed) done++;
    }
    return (done: done, total: total);
  }

  void _toggleSection(String sectionId) {
    setState(() {
      _expandedSectionId = _expandedSectionId == sectionId ? null : sectionId;
    });
  }

  List<Widget> _buildSectionLessonChildren({
    required AcademySectionDefinition section,
    required List<SkillNode> nodes,
    required String? activeId,
    required Color accent,
    required ColorScheme scheme,
  }) {
    final groups = AcademyRemoteService.instance.lessonGroupsForSection(
      section.id,
      section.lessonNodeIds,
    );
    final widgets = <Widget>[];
    final hasNamedGroups = groups.any((g) => g.title != null);

    for (var gi = 0; gi < groups.length; gi++) {
      final group = groups[gi];
      final String? headerTitle = group.title != null
          ? academyTranslate(group.title!, appLanguage.value)
          : (hasNamedGroups && group.groupId == null
              ? _localized(
                  ru: 'Прочее',
                  en: 'Other',
                  de: 'Sonstiges',
                )
              : null);

      if (headerTitle != null) {
        if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 10));
        widgets.add(
          _AcademyLessonGroupHeader(
            title: headerTitle,
            scheme: scheme,
            accent: accent,
          ),
        );
        widgets.add(const SizedBox(height: 8));
      } else if (widgets.isNotEmpty && groups.length > 1) {
        widgets.add(const SizedBox(height: 10));
      }

      for (var i = 0; i < group.lessonIds.length; i++) {
        if (i > 0) widgets.add(const SizedBox(height: 6));
        final id = group.lessonIds[i];
        final node = _nodeById(nodes, id);
        if (node == null) continue;
        final remote = AcademyRemoteService.instance;
        final isPremiumContent =
            remote.isLessonPremiumInSection(node.id, section.id);
        final isPremiumLocked =
            isPremiumContent && !PremiumService.instance.hasPremium;
        widgets.add(
          _AcademyLessonTile(
            node: node,
            accent: accent,
            scheme: scheme,
            isCurrent: node.id == activeId,
            isPremiumLocked: isPremiumLocked,
            ambient: _ambient,
            onTap: () {
              if (isPremiumLocked) {
                _openPremiumSettings();
                return;
              }
              if (node.status == SkillNodeStatus.locked) {
                _showLockedSheet(node);
                return;
              }
              _showLessonPreview(node, sectionId: section.id);
            },
          ),
        );
      }

      if (gi < groups.length - 1) {
        widgets.add(const SizedBox(height: 14));
      }
    }

    return widgets;
  }

  void _onSectionHeaderTap(AcademySectionDefinition section) {
    if (!_isSectionUnlocked(section)) {
      uiTapClick(UiClickSound.soft);
      _showSectionLockedSheet(section);
      return;
    }
    _toggleSection(section.id);
  }

  void _showSectionLockedSheet(AcademySectionDefinition section) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final lang = appLanguage.value;
    final title = academyTranslate(section.title, lang);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: palette.border, width: 0.6),
          ),
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: onSurface.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.card,
                  border:
                      Border.all(color: onSurface.withOpacity(0.15), width: 1),
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: onSurface.withOpacity(0.55),
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  color: onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _localized(
                  ru:
                      'Сначала пройди оба урока по связкам: «Связи» и «Задание 2 · Связки».',
                  en:
                      'Complete both linking lessons first: "Linking" and "Task 2 · Linking".',
                  de:
                      'Schließe zuerst beide Verknüpfungs-Lektionen ab: «Verbinden» und «Übung 2 · Verknüpfen».',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onSurface.withOpacity(0.55),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    AcademyRemoteService.instance.stopWatching();
    unawaited(_restoreAcademyDisplayRefresh());
    _ambient.dispose();
    super.dispose();
  }

  Future<void> _preferAcademyDisplayRefresh() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _kAcademyDisplayChannel.invokeMethod<void>(
        'preferRefreshRate',
        <String, dynamic>{'maxHz': 120.0},
      );
    } catch (_) {}
  }

  Future<void> _restoreAcademyDisplayRefresh() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _kAcademyDisplayChannel.invokeMethod<void>('restoreRefreshRate');
    } catch (_) {}
  }

  /// Активный узел = первый unlocked в главном пути; если такого нет —
  /// первый unlocked среди веток. Это «следующая цель» пользователя.
  String? _activeNodeId(List<SkillNode> nodes) {
    int cmpUnlockOrder(SkillNode a, SkillNode b) {
      final rc = a.row.compareTo(b.row);
      if (rc != 0) return rc;
      return a.xFraction.compareTo(b.xFraction);
    }

    final mains = nodes
        .where((n) => n.isMain && n.status == SkillNodeStatus.unlocked)
        .toList()
      ..sort(cmpUnlockOrder);
    if (mains.isNotEmpty) return mains.first.id;
    final any = nodes
        .where((n) => n.status == SkillNodeStatus.unlocked)
        .toList()
      ..sort(cmpUnlockOrder);
    return any.isNotEmpty ? any.first.id : null;
  }

  void _openPremiumSettings() {
    uiTapClick(UiClickSound.soft);
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const PremiumScreen(),
      ),
    );
  }

  Future<void> _openLesson(SkillNode node, {String? sectionId}) async {
    if (node.status == SkillNodeStatus.locked) {
      uiTapClick(UiClickSound.soft);
      _showLockedSheet(node);
      return;
    }
    if (sectionId != null) {
      final remote = AcademyRemoteService.instance;
      if (remote.isLessonPremiumInSection(node.id, sectionId) &&
          !PremiumService.instance.hasPremium) {
        _openPremiumSettings();
        return;
      }
    }
    uiTapClick(UiClickSound.soft);
    final finished = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 360),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (_, __, ___) {
          if (AcademyRemoteService.instance.isCustomLesson(node.id) ||
              AcademyRemoteService.instance.hasRemoteOverride(node.id)) {
            return CustomAcademyLessonScreen(lessonId: node.id);
          }
          // Узлы с реальным контентом. Остальные — placeholder.
          switch (node.id) {
            case 'm1':
              return const MnemonicsIntroLessonScreen();
            case 'intro1':
              return const MnemonicsCapabilitiesLessonScreen();
            case 'intro2':
              return const MnemonicsHistoryLessonScreen();
            case 'm2':
              return const ImageryLessonScreen();
            case 'task_strawberry':
              return const ImageryStrawberryTaskScreen();
            case 'image_types':
              return const ImageryTypesLessonScreen();
            case 'm3':
              return const LinkingLessonScreen();
            case 'task_association':
              return const AssociationTrainerScreen();
            case 'm4':
              return const MemoryPalaceMethodLessonScreen();
            case 'palace_create':
              return const MemoryPalaceCreateLessonScreen();
            case 'palace_place_images':
              return const MemoryPalacePlacingImagesLessonScreen();
            case 'palace_mistakes':
              return const MemoryPalaceMistakesLessonScreen();
            case 'numbers_intro':
              return const NumbersIntroLessonScreen();
            case 'disc_numbers':
              return const NumberCodingSystemLessonScreen();
            case 'disc_imagery':
              return const MemorizingPicturesLessonScreen();
            case 'disc_cards':
              return const CardBasicsLessonScreen();
            case 'disc_words':
              return const WordsMemorizingLessonScreen();
            case 'numbers_speed':
              return const NumbersMemorizationSpeedLessonScreen();
            case 'numbers_long':
              return const NumbersLongSequencesLessonScreen();
            case 'numbers_clock':
              return const NumbersAgainstTheClockLessonScreen();
            case 'imagery_main_object':
              return const HighlightingMainObjectLessonScreen();
            case 'imagery_encoding':
              return const ImageEncodingLessonScreen();
            case 'imagery_picture_errors':
              return const ImageryPictureErrorsLessonScreen();
            case 'cards_suit_categories':
              return const CardsSuitCategoriesLessonScreen();
            case 'cards_major_system':
              return const CardsMajorSystemLessonScreen();
            case 'cards_pao':
              return const CardsPaoLessonScreen();
            case 'cards_practice_speed':
              return const CardsPracticeSpeedLessonScreen();
            case 'words_abstract':
              return const WordsAbstractLessonScreen();
            case 'words_fast_coding':
              return const WordsFastCodingLessonScreen();
            case 'disc_texts':
              return const TextsMemorizationLesson1Screen();
            case 'texts_l2':
              return const TextsMemorizationLesson2Screen();
            case 'texts_l3':
              return const TextsMemorizationLesson3Screen();
            case 'texts_l4':
              return const TextsMemorizationLesson4Screen();
            case 'texts_l5':
              return const TextsMemorizationLesson5Screen();
            default:
              return _LessonPlaceholderScreen(node: node);
          }
        },
        transitionsBuilder: (_, anim, __, child) {
          final curved =
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
                child: child,
              ),
            ),
          );
        },
      ),
    );
    if (finished == true) {
      await _markCompleted(node.id);
      _syncExpandedWithProgress();
    }
  }

  void _showLessonPreview(SkillNode node, {required String sectionId}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = appAccentColor.value;
    final palette = appPalette.value;
    final done = node.status == SkillNodeStatus.completed;
    final locked = node.status == SkillNodeStatus.locked;
    final remote = AcademyRemoteService.instance;
    final premiumLocked = remote.isLessonPremiumInSection(node.id, sectionId) &&
        !PremiumService.instance.hasPremium;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          decoration: BoxDecoration(
            color: palette.surface.withOpacity(0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accent.withOpacity(0.25)),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.16),
                blurRadius: 28,
                spreadRadius: 1,
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTexts.translate(node.title),
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  premiumLocked
                      ? _localized(
                          ru: 'Премиум-урок. Оформи подписку в настройках.',
                          en: 'Premium lesson. Get Premium in Settings.',
                          de: 'Premium-Lektion. Hol dir Premium in den Einstellungen.',
                        )
                      : _localized(
                          ru: done
                              ? 'Урок уже завершен. Можно повторить в любом темпе.'
                              : 'Ключевой шаг твоего пути. Открой урок и двигайся дальше.',
                          en: done
                              ? 'This lesson is completed. You can replay it anytime.'
                              : 'A key step in your path. Open the lesson to move forward.',
                          de: done
                              ? 'Diese Lektion ist abgeschlossen. Du kannst sie jederzeit wiederholen.'
                              : 'Ein wichtiger Schritt auf deinem Weg. Starte die Lektion und gehe weiter.',
                        ),
                  style: TextStyle(
                    color: onSurface.withOpacity(0.62),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                _ProgressBar(
                  progress: done ? 1 : (locked || premiumLocked ? 0 : 0.35),
                  accent: accent,
                  onSurface: onSurface,
                  palette: palette,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: locked
                        ? null
                        : premiumLocked
                            ? () {
                                Navigator.pop(ctx);
                                _openPremiumSettings();
                              }
                            : () {
                                Navigator.pop(ctx);
                                unawaited(_openLesson(node, sectionId: sectionId));
                              },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: palette.background,
                      disabledBackgroundColor: onSurface.withOpacity(0.12),
                      disabledForegroundColor: onSurface.withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      locked
                          ? _localized(
                              ru: 'Заблокировано', en: 'Locked', de: 'Gesperrt')
                          : premiumLocked
                              ? _localized(
                                  ru: 'Premium',
                                  en: 'Premium',
                                  de: 'Premium',
                                )
                              : _localized(
                                  ru: 'Start Lesson',
                                  en: 'Start Lesson',
                                  de: 'Start Lesson'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLockedSheet(SkillNode node) {
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: palette.border, width: 0.6),
          ),
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: onSurface.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.card,
                  border:
                      Border.all(color: onSurface.withOpacity(0.15), width: 1),
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: onSurface.withOpacity(0.55),
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppTexts.translate(node.title),
                style: TextStyle(
                  color: onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _localized(
                  ru: 'Сначала пройди предыдущие уроки.',
                  en: 'Complete previous lessons to unlock.',
                  de: 'Schließe vorherige Lektionen ab, um freizuschalten.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onSurface.withOpacity(0.55),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withOpacity(0.25)),
                ),
                child: Center(
                  child: Text(
                    _localized(
                      ru: 'СКОРО',
                      en: 'COMING SOON',
                      de: 'BALD',
                    ),
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (_, __, ___) => ValueListenableBuilder<AppPalette>(
        valueListenable: appPalette,
        builder: (_, palette, __) => ValueListenableBuilder<Color>(
          valueListenable: appAccentColor,
          builder: (_, accent, __) => _buildScaffold(palette, accent),
        ),
      ),
    );
  }

  Widget _buildScaffold(AppPalette palette, Color accent) {
    final nodes = _resolvedTree();
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final completed =
        nodes.where((n) => n.status == SkillNodeStatus.completed).length;
    final total = nodes.length;
    final progress = completed / total;
    final activeId = _activeNodeId(nodes);

    if (_loadingProgress) {
      return Scaffold(
        backgroundColor: palette.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: onSurface.withOpacity(0.7),
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            AppTexts.get('academy'),
            style: TextStyle(
              color: onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: palette.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: onSurface.withOpacity(0.7),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppTexts.get('academy'),
          style: TextStyle(
            color: onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        centerTitle: true,
        actions: [
          if (AppCreator.isCurrentUser)
            IconButton(
              icon: Icon(Icons.edit_note_rounded, color: onSurface.withOpacity(0.75)),
              tooltip: AppTexts.translate(const <AppLanguage, String>{
                AppLanguage.ru: 'Редактор',
                AppLanguage.en: 'Editor',
                AppLanguage.de: 'Editor',
              }),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const AcademyEditorScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _AcademyBackdropPainter(
                  accent: accent,
                  background: palette.background,
                  scheme: Theme.of(context).colorScheme,
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: Listenable.merge([
              AcademyRemoteService.instance.refreshListenable,
              PremiumService.instance.active,
            ]),
            builder: (_, __) {
              final sections = _sections;
              return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.top + kToolbarHeight,
                ),
              ),
              SliverToBoxAdapter(
                child: _Header(
                  onSurface: onSurface,
                  accent: accent,
                  palette: palette,
                  progress: progress,
                  completed: completed,
                  total: total,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final section = sections[index];
                      final isLast = index == sections.length - 1;
                      final sectionUnlocked = _isSectionUnlocked(section);
                      final expanded =
                          sectionUnlocked && _expandedSectionId == section.id;
                      final stats = _sectionProgress(section, nodes);
                      final scheme = Theme.of(context).colorScheme;
                      return Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                        child: Column(
                          children: [
                            _AcademySectionCard(
                              section: section,
                              expanded: expanded,
                              locked: !sectionUnlocked,
                              stats: stats,
                              accent: accent,
                              scheme: scheme,
                              onHeaderTap: () => _onSectionHeaderTap(section),
                              children: section.isPlaceholder ||
                                      section.lessonNodeIds.isEmpty
                                  ? [
                                      _AcademyPlaceholderBody(
                                        scheme: scheme,
                                        accent: accent,
                                      ),
                                    ]
                                  : _buildSectionLessonChildren(
                                      section: section,
                                      nodes: nodes,
                                      activeId: activeId,
                                      accent: accent,
                                      scheme: scheme,
                                    ),
                            ),
                            if (!isLast)
                              _AcademyConnector(
                                scheme: scheme,
                                accent: accent,
                              ),
                          ],
                        ),
                      );
                    },
                    childCount: sections.length,
                  ),
                ),
              ),
            ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// =====================================================================
//  HEADER (заголовок + прогресс-бар)
// =====================================================================

class _Header extends StatelessWidget {
  const _Header({
    required this.onSurface,
    required this.accent,
    required this.palette,
    required this.progress,
    required this.completed,
    required this.total,
  });

  final Color onSurface;
  final Color accent;
  final AppPalette palette;
  final double progress;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _localized(
              ru: 'Путь обучения',
              en: 'Learning path',
              de: 'Lernpfad',
            ),
            style: TextStyle(
              color: onSurface,
              fontSize: 30,
              fontWeight: FontWeight.w200,
              letterSpacing: -0.3,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _localized(
              ru: 'Один маршрут сверху вниз — спокойный темп на дистанции',
              en: 'One calm path from top to bottom — built for the long run',
              de: 'Ein ruhiger Pfad von oben nach unten — für langfristiges Lernen',
            ),
            style: TextStyle(
              color: onSurface.withOpacity(0.45),
              fontSize: 13,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 22),
          _ProgressBar(
            progress: progress,
            accent: accent,
            onSurface: onSurface,
            palette: palette,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _localized(
                  ru: '$completed из $total уроков пройдено',
                  en: '$completed / $total lessons completed',
                  de: '$completed / $total Lektionen abgeschlossen',
                ),
                style: TextStyle(
                  color: onSurface.withOpacity(0.55),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.progress,
    required this.accent,
    required this.onSurface,
    required this.palette,
  });

  final double progress;
  final Color accent;
  final Color onSurface;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final hi = Theme.of(context).brightness == Brightness.dark ? 0.20 : 0.10;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: progress),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (_, value, __) {
        return SizedBox(
          height: 8,
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: onSurface.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      width: (w * value).clamp(0.0, w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accent.withOpacity(0.55),
                            accent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.45),
                            blurRadius: 12,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Едва заметный «highlight» сверху — премиум-блик.
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 1,
                    height: 2,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: Container(
                        width: (w * value).clamp(0.0, w),
                        color: onSurface.withOpacity(hi),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// =====================================================================
//  ACADEMY PATH — glass sections, theme + accent
// =====================================================================

class _AcademyBackdropPainter extends CustomPainter {
  _AcademyBackdropPainter({
    required this.accent,
    required this.background,
    required this.scheme,
  });

  final Color accent;
  final Color background;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.11);
    final radius = size.width * 0.95;
    final secondary = scheme.secondary;
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [
          Color.lerp(accent, secondary, 0.35)!.withOpacity(0.06),
          accent.withOpacity(0.025),
          background.withOpacity(0),
        ],
        const [0.0, 0.42, 1.0],
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _AcademyBackdropPainter old) =>
      old.accent != accent ||
      old.background != background ||
      old.scheme != scheme;
}

class _AcademyConnector extends StatelessWidget {
  const _AcademyConnector({
    required this.scheme,
    required this.accent,
  });

  final ColorScheme scheme;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final line = scheme.outline.withOpacity(0.16);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Divider(height: 1, thickness: 1, color: line)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.32),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.18),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: Divider(height: 1, thickness: 1, color: line)),
        ],
      ),
    );
  }
}

class _AcademyPlaceholderBody extends StatelessWidget {
  const _AcademyPlaceholderBody({
    required this.scheme,
    required this.accent,
  });

  final ColorScheme scheme;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.schedule_rounded,
              size: 20, color: accent.withOpacity(0.75)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _localized(
                ru: 'Здесь появятся дополнительные тренировки.',
                en: 'More practice drills will appear here.',
                de: 'Weitere Übungen erscheinen hier.',
              ),
              style: TextStyle(
                color: scheme.onSurface.withOpacity(0.52),
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineSectionProgress extends StatelessWidget {
  const _InlineSectionProgress({
    required this.done,
    required this.total,
    required this.frac,
    required this.accent,
    required this.scheme,
  });

  final int done;
  final int total;
  final double frac;
  final Color accent;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final onSurface = scheme.onSurface;
    if (total == 0) {
      return Text(
        _localized(ru: 'Скоро', en: 'Soon', de: 'Bald'),
        style: TextStyle(
          color: onSurface.withOpacity(0.45),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _localized(
            ru: '$done из $total уроков',
            en: '$done / $total lessons',
            de: '$done / $total Lektionen',
          ),
          style: TextStyle(
            color: onSurface.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: frac.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                height: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: onSurface.withOpacity(0.07)),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: value,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accent.withOpacity(0.55),
                                accent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AcademySectionLeading extends StatelessWidget {
  const _AcademySectionLeading({
    required this.icon,
    required this.accent,
    required this.scheme,
  });

  final IconData icon;
  final Color accent;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withOpacity(0.11),
        border: Border.all(color: accent.withOpacity(0.32)),
        boxShadow: [
          BoxShadow(color: accent.withOpacity(0.1), blurRadius: 14),
        ],
      ),
      child: Icon(icon, color: accent, size: 24),
    );
  }
}

class _AcademyLessonGroupHeader extends StatelessWidget {
  const _AcademyLessonGroupHeader({
    required this.title,
    required this.scheme,
    required this.accent,
  });

  final String title;
  final ColorScheme scheme;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.75),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: scheme.onSurface.withOpacity(0.58),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _AcademySectionCard extends StatelessWidget {
  const _AcademySectionCard({
    required this.section,
    required this.expanded,
    required this.locked,
    required this.stats,
    required this.accent,
    required this.scheme,
    required this.onHeaderTap,
    required this.children,
  });

  final AcademySectionDefinition section;
  final bool expanded;
  final bool locked;
  final ({int done, int total}) stats;
  final Color accent;
  final ColorScheme scheme;
  final VoidCallback onHeaderTap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final lang = appLanguage.value;
    final title = academyTranslate(section.title, lang);
    final subtitle = academyTranslate(section.subtitle, lang);
    final t = stats.total;
    final d = stats.done;
    final frac = t == 0 ? 0.0 : d / t;

    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.surface.withOpacity(0.5),
                scheme.surface.withOpacity(0.34),
              ],
            ),
            border: Border.all(
              color: Color.lerp(
                    scheme.outline,
                    accent,
                    locked ? 0.05 : (expanded ? 0.42 : 0.1),
                  )!
                  .withOpacity(locked ? 0.22 : (expanded ? 0.5 : 0.28)),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.06 + (expanded ? 0.05 : 0)),
                blurRadius: 22 + (expanded ? 10 : 0),
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: scheme.shadow.withOpacity(0.05),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onHeaderTap,
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 14, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Hero(
                          tag: 'academy_section_icon_${section.id}',
                          child: _AcademySectionLeading(
                            icon: section.icon,
                            accent: accent,
                            scheme: scheme,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                  color: scheme.onSurface.withOpacity(0.55),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _InlineSectionProgress(
                                done: d,
                                total: t,
                                frac: frac,
                                accent: accent,
                                scheme: scheme,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (locked)
                          Icon(
                            Icons.lock_outline_rounded,
                            color: scheme.onSurface.withOpacity(0.4),
                            size: 22,
                          )
                        else
                          AnimatedRotation(
                            turns: expanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOutCubic,
                            child: Icon(
                              Icons.expand_more_rounded,
                              color: scheme.onSurface.withOpacity(0.45),
                              size: 26,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              ClipRect(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: expanded
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              child: Divider(
                                height: 1,
                                color: scheme.outline.withOpacity(0.12),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: children,
                              ),
                            ),
                          ],
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _AcademyLessonTile extends StatelessWidget {
  const _AcademyLessonTile({
    required this.node,
    required this.accent,
    required this.scheme,
    required this.isCurrent,
    required this.isPremiumLocked,
    required this.ambient,
    required this.onTap,
  });

  final SkillNode node;
  final Color accent;
  final ColorScheme scheme;
  final bool isCurrent;
  final bool isPremiumLocked;
  final AnimationController ambient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = scheme.onSurface;
    final done = node.status == SkillNodeStatus.completed;
    final locked = node.status == SkillNodeStatus.locked;
    final premiumVisual = isPremiumLocked && !locked;
    final accentDeep = Color.lerp(accent, scheme.surface, 0.35)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedBuilder(
          animation: ambient,
          builder: (context, child) {
            final breath = (isCurrent && !locked && !done) || premiumVisual
                ? 0.5 + 0.5 * math.sin(ambient.value * 2 * math.pi)
                : 1.0;
            final pulse = isCurrent && !locked && !done ? 0.06 * breath : 0.0;
            final premiumPulse = premiumVisual ? 0.08 + 0.06 * breath : 0.0;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: premiumVisual
                      ? accent.withOpacity(0.42 + 0.28 * breath)
                      : isCurrent && !locked && !done
                          ? accent.withOpacity(0.38 + 0.22 * breath)
                          : scheme.outline.withOpacity(locked ? 0.12 : 0.2),
                  width: premiumVisual || (isCurrent && !locked && !done)
                      ? 1.15
                      : 1,
                ),
                gradient: premiumVisual
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withOpacity(0.14 + premiumPulse),
                          accentDeep.withOpacity(0.06 + premiumPulse * 0.5),
                        ],
                      )
                    : null,
                color: premiumVisual
                    ? null
                    : isCurrent && !locked && !done
                        ? accent.withOpacity(0.06 + pulse)
                        : scheme.surface.withOpacity(locked ? 0.28 : 0.5),
                boxShadow: premiumVisual
                    ? [
                        BoxShadow(
                          color: accent.withOpacity(0.22 + 0.18 * breath),
                          blurRadius: 18 + 6 * breath,
                          spreadRadius: 0.5,
                        ),
                        BoxShadow(
                          color: accentDeep.withOpacity(0.08 + 0.06 * breath),
                          blurRadius: 28,
                          spreadRadius: 1,
                        ),
                      ]
                    : isCurrent && !locked && !done
                        ? [
                            BoxShadow(
                              color: accent.withOpacity(0.12 + 0.1 * breath),
                              blurRadius: 16,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
              ),
              child: child,
            );
          },
          child: Row(
            children: [
              Opacity(
                opacity: locked ? 0.48 : 1,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? accent.withOpacity(0.2)
                        : premiumVisual
                            ? accent.withOpacity(0.16)
                            : scheme.surface.withOpacity(0.95),
                    border: Border.all(
                      color: done
                          ? accent.withOpacity(0.75)
                          : premiumVisual
                              ? accent.withOpacity(0.55)
                              : accent.withOpacity(locked ? 0.15 : 0.35),
                    ),
                  ),
                  child: Icon(
                    done
                        ? Icons.check_rounded
                        : premiumVisual
                            ? Icons.workspace_premium_rounded
                            : locked
                                ? Icons.lock_outline_rounded
                                : node.icon,
                    size: done ? 22 : 20,
                    color: done
                        ? accent
                        : premiumVisual
                            ? accentDeep
                            : locked
                                ? onSurface.withOpacity(0.42)
                                : accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTexts.translate(node.title),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        height: 1.25,
                        color: locked
                            ? onSurface.withOpacity(0.4)
                            : premiumVisual
                                ? onSurface.withOpacity(0.88)
                                : onSurface.withOpacity(0.92),
                      ),
                    ),
                    if (premiumVisual) ...[
                      const SizedBox(height: 3),
                      Text(
                        AppTexts.translate(const {
                          AppLanguage.ru: 'Premium',
                          AppLanguage.en: 'Premium',
                          AppLanguage.de: 'Premium',
                        }),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: accent.withOpacity(0.92),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                premiumVisual
                    ? Icons.lock_rounded
                    : Icons.chevron_right_rounded,
                color: premiumVisual
                    ? accent.withOpacity(0.75)
                    : onSurface.withOpacity(locked ? 0.18 : 0.34),
                size: premiumVisual ? 18 : 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
//  LESSON PLACEHOLDER — пока контент не готов.
// =====================================================================

class _LessonPlaceholderScreen extends StatelessWidget {
  const _LessonPlaceholderScreen({required this.node});

  final SkillNode node;

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded,
              color: onSurface.withOpacity(0.7), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.card,
                    border:
                        Border.all(color: accent.withOpacity(0.85), width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.35),
                        blurRadius: 22,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                  child: Icon(node.icon, color: accent, size: 40),
                ),
                const SizedBox(height: 28),
                Text(
                  AppTexts.translate(node.title),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _localized(
                    ru: 'Урок появится здесь',
                    en: 'Lesson coming soon',
                    de: 'Lektion folgt in Kürze',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: onSurface.withOpacity(0.45),
                    fontSize: 13,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _localized(
    {required String ru, required String en, required String de}) {
  switch (appLanguage.value) {
    case AppLanguage.en:
      return en;
    case AppLanguage.de:
      return de;
    case AppLanguage.ru:
      return ru;
  }
}
