part of 'package:flutter_application_1/recovered_app.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, dynamic> stats = {
    'standard': {'best': 0, 'total': 0, 'avg': 0.0, 'bestSpeedMs': 0},
    'binary': {'best': 0, 'total': 0, 'avg': 0.0, 'bestSpeedMs': 0},
    'words': {'best': 0, 'total': 0, 'avg': 0.0, 'bestSpeedMs': 0},
    'images': {'best': 0, 'total': 0, 'avg': 0.0, 'bestSpeedMs': 0},
    'cards': {'best': 0, 'total': 0, 'avg': 0.0, 'bestSpeedMs': 0},
    'faces': {'best': 0, 'total': 0, 'avg': 0.0, 'bestSpeedMs': 0},
  };
  final Map<String, List<String>> _historiesRaw = {
    'standard': [],
    'binary': [],
    'words': [],
    'images': [],
    'cards': [],
    'faces': [],
  };
  int _streakDays = 0;

  @override
  void initState() {
    super.initState();
    _loadAllStats();
  }

  Future<void> _loadAllStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (final mode in ['standard', 'binary', 'words', 'images', 'cards', 'faces']) {
        stats[mode] = {
          'best': prefs.getInt('best_score_$mode') ?? 0,
          'total': prefs.getInt('total_games_$mode') ?? 0,
          'avg': prefs.getDouble('avg_percentage_$mode') ?? 0.0,
          'bestSpeedMs': prefs.getInt('best_avg_ms_per_el_$mode') ?? 0,
        };
        _historiesRaw[mode] = List<String>.from(prefs.getStringList('game_history_$mode') ?? []);
      }
      _streakDays = ProgressService.instance.progress.value.streak;
    });
  }

  String _formatSecPerElement(int avgMsPerEl) {
    if (avgMsPerEl <= 0) return '—';
    final secLabel = appLanguage.value == AppLanguage.ru
        ? 'с'
        : appLanguage.value == AppLanguage.de
            ? 'Sek'
            : 's';
    return '${(avgMsPerEl / 1000.0).toStringAsFixed(2)} $secLabel';
  }

  Set<DateTime> _collectTrainingDays() {
    final out = <DateTime>{};
    for (final entries in _historiesRaw.values) {
      for (final raw in entries) {
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

  void _openStreakCalendar(AppPalette palette) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final days = _collectTrainingDays();
    final now = DateTime.now();
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
                          AppLanguage.ru: 'Стрик: $_streakDays',
                          AppLanguage.en: 'Streak: $_streakDays',
                          AppLanguage.de: 'Serie: $_streakDays',
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
                      final isToday =
                          day.year == now.year && day.month == now.month && day.day == now.day;
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
                  const SizedBox(height: 12),
                  Text(
                    AppTexts.translate({
                      AppLanguage.ru: 'Нажимай каждый день, чтобы не потерять стрик',
                      AppLanguage.en: 'Train daily to keep your streak alive',
                      AppLanguage.de: 'Trainiere taeglich, um die Serie zu halten',
                    }),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: onSurface.withOpacity(0.48),
                      fontSize: 11,
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

  List<double> _extractRecentPctSeries(List<String> rawList, {int maxPoints = 12}) {
    final parsed = <double>[];
    for (final raw in rawList.take(maxPoints).toList().reversed) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        final pct = ((m['pct'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 100.0);
        parsed.add(pct);
      } catch (_) {}
    }
    return parsed;
  }

  _ModeTrendSnapshot _buildTrendSnapshot(List<double> points) {
    if (points.isEmpty) {
      return const _ModeTrendSnapshot(
        predictedNext: 0,
        deltaFromStart: 0,
        slope: 0,
      );
    }
    if (points.length == 1) {
      final v = points.first;
      return _ModeTrendSnapshot(
        predictedNext: v,
        deltaFromStart: 0,
        slope: 0,
      );
    }

    final n = points.length;
    double sx = 0;
    double sy = 0;
    double sxx = 0;
    double sxy = 0;
    for (int i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = points[i];
      sx += x;
      sy += y;
      sxx += x * x;
      sxy += x * y;
    }
    final den = (n * sxx - sx * sx);
    final slope = den.abs() < 1e-9 ? 0.0 : (n * sxy - sx * sy) / den;
    final predictedNext = (points.last + slope).clamp(0.0, 100.0);
    final deltaFromStart = points.last - points.first;

    return _ModeTrendSnapshot(
      predictedNext: predictedNext,
      deltaFromStart: deltaFromStart,
      slope: slope,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: ValueListenableBuilder<AppPalette>(
        valueListenable: appPalette,
        builder: (context, palette, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTexts.get('statistics_title'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w200,
                    letterSpacing: 2,
                    color: palette.accent.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 20),
                _buildStreakRow(palette),
                const SizedBox(height: 14),
                _buildGlobalStandingCard(palette),
                const SizedBox(height: 28),
                _buildModeBlock(AppTexts.get('numbers'), 'standard', Icons.numbers, palette),
                const SizedBox(height: 14),
                _buildModeBlock(AppTexts.get('binary'), 'binary', Icons.data_array, palette),
                const SizedBox(height: 14),
                _buildModeBlock(AppTexts.get('words'), 'words', Icons.abc, palette),
                const SizedBox(height: 14),
                _buildModeBlock(AppTexts.get('photo'), 'images', Icons.image_outlined, palette),
                const SizedBox(height: 14),
                _buildModeBlock(AppTexts.get('cards'), 'cards', Icons.style_outlined, palette),
                const SizedBox(height: 14),
                _buildModeBlock(AppTexts.get('faces'), 'faces', Icons.face_retouching_natural_outlined, palette),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStreakRow(AppPalette palette) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final d = _streakDays.clamp(0, 999);
    final slots = d == 0 ? 1 : (d > 7 ? 7 : d);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border.withOpacity(0.55)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(slots, (i) {
                final t = slots <= 1 ? 1.0 : i / (slots - 1);
                final o = 0.35 + 0.45 * t;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    width: 10,
                    height: 22,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          palette.accent.withOpacity(0.15 + 0.1 * t),
                          palette.accent.withOpacity(o),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: palette.accent.withOpacity(0.25),
                          blurRadius: 6,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _openStreakCalendar(palette),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.local_fire_department_rounded, color: palette.accent, size: 26),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$d',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w200,
              color: palette.accent,
              height: 1,
            ),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              AppTexts.get('days_label'),
              style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeBlock(String title, String modeKey, IconData icon, AppPalette palette) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final data = stats[modeKey] as Map<String, dynamic>;
    final bestSpeed = data['bestSpeedMs'] as int;
    final rawList = _historiesRaw[modeKey] ?? [];
    final series = _extractRecentPctSeries(rawList);
    final trend = _buildTrendSnapshot(series);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: palette.accent.withOpacity(0.75), size: 22),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: onSurface.withOpacity(0.88))),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${AppTexts.get('record')}: ${data['best']} · ${AppTexts.get('games_count')}: ${data['total']} · ${AppTexts.get('avg_accuracy')}: ${(data['avg'] as double).toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.48), height: 1.35),
          ),
          const SizedBox(height: 4),
          Text(
            '${AppTexts.get('best_speed')}: ${_formatSecPerElement(bestSpeed)} ${AppTexts.get('per_element')}',
            style: TextStyle(fontSize: 11, color: palette.accent.withOpacity(0.85)),
          ),
          const SizedBox(height: 12),
          _ModeTrendCard(
            palette: palette,
            points: series,
            predictedNext: trend.predictedNext,
            deltaFromStart: trend.deltaFromStart,
            slope: trend.slope,
          ),
          if (rawList.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(AppTexts.get('recent_attempts'), style: TextStyle(fontSize: 10, letterSpacing: 1.2, color: onSurface.withOpacity(0.38))),
            const SizedBox(height: 8),
            ...rawList.take(6).map((raw) {
              String line = raw;
              try {
                final m = jsonDecode(raw) as Map<String, dynamic>;
                final pct = (m['pct'] as num).toDouble().toStringAsFixed(0);
                final n = (m['n'] as num).toInt();
                final c = (m['c'] as num).toInt();
                final avgEl = (m['avgMemMsPerEl'] as num?)?.toInt() ?? 0;
                final spd = _formatSecPerElement(avgEl);
                line = '$c/$n · $pct% · $spd / ${AppTexts.get('per_element')}';
              } catch (_) {}
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(line, style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.55))),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildGlobalStandingCard(AppPalette palette) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isRu = appLanguage.value == AppLanguage.ru;
    final isDe = appLanguage.value == AppLanguage.de;

    Widget firebaseOfflineNote() => Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.border.withOpacity(0.5)),
          ),
          child: Text(
            isRu
                ? 'Сравнение с другими недоступно: не удалось запустить Firebase. Проверь интернет и перезапусти приложение.'
                : isDe
                    ? 'Vergleich mit anderen nicht möglich: Firebase startet nicht. Internet prüfen und App neu starten.'
                    : 'Comparison unavailable: Firebase did not start. Check internet and restart the app.',
            style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.6)),
          ),
        );

    if (!CloudSyncService.instance.isFirebaseInitialized) {
      return firebaseOfflineNote();
    }

    Future<void> openLeaderboard() async {
      appHaptic(UiClickSound.soft);
      if (!mounted) return;
      await Navigator.push<void>(
        context,
        PageRouteBuilder<void>(
          pageBuilder: (_, __, ___) => const LeaderboardScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    }

    if (!CloudSyncService.instance.firebaseReady) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: openLeaderboard,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.border.withOpacity(0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    isRu
                        ? 'Таблица лидеров: нажми, чтобы открыть. Чтобы попасть в рейтинг, войди в аккаунт (облако ещё подключается).'
                        : isDe
                            ? 'Bestenliste öffnen: tippen. Für das Ranking bitte anmelden (Cloud verbindet noch).'
                            : 'Tap to open the leaderboard. Sign in to rank (cloud still connecting).',
                    style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.6)),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: onSurface.withOpacity(0.28), size: 22),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: openLeaderboard,
        child: StreamBuilder<List<LeaderboardEntry>>(
          stream: LeaderboardService.instance.watchAllTimeTop(limit: 100),
          builder: (context, snapshot) {
            final entries = snapshot.data ?? const <LeaderboardEntry>[];
            final myUid = CloudSyncService.instance.user.value?.uid;
            final myXp = ProgressService.instance.progress.value.xp;

            int rank = entries.where((e) => e.points > myXp).length + 1;
            final knownPool = entries.length;
            if (knownPool <= 0) rank = 0;
            final outranked = entries.where((e) => e.points < myXp).length;
            final percentile = knownPool <= 0 ? 0 : ((outranked / knownPool) * 100).round();
            final isMeInTop = myUid != null && entries.any((e) => e.uid == myUid);

            final standing = rank == 0
                ? (isRu ? 'Нет данных' : (isDe ? 'Keine Daten' : 'No data'))
                : isMeInTop
                    ? '#$rank / $knownPool'
                    : (isRu ? 'вне top-$knownPool' : (isDe ? 'außerhalb Top-$knownPool' : 'outside top-$knownPool'));

            final subtitle = isRu
                ? 'Ты лучше примерно $percentile% игроков в выборке • нажми для полной таблицы'
                : isDe
                    ? 'Du bist besser als etwa $percentile% der Spieler • tippen für die Bestenliste'
                    : 'You outperform about $percentile% of players in this sample • tap for full leaderboard';

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: palette.border.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.insights_rounded, color: palette.accent.withOpacity(0.9), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRu ? 'Позиция среди игроков' : (isDe ? 'Position unter Spielern' : 'Standing among players'),
                          style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.55)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          standing,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: palette.accent.withOpacity(0.95),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(subtitle, style: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.5))),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: onSurface.withOpacity(0.28), size: 22),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ModeTrendSnapshot {
  final double predictedNext;
  final double deltaFromStart;
  final double slope;

  const _ModeTrendSnapshot({
    required this.predictedNext,
    required this.deltaFromStart,
    required this.slope,
  });
}

