import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_creator.dart';
import '../cloud/cloud_sync_service.dart';
import '../cloud/firebase_access.dart';

class NewsPost {
  final String id;
  final String title;
  final String body;
  final int publishedAtMs;
  final String authorUid;
  final String authorName;
  final String imageData;
  final String imageMime;

  const NewsPost({
    required this.id,
    required this.title,
    required this.body,
    required this.publishedAtMs,
    required this.authorUid,
    this.authorName = '',
    this.imageData = '',
    this.imageMime = 'image/jpeg',
  });

  bool get hasImage => imageData.trim().isNotEmpty;

  Uint8List? get imageBytes {
    if (!hasImage) return null;
    try {
      return base64Decode(imageData);
    } catch (_) {
      return null;
    }
  }

  factory NewsPost.fromMap(String id, Map<String, dynamic> raw) {
    return NewsPost(
      id: id,
      title: (raw['title'] ?? '').toString(),
      body: (raw['body'] ?? '').toString(),
      publishedAtMs: (raw['publishedAtMs'] as num?)?.toInt() ?? 0,
      authorUid: (raw['authorUid'] ?? '').toString(),
      authorName: (raw['authorName'] ?? '').toString(),
      imageData: (raw['imageData'] ?? '').toString(),
      imageMime: (raw['imageMime'] ?? 'image/jpeg').toString(),
    );
  }
}

/// Community news feed — create/update/delete only for [AppCreator].
class NewsService {
  NewsService._();
  static final NewsService instance = NewsService._();

  static const String kCollection = 'news_posts';
  static const String kLastReadPrefs = 'news_last_read_ms_v1';
  static const int kMaxTitleLength = 120;
  static const int kMaxBodyLength = 4000;
  static const int kMaxImageBytes = 480000;

  final ValueNotifier<bool> hasUnread = ValueNotifier<bool>(false);

  FirebaseFirestore? get _db => firestoreOrNull();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _postsSub;
  int _latestPublishedMs = 0;
  int _watchers = 0;

  bool get canManagePosts => AppCreator.isCurrentUser;

  CollectionReference<Map<String, dynamic>>? get _postsRef {
    final db = _db;
    if (db == null) return null;
    return db.collection(kCollection);
  }

  Future<void> startWatching() async {
    _watchers++;
    if (_watchers > 1) return;
    final postsRef = _postsRef;
    if (postsRef == null) return;
    await _loadLastReadMs();
    _postsSub?.cancel();
    _postsSub = postsRef
        .orderBy('publishedAtMs', descending: true)
        .limit(40)
        .snapshots()
        .listen((snap) {
      var latest = 0;
      for (final doc in snap.docs) {
        final ms = (doc.data()['publishedAtMs'] as num?)?.toInt() ?? 0;
        if (ms > latest) latest = ms;
      }
      _latestPublishedMs = latest;
      _updateUnreadFlag();
    });
  }

  void stopWatching() {
    if (_watchers <= 0) return;
    _watchers--;
    if (_watchers > 0) return;
    _postsSub?.cancel();
    _postsSub = null;
  }

  Stream<List<NewsPost>> watchPosts({int limit = 40}) {
    final postsRef = _postsRef;
    if (postsRef == null) return const Stream.empty();
    return postsRef
        .orderBy('publishedAtMs', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final out = <NewsPost>[];
      for (final doc in snap.docs) {
        out.add(NewsPost.fromMap(doc.id, doc.data()));
      }
      out.sort((a, b) => b.publishedAtMs.compareTo(a.publishedAtMs));
      return out;
    });
  }

  Future<int> _loadLastReadMs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(kLastReadPrefs) ?? 0;
  }

  Future<void> _updateUnreadFlag() async {
    final lastRead = await _loadLastReadMs();
    hasUnread.value = _latestPublishedMs > lastRead;
  }

  Future<void> markAllRead() async {
    final prefs = await SharedPreferences.getInstance();
    final markMs = _latestPublishedMs > 0
        ? _latestPublishedMs
        : DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(kLastReadPrefs, markMs);
    hasUnread.value = false;
  }

  Future<void> refreshUnread() => _updateUnreadFlag();

  String _clip(String value, int max) {
    final trimmed = value.trim();
    if (trimmed.length <= max) return trimmed;
    return trimmed.substring(0, max);
  }

  String _resolveAuthorName() {
    final cloud = CloudSyncService.instance;
    final name = cloud.displayName.value?.trim() ?? '';
    if (name.isNotEmpty) return name;
    final email = cloud.user.value?.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'Admin';
  }

  Future<void> publishPost({
    required String title,
    required String body,
    List<int>? imageBytes,
    String imageMime = 'image/jpeg',
  }) async {
    if (!canManagePosts) throw StateError('forbidden');
    final uid = CloudSyncService.instance.user.value?.uid;
    if (uid == null) throw StateError('not_signed_in');

    final clippedTitle = _clip(title, kMaxTitleLength);
    final clippedBody = _clip(body, kMaxBodyLength);
    if (clippedTitle.isEmpty) throw StateError('empty_title');

    final data = <String, dynamic>{
      'title': clippedTitle,
      'body': clippedBody,
      'publishedAtMs': DateTime.now().millisecondsSinceEpoch,
      'authorUid': uid,
      'authorName': _resolveAuthorName(),
      'authorEmail': AppCreator.creatorEmail,
    };

    if (imageBytes != null && imageBytes.isNotEmpty) {
      if (imageBytes.length > kMaxImageBytes) {
        throw StateError('too_large');
      }
      data['imageData'] = base64Encode(imageBytes);
      data['imageMime'] = imageMime;
    }

    final postsRef = _postsRef;
    if (postsRef == null) throw StateError('firebase_not_ready');
    await postsRef.add(data);
  }

  Future<void> deletePost(String postId) async {
    if (!canManagePosts) throw StateError('forbidden');
    final postsRef = _postsRef;
    if (postsRef == null) throw StateError('firebase_not_ready');
    await postsRef.doc(postId).delete();
  }
}
