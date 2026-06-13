part of 'package:flutter_application_1/recovered_app.dart';

enum _FactsPhase { setup, memorize, recall, done }
enum _FactsRecallOrder { fromStart, fromEnd }
enum FactRecallPromptType { initials, hiddenWord, storedQuestion }

String normalizeText(String input) {
  return input.toLowerCase().replaceAll('.', '').replaceAll(RegExp(r'\s+'), ' ').trim();
}

class FactRecallPrompt {
  const FactRecallPrompt({
    required this.type,
    required this.text,
    required this.expectedAnswer,
  });

  final FactRecallPromptType type;
  final String text;
  final String expectedAnswer;
}

class QuestionBuilder {
  const QuestionBuilder();

  FactRecallPrompt build({
    required FactModel fact,
    required String factText,
    required String Function(Map<AppLanguage, String>) localize,
    required Random random,
  }) {
    final questionText = _randomQuestionText(fact, localize, random);
    final types = <FactRecallPromptType>[
      FactRecallPromptType.initials,
      FactRecallPromptType.hiddenWord,
      if (questionText != null) FactRecallPromptType.storedQuestion,
    ];
    final type = types[random.nextInt(types.length)];
    return FactRecallPrompt(
      type: type,
      text: switch (type) {
        FactRecallPromptType.initials => _initialsPrompt(factText),
        FactRecallPromptType.hiddenWord => HiddenWordSelector.hideOneWord(factText, random),
        FactRecallPromptType.storedQuestion => questionText ?? _initialsPrompt(factText),
      },
      expectedAnswer: factText,
    );
  }

  String? _randomQuestionText(
    FactModel fact,
    String Function(Map<AppLanguage, String>) localize,
    Random random,
  ) {
    final questions = fact.questions
        .map((q) => localize(q.text))
        .where((text) => text.trim().isNotEmpty)
        .toList(growable: false);
    if (questions.isEmpty) return null;
    return questions[random.nextInt(questions.length)];
  }

  String _initialsPrompt(String factText) {
    return factText
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .map((word) {
          final match = RegExp(r'[\p{L}\p{N}]', unicode: true).firstMatch(word);
          return match?.group(0) ?? word.characters.first;
        })
        .join(' ');
  }
}

class HiddenWordSelector {
  const HiddenWordSelector._();

  static String hideOneWord(String text, Random random) {
    final matches = RegExp(r'[\p{L}]{4,}', unicode: true).allMatches(text).toList();
    if (matches.isEmpty) return text;
    final match = matches[random.nextInt(matches.length)];
    final word = match.group(0)!;
    final hidden = '${word.characters.first}${'_' * max(3, word.characters.length - 1)}';
    return text.replaceRange(match.start, match.end, hidden);
  }
}

class FactRecallItem {
  const FactRecallItem({
    required this.fact,
    required this.prompt,
  });

  final FactModel fact;
  final FactRecallPrompt prompt;
}

class FactsTrainerScreen extends StatefulWidget {
  const FactsTrainerScreen({super.key});

  @override
  State<FactsTrainerScreen> createState() => _FactsTrainerScreenState();
}

class _FactsTrainerScreenState extends State<FactsTrainerScreen> {
  static const String _levelPrefsKey = 'facts_trainer_level_index';
  static const String _categoryPrefsKey = 'facts_trainer_category';
  static const String _recallOrderPrefsKey = 'facts_trainer_recall_order';

  final Random _random = Random();
  final PageController _pageController = PageController();
  final QuestionBuilder _questionBuilder = const QuestionBuilder();

  List<FactModel> _allFacts = const <FactModel>[];
  List<FactModel> _runFacts = const <FactModel>[];
  List<FactRecallItem> _recallItems = const <FactRecallItem>[];
  FactDifficulty _difficulty = FactDifficulty.easy;
  FactCategory _category = FactCategory.random;
  _FactsRecallOrder _recallOrder = _FactsRecallOrder.fromStart;
  _FactsPhase _phase = _FactsPhase.setup;

  int _selectedCount = 5;
  int _memorizeIndex = 0;
  int _memorizationElapsedMs = 0;
  int _recallElapsedMs = 0;
  int _correct = 0;
  int _mistakes = 0;
  int _xpEarned = 0;
  bool _loading = true;
  bool _savingScore = false;
  String? _loadError;
  Timer? _ticker;
  DateTime? _phaseStartedAt;

