part of 'package:flutter_application_1/recovered_app.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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
                final viewportW = constraints.maxWidth;
                final wideWeb = isWebDesktopLayout(context, viewportW);
                final twoCols = webMainMenuUseTwoColumns(viewportW);
                final menuWidth = webMainMenuMaxWidth(viewportW);

                if (wideWeb) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: menuWidth),
                        child: DecoratedBox(
                          decoration: webDesktopPanelDecoration(palette, accent),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(36, 28, 36, 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildMenuHeader(onSurface, wideWeb: true),
                                const SizedBox(height: 32),
                                if (twoCols)
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: Column(
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
                                            const SizedBox(height: 24),
                                            Text(
                                              AppTexts.get('main_bottom_quote'),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: onSurface.withOpacity(0.22),
                                                fontSize: 10,
                                                letterSpacing: 2.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                        const SizedBox(width: 32),
                                        Expanded(
                                          flex: 4,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              _buildDailyCard(onSurface, accent),
                                              const SizedBox(height: 16),
                                              _buildCommunityHubButton(onSurface, accent),
                                              const SizedBox(height: 16),
                                              _buildWebQuickNavChips(onSurface, accent),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                else
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _buildXpProgressHeader(onSurface),
                                      const SizedBox(height: 20),
                                      _buildDailyCard(onSurface, accent),
                                      const SizedBox(height: 20),
                                      ScaleTransition(
                                        scale: _pulseAnimation,
                                        child: _buildPrimaryTrainingButton(
                                          onSurface,
                                          accent,
                                          desktop: true,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildCommunityHubButton(onSurface, accent),
                                      const SizedBox(height: 16),
                                      _buildWebQuickNavChips(onSurface, accent),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMenuHeader(onSurface, wideWeb: false),
                            const SizedBox(height: 18),
                            _buildXpProgressHeader(onSurface),
                            const SizedBox(height: 18),
                            _buildDailyCard(onSurface, accent),
                            const SizedBox(height: 22),
                            ScaleTransition(
                              scale: _pulseAnimation,
                              child: _buildPrimaryTrainingButton(onSurface, accent),
                            ),
                            const SizedBox(height: 18),
                            _buildCommunityHubButton(onSurface, accent),
                            const SizedBox(height: 18),
                            _buildQuickNavRow(),
                            const Spacer(),
                            const SizedBox(height: 14),
                            Center(
                              child: Text(
                                AppTexts.get('main_bottom_quote'),
                                style: TextStyle(
                                  color: onSurface.withOpacity(0.2),
                                  fontSize: 9,
                                  letterSpacing: 3,
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuHeader(Color onSurface, {required bool wideWeb}) {
    final accent = appAccentColor.value;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mnemonica',
                style: TextStyle(
                  color: onSurface.withOpacity(0.95),
                  fontSize: wideWeb ? 36 : 38,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppTexts.get('app_subtitle'),
                style: TextStyle(
                  color: accent.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 2.4,
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

  Widget _buildWebQuickNavChips(Color onSurface, Color accent) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _webNavChip(
          icon: Icons.emoji_events_outlined,
          label: AppTexts.translate(const {
            AppLanguage.ru: 'Рейтинг',
            AppLanguage.en: 'Ranks',
            AppLanguage.de: 'Rang',
          }),
          onTap: () => _openScreen(const LeaderboardScreen()),
          onSurface: onSurface,
        ),
        _webNavChip(
          icon: Icons.lightbulb_outline_rounded,
          label: AppTexts.translate(const {
            AppLanguage.ru: 'Техники',
            AppLanguage.en: 'Tips',
            AppLanguage.de: 'Tipps',
          }),
          onTap: () => _openScreen(const TechniquesScreen()),
          onSurface: onSurface,
        ),
        _webNavChip(
          icon: Icons.flash_on_rounded,
          label: AppTexts.translate(const {
            AppLanguage.ru: 'Дуэли',
            AppLanguage.en: 'Duels',
            AppLanguage.de: 'Duelle',
          }),
          onTap: () => _openScreen(const DuelLobbyScreen()),
          onSurface: onSurface,
          highlight: true,
          accent: accent,
        ),
        _webNavChip(
          icon: Icons.bar_chart_rounded,
          label: AppTexts.translate(const {
            AppLanguage.ru: 'Статистика',
            AppLanguage.en: 'Stats',
            AppLanguage.de: 'Statistik',
          }),
          onTap: () => _openScreen(const premium_stats.PremiumStatisticsScreen()),
          onSurface: onSurface,
        ),
        _webNavChip(
          icon: Icons.task_alt_rounded,
          label: AppTexts.translate(const {
            AppLanguage.ru: 'Квесты',
            AppLanguage.en: 'Quests',
            AppLanguage.de: 'Quests',
          }),
          onTap: () => _openScreen(const QuestsScreen()),
          onSurface: onSurface,
        ),
      ],
    );
  }

  Widget _webNavChip({
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: highlight
                ? chipAccent.withOpacity(0.12)
                : appPalette.value.card.withOpacity(0.85),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlight
                  ? chipAccent.withOpacity(0.45)
                  : appPalette.value.border.withOpacity(0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: highlight ? chipAccent : onSurface.withOpacity(0.75),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: onSurface.withOpacity(0.82),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickNavRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _quickNavButton(
            icon: Icons.emoji_events_outlined,
            onTap: () => _openScreen(const LeaderboardScreen())),
        _quickNavButton(
            icon: Icons.lightbulb_outline_rounded,
            onTap: () => _openScreen(const TechniquesScreen())),
        _quickNavButton(
          icon: Icons.flash_on_rounded,
          onTap: () => _openScreen(const DuelLobbyScreen()),
          highlight: true,
        ),
        _quickNavButton(
            icon: Icons.bar_chart_rounded,
            onTap: () => _openScreen(const premium_stats.PremiumStatisticsScreen())),
        _quickNavButton(
            icon: Icons.task_alt_rounded,
            onTap: () => _openScreen(const QuestsScreen())),
      ],
    );
  }

  Widget _buildDailyCard(Color onSurface, Color accent) {
    return ValueListenableBuilder<QuestState>(
      valueListenable: QuestService.instance.state,
      builder: (context, questState, _) {
        final dailyItems = <Widget>[];
        final visibleCount = min(3, min(questState.dailyQuests.length, questState.dailyStatuses.length));

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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: appPalette.value.surface,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: appPalette.value.border.withOpacity(0.45)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
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

  Widget _buildCommunityHubButton(Color onSurface, Color accent) {
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: appPalette.value.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withOpacity(0.38)),
                  boxShadow: [
                    BoxShadow(color: accent.withOpacity(0.12), blurRadius: 14, spreadRadius: 0.5),
                  ],
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


  Widget _quickNavButton({
    required IconData icon,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    final accent = appAccentColor.value;
    return GestureDetector(
      onTap: withUiTap(onTap),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: highlight ? accent.withOpacity(0.10) : appPalette.value.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: highlight
                ? accent.withOpacity(0.55)
                : appPalette.value.border.withOpacity(0.35),
          ),
          boxShadow: highlight
              ? [BoxShadow(color: accent.withOpacity(0.18), blurRadius: 14, spreadRadius: 0.5)]
              : null,
        ),
        child: Icon(
          icon,
          color: highlight ? accent : accent.withOpacity(0.9),
          size: highlight ? 23 : 22,
        ),
      ),
    );
  }

  Widget _buildXpProgressHeader(Color onSurface) {
    return ValueListenableBuilder(
      valueListenable: ProgressService.instance.progress,
      builder: (context, p, _) {
        final accent = appAccentColor.value;
        final ratio = p.xpToNextLevel <= 0 ? 0.0 : (p.currentLevelXp / p.xpToNextLevel).clamp(0.0, 1.0);
        final levelTitle = ProgressService.instance.getLevelTitleLabel().toUpperCase();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: accent.withOpacity(0.45)),
                    color: accent.withOpacity(0.08),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.psychology_alt_outlined, size: 13, color: accent.withOpacity(0.95)),
                      const SizedBox(width: 6),
                      Text(
                        levelTitle,
                        style: TextStyle(
                          color: accent.withOpacity(0.95),
                          fontSize: 10,
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => _openStreakCalendar(appPalette.value, p.streak),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: accent.withOpacity(0.45)),
                        color: accent.withOpacity(0.16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_fire_department_rounded, size: 14, color: accent),
                          const SizedBox(width: 6),
                          Text('${p.streak}', style: TextStyle(color: onSurface.withOpacity(0.95), fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  levelTitle,
                  style: TextStyle(color: onSurface.withOpacity(0.58), fontSize: 11, letterSpacing: 1.7),
                ),
                const Spacer(),
                Text(
                  '${p.currentLevelXp} / ${p.xpToNextLevel} XP',
                  style: TextStyle(color: onSurface.withOpacity(0.58), fontSize: 12, letterSpacing: 0.5),
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
                      Container(height: 7, color: Colors.white.withOpacity(0.09)),
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
