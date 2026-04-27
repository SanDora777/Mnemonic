import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'content/binary_lesson.dart';
import 'progress/progress_service.dart';
import 'progress/quest_service.dart';
import 'progress/quest_models.dart';
import 'cloud/cloud_sync_service.dart';
import 'cloud/leaderboard_service.dart';
import 'quests_screen.dart';

const int _kMaxHistoryPerMode = 80;
const String _kLociRoutesPrefsKey = 'loci_routes_v1';
const Map<AppLanguage, String> _kWordsAssetByLanguage = {
  AppLanguage.ru: 'worsgenerator/ru/words.txt',
  AppLanguage.en: 'worsgenerator/en/words.txt',
  AppLanguage.de: 'worsgenerator/de/words.txt',
};

final Map<AppLanguage, List<String>> _wordsCache = {};

Future<List<String>> loadWordsForLanguage(
  AppLanguage language, {
  required List<String> fallback,
}) async {
  final cached = _wordsCache[language];
  if (cached != null && cached.isNotEmpty) {
    return cached;
  }

  final path = _kWordsAssetByLanguage[language];
  if (path == null) return fallback;
  try {
    final raw = await rootBundle.loadString(path);
    final words = raw
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    if (words.isNotEmpty) {
      _wordsCache[language] = words;
      return words;
    }
  } catch (_) {
    // Use fallback if language file is missing or malformed.
  }
  return fallback;
}

class AppPalette {
  final Color accent;
  final Color background;
  final Color surface;
  final Color card;
  final Color border;

  const AppPalette({
    required this.accent,
    required this.background,
    required this.surface,
    required this.card,
    required this.border,
  });
}

const List<AppPalette> appPalettes = [
  AppPalette(
    // Neon Lime
    accent: Color(0xFFCCFF00),
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    card: Color(0xFF111111),
    border: Color(0xFF222222),
  ),
  AppPalette(
    // Electric Cyan
    accent: Color(0xFF49B8FF),
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    card: Color(0xFF111111),
    border: Color(0xFF222222),
  ),
  AppPalette(
    // Vivid Purple
    accent: Color(0xFFBF00FF),
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    card: Color(0xFF111111),
    border: Color(0xFF222222),
  ),
  AppPalette(
    // Neon Green
    accent: Color(0xFF00FF6A),
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    card: Color(0xFF111111),
    border: Color(0xFF222222),
  ),
  AppPalette(
    // Neon Red
    accent: Color(0xFFFF3B30),
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    card: Color(0xFF111111),
    border: Color(0xFF222222),
  ),
  AppPalette(
    // Blue
    accent: Color(0xFF2F80FF),
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    card: Color(0xFF111111),
    border: Color(0xFF222222),
  ),
  AppPalette(
    // Purple
    accent: Color(0xFF8B5CFF),
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    card: Color(0xFF111111),
    border: Color(0xFF222222),
  ),
  AppPalette(
    // Gold
    accent: Color(0xFFFFC94A),
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    card: Color(0xFF111111),
    border: Color(0xFF2A2312),
  ),
];

// Глобальные контроллеры темы
final ValueNotifier<AppPalette> appPalette = ValueNotifier(appPalettes.first);
final ValueNotifier<Color> appAccentColor = ValueNotifier(appPalettes.first.accent);
final ValueNotifier<int> paletteCollapseSignal = ValueNotifier(0);

// --- ЛОКАЛИЗАЦИЯ ---
enum AppLanguage { ru, en, de }

final ValueNotifier<AppLanguage> appLanguage = ValueNotifier(AppLanguage.ru);

class AppTexts {
  static String get(String key, {Map<String, String>? params}) {
    final lang = appLanguage.value;
    final map = _data[key];
    if (map == null) return key;
    String result = map[lang] ?? map[AppLanguage.ru] ?? key;
    if (params != null) {
      params.forEach((k, v) {
        result = result.replaceAll('{$k}', v);
      });
    }
    return result;
  }

  static String plural(int n, String baseKey) {
    final lang = appLanguage.value;
    if (lang == AppLanguage.ru) {
      final m = n % 100;
      final m10 = n % 10;
      if (m >= 11 && m <= 14) return get('${baseKey}_5');
      if (m10 == 1) return get('${baseKey}_1');
      if (m10 >= 2 && m10 <= 4) return get('${baseKey}_2');
      return get('${baseKey}_5');
    } else {
      // EN/DE have simpler plural: 1 vs many
      return n == 1 ? get('${baseKey}_1') : get('${baseKey}_2');
    }
  }

  // Универсальный метод для получения перевода по текущему языку
  static String translate(Map<AppLanguage, String> translations) {
    return translations[appLanguage.value] ?? translations[AppLanguage.ru] ?? '';
  }

  static const Map<String, Map<AppLanguage, String>> _data = {
    'app_title': {
      AppLanguage.ru: 'Mnemonik',
      AppLanguage.en: 'Mnemonik',
      AppLanguage.de: 'Mnemonik',
    },
    'app_subtitle': {
      AppLanguage.ru: 'Neural Hack',
      AppLanguage.en: 'Neural Hack',
      AppLanguage.de: 'Neural Hack',
    },
    'trainer': {
      AppLanguage.ru: 'Тренажер памяти',
      AppLanguage.en: 'Memory Trainer',
      AppLanguage.de: 'Gedächtnistrainer',
    },
    'techniques': {
      AppLanguage.ru: 'Техники запоминания',
      AppLanguage.en: 'Memory Techniques',
      AppLanguage.de: 'Gedächtnistechniken',
    },
    'statistics': {
      AppLanguage.ru: 'Моя статистика',
      AppLanguage.en: 'My Statistics',
      AppLanguage.de: 'Meine Statistiken',
    },
    'academy': {
      AppLanguage.ru: 'АКАДЕМИЯ',
      AppLanguage.en: 'ACADEMY',
      AppLanguage.de: 'AKADEMIE',
    },
    'settings': {
      AppLanguage.ru: 'НАСТРОЙКИ',
      AppLanguage.en: 'SETTINGS',
      AppLanguage.de: 'EINSTELLUNGEN',
    },
    'quests': {
      AppLanguage.ru: 'ЗАДАНИЯ',
      AppLanguage.en: 'QUESTS',
      AppLanguage.de: 'AUFGABEN',
    },
    'language': {
      AppLanguage.ru: 'Язык',
      AppLanguage.en: 'Language',
      AppLanguage.de: 'Sprache',
    },
    'language_desc': {
      AppLanguage.ru: 'Выбери основной язык интерфейса',
      AppLanguage.en: 'Choose primary interface language',
      AppLanguage.de: 'Wähle Deine Hauptsprache',
    },
    'cloud_account': {
      AppLanguage.ru: 'Google аккаунт',
      AppLanguage.en: 'Google account',
      AppLanguage.de: 'Google-Konto',
    },
    'cloud_not_connected': {
      AppLanguage.ru: 'Не подключен',
      AppLanguage.en: 'Not connected',
      AppLanguage.de: 'Nicht verbunden',
    },
    'cloud_connected_as': {
      AppLanguage.ru: 'Подключен как {email}',
      AppLanguage.en: 'Connected as {email}',
      AppLanguage.de: 'Verbunden als {email}',
    },
    'cloud_sign_in': {
      AppLanguage.ru: 'Войти через Google',
      AppLanguage.en: 'Sign in with Google',
      AppLanguage.de: 'Mit Google anmelden',
    },
    'cloud_sign_out': {
      AppLanguage.ru: 'Выйти из аккаунта',
      AppLanguage.en: 'Sign out',
      AppLanguage.de: 'Abmelden',
    },
    'cloud_sync_now': {
      AppLanguage.ru: 'Синхронизировать сейчас',
      AppLanguage.en: 'Sync now',
      AppLanguage.de: 'Jetzt synchronisieren',
    },
    'account': {
      AppLanguage.ru: 'Аккаунт',
      AppLanguage.en: 'Account',
      AppLanguage.de: 'Konto',
    },
    'account_desc': {
      AppLanguage.ru: 'Имя пользователя и вход',
      AppLanguage.en: 'Username and sign-in',
      AppLanguage.de: 'Benutzername und Anmeldung',
    },
    'auth_welcome_title': {
      AppLanguage.ru: 'Добро пожаловать',
      AppLanguage.en: 'Welcome',
      AppLanguage.de: 'Willkommen',
    },
    'auth_welcome_subtitle': {
      AppLanguage.ru: 'Войди, чтобы сохранять прогресс в облаке',
      AppLanguage.en: 'Sign in to keep your progress in cloud',
      AppLanguage.de: 'Melde Dich an, um Deinen Fortschritt in der Cloud zu speichern',
    },
    'auth_continue_guest': {
      AppLanguage.ru: 'Продолжить анонимно',
      AppLanguage.en: 'Continue as guest',
      AppLanguage.de: 'Anonym fortfahren',
    },
    'auth_or': {
      AppLanguage.ru: 'или',
      AppLanguage.en: 'or',
      AppLanguage.de: 'oder',
    },
    'account_name_label': {
      AppLanguage.ru: 'Имя пользователя',
      AppLanguage.en: 'Username',
      AppLanguage.de: 'Benutzername',
    },
    'account_name_hint': {
      AppLanguage.ru: 'Введи имя',
      AppLanguage.en: 'Enter your name',
      AppLanguage.de: 'Gib Deinen Namen ein',
    },
    'account_save_name': {
      AppLanguage.ru: 'Сохранить имя',
      AppLanguage.en: 'Save name',
      AppLanguage.de: 'Namen speichern',
    },
    'leaderboard_title': {
      AppLanguage.ru: 'ЛИДЕРЫ',
      AppLanguage.en: 'LEADERBOARD',
      AppLanguage.de: 'BESTENLISTE',
    },
    'leaderboard_daily': {
      AppLanguage.ru: 'ДЕНЬ',
      AppLanguage.en: 'DAY',
      AppLanguage.de: 'TAG',
    },
    'leaderboard_monthly': {
      AppLanguage.ru: 'МЕСЯЦ',
      AppLanguage.en: 'MONTH',
      AppLanguage.de: 'MONAT',
    },
    'leaderboard_points': {
      AppLanguage.ru: 'очков',
      AppLanguage.en: 'pts',
      AppLanguage.de: 'pkt',
    },
    'leaderboard_empty': {
      AppLanguage.ru: 'Пока нет результатов',
      AppLanguage.en: 'No results yet',
      AppLanguage.de: 'Noch keine Ergebnisse',
    },
    'leaderboard_prev_champion': {
      AppLanguage.ru: 'Чемпион вчера: {name} ({points})',
      AppLanguage.en: 'Yesterday champion: {name} ({points})',
      AppLanguage.de: 'Champion gestern: {name} ({points})',
    },
    'leaderboard_prev_champion_none': {
      AppLanguage.ru: 'Вчера еще не было чемпиона',
      AppLanguage.en: 'No champion yesterday yet',
      AppLanguage.de: 'Gestern gab es noch keinen Champion',
    },
    'leaderboard_open': {
      AppLanguage.ru: 'Таблица лидеров',
      AppLanguage.en: 'Leaderboard',
      AppLanguage.de: 'Bestenliste',
    },
    'auth_signin_failed': {
      AppLanguage.ru: 'Не удалось войти через Google',
      AppLanguage.en: 'Google sign-in failed',
      AppLanguage.de: 'Google-Anmeldung fehlgeschlagen',
    },
    'auth_google_setup_hint': {
      AppLanguage.ru: 'Проверь Firebase: SHA-1/SHA-256 и google-services.json для пакета приложения.',
      AppLanguage.en: 'Check Firebase setup: SHA-1/SHA-256 and google-services.json for your package.',
      AppLanguage.de: 'Pruefe Firebase-Setup: SHA-1/SHA-256 und google-services.json fuer das App-Paket.',
    },
    'auth_guest_failed': {
      AppLanguage.ru: 'Не удалось войти как гость',
      AppLanguage.en: 'Guest sign-in failed',
      AppLanguage.de: 'Gast-Anmeldung fehlgeschlagen',
    },
    'auth_guest_setup_hint': {
      AppLanguage.ru: 'В Firebase Auth включи провайдер Anonymous и проверь API key в google-services.json.',
      AppLanguage.en: 'Enable Anonymous provider in Firebase Auth and verify API key in google-services.json.',
      AppLanguage.de: 'Aktiviere den Anonymous-Provider in Firebase Auth und pruefe den API key in google-services.json.',
    },
    'more': {
      AppLanguage.ru: 'ПОДРОБНЕЕ',
      AppLanguage.en: 'LEARN MORE',
      AppLanguage.de: 'MEHR ERFAHREN',
    },
    'hide': {
      AppLanguage.ru: 'СКРЫТЬ',
      AppLanguage.en: 'HIDE',
      AppLanguage.de: 'VERBERGEN',
    },
    'numbers': {
      AppLanguage.ru: 'ЧИСЛА',
      AppLanguage.en: 'NUMBERS',
      AppLanguage.de: 'ZAHLEN',
    },
    'binary': {
      AppLanguage.ru: 'БИНАР',
      AppLanguage.en: 'BINARY',
      AppLanguage.de: 'BINÄR',
    },
    'words': {
      AppLanguage.ru: 'СЛОВА',
      AppLanguage.en: 'WORDS',
      AppLanguage.de: 'WORTE',
    },
    'photo': {
      AppLanguage.ru: 'ФОТО',
      AppLanguage.en: 'PHOTO',
      AppLanguage.de: 'FOTO',
    },
    'cards': {
      AppLanguage.ru: 'КАРТЫ',
      AppLanguage.en: 'CARDS',
      AppLanguage.de: 'KARTEN',
    },
    'start': {
      AppLanguage.ru: 'ПОЕХАЛИ',
      AppLanguage.en: 'GO',
      AppLanguage.de: 'START',
    },
    'done': {
      AppLanguage.ru: 'ГОТОВО',
      AppLanguage.en: 'DONE',
      AppLanguage.de: 'FERTIG',
    },
    'back': {
      AppLanguage.ru: 'НАЗАД',
      AppLanguage.en: 'BACK',
      AppLanguage.de: 'ZURÜCK',
    },
    'first_chunk': {
      AppLanguage.ru: 'В НАЧАЛО',
      AppLanguage.en: 'FIRST',
      AppLanguage.de: 'ANFANG',
    },
    'next_chunk': {
      AppLanguage.ru: 'ДАЛЕЕ',
      AppLanguage.en: 'NEXT',
      AppLanguage.de: 'WEITER',
    },
    'statistics_title': {
      AppLanguage.ru: 'СТАТИСТИКА',
      AppLanguage.en: 'STATISTICS',
      AppLanguage.de: 'STATISTIKEN',
    },
    'record': {
      AppLanguage.ru: 'Рекорд',
      AppLanguage.en: 'Record',
      AppLanguage.de: 'Rekord',
    },
    'games_count': {
      AppLanguage.ru: 'Игр',
      AppLanguage.en: 'Games',
      AppLanguage.de: 'Spiele',
    },
    'avg_accuracy': {
      AppLanguage.ru: 'Ср. точность',
      AppLanguage.en: 'Avg. accuracy',
      AppLanguage.de: 'Durchschn. Genauigkeit',
    },
    'best_speed': {
      AppLanguage.ru: 'Лучшая скорость запоминания',
      AppLanguage.en: 'Best memorization speed',
      AppLanguage.de: 'Beste Einprägegeschwindigkeit',
    },
    'per_element': {
      AppLanguage.ru: 'на элемент',
      AppLanguage.en: 'per element',
      AppLanguage.de: 'pro Element',
    },
    'recent_attempts': {
      AppLanguage.ru: 'Недавние попытки',
      AppLanguage.en: 'Recent attempts',
      AppLanguage.de: 'Jüngste Versuche',
    },
    'no_history': {
      AppLanguage.ru: 'История пуста',
      AppLanguage.en: 'No history',
      AppLanguage.de: 'Keine Historie',
    },
    'settings_elements': {
      AppLanguage.ru: 'ЭЛЕМЕНТОВ',
      AppLanguage.en: 'ELEMENTS',
      AppLanguage.de: 'ELEMENTE',
    },
    'settings_chunk': {
      AppLanguage.ru: 'ЧАНК',
      AppLanguage.en: 'CHUNK',
      AppLanguage.de: 'CHUNK',
    },
    'settings_seconds': {
      AppLanguage.ru: 'СЕКУНДЫ',
      AppLanguage.en: 'SECONDS',
      AppLanguage.de: 'SEKUNDEN',
    },
    'settings_slot': {
      AppLanguage.ru: 'СЛОТ',
      AppLanguage.en: 'SLOT',
      AppLanguage.de: 'SLOT',
    },
    'settings_competition': {
      AppLanguage.ru: 'РЕЖИМ СОРЕВНОВАНИЯ',
      AppLanguage.en: 'COMPETITION MODE',
      AppLanguage.de: 'WETTBEWERBSMODUS',
    },
    'settings_matrix': {
      AppLanguage.ru: 'МАТРИЧНЫЙ ВИД',
      AppLanguage.en: 'MATRIX VIEW',
      AppLanguage.de: 'MATRIX-ANSICHT',
    },
    'modes_title': {
      AppLanguage.ru: 'РЕЖИМЫ',
      AppLanguage.en: 'MODES',
      AppLanguage.de: 'MODI',
    },
    'preparing_training': {
      AppLanguage.ru: 'Подготавливаем тренировку',
      AppLanguage.en: 'Preparing training',
      AppLanguage.de: 'Training wird vorbereitet',
    },
    'loading_images_desc': {
      AppLanguage.ru: 'Загружаем изображения заранее,\nчтобы таймер запоминания шел без задержек.',
      AppLanguage.en: 'Loading images in advance\nso the memorization timer runs smoothly.',
      AppLanguage.de: 'Bilder werden vorab geladen,\ndamit der Merk-Timer reibungslos läuft.',
    },
    'loading_progress': {
      AppLanguage.ru: '{current} из {total}',
      AppLanguage.en: '{current} of {total}',
      AppLanguage.de: '{current} von {total}',
    },
    'check': {
      AppLanguage.ru: 'ПРОВЕРИТЬ',
      AppLanguage.en: 'CHECK',
      AppLanguage.de: 'PRÜFEN',
    },
    'retry': {
      AppLanguage.ru: 'ПОВТОРИТЬ',
      AppLanguage.en: 'RETRY',
      AppLanguage.de: 'WIEDERHOLEN',
    },
    'finish': {
      AppLanguage.ru: 'ЗАКОНЧИТЬ',
      AppLanguage.en: 'FINISH',
      AppLanguage.de: 'BEENDEN',
    },
    'streak_label': {
      AppLanguage.ru: 'Серия: {days} дн.',
      AppLanguage.en: 'Streak: {days} days',
      AppLanguage.de: 'Serie: {days} Tage',
    },
    'result_first_attempt': {
      AppLanguage.ru: 'Первая зафиксированная попытка на {n} {plural} в режиме «{mode}».',
      AppLanguage.en: 'First recorded attempt for {n} {plural} in "{mode}" mode.',
      AppLanguage.de: 'Erster aufgezeichneter Versuch für {n} {plural} im Modus "{mode}".',
    },
    'result_previous_zero': {
      AppLanguage.ru: 'Прошлый раз на {n} {plural}: 0%. Сейчас: {pct}%.',
      AppLanguage.en: 'Last time for {n} {plural}: 0%. Now: {pct}%.',
      AppLanguage.de: 'Letztes Mal für {n} {plural}: 0%. Jetzt: {pct}%.',
    },
    'result_improvement': {
      AppLanguage.ru: 'На {imp}% лучше прошлой попытки на {n} {plural}.',
      AppLanguage.en: '{imp}% better than the last attempt for {n} {plural}.',
      AppLanguage.de: '{imp}% besser als beim letzten Versuch für {n} {plural}.',
    },
    'result_decline': {
      AppLanguage.ru: 'На {imp}% ниже прошлой попытки на {n} {plural}.',
      AppLanguage.en: '{imp}% lower than the last attempt for {n} {plural}.',
      AppLanguage.de: '{imp}% niedriger als beim letzten Versuch für {n} {plural}.',
    },
    'plural_element_1': {
      AppLanguage.ru: 'элемент',
      AppLanguage.en: 'element',
      AppLanguage.de: 'Element',
    },
    'plural_element_2': {
      AppLanguage.ru: 'элемента',
      AppLanguage.en: 'elements',
      AppLanguage.de: 'Elemente',
    },
    'plural_element_5': {
      AppLanguage.ru: 'элементов',
      AppLanguage.en: 'elements',
      AppLanguage.de: 'Elemente',
    },
    'mode_numbers': {
      AppLanguage.ru: 'числа',
      AppLanguage.en: 'numbers',
      AppLanguage.de: 'Zahlen',
    },
    'mode_binary': {
      AppLanguage.ru: 'бинар',
      AppLanguage.en: 'binary',
      AppLanguage.de: 'Binär',
    },
    'mode_words': {
      AppLanguage.ru: 'слова',
      AppLanguage.en: 'words',
      AppLanguage.de: 'Worte',
    },
    'mode_photo': {
      AppLanguage.ru: 'фото',
      AppLanguage.en: 'photo',
      AppLanguage.de: 'Foto',
    },
    'mode_cards': {
      AppLanguage.ru: 'карты',
      AppLanguage.en: 'cards',
      AppLanguage.de: 'Karten',
    },
    'settings_elements_count': {
      AppLanguage.ru: 'Количество элементов',
      AppLanguage.en: 'Number of elements',
      AppLanguage.de: 'Anzahl der Elemente',
    },
    'settings_chunk_count': {
      AppLanguage.ru: 'Элементов на экране',
      AppLanguage.en: 'Elements on screen',
      AppLanguage.de: 'Elemente auf dem Bildschirm',
    },
    'settings_flash_seconds': {
      AppLanguage.ru: 'Секунд на экран (вспышка)',
      AppLanguage.en: 'Seconds per screen (flash)',
      AppLanguage.de: 'Sekunden pro Bildschirm (Flash)',
    },
    'settings_flash_mode': {
      AppLanguage.ru: 'Режим Вспышка',
      AppLanguage.en: 'Flash Mode',
      AppLanguage.de: 'Flash-Modus',
    },
    'settings_flash_desc': {
      AppLanguage.ru: 'автоматическая смена',
      AppLanguage.en: 'automatic change',
      AppLanguage.de: 'automatischer Wechsel',
    },
    'settings_matrix_desc': {
      AppLanguage.ru: 'Matrix: режим сетки для высокой плотности данных.\nУпор на пространственную память и скорость.',
      AppLanguage.en: 'Matrix: grid mode for high data density.\nFocus on spatial memory and speed.',
      AppLanguage.de: 'Matrix: Gittermodus für hohe Datendichte.\nFokus auf räumliches Gedächtnis und Geschwindigkeit.',
    },
    'mode_numbers_sub': {
      AppLanguage.ru: 'Числа',
      AppLanguage.en: 'Numbers',
      AppLanguage.de: 'Zahlen',
    },
    'mode_matrix_sub': {
      AppLanguage.ru: 'Matrix',
      AppLanguage.en: 'Matrix',
      AppLanguage.de: 'Matrix',
    },
    'streak': {
      AppLanguage.ru: 'Серия',
      AppLanguage.en: 'Streak',
      AppLanguage.de: 'Serie',
    },
    'days_label': {
      AppLanguage.ru: 'дн.',
      AppLanguage.en: 'days',
      AppLanguage.de: 'Tage',
    },
    'your_training': {
      AppLanguage.ru: 'Твое обучение',
      AppLanguage.en: 'Your Training',
      AppLanguage.de: 'Dein Training',
    },
    'training_subtitle': {
      AppLanguage.ru: 'От основ до мастерства',
      AppLanguage.en: 'From basics to mastery',
      AppLanguage.de: 'Von den Grundlagen zur Meisterschaft',
    },
    'foundation': {
      AppLanguage.ru: 'ФУНДАМЕНТ',
      AppLanguage.en: 'FOUNDATION',
      AppLanguage.de: 'FUNDAMENT',
    },
    'architecture': {
      AppLanguage.ru: 'АРХИТЕКТУРА',
      AppLanguage.en: 'ARCHITECTURE',
      AppLanguage.de: 'ARCHITEKTUR',
    },
    'specialization': {
      AppLanguage.ru: 'СПЕЦИАЛИЗАЦИЯ',
      AppLanguage.en: 'SPECIALIZATION',
      AppLanguage.de: 'SPEZIALISIERUNG',
    },
    'practice': {
      AppLanguage.ru: 'ПРАКТИКА',
      AppLanguage.en: 'PRACTICE',
      AppLanguage.de: 'PRAXIS',
    },
    'level_beginner': {
      AppLanguage.ru: 'Новичок',
      AppLanguage.en: 'Beginner',
      AppLanguage.de: 'Anfänger',
    },
    'level_student': {
      AppLanguage.ru: 'Ученик',
      AppLanguage.en: 'Student',
      AppLanguage.de: 'Schüler',
    },
    'level_practitioner': {
      AppLanguage.ru: 'Практик',
      AppLanguage.en: 'Practitioner',
      AppLanguage.de: 'Praktiker',
    },
    'level_advanced': {
      AppLanguage.ru: 'Продвинутый',
      AppLanguage.en: 'Advanced',
      AppLanguage.de: 'Fortgeschritten',
    },
    'level_expert': {
      AppLanguage.ru: 'Эксперт',
      AppLanguage.en: 'Expert',
      AppLanguage.de: 'Experte',
    },
    'level_master': {
      AppLanguage.ru: 'Мастер',
      AppLanguage.en: 'Master',
      AppLanguage.de: 'Meister',
    },
    'level_grandmaster': {
      AppLanguage.ru: 'Грандмастер',
      AppLanguage.en: 'Grandmaster',
      AppLanguage.de: 'Großmeister',
    },
    'day_streak': {
      AppLanguage.ru: 'Дней ударного режима',
      AppLanguage.en: 'Day streak',
      AppLanguage.de: 'Tage in Folge',
    },
    'quest_completed_snack': {
      AppLanguage.ru: 'ЗАДАНИЕ ВЫПОЛНЕНО!',
      AppLanguage.en: 'QUEST COMPLETED!',
      AppLanguage.de: 'AUFGABE ABGESCHLOSSEN!',
    },
    'great_confetti': {
      AppLanguage.ru: 'ОТЛИЧНО!',
      AppLanguage.en: 'GREAT!',
      AppLanguage.de: 'GROSSARTIG!',
    },
    'daily_quests_title': {
      AppLanguage.ru: 'ЕЖЕДНЕВНЫЕ',
      AppLanguage.en: 'DAILY QUESTS',
      AppLanguage.de: 'TÄGLICHE AUFGABEN',
    },
    'weekly_quests_title': {
      AppLanguage.ru: 'ЕЖЕНЕДЕЛЬНЫЕ',
      AppLanguage.en: 'WEEKLY QUESTS',
      AppLanguage.de: 'WÖCHENTLICHE AUFGABEN',
    },
    'manage_associations': {
      AppLanguage.ru: 'Управляй своими ассоциациями',
      AppLanguage.en: 'Manage your associations',
      AppLanguage.de: 'Verwalte deine Assoziationen',
    },
    'number_images_labels_title': {
      AppLanguage.ru: 'Образы для чисел',
      AppLanguage.en: 'Number Images',
      AppLanguage.de: 'Zahlenbilder',
    },
    'number_images_labels_not_available': {
      AppLanguage.ru: 'Сейчас недоступно',
      AppLanguage.en: 'Currently not available',
      AppLanguage.de: 'Zurzeit nicht verfugbar',
    },
    'mnemonics_definition': {
      AppLanguage.ru: "Мнемотехника — это система методов, которая превращает скучные данные в яркие истории.",
      AppLanguage.en: "Mnemonics is a system of methods that turns boring data into vivid stories.",
      AppLanguage.de: "Mnemonik ist ein System von Methoden, das langweilige Daten in lebendige Geschichten verwandelt.",
    },
    'main_idea': {
      AppLanguage.ru: "Главная идея: мозг плохо помнит абстрактные цифры, но обожает: ОБРАЗЫ, ЭМОЦИИ, ДВИЖЕНИЯ.",
      AppLanguage.en: "Main idea: the brain remembers abstract numbers poorly, but loves: IMAGES, EMOTIONS, MOVEMENTS.",
      AppLanguage.de: "Hauptidee: Das Gehirn merkt sich abstrakte Zahlen schlecht, liebt aber: BILDER, EMOTIONEN, BEWEGUNGEN.",
    },
    'why_rote_fails': {
      AppLanguage.ru: "Почему зубрежка не работает?",
      AppLanguage.en: "Why rote learning doesn't work?",
      AppLanguage.de: "Warum Auswendiglernen nicht funktioniert?",
    },
    'noise_explanation': {
      AppLanguage.ru: "Когда ты видишь '482951736', мозгу не за что зацепиться. Это просто шум. Мнемотехника дает крючки, за которые цепляется память.",
      AppLanguage.en: "When you see '482951736', the brain has nothing to hold onto. It's just noise. Mnemonics provides hooks that memory clings to.",
      AppLanguage.de: "Wenn du '482951736' siehst, hat das Gehirn nichts, woran es sich festhalten kann. Es ist nur Lärm. Mnemonik bietet Haken, an denen sich das Gedächtnis festklammert.",
    },
    'main_principle': {
      AppLanguage.ru: "Главный принцип",
      AppLanguage.en: "Main Principle",
      AppLanguage.de: "Hauptprinzip",
    },
    'principle_1': {
      AppLanguage.ru: "1. Сделай информацию визуальной",
      AppLanguage.en: "1. Make information visual",
      AppLanguage.de: "1. Informationen visuell machen",
    },
    'principle_2': {
      AppLanguage.ru: "2. Добавь яркости и абсурда",
      AppLanguage.en: "2. Add brightness and absurdity",
      AppLanguage.de: "2. Helligkeit und Absurdität hinzufügen",
    },
    'principle_3': {
      AppLanguage.ru: "3. Связывай образы между собой",
      AppLanguage.en: "3. Connect images with each other",
      AppLanguage.de: "3. Bilder miteinander verbinden",
    },
    'bad_example_dog': {
      AppLanguage.ru: "Плохо: Собака стоит",
      AppLanguage.en: "Bad: A dog stands",
      AppLanguage.de: "Schlecht: Ein Hund steht",
    },
    'good_example_dog': {
      AppLanguage.ru: "Хорошо: Огромная собака лает огнем и взрывается",
      AppLanguage.en: "Good: A huge dog barks fire and explodes",
      AppLanguage.de: "Gut: Ein riesiger Hund bellt Feuer und explodiert",
    },
    'amplifiers': {
      AppLanguage.ru: "Усилители: добавляй звук, запах, юмор или даже 'фантомную' боль.",
      AppLanguage.en: "Amplifiers: add sound, smell, humor, or even 'phantom' pain.",
      AppLanguage.de: "Verstärker: Fügen Sie Ton, Geruch, Humor oder sogar 'Phantomschmerz' hinzu.",
    },
    'interaction_rule': {
      AppLanguage.ru: "Чтобы информация не 'рассыпалась', образы должны взаимодействовать друг с другом.",
      AppLanguage.en: "To prevent information from 'falling apart', images must interact with each other.",
      AppLanguage.de: "Damit Informationen nicht 'auseinanderfallen', müssen Bilder miteinander interagieren.",
    },
    'interaction_rule_box': {
      AppLanguage.ru: "Правило: первый образ должен физически влиять на второй.",
      AppLanguage.en: "Rule: the first image must physically affect the second.",
      AppLanguage.de: "Regel: Das erste Bild muss das zweite physisch beeinflussen.",
    },
    'loci_method_title': {
      AppLanguage.ru: 'Метод Локи (Дворец)',
      AppLanguage.en: 'Method of Loci (Palace)',
      AppLanguage.de: 'Loci-Methode (Palast)',
    },
    'loci_description': {
      AppLanguage.ru: 'Легендарная техника древнегреческих ораторов.',
      AppLanguage.en: 'Legendary technique of ancient Greek orators.',
      AppLanguage.de: 'Legendäre Technik antiker griechischer Redner.',
    },
    'loci_explanation': {
      AppLanguage.ru: "Ты запоминаешь информацию, 'раскладывая' её по знакомому пространству: квартире или маршруту до зала.",
      AppLanguage.en: "You remember information by 'placing' it in a familiar space: an apartment or a route to the gym.",
      AppLanguage.de: "Du merkst dir Informationen, indem du sie in einem vertrauten Raum 'platzierst': einer Wohnung oder einer Route zum Fitnessstudio.",
    },
    'how_it_works': {
      AppLanguage.ru: "Как это работает?",
      AppLanguage.en: "How it works?",
      AppLanguage.de: "Wie es funktioniert?",
    },
    'choose_place': {
      AppLanguage.ru: "Выбери место",
      AppLanguage.en: "Choose a place",
      AppLanguage.de: "Wähle einen Ort",
    },
    'choose_place_desc': {
      AppLanguage.ru: "Комната, которую ты знаешь идеально.",
      AppLanguage.en: "A room you know perfectly.",
      AppLanguage.de: "Ein Raum, den du perfekt kennst.",
    },
    'create_route': {
      AppLanguage.ru: "Создай маршрут",
      AppLanguage.en: "Create a route",
      AppLanguage.de: "Erstelle eine Route",
    },
    'create_route_desc': {
      AppLanguage.ru: "Всегда один порядок: Дверь → Зеркало → Стол...",
      AppLanguage.en: "Always the same order: Door → Mirror → Table...",
      AppLanguage.de: "Immer die gleiche Reihenfolge: Tür → Spiegel → Tisch...",
    },
    'add_images_label': {
      AppLanguage.ru: "Добавь образы",
      AppLanguage.en: "Add images",
      AppLanguage.de: "Bilder hinzufügen",
    },
    'add_images_desc': {
      AppLanguage.ru: "Размести по одному образу в каждой точке.",
      AppLanguage.en: "Place one image at each point.",
      AppLanguage.de: "Platziere ein Bild an jedem Punkt.",
    },
    'loci_mistake': {
      AppLanguage.ru: "Ошибка: не меняй порядок мест и не используй похожие локации!",
      AppLanguage.en: "Mistake: do not change the order of places or use similar locations!",
      AppLanguage.de: "Fehler: Ändern Sie nicht die Reihenfolge der Orte und verwenden Sie keine ähnlichen Orte!",
    },
    'numbers_memorization': {
      AppLanguage.ru: 'Запоминание чисел',
      AppLanguage.en: 'Memorizing Numbers',
      AppLanguage.de: 'Zahlen merken',
    },
    'numbers_description': {
      AppLanguage.ru: 'Превращаем сухие цифры в живых персонажей.',
      AppLanguage.en: 'Turning dry numbers into living characters.',
      AppLanguage.de: 'Trockene Zahlen in lebendige Charaktere verwandeln.',
    },
    'numbers_explanation': {
      AppLanguage.ru: "Числа абстрактны. Наша цель — присвоить каждому числу (00-99) свой постоянный образ.",
      AppLanguage.en: "Numbers are abstract. Our goal is to assign each number (00-99) its own permanent image.",
      AppLanguage.de: "Zahlen sind abstrakt. Unser Ziel ist es, jeder Zahl (00-99) ein eigenes permanentes Bild zuzuweisen.",
    },
    'numbers_example': {
      AppLanguage.ru: "Пример: 01=Ёж, 02=Яд, 03=Ухо. Теперь 010203 — это история про ежа и яд.",
      AppLanguage.en: "Example: 01=Hedgehog, 02=Poison, 03=Ear. Now 010203 is a story about a hedgehog and poison.",
      AppLanguage.de: "Beispiel: 01=Igel, 02=Gift, 03=Ohr. Jetzt ist 010203 eine Geschichte über einen Igel und Gift.",
    },
    'advanced_pao': {
      AppLanguage.ru: "Продвинутый уровень (PAO)",
      AppLanguage.en: "Advanced Level (PAO)",
      AppLanguage.de: "Fortgeschrittenes Level (PAO)",
    },
    'pao_explanation': {
      AppLanguage.ru: "Система Персонаж-Действие-Объект позволяет запоминать 6 цифр в одном образе.",
      AppLanguage.en: "The Person-Action-Object system allows memorizing 6 digits in one image.",
      AppLanguage.de: "Das Person-Aktion-Objekt-System ermöglicht das Einprägen von 6 Ziffern in einem Bild.",
    },
    'binary_numbers_title': {
      AppLanguage.ru: 'Бинарные числа',
      AppLanguage.en: 'Binary Numbers',
      AppLanguage.de: 'Binärzahlen',
    },
    'binary_description': {
      AppLanguage.ru: 'Как профессионалы запоминают сотни нулей и единиц.',
      AppLanguage.en: 'How professionals memorize hundreds of zeros and ones.',
      AppLanguage.de: 'Wie Profis Hunderte von Nullen und Einsen auswendig lernen.',
    },
    'binary_explanation': {
      AppLanguage.ru: "Бинары по 3 цифры имеют всего 8 комбинаций. Закодируй каждую в число (0-7).",
      AppLanguage.en: "Binaries of 3 digits have only 8 combinations. Code each into a number (0-7).",
      AppLanguage.de: "Binärzahlen aus 3 Ziffern haben nur 8 Kombinationen. Kodieren Sie jede in eine Zahl (0-7).",
    },
    'binary_example': {
      AppLanguage.ru: "001=1 (Яблоко), 011=2 (Лебедь), 111=3 (Тризуб)...",
      AppLanguage.en: "001=1 (Apple), 011=2 (Swan), 111=3 (Trident)...",
      AppLanguage.de: "001=1 (Apfel), 011=2 (Schwan), 111=3 (Dreizack)...",
    },
    'binary_result': {
      AppLanguage.ru: "Теперь бинарная лента '001111011' превращается в '1-3-2'.",
      AppLanguage.en: "Now the binary tape '001111011' turns into '1-3-2'.",
      AppLanguage.de: "Jetzt verwandelt sich das Binärband '001111011' in '1-3-2'.",
    },
    'words_images_title': {
      AppLanguage.ru: 'Слова и Изображения',
      AppLanguage.en: 'Words and Images',
      AppLanguage.de: 'Wörter und Bilder',
    },
    'words_images_description': {
      AppLanguage.ru: 'Работа с абстрактными понятиями и картинками.',
      AppLanguage.en: 'Working with abstract concepts and images.',
      AppLanguage.de: 'Arbeit mit abstrakten Konzepten und Bildern.',
    },
    'words_label': {
      AppLanguage.ru: "Слова",
      AppLanguage.en: "Words",
      AppLanguage.de: "Wörter",
    },
    'words_explanation': {
      AppLanguage.ru: "Разбивай слово на части: 'Компьютер' → комп + пьют + тер. Создай из этого сюжет.",
      AppLanguage.en: "Break the word into parts: 'Computer' → comp + put + er. Create a story out of this.",
      AppLanguage.de: "Zerlegen Sie das Wort in Teile: 'Computer' → Comp + put + er. Machen Sie daraus eine Geschichte.",
    },
    'images_label': {
      AppLanguage.ru: "Изображения",
      AppLanguage.en: "Images",
      AppLanguage.de: "Bilder",
    },
    'images_explanation': {
      AppLanguage.ru: "Не запоминай картинку как есть. Найди в ней главную деталь, преувеличь её и помести в локу.",
      AppLanguage.en: "Don't memorize the image as is. Find the main detail in it, exaggerate it, and place it in a loci.",
      AppLanguage.de: "Merken Sie sich das Bild nicht so, wie es ist. Finden Sie das Hauptdetail darin, übertreiben Sie es und platzieren Sie es in einem Locus.",
    },
    'speed_mistakes_title': {
      AppLanguage.ru: 'Скорость и Ошибки',
      AppLanguage.en: 'Speed and Mistakes',
      AppLanguage.de: 'Geschwindigkeit und Fehler',
    },
    'championship_level': {
      AppLanguage.ru: 'Как выйти на уровень чемпионата.',
      AppLanguage.en: 'How to reach the championship level.',
      AppLanguage.de: 'Wie man das Meisterschaftsniveau erreicht.',
    },
    'why_slow': {
      AppLanguage.ru: "Почему ты медлишь?",
      AppLanguage.en: "Why are you slow?",
      AppLanguage.de: "Warum bist du langsam?",
    },
    'images_not_automated': {
      AppLanguage.ru: "Образы не автоматизированы",
      AppLanguage.en: "Images are not automated",
      AppLanguage.de: "Bilder sind nicht automatisiert",
    },
    'weak_visualization': {
      AppLanguage.ru: "Слабая визуализация",
      AppLanguage.en: "Weak visualization",
      AppLanguage.de: "Schwache Visualisierung",
    },
    'training_solution': {
      AppLanguage.ru: "Решение: тренируйся по 10-15 минут ежедневно с таймером.",
      AppLanguage.en: "Solution: practice for 10-15 minutes daily with a timer.",
      AppLanguage.de: "Lösung: Trainieren Sie täglich 10-15 Minuten mit einem Timer.",
    },
    'main_mistakes': {
      AppLanguage.ru: "Основные ошибки",
      AppLanguage.en: "Main Mistakes",
      AppLanguage.de: "Hauptfehler",
    },
    'boring_images': {
      AppLanguage.ru: "Скучные образы без движения",
      AppLanguage.en: "Boring images without movement",
      AppLanguage.de: "Langweilige Bilder ohne Bewegung",
    },
    'chaotic_palaces': {
      AppLanguage.ru: "Хаотичные дворцы памяти",
      AppLanguage.en: "Chaotic memory palaces",
      AppLanguage.de: "Chaotische Gedächtnispaläste",
    },
    'location_overload': {
      AppLanguage.ru: "Перегрузка локаций (больше 2 образов на точку)",
      AppLanguage.en: "Location overload (more than 2 images per point)",
      AppLanguage.de: "Überlastung der Orte (mehr als 2 Bilder pro Punkt)",
    },
  };

