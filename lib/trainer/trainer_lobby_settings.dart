import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/core/ui_feedback.dart';
import '../duels/duel_disciplines.dart';
import '../duels/duel_service.dart';
import 'trainer_limits.dart';
import '../training_connectivity.dart';
import '../recovered_app.dart'
    show
        AppLanguage,
        AppPalette,
        AppTexts,
        TrainingMode,
        appAccentColor,
        appLanguage,
        appPalette;

/// Solo-trainer settings panel for duel lobby — same layout as [TrainingScreen._buildSettings].
class TrainerLobbySettingsPanel extends StatefulWidget {
  final DuelLobbySettings settings;
  final ValueChanged<DuelLobbySettings> onChanged;
  final bool enabled;
  /// Duel lobby: elements per screen — personal for each player.
  final int? personalChunkSize;
  final ValueChanged<int>? onPersonalChunkChanged;

  const TrainerLobbySettingsPanel({
    super.key,
    required this.settings,
    required this.onChanged,
    this.enabled = true,
    this.personalChunkSize,
    this.onPersonalChunkChanged,
  });

  @override
  State<TrainerLobbySettingsPanel> createState() => _TrainerLobbySettingsPanelState();
}

class _TrainerLobbySettingsPanelState extends State<TrainerLobbySettingsPanel> {
  late TextEditingController _totalCountController;
  late TextEditingController _chunkSizeController;
  Timer? _counterHoldTimer;

  int get _effectiveChunkSize =>
      widget.personalChunkSize ?? widget.settings.chunkSize;

  @override
  void initState() {
    super.initState();
    _totalCountController = TextEditingController(text: '${widget.settings.count}');
    _chunkSizeController = TextEditingController(text: '$_effectiveChunkSize');
  }

