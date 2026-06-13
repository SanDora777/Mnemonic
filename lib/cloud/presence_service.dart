import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'cloud_sync_service.dart';
import 'firebase_access.dart';

/// Lightweight online presence via `users/{uid}.lastSeenMs`.
class PresenceService {
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  static const int onlineThresholdMs = 5 * 60 * 1000;
  static const Duration heartbeatInterval = Duration(seconds: 45);

  Timer? _heartbeatTimer;
  int _watchers = 0;

  FirebaseFirestore? get _db => firestoreOrNull();

  bool _canUseFirestore() =>
      isFirebaseAppInitialized() && CloudSyncService.instance.firebaseReady;

  bool isOnline(int? lastSeenMs) {
    if (lastSeenMs == null || lastSeenMs <= 0) return false;
    return DateTime.now().millisecondsSinceEpoch - lastSeenMs <= onlineThresholdMs;
  }

  void startHeartbeat() {
    _watchers++;
    if (_watchers > 1) return;
    _heartbeatTimer?.cancel();
    unawaited(_ping());
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) => _ping());
  }

  void stopHeartbeat() {
    if (_watchers <= 0) return;
    _watchers--;
    if (_watchers > 0) return;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _ping() async {
    if (!_canUseFirestore()) return;
    final db = _db;
    if (db == null) return;
    final uid = CloudSyncService.instance.user.value?.uid;
    if (uid == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      await db.collection('users').doc(uid).set(
        {'lastSeenMs': now},
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  Future<Map<String, int>> fetchLastSeenMs(Iterable<String> uids) async {
    if (!_canUseFirestore()) return const {};
    final db = _db;
    if (db == null) return const {};
    final unique = uids.where((u) => u.isNotEmpty && u != '-').toSet();
    if (unique.isEmpty) return const {};

    final out = <String, int>{};
    final list = unique.toList();
    for (var i = 0; i < list.length; i += 30) {
      final chunk = list.skip(i).take(30).toList();
      final snaps = await Future.wait(
        chunk.map((uid) => db.collection('users').doc(uid).get()),
      );
      for (final snap in snaps) {
        if (!snap.exists) continue;
        final ms = (snap.data()?['lastSeenMs'] as num?)?.toInt();
        if (ms != null && ms > 0) out[snap.id] = ms;
      }
    }
    return out;
  }
}
