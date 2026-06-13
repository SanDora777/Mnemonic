import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app_creator.dart';
import '../recovered_app.dart' show AppLanguage;
import 'academy_curriculum.dart';
import 'academy_icon_registry.dart';
import 'academy_section_layout.dart';
import 'builtin_academy_slides.dart';
import 'lesson_framework.dart';

class RemoteAcademySection {
  const RemoteAcademySection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconName,
    required this.sortOrder,
    required this.unlockAfterNodeIds,
    required this.isPlaceholder,
    required this.lessonIds,
  });

  final String id;
  final Map<AppLanguage, String> title;
  final Map<AppLanguage, String> subtitle;
  final String iconName;
  final int sortOrder;
  final List<String> unlockAfterNodeIds;
  final bool isPlaceholder;
  final List<String> lessonIds;

  factory RemoteAcademySection.fromMap(String id, Map<String, dynamic> raw) {
    return RemoteAcademySection(
      id: id,
      title: _langMap(raw['title']),
      subtitle: _langMap(raw['subtitle']),
      iconName: (raw['iconName'] ?? 'school_outlined').toString(),
      sortOrder: (raw['sortOrder'] as num?)?.toInt() ?? 0,
      unlockAfterNodeIds: _stringList(raw['unlockAfterNodeIds']),
      isPlaceholder: raw['isPlaceholder'] == true,
      lessonIds: _stringList(raw['lessonIds']),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'title': _langToFirestore(title),
        'subtitle': _langToFirestore(subtitle),
        'iconName': iconName,
        'sortOrder': sortOrder,
        'unlockAfterNodeIds': unlockAfterNodeIds,
        'isPlaceholder': isPlaceholder,
        'lessonIds': lessonIds,
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      };
}

class RemoteAcademyLesson {
  const RemoteAcademyLesson({
    required this.id,
    required this.sectionId,
    required this.title,
    required this.iconName,
    required this.sortOrder,
    required this.prerequisiteNodeIds,
  });

  final String id;
  final String sectionId;
  final Map<AppLanguage, String> title;
  final String iconName;
  final int sortOrder;
  final List<String> prerequisiteNodeIds;

  bool get isCustom => id.startsWith('cless_');

  factory RemoteAcademyLesson.fromMap(String id, Map<String, dynamic> raw) {
    return RemoteAcademyLesson(
      id: id,
      sectionId: (raw['sectionId'] ?? '').toString(),
      title: _langMap(raw['title']),
      iconName: (raw['iconName'] ?? 'school_outlined').toString(),
      sortOrder: (raw['sortOrder'] as num?)?.toInt() ?? 0,
      prerequisiteNodeIds: _stringList(raw['prerequisiteNodeIds']),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'sectionId': sectionId,
        'title': _langToFirestore(title),
        'iconName': iconName,
        'sortOrder': sortOrder,
        'prerequisiteNodeIds': prerequisiteNodeIds,
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      };
}

class RemoteAcademySlide {
  const RemoteAcademySlide({
    required this.id,
    required this.lessonId,
    required this.sortOrder,
    required this.iconName,
    required this.title,
    required this.body,
    this.highlight,
    this.isCompletion = false,
    this.hideCompletionText = false,
    this.trainerLaunch = LessonTrainerLaunchKind.none,
    this.trainerCtaLabel,
    this.trainerCtaSubtitle,
    this.imageData = '',
    this.imageMime = 'image/jpeg',
  });

  final String id;
  final String lessonId;
  final int sortOrder;
  final String iconName;
  final Map<AppLanguage, String> title;
  final Map<AppLanguage, String> body;
  final Map<AppLanguage, String>? highlight;
  final bool isCompletion;
  final bool hideCompletionText;
  final LessonTrainerLaunchKind trainerLaunch;
  final Map<AppLanguage, String>? trainerCtaLabel;
  final Map<AppLanguage, String>? trainerCtaSubtitle;
  final String imageData;
  final String imageMime;

  bool get hasImage => imageData.trim().isNotEmpty;

