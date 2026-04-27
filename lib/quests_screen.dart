import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'progress/quest_service.dart';
import 'progress/quest_models.dart';
import 'progress/progress_service.dart';
import 'progress/progress_events.dart';
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
    Color onSurface,
  ) {
    final progress = (status.currentValue / quest.targetValue).clamp(0.0, 1.0);
    final isCompleted = status.isCompleted;

    return InkWell(
      onTap: isCompleted ? null : () {
        HapticFeedback.lightImpact();
        
        TrainingMode? mode;
        if (quest.type == QuestType.trainMode && quest.modeId != null) {
          switch (quest.modeId) {
            case 'numbers': mode = TrainingMode.standard; break;
            case 'binary': mode = TrainingMode.binary; break;
            case 'words': mode = TrainingMode.words; break;
            case 'photo': mode = TrainingMode.images; break;
            case 'cards': mode = TrainingMode.cards; break;
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
                  Icon(Icons.check_circle_rounded, color: accent, size: 28)
                else
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
