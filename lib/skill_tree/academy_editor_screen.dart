import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../app/core/ui_feedback.dart';
import '../app_creator.dart';
import '../recovered_app.dart'
    show
        AppLanguage,
        AppTexts,
        FactsEditorScreen,
        appAccentColor,
        appLanguage,
        appPalette;
import 'academy_curriculum.dart';
import 'academy_icon_registry.dart';
import 'academy_remote_service.dart';
import 'academy_section_layout.dart';
import 'builtin_academy_slides.dart';
import 'custom_academy_lesson_screen.dart';
import 'lesson_framework.dart';

String _t(Map<AppLanguage, String> m) =>
    m[appLanguage.value] ?? m[AppLanguage.ru] ?? '';

void _showEditorError(BuildContext context, Map<AppLanguage, String> message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(_t(message)),
    ),
  );
}

Listenable get _academyListenable => AcademyRemoteService.instance.refreshListenable;

/// Creator-only CMS for academy blocks and lessons.
class AcademyEditorScreen extends StatefulWidget {
  const AcademyEditorScreen({super.key});

  @override
  State<AcademyEditorScreen> createState() => _AcademyEditorScreenState();
}

class _AcademyEditorScreenState extends State<AcademyEditorScreen> {
  @override
  void initState() {
    super.initState();
    AcademyRemoteService.instance.startWatching();
  }

  @override
  void dispose() {
    AcademyRemoteService.instance.stopWatching();
    super.dispose();
  }

  List<({String id, String title, bool custom})> get _sectionChoices {
    final out = <({String id, String title, bool custom})>[];
    for (final s in kAcademySections) {
      out.add((
        id: s.id,
        title: academyTranslate(s.title, appLanguage.value),
        custom: false,
      ));
    }
    for (final s in AcademyRemoteService.instance.customSections) {
      out.add((
        id: s.id,
        title: academyTranslate(s.title, appLanguage.value),
        custom: true,
      ));
    }
    return out;
  }

  Future<void> _createSection() async {
    final title = await _editLangTriple(
      title: _t(const {
        AppLanguage.ru: 'Новый блок',
        AppLanguage.en: 'New block',
        AppLanguage.de: 'Neuer Block',
      }),
      initial: const <AppLanguage, String>{
        AppLanguage.ru: 'Новый блок',
        AppLanguage.en: 'New block',
        AppLanguage.de: 'Neuer Block',
      },
    );
    if (title == null) return;
    final subtitle = await _editLangTriple(
      title: _t(const {
        AppLanguage.ru: 'Подзаголовок',
        AppLanguage.en: 'Subtitle',
        AppLanguage.de: 'Untertitel',
      }),
      initial: const <AppLanguage, String>{
        AppLanguage.ru: 'Описание блока',
        AppLanguage.en: 'Block description',
        AppLanguage.de: 'Blockbeschreibung',
      },
    );
    if (subtitle == null) return;
    final icon = await _pickIcon(Icons.folder_outlined);
    if (icon == null) return;
    try {
      await AcademyRemoteService.instance.createSection(
        title: title,
        subtitle: subtitle,
        iconName: icon,
      );
    } catch (_) {}
  }