  @override
  void initState() {
    super.initState();
    _loadPrefsAndFacts();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefsAndFacts() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final levelIndex = (prefs.getInt(_levelPrefsKey) ?? 0)
          .clamp(0, FactDifficulty.values.length - 1)
          .toInt();
      final orderName = prefs.getString(_recallOrderPrefsKey) ?? _FactsRecallOrder.fromStart.name;
      final items = await FactsRepository.instance
          .preloadFacts()
          .timeout(const Duration(seconds: 12));
      if (!mounted) return;
      setState(() {
        _difficulty = FactDifficulty.values[levelIndex];
        _category = FactCategory.fromString(
          prefs.getString(_categoryPrefsKey) ?? FactCategory.random.name,
        );
        _recallOrder = _FactsRecallOrder.values.firstWhere(
          (order) => order.name == orderName,
          orElse: () => _FactsRecallOrder.fromStart,
        );
        _allFacts = items.where((f) => _loc(f.fact).isNotEmpty).toList(growable: false);
        _selectedCount = _defaultCountFor(_difficulty)
            .clamp(1, max(1, _allFacts.length))
            .toInt();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = '${_t(const {
          AppLanguage.ru: 'Не удалось загрузить факты.',
          AppLanguage.en: 'Could not load facts.',
          AppLanguage.de: 'Fakten konnten nicht geladen werden.',
        })}\n$e';
      });
    }
  }

  String _t(Map<AppLanguage, String> map) =>
      map[appLanguage.value] ?? map[AppLanguage.ru] ?? '';

  String _loc(Map<AppLanguage, String> map) {
    for (final lang in <AppLanguage>[
      appLanguage.value,
      AppLanguage.ru,
      AppLanguage.en,
      AppLanguage.de,
    ]) {
      final value = (map[lang] ?? '').trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  int _defaultCountFor(FactDifficulty difficulty) {
    switch (difficulty) {
      case FactDifficulty.easy:
        return 5;
      case FactDifficulty.medium:
        return 4;
      case FactDifficulty.hard:
        return 3;
      case FactDifficulty.expert:
        return 2;
    }
  }

  int _maxWordsFor(FactDifficulty difficulty) {
    switch (difficulty) {
      case FactDifficulty.easy:
        return 8;
      case FactDifficulty.medium:
        return 16;
      case FactDifficulty.hard:
        return 28;
      case FactDifficulty.expert:
        return 10000;
    }
  }

  List<FactModel> _factsForCurrentSettings({
    FactDifficulty? difficulty,
    FactCategory? category,
  }) {
    final level = difficulty ?? _difficulty;
    final cat = category ?? _category;
    final tagged = _allFacts.where((f) {
      final categoryOk = cat == FactCategory.random || f.category == cat;
      return categoryOk && f.difficulty == level;
    }).toList(growable: false);
    if (tagged.isNotEmpty) return tagged;

    final fallback = _allFacts.where((f) {
      final categoryOk = cat == FactCategory.random || f.category == cat;
      return categoryOk &&
          _loc(f.fact).split(RegExp(r'\s+')).length <= _maxWordsFor(level);
    }).toList(growable: false);
    return fallback.isEmpty ? _allFacts : fallback;
  }

  void _startTicker() {
    _ticker?.cancel();
    _phaseStartedAt = DateTime.now();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted || _phaseStartedAt == null) return;
      final elapsed = DateTime.now().difference(_phaseStartedAt!).inMilliseconds;
      setState(() {
        if (_phase == _FactsPhase.memorize) {
          _memorizationElapsedMs = elapsed;
        } else if (_phase == _FactsPhase.recall) {
          _recallElapsedMs = elapsed;
        }
      });
    });
  }

  void _startMemorization() {
    final pool = _factsForCurrentSettings();
    if (pool.isEmpty) return;
    final picked = List<FactModel>.from(pool)..shuffle(_random);
    _ticker?.cancel();
    setState(() {
      _runFacts = picked
          .take(_selectedCount.clamp(1, picked.length).toInt())
          .toList(growable: false);
      _recallItems = const <FactRecallItem>[];
      _memorizeIndex = 0;
      _memorizationElapsedMs = 0;
      _recallElapsedMs = 0;
      _correct = 0;
      _mistakes = 0;
      _xpEarned = 0;
      _phase = _FactsPhase.memorize;
    });
    _startTicker();
  }

  void _finishMemorization() {
    _ticker?.cancel();
    final items = _runFacts
        .map(
          (fact) => FactRecallItem(
            fact: fact,
            prompt: _questionBuilder.build(
              fact: fact,
              factText: _loc(fact.fact),
              localize: _loc,
              random: _random,
            ),
          ),
        )
        .toList(growable: false);
    setState(() {
      _recallItems = items;
      _phase = _FactsPhase.recall;
      _recallElapsedMs = 0;
    });
    _startTicker();
  }

  Future<void> _finishRecall(List<String> answers) async {
    _ticker?.cancel();
    final correctness = <bool>[];
    for (int i = 0; i < _recallItems.length; i++) {
      final expected = normalizeText(_recallItems[i].prompt.expectedAnswer);
      final answer = i < answers.length ? normalizeText(answers[i]) : '';
      correctness.add(answer.isNotEmpty && answer == expected);
    }
    final correct = correctness.where((v) => v).length;
    setState(() {
      _correct = correct;
      _mistakes = _recallItems.length - correct;
      _phase = _FactsPhase.done;
      _savingScore = true;
    });
    await _saveScore(correctness);
  }

  Future<void> _saveScore(List<bool> correctness) async {
    final total = _recallItems.length;
    final correct = correctness.where((v) => v).length;
    final accuracy = total == 0 ? 0.0 : (correct / total) * 100.0;
    int xp = 0;
    try {
      xp = await ProgressService.instance.awardMemorization(memorizedCount: correct);
      await ProfileSessionService.instance.recordSession(
        mode: 'facts',
        totalItems: total,
        correctItems: correct,
        timeSeconds: max(
          1,
          ((_memorizationElapsedMs + _recallElapsedMs) / 1000).ceil(),
        ),
        date: DateTime.now(),
        encodingMs: _memorizationElapsedMs,
        recallMs: _recallElapsedMs,
        correctnessPattern: correctness.map((v) => v ? 1 : 0).toList(growable: false),
        recordScore: correct,
      );
      await QuestService.instance.updateProgress(
        type: QuestType.completeXTrainings,
        value: 1,
      );
      await QuestService.instance.updateProgress(type: QuestType.memorizeN, value: correct);
      await QuestService.instance.updateProgress(
        type: QuestType.totalMemorizedN,
        value: correct,
      );
      if (accuracy >= 100) {
        await QuestService.instance.updateProgress(type: QuestType.noErrors, isPerfect: true);
      }
      await LeaderboardService.instance.addPoints(correct);
      await _updateProgression(accuracy);
    } catch (e) {
      debugPrint('Facts score sync skipped: $e');
    }
    if (!mounted) return;
    setState(() {
      _xpEarned = xp;
      _savingScore = false;
    });
  }

  Future<void> _updateProgression(double accuracy) async {
    if (accuracy < 80 || _difficulty == FactDifficulty.expert) return;
    final nextIndex = (_difficulty.index + 1)
        .clamp(0, FactDifficulty.values.length - 1)
        .toInt();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_levelPrefsKey, nextIndex);
    if (mounted) setState(() => _difficulty = FactDifficulty.values[nextIndex]);
  }

  Future<void> _setDifficulty(FactDifficulty value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_levelPrefsKey, value.index);
    if (!mounted) return;
    final pool = _factsForCurrentSettings(difficulty: value);
    setState(() {
      _difficulty = value;
      _selectedCount = _defaultCountFor(value).clamp(1, max(1, pool.length)).toInt();
    });
  }

  Future<void> _setCategory(FactCategory value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_categoryPrefsKey, value.name);
    if (mounted) setState(() => _category = value);
  }

  Future<void> _setRecallOrder(_FactsRecallOrder value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recallOrderPrefsKey, value.name);
    if (mounted) setState(() => _recallOrder = value);
  }

  String _formatTime(int ms) {
    final seconds = (ms / 1000).floor();
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = appAccentColor.value;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          _t(const {
            AppLanguage.ru: 'ФАКТЫ',
            AppLanguage.en: 'FACTS',
            AppLanguage.de: 'FAKTEN',
          }),
          style: TextStyle(
            color: onSurface,
            fontSize: 13,
            letterSpacing: 2.4,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _buildLoadError(onSurface)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    child: switch (_phase) {
                      _FactsPhase.setup => _buildSetup(onSurface, accent),
                      _FactsPhase.memorize => _buildMemorize(onSurface),
                      _FactsPhase.recall => FactsRecallScreen(
                          key: ValueKey(_recallItems.map((item) => item.fact.id).join('|')),
                          items: _recallItems,
                          startFromEnd: _recallOrder == _FactsRecallOrder.fromEnd,
                          onCompleted: _finishRecall,
                        ),
                      _FactsPhase.done => _buildDone(onSurface, accent),
                    },
                  ),
                ),
    );
  }

  Widget _buildLoadError(Color onSurface) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: onSurface.withOpacity(0.75), fontSize: 12),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _loadPrefsAndFacts,
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

  Widget _buildSetup(Color onSurface, Color accent) {
    final pool = _factsForCurrentSettings();
    if (_allFacts.isEmpty) {
      return Center(
        child: Text(
          _t(const {
            AppLanguage.ru: 'Пока нет фактов. Создатель добавит их в редакторе.',
            AppLanguage.en: 'No facts yet. The creator can add them in editor.',
            AppLanguage.de: 'Noch keine Fakten. Der Creator kann sie im Editor anlegen.',
          }),
          textAlign: TextAlign.center,
          style: TextStyle(color: onSurface.withOpacity(0.65)),
        ),
      );
    }

    final count = _selectedCount.clamp(1, max(1, pool.length)).toInt();
    return Column(
      key: const ValueKey('facts_setup'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSetupCard(onSurface, accent),
        const SizedBox(height: 14),
        Text(
          '${_t(const {
            AppLanguage.ru: 'Фактов',
            AppLanguage.en: 'Facts',
            AppLanguage.de: 'Fakten',
          })}: $count / ${pool.length}',
          style: TextStyle(color: onSurface.withOpacity(0.58), fontSize: 12),
        ),
        Slider(
          value: count.toDouble(),
          min: 1,
          max: max(1, pool.length).toDouble(),
          divisions: pool.length <= 1 ? null : pool.length - 1,
          onChanged: pool.isEmpty ? null : (v) => setState(() => _selectedCount = v.round()),
        ),
        const Spacer(),
        _factActionButton(
          label: _t(const {
            AppLanguage.ru: 'Старт',
            AppLanguage.en: 'Start',
            AppLanguage.de: 'Start',
          }),
          onPressed: pool.isEmpty ? null : _startMemorization,
        ),
      ],
    );
  }

  Widget _buildSetupCard(Color onSurface, Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appPalette.value.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appPalette.value.border.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('PROGRESSION', onSurface),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final level in FactDifficulty.values)
                _chip(
                  label: _difficultyLabel(level),
                  selected: _difficulty == level,
                  onTap: () => _setDifficulty(level),
                  onSurface: onSurface,
                  accent: accent,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in FactCategory.values)
                _chip(
                  label: _categoryLabel(category),
                  selected: _category == category,
                  onTap: () => _setCategory(category),
                  onSurface: onSurface,
                  accent: accent,
                ),
            ],
          ),
          const SizedBox(height: 14),
          _sectionLabel(
            _t(const {
              AppLanguage.ru: 'ORDER',
              AppLanguage.en: 'ORDER',
              AppLanguage.de: 'ORDER',
            }),
            onSurface,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _chip(
                  label: _t(const {
                    AppLanguage.ru: 'С начала',
                    AppLanguage.en: 'From start',
                    AppLanguage.de: 'Von vorne',
                  }),
                  selected: _recallOrder == _FactsRecallOrder.fromStart,
                  onTap: () => _setRecallOrder(_FactsRecallOrder.fromStart),
                  onSurface: onSurface,
                  accent: accent,
                  centered: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _chip(
                  label: _t(const {
                    AppLanguage.ru: 'С конца',
                    AppLanguage.en: 'From end',
                    AppLanguage.de: 'Von hinten',
                  }),
                  selected: _recallOrder == _FactsRecallOrder.fromEnd,
                  onTap: () => _setRecallOrder(_FactsRecallOrder.fromEnd),
                  onSurface: onSurface,
                  accent: accent,
                  centered: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, Color onSurface) {
    return Text(
      label,
      style: TextStyle(
        color: onSurface.withOpacity(0.45),
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color onSurface,
    required Color accent,
    bool centered = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? accent.withOpacity(0.55)
                : appPalette.value.border.withOpacity(0.35),
          ),
        ),
        child: Text(
          label,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: selected ? accent : onSurface.withOpacity(0.62),
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildMemorize(Color onSurface) {
    final progress = _runFacts.isEmpty ? 0.0 : (_memorizeIndex + 1) / _runFacts.length;
    return Column(
      key: const ValueKey('facts_memorize'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _factsTopBar(
          progress: progress,
          timerText: _formatTime(_memorizationElapsedMs),
          label: '${_memorizeIndex + 1}/${_runFacts.length}',
        ),
        const SizedBox(height: 18),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) {
              uiTapClick(UiClickSound.soft);
              setState(() => _memorizeIndex = i);
            },
            itemCount: _runFacts.length,
            itemBuilder: (_, i) => Center(
              child: _trainerCard(
                child: Text(
                  _loc(_runFacts[i].fact),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 24,
                    height: 1.35,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _factActionButton(
          label: _t(const {
            AppLanguage.ru: 'Recall',
            AppLanguage.en: 'Recall',
            AppLanguage.de: 'Recall',
          }),
          onPressed: _finishMemorization,
        ),
      ],
    );
  }

  Widget _buildDone(Color onSurface, Color accent) {
    final total = _recallItems.length;
    final accuracy = total == 0 ? 0.0 : (_correct / total) * 100.0;
    return Center(
      key: const ValueKey('facts_done'),
      child: _trainerCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${accuracy.toStringAsFixed(0)}% · $_correct/$total',
              style: TextStyle(color: accent, fontSize: 30, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            _metricLine(onSurface, 'Accuracy', '${accuracy.toStringAsFixed(0)}%'),
            _metricLine(onSurface, 'Time', _formatTime(_memorizationElapsedMs + _recallElapsedMs)),
            _metricLine(onSurface, 'Correct answers', '$_correct'),
            _metricLine(onSurface, 'Mistakes', '$_mistakes'),
            _metricLine(onSurface, 'XP', _savingScore ? '...' : '+$_xpEarned'),
            const SizedBox(height: 18),
            _factActionButton(
              label: _t(const {
                AppLanguage.ru: 'Новая попытка',
                AppLanguage.en: 'Try again',
                AppLanguage.de: 'Noch mal',
              }),
              onPressed: () => setState(() => _phase = _FactsPhase.setup),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricLine(Color onSurface, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: onSurface.withOpacity(0.55), fontSize: 12)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(color: onSurface, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class FactsRecallScreen extends StatefulWidget {
  const FactsRecallScreen({
    super.key,
    required this.items,
    required this.startFromEnd,
    required this.onCompleted,
  });

  final List<FactRecallItem> items;
  final bool startFromEnd;
  final ValueChanged<List<String>> onCompleted;

  @override
  State<FactsRecallScreen> createState() => _FactsRecallScreenState();
}

class _FactsRecallScreenState extends State<FactsRecallScreen> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  Timer? _ticker;
  DateTime? _startedAt;
  int _index = 0;
  int _elapsedMs = 0;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.items.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.items.length, (_) => FocusNode());
    _index = widget.startFromEnd ? max(0, widget.items.length - 1) : 0;
    _startedAt = DateTime.now();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted && _startedAt != null) {
        setState(() => _elapsedMs = DateTime.now().difference(_startedAt!).inMilliseconds);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNodes.isNotEmpty) _focusNodes[_index].requestFocus();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String _formatTime(int ms) {
    final seconds = (ms / 1000).floor();
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  void _go(int delta) {
    if (widget.items.isEmpty) return;
    final next = (_index + delta).clamp(0, widget.items.length - 1).toInt();
    if (next == _index) return;
    uiTapClick(UiClickSound.soft);
    setState(() => _index = next);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes[_index].requestFocus();
    });
  }

  void _submit() {
    _ticker?.cancel();
    widget.onCompleted(_controllers.map((c) => c.text.trim()).toList(growable: false));
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final item = widget.items[_index];
    final progress = widget.items.isEmpty ? 0.0 : (_index + 1) / widget.items.length;

    return Column(
      key: const ValueKey('facts_recall'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _factsTopBar(
          progress: progress,
          timerText: _formatTime(_elapsedMs),
          label: '',
        ),
        const SizedBox(height: 10),
        _buildQuestionNav(onSurface),
        const SizedBox(height: 14),
        Expanded(
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              child: _trainerCard(
                key: ValueKey('${item.fact.id}_${item.prompt.text}'),
                child: Text(
                  item.prompt.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: onSurface.withOpacity(0.78),
                    fontSize: 24,
                    height: 1.45,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _controllers[_index],
          focusNode: _focusNodes[_index],
          minLines: 1,
          maxLines: 4,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => widget.startFromEnd ? _go(-1) : _go(1),
          style: TextStyle(color: onSurface, fontSize: 16, height: 1.35),
          decoration: InputDecoration(
            filled: true,
            fillColor: appPalette.value.surface,
            hintText: AppTexts.translate(const {
              AppLanguage.ru: 'Восстанови факт',
              AppLanguage.en: 'Restore the fact',
              AppLanguage.de: 'Fakt wiederherstellen',
            }),
            hintStyle: TextStyle(color: onSurface.withOpacity(0.35)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: appPalette.value.border.withOpacity(0.35)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: appPalette.value.border.withOpacity(0.35)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: appAccentColor.value.withOpacity(0.8)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _factActionButton(label: AppTexts.get('check'), onPressed: _submit),
      ],
    );
  }

  Widget _buildQuestionNav(Color onSurface) {
    return Row(
      children: [
        _navButton(
          icon: Icons.arrow_back_rounded,
          enabled: _index > 0,
          onTap: () => _go(-1),
        ),
        Expanded(
          child: Text(
            AppTexts.translate({
              AppLanguage.ru: 'Вопрос ${_index + 1} / ${widget.items.length}',
              AppLanguage.en: 'Question ${_index + 1} / ${widget.items.length}',
              AppLanguage.de: 'Frage ${_index + 1} / ${widget.items.length}',
            }),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: onSurface.withOpacity(0.62),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        _navButton(
          icon: Icons.arrow_forward_rounded,
          enabled: _index < widget.items.length - 1,
          onTap: () => _go(1),
        ),
      ],
    );
  }

  Widget _navButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 42,
        height: 38,
        decoration: BoxDecoration(
          color: appPalette.value.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled
                ? appPalette.value.border.withOpacity(0.38)
                : appPalette.value.border.withOpacity(0.18),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.22),
        ),
      ),
    );
  }
}

Widget _trainerCard({Key? key, required Widget child}) {
  return Container(
    key: key,
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: appPalette.value.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: appPalette.value.border.withOpacity(0.35)),
    ),
    child: child,
  );
}

Widget _factsTopBar({
  required double progress,
  required String timerText,
  required String label,
}) {
  final onBackground =
      ThemeData.estimateBrightnessForColor(appPalette.value.background) == Brightness.dark
          ? Colors.white
          : Colors.black;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 5,
                value: progress.clamp(0.0, 1.0).toDouble(),
                backgroundColor: appPalette.value.border.withOpacity(0.25),
                valueColor: AlwaysStoppedAnimation<Color>(appAccentColor.value),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            timerText,
            style: TextStyle(
              color: appAccentColor.value,
              fontSize: 12,
              fontFeatures: const [ui.FontFeature.tabularFigures()],
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      if (label.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: onBackground.withOpacity(0.45),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
      ],
    ],
  );
}

Widget _factActionButton({
  required String label,
  required VoidCallback? onPressed,
}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: appAccentColor.value,
        foregroundColor: Colors.white,
        disabledBackgroundColor: appAccentColor.value.withOpacity(0.25),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4),
      ),
    ),
  );
}
