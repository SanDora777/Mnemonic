import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'quest_models.dart';
import 'progress_service.dart';
import 'progress_events.dart';

class QuestService {
  QuestService._();
  static final QuestService instance = QuestService._();

  static const _kQuestStateKey = 'quest_state';

  final ValueNotifier<QuestState> state = ValueNotifier(QuestState.initial());

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_kQuestStateKey);
    if (jsonStr != null) {
      try {
        state.value = QuestState.fromJson(jsonDecode(jsonStr));
      } catch (e) {
        debugPrint('Error loading quest state: $e');
      }
    }
    await checkResets();
    // Check for streak quest on init
    await updateProgress(type: QuestType.streakXDays, value: 0);
  }

  Future<void> checkResets() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final currentWeeklyReset = _getWeeklyResetDate(now);

    bool changed = false;
    var currentState = state.value;

    if (currentState.lastDailyReset.isBefore(today)) {
      currentState = _generateDailyQuests(currentState, today);
      changed = true;
    }

    if (currentState.lastWeeklyReset.isBefore(currentWeeklyReset)) {
      currentState = _generateWeeklyQuests(currentState, currentWeeklyReset);
      changed = true;
    }

    if (changed) {
      state.value = currentState;
      await _save();
    }
  }

  DateTime _getWeeklyResetDate(DateTime now) {
    final daysToSubtract = (now.weekday - 1);
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract));
    return monday;
  }

  QuestState _generateDailyQuests(QuestState current, DateTime date) {
    final userLevel = ProgressService.instance.progress.value.level;
    final random = Random();
    
    final dailyPool = [
      QuestType.memorizeN,
      QuestType.noErrors,
      QuestType.completeXTrainings,
      QuestType.trainMode,
    ];

    final modes = ['numbers', 'binary', 'words', 'photo', 'cards'];
    
    final newQuests = <Quest>[];
    final newStatuses = <QuestStatus>[];

    final selectedTypes = (dailyPool..shuffle(random)).take(3).toList();

    for (int i = 0; i < selectedTypes.length; i++) {
      final type = selectedTypes[i];
      final id = 'daily_${date.millisecondsSinceEpoch}_$i';
      
      String titleRu = '';
      String titleEn = '';
      String titleDe = '';
      int targetValue = 1;
      int rewardXp = 20;
      String? modeId;

      switch (type) {
        case QuestType.memorizeN:
          targetValue = 10 + (userLevel * 2);
          titleRu = 'Запомнить $targetValue элементов';
          titleEn = 'Memorize $targetValue items';
          titleDe = '$targetValue Elemente merken';
          rewardXp = 30;
          break;
        case QuestType.noErrors:
          titleRu = 'Тренировка без ошибок';
          titleEn = 'Training without errors';
          titleDe = 'Fehlerfreies Training';
          rewardXp = 40;
          break;
        case QuestType.completeXTrainings:
          targetValue = 2 + (userLevel > 10 ? 1 : 0);
          titleRu = 'Пройти $targetValue тренировки';
          titleEn = 'Complete $targetValue trainings';
          titleDe = '$targetValue Trainings abschließen';
          rewardXp = 25;
          break;
        case QuestType.trainMode:
          modeId = modes[random.nextInt(modes.length)];
          final modeNameRu = _getModeNameRu(modeId);
          final modeNameEn = _getModeNameEn(modeId);
          final modeNameDe = _getModeNameDe(modeId);
          titleRu = 'Тренировка: $modeNameRu';
          titleEn = 'Train mode: $modeNameEn';
          titleDe = 'Trainingsmodus: $modeNameDe';
          rewardXp = 20;
          break;
        default:
          break;
      }

      final quest = Quest(
        id: id,
        type: type,
        period: QuestPeriod.daily,
        titleRu: titleRu,
        titleEn: titleEn,
        titleDe: titleDe,
        targetValue: targetValue,
        rewardXp: rewardXp,
        modeId: modeId,
      );
      newQuests.add(quest);
      newStatuses.add(QuestStatus(questId: id));
    }

    return QuestState(
      dailyQuests: newQuests,
      dailyStatuses: newStatuses,
      weeklyQuests: current.weeklyQuests,
      weeklyStatuses: current.weeklyStatuses,
      lastDailyReset: date,
      lastWeeklyReset: current.lastWeeklyReset,
      allDailyCompletedRewarded: false,
    );
  }

  QuestState _generateWeeklyQuests(QuestState current, DateTime date) {
    final userLevel = ProgressService.instance.progress.value.level;
    final random = Random();
    
    final weeklyPool = [
      QuestType.totalMemorizedN,
      QuestType.completeXTrainings,
      QuestType.improveRecord,
      QuestType.streakXDays,
    ];

    final newQuests = <Quest>[];
    final newStatuses = <QuestStatus>[];

    final selectedTypes = (weeklyPool..shuffle(random)).take(4).toList();

    for (int i = 0; i < selectedTypes.length; i++) {
      final type = selectedTypes[i];
      final id = 'weekly_${date.millisecondsSinceEpoch}_$i';
      
      String titleRu = '';
      String titleEn = '';
      String titleDe = '';
      int targetValue = 1;
      int rewardXp = 100;

      switch (type) {
        case QuestType.totalMemorizedN:
          targetValue = 100 + (userLevel * 20);
          titleRu = 'Запомнить всего $targetValue элементов';
          titleEn = 'Memorize $targetValue items total';
          titleDe = 'Insgesamt $targetValue Elemente merken';
          rewardXp = 150;
          break;
        case QuestType.completeXTrainings:
          targetValue = 10 + (userLevel > 5 ? 5 : 0);
          titleRu = 'Пройти $targetValue тренировок';
          titleEn = 'Complete $targetValue trainings';
          titleDe = '$targetValue Trainings abschließen';
          rewardXp = 120;
          break;
        case QuestType.improveRecord:
          titleRu = 'Улучшить личный рекорд';
          titleEn = 'Improve personal record';
          titleDe = 'Persönlichen Rekord verbessern';
          rewardXp = 200;
          break;
        case QuestType.streakXDays:
          targetValue = 5;
          titleRu = 'Ударный режим: $targetValue дней';
          titleEn = 'Streak: $targetValue days';
          titleDe = 'Serie: $targetValue Tage';
          rewardXp = 250;
          break;
        default:
          break;
      }

      final quest = Quest(
        id: id,
        type: type,
        period: QuestPeriod.weekly,
        titleRu: titleRu,
        titleEn: titleEn,
        titleDe: titleDe,
        targetValue: targetValue,
        rewardXp: rewardXp,
      );
      newQuests.add(quest);
      newStatuses.add(QuestStatus(questId: id));
    }

    return QuestState(
      dailyQuests: current.dailyQuests,
      dailyStatuses: current.dailyStatuses,
      weeklyQuests: newQuests,
      weeklyStatuses: newStatuses,
      lastDailyReset: current.lastDailyReset,
      lastWeeklyReset: date,
      allDailyCompletedRewarded: current.allDailyCompletedRewarded,
    );
  }

  String _getModeNameRu(String modeId) {
    switch (modeId) {
      case 'numbers': return 'Числа';
      case 'binary': return 'Бинарные числа';
      case 'words': return 'Слова';
      case 'photo': return 'Фотографии';
      case 'cards': return 'Карты';
      default: return modeId;
    }
  }

  String _getModeNameEn(String modeId) {
    switch (modeId) {
      case 'numbers': return 'Numbers';
      case 'binary': return 'Binary';
      case 'words': return 'Words';
      case 'photo': return 'Photo';
      case 'cards': return 'Cards';
      default: return modeId;
    }
  }

  String _getModeNameDe(String modeId) {
    switch (modeId) {
      case 'numbers': return 'Zahlen';
      case 'binary': return 'Binärzahlen';
      case 'words': return 'Worte';
      case 'photo': return 'Foto';
      case 'cards': return 'Karten';
      default: return modeId;
    }
  }

  Future<void> updateProgress({
    required QuestType type,
    int value = 1,
    String? modeId,
    bool? isPerfect,
  }) async {
    var currentState = state.value;
    bool changed = false;
    final completedQuests = <Quest>[];
    bool hasCompletedDailyQuest = false;

    final newDailyStatuses = <QuestStatus>[];
    for (int i = 0; i < currentState.dailyQuests.length; i++) {
      final quest = currentState.dailyQuests[i];
      var status = currentState.dailyStatuses[i];

      if (status.isCompleted) {
        newDailyStatuses.add(status);
        continue;
      }

      bool match = false;
      int addValue = 0;

      if (quest.type == type) {
        if (type == QuestType.trainMode) {
          if (quest.modeId == modeId) {
            match = true;
            addValue = value;
          }
        } else if (type == QuestType.noErrors) {
          if (isPerfect == true) {
            match = true;
            addValue = 1;
          }
        } else if (type == QuestType.memorizeN) {
          if (value >= quest.targetValue) {
            match = true;
            addValue = quest.targetValue; 
          }
        } else {
          match = true;
          addValue = value;
        }
      }

      if (match) {
        final newValue = status.currentValue + addValue;
        final isCompleted = newValue >= quest.targetValue;
        status = status.copyWith(
          currentValue: newValue.clamp(0, quest.targetValue),
          isCompleted: isCompleted,
        );
        changed = true;
        
        if (isCompleted) {
          completedQuests.add(quest);
          if (quest.period == QuestPeriod.daily) {
            hasCompletedDailyQuest = true;
          }
        }
      }
      newDailyStatuses.add(status);
    }

    final newWeeklyStatuses = <QuestStatus>[];
    for (int i = 0; i < currentState.weeklyQuests.length; i++) {
      final quest = currentState.weeklyQuests[i];
      var status = currentState.weeklyStatuses[i];

      if (status.isCompleted) {
        newWeeklyStatuses.add(status);
        continue;
      }

      bool match = false;
      int addValue = 0;

      if (quest.type == type) {
        match = true;
        addValue = value;
      } else if (quest.type == QuestType.totalMemorizedN && type == QuestType.memorizeN) {
        match = true;
        addValue = value;
      } else if (quest.type == QuestType.completeXTrainings && (type == QuestType.trainMode || type == QuestType.noErrors)) {
        // Any specific training also counts as a general training
        match = true;
        addValue = 1;
      } else if (quest.type == QuestType.streakXDays) {
        final currentStreak = ProgressService.instance.progress.value.streak;
        if (currentStreak >= quest.targetValue) {
          match = true;
          addValue = quest.targetValue;
        }
      }

      if (match) {
        final newValue = status.currentValue + addValue;
        final isCompleted = newValue >= quest.targetValue;
        status = status.copyWith(
          currentValue: newValue.clamp(0, quest.targetValue),
          isCompleted: isCompleted,
        );
        changed = true;

        if (isCompleted) {
          completedQuests.add(quest);
          if (quest.period == QuestPeriod.daily) {
            hasCompletedDailyQuest = true;
          }
        }
      }
      newWeeklyStatuses.add(status);
    }

    if (changed) {
      state.value = QuestState(
        dailyQuests: currentState.dailyQuests,
        dailyStatuses: newDailyStatuses,
        weeklyQuests: currentState.weeklyQuests,
        weeklyStatuses: newWeeklyStatuses,
        lastDailyReset: currentState.lastDailyReset,
        lastWeeklyReset: currentState.lastWeeklyReset,
        allDailyCompletedRewarded: state.value.allDailyCompletedRewarded,
      );
      await _save();
    }

    for (final quest in completedQuests) {
      await _onQuestCompleted(quest);
    }
    if (hasCompletedDailyQuest) {
      await _checkAllDailyBonus();
    }
  }

  Future<void> _onQuestCompleted(Quest quest) async {
    await ProgressService.instance.addXP(quest.rewardXp, countForStreak: true);
    ProgressService.instance.emitQuestCompleted(QuestCompletedEvent(
      titleRu: quest.titleRu,
      titleEn: quest.titleEn,
      titleDe: quest.titleDe,
      xpReward: quest.rewardXp,
    ));
  }

  Future<void> _checkAllDailyBonus() async {
    final s = state.value;
    if (s.allDailyCompletedRewarded) return;

    final allDone = s.dailyStatuses.every((st) => st.isCompleted);
    
    if (allDone) {
      await ProgressService.instance.addXP(50, countForStreak: true);
      ProgressService.instance.emitQuestCompleted(const QuestCompletedEvent(
        titleRu: 'Все ежедневные задания выполнены!',
        titleEn: 'All daily quests completed!',
        titleDe: 'Alle täglichen Aufgaben abgeschlossen!',
        xpReward: 50,
      ));
      state.value = QuestState(
        dailyQuests: s.dailyQuests,
        dailyStatuses: s.dailyStatuses,
        weeklyQuests: s.weeklyQuests,
        weeklyStatuses: s.weeklyStatuses,
        lastDailyReset: s.lastDailyReset,
        lastWeeklyReset: s.lastWeeklyReset,
        allDailyCompletedRewarded: true,
      );
      await _save();
    }
  }

  Map<String, dynamic> toCloudJson() => state.value.toJson();

  Future<void> applyCloudJson(Map<String, dynamic> raw) async {
    try {
      state.value = QuestState.fromJson(raw);
      await _save();
    } catch (e) {
      debugPrint('Error applying cloud quest state: $e');
    }
  }

  Future<void> resetLocalQuests() async {
    state.value = QuestState.initial();
    await _save();
    await checkResets();
    await updateProgress(type: QuestType.streakXDays, value: 0);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kQuestStateKey, jsonEncode(state.value.toJson()));
  }
}
