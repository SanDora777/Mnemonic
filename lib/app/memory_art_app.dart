part of 'package:flutter_application_1/recovered_app.dart';

class MemoryArtApp extends StatelessWidget {
  const MemoryArtApp({super.key});

  Color _onAccent(Color accent) {
    return accent.computeLuminance() > 0.55 ? const Color(0xFF111111) : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, _, __) {
        return ValueListenableBuilder<AppPalette>(
          valueListenable: appPalette,
          builder: (context, palette, _) {
            final isLight = palette.background.computeLuminance() > 0.5;
            final primaryText = isLight ? const Color(0xFF1F2933) : Colors.white;
            final secondaryText = isLight ? const Color(0xFF52606D) : Colors.white70;
            final onAccent = _onAccent(palette.accent);
            final colorScheme = isLight
                ? ColorScheme.light(
                    primary: palette.accent,
                    secondary: palette.accent,
                    surface: palette.surface,
                    onSurface: primaryText,
                    onPrimary: onAccent,
                    onSecondary: onAccent,
                    outline: palette.border,
                  )
                : ColorScheme.dark(
                    primary: palette.accent,
                    secondary: palette.accent,
                    surface: palette.surface,
                    onSurface: Colors.white,
                    onPrimary: onAccent,
                    onSecondary: onAccent,
                    outline: palette.border,
                  );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
                systemNavigationBarColor: palette.background,
                systemNavigationBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
              ));
            });
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              scrollBehavior: const WebDesktopScrollBehavior(),
              builder: (context, child) {
                return PaletteThemeTransition(
                  child: DuelInviteGlobalOverlay(
                    child: webDesktopShell(
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                );
              },
              title: 'Mnemonik',
              theme: ThemeData(
                brightness: isLight ? Brightness.light : Brightness.dark,
                scaffoldBackgroundColor: palette.background,
                primaryColor: palette.accent,
                colorScheme: colorScheme,
                fontFamily: 'Roboto',
                textTheme: TextTheme(
                  displayLarge: TextStyle(color: primaryText),
                  displayMedium: TextStyle(color: primaryText),
                  displaySmall: TextStyle(color: primaryText),
                  headlineLarge: TextStyle(color: primaryText),
                  headlineMedium: TextStyle(color: primaryText),
                  headlineSmall: TextStyle(color: primaryText),
                  titleLarge: TextStyle(color: primaryText),
                  titleMedium: TextStyle(color: primaryText),
                  titleSmall: TextStyle(color: primaryText),
                  bodyLarge: TextStyle(color: primaryText),
                  bodyMedium: TextStyle(color: secondaryText),
                  bodySmall: TextStyle(color: secondaryText),
                  labelLarge: TextStyle(color: primaryText),
                  labelMedium: TextStyle(color: secondaryText),
                  labelSmall: TextStyle(color: secondaryText),
                ),
              ),
              // Do not key [home] by language — that disposes [AppOnlineServicesHost]
              // and cuts background music. [appLanguage] already rebuilds UI via listeners.
              home: const AuthGate(),
            );
          },
        );
      }
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: CloudSyncService.instance.authScreenRequired,
      builder: (context, required, _) {
        if (required) {
          return const AuthScreen();
        }

        // The memory trainer must stay fully usable offline. Firebase may be
        // initialized while the device has no internet, so requiring an auth user
        // on first launch can trap the app on a sign-in screen where guest sign-in
        // also needs network. Explicit sign-out still returns to AuthScreen.
        return ValueListenableBuilder<User?>(
          valueListenable: CloudSyncService.instance.user,
          builder: (context, user, _) {
            if (user != null &&
                user.email != null &&
                user.email!.isNotEmpty &&
                !user.emailVerified) {
              return EmailVerificationScreen(email: user.email!);
            }
            return const AppOnlineServicesHost(
              child: MainMenuScreen(),
            );
          },
        );
      },
    );
  }
}

