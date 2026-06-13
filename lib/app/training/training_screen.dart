part of 'package:flutter_application_1/recovered_app.dart';

enum _NumbersSubMode { standard, matrix, pi }

// --- ЭКРАН ТРЕНИРОВКИ ---
class TrainingScreen extends StatefulWidget {
  final TrainingMode? initialMode;
  final TrainingHistoryEntry? historyEntry;

  /// Префилл для уроков академии: стандартный режим, диапазон 0–9 → `1`.
  final int? academyStandardDigitsLevel;
  final int? academyElementCount;
  final bool? academyUseMemorizationTimer;
  final double? academyFlashSecondsPerItem;
  final int? academyChunkSize;

  /// [TrainerMode.duel]: same trainer UI with Firestore-synced multiplayer.
  final TrainerMode trainerMode;
  final String? duelRoomId;
  final int? duelInitialChunkSize;

  const TrainingScreen({
    super.key,
    this.initialMode,
    this.historyEntry,
    this.academyStandardDigitsLevel,
    this.academyElementCount,
    this.academyUseMemorizationTimer,
    this.academyFlashSecondsPerItem,
    this.academyChunkSize,
    this.trainerMode = TrainerMode.solo,
    this.duelRoomId,
    this.duelInitialChunkSize,
  });

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final TextEditingController _totalCountController =
      TextEditingController(text: "4");
  final TextEditingController _chunkSizeController =
      TextEditingController(text: "1");
  final TextEditingController _flashSecondsController =
      TextEditingController(text: "2.0");
  final TextEditingController _slotController =
      TextEditingController(text: "1");

  late TrainingMode _selectedMode;
  bool _useMemorizationTimer = false;

  /// Лимит времени на фазу запоминания (сек). 0 — без лимита (выбор сохраняется в prefs).
  int _sessionMemCapSec = 0;

  /// Зафиксировано при старте сессии запоминания (не меняется во время прохождения).
  int _activeSessionMemCapSec = 0;
  int _standardDigits = 2;
  final List<_LociRoute> _trainingLociRoutes = <_LociRoute>[];
  int _selectedTrainingLociRoute = -1;
  int _lociStartIndex = 0;
  List<String> _attachedLociByElement = <String>[];

  @override
  void initState() {
    super.initState();
    enterTrainingSession();
    _selectedMode = widget.historyEntry == null
        ? (widget.initialMode ?? TrainingMode.standard)
        : _modeFromHistory(widget.historyEntry!.mode);
    if (appLanguage.value == AppLanguage.ru) {
      _selectedFaceNamePool = 'RUNAME';
    } else if (appLanguage.value == AppLanguage.de) {
      _selectedFaceNamePool = 'GERNAME';
    } else {
      _selectedFaceNamePool = 'ENGNAME';
    }
    _selectedWordsLanguage = appLanguage.value;
    if (_isDuelRun) {
      _isSettingsMode = false;
      _duelController = DuelTrainerController(
        roomId: widget.duelRoomId!,
        onRoomUpdate: _onDuelRoomUpdate,
        onPhaseChanged: _onDuelPhaseChanged,
        onForceRecall: () {
          if (mounted && _isMemorizing) {
            _completeMemorizationToRecall(trimToSeenPrefix: true);
          }
        },
        onRecallExpired: () {
          if (mounted) unawaited(_onDuelRecallExpired());
        },
        onNavigateToResults: () {
          if (mounted) _navigateToDuelResults();
        },
        onRoomClosed: () {
          if (mounted) Navigator.of(context).maybePop();
        },
      );
      _duelController!.start();
    } else if (widget.historyEntry != null) {
      _loadHistoryEntry(widget.historyEntry!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      _applyAcademyTrainingPresets();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _guardInitialOnlineMode());
    }
    unawaited(_loadTrainingLociRoutes());
    if (!_isDuelRun) {
      unawaited(_loadSessionMemCapPref());
    }
    if (widget.historyEntry == null && !_isDuelRun) {
      unawaited(
          _loadModeCountPrefsForMode(_selectedMode, skipAcademyPresets: true));
      unawaited(_loadCardsDeckModePref());
      unawaited(_loadWordsTrainingPrefs());
    }
  }

