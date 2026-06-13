part of 'package:flutter_application_1/recovered_app.dart';

const String _kPrefsPaletteIndex = 'app_palette_index';
const String _kPrefsLanguage = 'app_language';
const String _kPrefsBlackSuitAlwaysWhite = 'cards_black_suit_always_white';
const String _kPrefsNumberDisplayDirection = 'number_display_direction_v1';
const String _kPrefsCardsShuffledDeck = 'cards_shuffled_deck_v1';

enum NumberDisplayDirection { topToBottom, leftToRight, bottomToTop }

final ValueNotifier<bool> blackSuitAlwaysWhite = ValueNotifier(false);
final ValueNotifier<NumberDisplayDirection> numberDisplayDirection =
    ValueNotifier(NumberDisplayDirection.topToBottom);

Future<void> persistLanguage(AppLanguage lang) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kPrefsLanguage, lang.name);
  unawaited(CloudSyncService.instance.enqueueSync());
}

Future<void> persistPaletteIndex(int index) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_kPrefsPaletteIndex, index);
  unawaited(CloudSyncService.instance.enqueueSync());
}

Future<void> persistBlackSuitAlwaysWhite(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kPrefsBlackSuitAlwaysWhite, value);
  blackSuitAlwaysWhite.value = value;
}

Future<void> persistNumberDisplayDirection(NumberDisplayDirection direction) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kPrefsNumberDisplayDirection, direction.name);
  numberDisplayDirection.value = direction;
}

Future<void> requestMediaPermissions() async {
  if (kIsWeb) return;
  if (defaultTargetPlatform == TargetPlatform.android) {
    final storage = await Permission.storage.status;
    if (storage.isDenied) {
      await Permission.storage.request();
    }
    final photos = await Permission.photos.status;
    if (photos.isDenied || photos.isLimited) {
      await Permission.photos.request();
    }
  } else if (defaultTargetPlatform == TargetPlatform.iOS) {
    await Permission.photos.request();
  }
}

Future<bool> initializeFirebaseSafely() async {
  if (Firebase.apps.isNotEmpty) return true;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 8));
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
      );
    } catch (_) {
      // Some platforms/Web may not accept settings here; reads still work online.
    }
    return true;
  } catch (_) {
    return Firebase.apps.isNotEmpty;
  }
}

void startFirebaseRetryIfNeeded() {
  Timer? retryTimer;
  retryTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
    final ready = await initializeFirebaseSafely();
    if (!ready) return;
    try {
      await CloudSyncService.instance
          .init(firebaseReady: true)
          .timeout(const Duration(seconds: 8));
      LeaderboardService.instance.startPendingPointsSync();
      retryTimer?.cancel();
    } catch (_) {}
  });
}

Future<void> initializeOnlineServicesAfterStartup() async {
  if (kIsWeb) return;
  final firebaseReady = await initializeFirebaseSafely();
  if (firebaseReady) {
    try {
      await CloudSyncService.instance
          .init(firebaseReady: true)
          .timeout(const Duration(seconds: 8));
      LeaderboardService.instance.startPendingPointsSync();
    } catch (_) {
      startFirebaseRetryIfNeeded();
    }
  } else {
    startFirebaseRetryIfNeeded();
  }

  try {
    await SmartNotificationService.instance
        .init(firebaseReady: firebaseReady)
        .timeout(const Duration(seconds: 8));
  } catch (_) {
    // Notifications must never block app startup in release builds.
  }
}