  // Контент уроков
  static const introLesson = {
    'title': {
      AppLanguage.ru: 'Что такое мнемотехника',
      AppLanguage.en: 'What is Mnemonics',
      AppLanguage.de: 'Was ist Mnemonik',
    },
    'subtitle': {
      AppLanguage.ru: 'Пойми, как твой мозг на самом деле запоминает информацию.',
      AppLanguage.en: 'Understand how your brain actually remembers information.',
      AppLanguage.de: 'Verstehe, wie dein Gehirn Informationen wirklich speichert.',
    },
    'main_text': {
      AppLanguage.ru: "Мнемотехника - это не трюк и не магия.\n\nЭто технология, с помощью которой люди запоминают десятки тысяч цифр числа π, сотни иностранных слов за вечер и конспекты на десятки страниц.\n\nРазница между тобой и чемпионом мира по памяти не в мозге, а в методе.\n\nВ этом разделе ты увидишь, как работает этот метод на своей голове.",
      AppLanguage.en: "Mnemonics is not a trick or magic.\n\nIt is a technology through which people memorize tens of thousands of digits of pi, hundreds of foreign words in an evening, and notes tens of pages long.\n\nThe difference between you and a world memory champion is not in the brain, but in the method.\n\nIn this section, you will see how this method works on your own head.",
      AppLanguage.de: "Mnemonik ist kein Trick oder Magie.\n\nEs ist eine Technologie, mit der Menschen Zehntausende von Stellen der Zahl Pi, Hunderte von Fremdwörtern an einem Abend und seitenlange Notizen auswendig lernen.\n\nDer Unterschied zwischen dir und einem Gedächtnisweltmeister liegt nicht im Gehirn, sondern in der Methode.\n\nIn diesem Abschnitt wirst du sehen, wie diese Methode in deinem eigenen Kopf funktioniert.",
    },
  };

  static const imagesLesson = {
    'title': {
      AppLanguage.ru: 'Как создавать образы',
      AppLanguage.en: 'How to create images',
      AppLanguage.de: 'Wie man Bilder erstellt',
    },
    'subtitle': {
      AppLanguage.ru: 'Секрет идеального образа: чем страннее, тем лучше.',
      AppLanguage.en: 'The secret of the perfect image: the weirder, the better.',
      AppLanguage.de: 'Das Geheimnis des perfekten Bildes: je seltsamer, desto besser.',
    },
    'why_images_title': {
      AppLanguage.ru: 'Зачем нужны образы?',
      AppLanguage.en: 'Why do we need images?',
      AppLanguage.de: 'Warum brauchen wir Bilder?',
    },
    'why_images_text': {
      AppLanguage.ru: "Твой мозг не хранит информацию как таблицу в Excel. Он запоминает картинки, эмоции и движения.\n\nКогда ты представляешь огромную собаку, которая лает огнем и взрывается — мозг такой: «О, это важно, запомню».",
      AppLanguage.en: "Your brain doesn't store information like an Excel spreadsheet. It remembers pictures, emotions, and movements.\n\nWhen you imagine a huge dog that barks fire and explodes — the brain is like: 'Oh, this is important, I'll remember it'.",
      AppLanguage.de: "Dein Gehirn speichert Informationen nicht wie eine Excel-Tabelle. Es merkt sich Bilder, Emotionen und Bewegungen.\n\nWenn du dir einen riesigen Hund vorstellst, der Feuer bellt und explodiert — sagt das Gehirn: 'Oh, das ist wichtig, das merke ich mir'.",
    },
    'formula_title': {
      AppLanguage.ru: 'Формула идеального образа',
      AppLanguage.en: 'Perfect Image Formula',
      AppLanguage.de: 'Formel für das perfekte Bild',
    },
    'formula_text': {
      AppLanguage.ru: "• БОЛЬШОЙ: Размером с дом или больше.\n• ЯРКИЙ: Неоновые цвета, сияние, контраст.\n• ДВИЖУЩИЙСЯ: Летит, взрывается, танцует.\n• ЭМОЦИОНАЛЬНЫЙ: Смешной, абсурдный или пугающий.",
      AppLanguage.en: "• BIG: Size of a house or larger.\n• BRIGHT: Neon colors, glow, contrast.\n• MOVING: Flying, exploding, dancing.\n• EMOTIONAL: Funny, absurd, or scary.",
      AppLanguage.de: "• GROSS: So groß wie ein Haus oder größer.\n• HELL: Neonfarben, Leuchten, Kontrast.\n• BEWEGT: Fliegen, explodieren, tanzen.\n• EMOTIONAL: Lustig, absurd oder beängstigend.",
    },
  };

  static const linkingLesson = {
    'title': {
      AppLanguage.ru: 'Связывание образов',
      AppLanguage.en: 'Linking Images',
      AppLanguage.de: 'Bilder verbinden',
    },
    'subtitle': {
      AppLanguage.ru: "Техника 'цепочка' для бесконечных списков.",
      AppLanguage.en: "'Chain' technique for infinite lists.",
      AppLanguage.de: "'Ketten'-Technik für unendliche Listen.",
    },
    'why_title': {
      AppLanguage.ru: 'Зачем это нужно',
      AppLanguage.en: 'Why do we need this',
      AppLanguage.de: 'Warum brauchen wir das',
    },
    'why_text': {
      AppLanguage.ru: 'Теперь нужно научиться соединять их так, чтобы мозг держал длинные списки как одну историю. Если один образ физически воздействует на другой — мозг автоматически фиксирует связь.',
      AppLanguage.en: 'Now you need to learn how to connect them so that the brain holds long lists as one story. If one image physically affects another, the brain automatically records the connection.',
      AppLanguage.de: 'Jetzt musst du lernen, sie so zu verbinden, dass das Gehirn lange Listen als eine Geschichte speichert. Wenn ein Bild ein anderes physisch beeinflusst, zeichnet das Gehirn die Verbindung automatisch auf.',
    },
    'principle_title': {
      AppLanguage.ru: 'Главный принцип цепочки',
      AppLanguage.en: 'Main Principle of the Chain',
      AppLanguage.de: 'Hauptprinzip der Kette',
    },
    'principle_text': {
      AppLanguage.ru: 'Образ А должен активно взаимодействовать с образом B. Действие = связь. Без действия — нет памяти.',
      AppLanguage.en: 'Image A must actively interact with image B. Action = connection. Without action, there is no memory.',
      AppLanguage.de: 'Bild A muss aktiv mit Bild B interagieren. Aktion = Verbindung. Ohne Aktion gibt es kein Gedächtnis.',
    },
    'example_title': {
      AppLanguage.ru: 'Пример (Яблоко, Нож, Книга)',
      AppLanguage.en: 'Example (Apple, Knife, Book)',
      AppLanguage.de: 'Beispiel (Apfel, Messer, Buch)',
    },
    'bad_example': {
      AppLanguage.ru: 'Плохо: они просто лежат рядом',
      AppLanguage.en: 'Bad: they just lie next to each other',
      AppLanguage.de: 'Schlecht: sie liegen einfach nebeneinander',
    },
    'good_example': {
      AppLanguage.ru: 'Хорошо: Нож режет яблоко, а из него вытекают страницы книги',
      AppLanguage.en: 'Good: A knife cuts an apple, and book pages flow out of it',
      AppLanguage.de: 'Gut: Ein Messer schneidet einen Apfel, und Buchseiten fließen daraus hervor',
    },
  };

  static const lociLesson = {
    'title': {
      AppLanguage.ru: 'Метод Локи (Дворец)',
      AppLanguage.en: 'Method of Loci (Palace)',
      AppLanguage.de: 'Loci-Methode (Palast)',
    },
    'subtitle': {
      AppLanguage.ru: 'Твой первый Дворец Памяти.',
      AppLanguage.en: 'Your first Memory Palace.',
      AppLanguage.de: 'Dein erster Gedächtnispalast.',
    },
    'what_is_title': {
      AppLanguage.ru: 'Что это такое',
      AppLanguage.en: 'What is it',
      AppLanguage.de: 'Was ist das',
    },
    'what_is_text': {
      AppLanguage.ru: 'Метод Локи — древнейшая техника. Ты создаёшь мысленный маршрут из знакомых мест и размещаешь на нём образы.',
      AppLanguage.en: 'Loci method is an ancient technique. You create a mental route of familiar places and place images on it.',
      AppLanguage.de: 'Loci-Methode ist eine antike Technik. Du erstellst eine mentale Route bekannter Orte und platzierst Bilder darauf.',
    },
    'screen_title': {
      AppLanguage.ru: 'Мысленный экран',
      AppLanguage.en: 'Mental Screen',
      AppLanguage.de: 'Mentaler Bildschirm',
    },
    'screen_text': {
      AppLanguage.ru: 'Это внутренняя сцена, на которой ты "видишь" свои образы: предмет, место, действие.',
      AppLanguage.en: 'This is the internal stage where you "see" your images: object, place, action.',
      AppLanguage.de: 'Dies ist die interne Bühne, auf der du deine Bilder "siehst": Objekt, Ort, Aktion.',
    },
    'start_title': {
      AppLanguage.ru: 'С чего начать',
      AppLanguage.en: 'Where to start',
      AppLanguage.de: 'Wo anfangen',
    },
    'start_text': {
      AppLanguage.ru: 'Лучшее место для первого дворца — твоя собственная кухня. Она знакома и в ней много объектов.',
      AppLanguage.en: 'The best place for the first palace is your own kitchen. It is familiar and has many objects.',
      AppLanguage.de: 'Der beste Ort für den ersten Palast ist deine eigene Küche. Sie ist vertraut und hat viele Objekte.',
    },
    'direction_title': {
      AppLanguage.ru: 'Правило направления',
      AppLanguage.en: 'Direction Rule',
      AppLanguage.de: 'Richtungsregel',
    },
    'direction_text': {
      AppLanguage.ru: 'Маршрут должен быть линейным (например, по часовой стрелке). Мозг любит порядок.',
      AppLanguage.en: 'The route must be linear (e.g., clockwise). The brain loves order.',
      AppLanguage.de: 'Die Route muss linear sein (z.B. im Uhrzeigersinn). Das Gehirn liebt Ordnung.',
    },
  };

  static const numbersLesson = {
    'title': {
      AppLanguage.ru: 'Запоминание чисел',
      AppLanguage.en: 'Memorizing Numbers',
      AppLanguage.de: 'Zahlen merken',
    },
    'subtitle': {
      AppLanguage.ru: 'Как превратить цифры в образы.',
      AppLanguage.en: 'How to turn numbers into images.',
      AppLanguage.de: 'Wie man Zahlen in Bilder verwandelt.',
    },
    'why_title': {
      AppLanguage.ru: 'Почему мозг не помнит числа',
      AppLanguage.en: 'Why the brain doesn\'t remember numbers',
      AppLanguage.de: 'Warum das Gehirn Zahlen nicht behält',
    },
    'why_text': {
      AppLanguage.ru: 'Числа — это абстракции. У них нет формы, цвета или запаха. Для мозга это просто шум.',
      AppLanguage.en: 'Numbers are abstractions. They have no shape, color, or smell. For the brain, it\'s just noise.',
      AppLanguage.de: 'Zahlen sind Abstraktionen. Sie haben keine Form, Farbe oder Geruch. Für das Gehirn ist es nur Lärm.',
    },
    'how_it_works_title': {
      AppLanguage.ru: 'Как это работает',
      AppLanguage.en: 'How it works',
      AppLanguage.de: 'Wie es funktioniert',
    },
    'how_it_works_text': {
      AppLanguage.ru: 'Ты создаёшь систему образов, где каждая цифра превращается в конкретный предмет (1 → свеча, 2 → лебедь).',
      AppLanguage.en: 'You create an image system where each digit turns into a specific object (1 → candle, 2 → swan).',
      AppLanguage.de: 'Du erstellst ein Bildsystem, in dem jede Ziffer zu einem bestimmten Objekt wird (1 → Kerze, 2 → Schwan).',
    },
    'foundation_title': {
      AppLanguage.ru: 'Образы 1–10 — твой фундамент',
      AppLanguage.en: 'Images 1–10 — your foundation',
      AppLanguage.de: 'Bilder 1–10 — dein Fundament',
    },
    'foundation_text': {
      AppLanguage.ru: 'Это строительные блоки для всего: дат, телефонов, длинных последовательностей и даже числа π.',
      AppLanguage.en: 'These are the building blocks for everything: dates, phones, long sequences, and even pi.',
      AppLanguage.de: 'Dies sind die Bausteine für alles: Daten, Telefone, lange Sequenzen und sogar Pi.',
    },
  };

  static const numberImagesLabels = {
    'title': {
      AppLanguage.ru: 'Образы для чисел',
      AppLanguage.en: 'Number Images',
      AppLanguage.de: 'Zahlenbilder',
    },
    'not_available': {
      AppLanguage.ru: 'Сейчас недоступно',
      AppLanguage.en: 'Currently not available',
      AppLanguage.de: 'Derzeit nicht verfügbar',
    },
  };
}

const String _kPrefsPaletteIndex = 'app_palette_index';
const String _kPrefsLanguage = 'app_language';
const String _kPrefsBlackSuitAlwaysWhite = 'cards_black_suit_always_white';

final ValueNotifier<bool> blackSuitAlwaysWhite = ValueNotifier(false);

Future<void> persistLanguage(AppLanguage lang) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kPrefsLanguage, lang.name);
  await CloudSyncService.instance.syncNow();
}

Future<void> persistPaletteIndex(int index) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_kPrefsPaletteIndex, index);
  await CloudSyncService.instance.syncNow();
}

Future<void> persistBlackSuitAlwaysWhite(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kPrefsBlackSuitAlwaysWhite, value);
  blackSuitAlwaysWhite.value = value;
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (_) {
    firebaseReady = false;
  }
  final prefs = await SharedPreferences.getInstance();
  await ProgressService.instance.init();
  await ProgressService.instance.onAppOpened();
  await QuestService.instance.init();
  await CloudSyncService.instance.init(firebaseReady: firebaseReady);
  
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

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: appPalettes[safeIdx].background,
  ));
  await requestMediaPermissions();
  runApp(const MemoryArtApp());
}
enum TrainingMode { standard, binary, words, images, cards }

