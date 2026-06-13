part of 'package:flutter_application_1/recovered_app.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const IgnorePointer(child: AnimatedBackground()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: CloudSyncService.instance.isBusy,
                    builder: (context, busy, _) {
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 550),
                        curve: Curves.easeOutCubic,
                        builder: (context, t, child) {
                          final y = (1 - t) * 18;
                          return Opacity(
                            opacity: t,
                            child: Transform.translate(
                              offset: Offset(0, y),
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: accent.withOpacity(0.4)),
                          ),
                          child: Icon(Icons.psychology_alt_rounded, color: accent, size: 46),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          AppTexts.get('auth_welcome_title'),
                          style: TextStyle(
                            color: onSurface,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          AppTexts.get('auth_welcome_subtitle'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: onSurface.withOpacity(0.65),
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 30),
                        _authButton(
                          context,
                          icon: Icons.alternate_email_rounded,
                          label: AppTexts.get('cloud_sign_in'),
                          enabled: !busy,
                          onTap: () => showEmailAuthBottomSheet(context),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          AppTexts.get('auth_or'),
                          style: TextStyle(color: onSurface.withOpacity(0.35), fontSize: 12),
                        ),
                        const SizedBox(height: 14),
                        _authButton(
                          context,
                          icon: Icons.person_outline_rounded,
                          label: AppTexts.get('auth_continue_guest'),
                          enabled: !busy,
                          onTap: () => confirmAnonymousSignIn(context),
                          outlined: true,
                        ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _authButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool enabled,
    required Future<void> Function() onTap,
    bool outlined = false,
  }) {
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: enabled ? () async => onTap() : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: outlined ? appPalette.value.surface : accent.withOpacity(0.16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: outlined ? appPalette.value.border.withOpacity(0.5) : accent.withOpacity(0.45)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: enabled ? onSurface : onSurface.withOpacity(0.35)),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: enabled ? onSurface : onSurface.withOpacity(0.35),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

