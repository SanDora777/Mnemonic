import 'package:flutter/foundation.dart';

@immutable
class UserProgress {
  final int xp;
  final int level;
  final int currentLevelXp;
  final int xpToNextLevel;
  final int streak;
  final DateTime? lastActiveDate;
  final DateTime? lastLoginDate;

  const UserProgress({
    required this.xp,
    required this.level,
    required this.currentLevelXp,
    required this.xpToNextLevel,
    required this.streak,
    required this.lastActiveDate,
    required this.lastLoginDate,
  });

  factory UserProgress.initial() => const UserProgress(
        xp: 0,
        level: 1,
        currentLevelXp: 0,
        xpToNextLevel: 50,
        streak: 0,
        lastActiveDate: null,
        lastLoginDate: null,
      );

  UserProgress copyWith({
    int? xp,
    int? level,
    int? currentLevelXp,
    int? xpToNextLevel,
    int? streak,
    DateTime? lastActiveDate,
    DateTime? lastLoginDate,
  }) {
    return UserProgress(
      xp: xp ?? this.xp,
      level: level ?? this.level,
      currentLevelXp: currentLevelXp ?? this.currentLevelXp,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      streak: streak ?? this.streak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
    );
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

