import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../app_creator.dart';

/// Free broadcast via Firestore — no Cloud Functions / Blaze plan required.
/// Online signed-in users receive a local notification; closed app won't get it.
class CreatorBroadcastService {
  CreatorBroadcastService._();
  static final CreatorBroadcastService instance = CreatorBroadcastService._();

  static const String _collection = 'creator_broadcasts';
  static const int _maxPerHour = 5;

  Future<CreatorBroadcastResult> send({
    required String title,
    required String body,
  }) async {
    if (!AppCreator.isCurrentUser) {
      return CreatorBroadcastResult.failure('Доступ только для аккаунта создателя.');
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return CreatorBroadcastResult.failure('Войдите в аккаунт.');
    }

    final trimmedTitle = title.trim();
    final trimmedBody = body.trim();
    if (trimmedTitle.isEmpty) {
      return CreatorBroadcastResult.failure('Введите заголовок.');
    }
    if (trimmedBody.isEmpty) {
      return CreatorBroadcastResult.failure('Введите текст уведомления.');
    }

    try {
      final db = FirebaseFirestore.instance;
      final now = DateTime.now().millisecondsSinceEpoch;
      final hourAgo = now - const Duration(hours: 1).inMilliseconds;

      final recent = await db
          .collection(_collection)
          .where('createdAtMs', isGreaterThan: hourAgo)
          .orderBy('createdAtMs', descending: true)
          .limit(_maxPerHour)
          .get();

      if (recent.docs.length >= _maxPerHour) {
        return CreatorBroadcastResult.failure(
          'Слишком много рассылок. Подождите около часа.',
        );
      }

      final doc = await db.collection(_collection).add({
        'title': trimmedTitle.length > 80 ? trimmedTitle.substring(0, 80) : trimmedTitle,
        'body': trimmedBody.length > 280 ? trimmedBody.substring(0, 280) : trimmedBody,
        'createdAtMs': now,
        'createdByUid': user.uid,
        'createdByEmail': user.email ?? AppCreator.creatorEmail,
      });

      return CreatorBroadcastResult.success(messageId: doc.id);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return CreatorBroadcastResult.failure(
          'Нет прав в Firestore. Задеплойте правила: firebase deploy --only firestore:rules',
        );
      }
      return CreatorBroadcastResult.failure(e.message ?? e.code);
    } catch (e) {
      return CreatorBroadcastResult.failure(e.toString());
    }
  }
}

class CreatorBroadcastResult {
  const CreatorBroadcastResult._({this.error, this.messageId});

  final String? error;
  final String? messageId;

  bool get ok => error == null;

  factory CreatorBroadcastResult.success({String? messageId}) =>
      CreatorBroadcastResult._(messageId: messageId);

  factory CreatorBroadcastResult.failure(String message) =>
      CreatorBroadcastResult._(error: message);
}
