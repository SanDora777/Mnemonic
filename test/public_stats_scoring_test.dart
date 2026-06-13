import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/public_stats_scoring.dart';
import 'package:flutter_application_1/training_record_rules.dart';

void main() {
  group('TrainingRecordRules timed bests', () {
    test('73% item accuracy still qualifies for best1m when digit score is high', () {
      const record = SessionRecord(
        displayScore: 54,
        memMs: 60000,
        totalItems: 37,
        correctItems: 27,
        accuracyPct: 73.0,
      );
      expect(record.qualifiesForBest1m, isTrue);
      expect(record.qualifiesForMax, isFalse);
    });

    test('lower digit score in same window loses to higher partial recall', () {
      final stats = PublicStatsScoring.buildModeStats(
        sessions: [
          const SessionRecord(
            displayScore: 38,
            memMs: 60000,
            totalItems: 20,
            correctItems: 19,
            accuracyPct: 95.0,
          ),
          const SessionRecord(
            displayScore: 54,
            memMs: 60000,
            totalItems: 37,
            correctItems: 27,
            accuracyPct: 73.0,
          ),
        ],
      );
      expect(stats['best1m'], 54);
    });
  });
}
