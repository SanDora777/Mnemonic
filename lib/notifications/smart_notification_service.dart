import 'dart:convert';
import 'dart:math';

import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../cloud/cloud_sync_service.dart';
import '../progress/progress_service.dart';
import '../progress/user_progress.dart';

/// Android `res/raw/notification_alert.mp3` — creator broadcast pushes only.
const String kAndroidNotificationSound = 'notification_alert';

const String kBroadcastChannelId = 'mnemonik_broadcast';
const String kDailyChannelId = 'mnemonik_daily';
const String kStreakChannelId = 'mnemonik_streak';

const AndroidNotificationDetails _broadcastAndroidDetails =
    AndroidNotificationDetails(
  kBroadcastChannelId,
  'Сообщения Mneem',
  channelDescription: 'Новости и объявления от разработчика',
  importance: Importance.high,
  priority: Priority.high,
  sound: RawResourceAndroidNotificationSound(kAndroidNotificationSound),
  playSound: true,
);

/// System default notification sound — no custom asset.
const AndroidNotificationDetails _dailyAndroidDetails = AndroidNotificationDetails(
  kDailyChannelId,
  'Ежедневные напоминания',
  channelDescription: 'Спокойное напоминание о тренировке раз в день',
  importance: Importance.defaultImportance,
  priority: Priority.defaultPriority,
  playSound: true,
);

const AndroidNotificationDetails _streakAndroidDetails = AndroidNotificationDetails(
  kStreakChannelId,
  'Серия дней',
  channelDescription: 'Напоминание сохранить стрик',
  importance: Importance.defaultImportance,
  priority: Priority.defaultPriority,
  playSound: true,
);

const NotificationDetails _dailyNotificationDetails = NotificationDetails(
  android: _dailyAndroidDetails,
  iOS: DarwinNotificationDetails(presentSound: true),
);

const NotificationDetails _streakNotificationDetails = NotificationDetails(
  android: _streakAndroidDetails,
  iOS: DarwinNotificationDetails(presentSound: true),
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await SmartNotificationService.showRemotePush(message);
}

/// Local daily reminders + FCM topic pushes.
class SmartNotificationService {
  SmartNotificationService._();
  static final SmartNotificationService instance = SmartNotificationService._();

  static const String _kEnabled = 'smart_push_enabled_v1';
  static const String _kSessions = 'smart_push_sessions_history_v1';
  static const String _kBestPerMode = 'smart_push_best_per_mode_v1';
  static const String _kLastActiveAt = 'smart_push_last_active_at_v1';
  static const String _kStreakDays = 'smart_push_streak_days_v1';
  static const String _kDevTestDone = 'notif_dev_test_20260608_done';

  static const int _kDailyNotificationId = 90321;
  static const int _kRemoteNotificationId = 90322;
  static const int _kStreakNotificationId = 90323;
  static const int _kDevTestNotificationId = 90324;

  static const int _kDailyHour = 18;
  static const int _kDailyMinute = 0;
  static const int _kStreakHour = 19;
  static const int _kStreakMinute = 0;

  /// One-time developer test: 8 Jun 2026, 14:40 Europe/Berlin.
  static const int _kDevTestYear = 2026;
  static const int _kDevTestMonth = 6;
  static const int _kDevTestDay = 8;
  static const int _kDevTestHour = 14;
  static const int _kDevTestMinute = 40;

  static const String _kTitle = 'Mnemonik';
  static const String _kFcmTopicAllUsers = 'all_users';

  final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _firebaseReady = false;
  bool _timezoneReady = false;

