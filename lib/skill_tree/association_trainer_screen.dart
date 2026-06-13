import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/core/app_session.dart';
import '../app/core/ui_feedback.dart';
import '../recovered_app.dart'
    show
        AppLanguage,
        AppPalette,
        appAccentColor,
        appLanguage,
        appPalette,
        loadWordsForLanguage;

/// Association Trainer: триггерные виджеты
/// [AssociationTrainerIntroBody], [AssociationTrainerTrainingBody],
/// [AssociationTrainerRecallBody], [AssociationTrainerResultBody].

const String _prefsAssocLvl2Ok = 'association_trainer_lvl2_unlocked';

const int _pairCountLvl1 = 10;
const int _pairCountLvl2 = 18;
const int _secPerPair = 25;
const double _passRatio = 0.70;
const int _maxHearts = 2;

int _pairCountFor(int lvl) => lvl == 2 ? _pairCountLvl2 : _pairCountLvl1;

String _txt(Map<AppLanguage, String> m) =>
    m[appLanguage.value] ?? m[AppLanguage.ru] ?? '';

String _capFixed(String s) =>
    s.isEmpty ? s : s.substring(0, 1).toUpperCase() + s.substring(1);

class AssocPairRound {
  AssocPairRound({
    required this.wordA,
    required this.wordB,
  });

  final String wordA;
  final String wordB;
  bool timedOut = false;
  double secondsUsed = _secPerPair.toDouble();
}

class RecallQ {
  const RecallQ({
    required this.pairIndex,
    required this.options,
    required this.correctIndex,
  });

  final int pairIndex;
  final List<String> options;
  final int correctIndex;
}

enum _TrainerPhase {
  intro,
  training,
  recall,
  result,
}

class AssociationTrainerScreen extends StatefulWidget {
  const AssociationTrainerScreen({super.key});

  @override
  State<AssociationTrainerScreen> createState() =>
      _AssociationTrainerScreenState();
}

class _AssociationTrainerScreenState extends State<AssociationTrainerScreen> {
  final math.Random _rng = math.Random();

  // Страховочные словари на случай, если asset-файл worsgenerator/<lang>/words.txt
  // не доступен. В обычном сценарии подгружаются настоящие списки слов из
  // тренажёра слов.
  static const List<String> _fallbackWordsRu = [
    'Камень', 'Утка', 'Яблоко', 'Дерево', 'Стул', 'Лампа', 'Облако', 'Часы',
    'Ключ', 'Мяч', 'Рыба', 'Мост', 'Дверь', 'Окно', 'Сапог', 'Зонт', 'Корабль',
    'Компас', 'Яйцо', 'Чайник', 'Роза', 'Ведро',
  ];
  static const List<String> _fallbackWordsEn = [
    'Stone', 'Duck', 'Apple', 'Tree', 'Chair', 'Lamp', 'Cloud', 'Clock', 'Key',
    'Ball', 'Fish', 'Bridge', 'Door', 'Window', 'Boot', 'Umbrella', 'Ship',
    'Compass', 'Egg', 'Kettle', 'Rose', 'Bucket',
  ];
  static const List<String> _fallbackWordsDe = [
    'Stein', 'Ente', 'Apfel', 'Baum', 'Stuhl', 'Lampe', 'Wolke', 'Uhr',
    'Schlüssel', 'Ball', 'Fisch', 'Brücke', 'Tür', 'Fenster', 'Stiefel',
    'Regenschirm', 'Schiff', 'Kompass', 'Ei', 'Kessel', 'Rose', 'Eimer',
  ];

  _TrainerPhase _phase = _TrainerPhase.intro;
  int _chosenLevel = 1;
  bool _level2Ready = false;
  bool _loadingPrefs = true;
  bool _preparingSession = false;

  // Пул слов, подгружаемый из worsgenerator/<lang>/words.txt под язык девайса.
  List<String> _wordPool = const [];

  List<AssocPairRound> _pairs = [];
  int _pairIndex = 0;
  int _ticks = 0;
  Timer? _timer;
  DateTime _started = DateTime.now();

  // Система «двух сердец».
  int _hearts = _maxHearts;
  bool _showFailOverlay = false;

  List<RecallQ>? _recQs;
  int _recIx = 0;
  int? _picked;
  bool _showFb = false;
  int _rightCount = 0;
  double _acc = 0;
  String _timeBucketRu = '';

  @override
  void initState() {
    super.initState();
    unawaited(_loadPrefs());
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getBool(_prefsAssocLvl2Ok) ?? false;
    if (mounted) {
      setState(() {
        _level2Ready = v;
        _loadingPrefs = false;
      });
    }
  }