  Uint8List? get imageBytes {
    if (!hasImage) return null;
    try {
      return base64Decode(imageData);
    } catch (_) {
      return null;
    }
  }

  factory RemoteAcademySlide.fromMap(String id, Map<String, dynamic> raw) {
    return RemoteAcademySlide(
      id: id,
      lessonId: (raw['lessonId'] ?? '').toString(),
      sortOrder: (raw['sortOrder'] as num?)?.toInt() ?? 0,
      iconName: (raw['iconName'] ?? 'school_outlined').toString(),
      title: _langMap(raw['title']),
      body: _langMap(raw['body']),
      highlight: raw['highlight'] != null ? _langMap(raw['highlight']) : null,
      isCompletion: raw['isCompletion'] == true,
      hideCompletionText: raw['hideCompletionText'] == true,
      trainerLaunch: _trainerFromString((raw['trainerLaunch'] ?? 'none').toString()),
      trainerCtaLabel:
          raw['trainerCtaLabel'] != null ? _langMap(raw['trainerCtaLabel']) : null,
      trainerCtaSubtitle: raw['trainerCtaSubtitle'] != null
          ? _langMap(raw['trainerCtaSubtitle'])
          : null,
      imageData: (raw['imageData'] ?? '').toString(),
      imageMime: (raw['imageMime'] ?? 'image/jpeg').toString(),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'lessonId': lessonId,
        'sortOrder': sortOrder,
        'iconName': iconName,
        'title': _langToFirestore(title),
        'body': _langToFirestore(body),
        if (highlight != null) 'highlight': _langToFirestore(highlight!),
        'isCompletion': isCompletion,
        'hideCompletionText': hideCompletionText,
        'trainerLaunch': trainerLaunch.name,
        if (trainerCtaLabel != null) 'trainerCtaLabel': _langToFirestore(trainerCtaLabel!),
        if (trainerCtaSubtitle != null)
          'trainerCtaSubtitle': _langToFirestore(trainerCtaSubtitle!),
        if (imageData.isNotEmpty) 'imageData': imageData,
        if (imageData.isNotEmpty) 'imageMime': imageMime,
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      };

  LessonSlide toLessonSlide() {
    return LessonSlide(
      icon: AcademyIconRegistry.resolve(iconName),
      title: title,
      body: body,
      highlight: highlight,
      isCompletion: isCompletion,
      hideCompletionText: hideCompletionText,
      trainerLaunch: trainerLaunch,
      trainerCtaLabel: trainerCtaLabel,
      trainerCtaSubtitle: trainerCtaSubtitle,
      imageData: imageData.isEmpty ? null : imageData,
      imageMime: imageMime,
    );
  }
}

/// Firestore-backed academy extensions (creator only writes).
class AcademyRemoteService {
  AcademyRemoteService._();
  static final AcademyRemoteService instance = AcademyRemoteService._();

  static const String kSections = 'academy_custom_sections';
  static const String kLessons = 'academy_custom_lessons';
  static const String kSlides = 'academy_custom_slides';
  static const String kLayouts = 'academy_section_layouts';
  static const String kPremiumConfig = 'academy_premium_config';
  static const String kPremiumConfigDoc = 'main';
  static const int kMaxImageBytes = 480000;

  final ValueNotifier<bool> loaded = ValueNotifier<bool>(false);
  final ValueNotifier<int> dataRevision = ValueNotifier<int>(0);

  List<RemoteAcademySection> _sections = const <RemoteAcademySection>[];
  List<RemoteAcademyLesson> _lessons = const <RemoteAcademyLesson>[];
  final Map<String, List<RemoteAcademySlide>> _slidesByLesson =
      <String, List<RemoteAcademySlide>>{};
  final Map<String, RemoteAcademySectionLayout> _layoutsBySection =
      <String, RemoteAcademySectionLayout>{};
  Set<String> _premiumSectionIds = <String>{};
  Set<String> _premiumLessonIds = <String>{};

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _secSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _lesSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _slideSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _layoutSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _premiumSub;
  int _watchers = 0;

