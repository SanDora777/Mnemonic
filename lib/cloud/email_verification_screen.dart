import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/core/ui_feedback.dart';
import '../recovered_app.dart' show appAccentColor, appLanguage, appPalette, AppLanguage;
import 'cloud_sync_service.dart';
import 'email_auth_policy.dart';

enum _VerifyMode { otp, link }

/// Full-screen step: enter the 6-digit code sent to [email], or confirm via
/// Firebase verification link when SMTP is not configured on the server.
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key, required this.email});

  final String email;

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final TextEditingController _codeCtrl = TextEditingController();
  final FocusNode _codeFocus = FocusNode();
  Timer? _resendTimer;
  int _resendSec = 0;
  bool _busy = false;
  bool _initialSendDone = false;
  _VerifyMode _mode = _VerifyMode.otp;
  String? _error;
  String? _info;

  String get _lang => appLanguage.value.name;

  @override
  void initState() {
    super.initState();
    final pendingError = CloudSyncService.instance.lastError.value;
    if (pendingError != null && pendingError.isNotEmpty) {
      _error = pendingError;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendInitialCode());
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _codeCtrl.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  void _startResendCooldown(int seconds) {
    _resendTimer?.cancel();
    setState(() => _resendSec = seconds);
    if (seconds <= 0) return;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendSec -= 1;
        if (_resendSec <= 0) t.cancel();
      });
    });
  }

  String _t(String ru, String en, String de) {
    switch (appLanguage.value) {
      case AppLanguage.en:
        return en;
      case AppLanguage.de:
        return de;
      case AppLanguage.ru:
        return ru;
    }
  }

  String _maskedEmail() {
    final e = widget.email;
    final at = e.indexOf('@');
    if (at <= 1) return e;
    return '${e[0]}***${e.substring(at)}';
  }

  Future<void> _sendInitialCode() async {
    if (_initialSendDone || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
      _info = EmailAuthPolicy.sendingCodeHint(_lang);
    });
    final ok = await CloudSyncService.instance.sendEmailVerificationCode(
      lang: _lang,
      allowWhileBusy: true,
      showSuccessInfo: false,
    );
    if (!mounted) return;
    final authInfo = CloudSyncService.instance.lastAuthInfo.value ?? '';
    final linkMode = authInfo.contains('ссылк') ||
        authInfo.contains('link') ||
        authInfo.contains('Link');
    setState(() {
      _busy = false;
      _initialSendDone = true;
      _mode = linkMode ? _VerifyMode.link : _VerifyMode.otp;
      if (ok) {
        _error = null;
        _info = linkMode
            ? EmailAuthPolicy.verificationLinkSent(_lang)
            : '${EmailAuthPolicy.verificationResent(_lang)}. ${EmailAuthPolicy.checkSpamHint(_lang)}';
        _startResendCooldown(60);
      } else {
        _info = null;
        _error = CloudSyncService.instance.lastError.value ??
            _t(
              'Не удалось отправить код. Проверь интернет и попробуй снова',
              'Could not send the code. Check your connection and try again',
              'Code konnte nicht gesendet werden. Verbindung prüfen',
            );
      }
    });
  }

  Future<void> _resend() async {
    if (_busy || _resendSec > 0) return;
    setState(() {
      _busy = true;
      _error = null;
      _info = EmailAuthPolicy.sendingCodeHint(_lang);
    });
    final ok = await CloudSyncService.instance.sendEmailVerificationCode(lang: _lang);
    if (!mounted) return;
    final authInfo = CloudSyncService.instance.lastAuthInfo.value ?? '';
    final linkMode = authInfo.contains('ссылк') ||
        authInfo.contains('link') ||
        authInfo.contains('Link');
    setState(() {
      _busy = false;
      _mode = linkMode ? _VerifyMode.link : _VerifyMode.otp;
      if (ok) {
        _info = linkMode
            ? EmailAuthPolicy.verificationLinkSent(_lang)
            : '${EmailAuthPolicy.verificationResent(_lang)}. ${EmailAuthPolicy.checkSpamHint(_lang)}';
        _startResendCooldown(60);
      } else {
        _info = null;
        _error = CloudSyncService.instance.lastError.value;
      }
    });
  }

  Future<void> _verify() async {
    if (_busy) return;
    if (_mode == _VerifyMode.link) {
      setState(() {
        _busy = true;
        _error = null;
        _info = null;
      });
      final verified = await CloudSyncService.instance.refreshEmailVerifiedStatus();
      if (!mounted) return;
      if (verified) {
        appHaptic(UiClickSound.bright);
        return;
      }
      setState(() {
        _busy = false;
        _error = _t(
          'Email ещё не подтверждён. Открой письмо и нажми ссылку',
          'Email not verified yet. Open the email and tap the link',
          'E-Mail noch nicht bestätigt. Link in der E-Mail öffnen',
        );
      });
      return;
    }

    final code = _codeCtrl.text.trim();
    final hint = EmailAuthPolicy.validateOtpCode(code, _lang);
    if (hint != null) {
      setState(() => _error = hint);
      return;
    }
    appHaptic(UiClickSound.soft);
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    final ok = await CloudSyncService.instance.verifyEmailWithCode(
      code: code,
      lang: _lang,
    );
    if (!mounted) return;
    if (ok) {
      appHaptic(UiClickSound.bright);
      return;
    }
    setState(() {
      _busy = false;
      _error = CloudSyncService.instance.lastError.value ??
          _t('Не удалось подтвердить', 'Verification failed', 'Bestätigung fehlgeschlagen');
    });
  }

  Future<void> _signOut() async {
    await CloudSyncService.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final sending = _busy && !_initialSendDone;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Icon(Icons.mark_email_read_outlined, size: 48, color: accent.withOpacity(0.9)),
              const SizedBox(height: 20),
              Text(
                _t('Подтверди почту', 'Verify your email', 'E-Mail bestätigen'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                sending
                    ? _t(
                        'Отправляем код на ${_maskedEmail()}…',
                        'Sending a code to ${_maskedEmail()}…',
                        'Code wird an ${_maskedEmail()} gesendet…',
                      )
                    : _mode == _VerifyMode.link
                        ? _t(
                            'Мы отправили ссылку на ${_maskedEmail()}. Открой письмо и нажми ссылку.',
                            'We sent a link to ${_maskedEmail()}. Open the email and tap the link.',
                            'Link an ${_maskedEmail()} gesendet. E-Mail öffnen und Link tippen.',
                          )
                        : _initialSendDone
                            ? _t(
                                '6-значный код отправлен на ${_maskedEmail()}. Введи его ниже.',
                                'A 6-digit code was sent to ${_maskedEmail()}. Enter it below.',
                                '6-stelliger Code an ${_maskedEmail()} gesendet.',
                              )
                            : _t(
                                'Код будет отправлен на ${_maskedEmail()}.',
                                'A code will be sent to ${_maskedEmail()}.',
                                'Code wird an ${_maskedEmail()} gesendet.',
                              ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onSurface.withOpacity(0.65),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              if (_mode == _VerifyMode.otp) ...[
                const SizedBox(height: 28),
                TextField(
                  controller: _codeCtrl,
                  focusNode: _codeFocus,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  enabled: !sending,
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 12,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '000000',
                    hintStyle: TextStyle(
                      color: onSurface.withOpacity(0.2),
                      letterSpacing: 12,
                    ),
                    filled: true,
                    fillColor: palette.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: palette.border.withOpacity(0.4)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: palette.border.withOpacity(0.4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: accent, width: 1.5),
                    ),
                  ),
                  onSubmitted: (_) => _verify(),
                ),
              ] else ...[
                const SizedBox(height: 28),
                Icon(Icons.link, size: 40, color: accent.withOpacity(0.85)),
              ],
              if (_info != null) ...[
                const SizedBox(height: 10),
                Text(
                  _info!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: accent.withOpacity(0.95), fontSize: 12),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFFF6E6E), fontSize: 12),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: (_busy || sending) ? null : _verify,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _busy
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black.withOpacity(0.7),
                        ),
                      )
                    : Text(
                        _mode == _VerifyMode.link
                            ? _t('Проверить', 'Check', 'Prüfen')
                            : _t('Подтвердить', 'Confirm', 'Bestätigen'),
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.85),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: (_busy || _resendSec > 0 || sending) ? null : _resend,
                child: Text(
                  _resendSec > 0
                      ? _t(
                          'Отправить снова ($_resendSec с)',
                          'Resend in ${_resendSec}s',
                          'Erneut in ${_resendSec}s',
                        )
                      : _mode == _VerifyMode.link
                          ? _t('Отправить ссылку снова', 'Resend link', 'Link erneut senden')
                          : _t('Отправить код снова', 'Resend code', 'Code erneut senden'),
                  style: TextStyle(
                    color: _resendSec > 0 ? onSurface.withOpacity(0.35) : accent,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _busy ? null : _signOut,
                child: Text(
                  _t('Выйти и сменить аккаунт', 'Sign out and use another account', 'Abmelden'),
                  style: TextStyle(color: onSurface.withOpacity(0.45), fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
