import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app/core/ui_feedback.dart';
import '../recovered_app.dart'
    show AppLanguage, AppPalette, AppTexts, appLanguage, appPalette;

enum _PremiumPlan { monthly, quarterly }

Color _accentDeep(Color accent, Color background) =>
    Color.lerp(accent, background, 0.32)!;

Color _accentLight(Color accent, Color surface) =>
    Color.lerp(accent, surface, 0.38)!;

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ambient;
  late final AnimationController _entry;
  _PremiumPlan _selected = _PremiumPlan.monthly;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _ambient.dispose();
    _entry.dispose();
    super.dispose();
  }

  String _t(Map<AppLanguage, String> m) => AppTexts.translate(m);

  double _entryT(double start, double end) {
    final v = ((_entry.value - start) / (end - start)).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(v);
  }

  Future<void> _onPurchase(AppPalette palette) async {
    uiTapClick(UiClickSound.bright);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.accent,
        content: Text(
          _t(const {
            AppLanguage.ru: 'Оплата скоро будет доступна',
            AppLanguage.en: 'Payment coming soon',
            AppLanguage.de: 'Zahlung demnächst verfügbar',
          }),
          style: TextStyle(
            color: palette.background,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, _, __) {
        return ValueListenableBuilder<AppPalette>(
          valueListenable: appPalette,
          builder: (context, palette, ___) {
            final accent = palette.accent;
            final accentDeep = _accentDeep(accent, palette.background);
            final onSurface = Theme.of(context).colorScheme.onSurface;
            return Scaffold(
              backgroundColor: palette.background,
              body: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedBuilder(
                    animation: _ambient,
                    builder: (_, __) {
                      return CustomPaint(
                        painter: _PremiumBackdropPainter(
                          t: _ambient.value,
                          background: palette.background,
                          accent: accent,
                          accentDeep: accentDeep,
                        ),
                        size: Size.infinite,
                      );
                    },
                  ),
                  SafeArea(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_entry, _ambient]),
                      builder: (context, _) {
                        final heroT = _entryT(0.0, 0.35);
                        final titleT = _entryT(0.08, 0.42);
                        final benefitsT = _entryT(0.18, 0.62);
                        final plansT = _entryT(0.34, 0.78);
                        final ctaT = _entryT(0.5, 0.92);

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: Icon(
                                      Icons.close_rounded,
                                      color: onSurface.withOpacity(0.65),
                                    ),
                                  ),
                                  Expanded(
                                    child: RepaintBoundary(
                                      child: Opacity(
                                        opacity: titleT,
                                        child: Text(
                                          _t(const {
                                            AppLanguage.ru: 'PREMIUM',
                                            AppLanguage.en: 'PREMIUM',
                                            AppLanguage.de: 'PREMIUM',
                                          }),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: onSurface.withOpacity(0.85),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 4,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 48),
                                ],
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                                child: Column(
                                  children: [
                                    Opacity(
                                      opacity: heroT,
                                      child: Transform.scale(
                                        scale: 0.88 + 0.12 * heroT,
                                        child: _HeroCrown(
                                          ambient: _ambient,
                                          accent: accent,
                                          accentDeep: accentDeep,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Opacity(
                                      opacity: titleT,
                                      child: Transform.translate(
                                        offset: Offset(0, (1 - titleT) * 16),
                                        child: Column(
                                          children: [
                                            Text(
                                              _t(const {
                                                AppLanguage.ru: 'Mneem Premium',
                                                AppLanguage.en: 'Mneem Premium',
                                                AppLanguage.de: 'Mneem Premium',
                                              }),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: onSurface,
                                                fontSize: 28,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -0.4,
                                                height: 1.1,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              _t(const {
                                                AppLanguage.ru:
                                                    'Больше фокуса, меньше отвлечений — вся сила приложения без ограничений.',
                                                AppLanguage.en:
                                                    'More focus, fewer distractions — the full app without limits.',
                                                AppLanguage.de:
                                                    'Mehr Fokus, weniger Ablenkung — die volle App ohne Grenzen.',
                                              }),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: onSurface.withOpacity(0.62),
                                                fontSize: 14,
                                                height: 1.45,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    Opacity(
                                      opacity: benefitsT,
                                      child: Transform.translate(
                                        offset: Offset(0, (1 - benefitsT) * 20),
                                        child: _BenefitsCard(
                                          onSurface: onSurface,
                                          palette: palette,
                                          ambient: _ambient,
                                          accent: accent,
                                          accentDeep: accentDeep,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 22),
                                    Opacity(
                                      opacity: plansT,
                                      child: Transform.translate(
                                        offset: Offset(0, (1 - plansT) * 24),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Text(
                                              _t(const {
                                                AppLanguage.ru: 'Выбери план',
                                                AppLanguage.en: 'Choose a plan',
                                                AppLanguage.de: 'Plan wählen',
                                              }),
                                              style: TextStyle(
                                                color: onSurface.withOpacity(0.55),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1.8,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            _PlanCard(
                                              selected:
                                                  _selected == _PremiumPlan.monthly,
                                              recommended: false,
                                              ambient: _ambient,
                                              onSurface: onSurface,
                                              palette: palette,
                                              accent: accent,
                                              accentDeep: accentDeep,
                                              title: _t(const {
                                                AppLanguage.ru: '1 месяц',
                                                AppLanguage.en: '1 month',
                                                AppLanguage.de: '1 Monat',
                                              }),
                                              price: '4,99 €',
                                              period: _t(const {
                                                AppLanguage.ru: 'в месяц',
                                                AppLanguage.en: 'per month',
                                                AppLanguage.de: 'pro Monat',
                                              }),
                                              badge: _t(const {
                                                AppLanguage.ru: 'Стандарт',
                                                AppLanguage.en: 'Standard',
                                                AppLanguage.de: 'Standard',
                                              }),
                                              onTap: () => setState(
                                                () => _selected =
                                                    _PremiumPlan.monthly,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            _PlanCard(
                                              selected: _selected ==
                                                  _PremiumPlan.quarterly,
                                              recommended: true,
                                              ambient: _ambient,
                                              onSurface: onSurface,
                                              palette: palette,
                                              accent: accent,
                                              accentDeep: accentDeep,
                                              title: _t(const {
                                                AppLanguage.ru: '3 месяца',
                                                AppLanguage.en: '3 months',
                                                AppLanguage.de: '3 Monate',
                                              }),
                                              price: '9,99 €',
                                              period: _t(const {
                                                AppLanguage.ru: 'за 3 месяца',
                                                AppLanguage.en: 'for 3 months',
                                                AppLanguage.de: 'für 3 Monate',
                                              }),
                                              badge: _t(const {
                                                AppLanguage.ru: 'Рекомендуем',
                                                AppLanguage.en: 'Recommended',
                                                AppLanguage.de: 'Empfohlen',
                                              }),
                                              onTap: () => setState(
                                                () => _selected =
                                                    _PremiumPlan.quarterly,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Opacity(
                                      opacity: ctaT,
                                      child: Transform.translate(
                                        offset: Offset(0, (1 - ctaT) * 18),
                                        child: _PurchaseButton(
                                          ambient: _ambient,
                                          accent: accent,
                                          accentDeep: accentDeep,
                                          accentLight:
                                              _accentLight(accent, palette.surface),
                                          onAccent: palette.background,
                                          label: _selected == _PremiumPlan.monthly
                                              ? _t(const {
                                                  AppLanguage.ru:
                                                      'Оформить за 4,99 € / мес',
                                                  AppLanguage.en:
                                                      'Subscribe for €4.99 / mo',
                                                  AppLanguage.de:
                                                      'Abo für 4,99 € / Monat',
                                                })
                                              : _t(const {
                                                  AppLanguage.ru:
                                                      'Оформить за 9,99 € / 3 мес',
                                                  AppLanguage.en:
                                                      'Subscribe for €9.99 / 3 mo',
                                                  AppLanguage.de:
                                                      'Abo für 9,99 € / 3 Monate',
                                                }),
                                          onTap: () => _onPurchase(palette),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Opacity(
                                      opacity: ctaT,
                                      child: Text(
                                        _t(const {
                                          AppLanguage.ru:
                                              'Подписка продлевается автоматически. Отменить можно в любой момент.',
                                          AppLanguage.en:
                                              'Subscription renews automatically. Cancel anytime.',
                                          AppLanguage.de:
                                              'Abo verlängert sich automatisch. Jederzeit kündbar.',
                                        }),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: onSurface.withOpacity(0.38),
                                          fontSize: 11,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
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

class _HeroCrown extends StatelessWidget {
  const _HeroCrown({
    required this.ambient,
    required this.accent,
    required this.accentDeep,
  });

  final Animation<double> ambient;
  final Color accent;
  final Color accentDeep;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambient,
      builder: (_, __) {
        final breath = 0.5 + 0.5 * math.sin(ambient.value * 2 * math.pi);
        final scale = 1.0 + 0.04 * breath;
        return Transform.scale(
          scale: scale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120 + 24 * breath,
                height: 120 + 24 * breath,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.18 + 0.14 * breath),
                      blurRadius: 36 + 12 * breath,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: accentDeep.withOpacity(0.1 + 0.08 * breath),
                      blurRadius: 64,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withOpacity(0.28 + 0.08 * breath),
                      accentDeep.withOpacity(0.14 + 0.06 * breath),
                    ],
                  ),
                  border: Border.all(
                    color: accent.withOpacity(0.55 + 0.2 * breath),
                    width: 1.4,
                  ),
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  size: 46,
                  color: Color.lerp(accentDeep, accent, breath),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard({
    required this.onSurface,
    required this.palette,
    required this.ambient,
    required this.accent,
    required this.accentDeep,
  });

  final Color onSurface;
  final AppPalette palette;
  final Animation<double> ambient;
  final Color accent;
  final Color accentDeep;

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String title, String subtitle})>[
      (
        icon: Icons.block_rounded,
        title: AppTexts.translate(const {
          AppLanguage.ru: 'Без рекламы',
          AppLanguage.en: 'No ads',
          AppLanguage.de: 'Keine Werbung',
        }),
        subtitle: AppTexts.translate(const {
          AppLanguage.ru: 'Ничто не отвлекает от тренировок и уроков',
          AppLanguage.en: 'Nothing gets in the way of training and lessons',
          AppLanguage.de: 'Nichts stört Training und Lektionen',
        }),
      ),
      (
        icon: Icons.insights_rounded,
        title: AppTexts.translate(const {
          AppLanguage.ru: 'Профи-статистика',
          AppLanguage.en: 'Pro analytics',
          AppLanguage.de: 'Pro-Analytik',
        }),
        subtitle: AppTexts.translate(const {
          AppLanguage.ru: 'Глубокая аналитика по всем дисциплинам',
          AppLanguage.en: 'Deep analytics across all disciplines',
          AppLanguage.de: 'Tiefe Analytik in allen Disziplinen',
        }),
      ),
      (
        icon: Icons.school_rounded,
        title: AppTexts.translate(const {
          AppLanguage.ru: 'Premium-уроки',
          AppLanguage.en: 'Premium lessons',
          AppLanguage.de: 'Premium-Lektionen',
        }),
        subtitle: AppTexts.translate(const {
          AppLanguage.ru: 'Полный доступ к эксклюзивным урокам академии',
          AppLanguage.en: 'Full access to exclusive academy lessons',
          AppLanguage.de: 'Voller Zugang zu exklusiven Akademie-Lektionen',
        }),
      ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: palette.surface.withOpacity(0.72),
            border: Border.all(color: accent.withOpacity(0.22)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _BenefitRow(
                  icon: items[i].icon,
                  title: items[i].title,
                  subtitle: items[i].subtitle,
                  onSurface: onSurface,
                  ambient: ambient,
                  index: i,
                  accent: accent,
                  accentDeep: accentDeep,
                ),
                if (i < items.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 54),
                    child: Divider(
                      height: 1,
                      color: onSurface.withOpacity(0.08),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onSurface,
    required this.ambient,
    required this.index,
    required this.accent,
    required this.accentDeep,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color onSurface;
  final Animation<double> ambient;
  final int index;
  final Color accent;
  final Color accentDeep;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambient,
      builder: (_, __) {
        final phase = ambient.value * 2 * math.pi + index * 0.9;
        final glow = 0.5 + 0.5 * math.sin(phase);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withOpacity(0.18 + 0.06 * glow),
                      accentDeep.withOpacity(0.08 + 0.04 * glow),
                    ],
                  ),
                  border: Border.all(color: accent.withOpacity(0.28)),
                ),
                child: Icon(icon, color: accentDeep, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: onSurface.withOpacity(0.92),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: onSurface.withOpacity(0.55),
                        fontSize: 12.5,
                        height: 1.35,
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
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.selected,
    required this.recommended,
    required this.ambient,
    required this.onSurface,
    required this.palette,
    required this.accent,
    required this.accentDeep,
    required this.title,
    required this.price,
    required this.period,
    required this.badge,
    required this.onTap,
  });

  final bool selected;
  final bool recommended;
  final Animation<double> ambient;
  final Color onSurface;
  final AppPalette palette;
  final Color accent;
  final Color accentDeep;
  final String title;
  final String price;
  final String period;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambient,
      builder: (_, __) {
        final breath = 0.5 + 0.5 * math.sin(ambient.value * 2 * math.pi);
        final glow = selected && recommended ? 0.14 + 0.12 * breath : 0.0;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              uiTapClick(UiClickSound.soft);
              onTap();
            },
            borderRadius: BorderRadius.circular(22),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.fromLTRB(18, recommended ? 22 : 16, 18, 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: selected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: recommended
                            ? [
                                accent.withOpacity(0.22 + glow),
                                accentDeep.withOpacity(0.1 + glow * 0.5),
                              ]
                            : [
                                palette.surface.withOpacity(0.95),
                                palette.surface.withOpacity(0.82),
                              ],
                      )
                    : null,
                color: selected
                    ? null
                    : palette.surface.withOpacity(recommended ? 0.55 : 0.72),
                border: Border.all(
                  color: selected
                      ? accent.withOpacity(recommended ? 0.72 + 0.18 * breath : 0.45)
                      : onSurface.withOpacity(0.12),
                  width: selected ? (recommended ? 1.6 : 1.2) : 1,
                ),
                boxShadow: selected && recommended
                    ? [
                        BoxShadow(
                          color: accent.withOpacity(0.22 + 0.16 * breath),
                          blurRadius: 22,
                          spreadRadius: 0.5,
                        ),
                        BoxShadow(
                          color: accentDeep.withOpacity(0.08 + 0.06 * breath),
                          blurRadius: 36,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (recommended)
                    Positioned(
                      top: -12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accent, accentDeep],
                          ),
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacity(0.35),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: palette.background,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? accentDeep
                                : onSurface.withOpacity(0.25),
                            width: selected ? 6 : 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: onSurface.withOpacity(0.88),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              period,
                              style: TextStyle(
                                color: onSurface.withOpacity(0.48),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            price,
                            style: TextStyle(
                              color: selected && recommended
                                  ? accent
                                  : onSurface,
                              fontSize: recommended && selected ? 24 : 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (!recommended)
                            Text(
                              badge,
                              style: TextStyle(
                                color: accentDeep.withOpacity(0.9),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PurchaseButton extends StatelessWidget {
  const _PurchaseButton({
    required this.ambient,
    required this.accent,
    required this.accentDeep,
    required this.accentLight,
    required this.onAccent,
    required this.label,
    required this.onTap,
  });

  final Animation<double> ambient;
  final Color accent;
  final Color accentDeep;
  final Color accentLight;
  final Color onAccent;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambient,
      builder: (_, __) {
        final breath = 0.5 + 0.5 * math.sin(ambient.value * 2 * math.pi);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(accent, accentLight, breath * 0.35)!,
                    Color.lerp(accentDeep, accent, breath * 0.25)!,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.28 + 0.12 * breath),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PremiumBackdropPainter extends CustomPainter {
  _PremiumBackdropPainter({
    required this.t,
    required this.background,
    required this.accent,
    required this.accentDeep,
  });

  final double t;
  final Color background;
  final Color accent;
  final Color accentDeep;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);

    final cx = size.width * 0.5;
    final cy = size.height * 0.18;
    final breath = 0.5 + 0.5 * math.sin(t * 2 * math.pi);

    final glow = Paint()
      ..shader = ui.Gradient.radial(
        Offset(cx, cy),
        size.width * (0.55 + 0.08 * breath),
        [
          accent.withOpacity(0.14 + 0.06 * breath),
          accentDeep.withOpacity(0.05 + 0.03 * breath),
          background.withOpacity(0),
        ],
        [0.0, 0.45, 1.0],
      );
    canvas.drawRect(Offset.zero & size, glow);

    final random = math.Random(42);
    for (var i = 0; i < 18; i++) {
      final bx = random.nextDouble() * size.width;
      final by = random.nextDouble() * size.height * 0.7;
      final phase = t * 2 * math.pi + i * 1.7;
      final r = 1.2 + random.nextDouble() * 2.2;
      final alpha = 0.08 + 0.12 * (0.5 + 0.5 * math.sin(phase));
      canvas.drawCircle(
        Offset(bx, by + 6 * math.sin(phase)),
        r,
        Paint()..color = accent.withOpacity(alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PremiumBackdropPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.background != background ||
      oldDelegate.accent != accent ||
      oldDelegate.accentDeep != accentDeep;
}