  Future<void> _addLessonToSection(String sectionId) async {
    final title = await _editLangTriple(
      title: _t(const {
        AppLanguage.ru: 'Название урока',
        AppLanguage.en: 'Lesson title',
        AppLanguage.de: 'Lektionstitel',
      }),
      initial: const <AppLanguage, String>{
        AppLanguage.ru: 'Новый урок',
        AppLanguage.en: 'New lesson',
        AppLanguage.de: 'Neue Lektion',
      },
    );
    if (title == null) return;
    final icon = await _pickIcon(Icons.school_outlined);
    if (icon == null) return;
    final prereqRaw = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: Text(_t(const {
            AppLanguage.ru: 'Предусловия (id через запятую)',
            AppLanguage.en: 'Prerequisites (comma-separated ids)',
            AppLanguage.de: 'Voraussetzungen (IDs, Komma)',
          })),
          content: TextField(
            controller: c,
            decoration: InputDecoration(
              hintText: _t(const {
                AppLanguage.ru: 'например: m3, task_association',
                AppLanguage.en: 'e.g. m3, task_association',
                AppLanguage.de: 'z.B. m3, task_association',
              }),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, ''), child: const Text('OK')),
          ],
        );
      },
    );
    final prereqs = (prereqRaw ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    try {
      final id = await AcademyRemoteService.instance.createLesson(
        sectionId: sectionId,
        title: title,
        iconName: icon,
        prerequisiteNodeIds: prereqs,
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => _LessonEditorScreen(lessonId: id),
        ),
      );
    } catch (_) {}
  }

  Future<String?> _pickIcon(IconData initial) async {
    final names = AcademyIconRegistry.names;
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          maxChildSize: 0.9,
          builder: (_, scroll) {
            return ListView.builder(
              controller: scroll,
              itemCount: names.length,
              itemBuilder: (_, i) {
                final name = names[i];
                final icon = AcademyIconRegistry.resolve(name);
                return ListTile(
                  leading: Icon(icon),
                  title: Text(name, style: const TextStyle(fontSize: 12)),
                  onTap: () => Navigator.pop(ctx, name),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<Map<AppLanguage, String>?> _editLangTriple({
    required String title,
    required Map<AppLanguage, String> initial,
  }) async {
    final ru = TextEditingController(text: initial[AppLanguage.ru]);
    final en = TextEditingController(text: initial[AppLanguage.en]);
    final de = TextEditingController(text: initial[AppLanguage.de]);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ru,
                decoration: const InputDecoration(labelText: 'RU'),
                maxLines: 3,
              ),
              TextField(
                controller: en,
                decoration: const InputDecoration(labelText: 'EN'),
                maxLines: 3,
              ),
              TextField(
                controller: de,
                decoration: const InputDecoration(labelText: 'DE'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
        ],
      ),
    );
    if (ok != true) {
      ru.dispose();
      en.dispose();
      de.dispose();
      return null;
    }
    final out = <AppLanguage, String>{
      AppLanguage.ru: ru.text.trim(),
      AppLanguage.en: en.text.trim(),
      AppLanguage.de: de.text.trim(),
    };
    ru.dispose();
    en.dispose();
    de.dispose();
    return out;
  }

  @override
  Widget build(BuildContext context) {
    if (!AppCreator.isCurrentUser) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Forbidden')),
      );
    }

    final palette = appPalette.value;
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        title: Text(
          _t(const {
            AppLanguage.ru: 'РЕДАКТОР АКАДЕМИИ',
            AppLanguage.en: 'ACADEMY EDITOR',
            AppLanguage.de: 'AKADEMIE-EDITOR',
          }),
          style: TextStyle(
            color: onSurface.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createSection,
        backgroundColor: accent,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: AnimatedBuilder(
        animation: _academyListenable,
        builder: (_, __) {
          final customSections = AcademyRemoteService.instance.customSections;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            children: [
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(Icons.fact_check_outlined, color: accent),
                  title: Text(
                    _t(const {
                      AppLanguage.ru: 'Факты и вопросы',
                      AppLanguage.en: 'Facts and questions',
                      AppLanguage.de: 'Fakten und Fragen',
                    }),
                  ),
                  subtitle: Text(
                    _t(const {
                      AppLanguage.ru: 'Редактор нового тренажера фактов',
                      AppLanguage.en: 'Editor for the new facts trainer',
                      AppLanguage.de: 'Editor fuer den Fakten-Trainer',
                    }),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const FactsEditorScreen(),
                      ),
                    );
                  },
                ),
              ),
              Text(
                _t(const {
                  AppLanguage.ru: 'Готовые блоки — уроки',
                  AppLanguage.en: 'Built-in blocks — lessons',
                  AppLanguage.de: 'Eingebaute Blöcke — Lektionen',
                }),
                style: TextStyle(color: onSurface.withOpacity(0.55), fontSize: 12),
              ),
              const SizedBox(height: 8),
              ...kAcademySections.map((s) => _sectionTile(s.id, s.title, s.icon, false)),
              const SizedBox(height: 20),
              Text(
                _t(const {
                  AppLanguage.ru: 'Мои блоки',
                  AppLanguage.en: 'My blocks',
                  AppLanguage.de: 'Meine Blöcke',
                }),
                style: TextStyle(color: onSurface.withOpacity(0.55), fontSize: 12),
              ),
              const SizedBox(height: 8),
              if (customSections.isEmpty)
                Text(
                  _t(const {
                    AppLanguage.ru: 'Нажми + чтобы создать блок',
                    AppLanguage.en: 'Tap + to create a block',
                    AppLanguage.de: 'Tippe + für einen Block',
                  }),
                  style: TextStyle(color: onSurface.withOpacity(0.4)),
                ),
              for (final s in customSections)
                _sectionTile(s.id, s.title, AcademyIconRegistry.resolve(s.iconName), true),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTile(
    String id,
    Map<AppLanguage, String> title,
    IconData icon,
    bool custom,
  ) {
    final accent = appAccentColor.value;
    final remote = AcademyRemoteService.instance;
    final lessonCount = remote.lessonsForSection(id).length;
    final isPremium = remote.isSectionPremium(id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: accent),
        title: Text(AppTexts.translate(title)),
        subtitle: Text(
          isPremium
              ? _t(const {
                  AppLanguage.ru: 'Premium-блок',
                  AppLanguage.en: 'Premium block',
                  AppLanguage.de: 'Premium-Block',
                })
              : '$lessonCount ${_t(const {
                  AppLanguage.ru: 'доп. уроков',
                  AppLanguage.en: 'extra lessons',
                  AppLanguage.de: 'Extra-Lektionen',
                })}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isPremium
                    ? Icons.workspace_premium_rounded
                    : Icons.workspace_premium_outlined,
                color: isPremium ? accent : null,
              ),
              tooltip: _t(const {
                AppLanguage.ru: 'Premium-блок',
                AppLanguage.en: 'Premium block',
                AppLanguage.de: 'Premium-Block',
              }),
              onPressed: () async {
                try {
                  await remote.setSectionPremium(id, !isPremium);
                } catch (_) {
                  if (!context.mounted) return;
                  _showEditorError(context, const {
                    AppLanguage.ru: 'Не удалось сохранить Premium. Проверь вход и правила Firestore.',
                    AppLanguage.en: 'Could not save Premium. Check sign-in and Firestore rules.',
                    AppLanguage.de: 'Premium konnte nicht gespeichert werden.',
                  });
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.post_add_outlined),
              tooltip: _t(const {
                AppLanguage.ru: 'Добавить урок',
                AppLanguage.en: 'Add lesson',
                AppLanguage.de: 'Lektion',
              }),
              onPressed: () => _addLessonToSection(id),
            ),
            if (custom)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await AcademyRemoteService.instance.deleteSection(id);
                },
              ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => _SectionLessonsScreen(
                sectionId: id,
                sectionTitle: title,
                includeBuiltinLessons: !custom,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionLessonsScreen extends StatefulWidget {
  const _SectionLessonsScreen({
    required this.sectionId,
    required this.sectionTitle,
    this.includeBuiltinLessons = false,
  });

  final String sectionId;
  final Map<AppLanguage, String> sectionTitle;
  final bool includeBuiltinLessons;

  @override
  State<_SectionLessonsScreen> createState() => _SectionLessonsScreenState();
}

class _SectionLessonsScreenState extends State<_SectionLessonsScreen> {
  List<String> get _builtinIds {
    if (!widget.includeBuiltinLessons) return const <String>[];
    for (final section in kAcademySections) {
      if (section.id == widget.sectionId) return section.lessonNodeIds;
    }
    return const <String>[];
  }

  List<String> _allLessonIds(List<RemoteAcademyLesson> customLessons) {
    return <String>[..._builtinIds, ...customLessons.map((l) => l.id)];
  }

  Set<String> _groupedLessonIds(List<RemoteAcademyLessonGroup> groups) {
    return groups.expand((g) => g.lessonIds).toSet();
  }

  String _lessonTitle(String lessonId, List<RemoteAcademyLesson> customLessons) {
    for (final lesson in customLessons) {
      if (lesson.id == lessonId) {
        return AppTexts.translate(lesson.title);
      }
    }
    final builtin = builtinSlidesForLesson(lessonId);
    if (builtin != null && builtin.isNotEmpty) {
      final title = AppTexts.translate(builtin.first.title).trim();
      if (title.isNotEmpty) return title;
    }
    return lessonId;
  }

  Future<Map<AppLanguage, String>?> _editLangTriple({
    required String title,
    Map<AppLanguage, String>? initial,
  }) async {
    final init = initial ??
        const <AppLanguage, String>{
          AppLanguage.ru: '',
          AppLanguage.en: '',
          AppLanguage.de: '',
        };
    final ru = TextEditingController(text: init[AppLanguage.ru]);
    final en = TextEditingController(text: init[AppLanguage.en]);
    final de = TextEditingController(text: init[AppLanguage.de]);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: ru, decoration: const InputDecoration(labelText: 'RU'), maxLines: 2),
              TextField(controller: en, decoration: const InputDecoration(labelText: 'EN'), maxLines: 2),
              TextField(controller: de, decoration: const InputDecoration(labelText: 'DE'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
        ],
      ),
    );
    if (ok != true) {
      ru.dispose();
      en.dispose();
      de.dispose();
      return null;
    }
    final out = <AppLanguage, String>{
      AppLanguage.ru: ru.text.trim(),
      AppLanguage.en: en.text.trim(),
      AppLanguage.de: de.text.trim(),
    };
    ru.dispose();
    en.dispose();
    de.dispose();
    return out;
  }

  Future<void> _addGroup() async {
    final title = await _editLangTriple(
      title: _t(const {
        AppLanguage.ru: 'Название группы',
        AppLanguage.en: 'Group title',
        AppLanguage.de: 'Gruppentitel',
      }),
      initial: const <AppLanguage, String>{
        AppLanguage.ru: 'Новая группа',
        AppLanguage.en: 'New group',
        AppLanguage.de: 'Neue Gruppe',
      },
    );
    if (title == null) return;
    await AcademyRemoteService.instance.addSectionGroup(widget.sectionId, title);
  }

  Future<void> _editGroup(RemoteAcademyLessonGroup group) async {
    final title = await _editLangTriple(
      title: _t(const {
        AppLanguage.ru: 'Название группы',
        AppLanguage.en: 'Group title',
        AppLanguage.de: 'Gruppentitel',
      }),
      initial: group.title,
    );
    if (title == null) return;
    await AcademyRemoteService.instance.updateSectionGroupTitle(
      widget.sectionId,
      group.id,
      title,
    );
  }

  Future<void> _deleteGroup(RemoteAcademyLessonGroup group) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t(const {
          AppLanguage.ru: 'Удалить группу?',
          AppLanguage.en: 'Delete group?',
          AppLanguage.de: 'Gruppe loeschen?',
        })),
        content: Text(_t(const {
          AppLanguage.ru: 'Уроки останутся в блоке без группы.',
          AppLanguage.en: 'Lessons will stay in the block, ungrouped.',
          AppLanguage.de: 'Lektionen bleiben im Block, ohne Gruppe.',
        })),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
        ],
      ),
    );
    if (ok == true) {
      await AcademyRemoteService.instance.deleteSectionGroup(widget.sectionId, group.id);
    }
  }

  Future<void> _pickGroupForLesson(
    String lessonId,
    List<RemoteAcademyLessonGroup> groups,
  ) async {
    final picked = await showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(_t(const {
                  AppLanguage.ru: 'Без группы',
                  AppLanguage.en: 'No group',
                  AppLanguage.de: 'Keine Gruppe',
                })),
                onTap: () => Navigator.pop(ctx, ''),
              ),
              for (final group in groups)
                ListTile(
                  title: Text(AppTexts.translate(group.title)),
                  onTap: () => Navigator.pop(ctx, group.id),
                ),
            ],
          ),
        );
      },
    );
    if (picked == null) return;
    await AcademyRemoteService.instance.moveLessonToGroup(
      widget.sectionId,
      lessonId,
      groupId: picked.isEmpty ? null : picked,
    );
  }

  Future<void> _addLessonToSection() async {
    final state = context.findAncestorStateOfType<_AcademyEditorScreenState>();
    if (state != null) {
      await state._addLessonToSection(widget.sectionId);
    }
  }

  Widget _lessonTile({
    required String lessonId,
    required List<RemoteAcademyLesson> customLessons,
    required List<RemoteAcademyLessonGroup> groups,
    required bool isCustom,
  }) {
    final remote = AcademyRemoteService.instance;
    final accent = appAccentColor.value;
    final hasOverride = remote.hasRemoteOverride(lessonId);
    final canImport = hasBuiltinAcademySlides(lessonId) && !hasOverride;
    final title = _lessonTitle(lessonId, customLessons);
    final isPremium = remote.isLessonPremium(lessonId);

    return ListTile(
      leading: Icon(
        isCustom
            ? AcademyIconRegistry.resolve(
                customLessons.firstWhere((l) => l.id == lessonId).iconName,
              )
            : Icons.menu_book_outlined,
      ),
      title: Text(title),
      subtitle: Text(
        isPremium
            ? _t(const {
                AppLanguage.ru: 'Premium-урок',
                AppLanguage.en: 'Premium lesson',
                AppLanguage.de: 'Premium-Lektion',
              })
            : isCustom
                ? _t(const {
                    AppLanguage.ru: 'Новый урок',
                    AppLanguage.en: 'Custom lesson',
                    AppLanguage.de: 'Eigene Lektion',
                  })
                : hasOverride
                    ? _t(const {
                        AppLanguage.ru: 'Встроенный · отредактирован',
                        AppLanguage.en: 'Built-in · edited',
                        AppLanguage.de: 'Eingebaut · bearbeitet',
                      })
                    : _t(const {
                        AppLanguage.ru: 'Встроенный · из приложения',
                        AppLanguage.en: 'Built-in · from app',
                        AppLanguage.de: 'Eingebaut · aus App',
                      }),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              isPremium
                  ? Icons.workspace_premium_rounded
                  : Icons.workspace_premium_outlined,
              color: isPremium ? accent : null,
            ),
            tooltip: _t(const {
              AppLanguage.ru: 'Premium-урок',
              AppLanguage.en: 'Premium lesson',
              AppLanguage.de: 'Premium-Lektion',
            }),
            onPressed: () async {
              try {
                await remote.setLessonPremium(lessonId, !isPremium);
              } catch (_) {
                if (!context.mounted) return;
                _showEditorError(context, const {
                  AppLanguage.ru: 'Не удалось сохранить Premium. Проверь вход и правила Firestore.',
                  AppLanguage.en: 'Could not save Premium. Check sign-in and Firestore rules.',
                  AppLanguage.de: 'Premium konnte nicht gespeichert werden.',
                });
              }
            },
          ),
          if (groups.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.drive_file_move_outline),
              tooltip: _t(const {
                AppLanguage.ru: 'Переместить в группу',
                AppLanguage.en: 'Move to group',
                AppLanguage.de: 'In Gruppe verschieben',
              }),
              onPressed: () => _pickGroupForLesson(lessonId, groups),
            ),
          if (canImport)
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: _t(const {
                AppLanguage.ru: 'Импорт из приложения',
                AppLanguage.en: 'Import from app',
                AppLanguage.de: 'Aus App importieren',
              }),
              onPressed: () => remote.importBuiltinSlides(lessonId),
            ),
          if (isCustom)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => remote.deleteLesson(lessonId),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => _LessonEditorScreen(lessonId: lessonId),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppTexts.translate(widget.sectionTitle)),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: _t(const {
              AppLanguage.ru: 'Новая группа',
              AppLanguage.en: 'New group',
              AppLanguage.de: 'Neue Gruppe',
            }),
            onPressed: _addGroup,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addLessonToSection,
        child: const Icon(Icons.add_rounded),
      ),
      body: AnimatedBuilder(
        animation: _academyListenable,
        builder: (_, __) {
          final remote = AcademyRemoteService.instance;
          final customLessons = remote.lessonsForSection(widget.sectionId);
          final allIds = _allLessonIds(customLessons);
          final groups = remote.sectionLayout(widget.sectionId)?.groups ??
              const <RemoteAcademyLessonGroup>[];
          final grouped = _groupedLessonIds(groups);
          final ungrouped = allIds.where((id) => !grouped.contains(id)).toList();

          if (allIds.isEmpty) {
            return Center(
              child: Text(_t(const {
                AppLanguage.ru: 'Нет уроков в этом блоке',
                AppLanguage.en: 'No lessons in this block',
                AppLanguage.de: 'Keine Lektionen in diesem Block',
              })),
            );
          }

          final children = <Widget>[
            if (groups.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  _t(const {
                    AppLanguage.ru: 'Создай группы, чтобы разделить уроки для всех пользователей',
                    AppLanguage.en: 'Create groups to organize lessons for all users',
                    AppLanguage.de: 'Erstelle Gruppen fuer alle Nutzer',
                  }),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ),
            for (final group in groups) ...[
              Card(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      title: Text(
                        AppTexts.translate(group.title),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _editGroup(group),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteGroup(group),
                          ),
                        ],
                      ),
                    ),
                    if (group.lessonIds.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Text(
                          _t(const {
                            AppLanguage.ru: 'Перемести сюда уроки кнопкой со стрелкой',
                            AppLanguage.en: 'Move lessons here with the arrow button',
                            AppLanguage.de: 'Lektionen mit dem Pfeil hierher verschieben',
                          }),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      for (final lessonId in group.lessonIds)
                        _lessonTile(
                          lessonId: lessonId,
                          customLessons: customLessons,
                          groups: groups,
                          isCustom: lessonId.startsWith('cless_'),
                        ),
                  ],
                ),
              ),
            ],
            if (ungrouped.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  groups.isEmpty
                      ? _t(const {
                          AppLanguage.ru: 'Уроки',
                          AppLanguage.en: 'Lessons',
                          AppLanguage.de: 'Lektionen',
                        })
                      : _t(const {
                          AppLanguage.ru: 'Без группы',
                          AppLanguage.en: 'Ungrouped',
                          AppLanguage.de: 'Ohne Gruppe',
                        }),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              for (final lessonId in ungrouped)
                _lessonTile(
                  lessonId: lessonId,
                  customLessons: customLessons,
                  groups: groups,
                  isCustom: lessonId.startsWith('cless_'),
                ),
            ],
            const SizedBox(height: 88),
          ];

          return ListView(children: children);
        },
      ),
    );
  }
}

