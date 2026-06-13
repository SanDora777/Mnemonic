import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cloud/cloud_sync_service.dart';
import '../cloud/firebase_access.dart';
import 'smart_notification_service.dart';

/// Listens for creator broadcasts in Firestore and shows local notifications.
class CreatorBroadcastInboxService {
  CreatorBroadcastInboxService._();
  static final CreatorBroadcastInboxService instance = CreatorBroadcastInboxService._();

  static const String _kLastBroadcastId = 'creator_broadcast_last_id_v1';
  static const String _collection = 'creator_broadcasts';

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  bool _skipInitial = true;

  void start() {
    if (_sub != null) return;
    final db = firestoreOrNull();
    if (db == null) return;
    _skipInitial = true;
    _sub = db
        .collection(_collection)
        .orderBy('createdAtMs', descending: true)
        .limit(8)
        .snapshots()
        .listen(_onSnapshot, onError: (e) {
      if (kDebugMode) debugPrint('CreatorBroadcastInbox: $e');
    });
  }

  void stop() {
    unawaited(_sub?.cancel());
    _sub = null;
  }

  Future<void> _onSnapshot(QuerySnapshot<Map<String, dynamic>> snap) async {
    if (snap.docs.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    if (_skipInitial) {
      _skipInitial = false;
      await prefs.setString(_kLastBroadcastId, snap.docs.first.id);
      return;
    }

    final lastId = prefs.getString(_kLastBroadcastId);
    final fresh = snap.docChanges.where((c) => c.type == DocumentChangeType.added);

    for (final change in fresh) {
      final doc = change.doc;
      if (doc.id == lastId) continue;
      final data = doc.data();
      if (data == null) continue;
      final authorUid = data['createdByUid'] as String?;
      if (authorUid != null && authorUid == myUid) continue;

      final title = (data['title'] as String?)?.trim() ?? 'Mneem';
      final body = (data['body'] as String?)?.trim() ?? '';
      if (body.isEmpty) continue;

      await SmartNotificationService.showCreatorBroadcast(title: title, body: body);
      await prefs.setString(_kLastBroadcastId, doc.id);
      break;
    }
  }

  /// Restart when user signs in/out.
  void bindAuth() {
    CloudSyncService.instance.user.addListener(_authChanged);
    _authChanged();
  }

  void unbindAuth() {
    CloudSyncService.instance.user.removeListener(_authChanged);
    stop();
  }

  void _authChanged() {
    final signedIn = CloudSyncService.instance.isSignedIn;
    if (signedIn) {
      start();
    } else {
      stop();
    }
  }
}
