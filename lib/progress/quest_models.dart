import 'package:flutter/foundation.dart';

enum QuestPeriod { daily, weekly }

enum QuestType {
  memorizeN,
  noErrors,
  completeXTrainings,
  trainMode,
  totalMemorizedN,
  improveRecord,
  streakXDays,
}

@immutable
class Quest {
  final String id;
  final QuestType type;
  final QuestPeriod period;
  final String titleRu;
  final String titleEn;
  final String titleDe;
  final int targetValue;
  final int rewardXp;
  final String? modeId; // For trainMode type

  const Quest({
    required this.id,
    required this.type,
    required this.period,
    required this.titleRu,
    required this.titleEn,
    required this.titleDe,
    required this.targetValue,
    required this.rewardXp,
    this.modeId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'period': period.name,
        'titleRu': titleRu,
        'titleEn': titleEn,
        'titleDe': titleDe,
        'targetValue': targetValue,
        'rewardXp': rewardXp,
        'modeId': modeId,
      };

  factory Quest.fromJson(Map<String, dynamic> json) => Quest(
        id: json['id'],
        type: QuestType.values.byName(json['type']),
        period: QuestPeriod.values.byName(json['period']),
        titleRu: json['titleRu'],
        titleEn: json['titleEn'],
        titleDe: json['titleDe'] ?? json['titleEn'], // Fallback for old data
        targetValue: json['targetValue'],
        rewardXp: json['rewardXp'],
        modeId: json['modeId'],
      );

  String getTitle(String lang) {
    switch (lang) {
      case 'ru': return titleRu;
      case 'de': return titleDe;
      case 'en':
      default: return titleEn;
    }
  }
}

@immutable
class QuestStatus {
  final String questId;
  final int currentValue;
  final bool isCompleted;
  final bool isRewarded;

  const QuestStatus({
    required this.questId,
    this.currentValue = 0,
    this.isCompleted = false,
    this.isRewarded = false,
  });

  QuestStatus copyWith({
    int? currentValue,
    bool? isCompleted,
    bool? isRewarded,
  }) {
    return QuestStatus(
      questId: questId,
      currentValue: currentValue ?? this.currentValue,
      isCompleted: isCompleted ?? this.isCompleted,
      isRewarded: isRewarded ?? this.isRewarded,
    );
  }

  Map<String, dynamic> toJson() => {
        'questId': questId,
        'currentValue': currentValue,
        'isCompleted': isCompleted,
        'isRewarded': isRewarded,
      };

  factory QuestStatus.fromJson(Map<String, dynamic> json) => QuestStatus(
        questId: json['questId'],
        currentValue: json['currentValue'],
        isCompleted: json['isCompleted'],
        isRewarded: json['isRewarded'],
      );
}

@immutable
class QuestState {
  final List<Quest> dailyQuests;
  final List<QuestStatus> dailyStatuses;
  final List<Quest> weeklyQuests;
  final List<QuestStatus> weeklyStatuses;
  final DateTime lastDailyReset;
  final DateTime lastWeeklyReset;
  final bool allDailyCompletedRewarded;

  const QuestState({
    required this.dailyQuests,
    required this.dailyStatuses,
    required this.weeklyQuests,
    required this.weeklyStatuses,
    required this.lastDailyReset,
    required this.lastWeeklyReset,
    this.allDailyCompletedRewarded = false,
  });

  Map<String, dynamic> toJson() => {
        'dailyQuests': dailyQuests.map((q) => q.toJson()).toList(),
        'dailyStatuses': dailyStatuses.map((s) => s.toJson()).toList(),
        'weeklyQuests': weeklyQuests.map((q) => q.toJson()).toList(),
        'weeklyStatuses': weeklyStatuses.map((s) => s.toJson()).toList(),
        'lastDailyReset': lastDailyReset.toIso8601String(),
        'lastWeeklyReset': lastWeeklyReset.toIso8601String(),
        'allDailyCompletedRewarded': allDailyCompletedRewarded,
      };

  factory QuestState.fromJson(Map<String, dynamic> json) => QuestState(
        dailyQuests: (json['dailyQuests'] as List).map((q) => Quest.fromJson(q)).toList(),
        dailyStatuses: (json['dailyStatuses'] as List).map((s) => QuestStatus.fromJson(s)).toList(),
        weeklyQuests: (json['weeklyQuests'] as List).map((q) => Quest.fromJson(q)).toList(),
        weeklyStatuses: (json['weeklyStatuses'] as List).map((s) => QuestStatus.fromJson(s)).toList(),
        lastDailyReset: DateTime.parse(json['lastDailyReset']),
        lastWeeklyReset: DateTime.parse(json['lastWeeklyReset']),
        allDailyCompletedRewarded: json['allDailyCompletedRewarded'] ?? false,
      );

  static QuestState initial() => QuestState(
        dailyQuests: [],
        dailyStatuses: [],
        weeklyQuests: [],
        weeklyStatuses: [],
        lastDailyReset: DateTime.fromMillisecondsSinceEpoch(0),
        lastWeeklyReset: DateTime.fromMillisecondsSinceEpoch(0),
        allDailyCompletedRewarded: false,
      );
}
