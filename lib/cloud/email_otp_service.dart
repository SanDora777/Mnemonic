import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'email_auth_policy.dart';

/// Sends and verifies 6-digit email codes via Firebase Cloud Functions.
class EmailOtpService {
  EmailOtpService._();
  static final EmailOtpService instance = EmailOtpService._();

  static FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'europe-west1');

  Future<EmailOtpSendResult> sendCode({String lang = 'ru'}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return EmailOtpSendResult.failure(
        EmailAuthPolicy.signInRequiredHint(lang),
      );
    }
    try {
      final callable = _functions.httpsCallable('sendEmailVerificationCode');
      final result = await callable.call<Map<String, dynamic>>({'lang': lang});
      final data = result.data;
      final expires = data['expiresInSec'];
      return EmailOtpSendResult.success(
        expiresInSec: expires is int ? expires : 600,
      );
    } on FirebaseFunctionsException catch (e) {
      return EmailOtpSendResult.failure(
        EmailAuthPolicy.friendlyFunctionsError(e.code, e.message, lang),
      );
    } catch (e) {
      return EmailOtpSendResult.failure(e.toString());
    }
  }

  Future<EmailOtpVerifyResult> verifyCode({
    required String code,
    String lang = 'ru',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return EmailOtpVerifyResult.failure(
        EmailAuthPolicy.signInRequiredHint(lang),
      );
    }
    final trimmed = code.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(trimmed)) {
      return EmailOtpVerifyResult.failure(
        EmailAuthPolicy.invalidOtpHint(lang),
      );
    }
    try {
      final callable = _functions.httpsCallable('verifyEmailVerificationCode');
      await callable.call<Map<String, dynamic>>({'code': trimmed});
      await user.reload();
      return EmailOtpVerifyResult.success();
    } on FirebaseFunctionsException catch (e) {
      return EmailOtpVerifyResult.failure(
        EmailAuthPolicy.friendlyFunctionsError(e.code, e.message, lang),
      );
    } catch (e) {
      return EmailOtpVerifyResult.failure(e.toString());
    }
  }
}

class EmailOtpSendResult {
  const EmailOtpSendResult._({this.error, this.expiresInSec});

  final String? error;
  final int? expiresInSec;

  bool get ok => error == null;

  factory EmailOtpSendResult.success({required int expiresInSec}) =>
      EmailOtpSendResult._(expiresInSec: expiresInSec);

  factory EmailOtpSendResult.failure(String message) =>
      EmailOtpSendResult._(error: message);
}

class EmailOtpVerifyResult {
  const EmailOtpVerifyResult._({this.error});

  final String? error;

  bool get ok => error == null;

  factory EmailOtpVerifyResult.success() => const EmailOtpVerifyResult._();

  factory EmailOtpVerifyResult.failure(String message) =>
      EmailOtpVerifyResult._(error: message);
}
