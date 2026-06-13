import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../app_creator.dart';
import '../cloud/cloud_sync_service.dart';
import '../cloud/firebase_access.dart';
import '../duels/duel_service.dart';

enum GlobalChatMessageType { text, image }

class GlobalChatMessage {
  final String id;
  final String uid;
  final String name;
  final String text;
  final int sentAtMs;
  final int? editedAtMs;
  final GlobalChatMessageType type;
  final String imageData;
  final String imageMime;
  final bool isCreator;

  const GlobalChatMessage({
    required this.id,
    required this.uid,
    required this.name,
    required this.text,
    required this.sentAtMs,
    this.editedAtMs,
    this.type = GlobalChatMessageType.text,
    this.imageData = '',
    this.imageMime = '',
    this.isCreator = false,
  });

  bool get isEdited => editedAtMs != null && editedAtMs! > sentAtMs;
  bool get hasImage =>
      type == GlobalChatMessageType.image && imageData.trim().isNotEmpty;

  Uint8List? get imageBytes {
    if (!hasImage) return null;
    try {
      return base64Decode(imageData);
    } catch (_) {
      return null;
    }
  }

  factory GlobalChatMessage.fromMap(String id, Map<String, dynamic> raw) {
    final typeRaw = (raw['type'] ?? 'text').toString();
    return GlobalChatMessage(
      id: id,
      uid: (raw['uid'] ?? '').toString(),
      name: (raw['name'] ?? '').toString(),
      text: (raw['text'] ?? '').toString(),
      sentAtMs: (raw['sentAtMs'] as num?)?.toInt() ?? 0,
      editedAtMs: (raw['editedAtMs'] as num?)?.toInt(),
      type: typeRaw == 'image'
          ? GlobalChatMessageType.image
          : GlobalChatMessageType.text,
      imageData: (raw['imageData'] ?? '').toString(),
      imageMime: (raw['imageMime'] ?? 'image/jpeg').toString(),
      isCreator: raw['isCreator'] == true,
    );
  }
}

class ChatMuteStatus {
  final int untilMs;
  final String mutedByName;

  const ChatMuteStatus({required this.untilMs, this.mutedByName = ''});

  bool get isActive => DateTime.now().millisecondsSinceEpoch < untilMs;

  Duration get remaining {
    final left = untilMs - DateTime.now().millisecondsSinceEpoch;
    return Duration(milliseconds: left > 0 ? left : 0);
  }
}

class DuelInviteNotification {
  final String fromUid;
  final String fromName;
  final String roomId;
  final int createdAtMs;

  const DuelInviteNotification({
    required this.fromUid,
    required this.fromName,
    required this.roomId,
    required this.createdAtMs,
  });

