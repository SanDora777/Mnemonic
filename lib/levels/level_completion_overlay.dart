import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/core/ui_feedback.dart';
import '../recovered_app.dart'
    show AppLanguage, AppPalette, appAccentColor, appPalette;
import 'level_i18n.dart';

class LevelCompletionReward {
  const LevelCompletionReward({
    required this.xpGained,
    required this.accuracyPct,
    required this.speedBonus,
    required this.streakDays,
    required this.levelNumber,
    required this.pathLabel,
  });

  final int xpGained;
  final double accuracyPct;
  final bool speedBonus;
  final int streakDays;
  final int levelNumber;
  final String pathLabel;
}

/// Fullscreen reward after passing a trainer level challenge.
class LevelCompletionOverlay extends StatefulWidget {
  const LevelCompletionOverlay({
    super.key,
    required this.reward,
    required this.onDismiss,
  });

  final LevelCompletionReward reward;
  final VoidCallback onDismiss;

  @override
  State<LevelCompletionOverlay> createState() => _LevelCompletionOverlayState();
}

class _LevelCompletionOverlayState extends State<LevelCompletionOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _entry;
  late final AnimationController _particles;
  late final Animation<double> _fill;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _particles = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _fill = CurvedAnimation(parent: _entry, curve: const Interval(0.2, 0.85, curve: Curves.easeOutCubic));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _entry.forward();
    });
  }

  @override
  void dispose() {
    _entry.dispose();
    _particles.dispose();
    super.dispose();
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
            return Material(
              color: palette.background.withOpacity(0.97),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _ParticleField(accent: accent, controller: _particles),
                  SafeArea(
                    child: AnimatedBuilder(
                      animation: _entry,
                      builder: (context, child) {
                        final slide = Tween<Offset>(
                          begin: const Offset(0, 0.06),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic));
                        return FadeTransition(
                          opacity: CurvedAnimation(parent: _entry, curve: Curves.easeOut),
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _GlowRing(accent: accent, progress: _fill),
                            const SizedBox(height: 36),
                            Text(
                              levelTxt({
                                AppLanguage.ru: 'СИЛА ПАМЯТИ РАСТЁТ',
                                AppLanguage.en: 'MEMORY STRENGTH INCREASED',
                                AppLanguage.de: 'GEDÄCHTNIS STÄRKER',
                              }),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 3.2,
                                fontWeight: FontWeight.w800,
                                color: onSurface.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              '+${widget.reward.xpGained} XP',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w200,
                                color: accent,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 28),
                            _RewardRow(
                              icon: Icons.bolt_rounded,
                              label: levelTxt({
                                AppLanguage.ru: 'Бонус скорости',
                                AppLanguage.en: 'Speed bonus',
                                AppLanguage.de: 'Tempo-Bonus',
                              }),
                              active: widget.reward.speedBonus,
                              accent: accent,
                              onSurface: onSurface,
                            ),
                            const SizedBox(height: 12),
                            _RewardRow(
                              icon: Icons.track_changes_rounded,
                              label: levelTxt({
                                AppLanguage.ru: 'Точность',
                                AppLanguage.en: 'Accuracy',
                                AppLanguage.de: 'Genauigkeit',
                              }),
                              detail: '${widget.reward.accuracyPct.toStringAsFixed(0)}%',
                              active: true,
                              accent: accent,
                              onSurface: onSurface,
                            ),
                            const SizedBox(height: 12),
                            _RewardRow(
                              icon: Icons.local_fire_department_rounded,
                              label: levelTxt({
                                AppLanguage.ru: 'Серия',
                                AppLanguage.en: 'Streak',
                                AppLanguage.de: 'Serie',
                              }),
                              detail: '${widget.reward.streakDays}',
                              active: widget.reward.streakDays > 0,
                              accent: accent,
                              onSurface: onSurface,
                            ),
                            const SizedBox(height: 48),
                            Text(
                              widget.reward.pathLabel,
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 2,
                                color: onSurface.withOpacity(0.35),
                              ),
                            ),
                            Text(
                              levelTxt({
                                AppLanguage.ru: 'Уровень ${widget.reward.levelNumber}',
                                AppLanguage.en: 'Level ${widget.reward.levelNumber}',
                                AppLanguage.de: 'Stufe ${widget.reward.levelNumber}',
                              }),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: onSurface.withOpacity(0.55),
                              ),
                            ),
                            const SizedBox(height: 40),
                            GestureDetector(
                              onTap: () {
                                uiTapClick(UiClickSound.soft);
                                widget.onDismiss();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: accent.withOpacity(0.45),
                                  ),
                                ),
                                child: Text(
                                  levelTxt({
                                    AppLanguage.ru: 'ПРОДОЛЖИТЬ',
                                    AppLanguage.en: 'CONTINUE',
                                    AppLanguage.de: 'WEITER',
                                  }),
                                  style: TextStyle(
                                    color: accent,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2.5,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _GlowRing extends StatelessWidget {
  const _GlowRing({required this.accent, required this.progress});

  final Color accent;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        return SizedBox(
          width: 88,
          height: 88,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: CircularProgressIndicator(
                  value: progress.value,
                  strokeWidth: 2.5,
                  backgroundColor: accent.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation(accent.withOpacity(0.9)),
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(0.12),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.35 * progress.value),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: accent.withOpacity(0.95),
                  size: 32,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.icon,
    required this.label,
    required this.active,
    required this.accent,
    required this.onSurface,
    this.detail,
  });

  final IconData icon;
  final String label;
  final bool active;
  final Color accent;
  final Color onSurface;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 18,
          color: active ? accent.withOpacity(0.9) : onSurface.withOpacity(0.2),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: onSurface.withOpacity(active ? 0.75 : 0.3),
            fontWeight: FontWeight.w500,
          ),
        ),
        if (detail != null) ...[
          const SizedBox(width: 8),
          Text(
            detail!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: accent.withOpacity(0.85),
            ),
          ),
        ],
      ],
    );
  }
}

class _ParticleField extends StatelessWidget {
  const _ParticleField({required this.accent, required this.controller});

  final Color accent;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ParticlePainter(
            accent: accent,
            t: controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.accent, required this.t});

  final Color accent;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(42);
    for (var i = 0; i < 28; i++) {
      final bx = rnd.nextDouble() * size.width;
      final by = rnd.nextDouble() * size.height;
      final phase = (t + i * 0.07) % 1.0;
      final y = by - phase * 40;
      final opacity = (1 - phase) * 0.35;
      final paint = Paint()..color = accent.withOpacity(opacity.clamp(0.0, 0.4));
      canvas.drawCircle(Offset(bx, y), 1.2 + rnd.nextDouble(), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.t != t;
}
