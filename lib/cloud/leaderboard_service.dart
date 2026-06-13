import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cloud_sync_service.dart';

class LeaderboardEntry {
  final String uid;
  final String displayName;
  final int points;
  final String photoUrl;
  final String photoData;
  final int? lastSeenMs;

  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.points,
    this.photoUrl = '',
    this.photoData = '',
    this.lastSeenMs,
  });

  bool get hasAvatar =>
      photoData.trim().isNotEmpty ||
      photoUrl.trim().startsWith('http://') ||
      photoUrl.trim().startsWith('https://');

  factory LeaderboardEntry.fromMap(Map<String, dynamic> raw) {
    return LeaderboardEntry(
      uid: (raw['uid'] ?? '').toString(),
      displayName: (raw['displayName'] ?? 'User').toString(),
      points: (raw['points'] as num?)?.toInt() ?? 0,
      photoUrl: (raw['photoUrl'] ?? '').toString(),
      photoData: (raw['photoData'] ?? '').toString(),
      lastSeenMs: (raw['lastSeenMs'] as num?)?.toInt() ??
          (raw['updatedAtMs'] as num?)?.toInt(),
    );
  }
}

class LeaderboardService {
  LeaderboardService._();
  static final LeaderboardService instance = LeaderboardService._();

  static const String _kPendingPointsKey = 'leaderboard_pending_points_v1';

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  Timer? _syncTimer;
  Future<void> _syncQueue = Future<void>.value();

