import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/core/ui_feedback.dart';
import '../recovered_app.dart'
    show AppPalette, appAccentColor, appPalette;
import 'level_definitions.dart';
import 'level_detail_screen.dart';
import 'level_i18n.dart';
import 'level_progress_service.dart';
import 'level_trainer_settings.dart';

class LevelsPathScreen extends StatefulWidget {
  const LevelsPathScreen({
    super.key,
    required this.path,
    required this.initialSettings,
    this.lociRouteLabels = const [],
  });

  final LevelPath path;
  final LevelTrainerSettingsSnapshot initialSettings;
  final List<String> lociRouteLabels;

  @override
  State<LevelsPathScreen> createState() => _LevelsPathScreenState();
}

class _LevelsPathScreenState extends State<LevelsPathScreen>
    with SingleTickerProviderStateMixin {
  Set<String> _completed = {};
  bool _loading = true;
  late final AnimationController _ambient;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    unawaited(_reload());
  }

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final c = await LevelProgressService.instance.completedIds();
    if (mounted) {
      setState(() {
        _completed = c;
        _loading = false;
      });
    }
  }

  Future<bool> _unlocked(TrainerLevelDef level) async {
    final all = LevelDefinitions.levelsForPath(widget.path);
    final idx = all.indexWhere((l) => l.id == level.id);
    if (idx <= 0) return true;
    return _completed.contains(all[idx - 1].id);
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
            return Scaffold(
              backgroundColor: palette.background,
              body: Stack(
                fit: StackFit.expand,
                children: [
                  _PathGlow(accent: accent, controller: _ambient),
                  SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.arrow_back_ios_new_rounded,
                                    size: 18, color: onSurface.withOpacity(0.7)),
                                onPressed: () => Navigator.pop(context),
                              ),
                              Expanded(
                                child: Text(
                                  pathTitle(widget.path),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 3.2,
                                    fontWeight: FontWeight.w800,
                                    color: onSurface.withOpacity(0.55),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 48),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _loading
                              ? Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: accent.withOpacity(0.6),
                                  ),
                                )
                              : ListView(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                                  children: [
                                    for (final tierEntry
                                        in LevelDefinitions.tiersForPath(widget.path))
                                      _TierSection(
                                        path: widget.path,
                                        tier: tierEntry.$1,
                                        emoji: tierEntry.$2,
                                        accent: accent,
                                        palette: palette,
                                        onSurface: onSurface,
                                        completed: _completed,
                                        unlockedFn: _unlocked,
                                        onLevelTap: (level, unlocked) async {
                                          if (!unlocked) {
                                            uiTapClick(UiClickSound.soft);
                                            return;
                                          }
                                          uiTapClick(UiClickSound.soft);
                                          final result =
                                              await Navigator.push<LevelStartResult>(
                                            context,
                                            PageRouteBuilder<LevelStartResult>(
                                              pageBuilder: (_, __, ___) =>
                                                  LevelDetailScreen(
                                                level: level,
                                                initialSettings:
                                                    widget.initialSettings,
                                                lociRouteLabels:
                                                    widget.lociRouteLabels,
                                              ),
                                              transitionsBuilder: (_, anim, __, child) {
                                                return FadeTransition(
                                                  opacity: anim,
                                                  child: child,
                                                );
                                              },
                                              transitionDuration:
                                                  const Duration(milliseconds: 280),
                                            ),
                                          );
                                          if (result != null && context.mounted) {
                                            Navigator.pop(context, result);
                                          }
                                        },
                                      ),
                                  ],
                                ),
                        ),
                      ],
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

class _TierSection extends StatelessWidget {
  const _TierSection({
    required this.path,
    required this.tier,
    required this.emoji,
    required this.accent,
    required this.palette,
    required this.onSurface,
    required this.completed,
    required this.unlockedFn,
    required this.onLevelTap,
  });

  final LevelPath path;
  final LevelTier tier;
  final String emoji;
  final Color accent;
  final AppPalette palette;
  final Color onSurface;
  final Set<String> completed;
  final Future<bool> Function(TrainerLevelDef) unlockedFn;
  final void Function(TrainerLevelDef level, bool unlocked) onLevelTap;

  @override
  Widget build(BuildContext context) {
    final levels = LevelDefinitions.levelsInTier(path, tier);
    return Padding(
      padding: const EdgeInsets.only(bottom: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Text(
                tierLabel(tier).toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: onSurface.withOpacity(0.72),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _LevelNodeRow(
            levels: levels,
            accent: accent,
            palette: palette,
            onSurface: onSurface,
            completed: completed,
            unlockedFn: unlockedFn,
            onLevelTap: onLevelTap,
          ),
        ],
      ),
    );
  }
}

class _LevelNodeRow extends StatefulWidget {
  const _LevelNodeRow({
    required this.levels,
    required this.accent,
    required this.palette,
    required this.onSurface,
    required this.completed,
    required this.unlockedFn,
    required this.onLevelTap,
  });

