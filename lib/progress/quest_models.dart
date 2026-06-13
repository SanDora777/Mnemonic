import 'dart:math' as math;

import 'package:flutter/foundation.dart';

enum QuestPeriod { daily, weekly, personal }

enum QuestType {
  memorizeN,
  noErrors,
  completeXTrainings,
  trainMode,
  totalMemorizedN,
  improveRecord,
  streakXDays,
  /// User-defined: complete [targetValue] sessions with at least [minSessionItems] items each.
  personalCustomGoal,
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

  /// For [QuestType.personalCustomGoal]: each counted session must have at least this many items.
  final int? minSessionItems;

  /// For [QuestType.personalCustomGoal]: require 100% accuracy in the session.
  final bool requirePerfect;

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
    this.minSessionItems,
    this.requirePerfect = false,
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
        if (minSessionItems != null) 'minSessionItems': minSessionItems,
        if (requirePerfect) 'requirePerfect': requirePerfect,
      };

  factory Quest.fromJson(Map<String, dynamic> json) {
    QuestType parseType(String? raw) {
      if (raw == null) return QuestType.completeXTrainings;
      for (final v in QuestType.values) {
        if (v.name == raw) return v;
      }
      return QuestType.completeXTrainings;
    }

    QuestPeriod parsePeriod(String? raw) {
      if (raw == null) return QuestPeriod.daily;
      for (final v in QuestPeriod.values) {
        if (v.name == raw) return v;
      }
      return QuestPeriod.daily;
    }

    return Quest(
      id: json['id'].toString(),
      type: parseType(json['type']?.toString()),
      period: parsePeriod(json['period']?.toString()),
      titleRu: json['titleRu']?.toString() ?? '',
      titleEn: json['titleEn']?.toString() ?? '',
      titleDe: json['titleDe']?.toString() ?? json['titleEn']?.toString() ?? '',
      targetValue: (json['targetValue'] as num?)?.toInt() ?? 1,
      rewardXp: (json['rewardXp'] as num?)?.toInt() ?? 5,
      modeId: json['modeId']?.toString(),
      minSessionItems: (json['minSessionItems'] as num?)?.toInt(),
      requirePerfect: json['requirePerfect'] == true,
    );
  }

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
  final List<Quest> personalQuests;
  final List<QuestStatus> personalStatuses;
  final Set<String> removedPersonalQuestIds;
  final DateTime lastDailyReset;
  final DateTime lastWeeklyReset;
  final bool allDailyCompletedRewarded;

  const QuestState({
    required this.dailyQuests,
    required this.dailyStatuses,
    required this.weeklyQuests,
    required this.weeklyStatuses,
    this.personalQuests = const [],
    this.personalStatuses = const [],
    this.removedPersonalQuestIds = const {},
    required this.lastDailyReset,
    required this.lastWeeklyReset,
    this.allDailyCompletedRewarded = false,
  });

  Map<String, dynamic> toJson() => {
        'dailyQuests': dailyQuests.map((q) => q.toJson()).toList(),
        'dailyStatuses': dailyStatuses.map((s) => s.toJson()).toList(),
        'weeklyQuests': weeklyQuests.map((q) => q.toJson()).toList(),
        'weeklyStatuses': weeklyStatuses.map((s) => s.toJson()).toList(),
        'personalQuests': personalQuests.map((q) => q.toJson()).toList(),
        'personalStatuses': personalStatuses.map((s) => s.toJson()).toList(),
        'removedPersonalQuestIds': removedPersonalQuestIds.toList(),
        'lastDailyReset': lastDailyReset.toIso8601String(),
        'lastWeeklyReset': lastWeeklyReset.toIso8601String(),
        'allDailyCompletedRewarded': allDailyCompletedRewarded,
      };

  factory QuestState.fromJson(Map<String, dynamic> json) {
    List<Quest> mapQuests(dynamic list) {
      if (list is! List) return [];
      return list.map((q) => Quest.fromJson(Map<String, dynamic>.from(q as Map))).toList();
    }

    List<QuestStatus> mapStatuses(dynamic list) {
      if (list is! List) return [];
      return list.map((s) => QuestStatus.fromJson(Map<String, dynamic>.from(s as Map))).toList();
    }

    final pq = mapQuests(json['personalQuests']);
    final ps = mapStatuses(json['personalStatuses']);
    final n = math.min(pq.length, ps.length);
    final removedRaw = json['removedPersonalQuestIds'];
    final removed = removedRaw is List
        ? removedRaw.map((e) => e.toString()).toSet()
        : const <String>{};
    return QuestState(
      dailyQuests: mapQuests(json['dailyQuests']),
      dailyStatuses: mapStatuses(json['dailyStatuses']),
      weeklyQuests: mapQuests(json['weeklyQuests']),
      weeklyStatuses: mapStatuses(json['weeklyStatuses']),
      personalQuests: pq.take(n).toList(),
      personalStatuses: ps.take(n).toList(),
      removedPersonalQuestIds: removed,
      lastDailyReset: DateTime.tryParse(json['lastDailyReset']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      lastWeeklyReset: DateTime.tryParse(json['lastWeeklyReset']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      allDailyCompletedRewarded: json['allDailyCompletedRewarded'] == true,
    );
  }

  static QuestState initial() => QuestState(
        dailyQuests: [],
        dailyStatuses: [],
        weeklyQuests: [],
        weeklyStatuses: [],
        personalQuests: const [],
        personalStatuses: const [],
        lastDailyReset: DateTime.fromMillisecondsSinceEpoch(0),
        lastWeeklyReset: DateTime.fromMillisecondsSinceEpoch(0),
        allDailyCompletedRewarded: false,
      );
}
