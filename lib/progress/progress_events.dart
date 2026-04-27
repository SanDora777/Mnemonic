import 'package:flutter/foundation.dart';

@immutable
sealed class ProgressEvent {
  const ProgressEvent();
}

class XpGained extends ProgressEvent {
  final int amount;
  const XpGained(this.amount);
}

class LevelUp extends ProgressEvent {
  final int newLevel;
  const LevelUp(this.newLevel);
}

class QuestCompletedEvent extends ProgressEvent {
  final String titleRu;
  final String titleEn;
  final String titleDe;
  final int xpReward;
  const QuestCompletedEvent({
    required this.titleRu,
    required this.titleEn,
    required this.titleDe,
    required this.xpReward,
  });
}