  Future<void> _saveLvl2() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_prefsAssocLvl2Ok, true);
    if (mounted) setState(() => _level2Ready = true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    setTrainingQuietMode(false);
    super.dispose();
  }

  void _killTicker() {
    _timer?.cancel();
    _timer = null;
  }

  List<String> _fallbackForLang(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.en:
        return _fallbackWordsEn;
      case AppLanguage.de:
        return _fallbackWordsDe;
      case AppLanguage.ru:
        return _fallbackWordsRu;
    }
  }

  bool _pairDup(List<AssocPairRound> L, AssocPairRound p) {
    for (final q in L) {
      final a = '${q.wordA}|${q.wordB}';
      final b = '${q.wordB}|${q.wordA}';
      final x = '${p.wordA}|${p.wordB}';
      if (a == x || b == x) return true;
    }
    return false;
  }

  List<AssocPairRound> _buildSession(int lvl) {
    final out = <AssocPairRound>[];
    if (_wordPool.length < 2) return out;
    final target = _pairCountFor(lvl);

    // Базовый сценарий: каждое слово используется только один раз за сессию,
    // чтобы пары не содержали повторяющиеся слова.
    final uniqueWords = List<String>.from(_wordPool)..shuffle(_rng);
    final maxUniquePairs = uniqueWords.length ~/ 2;
    final needPairs = math.min(target, maxUniquePairs);
    for (var i = 0; i < needPairs * 2; i += 2) {
      out.add(AssocPairRound(wordA: uniqueWords[i], wordB: uniqueWords[i + 1]));
    }

    // Резерв: если внезапно слов не хватило, добираем уникальными парами.
    var tries = 0;
    while (out.length < target && tries++ < 16000) {
      final a = _wordPool[_rng.nextInt(_wordPool.length)];
      final b = _wordPool[_rng.nextInt(_wordPool.length)];
      if (a == b) continue;
      final alreadyUsed = out.any((p) => p.wordA == a || p.wordB == a || p.wordA == b || p.wordB == b);
      if (alreadyUsed) continue;
      final t = AssocPairRound(wordA: a, wordB: b);
      if (!_pairDup(out, t)) out.add(t);
    }
    return out;
  }

  List<String> _pickThreeWrong(String left, String right) {
    final bag = <String>{};
    for (final r in _pairs) {
      bag.add(r.wordA);
      bag.add(r.wordB);
    }
    bag.addAll(_wordPool);
    bag.remove(left);
    bag.remove(right);
    final sh = bag.toList()..shuffle(_rng);
    final w = <String>[];
    for (final x in sh) {
      if (x.isEmpty || x == right || x == left) continue;
      if (!w.contains(x)) w.add(x);
      if (w.length >= 3) break;
    }
    if (_wordPool.isNotEmpty) {
      var fi = 0;
      while (w.length < 3) {
        final s = _wordPool[(fi++) % _wordPool.length];
        if (!w.contains(s) && s != left && s != right) w.add(s);
        if (fi > _wordPool.length * 2) break;
      }
    }
    return w;
  }

  void _prepRecall() {
    _killTicker();
    final order = List<int>.generate(_pairs.length, (i) => i)..shuffle(_rng);
    final qs = _buildRecallQs(order);
    setState(() {
      _recQs = qs;
      _recIx = 0;
      _picked = null;
      _showFb = false;
      _rightCount = 0;
      _phase = _TrainerPhase.recall;
    });
  }

  List<RecallQ> _buildRecallQs(List<int> order) {
    final qs = <RecallQ>[];
    for (final pi in order.take(_pairs.length)) {
      final p = _pairs[pi];
      final c = p.wordB;
      final w = _pickThreeWrong(p.wordA, c);
      final x = [...w, c];
      x.shuffle(_rng);
      final ci = x.indexOf(c);
      qs.add(RecallQ(
          pairIndex: pi, options: List<String>.from(x), correctIndex: ci));
    }
    return qs;
  }

  void _startTicker() {
    _killTicker();
    if (_pairIndex >= _pairs.length) {
      _prepRecall();
      return;
    }
    _ticks = 0;
    _started = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _ticks++;
      setState(() {});
      if (_ticks >= _secPerPair) {
        _killTicker();
        final p = _pairs[_pairIndex];
        p.timedOut = true;
        p.secondsUsed = _secPerPair.toDouble();
        _onPairTimeout();
      }
    });
    setState(() {});
  }

  void _onPairTimeout() {
    uiTapClick(UiClickSound.bright);
    final alive = _loseHeart();
    if (!alive) {
      setState(() {});
      return;
    }
    _pairIndex++;
    if (_pairIndex >= _pairs.length) {
      _prepRecall();
    } else {
      _startTicker();
    }
    setState(() {});
  }

  Future<void> _openTraining() async {
    if (_preparingSession) return;
    setState(() => _preparingSession = true);

    final words = await loadWordsForLanguage(
      appLanguage.value,
      fallback: _fallbackForLang(appLanguage.value),
    );
    if (!mounted) return;

    final seen = <String>{};
    final pool = <String>[];
    for (final w in words) {
      final cw = _capFixed(w.trim());
      if (cw.isEmpty) continue;
      if (seen.add(cw)) pool.add(cw);
    }
    if (pool.length < 2) {
      for (final w in _fallbackForLang(appLanguage.value)) {
        if (seen.add(w)) pool.add(w);
      }
    }

    _wordPool = pool;
    _pairs = _buildSession(_chosenLevel);
    _pairIndex = 0;
    _hearts = _maxHearts;
    _showFailOverlay = false;
    _recQs = null;
    _preparingSession = false;

    setState(() => _phase = _TrainerPhase.training);
    _startTicker();
  }

  void _earlyLinked() {
    if (_trainerPhaseFrozen()) return;
    _killTicker();
    final secs = math.min(
      _secPerPair.toDouble(),
      DateTime.now().difference(_started).inMilliseconds / 1000.0,
    );
    final p = _pairs[_pairIndex];
    p.secondsUsed = secs;
    p.timedOut = false;
    _pairIndex++;
    uiTapClick(UiClickSound.soft);
    if (_pairIndex >= _pairs.length) {
      _prepRecall();
      return;
    }
    _startTicker();
    setState(() {});
  }

  bool _trainerPhaseFrozen() =>
      _phase != _TrainerPhase.training || _showFailOverlay;

  Future<void> _tapAnswer(int ix) async {
    if (_showFb || _recQs == null || _showFailOverlay) return;
    final q = _recQs![_recIx];
    final ok = ix == q.correctIndex;

    setState(() {
      _picked = ix;
      _showFb = true;
    });

    if (ok) {
      _rightCount++;
      uiTapClick(UiClickSound.soft);
    } else {
      uiTapClick(UiClickSound.bright);
    }

    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;

    if (!ok) {
      final alive = _loseHeart();
      setState(() {});
      if (!alive) return;
    }

    final last = _recIx >= (_recQs!.length - 1);
    if (last) {
      _finalizeResult();
    } else {
      setState(() {
        _recIx++;
        _picked = null;
        _showFb = false;
      });
    }
  }

  bool _loseHeart() {
    if (_hearts <= 0) return false;
    _hearts--;
    if (_hearts <= 0) {
      _killTicker();
      _showFailOverlay = true;
      return false;
    }
    return true;
  }

  void _failBackToIntro() {
    _killTicker();
    setState(() {
      _hearts = _maxHearts;
      _showFailOverlay = false;
      _pairs = [];
      _pairIndex = 0;
      _recQs = null;
      _recIx = 0;
      _picked = null;
      _showFb = false;
      _rightCount = 0;
      _phase = _TrainerPhase.intro;
    });
  }

  void _finalizeResult() {
    final total = math.max(_recQs?.length ?? 1, 1);
    _acc = _rightCount / total;

    double s = 0;
    for (final p in _pairs) {
      s += p.secondsUsed;
    }
    final avg = _pairs.isEmpty ? _secPerPair.toDouble() : s / _pairs.length;

    if (avg < 13) {
      _timeBucketRu = 'Быстро';
    } else if (avg < 22.5) {
      _timeBucketRu = 'Обычно';
    } else {
      _timeBucketRu = 'Медленно';
    }

    if (_chosenLevel == 1 && _acc >= _passRatio) {
      unawaited(_saveLvl2());
    }

    setState(() {
      _phase = _TrainerPhase.result;
      _showFb = false;
    });
  }

  void _replay() => setState(() => _phase = _TrainerPhase.intro);

  void _exitResultTap() {
    if (_chosenLevel == 1 && _acc < _passRatio) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_txt({
          AppLanguage.ru:
              'Чтобы открыть следующий уровень, нужно лучше закрепить навык',
          AppLanguage.en: 'Raise accuracy to unlock the next level.',
          AppLanguage.de: 'Erhöhe die Genauigkeit für die nächste Stufe.',
        })),
      ));
    }
    // Академия помечает урок пройденным только при Navigator.pop(true).
    final passedSession = _acc >= _passRatio;
    Navigator.of(context).pop(passedSession);
  }

  @override
  Widget build(BuildContext context) {
    final onSurf = Theme.of(context).colorScheme.onSurface;
    final quiet = _phase == _TrainerPhase.training || _phase == _TrainerPhase.recall;
    if (trainingQuietMode.value != quiet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setTrainingQuietMode(quiet);
      });
    }

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (_, __, ___) {
        return ValueListenableBuilder<AppPalette>(
          valueListenable: appPalette,
          builder: (_, palette, __) {
            final accentCol = appAccentColor.value;

            Widget page;
            if (_loadingPrefs) {
              page = const Center(child: CircularProgressIndicator());
            } else {
              switch (_phase) {
                case _TrainerPhase.intro:
                  page = AssociationTrainerIntroBody(
                    palette: palette,
                    accent: accentCol,
                    onSurface: onSurf,
                    level2Allowed: _level2Ready,
                    selectedLevel: _chosenLevel,
                    preparing: _preparingSession,
                    onPickLvl: (l) => setState(() => _chosenLevel = l),
                    onLvl2Denied: () => ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(
                      content: Text(_txt({
                        AppLanguage.ru:
                            'Чтобы открыть следующий уровень, нужно лучше закрепить навык',
                        AppLanguage.en:
                            'Reach at least 70% on level 1 to unlock level 2',
                        AppLanguage.de:
                            'Mindestens 70% auf Stufe 1 erreichen für Stufe 2',
                      })),
                    )),
                    onStart: () => unawaited(_openTraining()),
                  );
                  break;
                case _TrainerPhase.training:
                  final ix =
                      math.min(math.max(_pairIndex, 0), _pairs.length - 1);
                  final rp = _pairs.isNotEmpty
                      ? _pairs[ix]
                      : AssocPairRound(wordA: '', wordB: '');
                  page = Stack(
                    children: [
                      AssociationTrainerTrainingBody(
                        palette: palette,
                        accent: accentCol,
                        onSurface: onSurf,
                        hearts: _hearts,
                        progressLabel:
                            '${math.min(_pairIndex + 1, _pairs.length)} / ${_pairs.length}',
                        wordA: rp.wordA,
                        wordB: rp.wordB,
                        elapsedTicks: _ticks,
                        maxSec: _secPerPair,
                        onLinkedEarly: _earlyLinked,
                      ),
                      if (_showFailOverlay)
                        AssociationTrainerFailOverlay(
                          palette: palette,
                          onSurface: onSurf,
                          accent: accentCol,
                          onRetry: _failBackToIntro,
                        ),
                    ],
                  );
                  break;
                case _TrainerPhase.recall:
                  final q = _recQs![_recIx];
                  final pair = _pairs[q.pairIndex];
                  page = Stack(
                    children: [
                      AssociationTrainerRecallBody(
                        palette: palette,
                        accent: accentCol,
                        onSurface: onSurf,
                        hearts: _hearts,
                        progress: '${_recIx + 1} / ${_recQs!.length}',
                        leftWord: pair.wordA,
                        options: q.options,
                        correctIndex: q.correctIndex,
                        pickedIndex: _picked,
                        reveal: _showFb,
                        onPick: _tapAnswer,
                      ),
                      if (_showFailOverlay)
                        AssociationTrainerFailOverlay(
                          palette: palette,
                          onSurface: onSurf,
                          accent: accentCol,
                          onRetry: _failBackToIntro,
                        ),
                    ],
                  );
                  break;
                case _TrainerPhase.result:
                  page = AssociationTrainerResultBody(
                    palette: palette,
                    accent: accentCol,
                    onSurface: onSurf,
                    accuracyPct: ((_acc * 100).round()),
                    rhythmRu: _timeBucketRu,
                    highScore: _acc >= _passRatio,
                    onRepeat: _replay,
                    onNext: _exitResultTap,
                  );
              }
            }

            return Scaffold(
              backgroundColor: palette.background,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                foregroundColor: onSurf.withOpacity(0.74),
              ),
              body: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  key: ValueKey(_phase.index),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: page,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class AssociationTrainerIntroBody extends StatelessWidget {
  const AssociationTrainerIntroBody({
    super.key,
    required this.palette,
    required this.accent,
    required this.onSurface,
    required this.level2Allowed,
    required this.selectedLevel,
    required this.preparing,
    required this.onPickLvl,
    required this.onLvl2Denied,
    required this.onStart,
  });

  final AppPalette palette;
  final Color accent;
  final Color onSurface;
  final bool level2Allowed;
  final int selectedLevel;
  final bool preparing;
  final ValueChanged<int> onPickLvl;
  final VoidCallback onLvl2Denied;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            _txt({
              AppLanguage.ru: 'Связывание образов',
              AppLanguage.en: 'Imagery linking',
              AppLanguage.de: 'Bilder verknüpfen',
            }),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w200,
              color: onSurface,
              letterSpacing: 1.05,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _txt({
              AppLanguage.ru:
                  'Твоя задача — соединить 2 объекта в один яркий, странный и живой образ в голове.',
              AppLanguage.en:
                  'Your task is to link two objects into one vivid, strange and lively mental picture.',
              AppLanguage.de:
                  'Deine Aufgabe: zwei Dinge zu einem hellen, seltsamen und lebendigen inneren Bild verbinden.',
            }),
            style: TextStyle(
              height: 1.45,
              fontSize: 14.9,
              color: onSurface.withOpacity(0.73),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 18),
          _bullet(
              _txt({
                AppLanguage.ru: 'Используй движение',
                AppLanguage.en: 'Use movement',
                AppLanguage.de: 'Nutze Bewegung',
              }),
              accent,
              onSurface),
          _bullet(
              _txt({
                AppLanguage.ru: 'Добавляй эмоции',
                AppLanguage.en: 'Add emotion',
                AppLanguage.de: 'Nutze Emotion',
              }),
              accent,
              onSurface),
          _bullet(
              _txt({
                AppLanguage.ru: 'Делай образ странным',
                AppLanguage.en: 'Make the image strange',
                AppLanguage.de: 'Mach es eigenartig',
              }),
              accent,
              onSurface),
          const SizedBox(height: 18),
          Text(
            _txt({
              AppLanguage.ru: 'Примеры',
              AppLanguage.en: 'Examples',
              AppLanguage.de: 'Beispiele',
            }),
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w700,
              color: onSurface.withOpacity(0.48),
            ),
          ),
          const SizedBox(height: 8),
          _example(
              _txt({
                AppLanguage.ru:
                    'Представь автобус с огромными клыками спереди',
                AppLanguage.en:
                    'Picture a bus with huge fangs sticking out of the front',
                AppLanguage.de:
                    'Stell dir einen Bus mit riesigen Reißzähnen vorne vor',
              }),
              accent,
              onSurface),
          _example(
              _txt({
                AppLanguage.ru:
                    'Представь, как груша вырастает прямо из пня',
                AppLanguage.en:
                    'Imagine a pear growing right out of a tree stump',
                AppLanguage.de:
                    'Stell dir vor, wie eine Birne direkt aus einem Baumstumpf wächst',
              }),
              accent,
              onSurface),
          const SizedBox(height: 20),
          Text(
            _txt({
              AppLanguage.ru: 'У тебя есть 25 секунд на каждую пару',
              AppLanguage.en: 'You get 25 seconds per pair',
              AppLanguage.de: '25 Sekunden pro Paar',
            }),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: accent.withOpacity(0.95),
              fontSize: 13.9,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            _txt({
              AppLanguage.ru: 'Уровень',
              AppLanguage.en: 'Level',
              AppLanguage.de: 'Stufe',
            }),
            style: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.48)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _LvlTile(
                      label: _txt({
                        AppLanguage.ru: 'Уровень 1',
                        AppLanguage.en: 'Level 1',
                        AppLanguage.de: 'Stufe 1',
                      }),
                      active: selectedLevel == 1,
                      locked: false,
                      palette: palette,
                      accent: accent,
                      onSurface: onSurface,
                      showLockIcon: false,
                      onTap: () => onPickLvl(1))),
              const SizedBox(width: 10),
              Expanded(
                  child: _LvlTile(
                      label: _txt({
                        AppLanguage.ru: 'Уровень 2',
                        AppLanguage.en: 'Level 2',
                        AppLanguage.de: 'Stufe 2',
                      }),
                      active: selectedLevel == 2 && level2Allowed,
                      locked: !level2Allowed,
                      palette: palette,
                      accent: accent,
                      onSurface: onSurface,
                      showLockIcon: !level2Allowed,
                      onTap: () {
                        if (!level2Allowed) {
                          onLvl2Denied();
                          return;
                        }
                        onPickLvl(2);
                      })),
            ],
          ),
          if (selectedLevel == 1 || selectedLevel == 2)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(Icons.favorite_rounded,
                      size: 14, color: accent.withOpacity(0.95)),
                  const SizedBox(width: 6),
                  Icon(Icons.favorite_rounded,
                      size: 14, color: accent.withOpacity(0.95)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _txt({
                        AppLanguage.ru:
                            'У тебя 2 возможности ошибиться, береги сердца.',
                        AppLanguage.en:
                            'You have 2 chances to make a mistake, protect your hearts.',
                        AppLanguage.de:
                            'Du hast 2 Versuche, einen Fehler zu machen — pass auf deine Herzen auf.',
                      }),
                      style: TextStyle(
                        fontSize: 12.2,
                        height: 1.35,
                        color: onSurface.withOpacity(0.78),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (!level2Allowed)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _txt({
                  AppLanguage.ru:
                      'Не менее 70% на уровне 1 нужно чтобы открыть уровень 2',
                  AppLanguage.en:
                      'You need ≥70% on level 1 to unlock level 2',
                  AppLanguage.de:
                      'Mind. 70% in Stufe 1 zur Freischaltung',
                }),
                style: TextStyle(
                    fontSize: 11, color: onSurface.withOpacity(0.45)),
              ),
            ),
          const SizedBox(height: 36),
          _GlowChipButton(
              palette: palette,
              accent: accent,
              label: preparing
                  ? _txt({
                      AppLanguage.ru: 'Готовим...',
                      AppLanguage.en: 'Preparing...',
                      AppLanguage.de: 'Lade...',
                    })
                  : _txt({
                      AppLanguage.ru: 'Начать',
                      AppLanguage.en: 'Start',
                      AppLanguage.de: 'Start',
                    }),
              onTap: () {
                if (preparing) return;
                if (!level2Allowed && selectedLevel == 2) {
                  onLvl2Denied();
                  return;
                }
                onStart();
              }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  static Widget _bullet(String t, Color a, Color o) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Icon(Icons.circle, size: 5, color: a.withOpacity(0.82)),
          const SizedBox(width: 11),
          Expanded(
              child: Text(t,
                  style: TextStyle(
                      height: 1.38,
                      fontSize: 14,
                      color: o.withOpacity(0.87)))),
        ]),
      );

  static Widget _example(String t, Color a, Color o) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(Icons.auto_awesome,
                  size: 13, color: a.withOpacity(0.72)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                t,
                style: TextStyle(
                  height: 1.42,
                  fontSize: 13.3,
                  fontStyle: FontStyle.italic,
                  color: o.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      );
}

