import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/core/ui_feedback.dart';
import '../recovered_app.dart'
    show AppLanguage, AppPalette, appAccentColor, appPalette;
import 'level_definitions.dart';
import 'level_i18n.dart';
import 'level_setup_preview.dart' show levelTimeRequirementLabel;
import 'level_trainer_settings.dart';

/// Config returned when user starts a level from the level menu.
class LevelStartResult {
  const LevelStartResult({
    required this.level,
    required this.settings,
  });

  final TrainerLevelDef level;
  final LevelTrainerSettingsSnapshot settings;
}

class LevelDetailScreen extends StatefulWidget {
  const LevelDetailScreen({
    super.key,
    required this.level,
    required this.initialSettings,
    this.lociRouteLabels = const [],
  });

  final TrainerLevelDef level;
  final LevelTrainerSettingsSnapshot initialSettings;
  final List<String> lociRouteLabels;

  @override
  State<LevelDetailScreen> createState() => _LevelDetailScreenState();
}

class _LevelDetailScreenState extends State<LevelDetailScreen> {
  late LevelTrainerSettingsSnapshot _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppPalette>(
      valueListenable: appPalette,
      builder: (context, palette, _) {
        return ValueListenableBuilder<Color>(
          valueListenable: appAccentColor,
          builder: (context, accent, _) {
            final onSurface = Theme.of(context).colorScheme.onSurface;
            final level = widget.level;
            return Scaffold(
              backgroundColor: palette.background,
              body: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_ios_new_rounded,
                              size: 18, color: onSurface.withOpacity(0.65)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Text(
                        levelTxt({
                          AppLanguage.ru: 'УРОВЕНЬ ${level.displayNumber}',
                          AppLanguage.en: 'LEVEL ${level.displayNumber}',
                          AppLanguage.de: 'STUFE ${level.displayNumber}',
                        }),
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 3.5,
                          fontWeight: FontWeight.w800,
                          color: onSurface.withOpacity(0.45),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        levelGoalTitle(level),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w200,
                          color: onSurface,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _InfoBlock(
                        label: levelTxt({
                          AppLanguage.ru: 'Цель',
                          AppLanguage.en: 'Goal',
                          AppLanguage.de: 'Ziel',
                        }),
                        value: elementUnitLabel(level.path, level.elementCount),
                        onSurface: onSurface,
                        accent: accent,
                      ),
                      const SizedBox(height: 12),
                      _InfoBlock(
                        label: levelTxt({
                          AppLanguage.ru: 'Точность',
                          AppLanguage.en: 'Accuracy',
                          AppLanguage.de: 'Genauigkeit',
                        }),
                        value: '${level.requiredAccuracy.toStringAsFixed(0)}%',
                        onSurface: onSurface,
                        accent: accent,
                      ),
                      const SizedBox(height: 12),
                      _InfoBlock(
                        label: levelTxt({
                          AppLanguage.ru: 'Время',
                          AppLanguage.en: 'Time',
                          AppLanguage.de: 'Zeit',
                        }),
                        value: levelTimeRequirementLabel(level),
                        onSurface: onSurface,
                        accent: accent,
                      ),
                      const SizedBox(height: 24),
                      Container(height: 1, color: onSurface.withOpacity(0.08)),
                      const SizedBox(height: 20),
                      Text(
                        levelTxt({
                          AppLanguage.ru: 'Настройка',
                          AppLanguage.en: 'Setup',
                          AppLanguage.de: 'Setup',
                        }),
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                          color: onSurface.withOpacity(0.38),
                        ),
                      ),
                      const SizedBox(height: 14),
                      LevelTrainerSettingsPanel(
                        path: level.path,
                        settings: _settings,
                        lociRouteLabels: widget.lociRouteLabels,
                        onChanged: (s) => setState(() => _settings = s),
                      ),
                      const SizedBox(height: 28),
                      _StartButton(
                        accent: accent,
                        palette: palette,
                        label: levelTxt({
                          AppLanguage.ru: 'СТАРТ',
                          AppLanguage.en: 'START',
                          AppLanguage.de: 'START',
                        }),
                        onTap: () {
                          uiTapClick(UiClickSound.bright);
                          Navigator.pop(
                            context,
                            LevelStartResult(level: level, settings: _settings),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.label,
    required this.value,
    required this.onSurface,
    required this.accent,
  });

  final String label;
  final String value;
  final Color onSurface;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
            color: onSurface.withOpacity(0.35),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: accent.withOpacity(0.92),
          ),
        ),
      ],
    );
  }
}

class _StartButton extends StatefulWidget {
  const _StartButton({
    required this.accent,
    required this.palette,
    required this.label,
    required this.onTap,
  });

  final Color accent;
  final AppPalette palette;
  final String label;
  final VoidCallback onTap;

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()..scale(_pressed ? 0.98 : 1.0),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              widget.accent.withOpacity(0.92),
              widget.accent.withOpacity(0.55),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: widget.accent.withOpacity(0.38),
              blurRadius: 22,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: TextStyle(
            color: widget.palette.background.withOpacity(0.95),
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