  bool get canManage => AppCreator.isCurrentUser;

  Listenable get refreshListenable =>
      Listenable.merge(<Listenable>[loaded, dataRevision]);

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  List<RemoteAcademySection> get customSections =>
      List<RemoteAcademySection>.unmodifiable(_sections);

  List<RemoteAcademyLesson> get customLessons =>
      List<RemoteAcademyLesson>.unmodifiable(_lessons);

  List<RemoteAcademyLesson> lessonsForSection(String sectionId) {
    final out = _lessons.where((l) => l.sectionId == sectionId).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return out;
  }

  bool isCustomLesson(String id) => id.startsWith('cless_');

  List<String>? prerequisitesFor(String lessonId) {
    for (final l in _lessons) {
      if (l.id == lessonId) return l.prerequisiteNodeIds;
    }
    return null;
  }

  List<RemoteAcademySlide> rawSlidesForLesson(String lessonId) {
    return List<RemoteAcademySlide>.from(
      _slidesByLesson[lessonId] ?? const <RemoteAcademySlide>[],
    );
  }

  List<LessonSlide> slidesForLesson(String lessonId) {
    return rawSlidesForLesson(lessonId)
        .map((s) => s.toLessonSlide())
        .toList(growable: false);
  }

  bool hasRemoteOverride(String lessonId) =>
      (_slidesByLesson[lessonId]?.isNotEmpty ?? false);

  bool isSectionPremium(String sectionId) =>
      _premiumSectionIds.contains(sectionId);

  bool isLessonPremium(String lessonId) =>
      _premiumLessonIds.contains(lessonId);

  bool isLessonPremiumInSection(String lessonId, String sectionId) =>
      isSectionPremium(sectionId) || isLessonPremium(lessonId);

  RemoteAcademySectionLayout? sectionLayout(String sectionId) =>
      _layoutsBySection[sectionId];

  List<AcademyLessonGroupView> lessonGroupsForSection(
    String sectionId,
    List<String> allLessonIds,
  ) {
    final layout = _layoutsBySection[sectionId];
    return resolveAcademyLessonGroups(
      allLessonIds: allLessonIds,
      groups: layout?.groups ?? const <RemoteAcademyLessonGroup>[],
    );
  }

  Future<void> importBuiltinSlides(String lessonId) async {
    if (!canManage) throw StateError('forbidden');
    if (hasRemoteOverride(lessonId)) throw StateError('already_has_slides');
    final builtin = builtinSlidesForLesson(lessonId);
    if (builtin == null || builtin.isEmpty) throw StateError('no_builtin');
    final baseMs = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < builtin.length; i++) {
      final slide = builtin[i];
      final id = 'cslide_${baseMs}_$i';
      await _db.collection(kSlides).doc(id).set(
            RemoteAcademySlide(
              id: id,
              lessonId: lessonId,
              sortOrder: i + 1,
              iconName: AcademyIconRegistry.nameFor(slide.icon),
              title: slide.title,
              body: slide.body,
              highlight: slide.highlight,
              isCompletion: slide.isCompletion,
              hideCompletionText: slide.hideCompletionText,
              trainerLaunch: slide.trainerLaunch,
              trainerCtaLabel: slide.trainerCtaLabel,
              trainerCtaSubtitle: slide.trainerCtaSubtitle,
              imageData: slide.imageData ?? '',
              imageMime: slide.imageMime,
            ).toMap(),
          );
    }
  }

  Future<void> startWatching() async {
    _watchers++;
    if (_watchers > 1) return;
    _secSub = _db.collection(kSections).orderBy('sortOrder').snapshots().listen(_onSections);
    _lesSub = _db.collection(kLessons).orderBy('sortOrder').snapshots().listen(_onLessons);
    _slideSub = _db.collection(kSlides).orderBy('sortOrder').snapshots().listen(_onSlides);
    _layoutSub = _db.collection(kLayouts).snapshots().listen(_onLayouts);
    _premiumSub = _db
        .collection(kPremiumConfig)
        .doc(kPremiumConfigDoc)
        .snapshots()
        .listen(_onPremiumConfig);
  }