  bool _canUseFirestore() {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void startPendingPointsSync() {
    _syncTimer ??= Timer.periodic(
      const Duration(seconds: 30),
      (_) => syncPendingPoints(),
    );
    unawaited(syncPendingPoints());
  }

  void dispose() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> addPoints(int points) async {
    if (points <= 0) return;
    await _enqueuePoints(points, DateTime.now());
    unawaited(syncPendingPoints());
  }

  Future<void> syncPendingPoints() {
    final op = _syncQueue.then((_) => _syncPendingPointsInternal());
    _syncQueue = op.catchError((_) {});
    return op;
  }

  Future<void> _syncPendingPointsInternal() async {
    if (!_canUseFirestore()) return;
    if (!CloudSyncService.instance.firebaseReady) return;
    final user = CloudSyncService.instance.user.value;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final pending = _readPendingPoints(prefs);
    if (pending.isEmpty) return;
    final batchItems = pending.take(100).toList(growable: false);

    final displayName = CloudSyncService.instance.accountTitle();
    final cloud = CloudSyncService.instance;
    final photoPayload = _leaderboardPhotoPayload(cloud, user);
    final publicStats = cloud.shareResults.value
        ? await cloud.buildLocalPublicStatsSnapshot()
        : const <String, dynamic>{};
    final batch = _db.batch();
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    for (final item in batchItems) {
      final earnedAt = item.earnedAt;
      final dayKey = _dayKey(earnedAt);
      final weekKey = _weekKey(earnedAt);
      final monthKey = _monthKey(earnedAt);
      _incrementBoardInBatch(
        batch: batch,
        board: 'daily',
        key: dayKey,
        uid: user.uid,
        displayName: displayName,
        photoUrl: photoPayload.photoUrl,
        photoData: photoPayload.photoData,
        aboutMe: cloud.aboutMe.value,
        shareResults: cloud.shareResults.value,
        publicStats: publicStats,
        points: item.points,
        updatedAtMs: nowMs,
      );
      _incrementBoardInBatch(
        batch: batch,
        board: 'weekly',
        key: weekKey,
        uid: user.uid,
        displayName: displayName,
        photoUrl: photoPayload.photoUrl,
        photoData: photoPayload.photoData,
        aboutMe: cloud.aboutMe.value,
        shareResults: cloud.shareResults.value,
        publicStats: publicStats,
        points: item.points,
        updatedAtMs: nowMs,
      );
      _incrementBoardInBatch(
        batch: batch,
        board: 'monthly',
        key: monthKey,
        uid: user.uid,
        displayName: displayName,
        photoUrl: photoPayload.photoUrl,
        photoData: photoPayload.photoData,
        aboutMe: cloud.aboutMe.value,
        shareResults: cloud.shareResults.value,
        publicStats: publicStats,
        points: item.points,
        updatedAtMs: nowMs,
      );
      _incrementBoardInBatch(
        batch: batch,
        board: 'alltime',
        key: 'global',
        uid: user.uid,
        displayName: displayName,
        photoUrl: photoPayload.photoUrl,
        photoData: photoPayload.photoData,
        aboutMe: cloud.aboutMe.value,
        shareResults: cloud.shareResults.value,
        publicStats: publicStats,
        points: item.points,
        updatedAtMs: nowMs,
      );
    }

    try {
      await batch.commit();
      if (batchItems.length == pending.length) {
        await prefs.remove(_kPendingPointsKey);
      } else {
        final remaining = pending.skip(batchItems.length);
        await prefs.setStringList(
          _kPendingPointsKey,
          remaining.map((e) => jsonEncode(e.toJson())).toList(growable: false),
        );
      }
    } catch (e) {
      CloudSyncService.instance.lastError.value = e.toString();
    }
  }

  Future<void> _enqueuePoints(int points, DateTime earnedAt) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = _readPendingPoints(prefs);
    pending.add(_PendingLeaderboardPoints(
      id: '${earnedAt.microsecondsSinceEpoch}_${pending.length}',
      points: points,
      earnedAt: earnedAt,
    ));
    await prefs.setStringList(
      _kPendingPointsKey,
      pending.map((e) => jsonEncode(e.toJson())).toList(growable: false),
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
    if (!_canUseFirestore()) return null;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final key = _dayKey(yesterday);
    try {
      final snap = await _db
          .collection('leaderboards')
          .doc('daily')
          .collection(key)
          .orderBy('points', descending: true)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 8));
      if (snap.docs.isEmpty) return null;
      return LeaderboardEntry.fromMap(snap.docs.first.data());
    } catch (_) {
      return null;
    }
  }

  Stream<List<LeaderboardEntry>> _watchBoard({
    required String board,
    required String key,
    required int limit,
  }) {
    if (!_canUseFirestore()) {
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

  _LeaderboardPhotoPayload _leaderboardPhotoPayload(
    CloudSyncService cloud,
    User user,
  ) {
    final bytes = cloud.photoBytes.value;
    if (bytes != null && bytes.isNotEmpty) {
      final b64 = base64Encode(bytes);
      if (b64.length <= 280000) {
        return _LeaderboardPhotoPayload(photoUrl: '', photoData: b64);
      }
    }
    final url = (cloud.photoUrl.value ?? user.photoURL ?? '').trim();
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return _LeaderboardPhotoPayload(photoUrl: url, photoData: '');
    }
    if (url.startsWith('data:')) {
      final comma = url.indexOf(',');
      if (comma > 0 && comma < url.length - 1) {
        final payload = url.substring(comma + 1);
        if (payload.length <= 280000) {
          return _LeaderboardPhotoPayload(photoUrl: '', photoData: payload);
        }
      }
    }
    return const _LeaderboardPhotoPayload(photoUrl: '', photoData: '');
  }

  void _incrementBoardInBatch({
    required WriteBatch batch,
    required String board,
    required String key,
    required String uid,
    required String displayName,
    required String photoUrl,
    required String photoData,
    required String aboutMe,
    required bool shareResults,
    required Map<String, dynamic> publicStats,
    required int points,
    required int updatedAtMs,
  }) {
    final ref = _db.collection('leaderboards').doc(board).collection(key).doc(uid);
    batch.set(ref, {
      'uid': uid,
      'displayName': displayName,
      'photoUrl': photoUrl,
      if (photoData.isNotEmpty) 'photoData': photoData,
      'aboutMe': aboutMe,
      'shareResults': shareResults,
      if (shareResults) 'publicStats': publicStats,
      if (!shareResults) 'publicStats': FieldValue.delete(),
      'points': FieldValue.increment(points),
      'updatedAtMs': updatedAtMs,
      'lastSeenMs': updatedAtMs,
    }, SetOptions(merge: true));
  }

  List<_PendingLeaderboardPoints> _readPendingPoints(SharedPreferences prefs) {
    final raw = prefs.getStringList(_kPendingPointsKey) ?? const <String>[];
    final pending = <_PendingLeaderboardPoints>[];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        final parsed = _PendingLeaderboardPoints.fromJson(decoded);
        if (parsed.points > 0) pending.add(parsed);
      } catch (_) {}
    }
    return pending;
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

class _LeaderboardPhotoPayload {
  final String photoUrl;
  final String photoData;

  const _LeaderboardPhotoPayload({
    required this.photoUrl,
    required this.photoData,
  });
}

class _PendingLeaderboardPoints {
  final String id;
  final int points;
  final DateTime earnedAt;

  const _PendingLeaderboardPoints({
    required this.id,
    required this.points,
    required this.earnedAt,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'points': points,
        'earnedAtMs': earnedAt.millisecondsSinceEpoch,
      };

  factory _PendingLeaderboardPoints.fromJson(Map<String, dynamic> raw) {
    return _PendingLeaderboardPoints(
      id: (raw['id'] ?? '').toString(),
      points: (raw['points'] as num?)?.toInt() ?? 0,
      earnedAt: DateTime.fromMillisecondsSinceEpoch(
        (raw['earnedAtMs'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
