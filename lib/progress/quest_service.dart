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
  static const int _kMaxPersonalQuests = 5;

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

    final shouldResetDaily = currentState.lastDailyReset.isBefore(today) ||
        currentState.lastDailyReset.isAfter(today) ||
        currentState.dailyQuests.isEmpty ||
        currentState.dailyQuests.length != currentState.dailyStatuses.length;
    final shouldResetWeekly = currentState.lastWeeklyReset.isBefore(currentWeeklyReset) ||
        currentState.lastWeeklyReset.isAfter(currentWeeklyReset) ||
        currentState.weeklyQuests.isEmpty ||
        currentState.weeklyQuests.length != currentState.weeklyStatuses.length;

    if (shouldResetDaily) {
      currentState = _generateDailyQuests(currentState, today);
      changed = true;
    }

    if (shouldResetWeekly) {
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

    final modes = ['numbers', 'binary', 'words', 'images', 'cards'];
    
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
      int rewardXp = 5;
      String? modeId;

      switch (type) {
        case QuestType.memorizeN:
          targetValue = 10 + (userLevel * 2);
          titleRu = 'Запомнить $targetValue элементов';
          titleEn = 'Memorize $targetValue items';
          titleDe = '$targetValue Elemente merken';
          rewardXp = 5;
          break;
        case QuestType.noErrors:
          titleRu = 'Тренировка без ошибок';
          titleEn = 'Training without errors';
          titleDe = 'Fehlerfreies Training';
          rewardXp = 5;
          break;
        case QuestType.completeXTrainings:
          targetValue = 2 + (userLevel > 10 ? 1 : 0);
          titleRu = 'Пройти $targetValue тренировки';
          titleEn = 'Complete $targetValue trainings';
          titleDe = '$targetValue Trainings abschließen';
          rewardXp = 5;
          break;
        case QuestType.trainMode:
          modeId = modes[random.nextInt(modes.length)];
          final modeNameRu = _getModeNameRu(modeId);
          final modeNameEn = _getModeNameEn(modeId);
          final modeNameDe = _getModeNameDe(modeId);
          titleRu = 'Тренировка: $modeNameRu';
          titleEn = 'Train mode: $modeNameEn';
          titleDe = 'Trainingsmodus: $modeNameDe';
          rewardXp = 5;
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
      personalQuests: current.personalQuests,
      personalStatuses: current.personalStatuses,
      removedPersonalQuestIds: current.removedPersonalQuestIds,
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
      int rewardXp = 10;

      switch (type) {
        case QuestType.totalMemorizedN:
          targetValue = 100 + (userLevel * 20);
          titleRu = 'Запомнить всего $targetValue элементов';
          titleEn = 'Memorize $targetValue items total';
          titleDe = 'Insgesamt $targetValue Elemente merken';
          rewardXp = 10;
          break;
        case QuestType.completeXTrainings:
          targetValue = 10 + (userLevel > 5 ? 5 : 0);
          titleRu = 'Пройти $targetValue тренировок';
          titleEn = 'Complete $targetValue trainings';
          titleDe = '$targetValue Trainings abschließen';
          rewardXp = 10;
          break;
        case QuestType.improveRecord:
          titleRu = 'Улучшить личный рекорд';
          titleEn = 'Improve personal record';
          titleDe = 'Persönlichen Rekord verbessern';
          rewardXp = 10;
          break;
        case QuestType.streakXDays:
          targetValue = 5;
          titleRu = 'Ударный режим: $targetValue дней';
          titleEn = 'Streak: $targetValue days';
          titleDe = 'Serie: $targetValue Tage';
          rewardXp = 10;
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
      personalQuests: current.personalQuests,
      personalStatuses: current.personalStatuses,
      removedPersonalQuestIds: current.removedPersonalQuestIds,
      lastDailyReset: current.lastDailyReset,
      lastWeeklyReset: date,
      allDailyCompletedRewarded: current.allDailyCompletedRewarded,
    );
  }

  /// Creates a user goal: [sessions] trainings with at least [minItems] elements each (session length).
  Quest buildPersonalQuest({
    required int sessions,
    required int minItems,
    String? modeId,
    bool requirePerfect = false,
  }) {
    final norm = modeId == null || modeId.isEmpty ? null : _normalizeModeId(modeId);
    final id = 'personal_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1 << 20)}';
    const xp = 0; // Personal goals track progress only — no XP payout.
    final modeRu = norm == null ? null : _getModeNameRu(norm);
    final modeEn = norm == null ? null : _getModeNameEn(norm);
    final modeDe = norm == null ? null : _getModeNameDe(norm);

    String titleRu;
    String titleEn;
    String titleDe;
    if (requirePerfect) {
      if (norm != null) {
        titleRu = '$sessions идеальных трен. от $minItems эл. · $modeRu';
        titleEn = '$sessions perfect sessions ($minItems+ items) · $modeEn';
        titleDe = '$sessions perfekte Trainings ab $minItems El. · $modeDe';
      } else {
        titleRu = '$sessions идеальных тренировок от $minItems элементов';
        titleEn = '$sessions perfect trainings ($minItems+ items each)';
        titleDe = '$sessions perfekte Trainings je $minItems+ Elemente';
      }
    } else if (norm != null) {
      titleRu = '$sessions тренировок от $minItems эл. · $modeRu';
      titleEn = '$sessions trainings ($minItems+ items) · $modeEn';
      titleDe = '$sessions Trainings ab $minItems El. · $modeDe';
    } else {
      titleRu = '$sessions тренировок от $minItems элементов';
      titleEn = '$sessions trainings of $minItems+ items';
      titleDe = '$sessions Trainings je $minItems+ Elemente';
    }

    return Quest(
      id: id,
      type: QuestType.personalCustomGoal,
      period: QuestPeriod.personal,
      titleRu: titleRu,
      titleEn: titleEn,
      titleDe: titleDe,
      targetValue: max(1, sessions),
      rewardXp: xp,
      modeId: norm,
      minSessionItems: max(1, minItems),
      requirePerfect: requirePerfect,
    );
  }

  Future<bool> addPersonalQuest(Quest quest) async {
    if (quest.period != QuestPeriod.personal || quest.type != QuestType.personalCustomGoal) {
      return false;
    }
    var s = state.value;
    if (s.personalQuests.length >= _kMaxPersonalQuests) return false;
    final nextQuests = List<Quest>.from(s.personalQuests)..add(quest);
    final nextStatuses = List<QuestStatus>.from(s.personalStatuses)
      ..add(QuestStatus(questId: quest.id));
    state.value = QuestState(
      dailyQuests: s.dailyQuests,
      dailyStatuses: s.dailyStatuses,
      weeklyQuests: s.weeklyQuests,
      weeklyStatuses: s.weeklyStatuses,
      personalQuests: nextQuests,
      personalStatuses: nextStatuses,
      removedPersonalQuestIds: s.removedPersonalQuestIds,
      lastDailyReset: s.lastDailyReset,
      lastWeeklyReset: s.lastWeeklyReset,
      allDailyCompletedRewarded: s.allDailyCompletedRewarded,
    );
    await _save();
    return true;
  }

  Future<void> removePersonalQuest(String questId) async {
    final s = state.value;
    if (!s.personalQuests.any((q) => q.id == questId)) return;
    final nextQuests = s.personalQuests.where((q) => q.id != questId).toList();
    final nextStatuses =
        s.personalStatuses.where((st) => st.questId != questId).toList();
    state.value = QuestState(
      dailyQuests: s.dailyQuests,
      dailyStatuses: s.dailyStatuses,
      weeklyQuests: s.weeklyQuests,
      weeklyStatuses: s.weeklyStatuses,
      personalQuests: nextQuests,
      personalStatuses: nextStatuses,
      removedPersonalQuestIds: {...s.removedPersonalQuestIds, questId},
      lastDailyReset: s.lastDailyReset,
      lastWeeklyReset: s.lastWeeklyReset,
      allDailyCompletedRewarded: s.allDailyCompletedRewarded,
    );
    await _save();
  }

  /// Call after each finished training (same moment as other quest updates).
  Future<void> recordPersonalTrainingSession({
    required String modeId,
    required int sessionItemCount,
    required bool isPerfectSession,
  }) async {
    var currentState = state.value;
    final completedQuests = <Quest>[];
    final newStatuses = <QuestStatus>[];

    for (var i = 0; i < currentState.personalQuests.length; i++) {
      final quest = currentState.personalQuests[i];
      var status = currentState.personalStatuses[i];

      if (status.isCompleted || quest.type != QuestType.personalCustomGoal) {
        newStatuses.add(status);
        continue;
      }

      final minItems = quest.minSessionItems ?? 1;
      if (sessionItemCount < minItems) {
        newStatuses.add(status);
        continue;
      }
      if (quest.requirePerfect && !isPerfectSession) {
        newStatuses.add(status);
        continue;
      }
      if (quest.modeId != null &&
          _normalizeModeId(quest.modeId) != _normalizeModeId(modeId)) {
        newStatuses.add(status);
        continue;
      }

      final newValue = (status.currentValue + 1).clamp(0, quest.targetValue);
      final isCompleted = newValue >= quest.targetValue;
      newStatuses.add(status.copyWith(currentValue: newValue, isCompleted: isCompleted));
      if (isCompleted && !status.isCompleted) {
        completedQuests.add(quest);
      }
    }

    var changed = false;
    for (var i = 0; i < newStatuses.length; i++) {
      if (newStatuses[i].currentValue != currentState.personalStatuses[i].currentValue ||
          newStatuses[i].isCompleted != currentState.personalStatuses[i].isCompleted) {
        changed = true;
        break;
      }
    }
    if (!changed) return;

    state.value = QuestState(
      dailyQuests: currentState.dailyQuests,
      dailyStatuses: currentState.dailyStatuses,
      weeklyQuests: currentState.weeklyQuests,
      weeklyStatuses: currentState.weeklyStatuses,
      personalQuests: currentState.personalQuests,
      personalStatuses: newStatuses,
      removedPersonalQuestIds: currentState.removedPersonalQuestIds,
      lastDailyReset: currentState.lastDailyReset,
      lastWeeklyReset: currentState.lastWeeklyReset,
      allDailyCompletedRewarded: currentState.allDailyCompletedRewarded,
    );
    await _save();

    for (final q in completedQuests) {
      await _onQuestCompleted(q);
    }
  }

  String _getModeNameRu(String modeId) {
    switch (_normalizeModeId(modeId)) {
      case 'numbers': return 'Числа';
      case 'binary': return 'Бинарные числа';
      case 'words': return 'Слова';
      case 'images': return 'Изображения';
      case 'cards': return 'Карты';
      case 'faces': return 'Лица';
      default: return modeId;
    }
  }

  String _getModeNameEn(String modeId) {
    switch (_normalizeModeId(modeId)) {
      case 'numbers': return 'Numbers';
      case 'binary': return 'Binary';
      case 'words': return 'Words';
      case 'images': return 'Images';
      case 'cards': return 'Cards';
      case 'faces': return 'Faces';
      default: return modeId;
    }
  }

  String _getModeNameDe(String modeId) {
    switch (_normalizeModeId(modeId)) {
      case 'numbers': return 'Zahlen';
      case 'binary': return 'Binärzahlen';
      case 'words': return 'Worte';
      case 'images': return 'Bilder';
      case 'cards': return 'Karten';
      case 'faces': return 'Gesichter';
      default: return modeId;
    }
  }

  String? _normalizeModeId(String? modeId) {
    if (modeId == null) return null;
    if (modeId == 'photo') return 'images';
    if (modeId == 'standard') return 'numbers';
    return modeId;
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
          if (_normalizeModeId(quest.modeId) == _normalizeModeId(modeId)) {
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
        personalQuests: currentState.personalQuests,
        personalStatuses: currentState.personalStatuses,
        removedPersonalQuestIds: currentState.removedPersonalQuestIds,
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
    final xpReward = quest.period == QuestPeriod.personal ? 0 : quest.rewardXp;
    if (xpReward > 0) {
      await ProgressService.instance.addXP(xpReward, countForStreak: true);
    }
    ProgressService.instance.emitQuestCompleted(QuestCompletedEvent(
      titleRu: quest.titleRu,
      titleEn: quest.titleEn,
      titleDe: quest.titleDe,
      xpReward: xpReward,
    ));
  }

  Future<void> _checkAllDailyBonus() async {
    final s = state.value;
    if (s.allDailyCompletedRewarded) return;

    final allDone = s.dailyStatuses.every((st) => st.isCompleted);
    
    if (allDone) {
      await ProgressService.instance.addXP(1, countForStreak: true);
      ProgressService.instance.emitQuestCompleted(const QuestCompletedEvent(
        titleRu: 'Все ежедневные задания выполнены!',
        titleEn: 'All daily quests completed!',
        titleDe: 'Alle täglichen Aufgaben abgeschlossen!',
        xpReward: 1,
      ));
      state.value = QuestState(
        dailyQuests: s.dailyQuests,
        dailyStatuses: s.dailyStatuses,
        weeklyQuests: s.weeklyQuests,
        weeklyStatuses: s.weeklyStatuses,
        personalQuests: s.personalQuests,
        personalStatuses: s.personalStatuses,
        removedPersonalQuestIds: s.removedPersonalQuestIds,
        lastDailyReset: s.lastDailyReset,
        lastWeeklyReset: s.lastWeeklyReset,
        allDailyCompletedRewarded: true,
      );
      await _save();
    }
  }

  Map<String, dynamic> toCloudJson() => state.value.toJson();

  /// Merges cloud quest boards with local — never downgrades progress on APK update / stale cloud.
  Future<void> mergeCloudJson(Map<String, dynamic> raw) async {
    try {
      final local = state.value;
      final cloud = QuestState.fromJson(raw);
      state.value = _mergeQuestStates(local, cloud);
      await _save();
      await checkResets();
    } catch (e) {
      debugPrint('Error merging cloud quest state: $e');
    }
  }

  QuestState _mergeQuestStates(QuestState local, QuestState cloud) {
    final useCloudDaily = cloud.lastDailyReset.isAfter(local.lastDailyReset) ||
        (local.dailyQuests.isEmpty && cloud.dailyQuests.isNotEmpty);
    final useCloudWeekly = cloud.lastWeeklyReset.isAfter(local.lastWeeklyReset) ||
        (local.weeklyQuests.isEmpty && cloud.weeklyQuests.isNotEmpty);

    final dailyQuests = useCloudDaily ? cloud.dailyQuests : local.dailyQuests;
    final dailyStatuses = _mergeStatusesForBoard(
      quests: dailyQuests,
      localStatuses: local.dailyStatuses,
      cloudStatuses: cloud.dailyStatuses,
    );

    final weeklyQuests = useCloudWeekly ? cloud.weeklyQuests : local.weeklyQuests;
    final weeklyStatuses = _mergeStatusesForBoard(
      quests: weeklyQuests,
      localStatuses: local.weeklyStatuses,
      cloudStatuses: cloud.weeklyStatuses,
    );

    final personalMerged = _mergePersonalBoard(local, cloud);
    final removedPersonalQuestIds = {
      ...local.removedPersonalQuestIds,
      ...cloud.removedPersonalQuestIds,
    };

    return QuestState(
      dailyQuests: dailyQuests,
      dailyStatuses: dailyStatuses,
      weeklyQuests: weeklyQuests,
      weeklyStatuses: weeklyStatuses,
      personalQuests: personalMerged.quests,
      personalStatuses: personalMerged.statuses,
      removedPersonalQuestIds: removedPersonalQuestIds,
      lastDailyReset: useCloudDaily ? cloud.lastDailyReset : local.lastDailyReset,
      lastWeeklyReset: useCloudWeekly ? cloud.lastWeeklyReset : local.lastWeeklyReset,
      allDailyCompletedRewarded:
          local.allDailyCompletedRewarded || cloud.allDailyCompletedRewarded,
    );
  }

  List<QuestStatus> _mergeStatusesForBoard({
    required List<Quest> quests,
    required List<QuestStatus> localStatuses,
    required List<QuestStatus> cloudStatuses,
  }) {
    final localById = {for (final s in localStatuses) s.questId: s};
    final cloudById = {for (final s in cloudStatuses) s.questId: s};
    return [
      for (final q in quests)
        _mergeSingleStatus(
          questId: q.id,
          local: localById[q.id],
          cloud: cloudById[q.id],
        ),
    ];
  }

  QuestStatus _mergeSingleStatus({
    required String questId,
    QuestStatus? local,
    QuestStatus? cloud,
  }) {
    if (local == null && cloud == null) {
      return QuestStatus(questId: questId);
    }
    if (local == null) return cloud!;
    if (cloud == null) return local;

    return QuestStatus(
      questId: questId,
      currentValue: max(local.currentValue, cloud.currentValue),
      isCompleted: local.isCompleted || cloud.isCompleted,
      isRewarded: local.isRewarded || cloud.isRewarded,
    );
  }

  ({List<Quest> quests, List<QuestStatus> statuses}) _mergePersonalBoard(
    QuestState local,
    QuestState cloud,
  ) {
    final removed = {...local.removedPersonalQuestIds, ...cloud.removedPersonalQuestIds};
    final questsById = <String, Quest>{};
    for (final q in local.personalQuests) {
      if (!removed.contains(q.id)) questsById[q.id] = q;
    }
    for (final q in cloud.personalQuests) {
      if (!removed.contains(q.id)) questsById.putIfAbsent(q.id, () => q);
    }

    final localById = {for (final s in local.personalStatuses) s.questId: s};
    final cloudById = {for (final s in cloud.personalStatuses) s.questId: s};

    final quests = questsById.values.toList(growable: false);
    final statuses = [
      for (final q in quests)
        _mergeSingleStatus(
          questId: q.id,
          local: localById[q.id],
          cloud: cloudById[q.id],
        ),
    ];
    return (quests: quests, statuses: statuses);
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