class AssociationTrainerTrainingBody extends StatelessWidget {
  const AssociationTrainerTrainingBody({
    super.key,
    required this.palette,
    required this.accent,
    required this.onSurface,
    required this.hearts,
    required this.progressLabel,
    required this.wordA,
    required this.wordB,
    required this.elapsedTicks,
    required this.maxSec,
    required this.onLinkedEarly,
  });

  final AppPalette palette;
  final Color accent;
  final Color onSurface;
  final int hearts;
  final String progressLabel;
  final String wordA;
  final String wordB;
  final int elapsedTicks;
  final int maxSec;
  final VoidCallback onLinkedEarly;

  @override
  Widget build(BuildContext context) {
    final t = math.min(maxSec, elapsedTicks.clamp(0, maxSec));
    final frac = t / math.max(maxSec, 1);
    final show = math.max(maxSec - t, 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 6),
        _HeartsStrip(remaining: hearts, accent: accent),
        const SizedBox(height: 12),
        Text(
          progressLabel,
          textAlign: TextAlign.center,
          style: TextStyle(
            letterSpacing: 1.55,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: onSurface.withOpacity(0.44),
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: SizedBox(
            width: 116,
            height: 116,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: math.max(0.002, 1 - frac.toDouble()),
                    strokeWidth: 4.8,
                    color: accent,
                    backgroundColor: palette.border.withOpacity(0.5),
                  ),
                ),
                Text(
                  '$show',
                  style: TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.w200,
                      color: onSurface.withOpacity(0.9)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 34),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
          child: Container(
            key: ValueKey('$wordA|$wordB'),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: palette.border.withOpacity(0.45)),
              boxShadow: [
                BoxShadow(
                  blurRadius: 28,
                  color: accent.withOpacity(0.09),
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Text(
              '$wordA — $wordB',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.06,
                  fontSize: 22,
                  color: onSurface.withOpacity(0.96)),
            ),
          ),
        ),
        const Spacer(),
        _GlowChipButton(
            palette: palette,
            accent: accent,
            label: _txt({
              AppLanguage.ru: 'Связал образ',
              AppLanguage.en: 'Linked the image',
              AppLanguage.de: 'Bild verknüpft',
            }),
            subdued: true,
            onTap: onLinkedEarly),
        const SizedBox(height: 28),
      ],
    );
  }
}