class MemoryArtApp extends StatelessWidget {
  const MemoryArtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, lang, _) {
        return ValueListenableBuilder<AppPalette>(
          valueListenable: appPalette,
          builder: (context, palette, _) {
            final isLight = palette.background.computeLuminance() > 0.5;
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
              title: 'Mnemonik',
              theme: ThemeData(
                brightness: isLight ? Brightness.light : Brightness.dark,
                scaffoldBackgroundColor: palette.background,
                primaryColor: palette.accent,
                colorScheme: isLight 
                  ? ColorScheme.light(
                      primary: palette.accent,
                      secondary: palette.accent,
                      surface: palette.surface,
                      onSurface: palette.accent, // Текст становится карамельным (акцентным) в светлых темах
                    )
                  : ColorScheme.dark(
                      primary: palette.accent,
                      secondary: palette.accent,
                      surface: palette.surface,
                      onSurface: Colors.white, // Белый для темных тем
                    ),
                fontFamily: 'Roboto',
                textTheme: TextTheme(
                  bodyLarge: TextStyle(color: isLight ? palette.accent : Colors.white),
                  bodyMedium: TextStyle(color: isLight ? palette.accent.withOpacity(0.7) : Colors.white70),
                ),
              ),
              home: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: KeyedSubtree(
                  key: ValueKey(lang),
                  child: const AuthGate(),
                ),
              ),
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
    return ValueListenableBuilder<User?>(
      valueListenable: CloudSyncService.instance.user,
      builder: (context, user, _) {
        if (!CloudSyncService.instance.firebaseReady) {
          return const MainMenuScreen();
        }
        if (user == null) {
          return const AuthScreen();
        }
        return const MainMenuScreen();
      },
    );
  }
}

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_NeuralNode> _nearLayer;
  late final List<_NeuralNode> _farLayer;

  @override
  void initState() {
    super.initState();
    final random = Random(72413);
    _nearLayer = List.generate(18, (i) => _NeuralNode.random(random, i, 1.0));
    _farLayer = List.generate(14, (i) => _NeuralNode.random(random, i + 99, 0.65));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _NeuralBackgroundPainter(
            t: _controller.value,
            nearLayer: _nearLayer,
            farLayer: _farLayer,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _NeuralNode {
  final double x;
  final double y;
  final double radius;
  final double drift;
  final double phaseX;
  final double phaseY;
  final double speed;
  final Color color;

  const _NeuralNode({
    required this.x,
    required this.y,
    required this.radius,
    required this.drift,
    required this.phaseX,
    required this.phaseY,
    required this.speed,
    required this.color,
  });

  factory _NeuralNode.random(Random r, int seed, double scale) {
    final palette = [
      const Color(0xFF52C8FF),
      const Color(0xFF6E7BFF),
      const Color(0xFF9A6DFF),
    ];
    final c = palette[(seed + r.nextInt(999)) % palette.length];
    return _NeuralNode(
      x: r.nextDouble(),
      y: r.nextDouble(),
      radius: (0.8 + r.nextDouble() * 1.8) * scale,
      drift: (8 + r.nextDouble() * 18) * scale,
      phaseX: r.nextDouble() * pi * 2,
      phaseY: r.nextDouble() * pi * 2,
      speed: 0.45 + r.nextDouble() * 0.7,
      color: c,
    );
  }
}

class _NeuralBackgroundPainter extends CustomPainter {
  final double t;
  final List<_NeuralNode> nearLayer;
  final List<_NeuralNode> farLayer;

  _NeuralBackgroundPainter({
    required this.t,
    required this.nearLayer,
    required this.farLayer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF05060A),
          Color(0xFF090B14),
          Color(0xFF120C1E),
          Color(0xFF080910),
        ],
        stops: [0.0, 0.4, 0.78, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    _drawLayer(
      canvas,
      size,
      farLayer,
      baseOpacity: 0.2,
      lineThreshold: 108,
      layerSpeed: 0.65,
    );
    _drawLayer(
      canvas,
      size,
      nearLayer,
      baseOpacity: 0.34,
      lineThreshold: 132,
      layerSpeed: 1.0,
    );
  }

  void _drawLayer(
    Canvas canvas,
    Size size,
    List<_NeuralNode> nodes, {
    required double baseOpacity,
    required double lineThreshold,
    required double layerSpeed,
  }) {
    final points = <Offset>[];
    final opacities = <double>[];

    final wave = t * pi * 2 * layerSpeed;
    final parallaxDx = sin(wave * 0.38) * 6 * layerSpeed;
    final parallaxDy = cos(wave * 0.32) * 5 * layerSpeed;

    for (final n in nodes) {
      final dx = sin(wave * n.speed + n.phaseX) * n.drift + parallaxDx;
      final dy = cos(wave * (n.speed * 0.9) + n.phaseY) * n.drift + parallaxDy;
      final px = n.x * size.width + dx;
      final py = n.y * size.height + dy;
      points.add(Offset(px, py));
      opacities.add(baseOpacity * (0.72 + 0.28 * sin(wave + n.phaseX).abs()));
    }

    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        final d = (points[i] - points[j]).distance;
        if (d > lineThreshold) continue;
        final link = (1 - d / lineThreshold) * 0.85;
        final pulse = 0.5 + 0.5 * sin(wave * 1.15 + (i * 0.37) + (j * 0.19));
        final alpha = link * pulse * min(opacities[i], opacities[j]) * 0.7;
        if (alpha < 0.02) continue;
        final linePaint = Paint()
          ..color = const Color(0xFF7DB7FF).withOpacity(alpha)
          ..strokeWidth = 0.7
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4);
        canvas.drawLine(points[i], points[j], linePaint);
      }
    }

    for (int i = 0; i < points.length; i++) {
      final n = nodes[i];
      final p = points[i];
      final glowPaint = Paint()
        ..color = n.color.withOpacity(opacities[i] * 0.42)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.5);
      canvas.drawCircle(p, n.radius * 2.8, glowPaint);

      final corePaint = Paint()
        ..shader = ui.Gradient.radial(
          p,
          n.radius * 1.6,
          [
            Colors.white.withOpacity(0.85),
            n.color.withOpacity(opacities[i] * 0.85),
            n.color.withOpacity(0),
          ],
          const [0.0, 0.55, 1.0],
        );
      canvas.drawCircle(p, n.radius * 1.7, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NeuralBackgroundPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}

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
                          icon: Icons.login_rounded,
                          label: AppTexts.get('cloud_sign_in'),
                          enabled: !busy,
                          onTap: () => _runAuthAction(
                            context,
                            () => CloudSyncService.instance.signInWithGoogle(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _authButton(
                          context,
                          icon: Icons.alternate_email_rounded,
                          label: 'Войти через Email',
                          enabled: !busy,
                          onTap: () => _showEmailAuthDialog(context),
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
                          onTap: () => _runAuthAction(
                            context,
                            () => CloudSyncService.instance.signInAnonymously(),
                          ),
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

  Future<void> _runAuthAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    await action();
    if (!context.mounted) return;
    final err = CloudSyncService.instance.lastError.value;
    if (err == null) return;
    final details = err.contains('configured')
        ? '\n${AppTexts.get('auth_google_setup_hint')}'
        : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${AppTexts.get('auth_signin_failed')}: $err$details'),
      ),
    );
  }

  Future<void> _showEmailAuthDialog(BuildContext context) async {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool isRegister = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: palette.border.withOpacity(0.35)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: onSurface.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isRegister ? 'Регистрация по Email' : 'Вход по Email',
                      style: TextStyle(color: onSurface, fontWeight: FontWeight.w700, fontSize: 17),
                    ),
                    const SizedBox(height: 14),
                    if (isRegister) ...[
                      TextField(
                        controller: nameCtrl,
                        style: TextStyle(color: onSurface),
                        decoration: InputDecoration(
                          hintText: 'Имя аккаунта',
                          hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                          filled: true,
                          fillColor: palette.background.withOpacity(0.45),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: palette.border.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: palette.border.withOpacity(0.3)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: onSurface),
                      decoration: InputDecoration(
                        hintText: 'Email',
                        hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                        filled: true,
                        fillColor: palette.background.withOpacity(0.45),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: palette.border.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: palette.border.withOpacity(0.3)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      style: TextStyle(color: onSurface),
                      decoration: InputDecoration(
                        hintText: 'Пароль (мин. 6 символов)',
                        hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                        filled: true,
                        fillColor: palette.background.withOpacity(0.45),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: palette.border.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: palette.border.withOpacity(0.3)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setLocal(() => isRegister = !isRegister),
                      child: Text(
                        isRegister
                            ? 'Уже есть аккаунт? Войти'
                            : 'Нет аккаунта? Зарегистрироваться',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Отмена'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
                            ),
                            onPressed: () async {
                              final name = nameCtrl.text.trim();
                              final email = emailCtrl.text.trim();
                              final pass = passCtrl.text;
                              if (email.isEmpty || pass.length < 6 || (isRegister && name.isEmpty)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Проверь поля: имя (для регистрации), email и пароль.')),
                                );
                                return;
                              }
                              Navigator.pop(ctx);
                              if (isRegister) {
                                await _runAuthAction(
                                  context,
                                  () => CloudSyncService.instance.registerWithEmail(
                                    email: email,
                                    password: pass,
                                    displayName: name,
                                  ),
                                );
                              } else {
                                await _runAuthAction(
                                  context,
                                  () => CloudSyncService.instance.signInWithEmail(
                                    email: email,
                                    password: pass,
                                  ),
                                );
                              }
                            },
                            child: Text(isRegister ? 'Создать' : 'Войти'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

enum _LeaderboardRange { day, week, allTime }

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  _LeaderboardRange _range = _LeaderboardRange.day;

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final stream = switch (_range) {
      _LeaderboardRange.day => LeaderboardService.instance.watchDailyTop(limit: 50),
      _LeaderboardRange.week => LeaderboardService.instance.watchWeeklyTop(limit: 50),
      _LeaderboardRange.allTime => LeaderboardService.instance.watchAllTimeTop(limit: 50),
    };

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: palette.background,
        foregroundColor: onSurface,
        title: Text(
          AppTexts.get('leaderboard_open'),
          style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: StreamBuilder<List<LeaderboardEntry>>(
          stream: stream,
          builder: (context, snapshot) {
            final data = snapshot.data ?? const <LeaderboardEntry>[];
            final meUid = CloudSyncService.instance.user.value?.uid;
            final myIndex = meUid == null ? -1 : data.indexWhere((e) => e.uid == meUid);
            final myEntry = myIndex >= 0 ? data[myIndex] : null;
            final nextEntry = (myIndex > 0) ? data[myIndex - 1] : null;
            final pointsToNext = (myEntry == null || nextEntry == null)
                ? 0
                : max(0, nextEntry.points - myEntry.points + 1);
            final progressToNext = (myEntry == null || nextEntry == null || nextEntry.points <= 0)
                ? 1.0
                : (myEntry.points / nextEntry.points).clamp(0.0, 1.0);

            return Column(
              children: [
                _buildRangeTabs(onSurface),
                const SizedBox(height: 12),
                if (data.isNotEmpty) _buildPodium(data.take(3).toList(growable: false), onSurface),
                if (data.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        AppTexts.get('leaderboard_empty'),
                        style: TextStyle(color: onSurface.withOpacity(0.45), fontSize: 12),
                      ),
                    ),
                  )
                else ...[
                  const SizedBox(height: 12),
                  _buildYourRankCard(
                    onSurface,
                    myIndex: myIndex,
                    myEntry: myEntry,
                    pointsToNext: pointsToNext,
                    progressToNext: progressToNext,
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final row = data[index];
                        return _LeaderboardRow(
                          rank: index + 1,
                          entry: row,
                          isMe: row.uid == meUid,
                        );
                      },
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRangeTabs(Color onSurface) {
    Widget tab(String label, _LeaderboardRange value) {
      final active = _range == value;
      return Expanded(
        child: _TapScale(
          onTap: () => setState(() => _range = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: active
                  ? LinearGradient(
                      colors: [
                        appAccentColor.value.withOpacity(0.28),
                        const Color(0xFF52C8FF).withOpacity(0.22),
                      ],
                    )
                  : null,
              color: active ? null : appPalette.value.surface,
              border: Border.all(
                color: active
                    ? appAccentColor.value.withOpacity(0.5)
                    : appPalette.value.border.withOpacity(0.35),
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: const Color(0xFF52C8FF).withOpacity(0.16),
                        blurRadius: 18,
                        spreadRadius: 0.3,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: onSurface.withOpacity(active ? 0.96 : 0.6),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.9,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tab('Day', _LeaderboardRange.day),
        const SizedBox(width: 8),
        tab('Week', _LeaderboardRange.week),
        const SizedBox(width: 8),
        tab('All-time', _LeaderboardRange.allTime),
      ],
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> top, Color onSurface) {
    Widget podiumCard({
      required int place,
      required LeaderboardEntry entry,
      required double height,
      required bool highlight,
    }) {
      final base = place == 1 ? const Color(0xFF52C8FF) : const Color(0xFF8A6DFF);
      return Expanded(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.94, end: 1),
          duration: Duration(milliseconds: 420 + place * 80),
          curve: Curves.easeOutBack,
          builder: (context, v, child) => Transform.scale(scale: v, child: child),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  base.withOpacity(highlight ? 0.35 : 0.24),
                  appPalette.value.surface.withOpacity(0.92),
                ],
              ),
              border: Border.all(color: base.withOpacity(highlight ? 0.6 : 0.42)),
              boxShadow: highlight
                  ? [
                      BoxShadow(
                        color: base.withOpacity(0.34),
                        blurRadius: 24,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                    border: Border.all(color: base.withOpacity(0.7)),
                  ),
                  child: Center(
                    child: Text(
                      '$place',
                      style: TextStyle(
                        color: onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entry.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                _AnimatedScoreText(
                  value: entry.points,
                  style: TextStyle(
                    color: base.withOpacity(0.95),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final first = top.isNotEmpty ? top[0] : const LeaderboardEntry(uid: '-', displayName: '-', points: 0);
    final second = top.length > 1 ? top[1] : const LeaderboardEntry(uid: '-', displayName: '-', points: 0);
    final third = top.length > 2 ? top[2] : const LeaderboardEntry(uid: '-', displayName: '-', points: 0);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      decoration: BoxDecoration(
        color: appPalette.value.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appPalette.value.border.withOpacity(0.42)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          podiumCard(place: 2, entry: second, height: 130, highlight: false),
          podiumCard(place: 1, entry: first, height: 158, highlight: true),
          podiumCard(place: 3, entry: third, height: 118, highlight: false),
        ],
      ),
    );
  }

  Widget _buildYourRankCard(
    Color onSurface, {
    required int myIndex,
    required LeaderboardEntry? myEntry,
    required int pointsToNext,
    required double progressToNext,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: appPalette.value.surface.withOpacity(0.9),
        border: Border.all(color: appAccentColor.value.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: appAccentColor.value.withOpacity(0.16),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your rank',
            style: TextStyle(
              color: onSurface.withOpacity(0.7),
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Text(
                myIndex >= 0 ? '#${myIndex + 1}' : '--',
                style: TextStyle(
                  color: onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  myEntry?.displayName ?? 'Not ranked yet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: onSurface.withOpacity(0.86), fontSize: 14),
                ),
              ),
              _AnimatedScoreText(
                value: myEntry?.points ?? 0,
                style: TextStyle(
                  color: appAccentColor.value,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressToNext,
              minHeight: 6,
              backgroundColor: onSurface.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation(const Color(0xFF52C8FF).withOpacity(0.9)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            (myIndex <= 0 || myEntry == null)
                ? 'You are at the top'
                : '$pointsToNext points to reach next position',
            style: TextStyle(color: onSurface.withOpacity(0.55), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final bool isMe;

  const _LeaderboardRow({
    required this.rank,
    required this.entry,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = appAccentColor.value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: _TapScale(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isMe ? accent.withOpacity(0.12) : appPalette.value.surface.withOpacity(0.7),
            border: Border.all(
              color: isMe ? accent.withOpacity(0.5) : appPalette.value.border.withOpacity(0.25),
            ),
            boxShadow: isMe
                ? [
                    BoxShadow(
                      color: accent.withOpacity(0.18),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 26,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    color: rank <= 3 ? const Color(0xFF52C8FF) : onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  entry.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isMe ? accent : onSurface.withOpacity(0.9),
                    fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              _AnimatedScoreText(
                value: entry.points,
                style: TextStyle(
                  color: onSurface.withOpacity(0.95),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _TapScale({required this.child, this.onTap});

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapCancel: () => setState(() => _scale = 1),
      onTapUp: (_) => setState(() => _scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 110),
        scale: _scale,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _AnimatedScoreText extends StatefulWidget {
  final int value;
  final TextStyle style;

  const _AnimatedScoreText({
    required this.value,
    required this.style,
  });

  @override
  State<_AnimatedScoreText> createState() => _AnimatedScoreTextState();
}

class _AnimatedScoreTextState extends State<_AnimatedScoreText> {
  int _old = 0;

  @override
  void initState() {
    super.initState();
    _old = widget.value;
  }

  @override
  void didUpdateWidget(covariant _AnimatedScoreText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _old = oldWidget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _old.toDouble(), end: widget.value.toDouble()),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return Text(v.round().toString(), style: widget.style);
      },
    );
  }
}

// --- ВИДЖЕТ ПЕРЕКЛЮЧЕНИЯ ТЕМЫ ---
class ThemeColorSwitcher extends StatefulWidget {
  const ThemeColorSwitcher({super.key, this.initialExpanded = true});

  final bool initialExpanded;

  @override
  State<ThemeColorSwitcher> createState() => _ThemeColorSwitcherState();
}

class _ThemeColorSwitcherState extends State<ThemeColorSwitcher> {
  late bool _isExpanded;
  late final VoidCallback _collapseListener;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
    _collapseListener = () {
      if (_isExpanded && mounted) {
        setState(() => _isExpanded = false);
      }
    };
    paletteCollapseSignal.addListener(_collapseListener);
  }

  @override
  void dispose() {
    paletteCollapseSignal.removeListener(_collapseListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppPalette>(
      valueListenable: appPalette,
      builder: (context, currentPalette, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: currentPalette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: currentPalette.accent.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl, // Расширение влево
            children: [
              _buildPaletteButton(currentPalette),
              Flexible(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: _isExpanded
                      ? ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              textDirection: TextDirection.ltr, // Точки внутри в обычном порядке
                              children: [
                                const SizedBox(width: 8),
                                ...appPalettes.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final palette = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 5),
                                    child: _buildColorDot(idx, palette, currentPalette),
                                  );
                                }),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaletteButton(AppPalette currentPalette) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: currentPalette.accent.withOpacity(0.22),
            shape: BoxShape.circle,
            border: Border.all(color: currentPalette.accent, width: 1.4),
          ),
          child: Icon(
            _isExpanded ? Icons.close_rounded : Icons.palette_outlined,
            size: 18,
            color: currentPalette.accent,
          ),
        ),
      ),
    );
  }

  Widget _buildColorDot(int index, AppPalette palette, AppPalette currentPalette) {
    final isActive = palette.accent == currentPalette.accent &&
        palette.background == currentPalette.background;
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        appPalette.value = palette;
        appAccentColor.value = palette.accent;
        persistPaletteIndex(index);
        // Закрываем палитру после выбора
        setState(() => _isExpanded = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        width: isActive ? 30 : 14,
        height: isActive ? 30 : 14,
        decoration: BoxDecoration(
          color: palette.accent,
          shape: BoxShape.circle,
          border: isActive ? Border.all(color: palette.accent, width: 2) : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: palette.accent.withOpacity(0.55),
                    blurRadius: 10,
                    spreadRadius: 1.2,
                  )
                ]
              : [],
        ),
        child: isActive
            ? Center(
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.background,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

// --- ГЛАВНОЕ МЕНЮ ---
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _closePalette() {
    paletteCollapseSignal.value++;
  }

  Future<void> _openScreen(Widget screen) async {
    _closePalette();
    HapticFeedback.lightImpact();
    if (!mounted) return;
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim, _) => screen,
        transitionsBuilder: (context, anim, _, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Spacer(),
                  IconButton(
                    onPressed: () => _openScreen(const SettingsScreen()),
                    icon: Icon(Icons.settings_outlined, color: onSurface.withOpacity(0.62)),
                  ),
                  const SizedBox(width: 4),
                  const ThemeColorSwitcher(initialExpanded: false),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Mnemonica',
                style: TextStyle(
                  color: onSurface.withOpacity(0.95),
                  fontSize: 38,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Neural Hack',
                style: TextStyle(
                  color: accent.withOpacity(0.75),
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2.2,
                ),
              ),
              const SizedBox(height: 18),
              _buildXpProgressHeader(onSurface),
              const SizedBox(height: 18),
              _buildDailyCard(onSurface, accent),
              const SizedBox(height: 22),
              ScaleTransition(
                scale: _pulseAnimation,
                child: _buildPrimaryTrainingButton(onSurface, accent),
              ),
              const SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _quickNavButton(icon: Icons.emoji_events_outlined, onTap: () => _openScreen(const LeaderboardScreen())),
                  _quickNavButton(icon: Icons.lightbulb_outline_rounded, onTap: () => _openScreen(const TechniquesScreen())),
                  _quickNavButton(icon: Icons.bar_chart_rounded, onTap: () => _openScreen(const StatisticsScreen())),
                  _quickNavButton(icon: Icons.task_alt_rounded, onTap: () => _openScreen(const QuestsScreen())),
                ],
              ),
              const Spacer(),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'YOUR BRAIN IS CAPABLE OF MORE',
                  style: TextStyle(color: onSurface.withOpacity(0.2), fontSize: 9, letterSpacing: 3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyCard(Color onSurface, Color accent) {
    return ValueListenableBuilder<QuestState>(
      valueListenable: QuestService.instance.state,
      builder: (context, questState, _) {
        final dailyItems = <Widget>[];
        final visibleCount = min(3, min(questState.dailyQuests.length, questState.dailyStatuses.length));

        for (int i = 0; i < visibleCount; i++) {
          final quest = questState.dailyQuests[i];
          final status = questState.dailyStatuses[i];
          final progress = status.isCompleted
              ? 'OK'
              : '${status.currentValue}/${quest.targetValue}';
          dailyItems.add(
            _dailyTaskRow(
              onSurface: onSurface,
              title: quest.getTitle(appLanguage.value.name),
              progress: progress,
              completed: status.isCompleted,
            ),
          );
          if (i < visibleCount - 1) {
            dailyItems.add(const SizedBox(height: 8));
          }
        }

        if (dailyItems.isEmpty) {
          dailyItems.add(
            Text(
              'Задания обновляются...',
              style: TextStyle(color: onSurface.withOpacity(0.45), fontSize: 12),
            ),
          );
        }

        return GestureDetector(
          onTap: () => _openScreen(const QuestsScreen()),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: appPalette.value.surface,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: appPalette.value.border.withOpacity(0.45)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'DAILY',
                      style: TextStyle(
                        color: onSurface.withOpacity(0.45),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded, color: onSurface.withOpacity(0.35), size: 18),
                  ],
                ),
                const SizedBox(height: 14),
                ...dailyItems,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dailyTaskRow({
    required Color onSurface,
    required String title,
    required String progress,
    bool completed = false,
  }) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: completed ? appAccentColor.value : onSurface.withOpacity(0.35)),
            color: completed ? appAccentColor.value.withOpacity(0.1) : Colors.transparent,
          ),
          child: completed ? Icon(Icons.check_rounded, size: 12, color: appAccentColor.value) : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: onSurface.withOpacity(completed ? 0.55 : 0.78),
              fontSize: 14,
              fontWeight: FontWeight.w300,
              decoration: completed ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        Text(
          progress,
          style: TextStyle(
            color: completed ? appAccentColor.value.withOpacity(0.85) : onSurface.withOpacity(0.45),
            fontSize: 12,
            fontWeight: completed ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryTrainingButton(Color onSurface, Color accent) {
    return GestureDetector(
      onTap: () => _openScreen(const TrainingScreen()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(colors: [accent.withOpacity(0.96), accent]),
          boxShadow: [
            BoxShadow(color: accent.withOpacity(0.38), blurRadius: 20, spreadRadius: 1),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.7),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              'START TRAINING',
              style: TextStyle(
                color: Colors.black.withOpacity(0.84),
                fontWeight: FontWeight.w600,
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickNavButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: appPalette.value.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: appPalette.value.border.withOpacity(0.35)),
        ),
        child: Icon(icon, color: appAccentColor.value.withOpacity(0.9), size: 24),
      ),
    );
  }

  Widget _buildXpProgressHeader(Color onSurface) {
    return ValueListenableBuilder(
      valueListenable: ProgressService.instance.progress,
      builder: (context, p, _) {
        final accent = appAccentColor.value;
        final ratio = p.xpToNextLevel <= 0 ? 0.0 : (p.currentLevelXp / p.xpToNextLevel).clamp(0.0, 1.0);
        final levelTitle = ProgressService.instance.getLevelTitleLabel().toUpperCase();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: accent.withOpacity(0.45)),
                    color: accent.withOpacity(0.08),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.psychology_alt_outlined, size: 13, color: accent.withOpacity(0.95)),
                      const SizedBox(width: 6),
                      Text(
                        levelTitle,
                        style: TextStyle(
                          color: accent.withOpacity(0.95),
                          fontSize: 10,
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: accent.withOpacity(0.45)),
                    color: accent.withOpacity(0.16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_fire_department_rounded, size: 14, color: accent),
                      const SizedBox(width: 6),
                      Text('${p.streak}', style: TextStyle(color: onSurface.withOpacity(0.95), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  levelTitle,
                  style: TextStyle(color: onSurface.withOpacity(0.58), fontSize: 11, letterSpacing: 1.7),
                ),
                const Spacer(),
                Text(
                  '${p.currentLevelXp} / ${p.xpToNextLevel} XP',
                  style: TextStyle(color: onSurface.withOpacity(0.58), fontSize: 12, letterSpacing: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: ratio),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      Container(height: 7, color: Colors.white.withOpacity(0.09)),
                      FractionallySizedBox(
                        widthFactor: v,
                        child: Container(
                          height: 7,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [accent.withOpacity(0.75), accent]),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// --- ЭКРАН НАСТРОЕК ---
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _alwaysWhiteBlackSuits;

  @override
  void initState() {
    super.initState();
    _alwaysWhiteBlackSuits = blackSuitAlwaysWhite.value;
  }

  Future<void> _toggleAlwaysWhiteBlackSuits(bool value) async {
    HapticFeedback.lightImpact();
    await persistBlackSuitAlwaysWhite(value);
    if (!mounted) return;
    setState(() => _alwaysWhiteBlackSuits = value);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, _, __) {
        const settingsBg = Color(0xFF060607);
        const textMain = Color(0xFFEDEDED);
        return Scaffold(
          backgroundColor: settingsBg,
          appBar: AppBar(
            backgroundColor: settingsBg,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: textMain, size: 24),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppTexts.get('settings'),
              style: TextStyle(
                color: textMain,
                fontSize: 20,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.6,
              ),
            ),
            centerTitle: false,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
            children: [
              _buildMinimalSettingsItem(
                context: context,
                title: AppTexts.get('language'),
                subtitle: AppTexts.get('language_desc'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LanguageSettingsScreen())),
              ),
              const SizedBox(height: 32),
              _buildCardSuitsStyleItem(),
              const SizedBox(height: 52),
              _buildMinimalSettingsItem(
                context: context,
                title: AppTexts.get('number_images_labels_title'),
                subtitle: AppTexts.get('manage_associations'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NumberImagesScreen())),
              ),
              const SizedBox(height: 52),
              _buildMinimalSettingsItem(
                context: context,
                title: AppTexts.get('create_route'),
                subtitle: AppTexts.get('create_route_desc'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LociRoutesScreen())),
              ),
              const SizedBox(height: 52),
              _buildMinimalSettingsItem(
                context: context,
                title: AppTexts.get('account'),
                subtitle: AppTexts.get('account_desc'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountScreen())),
              ),
              const SizedBox(height: 52),
              _buildCloudAccountItem(context),
              const SizedBox(height: 36),
              _buildSettingsFooterCredit(),
              const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardSuitsStyleItem() {
    const textMain = Color(0xFFEDEDED);
    const textSub = Color(0xFF9FA1A6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Черная масть всегда белая',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textMain,
            fontSize: 30,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Выкл: черные масти в цвет темы',
          textAlign: TextAlign.center,
          style: const TextStyle(color: textSub, fontSize: 14),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: textSub.withOpacity(0.55)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _alwaysWhiteBlackSuits ? 'Включено' : 'Выключено',
                  style: TextStyle(
                    color: textMain,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Switch(
                value: _alwaysWhiteBlackSuits,
                activeColor: appAccentColor.value,
                onChanged: _toggleAlwaysWhiteBlackSuits,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsFooterCredit() {
    const textSub = Color(0xFF9FA1A6);
    const tgBlue = Color(0xFF2AABEE);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Text(
          'Done By ',
          style: TextStyle(
            color: textSub,
            fontSize: 11,
            letterSpacing: 0.2,
          ),
        ),
        Text(
          'sandora778',
          style: TextStyle(
            color: textSub,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
        SizedBox(width: 5),
        Icon(Icons.send_rounded, color: tgBlue, size: 13),
      ],
    );
  }

  Widget _buildMinimalSettingsItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    const textMain = Color(0xFFEDEDED);
    const textSub = Color(0xFF9FA1A6);
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: textMain,
            fontSize: 34,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: textSub, fontSize: 14),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: textSub.withOpacity(0.55)),
            ),
            child: Text(
              AppTexts.get('more'),
              style: TextStyle(
                color: textMain,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCloudAccountItem(BuildContext context) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return ValueListenableBuilder<bool>(
      valueListenable: CloudSyncService.instance.isBusy,
      builder: (context, busy, _) {
        return ValueListenableBuilder(
          valueListenable: CloudSyncService.instance.user,
          builder: (context, user, __) {
            final signedIn = user != null;
            final accountName = CloudSyncService.instance.accountTitle();
            final subtitle = signedIn
                ? AppTexts.get('cloud_connected_as', params: {'email': accountName})
                : AppTexts.get('cloud_not_connected');

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: palette.border.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: appAccentColor.value.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.cloud_done_rounded, color: appAccentColor.value, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTexts.get('cloud_account'),
                              style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(color: onSurface.withOpacity(0.45), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _smallActionButton(
                        context,
                        busy
                            ? null
                            : () async {
                                if (signedIn) {
                                  await CloudSyncService.instance.syncNow();
                                } else {
                                  await CloudSyncService.instance.signInWithGoogle();
                                }
                              },
                        signedIn ? AppTexts.get('cloud_sync_now') : AppTexts.get('cloud_sign_in'),
                      ),
                      if (!signedIn)
                        _smallActionButton(
                          context,
                          busy
                              ? null
                              : () async {
                                  await CloudSyncService.instance.signInAnonymously();
                                },
                          AppTexts.get('auth_continue_guest'),
                        ),
                      if (signedIn)
                        _smallActionButton(
                          context,
                          busy
                              ? null
                              : () async {
                                  await CloudSyncService.instance.signOut();
                                },
                          AppTexts.get('cloud_sign_out'),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _smallActionButton(BuildContext context, Future<void> Function()? onTap, String label) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () async {
              await onTap();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: onTap == null ? appPalette.value.border.withOpacity(0.35) : appAccentColor.value.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: onTap == null ? appPalette.value.border.withOpacity(0.5) : appAccentColor.value.withOpacity(0.4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: onTap == null ? onSurface.withOpacity(0.5) : onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _LociRoute {
  final String name;
  final List<String> loci;

  _LociRoute({
    required this.name,
    required this.loci,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'loci': loci,
      };

  static _LociRoute fromJson(Map<String, dynamic> json) {
    final rawLoci = json['loci'];
    return _LociRoute(
      name: (json['name'] ?? '').toString().trim(),
      loci: rawLoci is List ? rawLoci.map((e) => e.toString()).toList() : <String>[],
    );
  }
}

class LociRoutesScreen extends StatefulWidget {
  const LociRoutesScreen({super.key});

  @override
  State<LociRoutesScreen> createState() => _LociRoutesScreenState();
}

class _LociRoutesScreenState extends State<LociRoutesScreen> {
  final List<_LociRoute> _routes = [];
  int _selectedRoute = 0;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLociRoutesPrefsKey);
    if (raw == null || raw.trim().isEmpty) {
      _routes.clear();
      _selectedRoute = 0;
      if (mounted) setState(() {});
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _routes
          ..clear()
          ..addAll(
            decoded
                .whereType<Map>()
                .map((e) => _LociRoute.fromJson(Map<String, dynamic>.from(e)))
                .where((e) => e.name.isNotEmpty),
          );
      }
      _selectedRoute = _selectedRoute.clamp(0, _routes.isEmpty ? 0 : _routes.length - 1);
      if (mounted) setState(() {});
    } catch (_) {
      _routes
        ..clear();
      _selectedRoute = 0;
      if (mounted) setState(() {});
    }
  }

  Future<void> _saveRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kLociRoutesPrefsKey,
      jsonEncode(_routes.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _addRoute() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: appPalette.value.surface,
          title: Text('Новый маршрут', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: const InputDecoration(hintText: 'Название маршрута'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Добавить')),
          ],
        );
      },
    );
    if (value == null || value.isEmpty) return;
    setState(() {
      _routes.add(_LociRoute(name: value, loci: <String>[]));
      _selectedRoute = _routes.length - 1;
    });
    await _saveRoutes();
  }

  Future<void> _addLoci() async {
    if (_routes.isEmpty || _selectedRoute < 0 || _selectedRoute >= _routes.length) return;
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: appPalette.value.surface,
          title: Text('Новая локация', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: const InputDecoration(hintText: 'Название локации'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Добавить')),
          ],
        );
      },
    );
    if (value == null || value.isEmpty) return;
    setState(() {
      _routes[_selectedRoute].loci.add(value);
    });
    await _saveRoutes();
  }

  Future<void> _removeRoute(int idx) async {
    if (idx < 0 || idx >= _routes.length) return;
    setState(() {
      _routes.removeAt(idx);
      _selectedRoute = _selectedRoute.clamp(0, _routes.isEmpty ? 0 : _routes.length - 1);
    });
    await _saveRoutes();
  }

  Future<void> _removeLoci(int idx) async {
    if (_routes.isEmpty || _selectedRoute < 0 || _selectedRoute >= _routes.length) return;
    final loci = _routes[_selectedRoute].loci;
    if (idx < 0 || idx >= loci.length) return;
    setState(() {
      loci.removeAt(idx);
    });
    await _saveRoutes();
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = appAccentColor.value;

    final current = (_routes.isEmpty || _selectedRoute < 0 || _selectedRoute >= _routes.length)
        ? null
        : _routes[_selectedRoute];

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurface.withOpacity(0.6), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppTexts.get('create_route'),
          style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.6),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: _routes.isEmpty
            ? Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: palette.border.withOpacity(0.35)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.route_rounded, size: 26, color: accent.withOpacity(0.85)),
                      const SizedBox(height: 10),
                      Text('Маршрутов пока нет', style: TextStyle(color: onSurface.withOpacity(0.9), fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Text('Создай первый маршрут и добавь локации', textAlign: TextAlign.center, style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12)),
                      const SizedBox(height: 14),
                      _routeActionButton('Создать маршрут', _addRoute),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: palette.border.withOpacity(0.35)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showModalBottomSheet<int>(
                                context: context,
                                backgroundColor: palette.surface,
                                builder: (ctx) => ListView.builder(
                                  itemCount: _routes.length,
                                  itemBuilder: (ctx, i) => ListTile(
                                    title: Text(_routes[i].name, style: TextStyle(color: onSurface)),
                                    trailing: i == _selectedRoute ? Icon(Icons.check, color: accent) : null,
                                    onTap: () => Navigator.pop(ctx, i),
                                  ),
                                ),
                              );
                              if (picked == null) return;
                              setState(() => _selectedRoute = picked);
                            },
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    current!.name,
                                    style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(Icons.expand_more_rounded, color: onSurface.withOpacity(0.45)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _iconActionBtn(Icons.add_rounded, _addRoute),
                        const SizedBox(width: 6),
                        _iconActionBtn(Icons.note_add_outlined, _addLoci),
                        const SizedBox(width: 6),
                        _iconActionBtn(Icons.delete_outline_rounded, () => _removeRoute(_selectedRoute)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: current.loci.isEmpty
                        ? Center(
                            child: Text(
                              'Добавь первую локацию',
                              style: TextStyle(color: onSurface.withOpacity(0.42), fontSize: 13),
                            ),
                          )
                        : ListView.separated(
                            itemCount: current.loci.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: palette.border.withOpacity(0.25)),
                            itemBuilder: (context, index) {
                              final value = current.loci[index];
                              return SizedBox(
                                height: 44,
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 32,
                                      child: Text(
                                        '${index + 1}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        value,
                                        style: TextStyle(color: onSurface.withOpacity(0.92), fontSize: 15),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _removeLoci(index),
                                      icon: Icon(Icons.close_rounded, color: onSurface.withOpacity(0.35), size: 18),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _iconActionBtn(IconData icon, VoidCallback onTap) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: appPalette.value.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: appPalette.value.border.withOpacity(0.45)),
        ),
        child: Icon(icon, size: 17, color: onSurface.withOpacity(0.7)),
      ),
    );
  }

  Widget _routeActionButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: appAccentColor.value.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: appAccentColor.value.withOpacity(0.35)),
        ),
        child: Text(
          label,
          style: TextStyle(color: appAccentColor.value, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// --- УРОК: ЗАПОМИНАНИЕ ЧИСЕЛ ---
class MnemonicNumbersLessonWidget extends StatefulWidget {
  const MnemonicNumbersLessonWidget({super.key});

  @override
  State<MnemonicNumbersLessonWidget> createState() => _MnemonicNumbersLessonWidgetState();
}

class _MnemonicNumbersLessonWidgetState extends State<MnemonicNumbersLessonWidget> with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    for (int i = 0; i < 3; i++) {
      HapticFeedback.lightImpact();
      await _blinkController.forward();
      await _blinkController.reverse();
      await Future.delayed(const Duration(milliseconds: 50));
    }
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isRu = appLanguage.value == AppLanguage.ru;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _handlePress,
          child: FadeTransition(
            opacity: _blinkAnimation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _isExpanded ? accent.withOpacity(0.05) : accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_isExpanded ? Icons.unfold_less_rounded : Icons.numbers_rounded, size: 14, color: accent),
                  const SizedBox(width: 8),
                  Text(_isExpanded ? AppTexts.get('hide') : AppTexts.get('more'),
                    style: TextStyle(color: accent, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
          child: _isExpanded
              ? Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildStepCard(
                      AppTexts.translate(AppTexts.numbersLesson['why_title'] as Map<AppLanguage, String>),
                      AppTexts.translate(AppTexts.numbersLesson['why_text'] as Map<AppLanguage, String>),
                      Icons.blur_on_rounded, accent,
                    ),
                    const SizedBox(height: 16),
                    _buildStepCard(
                      AppTexts.translate(AppTexts.numbersLesson['how_it_works_title'] as Map<AppLanguage, String>),
                      AppTexts.translate(AppTexts.numbersLesson['how_it_works_text'] as Map<AppLanguage, String>),
                      Icons.auto_fix_high_rounded, accent,
                    ),
                    const SizedBox(height: 16),
                    _buildStepCard(
                      AppTexts.translate(AppTexts.numbersLesson['foundation_title'] as Map<AppLanguage, String>),
                      AppTexts.translate(AppTexts.numbersLesson['foundation_text'] as Map<AppLanguage, String>),
                      Icons.architecture_rounded, accent,
                    ),
                    const SizedBox(height: 16),
                    _buildExampleSection(accent),
                    const SizedBox(height: 16),
                    _buildLociIntegration(accent),
                    const SizedBox(height: 16),
                    _buildInteractiveTask(accent),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildStepCard(String title, String content, IconData icon, Color accent) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: appPalette.value.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: accent, size: 20), const SizedBox(width: 12), Text(title, style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 16),
          Text(content, style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildExampleSection(Color accent) {
    final isRu = appLanguage.value == AppLanguage.ru;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: accent.withOpacity(0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: accent.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isRu ? "КАК ИСПОЛЬЗОВАТЬ ОБРАЗЫ" : "HOW TO USE IMAGES", style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          _buildMiniExample(isRu ? "Число 27" : "Number 27", isRu ? "2=Лебедь, 7=Коса. Итог: Лебедь косит траву огромной косой." : "2=Swan, 7=Scythe. Result: A swan mows grass with a huge scythe.", accent),
          _buildMiniExample(isRu ? "Число 406" : "Number 406", isRu ? "4=Стул, 0=Яблоко, 6=Сундук. Итог: На стуле лежит яблоко, внутри которого сундук." : "4=Chair, 0=Apple, 6=Chest. Result: An apple is on a chair, with a chest inside it.", accent),
        ],
      ),
    );
  }

  Widget _buildMiniExample(String title, String desc, Color accent) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 4), Text(desc, style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13))]));
  }

  Widget _buildLociIntegration(Color accent) {
    final isRu = appLanguage.value == AppLanguage.ru;
    return _buildStepCard(
      isRu ? "Числа + Метод Локи" : "Numbers + Loci Method",
      isRu ? "Берёшь число → Превращаешь в образ → Кладёшь в локацию дворца памяти." : "Take a number → Turn it into an image → Place it in a memory palace location.",
      Icons.hub_rounded, accent,
    );
  }

  Widget _buildInteractiveTask(Color accent) {
    final isRu = appLanguage.value == AppLanguage.ru;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [accent.withOpacity(0.15), accent.withOpacity(0.05)]), borderRadius: BorderRadius.circular(24), border: Border.all(color: accent.withOpacity(0.3))),
      child: Column(
        children: [
          Icon(Icons.psychology_alt_rounded, color: accent, size: 32),
          const SizedBox(height: 12),
          Text(isRu ? "ЗАДАНИЕ №4" : "TASK #4", style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(isRu ? "Числа: 3, 8, 1, 7. Преврати их в свои образы и размести в первых 4 точках кухни!" : "Numbers: 3, 8, 1, 7. Turn them into your images and place them in the first 4 points of the kitchen!", textAlign: TextAlign.center, style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 14)),
        ],
      ),
    );
  }
}

// --- УРОК: БИНАРНЫЕ ЧИСЛА ---
class MnemonicBinaryLessonWidget extends StatefulWidget {
  const MnemonicBinaryLessonWidget({super.key});

  @override
  State<MnemonicBinaryLessonWidget> createState() => _MnemonicBinaryLessonWidgetState();
}

class _MnemonicBinaryLessonWidgetState extends State<MnemonicBinaryLessonWidget> with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    for (int i = 0; i < 3; i++) {
      HapticFeedback.lightImpact();
      await _blinkController.forward();
      await _blinkController.reverse();
      await Future.delayed(const Duration(milliseconds: 50));
    }
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final lang = appLanguage.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _handlePress,
          child: FadeTransition(
            opacity: _blinkAnimation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _isExpanded ? accent.withOpacity(0.05) : accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_isExpanded ? Icons.unfold_less_rounded : Icons.data_array_rounded, size: 14, color: accent),
                  const SizedBox(width: 8),
                  Text(_isExpanded ? AppTexts.get('hide') : AppTexts.get('more'),
                    style: TextStyle(color: accent, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
          child: _isExpanded
              ? Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildStepCard(
                      BinaryLessonContent.binaryData['why_title']![lang]!,
                      BinaryLessonContent.binaryData['why_text']![lang]!,
                      Icons.blur_on_rounded, accent,
                    ),
                    const SizedBox(height: 16),
                    _buildStepCard(
                      BinaryLessonContent.binaryData['coding_title']![lang]!,
                      BinaryLessonContent.binaryData['coding_text']![lang]!,
                      Icons.settings_ethernet_rounded, accent,
                    ),
                    const SizedBox(height: 16),
                    _buildCodingGrid(accent),
                    const SizedBox(height: 16),
                    _buildStepCard(
                      BinaryLessonContent.binaryData['example_title']![lang]!,
                      BinaryLessonContent.binaryData['example_text']![lang]!,
                      Icons.auto_fix_high_rounded, accent,
                    ),
                    const SizedBox(height: 16),
                    _buildLociSection(accent),
                    const SizedBox(height: 16),
                    _buildInteractiveTask(accent),
                    const SizedBox(height: 16),
                    _buildStepCard(
                      AppTexts.get('trainer'),
                      BinaryLessonContent.binaryData['training_text']![lang]!,
                      Icons.bolt_rounded, accent,
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildStepCard(String title, String content, IconData icon, Color accent) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: appPalette.value.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: accent, size: 20), const SizedBox(width: 12), Expanded(child: Text(title, style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.bold)))]),
          const SizedBox(height: 16),
          Text(content, style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildCodingGrid(Color accent) {
    final lang = appLanguage.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isRu = lang == AppLanguage.ru;
    final isEn = lang == AppLanguage.en;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isRu ? "СИСТЕМА КОДИРОВАНИЯ" : (isEn ? "CODING SYSTEM" : "KODIERUNGSSYSTEM"), style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: BinaryLessonContent.codingSystem.length,
            itemBuilder: (context, index) {
              final item = BinaryLessonContent.codingSystem[index];
              String img = isRu ? item['img_ru']! : (isEn ? item['img_en']! : item['img_de']!);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: appPalette.value.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withOpacity(0.1)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['bin']!, style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    Text(img, style: TextStyle(color: onSurface, fontSize: 11, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLociSection(Color accent) {
    final lang = appLanguage.value;
    final isRu = lang == AppLanguage.ru;
    final isEn = lang == AppLanguage.en;
    
    return _buildStepCard(
      BinaryLessonContent.binaryData['loci_title']![lang]!,
      isRu ? "1. Создай 10-20 локи (кухня, спальня...)\n2. Разбей бинарную ленту по 3\n3. Преврати каждую тройку в образ\n4. Размести образы в локациях\n5. Визуализируй каждую сцену" 
           : (isEn ? "1. Create 10-20 loci (kitchen, bedroom...)\n2. Split binary sequence by 3\n3. Turn each triplet into an image\n4. Place images in locations\n5. Visualize each scene"
                   : "1. Erstellen Sie 10-20 Loci (Küche, Schlafzimmer...)\n2. Binärsequenz durch 3 teilen\n3. Verwandeln Sie jedes Triplett in ein Bild\n4. Platzieren Sie Bilder an Orten\n5. Visualisieren Sie jede Szene"),
      Icons.hub_rounded, accent,
    );
  }

  Widget _buildInteractiveTask(Color accent) {
    final lang = appLanguage.value;
    final isRu = lang == AppLanguage.ru;
    final isEn = lang == AppLanguage.en;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [accent.withOpacity(0.15), accent.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.psychology_alt_rounded, color: accent, size: 32),
          const SizedBox(height: 12),
          Text(BinaryLessonContent.binaryData['task_title']![lang]!, style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(isRu ? "Закодируй: 000 101 010 111.\nРазмести эти 4 образа в первых точках кухни и проверь себя через 2 минуты!" 
                   : (isEn ? "Code: 000 101 010 111.\nPlace these 4 images in the first points of the kitchen and check yourself in 2 minutes!"
                           : "Kodieren: 000 101 010 111.\nPlatzieren Sie diese 4 Bilder an den ersten Punkten der Küche und prüfen Sie sich in 2 Minuten!"), 
            textAlign: TextAlign.center, style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 14)),
        ],
      ),
    );
  }
}

// --- ЭКРАН ОБРАЗОВ ДЛЯ ЧИСЕЛ ---
class NumberImagesScreen extends StatelessWidget {
  const NumberImagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isRu = appLanguage.value == AppLanguage.ru;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurface.withOpacity(0.6), size: 20), onPressed: () => Navigator.pop(context)),
        title: Text(AppTexts.get('number_images_labels_title'), style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 3)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildOptionCard(context, "0 - 9", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NumberImagesListScreen()))),
            const SizedBox(height: 16),
            _buildOptionCard(context, "00 - 99", () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(AppTexts.get('number_images_labels_not_available')),
                backgroundColor: appAccentColor.value,
                behavior: SnackBarBehavior.floating,
              ));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, String label, VoidCallback onTap) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: palette.border.withOpacity(0.3))),
        child: Center(child: Text(label, style: TextStyle(color: onSurface, fontSize: 20, fontWeight: FontWeight.w200, letterSpacing: 4))),
      ),
    );
  }
}

class NumberImagesListScreen extends StatelessWidget {
  const NumberImagesListScreen({super.key});

  static const Map<AppLanguage, Map<int, String>> _imagesByLanguage = {
    AppLanguage.ru: {
      0: 'Яблоко',
      1: 'Копье',
      2: 'Лебедь',
      3: 'Тризуб',
      4: 'Стул',
      5: 'Крюк',
      6: 'Сундук',
      7: 'Коса',
      8: 'Очки',
      9: 'Воздушный шар',
    },
    AppLanguage.en: {
      0: 'Apple',
      1: 'Spear',
      2: 'Swan',
      3: 'Trident',
      4: 'Chair',
      5: 'Hook',
      6: 'Chest',
      7: 'Scythe',
      8: 'Glasses',
      9: 'Balloon',
    },
    AppLanguage.de: {
      0: 'Apfel',
      1: 'Speer',
      2: 'Schwan',
      3: 'Dreizack',
      4: 'Stuhl',
      5: 'Haken',
      6: 'Truhe',
      7: 'Sense',
      8: 'Brille',
      9: 'Luftballon',
    },
  };

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final language = appLanguage.value;
    final images = _imagesByLanguage[language] ?? _imagesByLanguage[AppLanguage.ru]!;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurface.withOpacity(0.6), size: 20), onPressed: () => Navigator.pop(context)),
        title: const Text("0 - 9", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 3)),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: 10,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: palette.border.withOpacity(0.2))),
            child: Row(
              children: [
                Text("$index", style: TextStyle(color: appAccentColor.value, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(width: 24),
                Text(images[index]!, style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.w300)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController.text = CloudSyncService.instance.accountTitle();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurface.withOpacity(0.6), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppTexts.get('account'),
          style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 3),
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: CloudSyncService.instance.isBusy,
        builder: (context, busy, _) {
          return ValueListenableBuilder<User?>(
            valueListenable: CloudSyncService.instance.user,
            builder: (context, user, __) {
              final signedIn = user != null;
              final photoUrl = CloudSyncService.instance.photoUrl.value;
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: palette.border.withOpacity(0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 34,
                              backgroundColor: appAccentColor.value.withOpacity(0.18),
                              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: (photoUrl == null || photoUrl.isEmpty)
                                  ? Icon(Icons.person_rounded, size: 34, color: onSurface.withOpacity(0.8))
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    CloudSyncService.instance.accountTitle(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    signedIn
                                        ? (user.email ?? 'Аккаунт подключен')
                                        : 'Не подключено',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: onSurface.withOpacity(0.55), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _smallActionButton(
                          context,
                          (!signedIn || busy)
                              ? null
                              : () async {
                                  await _pickAndUploadPhoto(context);
                                },
                          'Установить фото профиля',
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppTexts.get('account_name_label'),
                          style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _nameController,
                          style: TextStyle(color: onSurface),
                          decoration: InputDecoration(
                            hintText: AppTexts.get('account_name_hint'),
                            hintStyle: TextStyle(color: onSurface.withOpacity(0.35)),
                            filled: true,
                            fillColor: palette.background,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: palette.border.withOpacity(0.45)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: appAccentColor.value.withOpacity(0.5)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _smallActionButton(
                          context,
                          (!signedIn || busy)
                              ? null
                              : () async {
                                  await CloudSyncService.instance.updateDisplayName(_nameController.text);
                                },
                          AppTexts.get('account_save_name'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: palette.border.withOpacity(0.35)),
                    ),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (signedIn)
                          _smallActionButton(
                            context,
                            busy
                                ? null
                                : () async {
                                    await CloudSyncService.instance.syncNow();
                                  },
                            AppTexts.get('cloud_sync_now'),
                          ),
                        if (signedIn)
                          _smallActionButton(
                            context,
                            busy
                                ? null
                                : () async {
                                    await CloudSyncService.instance.signOut();
                                  },
                            AppTexts.get('cloud_sign_out'),
                          ),
                        if (!signedIn)
                          _smallActionButton(
                            context,
                            busy
                                ? null
                                : () async {
                                    await CloudSyncService.instance.signInWithGoogle();
                                  },
                            AppTexts.get('cloud_sign_in'),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _smallActionButton(BuildContext context, Future<void> Function()? onTap, String label) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: onTap == null ? null : () async => onTap(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: onTap == null ? appPalette.value.border.withOpacity(0.35) : appAccentColor.value.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: onTap == null ? appPalette.value.border.withOpacity(0.5) : appAccentColor.value.withOpacity(0.4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: onTap == null ? onSurface.withOpacity(0.5) : onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(BuildContext context) async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (file == null) return;
    final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
    final bytes = await file.readAsBytes();
    await CloudSyncService.instance.updateProfilePhotoBytes(bytes, fileExt: ext);
    if (!context.mounted) return;
    final err = CloudSyncService.instance.lastError.value;
    if (err == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Фото профиля обновлено.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось загрузить фото: $err')),
      );
    }
  }
}

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, _, __) {
        final palette = appPalette.value;
        final onSurface = Theme.of(context).colorScheme.onSurface;
        return Scaffold(
          backgroundColor: palette.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurface.withOpacity(0.6), size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(AppTexts.get('language'),
              style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 3)),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: Column(
                key: ValueKey(appLanguage.value),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLanguageOption(context, 'Русский', AppLanguage.ru),
                  const SizedBox(height: 12),
                  _buildLanguageOption(context, 'English', AppLanguage.en),
                  const SizedBox(height: 12),
                  _buildLanguageOption(context, 'Deutsch', AppLanguage.de),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(BuildContext context, String label, AppLanguage lang) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isSelected = appLanguage.value == lang;

    return GestureDetector(
      onTap: () async {
        HapticFeedback.mediumImpact();
        if (appLanguage.value == lang) return;
        appLanguage.value = lang;
        await persistLanguage(lang);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? appAccentColor.value.withOpacity(0.1) : palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? appAccentColor.value : palette.border.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(color: onSurface, fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.w300)),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle_rounded, color: appAccentColor.value, size: 20),
          ],
        ),
      ),
    );
  }
}

// --- ЭКРАН СТАТИСТИКИ ---
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, dynamic> stats = {
    'standard': {'best': 0, 'total': 0, 'avg': 0.0, 'bestSpeedMs': 0},
    'binary': {'best': 0, 'total': 0, 'avg': 0.0, 'bestSpeedMs': 0},
    'words': {'best': 0, 'total': 0, 'avg': 0.0, 'bestSpeedMs': 0},
    'images': {'best': 0, 'total': 0, 'avg': 0.0, 'bestSpeedMs': 0},
    'cards': {'best': 0, 'total': 0, 'avg': 0.0, 'bestSpeedMs': 0},
  };
  final Map<String, List<String>> _historiesRaw = {
    'standard': [],
    'binary': [],
    'words': [],
    'images': [],
    'cards': [],
  };
  int _streakDays = 0;

  @override
  void initState() {
    super.initState();
    _loadAllStats();
  }

  Future<void> _loadAllStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (final mode in ['standard', 'binary', 'words', 'images', 'cards']) {
        stats[mode] = {
          'best': prefs.getInt('best_score_$mode') ?? 0,
          'total': prefs.getInt('total_games_$mode') ?? 0,
          'avg': prefs.getDouble('avg_percentage_$mode') ?? 0.0,
          'bestSpeedMs': prefs.getInt('best_avg_ms_per_el_$mode') ?? 0,
        };
        _historiesRaw[mode] = List<String>.from(prefs.getStringList('game_history_$mode') ?? []);
      }
      _streakDays = ProgressService.instance.progress.value.streak;
    });
  }

  String _formatSecPerElement(int avgMsPerEl) {
    if (avgMsPerEl <= 0) return '—';
    return '${(avgMsPerEl / 1000.0).toStringAsFixed(2)} с';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: ValueListenableBuilder<AppPalette>(
        valueListenable: appPalette,
        builder: (context, palette, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTexts.get('statistics_title'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w200,
                    letterSpacing: 2,
                    color: palette.accent.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 20),
                _buildStreakRow(palette),
                const SizedBox(height: 28),
                _buildModeBlock(AppTexts.get('numbers'), 'standard', Icons.numbers, palette),
                const SizedBox(height: 14),
                _buildModeBlock(AppTexts.get('binary'), 'binary', Icons.data_array, palette),
                const SizedBox(height: 14),
                _buildModeBlock(AppTexts.get('words'), 'words', Icons.abc, palette),
                const SizedBox(height: 14),
                _buildModeBlock(AppTexts.get('photo'), 'images', Icons.image_outlined, palette),
                const SizedBox(height: 14),
                _buildModeBlock(AppTexts.get('cards'), 'cards', Icons.style_outlined, palette),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStreakRow(AppPalette palette) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final d = _streakDays.clamp(0, 999);
    final slots = d == 0 ? 1 : (d > 7 ? 7 : d);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border.withOpacity(0.55)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(slots, (i) {
                final t = slots <= 1 ? 1.0 : i / (slots - 1);
                final o = 0.35 + 0.45 * t;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    width: 10,
                    height: 22,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          palette.accent.withOpacity(0.15 + 0.1 * t),
                          palette.accent.withOpacity(o),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: palette.accent.withOpacity(0.25),
                          blurRadius: 6,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.local_fire_department_rounded, color: palette.accent, size: 26),
          const SizedBox(width: 6),
          Text(
            '$d',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w200,
              color: palette.accent,
              height: 1,
            ),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              AppTexts.get('days_label'),
              style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeBlock(String title, String modeKey, IconData icon, AppPalette palette) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final data = stats[modeKey] as Map<String, dynamic>;
    final bestSpeed = data['bestSpeedMs'] as int;
    final rawList = _historiesRaw[modeKey] ?? [];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: palette.accent.withOpacity(0.75), size: 22),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: onSurface.withOpacity(0.88))),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${AppTexts.get('record')}: ${data['best']} · ${AppTexts.get('games_count')}: ${data['total']} · ${AppTexts.get('avg_accuracy')}: ${(data['avg'] as double).toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.48), height: 1.35),
          ),
          const SizedBox(height: 4),
          Text(
            '${AppTexts.get('best_speed')}: ${_formatSecPerElement(bestSpeed)} ${AppTexts.get('per_element')}',
            style: TextStyle(fontSize: 11, color: palette.accent.withOpacity(0.85)),
          ),
          if (rawList.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(AppTexts.get('recent_attempts'), style: TextStyle(fontSize: 10, letterSpacing: 1.2, color: onSurface.withOpacity(0.38))),
            const SizedBox(height: 8),
            ...rawList.take(6).map((raw) {
              String line = raw;
              try {
                final m = jsonDecode(raw) as Map<String, dynamic>;
                final pct = (m['pct'] as num).toDouble().toStringAsFixed(0);
                final n = (m['n'] as num).toInt();
                final c = (m['c'] as num).toInt();
                final avgEl = (m['avgMemMsPerEl'] as num?)?.toInt() ?? 0;
                final spd = _formatSecPerElement(avgEl);
                line = '$c/$n · $pct% · $spd/эл.';
              } catch (_) {}
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(line, style: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.55))),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// --- ТЕХНИКИ ЗАПОМИНАНИЯ (Академия Мнемоники) ---
// --- МНЕМОТЕХНИКА: ИНТРО-ВИДЖЕТ ---
class MnemonicIntroWidget extends StatefulWidget {
  const MnemonicIntroWidget({super.key});

  @override
  State<MnemonicIntroWidget> createState() => _MnemonicIntroWidgetState();
}

class _MnemonicIntroWidgetState extends State<MnemonicIntroWidget> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    // Автоматическое подмигивание при открытии раздела
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoBlink();
    });
  }

  Future<void> _autoBlink() async {
    for (int i = 0; i < 3; i++) {
      if (!mounted) return;
      HapticFeedback.lightImpact();
      await _blinkController.forward();
      await _blinkController.reverse();
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    // Подмигивание 3 раза с легкой вибрацией
    for (int i = 0; i < 3; i++) {
      HapticFeedback.lightImpact();
      await _blinkController.forward();
      await _blinkController.reverse();
      await Future.delayed(const Duration(milliseconds: 50));
    }
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _handlePress,
          child: FadeTransition(
            opacity: _blinkAnimation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _isExpanded ? accent.withOpacity(0.05) : accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_isExpanded ? Icons.unfold_less_rounded : Icons.auto_awesome_rounded, size: 14, color: accent),
                  const SizedBox(width: 8),
                  Text(
                    _isExpanded ? AppTexts.get('hide') : AppTexts.get('more'),
                    style: TextStyle(
                      color: accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.fastOutSlowIn,
          child: _isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withOpacity(0.08),
                          accent.withOpacity(0.02),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accent.withOpacity(0.15)),
                    ),
                    child: Text(
                      AppTexts.translate(AppTexts.introLesson['main_text'] as Map<AppLanguage, String>),
                      style: TextStyle(
                        color: onSurface.withOpacity(0.85),
                        height: 1.65,
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// --- УРОК: СОЗДАНИЕ ОБРАЗОВ ---
class MnemonicImagesLessonWidget extends StatefulWidget {
  const MnemonicImagesLessonWidget({super.key});

  @override
  State<MnemonicImagesLessonWidget> createState() => _MnemonicImagesLessonWidgetState();
}

class _MnemonicImagesLessonWidgetState extends State<MnemonicImagesLessonWidget> with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    for (int i = 0; i < 3; i++) {
      HapticFeedback.lightImpact();
      await _blinkController.forward();
      await _blinkController.reverse();
      await Future.delayed(const Duration(milliseconds: 50));
    }
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _handlePress,
          child: FadeTransition(
            opacity: _blinkAnimation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _isExpanded ? accent.withOpacity(0.05) : accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_isExpanded ? Icons.unfold_less_rounded : Icons.auto_awesome_rounded, size: 14, color: accent),
                  const SizedBox(width: 8),
                  Text(
                    _isExpanded ? AppTexts.get('hide') : AppTexts.get('more'),
                    style: TextStyle(
                      color: accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
          child: _isExpanded
              ? Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildStepCard(
                      AppTexts.translate(AppTexts.imagesLesson['why_images_title'] as Map<AppLanguage, String>),
                      AppTexts.translate(AppTexts.imagesLesson['why_images_text'] as Map<AppLanguage, String>),
                      Icons.psychology_rounded,
                      accent,
                    ),
                    const SizedBox(height: 16),
                    _buildStepCard(
                      AppTexts.translate(AppTexts.imagesLesson['formula_title'] as Map<AppLanguage, String>),
                      AppTexts.translate(AppTexts.imagesLesson['formula_text'] as Map<AppLanguage, String>),
                      Icons.auto_fix_high_rounded,
                      accent,
                    ),
                    const SizedBox(height: 16),
                    _buildExampleSection(accent),
                    const SizedBox(height: 16),
                    _buildComparisonSection(accent),
                    const SizedBox(height: 16),
                    _buildInteractiveTask(accent),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildStepCard(String title, String content, IconData icon, Color accent) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: appPalette.value.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: accent.withOpacity(0.05), blurRadius: 15, spreadRadius: -5)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text(content, style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildExampleSection(Color accent) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isRu = appLanguage.value == AppLanguage.ru;
    final isEn = appLanguage.value == AppLanguage.en;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isRu ? "КЛЮЧ: ПОШАГОВЫЙ ПРИМЕР" : (isEn ? "KEY: STEP-BY-STEP EXAMPLE" : "SCHLÜSSEL: SCHRITT-FÜR-SCHRITT"), style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          _buildMiniStep(
            isRu ? "1. Увеличь" : (isEn ? "1. Enlarge" : "1. Vergrößern"), 
            isRu ? "Сделай его огромным, как автобус." : (isEn ? "Make it huge, like a bus." : "Mach es riesig, wie einen Bus."), 
            Icons.zoom_out_map_rounded, accent),
          _buildMiniStep(
            isRu ? "2. Подсвети" : (isEn ? "2. Highlight" : "2. Beleuchten"), 
            isRu ? "Золотой, неоновый, сияет до боли в глазах." : (isEn ? "Golden, neon, shines until it hurts your eyes." : "Golden, Neon, leuchtet, bis es in den Augen weh tut."), 
            Icons.wb_incandescent_rounded, accent),
          _buildMiniStep(
            isRu ? "3. Запусти" : (isEn ? "3. Launch" : "3. Starten"), 
            isRu ? "Крутится как вентилятор, снося всё вокруг." : (isEn ? "Spins like a fan, blowing everything away." : "Dreht sich wie ein Ventilator и bläst alles weg."), 
            Icons.autorenew_rounded, accent),
          _buildMiniStep(
            isRu ? "4. Оживи" : (isEn ? "4. Animate" : "4. Beleben"), 
            isRu ? "Он дико хохочет твоим голосом. Крипово? Да. Забыть? Невозможно." : (isEn ? "It laughs wildly with your voice. Creepy? Yes. Forget? Impossible." : "Es lacht wild mit deiner Stimme. Gruselig? Ja. Vergessen? Unmöglich."), 
            Icons.face_retouching_natural_rounded, accent),
        ],
      ),
    );
  }

  Widget _buildMiniStep(String title, String desc, IconData icon, Color accent) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: accent.withOpacity(0.6)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(desc, style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonSection(Color accent) {
    final isRu = appLanguage.value == AppLanguage.ru;
    final isEn = appLanguage.value == AppLanguage.en;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: appPalette.value.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isRu ? "ИЗ «ПЛОХО» В «ИДЕАЛЬНО»" : (isEn ? "FROM 'BAD' TO 'PERFECT'" : "VON 'SCHLECHT' ZU 'PERFEKT'"), style: TextStyle(color: accent.withOpacity(0.5), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          _buildComparisonItem(isRu ? "ПЛОХО" : (isEn ? "BAD" : "SCHLECHT"), isRu ? "Собака стоит." : (isEn ? "A dog is standing." : "Ein Hund steht."), Colors.redAccent.withOpacity(0.7)),
          const SizedBox(height: 12),
          _buildComparisonItem(isRu ? "ИДЕАЛЬНО" : (isEn ? "PERFECT" : "PERFEKT"), isRu ? "Неоново-синяя собака размером с дом прыгает по крышам, хохочет и пускает взрывающиеся пузыри." : (isEn ? "A neon-blue dog the size of a house jumps on roofs, laughs, and blows exploding bubbles." : "Ein neonblauer Hund von der Größe eines Hauses springt auf Dächer, lacht und bläst explodierende Blasen."), const Color(0xFF00E676)),
        ],
      ),
    );
  }

  Widget _buildComparisonItem(String label, String text, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
        const SizedBox(height: 6),
        Text(text, style: TextStyle(color: color.withOpacity(0.8), fontSize: 13, height: 1.4)),
      ],
    );
  }

  Widget _buildInteractiveTask(Color accent) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isRu = appLanguage.value == AppLanguage.ru;
    final isEn = appLanguage.value == AppLanguage.en;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withOpacity(0.15), accent.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.star_rounded, color: accent, size: 32),
          const SizedBox(height: 12),
          Text(isRu ? "ЗАДАНИЕ №1" : (isEn ? "TASK #1" : "AUFGABE №1"), style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(isRu ? "Возьми слово «СТОЛ» и преврати его в безумный образ по формуле прямо сейчас." : (isEn ? "Take the word 'TABLE' and turn it into a crazy image using the formula right now." : "Nimm das Wort 'TISCH' und verwandle es jetzt in ein verrücktes Bild nach der Formel."), textAlign: TextAlign.center, style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 14)),
        ],
      ),
    );
  }
}

// --- УРОК: СВЯЗЫВАНИЕ ОБРАЗОВ ---
class MnemonicLinkingLessonWidget extends StatefulWidget {
  const MnemonicLinkingLessonWidget({super.key});

  @override
  State<MnemonicLinkingLessonWidget> createState() => _MnemonicLinkingLessonWidgetState();
}

class _MnemonicLinkingLessonWidgetState extends State<MnemonicLinkingLessonWidget> with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    for (int i = 0; i < 3; i++) {
      HapticFeedback.lightImpact();
      await _blinkController.forward();
      await _blinkController.reverse();
      await Future.delayed(const Duration(milliseconds: 50));
    }
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isRu = appLanguage.value == AppLanguage.ru;
    final isEn = appLanguage.value == AppLanguage.en;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _handlePress,
          child: FadeTransition(
            opacity: _blinkAnimation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _isExpanded ? accent.withOpacity(0.05) : accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_isExpanded ? Icons.unfold_less_rounded : Icons.link_rounded, size: 14, color: accent),
                  const SizedBox(width: 8),
                  Text(
                    _isExpanded ? AppTexts.get('hide') : AppTexts.get('more'),
                    style: TextStyle(
                      color: accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
          child: _isExpanded
              ? Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildStepCard(
                      AppTexts.translate(AppTexts.linkingLesson['why_title'] as Map<AppLanguage, String>),
                      AppTexts.translate(AppTexts.linkingLesson['why_text'] as Map<AppLanguage, String>),
                      Icons.hub_rounded,
                      accent,
                    ),
                    const SizedBox(height: 16),
                    _buildStepCard(
                      AppTexts.translate(AppTexts.linkingLesson['principle_title'] as Map<AppLanguage, String>),
                      AppTexts.translate(AppTexts.linkingLesson['principle_text'] as Map<AppLanguage, String>),
                      Icons.bolt_rounded,
                      accent,
                    ),
                    const SizedBox(height: 16),
                    _buildExampleSection(accent),
                    const SizedBox(height: 16),
                    _buildStepByStepAlgo(accent),
                    const SizedBox(height: 16),
                    _buildLargeExample(accent),
                    const SizedBox(height: 16),
                    _buildInteractiveTask(accent),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildStepCard(String title, String content, IconData icon, Color accent) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: appPalette.value.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text(content, style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildExampleSection(Color accent) {
    final isRu = appLanguage.value == AppLanguage.ru;
    final isEn = appLanguage.value == AppLanguage.en;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isRu ? "ПОШАГОВЫЙ ПРИМЕР: ЦЕПОЧКА" : (isEn ? "STEP-BY-STEP EXAMPLE: CHAIN" : "SCHRITT-FÜR-SCHRITT: KETTE"), 
            style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          _buildMiniExample(
            isRu ? "1. Яблоко → Нож" : "1. Apple → Knife",
            isRu ? "Огромный нож разрезает гигантское яблоко, сок летит тебе в лицо." : "A huge knife cuts a giant apple, juice flies in your face.",
            accent
          ),
          _buildMiniExample(
            isRu ? "2. Нож → Книга" : "2. Knife → Book",
            isRu ? "Из разреза яблока вытекают страницы книги, как будто внутри библиотека." : "Book pages flow out of the apple cut, as if there's a library inside.",
            accent
          ),
        ],
      ),
    );
  }

  Widget _buildMiniExample(String title, String desc, Color accent) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStepByStepAlgo(Color accent) {
    final isRu = appLanguage.value == AppLanguage.ru;
    final isEn = appLanguage.value == AppLanguage.en;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: appPalette.value.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isRu ? "АЛГОРИТМ ПОСТРОЕНИЯ" : (isEn ? "BUILDING ALGORITHM" : "AUFBAU-ALGORITHMUS"), 
            style: TextStyle(color: accent.withOpacity(0.5), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          _buildAlgoStep("1", isRu ? "Яркий первый образ" : "Bright first image", accent),
          _buildAlgoStep("2", isRu ? "Атака следующего образа" : "Attack the next image", accent),
          _buildAlgoStep("3", isRu ? "Усиление (звук, запах)" : "Enhancement (sound, smell)", accent),
          _buildAlgoStep("4", isRu ? "Повтор для цепочки" : "Repeat for the chain", accent),
        ],
      ),
    );
  }

  Widget _buildAlgoStep(String num, String text, Color accent) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(color: accent.withOpacity(0.1), shape: BoxShape.circle),
            child: Center(child: Text(num, style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: onSurface.withOpacity(0.8), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildLargeExample(Color accent) {
    final isRu = appLanguage.value == AppLanguage.ru;
    final isEn = appLanguage.value == AppLanguage.en;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isRu ? "ЦЕПОЧКА ИЗ 5 СЛОВ" : (isEn ? "CHAIN OF 5 WORDS" : "KETTE AUS 5 WÖRTERN"), 
            style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Text(isRu ? "Лампа → Рыба → Телефон → Молоток → Торт" : "Lamp → Fish → Phone → Hammer → Cake", 
            style: TextStyle(color: onSurface.withOpacity(0.4), fontSize: 12, fontStyle: FontStyle.italic)),
          const SizedBox(height: 16),
          _buildMiniExample(isRu ? "Лампа → Рыба" : "Lamp → Fish", isRu ? "Лампа взрывается, вылетает гигантская золотая рыба." : "Lamp explodes, a giant golden fish flies out.", accent),
          _buildMiniExample(isRu ? "Рыба → Телефон" : "Fish → Phone", isRu ? "Рыба кричит в телефон у неё в пасти." : "Fish screams into the phone in its mouth.", accent),
          _buildMiniExample(isRu ? "Телефон → Молоток" : "Phone → Hammer", isRu ? "Телефон вибрирует и превращается в молоток." : "Phone vibrates and turns into a hammer.", accent),
          _buildMiniExample(isRu ? "Молоток → Торт" : "Hammer → Cake", isRu ? "Молоток размазывает торт по стенам." : "Hammer smashes the cake across the walls.", accent),
        ],
      ),
    );
  }

  Widget _buildInteractiveTask(Color accent) {
    final isRu = appLanguage.value == AppLanguage.ru;
    final isEn = appLanguage.value == AppLanguage.en;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [accent.withOpacity(0.15), accent.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.psychology_alt_rounded, color: accent, size: 32),
          const SizedBox(height: 12),
          Text(isRu ? "ЗАДАНИЕ №2" : (isEn ? "TASK #2" : "AUFGABE №2"), style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(isRu ? "Построй цепочку: ШАР → ДЕРЕВО → ОЧКИ.\nВизуализируй каждое действие!" : "Build a chain: BALL → TREE → GLASSES.\nVisualize every action!", 
            textAlign: TextAlign.center, style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 14)),
        ],
      ),
    );
  }
}

