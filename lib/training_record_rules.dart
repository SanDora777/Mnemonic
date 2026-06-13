/// Rules for which training sessions count as personal records.
///
/// Prevents trivial short runs (e.g. 4 items in 2 seconds) from beating
/// serious attempts (e.g. 50 items in two minutes).
class TrainingRecordRules {
  TrainingRecordRules._();

  /// Minimum memorization phase length (filters mis-taps and instant quits).
  static const int minMemorizationMs = 8000;

  /// Minimum display score (digits / bits / items) for any record.
  static const int minDisplayScore = 5;

  /// Sessions under 15s need a higher score to count.
  static const int minDisplayScoreShortBurst = 12;
  static const int shortBurstMemMs = 15000;

  /// Minimum accuracy (0–100) to count toward records.
  static const double minAccuracyPercent = 80.0;

  /// Best-in-1-minute: meaningful use of the minute window.
  static const int best1mMinMemMs = 20000;
  static const int best1mMaxMemMs = 60000;

  /// Best-in-5-minutes: at least 45s memorization, up to 5 minutes.
  static const int best5mMinMemMs = 45000;
  static const int best5mMaxMemMs = 300000;
  static const int timedWindowUpperBoundGraceMs = 250;

  /// Clamps tiny timer drift above timed windows (e.g. 60001 -> 60000).
  static int normalizeTimedWindowMemMs(int memMs) {
    if (memMs <= 0) return 0;
    if (memMs > best1mMaxMemMs &&
        memMs <= best1mMaxMemMs + timedWindowUpperBoundGraceMs) {
      return best1mMaxMemMs;
    }
    if (memMs > best5mMaxMemMs &&
        memMs <= best5mMaxMemMs + timedWindowUpperBoundGraceMs) {
      return best5mMaxMemMs;
    }
    return memMs;
  }

  static double accuracyPercent({
    required int correctItems,
    required int totalItems,
    double? storedPercent,
  }) {
    if (storedPercent != null && storedPercent >= 0)
      return storedPercent.clamp(0, 100);
    if (totalItems <= 0) return 0;
    return (correctItems / totalItems) * 100.0;
  }

  /// Shared anti-spam guards (duration / minimum score). Does not check accuracy.
  static bool meetsAttemptBaseline({
    required int displayScore,
    required int correctItems,
    required int totalItems,
    required int memMs,
  }) {
    if (totalItems <= 0 ||
        correctItems <= 0 ||
        displayScore < minDisplayScore) {
      return false;
    }
    if (memMs > 0 && memMs < minMemorizationMs) return false;
    if (memMs > 0 &&
        memMs < shortBurstMemMs &&
        displayScore < minDisplayScoreShortBurst) {
      return false;
    }
    return true;
  }

  static bool qualifiesForMaxRecord({
    required int displayScore,
    required int correctItems,
    required int totalItems,
    required double accuracyPct,
    required int memMs,
  }) {
    if (!meetsAttemptBaseline(
      displayScore: displayScore,
      correctItems: correctItems,
      totalItems: totalItems,
      memMs: memMs,
    )) {
      return false;
    }
    if (accuracyPct < minAccuracyPercent) return false;
    return true;
  }

  /// Timed bests use [displayScore] (correct digits/bits only), so a separate
  /// accuracy gate would hide real 1-minute peaks (e.g. 54 digits at 73% items).
  static bool qualifiesForBest1m({
    required int displayScore,
    required int correctItems,
    required int totalItems,
    required double accuracyPct,
    required int memMs,
  }) {
    if (!meetsAttemptBaseline(
      displayScore: displayScore,
      correctItems: correctItems,
      totalItems: totalItems,
      memMs: memMs,
    )) {
      return false;
    }
    if (memMs < best1mMinMemMs ||
        memMs > best1mMaxMemMs + timedWindowUpperBoundGraceMs) {
      return false;
    }
    return true;
  }

  static bool qualifiesForBest5m({
    required int displayScore,
    required int correctItems,
    required int totalItems,
    required double accuracyPct,
    required int memMs,
  }) {
    if (!meetsAttemptBaseline(
      displayScore: displayScore,
      correctItems: correctItems,
      totalItems: totalItems,
      memMs: memMs,
    )) {
      return false;
    }
    if (memMs < best5mMinMemMs ||
        memMs > best5mMaxMemMs + timedWindowUpperBoundGraceMs) {
      return false;
    }
    return true;
  }

  /// Returns >0 if [a] is a better record than [b], <0 if worse, 0 if tie.
  static int compareRecords({
    required int scoreA,
    required double accuracyA,
    required int memMsA,
    required int scoreB,
    required double accuracyB,
    required int memMsB,
  }) {
    if (scoreA != scoreB) return scoreA.compareTo(scoreB);
    final accCmp = accuracyA.compareTo(accuracyB);
    if (accCmp != 0) return accCmp;
    return memMsA.compareTo(memMsB);
  }
}