class AssociationTrainerFailOverlay extends StatelessWidget {
  const AssociationTrainerFailOverlay({
    super.key,
    required this.palette,
    required this.onSurface,
    required this.accent,
    required this.onRetry,
  });

  final AppPalette palette;
  final Color onSurface;
  final Color accent;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withOpacity(0.58),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: palette.border.withOpacity(0.55)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.heart_broken_rounded,
                  size: 42, color: accent.withOpacity(0.9)),
              const SizedBox(height: 14),
              Text(
                _txt({
                  AppLanguage.ru: 'Не получилось, давай ещё раз',
                  AppLanguage.en: 'Didn\'t work out, let\'s try again',
                  AppLanguage.de: 'Hat nicht geklappt, probier noch mal',
                }),
                textAlign: TextAlign.center,
                style: TextStyle(
                    height: 1.38,
                    fontWeight: FontWeight.w500,
                    color: onSurface.withOpacity(0.92),
                    fontSize: 17),
              ),
              const SizedBox(height: 22),
              _GlowChipButton(
                  palette: palette,
                  accent: accent,
                  label: _txt({
                    AppLanguage.ru: 'К началу урока',
                    AppLanguage.en: 'Back to the start',
                    AppLanguage.de: 'Zurück zum Start',
                  }),
                  onTap: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}

