import 'dart:async';

import 'package:flutter/material.dart';
import '../app/core/ui_feedback.dart';
import '../recovered_app.dart'
    show
        AppLanguage,
        AppPalette,
        AppTexts,
        TrainingMode,
        appAccentColor,
        appPalette,
        maxChunkForTrainingMode;
import 'level_definitions.dart';
import 'level_i18n.dart';

/// Snapshot of trainer options edited inside the level menu.
class LevelTrainerSettingsSnapshot {
  LevelTrainerSettingsSnapshot({
    required this.mode,
    required this.standardDigits,
    required this.isMatrixMode,
    required this.chunkSize,
    required this.lociRouteIndex,
    required this.hasLoci,
    required this.sessionMemCapSec,
    required this.useMemorizationTimer,
    required this.flashSeconds,
    required this.cardsShuffledDeck,
    required this.faceNamePool,
  });

  final TrainingMode mode;
  final int standardDigits;
  final bool isMatrixMode;
  final int chunkSize;
  final int lociRouteIndex;
  final bool hasLoci;
  final int sessionMemCapSec;
  final bool useMemorizationTimer;
  final double flashSeconds;
  final bool cardsShuffledDeck;
  final String faceNamePool;

  LevelTrainerSettingsSnapshot copyWith({
    int? standardDigits,
    bool? isMatrixMode,
    int? chunkSize,
    int? lociRouteIndex,
    bool? hasLoci,
    int? sessionMemCapSec,
    bool? useMemorizationTimer,
    double? flashSeconds,
    bool? cardsShuffledDeck,
    String? faceNamePool,
  }) {
    return LevelTrainerSettingsSnapshot(
      mode: mode,
      standardDigits: standardDigits ?? this.standardDigits,
      isMatrixMode: isMatrixMode ?? this.isMatrixMode,
      chunkSize: chunkSize ?? this.chunkSize,
      lociRouteIndex: lociRouteIndex ?? this.lociRouteIndex,
      hasLoci: hasLoci ?? this.hasLoci,
      sessionMemCapSec: sessionMemCapSec ?? this.sessionMemCapSec,
      useMemorizationTimer: useMemorizationTimer ?? this.useMemorizationTimer,
      flashSeconds: flashSeconds ?? this.flashSeconds,
      cardsShuffledDeck: cardsShuffledDeck ?? this.cardsShuffledDeck,
      faceNamePool: faceNamePool ?? this.faceNamePool,
    );
  }
}

/// Inline trainer settings (same options as pre-memorize screen).
class LevelTrainerSettingsPanel extends StatefulWidget {
  const LevelTrainerSettingsPanel({
    super.key,
    required this.path,
    required this.settings,
    required this.onChanged,
    this.lociRouteLabels = const [],
  });

  final LevelPath path;
  final LevelTrainerSettingsSnapshot settings;
  final ValueChanged<LevelTrainerSettingsSnapshot> onChanged;
  final List<String> lociRouteLabels;

  @override
  State<LevelTrainerSettingsPanel> createState() =>
      _LevelTrainerSettingsPanelState();
}

class _LevelTrainerSettingsPanelState extends State<LevelTrainerSettingsPanel> {
  late final TextEditingController _chunkController;
  Timer? _counterHoldTimer;

  TrainingMode get _mode => LevelDefinitions.trainingModeForPath(widget.path);

  int get _maxChunk => maxChunkForTrainingMode(_mode);

  @override
  void initState() {
    super.initState();
    _chunkController =
        TextEditingController(text: '${widget.settings.chunkSize}');
  }

  @override
  void didUpdateWidget(covariant LevelTrainerSettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = '${widget.settings.chunkSize}';
    if (_chunkController.text != next) {
      _chunkController.text = next;
    }
  }

  @override
  void dispose() {
    _counterHoldTimer?.cancel();
    _chunkController.dispose();
    super.dispose();
  }

  void _emitChunk(int value) {
    widget.onChanged(widget.settings.copyWith(chunkSize: value));
  }

