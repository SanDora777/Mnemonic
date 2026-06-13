import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show ValueNotifier, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_creator.dart';
import '../profile/profile_session_service.dart';
import '../progress/progress_service.dart';
import '../progress/quest_service.dart';
import '../public_stats_scoring.dart';
import '../training_history_service.dart';
import 'email_auth_policy.dart';
import 'email_otp_service.dart';

class CloudSyncService {
  CloudSyncService._();
  static final CloudSyncService instance = CloudSyncService._();

  /// Temporary: hide Google Sign-In UI; only email + anonymous auth.
  static const bool googleSignInEnabled = false;

  final ValueNotifier<User?> user = ValueNotifier<User?>(null);
  final ValueNotifier<String?> displayName = ValueNotifier<String?>(null);
  final ValueNotifier<String?> photoUrl = ValueNotifier<String?>(null);
  final ValueNotifier<Uint8List?> photoBytes = ValueNotifier<Uint8List?>(null);
  final ValueNotifier<String> aboutMe = ValueNotifier<String>('');
  final ValueNotifier<bool> shareResults = ValueNotifier<bool>(true);
  final ValueNotifier<bool> isBusy = ValueNotifier<bool>(false);
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);
  final ValueNotifier<String?> lastAuthInfo = ValueNotifier<String?>(null);
  final ValueNotifier<bool> authScreenRequired = ValueNotifier<bool>(false);

  StreamSubscription<User?>? _authSub;
  bool _initialized = false;
  bool _firebaseReady = false;
  bool _googleSignInReady = false;

  /// Firebase app is running (Firestore/Auth usable). Prefer this for public reads.
  bool get isFirebaseInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  bool get googleSignInReady => _googleSignInReady;
  /// OAuth client ID from Firebase (Google Sign-In → Web client).
  /// Used as [GoogleSignIn.initialize] `serverClientId` on Android/iOS and
  /// `clientId` on web — redirect-based Firebase OAuth breaks on partitioned
  /// mobile browsers without accessible sessionStorage.
  static const String _kGoogleServerClientId =
      '518339793941-vkblqi0u7sa6ign1hsfdflg72uq0evhi.apps.googleusercontent.com';
  static const String _kLocalBoundUid = 'cloud_bound_uid';
  static const String _kAuthScreenRequired = 'cloud_auth_screen_required';
  static const String _kAvatarBase64Prefix = 'cloud_avatar_b64_';
  static const String _kLocalStateUpdatedAtMs = 'cloud_local_state_updated_at_ms';
  static const int _kAvatarMaxBytes = 600 * 1024;
  static const Duration _kCloudOpTimeout = Duration(seconds: 8);

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void> _syncPipeline = Future<void>.value();

  bool get isSignedIn => user.value != null;
  bool get firebaseReady => _firebaseReady;

  /// Email/password account that still needs the 6-digit inbox code.
  bool get needsEmailVerification {
    final u = user.value;
    return u != null && u.email != null && u.email!.isNotEmpty && !u.emailVerified;
  }

  Future<void> init({required bool firebaseReady}) async {
    final prefs = await SharedPreferences.getInstance();
    authScreenRequired.value = prefs.getBool(_kAuthScreenRequired) ?? false;

    if (_initialized) {
      if (firebaseReady && !_firebaseReady) {
        await _enableFirebase();
      }
      return;
    }

    _initialized = true;
    if (!firebaseReady) {
      return;
    }

    await _enableFirebase();
  }

  Future<void> _enableFirebase() async {
    if (_firebaseReady) return;
    try {
      if (googleSignInEnabled) {
        try {
          await _googleSignIn
              .initialize(
                clientId: kIsWeb ? _kGoogleServerClientId : null,
                serverClientId: kIsWeb ? null : _kGoogleServerClientId,
              )
              .timeout(_kCloudOpTimeout);
          _googleSignInReady = true;
        } catch (_) {
          // Email/anonymous auth and Firestore reads still work; only Google Sign-In is unavailable.
          _googleSignInReady = false;
        }
      } else {
        _googleSignInReady = false;
      }
      _firebaseReady = true;
      user.value = FirebaseAuth.instance.currentUser;
      if (user.value != null) {
        await _setAuthScreenRequired(false);
      }
      await _authSub?.cancel();
      _authSub = FirebaseAuth.instance.authStateChanges().listen((u) async {
        user.value = u;
        displayName.value = u?.displayName;
        if (u != null) {
          await _setAuthScreenRequired(false);
          await _ensureLocalStateBoundToUser(u.uid);
          await _loadProfile();
          await pullMergeAndPush();
        } else {
          await _clearBoundUid();
        }
      });
    } catch (_) {
      _firebaseReady = false;
      _googleSignInReady = false;
      rethrow;
    }
  }

  Future<void> dispose() async {
    await _authSub?.cancel();
  }

  Future<void> signInWithGoogle() async {
    if (!googleSignInEnabled) {
      lastError.value = 'Google Sign-In is temporarily disabled. Use email or guest sign-in.';
      return;
    }
    if (!_firebaseReady) return;
    if (!_googleSignInReady) {
      lastError.value =
          'Google Sign-In is temporarily unavailable (initialization failed). Use email/password or restart the app.';
      return;
    }
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

  String _authLang(String lang) {
    if (lang == 'en' || lang == 'de' || lang == 'ru') return lang;
    return 'ru';
  }

  void _setAuthError(String? message) {
    lastError.value = message;
    if (message != null) lastAuthInfo.value = null;
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
    String lang = 'ru',
  }) async {
    if (!_firebaseReady) return;
    final l = _authLang(lang);
    final emailErr = EmailAuthPolicy.validateEmail(email, l);
    if (emailErr != null) {
      _setAuthError(emailErr);
      return;
    }
    final passErr = EmailAuthPolicy.validatePassword(password, l);
    if (passErr != null) {
      _setAuthError(passErr);
      return;
    }
    if (isBusy.value) return;
    isBusy.value = true;
    _setAuthError(null);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final current = FirebaseAuth.instance.currentUser;
      if (current != null && !current.emailVerified) {
        final sent = await sendEmailVerificationCode(lang: l);
        if (!sent) {
          lastAuthInfo.value = EmailAuthPolicy.emailNotVerifiedHint(l);
        }
        return;
      }
      await _loadProfile();
      await pullMergeAndPush();
    } on FirebaseAuthException catch (e) {
      _setAuthError(EmailAuthPolicy.friendlyFirebaseError(e.code, l, fallback: e.message));
    } catch (e) {
      _setAuthError(e.toString());
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
    String lang = 'ru',
  }) async {
    if (!_firebaseReady) return;
    final l = _authLang(lang);
    final emailErr = EmailAuthPolicy.validateEmail(email, l);
    if (emailErr != null) {
      _setAuthError(emailErr);
      return;
    }
    final passErr = EmailAuthPolicy.validatePassword(password, l);
    if (passErr != null) {
      _setAuthError(passErr);
      return;
    }
    if (isBusy.value) return;
    isBusy.value = true;
    _setAuthError(null);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final current = FirebaseAuth.instance.currentUser;
      if (current != null) {
        final normalizedName = displayName?.trim();
        if (normalizedName != null && normalizedName.isNotEmpty) {
          await current.updateDisplayName(normalizedName);
          this.displayName.value = normalizedName;
        }
        await current.reload();
        user.value = FirebaseAuth.instance.currentUser;
        final sent = await sendEmailVerificationCode(lang: l);
        if (sent) {
          lastAuthInfo.value =
              EmailAuthPolicy.registrationVerificationSent(email.trim(), l);
        }
      }
    } on FirebaseAuthException catch (e) {
      _setAuthError(EmailAuthPolicy.friendlyFirebaseError(e.code, l, fallback: e.message));
    } catch (e) {
      _setAuthError(e.toString());
    } finally {
      isBusy.value = false;
    }
  }

  /// Sends Firebase password-reset email (link to set a new password).
  Future<bool> sendPasswordResetEmail({
    required String email,
    String lang = 'ru',
  }) async {
    if (!_firebaseReady) return false;
    final l = _authLang(lang);
    final emailErr = EmailAuthPolicy.validateEmail(email, l);
    if (emailErr != null) {
      _setAuthError(emailErr);
      return false;
    }
    if (isBusy.value) return false;
    isBusy.value = true;
    _setAuthError(null);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      lastAuthInfo.value = EmailAuthPolicy.passwordResetSent(email.trim(), l);
      return true;
    } on FirebaseAuthException catch (e) {
      _setAuthError(EmailAuthPolicy.friendlyFirebaseError(e.code, l, fallback: e.message));
      return false;
    } catch (e) {
      _setAuthError(e.toString());
      return false;
    } finally {
      isBusy.value = false;
    }
  }

  /// Sends a new 6-digit verification code to the signed-in user's email.
  ///
  /// When [allowWhileBusy] is true (e.g. first open of the verification screen),
  /// the send is not blocked by other auth UI busy state.
  Future<bool> sendEmailVerificationCode({
    String lang = 'ru',
    bool allowWhileBusy = false,
    bool showSuccessInfo = true,
  }) async {
    if (!_firebaseReady) return false;
    final l = _authLang(lang);
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return false;
    if (current.emailVerified) return true;
    if (isBusy.value && !allowWhileBusy) return false;
    isBusy.value = true;
    _setAuthError(null);
    try {
      final result = await EmailOtpService.instance.sendCode(lang: l);
      if (!result.ok) {
        final usedLinkFallback = await _tryFirebaseLinkVerificationFallback(
          current,
          l,
          result.error,
        );
        if (usedLinkFallback) return true;
        _setAuthError(result.error);
        return false;
      }
      if (showSuccessInfo) {
        lastAuthInfo.value = EmailAuthPolicy.verificationResent(l);
      }
      return true;
    } catch (e) {
      _setAuthError(e.toString());
      return false;
    } finally {
      isBusy.value = false;
    }
  }

  /// If Cloud Functions are unavailable or SMTP is not configured, send
  /// Firebase's built-in verification link so users can still confirm email.
  Future<bool> _tryFirebaseLinkVerificationFallback(
    User current,
    String lang,
    String? otpError,
  ) async {
    if (otpError != null) {
      final lowered = otpError.toLowerCase();
      if (lowered.contains('wait ') ||
          lowered.contains('подожди') ||
          lowered.contains('später') ||
          lowered.contains('too many') ||
          lowered.contains('слишком много')) {
        return false;
      }
    }
    try {
      await current.sendEmailVerification();
      lastAuthInfo.value = EmailAuthPolicy.verificationLinkSent(lang);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Reloads the signed-in user and completes sign-in when email is verified
  /// (e.g. after the user tapped the link in their inbox).
  Future<bool> refreshEmailVerifiedStatus() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return false;
    await current.reload();
    user.value = FirebaseAuth.instance.currentUser;
    final verified = user.value?.emailVerified ?? false;
    if (verified) {
      await _setAuthScreenRequired(false);
      await _loadProfile();
      await pullMergeAndPush();
      lastAuthInfo.value = null;
    }
    return verified;
  }

  /// Verifies the 6-digit code and marks the account email as confirmed.
  Future<bool> verifyEmailWithCode({
    required String code,
    String lang = 'ru',
  }) async {
    if (!_firebaseReady) return false;
    final l = _authLang(lang);
    if (isBusy.value) return false;
    isBusy.value = true;
    _setAuthError(null);
    try {
      final result = await EmailOtpService.instance.verifyCode(code: code, lang: l);
      if (!result.ok) {
        _setAuthError(result.error);
        return false;
      }
      user.value = FirebaseAuth.instance.currentUser;
      await _setAuthScreenRequired(false);
      await _loadProfile();
      await pullMergeAndPush();
      lastAuthInfo.value = null;
      return true;
    } catch (e) {
      _setAuthError(e.toString());
      return false;
    } finally {
      isBusy.value = false;
    }
  }

  /// Resend verification code (alias for settings UI).
  Future<bool> resendEmailVerification({String lang = 'ru'}) =>
      sendEmailVerificationCode(lang: lang);

  Future<void> _performGoogleSignInFlow() async {
    // Always use Google Sign-In SDK + Firebase credential. Do not use
    // signInWithProvider on mobile: it launches a browser / Custom Tab, often
    // leaves the user stuck after OAuth. authenticate() shows the native
    // account picker (Play services / iOS) and returns an id token; Firebase
    // creates or links the user automatically. On web, this avoids redirect
    // sessionStorage issues (see kIsWeb initialize() above).
    await _signInWithGoogleCredential();
    await _loadProfile();
    await pullMergeAndPush();
  }

  Future<void> _signInWithGoogleCredential() async {
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

  Future<void> signOut() async {
    if (!_firebaseReady) return;
    if (isBusy.value) return;
    isBusy.value = true;
    lastError.value = null;
    try {
      await FirebaseAuth.instance.signOut();
      await _googleSignIn.signOut();
      user.value = null;
      displayName.value = null;
      photoUrl.value = null;
      photoBytes.value = null;
      aboutMe.value = '';
      shareResults.value = true;
      await _clearBoundUid();
      await _resetLocalAccountData();
      await _setAuthScreenRequired(true);
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
      await pullMergeAndPush();
    } catch (e) {
      lastError.value = e.toString();
    } finally {
      isBusy.value = false;
    }
  }

  /// Marks local app state as newer than the last cloud snapshot (before upload).
  Future<void> markLocalStateDirty() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _kLocalStateUpdatedAtMs,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Queues [syncNow] so it never races with [pullMergeAndPush] or another sync.
  /// Queues upload so it never races with cloud pull / merge.
  Future<void> enqueueSync() => _runOnSyncPipeline(_syncNowImpl);

  /// Pull cloud data, merge into local, merge training history, then push merged state.
  Future<void> pullMergeAndPush() => _runOnSyncPipeline(_pullMergeAndPushInternal);

  Future<T> _runOnSyncPipeline<T>(Future<T> Function() action) {
    final op = _syncPipeline.then((_) => action());
    _syncPipeline = op.then((_) {}).catchError((_) {});
    return op;
  }

  Future<void> _pullMergeAndPushInternal() async {
    await _pullFromCloud();
    await _pullAllTrainingHistoryFromCloud();
    await _syncNowImpl();
  }

  Future<void> syncNow() => enqueueSync();

  Future<void> _syncNowImpl() async {
    if (!_firebaseReady || !isSignedIn) return;
    final ownBusyLock = !isBusy.value;
    if (ownBusyLock) {
      isBusy.value = true;
    }
    lastError.value = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = user.value!.uid;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_kLocalStateUpdatedAtMs, nowMs);
      final payload = <String, dynamic>{
        'updatedAtMs': nowMs,
        'progress': ProgressService.instance.toCloudJson(),
        'quests': QuestService.instance.toCloudJson(),
        'stats': _readStats(prefs),
        'profileSessions': await ProfileSessionService.instance.toCloudJson(),
      };
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('app')
          .doc('state')
          .set(payload, SetOptions(merge: true))
          .timeout(_kCloudOpTimeout);
      await _profileDoc(uid).set({
        'publicStats': _buildPublicStatsSnapshot(prefs),
        'updatedAtMs': nowMs,
      }, SetOptions(merge: true)).timeout(_kCloudOpTimeout);
    } catch (e) {
      lastError.value = e.toString();
    } finally {
      if (ownBusyLock) {
        isBusy.value = false;
      }
    }
  }

  Future<void> uploadTrainingHistoryEntry(TrainingHistoryEntry entry) async {
    if (!_firebaseReady || !isSignedIn) return;
    return _runOnSyncPipeline(() async {
    try {
      final uid = user.value!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('training_history')
          .doc(entry.id)
          .set(_trainingHistoryCloudJson(entry), SetOptions(merge: true))
          .timeout(_kCloudOpTimeout);
    } catch (e) {
      lastError.value = e.toString();
    }
    });
  }

  Future<void> deleteTrainingHistoryEntry(String id) async {
    if (!_firebaseReady || !isSignedIn || id.isEmpty) return;
    try {
      final uid = user.value!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('training_history')
          .doc(id)
          .delete()
          .timeout(_kCloudOpTimeout);
    } catch (e) {
      lastError.value = e.toString();
    }
  }

  Map<String, dynamic> _trainingHistoryCloudJson(TrainingHistoryEntry entry) {
    final json = Map<String, dynamic>.from(entry.toJson());
    if (entry.mode == 'faces') {
      json['data'] = entry.data.map((raw) {
        try {
          final person = jsonDecode(raw) as Map<String, dynamic>;
          person['imageData'] = '';
          return jsonEncode(person);
        } catch (_) {
          return raw;
        }
      }).toList(growable: false);
    }
    return json;
  }

  Future<List<TrainingHistoryEntry>> fetchTrainingHistory({String? mode}) async {
    if (!_firebaseReady || !isSignedIn) return const <TrainingHistoryEntry>[];
    try {
      final uid = user.value!.uid;
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('training_history')
          .orderBy('date', descending: true)
          .limit(240)
          .get()
          .timeout(_kCloudOpTimeout);
      final out = <TrainingHistoryEntry>[];
      for (final doc in snap.docs) {
        try {
          final entry = TrainingHistoryEntry.fromJson(doc.data());
          if (mode == null || entry.mode == mode) {
            out.add(entry);
          }
        } catch (_) {}
      }
      return out;
    } catch (e) {
      lastError.value = e.toString();
      return const <TrainingHistoryEntry>[];
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
          .get()
          .timeout(_kCloudOpTimeout);
      if (!snap.exists) {
        await _syncNowImpl();
        return;
      }

      final data = snap.data();
      if (data == null) return;

      final progressRaw = data['progress'];
      if (progressRaw is Map<String, dynamic>) {
        await ProgressService.instance.applyCloudJson(progressRaw);
      }
      final questRaw = data['quests'];
      if (questRaw is Map<String, dynamic> &&
          !_cloudQuestPayloadWouldWipeDailyWeekly(questRaw)) {
        await QuestService.instance.mergeCloudJson(questRaw);
      }
      final statsRaw = data['stats'];
      if (statsRaw is Map<String, dynamic>) {
        final prefs = await SharedPreferences.getInstance();
        final mergedStats = _mergeStatsWithExisting(prefs, statsRaw);
        await _writeStats(prefs, mergedStats);
      }
      final profileSessionsRaw = data['profileSessions'];
      if (profileSessionsRaw is Map<String, dynamic>) {
        await ProfileSessionService.instance.applyCloudJson(profileSessionsRaw);
      } else if (profileSessionsRaw is Map) {
        await ProfileSessionService.instance.applyCloudJson(
          Map<String, dynamic>.from(profileSessionsRaw),
        );
      }
    } catch (e) {
      lastError.value = e.toString();
    }
  }

  Future<void> _pullAllTrainingHistoryFromCloud() async {
    if (!_firebaseReady || !isSignedIn) return;
    for (final mode in trainingHistoryModes) {
      try {
        final cloud = await fetchTrainingHistory(mode: mode);
        if (cloud.isNotEmpty) {
          await TrainingHistoryService.instance.mergeFromCloud(mode, cloud);
        }
      } catch (_) {}
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

  Future<void> updateAboutMe(String text) async {
    if (!_firebaseReady || !isSignedIn) return;
    final normalized = text.trim();
    if (normalized.length > 180) return;
    if (isBusy.value) return;
    isBusy.value = true;
    lastError.value = null;
    try {
      final current = FirebaseAuth.instance.currentUser;
      if (current == null) return;
      aboutMe.value = normalized;
      await _profileDoc(current.uid).set({
        'aboutMe': normalized,
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
      await _syncLeaderboardProfileMetadata(current.uid);
    } catch (e) {
      lastError.value = e.toString();
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> updateShareResults(bool allow) async {
    if (!_firebaseReady || !isSignedIn) return;
    if (isBusy.value) return;
    isBusy.value = true;
    lastError.value = null;
    try {
      final current = FirebaseAuth.instance.currentUser;
      if (current == null) return;
      shareResults.value = allow;
      await _profileDoc(current.uid).set({
        'shareResults': allow,
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
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
    if (!isSignedIn) return;
    if (isBusy.value) return;
    if (bytes.isEmpty) return;
    isBusy.value = true;
    lastError.value = null;
    try {
      if (bytes.lengthInBytes > _kAvatarMaxBytes) {
        lastError.value =
            'Фото слишком большое. Выбери изображение поменьше.';
        return;
      }

      final ext = fileExt.toLowerCase().replaceAll('.', '');
      final safeExt = (ext == 'jpg' || ext == 'jpeg' || ext == 'png' || ext == 'webp')
          ? ext
          : 'jpg';
      final mime = switch (safeExt) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
      final base64Str = base64Encode(bytes);
      final dataUri = 'data:$mime;base64,$base64Str';

      // Update local cache first so UI reflects the change instantly even
      // if Firestore is unavailable (offline / rules / etc.).
      final current = FirebaseAuth.instance.currentUser ?? user.value;
      final uid = current?.uid;
      final prefs = await SharedPreferences.getInstance();
      if (uid != null) {
        await prefs.setString('$_kAvatarBase64Prefix$uid', base64Str);
      }
      photoBytes.value = Uint8List.fromList(bytes);
      photoUrl.value = dataUri;

      if (_firebaseReady && current != null) {
        try {
          await _profileDoc(current.uid).set({
            'photoData': base64Str,
            'photoMime': mime,
            'photoUrl': '',
            'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
          }, SetOptions(merge: true)).timeout(_kCloudOpTimeout);
          await _syncLeaderboardProfileMetadata(current.uid);
        } catch (_) {
          // Cloud save is best-effort; local cache already keeps the avatar.
        }
      }
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

    // Restore avatar bytes from local cache first so the UI never blanks out.
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedB64 = prefs.getString('$_kAvatarBase64Prefix${u.uid}');
      if (cachedB64 != null && cachedB64.isNotEmpty) {
        try {
          photoBytes.value = base64Decode(cachedB64);
        } catch (_) {
          photoBytes.value = null;
        }
      } else {
        photoBytes.value = null;
      }
    } catch (_) {}

    try {
      final snap = await _profileDoc(u.uid).get().timeout(_kCloudOpTimeout);
      final data = snap.data();
      final cloudName = data?['displayName'];
      final cloudPhoto = data?['photoUrl'];
      final cloudPhotoData = data?['photoData'];
      final cloudAbout = data?['aboutMe'];
      final cloudShare = data?['shareResults'];
      if (cloudName is String && cloudName.trim().isNotEmpty) {
        displayName.value = cloudName.trim();
      } else {
        displayName.value = u.displayName;
      }

      // Prefer base64 inline avatar over a (legacy) URL.
      Uint8List? decodedBytes;
      if (cloudPhotoData is String && cloudPhotoData.isNotEmpty) {
        try {
          decodedBytes = base64Decode(cloudPhotoData);
        } catch (_) {
          decodedBytes = null;
        }
      }
      if (decodedBytes != null) {
        photoBytes.value = decodedBytes;
        photoUrl.value = '';
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              '$_kAvatarBase64Prefix${u.uid}', cloudPhotoData as String);
        } catch (_) {}
      } else if (cloudPhoto is String && cloudPhoto.trim().isNotEmpty) {
        photoUrl.value = cloudPhoto.trim();
      } else if (photoBytes.value == null) {
        photoUrl.value = u.photoURL;
      } else {
        photoUrl.value = '';
      }

      if (cloudAbout is String) {
        aboutMe.value = cloudAbout.trim();
      } else {
        aboutMe.value = '';
      }
      if (cloudShare is bool) {
        shareResults.value = cloudShare;
      } else {
        shareResults.value = true;
      }
      await AppCreator.syncProfileBadgeIfNeeded();
      await _profileDoc(u.uid).set({
        'isAnonymous': u.isAnonymous,
        'email': u.email,
        'displayName': displayName.value,
        'aboutMe': aboutMe.value,
        'shareResults': shareResults.value,
        if (AppCreator.isCurrentUser) 'isCreator': true,
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true)).timeout(_kCloudOpTimeout);
    } catch (_) {
      displayName.value = u.displayName;
      if (photoBytes.value == null) {
        photoUrl.value = u.photoURL;
      }
      aboutMe.value = '';
      shareResults.value = true;
    }
  }

  /// Decodes avatar bytes from profile/leaderboard fields (base64 or data: URI).
  static Uint8List? decodePublicAvatarBytes({
    String? photoData,
    String? photoUrl,
  }) {
    final rawData = (photoData ?? '').trim();
    if (rawData.isNotEmpty) {
      try {
        return base64Decode(rawData);
      } catch (_) {}
    }
    final url = (photoUrl ?? '').trim();
    if (url.startsWith('data:')) {
      final comma = url.indexOf(',');
      if (comma > 0 && comma < url.length - 1) {
        try {
          return base64Decode(url.substring(comma + 1));
        } catch (_) {}
      }
    }
    return null;
  }

  static String resolveHttpAvatarUrl(String? photoUrl) {
    final url = (photoUrl ?? '').trim();
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '';
  }

  Future<Map<String, dynamic>?> fetchPublicProfile(String uid) async {
    if (!_firebaseReady) return null;
    Map<String, dynamic> profile = <String, dynamic>{};
    Map<String, dynamic> leaderboard = <String, dynamic>{};
    bool profileExists = false;
    try {
      final profileSnap = await _profileDoc(uid).get().timeout(_kCloudOpTimeout);
      profileExists = profileSnap.exists;
      profile = profileSnap.data() ?? <String, dynamic>{};
    } catch (_) {}

    leaderboard = await _fetchLeaderboardProfileHints(uid);

    if (!profileExists && leaderboard.isEmpty) return null;

    final allow = (profile['shareResults'] as bool?) ?? (leaderboard['shareResults'] as bool?) ?? true;
    final meUid = user.value?.uid;
    final canSeeStats = allow || meUid == uid;
    Map<String, dynamic> appData = const <String, dynamic>{};

    if (!profileExists || canSeeStats) {
      try {
        final appSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('app')
            .doc('state')
            .get()
            .timeout(_kCloudOpTimeout);
        appData = appSnap.data() ?? const <String, dynamic>{};
      } catch (_) {}
    }

    Map<String, dynamic> publicStats = <String, dynamic>{};
    if (canSeeStats) {
      final cached = profile['publicStats'];
      if (cached is Map<String, dynamic>) {
        publicStats = cached;
      } else if (leaderboard['publicStats'] is Map) {
        publicStats = Map<String, dynamic>.from(leaderboard['publicStats'] as Map);
      } else {
        final rawStats = appData['stats'];
        if (rawStats is Map<String, dynamic>) {
          publicStats = _buildPublicStatsSnapshotFromRaw(rawStats);
        }
      }
    }

    final displayNameRaw =
        (profile['displayName'] ?? leaderboard['displayName'] ?? appData['displayName'] ?? 'User').toString().trim();

    return <String, dynamic>{
      'uid': uid,
      'displayName': displayNameRaw.isEmpty ? 'User' : displayNameRaw,
      'photoUrl': (profile['photoUrl'] ?? leaderboard['photoUrl'] ?? '').toString(),
      'photoData': (profile['photoData'] ?? leaderboard['photoData'] ?? '').toString(),
      'aboutMe': (profile['aboutMe'] ?? leaderboard['aboutMe'] ?? '').toString(),
      'shareResults': allow,
      'canSeeStats': canSeeStats,
      'publicStats': publicStats,
      'isCreator': profile['isCreator'] == true,
    };
  }

  Future<Map<String, dynamic>> buildLocalPublicStatsSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    return _buildPublicStatsSnapshot(prefs);
  }

  DocumentReference<Map<String, dynamic>> _profileDoc(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  Future<Map<String, dynamic>> _fetchLeaderboardProfileHints(String uid) async {
    final now = DateTime.now();
    final dayKey =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final monthKey = '${now.year}${now.month.toString().padLeft(2, '0')}';
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final yearStart = DateTime(monday.year, 1, 1);
    final week = ((monday.difference(yearStart).inDays) / 7).floor() + 1;
    final weekKey = '${monday.year}W${week.toString().padLeft(2, '0')}';

    final boards = <(String, String)>[
      ('alltime', 'global'),
      ('daily', dayKey),
      ('weekly', weekKey),
      ('monthly', monthKey),
    ];

    final merged = <String, dynamic>{};
    for (final board in boards) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('leaderboards')
            .doc(board.$1)
            .collection(board.$2)
            .doc(uid)
            .get()
            .timeout(_kCloudOpTimeout);
        if (!snap.exists) continue;
        final row = snap.data() ?? <String, dynamic>{};
        for (final key in const [
          'displayName',
          'photoUrl',
          'photoData',
          'aboutMe',
          'shareResults',
          'publicStats',
        ]) {
          final value = row[key];
          if (value == null) continue;
          if (value is String && value.trim().isEmpty) continue;
          if (merged[key] == null ||
              (merged[key] is String && (merged[key] as String).trim().isEmpty)) {
            merged[key] = value;
          }
        }
      } catch (_) {}
    }
    return merged;
  }

  Map<String, dynamic> _leaderboardProfilePatch() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final patch = <String, dynamic>{
      'displayName': accountTitle(),
      'aboutMe': aboutMe.value,
      'updatedAtMs': nowMs,
      'lastSeenMs': nowMs,
      if (AppCreator.isCurrentUser) 'isCreator': true,
    };
    final url = (photoUrl.value ?? '').trim();
    final bytes = photoBytes.value;
    if (bytes != null && bytes.isNotEmpty) {
      final b64 = base64Encode(bytes);
      if (b64.length <= 280000) {
        patch['photoData'] = b64;
        patch['photoUrl'] = '';
        return patch;
      }
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      patch['photoUrl'] = url;
    }
    return patch;
  }

  Future<void> _syncLeaderboardProfileMetadata(String uid) async {
    if (!_firebaseReady) return;
    final patch = _leaderboardProfilePatch();
    final now = DateTime.now();
    final dayKey =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final monthKey = '${now.year}${now.month.toString().padLeft(2, '0')}';
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final yearStart = DateTime(monday.year, 1, 1);
    final week = ((monday.difference(yearStart).inDays) / 7).floor() + 1;
    final weekKey = '${monday.year}W${week.toString().padLeft(2, '0')}';

    final refs = [
      FirebaseFirestore.instance
          .collection('leaderboards')
          .doc('alltime')
          .collection('global')
          .doc(uid),
      FirebaseFirestore.instance
          .collection('leaderboards')
          .doc('daily')
          .collection(dayKey)
          .doc(uid),
      FirebaseFirestore.instance
          .collection('leaderboards')
          .doc('weekly')
          .collection(weekKey)
          .doc(uid),
      FirebaseFirestore.instance
          .collection('leaderboards')
          .doc('monthly')
          .collection(monthKey)
          .doc(uid),
    ];

    for (final ref in refs) {
      try {
        final snap = await ref.get().timeout(_kCloudOpTimeout);
        if (!snap.exists) continue;
        await ref.set(patch, SetOptions(merge: true)).timeout(_kCloudOpTimeout);
      } catch (_) {}
    }
  }

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

  Future<void> _setAuthScreenRequired(bool value) async {
    authScreenRequired.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAuthScreenRequired, value);
  }

  Future<void> _resetLocalAccountData() async {
    await ProgressService.instance.resetLocalProgress();
    await QuestService.instance.resetLocalQuests();
    await TrainingHistoryService.instance.removeAllLocal();
    await ProfileSessionService.instance.removeAllLocal();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('leaderboard_pending_points_v1');

    const modes = ['standard', 'binary', 'words', 'images', 'cards', 'faces'];
    for (final mode in modes) {
      await prefs.remove('best_score_$mode');
      await prefs.remove('total_games_$mode');
      await prefs.remove('avg_percentage_$mode');
      await prefs.remove('best_avg_ms_per_el_$mode');
      await prefs.remove('game_history_$mode');
      await prefs.remove('training_history_$mode');
    }
  }

  bool _cloudQuestPayloadWouldWipeDailyWeekly(Map<String, dynamic> raw) {
    final dq = raw['dailyQuests'];
    final wq = raw['weeklyQuests'];
    final dailyEmpty = dq is! List || dq.isEmpty;
    final weeklyEmpty = wq is! List || wq.isEmpty;
    final local = QuestService.instance.state.value;
    final localHadBoardQuests =
        local.dailyQuests.isNotEmpty || local.weeklyQuests.isNotEmpty;
    return dailyEmpty && weeklyEmpty && localHadBoardQuests;
  }

  Map<String, dynamic> _mergeStatsWithExisting(
    SharedPreferences prefs,
    Map<String, dynamic> cloud,
  ) {
    final local = _readStats(prefs);
    final keys = {...local.keys, ...cloud.keys};
    final out = <String, dynamic>{};
    for (final key in keys) {
      final l = local[key];
      final c = cloud[key];
      if (key.startsWith('game_history_')) {
        final lList = l is List ? l.map((e) => e.toString()).toList() : <String>[];
        final cList = c is List ? c.map((e) => e.toString()).toList() : <String>[];
        out[key] = cList.length >= lList.length ? cList : lList;
        continue;
      }
      if (c == null) {
        if (l != null) out[key] = l;
        continue;
      }
      if (l == null) {
        out[key] = c;
        continue;
      }
      if (c is int && l is int) {
        out[key] = max(c, l);
      } else if (c is double && l is double) {
        out[key] = max(c, l);
      } else if (c is num && l is num) {
        out[key] = max(c.toDouble(), l.toDouble());
      } else if (c is String && l is String) {
        out[key] = c.isNotEmpty ? c : l;
      } else {
        out[key] = c;
      }
    }
    return out;
  }

  Map<String, dynamic> _readStats(SharedPreferences prefs) {
    final out = <String, dynamic>{};

    const modes = ['standard', 'binary', 'words', 'images', 'cards', 'faces'];
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

  Map<String, dynamic> _buildPublicStatsSnapshot(SharedPreferences prefs) {
    return PublicStatsScoring.buildPublicStatsSnapshot(prefs);
  }

  Map<String, dynamic> _buildPublicStatsSnapshotFromRaw(Map<String, dynamic> raw) {
    // Legacy path when only cloud stats payload is available (no training_history in raw).
    const modes = PublicStatsScoring.modes;
    final out = <String, dynamic>{};
    for (final mode in modes) {
      final historyKey = 'game_history_$mode';
      final history = (raw[historyKey] is List)
          ? (raw[historyKey] as List).map((e) => e.toString()).toList(growable: false)
          : const <String>[];
      final sessions = <SessionRecord>[];
      for (final item in history) {
        try {
          final m = jsonDecode(item) as Map<String, dynamic>;
          sessions.add(PublicStatsScoring.recordFromCompact(mode, m));
        } catch (_) {}
      }
      out[mode] = PublicStatsScoring.buildModeStats(sessions: sessions);
    }
    return out;
  }
}