  factory DuelInviteNotification.fromMap(String id, Map<String, dynamic> raw) {
    return DuelInviteNotification(
      fromUid: (raw['fromUid'] ?? id).toString(),
      fromName: (raw['fromName'] ?? 'Player').toString(),
      roomId: (raw['roomId'] ?? '').toString(),
      createdAtMs: (raw['createdAtMs'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Community chat cleared daily at 00:00 Europe/Berlin (CET/CEST).
class GlobalChatService {
  GlobalChatService._();
  static final GlobalChatService instance = GlobalChatService._();

  static const int kMaxMessageLength = 280;
  static const int kMaxChatImageBytes = 380000;
  static const String _kDaysCollection = 'global_chat_days';
  static const String _kMessagesSub = 'messages';
  static const String _kMutesCollection = 'global_chat_mutes';

  static bool _tzReady = false;

  FirebaseFirestore? get _db => firestoreOrNull();

  FirebaseFirestore _requireDb() {
    final db = _db;
    if (db == null) throw StateError('firebase_not_ready');
    return db;
  }

  bool get isCreator => AppCreator.isCurrentUser;

  static void _ensureTz() {
    if (_tzReady) return;
    tz_data.initializeTimeZones();
    _tzReady = true;
  }

  String europeDayKey([DateTime? utcNow]) {
    _ensureTz();
    final loc = tz.getLocation('Europe/Berlin');
    final europeNow = utcNow == null
        ? tz.TZDateTime.now(loc)
        : tz.TZDateTime.from(utcNow.toUtc(), loc);
    final y = europeNow.year;
    final m = europeNow.month.toString().padLeft(2, '0');
    final d = europeNow.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String? get _currentUid => CloudSyncService.instance.user.value?.uid;

  String _resolveDisplayName() {
    final cloud = CloudSyncService.instance;
    final cached = cloud.displayName.value;
    if (cached != null && cached.trim().isNotEmpty) return cached.trim();
    final fbName = cloud.user.value?.displayName;
    if (fbName != null && fbName.trim().isNotEmpty) return fbName.trim();
    final email = cloud.user.value?.email;
    if (email != null && email.contains('@')) return email.split('@').first;
    return 'Player';
  }

  CollectionReference<Map<String, dynamic>> _messagesRef(String dayKey) {
    return _requireDb()
        .collection(_kDaysCollection)
        .doc(dayKey)
        .collection(_kMessagesSub);
  }

  static String clipText(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.length > kMaxMessageLength
        ? trimmed.substring(0, kMaxMessageLength)
        : trimmed;
  }

  static bool looksLikeEmbeddedMedia(String text) {
    if (AppCreator.isCurrentUser) return false;
    final lower = text.toLowerCase();
    if (lower.contains('data:image') || lower.contains('data:video')) return true;
    final mediaUrl = RegExp(
      r'https?://\S+\.(gif|jpe?g|png|webp|bmp|svg|mp4|webm|mov)(\?\S*)?',
      caseSensitive: false,
    );
    return mediaUrl.hasMatch(lower);
  }

  Future<void> _ensureNotMuted() async {
    final status = await fetchMyMuteStatus();
    if (status != null && status.isActive) {
      throw StateError('muted');
    }
  }

  Stream<ChatMuteStatus?> watchMyMuteStatus() {
    final uid = _currentUid;
    final db = _db;
    if (uid == null || db == null) return const Stream<ChatMuteStatus?>.empty();
    return db.collection(_kMutesCollection).doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      final until = (data['untilMs'] as num?)?.toInt() ?? 0;
      if (until <= DateTime.now().millisecondsSinceEpoch) return null;
      return ChatMuteStatus(
        untilMs: until,
        mutedByName: (data['mutedByName'] ?? '').toString(),
      );
    });
  }

  Future<ChatMuteStatus?> fetchMyMuteStatus() async {
    final uid = _currentUid;
    final db = _db;
    if (uid == null || db == null) return null;
    final snap = await db.collection(_kMutesCollection).doc(uid).get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    final until = (data['untilMs'] as num?)?.toInt() ?? 0;
    if (until <= DateTime.now().millisecondsSinceEpoch) return null;
    return ChatMuteStatus(
      untilMs: until,
      mutedByName: (data['mutedByName'] ?? '').toString(),
    );
  }

  Stream<List<GlobalChatMessage>> watchMessages({int limit = 120}) {
    if (_db == null) return const Stream<List<GlobalChatMessage>>.empty();
    final dayKey = europeDayKey();
    return _messagesRef(dayKey)
        .orderBy('sentAtMs', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final out = <GlobalChatMessage>[];
      for (final d in snap.docs) {
        out.add(GlobalChatMessage.fromMap(d.id, d.data()));
      }
      out.sort((a, b) => a.sentAtMs.compareTo(b.sentAtMs));
      return out;
    });
  }

  Future<void> sendMessage(String text) async {
    final uid = _currentUid;
    if (uid == null) throw StateError('not_signed_in');
    await _ensureNotMuted();
    final clipped = clipText(text);
    if (clipped.isEmpty) return;
    if (looksLikeEmbeddedMedia(clipped)) throw StateError('media_not_allowed');

    await _messagesRef(europeDayKey()).add(<String, dynamic>{
      'uid': uid,
      'name': _resolveDisplayName(),
      'text': clipped,
      'type': 'text',
      'sentAtMs': DateTime.now().millisecondsSinceEpoch,
      if (isCreator) 'isCreator': true,
    });
  }

  Future<void> sendImageMessage({
    required Uint8List bytes,
    required String mime,
    String caption = '',
  }) async {
    if (!isCreator) throw StateError('forbidden');
    final uid = _currentUid;
    if (uid == null) throw StateError('not_signed_in');
    await _ensureNotMuted();
    if (bytes.isEmpty) throw StateError('empty');
    if (bytes.lengthInBytes > kMaxChatImageBytes) throw StateError('too_large');

    final clippedCaption = clipText(caption);
    final b64 = base64Encode(bytes);

    await _messagesRef(europeDayKey()).add(<String, dynamic>{
      'uid': uid,
      'name': _resolveDisplayName(),
      'text': clippedCaption,
      'type': 'image',
      'imageData': b64,
      'imageMime': mime,
      'sentAtMs': DateTime.now().millisecondsSinceEpoch,
      'isCreator': true,
    });
  }

  Future<void> editMessage({
    required String messageId,
    required String text,
  }) async {
    final uid = _currentUid;
    if (uid == null) throw StateError('not_signed_in');
    final clipped = clipText(text);
    if (clipped.isEmpty) throw StateError('empty');
    if (looksLikeEmbeddedMedia(clipped)) throw StateError('media_not_allowed');

    final ref = _messagesRef(europeDayKey()).doc(messageId);
    final snap = await ref.get();
    if (!snap.exists) throw StateError('not_found');
    final data = snap.data();
    if (data == null || data['uid'] != uid) throw StateError('forbidden');
    if ((data['type'] ?? 'text').toString() == 'image') {
      throw StateError('image_not_editable');
    }

    await ref.update(<String, dynamic>{
      'text': clipped,
      'editedAtMs': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> deleteMessage(String messageId, {String? authorUid}) async {
    final uid = _currentUid;
    if (uid == null) throw StateError('not_signed_in');

    final ref = _messagesRef(europeDayKey()).doc(messageId);
    final snap = await ref.get();
    if (!snap.exists) throw StateError('not_found');
    final data = snap.data();
    if (data == null) throw StateError('not_found');

    final owner = (data['uid'] ?? '').toString();
    if (owner != uid && !isCreator) throw StateError('forbidden');
    if (authorUid != null && owner != authorUid && !isCreator) {
      throw StateError('forbidden');
    }
    await ref.delete();
  }

  Future<void> muteUser({
    required String targetUid,
    required Duration duration,
  }) async {
    if (!isCreator) throw StateError('forbidden');
    if (targetUid == _currentUid) throw StateError('self_mute');
    final untilMs = DateTime.now().add(duration).millisecondsSinceEpoch;
    await _requireDb().collection(_kMutesCollection).doc(targetUid).set(<String, dynamic>{
      'untilMs': untilMs,
      'mutedByUid': _currentUid,
      'mutedByName': _resolveDisplayName(),
      'createdAtMs': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> unmuteUser(String targetUid) async {
    if (!isCreator) throw StateError('forbidden');
    await _requireDb().collection(_kMutesCollection).doc(targetUid).delete();
  }

  Future<DuelRoom> inviteToDuel({
    required String targetUid,
    required String targetName,
  }) async {
    final me = _currentUid;
    if (me == null) throw StateError('not_signed_in');
    if (targetUid == me) throw StateError('self_invite');

    final room = await DuelService.instance.createRoom();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _requireDb()
        .collection('users')
        .doc(targetUid)
        .collection('duel_invites')
        .doc(me)
        .set(<String, dynamic>{
      'fromUid': me,
      'fromName': _resolveDisplayName(),
      'roomId': room.roomId,
      'createdAtMs': now,
    });
    return room;
  }

  Stream<List<DuelInviteNotification>> watchIncomingInvites() {
    final uid = _currentUid;
    final db = _db;
    if (uid == null || db == null) {
      return const Stream<List<DuelInviteNotification>>.empty();
    }

    return db
        .collection('users')
        .doc(uid)
        .collection('duel_invites')
        .orderBy('createdAtMs', descending: true)
        .limit(8)
        .snapshots()
        .map((snap) {
      final out = <DuelInviteNotification>[];
      for (final d in snap.docs) {
        out.add(DuelInviteNotification.fromMap(d.id, d.data()));
      }
      return out;
    });
  }

  Future<void> dismissInvite(String fromUid) async {
    final uid = _currentUid;
    if (uid == null) return;
    final db = _db;
    if (db == null) return;
    await db
        .collection('users')
        .doc(uid)
        .collection('duel_invites')
        .doc(fromUid)
        .delete();
  }
}