  void stopWatching() {
    if (_watchers <= 0) return;
    _watchers--;
    if (_watchers > 0) return;
    _secSub?.cancel();
    _lesSub?.cancel();
    _slideSub?.cancel();
    _layoutSub?.cancel();
    _premiumSub?.cancel();
    _secSub = null;
    _lesSub = null;
    _slideSub = null;
    _layoutSub = null;
    _premiumSub = null;
  }

  void _bumpData() {
    dataRevision.value++;
    loaded.value = true;
  }

  void _onPremiumConfig(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data();
    _premiumSectionIds = _stringList(data?['premiumSectionIds']).toSet();
    _premiumLessonIds = _stringList(data?['premiumLessonIds']).toSet();
    _bumpData();
  }

  Future<void> setSectionPremium(String sectionId, bool premium) async {
    if (!canManage) throw StateError('forbidden');
    final sections = Set<String>.from(_premiumSectionIds);
    if (premium) {
      sections.add(sectionId);
    } else {
      sections.remove(sectionId);
    }
    _premiumSectionIds = sections;
    _bumpData();
    try {
      await _savePremiumConfig(
        premiumSectionIds: sections,
        premiumLessonIds: _premiumLessonIds,
      );
    } catch (e) {
      if (premium) {
        _premiumSectionIds.remove(sectionId);
      } else {
        _premiumSectionIds.add(sectionId);
      }
      _bumpData();
      rethrow;
    }
  }

  Future<void> setLessonPremium(String lessonId, bool premium) async {
    if (!canManage) throw StateError('forbidden');
    final lessons = Set<String>.from(_premiumLessonIds);
    if (premium) {
      lessons.add(lessonId);
    } else {
      lessons.remove(lessonId);
    }
    _premiumLessonIds = lessons;
    _bumpData();
    try {
      await _savePremiumConfig(
        premiumSectionIds: _premiumSectionIds,
        premiumLessonIds: lessons,
      );
    } catch (e) {
      if (premium) {
        _premiumLessonIds.remove(lessonId);
      } else {
        _premiumLessonIds.add(lessonId);
      }
      _bumpData();
      rethrow;
    }
  }

  Future<void> _savePremiumConfig({
    required Set<String> premiumSectionIds,
    required Set<String> premiumLessonIds,
  }) async {
    await _db.collection(kPremiumConfig).doc(kPremiumConfigDoc).set(
      <String, dynamic>{
        'premiumSectionIds': premiumSectionIds.toList(),
        'premiumLessonIds': premiumLessonIds.toList(),
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      },
      SetOptions(merge: true),
    );
  }

  void _onSections(QuerySnapshot<Map<String, dynamic>> snap) {
    _sections = snap.docs
        .map((d) => RemoteAcademySection.fromMap(d.id, d.data()))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    _bumpData();
  }

  void _onLessons(QuerySnapshot<Map<String, dynamic>> snap) {
    _lessons = snap.docs.map((d) => RemoteAcademyLesson.fromMap(d.id, d.data())).toList();
    _bumpData();
  }