class AssociationTrainerRecallBody extends StatelessWidget {
  const AssociationTrainerRecallBody({
    super.key,
    required this.palette,
    required this.accent,
    required this.onSurface,
    required this.hearts,
    required this.progress,
    required this.leftWord,
    required this.options,
    required this.correctIndex,
    required this.pickedIndex,
    required this.reveal,
    required this.onPick,
  });

  final AppPalette palette;
  final Color accent;
  final Color onSurface;
  final int hearts;
  final String progress;
  final String leftWord;
  final List<String> options;
  final int correctIndex;
  final int? pickedIndex;
  final bool reveal;
  final Future<void> Function(int) onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 6),
        _HeartsStrip(remaining: hearts, accent: accent),
        const SizedBox(height: 10),
        Text(
          progress,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 11.8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: onSurface.withOpacity(0.45)),
        ),
        const SizedBox(height: 28),
        Text(
          _txt({
            AppLanguage.ru: '${leftWord.capFixed} был связан с чем?',
            AppLanguage.en: '${leftWord.capFixed} was linked to what?',
            AppLanguage.de: '${leftWord.capFixed} war womit verbunden?',
          }),
          textAlign: TextAlign.center,
          style: TextStyle(
              fontWeight: FontWeight.w500,
              height: 1.35,
              fontSize: 19,
              color: onSurface.withOpacity(0.95)),
        ),
        const SizedBox(height: 28),
        ...List.generate(options.length, (i) {
          final label = options[i];
          Color border = palette.border.withOpacity(0.4);
          if (reveal) {
            final isCorrectSpot = i == correctIndex;
            final isPicked = pickedIndex == i;
            if (isCorrectSpot) {
              border = accent;
            } else if (isPicked && !isCorrectSpot) {
              border = const Color(0xFFFF5252);
            }
          }
          final showGlow =
              reveal && (pickedIndex == i || i == correctIndex);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: reveal ? null : () => onPick(i),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 16, horizontal: 14),
                decoration: BoxDecoration(
                  color: palette.card.withOpacity(0.94),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    width: showGlow ? 1.45 : 0.9,
                    color: border,
                  ),
                  boxShadow: !showGlow
                      ? []
                      : [
                          BoxShadow(
                            blurRadius: 18,
                            color: (pickedIndex == i &&
                                        pickedIndex != correctIndex
                                    ? const Color(0xFFFF5252)
                                    : accent)
                                .withOpacity(0.22),
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.9,
                      color: onSurface.withOpacity(0.92),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }),
        const Spacer(),
      ],
    );
  }
}

