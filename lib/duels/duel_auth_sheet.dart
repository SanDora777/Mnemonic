import 'package:flutter/material.dart';
import '../app/core/ui_feedback.dart';
import '../cloud/cloud_sync_service.dart';
import '../cloud/email_auth_policy.dart';
import '../cloud/email_verification_screen.dart';
import '../recovered_app.dart'
    show
        appPalette,
        appAccentColor,
        appLanguage,
        AppLanguage,
        initializeFirebaseSafely,
        showForgotPasswordDialog;

enum _AuthTab { signIn, signUp }

String _t(Map<AppLanguage, String> map) =>
    map[appLanguage.value] ?? map[AppLanguage.ru] ?? '';

/// Returns true if the user is signed in after the sheet closes.
Future<bool> showDuelAuthSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (ctx) => const _DuelAuthSheet(),
  );
  return result ?? CloudSyncService.instance.isSignedIn;
}

class _DuelAuthSheet extends StatefulWidget {
  const _DuelAuthSheet();

  @override
  State<_DuelAuthSheet> createState() => _DuelAuthSheetState();
}

class _DuelAuthSheetState extends State<_DuelAuthSheet> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  _AuthTab _tab = _AuthTab.signIn;
  bool _busy = false;
  String? _error;
  bool _obscure = true;
  bool _obscureConfirm = true;

  String get _lang => appLanguage.value.name;

  Future<bool> _prepareAuth() async {
    try {
      final ready = await initializeFirebaseSafely();
      await CloudSyncService.instance.init(firebaseReady: ready);
      return ready;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _googleAuth() async {
    if (_busy) return;
    appHaptic(UiClickSound.soft);
    setState(() {
      _busy = true;
      _error = null;
    });
    final ready = CloudSyncService.instance.firebaseReady || await _prepareAuth();
    if (!ready) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _t(const {
          AppLanguage.ru: 'Firebase не готов. Проверь интернет и конфиг проекта',
          AppLanguage.en: 'Firebase is not ready. Check internet and project config',
          AppLanguage.de: 'Firebase nicht bereit. Internet und Projektkonfiguration prüfen',
        });
      });
      return;
    }
    try {
      await CloudSyncService.instance.signInWithGoogle();
    } catch (e) {
      _error = e.toString();
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (CloudSyncService.instance.isSignedIn) {
      Navigator.of(context).pop(true);
    } else {
      final cloudErr = CloudSyncService.instance.lastError.value;
      if (cloudErr != null && cloudErr.isNotEmpty) {
        setState(() => _error = cloudErr);
      }
    }
  }

  Future<void> _emailAuth() async {
    if (_busy) return;
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final emailErr = EmailAuthPolicy.validateEmail(email, _lang);
    if (emailErr != null) {
      setState(() => _error = emailErr);
      return;
    }
    final passErr = EmailAuthPolicy.validatePassword(pass, _lang);
    if (passErr != null) {
      setState(() => _error = passErr);
      return;
    }
    if (_tab == _AuthTab.signUp) {
      final confirmErr = EmailAuthPolicy.validatePasswordConfirm(pass, _confirmPassCtrl.text, _lang);
      if (confirmErr != null) {
        setState(() => _error = confirmErr);
        return;
      }
    }
    appHaptic(UiClickSound.soft);
    setState(() {
      _busy = true;
      _error = null;
    });
    final ready = CloudSyncService.instance.firebaseReady || await _prepareAuth();
    if (!ready) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _t(const {
          AppLanguage.ru: 'Firebase не готов. Проверь интернет и конфиг проекта',
          AppLanguage.en: 'Firebase is not ready. Check internet and project config',
          AppLanguage.de: 'Firebase nicht bereit. Internet und Projektkonfiguration prüfen',
        });
      });
      return;
    }
    CloudSyncService.instance.lastAuthInfo.value = null;
    try {
      if (_tab == _AuthTab.signIn) {
        await CloudSyncService.instance.signInWithEmail(
          email: email,
          password: pass,
          lang: _lang,
        );
      } else {
        final name = _nameCtrl.text.trim();
        await CloudSyncService.instance.registerWithEmail(
          email: email,
          password: pass,
          displayName: name.isEmpty ? null : name,
          lang: _lang,
        );
      }
    } catch (e) {
      _error = e.toString();
    }
    if (!mounted) return;
    setState(() => _busy = false);
    final cloudInfo = CloudSyncService.instance.lastAuthInfo.value;
    if (cloudInfo != null && cloudInfo.isNotEmpty) {
      setState(() => _error = cloudInfo);
      return;
    }
    final cloudErr = CloudSyncService.instance.lastError.value;
    if (CloudSyncService.instance.isSignedIn) {
      if (CloudSyncService.instance.needsEmailVerification) {
        final email = CloudSyncService.instance.user.value?.email;
        if (email != null && mounted) {
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => EmailVerificationScreen(email: email),
            ),
          );
        }
      }
      if (!mounted) return;
      if (CloudSyncService.instance.isSignedIn &&
          !CloudSyncService.instance.needsEmailVerification) {
        Navigator.of(context).pop(true);
      }
    } else if (cloudErr != null && cloudErr.isNotEmpty) {
      setState(() => _error = cloudErr);
    } else if (_error == null) {
      setState(() => _error = _t(const {
            AppLanguage.ru: 'Не удалось войти',
            AppLanguage.en: 'Sign-in failed',
            AppLanguage.de: 'Anmeldung fehlgeschlagen',
          }));
    }
  }

  Future<void> _guestAuth() async {
    if (_busy) return;
    final confirmed = await _showGuestWarning();
    if (!confirmed) return;
    appHaptic(UiClickSound.soft);
    setState(() {
      _busy = true;
      _error = null;
    });
    final ready = CloudSyncService.instance.firebaseReady || await _prepareAuth();
    if (!ready) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _t(const {
          AppLanguage.ru: 'Firebase не готов. Проверь интернет и конфиг проекта',
          AppLanguage.en: 'Firebase is not ready. Check internet and project config',
          AppLanguage.de: 'Firebase nicht bereit. Internet und Projektkonfiguration prüfen',
        });
      });
      return;
    }
    try {
      await CloudSyncService.instance.signInAnonymously();
    } catch (e) {
      _error = e.toString();
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (CloudSyncService.instance.isSignedIn) {
      Navigator.of(context).pop(true);
    } else {
      final cloudErr = CloudSyncService.instance.lastError.value;
      if (cloudErr != null && cloudErr.isNotEmpty) {
        setState(() => _error = cloudErr);
      }
    }
  }

  Future<bool> _showGuestWarning() async {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = appAccentColor.value;
    final palette = appPalette.value;
    final (title, body, cancelLabel, continueLabel) = switch (appLanguage.value) {
      AppLanguage.en => (
          'Guest mode notice',
          'If you uninstall the app, guest data may be permanently lost. Use Email sign-in to keep progress.',
          'Cancel',
          'Continue',
        ),
      AppLanguage.de => (
          'Hinweis zum Gastmodus',
          'Wenn du die App löschst, können Gastdaten dauerhaft verloren gehen. Mit E-Mail bleibt der Fortschritt erhalten.',
          'Abbrechen',
          'Fortfahren',
        ),
      AppLanguage.ru => (
          'Внимание: гостевой режим',
          'Если удалить приложение, данные гостевого аккаунта могут быть утеряны. Для сохранения прогресса используй Email.',
          'Отмена',
          'Продолжить',
        ),
    };

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withOpacity(0.45)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: onSurface, fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(body, style: TextStyle(color: onSurface.withOpacity(0.78), height: 1.35)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(cancelLabel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: accent),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(continueLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: palette.border.withOpacity(0.45)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: onSurface.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _t(const {
                  AppLanguage.ru: 'Войди, чтобы играть в дуэли',
                  AppLanguage.en: 'Sign in to play duels',
                  AppLanguage.de: 'Anmelden, um zu duellieren',
                }),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onSurface.withOpacity(0.92),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _t(const {
                  AppLanguage.ru: 'Email или гостевой вход — прогресс сохраняется в облаке',
                  AppLanguage.en: 'Email or guest sign-in — progress saved to the cloud',
                  AppLanguage.de: 'E-Mail oder Gast — Fortschritt wird in der Cloud gespeichert',
                }),
                textAlign: TextAlign.center,
                style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12),
              ),
              const SizedBox(height: 18),
              if (CloudSyncService.googleSignInEnabled) ...[
                _googleButton(palette: palette, onSurface: onSurface),
                const SizedBox(height: 10),
              ],
              _guestButton(onSurface: onSurface),
              const SizedBox(height: 14),
              _divider(onSurface),
              const SizedBox(height: 14),
              _tabsHeader(accent: accent, onSurface: onSurface, palette: palette),
              const SizedBox(height: 14),
              if (_tab == _AuthTab.signUp) ...[
                _input(
                  controller: _nameCtrl,
                  hint: _t(const {
                    AppLanguage.ru: 'Имя (необязательно)',
                    AppLanguage.en: 'Name (optional)',
                    AppLanguage.de: 'Name (optional)',
                  }),
                  icon: Icons.person_outline_rounded,
                  onSurface: onSurface,
                  palette: palette,
                ),
                const SizedBox(height: 10),
              ],
              _input(
                controller: _emailCtrl,
                hint: 'email@example.com',
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                onSurface: onSurface,
                palette: palette,
              ),
              const SizedBox(height: 10),
              _input(
                controller: _passCtrl,
                hint: _t(const {
                  AppLanguage.ru: 'Пароль',
                  AppLanguage.en: 'Password',
                  AppLanguage.de: 'Passwort',
                }),
                icon: Icons.lock_outline_rounded,
                obscure: _obscure,
                trailing: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                      size: 18, color: onSurface.withOpacity(0.55)),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                onSurface: onSurface,
                palette: palette,
              ),
              if (_tab == _AuthTab.signUp) ...[
                const SizedBox(height: 6),
                Text(
                  EmailAuthPolicy.passwordRequirementsHint(_lang),
                  style: TextStyle(color: onSurface.withOpacity(0.45), fontSize: 11),
                ),
                const SizedBox(height: 8),
                _input(
                  controller: _confirmPassCtrl,
                  hint: _t(const {
                    AppLanguage.ru: 'Повтор пароля',
                    AppLanguage.en: 'Confirm password',
                    AppLanguage.de: 'Passwort bestätigen',
                  }),
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscureConfirm,
                  trailing: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                      color: onSurface.withOpacity(0.55),
                    ),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  onSurface: onSurface,
                  palette: palette,
                ),
              ],
              if (_tab == _AuthTab.signIn) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _busy
                        ? null
                        : () => showForgotPasswordDialog(context, initialEmail: _emailCtrl.text),
                    child: Text(
                      _t(const {
                        AppLanguage.ru: 'Забыл пароль?',
                        AppLanguage.en: 'Forgot password?',
                        AppLanguage.de: 'Passwort vergessen?',
                      }),
                      style: TextStyle(color: accent.withOpacity(0.9), fontSize: 12),
                    ),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFFF6E6E), fontSize: 12),
                ),
              ],
              const SizedBox(height: 16),
              _primaryButton(
                label: _busy
                    ? '...'
                    : (_tab == _AuthTab.signIn
                        ? _t(const {
                            AppLanguage.ru: 'ВОЙТИ',
                            AppLanguage.en: 'SIGN IN',
                            AppLanguage.de: 'ANMELDEN',
                          })
                        : _t(const {
                            AppLanguage.ru: 'СОЗДАТЬ АККАУНТ',
                            AppLanguage.en: 'CREATE ACCOUNT',
                            AppLanguage.de: 'KONTO ERSTELLEN',
                          })),
                accent: accent,
                onTap: _busy ? null : _emailAuth,
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).maybePop(false),
                  child: Text(
                    _t(const {
                      AppLanguage.ru: 'Отмена',
                      AppLanguage.en: 'Cancel',
                      AppLanguage.de: 'Abbrechen',
                    }),
                    style: TextStyle(color: onSurface.withOpacity(0.5)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _guestButton({required Color onSurface}) {
    final accent = appAccentColor.value;
    final palette = appPalette.value;
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _busy ? null : _guestAuth,
        icon: Icon(Icons.person_outline_rounded, color: onSurface.withOpacity(0.86)),
        label: Text(
          _t(const {
            AppLanguage.ru: 'Войти как гость',
            AppLanguage.en: 'Continue as guest',
            AppLanguage.de: 'Als Gast fortfahren',
          }),
          style: TextStyle(
            color: onSurface.withOpacity(0.9),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: accent.withOpacity(0.45)),
          backgroundColor: palette.background.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _googleButton({required dynamic palette, required Color onSurface}) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: _busy ? null : _googleAuth,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: palette.card,
          border: Border.all(color: palette.border.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Text(
                'G',
                style: TextStyle(
                  color: Color(0xFF4285F4),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _t(const {
                AppLanguage.ru: 'Войти через Google',
                AppLanguage.en: 'Continue with Google',
                AppLanguage.de: 'Mit Google fortfahren',
              }),
              style: TextStyle(
                color: onSurface.withOpacity(0.92),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(Color onSurface) {
    return Row(
      children: [
        Expanded(child: Divider(color: onSurface.withOpacity(0.10), height: 1)),
        const SizedBox(width: 10),
        Text(
          _t(const {
            AppLanguage.ru: 'или email',
            AppLanguage.en: 'or email',
            AppLanguage.de: 'oder E-Mail',
          }),
          style: TextStyle(color: onSurface.withOpacity(0.4), fontSize: 11, letterSpacing: 1.2),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: onSurface.withOpacity(0.10), height: 1)),
      ],
    );
  }

  Widget _tabsHeader({
    required Color accent,
    required Color onSurface,
    required dynamic palette,
  }) {
    Widget tab(String label, _AuthTab value) {
      final selected = _tab == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() {
            _tab = value;
            _error = null;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: selected ? accent.withOpacity(0.12) : Colors.transparent,
              border: Border.all(
                color: selected ? accent.withOpacity(0.5) : Colors.transparent,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? accent : onSurface.withOpacity(0.55),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          tab(
            _t(const {
              AppLanguage.ru: 'ВХОД',
              AppLanguage.en: 'SIGN IN',
              AppLanguage.de: 'ANMELDEN',
            }),
            _AuthTab.signIn,
          ),
          tab(
            _t(const {
              AppLanguage.ru: 'РЕГИСТРАЦИЯ',
              AppLanguage.en: 'SIGN UP',
              AppLanguage.de: 'REGISTRIEREN',
            }),
            _AuthTab.signUp,
          ),
        ],
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color onSurface,
    required dynamic palette,
    bool obscure = false,
    Widget? trailing,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border.withOpacity(0.45)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(icon, size: 16, color: onSurface.withOpacity(0.55)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              keyboardType: keyboardType,
              style: TextStyle(color: onSurface.withOpacity(0.95), fontSize: 14),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(color: onSurface.withOpacity(0.3), fontSize: 14),
              ),
            ),
          ),
          if (trailing != null) trailing else const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required Color accent,
    required VoidCallback? onTap,
  }) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(colors: [accent.withOpacity(0.96), accent]),
            boxShadow: [
              BoxShadow(color: accent.withOpacity(0.3), blurRadius: 16),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.black.withOpacity(0.85),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
