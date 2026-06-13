import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/core/app_session.dart';
import '../app/core/ui_feedback.dart';
import '../progress/progress_service.dart';
import '../progress/quest_models.dart';
import '../progress/quest_service.dart';
import '../profile/profile_session_service.dart';
import '../recovered_app.dart'
    show
        AppLanguage,
        AppPalette,
        AppTexts,
        appAccentColor,
        appLanguage,
        appPalette;
import '../training_record_rules.dart';
import 'card_codes_deck.dart';
import 'card_codes_service.dart';
import 'playing_card_face.dart';

/// Editor + trainer for custom mnemonic images on playing cards.
class CardCodesScreen extends StatefulWidget {
  const CardCodesScreen({super.key});

  @override
  State<CardCodesScreen> createState() => _CardCodesScreenState();
}

class _CardCodesScreenState extends State<CardCodesScreen> {
  static const _svc = CardCodesService.instance;

  Map<String, String> _images = {};
  int _filled = 0;
  bool _loading = true;
  String _searchQuery = '';
  String _selectedSuit = CardCodesDeck.suits.first;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final lang = appLanguage.value;
    final images = await _svc.loadImages(lang);
    final filled = images.values.where((v) => v.isNotEmpty).length;
    if (!mounted) return;
    setState(() {
      _images = images;
      _filled = filled;
      _loading = false;
    });
  }

  String _t(Map<AppLanguage, String> m) =>
      m[appLanguage.value] ?? m[AppLanguage.ru] ?? '';

  List<String> _visibleCodes() {
    final all = _searchQuery.isEmpty
        ? CardCodesDeck.codesForSuit(_selectedSuit)
        : CardCodesDeck.allCodes().where((code) {
            final q = _searchQuery.toLowerCase();
            final img = (_images[code] ?? '').toLowerCase();
            return code.contains(q) || img.contains(q);
          }).toList(growable: false);
    return all;
  }

  Future<void> _openEdit(String cardCode) async {
    final lang = appLanguage.value;
    final controller = TextEditingController(text: _images[cardCode] ?? '');
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final palette = appPalette.value;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                decoration: BoxDecoration(
                  color: palette.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: palette.border.withOpacity(0.4)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PlayingCardFace(
                      cardCode: cardCode,
                      width: 100,
                      height: 140,
                      animateIn: true,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: AppTexts.get('card_codes_edit_hint'),
                        filled: true,
                        fillColor: palette.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: palette.border.withOpacity(0.35),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if ((_images[cardCode] ?? '').isNotEmpty)
                          TextButton(
                            onPressed: () async {
                              await _svc.saveImage(lang, cardCode, '');
                              if (ctx.mounted) Navigator.pop(ctx, true);
                            },
                            child: Text(_t(const {
                              AppLanguage.ru: 'Очистить',
                              AppLanguage.en: 'Clear',
                              AppLanguage.de: 'Löschen',
                            })),
                          ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(_t(const {
                            AppLanguage.ru: 'Сохранить',
                            AppLanguage.en: 'Save',
                            AppLanguage.de: 'Speichern',
                          })),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    if (saved != true || !mounted) {
      controller.dispose();
      return;
    }
    await _svc.saveImage(lang, cardCode, controller.text);
    controller.dispose();
    await _reload();
  }

  Future<void> _openTrainer() async {
    if (_filled < CardCodesDeck.minTrainerCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTexts.get('card_codes_need_images')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await Navigator.push<void>(
      context,
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => const CardCodesTrainerScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = appAccentColor.value;
    final lang = appLanguage.value;
    final fillRatio = _filled / CardCodesDeck.codeCount;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: onSurface.withOpacity(0.6), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppTexts.get('card_codes_title'),
          style: TextStyle(
            color: onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_filled >= CardCodesDeck.minTrainerCount)
            IconButton(
              tooltip: AppTexts.get('card_codes_trainer'),
              onPressed: withUiTap(_openTrainer, sound: UiClickSound.soft),
              icon: Icon(Icons.fitness_center_rounded,
                  color: accent.withOpacity(0.85), size: 22),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppTexts.get('card_codes_filled_count', params: {
                                'n': '$_filled',
                                'total': '${CardCodesDeck.codeCount}',
                              }),
                              style: TextStyle(
                                color: onSurface.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (_filled >= CardCodesDeck.minTrainerCount)
                            GestureDetector(
                              onTap:
                                  withUiTap(_openTrainer, sound: UiClickSound.soft),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: accent.withOpacity(0.35)),
                                ),
                                child: Text(
                                  AppTexts.get('card_codes_trainer'),
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: fillRatio),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => LinearProgressIndicator(
                            value: value,
                            minHeight: 5,
                            backgroundColor: onSurface.withOpacity(0.06),
                            color: accent.withOpacity(0.75),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    decoration: InputDecoration(
                      hintText: AppTexts.get('card_codes_search_hint'),
                      isDense: true,
                      filled: true,
                      fillColor: palette.surface,
                      prefixIcon: Icon(Icons.search_rounded,
                          size: 20, color: onSurface.withOpacity(0.4)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: palette.border.withOpacity(0.3)),
                      ),
                    ),
                  ),
                ),
                if (_searchQuery.isEmpty)
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: CardCodesDeck.suits.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final suit = CardCodesDeck.suits[index];
                        final selected = _selectedSuit == suit;
                        final suitColor = suit == 'h' || suit == 'd'
                            ? const Color(0xFFFF3B30)
                            : accent;
                        return GestureDetector(
                          onTap: withUiTap(
                            () => setState(() => _selectedSuit = suit),
                            sound: UiClickSound.soft,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: selected
                                  ? suitColor.withOpacity(0.14)
                                  : palette.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? suitColor.withOpacity(0.5)
                                    : palette.border.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  CardCodesDeckDisplay.suitGlyph(suit),
                                  style: TextStyle(
                                    color: suitColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  CardCodesDeckDisplay.suitLabel(suit, lang),
                                  style: TextStyle(
                                    color: selected
                                        ? suitColor
                                        : onSurface.withOpacity(0.55),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: _visibleCodes().length,
                    itemBuilder: (context, index) {
                      final code = _visibleCodes()[index];
                      final img = _images[code] ?? '';
                      final has = img.isNotEmpty;
                      return TweenAnimationBuilder<double>(
                        key: ValueKey('$code-$has'),
                        tween: Tween(begin: 0.92, end: 1.0),
                        duration: Duration(milliseconds: 260 + index * 18),
                        curve: Curves.easeOutCubic,
                        builder: (context, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: GestureDetector(
                          onTap: withUiTap(() => _openEdit(code),
                              sound: UiClickSound.soft),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            decoration: BoxDecoration(
                              color: palette.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: has
                                    ? accent.withOpacity(0.45)
                                    : palette.border.withOpacity(0.22),
                              ),
                              boxShadow: has
                                  ? [
                                      BoxShadow(
                                        color: accent.withOpacity(0.08),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                PlayingCardFace(
                                  cardCode: code,
                                  width: 52,
                                  height: 72,
                                  elevated: false,
                                ),
                                if (has) ...[
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                    child: Text(
                                      img,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: onSurface.withOpacity(0.72),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

enum _CardTrainerPhase { setup, run, done }

class CardCodesTrainerScreen extends StatefulWidget {
  const CardCodesTrainerScreen({super.key});

  @override
  State<CardCodesTrainerScreen> createState() => _CardCodesTrainerScreenState();
}

class _CardCodesTrainerScreenState extends State<CardCodesTrainerScreen> {
  static const _svc = CardCodesService.instance;
  final _rng = Random();
  final TextEditingController _countController =
      TextEditingController(text: '${CardCodesDeck.defaultTrainerCount}');

  _CardTrainerPhase _phase = _CardTrainerPhase.setup;
  int _selectedCount = CardCodesDeck.defaultTrainerCount;
  int _available = 0;
  bool _loading = true;
  CardCodesTrainerDirection _direction = CardCodesTrainerDirection.forward;
  Map<String, String> _sessionImages = {};

  List<String> _cards = [];
  int _index = 0;
  bool _hintVisible = false;
  DateTime? _shownAt;
  final List<int> _timesMs = [];
  int _totalMs = 0;
  bool _newRecord = false;
  int _prevBest = 0;

  List<({String card, int ms})> _sessionSamples = [];
  List<({String card, String image, int ms})> _resultRows = [];
  List<({String card, String image, int avgMs})> _weakOverall = [];
  List<({String card, String image, int avgMs})> _strongOverall = [];

  @override
  void initState() {
    super.initState();
    setTrainingQuietMode(true);
    unawaited(_loadSetup());
  }

  @override
  void dispose() {
    _countController.dispose();
    setTrainingQuietMode(false);
    super.dispose();
  }

  int get _maxSelectableCount =>
      max(CardCodesDeck.minTrainerCount, _available);

  Future<void> _loadSetup() async {
    final lang = appLanguage.value;
    final pool = await _svc.cardsWithImages(lang);
    final count = await _svc.loadTrainerCount();
    final direction = await _svc.loadTrainerDirection();
    if (!mounted) return;
    final maxCount = max(CardCodesDeck.minTrainerCount, pool.length);
    final selected = count.clamp(CardCodesDeck.minTrainerCount, maxCount);
    setState(() {
      _available = pool.length;
      _selectedCount = selected;
      _countController.text = '$selected';
      _direction = direction;
      _loading = false;
    });
  }

  String _t(Map<AppLanguage, String> m) =>
      m[appLanguage.value] ?? m[AppLanguage.ru] ?? '';

  String _formatMs(int ms) {
    final seconds = ms / 1000.0;
    if (seconds < 10) {
      return '${seconds.toStringAsFixed(2)} ${AppTexts.get('seconds_short')}';
    }
    if (seconds < 60) {
      return '${seconds.toStringAsFixed(1)} ${AppTexts.get('seconds_short')}';
    }
    final minutes = seconds ~/ 60;
    final rest = (seconds % 60).round().toString().padLeft(2, '0');
    return '$minutes:$rest';
  }

  void _normalizeCountInput() {
    if (_countController.text.isEmpty) return;
    var val = int.tryParse(_countController.text) ??
        CardCodesDeck.defaultTrainerCount;
    val = val.clamp(CardCodesDeck.minTrainerCount, _maxSelectableCount);
    _countController.text = '$val';
    _countController.selection =
        TextSelection.collapsed(offset: _countController.text.length);
    _selectedCount = val;
  }

  void _changeCount(int delta) {
    final current = int.tryParse(_countController.text) ??
        CardCodesDeck.defaultTrainerCount;
    final next = (current + delta)
        .clamp(CardCodesDeck.minTrainerCount, _maxSelectableCount)
        .toInt();
    setState(() {
      _countController.text = '$next';
      _selectedCount = next;
    });
  }

  Future<void> _startSession() async {
    final lang = appLanguage.value;
    final pool = await _svc.cardsWithImages(lang);
    if (pool.isEmpty) return;
    final images = await _svc.loadImages(lang);
    final take = min(_selectedCount, pool.length);
    final shuffled = List<String>.from(pool)..shuffle(_rng);
    final cards = shuffled.take(take).toList(growable: false);
    await _svc.saveTrainerCount(take);
    await _svc.saveTrainerDirection(_direction);

    setState(() {
      _cards = cards;
      _sessionImages = images;
      _index = 0;
      _hintVisible = false;
      _timesMs.clear();
      _totalMs = 0;
      _sessionSamples = [];
      _resultRows = [];
      _phase = _CardTrainerPhase.run;
      _shownAt = DateTime.now();
    });
  }

  void _toggleHint() {
    if (_phase != _CardTrainerPhase.run) return;
    setState(() => _hintVisible = !_hintVisible);
    uiTapClick(UiClickSound.soft);
  }

  void _recordCurrentReaction() {
    if (_timesMs.length > _index) return;
    final started = _shownAt ?? DateTime.now();
    final elapsed = DateTime.now().difference(started).inMilliseconds;
    _timesMs.add(elapsed);
    _totalMs += elapsed;
    _sessionSamples.add((card: _cards[_index], ms: elapsed));
  }

  Future<void> _next() async {
    if (_phase != _CardTrainerPhase.run) return;
    _recordCurrentReaction();
    if (_index >= _cards.length - 1) {
      await _finish();
      return;
    }
    setState(() {
      _index++;
      _hintVisible = false;
      _shownAt = DateTime.now();
    });
    uiTapClick(UiClickSound.soft);
  }

  Future<void> _finish() async {
    final lang = appLanguage.value;
    final images = await _svc.loadImages(lang);
    final rows = <({String card, String image, int ms})>[];
    for (var i = 0; i < _cards.length; i++) {
      final card = _cards[i];
      rows.add((
        card: card,
        image: images[card] ?? '',
        ms: i < _timesMs.length ? _timesMs[i] : 0,
      ));
    }
    rows.sort((a, b) => b.ms.compareTo(a.ms));

    await _svc.recordReactionTimes(
      lang,
      _sessionSamples,
      direction: _direction,
    );
    final weak = await _svc.weakestOverall(lang, direction: _direction);
    final strong = await _svc.strongestOverall(lang, direction: _direction);

    final n = _cards.length;
    final avgMs = n <= 0 ? 0 : (_totalMs / n).round();
    final displayScore = n;
    final qualifies = TrainingRecordRules.qualifiesForMaxRecord(
      displayScore: displayScore,
      correctItems: n,
      totalItems: n,
      accuracyPct: 100,
      memMs: _totalMs,
    );

    final modeKey = _svc.recordModeKey(_direction);
    final prefs = await SharedPreferences.getInstance();
    final prevBest = prefs.getInt('best_score_$modeKey') ?? 0;
    var newRecord = false;
    if (qualifies && displayScore > prevBest) {
      await prefs.setInt('best_score_$modeKey', displayScore);
      newRecord = true;
    }
    final bestSpeedKey = 'best_avg_ms_per_el_$modeKey';
    final prevBestMs = prefs.getInt(bestSpeedKey);
    if (prevBestMs == null || (avgMs > 0 && avgMs < prevBestMs)) {
      await prefs.setInt(bestSpeedKey, avgMs);
    }

    try {
      await ProfileSessionService.instance.recordSession(
        mode: modeKey,
        totalItems: n,
        correctItems: n,
        timeSeconds: max(1, (_totalMs / 1000).ceil()),
        encodingMs: _totalMs,
        correctnessPattern: List<int>.filled(n, 1),
        recordScore: displayScore,
      );
      await QuestService.instance.updateProgress(
        type: QuestType.completeXTrainings,
        value: 1,
      );
      if (newRecord) {
        await QuestService.instance.updateProgress(
          type: QuestType.improveRecord,
          value: 1,
        );
      }
      await ProgressService.instance.awardMemorization(memorizedCount: n);
    } catch (e) {
      debugPrint('Card codes trainer sync skipped: $e');
    }

    if (!mounted) return;
    setState(() {
      _resultRows = rows;
      _weakOverall = weak;
      _strongOverall = strong;
      _newRecord = newRecord;
      _prevBest = prevBest;
      _phase = _CardTrainerPhase.done;
    });
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
          AppTexts.get('card_codes_trainer'),
          style: TextStyle(
            color: onSurface,
            fontSize: 13,
            letterSpacing: 2,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.03),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: switch (_phase) {
                _CardTrainerPhase.setup =>
                  _buildSetup(onSurface, accent, palette),
                _CardTrainerPhase.run => _buildRun(onSurface, accent, palette),
                _CardTrainerPhase.done =>
                  _buildDone(onSurface, accent, palette),
              },
            ),
    );
  }

  Widget _buildSetup(Color onSurface, Color accent, AppPalette palette) {
    return Padding(
      key: const ValueKey('setup'),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppTexts.get('card_codes_count_label'),
            style: TextStyle(color: onSurface.withOpacity(0.55), fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _countStepButton(
                icon: Icons.remove,
                onSurface: onSurface,
                onTap: () => _changeCount(-1),
              ),
              Container(
                width: 96,
                height: 50,
                alignment: Alignment.center,
                child: TextField(
                  controller: _countController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                  onChanged: (_) {
                    _normalizeCountInput();
                    setState(() {});
                  },
                ),
              ),
              _countStepButton(
                icon: Icons.add,
                onSurface: onSurface,
                onTap: () => _changeCount(1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            AppTexts.get('card_codes_direction_label'),
            style: TextStyle(color: onSurface.withOpacity(0.55), fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _directionChip(
                  onSurface: onSurface,
                  accent: accent,
                  label: AppTexts.get('card_codes_direction_forward'),
                  selected: _direction == CardCodesTrainerDirection.forward,
                  onTap: () => setState(
                    () => _direction = CardCodesTrainerDirection.forward,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _directionChip(
                  onSurface: onSurface,
                  accent: accent,
                  label: AppTexts.get('card_codes_direction_reverse'),
                  selected: _direction == CardCodesTrainerDirection.reverse,
                  onTap: () => setState(
                    () => _direction = CardCodesTrainerDirection.reverse,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _direction == CardCodesTrainerDirection.forward
                ? AppTexts.get('card_codes_direction_forward_hint')
                : AppTexts.get('card_codes_direction_reverse_hint'),
            style: TextStyle(color: onSurface.withOpacity(0.4), fontSize: 11),
          ),
          const SizedBox(height: 16),
          Text(
            AppTexts.get('card_codes_available', params: {'n': '$_available'}),
            style: TextStyle(color: onSurface.withOpacity(0.45), fontSize: 11),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _available < CardCodesDeck.minTrainerCount
                ? null
                : withUiTap(() {
                    _normalizeCountInput();
                    _startSession();
                  }, sound: UiClickSound.soft),
            child: Text(AppTexts.get('card_codes_trainer_start')),
          ),
        ],
      ),
    );
  }

  Widget _countStepButton({
    required IconData icon,
    required Color onSurface,
    required VoidCallback onTap,
  }) {
    return Material(
      color: onSurface.withOpacity(0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: withUiTap(onTap, sound: UiClickSound.soft),
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 20, color: onSurface.withOpacity(0.7)),
        ),
      ),
    );
  }

  Widget _directionChip({
    required Color onSurface,
    required Color accent,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: withUiTap(onTap, sound: UiClickSound.soft),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color:
              selected ? accent.withOpacity(0.14) : onSurface.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? accent.withOpacity(0.5)
                : onSurface.withOpacity(0.12),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? accent : onSurface.withOpacity(0.65),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildRun(Color onSurface, Color accent, AppPalette palette) {
    final card = _cards[_index];
    final image = _sessionImages[card] ?? '';
    final isReverse = _direction == CardCodesTrainerDirection.reverse;
    final progress = (_index + 1) / _cards.length;

    return Padding(
      key: ValueKey('run_${_direction.name}_$card'),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_index + 1} / ${_cards.length}',
                      style: TextStyle(
                        color: onSurface.withOpacity(0.45),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isReverse
                          ? AppTexts.get('card_codes_direction_reverse_short')
                          : AppTexts.get('card_codes_direction_forward_short'),
                      style: TextStyle(
                        color: accent.withOpacity(0.65),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: isReverse
                    ? AppTexts.get('card_codes_hint_card_tooltip')
                    : AppTexts.get('card_codes_hint_image_tooltip'),
                child: Material(
                  color: _hintVisible
                      ? accent.withOpacity(0.16)
                      : onSurface.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: withUiTap(_toggleHint, sound: UiClickSound.soft),
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.help_outline_rounded,
                        size: 22,
                        color: _hintVisible
                            ? accent
                            : onSurface.withOpacity(0.55),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 4,
                backgroundColor: onSurface.withOpacity(0.06),
                color: accent.withOpacity(0.7),
              ),
            ),
          ),
          const Spacer(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                ),
                child: child,
              ),
            ),
            child: !isReverse
                ? (_hintVisible
                    ? Column(
                        key: const ValueKey('forward_hint'),
                        children: [
                          PlayingCardFace(
                            cardCode: card,
                            width: 130,
                            height: 182,
                            animateIn: true,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            image,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: onSurface.withOpacity(0.9),
                              fontSize: 22,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      )
                    : PlayingCardFace(
                        key: const ValueKey('forward_card'),
                        cardCode: card,
                        width: 150,
                        height: 210,
                        animateIn: true,
                      ))
                : (_hintVisible
                    ? Column(
                        key: const ValueKey('reverse_hint'),
                        children: [
                          Text(
                            image,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: onSurface.withOpacity(0.9),
                              fontSize: 26,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 18),
                          PlayingCardFace(
                            cardCode: card,
                            width: 130,
                            height: 182,
                            animateIn: true,
                          ),
                        ],
                      )
                    : Text(
                        key: const ValueKey('reverse_image'),
                        image,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: onSurface.withOpacity(0.9),
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                        ),
                      )),
          ),
          const Spacer(),
          FilledButton(
            onPressed: withUiTap(_next, sound: UiClickSound.soft),
            child: Text(
              _index >= _cards.length - 1
                  ? _t(const {
                      AppLanguage.ru: 'Завершить',
                      AppLanguage.en: 'Finish',
                      AppLanguage.de: 'Beenden',
                    })
                  : AppTexts.get('next_chunk'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDone(Color onSurface, Color accent, AppPalette palette) {
    final n = _cards.length;
    final avgMs = n <= 0 ? 0 : (_totalMs / n).round();
    final slowest = _resultRows.isEmpty ? null : _resultRows.first;
    final fastest = _resultRows.isEmpty ? null : _resultRows.last;

    return ListView(
      key: ValueKey('done_${_direction.name}'),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: [
        if (_newRecord)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.emoji_events_rounded, color: accent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppTexts.get('card_codes_new_record', params: {
                      'score': '$n',
                      'prev': '$_prevBest',
                    }),
                    style: TextStyle(
                      color: onSurface.withOpacity(0.88),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        _miniStat(
          onSurface: onSurface,
          accent: accent,
          palette: palette,
          label: AppTexts.get('element_stats_total'),
          value: _formatMs(_totalMs),
        ),
        const SizedBox(height: 8),
        _miniStat(
          onSurface: onSurface,
          accent: accent,
          palette: palette,
          label: AppTexts.get('element_stats_avg'),
          value: _formatMs(avgMs),
        ),
        if (slowest != null) ...[
          const SizedBox(height: 16),
          _highlightCard(
            onSurface: onSurface,
            accent: const Color(0xFFFF3B30),
            title: AppTexts.get('card_codes_weak_session'),
            card: slowest.card,
            image: slowest.image,
            time: _formatMs(slowest.ms),
            palette: palette,
          ),
        ],
        if (fastest != null && fastest.card != slowest?.card) ...[
          const SizedBox(height: 8),
          _highlightCard(
            onSurface: onSurface,
            accent: accent,
            title: AppTexts.get('card_codes_best_session'),
            card: fastest.card,
            image: fastest.image,
            time: _formatMs(fastest.ms),
            palette: palette,
          ),
        ],
        if (_weakOverall.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            AppTexts.get('number_pair_weak_overall'),
            style: TextStyle(
              color: onSurface.withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          for (final row in _weakOverall)
            _compactResultRow(
              onSurface: onSurface,
              palette: palette,
              card: row.card,
              image: row.image,
              time: _formatMs(row.avgMs),
            ),
        ],
        if (_strongOverall.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            AppTexts.get('number_pair_best_overall'),
            style: TextStyle(
              color: onSurface.withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          for (final row in _strongOverall)
            _compactResultRow(
              onSurface: onSurface,
              palette: palette,
              card: row.card,
              image: row.image,
              time: _formatMs(row.avgMs),
            ),
        ],
        const SizedBox(height: 18),
        ...List.generate(_resultRows.length, (i) {
          final row = _resultRows[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.border.withOpacity(0.28)),
            ),
            child: Row(
              children: [
                PlayingCardFace(
                  cardCode: row.card,
                  width: 36,
                  height: 50,
                  elevated: false,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    row.image,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: onSurface.withOpacity(0.78),
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  _formatMs(row.ms),
                  style: TextStyle(
                    color: onSurface.withOpacity(0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: withUiTap(() {
            setState(() => _phase = _CardTrainerPhase.setup);
            unawaited(_loadSetup());
          }, sound: UiClickSound.soft),
          child: Text(_t(const {
            AppLanguage.ru: 'Ещё раз',
            AppLanguage.en: 'Again',
            AppLanguage.de: 'Nochmal',
          })),
        ),
      ],
    );
  }

  Widget _miniStat({
    required Color onSurface,
    required Color accent,
    required AppPalette palette,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border.withOpacity(0.28)),
      ),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  color: accent, fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _compactResultRow({
    required Color onSurface,
    required AppPalette palette,
    required String card,
    required String image,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          PlayingCardFace(
            cardCode: card,
            width: 32,
            height: 44,
            elevated: false,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              image,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: onSurface.withOpacity(0.75), fontSize: 12),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: onSurface.withOpacity(0.42),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _highlightCard({
    required Color onSurface,
    required Color accent,
    required String title,
    required String card,
    required String image,
    required String time,
    required AppPalette palette,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: onSurface.withOpacity(0.55),
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              PlayingCardFace(
                cardCode: card,
                width: 40,
                height: 56,
                elevated: false,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(image,
                    style: TextStyle(
                        color: onSurface.withOpacity(0.85), fontSize: 14)),
              ),
              Text(time,
                  style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}
