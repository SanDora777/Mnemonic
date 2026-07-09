part of 'package:flutter_application_1/recovered_app.dart';

enum _PiPhase { setup, memorize, recall, done }

enum _PiSetupTab { training, reading }

class PiTrainerScreen extends StatefulWidget {
  const PiTrainerScreen({super.key});

  @override
  State<PiTrainerScreen> createState() => _PiTrainerScreenState();
}

class _PiTrainerScreenState extends State<PiTrainerScreen> {
  static const String _kMasteredCount = 'pi_trainer_mastered_count';
  static const String _kStartOffset = 'pi_trainer_start_offset';
  static const String _kStandardDigits = 'pi_trainer_standard_digits_v1';
  static const String _kUseCodes = 'pi_trainer_use_number_codes_v1';
  static const String _kBestStreak = 'pi_trainer_best_streak';
  static const String _kLociRouteIndex = 'pi_trainer_loci_route_index';
  static const String _kLociStartIndex = 'pi_trainer_loci_start_index';

  final TextEditingController _totalCountController = TextEditingController();
  final TextEditingController _chunkSizeController = TextEditingController(text: '1');
  final TextEditingController _startOffsetController = TextEditingController(text: '1');
  Timer? _counterHoldTimer;

  _PiPhase _phase = _PiPhase.setup;
  bool _loading = true;
  String? _loadError;

  int _totalAvailable = 0;
  int _masteredCount = 0;
  int _startOffset = 0;
  int _standardDigits = 2;
  bool _useNumberCodes = false;
  Map<String, String> _numberCodes = const {};
  int _codesFilledCount = 0;

  int _currentChunkIndex = 0;
  int _memorizationElapsedMs = 0;
  int _recallElapsedMs = 0;
  int _correctElements = 0;
  int? _firstWrongElementIndex;
  bool _isChecking = false;
  List<bool> _correctnessPattern = const [];
  Timer? _ticker;
  DateTime? _phaseStartedAt;

  List<String> _sessionElements = const [];
  String _sessionDigits = '';
  List<TextEditingController> _recallControllers = const [];
  List<FocusNode> _recallFocusNodes = const [];
  final ScrollController _memorizerScrollController = ScrollController();

  final List<_LociRoute> _trainingLociRoutes = <_LociRoute>[];
  int _selectedTrainingLociRoute = -1;
  int _lociStartIndex = 0;
  List<String> _attachedLociByElement = <String>[];