// --- УРОК: МЕТОД ЛОКИ ---
class MnemonicLociLessonWidget extends StatefulWidget {
  const MnemonicLociLessonWidget({super.key});

  @override
  State<MnemonicLociLessonWidget> createState() => _MnemonicLociLessonWidgetState();
}

class _MnemonicLociLessonWidgetState extends State<MnemonicLociLessonWidget> with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    for (int i = 0; i < 3; i++) {
      HapticFeedback.lightImpact();
      await _blinkController.forward();
      await _blinkController.reverse();
      await Future.delayed(const Duration(milliseconds: 50));
    }
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isRu = appLanguage.value == AppLanguage.ru;
    final isEn = appLanguage.value == AppLanguage.en;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _handlePress,
          child: FadeTransition(
            opacity: _blinkAnimation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _isExpanded ? accent.withOpacity(0.05) : accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_isExpanded ? Icons.unfold_less_rounded : Icons.account_balance_rounded, size: 14, color: accent),
                  const SizedBox(width: 8),
                  Text(
                    _isExpanded ? AppTexts.get('hide') : AppTexts.get('more'),
                    style: TextStyle(
                      color: accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
          child: _isExpanded
              ? Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildStepCard(
                      AppTexts.translate(AppTexts.lociLesson['what_is_title'] as Map<AppLanguage, String>),
                      AppTexts.translate(AppTexts.lociLesson['what_is_text'] as Map<AppLanguage, String>),
                      Icons.history_edu_rounded,
                      accent,
                    ),
                    const SizedBox(height: 16),
                    _buildStepCard(
                      AppTexts.translate(AppTexts.lociLesson['screen_title'] as Map<AppLanguage, String>),
                      AppTexts.translate(AppTexts.lociLesson['screen_text'] as Map<AppLanguage, String>),
                      Icons.visibility_rounded,
                      accent,
                    ),
                    const SizedBox(height: 16),
                    _buildStepCard(
                      AppTexts.translate(AppTexts.lociLesson['start_title'] as Map<AppLanguage, String>),
                      AppTexts.translate(AppTexts.lociLesson['start_text'] as Map<AppLanguage, String>),
                      Icons.kitchen_rounded,
                      accent,
                    ),
                    const SizedBox(height: 16),
                    _buildStepCard(
                      AppTexts.translate(AppTexts.lociLesson['direction_title'] as Map<AppLanguage, String>),
                      AppTexts.translate(AppTexts.lociLesson['direction_text'] as Map<AppLanguage, String>),
                      Icons.rotate_right_rounded,
                      accent,
                    ),
                    const SizedBox(height: 16),
                    _buildLociExample(accent),
                    const SizedBox(height: 16),
                    _buildInteractiveTask(accent),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildStepCard(String title, String content, IconData icon, Color accent) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: appPalette.value.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text(content, style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildLociExample(Color accent) {
    final isRu = appLanguage.value == AppLanguage.ru;
    final isEn = appLanguage.value == AppLanguage.en;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isRu ? "ПРИМЕР: РАЗМЕЩЕНИЕ ОБРАЗОВ" : (isEn ? "EXAMPLE: PLACING IMAGES" : "BEISPIEL: BILDER PLATZIEREN"), 
            style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          _buildMiniExample(
            isRu ? "1. Дверь → Выдра" : "1. Door → Otter",
            isRu ? "Огромная мокрая выдра висит на двери и визжит." : "A huge wet otter hangs on the door and squeals.",
            accent
          ),
          _buildMiniExample(
            isRu ? "2. Коврик → Ящик" : "2. Mat → Box",
            isRu ? "На коврике вибрирует металлический ящик с молотками." : "A metal box with hammers vibrates on the mat.",
            accent
          ),
          _buildMiniExample(
            isRu ? "3. Холодильник → Фасоль" : "3. Fridge → Beans",
            isRu ? "Открываешь холодильник, а оттуда сыпется горячая фасоль." : "You open the fridge, and hot beans pour out.",
            accent
          ),
        ],
      ),
    );
  }

  Widget _buildMiniExample(String title, String desc, Color accent) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildInteractiveTask(Color accent) {
    final isRu = appLanguage.value == AppLanguage.ru;
    final isEn = appLanguage.value == AppLanguage.en;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [accent.withOpacity(0.15), accent.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.star_rounded, color: accent, size: 32),
          const SizedBox(height: 12),
          Text(isRu ? "ЗАДАНИЕ №3" : (isEn ? "TASK #3" : "AUFGABE №3"), style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(isRu ? "Выбери 10 точек на кухне. Закрой глаза и увидь их. Затем попробуй запомнить первые 4-6 слов в тренажёре!" : "Choose 10 points in the kitchen. Close your eyes and see them. Then try to memorize the first 4-6 words in the trainer!", 
            textAlign: TextAlign.center, style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 14)),
        ],
      ),
    );
  }
}

