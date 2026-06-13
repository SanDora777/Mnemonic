import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'progress/quest_service.dart';
import 'progress/quest_models.dart';
import 'progress/progress_service.dart';
import 'progress/progress_events.dart';
import 'app/core/ui_feedback.dart';
import 'recovered_app.dart';

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> with SingleTickerProviderStateMixin {
  StreamSubscription? _eventSub;
  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    unawaited(QuestService.instance.checkResets());
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _eventSub = ProgressService.instance.events.listen((event) {
      if (event is QuestCompletedEvent && mounted) {
        _showCompletionDialog(event);
        _confettiController.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _showCompletionDialog(QuestCompletedEvent event) {
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    final lang = appLanguage.value;
    final title = lang == AppLanguage.ru
        ? event.titleRu
        : lang == AppLanguage.de
            ? event.titleDe
            : event.titleEn;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.star_rounded, color: accent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTexts.get('quest_completed_snack'),
                      style: TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '+${event.xpReward} XP',
                style: TextStyle(
                  color: accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppTexts.get('quests'),
          style: TextStyle(
            color: onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ValueListenableBuilder<QuestState>(
            valueListenable: QuestService.instance.state,
            builder: (context, state, _) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStreakCard(context, accent, onSurface),
                    const SizedBox(height: 28),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle(
                                context,
                                AppTexts.get('personal_quests_title'),
                                accent,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppTexts.get('personal_quests_subtitle'),
                                style: TextStyle(
                                  color: onSurface.withOpacity(0.38),
                                  fontSize: 11,
                                  height: 1.4,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 520),
                          curve: Curves.easeOutCubic,
                          builder: (context, t, child) {
                            return Transform.scale(
                              scale: 0.86 + 0.14 * t,
                              child: Opacity(opacity: t, child: child),
                            );
                          },
                          child: Material(
                            color: accent.withOpacity(0.12),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                uiTapClick(UiClickSound.soft);
                                if (state.personalQuests.length >= 5) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(AppTexts.get('personal_goal_max'))),
                                  );
                                  return;
                                }
                                _openPersonalGoalSheet(context, accent);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Icon(Icons.add_rounded, color: accent, size: 22),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (state.personalQuests.isEmpty)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        builder: (context, t, _) {
                          return Opacity(
                            opacity: t,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(22),
                                onTap: () {
                                  uiTapClick(UiClickSound.soft);
                                  if (state.personalQuests.length >= 5) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(AppTexts.get('personal_goal_max'))),
                                    );
                                    return;
                                  }
                                  _openPersonalGoalSheet(context, accent);
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
                                  decoration: BoxDecoration(
                                    color: appPalette.value.surface.withOpacity(0.65),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(color: accent.withOpacity(0.12)),
                                  ),
                                  child: Text(
                                    AppTexts.get('personal_goal_add'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: onSurface.withOpacity(0.35),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    else
                      ...List.generate(state.personalQuests.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(milliseconds: 340 + index * 60),
                            curve: Curves.easeOutCubic,
                            builder: (context, t, child) {
                              return Opacity(
                                opacity: t,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - t) * 10),
                                  child: child,
                                ),
                              );
                            },
                            child: _buildQuestCard(
                              context,
                              state.personalQuests[index],
                              state.personalStatuses[index],
                              accent,
                              onSurface,
                              isPersonal: true,
                              onRemovePersonal: () {
                                _confirmRemovePersonalGoal(
                                  context,
                                  state.personalQuests[index],
                                );
                              },
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 32),
                    _buildSectionTitle(
                      context, 
                      AppTexts.get('daily_quests_title'),
                      accent,
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(state.dailyQuests.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildQuestCard(
                          context,
                          state.dailyQuests[index],
                          state.dailyStatuses[index],
                          accent,
                          onSurface,
                          isPersonal: false,
                        ),
                      );
                    }),
                    const SizedBox(height: 32),
                    _buildSectionTitle(
                      context, 
                      AppTexts.get('weekly_quests_title'),
                      accent,
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(state.weeklyQuests.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildQuestCard(
                          context,
                          state.weeklyQuests[index],
                          state.weeklyStatuses[index],
                          accent,
                          onSurface,
                          isPersonal: false,
                        ),
                      );
                    }),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
          _buildConfettiEffect(),
        ],
      ),
    );
  }

  void _openPersonalGoalSheet(BuildContext context, Color accent) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (ctx) => _PersonalGoalComposerSheet(accent: accent),
    );
  }

  Future<void> _confirmRemovePersonalGoal(BuildContext context, Quest quest) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppTexts.get('personal_goal_delete_title')),
        content: Text(AppTexts.get('personal_goal_delete_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppTexts.get('personal_goal_delete_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppTexts.get('personal_goal_delete_confirm')),
          ),
        ],
      ),
    );
    if (ok == true) {
      uiTapClick(UiClickSound.soft);
      await QuestService.instance.removePersonalQuest(quest.id);
    }
  }

  Widget _buildConfettiEffect() {
    return IgnorePointer(
      child: FadeTransition(
        opacity: TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
          TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
        ]).animate(_confettiController),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, color: appAccentColor.value, size: 120),
              const SizedBox(height: 16),
              Text(
                AppTexts.get('great_confetti'),
                style: TextStyle(
                  color: appAccentColor.value,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, Color accent) {
    return Text(
      title,
      style: TextStyle(
        color: accent.withOpacity(0.7),
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, Color accent, Color onSurface) {
    return ValueListenableBuilder(
      valueListenable: ProgressService.instance.progress,
      builder: (context, p, _) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: appPalette.value.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: accent.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_fire_department_rounded, color: accent, size: 40),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${p.streak}',
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      AppTexts.get('day_streak'),
                      style: TextStyle(
                        color: onSurface.withOpacity(0.5),
                        fontSize: 14,
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

  Widget _buildQuestCard(
    BuildContext context,
    Quest quest,
    QuestStatus status,
    Color accent,
    Color onSurface, {
    bool isPersonal = false,
    VoidCallback? onRemovePersonal,
  }) {
    final progress = (status.currentValue / quest.targetValue).clamp(0.0, 1.0);
    final isCompleted = status.isCompleted;

    return InkWell(
      onTap: isCompleted ? null : () {
        uiTapClick(UiClickSound.soft);
        
        TrainingMode? mode;
        final bool modeFromQuest = quest.type == QuestType.trainMode ||
            (quest.type == QuestType.personalCustomGoal && quest.modeId != null);
        if (modeFromQuest && quest.modeId != null) {
          switch (quest.modeId) {
            case 'numbers': mode = TrainingMode.standard; break;
            case 'binary': mode = TrainingMode.binary; break;
            case 'words': mode = TrainingMode.words; break;
            case 'photo': mode = TrainingMode.images; break;
            case 'images': mode = TrainingMode.images; break;
            case 'cards': mode = TrainingMode.cards; break;
            case 'faces': mode = TrainingMode.faces; break;
          }
        }

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TrainingScreen(initialMode: mode)),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: appPalette.value.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isCompleted ? accent.withOpacity(0.4) : appPalette.value.border.withOpacity(0.5),
            width: isCompleted ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getQuestIcon(quest.type, accent),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.getTitle(appLanguage.value.name),
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),


                      Text(
                        '+${quest.rewardXp} XP',
                        style: TextStyle(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  Icon(Icons.check_circle_rounded, color: accent, size: 28),
                if (isPersonal && onRemovePersonal != null)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    tooltip: AppTexts.get('personal_goal_delete_confirm'),
                    icon: Icon(Icons.close_rounded, color: onSurface.withOpacity(0.28), size: 20),
                    onPressed: onRemovePersonal,
                  )
                else if (!isCompleted)
                  Icon(Icons.arrow_forward_ios_rounded, color: onSurface.withOpacity(0.2), size: 16),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: appPalette.value.background,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        height: 12,
                        width: (MediaQuery.of(context).size.width - 88) * progress, // Adjusted width
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accent, accent.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            if (progress > 0)
                              BoxShadow(
                                color: accent.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isCompleted) ...[
                  const SizedBox(width: 12),
                  Text(
                    '${status.currentValue}/${quest.targetValue}',
                    style: TextStyle(
                      color: onSurface.withOpacity(0.4),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getQuestIcon(QuestType type, Color accent) {
    IconData iconData;
    switch (type) {
      case QuestType.memorizeN:
      case QuestType.totalMemorizedN:
        iconData = Icons.psychology_rounded;
        break;
      case QuestType.noErrors:
        iconData = Icons.verified_rounded;
        break;
      case QuestType.completeXTrainings:
        iconData = Icons.fitness_center_rounded;
        break;
      case QuestType.trainMode:
        iconData = Icons.play_circle_outline_rounded;
        break;
      case QuestType.improveRecord:
        iconData = Icons.emoji_events_rounded;
        break;
      case QuestType.streakXDays:
        iconData = Icons.bolt_rounded;
        break;
      case QuestType.personalCustomGoal:
        iconData = Icons.flag_outlined;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: accent, size: 22),
    );
  }
}

class _PersonalGoalComposerSheet extends StatefulWidget {
  final Color accent;

  const _PersonalGoalComposerSheet({required this.accent});

  @override
  State<_PersonalGoalComposerSheet> createState() => _PersonalGoalComposerSheetState();
}

class _PersonalGoalComposerSheetState extends State<_PersonalGoalComposerSheet> {
  int _template = 0;
  double _sessions = 3;
  double _minItems = 50;
  String? _modeId = 'numbers';

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.82;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Material(
            color: palette.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(22, 10, 22, 18 + bottom),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: onSurface.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        AppTexts.get('personal_goal_sheet_title'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 17,
                          fontWeight: FontWeight.w200,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          _templateChip(
                            palette: palette,
                            onSurface: onSurface,
                            index: 0,
                            title: AppTexts.get('personal_goal_template_volume'),
                            subtitle: AppTexts.get('personal_goal_template_volume_desc'),
                          ),
                          _templateChip(
                            palette: palette,
                            onSurface: onSurface,
                            index: 1,
                            title: AppTexts.get('personal_goal_template_perfect'),
                            subtitle: AppTexts.get('personal_goal_template_perfect_desc'),
                          ),
                          _templateChip(
                            palette: palette,
                            onSurface: onSurface,
                            index: 2,
                            title: AppTexts.get('personal_goal_template_mode'),
                            subtitle: AppTexts.get('personal_goal_template_mode_desc'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        AppTexts.get('personal_goal_sessions_label'),
                        style: TextStyle(
                          color: onSurface.withOpacity(0.45),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                        ),
                        child: Slider(
                          value: _sessions,
                          min: 1,
                          max: 12,
                          divisions: 11,
                          activeColor: widget.accent,
                          inactiveColor: widget.accent.withOpacity(0.15),
                          onChanged: (v) {
                            uiTapClick(UiClickSound.soft);
                            setState(() => _sessions = v);
                          },
                        ),
                      ),
                      Text(
                        '${_sessions.round()}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: widget.accent,
                          fontSize: 22,
                          fontWeight: FontWeight.w200,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppTexts.get('personal_goal_min_items_label'),
                        style: TextStyle(
                          color: onSurface.withOpacity(0.45),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                        ),
                        child: Slider(
                          value: _minItems,
                          min: 4,
                          max: 100,
                          divisions: 48,
                          activeColor: widget.accent,
                          inactiveColor: widget.accent.withOpacity(0.15),
                          onChanged: (v) {
                            uiTapClick(UiClickSound.soft);
                            setState(() => _minItems = v);
                          },
                        ),
                      ),
                      Text(
                        '${_minItems.round()}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: widget.accent,
                          fontSize: 22,
                          fontWeight: FontWeight.w200,
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _template == 2
                            ? Column(
                                key: const ValueKey('mode'),
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 16),
                                  Text(
                                    AppTexts.get('personal_goal_mode_label'),
                                    style: TextStyle(
                                      color: onSurface.withOpacity(0.45),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _modeId ?? 'numbers',
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: palette.background,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(color: palette.border.withOpacity(0.35)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(color: palette.border.withOpacity(0.35)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(color: widget.accent.withOpacity(0.45)),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    dropdownColor: palette.surface,
                                    style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.w500),
                                    items: const [
                                      'numbers',
                                      'binary',
                                      'words',
                                      'images',
                                      'cards',
                                      'faces',
                                    ].map((id) {
                                      return DropdownMenuItem<String>(
                                        value: id,
                                        child: Text(_modeLabelFor(id)),
                                      );
                                    }).toList(),
                                    onChanged: (v) {
                                      if (v == null) return;
                                      setState(() => _modeId = v);
                                    },
                                  ),
                                ],
                              )
                            : const SizedBox(key: ValueKey('empty'), height: 8),
                      ),
                      const SizedBox(height: 28),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.94, end: 1),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutBack,
                        builder: (context, s, child) {
                          return Transform.scale(scale: s, child: child);
                        },
                        child: FilledButton(
                          onPressed: _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: widget.accent,
                            foregroundColor: palette.background,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 0,
                          ),
                          child: Text(
                            AppTexts.get('personal_goal_create'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _modeLabelFor(String id) {
    switch (id) {
      case 'numbers':
        return AppTexts.get('mode_numbers');
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
        return id;
    }
  }

  Widget _templateChip({
    required AppPalette palette,
    required Color onSurface,
    required int index,
    required String title,
    required String subtitle,
  }) {
    final sel = _template == index;
    return Expanded(
      child: AnimatedScale(
        scale: sel ? 1.02 : 1,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              uiTapClick(UiClickSound.soft);
              setState(() => _template = index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: sel ? widget.accent.withOpacity(0.55) : palette.border.withOpacity(0.35),
                  width: sel ? 2 : 1,
                ),
                color: sel ? widget.accent.withOpacity(0.07) : palette.background.withOpacity(0.4),
              ),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: onSurface.withOpacity(sel ? 0.95 : 0.72),
                      fontSize: 11,
                      fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: onSurface.withOpacity(0.38),
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_template == 2 && (_modeId == null || _modeId!.isEmpty)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppTexts.get('personal_goal_pick_mode'))),
        );
      }
      return;
    }
    final sessions = _sessions.round().clamp(1, 12);
    final minIt = _minItems.round().clamp(4, 100);
    final quest = QuestService.instance.buildPersonalQuest(
      sessions: sessions,
      minItems: minIt,
      modeId: _template == 2 ? _modeId : null,
      requirePerfect: _template == 1,
    );
    final ok = await QuestService.instance.addPersonalQuest(quest);
    if (!mounted) return;
    Navigator.of(context).pop();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppTexts.get('personal_goal_max'))),
      );
    }
  }
}