  Future<void> _loadCardsDeckModePref() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _cardsShuffledDeckMode =
        prefs.getBool(_kPrefsCardsShuffledDeck) ?? false);
  }

  Future<void> _persistCardsDeckModePref() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefsCardsShuffledDeck, _cardsShuffledDeckMode);
  }

  Future<void> _loadWordsTrainingPrefs() async {
    final savedLang = await loadSavedWordsTrainingLanguage();
    final counts = <AppLanguage, int>{};
    for (final lang in AppLanguage.values) {
      counts[lang] = await wordsCountForLanguage(lang);
    }
    await FaceCatalogService.instance.ensureLoaded();
    if (!mounted) return;
    setState(() {
      if (savedLang != null) {
        _selectedWordsLanguage = savedLang;
      }
      _wordsCountByLanguage
        ..clear()
        ..addAll(counts);
      _faceCatalogSize = FaceCatalogService.instance.entries.length;
    });
  }

  Future<void> _refreshWordsCounts() async {
    final counts = <AppLanguage, int>{};
    for (final lang in AppLanguage.values) {
      counts[lang] = await wordsCountForLanguage(lang);
    }
    if (!mounted) return;
    setState(() {
      _wordsCountByLanguage
        ..clear()
        ..addAll(counts);
    });
  }

  int _maxTotalCountForMode(TrainingMode mode) {
    if (_activeLevelChallenge != null) {
      return _activeLevelChallenge!.elementCount.clamp(1, kTrainerElementCountMax);
    }
    if (mode == TrainingMode.cards && _cardsShuffledDeckMode) {
      return kPlayingCardDeckSize;
    }
    return kTrainerElementCountMax;
  }

  String _totalCountPrefsKeyForMode(TrainingMode mode) =>
      '$_kTrainingTotalCountPerModePrefsPrefix${mode.name}';

  String _chunkCountPrefsKeyForMode(TrainingMode mode) =>
      '$_kTrainingChunkCountPerModePrefsPrefix${mode.name}';

  int _maxChunkForMode(TrainingMode mode) => maxChunkForTrainingMode(mode);

  int _safeTotalCountForMode(TrainingMode mode, int? raw) {
    return (raw ?? 4).clamp(1, _maxTotalCountForMode(mode));
  }

  int _safeChunkCountForMode(TrainingMode mode, int? raw) {
    return (raw ?? 1).clamp(1, _maxChunkForMode(mode));
  }

  Future<void> _loadModeCountPrefsForMode(
    TrainingMode mode, {
    bool skipAcademyPresets = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final int savedTotal = _safeTotalCountForMode(
      mode,
      prefs.getInt(_totalCountPrefsKeyForMode(mode)),
    );
    final int savedChunk = _safeChunkCountForMode(
      mode,
      prefs.getInt(_chunkCountPrefsKeyForMode(mode)),
    );

    if (!mounted || _selectedMode != mode) return;

    final bool keepAcademyTotal =
        skipAcademyPresets && widget.academyElementCount != null;
    final bool keepAcademyChunk =
        skipAcademyPresets && widget.academyChunkSize != null;

    if (!keepAcademyTotal) {
      _totalCountController.text = '$savedTotal';
    }
    if (!keepAcademyChunk) {
      _chunkSizeController.text = '$savedChunk';
    }

    _normalizeCounter(_totalCountController, isChunk: false, persist: false);
    _normalizeCounter(_chunkSizeController, isChunk: true, persist: false);
    if (mounted) setState(() {});
  }

  Future<void> _persistModeCountPrefsForMode(TrainingMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final int total =
        _safeTotalCountForMode(mode, int.tryParse(_totalCountController.text));
    final int chunk =
        _safeChunkCountForMode(mode, int.tryParse(_chunkSizeController.text));
    await prefs.setInt(_totalCountPrefsKeyForMode(mode), total);
    await prefs.setInt(_chunkCountPrefsKeyForMode(mode), chunk);
  }

  Future<void> _loadSessionMemCapPref() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getInt(_kTrainingSessionMemCapSecPrefsKey);
    if (!mounted) return;
    final v = raw == null || raw <= 0 ? 0 : raw.clamp(15, 7200);
    setState(() => _sessionMemCapSec = v);
  }

  Future<void> _persistSessionMemCapPref() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(
      _kTrainingSessionMemCapSecPrefsKey,
      _sessionMemCapSec <= 0 ? 0 : _sessionMemCapSec,
    );
  }

  void _applyAcademyTrainingPresets() {
    if (widget.historyEntry != null) return;
    final d = widget.academyStandardDigitsLevel;
    if (d != null) {
      _standardDigits = d.clamp(1, 3);
    }
    final n = widget.academyElementCount;
    if (n != null) {
      _totalCountController.text = '${n.clamp(1, 999)}';
    }
    final tm = widget.academyUseMemorizationTimer;
    if (tm != null) {
      _useMemorizationTimer = tm;
    }
    final flash = widget.academyFlashSecondsPerItem;
    if (flash != null && flash > 0) {
      _flashSecondsController.text = flash.toString();
    }
    final ch = widget.academyChunkSize;
    if (ch != null) {
      _chunkSizeController.text = '${ch.clamp(1, 999)}';
    }
    if (widget.academyElementCount != null ||
        widget.academyStandardDigitsLevel != null) {
      _numbersSubMode = _NumbersSubMode.standard;
    }
  }

  TrainingMode _modeFromHistory(String mode) {
    return TrainingMode.values.firstWhere(
      (m) => m.name == mode,
      orElse: () => TrainingMode.standard,
    );
  }

  void _loadHistoryEntry(TrainingHistoryEntry entry) {
    _isHistoryReplay = true;
    _data = List<String>.from(entry.data);
    _controllers = List.generate(_data.length, (i) {
      final text = i < entry.answers.length ? entry.answers[i] : '';
      return TextEditingController(text: text);
    });
    _focusNodes = List.generate(_data.length, (_) => FocusNode());
    _imageAnswerOrder = entry.imageAnswerOrder.length == _data.length
        ? List<int?>.from(entry.imageAnswerOrder)
        : List<int?>.filled(_data.length, null);
    _shuffledImageIndices = List.generate(_data.length, (i) => i);
    _shuffledFaceIndices = List.generate(_data.length, (i) => i);
    _imageProviders = _selectedMode == TrainingMode.faces
        ? _data.map(_decodeFaceEntry).map(_faceImageProvider).toList()
        : (_selectedMode == TrainingMode.images
            ? _data
                .map((url) => ResizeImage(NetworkImage(url), width: 700))
                .toList()
            : <ImageProvider>[]);
    _memorizationElapsedMs = entry.memorizationMs;
    _recallElapsedMs = entry.recallMs;
    _memorizationMsByElement = entry.memorizationMsByElement.length ==
            _data.length
        ? List<int>.from(entry.memorizationMsByElement)
        : List<int>.filled(
            _data.length,
            _data.isEmpty ? 0 : (entry.memorizationMs / _data.length).round(),
          );
    _xpEarnedLast = entry.xpEarned;
    _resultComparisonLine = _historyResultLine(entry);
    _streakLine = '';
    _isSettingsMode = false;
    _isMemorizing = false;
    _isInputMode = true;
    _isChecking = true;
    _currentChunkIndex = 0;
    _attachedLociByElement = List<String>.filled(_data.length, '');
  }

  Future<void> _loadTrainingLociRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLociRoutesPrefsKey);
    final parsed = <_LociRoute>[];
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          parsed.addAll(
            decoded
                .whereType<Map>()
                .map((e) => _LociRoute.fromJson(Map<String, dynamic>.from(e)))
                .where((e) => e.name.trim().isNotEmpty && e.loci.isNotEmpty),
          );
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _trainingLociRoutes
        ..clear()
        ..addAll(parsed);
      if (_trainingLociRoutes.isEmpty) {
        _selectedTrainingLociRoute = -1;
        _lociStartIndex = 0;
      } else {
        if (_selectedTrainingLociRoute >= _trainingLociRoutes.length) {
          _selectedTrainingLociRoute = -1;
        }
        if (_selectedTrainingLociRoute >= 0) {
          final maxStart =
              _trainingLociRoutes[_selectedTrainingLociRoute].loci.length - 1;
          _lociStartIndex = _lociStartIndex.clamp(0, max(0, maxStart));
        } else {
          _lociStartIndex = 0;
        }
      }
      _rebuildAttachedLoci();
    });
  }

  String _historyResultLine(TrainingHistoryEntry entry) {
    final date = entry.date;
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '${AppTexts.get('training_history_replay')}: $d.$m.$y $hh:$mm';
  }

  Future<void> _guardInitialOnlineMode() async {
    final initial = widget.initialMode;
    if (initial != TrainingMode.images) return;
    if (await trainingHasInternetAccess()) return;
    if (!mounted) return;
    await _showOfflinePhotoFacesDialog();
    if (mounted) setState(() => _selectedMode = TrainingMode.standard);
  }

  Future<void> _showOfflinePhotoFacesDialog() async {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = appAccentColor.value;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          backgroundColor: palette.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.wifi_off_rounded,
                      size: 32, color: accent.withOpacity(0.88)),
                ),
                const SizedBox(height: 18),
                Text(
                  AppTexts.get('offline_photo_faces_title'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: onSurface.withOpacity(0.94),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppTexts.get('offline_photo_faces_message'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: onSurface.withOpacity(0.62),
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      AppTexts.get('offline_photo_faces_ok'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, letterSpacing: 0.4),
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

  final List<String> _fallbackDictionary = const [
    'Стол',
    'Стул',
    'Диван',
    'Кровать',
    'Шкаф',
    'Полка',
    'Кресло',
    'Тумбочка',
    'Комод',
    'Зеркало',
    'Ковер',
    'Штора',
    'Люстра',
    'Лампа',
    'Картина',
    'Ваза',
    'Подушка',
    'Одеяло',
    'Матрас',
    'Дверь',
    'Окно',
    'Подоконник',
    'Порог',
    'Стена',
    'Пол',
    'Потолок',
    'Лестница',
    'Вешалка',
    'Замок',
    'Ключ',
    'Холодильник',
    'Плита',
    'Духовка',
    'Микроволновка',
    'Чайник',
    'Кастрюля',
    'Сковорода',
    'Тарелка',
    'Чашка',
    'Стакан',
    'Ложка',
    'Вилка',
    'Нож',
    'Доска',
    'Половник',
    'Дуршлаг',
    'Терка',
    'Салфетка',
    'Скатерть',
    'Фартук',
    'Хлеб',
    'Молоко',
    'Сыр',
    'Яйцо',
    'Мясо',
    'Рыба',
    'Овощ',
    'Фрукт',
    'Сахар',
    'Соль',
    'Рубашка',
    'Футболка',
    'Брюки',
    'Джинсы',
    'Платье',
    'Юбка',
    'Кофта',
    'Свитер',
    'Куртка',
    'Пальто',
    'Шапка',
    'Шарф',
    'Перчатки',
    'Носки',
    'Трусы',
    'Ботинки',
    'Кроссовки',
    'Туфли',
    'Сапоги',
    'Тапочки',
    'Ремень',
    'Сумка',
    'Рюкзак',
    'Кошелек',
    'Часы',
    'Очки',
    'Зонт',
    'Кольцо',
    'Браслет',
    'Галстук',
    'Компьютер',
    'Ноутбук',
    'Телефон',
    'Планшет',
    'Монитор',
    'Клавиатура',
    'Мышь',
    'Принтер',
    'Сканер',
    'Наушники',
    'Колонка',
    'Телевизор',
    'Камера',
    'Плеер',
    'Провод',
    'Зарядка',
    'Батарейка',
    'Розетка',
    'Выключатель',
    'Пылесос',
    'Утюг',
    'Фен',
    'Кондиционер',
    'Вентилятор',
    'Радио',
    'Флешка',
    'Диск',
    'Экран',
    'Кнопка',
    'Пульт',
    'Ручка',
    'Карандаш',
    'Тетрадь',
    'Блокнот',
    'Книга',
    'Учебник',
    'Линейка',
    'Ластик',
    'Точилка',
    'Клей',
    'Ножницы',
    'Скрепка',
    'Папка',
    'Бумага',
    'Маркер',
    'Краска',
    'Кисть',
    'Альбом',
    'Циркуль',
    'Дырокол',
    'Степлер',
    'Календарь',
    'Карта',
    'Глобус',
    'Мел',
    'Доска',
    'Пенал',
    'Конверт',
    'Марка',
    'Печать',
    'Машина',
    'Автобус',
    'Трамвай',
    'Троллейбус',
    'Поезд',
    'Метро',
    'Самолет',
    'Вертолет',
    'Корабль',
    'Лодка',
    'Велосипед',
    'Самокат',
    'Мотоцикл',
    'Колесо',
    'Руль',
    'Фара',
    'Дорога',
    'Тротуар',
    'Светофор',
    'Мост',
    'Здание',
    'Магазин',
    'Аптека',
    'Школа',
    'Больница',
    'Парк',
    'Лавочка',
    'Фонтан',
    'Фонарь',
    'Урна',
    'Дерево',
    'Цветок',
    'Трава',
    'Лист',
    'Корень',
    'Ветка',
    'Камень',
    'Песок',
    'Земля',
    'Вода',
    'Река',
    'Озеро',
    'Море',
    'Гора',
    'Лес',
    'Небо',
    'Облако',
    'Солнце',
    'Луна',
    'Звезда',
    'Собака',
    'Кошка',
    'Птица',
    'Рыба',
    'Насекомое',
    'Лошадь',
    'Корова',
    'Медведь',
    'Волк',
    'Заяц',
    'Мыло',
    'Шампунь',
    'Щетка',
    'Паста',
    'Полотенце',
    'Мочалка',
    'Расческа',
    'Бритва',
    'Ванна',
    'Душ',
    'Раковина',
    'Унитаз',
    'Кран',
    'Стиральный порошок',
    'Туалетная бумага',
    'Крем',
    'Духи',
    'Косметичка',
    'Халат',
    'Таз',
    'Молоток',
    'Отвертка',
    'Пила',
    'Топор',
    'Гвоздь',
    'Винт',
    'Клещи',
    'Гаечный ключ',
    'Дрель',
    'Рулетка',
    'Лопата',
    'Грабли',
    'Ведро',
    'Леска',
    'Ткань',
    'Нитки',
    'Иголка',
    'Верёвка',
    'Проволока',
    'Стекло',
    'Мяч',
    'Ракетка',
    'Сетка',
    'Коньки',
    'Лыжи',
    'Гантели',
    'Коврик',
    'Скакалка',
    'Шлем',
    'Палатка',
    'Спальник',
    'Рюкзак',
    'Гитара',
    'Пианино',
    'Флейта',
    'Карта',
    'Шахматы',
    'Кубик',
    'Кукла',
    'Машинка',
    'Таблетка',
    'Пластырь',
    'Бинт',
    'Вата',
    'Шприц',
    'Термометр',
    'Маска',
    'Очки',
    'Витамины',
    'Микстура',
    'Скальпель',
    'Жгут',
    'Грелка',
    'Йод',
    'Пипетка',
    'Шина',
    'Зонд',
    'Ланцет',
    'Полис',
    'Рецепт',
    'Деньги',
    'Монета',
    'Билет',
    'Паспорт',
    'Газета',
    'Журнал',
    'Письмо',
    'Коробка',
    'Пакет',
    'Корзина',
    'Чемодан',
    'Флаг',
    'Подарок',
    'Свеча',
    'Спички',
    'Зажигалка',
    'Фонарик',
    'Батарея',
    'Пепельница',
    'Кошелёк',
    'Крючок',
    'Цепь',
    'Магнит',
    'Песочные часы',
    'Компас',
    'Труба',
    'Шнурок',
    'Пуговица',
    'Медаль',
    'Статуя',
    'Якорь',
    'Штурвал',
    'Парус',
    'Ракушка',
    'Перо',
    'Свисток',
    'Клюшка',
    'Шайба',
    'Обруч',
    'Конус',
    'Глобус',
    'Радар',
    'Телескоп',
    'Микроскоп',
    'Лупа',
    'Весы',
    'Гиря',
    'Свинья-копилка',
    'Фарфор',
    'Хрусталь',
    'Черепица',
    'Кирпич',
    'Бетон',
    'Шифер',
    'Доска',
    'Бревно',
    'Пень',
    'Шишка',
    'Желудь',
    'Орех',
    'Гриб',
    'Ягода',
    'Колос',
    'Сено',
    'Солома',
    'Улей',
    'Мёд',
    'Воск',
    'Глина',
    'Уголь',
    'гойда'
  ];
  List<String> _data = [];
  int _currentChunkIndex = 0;

  /// Максимальный индекс чанка, до которого пользователь дошёл в этой сессии запоминания.
  int _furthestChunkIndexReached = 0;
  bool _isSettingsMode = true;
  bool _isMemorizing = false;
  bool _isInputMode = false;
  bool _isChecking = false;
  bool _isPreparingImages = false;
  final FocusNode _trainerKeyboardFocusNode = FocusNode();
  final ScrollController _memorizerScrollController = ScrollController();
  _NumbersSubMode _numbersSubMode = _NumbersSubMode.standard;

  bool get _isMatrixMode => _numbersSubMode == _NumbersSubMode.matrix;
  bool get _isPiMode => _numbersSubMode == _NumbersSubMode.pi;

  /// Карты: true = перемешанная колода без повторов (до 52).
  bool _cardsShuffledDeckMode = false;
  bool _pulseElementStatsButton = false;
  bool _historySavedForCurrentRun = false;
  bool _isHistoryReplay = false;

  /// Training opened from an Academy lesson (embedded trainer) — no XP.
  bool get _isAcademyLessonRun =>
      widget.academyElementCount != null ||
      widget.academyStandardDigitsLevel != null ||
      widget.academyUseMemorizationTimer != null ||
      widget.academyFlashSecondsPerItem != null ||
      widget.academyChunkSize != null;

  bool get _isDuelRun =>
      widget.trainerMode == TrainerMode.duel && widget.duelRoomId != null;

  DuelTrainerController? _duelController;
  DuelDiscipline? _duelDiscipline;
  bool _duelItemsReady = false;
  bool _duelSubmitted = false;
  bool _duelNavigatedToResults = false;
  int _duelCountdownLeft = 3;
  DuelTrainerPhase _duelPhase = DuelTrainerPhase.loading;
  DuelPlayerPhase? _lastSyncedDuelFirestorePhase;
  int _duelRecallCapSec = 0;
  int _duelRecallDeadlineMs = 0;
  int _preloadedImageCount = 0;
  int _totalImagesToPreload = 0;
  int _activeImageSlot = 1;
  int _selectedImageIndex = -1;
  int _currentPage = 0;
  final int _slotPage = 0;

  List<TextEditingController> _controllers = [];
  List<FocusNode> _focusNodes = [];
  List<int> _shuffledImageIndices = [];
  List<int> _shuffledFaceIndices = [];
  List<int?> _imageAnswerOrder = [];
  List<ImageProvider> _imageProviders = [];

  Timer? _mainTimer;
  Timer? _autoPlayTimer;
  Timer? _counterHoldTimer;
  int _memorizationTime = 0;
  int _recallTime = 0;
  final Stopwatch _memorizationStopwatch = Stopwatch();
  final Stopwatch _recallStopwatch = Stopwatch();
  int _memorizationElapsedMs = 0;
  int _recallElapsedMs = 0;
  List<int> _memorizationMsByElement = [];
  int _chunkStartedAtMs = 0;
  Timer? _elementStatsPulseTimer;
  String _resultComparisonLine = '';
  String _streakLine = '';
  int _xpEarnedLast = 0;
  bool _perfectMemLast = false;
  String _selectedFaceNamePool = 'ENGNAME';
  AppLanguage _selectedWordsLanguage = AppLanguage.ru;
  final Map<AppLanguage, int> _wordsCountByLanguage = {};
  int _faceCatalogSize = 0;

  TrainerLevelDef? _activeLevelChallenge;
  LevelCompletionReward? _pendingLevelReward;
  bool _showLevelCompletion = false;
  bool _returnToLevelsPathAfterSession = false;

  /// While finalizing a level run, defer the results screen until the reward overlay.
  bool _isSessionFinalizing = false;

  /// Numbers level: goal is digit count — one item per digit in session data.
  bool _levelDigitGoalMode = false;

  bool get _deferResultsForActiveLevel =>
      _activeLevelChallenge != null && _canUseTrainerLevels;

  bool get _canUseTrainerLevels =>
      !_isDuelRun && !_isAcademyLessonRun && !_isHistoryReplay;

  LevelPath? get _currentLevelPath =>
      LevelDefinitions.pathForTrainingMode(_selectedMode);

  LevelTrainerSettingsSnapshot _buildLevelTrainerSettingsSnapshot() {
    return LevelTrainerSettingsSnapshot(
      mode: _selectedMode,
      standardDigits: _standardDigits,
      isMatrixMode: _isMatrixMode,
      chunkSize: int.tryParse(_chunkSizeController.text) ?? 1,
      lociRouteIndex: _selectedTrainingLociRoute,
      hasLoci: _selectedTrainingLociRoute >= 0 &&
          _selectedTrainingLociRoute < _trainingLociRoutes.length,
      sessionMemCapSec: _sessionMemCapSec,
      useMemorizationTimer: _useMemorizationTimer,
      flashSeconds: double.tryParse(_flashSecondsController.text) ?? 2.0,
      cardsShuffledDeck: _cardsShuffledDeckMode,
      faceNamePool: _selectedFaceNamePool,
    );
  }

  void _applyLevelTrainerSettingsSnapshot(LevelTrainerSettingsSnapshot s) {
    _standardDigits = s.standardDigits.clamp(1, 3);
    _numbersSubMode = s.isMatrixMode
        ? _NumbersSubMode.matrix
        : _NumbersSubMode.standard;
    _chunkSizeController.text = '${s.chunkSize}';
    _selectedTrainingLociRoute = s.hasLoci && _trainingLociRoutes.isNotEmpty
        ? s.lociRouteIndex.clamp(0, _trainingLociRoutes.length - 1)
        : -1;
    _flashSecondsController.text = s.flashSeconds.toStringAsFixed(1);
    _cardsShuffledDeckMode = s.cardsShuffledDeck;
    _selectedFaceNamePool = s.faceNamePool;
    unawaited(_persistCardsDeckModePref());
    unawaited(_persistSessionMemCapPref());
    _normalizeCounter(_chunkSizeController, isChunk: true, persist: false);
  }

  int get _effectiveStandardDigits => _levelDigitGoalMode &&
          _selectedMode == TrainingMode.standard &&
          !_isMatrixMode
      ? 1
      : _standardDigits;

  void _applyLevelChallenge(TrainerLevelDef level) {
    _activeLevelChallenge = level;
    _returnToLevelsPathAfterSession = true;
    _levelDigitGoalMode = level.countsAsDigits && !_isMatrixMode;
    final countForTrainer =
        _levelDigitGoalMode ? level.elementCount : level.elementCount;
    _totalCountController.text = '$countForTrainer';
    final levelMemCap = level.memTimeLimitSec ?? 0;
    _sessionMemCapSec = levelMemCap > 0 ? levelMemCap : 0;
    _useMemorizationTimer = false;
    if (levelMemCap > 0) {
      unawaited(_persistSessionMemCapPref());
    }
    _normalizeCounter(_totalCountController, isChunk: false, persist: false);
    if (mounted) setState(() {});
  }

  Future<void> _openLevelsPath() async {
    final path = _currentLevelPath;
    if (path == null || !_canUseTrainerLevels) return;
    uiTapClick(UiClickSound.soft);
    final lociLabels = _trainingLociRoutes.map((r) => r.name).toList();
    final result = await Navigator.of(context).push<LevelStartResult>(
      PageRouteBuilder<LevelStartResult>(
        fullscreenDialog: true,
        opaque: true,
        pageBuilder: (_, __, ___) => LevelsPathScreen(
          path: path,
          initialSettings: _buildLevelTrainerSettingsSnapshot(),
          lociRouteLabels: lociLabels,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 260),
      ),
    );
    if (result != null && mounted) {
      _applyLevelTrainerSettingsSnapshot(result.settings);
      _applyLevelChallenge(result.level);
      await _generateData();
    }
  }

  void _returnToTrainerLobby({bool openLevelsPath = false}) {
    _autoPlayTimer?.cancel();
    if (_recallStopwatch.isRunning) {
      _recallStopwatch.stop();
    }
    if (mounted) {
      setState(() {
        _isSettingsMode = true;
        _isMemorizing = false;
        _isInputMode = false;
        _isChecking = false;
        _isSessionFinalizing = false;
        _showLevelCompletion = false;
        _pendingLevelReward = null;
        _currentChunkIndex = 0;
      });
    }
    final shouldOpenLevels = openLevelsPath && _returnToLevelsPathAfterSession;
    _returnToLevelsPathAfterSession = false;
    if (shouldOpenLevels && _canUseTrainerLevels) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_openLevelsPath());
      });
    }
  }

  void _exitResultsScreen() {
    if (widget.historyEntry != null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    _returnToTrainerLobby(openLevelsPath: _returnToLevelsPathAfterSession);
  }

  Future<void> _evaluateLevelChallengeAfterSession({
    required double percentage,
    required int memMs,
  }) async {
    final level = _activeLevelChallenge;
    if (level == null || !_canUseTrainerLevels) return;

    final passedAccuracy = percentage >= level.requiredAccuracy;
    final timeLimitMs = (level.memTimeLimitSec ?? 0) * 1000;
    final passedTime = timeLimitMs <= 0 || memMs <= timeLimitMs;
    final passed = passedAccuracy && passedTime;

    if (passed) {
      uiPlayLevelSuccess();
      await LevelProgressService.instance.markCompleted(level.id);
      final streak = ProgressService.instance.progress.value.streak;
      final speedBonus = level.isSpeedChallenge && passedTime;
      final bonusXp = 120;
      await ProgressService.instance.addXP(bonusXp, countForStreak: false);
      if (mounted) {
        setState(() {
          _pendingLevelReward = LevelCompletionReward(
            xpGained: _xpEarnedLast + bonusXp,
            accuracyPct: percentage,
            speedBonus: speedBonus,
            streakDays: streak,
            levelNumber: level.displayNumber,
            pathLabel: pathTitle(level.path),
          );
          _showLevelCompletion = true;
        });
      }
    } else {
      if (!passedAccuracy) {
        uiPlayLevelFail();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _lociText(
              ru: 'Уровень не пройден · нужно ${level.requiredAccuracy.toStringAsFixed(0)}%',
              en: 'Level not passed · need ${level.requiredAccuracy.toStringAsFixed(0)}%',
              de: 'Stufe nicht bestanden · ${level.requiredAccuracy.toStringAsFixed(0)}% nötig',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _completeSessionCheck() async {
    if (!mounted) return;
    final deferResults = _deferResultsForActiveLevel;
    setState(() {
      if (deferResults) {
        _isSessionFinalizing = true;
      } else {
        _isChecking = true;
      }
    });
    try {
      await _finalizeAndPersistResults();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppTexts.get('cloud_save_failed'))),
        );
      }
    } finally {
      if (!mounted) return;
      if (deferResults) {
        setState(() {
          _isSessionFinalizing = false;
          if (!_showLevelCompletion) {
            _isChecking = true;
          }
        });
      }
    }
  }

  void _syncDuelFirestorePhase(DuelPlayerPhase phase) {
    if (!_isDuelRun || widget.duelRoomId == null) return;
    if (_lastSyncedDuelFirestorePhase == phase) return;
    _lastSyncedDuelFirestorePhase = phase;
    unawaited(
      DuelService.instance
          .setPlayerPhase(roomId: widget.duelRoomId!, phase: phase),
    );
  }

  DuelPlayerPhase _firestorePhaseFromTrainer(DuelTrainerPhase phase) {
    switch (phase) {
      case DuelTrainerPhase.countdown:
        return DuelPlayerPhase.countdown;
      case DuelTrainerPhase.memorize:
        return DuelPlayerPhase.memorizing;
      case DuelTrainerPhase.recall:
        return DuelPlayerPhase.recalling;
      case DuelTrainerPhase.submitted:
      case DuelTrainerPhase.finished:
        return DuelPlayerPhase.finished;
      default:
        return DuelPlayerPhase.waiting;
    }
  }

  @override
  void dispose() {
    leaveTrainingSession();
    if (_isDuelRun && widget.duelRoomId != null && !_duelSubmitted) {
      unawaited(
        DuelService.instance.setPlayerPhase(
          roomId: widget.duelRoomId!,
          phase: DuelPlayerPhase.disconnected,
        ),
      );
    }
    _duelController?.dispose();
    _mainTimer?.cancel();
    _autoPlayTimer?.cancel();
    _elementStatsPulseTimer?.cancel();
    _totalCountController.dispose();
    _chunkSizeController.dispose();
    _flashSecondsController.dispose();
    _slotController.dispose();
    _counterHoldTimer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    _trainerKeyboardFocusNode.dispose();
    _memorizerScrollController.dispose();
    super.dispose();
  }

  String _encodeFaceEntry(String name, String imageUrl,
      {String imageData = ''}) {
    return jsonEncode(
        {'name': name, 'imageUrl': imageUrl, 'imageData': imageData});
  }

  ({String name, String imageUrl, String imageData}) _decodeFaceEntry(
      String raw) {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final name = (m['name'] as String?)?.trim() ?? '';
      final imageUrl = (m['imageUrl'] as String?)?.trim() ?? '';
      final imageData = (m['imageData'] as String?)?.trim() ?? '';
      return (name: name, imageUrl: imageUrl, imageData: imageData);
    } catch (_) {
      return (name: '', imageUrl: '', imageData: '');
    }
  }

  Future<String> _downloadFaceImageAsBase64(String imageUrl) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final uri = Uri.parse(imageUrl);
        final data = await NetworkAssetBundle(uri).load(uri.toString());
        final bytes = data.buffer.asUint8List();
        if (bytes.isNotEmpty) return base64Encode(bytes);
      } catch (_) {
        if (attempt < 2) {
          await Future.delayed(Duration(milliseconds: 120 + (attempt * 180)));
        }
      }
    }
    return '';
  }

  String _faceFingerprint(String imageData) {
    if (imageData.isEmpty) return '';
    if (imageData.length <= 900) return imageData;
    final first = imageData.substring(0, 300);
    final middleStart = (imageData.length ~/ 2) - 150;
    final middle = imageData.substring(middleStart, middleStart + 300);
    final last = imageData.substring(imageData.length - 300);
    return '$first|$middle|$last|${imageData.length}';
  }

  ImageProvider _faceImageProvider(
      ({String name, String imageUrl, String imageData}) person) {
    return faceEntryImageProvider(
      imageUrl: person.imageUrl,
      imageData: person.imageData,
    );
  }

  ImageProvider _faceImageProviderAt(int index) {
    if (index >= 0 && index < _imageProviders.length) {
      return _imageProviders[index];
    }
    if (index >= 0 && index < _data.length) {
      return _faceImageProvider(_decodeFaceEntry(_data[index]));
    }
    return ResizeImage(
      MemoryImage(base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO7Zk4sAAAAASUVORK5CYII=')),
      width: 700,
    );
  }

  String _normalizePersonName(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  List<String> _parseFaceNames(String raw) {
    String cleanSingleName(String value) {
      final parts = value.trim().split(RegExp(r'\s+'));
      final firstToken = parts.isEmpty ? '' : parts.first;
      final cleaned =
          firstToken.replaceAll(RegExp(r"[^A-Za-zА-Яа-яЁёÄÖÜäöüẞß'\-]"), '');
      return cleaned.trim();
    }

    return raw
        .split(RegExp(r'[\r\n,;]+'))
        .map(cleanSingleName)
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..shuffle();
  }

  String _faceNameAssetPath() {
    switch (_selectedFaceNamePool) {
      case 'GERNAME':
        return 'assets/facenames/gername.txt';
      case 'RUNAME':
        return 'assets/facenames/runame.txt';
      case 'RUINTERNATIONAL':
        return 'assets/facenames/ruinternational name.txt';
      case 'ENGNAME':
      default:
        return 'assets/facenames/engname.txt';
    }
  }

  Future<List<String>> _loadFaceNamesForCurrentSelection() async {
    try {
      final raw = await rootBundle.loadString(_faceNameAssetPath());
      return _parseFaceNames(raw);
    } catch (_) {
      return const [];
    }
  }

  String _facePoolLabel() {
    switch (_selectedFaceNamePool) {
      case 'GERNAME':
        return 'German names';
      case 'RUNAME':
        return 'Russian names';
      case 'RUINTERNATIONAL':
        return 'RU International';
      case 'ENGNAME':
      default:
        return 'English names';
    }
  }

  bool get _duelBothFinished {
    final room = _duelController?.room;
    return room != null && room.results.length >= 2;
  }

  void _onDuelRoomUpdate(DuelRoom? room) {
    if (!mounted) return;
    if (_duelController?.phase == DuelTrainerPhase.countdown) {
      _duelCountdownLeft = _duelController!.countdownLeft;
    }
    if (room?.status == DuelStatus.finished) {
      _duelPhase = DuelTrainerPhase.finished;
      if (_duelBothFinished) {
        _navigateToDuelResults();
      }
    }
    setState(() {});
    if (room == null || room.task == null) return;
    if (!_duelItemsReady) {
      unawaited(_prepareDuelItems(room.task!));
    }
  }

  void _onDuelPhaseChanged(DuelTrainerPhase phase) {
    if (!mounted) return;
    setState(() {
      _duelPhase = phase;
      if (phase == DuelTrainerPhase.countdown) {
        _duelCountdownLeft = _duelController?.countdownLeft ?? 3;
      }
    });
    _syncDuelFirestorePhase(_firestorePhaseFromTrainer(phase));
    if (phase == DuelTrainerPhase.memorize &&
        _duelItemsReady &&
        !_isMemorizing &&
        !_isInputMode) {
      final task = _duelController?.room?.task;
      if (task != null && _data.isNotEmpty) {
        _startDuelMemorizationFromPreparedData(task);
      }
    }
  }

  Future<void> _prepareDuelItems(DuelTask task) async {
    List<String> resolved;
    if (task.discipline.sharedContent) {
      resolved = List<String>.from(task.items);
    } else {
      resolved = await generateLocalDuelItems(
        discipline: task.discipline,
        count: task.count,
      );
    }
    if (!mounted) return;
    final preset = duelPresetFromDiscipline(task.discipline);
    _duelDiscipline = task.discipline;
    _selectedMode = preset.mode;
    _numbersSubMode = preset.matrixMode
        ? _NumbersSubMode.matrix
        : _NumbersSubMode.standard;
    _standardDigits = preset.standardDigits;
    _totalCountController.text = '${resolved.length}';
    final chunk = (widget.duelInitialChunkSize ?? 1)
        .clamp(1, duelTrainerMaxChunkOnScreen(task.discipline));
    _chunkSizeController.text = '$chunk';
    _useMemorizationTimer = false;
    if (task.memorizeSeconds > 0) {
      _sessionMemCapSec = task.memorizeSeconds;
      _activeSessionMemCapSec = task.memorizeSeconds;
    } else {
      _sessionMemCapSec = 0;
      _activeSessionMemCapSec = 0;
    }
    _data = _normalizeDuelFaceItems(resolved, task.discipline);
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _controllers = List.generate(_data.length, (_) => TextEditingController());
    _focusNodes = List.generate(_data.length, (_) => FocusNode());
    _imageAnswerOrder = List<int?>.filled(_data.length, null);
    final rand = Random();
    _shuffledImageIndices = List.generate(_data.length, (i) => i)
      ..shuffle(rand);
    _shuffledFaceIndices = List.generate(_data.length, (i) => i)..shuffle(rand);
    _imageProviders = [];
    if (_selectedMode == TrainingMode.images) {
      setState(() {
        _duelItemsReady = true;
        _isPreparingImages = true;
      });
      await _preloadImagesForDuel();
    } else if (_selectedMode == TrainingMode.faces) {
      setState(() {
        _duelItemsReady = true;
        _isPreparingImages = true;
      });
      await _preloadFacesForDuel();
    } else {
      setState(() => _duelItemsReady = true);
    }
  }

  List<String> _normalizeDuelFaceItems(
      List<String> items, DuelDiscipline discipline) {
    if (discipline != DuelDiscipline.faces) return items;
    return items.map((raw) {
      if (raw.startsWith('{')) return raw;
      final face = decodeFaceItem(raw);
      return _encodeFaceEntry(face.name, face.url);
    }).toList(growable: false);
  }

  Future<void> _preloadImagesForDuel() async {
    _preloadedImageCount = 0;
    _totalImagesToPreload = _data.length;
    _imageProviders =
        List<ImageProvider>.filled(_data.length, const AssetImage(''));
    for (int i = 0; i < _data.length; i++) {
      if (!mounted) return;
      try {
        final p = NetworkImage(_data[i]);
        await precacheImage(p, context);
        _imageProviders[i] = ResizeImage(p, width: 700);
      } catch (_) {}
      setState(() => _preloadedImageCount = i + 1);
    }
    if (mounted) {
      setState(() => _isPreparingImages = false);
    }
  }

  Future<void> _preloadFacesForDuel() async {
    _preloadedImageCount = 0;
    _totalImagesToPreload = _data.length;
    _imageProviders =
        List<ImageProvider>.filled(_data.length, const AssetImage(''));
    for (int i = 0; i < _data.length; i++) {
      if (!mounted) return;
      final person = _decodeFaceEntry(_data[i]);
      try {
        final p = _faceImageProvider(person);
        await precacheImage(p, context);
        _imageProviders[i] = p;
      } catch (_) {}
      setState(() => _preloadedImageCount = i + 1);
    }
    if (mounted) {
      setState(() => _isPreparingImages = false);
    }
  }

  void _startDuelMemorizationFromPreparedData(DuelTask task) {
    if (_isMemorizing || _isInputMode) return;
    _memorizationTime = 0;
    _recallTime = 0;
    _memorizationElapsedMs = 0;
    _recallElapsedMs = 0;
    _memorizationMsByElement = List<int>.filled(_data.length, 0);
    _chunkStartedAtMs = 0;
    _historySavedForCurrentRun = false;
    _currentChunkIndex = 0;
    _furthestChunkIndexReached = 0;
    _memorizationStopwatch.reset();
    _recallStopwatch.reset();
    _mainTimer?.cancel();
    _activeSessionMemCapSec =
        task.memorizeSeconds > 0 ? task.memorizeSeconds : 0;
    _mainTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_isMemorizing) {
        if (_isDuelRun && task.memorizeSeconds > 0) {
          final leftMs = _duelController?.memorizeLeftMs ?? 0;
          setState(() => _memorizationTime = (leftMs / 1000).ceil());
        } else {
          setState(() => _memorizationTime++);
        }
        if (_activeSessionMemCapSec > 0 &&
            !_isDuelRun &&
            _memorizationTime >= _activeSessionMemCapSec) {
          _onSessionMemorizationExpired();
        }
      } else if (_isInputMode && !_isChecking) {
        _tickDuelRecallCountdown();
      }
    });
    _memorizationStopwatch.start();
    setState(() {
      _isSettingsMode = false;
      _isMemorizing = true;
      _isInputMode = false;
      _isChecking = false;
    });
    _syncDuelFirestorePhase(DuelPlayerPhase.memorizing);
  }

  void _beginDuelRecallCountdown() {
    final task = _duelController?.room?.task;
    final capSec = duelRecallCapSecondsForCount(_data.length);
    _duelRecallCapSec = capSec;
    final syncedRecall = task != null && task.memorizeSeconds > 0;
    if (syncedRecall) {
      _duelRecallDeadlineMs = 0;
      final leftMs = _duelController?.recallLeftMs ?? capSec * 1000;
      _recallTime = (leftMs / 1000).ceil().clamp(0, capSec);
    } else {
      _duelRecallDeadlineMs =
          DateTime.now().millisecondsSinceEpoch + capSec * 1000;
      _recallTime = capSec;
    }
  }

  void _tickDuelRecallCountdown() {
    if (!_isDuelRun || _duelRecallCapSec <= 0) {
      setState(() => _recallTime++);
      return;
    }
    final capSec = _duelRecallCapSec;
    final task = _duelController?.room?.task;
    final syncedRecall = task != null && task.memorizeSeconds > 0;
    int leftSec;
    if (syncedRecall) {
      final leftMs = _duelController?.recallLeftMs ?? 0;
      leftSec = (leftMs / 1000).ceil().clamp(0, capSec);
      if (leftMs <= 0) {
        unawaited(_onDuelRecallExpired());
      }
    } else {
      final leftMs =
          _duelRecallDeadlineMs - DateTime.now().millisecondsSinceEpoch;
      leftSec = (leftMs / 1000).ceil().clamp(0, capSec);
      if (leftMs <= 0) {
        unawaited(_onDuelRecallExpired());
      }
    }
    setState(() => _recallTime = leftSec);
  }

  Future<void> _onDuelRecallExpired() async {
    if (_duelSubmitted || !_isDuelRun) return;
    if (_isMemorizing) {
      _completeMemorizationToRecall(trimToSeenPrefix: true);
    }
    if (!_isInputMode && !_isChecking) return;
    uiTapClick(UiClickSound.bright);
    if (_recallStopwatch.isRunning) {
      _recallStopwatch.stop();
      _recallElapsedMs = _recallStopwatch.elapsedMilliseconds;
    }
    await _finalizeAndPersistResults();
  }

  void _navigateToDuelResults() {
    if (_duelNavigatedToResults || !mounted) return;
    _duelNavigatedToResults = true;
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (context, anim, _) => DuelResultScreen(
            roomId: widget.duelRoomId!,
            items: _data,
          ),
          transitionsBuilder: (context, anim, _, c) =>
              FadeTransition(opacity: anim, child: c),
          transitionDuration: const Duration(milliseconds: 320),
        ),
      );
    });
  }

  Future<void> _submitDuelResults() async {
    if (_duelSubmitted) return;
    final room = _duelController?.room;
    final task = room?.task;
    final discipline = _duelDiscipline;
    if (room == null || task == null || discipline == null) return;
    final uid = CloudSyncService.instance.user.value?.uid;
    if (uid == null) return;

    final answers = <String>[];
    if (_selectedMode == TrainingMode.images) {
      for (int i = 0; i < _data.length; i++) {
        answers.add(_imageAnswerOrder[i]?.toString() ?? '');
      }
    } else {
      for (int i = 0; i < _data.length; i++) {
        answers.add(i < _controllers.length ? _controllers[i].text : '');
      }
    }

    int correct = 0;
    for (int i = 0; i < _data.length; i++) {
      final user = i < answers.length ? answers[i] : '';
      final expected =
          discipline == DuelDiscipline.images ? (i + 1).toString() : _data[i];
      if (answerMatches(discipline, expected, user)) correct++;
    }

    final recallMs = _recallElapsedMs > 0
        ? _recallElapsedMs
        : _recallStopwatch.elapsedMilliseconds;
    final memorizeMs = _memorizationElapsedMs > 0
        ? _memorizationElapsedMs
        : _memorizationStopwatch.elapsedMilliseconds;

    _duelSubmitted = true;
    _duelController?.markSubmitted();

    final result = DuelResult(
      uid: uid,
      correct: correct,
      total: _data.length,
      timeMs: recallMs,
      memorizeMs: memorizeMs,
      submittedAtMs: DateTime.now().millisecondsSinceEpoch,
      answers: answers,
    );

    try {
      await DuelService.instance
          .submitResult(roomId: widget.duelRoomId!, result: result);
    } catch (_) {}

    await _saveDuelTrainingHistory(task: task, result: result);
    if (mounted) setState(() {});
  }

  Future<void> _saveDuelTrainingHistory({
    required DuelTask task,
    required DuelResult result,
  }) async {
    try {
      final discipline = task.discipline;
      final correctnessPattern = <int>[];
      for (int i = 0; i < _data.length; i++) {
        final user = i < result.answers.length ? result.answers[i] : '';
        final expected =
            discipline == DuelDiscipline.images ? (i + 1).toString() : _data[i];
        correctnessPattern.add(
          answerMatches(discipline, expected, user) ? 1 : 0,
        );
      }
      final entry = TrainingHistoryEntry(
        id: 'duel_${widget.duelRoomId}_${result.uid}_${result.submittedAtMs}',
        mode: discipline.historyMode,
        date: DateTime.fromMillisecondsSinceEpoch(result.submittedAtMs),
        totalItems: _data.length,
        correctItems: result.correct,
        memorizationMs: result.memorizeMs,
        recallMs: result.timeMs,
        xpEarned: 0,
        data: List<String>.from(_data),
        answers: List<String>.from(result.answers),
        imageAnswerOrder: List<int?>.from(_imageAnswerOrder),
        memorizationMsByElement: List<int>.filled(
          _data.length,
          _data.isEmpty ? 0 : (result.memorizeMs / _data.length).round(),
        ),
        correctnessPattern: correctnessPattern,
        lociBindings: const <String>[],
      );
      await TrainingHistoryService.instance.record(entry);
      unawaited(CloudSyncService.instance.uploadTrainingHistoryEntry(entry));
    } catch (_) {}
  }

  Future<void> _generateData() async {
    if (_isDuelRun) return;
    uiTapClick(UiClickSound.soft);
    int total = _safeTotalCountForMode(
      _selectedMode,
      int.tryParse(_totalCountController.text),
    );
    total = max(1, total);
    final random = Random();

    if (_selectedMode == TrainingMode.standard) {
      if (_isMatrixMode) {
        _data = List.generate(total, (_) => random.nextInt(10).toString());
      } else if (_levelDigitGoalMode) {
        _data = List.generate(
          total,
          (_) => random.nextInt(10).toString(),
        );
      } else {
        final maxExclusive =
            _standardDigits == 1 ? 10 : (_standardDigits == 2 ? 100 : 1000);
        _data = List.generate(
          total,
          (_) => random
              .nextInt(maxExclusive)
              .toString()
              .padLeft(_standardDigits, '0'),
        );
      }
    } else if (_selectedMode == TrainingMode.binary) {
      _data = List.generate(
          total, (_) => List.generate(3, (index) => random.nextInt(2)).join());
    } else if (_selectedMode == TrainingMode.words) {
      final words = await loadWordsForLanguage(
        _selectedWordsLanguage,
        fallback: _fallbackDictionary,
      );
      if (words.isNotEmpty && total > words.length) {
        total = words.length;
        _totalCountController.text = total.toString();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_lociText(
                ru: 'В словаре ${words.length} слов — без повторов в сессии',
                en: 'Dictionary has ${words.length} words — no repeats per session',
                de: 'Wörterbuch: ${words.length} Wörter — keine Wiederholungen',
              )),
            ),
          );
        }
      }
      _data = await pickWordsForTraining(
        count: total,
        language: _selectedWordsLanguage,
        fallback: _fallbackDictionary,
        random: random,
      );
    } else if (_selectedMode == TrainingMode.cards) {
      if (_cardsShuffledDeckMode && total > kPlayingCardDeckSize) {
        total = kPlayingCardDeckSize;
        _totalCountController.text = total.toString();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppTexts.get('cards_deck_max_count'))),
          );
        }
      }
      _data = generateCardsTrainingSequence(
        count: total,
        random: random,
        shuffledDeckNoRepeats: _cardsShuffledDeckMode,
      );
    } else if (_selectedMode == TrainingMode.faces) {
      await FaceCatalogService.instance.ensureLoaded();
      if (!FaceCatalogService.instance.isReady) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Каталог лиц не найден в сборке приложения.'),
            ),
          );
        }
        return;
      }
      final catalogSize = FaceCatalogService.instance.entries.length;
      if (total > catalogSize) {
        total = catalogSize;
        _totalCountController.text = total.toString();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppTexts.get('faces_names_not_enough', params: {
                'count': total.toString(),
              })),
            ),
          );
        }
      }
      final picked = await FaceCatalogService.instance.pickFaces(
        count: total,
        namePoolKey: _selectedFaceNamePool,
        random: random,
      );
      if (picked.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppTexts.get('faces_names_file_empty'))),
          );
        }
        return;
      }
      total = picked.length;
      _data = picked
          .map((face) => _encodeFaceEntry(face.name, face.assetPath))
          .toList(growable: false);
      _chunkSizeController.text = '1';
      _imageProviders =
          _data.map(_decodeFaceEntry).map(_faceImageProvider).toList();
    } else {
      if (total > _kTrainingImagePoolSize) {
        total = _kTrainingImagePoolSize;
        _totalCountController.text = total.toString();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_lociText(
                ru: 'До $_kTrainingImagePoolSize уникальных картинок без повторов',
                en: 'Up to $_kTrainingImagePoolSize unique images without repeats',
                de: 'Bis $_kTrainingImagePoolSize einzigartige Bilder ohne Wiederholungen',
              )),
            ),
          );
        }
      }
      _data = await pickImageUrlsForTraining(count: total, random: random);
      _imageProviders = _data
          .map((url) => ResizeImage(NetworkImage(url), width: 700))
          .toList();
    }

    _controllers = List.generate(total, (_) => TextEditingController());
    _focusNodes = List.generate(total, (_) => FocusNode());
    _rebuildAttachedLoci();
    _imageAnswerOrder = List<int?>.filled(total, null);
    _shuffledImageIndices = List.generate(total, (i) => i)..shuffle(random);
    _shuffledFaceIndices = List.generate(total, (i) => i)..shuffle(random);

    if (_selectedMode == TrainingMode.images ||
        _selectedMode == TrainingMode.faces) {
      final preloadTarget = _data.length;
      setState(() {
        _isPreparingImages = true;
        _preloadedImageCount = 0;
        _totalImagesToPreload = preloadTarget;
      });
      for (int idx = 0; idx < preloadTarget; idx++) {
        final url = _selectedMode == TrainingMode.faces
            ? _decodeFaceEntry(_data[idx]).imageUrl
            : _data[idx];
        try {
          final provider = idx >= 0 && idx < _imageProviders.length
              ? _imageProviders[idx]
              : (_selectedMode == TrainingMode.faces
                  ? _faceImageProvider(_decodeFaceEntry(_data[idx]))
                  : NetworkImage(url));
          await precacheImage(provider, context);
        } catch (_) {
          try {
            final provider = idx >= 0 && idx < _imageProviders.length
                ? _imageProviders[idx]
                : (_selectedMode == TrainingMode.faces
                    ? _faceImageProvider(_decodeFaceEntry(_data[idx]))
                    : NetworkImage(url));
            await Future.delayed(const Duration(milliseconds: 200));
            await precacheImage(provider, context);
          } catch (_) {
            // Игнорируем единичные сетевые ошибки, чтобы тренировка все равно запустилась.
          }
        } finally {
          if (mounted) {
            setState(() => _preloadedImageCount++);
          }
        }
      }
      if (mounted) {
        setState(() => _isPreparingImages = false);
      }
    }

    _memorizationTime = 0;
    _recallTime = 0;
    _memorizationElapsedMs = 0;
    _recallElapsedMs = 0;
    _memorizationMsByElement = List<int>.filled(_data.length, 0);
    _chunkStartedAtMs = 0;
    _historySavedForCurrentRun = false;
    _isHistoryReplay = false;
    _resultComparisonLine = '';
    _streakLine = '';
    _slotController.text = '1';
    _memorizationStopwatch.reset();
    _recallStopwatch.reset();

    _mainTimer?.cancel(); // Убедимся, что старый таймер отменен
    _activeSessionMemCapSec = _sessionMemCapSec.clamp(0, 7200);
    _mainTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_isMemorizing) {
        setState(() => _memorizationTime++);
        if (_activeSessionMemCapSec > 0 &&
            _memorizationTime >= _activeSessionMemCapSec) {
          _onSessionMemorizationExpired();
        }
      } else if (_isInputMode && !_isChecking && !_isSessionFinalizing) {
        setState(() => _recallTime++);
      }
    });

    _memorizationStopwatch.reset();
    _memorizationStopwatch.start();
    _chunkStartedAtMs = 0;
    setState(() {
      _isSettingsMode = false;
      _isMemorizing = true;
      _currentChunkIndex = 0;
      _furthestChunkIndexReached = 0;
      _isChecking = false;
      _isSessionFinalizing = false;
      _showLevelCompletion = false;
      _pendingLevelReward = null;
    });
    _handleAutoPlay();
  }

  void _handleAutoPlay() {
    if (_useMemorizationTimer && _isMemorizing) {
      final double flashSeconds =
          double.tryParse(_flashSecondsController.text) ?? 2.0;
      int chunkSize = int.tryParse(_chunkSizeController.text) ?? 1;
      if (_selectedMode == TrainingMode.faces) chunkSize = 1;

      // Рассчитываем время на весь чанк (количество элементов в чанке * время на 1 элемент)
      double totalChunkSeconds = chunkSize * flashSeconds;

      _autoPlayTimer?.cancel();
      _autoPlayTimer =
          Timer(Duration(milliseconds: (totalChunkSeconds * 1000).round()), () {
        if (_isMemorizing) _nextChunk();
      });
    }
  }

  int _currentEffectiveChunkSize() {
    int chunkSize = int.tryParse(_chunkSizeController.text) ?? 1;
    if (_selectedMode == TrainingMode.faces) chunkSize = 1;
    return max(1, chunkSize);
  }

  void _captureCurrentChunkMemorizationTime() {
    if (_data.isEmpty || !_memorizationStopwatch.isRunning) return;
    if (_memorizationMsByElement.length != _data.length) {
      _memorizationMsByElement = List<int>.filled(_data.length, 0);
    }

    final nowMs = _memorizationStopwatch.elapsedMilliseconds;
    final deltaMs = max(0, nowMs - _chunkStartedAtMs);
    if (deltaMs <= 0) {
      _chunkStartedAtMs = nowMs;
      return;
    }

    final chunkSize = _currentEffectiveChunkSize();
    final start = min(max(0, _currentChunkIndex * chunkSize), _data.length);
    final end = min(start + chunkSize, _data.length);
    final visibleCount = end - start;
    if (visibleCount <= 0) {
      _chunkStartedAtMs = nowMs;
      return;
    }

    final perElementMs = (deltaMs / visibleCount).round();
    for (int i = start; i < end; i++) {
      _memorizationMsByElement[i] += perElementMs;
    }
    _chunkStartedAtMs = nowMs;
  }

  void _finishMemorizationPhase() {
    _captureCurrentChunkMemorizationTime();
    _autoPlayTimer?.cancel();
    _memorizationStopwatch.stop();
    final rawMemMs = _memorizationStopwatch.elapsedMilliseconds;
    final capMs =
        _activeSessionMemCapSec > 0 ? _activeSessionMemCapSec * 1000 : 0;
    _memorizationElapsedMs = capMs > 0 ? min(rawMemMs, capMs) : rawMemMs;
    _recallStopwatch.reset();
    _recallStopwatch.start();
  }

  /// Оставляем только те элементы, которые пользователь уже успел увидеть в фазе запоминания
  /// (актуально при лимите времени или досрочном переходе к вводу).
  void _truncateSessionToMemorizedPrefix() {
    if (_data.isEmpty) return;
    final chunkSize = max(1, _currentEffectiveChunkSize());
    final furthestCi = max(_currentChunkIndex, _furthestChunkIndexReached);
    final visible = min(_data.length, (furthestCi + 1) * chunkSize);
    final n = visible.clamp(1, _data.length);
    if (n >= _data.length) return;

    for (var i = n; i < _controllers.length; i++) {
      _controllers[i].dispose();
    }
    for (var i = n; i < _focusNodes.length; i++) {
      _focusNodes[i].dispose();
    }

    final rand = Random();
    final maxCi = (n - 1) ~/ chunkSize;
    final newCi = min(_currentChunkIndex, maxCi);

    setState(() {
      _data = _data.sublist(0, n);
      _controllers = _controllers.sublist(0, n);
      _focusNodes = _focusNodes.sublist(0, n);
      if (_memorizationMsByElement.length >= n) {
        _memorizationMsByElement =
            List<int>.from(_memorizationMsByElement.sublist(0, n));
      } else {
        _memorizationMsByElement = [
          ..._memorizationMsByElement,
          ...List<int>.filled(n - _memorizationMsByElement.length, 0),
        ];
      }
      _imageAnswerOrder = List<int?>.filled(n, null);
      _shuffledImageIndices = List.generate(n, (i) => i)..shuffle(rand);
      _shuffledFaceIndices = List.generate(n, (i) => i)..shuffle(rand);
      if (_imageProviders.length > n) {
        _imageProviders =
            List<ImageProvider>.from(_imageProviders.sublist(0, n));
      }
      _currentChunkIndex = newCi;
      _rebuildAttachedLoci();
    });
  }

  void _completeMemorizationToRecall({bool trimToSeenPrefix = false}) {
    if (trimToSeenPrefix) {
      _truncateSessionToMemorizedPrefix();
    }
    _finishMemorizationPhase();
    if (_isDuelRun) {
      _beginDuelRecallCountdown();
      _syncDuelFirestorePhase(DuelPlayerPhase.recalling);
    }
    setState(() {
      _isMemorizing = false;
      _isInputMode = true;
      if (_selectedMode == TrainingMode.images) {
        _shuffledImageIndices.shuffle();
        _imageAnswerOrder = List<int?>.filled(_data.length, null);
        _activeImageSlot = 1;
        _slotController.text = '1';
        _selectedImageIndex = -1;
        _currentPage = 0;
      } else if (_selectedMode == TrainingMode.faces) {
        _shuffledFaceIndices = List.generate(_data.length, (i) => i)..shuffle();
        for (final c in _controllers) {
          c.clear();
        }
      }
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted || _focusNodes.isEmpty) return;
      final recallOrder = _recallOrderedDataIndices();
      final firstDataIndex = recallOrder.isNotEmpty ? recallOrder.first : 0;
      if (firstDataIndex >= 0 && firstDataIndex < _focusNodes.length) {
        _focusNodes[firstDataIndex].requestFocus();
      }
    });
  }

  /// Срабатывает при достижении лимита времени на запоминание всей сессии.
  void _onSessionMemorizationExpired() {
    if (!_isMemorizing || _activeSessionMemCapSec <= 0) return;
    uiTapClick(UiClickSound.bright);
    _completeMemorizationToRecall(trimToSeenPrefix: true);
  }

  void _nextChunk() {
    uiTapClick(UiClickSound.soft);
    final chunkSize = _currentEffectiveChunkSize();
    if ((_currentChunkIndex + 1) * chunkSize < _data.length) {
      _captureCurrentChunkMemorizationTime();
      setState(() {
        _currentChunkIndex++;
        if (_currentChunkIndex > _furthestChunkIndexReached) {
          _furthestChunkIndexReached = _currentChunkIndex;
        }
      });
      _handleAutoPlay();
    } else {
      _completeMemorizationToRecall(trimToSeenPrefix: false);
    }
  }

  void _previousChunk() {
    if (_currentChunkIndex <= 0) return;
    uiTapClick(UiClickSound.soft);
    _autoPlayTimer?.cancel();
    _captureCurrentChunkMemorizationTime();
    setState(() => _currentChunkIndex--);
  }

  void _goToFirstChunk() {
    if (_currentChunkIndex == 0) return;
    uiTapClick(UiClickSound.soft);
    _autoPlayTimer?.cancel();
    _captureCurrentChunkMemorizationTime();
    setState(() => _currentChunkIndex = 0);
  }

  Future<void> _finalizeAndPersistResults() async {
    uiTapClick(UiClickSound.bright);
    if (_isDuelRun) {
      if (!_isChecking && mounted) {
        setState(() => _isChecking = true);
      }
      await _submitDuelResults();
      return;
    }
    if (_recallStopwatch.isRunning) {
      _recallStopwatch.stop();
      _recallElapsedMs = _recallStopwatch.elapsedMilliseconds;
    }
    if (_memorizationElapsedMs == 0 && _memorizationTime > 0) {
      _memorizationElapsedMs = _memorizationTime * 1000;
    }
    if (_data.isNotEmpty &&
        (_memorizationMsByElement.length != _data.length ||
            _memorizationMsByElement.every((ms) => ms <= 0))) {
      final avgMs = (_memorizationElapsedMs / _data.length).round();
      _memorizationMsByElement = List<int>.filled(_data.length, avgMs);
    }

    int correctCount = 0;
    final List<int> correctnessPattern = List<int>.filled(_data.length, 0);
    if (_selectedMode == TrainingMode.images) {
      for (int i = 0; i < _data.length; i++) {
        if (_imageAnswerOrder[i] == i + 1) {
          correctCount++;
          correctnessPattern[i] = 1;
        }
      }
    } else if (_selectedMode == TrainingMode.faces) {
      for (int i = 0; i < _data.length; i++) {
        final answer = _normalizePersonName(_controllers[i].text);
        final expected = _normalizePersonName(_decodeFaceEntry(_data[i]).name);
        if (answer.isNotEmpty && answer == expected) {
          correctCount++;
          correctnessPattern[i] = 1;
        }
      }
    } else if (_selectedMode == TrainingMode.cards) {
      for (int i = 0; i < _data.length; i++) {
        if (_controllers[i].text.trim().toLowerCase() ==
            _data[i].toLowerCase()) {
          correctCount++;
          correctnessPattern[i] = 1;
        }
      }
    } else {
      for (int i = 0; i < _data.length; i++) {
        if (_controllers[i].text.trim().toLowerCase() ==
            _data[i].toLowerCase()) {
          correctCount++;
          correctnessPattern[i] = 1;
        }
      }
    }
    final double percentage =
        (_data.isEmpty) ? 0 : (correctCount / _data.length) * 100;
    final int n = _data.length;
    final int avgMemMsPerEl = n <= 0 ? 0 : (_memorizationElapsedMs / n).round();
    final totalTimeSec = ((_memorizationElapsedMs + _recallElapsedMs) / 1000.0)
        .round()
        .clamp(1, 999999)
        .toInt();
    final finishedAt = DateTime.now();
    final String modeKey = _selectedMode.name;
    final answersForScore =
        _controllers.map((c) => c.text).toList(growable: false);
    final displayScore = PublicStatsScoring.scoreFromItems(
      mode: modeKey,
      correctItems: correctCount,
      data: List<String>.from(_data),
      answers: answersForScore,
    );
    final qualifiesForRecord = TrainingRecordRules.qualifiesForMaxRecord(
      displayScore: displayScore,
      correctItems: correctCount,
      totalItems: n,
      accuracyPct: percentage,
      memMs: _memorizationElapsedMs,
    );
    await ProfileSessionService.instance.recordSession(
      mode: _selectedMode.name,
      totalItems: n,
      correctItems: correctCount,
      timeSeconds: totalTimeSec,
      date: finishedAt,
      encodingMs: _memorizationElapsedMs,
      recallMs: _recallElapsedMs,
      correctnessPattern: correctnessPattern,
      recordScore: displayScore,
    );
    try {
      await SmartNotificationService.instance.onTrainingCompleted(
        mode: _selectedMode.name,
        score: correctCount,
        date: finishedAt,
      );
    } catch (e) {
      // Notification cloud sync must not break training completion.
      debugPrint('Smart notification sync skipped: $e');
    }

    _perfectMemLast = correctCount >= 10;
    if (_isAcademyLessonRun || _isHistoryReplay || _isDuelRun) {
      _xpEarnedLast = 0;
    } else {
      _xpEarnedLast = await ProgressService.instance
          .awardMemorization(memorizedCount: correctCount);
    }

    final prefs = await SharedPreferences.getInstance();
    final String modeId =
        _selectedMode.name == 'standard' ? 'numbers' : _selectedMode.name;

    // Quests / personal goals — only for real training runs (not Academy lessons or replay).
    if (!_isAcademyLessonRun && !_isHistoryReplay) {
      await QuestService.instance
          .updateProgress(type: QuestType.completeXTrainings, value: 1);
      await QuestService.instance
          .updateProgress(type: QuestType.memorizeN, value: correctCount);
      await QuestService.instance
          .updateProgress(type: QuestType.totalMemorizedN, value: correctCount);
      await QuestService.instance
          .updateProgress(type: QuestType.trainMode, modeId: modeId, value: 1);
      if (percentage >= 100) {
        await QuestService.instance
            .updateProgress(type: QuestType.noErrors, isPerfect: true);
      }
      final currentBestBefore = prefs.getInt('best_score_$modeKey') ?? 0;
      if (qualifiesForRecord && displayScore > currentBestBefore) {
        await QuestService.instance
            .updateProgress(type: QuestType.improveRecord, value: 1);
      }
      await QuestService.instance.recordPersonalTrainingSession(
        modeId: modeId,
        sessionItemCount: n,
        isPerfectSession: percentage >= 100,
      );
    }

    final String historyKey = 'game_history_$modeKey';
    final List<String> historyRaw =
        List<String>.from(prefs.getStringList(historyKey) ?? []);

    double? prevPctSameN;
    for (final raw in historyRaw) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        final rowN = (m['n'] as num?)?.toInt();
        if (rowN == n) {
          prevPctSameN = (m['pct'] as num?)?.toDouble();
          break;
        }
      } catch (_) {}
    }

    final String modeLabelKey = modeKey == 'standard'
        ? 'mode_numbers'
        : modeKey == 'binary'
            ? 'mode_binary'
            : modeKey == 'words'
                ? 'mode_words'
                : modeKey == 'images'
                    ? 'mode_photo'
                    : modeKey == 'cards'
                        ? 'mode_cards'
                        : modeKey == 'faces'
                            ? 'mode_faces'
                            : 'mode_digits';
    final modeLabel = AppTexts.get(modeLabelKey);
    final pluralElements = AppTexts.plural(n, 'plural_element');

    if (prevPctSameN == null) {
      _resultComparisonLine = AppTexts.get('result_first_attempt', params: {
        'n': n.toString(),
        'plural': pluralElements,
        'mode': modeLabel,
      });
    } else if (prevPctSameN <= 0) {
      _resultComparisonLine = AppTexts.get('result_previous_zero', params: {
        'n': n.toString(),
        'plural': pluralElements,
        'pct': percentage.toStringAsFixed(0),
      });
    } else {
      final imp = ((percentage - prevPctSameN) / prevPctSameN) * 100.0;
      if (imp >= 0) {
        _resultComparisonLine = AppTexts.get('result_improvement', params: {
          'imp': imp.toStringAsFixed(1),
          'n': n.toString(),
          'plural': pluralElements,
        });
      } else {
        _resultComparisonLine = AppTexts.get('result_decline', params: {
          'imp': (-imp).toStringAsFixed(1),
          'n': n.toString(),
          'plural': pluralElements,
        });
      }
    }

    final String trainingHistoryRowId =
        '${finishedAt.millisecondsSinceEpoch}_${_selectedMode.name}_${Random().nextInt(1 << 32)}';
    final entry = <String, dynamic>{
      't': finishedAt.millisecondsSinceEpoch,
      'thId': trainingHistoryRowId,
      'n': n,
      'c': correctCount,
      'ds': displayScore,
      'pct': percentage,
      'memMs': _memorizationElapsedMs,
      'recMs': _recallElapsedMs,
      'avgMemMsPerEl': avgMemMsPerEl,
    };
    historyRaw.insert(0, jsonEncode(entry));
    if (historyRaw.length > _kMaxHistoryPerMode) {
      historyRaw.removeRange(_kMaxHistoryPerMode, historyRaw.length);
    }
    await prefs.setStringList(historyKey, historyRaw);

    final String bestSpeedKey = 'best_avg_ms_per_el_$modeKey';
    final int? prevBestMs = prefs.getInt(bestSpeedKey);
    if (prevBestMs == null ||
        (avgMemMsPerEl > 0 && avgMemMsPerEl < prevBestMs)) {
      await prefs.setInt(bestSpeedKey, avgMemMsPerEl);
    }

    int currentBest = prefs.getInt('best_score_$modeKey') ?? 0;
    if (qualifiesForRecord && displayScore > currentBest) {
      await prefs.setInt('best_score_$modeKey', displayScore);
    }

    int games = prefs.getInt('total_games_$modeKey') ?? 0;
    double avg = prefs.getDouble('avg_percentage_$modeKey') ?? 0.0;

    await prefs.setInt('total_games_$modeKey', games + 1);
    await prefs.setDouble(
        'avg_percentage_$modeKey', ((avg * games) + percentage) / (games + 1));
    try {
      await LeaderboardService.instance.addPoints(correctCount);
    } catch (e) {
      // Leaderboard push is best-effort and should not fail the run.
      debugPrint('Leaderboard sync skipped: $e');
    }
    await _saveTrainingHistoryEntry(
      finishedAt: finishedAt,
      correctCount: correctCount,
      correctnessPattern: correctnessPattern,
      historyId: trainingHistoryRowId,
    );
    unawaited(CloudSyncService.instance.markLocalStateDirty());
    unawaited(CloudSyncService.instance.enqueueSync());

    final streakNow = ProgressService.instance.progress.value.streak;
    _streakLine =
        AppTexts.get('streak_label', params: {'days': streakNow.toString()});
    await _maybePulseElementStatsButton();

    if (_activeLevelChallenge != null) {
      await _evaluateLevelChallengeAfterSession(
        percentage: percentage,
        memMs: _memorizationElapsedMs,
      );
    }
  }

  Future<void> _saveTrainingHistoryEntry({
    required DateTime finishedAt,
    required int correctCount,
    required List<int> correctnessPattern,
    required String historyId,
  }) async {
    if (_isHistoryReplay || _historySavedForCurrentRun || _data.isEmpty) return;
    _historySavedForCurrentRun = true;
    final answers = _controllers.map((c) => c.text).toList(growable: false);
    final entry = TrainingHistoryEntry(
      id: historyId,
      mode: _selectedMode.name,
      date: finishedAt,
      totalItems: _data.length,
      correctItems: correctCount,
      memorizationMs: _memorizationElapsedMs,
      recallMs: _recallElapsedMs,
      xpEarned: _xpEarnedLast,
      data: List<String>.from(_data),
      answers: answers,
      imageAnswerOrder: List<int?>.from(_imageAnswerOrder),
      memorizationMsByElement: List<int>.from(_elementTimes()),
      correctnessPattern: List<int>.from(correctnessPattern),
      lociBindings: List<String>.from(_attachedLociByElement),
    );
    await TrainingHistoryService.instance.record(entry);
    unawaited(CloudSyncService.instance.uploadTrainingHistoryEntry(entry));
  }

  void _requestTrainerKeyboardFocus() {
    if (!mounted || !trainerKeyboardShortcutsEnabled(context)) return;
    if (!_isSettingsMode && !_isMemorizing) return;
    if (_isPreparingImages || _isChecking) return;
    _trainerKeyboardFocusNode.requestFocus();
  }

  KeyEventResult _onTrainerKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (!trainerKeyboardShortcutsEnabled(context)) {
      return KeyEventResult.ignored;
    }
    if (_isPreparingImages) return KeyEventResult.ignored;

    if (_isSettingsMode && !_isDuelRun) {
      if (!handleTrainerStartKeyDown(event)) {
        return KeyEventResult.ignored;
      }
      if (_isPiMode) {
        _openPiTrainer();
      } else {
        unawaited(_generateData());
      }
      return KeyEventResult.handled;
    }

    if (_isMemorizing) {
      final handled = handleTrainerMemorizeKeyDown(
        event: event,
        onNext: _nextChunk,
        onPrev: _previousChunk,
        onFirst: _goToFirstChunk,
        onRecallNow: () {
          uiTapClick(UiClickSound.bright);
          _completeMemorizationToRecall(trimToSeenPrefix: true);
        },
        scrollController: _memorizerScrollController,
      );
      return handled ? KeyEventResult.handled : KeyEventResult.ignored;
    }

    return KeyEventResult.ignored;
  }

  Future<void> _maybePulseElementStatsButton() async {
    if (!mounted || _data.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final shownCount = prefs.getInt(_kElementStatsHintCountPrefsKey) ?? 0;
    if (shownCount >= 5) return;
    await prefs.setInt(_kElementStatsHintCountPrefsKey, shownCount + 1);
    _startElementStatsButtonPulse();
  }

  void _startElementStatsButtonPulse() {
    _elementStatsPulseTimer?.cancel();
    int ticks = 0;
    setState(() => _pulseElementStatsButton = true);
    uiTapClick(UiClickSound.bright);
    _elementStatsPulseTimer =
        Timer.periodic(const Duration(milliseconds: 150), (timer) {
      ticks++;
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _pulseElementStatsButton = !_pulseElementStatsButton);
      if (ticks == 2 || ticks == 4) {
        uiTapClick(UiClickSound.soft);
      }
      if (ticks >= 5) {
        timer.cancel();
        setState(() => _pulseElementStatsButton = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = appAccentColor.value;
    final showDuelCountdown = _isDuelRun &&
        (_duelPhase == DuelTrainerPhase.countdown ||
            (_duelPhase == DuelTrainerPhase.loading && !_duelItemsReady));

    Widget trainerBody;
    if (_isDuelRun && !_duelItemsReady) {
      trainerBody = const Center(child: CircularProgressIndicator());
    } else if (_isDuelRun && showDuelCountdown) {
      trainerBody = _buildDuelCountdown(onSurface, accent);
    } else {
      trainerBody = AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _isSettingsMode
            ? _buildSettings(key: const ValueKey('settings'))
            : (_isMemorizing
                ? _buildMemorizer(key: const ValueKey('memorizer'))
                : _buildInputArea(key: const ValueKey('input'))),
      );
    }

    final quiet = _isMemorizing || _isInputMode;
    if (trainingQuietMode.value != quiet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setTrainingQuietMode(quiet);
      });
    }

    final keyboardEnabled = trainerKeyboardShortcutsEnabled(context);
    if (keyboardEnabled && (_isSettingsMode || _isMemorizing)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestTrainerKeyboardFocus();
      });
    }

    final contentMaxWidth = _isSettingsMode
        ? webDesktopContentMaxWidth(context, narrow: 480, medium: 560, wide: 620)
        : webDesktopContentMaxWidth(context, narrow: 520, medium: 720, wide: 900);
    trainerBody = webDesktopFrame(
      context: context,
      maxWidth: contentMaxWidth,
      child: trainerBody,
    );

    final keyboardHint = keyboardEnabled
        ? trainerKeyboardHintText(
            settings: _isSettingsMode && !_isDuelRun,
            memorizing: _isMemorizing,
          )
        : '';

    final soloInSession = !_isDuelRun && !_isSettingsMode;
    Widget bodyStack = Stack(
          fit: StackFit.expand,
          children: [
            if (_isDuelRun && !showDuelCountdown && _duelItemsReady)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DuelTrainerOverlayBar(
                        room: _duelController?.room,
                        controller: _duelController,
                        accent: accent,
                        onSurface: onSurface,
                        recallCountdownLabel: _isInputMode &&
                                !_isChecking &&
                                !_duelSubmitted &&
                                _duelRecallCapSec > 0
                            ? _formatClockFromSec(
                                _recallTime.clamp(0, _duelRecallCapSec),
                              )
                            : null,
                      ),
                      if (_duelSubmitted)
                        _buildDuelWaitingBanner(onSurface, accent),
                    ],
                  ),
                ),
              ),
            Center(
              child: Padding(
                padding: EdgeInsets.only(
                  top: _isDuelRun && !showDuelCountdown
                      ? (_duelSubmitted ? 108 : 72)
                      : 0,
                ),
                child: trainerBody,
              ),
            ),
            if (_isPreparingImages)
              Positioned.fill(
                child: _buildPreloadView(key: const ValueKey('preloading')),
              ),
            if (_isChecking && _data.isNotEmpty && _selectedMode != TrainingMode.images)
              Positioned(
                right: 20,
                bottom: 20,
                child: SafeArea(child: _buildElementStatsButton()),
              ),
            if (_isSessionFinalizing && _deferResultsForActiveLevel)
              Positioned.fill(
                child: ColoredBox(
                  color: appPalette.value.background.withOpacity(0.92),
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              ),
            if (_showLevelCompletion && _pendingLevelReward != null)
              Positioned.fill(
                child: LevelCompletionOverlay(
                  reward: _pendingLevelReward!,
                  onDismiss: () {
                    if (!mounted) return;
                    setState(() {
                      _showLevelCompletion = false;
                      _pendingLevelReward = null;
                      _activeLevelChallenge = null;
                      _levelDigitGoalMode = false;
                    });
                    _returnToTrainerLobby(openLevelsPath: true);
                  },
                ),
              ),
            if (keyboardHint.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: trainerKeyboardHintBar(context, text: keyboardHint),
              ),
          ],
        );

    if (keyboardEnabled) {
      bodyStack = Focus(
        focusNode: _trainerKeyboardFocusNode,
        autofocus: false,
        onKeyEvent: _onTrainerKeyEvent,
        child: bodyStack,
      );
    }

    return PopScope(
      canPop: _isDuelRun ? _duelSubmitted : !soloInSession,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !soloInSession || !mounted) return;
        _returnToTrainerLobby(openLevelsPath: _returnToLevelsPathAfterSession);
      },
      child: Scaffold(
        backgroundColor: appPalette.value.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: !_isDuelRun,
        ),
        body: bodyStack,
      ),
    );
  }

  Widget _buildActiveLevelBanner(Color onSurface) {
    final level = _activeLevelChallenge!;
    final accent = appAccentColor.value;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.35)),
        color: accent.withOpacity(0.06),
      ),
      child: Row(
        children: [
          Icon(Icons.flag_outlined, size: 16, color: accent.withOpacity(0.85)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${levelGoalTitle(level)} · ${level.requiredAccuracy.toStringAsFixed(0)}%',
              style: TextStyle(
                color: onSurface.withOpacity(0.72),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              uiTapClick(UiClickSound.soft);
              setState(() {
                _activeLevelChallenge = null;
                _levelDigitGoalMode = false;
              });
            },
            child: Icon(Icons.close_rounded,
                size: 18, color: onSurface.withOpacity(0.35)),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelsPathButton(Color onSurface, {bool compact = false}) {
    return GestureDetector(
      onTap: _openLevelsPath,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 7 : 8,
        ),
        decoration: BoxDecoration(
          color: appPalette.value.surface.withOpacity(0.92),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _activeLevelChallenge != null
                ? appAccentColor.value.withOpacity(0.55)
                : appPalette.value.border.withOpacity(0.35),
          ),
          boxShadow: _activeLevelChallenge != null
              ? [
                  BoxShadow(
                    color: appAccentColor.value.withOpacity(0.22),
                    blurRadius: 14,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hub_outlined,
              size: compact ? 13 : 14,
              color: appAccentColor.value.withOpacity(0.9),
            ),
            const SizedBox(width: 6),
            Text(
              _lociText(ru: 'УРОВЕНЬ', en: 'LEVEL', de: 'STUFE'),
              style: TextStyle(
                color: onSurface.withOpacity(0.62),
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDuelCountdown(Color onSurface, Color accent) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: Tween<double>(begin: 0.55, end: 1).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
              ),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Text(
              '$_duelCountdownLeft',
              key: ValueKey(_duelCountdownLeft),
              style: TextStyle(
                color: accent,
                fontSize: 96,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _lociText(ru: 'ПРИГОТОВЬСЯ', en: 'GET READY', de: 'BEREIT MACHEN'),
            style: TextStyle(
              color: onSurface.withOpacity(0.45),
              fontSize: 12,
              letterSpacing: 4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuelWaitingBanner(Color onSurface, Color accent) {
    final bothDone = _duelBothFinished;

    if (bothDone) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.12),
          border: Border(
            bottom: BorderSide(color: accent.withOpacity(0.35)),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.emoji_events_outlined, size: 18, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _lociText(
                  ru: 'Дуэль завершена — разберите ответы ниже',
                  en: 'Duel finished — review your answers below',
                  de: 'Duell beendet — Antworten unten prüfen',
                ),
                style: TextStyle(
                  color: onSurface.withOpacity(0.82),
                  fontSize: 11.5,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed:
                  _duelNavigatedToResults ? null : _navigateToDuelResults,
              style: TextButton.styleFrom(
                foregroundColor: accent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _lociText(
                  ru: 'ИТОГИ',
                  en: 'RESULTS',
                  de: 'ERGEBNIS',
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final oppDone = _duelController?.opponentSubmitted() ?? false;
    final message = oppDone
        ? _lociText(
            ru: 'Соперник отправил — смотрите свои ответы ниже',
            en: 'Opponent submitted — review your answers below',
            de: 'Gegner fertig — Antworten unten prüfen',
          )
        : _lociText(
            ru: 'Ждём соперника — можно просмотреть свои ответы ниже',
            en: 'Waiting for opponent — review your answers below',
            de: 'Warte auf Gegner — Antworten unten prüfen',
          );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.10),
        border: Border(
          bottom: BorderSide(color: accent.withOpacity(0.28)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: accent.withOpacity(0.9),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: onSurface.withOpacity(0.78),
                fontSize: 11.5,
                height: 1.3,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings({Key? key}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SingleChildScrollView(
      key: key,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          children: [
            _buildModeSelector(),
            if (_selectedMode == TrainingMode.standard) ...[
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.layers_outlined,
                      size: 14, color: onSurface.withOpacity(0.3)),
                  const SizedBox(width: 8),
                  Text(AppTexts.get('modes_title'),
                      style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                          color: onSurface.withOpacity(0.3))),
                ],
              ),
              const SizedBox(height: 16),
              _buildMatrixModeSwitcher(),
              if (_isMatrixMode) const SizedBox(height: 12),
              if (!_isMatrixMode) ...[
                const SizedBox(height: 14),
                _buildNumberRangeSelector(),
              ],
            ],
            if (_selectedMode == TrainingMode.cards) ...[
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.style_rounded,
                      size: 14, color: onSurface.withOpacity(0.3)),
                  const SizedBox(width: 8),
                  Text(AppTexts.get('modes_title'),
                      style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                          color: onSurface.withOpacity(0.3))),
                ],
              ),
              const SizedBox(height: 16),
              _buildCardsDeckModeSwitcher(),
            ],
            if (_selectedMode == TrainingMode.words) ...[
              const SizedBox(height: 32),
              _buildWordsLanguageSelector(onSurface),
            ],
            if (_selectedMode == TrainingMode.images) ...[
              const SizedBox(height: 12),
              Text(
                _lociText(
                  ru: 'Картинки не повторяются, пока не пройдёте весь каталог ($_kTrainingImagePoolSize)',
                  en: 'Images won\'t repeat until you\'ve seen all $_kTrainingImagePoolSize',
                  de: 'Bilder wiederholen sich erst nach allen $_kTrainingImagePoolSize',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onSurface.withOpacity(0.4),
                  fontSize: 10,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (_selectedMode == TrainingMode.faces && _faceCatalogSize > 0) ...[
              const SizedBox(height: 12),
              Text(
                _lociText(
                  ru: 'В каталоге $_faceCatalogSize лиц — без повторов',
                  en: 'Catalog: $_faceCatalogSize faces — no repeats',
                  de: 'Katalog: $_faceCatalogSize Gesichter — keine Wiederholungen',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onSurface.withOpacity(0.4),
                  fontSize: 10,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            SizedBox(
                height: (_selectedMode == TrainingMode.standard ||
                        _selectedMode == TrainingMode.cards)
                    ? 36
                    : 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!_isPiMode && _currentLevelPath != null && _canUseTrainerLevels) ...[
                  _buildLevelsPathButton(onSurface),
                  const SizedBox(width: 8),
                ],
                if (_selectedMode == TrainingMode.faces) ...[
                  _buildFaceNamePoolButton(onSurface),
                  const SizedBox(width: 8),
                ],
                if (!_isPiMode) ...[
                  _buildLociBindingButton(onSurface),
                  const SizedBox(width: 8),
                ],
                if (!_isPiMode) _buildTimingSettingsButton(onSurface),
              ],
            ),
            if (_activeLevelChallenge != null) ...[
              const SizedBox(height: 12),
              _buildActiveLevelBanner(onSurface),
            ],
            const SizedBox(height: 14),
            _buildCounterSetting(
                AppTexts.get('settings_elements_count'), _totalCountController,
                isChunk: false),
            const SizedBox(height: 28),
            _buildCounterSetting(
                AppTexts.get('settings_chunk_count'), _chunkSizeController,
                isChunk: true),
            const SizedBox(height: 50),
            _buildActionButton(
              AppTexts.get('start'),
              _isPiMode ? _openPiTrainer : _generateData,
            ),
          ],
        ),
      ),
    );
  }

  void _openPiTrainer() {
    uiTapClick(UiClickSound.soft);
    unawaited(_persistModeCountPrefsForMode(TrainingMode.standard));
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PiTrainerScreen(),
      ),
    );
  }

  Widget _buildMatrixModeSwitcher() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final palette = appPalette.value;
    return Column(
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.border.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _subModeItem(AppTexts.get('mode_numbers_sub'), _NumbersSubMode.standard),
                _subModeItem(AppTexts.get('mode_matrix_sub'), _NumbersSubMode.matrix),
                _subModeItem('π', _NumbersSubMode.pi),
              ],
            ),
          ),
        ),
        if (_isMatrixMode)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              AppTexts.get('settings_matrix_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: onSurface.withOpacity(0.4),
                fontSize: 10,
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        if (_isPiMode)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _lociText(
                ru: 'Запоминание цифр числа π',
                en: 'Memorize digits of pi',
                de: 'Pi-Ziffern merken',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: onSurface.withOpacity(0.4),
                fontSize: 10,
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  String _wordsLanguageLabel(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.ru:
        return 'RU';
      case AppLanguage.en:
        return 'EN';
      case AppLanguage.de:
        return 'DE';
    }
  }

  Widget _buildWordsLanguageSelector(Color onSurface) {
    final palette = appPalette.value;
    return Column(
      children: [
        Text(
          _lociText(
            ru: 'Язык слов',
            en: 'Word language',
            de: 'Wortsprache',
          ),
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.4,
            fontWeight: FontWeight.bold,
            color: onSurface.withOpacity(0.35),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.border.withOpacity(0.3)),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final lang in AppLanguage.values)
                _wordsLanguageChip(lang, onSurface),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _lociText(
            ru: 'Слова не повторяются, пока не пройдёте весь словарь',
            en: 'Words won\'t repeat until you\'ve seen the full dictionary',
            de: 'Wörter wiederholen sich erst nach dem ganzen Wörterbuch',
          ),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: onSurface.withOpacity(0.4),
            fontSize: 10,
            height: 1.4,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _wordsLanguageChip(AppLanguage lang, Color onSurface) {
    final isSelected = _selectedWordsLanguage == lang;
    final count = _wordsCountByLanguage[lang];
    final label = count != null
        ? '${_wordsLanguageLabel(lang)} · $count'
        : _wordsLanguageLabel(lang);
    return GestureDetector(
      onTap: () {
        if (_selectedWordsLanguage == lang) return;
        uiTapClick(UiClickSound.soft);
        setState(() => _selectedWordsLanguage = lang);
        unawaited(persistWordsTrainingLanguage(lang));
        _normalizeCounter(_totalCountController, isChunk: false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? appAccentColor.value.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w300,
            color: isSelected
                ? appAccentColor.value
                : onSurface.withOpacity(0.48),
          ),
        ),
      ),
    );
  }

  Widget _buildCardsDeckModeSwitcher() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final palette = appPalette.value;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.border.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _cardsDeckSubModeItem(
                  AppTexts.get('mode_cards_random_sub'), false),
              _cardsDeckSubModeItem(AppTexts.get('mode_cards_deck_sub'), true),
            ],
          ),
        ),
        if (_cardsShuffledDeckMode) ...[
          const SizedBox(height: 12),
          Text(
            AppTexts.get('settings_cards_deck_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: onSurface.withOpacity(0.4),
              fontSize: 10,
              height: 1.4,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _cardsDeckSubModeItem(String label, bool isDeck) {
    final isSelected = _cardsShuffledDeckMode == isDeck;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: () {
        if (_cardsShuffledDeckMode == isDeck) return;
        uiTapClick(UiClickSound.soft);
        setState(() => _cardsShuffledDeckMode = isDeck);
        unawaited(_persistCardsDeckModePref());
        _normalizeCounter(_totalCountController, isChunk: false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? appAccentColor.value.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w200,
            color:
                isSelected ? appAccentColor.value : onSurface.withOpacity(0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberRangeSelector() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final palette = appPalette.value;
    return Column(
      children: [
        Text(
          'Диапазон чисел',
          style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.4,
              fontWeight: FontWeight.bold,
              color: onSurface.withOpacity(0.35)),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.border.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _numberRangeItem('0-9', 1),
              _numberRangeItem('00-99', 2),
              _numberRangeItem('000-999', 3),
            ],
          ),
        ),
      ],
    );
  }

  Widget _numberRangeItem(String label, int digits) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isSelected = _standardDigits == digits;
    return GestureDetector(
      onTap: () {
        uiTapClick(UiClickSound.soft);
        setState(() => _standardDigits = digits);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? appAccentColor.value.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w300,
            color:
                isSelected ? appAccentColor.value : onSurface.withOpacity(0.48),
          ),
        ),
      ),
    );
  }

  Widget _buildCardsDeckActiveBadge(Color onSurface) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: appPalette.value.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appAccentColor.value.withOpacity(0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.style_rounded,
              size: 14, color: appAccentColor.value.withOpacity(0.92)),
          const SizedBox(width: 6),
          Text(
            AppTexts.get('mode_cards_deck_sub'),
            style: TextStyle(
                color: onSurface.withOpacity(0.62),
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingSettingsButton(Color onSurface) {
    final hasCap = _sessionMemCapSec > 0;
    return GestureDetector(
      onTap: () {
        uiTapClick(UiClickSound.soft);
        _showTimingSettingsSheet();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: appPalette.value.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasCap
                ? appAccentColor.value.withOpacity(0.42)
                : appPalette.value.border.withOpacity(0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined,
                size: 14, color: appAccentColor.value.withOpacity(0.92)),
            const SizedBox(width: 6),
            Text(
              _lociText(ru: 'Время', en: 'Time', de: 'Zeit'),
              style: TextStyle(
                  color: onSurface.withOpacity(0.62),
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCustomSessionCapDialog() async {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    final controller = TextEditingController(
      text: _sessionMemCapSec > 0 ? '$_sessionMemCapSec' : '60',
    );
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: palette.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            _lociText(
                ru: 'Своё время', en: 'Custom duration', de: 'Eigene Dauer'),
            style: TextStyle(
                color: onSurface.withOpacity(0.92),
                fontSize: 17,
                fontWeight: FontWeight.w600),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(color: onSurface),
            decoration: InputDecoration(
              hintText: _lociText(
                  ru: 'Секунды (15–7200)',
                  en: 'Seconds (15–7200)',
                  de: 'Sekunden (15–7200)'),
              hintStyle: TextStyle(color: onSurface.withOpacity(0.35)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: palette.border.withOpacity(0.45)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: accent.withOpacity(0.55)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  Text(_lociText(ru: 'Отмена', en: 'Cancel', de: 'Abbrechen')),
            ),
            TextButton(
              onPressed: () {
                final v = int.tryParse(controller.text.trim());
                if (v == null || v < 15 || v > 7200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_lociText(
                          ru: 'Введите от 15 до 7200 секунд',
                          en: 'Enter 15–7200 seconds',
                          de: '15–7200 Sekunden eingeben')),
                    ),
                  );
                  return;
                }
                setState(() => _sessionMemCapSec = v);
                unawaited(_persistSessionMemCapPref());
                Navigator.pop(ctx);
              },
              child:
                  Text(_lociText(ru: 'Сохранить', en: 'Save', de: 'Speichern')),
            ),
          ],
        );
      },
    );
    controller.dispose();
  }

  void _showTimingSettingsSheet() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    const presets = <int>[30, 60, 90, 120, 180, 300, 600];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewPadding.bottom;
        return SafeArea(
          child: StatefulBuilder(
            builder: (ctx, setModal) {
              void syncBoth(VoidCallback fn) {
                setState(fn);
                setModal(() {});
              }

              return Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: onSurface.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.hourglass_top_rounded,
                                color: accent.withOpacity(0.9), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _lociText(
                                      ru: 'Тайминг тренировки',
                                      en: 'Training timing',
                                      de: 'Training-Timing'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16.5,
                                    color: onSurface.withOpacity(0.94),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _lociText(
                                    ru: 'Сколько длится фаза запоминания; после лимита или досрочного «к вводу» проверяются только уже показанные элементы.',
                                    en: 'Memorization duration; after the limit or early recall, only items you already saw will be tested.',
                                    de: 'Merkphase; nach Limit oder früher Abfrage werden nur bereits gezeigte Elemente abgefragt.',
                                  ),
                                  style: TextStyle(
                                      color: onSurface.withOpacity(0.5),
                                      fontSize: 12.4,
                                      height: 1.4),
                                ),
                                if (_isMemorizing) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: accent.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: accent.withOpacity(0.22)),
                                    ),
                                    child: Text(
                                      _lociText(
                                        ru: 'Новый лимит применится со следующего старта «Начать».',
                                        en: 'A new limit applies from the next time you press Start.',
                                        de: 'Ein neues Limit gilt ab dem nächsten «Start».',
                                      ),
                                      style: TextStyle(
                                          color: onSurface.withOpacity(0.62),
                                          fontSize: 11.5,
                                          height: 1.35),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text(
                        _lociText(
                            ru: 'ЛИМИТ НА ЗАПОМИНАНИЕ',
                            en: 'MEMORIZATION LIMIT',
                            de: 'MERK-LIMIT'),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: onSurface.withOpacity(0.38),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ChoiceChip(
                            label: Text(_lociText(
                                ru: 'Без лимита', en: 'None', de: 'Keins')),
                            selected: _sessionMemCapSec <= 0,
                            onSelected: (_) {
                              syncBoth(() => _sessionMemCapSec = 0);
                              unawaited(_persistSessionMemCapPref());
                            },
                            selectedColor: accent.withOpacity(0.22),
                            labelStyle: TextStyle(
                              color: _sessionMemCapSec <= 0
                                  ? accent
                                  : onSurface.withOpacity(0.78),
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                          for (final s in presets)
                            ChoiceChip(
                              label: Text(_formatClockFromSec(s)),
                              selected: _sessionMemCapSec == s,
                              onSelected: (_) {
                                syncBoth(() => _sessionMemCapSec = s);
                                unawaited(_persistSessionMemCapPref());
                              },
                              selectedColor: accent.withOpacity(0.22),
                              labelStyle: TextStyle(
                                color: _sessionMemCapSec == s
                                    ? accent
                                    : onSurface.withOpacity(0.78),
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ),
                            ),
                          ActionChip(
                            avatar: Icon(Icons.edit_outlined,
                                size: 16, color: accent.withOpacity(0.85)),
                            label: Text(_lociText(
                                ru: 'Своё…', en: 'Custom…', de: 'Eigene…')),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await _showCustomSessionCapDialog();
                            },
                            backgroundColor: palette.card.withOpacity(0.9),
                            labelStyle: TextStyle(
                                color: onSurface.withOpacity(0.85),
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Divider(color: onSurface.withOpacity(0.08), height: 1),
                      const SizedBox(height: 18),
                      Text(
                        _lociText(
                            ru: 'АВТОПЕРЕЛИСТЫВАНИЕ',
                            en: 'AUTO-ADVANCE',
                            de: 'AUTO-WEITER'),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: onSurface.withOpacity(0.38),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _lociText(
                            ru: 'Таймер на элемент',
                            en: 'Timer per element',
                            de: 'Timer pro Element',
                          ),
                          style: TextStyle(
                              color: onSurface.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                        subtitle: Text(
                          _lociText(
                            ru: 'Автоматически к следующему фрагменту после паузы.',
                            en: 'Automatically go to the next chunk after a pause.',
                            de: 'Automatisch zur nächsten Gruppe nach einer Pause.',
                          ),
                          style: TextStyle(
                              color: onSurface.withOpacity(0.48),
                              fontSize: 12,
                              height: 1.35),
                        ),
                        value: _useMemorizationTimer,
                        activeTrackColor: accent.withOpacity(0.38),
                        activeThumbColor: accent,
                        onChanged: (v) =>
                            syncBoth(() => _useMemorizationTimer = v),
                      ),
                      if (_useMemorizationTimer) ...[
                        const SizedBox(height: 4),
                        _buildCounterSetting(
                            AppTexts.get('settings_flash_seconds'),
                            _flashSecondsController,
                            isChunk: false),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: accent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            _lociText(ru: 'Готово', en: 'Done', de: 'Fertig'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _lociText({
    required String ru,
    required String en,
    required String de,
  }) {
    switch (appLanguage.value) {
      case AppLanguage.en:
        return en;
      case AppLanguage.de:
        return de;
      case AppLanguage.ru:
        return ru;
    }
  }

  _LociRoute? _activeTrainingLociRoute() {
    if (_selectedTrainingLociRoute < 0 ||
        _selectedTrainingLociRoute >= _trainingLociRoutes.length) {
      return null;
    }
    return _trainingLociRoutes[_selectedTrainingLociRoute];
  }

  void _rebuildAttachedLoci() {
    if (_data.isEmpty) {
      _attachedLociByElement = const <String>[];
      return;
    }
    final route = _activeTrainingLociRoute();
    if (route == null || route.loci.isEmpty) {
      _attachedLociByElement = List<String>.filled(_data.length, '');
      return;
    }
    final loci = route.loci;
    final int start = _lociStartIndex.clamp(0, max(0, loci.length - 1));
    _attachedLociByElement = List<String>.generate(_data.length, (index) {
      final locusIndex = (start + index) % loci.length;
      return loci[locusIndex];
    }, growable: false);
  }

  String _attachedLocusForIndex(int index) {
    if (index < 0 || index >= _attachedLociByElement.length) return '';
    return _attachedLociByElement[index];
  }

  void _openLociRoutesForLocus(String locusName, {bool popStatsSheet = false}) {
    final trimmed = locusName.trim();
    if (trimmed.isEmpty) return;
    uiTapClick(UiClickSound.soft);
    if (popStatsSheet) {
      Navigator.of(context).pop();
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LociRoutesScreen(
          initialRouteIndex: _selectedTrainingLociRoute >= 0
              ? _selectedTrainingLociRoute
              : null,
          highlightLocusName: trimmed,
        ),
      ),
    );
  }

  Widget _buildLociBindingButton(Color onSurface) {
    final route = _activeTrainingLociRoute();
    final hasRoute = route != null;
    return GestureDetector(
      onTap: _showLociBindingSheet,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: appPalette.value.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasRoute
                ? appAccentColor.value.withOpacity(0.42)
                : appPalette.value.border.withOpacity(0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.alt_route_rounded,
                size: 14, color: appAccentColor.value.withOpacity(0.92)),
            const SizedBox(width: 6),
            Text(
              hasRoute ? 'Loci #${_lociStartIndex + 1}' : 'Loci',
              style: TextStyle(
                  color: onSurface.withOpacity(0.62),
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _showLociBindingSheet() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    int selected = _selectedTrainingLociRoute;
    int start = _lociStartIndex;
    showModalBottomSheet(
      context: context,
      backgroundColor: appPalette.value.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            final hasRoutes = _trainingLociRoutes.isNotEmpty;
            final route =
                (selected >= 0 && selected < _trainingLociRoutes.length)
                    ? _trainingLociRoutes[selected]
                    : null;
            final loci = route?.loci ?? const <String>[];
            final safeStart =
                loci.isEmpty ? 0 : start.clamp(0, loci.length - 1);
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 4,
                    decoration: BoxDecoration(
                      color: onSurface.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _lociText(
                      ru: 'Привязка локи к тренировке',
                      en: 'Attach loci to training',
                      de: 'Loci mit Training verknuepfen',
                    ),
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: onSurface),
                  ),
                  const SizedBox(height: 12),
                  if (!hasRoutes)
                    Text(
                      _lociText(
                        ru: 'Сначала создай маршрут в меню Loci.',
                        en: 'Create a route first in the Loci menu.',
                        de: 'Erstelle zuerst eine Route im Loci-Menue.',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: onSurface.withOpacity(0.55), fontSize: 12),
                    )
                  else ...[
                    SizedBox(
                      height: 170,
                      child: ListView(
                        children: [
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              selected < 0
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              size: 18,
                              color: selected < 0
                                  ? appAccentColor.value
                                  : onSurface.withOpacity(0.35),
                            ),
                            title: Text(
                              _lociText(
                                ru: 'Без маршрута',
                                en: 'No route',
                                de: 'Keine Route',
                              ),
                              style: TextStyle(
                                color: onSurface
                                    .withOpacity(selected < 0 ? 0.92 : 0.72),
                                fontWeight: selected < 0
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                            subtitle: Text(
                              _lociText(
                                ru: 'Тренировка без привязки к локациям',
                                en: 'Train without loci bindings',
                                de: 'Training ohne Loci-Zuordnung',
                              ),
                              style: TextStyle(
                                  color: onSurface.withOpacity(0.45),
                                  fontSize: 11),
                            ),
                            onTap: () => setLocal(() {
                              selected = -1;
                              start = 0;
                            }),
                          ),
                          ...List.generate(_trainingLociRoutes.length, (i) {
                            final active = i == selected;
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                active
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                size: 18,
                                color: active
                                    ? appAccentColor.value
                                    : onSurface.withOpacity(0.35),
                              ),
                              title: Text(
                                _trainingLociRoutes[i].name,
                                style: TextStyle(
                                  color: onSurface
                                      .withOpacity(active ? 0.92 : 0.72),
                                  fontWeight: active
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                              subtitle: Text(
                                '${_trainingLociRoutes[i].loci.length} loci',
                                style: TextStyle(
                                    color: onSurface.withOpacity(0.45),
                                    fontSize: 11),
                              ),
                              onTap: () => setLocal(() {
                                selected = i;
                                start = 0;
                              }),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (loci.isNotEmpty) ...[
                      Text(
                        '${_lociText(ru: 'Стартовая точка', en: 'Start point', de: 'Startpunkt')}: ${safeStart + 1} - ${loci[safeStart]}',
                        style: TextStyle(
                            color: onSurface.withOpacity(0.72), fontSize: 12),
                      ),
                      Slider(
                        value: safeStart.toDouble(),
                        min: 0,
                        max: max(0, loci.length - 1).toDouble(),
                        divisions: max(1, loci.length - 1),
                        onChanged: (v) => setLocal(() => start = v.round()),
                      ),
                    ],
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(_lociText(
                              ru: 'Отмена', en: 'Cancel', de: 'Abbrechen')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _selectedTrainingLociRoute = selected;
                              _lociStartIndex = start;
                              _rebuildAttachedLoci();
                            });
                            Navigator.pop(context);
                          },
                          child: Text(_lociText(
                              ru: 'Применить', en: 'Apply', de: 'Anwenden')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAttachedLociPreviewSheet() {
    final route = _activeTrainingLociRoute();
    if (route == null || route.loci.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_lociText(
            ru: 'Локи не выбраны. Нажми кнопку Loci в настройках.',
            en: 'No loci selected. Tap the Loci button in settings.',
            de: 'Keine Loci ausgewaehlt. Tippe auf Loci in den Einstellungen.',
          )),
        ),
      );
      return;
    }
    uiTapClick(UiClickSound.soft);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    showModalBottomSheet(
      context: context,
      backgroundColor: appPalette.value.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 4,
                decoration: BoxDecoration(
                  color: onSurface.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${route.name} • ${_lociText(ru: 'старт', en: 'start', de: 'start')} #${_lociStartIndex + 1}',
                style: TextStyle(color: onSurface, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 240,
                child: ListView.builder(
                  itemCount: _attachedLociByElement.length,
                  itemBuilder: (context, index) {
                    final locus = _attachedLocusForIndex(index);
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Text(
                        '${index + 1}',
                        style: TextStyle(
                            color: onSurface.withOpacity(0.5), fontSize: 12),
                      ),
                      title: Text(
                        locus.isEmpty ? '-' : locus,
                        style: TextStyle(
                            color: onSurface.withOpacity(0.85), fontSize: 13),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _subModeItem(String label, _NumbersSubMode mode) {
    final isSelected = _numbersSubMode == mode;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: () {
        uiTapClick(UiClickSound.soft);
        setState(() => _numbersSubMode = mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: mode == _NumbersSubMode.pi ? 14 : 18,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? appAccentColor.value.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w200,
            color:
                isSelected ? appAccentColor.value : onSurface.withOpacity(0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: appPalette.value.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appPalette.value.border.withOpacity(0.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _modeButton(AppTexts.get('numbers'), TrainingMode.standard),
            _modeButton(AppTexts.get('binary'), TrainingMode.binary),
            _modeButton(AppTexts.get('words'), TrainingMode.words),
            _modeButton(AppTexts.get('photo'), TrainingMode.images),
            _modeButton(AppTexts.get('cards'), TrainingMode.cards),
            _modeButton(AppTexts.get('faces'), TrainingMode.faces),
            if (kFactsTrainerVisible) _factsModeButton(),
          ],
        ),
      ),
    );
  }

  Widget _factsModeButton() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: () {
        uiTapClick(UiClickSound.soft);
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const FactsTrainerScreen(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(left: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          AppTexts.translate(const {
            AppLanguage.ru: 'ФАКТЫ',
            AppLanguage.en: 'FACTS',
            AppLanguage.de: 'FAKTEN',
          }),
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w200,
            color: onSurface.withOpacity(0.52),
          ),
        ),
      ),
    );
  }

  Widget _modeButton(String label, TrainingMode mode) {
    bool isSelected = _selectedMode == mode;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: () async {
        uiTapClick(UiClickSound.soft);
        if (mode == TrainingMode.images) {
          if (!await trainingHasInternetAccess()) {
            if (!mounted) return;
            await _showOfflinePhotoFacesDialog();
            return;
          }
        }
        if (widget.historyEntry == null) {
          await _persistModeCountPrefsForMode(_selectedMode);
        }
        if (!mounted) return;
        setState(() {
          _selectedMode = mode;
          if (_selectedMode != TrainingMode.standard) {
            _numbersSubMode = _NumbersSubMode.standard;
          }
          // При переключении режима проверяем и корректируем количество элементов на экране
          _normalizeCounter(_chunkSizeController,
              isChunk: true, persist: false);
        });
        if (widget.historyEntry == null) {
          await _loadModeCountPrefsForMode(mode);
        }
        if (mode == TrainingMode.words && _wordsCountByLanguage.isEmpty) {
          unawaited(_refreshWordsCounts());
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? appAccentColor.value.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 9,
                letterSpacing: 0.8,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w200,
                color: isSelected
                    ? appAccentColor.value
                    : onSurface.withOpacity(0.52))),
      ),
    );
  }

  Widget _buildFaceNamePoolButton(Color onSurface) {
    return GestureDetector(
      onTap: () {
        uiTapClick(UiClickSound.soft);
        showModalBottomSheet(
          context: context,
          backgroundColor: appPalette.value.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          builder: (context) {
            final options = const [
              ('ENGNAME', 'English names'),
              ('GERNAME', 'German names'),
              ('RUNAME', 'Russian names'),
              ('RUINTERNATIONAL', 'RU International'),
            ];
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 4,
                    decoration: BoxDecoration(
                      color: onSurface.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Name pool',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...options.map((entry) {
                    final key = entry.$1;
                    final label = entry.$2;
                    final selected = _selectedFaceNamePool == key;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 18,
                        color: selected
                            ? appAccentColor.value
                            : onSurface.withOpacity(0.35),
                      ),
                      title: Text(
                        label,
                        style: TextStyle(
                          color: onSurface.withOpacity(selected ? 0.92 : 0.72),
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      onTap: () {
                        setState(() => _selectedFaceNamePool = key);
                        Navigator.of(context).pop();
                      },
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: appPalette.value.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: appPalette.value.border.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.badge_outlined,
                size: 13, color: appAccentColor.value.withOpacity(0.92)),
            const SizedBox(width: 6),
            Text(
              _facePoolLabel(),
              style: TextStyle(
                  color: onSurface.withOpacity(0.65),
                  fontSize: 10,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterSetting(String title, TextEditingController controller,
      {required bool isChunk}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isTime = controller == _flashSecondsController;
    return Column(
      children: [
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w200,
                fontSize: 14,
                color: onSurface.withOpacity(0.62))),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _counterStepButton(
              icon: Icons.remove,
              onTap: () => _changeCounter(controller, isTime ? -0.1 : -1,
                  isChunk: isChunk),
              onLongPressStart: () => _startCounterHold(
                  controller, isTime ? -0.1 : -1,
                  isChunk: isChunk),
            ),
            Container(
              width: 96,
              height: 50,
              alignment: Alignment.center,
              child: TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w200,
                    color: appAccentColor.value),
                decoration: const InputDecoration(
                    border: InputBorder.none, isCollapsed: true),
                onChanged: (_) =>
                    _normalizeCounter(controller, isChunk: isChunk),
              ),
            ),
            _counterStepButton(
              icon: Icons.add,
              onTap: () => _changeCounter(controller, isTime ? 0.1 : 1,
                  isChunk: isChunk),
              onLongPressStart: () => _startCounterHold(
                  controller, isTime ? 0.1 : 1,
                  isChunk: isChunk),
            ),
          ],
        ),
      ],
    );
  }

  void _normalizeCounter(
    TextEditingController controller, {
    required bool isChunk,
    bool persist = true,
  }) {
    if (controller.text.isEmpty)
      return; // Разрешаем временно пустую строку при вводе

    if (controller == _flashSecondsController) {
      double? val = double.tryParse(controller.text);
      if (val != null) {
        if (val < 0.1) {
          controller.text = "0.1";
          controller.selection = const TextSelection.collapsed(offset: 3);
        } else if (val > 10.0) {
          controller.text = "10.0";
          controller.selection = const TextSelection.collapsed(offset: 4);
        }
      }
      return;
    }

    int val = int.tryParse(controller.text) ?? 1;
    int maxVal = isChunk ? 10 : _maxTotalCountForMode(_selectedMode);

    if (isChunk) {
      maxVal = _maxChunkForMode(_selectedMode);
    }

    if (val > maxVal) {
      controller.text = maxVal.toString();
      controller.selection =
          TextSelection.collapsed(offset: controller.text.length);
    }
    if (val < 1) {
      controller.text = "1";
      controller.selection = const TextSelection.collapsed(offset: 1);
    }
    if (persist && widget.historyEntry == null) {
      unawaited(_persistModeCountPrefsForMode(_selectedMode));
    }
  }

  void _changeCounter(TextEditingController controller, double delta,
      {required bool isChunk}) {
    if (controller == _flashSecondsController) {
      double val = double.tryParse(controller.text) ?? 2.0;
      val += delta;
      if (val < 0.1) val = 0.1;
      if (val > 10.0) val = 10.0;
      setState(() => controller.text = val.toStringAsFixed(1));
      return;
    }

    int val = int.tryParse(controller.text) ?? 1;
    val += delta.toInt();
    val = max(1, val);

    int maxVal = isChunk ? 10 : _maxTotalCountForMode(_selectedMode);
    if (isChunk) {
      maxVal = _maxChunkForMode(_selectedMode);
    }

    val = min(maxVal, val);
    setState(() => controller.text = val.toString());
    if (widget.historyEntry == null) {
      unawaited(_persistModeCountPrefsForMode(_selectedMode));
    }
  }

  void _startCounterHold(TextEditingController controller, double delta,
      {required bool isChunk}) {
    _counterHoldTimer?.cancel();
    _changeCounter(controller, delta, isChunk: isChunk);
    _counterHoldTimer = Timer.periodic(const Duration(milliseconds: 90), (_) {
      _changeCounter(controller, delta, isChunk: isChunk);
    });
  }

  Widget _counterStepButton({
    required IconData icon,
    required VoidCallback onTap,
    required VoidCallback onLongPressStart,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: () {
        uiTapClick(UiClickSound.soft);
        onTap();
      },
      onLongPressStart: (_) => onLongPressStart(),
      onLongPressEnd: (_) => _counterHoldTimer?.cancel(),
      onLongPressCancel: () => _counterHoldTimer?.cancel(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: onSurface.withOpacity(0.05)),
        ),
        child: Icon(icon, size: 18, color: onSurface.withOpacity(0.24)),
      ),
    );
  }

  Widget _circleIconButton(IconData icon, VoidCallback onTap) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: () {
        uiTapClick(UiClickSound.soft);
        onTap();
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: onSurface.withOpacity(0.05)),
        ),
        child: Icon(icon, size: 18, color: onSurface.withOpacity(0.24)),
      ),
    );
  }

  Widget _buildCardDisplay(String cardCode) {
    return ListenableBuilder(
      listenable:
          Listenable.merge([blackSuitAlwaysWhite, appAccentColor, appPalette]),
      builder: (context, _) {
        final palette = appPalette.value;
        final suitLetter = parsePlayingCardSuitLetter(cardCode);
        if (suitLetter == null) {
          return Container(
            width: 140,
            height: 200,
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: palette.border.withOpacity(0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.style_outlined,
                size: 42,
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.22),
              ),
            ),
          );
        }

        final rank = cardCode.substring(1).toUpperCase();
        final suitColor = semanticPlayingCardSuitColor(
          suitLetter: suitLetter,
          accent: appAccentColor.value,
          blackSuitsWhite: blackSuitAlwaysWhite.value,
        );
        final glyphShadows =
            playingCardGlyphShadows(suitColor, palette.surface);
        final rankStyle = TextStyle(
          color: suitColor,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          height: 1,
          shadows: glyphShadows,
        );

        return Container(
          width: 140,
          height: 200,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: palette.border.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Opacity(
                  opacity: 0.2,
                  child: PlayingCardSuitIcon(
                    suitLetter: suitLetter,
                    color: suitColor,
                    size: 124,
                    cardSurfaceColor: palette.surface,
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rank, style: rankStyle),
                    const SizedBox(height: 2),
                    PlayingCardSuitIcon(
                      suitLetter: suitLetter,
                      color: suitColor,
                      size: 22,
                      cardSurfaceColor: palette.surface,
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 14,
                right: 14,
                child: RotatedBox(
                  quarterTurns: 2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rank, style: rankStyle),
                      const SizedBox(height: 2),
                      PlayingCardSuitIcon(
                        suitLetter: suitLetter,
                        color: suitColor,
                        size: 22,
                        cardSurfaceColor: palette.surface,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatClockFromSec(int sec) {
    final s = sec.clamp(0, 86400);
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  /// Numbers, binary, words, and images — not matrix / cards / faces.
  bool _displayDirectionApplies() {
    if (_selectedMode == TrainingMode.standard && _isMatrixMode) {
      return false;
    }
    return _selectedMode == TrainingMode.standard ||
        _selectedMode == TrainingMode.binary ||
        _selectedMode == TrainingMode.words ||
        _selectedMode == TrainingMode.images;
  }

  List<int> _memorizerVisibleIndices({
    required int start,
    required int end,
  }) {
    final indices = List<int>.generate(end - start, (offset) => start + offset);
    if (_displayDirectionApplies() &&
        numberDisplayDirection.value == NumberDisplayDirection.bottomToTop) {
      return indices.reversed.toList(growable: false);
    }
    return indices;
  }

  /// Matches memorizer chunk order so recall slots align with how elements were shown.
  List<int> _recallOrderedDataIndices() {
    final n = _data.length;
    if (n == 0) return const [];
    if (!_displayDirectionApplies()) {
      return List<int>.generate(n, (i) => i, growable: false);
    }
    final chunkSize = _currentEffectiveChunkSize();
    final out = <int>[];
    var ci = 0;
    while (ci * chunkSize < n) {
      final start = ci * chunkSize;
      final end = min(start + chunkSize, n);
      out.addAll(_memorizerVisibleIndices(start: start, end: end));
      ci++;
    }
    return out;
  }

  Widget _buildMemorizerChunkItem(
    int index,
    Color onSurface, {
    bool horizontal = false,
  }) {
    final item = _data[index];
    if (_selectedMode == TrainingMode.images) {
      final w = horizontal ? 200.0 : 300.0;
      final h = horizontal ? 130.0 : 190.0;
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: onSurface.withOpacity(0.1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          item,
          fit: BoxFit.cover,
          cacheWidth: 700,
          errorBuilder: (_, __, ___) => Center(
            child: Icon(Icons.broken_image_outlined,
                color: onSurface.withOpacity(0.2), size: 42),
          ),
        ),
      );
    }
    if (_selectedMode == TrainingMode.faces) {
      final person = _decodeFaceEntry(item);
      final size = horizontal ? 160.0 : 240.0;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: onSurface.withOpacity(0.15), width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image(
              image: _faceImageProviderAt(index),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Icon(Icons.broken_image_outlined,
                    color: onSurface.withOpacity(0.2), size: 42),
              ),
            ),
          ),
          if (!horizontal) ...[
            const SizedBox(height: 16),
            Text(
              person.name.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
                color: onSurface.withOpacity(0.92),
              ),
            ),
          ],
        ],
      );
    }
    if (_selectedMode == TrainingMode.cards) {
      return _buildCardDisplay(item);
    }
    final isWords = _selectedMode == TrainingMode.words;
    return Text(
      item.toUpperCase(),
      style: TextStyle(
        fontSize: horizontal
            ? (isWords ? 28 : 42)
            : (isWords ? 40 : 80),
        fontWeight: FontWeight.w100,
        letterSpacing: horizontal ? 4 : 8,
        color: onSurface.withOpacity(0.9),
      ),
    );
  }

  Widget _buildMemorizer({Key? key}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accentTint =
        Color.lerp(onSurface, appAccentColor.value, 0.3)!.withOpacity(0.45);
    int chunkSize = int.tryParse(_chunkSizeController.text) ?? 1;
    if (_selectedMode == TrainingMode.faces) chunkSize = 1;
    int start = _currentChunkIndex * chunkSize;
    int end = min(start + chunkSize, _data.length);
    int totalChunks = (_data.length / chunkSize).ceil();
    bool canGoBack = _currentChunkIndex > 0;
    final hasMemLimit = _activeSessionMemCapSec > 0;
    final formattedMemTime = _isDuelRun && hasMemLimit
        ? _formatClockFromSec(
            _memorizationTime.clamp(0, _activeSessionMemCapSec))
        : hasMemLimit
            ? _formatClockFromSec(
                (_activeSessionMemCapSec - _memorizationTime)
                    .clamp(0, _activeSessionMemCapSec),
              )
            : '${(_memorizationTime ~/ 60).toString().padLeft(2, '0')}:${(_memorizationTime % 60).toString().padLeft(2, '0')}';

    if (_selectedMode == TrainingMode.standard && _isMatrixMode) {
      return MnemonicMatrixMemorizer(
        data: _data,
        currentChunkIndex: _currentChunkIndex,
        chunkSize: chunkSize,
        formattedTime: formattedMemTime,
        memorizationSubtitle: null,
        onTimerSettingsTap: _isDuelRun
            ? null
            : () {
                uiTapClick(UiClickSound.soft);
                _showTimingSettingsSheet();
              },
        onNext: _nextChunk,
        onPrev: _previousChunk,
        onFirst: _goToFirstChunk,
        onRecallNow: () {
          uiTapClick(UiClickSound.bright);
          _completeMemorizationToRecall(trimToSeenPrefix: true);
        },
      );
    }

    return ValueListenableBuilder<NumberDisplayDirection>(
      valueListenable: numberDisplayDirection,
      builder: (context, _, __) {
        final useHorizontalChunkLayout = _displayDirectionApplies() &&
            numberDisplayDirection.value == NumberDisplayDirection.leftToRight;
        final visibleIndices = _memorizerVisibleIndices(start: start, end: end);
        return SingleChildScrollView(
          controller: _memorizerScrollController,
          physics: const BouncingScrollPhysics(),
          child: Column(
            key: key,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _isDuelRun
                        ? null
                        : () {
                            uiTapClick(UiClickSound.soft);
                            _showTimingSettingsSheet();
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formattedMemTime,
                            style: TextStyle(
                              color: accentTint,
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 4,
                              decoration: TextDecoration.underline,
                              decorationColor: accentTint.withOpacity(0.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_selectedMode == TrainingMode.cards &&
                      _cardsShuffledDeckMode) ...[
                    const SizedBox(width: 8),
                    _buildCardsDeckActiveBadge(onSurface),
                  ],
                ],
              ),
              const SizedBox(height: 40),
              if (useHorizontalChunkLayout)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 20,
                    runSpacing: 12,
                    children: visibleIndices
                        .map((index) => _buildMemorizerChunkItem(
                              index,
                              onSurface,
                              horizontal: true,
                            ))
                        .toList(growable: false),
                  ),
                )
              else
                ...visibleIndices.map((index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: _buildMemorizerChunkItem(index, onSurface),
                  );
                }),
              const SizedBox(height: 12),
              Text(
                '${_currentChunkIndex + 1} / $totalChunks',
                style: TextStyle(
                    color: onSurface.withOpacity(0.2),
                    fontSize: 12,
                    letterSpacing: 1),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      child: _buildActionButton(AppTexts.get('back'),
                          canGoBack ? _previousChunk : () {}),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 120,
                      child: _buildActionButton(AppTexts.get('first_chunk'),
                          canGoBack ? _goToFirstChunk : () {}),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 100,
                      child: _buildActionButton(
                          AppTexts.get('next_chunk'), _nextChunk),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputArea({Key? key}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final duelRecallCountdown =
        _isDuelRun && _duelRecallCapSec > 0 && !_isChecking;
    String formattedRecallTime = duelRecallCountdown
        ? _formatClockFromSec(_recallTime.clamp(0, _duelRecallCapSec))
        : '${(_recallTime ~/ 60).toString().padLeft(2, '0')}:${(_recallTime % 60).toString().padLeft(2, '0')}';

    // Интеграция нового профессионального интерфейса для изображений (V2)
    if (_selectedMode == TrainingMode.images) {
      return MnemonicImageRecallScreen(
        imageUrls: _data,
        shuffledIndices: _shuffledImageIndices,
        focusAdvanceOrder: _recallOrderedDataIndices(),
        initialSelections: _imageAnswerOrder,
        isResultsMode: _isChecking,
        memorizationElapsedMs: _memorizationElapsedMs,
        recallElapsedMs: _recallElapsedMs,
        xpEarned: _xpEarnedLast,
        onElementStatsTap: _isChecking ? _showElementStatsSheet : null,
        onCompleted: (selections) async {
          if (_isChecking) {
            _exitResultsScreen();
            return;
          }
          setState(() => _imageAnswerOrder = selections);
          await _completeSessionCheck();
        },
      );
    }

    if (_selectedMode == TrainingMode.standard && _isMatrixMode) {
      return MnemonicMatrixRecallScreen(
        correctData: _data,
        isResultsMode: _isChecking,
        initialSelections:
            _controllers.map((c) => c.text).toList(growable: false),
        onCompleted: (selections) async {
          if (_isChecking) {
            _exitResultsScreen();
            return;
          }
          for (int i = 0; i < selections.length; i++) {
            _controllers[i].text = selections[i] ?? "";
          }
          await _completeSessionCheck();
        },
      );
    }

    if (_selectedMode == TrainingMode.cards) {
      return MnemonicCardRecallScreen(
        correctData: _data,
        isResultsMode: _isChecking,
        initialSelections:
            _controllers.map((c) => c.text).toList(growable: false),
        memorizationElapsedMs: _memorizationElapsedMs,
        recallElapsedMs: _recallElapsedMs,
        xpEarned: _xpEarnedLast,
        onCompleted: (selections) async {
          if (_isChecking) {
            _exitResultsScreen();
            return;
          }
          for (int i = 0; i < selections.length; i++) {
            _controllers[i].text = selections[i] ?? "";
          }
          await _completeSessionCheck();
        },
      );
    }

    if (_selectedMode == TrainingMode.faces) {
      return MnemonicFaceRecallScreen(
        rawPeopleData: _data,
        shuffledIndices: _shuffledFaceIndices,
        initialAnswers: _controllers.map((c) => c.text).toList(growable: false),
        isResultsMode: _isChecking,
        memorizationElapsedMs: _memorizationElapsedMs,
        recallElapsedMs: _recallElapsedMs,
        xpEarned: _xpEarnedLast,
        onCompleted: (answers) async {
          if (_isChecking) {
            _exitResultsScreen();
            return;
          }
          for (int i = 0; i < answers.length && i < _controllers.length; i++) {
            _controllers[i].text = answers[i] ?? '';
          }
          await _completeSessionCheck();
        },
      );
    }

    return Column(
      key: key,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!_isChecking)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                formattedRecallTime,
                style: TextStyle(
                  color: Color.lerp(onSurface, appAccentColor.value, 0.3)!
                      .withOpacity(0.45),
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 4,
                ),
              ),
              if (!_isDuelRun) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _showAttachedLociPreviewSheet,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: appPalette.value.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: appPalette.value.border.withOpacity(0.35)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.alt_route_rounded,
                            size: 13,
                            color: appAccentColor.value.withOpacity(0.92)),
                        const SizedBox(width: 4),
                        Text(
                          'Loci',
                          style: TextStyle(
                              color: onSurface.withOpacity(0.62),
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        if (_isChecking)
          (_selectedMode == TrainingMode.images ||
                  _selectedMode == TrainingMode.cards ||
                  _selectedMode == TrainingMode.faces)
              ? _buildCompactStatsLauncher()
              : _buildResultsSummary(),
        const SizedBox(height: 40),
        Flexible(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ValueListenableBuilder<NumberDisplayDirection>(
              valueListenable: numberDisplayDirection,
              builder: (context, _, __) {
                final recallOrder = _recallOrderedDataIndices();
                return Wrap(
                  spacing: 12,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    for (int slot = 0; slot < recallOrder.length; slot++)
                      _buildSelectionBox(
                        recallOrder[slot],
                        recallOrder: recallOrder,
                        recallSlot: slot,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 40),
        _buildActionButton(
            _isChecking ? AppTexts.get('exit') : AppTexts.get('check'),
            () async {
          if (_isChecking) {
            if (!_isDuelRun) {
              _exitResultsScreen();
            }
          } else {
            await _completeSessionCheck();
          }
        }),
        const SizedBox(height: 20),
      ],
    );
  }

  int _calculateCorrectCount() {
    int correctCount = 0;
    if (_selectedMode == TrainingMode.images) {
      for (int i = 0; i < _data.length; i++) {
        if (_imageAnswerOrder[i] == i + 1) correctCount++;
      }
    } else if (_selectedMode == TrainingMode.faces) {
      for (int i = 0; i < _data.length; i++) {
        final expected = _normalizePersonName(_decodeFaceEntry(_data[i]).name);
        final answer = _normalizePersonName(_controllers[i].text);
        if (answer.isNotEmpty && answer == expected) correctCount++;
      }
    } else {
      for (int i = 0; i < _data.length; i++) {
        if (_controllers[i].text.trim().toLowerCase() ==
            _data[i].toLowerCase()) {
          correctCount++;
        }
      }
    }
    return correctCount;
  }

  Widget _buildCompactStatsLauncher() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final int correctCount = _calculateCorrectCount();
    final int n = _data.length;
    final double percentage = n == 0 ? 0 : (correctCount / n) * 100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: const BoxConstraints(maxWidth: 360),
      decoration: BoxDecoration(
        color: appPalette.value.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appPalette.value.border.withOpacity(0.45)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${percentage.toStringAsFixed(0)}% · $correctCount/$n',
              style: TextStyle(
                color: appAccentColor.value,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _showVisualModeStatsSheet,
            style: TextButton.styleFrom(
              foregroundColor: appAccentColor.value,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.bar_chart_rounded, size: 16),
            label: Text(
              AppTexts.get('statistics'),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.error_outline_rounded,
              size: 14, color: onSurface.withOpacity(0.35)),
        ],
      ),
    );
  }

  void _showVisualModeStatsSheet() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: BoxDecoration(
                color: appPalette.value.background,
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: appPalette.value.border.withOpacity(0.4)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Center(child: _buildResultsSummary()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildElementStatsButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Transform.translate(
          offset: Offset(0, 18 * (1 - t)),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showElementStatsSheet,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedScale(
            scale: _pulseElementStatsButton ? 1.12 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _pulseElementStatsButton
                    ? appAccentColor.value.withOpacity(0.16)
                    : appPalette.value.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: appAccentColor.value
                      .withOpacity(_pulseElementStatsButton ? 0.9 : 0.38),
                  width: _pulseElementStatsButton ? 1.6 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: appAccentColor.value
                        .withOpacity(_pulseElementStatsButton ? 0.32 : 0.12),
                    blurRadius: _pulseElementStatsButton ? 22 : 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(Icons.query_stats_rounded,
                  color: appAccentColor.value, size: 24),
            ),
          ),
        ),
      ),
    );
  }

  void _showElementStatsSheet() {
    uiTapClick(UiClickSound.soft);
    final scrollController = ScrollController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (sheetContext) {
        return ValueListenableBuilder<AppPalette>(
          valueListenable: appPalette,
          builder: (context, palette, _) {
            return ValueListenableBuilder<Color>(
              valueListenable: appAccentColor,
              builder: (context, accent, __) {
                final height = MediaQuery.of(context).size.height * 0.82;
                final onSurface = Theme.of(context).colorScheme.onSurface;
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    child: Container(
                      height: height,
                      decoration: BoxDecoration(
                        color: palette.background,
                        borderRadius: BorderRadius.circular(28),
                        border:
                            Border.all(color: palette.border.withOpacity(0.45)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            Container(
                              width: 38,
                              height: 4,
                              decoration: BoxDecoration(
                                color: onSurface.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 18, 20, 12),
                              child: Column(
                                children: [
                                  Icon(Icons.timeline_rounded,
                                      color: accent, size: 30),
                                  const SizedBox(height: 10),
                                  Text(
                                    AppTexts.get('element_stats_title'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: onSurface.withOpacity(0.92),
                                      fontSize: 22,
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppTexts.get('element_stats_subtitle'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: onSurface.withOpacity(0.48),
                                      fontSize: 12,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildElementStatsSummary(onSurface, accent),
                                  const SizedBox(height: 16),
                                  _buildElementStatsBars(onSurface, accent,
                                      (index) {
                                    _scrollToElementStat(
                                        scrollController, index);
                                  }),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                controller: scrollController,
                                physics: const BouncingScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 18),
                                itemCount: _data.length,
                                itemBuilder: (context, index) =>
                                    _buildElementStatCard(
                                  index,
                                  onSurface,
                                  accent,
                                  onLocusTap: (locus) =>
                                      _openLociRoutesForLocus(locus,
                                          popStatsSheet: true),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildElementStatsSummary(Color onSurface, Color accent) {
    final totalMs = _elementStatsTotalMs();
    final avgMs = _data.isEmpty ? 0 : (totalMs / _data.length).round();
    return Row(
      children: [
        Expanded(
          child: _buildElementStatsMiniTile(
            icon: Icons.functions_rounded,
            label: AppTexts.get('element_stats_total'),
            value: _formatElementTime(totalMs),
            onSurface: onSurface,
            accent: accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildElementStatsMiniTile(
            icon: Icons.speed_rounded,
            label: AppTexts.get('element_stats_avg'),
            value: _formatElementTime(avgMs),
            onSurface: onSurface,
            accent: accent,
          ),
        ),
      ],
    );
  }

  Widget _buildElementStatsMiniTile({
    required IconData icon,
    required String label,
    required String value,
    required Color onSurface,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: appPalette.value.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appPalette.value.border.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent.withOpacity(0.9), size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: onSurface.withOpacity(0.42), fontSize: 10)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        color: onSurface.withOpacity(0.88),
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElementStatsBars(
      Color onSurface, Color accent, ValueChanged<int> onBarTap) {
    final times = _elementTimes();
    final maxMs = times.isEmpty ? 1 : max(1, times.reduce(max));
    final visible = times.take(36).toList(growable: false);
    return Container(
      height: 90,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: appPalette.value.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: appPalette.value.border.withOpacity(0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(visible.length, (index) {
          final h = (visible[index] / maxMs).clamp(0.08, 1.0);
          final isCorrect = _isElementCorrect(index);
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                uiTapClick(UiClickSound.soft);
                onBarTap(index);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: h),
                  duration:
                      Duration(milliseconds: 360 + (index * 12).clamp(0, 260)),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) {
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 64 * v,
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? accent.withOpacity(0.72)
                              : const Color(0xFFFF3B30).withOpacity(0.78),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _scrollToElementStat(ScrollController controller, int index) {
    if (!controller.hasClients) return;
    final target =
        (index * 116.0).clamp(0.0, controller.position.maxScrollExtent);
    controller.animateTo(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildElementStatCard(
    int index,
    Color onSurface,
    Color accent, {
    void Function(String locusName)? onLocusTap,
  }) {
    final correct = _isElementCorrect(index);
    final correctValue = _correctValueForIndex(index);
    final answerValue = _answerValueForIndex(index);
    final time = _formatElementTime(_elementTimeForIndex(index));
    final attachedLocus = _attachedLocusForIndex(index);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + (index * 16).clamp(0, 300)),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Transform.translate(
          offset: Offset(0, 12 * (1 - t)),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: appPalette.value.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: correct
                ? appPalette.value.border.withOpacity(0.34)
                : const Color(0xFFFF3B30).withOpacity(0.45),
          ),
        ),
        child: Row(
          children: [
            _buildElementPreview(index, correct, onSurface, accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: onSurface.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '#${index + 1}',
                          style: TextStyle(
                              color: onSurface.withOpacity(0.56),
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.timer_outlined,
                          size: 14, color: accent.withOpacity(0.9)),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: TextStyle(
                            color: accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      Icon(
                        correct
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        color: correct
                            ? const Color(0xFF00E676)
                            : const Color(0xFFFF3B30),
                        size: 17,
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    '${AppTexts.get('element_stats_value')}: $correctValue',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: onSurface.withOpacity(0.86),
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  if (attachedLocus.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onLocusTap == null
                            ? null
                            : () => onLocusTap(attachedLocus),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(Icons.alt_route_rounded,
                                  size: 13,
                                  color:
                                      appAccentColor.value.withOpacity(0.86)),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  '${_lociText(ru: 'Loci', en: 'Loci', de: 'Loci')}: $attachedLocus',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: onLocusTap == null
                                        ? onSurface.withOpacity(0.62)
                                        : appAccentColor.value
                                            .withOpacity(0.92),
                                    fontSize: 11,
                                    fontWeight: onLocusTap == null
                                        ? FontWeight.w400
                                        : FontWeight.w600,
                                    decoration: onLocusTap == null
                                        ? null
                                        : TextDecoration.underline,
                                    decorationColor:
                                        appAccentColor.value.withOpacity(0.45),
                                  ),
                                ),
                              ),
                              if (onLocusTap != null)
                                Icon(Icons.open_in_new_rounded,
                                    size: 12,
                                    color:
                                        appAccentColor.value.withOpacity(0.7)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (!correct) ...[
                    const SizedBox(height: 5),
                    Text(
                      '${AppTexts.get('element_stats_your_answer')}: $answerValue',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: const Color(0xFFFF3B30).withOpacity(0.9),
                          fontSize: 12),
                    ),
                    Text(
                      '${AppTexts.get('element_stats_correct_answer')}: $correctValue',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: onSurface.withOpacity(0.48), fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElementPreview(
      int index, bool correct, Color onSurface, Color accent) {
    if (_selectedMode == TrainingMode.images) {
      return Container(
        width: 58,
        height: 58,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: appPalette.value.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: correct
                  ? accent.withOpacity(0.25)
                  : const Color(0xFFFF3B30).withOpacity(0.45)),
        ),
        child: Image.network(
          _data[index],
          fit: BoxFit.cover,
          cacheWidth: 180,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.image_outlined, color: onSurface.withOpacity(0.24)),
        ),
      );
    }

    if (_selectedMode == TrainingMode.faces) {
      return Container(
        width: 58,
        height: 58,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: appPalette.value.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: correct
                  ? accent.withOpacity(0.25)
                  : const Color(0xFFFF3B30).withOpacity(0.45)),
        ),
        child: Image(image: _faceImageProviderAt(index), fit: BoxFit.cover),
      );
    }

    final text = _selectedMode == TrainingMode.cards
        ? _formatCardValue(_data[index])
        : _data[index];
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: correct
            ? accent.withOpacity(0.08)
            : const Color(0xFFFF3B30).withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: correct
                ? accent.withOpacity(0.25)
                : const Color(0xFFFF3B30).withOpacity(0.45)),
      ),
      child: Center(
        child: Text(
          text.toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: onSurface.withOpacity(0.9),
            fontSize: _selectedMode == TrainingMode.words ? 11 : 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  List<int> _elementTimes() {
    if (_memorizationMsByElement.length == _data.length &&
        _memorizationMsByElement.any((ms) => ms > 0)) {
      return _memorizationMsByElement;
    }
    final avg =
        _data.isEmpty ? 0 : (_memorizationElapsedMs / _data.length).round();
    return List<int>.filled(_data.length, avg);
  }

  int _elementTimeForIndex(int index) {
    if (index < 0 || index >= _data.length) return 0;
    return _elementTimes()[index];
  }

  int _elementStatsTotalMs() {
    final times = _elementTimes();
    if (times.isEmpty) return _memorizationElapsedMs;
    return times.fold<int>(0, (sum, ms) => sum + ms);
  }

  String _formatElementTime(int ms) {
    final seconds = ms / 1000.0;
    if (seconds < 10)
      return '${seconds.toStringAsFixed(2)} ${AppTexts.get('seconds_short')}';
    if (seconds < 60)
      return '${seconds.toStringAsFixed(1)} ${AppTexts.get('seconds_short')}';
    final minutes = seconds ~/ 60;
    final rest = (seconds % 60).round().toString().padLeft(2, '0');
    return '$minutes:$rest ${AppTexts.get('seconds_short')}';
  }

  bool _isElementCorrect(int index) {
    if (index < 0 || index >= _data.length) return false;
    if (_selectedMode == TrainingMode.images) {
      return index < _imageAnswerOrder.length &&
          _imageAnswerOrder[index] == index + 1;
    }
    if (_selectedMode == TrainingMode.faces) {
      final answer = index < _controllers.length
          ? _normalizePersonName(_controllers[index].text)
          : '';
      final expected =
          _normalizePersonName(_decodeFaceEntry(_data[index]).name);
      return answer.isNotEmpty && answer == expected;
    }
    final answer = index < _controllers.length
        ? _controllers[index].text.trim().toLowerCase()
        : '';
    return answer == _data[index].toLowerCase();
  }

  String _correctValueForIndex(int index) {
    if (index < 0 || index >= _data.length) return '—';
    if (_selectedMode == TrainingMode.images) {
      return AppTexts.get('element_stats_image_value',
          params: {'n': '${index + 1}'});
    }
    if (_selectedMode == TrainingMode.faces) {
      return _decodeFaceEntry(_data[index]).name;
    }
    if (_selectedMode == TrainingMode.cards) {
      return _formatCardValue(_data[index]);
    }
    return _data[index];
  }

  String _answerValueForIndex(int index) {
    if (index < 0 || index >= _data.length) return '—';
    if (_selectedMode == TrainingMode.images) {
      final slot =
          index < _imageAnswerOrder.length ? _imageAnswerOrder[index] : null;
      return slot == null
          ? '—'
          : AppTexts.get('element_stats_slot_value', params: {'n': '$slot'});
    }
    if (index >= _controllers.length) return '—';
    final raw = _controllers[index].text.trim();
    if (raw.isEmpty) return '—';
    if (_selectedMode == TrainingMode.cards) return _formatCardValue(raw);
    return raw;
  }

  String _formatCardValue(String code) {
    if (code.length < 2) return code.toUpperCase();
    final suit = code[0].toLowerCase();
    final rank = code.substring(1).toUpperCase();
    final suitChar = suit == 'h'
        ? '♥'
        : suit == 'd'
            ? '♦'
            : suit == 'c'
                ? '♣'
                : suit == 's'
                    ? '♠'
                    : suit.toUpperCase();
    return '$rank$suitChar';
  }

  Widget _buildResultsSummary() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isRu = appLanguage.value == AppLanguage.ru;
    final isDe = appLanguage.value == AppLanguage.de;
    final int correctCount = _calculateCorrectCount();
    final double percentage =
        (_data.isEmpty) ? 0 : (correctCount / _data.length) * 100;
    final int n = _data.length;
    final int cappedMemMs =
        (_activeSessionMemCapSec > 0 && _memorizationElapsedMs > 0)
            ? min(_memorizationElapsedMs, _activeSessionMemCapSec * 1000)
            : _memorizationElapsedMs;
    final double secPerEl = n <= 0 ? 0 : (cappedMemMs / 1000.0) / n;
    final double totalMemSec = cappedMemMs / 1000.0;
    final isPerfectMem = n >= 10;

    // Detailed Stats for Images and Cards (as in Numbers/Words)
    final bool showDetailedStats = _selectedMode == TrainingMode.images ||
        _selectedMode == TrainingMode.cards ||
        _selectedMode == TrainingMode.faces;
    String standardNumbersSummary() {
      int correctDigits = 0;
      int totalDigits = 0;
      for (int i = 0; i < _data.length; i++) {
        final expected = _data[i];
        final digitsInExpected = RegExp(r'\d').allMatches(expected).length;
        totalDigits += digitsInExpected;
        final answer =
            i < _controllers.length ? _controllers[i].text.trim() : '';
        if (answer.isNotEmpty &&
            answer.toLowerCase() == expected.toLowerCase()) {
          correctDigits += digitsInExpected;
        }
      }
      if (isRu) {
        return 'Чисел верно: $correctCount из $n (цифр: $correctDigits из $totalDigits)';
      }
      if (isDe) {
        return 'Zahlen korrekt: $correctCount von $n (Ziffern: $correctDigits von $totalDigits)';
      }
      return 'Numbers correct: $correctCount / $n (digits: $correctDigits / $totalDigits)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      constraints: const BoxConstraints(maxWidth: 360),
      decoration: BoxDecoration(
        color: appPalette.value.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appPalette.value.border.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPerfectMem) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: appAccentColor.value.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: appAccentColor.value.withOpacity(0.35)),
              ),
              child: Text(
                'Perfect',
                style: TextStyle(
                  color: appAccentColor.value,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text('${percentage.toStringAsFixed(0)}%',
              style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w100,
                  color: appAccentColor.value)),
          const SizedBox(height: 6),
          Text(
            _selectedMode == TrainingMode.standard
                ? standardNumbersSummary()
                : '$correctCount / $n ${AppTexts.plural(n, 'plural_element')}',
            style: TextStyle(
              color: onSurface.withOpacity(0.55),
              fontSize: _selectedMode == TrainingMode.standard ? 16 : 13,
              fontWeight: _selectedMode == TrainingMode.standard
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
          if (showDetailedStats) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: onSurface.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildStatRow(
                      onSurface,
                      AppTexts.get('speed_label'),
                      "${secPerEl.toStringAsFixed(2)} ${AppTexts.get('seconds_short')}/${AppTexts.get('per_element')}",
                      Icons.speed_rounded),
                  const SizedBox(height: 8),
                  _buildStatRow(
                      onSurface,
                      AppTexts.get('memorization_label'),
                      "${totalMemSec.toStringAsFixed(1)} ${AppTexts.get('seconds_short')}",
                      Icons.psychology_rounded),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            Text(
              n > 0
                  ? isRu
                      ? '${secPerEl.toStringAsFixed(2)} ${AppTexts.get('seconds_short')} на элемент (${AppTexts.get('memorization_label').toLowerCase()})'
                      : isDe
                          ? '${secPerEl.toStringAsFixed(2)} ${AppTexts.get('seconds_short')} pro Element (${AppTexts.get('memorization_label')})'
                          : '${secPerEl.toStringAsFixed(2)} ${AppTexts.get('seconds_short')} per element (${AppTexts.get('memorization_label').toLowerCase()})'
                  : '—',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: appAccentColor.value.withOpacity(0.95),
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              isRu
                  ? 'Всего на ${AppTexts.get('memorization_label').toLowerCase()}: ${totalMemSec.toStringAsFixed(2)} ${AppTexts.get('seconds_short')}'
                  : isDe
                      ? '${AppTexts.get('memorization_label')}: ${totalMemSec.toStringAsFixed(2)} ${AppTexts.get('seconds_short')} gesamt'
                      : 'Total ${AppTexts.get('memorization_label').toLowerCase()}: ${totalMemSec.toStringAsFixed(2)} ${AppTexts.get('seconds_short')}',
              style:
                  TextStyle(color: onSurface.withOpacity(0.45), fontSize: 11),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            _resultComparisonLine,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: onSurface.withOpacity(0.62), fontSize: 12, height: 1.35),
          ),
          if (_streakLine.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_fire_department_rounded,
                    size: 16, color: appAccentColor.value.withOpacity(0.85)),
                const SizedBox(width: 6),
                Text(
                  _streakLine,
                  style: TextStyle(
                      color: onSurface.withOpacity(0.5), fontSize: 11),
                ),
              ],
            ),
          ],
          if (_xpEarnedLast > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: appAccentColor.value.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: appAccentColor.value.withOpacity(0.22)),
              ),
              child: Text(
                '+ $_xpEarnedLast XP',
                style: TextStyle(
                  color: appAccentColor.value,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectionBox(int dataIndex,
      {required List<int> recallOrder, required int recallSlot}) {
    bool isCorrect = _isChecking &&
        _controllers[dataIndex].text.trim().toLowerCase() ==
            _data[dataIndex].toLowerCase();
    bool isWrong = _isChecking &&
        _controllers[dataIndex].text.trim().toLowerCase() !=
            _data[dataIndex].toLowerCase();
    int autoNextLength =
        (_selectedMode == TrainingMode.standard && !_isMatrixMode)
            ? _effectiveStandardDigits
            : (_selectedMode == TrainingMode.binary ? 3 : 0);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: appPalette.value.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: onSurface.withOpacity(0.12)),
          ),
          child: Text(
            '${recallSlot + 1}',
            style: TextStyle(
              fontSize: 9.5,
              color: onSurface.withOpacity(0.68),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 5),
        ValueListenableBuilder<Color>(
            valueListenable: appAccentColor,
            builder: (context, accentColor, _) {
              Color borderColor = onSurface.withOpacity(0.05);
              if (isCorrect) {
                borderColor = const Color(0xFF00E676);
              } else if (isWrong)
                borderColor = const Color(0xFFFF1744);
              else if (_focusNodes[dataIndex].hasFocus)
                borderColor = accentColor;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 70),
                width: _selectedMode == TrainingMode.words ? 110 : 70,
                height: 50,
                decoration: BoxDecoration(
                  color: appPalette.value.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: _isChecking
                      ? null
                      : (_) {
                          final node = _focusNodes[dataIndex];
                          if (!node.hasFocus) {
                            node.requestFocus();
                            if (mounted) setState(() {});
                          }
                          SystemChannels.textInput
                              .invokeMethod('TextInput.show');
                        },
                  onTap: _isChecking
                      ? null
                      : () {
                          final node = _focusNodes[dataIndex];
                          if (!node.hasFocus) {
                            node.requestFocus();
                            if (mounted) setState(() {});
                          }
                          SystemChannels.textInput
                              .invokeMethod('TextInput.show');
                        },
                  child: Center(
                    child: TextField(
                      controller: _controllers[dataIndex],
                      focusNode: _focusNodes[dataIndex],
                      textAlign: TextAlign.center,
                      showCursor: false,
                      readOnly: _isChecking, // Блокируем ввод после проверки
                      textCapitalization: _selectedMode == TrainingMode.words
                          ? TextCapitalization.words
                          : TextCapitalization.none,
                      keyboardType: _selectedMode == TrainingMode.words
                          ? TextInputType.text
                          : TextInputType.number,
                      maxLength: (_selectedMode == TrainingMode.standard &&
                              !_isMatrixMode)
                          ? _effectiveStandardDigits
                          : (_selectedMode == TrainingMode.binary ? 3 : null),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color.lerp(onSurface, accentColor, 0.2),
                      ),
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          counterText: "",
                          isCollapsed: true),
                      onTap: () {
                        final node = _focusNodes[dataIndex];
                        if (!node.hasFocus) {
                          node.requestFocus();
                          if (mounted) setState(() {});
                        }
                        SystemChannels.textInput.invokeMethod('TextInput.show');
                      },
                      onChanged: (value) {
                        uiTapClick(UiClickSound.soft);
                        if (autoNextLength > 0 &&
                            value.length >= autoNextLength &&
                            recallSlot < recallOrder.length - 1) {
                          _focusNodes[recallOrder[recallSlot + 1]]
                              .requestFocus();
                        }
                      },
                    ),
                  ),
                ),
              );
            }),
        if (isWrong)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_data[dataIndex],
                style: const TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _buildActionButton(String text, VoidCallback onTap,
      {double width = 200}) {
    return ValueListenableBuilder<Color>(
        valueListenable: appAccentColor,
        builder: (context, accentColor, _) {
          return SizedBox(
            width: width,
            height: 56,
            child: Material(
              color: appPalette.value.surface,
              borderRadius: BorderRadius.circular(28),
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () {
                  uiTapClick(UiClickSound.bright);
                  onTap();
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: accentColor.withOpacity(0.4)),
                  ),
                  child: Center(
                    child: Text(
                      text,
                      style: TextStyle(
                        letterSpacing: 3,
                        fontSize: 12,
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        });
  }

  Widget _buildPreloadView({Key? key}) {
    final progress = _totalImagesToPreload == 0
        ? 0.0
        : _preloadedImageCount / _totalImagesToPreload;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Material(
      key: key,
      color: Colors.black.withOpacity(0.78),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: 340,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              decoration: BoxDecoration(
                color: appPalette.value.surface,
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: appAccentColor.value.withOpacity(0.45)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.45),
                    blurRadius: 22,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_download_outlined,
                      color: appAccentColor.value, size: 36),
                  const SizedBox(height: 14),
                  Text(
                    AppTexts.get('preparing_training'),
                    style: TextStyle(
                      color: appAccentColor.value,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppTexts.get('loading_images_desc'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: onSurface.withOpacity(0.72),
                        fontSize: 13,
                        height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: onSurface.withOpacity(0.12),
                      color: appAccentColor.value,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppTexts.get('loading_progress', params: {
                      'current': _preloadedImageCount.toString(),
                      'total': _totalImagesToPreload.toString(),
                    }),
                    style: TextStyle(
                        color: onSurface.withOpacity(0.72), fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _clearImageSelections() {
    if (_selectedMode != TrainingMode.images) return;
    setState(() {
      _imageAnswerOrder = List<int?>.filled(_data.length, null);
      _activeImageSlot = 1;
      _slotController.text = '1';
    });
  }

  Widget _buildStatRow(
      Color onSurface, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: appAccentColor.value.withOpacity(0.9)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: onSurface.withOpacity(0.52), fontSize: 12),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: onSurface.withOpacity(0.88),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