class _ModeTrendCard extends StatelessWidget {
  final AppPalette palette;
  final List<double> points;
  final double predictedNext;
  final double deltaFromStart;
  final double slope;

  const _ModeTrendCard({
    required this.palette,
    required this.points,
    required this.predictedNext,
    required this.deltaFromStart,
    required this.slope,
  });

  String _helpTitle() {
    if (appLanguage.value == AppLanguage.ru) return 'Прогноз и тренд';
    if (appLanguage.value == AppLanguage.de) return 'Prognose und Trend';
    return 'Forecast and trend';
  }

  String _helpBody() {
    if (appLanguage.value == AppLanguage.ru) {
      return 'Этот блок показывает динамику последних попыток.\n\n'
          '• Прогноз — ожидаемая точность в следующей попытке на основе текущего наклона линии.\n'
          '• Изменение (%) — разница между первой и последней точкой в выбранной серии.\n'
          '• Тренд — общее направление: рост, спад или стабильность.\n\n'
          'Подсказка: лучше смотреть на тренд вместе с количеством попыток — чем их больше, тем вывод точнее.';
    }
    if (appLanguage.value == AppLanguage.de) {
      return 'Dieser Block zeigt die Entwicklung der letzten Versuche.\n\n'
          '• Prognose — erwartete Genauigkeit im nächsten Versuch basierend auf der aktuellen Liniensteigung.\n'
          '• Veränderung (%) — Differenz zwischen dem ersten und letzten Punkt der Serie.\n'
          '• Trend — Gesamtrichtung: Anstieg, Rückgang oder stabil.\n\n'
          'Tipp: Trend zusammen mit der Anzahl der Versuche betrachten — je mehr Daten, desto verlässlicher.';
    }
    return 'This block shows the dynamics of recent attempts.\n\n'
        '• Forecast — expected accuracy for the next attempt based on the current slope.\n'
        '• Change (%) — difference between the first and last point in the series.\n'
        '• Trend — overall direction: growth, decline, or stable.\n\n'
        'Tip: evaluate trend together with attempt count — more data gives more reliable signals.';
  }