class TechniquesScreen extends StatelessWidget {
  const TechniquesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final palette = appPalette.value;
    final accent = appAccentColor.value;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurface.withOpacity(0.6), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppTexts.get('academy'), 
          style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 3)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(appLanguage.value == AppLanguage.ru ? 'Твое обучение' : (appLanguage.value == AppLanguage.en ? 'Your Training' : 'Dein Training'), 
              style: TextStyle(color: onSurface, fontSize: 32, fontWeight: FontWeight.w200)),
            const SizedBox(height: 8),
            Text(appLanguage.value == AppLanguage.ru ? 'От основ до мастерства' : (appLanguage.value == AppLanguage.en ? 'From basics to mastery' : 'Von den Grundlagen zur Meisterschaft'), 
              style: TextStyle(color: onSurface.withOpacity(0.4), fontSize: 14, letterSpacing: 1)),
            const SizedBox(height: 40),
            
            _buildSectionHeader(appLanguage.value == AppLanguage.ru ? "ФУНДАМЕНТ" : (appLanguage.value == AppLanguage.en ? "FOUNDATION" : "FUNDAMENT"), Icons.psychology_outlined),
            _lessonCard(
              context,
              AppTexts.translate(AppTexts.introLesson['title'] as Map<AppLanguage, String>),
              AppTexts.translate(AppTexts.introLesson['subtitle'] as Map<AppLanguage, String>),
              Icons.auto_awesome_mosaic_rounded,
              [
                const MnemonicIntroWidget(),
                _textBlock(appLanguage.value == AppLanguage.ru ? "Мнемотехника — это система методов, которая превращает скучные данные в яркие истории." : (appLanguage.value == AppLanguage.en ? "Mnemonics is a system of methods that turns boring data into vivid stories." : "Mnemonik ist ein System von Methoden, das langweilige Daten in lebendige Geschichten verwandelt.")),
                _infoBox(appLanguage.value == AppLanguage.ru ? "Главная идея: мозг плохо помнит абстрактные цифры, но обожает: ОБРАЗЫ, ЭМОЦИИ, ДВИЖЕНИЯ." : (appLanguage.value == AppLanguage.en ? "Main idea: the brain remembers abstract numbers poorly, but loves: IMAGES, EMOTIONS, MOVEMENTS." : "Hauptidee: Das Gehirn merkt sich abstrakte Zahlen schlecht, liebt aber: BILDER, EMOTIONEN, BEWEGUNGEN."), accent),
                _subHeader(appLanguage.value == AppLanguage.ru ? "Почему зубрежка не работает?" : (appLanguage.value == AppLanguage.en ? "Why rote learning doesn't work?" : "Warum Auswendiglernen nicht funktioniert?")),
                _textBlock(appLanguage.value == AppLanguage.ru ? "Когда ты видишь '482951736', мозгу не за что зацепиться. Это просто шум. Мнемотехника дает крючки, за которые цепляется память." : (appLanguage.value == AppLanguage.en ? "When you see '482951736', the brain has nothing to hold onto. It's just noise. Mnemonics provides hooks that memory clings to." : "Wenn du '482951736' siehst, hat das Gehirn nichts, woran es sich festhalten kann. Es ist nur Lärm. Mnemonik bietet Haken, an denen sich das Gedächtnis festklammert.")),
                _subHeader(appLanguage.value == AppLanguage.ru ? "Главный принцип" : (appLanguage.value == AppLanguage.en ? "Main Principle" : "Hauptprinzip")),
                _bulletPoint(appLanguage.value == AppLanguage.ru ? "1. Сделай информацию визуальной" : (appLanguage.value == AppLanguage.en ? "1. Make information visual" : "1. Informationen visuell machen")),
                _bulletPoint(appLanguage.value == AppLanguage.ru ? "2. Добавь яркости и абсурда" : (appLanguage.value == AppLanguage.en ? "2. Add brightness and absurdity" : "2. Helligkeit und Absurdität hinzufügen")),
                _bulletPoint(appLanguage.value == AppLanguage.ru ? "3. Связывай образы между собой" : (appLanguage.value == AppLanguage.en ? "3. Connect images with each other" : "3. Bilder miteinander verbinden")),
              ],
            ),
            _lessonCard(
              context,
              AppTexts.translate(AppTexts.imagesLesson['title'] as Map<AppLanguage, String>),
              AppTexts.translate(AppTexts.imagesLesson['subtitle'] as Map<AppLanguage, String>),
              Icons.palette_outlined,
              [
                const MnemonicImagesLessonWidget(),
                _subHeader(AppTexts.translate(AppTexts.imagesLesson['formula_title'] as Map<AppLanguage, String>)),
                _textBlock(AppTexts.translate(AppTexts.imagesLesson['formula_text'] as Map<AppLanguage, String>)),
                const SizedBox(height: 16),
                _comparisonBox(
                  appLanguage.value == AppLanguage.ru ? "Плохо: Собака стоит" : (appLanguage.value == AppLanguage.en ? "Bad: A dog stands" : "Schlecht: Ein Hund steht"), 
                  appLanguage.value == AppLanguage.ru ? "Хорошо: Огромная собака лает огнем и взрывается" : (appLanguage.value == AppLanguage.en ? "Good: A huge dog barks fire and explodes" : "Gut: Ein riesiger Hund bellt Feuer und explodiert")
                ),
                _infoBox(appLanguage.value == AppLanguage.ru ? "Усилители: добавляй звук, запах, юмор или даже 'фантомную' боль." : (appLanguage.value == AppLanguage.en ? "Amplifiers: add sound, smell, humor, or even 'phantom' pain." : "Verstärker: Fügen Sie Ton, Geruch, Humor oder sogar 'Phantomschmerz' hinzu."), accent),
              ],
            ),
            _lessonCard(
              context,
              AppTexts.translate(AppTexts.linkingLesson['title'] as Map<AppLanguage, String>),
              AppTexts.translate(AppTexts.linkingLesson['subtitle'] as Map<AppLanguage, String>),
              Icons.link_rounded,
              [
                const MnemonicLinkingLessonWidget(),
                _textBlock(appLanguage.value == AppLanguage.ru ? "Чтобы информация не 'рассыпалась', образы должны взаимодействовать друг с другом." : (appLanguage.value == AppLanguage.en ? "To prevent information from 'falling apart', images must interact with each other." : "Damit Informationen nicht 'auseinanderfallen', müssen Bilder miteinander interagieren.")),
                _infoBox(appLanguage.value == AppLanguage.ru ? "Правило: первый образ должен физически влиять на второй." : (appLanguage.value == AppLanguage.en ? "Rule: the first image must physically affect the second." : "Regel: Das erste Bild muss das zweite physisch beeinflussen."), accent),
                _subHeader(AppTexts.translate(AppTexts.linkingLesson['example_title'] as Map<AppLanguage, String>)),
                _comparisonBox(
                  AppTexts.translate(AppTexts.linkingLesson['bad_example'] as Map<AppLanguage, String>),
                  AppTexts.translate(AppTexts.linkingLesson['good_example'] as Map<AppLanguage, String>),
                ),
              ],
            ),

            const SizedBox(height: 30),
            _buildSectionHeader(appLanguage.value == AppLanguage.ru ? "АРХИТЕКТУРА" : (appLanguage.value == AppLanguage.en ? "ARCHITECTURE" : "ARCHITEKTUR"), Icons.architecture_rounded),
            _lessonCard(
              context,
              appLanguage.value == AppLanguage.ru ? 'Метод Локи (Дворец)' : (appLanguage.value == AppLanguage.en ? 'Method of Loci (Palace)' : 'Loci-Methode (Palast)'),
              appLanguage.value == AppLanguage.ru ? 'Легендарная техника древнегреческих ораторов.' : (appLanguage.value == AppLanguage.en ? 'Legendary technique of ancient Greek orators.' : 'Legendäre Technik antiker griechischer Redner.'),
              Icons.account_balance_outlined,
              [
                const MnemonicLociLessonWidget(),
                _textBlock(appLanguage.value == AppLanguage.ru ? "Ты запоминаешь информацию, 'раскладывая' её по знакомому пространству: квартире или маршруту до зала." : (appLanguage.value == AppLanguage.en ? "You remember information by 'placing' it in a familiar space: an apartment or a route to the gym." : "Du merkst dir Informationen, indem du sie in einem vertrauten Raum 'platzierst': einer Wohnung oder einer Route zum Fitnessstudio.")),
                _subHeader(appLanguage.value == AppLanguage.ru ? "Как это работает?" : (appLanguage.value == AppLanguage.en ? "How it works?" : "Wie es funktioniert?")),
                _stepItem("1", appLanguage.value == AppLanguage.ru ? "Выбери место" : (appLanguage.value == AppLanguage.en ? "Choose a place" : "Wähle einen Ort"), appLanguage.value == AppLanguage.ru ? "Комната, которую ты знаешь идеально." : (appLanguage.value == AppLanguage.en ? "A room you know perfectly." : "Ein Raum, den du perfekt kennst.")),
                _stepItem("2", appLanguage.value == AppLanguage.ru ? "Создай маршрут" : (appLanguage.value == AppLanguage.en ? "Create a route" : "Erstelle eine Route"), appLanguage.value == AppLanguage.ru ? "Всегда один порядок: Дверь → Зеркало → Стол..." : (appLanguage.value == AppLanguage.en ? "Always the same order: Door → Mirror → Table..." : "Immer die gleiche Reihenfolge: Tür → Spiegel → Tisch...")),
                _stepItem("3", appLanguage.value == AppLanguage.ru ? "Добавь образы" : (appLanguage.value == AppLanguage.en ? "Add images" : "Bilder hinzufügen"), appLanguage.value == AppLanguage.ru ? "Размести по одному образу в каждой точке." : (appLanguage.value == AppLanguage.en ? "Place one image at each point." : "Platziere ein Bild an jedem Punkt.")),
                _infoBox(appLanguage.value == AppLanguage.ru ? "Ошибка: не меняй порядок мест и не используй похожие локации!" : (appLanguage.value == AppLanguage.en ? "Mistake: do not change the order of places or use similar locations!" : "Fehler: Ändern Sie nicht die Reihenfolge der Orte und verwenden Sie keine ähnlichen Orte!"), accent),
              ],
            ),

            const SizedBox(height: 30),
            _buildSectionHeader(appLanguage.value == AppLanguage.ru ? "СПЕЦИАЛИЗАЦИЯ" : (appLanguage.value == AppLanguage.en ? "SPECIALIZATION" : "SPEZIALISIERUNG"), Icons.star_outline_rounded),
            _lessonCard(
              context,
              appLanguage.value == AppLanguage.ru ? 'Запоминание чисел' : (appLanguage.value == AppLanguage.en ? 'Memorizing Numbers' : 'Zahlen merken'),
              appLanguage.value == AppLanguage.ru ? 'Превращаем сухие цифры в живых персонажей.' : (appLanguage.value == AppLanguage.en ? 'Turning dry numbers into living characters.' : 'Trockene Zahlen in lebendige Charaktere verwandeln.'),
              Icons.numbers_rounded,
              [
                const MnemonicNumbersLessonWidget(),
                _textBlock(appLanguage.value == AppLanguage.ru ? "Числа абстрактны. Наша цель — присвоить каждому числу (00-99) свой постоянный образ." : (appLanguage.value == AppLanguage.en ? "Numbers are abstract. Our goal is to assign each number (00-99) its own permanent image." : "Zahlen sind abstrakt. Unser Ziel ist es, jeder Zahl (00-99) ein eigenes permanentes Bild zuzuweisen.")),
                _infoBox(appLanguage.value == AppLanguage.ru ? "Пример: 01=Ёж, 02=Яд, 03=Ухо. Теперь 010203 — это история про ежа и яд." : (appLanguage.value == AppLanguage.en ? "Example: 01=Hedgehog, 02=Poison, 03=Ear. Now 010203 is a story about a hedgehog and poison." : "Beispiel: 01=Igel, 02=Gift, 03=Ohr. Jetzt ist 010203 eine Geschichte über einen Igel und Gift."), accent),
                _subHeader(appLanguage.value == AppLanguage.ru ? "Продвинутый уровень (PAO)" : (appLanguage.value == AppLanguage.en ? "Advanced Level (PAO)" : "Fortgeschrittenes Level (PAO)")),
                _textBlock(appLanguage.value == AppLanguage.ru ? "Система Персонаж-Действие-Объект позволяет запоминать 6 цифр в одном образе." : (appLanguage.value == AppLanguage.en ? "The Person-Action-Object system allows memorizing 6 digits in one image." : "Das Person-Aktion-Objekt-System ermöglicht das Einprägen von 6 Ziffern in einem Bild.")),
              ],
            ),
            _lessonCard(
              context,
              appLanguage.value == AppLanguage.ru ? 'Бинарные числа' : (appLanguage.value == AppLanguage.en ? 'Binary Numbers' : 'Binärzahlen'),
              appLanguage.value == AppLanguage.ru ? 'Как профессионалы запоминают сотни нулей и единиц.' : (appLanguage.value == AppLanguage.en ? 'How professionals memorize hundreds of zeros and ones.' : 'Wie Profis Hunderte von Nullen und Einsen auswendig lernen.'),
              Icons.data_array_rounded,
              [
                _textBlock(appLanguage.value == AppLanguage.ru ? "Бинары по 3 цифры имеют всего 8 комбинаций. Закодируй каждую в число (0-7)." : (appLanguage.value == AppLanguage.en ? "Binaries of 3 digits have only 8 combinations. Code each into a number (0-7)." : "Binärzahlen aus 3 Ziffern haben nur 8 Kombinationen. Kodieren Sie jede in eine Zahl (0-7).")),
                _infoBox(appLanguage.value == AppLanguage.ru ? "001=1 (Яблоко), 011=2 (Лебедь), 111=3 (Тризуб)..." : (appLanguage.value == AppLanguage.en ? "001=1 (Apple), 011=2 (Swan), 111=3 (Trident)..." : "001=1 (Apfel), 011=2 (Schwan), 111=3 (Dreizack)..."), accent),
                _textBlock(appLanguage.value == AppLanguage.ru ? "Теперь бинарная лента '001111011' превращается в '1-3-2'." : (appLanguage.value == AppLanguage.en ? "Now the binary tape '001111011' turns into '1-3-2'." : "Jetzt verwandelt sich das Binärband '001111011' in '1-3-2'.")),
              ],
            ),
            _lessonCard(
              context,
              appLanguage.value == AppLanguage.ru ? 'Слова и Изображения' : (appLanguage.value == AppLanguage.en ? 'Words and Images' : 'Wörter und Bilder'),
              appLanguage.value == AppLanguage.ru ? 'Работа с абстрактными понятиями и картинками.' : (appLanguage.value == AppLanguage.en ? 'Working with abstract concepts and images.' : 'Arbeit mit abstrakten Konzepten und Bildern.'),
              Icons.abc_rounded,
              [
                _subHeader(appLanguage.value == AppLanguage.ru ? "Слова" : (appLanguage.value == AppLanguage.en ? "Words" : "Wörter")),
                _textBlock(appLanguage.value == AppLanguage.ru ? "Разбивай слово на части: 'Компьютер' → комп + пьют + тер. Создай из этого сюжет." : (appLanguage.value == AppLanguage.en ? "Break the word into parts: 'Computer' → comp + put + er. Create a story out of this." : "Zerlegen Sie das Wort in Teile: 'Computer' → Comp + put + er. Machen Sie daraus eine Geschichte.")),
                _subHeader(appLanguage.value == AppLanguage.ru ? "Изображения" : (appLanguage.value == AppLanguage.en ? "Images" : "Bilder")),
                _textBlock(appLanguage.value == AppLanguage.ru ? "Не запоминай картинку как есть. Найди в ней главную деталь, преувеличь её и помести в локу." : (appLanguage.value == AppLanguage.en ? "Don't memorize the image as is. Find the main detail in it, exaggerate it, and place it in a loci." : "Merken Sie sich das Bild nicht so, wie es ist. Finden Sie das Hauptdetail darin, übertreiben Sie es und platzieren Sie es in einem Locus.")),
              ],
            ),

            const SizedBox(height: 30),
            _buildSectionHeader(appLanguage.value == AppLanguage.ru ? "ПРАКТИКА" : (appLanguage.value == AppLanguage.en ? "PRACTICE" : "PRAXIS"), Icons.speed_rounded),
            _lessonCard(
              context,
              appLanguage.value == AppLanguage.ru ? 'Скорость и Ошибки' : (appLanguage.value == AppLanguage.en ? 'Speed and Mistakes' : 'Geschwindigkeit und Fehler'),
              appLanguage.value == AppLanguage.ru ? 'Как выйти на уровень чемпионата.' : (appLanguage.value == AppLanguage.en ? 'How to reach the championship level.' : 'Wie man das Meisterschaftsniveau erreicht.'),
              Icons.bolt_rounded,
              [
                _subHeader(appLanguage.value == AppLanguage.ru ? "Почему ты медлишь?" : (appLanguage.value == AppLanguage.en ? "Why are you slow?" : "Warum bist du langsam?")),
                _bulletPoint(appLanguage.value == AppLanguage.ru ? "Образы не автоматизированы" : (appLanguage.value == AppLanguage.en ? "Images are not automated" : "Bilder sind nicht automatisiert")),
                _bulletPoint(appLanguage.value == AppLanguage.ru ? "Слабая визуализация" : (appLanguage.value == AppLanguage.en ? "Weak visualization" : "Schwache Visualisierung")),
                _infoBox(appLanguage.value == AppLanguage.ru ? "Решение: тренируйся по 10-15 минут ежедневно с таймером." : (appLanguage.value == AppLanguage.en ? "Solution: practice for 10-15 minutes daily with a timer." : "Lösung: Trainieren Sie täglich 10-15 Minuten mit einem Timer."), accent),
                _subHeader(appLanguage.value == AppLanguage.ru ? "Основные ошибки" : (appLanguage.value == AppLanguage.en ? "Main Mistakes" : "Hauptfehler")),
                _bulletPoint(appLanguage.value == AppLanguage.ru ? "Скучные образы без движения" : (appLanguage.value == AppLanguage.en ? "Boring images without movement" : "Langweilige Bilder ohne Bewegung")),
                _bulletPoint(appLanguage.value == AppLanguage.ru ? "Хаотичные дворцы памяти" : (appLanguage.value == AppLanguage.en ? "Chaotic memory palaces" : "Chaotische Gedächtnispaläste")),
                _bulletPoint(appLanguage.value == AppLanguage.ru ? "Перегрузка локаций (больше 2 образов на точку)" : (appLanguage.value == AppLanguage.en ? "Location overload (more than 2 images per point)" : "Überlastung der Orte (mehr als 2 Bilder pro Punkt)")),
              ],
            ),
            
            const SizedBox(height: 60),
            _buildConclusion(onSurface, accent),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: appAccentColor.value.withOpacity(0.5)),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(
            color: appAccentColor.value.withOpacity(0.5), 
            fontSize: 10, 
            fontWeight: FontWeight.w900, 
            letterSpacing: 2
          )),
        ],
      ),
    );
  }

  Widget _lessonCard(BuildContext context, String title, String subtitle, IconData icon, List<Widget> children) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final palette = appPalette.value;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border.withOpacity(0.4)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: appAccentColor.value.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: appAccentColor.value, size: 24),
          ),
          title: Text(title, style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text(subtitle, style: TextStyle(color: onSurface.withOpacity(0.4), fontSize: 12)),
          iconColor: appAccentColor.value,
          collapsedIconColor: onSurface.withOpacity(0.2),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textBlock(String text) {
    return Builder(builder: (context) {
      final onSurface = Theme.of(context).colorScheme.onSurface;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text, style: TextStyle(color: onSurface.withOpacity(0.7), height: 1.5, fontSize: 14)),
      );
    });
  }

  Widget _subHeader(String title) {
    return Builder(builder: (context) {
      return Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(title, style: TextStyle(color: appAccentColor.value, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
      );
    });
  }

  Widget _bulletPoint(String text) {
    return Builder(builder: (context) {
      final onSurface = Theme.of(context).colorScheme.onSurface;
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("• ", style: TextStyle(color: appAccentColor.value, fontWeight: FontWeight.bold)),
            Expanded(child: Text(text, style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 14))),
          ],
        ),
      );
    });
  }

  Widget _infoBox(String text, Color accent) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.1)),
      ),
      child: Text(text, style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.w500, height: 1.4)),
    );
  }

  Widget _comparisonBox(String bad, String good) {
    return Column(
      children: [
        _miniLabel("ПЛОХО", Colors.redAccent),
        _textBlock(bad),
        _miniLabel("ИДЕАЛЬНО", const Color(0xFF00E676)),
        _textBlock(good),
      ],
    );
  }

  Widget _miniLabel(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
    );
  }

  Widget _stepItem(String num, String title, String desc) {
    return Builder(builder: (context) {
      final onSurface = Theme.of(context).colorScheme.onSurface;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24, height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: appAccentColor.value, shape: BoxShape.circle),
              child: Text(num, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(desc, style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildConclusion(Color onSurface, Color accent) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.emoji_events_outlined, color: accent, size: 48),
          const SizedBox(height: 16),
          Text('Мнемотехника — это не талант.\nЭто навык.', 
            textAlign: TextAlign.center,
            style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.w200, height: 1.4)),
          const SizedBox(height: 12),
          Text('Тренируйся каждый день,\nи твой мозг тебя удивит.', 
            textAlign: TextAlign.center,
            style: TextStyle(color: onSurface.withOpacity(0.4), fontSize: 13)),
        ],
      ),
    );
  }
}