class AssociationTrainerResultBody extends StatelessWidget {
  const AssociationTrainerResultBody({
    super.key,
    required this.palette,
    required this.accent,
    required this.onSurface,
    required this.accuracyPct,
    required this.rhythmRu,
    required this.highScore,
    required this.onRepeat,
    required this.onNext,
  });

  final AppPalette palette;
  final Color accent;
  final Color onSurface;
  final int accuracyPct;
  final String rhythmRu;
  final bool highScore;
  final VoidCallback onRepeat;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Text(
          _txt({
            AppLanguage.ru: '$accuracyPct%',
            AppLanguage.en: '$accuracyPct% accuracy',
            AppLanguage.de: '$accuracyPct% korrekt',
          }),
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 34, fontWeight: FontWeight.w200, color: accent),
        ),
        const SizedBox(height: 24),
        Text(
          '${_txt({
            AppLanguage.ru: 'Темп воспроизведения:',
            AppLanguage.en: 'Response pace:',
            AppLanguage.de: 'Tempo:',
          })} $rhythmRu',
          style: TextStyle(color: onSurface.withOpacity(0.78)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        Text(
          highScore
              ? _txt({
                  AppLanguage.ru: 'Отлично. Ты начинаешь мыслить образами',
                  AppLanguage.en:
                      'Great. You\'re beginning to think in images.',
                  AppLanguage.de:
                      'Sehr gut. Du denkst zunehmend in Bildern.',
                })
              : _txt({
                  AppLanguage.ru: 'Нужно больше яркости и скорости',
                  AppLanguage.en: 'Needs more vividness and speed',
                  AppLanguage.de: 'Braucht mehr Klarheit und Tempo',
                }),
          style: TextStyle(
              height: 1.5,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: onSurface.withOpacity(0.88)),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        _GlowChipButton(
            palette: palette,
            accent: accent,
            label: _txt({
              AppLanguage.ru: 'Повторить',
              AppLanguage.en: 'Repeat',
              AppLanguage.de: 'Wiederholen',
            }),
            onTap: onRepeat),
        const SizedBox(height: 13),
        _GlowChipButton(
            palette: palette,
            accent: accent,
            subdued: true,
            label: _txt({
              AppLanguage.ru: 'Дальше',
              AppLanguage.en: 'Next',
              AppLanguage.de: 'Weiter',
            }),
            onTap: onNext),
        const SizedBox(height: 36),
      ],
    );
  }
}