  void _showHelp(BuildContext context, Color onSurface) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: palette.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: palette.border.withOpacity(0.6)),
          ),
          title: Row(
            children: [
              Icon(Icons.help_outline_rounded, color: palette.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _helpTitle(),
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            _helpBody(),
            style: TextStyle(
              color: onSurface.withOpacity(0.76),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                AppTexts.get('close'),
                style: TextStyle(color: palette.accent, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isRu = appLanguage.value == AppLanguage.ru;
    final isDe = appLanguage.value == AppLanguage.de;
    final trendColor = deltaFromStart >= 0 ? const Color(0xFF34D399) : const Color(0xFFFF6B6B);

    String trendLabel;
    if (slope > 0.3) {
      trendLabel = isRu ? 'рост' : (isDe ? 'Anstieg' : 'growth');
    } else if (slope < -0.3) {
      trendLabel = isRu ? 'спад' : (isDe ? 'Rückgang' : 'decline');
    } else {
      trendLabel = isRu ? 'стабильно' : (isDe ? 'stabil' : 'stable');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: palette.background.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isRu
                    ? 'Новая аналитика'
                    : isDe
                        ? 'Neue Analytik'
                        : 'New analytics',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.0,
                  color: onSurface.withOpacity(0.42),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Tooltip(
                message: isRu ? 'Что это?' : isDe ? 'Was ist das?' : 'What is this?',
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    uiTapClick(UiClickSound.soft);
                    _showHelp(context, onSurface);
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.card.withOpacity(0.75),
                      border: Border.all(color: palette.border.withOpacity(0.6)),
                    ),
                    child: Icon(
                      Icons.question_mark_rounded,
                      size: 13,
                      color: onSurface.withOpacity(0.62),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 86,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) {
                return CustomPaint(
                  painter: _MiniTrendPainter(
                    points: points,
                    accent: palette.accent,
                    revealProgress: t,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                isRu
                    ? 'Прогноз: ${predictedNext.toStringAsFixed(0)}%'
                    : isDe
                        ? 'Prognose: ${predictedNext.toStringAsFixed(0)}%'
                        : 'Forecast: ${predictedNext.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.72)),
              ),
              Text(
                '${deltaFromStart >= 0 ? '+' : ''}${deltaFromStart.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 11, color: trendColor, fontWeight: FontWeight.w600),
              ),
              Text(
                isRu ? 'Тренд: $trendLabel' : (isDe ? 'Trend: $trendLabel' : 'Trend: $trendLabel'),
                style: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.55)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniTrendPainter extends CustomPainter {
  final List<double> points;
  final Color accent;
  final double revealProgress;

  _MiniTrendPainter({
    required this.points,
    required this.accent,
    required this.revealProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..color = accent.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height * 0.85), Offset(size.width, size.height * 0.85), bg);
    canvas.drawLine(Offset(0, size.height * 0.1), Offset(size.width, size.height * 0.1), bg);

    if (points.length < 2) {
      if (points.isNotEmpty) {
        final y = size.height * (1 - points.first / 100.0);
        final dot = Paint()..color = accent.withOpacity(0.85);
        canvas.drawCircle(Offset(size.width * 0.5, y.clamp(6.0, size.height - 6.0)), 3.2, dot);
      }
      return;
    }

    final path = Path();
    final areaPath = Path();
    for (int i = 0; i < points.length; i++) {
      final x = size.width * (i / (points.length - 1));
      final y = (size.height * (1 - points[i] / 100.0)).clamp(4.0, size.height - 4.0);
      if (i == 0) {
        path.moveTo(x, y);
        areaPath.moveTo(x, size.height);
        areaPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        areaPath.lineTo(x, y);
      }
    }
    areaPath.lineTo(size.width, size.height);
    areaPath.close();

    final reveal = (size.width * revealProgress.clamp(0.0, 1.0));
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, reveal, size.height));
    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [accent.withOpacity(0.22), accent.withOpacity(0.02)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(areaPath, areaPaint);

    final linePaint = Paint()
      ..color = accent.withOpacity(0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MiniTrendPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.accent != accent ||
        oldDelegate.revealProgress != revealProgress;
  }
}

// --- АКАДЕМИЯ: SKILL TREE ---
// Прежний экран с уроками заменён на ветвящееся дерево навыков.
// Реализация — в `lib/skill_tree/skill_tree_screen.dart`. Класс
// `TechniquesScreen` оставлен как фасад, чтобы существующие точки
// входа в академию продолжали работать без правок.