  _PiSetupTab _setupTab = _PiSetupTab.training;
  List<PiCheckpoint> _checkpoints = const <PiCheckpoint>[];
  bool _showLociOverlay = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _counterHoldTimer?.cancel();
    _totalCountController.dispose();
    _chunkSizeController.dispose();
    _startOffsetController.dispose();
    _disposeRecallInputs();
    _memorizerScrollController.dispose();
    super.dispose();
  }

  void _disposeRecallInputs() {
    for (final c in _recallControllers) {
      c.dispose();
    }
    for (final n in _recallFocusNodes) {
      n.dispose();
    }
    _recallControllers = const [];
    _recallFocusNodes = const [];
  }

  NumberCodesService? get _codesService {
    switch (_standardDigits) {
      case 2:
        return NumberCodesService.pair99;
      case 3:
        return NumberCodesService.triple999;
      default:
        return null;
    }
  }

  int get _chunkSize =>
      (int.tryParse(_chunkSizeController.text) ?? 1).clamp(1, maxChunkForTrainingMode(TrainingMode.standard));

  int get _elementCount =>
      (int.tryParse(_totalCountController.text) ?? 4).clamp(1, _maxElementCount);

  int get _maxElementCount {
    final remaining = max(0, _totalAvailable - _startOffset);
    return max(1, remaining ~/ _standardDigits);
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      await PiDigitsService.instance.ensureLoaded();
      final prefs = await SharedPreferences.getInstance();
      final total = PiDigitsService.instance.totalDigits;
      final mastered = (prefs.getInt(_kMasteredCount) ?? 0).clamp(0, total);
      final savedStart = (prefs.getInt(_kStartOffset) ?? mastered).clamp(0, total);
      final digits = (prefs.getInt(_kStandardDigits) ?? 2).clamp(1, 3);
      final useCodes = prefs.getBool(_kUseCodes) ?? false;
      final savedTotal = (prefs.getInt('$_kTrainingTotalCountPerModePrefsPrefix${TrainingMode.standard.name}') ?? 20)
          .clamp(1, kTrainerElementCountMax);
      final savedChunk = (prefs.getInt('$_kTrainingChunkCountPerModePrefsPrefix${TrainingMode.standard.name}') ?? 1)
          .clamp(1, maxChunkForTrainingMode(TrainingMode.standard));

      await _reloadNumberCodes(digits);
      _selectedTrainingLociRoute = prefs.getInt(_kLociRouteIndex) ?? -1;
      _lociStartIndex = prefs.getInt(_kLociStartIndex) ?? 0;
      await _loadTrainingLociRoutes();
      _checkpoints = await PiTrainerPersistence.loadCheckpoints();
      _showLociOverlay = await PiTrainerPersistence.loadShowLociOverlay();

      if (!mounted) return;
      setState(() {
        _totalAvailable = total;
        _masteredCount = mastered;
        _startOffset = savedStart;
        _startOffsetController.text = '${savedStart + 1}';
        _standardDigits = digits;
        _useNumberCodes = useCodes && digits > 1 && _codesFilledCount > 0;
        _totalCountController.text = '$savedTotal';
        _chunkSizeController.text = '$savedChunk';
        _loading = false;
      });
      _normalizeStartOffset(persist: false);
      _normalizeElementCount(persist: false);
      _normalizeChunkCount(persist: false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = '${_t(const {
          AppLanguage.ru: 'Не удалось загрузить цифры π.',
          AppLanguage.en: 'Could not load pi digits.',
          AppLanguage.de: 'Pi-Ziffern konnten nicht geladen werden.',
        })}\n$e';
      });
    }
  }

  Future<void> _reloadNumberCodes(int digits) async {
    final svc = digits == 2
        ? NumberCodesService.pair99
        : digits == 3
            ? NumberCodesService.triple999
            : null;
    if (svc == null) {
      _numberCodes = const {};
      _codesFilledCount = 0;
      return;
    }
    final map = await svc.loadImages(appLanguage.value);
    _numberCodes = map;
    _codesFilledCount = map.values.where((v) => v.trim().isNotEmpty).length;
  }

  Future<void> _persistSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kStartOffset, _startOffset);
    await prefs.setInt(_kStandardDigits, _standardDigits);
    await prefs.setBool(_kUseCodes, _useNumberCodes);
    await prefs.setInt(_kLociRouteIndex, _selectedTrainingLociRoute);
    await prefs.setInt(_kLociStartIndex, _lociStartIndex);
    await prefs.setInt(
      '$_kTrainingTotalCountPerModePrefsPrefix${TrainingMode.standard.name}',
      _elementCount,
    );
    await prefs.setInt(
      '$_kTrainingChunkCountPerModePrefsPrefix${TrainingMode.standard.name}',
      _chunkSize,
    );
  }

  Future<void> _setMasteredCount(int value) async {
    final next = value.clamp(0, _totalAvailable);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kMasteredCount, next);
    if (!mounted) return;
    setState(() {
      _masteredCount = next;
      if (_startOffset < next) {
        _startOffset = next;
        _startOffsetController.text = '${next + 1}';
      }
      _normalizeElementCount(persist: false);
    });
    await _persistSetup();
  }

  Future<void> _resetProgress() async {
    await _setMasteredCount(0);
    setState(() {
      _startOffset = 0;
      _startOffsetController.text = '1';
    });
    _normalizeElementCount(persist: false);
    await _persistSetup();
  }

  void _continueFromMastered() {
    setState(() {
      _startOffset = _masteredCount;
      _startOffsetController.text = '${_masteredCount + 1}';
    });
    _normalizeElementCount(persist: false);
    unawaited(_persistSetup());
  }

  String _checkpointDigitLabel(int displayDigit) {
    switch (appLanguage.value) {
      case AppLanguage.en:
        return 'Digit #$displayDigit';
      case AppLanguage.de:
        return 'Ziffer Nr. $displayDigit';
      case AppLanguage.ru:
        return 'Цифра №$displayDigit';
    }
  }

  Future<void> _saveCheckpointAtDigit(int digitIndex, {required String label}) async {
    final safeIndex = digitIndex.clamp(0, max(0, _totalAvailable)).toInt();
    final trimmed = label.trim();
    final existing = _checkpoints.indexWhere((c) => c.digitIndex == safeIndex);
    final next = List<PiCheckpoint>.from(_checkpoints);
    if (existing >= 0) {
      next[existing] = next[existing].copyWith(
        label: trimmed.isEmpty ? next[existing].label : trimmed,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      );
    } else {
      next.add(
        PiCheckpoint(
          id: 'cp_${safeIndex}_${DateTime.now().millisecondsSinceEpoch}',
          label: trimmed.isEmpty ? _checkpointDigitLabel(safeIndex + 1) : trimmed,
          digitIndex: safeIndex,
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
    await PiTrainerPersistence.saveCheckpoints(next);
    if (!mounted) return;
    setState(() => _checkpoints = next);
  }

  Future<void> _promptSaveCheckpoint() async {
    final label = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(
          text: _checkpointDigitLabel(_startOffset + 1),
        );
        return AlertDialog(
          backgroundColor: appPalette.value.surface,
          title: Text(_t(const {
            AppLanguage.ru: 'Сохранить чекпоинт',
            AppLanguage.en: 'Save checkpoint',
            AppLanguage.de: 'Checkpoint speichern',
          })),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: _t(const {
                AppLanguage.ru: 'Название (необязательно)',
                AppLanguage.en: 'Label (optional)',
                AppLanguage.de: 'Name (optional)',
              }),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_t(const {
                AppLanguage.ru: 'Отмена',
                AppLanguage.en: 'Cancel',
                AppLanguage.de: 'Abbrechen',
              })),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(_t(const {
                AppLanguage.ru: 'Сохранить',
                AppLanguage.en: 'Save',
                AppLanguage.de: 'Speichern',
              })),
            ),
          ],
        );
      },
    );
    if (label == null) return;
    await _saveCheckpointAtDigit(_startOffset, label: label);
  }

  void _jumpToCheckpoint(PiCheckpoint checkpoint) {
    uiTapClick(UiClickSound.soft);
    setState(() {
      _startOffset = checkpoint.digitIndex.clamp(0, max(0, _totalAvailable));
      _startOffsetController.text = '${_startOffset + 1}';
    });
    _normalizeElementCount(persist: false);
    unawaited(_persistSetup());
    unawaited(PiTrainerPersistence.saveActiveCheckpointId(checkpoint.id));
  }

  Future<void> _deleteCheckpoint(PiCheckpoint checkpoint) async {
    final next = _checkpoints.where((c) => c.id != checkpoint.id).toList(growable: false);
    await PiTrainerPersistence.saveCheckpoints(next);
    if (!mounted) return;
    setState(() => _checkpoints = next);
  }

  Future<void> _toggleLociOverlay() async {
    uiTapClick(UiClickSound.soft);
    final next = !_showLociOverlay;
    setState(() => _showLociOverlay = next);
    await PiTrainerPersistence.saveShowLociOverlay(next);
  }

  List<PiLociMapRow> _lociMapRows() {
    final route = _activeTrainingLociRoute();
    if (route == null || route.loci.isEmpty) return const <PiLociMapRow>[];
    final piRoute = PiLociRoute(name: route.name, loci: List<String>.from(route.loci));
    final elements = _sessionElements.isNotEmpty
        ? _sessionElements
        : _buildSessionElements();
    if (elements.isEmpty) return const <PiLociMapRow>[];
    return PiLociBindingService.buildRouteMapRows(
      route: piRoute,
      startLocusIndex: _lociStartIndex,
      elementCount: elements.length,
      standardDigits: _standardDigits,
      sessionStartDigitIndex: _startOffset,
      sessionElements: elements,
    );
  }

  int? _overlayHighlightElementIndex() {
    if (_phase == _PiPhase.memorize && _sessionElements.isNotEmpty) {
      final chunk = _chunkSize;
      return (_currentChunkIndex * chunk).clamp(0, _sessionElements.length - 1);
    }
    return null;
  }

  int _readingBlockCount() {
    final remaining = max(0, _totalAvailable - _startOffset);
    final maxBlocks = remaining ~/ max(1, _standardDigits);
    return min(480, max(1, maxBlocks));
  }

  List<PiDigitBlock> _readingBlocks() {
    return PiDigitBlock.buildBlocks(
      startOffset: _startOffset,
      blockCount: _readingBlockCount(),
      standardDigits: _standardDigits,
      lociByElement: _attachedLociByElement,
    );
  }

  void _normalizeStartOffset({required bool persist}) {
    if (_startOffsetController.text.isEmpty) return;
    var val = int.tryParse(_startOffsetController.text) ?? 1;
    val = val.clamp(1, max(1, _totalAvailable));
    _startOffset = val - 1;
    if (_startOffsetController.text != '$val') {
      _startOffsetController.text = '$val';
      _startOffsetController.selection =
          TextSelection.collapsed(offset: _startOffsetController.text.length);
    }
    _normalizeElementCount(persist: false);
    if (persist) {
      _rebuildAttachedLoci();
      unawaited(_persistSetup());
    }
  }

  void _changeStartOffset(int delta) {
    uiTapClick(UiClickSound.soft);
    final current = int.tryParse(_startOffsetController.text) ?? 1;
    _startOffsetController.text = '${(current + delta).clamp(1, max(1, _totalAvailable))}';
    _normalizeStartOffset(persist: true);
    setState(() {});
  }

  void _normalizeElementCount({required bool persist}) {
    final maxVal = _maxElementCount;
    var val = int.tryParse(_totalCountController.text) ?? 4;
    val = val.clamp(1, maxVal);
    if (_totalCountController.text != '$val') {
      _totalCountController.text = '$val';
      _totalCountController.selection =
          TextSelection.collapsed(offset: _totalCountController.text.length);
    }
    if (persist) unawaited(_persistSetup());
  }

  void _normalizeChunkCount({required bool persist}) {
    final maxVal = maxChunkForTrainingMode(TrainingMode.standard);
    var val = int.tryParse(_chunkSizeController.text) ?? 1;
    val = val.clamp(1, maxVal);
    if (_chunkSizeController.text != '$val') {
      _chunkSizeController.text = '$val';
      _chunkSizeController.selection =
          TextSelection.collapsed(offset: _chunkSizeController.text.length);
    }
    if (persist) {
      _rebuildAttachedLoci();
      unawaited(_persistSetup());
    }
  }

  void _changeCounter(TextEditingController controller, int delta, {required bool isChunk}) {
    uiTapClick(UiClickSound.soft);
    final current = int.tryParse(controller.text) ?? (isChunk ? 1 : 4);
    controller.text = '${current + delta}';
    if (isChunk) {
      _normalizeChunkCount(persist: true);
    } else {
      _normalizeElementCount(persist: true);
    }
    setState(() {});
  }

  void _startCounterHold(TextEditingController controller, int delta, {required bool isChunk}) {
    _counterHoldTimer?.cancel();
    _counterHoldTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      _changeCounter(controller, delta, isChunk: isChunk);
    });
  }

  void _stopCounterHold() {
    _counterHoldTimer?.cancel();
    _counterHoldTimer = null;
  }

  Future<void> _setStandardDigits(int digits) async {
    uiTapClick(UiClickSound.soft);
    await _reloadNumberCodes(digits);
    if (!mounted) return;
    setState(() {
      _standardDigits = digits;
      if (digits == 1) _useNumberCodes = false;
      if (_useNumberCodes && _codesFilledCount == 0) _useNumberCodes = false;
      _normalizeElementCount(persist: false);
    });
    await _persistSetup();
  }

  Future<void> _setUseNumberCodes(bool value) async {
    if (_standardDigits < 2) return;
    setState(() => _useNumberCodes = value && _codesFilledCount > 0);
    await _persistSetup();
  }

  List<String> _buildSessionElements() {
    return PiSessionBuilder.buildElements(
      startOffset: _startOffset,
      elementCount: _elementCount,
      standardDigits: _standardDigits,
    );
  }

  String _displayForElement(String element) {
    if (!_useNumberCodes || _standardDigits < 2) return element;
    final svc = _codesService;
    if (svc == null) return element;
    final code = int.tryParse(element);
    if (code == null) return element;
    final image = _numberCodes[svc.formatCode(code)];
    if (image != null && image.trim().isNotEmpty) return image.trim();
    return element;
  }

  void _startTicker() {
    _ticker?.cancel();
    _phaseStartedAt = DateTime.now();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted || _phaseStartedAt == null) return;
      final elapsed = DateTime.now().difference(_phaseStartedAt!).inMilliseconds;
      setState(() {
        if (_phase == _PiPhase.memorize) {
          _memorizationElapsedMs = elapsed;
        } else if (_phase == _PiPhase.recall) {
          _recallElapsedMs = elapsed;
        }
      });
    });
  }

  void _startMemorization() {
    uiTapClick(UiClickSound.soft);
    final elements = _buildSessionElements();
    if (elements.isEmpty) return;
    unawaited(_persistSetup());
    _disposeRecallInputs();
    _ticker?.cancel();
    setState(() {
      _sessionElements = elements;
      _sessionDigits = elements.join();
      _currentChunkIndex = 0;
      _memorizationElapsedMs = 0;
      _recallElapsedMs = 0;
      _correctElements = 0;
      _firstWrongElementIndex = null;
      _isChecking = false;
      _correctnessPattern = const [];
      _phase = _PiPhase.memorize;
    });
    _rebuildAttachedLoci();
    _startTicker();
  }

  void _beginRecall() {
    uiTapClick(UiClickSound.bright);
    _ticker?.cancel();
    _disposeRecallInputs();
    final controllers = List.generate(
      _sessionElements.length,
      (_) => TextEditingController(),
    );
    final nodes = List.generate(_sessionElements.length, (_) => FocusNode());
    setState(() {
      _recallControllers = controllers;
      _recallFocusNodes = nodes;
      _phase = _PiPhase.recall;
      _recallElapsedMs = 0;
      _isChecking = false;
      _correctnessPattern = const [];
    });
    _startTicker();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_recallFocusNodes.isNotEmpty) {
        _recallFocusNodes.first.requestFocus();
      }
    });
  }

  bool _answerMatchesIndex(int index) {
    if (index < 0 || index >= _sessionElements.length) return false;
    if (index >= _recallControllers.length) return false;
    final answer = _recallControllers[index].text.trim();
    if (answer.isEmpty) return false;
    return answer == _sessionElements[index];
  }

  Future<void> _submitRecall() async {
    _ticker?.cancel();
    for (final node in _recallFocusNodes) {
      node.unfocus();
    }
    final pattern = List<bool>.generate(
      _sessionElements.length,
      _answerMatchesIndex,
    );
    final correct = pattern.where((v) => v).length;
    int? firstWrong;
    for (var i = 0; i < pattern.length; i++) {
      if (!pattern[i]) {
        firstWrong = i;
        break;
      }
    }

    final perfect = correct == _sessionElements.length;
    if (perfect) {
      final newMastered = max(_masteredCount, _startOffset + _sessionDigits.length);
      await _setMasteredCount(newMastered);
      await _saveCheckpointAtDigit(
        newMastered,
        label: _t(const {
          AppLanguage.ru: 'Сессия',
          AppLanguage.en: 'Session',
          AppLanguage.de: 'Sitzung',
        }),
      );
      final prefs = await SharedPreferences.getInstance();
      final prevBest = prefs.getInt(_kBestStreak) ?? 0;
      if (_sessionElements.length > prevBest) {
        await prefs.setInt(_kBestStreak, _sessionElements.length);
      }
      try {
        await ProgressService.instance.awardMemorization(memorizedCount: _sessionElements.length);
        await ProfileSessionService.instance.recordSession(
          mode: 'pi',
          totalItems: _sessionElements.length,
          correctItems: _sessionElements.length,
          timeSeconds: max(1, ((_memorizationElapsedMs + _recallElapsedMs) / 1000).ceil()),
          date: DateTime.now(),
          encodingMs: _memorizationElapsedMs,
        );
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _correctElements = correct;
      _firstWrongElementIndex = firstWrong;
      _correctnessPattern = pattern;
      _isChecking = true;
    });
  }

  void _nextChunk() {
    uiTapClick(UiClickSound.soft);
    final total = (_sessionElements.length / _chunkSize).ceil();
    if (_currentChunkIndex + 1 < total) {
      setState(() => _currentChunkIndex++);
    } else {
      _beginRecall();
    }
  }

  void _previousChunk() {
    uiTapClick(UiClickSound.soft);
    if (_currentChunkIndex > 0) {
      setState(() => _currentChunkIndex--);
    }
  }

  void _goToFirstChunk() {
    uiTapClick(UiClickSound.soft);
    if (_currentChunkIndex > 0) {
      setState(() => _currentChunkIndex = 0);
    }
  }

  String _t(Map<AppLanguage, String> map) =>
      map[appLanguage.value] ?? map[AppLanguage.ru] ?? '';

  String _progressLine() {
    switch (appLanguage.value) {
      case AppLanguage.en:
        return 'Learned: $_masteredCount of $_totalAvailable digits after the decimal';
      case AppLanguage.de:
        return 'Gelernt: $_masteredCount von $_totalAvailable Ziffern nach dem Komma';
      case AppLanguage.ru:
        return 'Выучено: $_masteredCount из $_totalAvailable цифр после запятой';
    }
  }

  String _formatTime(int ms) {
    final seconds = (ms / 1000).floor();
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  void _requestTrainerKeyboardFocus() {}

  TrainerShortcutPhase _shortcutPhase() {
    switch (_phase) {
      case _PiPhase.setup:
        return TrainerShortcutPhase.setup;
      case _PiPhase.memorize:
        return TrainerShortcutPhase.memorize;
      default:
        return TrainerShortcutPhase.inactive;
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = appAccentColor.value;
    final keyboardEnabled = trainerKeyboardShortcutsEnabled(context);
    if (keyboardEnabled && (_phase == _PiPhase.setup || _phase == _PiPhase.memorize)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestTrainerKeyboardFocus();
      });
    }

    final keyboardHint = keyboardEnabled
        ? trainerKeyboardHintText(
            settings: _phase == _PiPhase.setup,
            memorizing: _phase == _PiPhase.memorize,
          )
        : '';

    Widget body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _loadError != null
            ? _buildLoadError(onSurface)
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: switch (_phase) {
                  _PiPhase.setup => Padding(
                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 20),
                      child: SizedBox.expand(child: _buildSetup(onSurface, accent)),
                    ),
                  _PiPhase.memorize => SizedBox.expand(child: _buildMemorize(onSurface, accent)),
                  _PiPhase.recall => SizedBox.expand(child: _buildInputArea(onSurface, accent)),
                  _PiPhase.done => _buildDone(onSurface, accent),
                },
              );

    body = webDesktopFrame(context: context, child: body);

    final overlayWidth = min(360.0, MediaQuery.sizeOf(context).width * 0.38);

    Widget bodyStack = Stack(
      fit: StackFit.expand,
      children: [
        webTrainerViewport(
          context: context,
          topPadding: 8,
          bottomReserve: keyboardEnabled &&
                  (_phase == _PiPhase.setup || _phase == _PiPhase.memorize)
              ? 52
              : 16,
          centerVertically: _phase == _PiPhase.memorize,
          child: body,
        ),
        if (_showLociOverlay && _activeTrainingLociRoute() != null)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: overlayWidth,
            child: PiLociRouteOverlay(
              rows: _lociMapRows(),
              routeName: _activeTrainingLociRoute()!.name,
              highlightElementIndex: _overlayHighlightElementIndex(),
              surfaceColor: appPalette.value.surface,
              borderColor: appPalette.value.border,
              accentColor: accent,
              onSurface: onSurface,
              title: _lociText(
                ru: 'Карта маршрута',
                en: 'Route map',
                de: 'Routenkarte',
              ),
              emptyLabel: _lociText(
                ru: 'Нет привязанных цифр для текущей сессии.',
                en: 'No digits bound for the current session.',
                de: 'Keine Ziffern fuer die aktuelle Sitzung gebunden.',
              ),
              onClose: _toggleLociOverlay,
              onRowTap: (row) {
                if (_phase == _PiPhase.setup && _setupTab == _PiSetupTab.reading) {
                  setState(() {
                    _startOffset = row.globalDigitStart;
                    _startOffsetController.text = '${row.globalDigitStart + 1}';
                  });
                  _normalizeElementCount(persist: false);
                  unawaited(_persistSetup());
                }
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
      bodyStack = TrainerShortcutScope(
        phase: _shortcutPhase(),
        autofocus: true,
        callbacks: TrainerShortcutCallbacks(
          enabled: keyboardEnabled,
          scrollController: _memorizerScrollController,
          onStartTraining: () {
            if (_maxElementCount > 0) _startMemorization();
          },
          onNextChunk: _nextChunk,
          onPrevChunk: _previousChunk,
          onFirstChunk: _goToFirstChunk,
          onRecallNow: _beginRecall,
          onToggleLociMap:
              _activeTrainingLociRoute() != null ? _toggleLociOverlay : null,
          onSaveCheckpoint:
              _phase == _PiPhase.setup ? _promptSaveCheckpoint : null,
        ),
        child: bodyStack,
      );
    }

    return Scaffold(
      backgroundColor: appPalette.value.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('π', style: TextStyle(color: onSurface, fontSize: 20, fontWeight: FontWeight.w300)),
        actions: [
          if (_activeTrainingLociRoute() != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PiLociOverlayToggle(
                active: _showLociOverlay,
                onTap: _toggleLociOverlay,
                surfaceColor: appPalette.value.surface,
                borderColor: appPalette.value.border,
                accentColor: accent,
                onSurface: onSurface,
                label: _lociText(ru: 'Карта', en: 'Map', de: 'Karte'),
              ),
            ),
        ],
      ),
      body: bodyStack,
    );
  }

  Widget _buildLoadError(Color onSurface) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(_loadError!, textAlign: TextAlign.center, style: TextStyle(color: onSurface.withOpacity(0.75))),
          ),
          const SizedBox(height: 10),
          FilledButton(onPressed: _bootstrap, child: Text(_t(const {
            AppLanguage.ru: 'Повторить',
            AppLanguage.en: 'Retry',
            AppLanguage.de: 'Erneut',
          }))),
        ],
      ),
    );
  }

  Widget _buildSetup(Color onSurface, Color accent) {
    return Column(
      key: const ValueKey('pi_setup'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              _buildProgressCard(onSurface),
              const SizedBox(height: 14),
              PiCheckpointPanel(
                checkpoints: _checkpoints,
                currentDigitIndex: _startOffset,
                onJumpTo: _jumpToCheckpoint,
                onDelete: _deleteCheckpoint,
                onSaveCurrent: _promptSaveCheckpoint,
                surfaceColor: appPalette.value.surface,
                borderColor: appPalette.value.border,
                accentColor: accent,
                onSurface: onSurface,
                title: _t(const {
                  AppLanguage.ru: 'ЧЕКПОИНТЫ',
                  AppLanguage.en: 'CHECKPOINTS',
                  AppLanguage.de: 'CHECKPOINTS',
                }),
                saveLabel: _t(const {
                  AppLanguage.ru: '+ Точка',
                  AppLanguage.en: '+ Mark',
                  AppLanguage.de: '+ Mark',
                }),
                emptyLabel: _t(const {
                  AppLanguage.ru: 'Отметьте прогресс, чтобы быстро вернуться к нужной цифре.',
                  AppLanguage.en: 'Mark progress to jump back to any digit quickly.',
                  AppLanguage.de: 'Markiere Fortschritt, um schnell zu einer Ziffer zu springen.',
                }),
                digitLabelBuilder: _checkpointDigitLabel,
              ),
              const SizedBox(height: 20),
              _buildSetupTabSelector(onSurface),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _setupTab == _PiSetupTab.reading
                ? _buildReadingSetup(onSurface, accent)
                : _buildTrainingSetup(onSurface, accent),
          ),
        ),
      ],
    );
  }

  Widget _buildSetupTabSelector(Color onSurface) {
    final palette = appPalette.value;
    return Center(
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
            _setupTabItem(
              _t(const {
                AppLanguage.ru: 'Тренировка',
                AppLanguage.en: 'Training',
                AppLanguage.de: 'Training',
              }),
              _PiSetupTab.training,
              onSurface,
            ),
            _setupTabItem(
              _t(const {
                AppLanguage.ru: 'Чтение π',
                AppLanguage.en: 'Read π',
                AppLanguage.de: 'Pi lesen',
              }),
              _PiSetupTab.reading,
              onSurface,
            ),
          ],
        ),
      ),
    );
  }

  Widget _setupTabItem(String label, _PiSetupTab tab, Color onSurface) {
    final isSelected = _setupTab == tab;
    return GestureDetector(
      onTap: () {
        uiTapClick(UiClickSound.soft);
        setState(() {
          _setupTab = tab;
          _rebuildAttachedLoci();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? appAccentColor.value.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w300,
            color: isSelected ? appAccentColor.value : onSurface.withOpacity(0.48),
          ),
        ),
      ),
    );
  }

  Widget _buildReadingSetup(Color onSurface, Color accent) {
    return PiReadingDigitsView(
      key: ValueKey('reading_${_startOffset}_$_standardDigits'),
      blocks: _readingBlocks(),
      accentColor: accent,
      onSurface: onSurface,
      surfaceColor: appPalette.value.surface,
      borderColor: appPalette.value.border,
      highlightGlobalDigitStart: _startOffset,
      showLoci: _activeTrainingLociRoute() != null,
      positionLabel: _t(const {
        AppLanguage.ru: 'ПРОКРУТКА · НАЖМИТЕ БЛОК, ЧТОБЫ НАЧАТЬ С ЦИФРЫ',
        AppLanguage.en: 'SCROLL · TAP A BLOCK TO START FROM THAT DIGIT',
        AppLanguage.de: 'SCROLLEN · BLOCK TIPPEN FUER STARTZIFFER',
      }),
      onBlockTap: (block) {
        uiTapClick(UiClickSound.soft);
        setState(() {
          _startOffset = block.globalDigitStart;
          _startOffsetController.text = '${block.globalDigitStart + 1}';
          _setupTab = _PiSetupTab.training;
        });
        _normalizeElementCount(persist: false);
        unawaited(_persistSetup());
      },
    );
  }

  Widget _buildTrainingSetup(Color onSurface, Color accent) {
    return SingleChildScrollView(
      key: const ValueKey('pi_training_setup'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.layers_outlined, size: 14, color: onSurface.withOpacity(0.3)),
                const SizedBox(width: 8),
                Text(
                  AppTexts.get('modes_title'),
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                    color: onSurface.withOpacity(0.3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildNumberRangeSelector(onSurface),
            if (_standardDigits > 1) ...[
              const SizedBox(height: 16),
              _buildCodesToggle(onSurface, accent),
            ],
            const SizedBox(height: 36),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildLociBindingButton(onSurface),
              ],
            ),
            const SizedBox(height: 14),
            _buildStartOffsetSetting(onSurface),
            const SizedBox(height: 28),
            _buildCounterSetting(
              AppTexts.get('settings_elements_count'),
              _totalCountController,
              isChunk: false,
              onSurface: onSurface,
            ),
            const SizedBox(height: 28),
            _buildCounterSetting(
              AppTexts.get('settings_chunk_count'),
              _chunkSizeController,
              isChunk: true,
              onSurface: onSurface,
            ),
            const SizedBox(height: 50),
            _buildActionButton(
              AppTexts.get('start'),
              _maxElementCount > 0 ? _startMemorization : () {},
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(Color onSurface) {
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
          Text(
            _t(const {AppLanguage.ru: 'Прогресс', AppLanguage.en: 'Progress', AppLanguage.de: 'Fortschritt'}),
            style: TextStyle(color: onSurface.withOpacity(0.45), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Text(_progressLine(), style: TextStyle(color: onSurface.withOpacity(0.72), fontSize: 13, height: 1.35)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _masteredCount >= _totalAvailable ? null : _continueFromMastered,
                  child: Text(_t(const {AppLanguage.ru: 'Продолжить', AppLanguage.en: 'Continue', AppLanguage.de: 'Weiter'}), style: const TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetProgress,
                  child: Text(_t(const {AppLanguage.ru: 'Сначала', AppLanguage.en: 'Start over', AppLanguage.de: 'Neu'}), style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberRangeSelector(Color onSurface) {
    final palette = appPalette.value;
    return Center(
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
            _numberRangeItem('0-9', 1, onSurface),
            _numberRangeItem('00-99', 2, onSurface),
            _numberRangeItem('000-999', 3, onSurface),
          ],
        ),
      ),
    );
  }

  Widget _numberRangeItem(String label, int digits, Color onSurface) {
    final isSelected = _standardDigits == digits;
    return GestureDetector(
      onTap: () => _setStandardDigits(digits),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? appAccentColor.value.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w300,
            color: isSelected ? appAccentColor.value : onSurface.withOpacity(0.48),
          ),
        ),
      ),
    );
  }

  Widget _buildCodesToggle(Color onSurface, Color accent) {
    final canUse = _codesFilledCount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: appPalette.value.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: appPalette.value.border.withOpacity(0.35)),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _useNumberCodes && canUse,
        onChanged: canUse ? _setUseNumberCodes : null,
        activeColor: accent,
        title: Text(
          _t(const {
            AppLanguage.ru: 'Коды образов',
            AppLanguage.en: 'Image codes',
            AppLanguage.de: 'Bild-Codes',
          }),
          style: TextStyle(color: onSurface.withOpacity(0.82), fontSize: 13),
        ),
        subtitle: Text(
          canUse ? _codesToggleHint() : _codesToggleEmptyHint(),
          style: TextStyle(color: onSurface.withOpacity(0.45), fontSize: 11),
        ),
      ),
    );
  }

  String _codesToggleHint() {
    switch (appLanguage.value) {
      case AppLanguage.en:
        return 'Memorize with images, recall digits ($_codesFilledCount codes)';
      case AppLanguage.de:
        return 'Merken mit Bildern, Abruf Ziffern ($_codesFilledCount Codes)';
      case AppLanguage.ru:
        return 'При запоминании — образы, при вводе — цифры ($_codesFilledCount кодов)';
    }
  }

  String _codesToggleEmptyHint() {
    switch (appLanguage.value) {
      case AppLanguage.en:
        return 'Fill in 00–99 or 000–999 codes in the codes section';
      case AppLanguage.de:
        return 'Codes 00–99 oder 000–999 im Codes-Bereich ausfüllen';
      case AppLanguage.ru:
        return 'Заполните коды 00–99 или 000–999 в разделе кодов';
    }
  }

  String _startOffsetSettingTitle() {
    switch (appLanguage.value) {
      case AppLanguage.en:
        return 'Start at digit # (after decimal)';
      case AppLanguage.de:
        return 'Start bei Ziffer Nr. (nach dem Komma)';
      case AppLanguage.ru:
        return 'Начать с цифры № (после запятой)';
    }
  }

  List<int> _memorizerVisibleIndices({required int start, required int end}) {
    final indices = List<int>.generate(end - start, (offset) => start + offset);
    if (numberDisplayDirection.value == NumberDisplayDirection.bottomToTop) {
      return indices.reversed.toList(growable: false);
    }
    return indices;
  }

  Widget _buildStartOffsetSetting(Color onSurface) {
    return Column(
      children: [
        Text(
          _startOffsetSettingTitle(),
          style: TextStyle(fontWeight: FontWeight.w200, fontSize: 14, color: onSurface.withOpacity(0.62)),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _counterStepButton(
              icon: Icons.remove,
              onTap: () => _changeStartOffset(-1),
              onLongPressStart: () {
                _counterHoldTimer?.cancel();
                _counterHoldTimer = Timer.periodic(const Duration(milliseconds: 80), (_) => _changeStartOffset(-1));
              },
              onLongPressEnd: _stopCounterHold,
            ),
            Container(
              width: 96,
              height: 50,
              alignment: Alignment.center,
              child: TextField(
                controller: _startOffsetController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w200, color: appAccentColor.value),
                decoration: const InputDecoration(border: InputBorder.none, isCollapsed: true),
                onChanged: (_) {
                  _normalizeStartOffset(persist: true);
                  setState(() {});
                },
              ),
            ),
            _counterStepButton(
              icon: Icons.add,
              onTap: () => _changeStartOffset(1),
              onLongPressStart: () {
                _counterHoldTimer?.cancel();
                _counterHoldTimer = Timer.periodic(const Duration(milliseconds: 80), (_) => _changeStartOffset(1));
              },
              onLongPressEnd: _stopCounterHold,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCounterSetting(
    String title,
    TextEditingController controller, {
    required bool isChunk,
    required Color onSurface,
  }) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w200, fontSize: 14, color: onSurface.withOpacity(0.62))),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _counterStepButton(
              icon: Icons.remove,
              onTap: () => _changeCounter(controller, -1, isChunk: isChunk),
              onLongPressStart: () => _startCounterHold(controller, -1, isChunk: isChunk),
              onLongPressEnd: _stopCounterHold,
            ),
            Container(
              width: 96,
              height: 50,
              alignment: Alignment.center,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w200, color: appAccentColor.value),
                decoration: const InputDecoration(border: InputBorder.none, isCollapsed: true),
                onChanged: (_) => isChunk ? _normalizeChunkCount(persist: true) : _normalizeElementCount(persist: true),
              ),
            ),
            _counterStepButton(
              icon: Icons.add,
              onTap: () => _changeCounter(controller, 1, isChunk: isChunk),
              onLongPressStart: () => _startCounterHold(controller, 1, isChunk: isChunk),
              onLongPressEnd: _stopCounterHold,
            ),
          ],
        ),
      ],
    );
  }

  Widget _counterStepButton({
    required IconData icon,
    required VoidCallback onTap,
    required VoidCallback onLongPressStart,
    required VoidCallback onLongPressEnd,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPressStart: (_) => onLongPressStart(),
      onLongPressEnd: (_) => onLongPressEnd(),
      onLongPressCancel: onLongPressEnd,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: appPalette.value.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: appPalette.value.border.withOpacity(0.35)),
        ),
        child: Icon(icon, size: 18, color: appAccentColor.value.withOpacity(0.85)),
      ),
    );
  }

  Widget _buildMemorize(Color onSurface, Color accent) {
    final chunk = _chunkSize;
    final start = _currentChunkIndex * chunk;
    final end = min(start + chunk, _sessionElements.length);
    final totalChunks = (_sessionElements.length / chunk).ceil();
    final canGoBack = _currentChunkIndex > 0;
    final accentTint = Color.lerp(onSurface, accent, 0.3)!.withOpacity(0.45);
    final formattedMemTime = _formatTime(_memorizationElapsedMs);

    return ValueListenableBuilder<NumberDisplayDirection>(
      valueListenable: numberDisplayDirection,
      builder: (context, _, __) {
        final useHorizontalChunkLayout =
            numberDisplayDirection.value == NumberDisplayDirection.leftToRight;
        final visibleIndices = _memorizerVisibleIndices(start: start, end: end);
        return webTrainerMemorizerScroll(
          controller: _memorizerScrollController,
          key: const ValueKey('pi_memorize'),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Text(
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
                  ),
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
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      child: _buildActionButton(
                        AppTexts.get('back'),
                        canGoBack ? _previousChunk : () {},
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 120,
                      child: _buildActionButton(
                        AppTexts.get('first_chunk'),
                        canGoBack ? _goToFirstChunk : () {},
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 100,
                      child: _buildActionButton(AppTexts.get('next_chunk'), _nextChunk),
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

  Widget _buildMemorizerChunkItem(
    int index,
    Color onSurface, {
    bool horizontal = false,
  }) {
    final element = _sessionElements[index];
    final display = _displayForElement(element);
    final showingCode = display != element;
    final locus = _attachedLocusForIndex(index);
    final digitStart = _startOffset + index * _standardDigits;
    final content = showingCode
        ? Text(
            display,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: horizontal ? 28 : 40,
              fontWeight: FontWeight.w100,
              letterSpacing: horizontal ? 2 : 4,
              color: onSurface.withOpacity(0.9),
            ),
          )
        : Text(
            element.toUpperCase(),
            style: TextStyle(
              fontSize: horizontal ? 42 : 80,
              fontWeight: FontWeight.w100,
              letterSpacing: horizontal ? 4 : 8,
              color: onSurface.withOpacity(0.9),
              fontFamily: 'monospace',
            ),
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '#${digitStart + 1}',
          style: TextStyle(
            color: onSurface.withOpacity(0.28),
            fontSize: 9,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        content,
        if (locus.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            locus,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: appAccentColor.value.withOpacity(0.55),
              fontSize: horizontal ? 9 : 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton(String text, VoidCallback onTap, {double width = 200}) {
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
      },
    );
  }

  List<int> _recallOrderedDataIndices() {
    final n = _sessionElements.length;
    if (n == 0) return const [];
    final chunkSize = _chunkSize;
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

  Widget _buildInputArea(Color onSurface, Color accent) {
    final formattedRecallTime = _formatTime(_recallElapsedMs);
    return Column(
      key: const ValueKey('pi_recall'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!_isChecking)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                formattedRecallTime,
                style: TextStyle(
                  color: Color.lerp(onSurface, accent, 0.3)!.withOpacity(0.45),
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _showAttachedLociPreviewSheet,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: appPalette.value.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: appPalette.value.border.withOpacity(0.35)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.alt_route_rounded,
                          size: 13, color: appAccentColor.value.withOpacity(0.92)),
                      const SizedBox(width: 4),
                      Text(
                        'Loci',
                        style: TextStyle(
                          color: onSurface.withOpacity(0.62),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        if (_isChecking) ...[
          Text(
            '${((_correctElements / max(1, _sessionElements.length)) * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w100,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$_correctElements / ${_sessionElements.length}',
            style: TextStyle(color: onSurface.withOpacity(0.55), fontSize: 13),
          ),
          if (_firstWrongElementIndex != null) ...[
            const SizedBox(height: 8),
            Text(
              _firstMistakeWithLocusLabel(_firstWrongElementIndex!),
              textAlign: TextAlign.center,
              style: TextStyle(color: onSurface.withOpacity(0.55), fontSize: 12),
            ),
          ],
        ],
        const SizedBox(height: 40),
        Expanded(
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
                        onSurface: onSurface,
                        accent: accent,
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
              setState(() {
                _phase = _PiPhase.setup;
                _isChecking = false;
              });
            } else {
              await _submitRecall();
            }
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSelectionBox(
    int dataIndex, {
    required List<int> recallOrder,
    required int recallSlot,
    required Color onSurface,
    required Color accent,
  }) {
    final expected = _sessionElements[dataIndex];
    final isCorrect = _isChecking &&
        dataIndex < _correctnessPattern.length &&
        _correctnessPattern[dataIndex];
    final isWrong = _isChecking &&
        dataIndex < _correctnessPattern.length &&
        !_correctnessPattern[dataIndex];
    final locus = _attachedLocusForIndex(dataIndex);

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
            } else if (isWrong) {
              borderColor = const Color(0xFFFF1744);
            } else if (dataIndex < _recallFocusNodes.length &&
                _recallFocusNodes[dataIndex].hasFocus) {
              borderColor = accentColor;
            }

            return AnimatedContainer(
              duration: const Duration(milliseconds: 70),
              width: 70,
              height: 50,
              decoration: BoxDecoration(
                color: appPalette.value.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _isChecking
                    ? null
                    : () {
                        final node = _recallFocusNodes[dataIndex];
                        if (!node.hasFocus) {
                          node.requestFocus();
                          if (mounted) setState(() {});
                        }
                        SystemChannels.textInput.invokeMethod('TextInput.show');
                      },
                child: Center(
                  child: TextField(
                    controller: _recallControllers[dataIndex],
                    focusNode: _recallFocusNodes[dataIndex],
                    textAlign: TextAlign.center,
                    showCursor: false,
                    readOnly: _isChecking,
                    keyboardType: TextInputType.number,
                    maxLength: _standardDigits,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color.lerp(onSurface, accentColor, 0.2),
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      isCollapsed: true,
                    ),
                    onTap: () {
                      final node = _recallFocusNodes[dataIndex];
                      if (!node.hasFocus) {
                        node.requestFocus();
                        if (mounted) setState(() {});
                      }
                      SystemChannels.textInput.invokeMethod('TextInput.show');
                    },
                    onChanged: (value) {
                      uiTapClick(UiClickSound.soft);
                      if (!_isChecking &&
                          value.length >= _standardDigits &&
                          recallSlot < recallOrder.length - 1) {
                        _recallFocusNodes[recallOrder[recallSlot + 1]]
                            .requestFocus();
                      }
                      if (mounted) setState(() {});
                    },
                  ),
                ),
              ),
            );
          },
        ),
        if (isWrong) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              expected,
              style: const TextStyle(
                color: Color(0xFF00E676),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (locus.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                locus,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onSurface.withOpacity(0.42),
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ],
    );
  }

  String _firstMistakeWithLocusLabel(int elementIndex) {
    final locus = _attachedLocusForIndex(elementIndex);
    switch (appLanguage.value) {
      case AppLanguage.en:
        return locus.isEmpty
            ? 'First mistake at element ${elementIndex + 1}'
            : 'First mistake at element ${elementIndex + 1} · $locus';
      case AppLanguage.de:
        return locus.isEmpty
            ? 'Erster Fehler bei Element ${elementIndex + 1}'
            : 'Erster Fehler bei Element ${elementIndex + 1} · $locus';
      case AppLanguage.ru:
        return locus.isEmpty
            ? 'Первая ошибка на элементе ${elementIndex + 1}'
            : 'Первая ошибка на элементе ${elementIndex + 1} · $locus';
    }
  }

  String _lociText({required String ru, required String en, required String de}) {
    switch (appLanguage.value) {
      case AppLanguage.en:
        return en;
      case AppLanguage.de:
        return de;
      case AppLanguage.ru:
        return ru;
    }
  }

  Future<void> _loadTrainingLociRoutes() async {
    final parsed = await PiTrainerPersistence.loadLociRoutes();
    if (!mounted) return;
    setState(() {
      _trainingLociRoutes
        ..clear()
        ..addAll(parsed.map((r) => _LociRoute(name: r.name, loci: r.loci)));
      if (_trainingLociRoutes.isEmpty) {
        _selectedTrainingLociRoute = -1;
        _lociStartIndex = 0;
      } else if (_selectedTrainingLociRoute >= _trainingLociRoutes.length) {
        _selectedTrainingLociRoute = -1;
      }
      if (_selectedTrainingLociRoute >= 0) {
        final maxStart =
            _trainingLociRoutes[_selectedTrainingLociRoute].loci.length - 1;
        _lociStartIndex = _lociStartIndex.clamp(0, max(0, maxStart));
      } else {
        _lociStartIndex = 0;
      }
      _rebuildAttachedLoci();
    });
  }

  _LociRoute? _activeTrainingLociRoute() {
    if (_selectedTrainingLociRoute < 0 ||
        _selectedTrainingLociRoute >= _trainingLociRoutes.length) {
      return null;
    }
    return _trainingLociRoutes[_selectedTrainingLociRoute];
  }

  void _rebuildAttachedLoci() {
    final route = _activeTrainingLociRoute();
    final count =
        _sessionElements.isNotEmpty ? _sessionElements.length : _elementCount;
    if (count <= 0) {
      _attachedLociByElement = const <String>[];
      return;
    }
    final piRoute = route == null
        ? null
        : PiLociRoute(name: route.name, loci: List<String>.from(route.loci));
    _attachedLociByElement = PiLociBindingService.lociForElements(
      route: piRoute,
      startLocusIndex: _lociStartIndex,
      elementCount: count,
    );
  }

  String _attachedLocusForIndex(int index) {
    if (index < 0 || index >= _attachedLociByElement.length) return '';
    return _attachedLociByElement[index];
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
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLociBindingSheet() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    var selected = _selectedTrainingLociRoute;
    var start = _lociStartIndex;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: appPalette.value.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            final hasRoutes = _trainingLociRoutes.isNotEmpty;
            final route = (selected >= 0 && selected < _trainingLociRoutes.length)
                ? _trainingLociRoutes[selected]
                : null;
            final loci = route?.loci ?? const <String>[];
            final safeStart = loci.isEmpty ? 0 : start.clamp(0, loci.length - 1);
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
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!hasRoutes) ...[
                    Text(
                      _lociText(
                        ru: 'Сначала создай маршрут в меню Loci.',
                        en: 'Create a route first in the Loci menu.',
                        de: 'Erstelle zuerst eine Route im Loci-Menue.',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: onSurface.withOpacity(0.55), fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(this.context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const LociRoutesScreen(),
                          ),
                        );
                      },
                      child: Text(_lociText(
                        ru: 'Создать маршрут',
                        en: 'Create route',
                        de: 'Route erstellen',
                      )),
                    ),
                  ]
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
                                color: onSurface.withOpacity(selected < 0 ? 0.92 : 0.72),
                                fontWeight:
                                    selected < 0 ? FontWeight.w600 : FontWeight.w400,
                              ),
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
                                  color: onSurface.withOpacity(active ? 0.92 : 0.72),
                                  fontWeight:
                                      active ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                              subtitle: Text(
                                '${_trainingLociRoutes[i].loci.length} loci',
                                style: TextStyle(
                                  color: onSurface.withOpacity(0.45),
                                  fontSize: 11,
                                ),
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
                    if (loci.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${_lociText(ru: 'Стартовая точка', en: 'Start point', de: 'Startpunkt')}: ${safeStart + 1} - ${loci[safeStart]}',
                        style: TextStyle(color: onSurface.withOpacity(0.72), fontSize: 12),
                      ),
                      Slider(
                        value: safeStart.toDouble(),
                        min: 0,
                        max: max(0, loci.length - 1).toDouble(),
                        divisions: loci.length <= 1 ? null : loci.length - 1,
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
                            ru: 'Отмена',
                            en: 'Cancel',
                            de: 'Abbrechen',
                          )),
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
                            unawaited(_persistSetup());
                            Navigator.pop(context);
                          },
                          child: Text(_lociText(
                            ru: 'Применить',
                            en: 'Apply',
                            de: 'Anwenden',
                          )),
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
    final items = _phase == _PiPhase.recall && _sessionElements.isNotEmpty
        ? _sessionElements.length
        : _attachedLociByElement.length;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: appPalette.value.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
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
                  itemCount: items,
                  itemBuilder: (context, index) {
                    final locus = _attachedLocusForIndex(index);
                    final digitLabel = _phase == _PiPhase.recall &&
                            index < _sessionElements.length
                        ? _sessionElements[index]
                        : null;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: onSurface.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      title: Text(
                        locus.isEmpty ? '-' : locus,
                        style: TextStyle(
                          color: onSurface.withOpacity(0.85),
                          fontSize: 13,
                        ),
                      ),
                      subtitle: digitLabel == null
                          ? null
                          : Text(
                              digitLabel,
                              style: TextStyle(
                                color: onSurface.withOpacity(0.45),
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
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

  Widget _buildDone(Color onSurface, Color accent) {
    final total = _sessionElements.length;
    final accuracy = total == 0 ? 0.0 : (_correctElements / total) * 100.0;
    final perfect = _correctElements == total;
    return Center(
      key: const ValueKey('pi_done'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: appPalette.value.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: appPalette.value.border.withOpacity(0.35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${accuracy.toStringAsFixed(0)}%', style: TextStyle(color: accent, fontSize: 36, fontWeight: FontWeight.w200)),
              Text('$_correctElements / $total', style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 14)),
              if (_firstWrongElementIndex != null) ...[
                const SizedBox(height: 10),
                Text(
                  _firstMistakeLabel(_firstWrongElementIndex! + 1),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: onSurface.withOpacity(0.55), fontSize: 12),
                ),
              ],
              if (perfect) ...[
                const SizedBox(height: 8),
                Text(
                  _savedProgressLabel(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: accent.withOpacity(0.85), fontSize: 12),
                ),
              ],
              const SizedBox(height: 18),
              _buildActionButton(
                _t(const {AppLanguage.ru: 'Ещё раз', AppLanguage.en: 'Again', AppLanguage.de: 'Nochmal'}),
                () => setState(() {
                  _phase = _PiPhase.setup;
                  _isChecking = false;
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _firstMistakeLabel(int position) {
    switch (appLanguage.value) {
      case AppLanguage.en:
        return 'First mistake at element $position';
      case AppLanguage.de:
        return 'Erster Fehler bei Element $position';
      case AppLanguage.ru:
        return 'Первая ошибка на элементе $position';
    }
  }

  String _savedProgressLabel() {
    switch (appLanguage.value) {
      case AppLanguage.en:
        return 'Progress saved: $_masteredCount digits';
      case AppLanguage.de:
        return 'Fortschritt gespeichert: $_masteredCount Ziffern';
      case AppLanguage.ru:
        return 'Прогресс сохранён: $_masteredCount цифр';
    }
  }

}