class _LessonEditorScreen extends StatefulWidget {
  const _LessonEditorScreen({required this.lessonId});

  final String lessonId;

  @override
  State<_LessonEditorScreen> createState() => _LessonEditorScreenState();
}

class _LessonEditorScreenState extends State<_LessonEditorScreen> {
  Future<void> _importBuiltinIfNeeded() async {
    if (AcademyRemoteService.instance.hasRemoteOverride(widget.lessonId)) return;
    if (!hasBuiltinAcademySlides(widget.lessonId)) return;
    await AcademyRemoteService.instance.importBuiltinSlides(widget.lessonId);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final accent = appAccentColor.value;
    final remote = AcademyRemoteService.instance;
    final remoteSlides = remote.rawSlidesForLesson(widget.lessonId);
    final canImport =
        remoteSlides.isEmpty && hasBuiltinAcademySlides(widget.lessonId);

    return Scaffold(
      appBar: AppBar(
        title: Text(_t(const {
          AppLanguage.ru: 'Слайды урока',
          AppLanguage.en: 'Lesson slides',
          AppLanguage.de: 'Lektionsfolien',
        })),
        actions: [
          if (canImport)
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: _t(const {
                AppLanguage.ru: 'Импорт из приложения',
                AppLanguage.en: 'Import from app',
                AppLanguage.de: 'Aus App importieren',
              }),
              onPressed: _importBuiltinIfNeeded,
            ),
          IconButton(
            icon: const Icon(Icons.play_arrow_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => CustomAcademyLessonScreen(lessonId: widget.lessonId),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: accent,
        onPressed: () => _addSlide(),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: AnimatedBuilder(
        animation: remote.refreshListenable,
        builder: (_, __) {
          final slides = remote.rawSlidesForLesson(widget.lessonId);
          if (slides.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_t(const {
                      AppLanguage.ru: 'Добавь первый слайд или импортируй встроенный урок',
                      AppLanguage.en: 'Add the first slide or import the built-in lesson',
                      AppLanguage.de: 'Erste Folie hinzufügen oder eingebaute Lektion importieren',
                    })),
                    if (canImport) ...[
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _importBuiltinIfNeeded,
                        icon: const Icon(Icons.download_outlined),
                        label: Text(_t(const {
                          AppLanguage.ru: 'Импорт из приложения',
                          AppLanguage.en: 'Import from app',
                          AppLanguage.de: 'Aus App importieren',
                        })),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: slides.length,
            itemBuilder: (_, i) {
              final s = slides[i];
              return ListTile(
                key: ValueKey(s.id),
                leading: Icon(AcademyIconRegistry.resolve(s.iconName)),
                title: Text(
                  AppTexts.translate(s.title).isEmpty
                      ? AppTexts.translate(s.body).split('\n').first
                      : AppTexts.translate(s.title),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(s.isCompletion ? '✓ completion' : 'slide ${i + 1}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => remote.deleteSlide(s.id),
                ),
                onTap: () => _editSlide(s),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addSlide() => _editSlide(null);

  Future<void> _editSlide(RemoteAcademySlide? existing) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SlideComposeSheet(
        lessonId: widget.lessonId,
        existing: existing,
      ),
    );
    if (mounted) setState(() {});
  }
}

// Need to expose raw slides from service - I'll add a method

class _SlideComposeSheet extends StatefulWidget {
  const _SlideComposeSheet({required this.lessonId, this.existing});

  final String lessonId;
  final RemoteAcademySlide? existing;

  @override
  State<_SlideComposeSheet> createState() => _SlideComposeSheetState();
}

class _SlideComposeSheetState extends State<_SlideComposeSheet> {
  late final TextEditingController _ruTitle;
  late final TextEditingController _enTitle;
  late final TextEditingController _deTitle;
  late final TextEditingController _ruBody;
  late final TextEditingController _enBody;
  late final TextEditingController _deBody;
  late final TextEditingController _ruHl;
  late final TextEditingController _enHl;
  late final TextEditingController _deHl;
  String _iconName = 'school_outlined';
  bool _isCompletion = false;
  LessonTrainerLaunchKind _trainer = LessonTrainerLaunchKind.none;
  Uint8List? _imageBytes;
  bool _imageRemoved = false;
  bool _saving = false;

  bool get _hasImagePreview =>
      _imageBytes != null && _imageBytes!.isNotEmpty && !_imageRemoved;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _ruTitle = TextEditingController(text: e?.title[AppLanguage.ru] ?? '');
    _enTitle = TextEditingController(text: e?.title[AppLanguage.en] ?? '');
    _deTitle = TextEditingController(text: e?.title[AppLanguage.de] ?? '');
    _ruBody = TextEditingController(text: e?.body[AppLanguage.ru] ?? '');
    _enBody = TextEditingController(text: e?.body[AppLanguage.en] ?? '');
    _deBody = TextEditingController(text: e?.body[AppLanguage.de] ?? '');
    _ruHl = TextEditingController(text: e?.highlight?[AppLanguage.ru] ?? '');
    _enHl = TextEditingController(text: e?.highlight?[AppLanguage.en] ?? '');
    _deHl = TextEditingController(text: e?.highlight?[AppLanguage.de] ?? '');
    _iconName = e?.iconName ?? 'school_outlined';
    _isCompletion = e?.isCompletion ?? false;
    _trainer = e?.trainerLaunch ?? LessonTrainerLaunchKind.none;
    if (e != null && e.imageBytes != null) _imageBytes = e.imageBytes;
  }

  void _removeImage() {
    setState(() {
      _imageBytes = null;
      _imageRemoved = true;
    });
  }

  @override
  void dispose() {
    _ruTitle.dispose();
    _enTitle.dispose();
    _deTitle.dispose();
    _ruBody.dispose();
    _enBody.dispose();
    _deBody.dispose();
    _ruHl.dispose();
    _enHl.dispose();
    _deHl.dispose();
    super.dispose();
  }

  Map<AppLanguage, String> _map(TextEditingController ru, en, de) => <AppLanguage, String>{
        AppLanguage.ru: ru.text,
        AppLanguage.en: en.text,
        AppLanguage.de: de.text,
      };

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1200,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) {
      setState(() {
        _imageBytes = bytes;
        _imageRemoved = false;
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    appHaptic(UiClickSound.soft);
    try {
      final title = _map(_ruTitle, _enTitle, _deTitle);
      final body = _map(_ruBody, _enBody, _deBody);
      final hlRu = _ruHl.text.trim();
      final highlight = (hlRu.isEmpty &&
              _enHl.text.trim().isEmpty &&
              _deHl.text.trim().isEmpty)
          ? null
          : _map(_ruHl, _enHl, _deHl);

      if (widget.existing == null) {
        await AcademyRemoteService.instance.createSlide(
          lessonId: widget.lessonId,
          iconName: _iconName,
          title: title,
          body: body,
          highlight: highlight,
          isCompletion: _isCompletion,
          trainerLaunch: _trainer,
          imageBytes: _imageBytes,
        );
      } else {
        final clearImage = _imageRemoved;
        var imageData = clearImage ? '' : widget.existing!.imageData;
        var imageMime = clearImage ? 'image/jpeg' : widget.existing!.imageMime;
        if (_imageBytes != null && _imageBytes!.isNotEmpty) {
          if (_imageBytes!.length > AcademyRemoteService.kMaxImageBytes) {
            throw StateError('too_large');
          }
          imageData = base64Encode(_imageBytes!);
          imageMime = 'image/jpeg';
        }
        await AcademyRemoteService.instance.updateSlide(
          RemoteAcademySlide(
            id: widget.existing!.id,
            lessonId: widget.lessonId,
            sortOrder: widget.existing!.sortOrder,
            iconName: _iconName,
            title: title,
            body: body,
            highlight: highlight,
            isCompletion: _isCompletion,
            trainerLaunch: _trainer,
            imageData: imageData,
            imageMime: imageMime,
          ),
          clearImage: clearImage,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {}
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final palette = appPalette.value;
    final accent = appAccentColor.value;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_t(const {
                AppLanguage.ru: 'Слайд (эмодзи в тексте 😊)',
                AppLanguage.en: 'Slide (emoji in text 😊)',
                AppLanguage.de: 'Folie (Emoji im Text 😊)',
              })),
              const SizedBox(height: 10),
              DropdownButtonFormField<LessonTrainerLaunchKind>(
                value: _trainer,
                decoration: const InputDecoration(labelText: 'Trainer link (final slide)'),
                items: LessonTrainerLaunchKind.values
                    .map(
                      (k) => DropdownMenuItem(
                        value: k,
                        child: Text(k.name, style: const TextStyle(fontSize: 11)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _trainer = v);
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(AcademyIconRegistry.resolve(_iconName)),
                  TextButton(
                    onPressed: () async {
                      final name = await showModalBottomSheet<String>(
                        context: context,
                        builder: (c) => SizedBox(
                          height: 300,
                          child: ListView(
                            children: AcademyIconRegistry.names
                                .map(
                                  (n) => ListTile(
                                    leading: Icon(AcademyIconRegistry.resolve(n)),
                                    title: Text(n),
                                    onTap: () => Navigator.pop(c, n),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      );
                      if (name != null) setState(() => _iconName = name);
                    },
                    child: const Text('Icon'),
                  ),
                  Switch(
                    value: _isCompletion,
                    onChanged: (v) => setState(() => _isCompletion = v),
                  ),
                  const Text('Final'),
                ],
              ),
              _langFields('Title RU', _ruTitle),
              _langFields('Title EN', _enTitle),
              _langFields('Title DE', _deTitle),
              _langFields('Body RU', _ruBody, maxLines: 5),
              _langFields('Body EN', _enBody, maxLines: 5),
              _langFields('Body DE', _deBody, maxLines: 5),
              _langFields('Highlight RU', _ruHl),
              _langFields('Highlight EN', _enHl),
              _langFields('Highlight DE', _deHl),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_outlined),
                    label: Text(_t(const {
                      AppLanguage.ru: 'Фото',
                      AppLanguage.en: 'Photo',
                      AppLanguage.de: 'Foto',
                    })),
                  ),
                  if (_hasImagePreview) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: _t(const {
                        AppLanguage.ru: 'Удалить фото',
                        AppLanguage.en: 'Remove photo',
                        AppLanguage.de: 'Foto entfernen',
                      }),
                      onPressed: _removeImage,
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    ),
                  ],
                ],
              ),
              if (_hasImagePreview) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    _imageBytes!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(backgroundColor: accent),
                child: Text(_saving ? '...' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langFields(String label, TextEditingController c, {int maxLines = 2}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, isDense: true),
      ),
    );
  }
}
