import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../chat/global_chat_service.dart';
import '../cloud/cloud_sync_service.dart';
import '../recovered_app.dart' show AppLanguage, appLanguage, initializeFirebaseSafely;
import 'duel_auth_sheet.dart';
import 'duel_screens.dart';
import 'duel_service.dart';

String duelInviteText(Map<AppLanguage, String> map) =>
    map[appLanguage.value] ?? map[AppLanguage.ru] ?? '';

/// Maps join/accept failures to a short user-facing message.
String mapDuelJoinError(Object error) {
  if (error is StateError) {
    switch (error.message) {
      case 'room_not_found':
        return duelInviteText(const {
          AppLanguage.ru: 'Комната не найдена',
          AppLanguage.en: 'Room not found',
          AppLanguage.de: 'Raum nicht gefunden',
        });
      case 'room_full':
        return duelInviteText(const {
          AppLanguage.ru: 'Комната уже заполнена',
          AppLanguage.en: 'Room is full',
          AppLanguage.de: 'Raum ist voll',
        });
      case 'not_signed_in':
        return duelInviteText(const {
          AppLanguage.ru: 'Сначала войди в аккаунт',
          AppLanguage.en: 'Please sign in first',
          AppLanguage.de: 'Bitte zuerst anmelden',
        });
      case 'empty_code':
        return duelInviteText(const {
          AppLanguage.ru: 'Неверное приглашение',
          AppLanguage.en: 'Invalid invite',
          AppLanguage.de: 'Ungültige Einladung',
        });
      case 'network_unavailable':
        return duelInviteText(const {
          AppLanguage.ru: 'Нет сети. Проверь подключение и попробуй снова',
          AppLanguage.en: 'No connection. Check internet and try again',
          AppLanguage.de: 'Keine Verbindung. Internet prüfen und erneut versuchen',
        });
      case 'permission_denied':
        return duelInviteText(const {
          AppLanguage.ru: 'Нет доступа. Войди в аккаунт и попробуй снова',
          AppLanguage.en: 'Access denied. Sign in and try again',
          AppLanguage.de: 'Zugriff verweigert. Anmelden und erneut versuchen',
        });
    }
  }
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return mapDuelJoinError(StateError('permission_denied'));
      case 'unavailable':
      case 'deadline-exceeded':
        return mapDuelJoinError(StateError('network_unavailable'));
    }
  }

  final raw = error.toString();
  if (raw.contains('room_full')) {
    return mapDuelJoinError(StateError('room_full'));
  }
  if (raw.contains('room_not_found')) {
    return mapDuelJoinError(StateError('room_not_found'));
  }
  if (raw.contains('not_signed_in')) {
    return mapDuelJoinError(StateError('not_signed_in'));
  }
  if (raw.contains('unavailable') ||
      raw.contains('network-request-failed') ||
      raw.contains('Failed host lookup')) {
    return mapDuelJoinError(StateError('network_unavailable'));
  }

  return duelInviteText(const {
    AppLanguage.ru: 'Не удалось войти в дуэль',
    AppLanguage.en: 'Could not join duel',
    AppLanguage.de: 'Duellbeitritt fehlgeschlagen',
  });
}

/// Ensures Firebase + auth, joins the duel room, dismisses the invite, opens the lobby.
Future<void> acceptDuelInvite({
  required BuildContext context,
  required DuelInviteNotification invite,
}) async {
  final code = invite.roomId.trim();
  if (code.isEmpty) {
    await GlobalChatService.instance.dismissInvite(invite.fromUid);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mapDuelJoinError(StateError('empty_code'))),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final ready =
      CloudSyncService.instance.firebaseReady || await initializeFirebaseSafely();
  if (!ready) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mapDuelJoinError(StateError('network_unavailable'))),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  await CloudSyncService.instance.init(firebaseReady: true);

  if (!CloudSyncService.instance.isSignedIn) {
    final ok = await showDuelAuthSheet(context);
    if (!ok || !context.mounted) return;
  }

  try {
    await DuelService.instance.joinRoom(code);
    await GlobalChatService.instance.dismissInvite(invite.fromUid);
    if (!context.mounted) return;
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DuelWaitingScreen(roomId: code.toUpperCase()),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mapDuelJoinError(e)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
