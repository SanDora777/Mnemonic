part of 'package:flutter_application_1/recovered_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await loadAudioPreferences(prefs);
  await loadHapticPreference(prefs);
  final audioPrepare = Future.wait<void>([
    AppBackgroundMusic.instance.prepare(),
    AppUiSounds.instance.prepare(),
  ]);
  await ProgressService.instance.init();
  await ProgressService.instance.onAppOpened();
  await WebKeyboardManager.instance.ensureLoaded();
  await PremiumService.instance.init();
  await ProfileSessionService.instance.loadSessions();
  await QuestService.instance.init();
  await CloudSyncService.instance.init(firebaseReady: false);
  final isDesktopDebug = !kReleaseMode &&
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);
  if (isDesktopDebug) {
    // Force auth-first startup on desktop debug only when Firebase is available.
    final firebaseReady = await initializeFirebaseSafely();
    await CloudSyncService.instance.init(firebaseReady: firebaseReady);
    CloudSyncService.instance.authScreenRequired.value = firebaseReady;
  }
  
  // Загрузка темы
  final idx = prefs.getInt(_kPrefsPaletteIndex) ?? 0;
  final safeIdx = idx.clamp(0, appPalettes.length - 1);
  appPalette.value = appPalettes[safeIdx];
  appAccentColor.value = appPalettes[safeIdx].accent;

  // Загрузка языка
  final langStr = prefs.getString(_kPrefsLanguage) ?? 'ru';
  appLanguage.value = AppLanguage.values.firstWhere(
    (e) => e.name == langStr, 
    orElse: () => AppLanguage.ru,
  );
  blackSuitAlwaysWhite.value = prefs.getBool(_kPrefsBlackSuitAlwaysWhite) ?? false;
  final savedDirection = prefs.getString(_kPrefsNumberDisplayDirection);
  numberDisplayDirection.value = NumberDisplayDirection.values.firstWhere(
    (e) => e.name == savedDirection,
    orElse: () => NumberDisplayDirection.topToBottom,
  );

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: appPalettes[safeIdx].background,
  ));
  await audioPrepare;
  runApp(const MemoryArtApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(initializeOnlineServicesAfterStartup());
    unawaited(requestMediaPermissions());
  });
}
