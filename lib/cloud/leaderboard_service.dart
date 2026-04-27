import 'package:cloud_firestore/cloud_firestore.dart';

import 'cloud_sync_service.dart';

class LeaderboardEntry {
  final String uid;
  final String displayName;
  final int points;

  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.points,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> raw) {
    return LeaderboardEntry(
      uid: (raw['uid'] ?? '').toString(),
      displayName: (raw['displayName'] ?? 'User').toString(),
      points: (raw['points'] as num?)?.toInt() ?? 0,
    );
  }
}

class LeaderboardService {
  LeaderboardService._();
  static final LeaderboardService instance = LeaderboardService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<void> addPoints(int points) async {
    if (points <= 0) return;
    if (!CloudSyncService.instance.firebaseReady) return;
    final user = CloudSyncService.instance.user.value;
    if (user == null) return;

    final now = DateTime.now();
    final dayKey = _dayKey(now);
    final weekKey = _weekKey(now);
    final monthKey = _monthKey(now);
    final displayName = CloudSyncService.instance.accountTitle();

    await _incrementBoard(
      board: 'daily',
      key: dayKey,
      uid: user.uid,
      displayName: displayName,
      points: points,
    );
    await _incrementBoard(
      board: 'weekly',
      key: weekKey,
      uid: user.uid,
      displayName: displayName,
      points: points,
    );
    await _incrementBoard(
      board: 'monthly',
      key: monthKey,
      uid: user.uid,
      displayName: displayName,
      points: points,
    );
    await _incrementBoard(
      board: 'alltime',
      key: 'global',
      uid: user.uid,
      displayName: displayName,
      points: points,
    );
  }

  Stream<List<LeaderboardEntry>> watchDailyTop({int limit = 10}) {
    final key = _dayKey(DateTime.now());
    return _watchBoard(board: 'daily', key: key, limit: limit);
  }

  Stream<List<LeaderboardEntry>> watchMonthlyTop({int limit = 10}) {
    final key = _monthKey(DateTime.now());
    return _watchBoard(board: 'monthly', key: key, limit: limit);
  }

  Stream<List<LeaderboardEntry>> watchWeeklyTop({int limit = 10}) {
    final key = _weekKey(DateTime.now());
    return _watchBoard(board: 'weekly', key: key, limit: limit);
  }

  Stream<List<LeaderboardEntry>> watchAllTimeTop({int limit = 10}) {
    return _watchBoard(board: 'alltime', key: 'global', limit: limit);
  }

  Future<LeaderboardEntry?> fetchPreviousDayChampion() async {
    if (!CloudSyncService.instance.firebaseReady) return null;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final key = _dayKey(yesterday);
    final snap = await _db
        .collection('leaderboards')
        .doc('daily')
        .collection(key)
        .orderBy('points', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return LeaderboardEntry.fromMap(snap.docs.first.data());
  }

  Stream<List<LeaderboardEntry>> _watchBoard({
    required String board,
    required String key,
    required int limit,
  }) {
    if (!CloudSyncService.instance.firebaseReady) {
      return const Stream<List<LeaderboardEntry>>.empty();
    }
    return _db
        .collection('leaderboards')
        .doc(board)
        .collection(key)
        .orderBy('points', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => LeaderboardEntry.fromMap(d.data()))
              .toList(growable: false),
        );
  }

  Future<void> _incrementBoard({
    required String board,
    required String key,
    required String uid,
    required String displayName,
    required int points,
  }) async {
    final ref = _db.collection('leaderboards').doc(board).collection(key).doc(uid);
    await ref.set({
      'uid': uid,
      'displayName': displayName,
      'points': FieldValue.increment(points),
      'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  String _dayKey(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}$m$d';
  }

  String _monthKey(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    return '${dt.year}$m';
  }

  String _weekKey(DateTime dt) {
    final monday = DateTime(dt.year, dt.month, dt.day).subtract(Duration(days: dt.weekday - 1));
    final yearStart = DateTime(monday.year, 1, 1);
    final week = ((monday.difference(yearStart).inDays) / 7).floor() + 1;
    return '${monday.year}W${week.toString().padLeft(2, '0')}';
  }
}
