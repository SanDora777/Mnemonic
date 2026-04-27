import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../progress/progress_service.dart';
import '../progress/quest_service.dart';

class CloudSyncService {
  CloudSyncService._();
  static final CloudSyncService instance = CloudSyncService._();

  final ValueNotifier<User?> user = ValueNotifier<User?>(null);
  final ValueNotifier<String?> displayName = ValueNotifier<String?>(null);
  final ValueNotifier<String?> photoUrl = ValueNotifier<String?>(null);
  final ValueNotifier<bool> isBusy = ValueNotifier<bool>(false);
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);

  StreamSubscription<User?>? _authSub;
  bool _initialized = false;
  bool _firebaseReady = false;
  // Web OAuth client ID from Firebase project settings.
  static const String _kGoogleServerClientId =
      '518339793941-vkblqi0u7sa6ign1hsfdflg72uq0evhi.apps.googleusercontent.com';
  static const String _kLocalBoundUid = 'cloud_bound_uid';

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool get isSignedIn => user.value != null;
  bool get firebaseReady => _firebaseReady;

  Future<void> init({required bool firebaseReady}) async {
    if (_initialized) return;
    _initialized = true;
    _firebaseReady = firebaseReady;

    if (!_firebaseReady) {
      return;
    }

    await _googleSignIn.initialize(serverClientId: _kGoogleServerClientId);
    user.value = FirebaseAuth.instance.currentUser;
    _authSub = FirebaseAuth.instance.authStateChanges().listen((u) async {
      user.value = u;
      displayName.value = u?.displayName;
      if (u != null) {
        await _ensureLocalStateBoundToUser(u.uid);
        await _loadProfile();
        await _pullFromCloud();
      } else {
        await _clearBoundUid();
      }
    });
  }

  Future<void> dispose() async {
    await _authSub?.cancel();
  }

  Future<void> signInWithGoogle() async {
    if (!_firebaseReady) return;
    if (isBusy.value) return;
    isBusy.value = true;
    lastError.value = null;
    try {
      await _performGoogleSignInFlow();
    } on GoogleSignInException catch (e) {
      final message = e.toString();
      if (message.contains('Account reauth failed')) {
        // Attempt automatic recovery from stale account state.
        try {
          await _googleSignIn.disconnect();
        } catch (_) {}
        try {
          await _googleSignIn.signOut();
        } catch (_) {}
        try {
          await FirebaseAuth.instance.signOut();
        } catch (_) {}
        try {
          await _performGoogleSignInFlow();
          return;
        } catch (_) {
          lastError.value =
              'Google account re-auth failed. Remove this app access in Google account settings and sign in again.';
        }
      } else {
        lastError.value = message;
      }
    } on FirebaseAuthException catch (e) {
      lastError.value = e.message ?? e.code;
    } catch (e) {
      final raw = e.toString();
      if (raw.contains('ApiException: 10') ||
          raw.contains('DEVELOPER_ERROR') ||
          raw.contains('Developer console is not set up correctly') ||
          raw.contains('API key not valid')) {
        lastError.value =
            'Google Sign-In is not configured correctly in Firebase/Google Cloud (OAuth, API key, SHA-1/SHA-256).';
      } else {
        lastError.value = raw;
      }
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (!_firebaseReady) return;
    if (isBusy.value) return;
    isBusy.value = true;
    lastError.value = null;
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _loadProfile();
      await _pullFromCloud();
      await syncNow();
    } on FirebaseAuthException catch (e) {
      lastError.value = e.message ?? e.code;
    } catch (e) {
      lastError.value = e.toString();
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (!_firebaseReady) return;
    if (isBusy.value) return;
    isBusy.value = true;
    lastError.value = null;
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final normalizedName = displayName?.trim();
      if (normalizedName != null && normalizedName.isNotEmpty) {
        final current = FirebaseAuth.instance.currentUser;
        if (current != null) {
          await current.updateDisplayName(normalizedName);
          await current.reload();
          user.value = FirebaseAuth.instance.currentUser;
          this.displayName.value = normalizedName;
        }
      }
      await _loadProfile();
      await _pullFromCloud();
      await syncNow();
    } on FirebaseAuthException catch (e) {
      lastError.value = e.message ?? e.code;
    } catch (e) {
      lastError.value = e.toString();
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> _performGoogleSignInFlow() async {
    // Prefer native Firebase provider flow first: avoids flaky re-auth in
    // GoogleSignIn Android Credential Manager for some devices/accounts.
    try {
      await FirebaseAuth.instance.signInWithProvider(GoogleAuthProvider());
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
      // Fallback to token-based flow for compatibility.
      final account = await _googleSignIn.authenticate();
      final auth = account.authentication;
      if (auth.idToken == null) {
        throw FirebaseAuthException(
          code: 'missing-google-token',
          message: 'Google Sign-In did not return ID token.',
        );
      }
      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    }
    await _loadProfile();
    await _pullFromCloud();
    await syncNow();
  }

  Future<void> signOut() async {
    if (!_firebaseReady) return;
    if (isBusy.value) return;
    isBusy.value = true;
    lastError.value = null;
    try {
      await FirebaseAuth.instance.signOut();
      await _googleSignIn.signOut();
      displayName.value = null;
      photoUrl.value = null;
    } catch (e) {
      lastError.value = e.toString();
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> signInAnonymously() async {
    if (!_firebaseReady) return;
    if (isBusy.value) return;
    isBusy.value = true;
    lastError.value = null;
    try {
      await FirebaseAuth.instance.signInAnonymously();
      await _loadProfile();
      await _pullFromCloud();
      await syncNow();
    } catch (e) {
      lastError.value = e.toString();
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> syncNow() async {
    if (!_firebaseReady || !isSignedIn) return;
    final ownBusyLock = !isBusy.value;
    if (ownBusyLock) {
      isBusy.value = true;
    }
    lastError.value = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = user.value!.uid;
      final payload = <String, dynamic>{
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
        'progress': ProgressService.instance.toCloudJson(),
        'quests': QuestService.instance.toCloudJson(),
        'stats': _readStats(prefs),
      };
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('app')
          .doc('state')
          .set(payload, SetOptions(merge: true));
    } catch (e) {
      lastError.value = e.toString();
    } finally {
      if (ownBusyLock) {
        isBusy.value = false;
      }
    }
  }

  Future<void> _pullFromCloud() async {
    if (!_firebaseReady || !isSignedIn) return;
    lastError.value = null;
    try {
      final uid = user.value!.uid;
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('app')
          .doc('state')
          .get();
      if (!snap.exists) {
        await syncNow();
        return;
      }

      final data = snap.data();
      if (data == null) return;

      final progressRaw = data['progress'];
      if (progressRaw is Map<String, dynamic>) {
        await ProgressService.instance.applyCloudJson(progressRaw);
      }
      final questRaw = data['quests'];
      if (questRaw is Map<String, dynamic>) {
        await QuestService.instance.applyCloudJson(questRaw);
      }
      final statsRaw = data['stats'];
      if (statsRaw is Map<String, dynamic>) {
        final prefs = await SharedPreferences.getInstance();
        await _writeStats(prefs, statsRaw);
      }
    } catch (e) {
      lastError.value = e.toString();
    }
  }

  Future<void> updateDisplayName(String name) async {
    if (!_firebaseReady || !isSignedIn) return;
    final normalized = name.trim();
    if (normalized.isEmpty) return;
    if (isBusy.value) return;
    isBusy.value = true;
    lastError.value = null;
    try {
      final current = FirebaseAuth.instance.currentUser;
      if (current == null) return;
      await current.updateDisplayName(normalized);
      await current.reload();
      final reloaded = FirebaseAuth.instance.currentUser;
      user.value = reloaded;
      displayName.value = normalized;
      await _profileDoc(current.uid).set({
        'displayName': normalized,
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
      await _updateCurrentLeaderboardName(current.uid, normalized);
    } catch (e) {
      lastError.value = e.toString();
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> updateProfilePhotoBytes(
    Uint8List bytes, {
    required String fileExt,
  }) async {
    if (!_firebaseReady || !isSignedIn) return;
    if (isBusy.value) return;
    isBusy.value = true;
    lastError.value = null;
    try {
      final current = FirebaseAuth.instance.currentUser;
      if (current == null) return;
      final ext = fileExt.toLowerCase().replaceAll('.', '');
      final safeExt = (ext == 'jpg' || ext == 'jpeg' || ext == 'png' || ext == 'webp')
          ? ext
          : 'jpg';
      final contentType = switch (safeExt) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(current.uid)
          .child('profile')
          .child('avatar.$safeExt');
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      final downloadUrl = await ref.getDownloadURL();

      await current.updatePhotoURL(downloadUrl);
      await current.reload();
      user.value = FirebaseAuth.instance.currentUser;
      photoUrl.value = downloadUrl;

      await _profileDoc(current.uid).set({
        'photoUrl': downloadUrl,
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
    } catch (e) {
      lastError.value = e.toString();
    } finally {
      isBusy.value = false;
    }
  }

  String accountTitle() {
    final u = user.value;
    if (u == null) return '';
    final explicit = displayName.value?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final authName = u.displayName?.trim();
    if (authName != null && authName.isNotEmpty) return authName;
    final email = u.email?.trim();
    if (email != null && email.isNotEmpty) return email;
    if (u.isAnonymous) return 'Guest';
    return 'User';
  }

  Future<void> _loadProfile() async {
    final u = user.value;
    if (!_firebaseReady || u == null) return;
    try {
      final snap = await _profileDoc(u.uid).get();
      final data = snap.data();
      final cloudName = data?['displayName'];
      final cloudPhoto = data?['photoUrl'];
      if (cloudName is String && cloudName.trim().isNotEmpty) {
        displayName.value = cloudName.trim();
      } else {
        displayName.value = u.displayName;
      }
      if (cloudPhoto is String && cloudPhoto.trim().isNotEmpty) {
        photoUrl.value = cloudPhoto.trim();
      } else {
        photoUrl.value = u.photoURL;
      }
      await _profileDoc(u.uid).set({
        'isAnonymous': u.isAnonymous,
        'email': u.email,
        'displayName': displayName.value,
        'photoUrl': photoUrl.value,
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
    } catch (_) {
      displayName.value = u.displayName;
      photoUrl.value = u.photoURL;
    }
  }

  DocumentReference<Map<String, dynamic>> _profileDoc(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  Future<void> _updateCurrentLeaderboardName(String uid, String newName) async {
    final now = DateTime.now();
    final dayKey =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final monthKey = '${now.year}${now.month.toString().padLeft(2, '0')}';

    final dailyRef = FirebaseFirestore.instance
        .collection('leaderboards')
        .doc('daily')
        .collection(dayKey)
        .doc(uid);
    final monthlyRef = FirebaseFirestore.instance
        .collection('leaderboards')
        .doc('monthly')
        .collection(monthKey)
        .doc(uid);
    await dailyRef.set({'displayName': newName}, SetOptions(merge: true));
    await monthlyRef.set({'displayName': newName}, SetOptions(merge: true));
  }

  Future<void> _ensureLocalStateBoundToUser(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final boundUid = prefs.getString(_kLocalBoundUid);
    if (boundUid == uid) return;

    await _resetLocalAccountData();
    await prefs.setString(_kLocalBoundUid, uid);
  }

  Future<void> _clearBoundUid() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLocalBoundUid);
  }

  Future<void> _resetLocalAccountData() async {
    await ProgressService.instance.resetLocalProgress();
    await QuestService.instance.resetLocalQuests();
    final prefs = await SharedPreferences.getInstance();

    const modes = ['standard', 'binary', 'words', 'images', 'cards'];
    for (final mode in modes) {
      await prefs.remove('best_score_$mode');
      await prefs.remove('total_games_$mode');
      await prefs.remove('avg_percentage_$mode');
      await prefs.remove('best_avg_ms_per_el_$mode');
      await prefs.remove('game_history_$mode');
    }
  }

  Map<String, dynamic> _readStats(SharedPreferences prefs) {
    final out = <String, dynamic>{};

    const modes = ['standard', 'binary', 'words', 'images', 'cards'];
    for (final mode in modes) {
      out['best_score_$mode'] = prefs.getInt('best_score_$mode') ?? 0;
      out['total_games_$mode'] = prefs.getInt('total_games_$mode') ?? 0;
      out['avg_percentage_$mode'] = prefs.getDouble('avg_percentage_$mode') ?? 0.0;
      out['best_avg_ms_per_el_$mode'] = prefs.getInt('best_avg_ms_per_el_$mode') ?? 0;
      out['game_history_$mode'] = prefs.getStringList('game_history_$mode') ?? <String>[];
    }

    out['app_language'] = prefs.getString('app_language') ?? 'ru';
    out['app_palette_index'] = prefs.getInt('app_palette_index') ?? 0;
    return out;
  }

  Future<void> _writeStats(SharedPreferences prefs, Map<String, dynamic> raw) async {
    for (final entry in raw.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is List) {
        final asStrings = value.map((e) => e.toString()).toList();
        await prefs.setStringList(key, asStrings);
      }
    }
  }
}
