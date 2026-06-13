import 'package:cloud_firestore/cloud_firestore.dart';

import 'cloud/cloud_sync_service.dart';

/// App creator account — moderation and special chat features.
class AppCreator {
  AppCreator._();

  static const String creatorEmail = 'nbs27933@gmail.com';

  static bool get isCurrentUser {
    final email = CloudSyncService.instance.user.value?.email?.trim().toLowerCase();
    return email == creatorEmail;
  }

  static Future<void> syncProfileBadgeIfNeeded() async {
    if (!isCurrentUser || !CloudSyncService.instance.isSignedIn) return;
    final uid = CloudSyncService.instance.user.value?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        <String, dynamic>{
          'isCreator': true,
          'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }
}
