import '../recovered_app.dart' show AppLanguage;

/// One lesson group inside an academy block (Firestore-backed).
class RemoteAcademyLessonGroup {
  const RemoteAcademyLessonGroup({
    required this.id,
    required this.title,
    required this.lessonIds,
    required this.sortOrder,
  });

  final String id;
  final Map<AppLanguage, String> title;
  final List<String> lessonIds;
  final int sortOrder;

  factory RemoteAcademyLessonGroup.fromMap(Map<String, dynamic> raw) {
    return RemoteAcademyLessonGroup(
      id: (raw['id'] ?? '').toString(),
      title: _langMap(raw['title']),
      lessonIds: _stringList(raw['lessonIds']),
      sortOrder: (raw['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'title': _langToFirestore(title),
        'lessonIds': lessonIds,
        'sortOrder': sortOrder,
      };

  RemoteAcademyLessonGroup copyWith({
    Map<AppLanguage, String>? title,
    List<String>? lessonIds,
    int? sortOrder,
  }) {
    return RemoteAcademyLessonGroup(
      id: id,
      title: title ?? this.title,
      lessonIds: lessonIds ?? this.lessonIds,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class RemoteAcademySectionLayout {
  const RemoteAcademySectionLayout({
    required this.sectionId,
    required this.groups,
  });

  final String sectionId;
  final List<RemoteAcademyLessonGroup> groups;

  factory RemoteAcademySectionLayout.fromMap(String sectionId, Map<String, dynamic> raw) {
    final groupsRaw = raw['groups'];
    final groups = groupsRaw is List
        ? groupsRaw
            .whereType<Map>()
            .map((g) => RemoteAcademyLessonGroup.fromMap(Map<String, dynamic>.from(g)))
            .toList()
        : const <RemoteAcademyLessonGroup>[];
    groups.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return RemoteAcademySectionLayout(sectionId: sectionId, groups: groups);
  }
}

/// Resolved group for UI — [title] null means no header (flat tail / default).
class AcademyLessonGroupView {
  const AcademyLessonGroupView({
    required this.lessonIds,
    this.title,
    this.groupId,
  });

  final Map<AppLanguage, String>? title;
  final List<String> lessonIds;
  final String? groupId;
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

List<AcademyLessonGroupView> resolveAcademyLessonGroups({
  required List<String> allLessonIds,
  required List<RemoteAcademyLessonGroup> groups,
}) {
  if (groups.isEmpty) {
    return [AcademyLessonGroupView(lessonIds: allLessonIds)];
  }

  final assigned = <String>{};
  final out = <AcademyLessonGroupView>[];
  for (final group in groups) {
    final ids = group.lessonIds.where(allLessonIds.contains).toList(growable: false);
    if (ids.isEmpty) continue;
    assigned.addAll(ids);
    out.add(
      AcademyLessonGroupView(
        title: group.title,
        lessonIds: ids,
        groupId: group.id,
      ),
    );
  }

  final rest = allLessonIds.where((id) => !assigned.contains(id)).toList(growable: false);
  if (rest.isNotEmpty) {
    out.add(AcademyLessonGroupView(lessonIds: rest));
  }
  return out.isEmpty ? [AcademyLessonGroupView(lessonIds: allLessonIds)] : out;
}