class _HeartsStrip extends StatelessWidget {
  const _HeartsStrip({required this.remaining, required this.accent});

  final int remaining;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_maxHearts, (i) {
        final alive = i < remaining;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _Heart(alive: alive, accent: accent),
        );
      }),
    );
  }
}

class _Heart extends StatefulWidget {
  const _Heart({required this.alive, required this.accent});

  final bool alive;
  final Color accent;

  @override
  State<_Heart> createState() => _HeartState();
}

class _HeartState extends State<_Heart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _curved;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
      value: widget.alive ? 1.0 : 0.0,
    );
    _curved = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  }

  @override
  void didUpdateWidget(covariant _Heart old) {
    super.didUpdateWidget(old);
    if (widget.alive != old.alive) {
      if (widget.alive) {
        _c.forward();
      } else {
        _c.reverse();
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curved,
      builder: (_, __) {
        final t = _curved.value;
        final scale = 0.88 + 0.12 * t;
        final opacity = 0.18 + 0.82 * t;
        final col = Color.lerp(
          widget.accent.withOpacity(0.35),
          widget.accent,
          t,
        );
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Icon(
              Icons.favorite_rounded,
              size: 26,
              color: col,
              shadows: t > 0.35
                  ? [
                      Shadow(
                        color: widget.accent.withOpacity(0.45 * t),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      },
    );
  }
}

class _LvlTile extends StatelessWidget {
  const _LvlTile({
    required this.label,
    required this.active,
    required this.locked,
    required this.showLockIcon,
    required this.palette,
    required this.accent,
    required this.onSurface,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool locked;
  final bool showLockIcon;
  final AppPalette palette;
  final Color accent;
  final Color onSurface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final faded = locked && label.contains('2');
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            width: active ? 1.45 : 0.92,
            color: faded
                ? accent.withOpacity(0.2)
                : active
                    ? accent.withOpacity(0.7)
                    : onSurface.withOpacity(0.19),
          ),
          color: palette.surface.withOpacity(faded ? 0.5 : 0.97),
          boxShadow: active
              ? [BoxShadow(color: accent.withOpacity(0.2), blurRadius: 22)]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showLockIcon) ...[
              Icon(Icons.lock_rounded,
                  size: 16, color: onSurface.withOpacity(0.4)),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: faded
                    ? onSurface.withOpacity(0.4)
                    : onSurface.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowChipButton extends StatefulWidget {
  const _GlowChipButton({
    required this.palette,
    required this.accent,
    required this.label,
    required this.onTap,
    this.subdued = false,
  });

  final AppPalette palette;
  final Color accent;
  final String label;
  final VoidCallback onTap;
  final bool subdued;

  @override
  State<_GlowChipButton> createState() => __GlowChipButtonState();
}

class __GlowChipButtonState extends State<_GlowChipButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 95));
    _c.value = 1;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    await _c.reverse();
    if (mounted) unawaited(_c.forward());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final bgCol =
        widget.subdued ? widget.palette.card : widget.accent.withOpacity(0.96);
    final fgCol = widget.subdued
        ? Colors.white.withOpacity(0.88)
        : Colors.black.withOpacity(0.8);
    final border = Border.all(
        width: widget.subdued ? 0.9 : 0,
        color: widget.accent.withOpacity(widget.subdued ? 0.43 : 0));

    final Animation<double> scaleAnim = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));

    return ScaleTransition(
      scale: scaleAnim,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTapDown: (_) => _c.reverse(from: 1),
          onTapCancel: () => _c.forward(),
          onTap: _go,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: bgCol,
              border: border,
              boxShadow: widget.subdued
                  ? []
                  : [
                      BoxShadow(
                          blurRadius: 22,
                          color: widget.accent.withOpacity(0.28),
                          offset: const Offset(0, 8))
                    ],
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                  letterSpacing: 1.06,
                  fontWeight: FontWeight.w700,
                  color: fgCol,
                  fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}

extension on String {
  /// Навигационный текст «был»: первая буква в верхний регистр
  String get capFixed =>
      isEmpty ? this : substring(0, 1).toUpperCase() + substring(1);
}