// --- ЭКРАН ТРЕНИРОВКИ ---
class TrainingScreen extends StatefulWidget {
  final TrainingMode? initialMode;
  const TrainingScreen({super.key, this.initialMode});
  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final TextEditingController _totalCountController = TextEditingController(text: "4");
  final TextEditingController _chunkSizeController = TextEditingController(text: "1");
  final TextEditingController _flashSecondsController = TextEditingController(text: "2.0");
  final TextEditingController _slotController = TextEditingController(text: "1");
  
  late TrainingMode _selectedMode;
  bool _useMemorizationTimer = false;
  int _standardDigits = 2;
  
  @override
   void initState() {
     super.initState();
     _selectedMode = widget.initialMode ?? TrainingMode.standard;
   }
  final List<String> _fallbackDictionary = const [
    'Стол', 'Стул', 'Диван', 'Кровать', 'Шкаф', 'Полка', 'Кресло', 'Тумбочка', 'Комод', 'Зеркало',
    'Ковер', 'Штора', 'Люстра', 'Лампа', 'Картина', 'Ваза', 'Подушка', 'Одеяло', 'Матрас', 'Дверь',
    'Окно', 'Подоконник', 'Порог', 'Стена', 'Пол', 'Потолок', 'Лестница', 'Вешалка', 'Замок', 'Ключ',
    'Холодильник', 'Плита', 'Духовка', 'Микроволновка', 'Чайник', 'Кастрюля', 'Сковорода', 'Тарелка', 'Чашка', 'Стакан',
    'Ложка', 'Вилка', 'Нож', 'Доска', 'Половник', 'Дуршлаг', 'Терка', 'Салфетка', 'Скатерть', 'Фартук',
    'Хлеб', 'Молоко', 'Сыр', 'Яйцо', 'Мясо', 'Рыба', 'Овощ', 'Фрукт', 'Сахар', 'Соль',
    'Рубашка', 'Футболка', 'Брюки', 'Джинсы', 'Платье', 'Юбка', 'Кофта', 'Свитер', 'Куртка', 'Пальто',
    'Шапка', 'Шарф', 'Перчатки', 'Носки', 'Трусы', 'Ботинки', 'Кроссовки', 'Туфли', 'Сапоги', 'Тапочки',
    'Ремень', 'Сумка', 'Рюкзак', 'Кошелек', 'Часы', 'Очки', 'Зонт', 'Кольцо', 'Браслет', 'Галстук',
    'Компьютер', 'Ноутбук', 'Телефон', 'Планшет', 'Монитор', 'Клавиатура', 'Мышь', 'Принтер', 'Сканер', 'Наушники',
    'Колонка', 'Телевизор', 'Камера', 'Плеер', 'Провод', 'Зарядка', 'Батарейка', 'Розетка', 'Выключатель', 'Пылесос',
    'Утюг', 'Фен', 'Кондиционер', 'Вентилятор', 'Радио', 'Флешка', 'Диск', 'Экран', 'Кнопка', 'Пульт',
    'Ручка', 'Карандаш', 'Тетрадь', 'Блокнот', 'Книга', 'Учебник', 'Линейка', 'Ластик', 'Точилка', 'Клей',
    'Ножницы', 'Скрепка', 'Папка', 'Бумага', 'Маркер', 'Краска', 'Кисть', 'Альбом', 'Циркуль', 'Дырокол',
    'Степлер', 'Календарь', 'Карта', 'Глобус', 'Мел', 'Доска', 'Пенал', 'Конверт', 'Марка', 'Печать',
    'Машина', 'Автобус', 'Трамвай', 'Троллейбус', 'Поезд', 'Метро', 'Самолет', 'Вертолет', 'Корабль', 'Лодка',
    'Велосипед', 'Самокат', 'Мотоцикл', 'Колесо', 'Руль', 'Фара', 'Дорога', 'Тротуар', 'Светофор', 'Мост',
    'Здание', 'Магазин', 'Аптека', 'Школа', 'Больница', 'Парк', 'Лавочка', 'Фонтан', 'Фонарь', 'Урна',
    'Дерево', 'Цветок', 'Трава', 'Лист', 'Корень', 'Ветка', 'Камень', 'Песок', 'Земля', 'Вода',
    'Река', 'Озеро', 'Море', 'Гора', 'Лес', 'Небо', 'Облако', 'Солнце', 'Луна', 'Звезда',
    'Собака', 'Кошка', 'Птица', 'Рыба', 'Насекомое', 'Лошадь', 'Корова', 'Медведь', 'Волк', 'Заяц',
    'Мыло', 'Шампунь', 'Щетка', 'Паста', 'Полотенце', 'Мочалка', 'Расческа', 'Бритва', 'Ванна', 'Душ',
    'Раковина', 'Унитаз', 'Кран', 'Стиральный порошок', 'Туалетная бумага', 'Крем', 'Духи', 'Косметичка', 'Халат', 'Таз',
    'Молоток', 'Отвертка', 'Пила', 'Топор', 'Гвоздь', 'Винт', 'Клещи', 'Гаечный ключ', 'Дрель', 'Рулетка',
    'Лопата', 'Грабли', 'Ведро', 'Леска', 'Ткань', 'Нитки', 'Иголка', 'Верёвка', 'Проволока', 'Стекло',
    'Мяч', 'Ракетка', 'Сетка', 'Коньки', 'Лыжи', 'Гантели', 'Коврик', 'Скакалка', 'Шлем', 'Палатка',
    'Спальник', 'Рюкзак', 'Гитара', 'Пианино', 'Флейта', 'Карта', 'Шахматы', 'Кубик', 'Кукла', 'Машинка',
    'Таблетка', 'Пластырь', 'Бинт', 'Вата', 'Шприц', 'Термометр', 'Маска', 'Очки', 'Витамины', 'Микстура',
    'Скальпель', 'Жгут', 'Грелка', 'Йод', 'Пипетка', 'Шина', 'Зонд', 'Ланцет', 'Полис', 'Рецепт',
    'Деньги', 'Монета', 'Билет', 'Паспорт', 'Газета', 'Журнал', 'Письмо', 'Коробка', 'Пакет', 'Корзина',
    'Чемодан', 'Флаг', 'Подарок', 'Свеча', 'Спички', 'Зажигалка', 'Фонарик', 'Батарея', 'Пепельница', 'Кошелёк',
    'Крючок', 'Цепь', 'Магнит', 'Песочные часы', 'Компас', 'Труба', 'Шнурок', 'Пуговица', 'Медаль', 'Статуя',
    'Якорь', 'Штурвал', 'Парус', 'Ракушка', 'Перо', 'Свисток', 'Клюшка', 'Шайба', 'Обруч', 'Конус',
    'Глобус', 'Радар', 'Телескоп', 'Микроскоп', 'Лупа', 'Весы', 'Гиря', 'Свинья-копилка', 'Фарфор', 'Хрусталь',
    'Черепица', 'Кирпич', 'Бетон', 'Шифер', 'Доска', 'Бревно', 'Пень', 'Шишка', 'Желудь', 'Орех',
    'Гриб', 'Ягода', 'Колос', 'Сено', 'Солома', 'Улей', 'Мёд', 'Воск', 'Глина', 'Уголь', 'гойда'
  ];
  List<String> _data = [];
  int _currentChunkIndex = 0;
  bool _isSettingsMode = true;
  bool _isMemorizing = false;
  bool _isInputMode = false;
  bool _isChecking = false;
  bool _isPreparingImages = false;
  bool _isMatrixMode = false;
  int _preloadedImageCount = 0;
  int _totalImagesToPreload = 0;
  int _activeImageSlot = 1;
  int _selectedImageIndex = -1;
  int _currentPage = 0;
  final int _slotPage = 0;

  List<TextEditingController> _controllers = [];
  List<FocusNode> _focusNodes = [];
  List<int> _shuffledImageIndices = [];
  List<int?> _imageAnswerOrder = [];
  List<ImageProvider> _imageProviders = [];

  Timer? _mainTimer;
  Timer? _autoPlayTimer;
  Timer? _counterHoldTimer;
  int _memorizationTime = 0;
  int _recallTime = 0;
  final Stopwatch _memorizationStopwatch = Stopwatch();
  final Stopwatch _recallStopwatch = Stopwatch();
  int _memorizationElapsedMs = 0;
  int _recallElapsedMs = 0;
  String _resultComparisonLine = '';
  String _streakLine = '';
  int _xpEarnedLast = 0;
  bool _perfectMemLast = false;

