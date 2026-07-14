part of 'package:flutter_application_1/recovered_app.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  TrainingHistoryEntry? _latestTraining;
  bool _loadingLatestTraining = true;

  static const List<Map<AppLanguage, String>> _dailyTips = [
    {
      AppLanguage.ru: 'Разбивай длинные последовательности на блоки по 3–4 элемента.',
      AppLanguage.en: 'Split long sequences into chunks of 3–4 items.',
      AppLanguage.de: 'Teile lange Folgen in Blöcke à 3–4 Elemente.',
    },
    {
      AppLanguage.ru: 'Яркие и абсурдные образы запоминаются быстрее обычных.',
      AppLanguage.en: 'Vivid, absurd images stick faster than plain ones.',
      AppLanguage.de: 'Lebendige, absurde Bilder bleiben schneller hängen.',
    },
    {
      AppLanguage.ru: 'Повторяй коды чисел, пока они не станут автоматическими.',
      AppLanguage.en: 'Drill number codes until they feel automatic.',
      AppLanguage.de: 'Übe Zahlencodes, bis sie automatisch wirken.',
    },
    {
      AppLanguage.ru: 'Короткая ежедневная сессия лучше редкой длинной.',
      AppLanguage.en: 'A short daily session beats a rare long one.',
      AppLanguage.de: 'Kurz täglich trainieren schlägt selten lange Sessions.',
    },
    {
      AppLanguage.ru: 'Связывай новый образ с уже знакомым маршрутом.',
      AppLanguage.en: 'Link new images to a route you already know.',
      AppLanguage.de: 'Verknüpfe neue Bilder mit einer bekannten Route.',
    },
    {
      AppLanguage.ru: 'Сначала запоминай, потом проверяй — не наоборот.',
      AppLanguage.en: 'Memorize first, then recall — not the other way.',
      AppLanguage.de: 'Erst merken, dann abrufen — nicht umgekehrt.',
    },
    {
      AppLanguage.ru: 'Дыши ровно во время запоминания — темп стабильнее.',
      AppLanguage.en: 'Breathe steadily while memorizing — pace stays stable.',
      AppLanguage.de: 'Atme ruhig beim Merken — das Tempo bleibt stabil.',
    },
  ];

  Set<DateTime> _collectTrainingDays(Map<String, Object?> data) {
    final out = <DateTime>{};
    for (final mode in const ['standard', 'binary', 'words', 'images', 'cards', 'faces']) {
      final list = data['game_history_$mode'] as List<String>? ?? const <String>[];
      for (final raw in list) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          final ts = (map['t'] as num?)?.toInt();
          if (ts == null || ts <= 0) continue;
          final dt = DateTime.fromMillisecondsSinceEpoch(ts);
          out.add(DateTime(dt.year, dt.month, dt.day));
        } catch (_) {}
      }
    }
    return out;
  }

  Future<void> _openStreakCalendar(AppPalette palette, int streakDays) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getKeys().fold<Map<String, Object?>>(
      <String, Object?>{},
      (acc, key) {
        acc[key] = prefs.get(key);
        return acc;
      },
    );
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final days = _collectTrainingDays(data);
    final now = DateTime.now();
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (context) {
        DateTime shownMonth = DateTime(now.year, now.month, 1);
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final monthStart = DateTime(shownMonth.year, shownMonth.month, 1);
            final monthEnd = DateTime(shownMonth.year, shownMonth.month + 1, 0);
            final firstWeekdayShift = (monthStart.weekday + 6) % 7;
            final dayCells = <DateTime?>[];
            for (int i = 0; i < firstWeekdayShift; i++) {
              dayCells.add(null);
            }
            for (int d = 1; d <= monthEnd.day; d++) {
              dayCells.add(DateTime(shownMonth.year, shownMonth.month, d));
            }
            while (dayCells.length % 7 != 0) {
              dayCells.add(null);
            }

            String monthTitle() {
              return AppTexts.translate({
                AppLanguage.ru: '${shownMonth.month.toString().padLeft(2, '0')}.${shownMonth.year}',
                AppLanguage.en: '${shownMonth.month.toString().padLeft(2, '0')}.${shownMonth.year}',
                AppLanguage.de: '${shownMonth.month.toString().padLeft(2, '0')}.${shownMonth.year}',
              });
            }

            final weekdayLabels = appLanguage.value == AppLanguage.ru
                ? const ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС']
                : appLanguage.value == AppLanguage.de
                    ? const ['MO', 'DI', 'MI', 'DO', 'FR', 'SA', 'SO']
                    : const ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

            return Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: palette.border.withOpacity(0.6)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: palette.border.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.local_fire_department_rounded, color: palette.accent, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        AppTexts.translate({
                          AppLanguage.ru: 'Стрик: $streakDays',
                          AppLanguage.en: 'Streak: $streakDays',
                          AppLanguage.de: 'Serie: $streakDays',
                        }),
                        style: TextStyle(
                          color: palette.accent,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => setSheetState(() {
                          shownMonth = DateTime(shownMonth.year, shownMonth.month - 1, 1);
                        }),
                        icon: Icon(Icons.chevron_left_rounded, color: onSurface.withOpacity(0.7)),
                      ),
                      Text(
                        monthTitle(),
                        style: TextStyle(color: onSurface.withOpacity(0.85), fontSize: 13),
                      ),
                      IconButton(
                        onPressed: () => setSheetState(() {
                          shownMonth = DateTime(shownMonth.year, shownMonth.month + 1, 1);
                        }),
                        icon: Icon(Icons.chevron_right_rounded, color: onSurface.withOpacity(0.7)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final wd in weekdayLabels)
                        Expanded(
                          child: Center(
                            child: Text(
                              wd,
                              style: TextStyle(
                                color: onSurface.withOpacity(0.42),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    itemCount: dayCells.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      final day = dayCells[index];
                      if (day == null) return const SizedBox.shrink();
                      final isToday = day.year == now.year && day.month == now.month && day.day == now.day;
                      final isActive = days.contains(day);
                      return Container(
                        decoration: BoxDecoration(
                          color: isActive ? palette.accent.withOpacity(0.17) : palette.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isToday ? palette.accent : palette.border.withOpacity(0.45),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: isActive ? palette.accent : onSurface.withOpacity(0.75),
                              fontSize: 12,
                              fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppTexts.translate({
                      AppLanguage.ru: 'Тренируйся ежедневно, чтобы сохранить серию',
                      AppLanguage.en: 'Train daily to keep your streak alive',
                      AppLanguage.de: 'Trainiere taeglich, um deine Serie zu halten',
                    }),
                    style: TextStyle(
                      color: onSurface.withOpacity(0.55),
                      fontSize: 12,
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

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    unawaited(_loadLatestTraining());
  }

  Future<void> _loadLatestTraining() async {
    TrainingHistoryEntry? latest;
    for (final mode in trainingHistoryModes) {
      final entries = await TrainingHistoryService.instance.loadMode(mode);
      if (entries.isEmpty) continue;
      final candidate = entries.first;
      if (latest == null || candidate.date.isAfter(latest.date)) {
        latest = candidate;
      }
    }
    if (!mounted) return;
    setState(() {
      _latestTraining = latest;
      _loadingLatestTraining = false;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _closePalette() {
    paletteCollapseSignal.value++;
  }

  Future<void> _openScreen(Widget screen, {UiClickSound sound = UiClickSound.soft}) async {
    _closePalette();
    uiTapClick(sound);
    if (!mounted) return;
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim, _) => screen,
        transitionsBuilder: (context, anim, _, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
    if (mounted) unawaited(_loadLatestTraining());
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, _, __) {
        final palette = appPalette.value;
        final accent = appAccentColor.value;
        final onSurface = Theme.of(context).colorScheme.onSurface;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final viewportW = max(constraints.maxWidth, webViewportWidth(context));
                final wideWeb = isWebDesktopLayout(context, viewportW);
                final menuWidth = webMainMenuMaxWidth(viewportW);
                final sidePad = webMainMenuSidePadding(viewportW);

                if (wideWeb) {
                  return Align(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(vertical: 36, horizontal: sidePad),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: menuWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildMenuHeader(onSurface, accent, wideWeb: true),
                            const SizedBox(height: 40),
                            _buildWebPrimarySection(onSurface, accent),
                            const SizedBox(height: 32),
                            _buildWebSectionDivider(onSurface),
                            const SizedBox(height: 28),
                            _buildWebSecondarySection(onSurface, accent),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: palette.background),
                    if (palette.background.computeLuminance() < 0.5)
                      IgnorePointer(
                        child: Opacity(
                          opacity: 0.16,
                          child: const AnimatedBackground(),
                        ),
                      )
                    else
                      IgnorePointer(child: _buildAmbientGlow(accent)),
                    SafeArea(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildMenuHeader(onSurface, accent, wideWeb: false),
                                const SizedBox(height: 20),
                                _buildMiniStatRow(onSurface, accent),
                                const SizedBox(height: 14),
                                _buildXpProgressHeader(onSurface),
                                const SizedBox(height: 18),
                                _buildDailyCard(onSurface, accent),
                                if (_loadingLatestTraining)
                                  const SizedBox(height: 18)
                                else if (_latestTraining != null) ...[
                                  const SizedBox(height: 18),
                                  _buildLastTrainingCard(onSurface, accent, _latestTraining!),
                                ],
                                const SizedBox(height: 22),
                                _buildPrimaryTrainingGlow(accent, onSurface),
                                const SizedBox(height: 18),
                                _buildCommunityHubButton(onSurface, accent),
                                const SizedBox(height: 22),
                                _buildSectionDivider(onSurface),
                                const SizedBox(height: 16),
                                _buildQuickNavRow(onSurface, accent),
                                const SizedBox(height: 28),
                                _buildDailyTip(onSurface, accent),
                                const SizedBox(height: 8),
                                Center(
                                  child: Text(
                                    AppTexts.get('main_bottom_quote'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: onSurface.withOpacity(0.38),
                                      fontSize: 10,
                                      letterSpacing: 2.4,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildWebPrimarySection(Color onSurface, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildXpProgressHeader(onSurface),
        const SizedBox(height: 28),
        ScaleTransition(
          scale: _pulseAnimation,
          child: _buildPrimaryTrainingButton(
            onSurface,
            accent,
            desktop: true,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          AppTexts.get('main_bottom_quote'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: onSurface.withOpacity(0.2),
            fontSize: 10,
            letterSpacing: 3.2,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildWebSectionDivider(Color onSurface) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: onSurface.withOpacity(0.08),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            AppTexts.get('main_panel'),
            style: TextStyle(
              color: onSurface.withOpacity(0.22),
              fontSize: 9,
              letterSpacing: 3.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: onSurface.withOpacity(0.08),
          ),
        ),
      ],
    );
  }

  Widget _buildWebSecondarySection(Color onSurface, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDailyCard(onSurface, accent, compact: true),
        const SizedBox(height: 14),
        _buildCommunityHubButton(onSurface, accent, compact: true),
        const SizedBox(height: 16),
        _buildWebQuickNavRow(onSurface, accent),
      ],
    );
  }

  Widget _buildAmbientGlow(Color accent) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.2, -0.65),
          radius: 1.1,
          colors: [
            accent.withOpacity(0.08),
            Colors.transparent,
          ],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }

  Widget _buildSectionDivider(Color onSurface) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: onSurface.withOpacity(0.08))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            AppTexts.get('main_panel'),
            style: TextStyle(
              color: onSurface.withOpacity(0.28),
              fontSize: 9,
              letterSpacing: 3.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: onSurface.withOpacity(0.08))),
      ],
    );
  }

  Widget _buildDailyTip(Color onSurface, Color accent) {
    final tip = _dailyTips[DateTime.now().day % _dailyTips.length];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: appPalette.value.surface.withOpacity(0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appPalette.value.border.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppTexts.get('main_tip_label'),
            style: TextStyle(
              color: accent.withOpacity(0.85),
              fontSize: 9,
              letterSpacing: 2.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppTexts.translate(tip),
            style: TextStyle(
              color: onSurface.withOpacity(0.72),
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryTrainingGlow(Color accent, Color onSurface) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 24,
          right: 24,
          top: 10,
          bottom: 10,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.32),
                  blurRadius: 36,
                  spreadRadius: -6,
                ),
              ],
            ),
          ),
        ),
        ScaleTransition(
          scale: _pulseAnimation,
          child: _buildPrimaryTrainingButton(onSurface, accent),
        ),
      ],
    );
  }

  String _modeLabel(String mode) {
    switch (mode) {
      case 'binary':
        return AppTexts.get('mode_binary');
      case 'words':
        return AppTexts.get('mode_words');
      case 'images':
        return AppTexts.get('mode_photo');
      case 'cards':
        return AppTexts.get('mode_cards');
      case 'faces':
        return AppTexts.get('mode_faces');
      default:
        return AppTexts.get('mode_numbers');
    }
  }

  String _formatSessionAge(DateTime date) {
    final now = DateTime.now();
    final sameDay = (DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    if (sameDay(date, now)) {
      return AppTexts.translate(const {
        AppLanguage.ru: 'сегодня',
        AppLanguage.en: 'today',
        AppLanguage.de: 'heute',
      });
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (sameDay(date, yesterday)) {
      return AppTexts.translate(const {
        AppLanguage.ru: 'вчера',
        AppLanguage.en: 'yesterday',
        AppLanguage.de: 'gestern',
      });
    }
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd.$mm';
  }

  Widget _buildLastTrainingCard(Color onSurface, Color accent, TrainingHistoryEntry entry) {
    final accuracy = (entry.accuracy * 100).round();
    return GestureDetector(
      onTap: () => _openScreen(const premium_stats.PremiumStatisticsScreen()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: appPalette.value.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: appPalette.value.border.withOpacity(0.38)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.12),
                border: Border.all(color: accent.withOpacity(0.35)),
              ),
              child: Icon(Icons.history_rounded, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTexts.get('main_last_session'),
                    style: TextStyle(
                      color: onSurface.withOpacity(0.42),
                      fontSize: 9,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _modeLabel(entry.mode),
                    style: TextStyle(
                      color: onSurface.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$accuracy%',
                  style: TextStyle(
                    color: accent,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatSessionAge(entry.date),
                  style: TextStyle(
                    color: onSurface.withOpacity(0.45),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatRow(Color onSurface, Color accent) {
    return ValueListenableBuilder(
      valueListenable: ProgressService.instance.progress,
      builder: (context, p, _) {
        final levelTitle = ProgressService.instance.getLevelTitleLabel();
        return Row(
          children: [
            Expanded(
              child: _miniStatChip(
                onSurface: onSurface,
                accent: accent,
                icon: Icons.local_fire_department_rounded,
                value: '${p.streak}',
                label: AppTexts.translate(const {
                  AppLanguage.ru: 'СТРИК',
                  AppLanguage.en: 'STREAK',
                  AppLanguage.de: 'SERIE',
                }),
                onTap: () => _openStreakCalendar(appPalette.value, p.streak),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _miniStatChip(
                onSurface: onSurface,
                accent: accent,
                icon: Icons.bolt_rounded,
                value: '${p.xp}',
                label: 'XP',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _miniStatChip(
                onSurface: onSurface,
                accent: accent,
                icon: Icons.psychology_alt_outlined,
                value: 'LV ${p.level}',
                label: levelTitle.toUpperCase(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _miniStatChip({
    required Color onSurface,
    required Color accent,
    required IconData icon,
    required String value,
    required String label,
    VoidCallback? onTap,
  }) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: appPalette.value.surface.withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: appPalette.value.border.withOpacity(0.38)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 14, color: accent.withOpacity(0.9)),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: onSurface.withOpacity(0.92),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: onSurface.withOpacity(0.42),
              fontSize: 8,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return chip;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: withUiTap(onTap),
        borderRadius: BorderRadius.circular(14),
        child: chip,
      ),
    );
  }

  Widget _buildMenuHeader(Color onSurface, Color accent, {required bool wideWeb}) {
    final titleStyle = GoogleFonts.spaceGrotesk(
      fontSize: wideWeb ? 34 : 30,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
      height: 1.05,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: wideWeb ? 48 : 44,
          height: wideWeb ? 48 : 44,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withOpacity(0.38)),
          ),
          child: Icon(Icons.psychology_alt_rounded, color: accent, size: wideWeb ? 26 : 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    onSurface.withOpacity(0.98),
                    accent.withOpacity(0.92),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(bounds),
                child: Text(
                  AppTexts.get('app_title'),
                  style: titleStyle,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppTexts.get('app_subtitle'),
                style: TextStyle(
                  color: accent.withOpacity(0.78),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _openScreen(const SettingsScreen()),
          icon: Icon(Icons.settings_outlined, color: onSurface.withOpacity(0.55)),
          tooltip: 'Settings',
        ),
        const ThemeColorSwitcher(initialExpanded: false),
      ],
    );
  }

  Widget _buildWebQuickNavRow(Color onSurface, Color accent) {
    final items = _quickNavItems();

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _webNavTile(
              icon: items[i].icon,
              label: items[i].label,
              onTap: items[i].onTap,
              onSurface: onSurface,
              highlight: items[i].highlight,
              accent: accent,
            ),
          ),
        ],
      ],
    );
  }

  Widget _webNavTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color onSurface,
    bool highlight = false,
    Color? accent,
  }) {
    final chipAccent = accent ?? appAccentColor.value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: withUiTap(onTap),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: highlight
                ? chipAccent.withOpacity(0.1)
                : appPalette.value.card.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: highlight
                  ? chipAccent.withOpacity(0.42)
                  : appPalette.value.border.withOpacity(0.32),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: highlight ? chipAccent : onSurface.withOpacity(0.72),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onSurface.withOpacity(0.78),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickNavRow(Color onSurface, Color accent) {
    final items = _quickNavItems();
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return _mobileNavTile(
            icon: item.icon,
            label: item.label,
            onTap: item.onTap,
            onSurface: onSurface,
            accent: accent,
            highlight: item.highlight,
          );
        },
      ),
    );
  }

  List<({IconData icon, String label, VoidCallback onTap, bool highlight})> _quickNavItems() {
    return [
      (
        icon: Icons.emoji_events_outlined,
        label: AppTexts.translate(const {
          AppLanguage.ru: 'Рейтинг',
          AppLanguage.en: 'Ranks',
          AppLanguage.de: 'Rang',
        }),
        onTap: () => _openScreen(const LeaderboardScreen()),
        highlight: false,
      ),
      (
        icon: Icons.lightbulb_outline_rounded,
        label: AppTexts.translate(const {
          AppLanguage.ru: 'Техники',
          AppLanguage.en: 'Tips',
          AppLanguage.de: 'Tipps',
        }),
        onTap: () => _openScreen(const TechniquesScreen()),
        highlight: false,
      ),
      (
        icon: Icons.flash_on_rounded,
        label: AppTexts.translate(const {
          AppLanguage.ru: 'Дуэли',
          AppLanguage.en: 'Duels',
          AppLanguage.de: 'Duelle',
        }),
        onTap: () => _openScreen(const DuelLobbyScreen()),
        highlight: true,
      ),
      (
        icon: Icons.bar_chart_rounded,
        label: AppTexts.translate(const {
          AppLanguage.ru: 'Статистика',
          AppLanguage.en: 'Stats',
          AppLanguage.de: 'Statistik',
        }),
        onTap: () => _openScreen(const premium_stats.PremiumStatisticsScreen()),
        highlight: false,
      ),
      (
        icon: Icons.task_alt_rounded,
        label: AppTexts.translate(const {
          AppLanguage.ru: 'Квесты',
          AppLanguage.en: 'Quests',
          AppLanguage.de: 'Quests',
        }),
        onTap: () => _openScreen(const QuestsScreen()),
        highlight: false,
      ),
    ];
  }

  Widget _mobileNavTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color onSurface,
    required Color accent,
    bool highlight = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: withUiTap(onTap),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 68,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            color: highlight ? accent.withOpacity(0.1) : appPalette.value.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: highlight ? accent.withOpacity(0.45) : appPalette.value.border.withOpacity(0.35),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: highlight ? accent : onSurface.withOpacity(0.78),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onSurface.withOpacity(0.72),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyCard(Color onSurface, Color accent, {bool compact = false}) {
    return ValueListenableBuilder<QuestState>(
      valueListenable: QuestService.instance.state,
      builder: (context, questState, _) {
        final dailyItems = <Widget>[];
        final visibleCount = min(3, min(questState.dailyQuests.length, questState.dailyStatuses.length));
        var completedCount = 0;
        for (int i = 0; i < visibleCount; i++) {
          if (questState.dailyStatuses[i].isCompleted) completedCount++;
        }
        final progressValue = visibleCount == 0 ? 0.0 : completedCount / visibleCount;

        for (int i = 0; i < visibleCount; i++) {
          final quest = questState.dailyQuests[i];
          final status = questState.dailyStatuses[i];
          final progress = status.isCompleted
              ? 'OK'
              : '${status.currentValue}/${quest.targetValue}';
          dailyItems.add(
            _dailyTaskRow(
              onSurface: onSurface,
              title: quest.getTitle(appLanguage.value.name),
              progress: progress,
              completed: status.isCompleted,
            ),
          );
          if (i < visibleCount - 1) {
            dailyItems.add(const SizedBox(height: 8));
          }
        }

        if (dailyItems.isEmpty) {
          dailyItems.add(
            Text(
              AppTexts.translate(const {
                AppLanguage.ru: 'Задания обновляются...',
                AppLanguage.en: 'Tasks are updating...',
                AppLanguage.de: 'Aufgaben werden aktualisiert...',
              }),
              style: TextStyle(color: onSurface.withOpacity(0.45), fontSize: 12),
            ),
          );
        }

        return GestureDetector(
          onTap: () => _openScreen(const QuestsScreen()),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 14 : 16),
            decoration: BoxDecoration(
              color: appPalette.value.surface,
              borderRadius: BorderRadius.circular(compact ? 14 : 26),
              border: Border.all(color: appPalette.value.border.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 34,
                      height: 34,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: visibleCount == 0 ? null : progressValue,
                            strokeWidth: 2.5,
                            backgroundColor: onSurface.withOpacity(0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(accent),
                          ),
                          if (visibleCount > 0)
                            Text(
                              '$completedCount/$visibleCount',
                              style: TextStyle(
                                color: onSurface.withOpacity(0.65),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppTexts.translate(const {
                        AppLanguage.ru: 'ЕЖЕДНЕВНЫЕ',
                        AppLanguage.en: 'DAILY',
                        AppLanguage.de: 'TÄGLICH',
                      }),
                      style: TextStyle(
                        color: onSurface.withOpacity(0.45),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded, color: onSurface.withOpacity(0.35), size: 18),
                  ],
                ),
                const SizedBox(height: 14),
                ...dailyItems,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dailyTaskRow({
    required Color onSurface,
    required String title,
    required String progress,
    bool completed = false,
  }) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: completed ? appAccentColor.value : onSurface.withOpacity(0.35)),
            color: completed ? appAccentColor.value.withOpacity(0.1) : Colors.transparent,
          ),
          child: completed ? Icon(Icons.check_rounded, size: 12, color: appAccentColor.value) : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: onSurface.withOpacity(completed ? 0.55 : 0.78),
              fontSize: 14,
              fontWeight: FontWeight.w300,
              decoration: completed ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        Text(
          progress,
          style: TextStyle(
            color: completed ? appAccentColor.value.withOpacity(0.85) : onSurface.withOpacity(0.45),
            fontSize: 12,
            fontWeight: completed ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryTrainingButton(Color onSurface, Color accent,
      {bool desktop = false}) {
    return GestureDetector(
      onTap: () => _openScreen(const TrainingScreen()),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: desktop ? 16 : 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(desktop ? 16 : 22),
          gradient: LinearGradient(colors: [accent.withOpacity(0.96), accent]),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(desktop ? 0.28 : 0.38),
              blurRadius: desktop ? 14 : 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: desktop ? 32 : 30,
              height: desktop ? 32 : 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.7),
              ),
              child: Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: desktop ? 20 : 20),
            ),
            const SizedBox(width: 12),
            Text(
              AppTexts.translate(const {
                AppLanguage.ru: 'НАЧАТЬ ТРЕНИРОВКУ',
                AppLanguage.en: 'START TRAINING',
                AppLanguage.de: 'TRAINING STARTEN',
              }),
              style: TextStyle(
                color: Colors.black.withOpacity(0.84),
                fontWeight: FontWeight.w600,
                fontSize: desktop ? 15 : 18,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityHubButton(Color onSurface, Color accent,
      {bool compact = false}) {
    return ValueListenableBuilder<bool>(
      valueListenable: NewsService.instance.hasUnread,
      builder: (context, hasUnread, _) {
        return GestureDetector(
          onTap: () => _openScreen(const CommunityHubScreen()),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 14 : 16,
                  vertical: compact ? 12 : 14,
                ),
                decoration: BoxDecoration(
                  color: appPalette.value.surface,
                  borderRadius: BorderRadius.circular(compact ? 14 : 20),
                  border: Border.all(color: accent.withOpacity(0.34)),
                ),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withOpacity(0.14),
                            border: Border.all(color: accent.withOpacity(0.45)),
                          ),
                          child: Icon(Icons.forum_rounded, color: accent, size: 18),
                        ),
                        if (hasUnread)
                          Positioned(
                            top: -1,
                            right: -1,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                                border: Border.all(color: appPalette.value.background, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTexts.translate({
                              AppLanguage.ru: 'ЧАТ И НОВОСТИ',
                              AppLanguage.en: 'CHAT & NEWS',
                              AppLanguage.de: 'CHAT & NEWS',
                            }),
                            style: TextStyle(
                              color: onSurface.withOpacity(0.88),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppTexts.translate({
                              AppLanguage.ru: 'Общение · новости · дуэли',
                              AppLanguage.en: 'Chat · news · duels',
                              AppLanguage.de: 'Chat · News · Duelle',
                            }),
                            style: TextStyle(
                              color: accent.withOpacity(0.72),
                              fontSize: 10,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: onSurface.withOpacity(0.35), size: 22),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildXpProgressHeader(Color onSurface) {
    return ValueListenableBuilder(
      valueListenable: ProgressService.instance.progress,
      builder: (context, p, _) {
        final accent = appAccentColor.value;
        final ratio = p.xpToNextLevel <= 0 ? 0.0 : (p.currentLevelXp / p.xpToNextLevel).clamp(0.0, 1.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppTexts.translate(const {
                    AppLanguage.ru: 'ПРОГРЕСС УРОВНЯ',
                    AppLanguage.en: 'LEVEL PROGRESS',
                    AppLanguage.de: 'LEVEL-FORTSCHRITT',
                  }),
                  style: TextStyle(
                    color: onSurface.withOpacity(0.42),
                    fontSize: 9,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${p.currentLevelXp} / ${p.xpToNextLevel} XP',
                  style: TextStyle(color: onSurface.withOpacity(0.58), fontSize: 11, letterSpacing: 0.4),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: ratio),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      Container(height: 7, color: onSurface.withOpacity(0.08)),
                      FractionallySizedBox(
                        widthFactor: v,
                        child: Container(
                          height: 7,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [accent.withOpacity(0.75), accent]),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// --- ЭКРАН НАСТРОЕК ---
