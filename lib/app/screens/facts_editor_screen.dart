part of 'package:flutter_application_1/recovered_app.dart';

String _difficultyLabel(FactDifficulty value) {
  switch (value) {
    case FactDifficulty.easy:
      return 'Easy';
    case FactDifficulty.medium:
      return 'Medium';
    case FactDifficulty.hard:
      return 'Hard';
    case FactDifficulty.expert:
      return 'Expert';
  }
}

String _categoryLabel(FactCategory value) {
  switch (value) {
    case FactCategory.science:
      return 'Science';
    case FactCategory.history:
      return 'History';
    case FactCategory.psychology:
      return 'Psychology';
    case FactCategory.random:
      return 'Random';
    case FactCategory.language:
      return 'Language';
    case FactCategory.philosophy:
      return 'Philosophy';
  }
}

class FactsEditorScreen extends StatefulWidget {
  const FactsEditorScreen({super.key});

  @override
  State<FactsEditorScreen> createState() => _FactsEditorScreenState();
}

class FactEditorScreen extends FactsEditorScreen {
  const FactEditorScreen({super.key});
}

class _FactsEditorScreenState extends State<FactsEditorScreen> {
  Future<List<FactEntry>>? _factsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  String _t(Map<AppLanguage, String> map) =>
      map[appLanguage.value] ?? map[AppLanguage.ru] ?? '';

  void _reload() {
    setState(() {
      _factsFuture = FactsRepository.instance
          .loadFacts()
          .timeout(const Duration(seconds: 15));
    });
  }