  static Future<void> showRemotePush(RemoteMessage message) async {
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        _kTitle;
    final body =
        message.notification?.body ?? message.data['body']?.toString() ?? '';
    if (body.trim().isEmpty) return;

    final plugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    final android = plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          kBroadcastChannelId,
          'Сообщения Mneem',
          description: 'Новости и объявления от разработчика',
          importance: Importance.high,
          sound: RawResourceAndroidNotificationSound(kAndroidNotificationSound),
        ),
      );
    }

    await plugin.show(
      _kRemoteNotificationId,
      title,
      body,
      const NotificationDetails(
        android: _broadcastAndroidDetails,
        iOS: DarwinNotificationDetails(presentSound: true),
      ),
    );
  }

  static Future<void> showCreatorBroadcast({
    required String title,
    required String body,
  }) async {
    await showRemotePush(
      RemoteMessage(
        notification: RemoteNotification(title: title, body: body),
        data: <String, dynamic>{
          'type': 'creator_broadcast',
          'title': title,
          'body': body,
        },
      ),
    );
  }

  Future<void> init({required bool firebaseReady}) async {
    if (_initialized) return;
    _initialized = true;
    _firebaseReady = firebaseReady;

    final prefs = await SharedPreferences.getInstance();
    enabled.value = prefs.getBool(_kEnabled) ?? true;

    try {
      await _initTimezone();
      await _initLocalNotifications();
    } catch (_) {}

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    if (!kIsWeb && firebaseReady) {
      await _initFcm();
    }

    try {
      if (enabled.value) {
        await onAppOpened();
      } else {
        await _cancelAllLocalSchedules();
      }
    } catch (_) {}
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, value);
    enabled.value = value;
    try {
      if (!value) {
        await _cancelAllLocalSchedules();
        if (_firebaseReady) {
          await FirebaseMessaging.instance.unsubscribeFromTopic(_kFcmTopicAllUsers);
        }
        return;
      }
      if (_firebaseReady) {
        await _subscribeToBroadcastTopic();
      }
      await onAppOpened();
    } catch (_) {}
  }

  Future<void> onAppOpened() async {
    if (!enabled.value) return;
    final now = DateTime.now();
    await _updateLastActiveAt(now);
    await _syncUserProfileToFirestore();

    try {
      await _refreshLocalSchedules();
    } catch (e) {
      if (kDebugMode) debugPrint('Notification schedule failed: $e');
    }
  }

  Future<void> onTrainingCompleted({
    required String mode,
    required int score,
    DateTime? date,
  }) async {
    final now = date ?? DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final sessions = _loadSessionsFromPrefs(prefs);
    sessions.insert(0, <String, dynamic>{
      'date': now.toIso8601String(),
      'score': max(0, score),
      'mode': mode,
    });
    if (sessions.length > 120) {
      sessions.removeRange(120, sessions.length);
    }
    await prefs.setString(_kSessions, jsonEncode(sessions));

    final best = _loadBestPerModeFromPrefs(prefs);
    final currentBest = best[mode] ?? 0;
    if (score > currentBest) {
      best[mode] = score;
      await prefs.setString(_kBestPerMode, jsonEncode(best));
    }

    final streak = _calculateStreakDays(sessions, now);
    await prefs.setInt(_kStreakDays, streak);
    await _updateLastActiveAt(now);
    await _syncUserProfileToFirestore();

    try {
      await _local.cancel(_kStreakNotificationId);
      await _refreshLocalSchedules();
    } catch (_) {}
  }

  /// Legacy helper kept for Firestore sync payloads.
  String generateNotification(Map<String, dynamic> userData) {
    return _dailyReminderBody(DateTime.now());
  }

  Future<void> _initTimezone() async {
    tz.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Berlin'));
    }
    _timezoneReady = true;
  }

  Future<void> _initLocalNotifications() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _local.initialize(settings);

    final android = _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          kBroadcastChannelId,
          'Сообщения Mneem',
          description: 'Новости и объявления от разработчика',
          importance: Importance.high,
          sound: RawResourceAndroidNotificationSound(kAndroidNotificationSound),
        ),
      );
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          kDailyChannelId,
          'Ежедневные напоминания',
          description: 'Спокойное напоминание о тренировке',
          importance: Importance.defaultImportance,
          playSound: true,
        ),
      );
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          kStreakChannelId,
          'Серия дней',
          description: 'Напоминание сохранить стрик',
          importance: Importance.defaultImportance,
          playSound: true,
        ),
      );
    }
  }

  Future<void> _refreshLocalSchedules() async {
    if (!enabled.value || !_timezoneReady) return;
    if (!await _requestNotificationPermission()) return;

    final prefs = await SharedPreferences.getInstance();
    await _ensureDailyRepeat(prefs);
    await _scheduleStreakIfNeeded(prefs);
    await _scheduleDevTestOnce(prefs);
  }

  Future<void> _ensureDailyRepeat(SharedPreferences prefs) async {
    await _local.cancel(_kDailyNotificationId);
    final when = _nextLocalTime(_kDailyHour, _kDailyMinute);
    final body = _dailyReminderBody(when);

    try {
      await _local.zonedSchedule(
        _kDailyNotificationId,
        _kTitle,
        body,
        when,
        _dailyNotificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'daily',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Daily notification schedule failed: $e');
    }
  }

  Future<void> _scheduleStreakIfNeeded(SharedPreferences prefs) async {
    await _local.cancel(_kStreakNotificationId);

    final progress = ProgressService.instance.progress.value;
    if (progress.streak <= 0) return;

    final now = DateTime.now();
    if (progress.lastActiveDate != null &&
        UserProgress.isSameDay(progress.lastActiveDate!, now)) {
      return;
    }

    final when = _nextLocalTime(_kStreakHour, _kStreakMinute);
    if (when.difference(tz.TZDateTime.now(tz.local)).inMinutes < 2) {
      return;
    }

    final body = _streakReminderBody(progress.streak);
    try {
      await _local.zonedSchedule(
        _kStreakNotificationId,
        _kTitle,
        body,
        when,
        _streakNotificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'streak',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Streak notification schedule failed: $e');
    }
  }

  /// One-time test notification for 8 Jun 2026 at 14:40 Europe/Berlin.
  Future<void> _scheduleDevTestOnce(SharedPreferences prefs) async {
    if (prefs.getBool(_kDevTestDone) ?? false) return;

    final berlin = tz.getLocation('Europe/Berlin');
    final nowBerlin = tz.TZDateTime.now(berlin);
    final target = tz.TZDateTime(
      berlin,
      _kDevTestYear,
      _kDevTestMonth,
      _kDevTestDay,
      _kDevTestHour,
      _kDevTestMinute,
    );

    if (nowBerlin.year != _kDevTestYear ||
        nowBerlin.month != _kDevTestMonth ||
        nowBerlin.day != _kDevTestDay) {
      return;
    }

    if (nowBerlin.isAfter(target.add(const Duration(minutes: 5)))) {
      await prefs.setBool(_kDevTestDone, true);
      return;
    }

    if (!nowBerlin.isBefore(target)) {
      await prefs.setBool(_kDevTestDone, true);
      return;
    }

    await _local.cancel(_kDevTestNotificationId);
    try {
      await _local.zonedSchedule(
        _kDevTestNotificationId,
        _kTitle,
        'Тест: уведомления работают. Спокойное напоминание в 18:00 — каждый день.',
        target,
        _dailyNotificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'dev_test',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Dev test notification failed: $e');
    }
  }

  tz.TZDateTime _nextLocalTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  String _dailyReminderBody(DateTime date) {
    const messages = <String>[
      'Пару минут тренировки?',
      'Память любит регулярность. Загляни, когда будет удобно.',
      'Короткая сессия только для себя.',
      'Небольшая разминка для ума  в любой момент.',
      'Один тихий раунд  и день завершён с пользой.',
    ];
    return messages[date.day % messages.length];
  }

  String _streakReminderBody(int streakDays) {
    final n = max(1, streakDays);
    const templates = <String>[
      'Серия из {n} дней может прерваться. Один раунд  и огонёк снова твой.',
      'Стрик {n}  ещё не продлён сегодня. Пара минут, и серия в безопасности.',
      'Твоя серия {n} дней ждёт. Успей сохранить её до конца дня.',
    ];
    return templates[n % templates.length].replaceAll('{n}', '$n');
  }

  Future<void> _cancelAllLocalSchedules() async {
    await _local.cancel(_kDailyNotificationId);
    await _local.cancel(_kStreakNotificationId);
    await _local.cancel(_kDevTestNotificationId);
  }

  Future<bool> _requestNotificationPermission() async {
    if (kIsWeb) return false;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.status;
      if (status.isGranted) return true;
      final result = await Permission.notification.request();
      return result.isGranted;
    }

    if (_firebaseReady) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    }

    return true;
  }

  Future<void> _initFcm() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();
    await _saveFcmToken(token);
    FirebaseMessaging.instance.onTokenRefresh.listen(_saveFcmToken);
    FirebaseMessaging.onMessage.listen(showRemotePush);
    FirebaseMessaging.onMessageOpenedApp.listen((_) {});
  }

  Future<void> _subscribeToBroadcastTopic() async {
    if (!_firebaseReady || !enabled.value) return;
    if (!await _requestNotificationPermission()) return;
    try {
      await FirebaseMessaging.instance.subscribeToTopic(_kFcmTopicAllUsers);
    } catch (e) {
      if (kDebugMode) debugPrint('FCM topic subscribe failed: $e');
    }
  }

  Future<void> _saveFcmToken(String? token) async {
    if (token == null || !_firebaseReady) return;
    final uid = CloudSyncService.instance.user.value?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      <String, dynamic>{
        'fcm_token': token,
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      },
      SetOptions(merge: true),
    );
    await _subscribeToBroadcastTopic();
  }

  Future<void> _updateLastActiveAt(DateTime now) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastActiveAt, now.toIso8601String());
  }

  Map<String, dynamic> _buildUserData(SharedPreferences prefs, DateTime now) {
    final sessions = _loadSessionsFromPrefs(prefs);
    final bestPerMode = _loadBestPerModeFromPrefs(prefs);
    final lastIso = prefs.getString(_kLastActiveAt);
    final lastActive = DateTime.tryParse(lastIso ?? '') ?? now;
    final inactivityDays =
        _dateOnly(now).difference(_dateOnly(lastActive)).inDays.clamp(0, 9999);
    final streakDays = ProgressService.instance.progress.value.streak;

    final lastSession =
        sessions.isNotEmpty ? sessions.first : const <String, dynamic>{};
    final prevSession =
        sessions.length > 1 ? sessions[1] : const <String, dynamic>{};
    final lastScore = (lastSession['score'] as num?)?.toInt() ?? 0;
    final prevScore = (prevSession['score'] as num?)?.toInt() ?? 0;
    final bestScore = bestPerMode.values.fold<int>(0, (a, b) => max(a, b));

    return <String, dynamic>{
      'last_active_at': lastActive.toIso8601String(),
      'sessions_history': sessions,
      'sessions_count': sessions.length,
      'best_score_per_mode': bestPerMode,
      'streak_days': streakDays,
      'inactivity_days': inactivityDays,
      'last_score': lastScore,
      'prev_score': prevScore,
      'best_score': bestScore,
      'notifications_enabled': enabled.value,
    };
  }

  Future<void> _syncUserProfileToFirestore() async {
    if (!_firebaseReady) return;
    final uid = CloudSyncService.instance.user.value?.uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final payload = _buildUserData(prefs, now);
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      <String, dynamic>{
        ...payload,
        'updatedAtMs': now.millisecondsSinceEpoch,
      },
      SetOptions(merge: true),
    );
  }

  List<Map<String, dynamic>> _loadSessionsFromPrefs(SharedPreferences prefs) {
    final raw = prefs.getString(_kSessions);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final parsed = jsonDecode(raw);
      if (parsed is List) {
        return parsed
            .whereType<Map>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
            .toList(growable: true);
      }
    } catch (_) {}
    return <Map<String, dynamic>>[];
  }

  Map<String, int> _loadBestPerModeFromPrefs(SharedPreferences prefs) {
    final raw = prefs.getString(_kBestPerMode);
    if (raw == null || raw.isEmpty) return <String, int>{};
    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map<String, dynamic>) {
        return parsed.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0));
      }
      if (parsed is Map) {
        return parsed.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0));
      }
    } catch (_) {}
    return <String, int>{};
  }

  int _calculateStreakDays(List<Map<String, dynamic>> sessions, DateTime now) {
    final daySet = <String>{};
    for (final item in sessions) {
      final dt = DateTime.tryParse((item['date'] ?? '').toString());
      if (dt != null) daySet.add('${dt.year}${dt.month}${dt.day}');
    }
    if (daySet.isEmpty) return ProgressService.instance.progress.value.streak;
    var streak = 0;
    var cursor = _dateOnly(now);
    if (!daySet.contains('${cursor.year}${cursor.month}${cursor.day}')) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (daySet.contains('${cursor.year}${cursor.month}${cursor.day}')) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return max(streak, ProgressService.instance.progress.value.streak);
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