  final List<TrainerLevelDef> levels;
  final Color accent;
  final AppPalette palette;
  final Color onSurface;
  final Set<String> completed;
  final Future<bool> Function(TrainerLevelDef) unlockedFn;
  final void Function(TrainerLevelDef level, bool unlocked) onLevelTap;

  @override
  State<_LevelNodeRow> createState() => _LevelNodeRowState();
}

class _LevelNodeRowState extends State<_LevelNodeRow> {
  final Map<String, bool> _unlockCache = {};

  @override
  void initState() {
    super.initState();
    unawaited(_loadUnlocks());
  }

  @override
  void didUpdateWidget(covariant _LevelNodeRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.completed != widget.completed) {
      unawaited(_loadUnlocks());
    }
  }

  Future<void> _loadUnlocks() async {
    for (final l in widget.levels) {
      _unlockCache[l.id] = await widget.unlockedFn(l);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = widget.levels.length;
        if (count == 0) return const SizedBox.shrink();
        final nodeSize = 36.0;
        final spacing = count <= 4
            ? (constraints.maxWidth - count * nodeSize) / (count + 1)
            : 12.0;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (var i = 0; i < count; i++) ...[
                if (i > 0)
                  _Connector(
                    width: spacing.clamp(16, 48),
                    accent: widget.accent,
                    lit: widget.completed.contains(widget.levels[i - 1].id),
                  ),
                _LevelNode(
                  level: widget.levels[i],
                  accent: widget.accent,
                  palette: widget.palette,
                  onSurface: widget.onSurface,
                  completed: widget.completed.contains(widget.levels[i].id),
                  unlocked: _unlockCache[widget.levels[i].id] ?? (i == 0),
                  onTap: () => widget.onLevelTap(
                    widget.levels[i],
                    _unlockCache[widget.levels[i].id] ?? (i == 0),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector({
    required this.width,
    required this.accent,
    required this.lit,
  });

  final double width;
  final Color accent;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: LinearGradient(
            colors: [
              lit ? accent.withOpacity(0.75) : accent.withOpacity(0.12),
              lit ? accent.withOpacity(0.35) : accent.withOpacity(0.08),
            ],
          ),
          boxShadow: lit
              ? [BoxShadow(color: accent.withOpacity(0.35), blurRadius: 8)]
              : null,
        ),
      ),
    );
  }
}

class _LevelNode extends StatefulWidget {
  const _LevelNode({
    required this.level,
    required this.accent,
    required this.palette,
    required this.onSurface,
    required this.completed,
    required this.unlocked,
    required this.onTap,
  });

  final TrainerLevelDef level;
  final Color accent;
  final AppPalette palette;
  final Color onSurface;
  final bool completed;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  State<_LevelNode> createState() => _LevelNodeState();
}

class _LevelNodeState extends State<_LevelNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.completed) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _LevelNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.completed && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.completed) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locked = !widget.unlocked;
    final done = widget.completed;
    final active = widget.unlocked && !done;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final glow = done ? 0.15 + _pulse.value * 0.2 : 0.0;
          return Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.palette.surface.withOpacity(locked ? 0.4 : 0.95),
              border: Border.all(
                width: done || active ? 1.4 : 0.9,
                color: locked
                    ? widget.onSurface.withOpacity(0.15)
                    : done
                        ? widget.accent.withOpacity(0.85)
                        : active
                            ? widget.accent.withOpacity(0.55)
                            : widget.onSurface.withOpacity(0.2),
              ),
              boxShadow: [
                if (done || active)
                  BoxShadow(
                    color: widget.accent.withOpacity(glow + (active ? 0.18 : 0.28)),
                    blurRadius: done ? 16 : 10,
                  ),
              ],
            ),
            alignment: Alignment.center,
            child: locked
                ? Icon(Icons.lock_rounded,
                    size: 14, color: widget.onSurface.withOpacity(0.28))
                : done
                    ? Icon(Icons.check_rounded,
                        size: 16, color: widget.accent.withOpacity(0.95))
                    : Text(
                        '${widget.level.displayNumber}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: widget.onSurface.withOpacity(0.85),
                        ),
                      ),
          );
        },
      ),
    );
  }
}

class _PathGlow extends StatelessWidget {
  const _PathGlow({required this.accent, required this.controller});

  final Color accent;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value * 2 * math.pi;
        return CustomPaint(
          painter: _GlowPainter(
            accent: accent,
            phase: t,
          ),
        );
      },
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter({required this.accent, required this.phase});

  final Color accent;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.08);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          accent.withOpacity(0.14 + 0.04 * math.sin(phase)),
          accent.withOpacity(0.02),
          Colors.transparent,
        ],
        stops: const [0, 0.45, 1],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.9));
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowPainter old) => old.phase != phase;
}