  Future<void> _openEditor(FactEntry? existing, int defaultOrder) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _FactEditorPage(
          existing: existing,
          defaultOrder: defaultOrder,
        ),
      ),
    );
    if (changed == true) _reload();
  }

  Future<void> _confirmDelete(FactEntry item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t(const {
          AppLanguage.ru: 'Удалить факт?',
          AppLanguage.en: 'Delete fact?',
          AppLanguage.de: 'Fakt loeschen?',
        })),
        content: Text(_t(item.fact)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_t(const {
              AppLanguage.ru: 'Отмена',
              AppLanguage.en: 'Cancel',
              AppLanguage.de: 'Abbrechen',
            })),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_t(const {
              AppLanguage.ru: 'Удалить',
              AppLanguage.en: 'Delete',
              AppLanguage.de: 'Loeschen',
            })),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await FactsRepository.instance.deleteFact(item.id);
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_t(const {
          AppLanguage.ru: 'Ошибка удаления',
          AppLanguage.en: 'Delete failed',
          AppLanguage.de: 'Loeschen fehlgeschlagen',
        })}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = appAccentColor.value;

    if (!AppCreator.isCurrentUser) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Forbidden')),
      );
    }

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          _t(const {
            AppLanguage.ru: 'РЕДАКТОР ФАКТОВ',
            AppLanguage.en: 'FACTS EDITOR',
            AppLanguage.de: 'FAKTEN-EDITOR',
          }),
          style: TextStyle(
            color: onSurface,
            fontSize: 13,
            letterSpacing: 2.2,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: onSurface.withOpacity(0.7)),
            onPressed: _reload,
          ),
        ],
      ),
      floatingActionButton: FutureBuilder<List<FactEntry>>(
        future: _factsFuture,
        builder: (_, snap) {
          final next = (snap.data?.length ?? 0) + 1;
          return FloatingActionButton.extended(
            backgroundColor: accent,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              _t(const {
                AppLanguage.ru: 'Новый факт',
                AppLanguage.en: 'New fact',
                AppLanguage.de: 'Neuer Fakt',
              }),
              style: const TextStyle(color: Colors.white),
            ),
            onPressed: () => _openEditor(null, next),
          );
        },
      ),
      body: FutureBuilder<List<FactEntry>>(
        future: _factsFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(
                    _t(const {
                      AppLanguage.ru: 'Загружаем факты...',
                      AppLanguage.en: 'Loading facts...',
                      AppLanguage.de: 'Fakten werden geladen...',
                    }),
                    style: TextStyle(color: onSurface.withOpacity(0.65)),
                  ),
                ],
              ),
            );
          }
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded, color: onSurface.withOpacity(0.65), size: 36),
                    const SizedBox(height: 12),
                    Text(
                      _t(const {
                        AppLanguage.ru: 'Не удалось загрузить факты.',
                        AppLanguage.en: 'Failed to load facts.',
                        AppLanguage.de: 'Fakten konnten nicht geladen werden.',
                      }),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: onSurface.withOpacity(0.85), fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snap.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: onSurface.withOpacity(0.55), fontSize: 11),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _reload,
                      child: Text(_t(const {
                        AppLanguage.ru: 'Повторить',
                        AppLanguage.en: 'Retry',
                        AppLanguage.de: 'Erneut',
                      })),
                    ),
                  ],
                ),
              ),
            );
          }
          final list = snap.data ?? const <FactEntry>[];
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fact_check_outlined, color: onSurface.withOpacity(0.45), size: 36),
                    const SizedBox(height: 12),
                    Text(
                      _t(const {
                        AppLanguage.ru: 'Пока нет фактов. Нажми «Новый факт».',
                        AppLanguage.en: 'No facts yet. Tap “New fact”.',
                        AppLanguage.de: 'Noch keine Fakten. „Neuer Fakt“ tippen.',
                      }),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: onSurface.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final item = list[i];
              final factText = _t(item.fact).trim();
              final questionCount = item.questions.length;
              return Material(
                color: palette.surface,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openEditor(item, item.sortOrder),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withOpacity(0.14),
                            border: Border.all(color: accent.withOpacity(0.35)),
                          ),
                          child: Text(
                            '${item.sortOrder}',
                            style: TextStyle(color: accent, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                factText.isEmpty
                                    ? _t(const {
                                        AppLanguage.ru: '(без названия)',
                                        AppLanguage.en: '(untitled)',
                                        AppLanguage.de: '(ohne Titel)',
                                      })
                                    : factText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: onSurface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_difficultyLabel(item.difficulty)} · ${_categoryLabel(item.category)} · $questionCount ${_t(const {
                                  AppLanguage.ru: 'вопрос(ов)',
                                  AppLanguage.en: 'question(s)',
                                  AppLanguage.de: 'Frage(n)',
                                })}',
                                style: TextStyle(color: onSurface.withOpacity(0.55), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              color: onSurface.withOpacity(0.55)),
                          onPressed: () => _confirmDelete(item),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FactEditorPage extends StatefulWidget {
  const _FactEditorPage({this.existing, required this.defaultOrder});

  final FactEntry? existing;
  final int defaultOrder;

  @override
  State<_FactEditorPage> createState() => _FactEditorPageState();
}

class _FactEditorPageState extends State<_FactEditorPage> {
  late int _sortOrder;
  late FactDifficulty _difficulty;
  late FactCategory _category;
  late Map<AppLanguage, TextEditingController> _factControllers;
  late List<_QuestionDraft> _questions;
  AppLanguage _activeLang = AppLanguage.ru;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _sortOrder = widget.existing?.sortOrder ?? widget.defaultOrder;
    _difficulty = widget.existing?.difficulty ?? FactDifficulty.easy;
    _category = widget.existing?.category ?? FactCategory.random;
    _activeLang = appLanguage.value;

    _factControllers = <AppLanguage, TextEditingController>{
      for (final lang in AppLanguage.values)
        lang: TextEditingController(text: widget.existing?.fact[lang] ?? ''),
    };

    final src = widget.existing?.questions ?? const <FactQuestion>[];
    _questions = src.map(_QuestionDraft.fromQuestion).toList();
    if (_questions.isEmpty) {
      _questions.add(_QuestionDraft.empty());
    }
  }

  @override
  void dispose() {
    for (final c in _factControllers.values) {
      c.dispose();
    }
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  String _t(Map<AppLanguage, String> map) =>
      map[appLanguage.value] ?? map[AppLanguage.ru] ?? '';

  String _langLabel(AppLanguage l) {
    switch (l) {
      case AppLanguage.ru:
        return 'RU';
      case AppLanguage.en:
        return 'EN';
      case AppLanguage.de:
        return 'DE';
    }
  }

  void _addQuestion() {
    setState(() => _questions.add(_QuestionDraft.empty()));
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions[index].dispose();
      _questions.removeAt(index);
      if (_questions.isEmpty) _questions.add(_QuestionDraft.empty());
    });
  }

  Future<void> _save() async {
    if (_saving) return;

    final factMap = <AppLanguage, String>{
      for (final e in _factControllers.entries) e.key: e.value.text.trim(),
    };

    if ((factMap[AppLanguage.ru] ?? '').isEmpty &&
        (factMap[AppLanguage.en] ?? '').isEmpty &&
        (factMap[AppLanguage.de] ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t(const {
          AppLanguage.ru: 'Заполните текст факта хотя бы на одном языке.',
          AppLanguage.en: 'Fill the fact text in at least one language.',
          AppLanguage.de: 'Bitte Fakt mindestens in einer Sprache eingeben.',
        }))),
      );
      return;
    }

    final builtQuestions = <FactQuestion>[];
    for (final q in _questions) {
      final text = <AppLanguage, String>{
        for (final lang in AppLanguage.values)
          lang: q.controllers[lang]!.text.trim(),
      };
      final allEmpty = text.values.every((v) => v.isEmpty);
      if (allEmpty) continue;
      builtQuestions.add(FactQuestion(id: q.id, text: text));
    }

    if (builtQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t(const {
          AppLanguage.ru: 'Добавьте хотя бы один вопрос.',
          AppLanguage.en: 'Add at least one question.',
          AppLanguage.de: 'Mindestens eine Frage hinzufuegen.',
        }))),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final entry = FactEntry(
        id: widget.existing?.id ?? '',
        sortOrder: _sortOrder,
        fact: factMap,
        questions: builtQuestions,
        difficulty: _difficulty,
        category: _category,
      );
      await FactsRepository.instance.upsertFact(entry);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_t(const {
          AppLanguage.ru: 'Ошибка сохранения',
          AppLanguage.en: 'Save failed',
          AppLanguage.de: 'Speichern fehlgeschlagen',
        })}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          widget.existing == null
              ? _t(const {
                  AppLanguage.ru: 'Новый факт',
                  AppLanguage.en: 'New fact',
                  AppLanguage.de: 'Neuer Fakt',
                })
              : _t(const {
                  AppLanguage.ru: 'Редактирование',
                  AppLanguage.en: 'Edit fact',
                  AppLanguage.de: 'Fakt bearbeiten',
                }),
          style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _t(const {
                      AppLanguage.ru: 'СОХРАНИТЬ',
                      AppLanguage.en: 'SAVE',
                      AppLanguage.de: 'SPEICHERN',
                    }),
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 40),
        children: [
          _buildLangSwitcher(onSurface, accent),
          const SizedBox(height: 12),
          _buildOrderField(palette, onSurface, accent),
          const SizedBox(height: 12),
          _buildMetadataPickers(palette, onSurface, accent),
          const SizedBox(height: 16),
          _sectionTitle(_t(const {
            AppLanguage.ru: 'ФАКТ',
            AppLanguage.en: 'FACT',
            AppLanguage.de: 'FAKT',
          }), onSurface),
          const SizedBox(height: 6),
          _buildFactField(palette, onSurface, accent),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _sectionTitle(
                  _t(const {
                    AppLanguage.ru: 'ВОПРОСЫ',
                    AppLanguage.en: 'QUESTIONS',
                    AppLanguage.de: 'FRAGEN',
                  }),
                  onSurface,
                ),
              ),
              TextButton.icon(
                onPressed: _addQuestion,
                icon: Icon(Icons.add_rounded, color: accent, size: 18),
                label: Text(
                  _t(const {
                    AppLanguage.ru: 'Добавить',
                    AppLanguage.en: 'Add',
                    AppLanguage.de: 'Hinzufuegen',
                  }),
                  style: TextStyle(color: accent, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (int i = 0; i < _questions.length; i++) ...[
            _buildQuestionCard(i, palette, onSurface, accent),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String label, Color onSurface) {
    return Text(
      label,
      style: TextStyle(
        color: onSurface.withOpacity(0.5),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.2,
      ),
    );
  }

  Widget _buildLangSwitcher(Color onSurface, Color accent) {
    return Container(
      decoration: BoxDecoration(
        color: appPalette.value.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appPalette.value.border.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (final lang in AppLanguage.values)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeLang = lang),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: _activeLang == lang
                        ? accent.withOpacity(0.18)
                        : Colors.transparent,
                  ),
                  child: Center(
                    child: Text(
                      _langLabel(lang),
                      style: TextStyle(
                        color: _activeLang == lang
                            ? accent
                            : onSurface.withOpacity(0.55),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderField(AppPalette palette, Color onSurface, Color accent) {
    return Row(
      children: [
        Text(
          _t(const {
            AppLanguage.ru: 'Порядок',
            AppLanguage.en: 'Order',
            AppLanguage.de: 'Reihenfolge',
          }),
          style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 12),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline_rounded),
          onPressed: () => setState(() => _sortOrder = (_sortOrder - 1).clamp(1, 999)),
        ),
        SizedBox(
          width: 44,
          child: Text(
            '$_sortOrder',
            textAlign: TextAlign.center,
            style: TextStyle(color: onSurface, fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded),
          onPressed: () => setState(() => _sortOrder = (_sortOrder + 1).clamp(1, 999)),
        ),
      ],
    );
  }

  Widget _buildMetadataPickers(AppPalette palette, Color onSurface, Color accent) {
    return Row(
      children: [
        Expanded(
          child: _buildChoiceButton(
            label: _t(const {
              AppLanguage.ru: 'Уровень',
              AppLanguage.en: 'Level',
              AppLanguage.de: 'Level',
            }),
            value: _difficultyLabel(_difficulty),
            onSurface: onSurface,
            accent: accent,
            onTap: () => _pickDifficulty(onSurface, accent),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildChoiceButton(
            label: _t(const {
              AppLanguage.ru: 'Категория',
              AppLanguage.en: 'Category',
              AppLanguage.de: 'Kategorie',
            }),
            value: _categoryLabel(_category),
            onSurface: onSurface,
            accent: accent,
            onTap: () => _pickCategory(onSurface, accent),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceButton({
    required String label,
    required String value,
    required Color onSurface,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: appPalette.value.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: appPalette.value.border.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: onSurface.withOpacity(0.45),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDifficulty(Color onSurface, Color accent) async {
    final picked = await showModalBottomSheet<FactDifficulty>(
      context: context,
      backgroundColor: appPalette.value.background,
      builder: (ctx) => _buildSheet(
        title: _t(const {
          AppLanguage.ru: 'Уровень',
          AppLanguage.en: 'Level',
          AppLanguage.de: 'Level',
        }),
        children: [
          for (final value in FactDifficulty.values)
            ListTile(
              title: Text(_difficultyLabel(value), style: TextStyle(color: onSurface)),
              trailing: value == _difficulty ? Icon(Icons.check_rounded, color: accent) : null,
              onTap: () => Navigator.pop(ctx, value),
            ),
        ],
      ),
    );
    if (picked != null) setState(() => _difficulty = picked);
  }

  Future<void> _pickCategory(Color onSurface, Color accent) async {
    final picked = await showModalBottomSheet<FactCategory>(
      context: context,
      backgroundColor: appPalette.value.background,
      builder: (ctx) => _buildSheet(
        title: _t(const {
          AppLanguage.ru: 'Категория',
          AppLanguage.en: 'Category',
          AppLanguage.de: 'Kategorie',
        }),
        children: [
          for (final value in FactCategory.values)
            ListTile(
              title: Text(_categoryLabel(value), style: TextStyle(color: onSurface)),
              trailing: value == _category ? Icon(Icons.check_rounded, color: accent) : null,
              onTap: () => Navigator.pop(ctx, value),
            ),
        ],
      ),
    );
    if (picked != null) setState(() => _category = picked);
  }

  Widget _buildSheet({required String title, required List<Widget> children}) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildFactField(AppPalette palette, Color onSurface, Color accent) {
    return TextField(
      controller: _factControllers[_activeLang],
      minLines: 2,
      maxLines: 6,
      style: TextStyle(color: onSurface, fontSize: 16, height: 1.4),
      decoration: InputDecoration(
        filled: true,
        fillColor: palette.surface,
        hintText: _t(const {
          AppLanguage.ru: 'Сам факт (ответ для тренажера)',
          AppLanguage.en: 'The fact text (correct answer)',
          AppLanguage.de: 'Faktentext (richtige Antwort)',
        }),
        hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.border.withOpacity(0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.border.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index, AppPalette palette, Color onSurface, Color accent) {
    final q = _questions[index];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(0.14),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _t(const {
                    AppLanguage.ru: 'Вопрос',
                    AppLanguage.en: 'Question',
                    AppLanguage.de: 'Frage',
                  }),
                  style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 12),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: onSurface.withOpacity(0.6),
                onPressed: () => _removeQuestion(index),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: q.controllers[_activeLang],
            minLines: 2,
            maxLines: 5,
            style: TextStyle(color: onSurface, fontSize: 15, height: 1.4),
            decoration: InputDecoration(
              hintText: _t(const {
                AppLanguage.ru: 'Текст вопроса',
                AppLanguage.en: 'Question text',
                AppLanguage.de: 'Fragentext',
              }),
              hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: palette.border.withOpacity(0.4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionDraft {
  _QuestionDraft({required this.id, required this.controllers});

  final String id;
  final Map<AppLanguage, TextEditingController> controllers;

  factory _QuestionDraft.empty() {
    return _QuestionDraft(
      id: 'q_${DateTime.now().microsecondsSinceEpoch}',
      controllers: <AppLanguage, TextEditingController>{
        for (final lang in AppLanguage.values) lang: TextEditingController(),
      },
    );
  }

  factory _QuestionDraft.fromQuestion(FactQuestion q) {
    return _QuestionDraft(
      id: q.id,
      controllers: <AppLanguage, TextEditingController>{
        for (final lang in AppLanguage.values)
          lang: TextEditingController(text: q.text[lang] ?? ''),
      },
    );
  }

  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
  }
}