  void _onSlides(QuerySnapshot<Map<String, dynamic>> snap) {
    final grouped = <String, List<RemoteAcademySlide>>{};
    for (final d in snap.docs) {
      final slide = RemoteAcademySlide.fromMap(d.id, d.data());
      grouped.putIfAbsent(slide.lessonId, () => <RemoteAcademySlide>[]).add(slide);
    }
    for (final list in grouped.values) {
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
    _slidesByLesson
      ..clear()
      ..addAll(grouped);
    _bumpData();
  }

  void _onLayouts(QuerySnapshot<Map<String, dynamic>> snap) {
    _layoutsBySection
      ..clear()
      ..addEntries(
        snap.docs.map(
          (d) => MapEntry(
            d.id,
            RemoteAcademySectionLayout.fromMap(d.id, d.data()),
          ),
        ),
      );
    _bumpData();
  }

  /// Built-in sections + appended custom lessons + custom sections at end.
  List<AcademySectionDefinition> mergeSections(
    List<AcademySectionDefinition> builtIn,
  ) {
    final extraBySection = <String, List<String>>{};
    for (final l in _lessons) {
      extraBySection.putIfAbsent(l.sectionId, () => <String>[]).add(l.id);
    }

    final merged = <AcademySectionDefinition>[];
    for (final s in builtIn) {
      final extra = extraBySection.remove(s.id) ?? const <String>[];
      if (extra.isEmpty) {
        merged.add(s);
      } else {
        merged.add(
          AcademySectionDefinition(
            id: s.id,
            title: s.title,
            subtitle: s.subtitle,
            icon: s.icon,
            lessonNodeIds: <String>[...s.lessonNodeIds, ...extra],
            isPlaceholder: s.isPlaceholder,
            unlockAfterNodeIds: s.unlockAfterNodeIds,
          ),
        );
      }
    }

    for (final cs in _sections) {
      final lessonIds = cs.lessonIds.isNotEmpty
          ? cs.lessonIds
          : (extraBySection.remove(cs.id) ?? const <String>[]);
      merged.add(
        AcademySectionDefinition(
          id: cs.id,
          title: cs.title,
          subtitle: cs.subtitle,
          icon: AcademyIconRegistry.resolve(cs.iconName),
          lessonNodeIds: lessonIds,
          isPlaceholder: cs.isPlaceholder,
          unlockAfterNodeIds: cs.unlockAfterNodeIds,
        ),
      );
    }

    for (final entry in extraBySection.entries) {
      final lessons = entry.value;
      if (lessons.isEmpty) continue;
      merged.add(
        AcademySectionDefinition(
          id: entry.key,
          title: const <AppLanguage, String>{
            AppLanguage.ru: 'Дополнительно',
            AppLanguage.en: 'Extra',
            AppLanguage.de: 'Extra',
          },
          subtitle: const <AppLanguage, String>{
            AppLanguage.ru: 'Пользовательские уроки',
            AppLanguage.en: 'Custom lessons',
            AppLanguage.de: 'Eigene Lektionen',
          },
          icon: Icons.school_outlined,
          lessonNodeIds: lessons,
        ),
      );
    }

    return merged;
  }

  List<RemoteAcademyLesson> extraLessons() => List<RemoteAcademyLesson>.from(_lessons);

  // ——— Section lesson groups ———

  Future<void> saveSectionGroups(
    String sectionId,
    List<RemoteAcademyLessonGroup> groups,
  ) async {
    if (!canManage) throw StateError('forbidden');
    final normalized = <RemoteAcademyLessonGroup>[];
    for (var i = 0; i < groups.length; i++) {
      final g = groups[i];
      normalized.add(
        RemoteAcademyLessonGroup(
          id: g.id,
          title: g.title,
          lessonIds: g.lessonIds,
          sortOrder: i + 1,
        ),
      );
    }
    await _db.collection(kLayouts).doc(sectionId).set(<String, dynamic>{
      'sectionId': sectionId,
      'groups': normalized.map((g) => g.toMap()).toList(),
      'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<String> addSectionGroup(
    String sectionId,
    Map<AppLanguage, String> title,
  ) async {
    if (!canManage) throw StateError('forbidden');
    final current = List<RemoteAcademyLessonGroup>.from(
      _layoutsBySection[sectionId]?.groups ?? const <RemoteAcademyLessonGroup>[],
    );
    final id = 'grp_${DateTime.now().millisecondsSinceEpoch}';
    current.add(
      RemoteAcademyLessonGroup(
        id: id,
        title: title,
        lessonIds: const <String>[],
        sortOrder: current.length + 1,
      ),
    );
    await saveSectionGroups(sectionId, current);
    return id;
  }

  Future<void> updateSectionGroupTitle(
    String sectionId,
    String groupId,
    Map<AppLanguage, String> title,
  ) async {
    if (!canManage) throw StateError('forbidden');
    final current = List<RemoteAcademyLessonGroup>.from(
      _layoutsBySection[sectionId]?.groups ?? const <RemoteAcademyLessonGroup>[],
    );
    final idx = current.indexWhere((g) => g.id == groupId);
    if (idx < 0) return;
    current[idx] = current[idx].copyWith(title: title);
    await saveSectionGroups(sectionId, current);
  }

  Future<void> deleteSectionGroup(String sectionId, String groupId) async {
    if (!canManage) throw StateError('forbidden');
    final current = List<RemoteAcademyLessonGroup>.from(
      _layoutsBySection[sectionId]?.groups ?? const <RemoteAcademyLessonGroup>[],
    )..removeWhere((g) => g.id == groupId);
    if (current.isEmpty) {
      await _db.collection(kLayouts).doc(sectionId).delete();
    } else {
      await saveSectionGroups(sectionId, current);
    }
  }

  Future<void> moveLessonToGroup(
    String sectionId,
    String lessonId, {
    String? groupId,
  }) async {
    if (!canManage) throw StateError('forbidden');
    var current = List<RemoteAcademyLessonGroup>.from(
      _layoutsBySection[sectionId]?.groups ?? const <RemoteAcademyLessonGroup>[],
    );
    for (var i = 0; i < current.length; i++) {
      final ids = current[i].lessonIds.where((id) => id != lessonId).toList();
      if (ids.length != current[i].lessonIds.length) {
        current[i] = current[i].copyWith(lessonIds: ids);
      }
    }
    if (groupId != null) {
      final idx = current.indexWhere((g) => g.id == groupId);
      if (idx >= 0) {
        current[idx] = current[idx].copyWith(
          lessonIds: <String>[...current[idx].lessonIds, lessonId],
        );
      }
    }
    if (current.isEmpty) return;
    await saveSectionGroups(sectionId, current);
  }

  // ——— Creator CRUD ———

  Future<String> createSection({
    required Map<AppLanguage, String> title,
    required Map<AppLanguage, String> subtitle,
    required String iconName,
    List<String> unlockAfterNodeIds = const <String>[],
  }) async {
    if (!canManage) throw StateError('forbidden');
    final id = 'csec_${DateTime.now().millisecondsSinceEpoch}';
    final sortOrder = _sections.length + 1000;
    await _db.collection(kSections).doc(id).set(
          RemoteAcademySection(
            id: id,
            title: title,
            subtitle: subtitle,
            iconName: iconName,
            sortOrder: sortOrder,
            unlockAfterNodeIds: unlockAfterNodeIds,
            isPlaceholder: false,
            lessonIds: const <String>[],
          ).toMap(),
        );
    return id;
  }

  Future<void> updateSection(RemoteAcademySection section) async {
    if (!canManage) throw StateError('forbidden');
    await _db.collection(kSections).doc(section.id).set(section.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteSection(String sectionId) async {
    if (!canManage) throw StateError('forbidden');
    final lessons = _lessons.where((l) => l.sectionId == sectionId).toList();
    for (final l in lessons) {
      await deleteLesson(l.id);
    }
    await _db.collection(kSections).doc(sectionId).delete();
  }

  Future<String> createLesson({
    required String sectionId,
    required Map<AppLanguage, String> title,
    required String iconName,
    List<String> prerequisiteNodeIds = const <String>[],
  }) async {
    if (!canManage) throw StateError('forbidden');
    final id = 'cless_${DateTime.now().millisecondsSinceEpoch}';
    final sortOrder = lessonsForSection(sectionId).length + 1;
    await _db.collection(kLessons).doc(id).set(
          RemoteAcademyLesson(
            id: id,
            sectionId: sectionId,
            title: title,
            iconName: iconName,
            sortOrder: sortOrder,
            prerequisiteNodeIds: prerequisiteNodeIds,
          ).toMap(),
        );

    if (sectionId.startsWith('csec_')) {
      RemoteAcademySection? sec;
      for (final s in _sections) {
        if (s.id == sectionId) {
          sec = s;
          break;
        }
      }
      if (sec != null) {
        await updateSection(
          RemoteAcademySection(
            id: sec.id,
            title: sec.title,
            subtitle: sec.subtitle,
            iconName: sec.iconName,
            sortOrder: sec.sortOrder,
            unlockAfterNodeIds: sec.unlockAfterNodeIds,
            isPlaceholder: sec.isPlaceholder,
            lessonIds: <String>[...sec.lessonIds, id],
          ),
        );
      }
    }
    return id;
  }

  Future<void> updateLesson(RemoteAcademyLesson lesson) async {
    if (!canManage) throw StateError('forbidden');
    await _db.collection(kLessons).doc(lesson.id).set(lesson.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteLesson(String lessonId) async {
    if (!canManage) throw StateError('forbidden');
    final slides = _slidesByLesson[lessonId] ?? const <RemoteAcademySlide>[];
    for (final s in slides) {
      await _db.collection(kSlides).doc(s.id).delete();
    }
    await _db.collection(kLessons).doc(lessonId).delete();
  }

  Future<String> createSlide({
    required String lessonId,
    required String iconName,
    required Map<AppLanguage, String> title,
    required Map<AppLanguage, String> body,
    Map<AppLanguage, String>? highlight,
    bool isCompletion = false,
    LessonTrainerLaunchKind trainerLaunch = LessonTrainerLaunchKind.none,
    List<int>? imageBytes,
    String imageMime = 'image/jpeg',
  }) async {
    if (!canManage) throw StateError('forbidden');
    final id = 'cslide_${DateTime.now().millisecondsSinceEpoch}';
    final sortOrder = (_slidesByLesson[lessonId]?.length ?? 0) + 1;
    var imageData = '';
    if (imageBytes != null && imageBytes.isNotEmpty) {
      if (imageBytes.length > kMaxImageBytes) throw StateError('too_large');
      imageData = base64Encode(imageBytes);
    }
    await _db.collection(kSlides).doc(id).set(
          RemoteAcademySlide(
            id: id,
            lessonId: lessonId,
            sortOrder: sortOrder,
            iconName: iconName,
            title: title,
            body: body,
            highlight: highlight,
            isCompletion: isCompletion,
            trainerLaunch: trainerLaunch,
            imageData: imageData,
            imageMime: imageMime,
          ).toMap(),
        );
    return id;
  }

  Future<void> updateSlide(RemoteAcademySlide slide, {bool clearImage = false}) async {
    if (!canManage) throw StateError('forbidden');
    final data = slide.toMap();
    if (clearImage) {
      data['imageData'] = FieldValue.delete();
      data['imageMime'] = FieldValue.delete();
    }
    await _db.collection(kSlides).doc(slide.id).set(data, SetOptions(merge: true));
  }

  Future<void> deleteSlide(String slideId) async {
    if (!canManage) throw StateError('forbidden');
    await _db.collection(kSlides).doc(slideId).delete();
  }
}

Map<AppLanguage, String> _langMap(dynamic raw) {
  if (raw is! Map) {
    return const <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    };
  }
  return <AppLanguage, String>{
    AppLanguage.ru: (raw['ru'] ?? '').toString(),
    AppLanguage.en: (raw['en'] ?? '').toString(),
    AppLanguage.de: (raw['de'] ?? '').toString(),
  };
}

Map<String, String> _langToFirestore(Map<AppLanguage, String> map) => <String, String>{
      'ru': map[AppLanguage.ru] ?? '',
      'en': map[AppLanguage.en] ?? '',
      'de': map[AppLanguage.de] ?? '',
    };

List<String> _stringList(dynamic raw) {
  if (raw is! List) return const <String>[];
  return raw.map((e) => e.toString()).toList(growable: false);
}

LessonTrainerLaunchKind _trainerFromString(String raw) {
  for (final k in LessonTrainerLaunchKind.values) {
    if (k.name == raw) return k;
  }
  return LessonTrainerLaunchKind.none;
}