  @override
  void dispose() {
    _mainTimer?.cancel();
    _autoPlayTimer?.cancel();
    _totalCountController.dispose();
    _chunkSizeController.dispose();
    _flashSecondsController.dispose();
    _slotController.dispose();
    _counterHoldTimer?.cancel();
    for (var c in _controllers) { c.dispose(); }
    for (var f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  Future<void> _generateData() async {
    HapticFeedback.selectionClick();
    int total = int.tryParse(_totalCountController.text) ?? 4;
    total = max(1, total);
    final random = Random();
    
    if (_selectedMode == TrainingMode.standard) {
      if (_isMatrixMode) {
        _data = List.generate(total, (_) => random.nextInt(10).toString());
      } else {
        final maxExclusive = _standardDigits == 1 ? 10 : (_standardDigits == 2 ? 100 : 1000);
        _data = List.generate(
          total,
          (_) => random.nextInt(maxExclusive).toString().padLeft(_standardDigits, '0'),
        );
      }
    } else if (_selectedMode == TrainingMode.binary) {
      _data = List.generate(total, (_) => List.generate(3, (index) => random.nextInt(2)).join());
    } else if (_selectedMode == TrainingMode.words) {
      final words = await loadWordsForLanguage(
        appLanguage.value,
        fallback: _fallbackDictionary,
      );
      _data = List.generate(total, (_) => words[random.nextInt(words.length)]);
    } else if (_selectedMode == TrainingMode.cards) {
      final suits = ['h', 'd', 'c', 's'];
      final ranks = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'j', 'q', 'k', 'a'];
      final deck = [for (var s in suits) for (var r in ranks) '$s$r'];
      _data = List.generate(total, (_) => deck[random.nextInt(deck.length)]);
    } else {
      final ids = List.generate(2000, (i) => i + 1)..shuffle(random);
      _data = ids
          .take(total)
          .map((id) => 'https://picsum.photos/seed/$id/400/300')
          .toList();
      _imageProviders = _data
          .map((url) => ResizeImage(NetworkImage(url), width: 700))
          .toList();
    }

    _controllers = List.generate(total, (_) => TextEditingController());
    _focusNodes = List.generate(total, (_) => FocusNode());
    _imageAnswerOrder = List<int?>.filled(total, null);
    _shuffledImageIndices = List.generate(total, (i) => i)..shuffle(random);

    if (_selectedMode == TrainingMode.images) {
      setState(() {
        _isPreparingImages = true;
        _preloadedImageCount = 0;
        _totalImagesToPreload = _data.length;
      });
      for (int idx = 0; idx < _data.length; idx++) {
        final url = _data[idx];
        try {
          final provider = idx >= 0 && idx < _imageProviders.length
              ? _imageProviders[idx]
              : NetworkImage(url);
          await precacheImage(provider, context);
        } catch (_) {
          try {
            final provider = idx >= 0 && idx < _imageProviders.length
                ? _imageProviders[idx]
                : NetworkImage(url);
            await Future.delayed(const Duration(milliseconds: 200));
            await precacheImage(provider, context);
          } catch (_) {
            // Игнорируем единичные сетевые ошибки, чтобы тренировка все равно запустилась.
          }
        } finally {
          if (mounted) {
            setState(() => _preloadedImageCount++);
          }
        }
      }
      if (mounted) {
        setState(() => _isPreparingImages = false);
      }
    }
    
    _memorizationTime = 0;
    _recallTime = 0;
    _memorizationElapsedMs = 0;
    _recallElapsedMs = 0;
    _resultComparisonLine = '';
    _streakLine = '';
    _slotController.text = '1';
    _memorizationStopwatch.reset();
    _recallStopwatch.reset();

    _mainTimer?.cancel(); // Убедимся, что старый таймер отменен
    _mainTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_isMemorizing) {
            _memorizationTime++;
          } else if (_isInputMode && !_isChecking) {
            _recallTime++;
          }
        });
      }
    });

    _memorizationStopwatch.reset();
    _memorizationStopwatch.start();
    setState(() { 
      _isSettingsMode = false; 
      _isMemorizing = true; 
      _currentChunkIndex = 0; 
      _isChecking = false;
    });
    _handleAutoPlay();
  }

  void _handleAutoPlay() {
    if (_useMemorizationTimer && _isMemorizing) {
      final double flashSeconds = double.tryParse(_flashSecondsController.text) ?? 2.0;
      int chunkSize = int.tryParse(_chunkSizeController.text) ?? 1;
      
      // Рассчитываем время на весь чанк (количество элементов в чанке * время на 1 элемент)
      double totalChunkSeconds = chunkSize * flashSeconds;
      
      _autoPlayTimer?.cancel();
      _autoPlayTimer = Timer(Duration(milliseconds: (totalChunkSeconds * 1000).round()), () {
        if (_isMemorizing) _nextChunk();
      });
    }
  }

  void _nextChunk() {
    HapticFeedback.lightImpact();
    int chunkSize = int.tryParse(_chunkSizeController.text) ?? 1;
    if ((_currentChunkIndex + 1) * chunkSize < _data.length) {
      setState(() => _currentChunkIndex++);
      _handleAutoPlay();
    } else {
      _autoPlayTimer?.cancel();
      _memorizationStopwatch.stop();
      _memorizationElapsedMs = _memorizationStopwatch.elapsedMilliseconds;
      _recallStopwatch.reset();
      _recallStopwatch.start();
      setState(() {
        _isMemorizing = false;
        _isInputMode = true;
        if (_selectedMode == TrainingMode.images) {
          _shuffledImageIndices.shuffle();
          _imageAnswerOrder = List<int?>.filled(_data.length, null);
          _activeImageSlot = 1;
          _slotController.text = '1';
          _selectedImageIndex = -1;
          _currentPage = 0;
        }
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_focusNodes.isNotEmpty && mounted) {
          _focusNodes[0].requestFocus();
        }
      });
    }
  }

  void _previousChunk() {
    if (_currentChunkIndex <= 0) return;
    HapticFeedback.lightImpact();
    _autoPlayTimer?.cancel();
    setState(() => _currentChunkIndex--);
    _handleAutoPlay();
  }

  void _goToFirstChunk() {
    if (_currentChunkIndex == 0) return;
    HapticFeedback.selectionClick();
    _autoPlayTimer?.cancel();
    setState(() => _currentChunkIndex = 0);
    _handleAutoPlay();
  }

  Future<void> _finalizeAndPersistResults() async {
    HapticFeedback.heavyImpact();
    if (_recallStopwatch.isRunning) {
      _recallStopwatch.stop();
      _recallElapsedMs = _recallStopwatch.elapsedMilliseconds;
    }
    if (_memorizationElapsedMs == 0 && _memorizationTime > 0) {
      _memorizationElapsedMs = _memorizationTime * 1000;
    }

    int correctCount = 0;
    if (_selectedMode == TrainingMode.images) {
      for (int i = 0; i < _data.length; i++) {
        if (_imageAnswerOrder[i] == i + 1) correctCount++;
      }
    } else if (_selectedMode == TrainingMode.cards) {
      for (int i = 0; i < _data.length; i++) {
        if (_controllers[i].text.trim().toLowerCase() == _data[i].toLowerCase()) correctCount++;
      }
    } else {
      for (int i = 0; i < _data.length; i++) {
        if (_controllers[i].text.trim().toLowerCase() == _data[i].toLowerCase()) correctCount++;
      }
    }
    final double percentage = (_data.isEmpty) ? 0 : (correctCount / _data.length) * 100;
    final int n = _data.length;
    final int avgMemMsPerEl = n <= 0 ? 0 : (_memorizationElapsedMs / n).round();

    _perfectMemLast = correctCount >= 10;
    _xpEarnedLast = await ProgressService.instance.awardMemorization(memorizedCount: correctCount);

    // Update Quests
    final String modeId = _selectedMode.name == 'standard' ? 'numbers' : _selectedMode.name;
    final prefs = await SharedPreferences.getInstance();
    final String modeKey = _selectedMode.name;
    
    // 1. Training completed (generic)
    await QuestService.instance.updateProgress(type: QuestType.completeXTrainings, value: 1);
    
    // 2. Memorize N elements (best result in this session)
    await QuestService.instance.updateProgress(type: QuestType.memorizeN, value: correctCount);
    
    // 3. Total memorized (cumulative)
    await QuestService.instance.updateProgress(type: QuestType.totalMemorizedN, value: correctCount);
    
    // 4. Specific mode
    await QuestService.instance.updateProgress(type: QuestType.trainMode, modeId: modeId, value: 1);
    
    // 5. No errors
    if (percentage >= 100) {
      await QuestService.instance.updateProgress(type: QuestType.noErrors, isPerfect: true);
    }
    
    // 6. Improve record
    int currentBestBefore = prefs.getInt('best_score_$modeKey') ?? 0;
    if (correctCount > currentBestBefore) {
      await QuestService.instance.updateProgress(type: QuestType.improveRecord, value: 1);
    }

    final String historyKey = 'game_history_$modeKey';
    final List<String> historyRaw = List<String>.from(prefs.getStringList(historyKey) ?? []);

    double? prevPctSameN;
    for (final raw in historyRaw) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        if ((m['n'] as num).toInt() == n) {
          prevPctSameN = (m['pct'] as num).toDouble();
          break;
        }
      } catch (_) {}
    }

    final String modeLabelKey = modeKey == 'standard'
        ? 'mode_numbers'
        : modeKey == 'binary'
            ? 'mode_binary'
            : modeKey == 'words'
                ? 'mode_words'
                : modeKey == 'images' 
                    ? 'mode_photo'
                    : modeKey == 'cards'
                        ? 'mode_cards'
                        : 'mode_digits';
    final modeLabel = AppTexts.get(modeLabelKey);
    final pluralElements = AppTexts.plural(n, 'plural_element');

    if (prevPctSameN == null) {
      _resultComparisonLine = AppTexts.get('result_first_attempt', params: {
        'n': n.toString(),
        'plural': pluralElements,
        'mode': modeLabel,
      });
    } else if (prevPctSameN <= 0) {
      _resultComparisonLine = AppTexts.get('result_previous_zero', params: {
        'n': n.toString(),
        'plural': pluralElements,
        'pct': percentage.toStringAsFixed(0),
      });
    } else {
      final imp = ((percentage - prevPctSameN) / prevPctSameN) * 100.0;
      if (imp >= 0) {
        _resultComparisonLine = AppTexts.get('result_improvement', params: {
          'imp': imp.toStringAsFixed(1),
          'n': n.toString(),
          'plural': pluralElements,
        });
      } else {
        _resultComparisonLine = AppTexts.get('result_decline', params: {
          'imp': (-imp).toStringAsFixed(1),
          'n': n.toString(),
          'plural': pluralElements,
        });
      }
    }

    final entry = <String, dynamic>{
      't': DateTime.now().millisecondsSinceEpoch,
      'n': n,
      'c': correctCount,
      'pct': percentage,
      'memMs': _memorizationElapsedMs,
      'recMs': _recallElapsedMs,
      'avgMemMsPerEl': avgMemMsPerEl,
    };
    historyRaw.insert(0, jsonEncode(entry));
    if (historyRaw.length > _kMaxHistoryPerMode) {
      historyRaw.removeRange(_kMaxHistoryPerMode, historyRaw.length);
    }
    await prefs.setStringList(historyKey, historyRaw);

    final String bestSpeedKey = 'best_avg_ms_per_el_$modeKey';
    final int? prevBestMs = prefs.getInt(bestSpeedKey);
    if (prevBestMs == null || (avgMemMsPerEl > 0 && avgMemMsPerEl < prevBestMs)) {
      await prefs.setInt(bestSpeedKey, avgMemMsPerEl);
    }

    int currentBest = prefs.getInt('best_score_$modeKey') ?? 0;
    if (correctCount > currentBest) {
      await prefs.setInt('best_score_$modeKey', correctCount);
    }

    int games = prefs.getInt('total_games_$modeKey') ?? 0;
    double avg = prefs.getDouble('avg_percentage_$modeKey') ?? 0.0;

    await prefs.setInt('total_games_$modeKey', games + 1);
    await prefs.setDouble('avg_percentage_$modeKey', ((avg * games) + percentage) / (games + 1));
    await LeaderboardService.instance.addPoints(correctCount);
    await CloudSyncService.instance.syncNow();

    final streakNow = ProgressService.instance.progress.value.streak;
    _streakLine = AppTexts.get('streak_label', params: {'days': streakNow.toString()});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        actions: [
          if (_isMemorizing) IconButton(
            icon: const Icon(Icons.lightbulb_outline, color: Colors.white10),
            onPressed: () => showModalBottomSheet(
              context: context, 
              backgroundColor: appPalette.value.surface,
              builder: (c) => const TechniquesScreen()
            ),
          )
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _isSettingsMode
                  ? _buildSettings(key: const ValueKey('settings'))
                  : (_isMemorizing
                      ? _buildMemorizer(key: const ValueKey('memorizer'))
                      : _buildInputArea(key: const ValueKey('input'))),
            ),
          ),
          if (_isPreparingImages)
            Positioned.fill(
              child: _buildPreloadView(key: const ValueKey('preloading')),
            ),
        ],
      ),
    );
  }

  Widget _buildSettings({Key? key}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SingleChildScrollView(
      key: key,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          children: [
            _buildModeSelector(),
            if (_selectedMode == TrainingMode.standard) ...[
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.layers_outlined, size: 14, color: onSurface.withOpacity(0.3)),
                  const SizedBox(width: 8),
                  Text(AppTexts.get('modes_title'), style: TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold, color: onSurface.withOpacity(0.3))),
                ],
              ),
              const SizedBox(height: 16),
              _buildMatrixModeSwitcher(),
              if (!_isMatrixMode) ...[
                const SizedBox(height: 14),
                _buildNumberRangeSelector(),
              ],
            ],
            const SizedBox(height: 36),
            Align(
              alignment: Alignment.centerRight,
              child: _buildTimingSettingsButton(onSurface),
            ),
            const SizedBox(height: 14),
            _buildCounterSetting(AppTexts.get('settings_elements_count'), _totalCountController, isChunk: false),
            const SizedBox(height: 28),
            _buildCounterSetting(AppTexts.get('settings_chunk_count'), _chunkSizeController, isChunk: true),
            const SizedBox(height: 50),
            _buildActionButton(AppTexts.get('start'), _generateData),
          ],
        ),
      ),
    );
  }

  Widget _buildMatrixModeSwitcher() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final palette = appPalette.value;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.border.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _subModeItem(AppTexts.get('mode_numbers_sub'), false),
              _subModeItem(AppTexts.get('mode_matrix_sub'), true),
            ],
          ),
        ),
        if (_isMatrixMode) ...[
          const SizedBox(height: 12),
          Text(
            AppTexts.get('settings_matrix_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: onSurface.withOpacity(0.4),
              fontSize: 10,
              height: 1.4,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNumberRangeSelector() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final palette = appPalette.value;
    return Column(
      children: [
        Text(
          'Диапазон чисел',
          style: TextStyle(fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.bold, color: onSurface.withOpacity(0.35)),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.border.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _numberRangeItem('0-9', 1),
              _numberRangeItem('00-99', 2),
              _numberRangeItem('000-999', 3),
            ],
          ),
        ),
      ],
    );
  }

  Widget _numberRangeItem(String label, int digits) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isSelected = _standardDigits == digits;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _standardDigits = digits);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? appAccentColor.value.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w300,
            color: isSelected ? appAccentColor.value : onSurface.withOpacity(0.48),
          ),
        ),
      ),
    );
  }

  Widget _buildTimingSettingsButton(Color onSurface) {
    return GestureDetector(
      onTap: () {
        if (!_useMemorizationTimer) {
          setState(() => _useMemorizationTimer = true);
        }
        _showTimingSettingsSheet();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: appPalette.value.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: appPalette.value.border.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_rounded, size: 14, color: appAccentColor.value.withOpacity(0.92)),
            const SizedBox(width: 6),
            Text('Время', style: TextStyle(color: onSurface.withOpacity(0.62), fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showTimingSettingsSheet() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    showModalBottomSheet(
      context: context,
      backgroundColor: appPalette.value.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 4,
                decoration: BoxDecoration(
                  color: onSurface.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Таймер запоминания',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'Время на 1 элемент',
                style: TextStyle(color: onSurface.withOpacity(0.45), fontSize: 11),
              ),
              const SizedBox(height: 8),
              _buildCounterSetting(AppTexts.get('settings_flash_seconds'), _flashSecondsController, isChunk: false),
            ],
          ),
        );
      },
    );
  }

  Widget _subModeItem(String label, bool isMatrix) {
    bool isSelected = _isMatrixMode == isMatrix;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _isMatrixMode = isMatrix);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? appAccentColor.value.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w200,
            color: isSelected ? appAccentColor.value : onSurface.withOpacity(0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: appPalette.value.surface, 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appPalette.value.border.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeButton(AppTexts.get('numbers'), TrainingMode.standard),
          _modeButton(AppTexts.get('binary'), TrainingMode.binary),
          _modeButton(AppTexts.get('words'), TrainingMode.words),
          _modeButton(AppTexts.get('photo'), TrainingMode.images),
          _modeButton(AppTexts.get('cards'), TrainingMode.cards),
        ],
      ),
    );
  }

  Widget _modeButton(String label, TrainingMode mode) {
    bool isSelected = _selectedMode == mode;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedMode = mode;
          if (_selectedMode != TrainingMode.standard) {
            _isMatrixMode = false;
          }
          // При переключении режима проверяем и корректируем количество элементов на экране
          _normalizeCounter(_chunkSizeController, isChunk: true);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? appAccentColor.value.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 10, 
          letterSpacing: 1,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w200, 
          color: isSelected ? appAccentColor.value : onSurface.withOpacity(0.52)
        )),
      ),
    );
  }

  Widget _buildCounterSetting(String title, TextEditingController controller, {required bool isChunk}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isTime = controller == _flashSecondsController;
    return Column(
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w200, fontSize: 14, color: onSurface.withOpacity(0.62))),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _counterStepButton(
              icon: Icons.remove,
              onTap: () => _changeCounter(controller, isTime ? -0.1 : -1, isChunk: isChunk),
              onLongPressStart: () => _startCounterHold(controller, isTime ? -0.1 : -1, isChunk: isChunk),
            ),
            Container(
              width: 96,
              height: 50,
              alignment: Alignment.center,
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w200, color: appAccentColor.value),
                decoration: const InputDecoration(border: InputBorder.none, isCollapsed: true),
                onChanged: (_) => _normalizeCounter(controller, isChunk: isChunk),
              ),
            ),
            _counterStepButton(
              icon: Icons.add,
              onTap: () => _changeCounter(controller, isTime ? 0.1 : 1, isChunk: isChunk),
              onLongPressStart: () => _startCounterHold(controller, isTime ? 0.1 : 1, isChunk: isChunk),
            ),
          ],
        ),
      ],
    );
  }

  void _normalizeCounter(TextEditingController controller, {required bool isChunk}) {
    if (controller.text.isEmpty) return; // Разрешаем временно пустую строку при вводе
    
    if (controller == _flashSecondsController) {
      double? val = double.tryParse(controller.text);
      if (val != null) {
        if (val < 0.1) {
          controller.text = "0.1";
          controller.selection = const TextSelection.collapsed(offset: 3);
        } else if (val > 10.0) {
          controller.text = "10.0";
          controller.selection = const TextSelection.collapsed(offset: 4);
        }
      }
      return;
    }

    int val = int.tryParse(controller.text) ?? 1;
    int maxVal = isChunk ? 10 : 200;
    
    if (isChunk) {
      if (_selectedMode == TrainingMode.images) maxVal = 3;
      else if (_selectedMode == TrainingMode.cards) maxVal = 2;
      else if (_selectedMode == TrainingMode.words) maxVal = 4;
    }

    if (val > maxVal) {
      controller.text = maxVal.toString();
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
    }
    if (val < 1) {
      controller.text = "1";
      controller.selection = const TextSelection.collapsed(offset: 1);
    }
  }

  void _changeCounter(TextEditingController controller, double delta, {required bool isChunk}) {
    if (controller == _flashSecondsController) {
      double val = double.tryParse(controller.text) ?? 2.0;
      val += delta;
      if (val < 0.1) val = 0.1;
      if (val > 10.0) val = 10.0;
      setState(() => controller.text = val.toStringAsFixed(1));
      return;
    }

    int val = int.tryParse(controller.text) ?? 1;
    val += delta.toInt();
    val = max(1, val);
    
    int maxVal = isChunk ? 10 : 200;
    if (isChunk) {
      if (_selectedMode == TrainingMode.images) maxVal = 3;
      else if (_selectedMode == TrainingMode.cards) maxVal = 2;
      else if (_selectedMode == TrainingMode.words) maxVal = 4;
    }

    val = min(maxVal, val);
    setState(() => controller.text = val.toString());
  }

  void _startCounterHold(TextEditingController controller, double delta, {required bool isChunk}) {
    _counterHoldTimer?.cancel();
    _changeCounter(controller, delta, isChunk: isChunk);
    _counterHoldTimer = Timer.periodic(const Duration(milliseconds: 90), (_) {
      _changeCounter(controller, delta, isChunk: isChunk);
    });
  }

  Widget _counterStepButton({
    required IconData icon,
    required VoidCallback onTap,
    required VoidCallback onLongPressStart,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      onLongPressStart: (_) => onLongPressStart(),
      onLongPressEnd: (_) => _counterHoldTimer?.cancel(),
      onLongPressCancel: () => _counterHoldTimer?.cancel(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: onSurface.withOpacity(0.05)),
        ),
        child: Icon(icon, size: 18, color: onSurface.withOpacity(0.24)),
      ),
    );
  }

  Widget _circleIconButton(IconData icon, VoidCallback onTap) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: onSurface.withOpacity(0.05)),
        ),
        child: Icon(icon, size: 18, color: onSurface.withOpacity(0.24)),
      ),
    );
  }

  Widget _buildCardDisplay(String cardCode) {
    final palette = appPalette.value;
    final suit = cardCode[0];
    final rank = cardCode.substring(1).toUpperCase();
    
    final isRed = suit == 'h' || suit == 'd';
    final suitChar = suit == 'h' ? '♥' : 
                    suit == 'd' ? '♦' : 
                    suit == 'c' ? '♣' : '♠';
    
    // Черные масти: цвет темы, либо всегда белые по настройке.
    final suitColor = isRed
        ? const Color(0xFFFF3B30)
        : (blackSuitAlwaysWhite.value ? Colors.white : appAccentColor.value);
    final rankColor = Colors.white;

    return Container(
      width: 140,
      height: 200,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 6))
        ],
      ),
      child: Stack(
        children: [
          // Основные индексы (сверху слева)
          Positioned(
            top: 14, left: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(rank, style: TextStyle(color: rankColor, fontSize: 26, fontWeight: FontWeight.w800, height: 1)),
                const SizedBox(height: 2),
                Text(suitChar, style: TextStyle(color: suitColor, fontSize: 22, height: 1)),
              ],
            ),
          ),
          // Большая фоновая масть в центре
          Center(
            child: Text(suitChar, style: TextStyle(color: suitColor.withOpacity(0.1), fontSize: 130)),
          ),
          // Перевернутые индексы (снизу справа)
          Positioned(
            bottom: 14, right: 14,
            child: RotatedBox(
              quarterTurns: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(rank, style: TextStyle(color: rankColor, fontSize: 26, fontWeight: FontWeight.w800, height: 1)),
                  const SizedBox(height: 2),
                  Text(suitChar, style: TextStyle(color: suitColor, fontSize: 22, height: 1)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemorizer({Key? key}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final palette = appPalette.value;
    int chunkSize = int.tryParse(_chunkSizeController.text) ?? 1;
    int start = _currentChunkIndex * chunkSize;
    int end = min(start + chunkSize, _data.length);
    int totalChunks = (_data.length / chunkSize).ceil();
    bool canGoBack = _currentChunkIndex > 0;
    String formattedMemTime = '${(_memorizationTime ~/ 60).toString().padLeft(2, '0')}:${(_memorizationTime % 60).toString().padLeft(2, '0')}';
    
    if (_selectedMode == TrainingMode.standard && _isMatrixMode) {
      return MnemonicMatrixMemorizer(
        data: _data,
        currentChunkIndex: _currentChunkIndex,
        chunkSize: chunkSize,
        formattedTime: formattedMemTime,
        onNext: _nextChunk,
        onPrev: _previousChunk,
        onFirst: _goToFirstChunk,
        onRecallNow: () {
          _autoPlayTimer?.cancel();
          _memorizationStopwatch.stop();
          _memorizationElapsedMs = _memorizationStopwatch.elapsedMilliseconds;
          _recallStopwatch.reset();
          _recallStopwatch.start();
          setState(() {
            _isMemorizing = false;
            _isInputMode = true;
          });
        },
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        key: key,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(
            formattedMemTime, 
            style: TextStyle(
              color: Color.lerp(onSurface, appAccentColor.value, 0.3)!.withOpacity(0.45), 
              fontSize: 18, 
              fontWeight: FontWeight.w400, 
              letterSpacing: 4
            )
          ),
          const SizedBox(height: 40),
          ..._data.sublist(start, end).map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: _selectedMode == TrainingMode.images
                ? Container(
                    width: 300,
                    height: 190,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: onSurface.withOpacity(0.1)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      item,
                      fit: BoxFit.cover,
                      cacheWidth: 700,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(Icons.broken_image_outlined, color: onSurface.withOpacity(0.2), size: 42),
                      ),
                    ),
                  )
                : _selectedMode == TrainingMode.cards
                    ? _buildCardDisplay(item)
                    : Text(item.toUpperCase(), 
                        style: TextStyle(
                          fontSize: _selectedMode == TrainingMode.words ? 40 : 80, 
                          fontWeight: FontWeight.w100, 
                          letterSpacing: 8,
                          color: onSurface.withOpacity(0.9)
                        )
                      ),
          )),
          const SizedBox(height: 12),
          Text(
            '${_currentChunkIndex + 1} / $totalChunks',
            style: TextStyle(color: onSurface.withOpacity(0.2), fontSize: 12, letterSpacing: 1),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  child: _buildActionButton(AppTexts.get('back'), canGoBack ? _previousChunk : () {}),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 120,
                  child: _buildActionButton(AppTexts.get('first_chunk'), canGoBack ? _goToFirstChunk : () {}),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 100,
                  child: _buildActionButton(AppTexts.get('next_chunk'), _nextChunk),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea({Key? key}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    String formattedRecallTime = '${(_recallTime ~/ 60).toString().padLeft(2, '0')}:${(_recallTime % 60).toString().padLeft(2, '0')}';

    // Интеграция нового профессионального интерфейса для изображений (V2)
    if (_selectedMode == TrainingMode.images) {
      return MnemonicImageRecallScreen(
        imageUrls: _data,
        shuffledIndices: _shuffledImageIndices,
        initialSelections: _imageAnswerOrder,
        isResultsMode: _isChecking,
        memorizationElapsedMs: _memorizationElapsedMs,
        recallElapsedMs: _recallElapsedMs,
        xpEarned: _xpEarnedLast,
        onCompleted: (selections) async {
          setState(() {
            _imageAnswerOrder = selections;
            _isChecking = true;
          });
          try {
            await _finalizeAndPersistResults();
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Не удалось сохранить результат в облаке.')),
              );
            }
          }
        },
      );
    }

    if (_selectedMode == TrainingMode.standard && _isMatrixMode) {
      return MnemonicMatrixRecallScreen(
        correctData: _data,
        isResultsMode: _isChecking,
        onCompleted: (selections) async {
          for (int i = 0; i < selections.length; i++) {
            _controllers[i].text = selections[i] ?? "";
          }
          if (mounted) {
            setState(() => _isChecking = true);
          }
          try {
            await _finalizeAndPersistResults();
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Не удалось сохранить результат в облаке.')),
              );
            }
          }
        },
      );
    }

    if (_selectedMode == TrainingMode.cards) {
      return MnemonicCardRecallScreen(
        correctData: _data,
        isResultsMode: _isChecking,
        alwaysWhiteBlackSuits: blackSuitAlwaysWhite.value,
        memorizationElapsedMs: _memorizationElapsedMs,
        recallElapsedMs: _recallElapsedMs,
        xpEarned: _xpEarnedLast,
        onCompleted: (selections) async {
          for (int i = 0; i < selections.length; i++) {
            _controllers[i].text = selections[i] ?? "";
          }
          if (mounted) {
            setState(() => _isChecking = true);
          }
          try {
            await _finalizeAndPersistResults();
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Не удалось сохранить результат в облаке.')),
              );
            }
          }
        },
      );
    }

    return Column(
      key: key,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!_isChecking) 
          Text(
            formattedRecallTime, 
            style: TextStyle(
              color: Color.lerp(onSurface, appAccentColor.value, 0.3)!.withOpacity(0.45), 
              fontSize: 18, 
              fontWeight: FontWeight.w400, 
              letterSpacing: 4
            )
          ),
        if (_isChecking)
          (_selectedMode == TrainingMode.images || _selectedMode == TrainingMode.cards)
              ? _buildCompactStatsLauncher()
              : _buildResultsSummary(),
        const SizedBox(height: 40),
        Flexible(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Wrap(
              spacing: 12,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: List.generate(_data.length, (i) => _buildSelectionBox(i)),
            ),
          ),
        ),
        const SizedBox(height: 40),
        _buildActionButton(_isChecking ? "ВЫХОД" : "ПРОВЕРИТЬ", () async {
          if (_isChecking) {
            Navigator.pop(context); // Возврат в главное меню
          } else {
            if (mounted) {
              setState(() => _isChecking = true);
            }
            try {
              await _finalizeAndPersistResults();
            } catch (_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Не удалось сохранить результат в облаке.')),
                );
              }
            }
          }
        }),
        const SizedBox(height: 20),
      ],
    );
  }

  int _calculateCorrectCount() {
    int correctCount = 0;
    if (_selectedMode == TrainingMode.images) {
      for (int i = 0; i < _data.length; i++) {
        if (_imageAnswerOrder[i] == i + 1) correctCount++;
      }
    } else {
      for (int i = 0; i < _data.length; i++) {
        if (_controllers[i].text.trim().toLowerCase() == _data[i].toLowerCase()) {
          correctCount++;
        }
      }
    }
    return correctCount;
  }

  Widget _buildCompactStatsLauncher() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final int correctCount = _calculateCorrectCount();
    final int n = _data.length;
    final double percentage = n == 0 ? 0 : (correctCount / n) * 100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: const BoxConstraints(maxWidth: 360),
      decoration: BoxDecoration(
        color: appPalette.value.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appPalette.value.border.withOpacity(0.45)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${percentage.toStringAsFixed(0)}% · $correctCount/$n',
              style: TextStyle(
                color: appAccentColor.value,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _showVisualModeStatsSheet,
            style: TextButton.styleFrom(
              foregroundColor: appAccentColor.value,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.bar_chart_rounded, size: 16),
            label: Text(
              AppTexts.get('statistics'),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.error_outline_rounded, size: 14, color: onSurface.withOpacity(0.35)),
        ],
      ),
    );
  }

  void _showVisualModeStatsSheet() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: BoxDecoration(
                color: appPalette.value.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: appPalette.value.border.withOpacity(0.4)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Center(child: _buildResultsSummary()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultsSummary() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final int correctCount = _calculateCorrectCount();
    final double percentage = (_data.isEmpty) ? 0 : (correctCount / _data.length) * 100;
    final int n = _data.length;
    final double secPerEl =
        n <= 0 ? 0 : (_memorizationElapsedMs / 1000.0) / n;
    final double totalMemSec = _memorizationElapsedMs / 1000.0;
    final isPerfectMem = n >= 10;

    // Detailed Stats for Images and Cards (as in Numbers/Words)
    final bool showDetailedStats = _selectedMode == TrainingMode.images || _selectedMode == TrainingMode.cards;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      constraints: const BoxConstraints(maxWidth: 360),
      decoration: BoxDecoration(
        color: appPalette.value.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appPalette.value.border.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPerfectMem) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: appAccentColor.value.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: appAccentColor.value.withOpacity(0.35)),
              ),
              child: Text(
                'Perfect',
                style: TextStyle(
                  color: appAccentColor.value,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text('${percentage.toStringAsFixed(0)}%', 
            style: TextStyle(fontSize: 42, fontWeight: FontWeight.w100, color: appAccentColor.value)),
          const SizedBox(height: 6),
          Text('$correctCount / $n элементов', style: TextStyle(color: onSurface.withOpacity(0.55), fontSize: 13)),
          
          if (showDetailedStats) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: onSurface.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildStatRow(
                    onSurface, 
                    "Скорость", 
                    "${secPerEl.toStringAsFixed(2)} с/эл", 
                    Icons.speed_rounded
                  ),
                  const SizedBox(height: 8),
                  _buildStatRow(
                    onSurface, 
                    "Запоминание", 
                    "${totalMemSec.toStringAsFixed(1)} с", 
                    Icons.psychology_rounded
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            Text(
              n > 0
                  ? '${secPerEl.toStringAsFixed(2)} с на элемент (запоминание)'
                  : '—',
              textAlign: TextAlign.center,
              style: TextStyle(color: appAccentColor.value.withOpacity(0.95), fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'Всего на запоминание: ${totalMemSec.toStringAsFixed(2)} с',
              style: TextStyle(color: onSurface.withOpacity(0.45), fontSize: 11),
            ),
          ],

          const SizedBox(height: 12),
          Text(
            _resultComparisonLine,
            textAlign: TextAlign.center,
            style: TextStyle(color: onSurface.withOpacity(0.62), fontSize: 12, height: 1.35),
          ),
          if (_streakLine.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_fire_department_rounded, size: 16, color: appAccentColor.value.withOpacity(0.85)),
                const SizedBox(width: 6),
                Text(
                  _streakLine,
                  style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 11),
                ),
              ],
            ),
          ],
          if (_xpEarnedLast > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: appAccentColor.value.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: appAccentColor.value.withOpacity(0.22)),
              ),
              child: Text(
                '+ $_xpEarnedLast XP',
                style: TextStyle(
                  color: appAccentColor.value,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectionBox(int index) {
    bool isCorrect = _isChecking && _controllers[index].text.trim().toLowerCase() == _data[index].toLowerCase();
    bool isWrong = _isChecking && _controllers[index].text.trim().toLowerCase() != _data[index].toLowerCase();
    int autoNextLength = (_selectedMode == TrainingMode.standard && !_isMatrixMode)
        ? _standardDigits
        : (_selectedMode == TrainingMode.binary ? 3 : 0);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${index + 1}', style: TextStyle(fontSize: 9, color: onSurface.withOpacity(0.1))),
        const SizedBox(height: 5),
        ValueListenableBuilder<Color>(
          valueListenable: appAccentColor,
          builder: (context, accentColor, _) {
            Color borderColor = onSurface.withOpacity(0.05);
            if (isCorrect) {
              borderColor = const Color(0xFF00E676);
            }
            else if (isWrong) borderColor = const Color(0xFFFF1744);
            else if (_focusNodes[index].hasFocus) borderColor = accentColor;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 70),
              width: _selectedMode == TrainingMode.words ? 110 : 70, 
              height: 50,
              decoration: BoxDecoration(
                color: appPalette.value.card, 
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: _isChecking
                    ? null
                    : (_) {
                        final node = _focusNodes[index];
                        if (!node.hasFocus) {
                          node.requestFocus();
                          if (mounted) setState(() {});
                        }
                        SystemChannels.textInput.invokeMethod('TextInput.show');
                      },
                onTap: _isChecking
                    ? null
                    : () {
                        final node = _focusNodes[index];
                        if (!node.hasFocus) {
                          node.requestFocus();
                          if (mounted) setState(() {});
                        }
                        SystemChannels.textInput.invokeMethod('TextInput.show');
                      },
                child: Center(
                  child: TextField(
                    controller: _controllers[index], 
                    focusNode: _focusNodes[index], 
                    textAlign: TextAlign.center,
                    showCursor: false,
                    readOnly: _isChecking, // Блокируем ввод после проверки
                    textCapitalization: _selectedMode == TrainingMode.words ? TextCapitalization.words : TextCapitalization.none,
                    keyboardType: _selectedMode == TrainingMode.words ? TextInputType.text : TextInputType.number,
                    maxLength: (_selectedMode == TrainingMode.standard && !_isMatrixMode)
                        ? _standardDigits
                        : (_selectedMode == TrainingMode.binary ? 3 : null),
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.w500, 
                      color: Color.lerp(onSurface, accentColor, 0.2),
                    ),
                    decoration: const InputDecoration(border: InputBorder.none, counterText: "", isCollapsed: true),
                    onTap: () {
                      final node = _focusNodes[index];
                      if (!node.hasFocus) {
                        node.requestFocus();
                        if (mounted) setState(() {});
                      }
                      SystemChannels.textInput.invokeMethod('TextInput.show');
                    },
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      if (autoNextLength > 0 && value.length >= autoNextLength && index < _data.length - 1) {
                        _focusNodes[index + 1].requestFocus();
                      }
                    },
                  ),
                ),
              ),
            );
          }
        ),
        if (isWrong) Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(_data[index], style: const TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildActionButton(String text, VoidCallback onTap, {double width = 200}) {
    return ValueListenableBuilder<Color>(
      valueListenable: appAccentColor,
      builder: (context, accentColor, _) {
        return SizedBox(
          width: width,
          height: 56,
          child: Material(
            color: appPalette.value.surface,
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () {
                HapticFeedback.mediumImpact();
                onTap();
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: accentColor.withOpacity(0.4)),
                ),
                child: Center(
                  child: Text(
                    text,
                    style: TextStyle(
                      letterSpacing: 3,
                      fontSize: 12,
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildPreloadView({Key? key}) {
    final progress = _totalImagesToPreload == 0 ? 0.0 : _preloadedImageCount / _totalImagesToPreload;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Material(
      key: key,
      color: Colors.black.withOpacity(0.78),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: 340,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              decoration: BoxDecoration(
                color: appPalette.value.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: appAccentColor.value.withOpacity(0.45)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.45),
                    blurRadius: 22,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_download_outlined, color: appAccentColor.value, size: 36),
                  const SizedBox(height: 14),
                  Text(
                    AppTexts.get('preparing_training'),
                    style: TextStyle(
                      color: appAccentColor.value,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppTexts.get('loading_images_desc'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: onSurface.withOpacity(0.72), fontSize: 13, height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: onSurface.withOpacity(0.12),
                      color: appAccentColor.value,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppTexts.get('loading_progress', params: {
                      'current': _preloadedImageCount.toString(),
                      'total': _totalImagesToPreload.toString(),
                    }),
                    style: TextStyle(color: onSurface.withOpacity(0.72), fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _clearImageSelections() {
    if (_selectedMode != TrainingMode.images) return;
    setState(() {
      _imageAnswerOrder = List<int?>.filled(_data.length, null);
      _activeImageSlot = 1;
      _slotController.text = '1';
    });
  }
  
  Widget _buildStatRow(Color onSurface, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: appAccentColor.value.withOpacity(0.9)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: onSurface.withOpacity(0.52), fontSize: 12),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: onSurface.withOpacity(0.88),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// --- V2 ---

// --- МНЕМНИКА: ПРОФЕССИОНАЛЬНЫЙ ИНТЕРФЕЙС ВСПОМИНАНИЯ (V2) ---

class MnemonicImageRecallScreen extends StatefulWidget {
  final List<String> imageUrls;
  final List<int> shuffledIndices;
  final List<int?> initialSelections;
  final Function(List<int?>) onCompleted;
  final bool isResultsMode;
  final int memorizationElapsedMs;
  final int recallElapsedMs;
  final int xpEarned;

  const MnemonicImageRecallScreen({
    super.key,
    required this.imageUrls,
    required this.shuffledIndices,
    required this.initialSelections,
    required this.onCompleted,
    this.isResultsMode = false,
    this.memorizationElapsedMs = 0,
    this.recallElapsedMs = 0,
    this.xpEarned = 0,
  });

  @override
  State<MnemonicImageRecallScreen> createState() => _MnemonicImageRecallScreenState();
}

class _MnemonicImageRecallScreenState extends State<MnemonicImageRecallScreen> with TickerProviderStateMixin {
  // Позиция (0-indexed) -> Индекс картинки (из imageUrls)
  late Map<int, int?> _placements;
  late Set<int> _usedImageIndices;
  int _focusedPosition = 0;
  int _currentPage = 0;
  final int _pageSize = 6; // 2x3 grid for more focus
  bool _isOverviewOpen = false;
  int? _selectedFromSource;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _placements = {};
    _usedImageIndices = {};
    _pageController = PageController(initialPage: 0);
    
    // Инициализация из начального состояния (если есть)
    for (int imgIdx = 0; imgIdx < widget.initialSelections.length; imgIdx++) {
      final posPlusOne = widget.initialSelections[imgIdx];
      if (posPlusOne != null && posPlusOne > 0) {
        final pos = posPlusOne - 1;
        _placements[pos] = imgIdx;
        _usedImageIndices.add(imgIdx);
      }
    }
    
    _autoAdvanceFocus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _autoAdvanceFocus() {
    for (int i = 0; i < widget.imageUrls.length; i++) {
      if (!_placements.containsKey(i) || _placements[i] == null) {
        _setFocusPosition(i);
        return;
      }
    }
  }

  void _setFocusPosition(int pos, {bool animate = true}) {
    final total = widget.imageUrls.length;
    if (total <= 0) return;
    final clamped = pos.clamp(0, total - 1);
    setState(() {
      _focusedPosition = clamped;
      _currentPage = clamped ~/ _pageSize;
    });
    if (_pageController.hasClients && _pageController.page?.toInt() != _currentPage) {
      if (animate) {
        _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      } else {
        _pageController.jumpToPage(_currentPage);
      }
    }
  }

  void _autoAdvanceForwardFrom(int fromPos) {
    final total = widget.imageUrls.length;
    for (int i = fromPos + 1; i < total; i++) {
      if (_placements[i] == null) {
        _setFocusPosition(i);
        return;
      }
    }
    // Не возвращаемся к пропущенным: если впереди пустых нет, остаемся на текущей/последней позиции.
    _setFocusPosition(min(fromPos + 1, total - 1));
  }

  void _onImagePlaced(int pos, int imgIdx) {
    if (widget.isResultsMode) return;
    
    setState(() {
      // Если в слоте уже была картинка, возвращаем её в пул
      final oldImg = _placements[pos];
      if (oldImg != null) _usedImageIndices.remove(oldImg);

      _placements[pos] = imgIdx;
      _usedImageIndices.add(imgIdx);
      
      _selectedFromSource = null;
    });
    _autoAdvanceForwardFrom(pos);
    HapticFeedback.mediumImpact();
  }

  void _onSlotTap(int position) {
    if (widget.isResultsMode) {
      setState(() => _focusedPosition = position);
      return;
    }
    
    if (_selectedFromSource != null) {
      _onImagePlaced(position, _selectedFromSource!);
      HapticFeedback.selectionClick();
      return;
    }

    setState(() {
      if (_focusedPosition == position) {
        final img = _placements[position];
        if (img != null) {
          _usedImageIndices.remove(img);
          _placements.remove(position);
        }
      } else {
        _focusedPosition = position;
      }
    });
    HapticFeedback.selectionClick();
  }

  void _onSourceTap(int imgIdx) {
    if (widget.isResultsMode) return;
    if (_usedImageIndices.contains(imgIdx)) return;

    setState(() {
      if (_selectedFromSource == imgIdx) {
        _selectedFromSource = null;
      } else {
        _selectedFromSource = imgIdx;
        // Автоматически ставим в фокусный слот, если выбран режим Tap-to-fill
        _onImagePlaced(_focusedPosition, imgIdx);
      }
    });
    HapticFeedback.lightImpact();
  }

  void _jumpToPosition(int pos) {
    setState(() => _isOverviewOpen = false);
    _setFocusPosition(pos, animate: false);
  }

  void _onArrowNav(int delta, {bool isLongPress = false}) {
    final total = widget.imageUrls.length;
    int actualDelta = isLongPress ? (delta * 10) : delta;
    int newPos = (_focusedPosition + actualDelta).clamp(0, total - 1);
    
    if (newPos != _focusedPosition) {
      setState(() {
        _focusedPosition = newPos;
        _currentPage = _focusedPosition ~/ _pageSize;
      });
      if (_pageController.hasClients && _pageController.page?.toInt() != _currentPage) {
        _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.imageUrls.length;
    final totalPages = (total / _pageSize).ceil();
    final palette = appPalette.value;

    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(totalPages),
              if (widget.isResultsMode) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                  child: _buildResultsDashboard(),
                ),
              ],
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: 280, // Немного уменьшим высоту сетки слотов
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (p) => setState(() => _currentPage = p),
                        itemCount: totalPages,
                        itemBuilder: (context, pageIdx) => _buildTargetTable(pageIdx),
                      ),
                    ),
                    // Убрали Spacer, чтобы Deck был выше
                    _buildSourceDeck(),
                  ],
                ),
              ),
              _buildBottomBar(),
            ],
          ),
          if (_isOverviewOpen) _buildOverviewOverlay(),
        ],
      ),
    );
  }

  Widget _buildResultsDashboard() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final int n = widget.imageUrls.length;
    int correct = 0;
    for (int i = 0; i < n; i++) {
      if (_placements[i] == i) correct++;
    }
    final double pct = n == 0 ? 0 : (correct / n) * 100.0;
    final double memSec = widget.memorizationElapsedMs / 1000.0;
    final double recallSec = widget.recallElapsedMs / 1000.0;
    final double secPerEl = n == 0 ? 0 : memSec / n;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appPalette.value.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appPalette.value.border.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          Text(
            '${pct.toStringAsFixed(0)}% · $correct/$n',
            style: TextStyle(color: appAccentColor.value, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _resultRow(onSurface, Icons.speed_rounded, 'Время на элемент', '${secPerEl.toStringAsFixed(2)} с'),
          const SizedBox(height: 5),
          _resultRow(onSurface, Icons.psychology_rounded, 'Запоминание', '${memSec.toStringAsFixed(1)} с'),
          const SizedBox(height: 5),
          _resultRow(onSurface, Icons.timer_outlined, 'Вспоминание', '${recallSec.toStringAsFixed(1)} с'),
          const SizedBox(height: 5),
          _resultRow(onSurface, Icons.bolt_rounded, 'XP', '+${widget.xpEarned}'),
        ],
      ),
    );
  }

  Widget _resultRow(Color onSurface, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: onSurface.withOpacity(0.6)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 12)),
        ),
        Text(
          value,
          style: TextStyle(color: onSurface, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildHeader(int totalPages) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "TABLE VIEW • ${_currentPage + 1} / $totalPages",
                style: TextStyle(color: onSurface.withOpacity(0.3), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "Slot #${_focusedPosition + 1}",
                style: TextStyle(color: onSurface, fontSize: 22, fontWeight: FontWeight.w200),
              ),
            ],
          ),
          Row(
            children: [
              _headerButton(Icons.apps_rounded, () => setState(() => _isOverviewOpen = true)),
              const SizedBox(width: 12),
              if (!widget.isResultsMode)
                _headerButton(Icons.done_all_rounded, _finishRecall, color: appAccentColor.value, size: 28),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerButton(IconData icon, VoidCallback onTap, {Color? color, double size = 24}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final palette = appPalette.value;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.border.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color ?? onSurface.withOpacity(0.6), size: size),
      ),
    );
  }

  Widget _buildTargetTable(int pageIdx) {
    final start = pageIdx * _pageSize;
    final end = min(start + _pageSize, widget.imageUrls.length);
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.0, // Квадраты
        ),
        itemCount: end - start,
        itemBuilder: (context, index) {
          final pos = start + index;
          final isFocused = _focusedPosition == pos;
          final imgIdx = _placements[pos];
          
          Color borderColor = isFocused ? appAccentColor.value : palette.border.withOpacity(0.15);
          if (widget.isResultsMode && imgIdx != null) {
            borderColor = (imgIdx == pos) ? const Color(0xFF00E676) : const Color(0xFFFF1744);
          }

          return DragTarget<int>(
            onWillAcceptWithDetails: (details) => !widget.isResultsMode,
            onAcceptWithDetails: (details) => _onImagePlaced(pos, details.data),
            builder: (context, candidateData, rejectedData) {
              final isHovering = candidateData.isNotEmpty;
              return GestureDetector(
                onTap: () => _onSlotTap(pos),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: isFocused 
                        ? appAccentColor.value.withOpacity(0.08) 
                        : (isHovering ? appAccentColor.value.withOpacity(0.15) : palette.card.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(24), // Более округлые как на фото
                    border: Border.all(
                      color: isHovering ? appAccentColor.value : borderColor, 
                      width: (isFocused || isHovering) ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imgIdx != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.network(
                            widget.imageUrls[imgIdx],
                            fit: BoxFit.cover,
                            cacheWidth: 250,
                          ),
                        ),
                      Center(
                        child: Text(
                          "${pos + 1}",
                          style: TextStyle(
                            fontSize: 14, 
                            fontWeight: FontWeight.w900,
                            color: imgIdx != null ? Colors.white.withOpacity(0.3) : onSurface.withOpacity(0.05),
                          ),
                        ),
                      ),
                      if (widget.isResultsMode && imgIdx != null && imgIdx != pos)
                        Positioned(
                          bottom: 0, right: 0, left: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
                            ),
                            child: Text(
                              "#${imgIdx + 1}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFF00E676), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSourceDeck() {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    if (widget.isResultsMode) return const SizedBox.shrink();

    // Фильтруем только неиспользованные изображения
    final availableIndices = widget.shuffledIndices.where((idx) => !_usedImageIndices.contains(idx)).toList();

    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Text("IMAGES DECK", style: TextStyle(color: onSurface.withOpacity(0.2), fontSize: 10, letterSpacing: 3, fontWeight: FontWeight.w900)),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showAllImagesPicker(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: appAccentColor.value.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.filter_rounded, size: 12, color: appAccentColor.value),
                        const SizedBox(width: 4),
                        Text("ALL", style: TextStyle(color: appAccentColor.value, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text("${_usedImageIndices.length} / ${widget.imageUrls.length}", 
                  style: TextStyle(color: onSurface.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              itemCount: availableIndices.length,
              itemBuilder: (context, index) {
                final imgIdx = availableIndices[index];
                
                final imageWidget = Container(
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedFromSource == imgIdx ? appAccentColor.value : palette.border.withOpacity(0.1),
                      width: _selectedFromSource == imgIdx ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    widget.imageUrls[imgIdx],
                    fit: BoxFit.cover,
                    cacheWidth: 200,
                  ),
                );

                return Draggable<int>(
                  data: imgIdx,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Transform.scale(
                      scale: 1.1,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(widget.imageUrls[imgIdx], fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(opacity: 0.3, child: imageWidget),
                  onDragStarted: () => HapticFeedback.selectionClick(),
                  child: GestureDetector(
                    onTap: () => _onSourceTap(imgIdx),
                    child: imageWidget,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAllImagesPicker() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: appPalette.value.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: onSurface.withOpacity(0.1), borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("ВСЕ ИЗОБРАЖЕНИЯ", style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.w200, letterSpacing: 1)),
                  Text("${widget.imageUrls.length}", style: TextStyle(color: appAccentColor.value, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: widget.imageUrls.length,
                itemBuilder: (context, idx) {
                  // Исправлено: отображаем в правильном порядке 0, 1, 2...
                  final displayIdx = idx; 
                  final isUsed = _usedImageIndices.contains(displayIdx);
                  return GestureDetector(
                    onTap: () {
                      if (!isUsed) {
                        _onImagePlaced(_focusedPosition, displayIdx);
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isUsed ? Colors.transparent : onSurface.withOpacity(0.1)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Opacity(
                            opacity: isUsed ? 0.2 : 1.0,
                            child: Image.network(widget.imageUrls[displayIdx], fit: BoxFit.cover, cacheWidth: 300),
                          ),
                          if (isUsed) Center(child: Icon(Icons.check_circle_outline_rounded, color: onSurface.withOpacity(0.3))),
                          Positioned(
                            top: 8, left: 8,
                            child: Text("${displayIdx + 1}", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final palette = appPalette.value;
    final total = widget.imageUrls.length;
    final totalPages = (total / _pageSize).ceil();
    
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navButton(
            Icons.arrow_back_ios_new_rounded, 
            () => _onArrowNav(-1),
            onLongPress: () => _onArrowNav(-1, isLongPress: true),
          ),
          Row(
            children: List.generate(totalPages, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _currentPage == i ? 12 : 4,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: _currentPage == i ? appAccentColor.value : palette.border.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            )),
          ),
          _navButton(
            Icons.arrow_forward_ios_rounded, 
            () => _onArrowNav(1),
            onLongPress: () => _onArrowNav(1, isLongPress: true),
          ),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap, {VoidCallback? onLongPress}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final palette = appPalette.value;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: onSurface, size: 28),
      ),
    );
  }

  Widget _buildOverviewOverlay() {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Material(
      color: palette.background.withOpacity(0.95),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("КАРТА ПОЗИЦИЙ", style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  IconButton(icon: Icon(Icons.close, color: onSurface), onPressed: () => setState(() => _isOverviewOpen = false)),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 10,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemCount: widget.imageUrls.length,
                itemBuilder: (context, i) {
                  final imgIdx = _placements[i];
                  final isFilled = imgIdx != null;
                  
                  Color color = isFilled ? onSurface.withOpacity(0.1) : Colors.transparent;
                  Color textColor = isFilled ? onSurface.withOpacity(0.7) : onSurface.withOpacity(0.24);
                  Color borderColor = isFilled ? onSurface.withOpacity(0.24) : onSurface.withOpacity(0.05);

                  if (widget.isResultsMode && isFilled) {
                    final correct = (imgIdx == i);
                    color = correct ? const Color(0xFF00E676).withOpacity(0.2) : const Color(0xFFFF1744).withOpacity(0.2);
                    borderColor = correct ? const Color(0xFF00E676) : const Color(0xFFFF1744);
                    textColor = onSurface;
                  }

                  return GestureDetector(
                    onTap: () => _jumpToPosition(i),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text("${i + 1}", style: TextStyle(fontSize: 10, color: textColor, fontWeight: isFilled ? FontWeight.bold : FontWeight.normal)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _finishRecall() {
    // Конвертируем обратно в формат _imageAnswerOrder
    // Ожидается List<int?> где index=imageIdx, value=position+1
    final result = List<int?>.filled(widget.imageUrls.length, null);
    _placements.forEach((pos, imgIdx) {
      if (imgIdx != null) {
        result[imgIdx] = pos + 1;
      }
    });
    widget.onCompleted(result);
  }
}

class MnemonicCardRecallScreen extends StatefulWidget {
  final List<String> correctData;
  final bool isResultsMode;
  final bool alwaysWhiteBlackSuits;
  final int memorizationElapsedMs;
  final int recallElapsedMs;
  final int xpEarned;
  final Function(List<String?>) onCompleted;

  const MnemonicCardRecallScreen({
    super.key,
    required this.correctData,
    required this.isResultsMode,
    required this.alwaysWhiteBlackSuits,
    this.memorizationElapsedMs = 0,
    this.recallElapsedMs = 0,
    this.xpEarned = 0,
    required this.onCompleted,
  });

  @override
  State<MnemonicCardRecallScreen> createState() => _MnemonicCardRecallScreenState();
}

class _MnemonicCardRecallScreenState extends State<MnemonicCardRecallScreen> {
  static const Color _redSuitColor = Color(0xFFFF3B30);
  final List<String?> _selections = [];
  int _focusedIndex = 0;
  String _selectedSuit = 'h';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.correctData.length; i++) {
      _selections.add(null);
    }
  }

  void _onCardSelect(String rank) {
    if (widget.isResultsMode) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selections[_focusedIndex] = '$_selectedSuit$rank';
      if (_focusedIndex < _selections.length - 1) {
        _focusedIndex++;
        _scrollToFocused();
      }
    });
  }

  Color _blackSuitColor() {
    if (widget.alwaysWhiteBlackSuits) return Colors.white;
    return appAccentColor.value;
  }

  void _scrollToFocused() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          max(0, _focusedIndex * 90.0 - 100.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          const SizedBox(height: 20),
          if (widget.isResultsMode) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: _buildResultsDashboard(onSurface),
            ),
          ],
          // Скролл выбранных карт
          SizedBox(
            height: 180,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _selections.length,
              itemBuilder: (context, index) {
                final card = _selections[index];
                final isFocused = _focusedIndex == index && !widget.isResultsMode;
                final isCorrect = widget.isResultsMode && _selections[index] == widget.correctData[index];
                final isWrong = widget.isResultsMode && _selections[index] != widget.correctData[index];

                return GestureDetector(
                  onTap: () => setState(() => _focusedIndex = index),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Text("${index + 1}", style: TextStyle(color: onSurface.withOpacity(0.2), fontSize: 10)),
                        const SizedBox(height: 8),
                        _buildSmallCard(
                          card, 
                          isFocused: isFocused,
                          isCorrect: isCorrect,
                          isWrong: isWrong,
                          correctCard: widget.isResultsMode ? widget.correctData[index] : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const Spacer(),

          if (!widget.isResultsMode) ...[
            // Селектор масти
             Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: ['h', 'd', 'c', 's'].map((s) {
                 final isSel = _selectedSuit == s;
                 final isRed = s == 'h' || s == 'd';
                 final suitChar = s == 'h' ? '♥' : 
                             s == 'd' ? '♦' : 
                             s == 'c' ? '♣' : '♠';
                 return GestureDetector(
                   onTap: () => setState(() => _selectedSuit = s),
                   child: AnimatedContainer(
                     duration: const Duration(milliseconds: 200),
                     margin: const EdgeInsets.symmetric(horizontal: 10),
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: isSel ? appAccentColor.value.withOpacity(0.15) : palette.surface,
                       borderRadius: BorderRadius.circular(14),
                       border: Border.all(color: isSel ? appAccentColor.value : palette.border.withOpacity(0.3)),
                     ),
                     child: Text(
                       suitChar,
                       style: TextStyle(
                         color: isRed
                            ? (isSel ? _redSuitColor : _redSuitColor.withOpacity(0.7))
                            : (isSel ? _blackSuitColor() : _blackSuitColor().withOpacity(0.75)),
                         fontSize: 28,
                       ),
                     ),
                   ),
                 );
               }).toList(),
             ),
            const SizedBox(height: 30),
            // Селектор ранга
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: ['a', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'j', 'q', 'k'].map((r) {
                  return GestureDetector(
                    onTap: () => _onCardSelect(r),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: palette.border.withOpacity(0.3)),
                      ),
                      child: Center(
                        child: Text(r.toUpperCase(), style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.w300)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 40),
            _buildActionBtn("ГОТОВО", () => widget.onCompleted(_selections)),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildResultsDashboard(Color onSurface) {
    final int n = widget.correctData.length;
    int correct = 0;
    for (int i = 0; i < n; i++) {
      if (_selections[i] == widget.correctData[i]) correct++;
    }
    final double pct = n == 0 ? 0 : (correct / n) * 100.0;
    final double memSec = widget.memorizationElapsedMs / 1000.0;
    final double recallSec = widget.recallElapsedMs / 1000.0;
    final double secPerEl = n == 0 ? 0 : memSec / n;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appPalette.value.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appPalette.value.border.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          Text(
            '${pct.toStringAsFixed(0)}% · $correct/$n',
            style: TextStyle(color: appAccentColor.value, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _resultRow(onSurface, Icons.speed_rounded, 'Время на элемент', '${secPerEl.toStringAsFixed(2)} с'),
          const SizedBox(height: 5),
          _resultRow(onSurface, Icons.psychology_rounded, 'Запоминание', '${memSec.toStringAsFixed(1)} с'),
          const SizedBox(height: 5),
          _resultRow(onSurface, Icons.timer_outlined, 'Вспоминание', '${recallSec.toStringAsFixed(1)} с'),
          const SizedBox(height: 5),
          _resultRow(onSurface, Icons.bolt_rounded, 'XP', '+${widget.xpEarned}'),
        ],
      ),
    );
  }

  Widget _resultRow(Color onSurface, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: onSurface.withOpacity(0.6)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 12)),
        ),
        Text(
          value,
          style: TextStyle(color: onSurface, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildSmallCard(String? code, {bool isFocused = false, bool isCorrect = false, bool isWrong = false, String? correctCard}) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    
    Color borderColor = isFocused ? appAccentColor.value : palette.border.withOpacity(0.2);
    if (isCorrect) borderColor = const Color(0xFF00E676);
    if (isWrong) borderColor = const Color(0xFFFF1744);

    if (code == null) {
      return Container(
        width: 80,
        height: 120,
        decoration: BoxDecoration(
          color: palette.card.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isFocused ? 2 : 1),
        ),
        child: Center(child: Icon(Icons.add, color: onSurface.withOpacity(0.05))),
      );
    }

    final suit = code[0];
    final rank = code.substring(1).toUpperCase();
    final isRed = suit == 'h' || suit == 'd';
    final suitChar = suit == 'h' ? '♥' : 
                    suit == 'd' ? '♦' : 
                    suit == 'c' ? '♣' : '♠';
    final color = isRed ? _redSuitColor : _blackSuitColor();
    const rankColor = Colors.white;

    return Container(
      width: 80,
      height: 120,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: (isFocused || isWrong || isCorrect) ? 2 : 1),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rank, style: const TextStyle(color: rankColor, fontSize: 16, fontWeight: FontWeight.w900, height: 1)),
                Text(suitChar, style: TextStyle(color: color, fontSize: 12, height: 1)),
              ],
            ),
          ),
          if (true) // Фоновая масть теперь всегда по умолчанию
            Center(child: Text(suitChar, style: TextStyle(color: color.withOpacity(0.12), fontSize: 40))),
          if (isWrong && correctCard != null)
            Positioned(
              bottom: 4, left: 0, right: 0,
              child: Text(
                correctCard.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF00E676), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          decoration: BoxDecoration(
            color: appAccentColor.value,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: appAccentColor.value.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
            ],
          ),
          child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 14)),
        ),
      ),
    );
  }
}

class MnemonicMatrixMemorizer extends StatefulWidget {
  final List<String> data;
  final int currentChunkIndex;
  final int chunkSize;
  final String formattedTime;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onFirst;
  final VoidCallback onRecallNow;

  const MnemonicMatrixMemorizer({
    super.key,
    required this.data,
    required this.currentChunkIndex,
    required this.chunkSize,
    required this.formattedTime,
    required this.onNext,
    required this.onPrev,
    required this.onFirst,
    required this.onRecallNow,
  });

  @override
  State<MnemonicMatrixMemorizer> createState() => _MnemonicMatrixMemorizerState();
}

class _MnemonicMatrixMemorizerState extends State<MnemonicMatrixMemorizer> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MnemonicMatrixMemorizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentChunkIndex != oldWidget.currentChunkIndex) {
      _scrollToRow();
    }
  }

  void _scrollToRow() {
    int currentRow = (widget.currentChunkIndex * widget.chunkSize) ~/ 6;
    // Начинаем движение с 5-го рядка (индекс 4)
    if (currentRow >= 4) {
      double offset = (currentRow - 3) * 48.0; // 40 (высота) + 8 (spacing)
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final palette = appPalette.value;
    int start = widget.currentChunkIndex * widget.chunkSize;
    int end = min(start + widget.chunkSize, widget.data.length);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(widget.formattedTime, style: TextStyle(color: onSurface.withOpacity(0.1), fontSize: 16, fontWeight: FontWeight.w200, letterSpacing: 4)),
        const SizedBox(height: 40),
        // Текущий чанк
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: appAccentColor.value.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: appAccentColor.value.withOpacity(0.2)),
          ),
          child: Text(
            widget.data.sublist(start, end).join(" "),
            style: TextStyle(color: onSurface, fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: 4),
          ),
        ),
        const SizedBox(height: 30),
        // Сетка 6x7 с рамкой
        Container(
          width: 320,
          height: 360, // Примерно 7 рядков (40*7 + 8*6 + padding)
          padding: const EdgeInsets.only(left: 24, right: 16, top: 16, bottom: 16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: palette.border.withOpacity(0.3)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const NeverScrollableScrollPhysics(),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: widget.data.length,
                itemBuilder: (context, i) {
                  final isCurrent = i >= start && i < end;
                  final rowNum = i ~/ 6;
                  
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (i % 6 == 0 && rowNum > 0) 
                        Positioned(
                          left: -22, top: 0, bottom: 0,
                          child: Center(
                            child: Text("${rowNum * 6}", style: TextStyle(color: onSurface.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isCurrent ? appAccentColor.value.withOpacity(0.15) : palette.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isCurrent ? appAccentColor.value : Colors.transparent, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            widget.data[i],
                            style: TextStyle(
                              color: isCurrent ? onSurface : onSurface.withOpacity(0.15),
                              fontSize: 16,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _circleNavBtn(Icons.arrow_back_ios_new_rounded, widget.onPrev),
            const SizedBox(width: 20),
            _circleNavBtn(Icons.circle, widget.onFirst),
            const SizedBox(width: 20),
            _circleNavBtn(Icons.arrow_forward_ios_rounded, widget.onNext),
            const SizedBox(width: 20),
            _circleNavBtn(Icons.bolt_rounded, widget.onRecallNow, isPrimary: true),
          ],
        ),
      ],
    );
  }

  Widget _circleNavBtn(IconData icon, VoidCallback onTap, {bool isPrimary = false}) {
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isPrimary ? accent.withOpacity(0.1) : palette.surface,
          shape: BoxShape.circle,
          border: Border.all(color: isPrimary ? accent.withOpacity(0.5) : palette.border.withOpacity(0.3)),
        ),
        child: Icon(icon, color: isPrimary ? accent : Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: 20),
      ),
    );
  }
}

class MnemonicMatrixRecallScreen extends StatefulWidget {
  final List<String> correctData;
  final bool isResultsMode;
  final Function(List<String?>) onCompleted;

  const MnemonicMatrixRecallScreen({
    super.key,
    required this.correctData,
    required this.isResultsMode,
    required this.onCompleted,
  });

  @override
  State<MnemonicMatrixRecallScreen> createState() => _MnemonicMatrixRecallScreenState();
}

class _MnemonicMatrixRecallScreenState extends State<MnemonicMatrixRecallScreen> {
  late final List<String?> _selections;
  int _focusedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selections = List<String?>.filled(widget.correctData.length, null);
    // Запрашиваем фокус для работы клавиатуры
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.isResultsMode) {
        _keyboardFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _onDigitInput(String digit) {
    if (widget.isResultsMode) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selections[_focusedIndex] = digit;
      if (_focusedIndex < _selections.length - 1) {
        _focusedIndex++;
        _scrollToRow();
      }
    });
  }

  void _onBackspace() {
    if (widget.isResultsMode) return;
    if (_focusedIndex > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _selections[_focusedIndex] = null;
        _focusedIndex--;
        _scrollToRow();
      });
    }
  }

  void _scrollToRow() {
    int currentRow = _focusedIndex ~/ 6;
    if (currentRow >= 4) {
      double offset = (currentRow - 3) * 48.0;
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (event) {
         if (event is KeyDownEvent) {
           final char = event.logicalKey.keyLabel;
           // Поддержка обычных цифр и Numpad
           bool isDigit = RegExp(r'^[0-9]$').hasMatch(char) || 
                          (event.logicalKey.keyId >= LogicalKeyboardKey.numpad0.keyId && 
                           event.logicalKey.keyId <= LogicalKeyboardKey.numpad9.keyId);
           
           if (isDigit) {
             // Извлекаем цифру из keyLabel или из Numpad названия
             final digit = char.length == 1 ? char : char.replaceAll(RegExp(r'[^0-9]'), '');
             if (digit.isNotEmpty) _onDigitInput(digit);
           } else if (event.logicalKey == LogicalKeyboardKey.backspace || event.logicalKey == LogicalKeyboardKey.delete) {
             _onBackspace();
           } else if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
             widget.onCompleted(_selections);
           }
         }
       },
      child: Column(
        children: [
          if (widget.isResultsMode) _buildSummaryHeader(),
          const SizedBox(height: 30),
          // Сетка 6x7
          Container(
            width: 320,
            height: 360,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.only(left: 24, right: 16, top: 16, bottom: 16),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: palette.border.withOpacity(0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const NeverScrollableScrollPhysics(),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: widget.correctData.length,
                  itemBuilder: (context, index) {
                    final val = _selections[index];
                    final isFocused = _focusedIndex == index && !widget.isResultsMode;
                    final isCorrect = widget.isResultsMode && val == widget.correctData[index];
                    final isWrong = widget.isResultsMode && val != widget.correctData[index];
                    final rowNum = index ~/ 6;

                    Color borderColor = isFocused ? appAccentColor.value : palette.border.withOpacity(0.2);
                    if (isCorrect) borderColor = const Color(0xFF00E676);
                    if (isWrong) borderColor = const Color(0xFFFF1744);

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (index % 6 == 0 && rowNum > 0) 
                          Positioned(
                            left: -22, top: 0, bottom: 0,
                            child: Center(
                              child: Text("${rowNum * 6}", style: TextStyle(color: onSurface.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        GestureDetector(
                          onTap: () => setState(() {
                            _focusedIndex = index;
                            _scrollToRow();
                            _keyboardFocusNode.requestFocus();
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isFocused ? appAccentColor.value.withOpacity(0.1) : palette.card,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderColor, width: isFocused ? 2 : 1),
                            ),
                            child: Center(
                              child: Text(
                                val ?? "",
                                style: TextStyle(
                                  color: isWrong ? const Color(0xFFFF1744) : onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          if (!widget.isResultsMode) ...[
            const SizedBox(height: 20),
            // Клавиатура
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: List.generate(10, (i) => i.toString()).map((d) {
                  return GestureDetector(
                    onTap: () => _onDigitInput(d),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: palette.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.border.withOpacity(0.3)),
                      ),
                      child: Center(child: Text(d, style: TextStyle(color: onSurface, fontSize: 18))),
                    ),
                  );
                }).toList()..add(
                  GestureDetector(
                    onTap: _onBackspace,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: palette.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.border.withOpacity(0.3)),
                      ),
                      child: Icon(Icons.backspace_outlined, color: onSurface.withOpacity(0.5), size: 18),
                    ),
                  )
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildActionBtn("ПРОВЕРИТЬ", () => widget.onCompleted(_selections)),
          ],
          if (widget.isResultsMode) ...[
            const SizedBox(height: 20),
            _buildActionBtn("ВЫХОД", () => Navigator.pop(context)),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    int correct = 0;
    for (int i = 0; i < widget.correctData.length; i++) {
      if (_selections[i] == widget.correctData[i]) correct++;
    }
    final pct = (correct / widget.correctData.length) * 100;
    return Text(
      "Результат: ${pct.toStringAsFixed(0)}% ($correct/${widget.correctData.length})",
      style: TextStyle(color: appAccentColor.value, fontSize: 18, fontWeight: FontWeight.w200),
    );
  }

  Widget _buildActionBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        decoration: BoxDecoration(
          color: appAccentColor.value,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: appAccentColor.value.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
          ],
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 14)),
      ),
    );
  }
}