  @override
  void didUpdateWidget(covariant TrainerLobbySettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings ||
        oldWidget.personalChunkSize != widget.personalChunkSize) {
      final countText = '${widget.settings.count}';
      final chunkText = '$_effectiveChunkSize';
      if (_totalCountController.text != countText) {
        _totalCountController.text = countText;
      }
      if (_chunkSizeController.text != chunkText) {
        _chunkSizeController.text = chunkText;
      }
    }
  }

  @override
  void dispose() {
    _counterHoldTimer?.cancel();
    _totalCountController.dispose();
    _chunkSizeController.dispose();
    super.dispose();
  }

  TrainingMode get _mode => _modeFromString(widget.settings.mode);

  TrainingMode _modeFromString(String raw) {
    switch (raw) {
      case 'binary':
        return TrainingMode.binary;
      case 'words':
        return TrainingMode.words;
      case 'images':
        return TrainingMode.images;
      case 'cards':
        return TrainingMode.cards;
      case 'faces':
        return TrainingMode.faces;
      default:
        return TrainingMode.standard;
    }
  }

  String _modeToString(TrainingMode mode) {
    switch (mode) {
      case TrainingMode.binary:
        return 'binary';
      case TrainingMode.words:
        return 'words';
      case TrainingMode.images:
        return 'images';
      case TrainingMode.cards:
        return 'cards';
      case TrainingMode.faces:
        return 'faces';
      case TrainingMode.standard:
        return 'standard';
    }
  }

  void _emit(DuelLobbySettings next) {
    if (!widget.enabled) return;
    widget.onChanged(next);
  }

  void _applyMode(TrainingMode mode) {
    final count = defaultCountForLobbyMode(_modeToString(mode));
    final chunk = 1;
    _totalCountController.text = '$count';
    _chunkSizeController.text = '$chunk';
    if (widget.onPersonalChunkChanged != null) {
      widget.onPersonalChunkChanged!(chunk);
    }
    _emit(widget.settings.copyWith(
      mode: _modeToString(mode),
      matrixMode: mode == TrainingMode.standard ? widget.settings.matrixMode : false,
      count: count,
      chunkSize: chunk,
    ));
  }

  int _maxChunkForMode() => maxChunkForLobbyMode(widget.settings.mode);

  void _normalizeCounter(TextEditingController controller, {required bool isChunk}) {
    if (controller.text.isEmpty) return;
    int val = int.tryParse(controller.text) ?? 1;
    final maxVal = isChunk ? _maxChunkForMode() : kTrainerElementCountMax;
    if (val > maxVal) {
      controller.text = maxVal.toString();
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
    }
    if (val < 1) {
      controller.text = '1';
      controller.selection = const TextSelection.collapsed(offset: 1);
    }
    final count = int.tryParse(_totalCountController.text) ?? widget.settings.count;
    final chunk = int.tryParse(_chunkSizeController.text) ?? _effectiveChunkSize;
    if (isChunk && widget.onPersonalChunkChanged != null) {
      widget.onPersonalChunkChanged!(chunk);
    } else {
      _emit(widget.settings.copyWith(count: count, chunkSize: chunk));
    }
  }

  void _changeCounter(TextEditingController controller, int delta, {required bool isChunk}) {
    int val = int.tryParse(controller.text) ?? 1;
    val += delta;
    val = max(1, val);
    final maxVal = isChunk ? _maxChunkForMode() : kTrainerElementCountMax;
    val = min(maxVal, val);
    setState(() => controller.text = val.toString());
    final count = int.tryParse(_totalCountController.text) ?? widget.settings.count;
    final chunk = int.tryParse(_chunkSizeController.text) ?? _effectiveChunkSize;
    if (isChunk && widget.onPersonalChunkChanged != null) {
      widget.onPersonalChunkChanged!(chunk);
    } else {
      _emit(widget.settings.copyWith(count: count, chunkSize: chunk));
    }
  }

  void _startCounterHold(TextEditingController controller, int delta, {required bool isChunk}) {
    _counterHoldTimer?.cancel();
    _changeCounter(controller, delta, isChunk: isChunk);
    _counterHoldTimer = Timer.periodic(const Duration(milliseconds: 90), (_) {
      _changeCounter(controller, delta, isChunk: isChunk);
    });
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

  String _formatClockFromSec(int sec) {
    final s = sec.clamp(0, 86400);
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  Future<void> _showCustomSessionCapDialog() async {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    final controller = TextEditingController(
      text: widget.settings.memorizeSeconds > 0 ? '${widget.settings.memorizeSeconds}' : '60',
    );
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: palette.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            _lociText(ru: 'Своё время', en: 'Custom duration', de: 'Eigene Dauer'),
            style: TextStyle(color: onSurface.withOpacity(0.92), fontSize: 17, fontWeight: FontWeight.w600),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(color: onSurface),
            decoration: InputDecoration(
              hintText: _lociText(ru: 'Секунды (15–7200)', en: 'Seconds (15–7200)', de: 'Sekunden (15–7200)'),
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
              child: Text(_lociText(ru: 'Отмена', en: 'Cancel', de: 'Abbrechen')),
            ),
            TextButton(
              onPressed: () {
                final v = int.tryParse(controller.text.trim());
                if (v == null || v < 15 || v > 7200) return;
                _emit(widget.settings.copyWith(memorizeSeconds: v));
                Navigator.pop(ctx);
              },
              child: Text(_lociText(ru: 'Сохранить', en: 'Save', de: 'Speichern')),
            ),
          ],
        );
      },
    );
    controller.dispose();
  }

  void _showTimingSettingsSheet() {
    if (!widget.enabled) return;
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
              final memSec = widget.settings.memorizeSeconds;
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
                            child: Icon(Icons.hourglass_top_rounded, color: accent.withOpacity(0.9), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _lociText(ru: 'Тайминг тренировки', en: 'Training timing', de: 'Training-Timing'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16.5,
                                    color: onSurface.withOpacity(0.94),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _lociText(
                                    ru: 'Лимит на фазу запоминания. 0 — без лимита, соревнуетесь по скорости.',
                                    en: 'Memorization time limit. 0 = none — compete on speed.',
                                    de: 'Merkzeit-Limit. 0 = keins — Wettbewerb nach Geschwindigkeit.',
                                  ),
                                  style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12.4, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text(
                        _lociText(ru: 'ЛИМИТ НА ЗАПОМИНАНИЕ', en: 'MEMORIZATION LIMIT', de: 'MERK-LIMIT'),
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
                            label: Text(_lociText(ru: 'Без лимита', en: 'None', de: 'Keins')),
                            selected: memSec <= 0,
                            onSelected: (_) {
                              _emit(widget.settings.copyWith(memorizeSeconds: 0));
                              setModal(() {});
                            },
                            selectedColor: accent.withOpacity(0.22),
                            labelStyle: TextStyle(
                              color: memSec <= 0 ? accent : onSurface.withOpacity(0.78),
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                          for (final s in presets)
                            ChoiceChip(
                              label: Text(_formatClockFromSec(s)),
                              selected: memSec == s,
                              onSelected: (_) {
                                _emit(widget.settings.copyWith(memorizeSeconds: s));
                                setModal(() {});
                              },
                              selectedColor: accent.withOpacity(0.22),
                              labelStyle: TextStyle(
                                color: memSec == s ? accent : onSurface.withOpacity(0.78),
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ),
                            ),
                          ActionChip(
                            avatar: Icon(Icons.edit_outlined, size: 16, color: accent.withOpacity(0.85)),
                            label: Text(_lociText(ru: 'Своё…', en: 'Custom…', de: 'Eigene…')),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await _showCustomSessionCapDialog();
                            },
                            backgroundColor: palette.card.withOpacity(0.9),
                            labelStyle: TextStyle(color: onSurface.withOpacity(0.85), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: accent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            _lociText(ru: 'Готово', en: 'Done', de: 'Fertig'),
                            style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4),
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

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final palette = appPalette.value;
    final opacity = widget.enabled ? 1.0 : 0.55;

    return Opacity(
      opacity: opacity,
      child: IgnorePointer(
        ignoring: !widget.enabled,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildModeSelector(onSurface, palette),
              if (_mode == TrainingMode.standard) ...[
                const SizedBox(height: 32),
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
                _buildMatrixModeSwitcher(onSurface, palette),
                if (!widget.settings.matrixMode) ...[
                  const SizedBox(height: 14),
                  _buildNumberRangeSelector(onSurface, palette),
                  const SizedBox(height: 8),
                  Text(
                    _lociText(
                      ru: 'Одинаково у обоих игроков',
                      en: 'Same for both players',
                      de: 'Gleich für beide Spieler',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: onSurface.withOpacity(0.38),
                      fontSize: 9.5,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ],
              SizedBox(height: _mode == TrainingMode.standard ? 36 : 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildTimingSettingsButton(onSurface),
                ],
              ),
              const SizedBox(height: 14),
              _buildCounterSetting(
                AppTexts.get('settings_elements_count'),
                _totalCountController,
                isChunk: false,
                onSurface: onSurface,
              ),
              const SizedBox(height: 28),
              if (widget.onPersonalChunkChanged != null) ...[
                Text(
                  _lociText(
                    ru: 'На экране (только у вас)',
                    en: 'On screen (yours only)',
                    de: 'Auf dem Bildschirm (nur für dich)',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.bold,
                    color: onSurface.withOpacity(0.35),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              _buildCounterSetting(
                widget.onPersonalChunkChanged != null
                    ? _lociText(
                        ru: 'Элементов на экране',
                        en: 'Items on screen',
                        de: 'Elemente auf dem Bildschirm',
                      )
                    : AppTexts.get('settings_chunk_count'),
                _chunkSizeController,
                isChunk: true,
                onSurface: onSurface,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector(Color onSurface, AppPalette palette) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border.withOpacity(0.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _modeButton(AppTexts.get('numbers'), TrainingMode.standard, onSurface),
            _modeButton(AppTexts.get('binary'), TrainingMode.binary, onSurface),
            _modeButton(AppTexts.get('words'), TrainingMode.words, onSurface),
            _modeButton(AppTexts.get('photo'), TrainingMode.images, onSurface),
            _modeButton(AppTexts.get('cards'), TrainingMode.cards, onSurface),
            _modeButton(AppTexts.get('faces'), TrainingMode.faces, onSurface),
          ],
        ),
      ),
    );
  }

  Widget _modeButton(String label, TrainingMode mode, Color onSurface) {
    final isSelected = _mode == mode;
    return GestureDetector(
      onTap: () async {
        uiTapClick(UiClickSound.soft);
        if (mode == TrainingMode.images) {
          if (!await trainingHasInternetAccess()) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_lociText(
                  ru: 'Нужен интернет для изображений',
                  en: 'Internet required for images',
                  de: 'Internet für Bilder erforderlich',
                )),
              ),
            );
            return;
          }
        }
        setState(() => _applyMode(mode));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? appAccentColor.value.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 0.8,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w200,
            color: isSelected ? appAccentColor.value : onSurface.withOpacity(0.52),
          ),
        ),
      ),
    );
  }

  Widget _buildMatrixModeSwitcher(Color onSurface, AppPalette palette) {
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
              _subModeItem(AppTexts.get('mode_numbers_sub'), false, onSurface),
              _subModeItem(AppTexts.get('mode_matrix_sub'), true, onSurface),
            ],
          ),
        ),
        if (widget.settings.matrixMode) ...[
          const SizedBox(height: 12),
          Text(
            AppTexts.get('settings_matrix_desc'),
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

  Widget _subModeItem(String label, bool isMatrix, Color onSurface) {
    final isSelected = widget.settings.matrixMode == isMatrix;
    return GestureDetector(
      onTap: () {
        uiTapClick(UiClickSound.soft);
        _emit(widget.settings.copyWith(matrixMode: isMatrix));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? appAccentColor.value.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w200,
            color: isSelected ? appAccentColor.value : onSurface.withOpacity(0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberRangeSelector(Color onSurface, AppPalette palette) {
    return Column(
      children: [
        Text(
          _lociText(ru: 'Диапазон чисел', en: 'Number range', de: 'Zahlenbereich'),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _numberRangeItem('0-9', 1, onSurface),
              _numberRangeItem('00-99', 2, onSurface),
              _numberRangeItem('000-999', 3, onSurface),
            ],
          ),
        ),
      ],
    );
  }

  Widget _numberRangeItem(String label, int digits, Color onSurface) {
    final isSelected = widget.settings.standardDigits == digits;
    return GestureDetector(
      onTap: () {
        uiTapClick(UiClickSound.soft);
        _emit(widget.settings.copyWith(standardDigits: digits));
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

  Widget _buildTimingSettingsButton(Color onSurface) {
    final hasCap = widget.settings.memorizeSeconds > 0;
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
            Icon(Icons.timer_outlined, size: 14, color: appAccentColor.value.withOpacity(0.92)),
            const SizedBox(width: 6),
            Text(
              _lociText(ru: 'Время', en: 'Time', de: 'Zeit'),
              style: TextStyle(color: onSurface.withOpacity(0.62), fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
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
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w200, fontSize: 14, color: onSurface.withOpacity(0.62)),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _counterStepButton(
              icon: Icons.remove,
              onTap: () => _changeCounter(controller, -1, isChunk: isChunk),
              onLongPressStart: () => _startCounterHold(controller, -1, isChunk: isChunk),
              onSurface: onSurface,
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
                onChanged: (_) => _normalizeCounter(controller, isChunk: isChunk),
              ),
            ),
            _counterStepButton(
              icon: Icons.add,
              onTap: () => _changeCounter(controller, 1, isChunk: isChunk),
              onLongPressStart: () => _startCounterHold(controller, 1, isChunk: isChunk),
              onSurface: onSurface,
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
    required Color onSurface,
  }) {
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
}