  void _normalizeChunkCounter() {
    if (_chunkController.text.isEmpty) return;
    var val = int.tryParse(_chunkController.text) ?? 1;
    val = val.clamp(1, _maxChunk);
    if (_chunkController.text != '$val') {
      _chunkController.text = '$val';
      _chunkController.selection =
          TextSelection.collapsed(offset: _chunkController.text.length);
    }
    if (val != widget.settings.chunkSize) {
      _emitChunk(val);
    }
  }

  void _changeChunkCounter(int delta) {
    var val = int.tryParse(_chunkController.text) ?? widget.settings.chunkSize;
    val = (val + delta).clamp(1, _maxChunk);
    setState(() => _chunkController.text = '$val');
    _emitChunk(val);
  }

  void _startChunkCounterHold(int delta) {
    _counterHoldTimer?.cancel();
    _changeChunkCounter(delta);
    _counterHoldTimer = Timer.periodic(const Duration(milliseconds: 90), (_) {
      _changeChunkCounter(delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final palette = appPalette.value;
    final accent = appAccentColor.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_mode == TrainingMode.standard) ...[
          _sectionLabel(onSurface, AppTexts.get('modes_title')),
          const SizedBox(height: 10),
          _chipRow(
            palette: palette,
            accent: accent,
            onSurface: onSurface,
            children: [
              _chip(
                label: AppTexts.get('mode_numbers_sub'),
                selected: !widget.settings.isMatrixMode,
                onTap: () => widget.onChanged(
                    widget.settings.copyWith(isMatrixMode: false)),
                accent: accent,
                onSurface: onSurface,
              ),
              _chip(
                label: AppTexts.get('mode_matrix_sub'),
                selected: widget.settings.isMatrixMode,
                onTap: () =>
                    widget.onChanged(widget.settings.copyWith(isMatrixMode: true)),
                accent: accent,
                onSurface: onSurface,
              ),
            ],
          ),
          if (!widget.settings.isMatrixMode) ...[
            const SizedBox(height: 14),
            _sectionLabel(
              onSurface,
              levelTxt({
                AppLanguage.ru: 'Диапазон чисел',
                AppLanguage.en: 'Number range',
                AppLanguage.de: 'Zahlenbereich',
              }),
            ),
            const SizedBox(height: 8),
            _chipRow(
              palette: palette,
              accent: accent,
              onSurface: onSurface,
              children: [
                for (final e in [(1, '0-9'), (2, '00-99'), (3, '000-999')])
                  _chip(
                    label: e.$2,
                    selected: widget.settings.standardDigits == e.$1,
                    onTap: () => widget.onChanged(
                        widget.settings.copyWith(standardDigits: e.$1)),
                    accent: accent,
                    onSurface: onSurface,
                  ),
              ],
            ),
          ],
        ],
        if (_mode == TrainingMode.cards) ...[
          const SizedBox(height: 16),
          _sectionLabel(onSurface, AppTexts.get('modes_title')),
          const SizedBox(height: 10),
          _chipRow(
            palette: palette,
            accent: accent,
            onSurface: onSurface,
            children: [
              _chip(
                label: AppTexts.get('mode_cards_random_sub'),
                selected: !widget.settings.cardsShuffledDeck,
                onTap: () => widget.onChanged(
                    widget.settings.copyWith(cardsShuffledDeck: false)),
                accent: accent,
                onSurface: onSurface,
              ),
              _chip(
                label: AppTexts.get('mode_cards_deck_sub'),
                selected: widget.settings.cardsShuffledDeck,
                onTap: () => widget.onChanged(
                    widget.settings.copyWith(cardsShuffledDeck: true)),
                accent: accent,
                onSurface: onSurface,
              ),
            ],
          ),
        ],
        if (_mode == TrainingMode.faces) ...[
          const SizedBox(height: 16),
          _sectionLabel(
            onSurface,
            levelTxt({
              AppLanguage.ru: 'Имена',
              AppLanguage.en: 'Names',
              AppLanguage.de: 'Namen',
            }),
          ),
          const SizedBox(height: 8),
          _chipRow(
            palette: palette,
            accent: accent,
            onSurface: onSurface,
            children: [
              for (final pool in ['ENGNAME', 'RUNAME', 'GERNAME'])
                _chip(
                  label: pool,
                  selected: widget.settings.faceNamePool == pool,
                  onTap: () =>
                      widget.onChanged(widget.settings.copyWith(faceNamePool: pool)),
                  accent: accent,
                  onSurface: onSurface,
                ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        _buildChunkCounter(onSurface: onSurface, accent: accent),
        const SizedBox(height: 14),
        _chipRow(
          palette: palette,
          accent: accent,
          onSurface: onSurface,
          children: [
            _chip(
              label: widget.settings.hasLoci
                  ? levelTxt({
                      AppLanguage.ru: 'Локусы ВКЛ',
                      AppLanguage.en: 'Loci ON',
                      AppLanguage.de: 'Loci AN',
                    })
                  : levelTxt({
                      AppLanguage.ru: 'Локусы ВЫКЛ',
                      AppLanguage.en: 'Loci OFF',
                      AppLanguage.de: 'Loci AUS',
                    }),
              selected: widget.settings.hasLoci,
              onTap: () {
                if (widget.lociRouteLabels.isEmpty) return;
                final next = !widget.settings.hasLoci;
                widget.onChanged(widget.settings.copyWith(
                  hasLoci: next,
                  lociRouteIndex: next
                      ? 0.clamp(0, widget.lociRouteLabels.length - 1)
                      : -1,
                ));
              },
              accent: accent,
              onSurface: onSurface,
            ),
          ],
        ),
        if (widget.settings.hasLoci && widget.lociRouteLabels.isNotEmpty) ...[
          const SizedBox(height: 10),
          _chipRow(
            palette: palette,
            accent: accent,
            onSurface: onSurface,
            children: [
              for (var i = 0;
                  i < widget.lociRouteLabels.length && i < 4;
                  i++)
                _chip(
                  label: widget.lociRouteLabels[i].length > 12
                      ? '${widget.lociRouteLabels[i].substring(0, 12)}…'
                      : widget.lociRouteLabels[i],
                  selected: widget.settings.lociRouteIndex == i,
                  onTap: () =>
                      widget.onChanged(widget.settings.copyWith(lociRouteIndex: i)),
                  accent: accent,
                  onSurface: onSurface,
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _sectionLabel(Color onSurface, String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 9,
        letterSpacing: 2,
        fontWeight: FontWeight.w700,
        color: onSurface.withOpacity(0.35),
      ),
    );
  }

  Widget _chipRow({
    required AppPalette palette,
    required Color accent,
    required Color onSurface,
    required List<Widget> children,
  }) {
    return Container(
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
        children: children,
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color accent,
    required Color onSurface,
  }) {
    return GestureDetector(
      onTap: () {
        appHaptic(UiClickSound.deep);
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w300,
            color: selected ? accent : onSurface.withOpacity(0.45),
          ),
        ),
      ),
    );
  }

  Widget _buildChunkCounter({
    required Color onSurface,
    required Color accent,
  }) {
    return Column(
      children: [
        Text(
          AppTexts.get('settings_chunk_count'),
          style: TextStyle(
            fontWeight: FontWeight.w200,
            fontSize: 14,
            color: onSurface.withOpacity(0.62),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _chunkStepButton(
              icon: Icons.remove,
              onSurface: onSurface,
              onTap: () => _changeChunkCounter(-1),
              onLongPressStart: () => _startChunkCounterHold(-1),
            ),
            Container(
              width: 96,
              height: 50,
              alignment: Alignment.center,
              child: TextField(
                controller: _chunkController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w200,
                  color: accent,
                ),
                decoration:
                    const InputDecoration(border: InputBorder.none, isCollapsed: true),
                onChanged: (_) => _normalizeChunkCounter(),
              ),
            ),
            _chunkStepButton(
              icon: Icons.add,
              onSurface: onSurface,
              onTap: () => _changeChunkCounter(1),
              onLongPressStart: () => _startChunkCounterHold(1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chunkStepButton({
    required IconData icon,
    required Color onSurface,
    required VoidCallback onTap,
    required VoidCallback onLongPressStart,
  }) {
    return GestureDetector(
      onTap: () {
        appHaptic(UiClickSound.soft);
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
