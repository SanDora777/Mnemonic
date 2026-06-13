part of 'package:flutter_application_1/recovered_app.dart';

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
    'main_bottom_quote': {
      AppLanguage.ru: 'ТВОЙ МОЗГ СПОСОБЕН НА БОЛЬШЕЕ',
      AppLanguage.en: 'YOUR BRAIN IS CAPABLE OF MORE',
      AppLanguage.de: 'DEIN GEHIRN KANN MEHR',
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
      AppLanguage.ru: 'Облачный аккаунт',
      AppLanguage.en: 'Cloud account',
      AppLanguage.de: 'Cloud-Konto',
    },
    'cloud_not_connected': {
      AppLanguage.ru: 'Не подключен',
      AppLanguage.en: 'Not connected',
      AppLanguage.de: 'Nicht verbunden',
    },
    'offline_photo_faces_title': {
      AppLanguage.ru: 'Нужен интернет',
      AppLanguage.en: 'Internet required',
      AppLanguage.de: 'Internet erforderlich',
    },
    'offline_photo_faces_message': {
      AppLanguage.ru:
          'Режимы «Изображения» и «Лица» работают только онлайн — без сети картинки не загрузятся.',
      AppLanguage.en: 'Images and Faces modes need an internet connection to load pictures.',
      AppLanguage.de:
          'Die Modi „Bilder“ und „Gesichter“ funktionieren nur online — ohne Verbindung lassen sich die Bilder nicht laden.',
    },
    'offline_photo_faces_ok': {
      AppLanguage.ru: 'Понятно',
      AppLanguage.en: 'Got it',
      AppLanguage.de: 'Verstanden',
    },
    'cloud_connected_as': {
      AppLanguage.ru: 'Подключен как {email}',
      AppLanguage.en: 'Connected as {email}',
      AppLanguage.de: 'Verbunden als {email}',
    },
    'cloud_sign_in': {
      AppLanguage.ru: 'Войти по Email',
      AppLanguage.en: 'Sign in with Email',
      AppLanguage.de: 'Mit E-Mail anmelden',
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
    'account_about_label': {
      AppLanguage.ru: 'О себе',
      AppLanguage.en: 'About me',
      AppLanguage.de: 'Über mich',
    },
    'account_about_hint': {
      AppLanguage.ru: 'Коротко расскажи о себе',
      AppLanguage.en: 'Write a short bio',
      AppLanguage.de: 'Schreibe kurz über dich',
    },
    'account_save_about': {
      AppLanguage.ru: 'Сохранить описание',
      AppLanguage.en: 'Save bio',
      AppLanguage.de: 'Bio speichern',
    },
    'account_share_results': {
      AppLanguage.ru: 'Показывать мои результаты другим',
      AppLanguage.en: 'Show my results to others',
      AppLanguage.de: 'Meine Ergebnisse anderen zeigen',
    },
    'account_share_results_desc': {
      AppLanguage.ru: 'Если выключено, другие не увидят твою статистику.',
      AppLanguage.en: 'If disabled, other users will not see your stats.',
      AppLanguage.de: 'Wenn deaktiviert, sehen andere deine Statistiken nicht.',
    },
    'profile_results_hidden': {
      AppLanguage.ru: 'Пользователь скрыл результаты.',
      AppLanguage.en: 'This user has hidden results.',
      AppLanguage.de: 'Dieser Benutzer hat Ergebnisse ausgeblendet.',
    },
    'profile_best_1m': {
      AppLanguage.ru: 'Лучшее за 1 мин',
      AppLanguage.en: 'Best in 1 min',
      AppLanguage.de: 'Bestes in 1 Min',
    },
    'profile_best_5m': {
      AppLanguage.ru: 'Лучшее за 5 мин',
      AppLanguage.en: 'Best in 5 min',
      AppLanguage.de: 'Bestes in 5 Min',
    },
    'profile_max_mem': {
      AppLanguage.ru: 'Макс. запомнено',
      AppLanguage.en: 'Max memorized',
      AppLanguage.de: 'Max. gemerkt',
    },
    'profile_user_results': {
      AppLanguage.ru: 'Результаты пользователя',
      AppLanguage.en: 'User results',
      AppLanguage.de: 'Benutzerergebnisse',
    },
    'profile_about_me': {
      AppLanguage.ru: 'О себе',
      AppLanguage.en: 'About me',
      AppLanguage.de: 'Über mich',
    },
    'profile_tap_for_profile': {
      AppLanguage.ru: 'Нажмите, чтобы открыть профиль',
      AppLanguage.en: 'Tap to view profile',
      AppLanguage.de: 'Tippen für Profil',
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
      AppLanguage.ru: 'ИЗОБРАЖЕНИЯ',
      AppLanguage.en: 'IMAGES',
      AppLanguage.de: 'BILDER',
    },
    'cards': {
      AppLanguage.ru: 'КАРТЫ',
      AppLanguage.en: 'CARDS',
      AppLanguage.de: 'KARTEN',
    },
    'faces': {
      AppLanguage.ru: 'ЛИЦА',
      AppLanguage.en: 'FACES',
      AppLanguage.de: 'GESICHTER',
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
    'cloud_save_failed': {
      AppLanguage.ru: 'Не удалось сохранить результат в облаке.',
      AppLanguage.en: 'Failed to save result to cloud.',
      AppLanguage.de: 'Ergebnis konnte nicht in der Cloud gespeichert werden.',
    },
    'faces_names_file_empty': {
      AppLanguage.ru: 'Файл имен пуст или не найден в build/facenames. Заполни файл именами.',
      AppLanguage.en: 'Names file is empty or missing in build/facenames. Please fill it with names.',
      AppLanguage.de: 'Namensdatei ist leer oder fehlt in build/facenames. Bitte mit Namen füllen.',
    },
    'faces_names_not_enough': {
      AppLanguage.ru: 'Имен меньше, чем элементов. Количество уменьшено до {count}.',
      AppLanguage.en: 'Names are fewer than elements. Reduced to {count}.',
      AppLanguage.de: 'Weniger Namen als Elemente. Anzahl auf {count} reduziert.',
    },
    'exit': {
      AppLanguage.ru: 'ВЫХОД',
      AppLanguage.en: 'EXIT',
      AppLanguage.de: 'AUSGANG',
    },
    'enter_name_hint': {
      AppLanguage.ru: 'Введите имя',
      AppLanguage.en: 'Type the name',
      AppLanguage.de: 'Namen eingeben',
    },
    'correct_answer_prefix': {
      AppLanguage.ru: 'Верно',
      AppLanguage.en: 'Correct',
      AppLanguage.de: 'Richtig',
    },
    'memorization_label': {
      AppLanguage.ru: 'Запоминание',
      AppLanguage.en: 'Memorization',
      AppLanguage.de: 'Merken',
    },
    'recall_label': {
      AppLanguage.ru: 'Вспоминание',
      AppLanguage.en: 'Recall',
      AppLanguage.de: 'Abrufen',
    },
    'speed_label': {
      AppLanguage.ru: 'Скорость',
      AppLanguage.en: 'Speed',
      AppLanguage.de: 'Geschwindigkeit',
    },
    'element_stats_title': {
      AppLanguage.ru: 'Статистика элементов',
      AppLanguage.en: 'Element Statistics',
      AppLanguage.de: 'Elementstatistik',
    },
    'element_stats_subtitle': {
      AppLanguage.ru: 'Сколько времени ушло на запоминание каждого элемента',
      AppLanguage.en: 'How much time each element took to memorize',
      AppLanguage.de: 'Wie viel Zeit jedes Element zum Merken brauchte',
    },
    'element_stats_open': {
      AppLanguage.ru: 'Статистика элементов',
      AppLanguage.en: 'Element stats',
      AppLanguage.de: 'Elementstatistik',
    },
    'training_history_replay': {
      AppLanguage.ru: 'История попытки',
      AppLanguage.en: 'Session history',
      AppLanguage.de: 'Trainingsverlauf',
    },
    'element_stats_avg': {
      AppLanguage.ru: 'Среднее',
      AppLanguage.en: 'Average',
      AppLanguage.de: 'Durchschnitt',
    },
    'element_stats_total': {
      AppLanguage.ru: 'Всего',
      AppLanguage.en: 'Total',
      AppLanguage.de: 'Gesamt',
    },
    'element_stats_time': {
      AppLanguage.ru: 'Время',
      AppLanguage.en: 'Time',
      AppLanguage.de: 'Zeit',
    },
    'element_stats_value': {
      AppLanguage.ru: 'Значение',
      AppLanguage.en: 'Value',
      AppLanguage.de: 'Wert',
    },
    'element_stats_your_answer': {
      AppLanguage.ru: 'Ответ',
      AppLanguage.en: 'Answer',
      AppLanguage.de: 'Antwort',
    },
    'element_stats_correct_answer': {
      AppLanguage.ru: 'Правильно',
      AppLanguage.en: 'Correct',
      AppLanguage.de: 'Richtig',
    },
    'element_stats_image_value': {
      AppLanguage.ru: 'Изображение #{n}',
      AppLanguage.en: 'Image #{n}',
      AppLanguage.de: 'Bild #{n}',
    },
    'element_stats_slot_value': {
      AppLanguage.ru: 'Слот {n}',
      AppLanguage.en: 'Slot {n}',
      AppLanguage.de: 'Slot {n}',
    },
    'image_recall_table_page': {
      AppLanguage.ru: 'ТАБЛИЦА · {current} / {total}',
      AppLanguage.en: 'TABLE · {current} / {total}',
      AppLanguage.de: 'TABELLE · {current} / {total}',
    },
    'image_recall_all_images': {
      AppLanguage.ru: 'Все изображения',
      AppLanguage.en: 'All images',
      AppLanguage.de: 'Alle Bilder',
    },
    'image_recall_positions_map': {
      AppLanguage.ru: 'Карта позиций',
      AppLanguage.en: 'Position map',
      AppLanguage.de: 'Positionskarte',
    },
    'image_recall_deck_label': {
      AppLanguage.ru: 'КОЛОДА',
      AppLanguage.en: 'DECK',
      AppLanguage.de: 'DECK',
    },
    'image_recall_all_short': {
      AppLanguage.ru: 'ВСЕ',
      AppLanguage.en: 'ALL',
      AppLanguage.de: 'ALLE',
    },
    'seconds_short': {
      AppLanguage.ru: 'с',
      AppLanguage.en: 's',
      AppLanguage.de: 's',
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
    'standard_digits_result': {
      AppLanguage.ru: 'Цифр верно: {correct} из {total}',
      AppLanguage.en: 'Digits correct: {correct} / {total}',
      AppLanguage.de: 'Ziffern richtig: {correct} / {total}',
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
      AppLanguage.ru: 'изображения',
      AppLanguage.en: 'images',
      AppLanguage.de: 'Bilder',
    },
    'mode_cards': {
      AppLanguage.ru: 'карты',
      AppLanguage.en: 'cards',
      AppLanguage.de: 'Karten',
    },
    'mode_faces': {
      AppLanguage.ru: 'лица',
      AppLanguage.en: 'faces',
      AppLanguage.de: 'Gesichter',
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
    'mode_cards_random_sub': {
      AppLanguage.ru: 'Случайно',
      AppLanguage.en: 'Random',
      AppLanguage.de: 'Zufall',
    },
    'mode_cards_deck_sub': {
      AppLanguage.ru: 'Колода',
      AppLanguage.en: 'Deck',
      AppLanguage.de: 'Deck',
    },
    'settings_cards_deck_desc': {
      AppLanguage.ru:
          'Колода: 52 карты перемешиваются один раз — каждая встречается не больше одного раза, как при запоминании настоящей колоды.',
      AppLanguage.en:
          'Deck: all 52 cards are shuffled once — each appears at most once, like memorizing a real shuffled deck.',
      AppLanguage.de:
          'Deck: alle 52 Karten werden einmal gemischt — jede höchstens einmal, wie bei einer echten Karte.',
    },
    'cards_deck_max_count': {
      AppLanguage.ru: 'В режиме «Колода» максимум 52 карты',
      AppLanguage.en: 'Deck mode allows at most 52 cards',
      AppLanguage.de: 'Deck-Modus: maximal 52 Karten',
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
    'personal_quests_title': {
      AppLanguage.ru: 'СВОИ ЦЕЛИ',
      AppLanguage.en: 'MY GOALS',
      AppLanguage.de: 'EIGENE ZIELE',
    },
    'personal_quests_subtitle': {
      AppLanguage.ru: 'Заготовки и параметры — прогресс считается автоматически',
      AppLanguage.en: 'Pick a template and numbers — progress updates when you train',
      AppLanguage.de: 'Vorlage und Zahlen waehlen — Fortschritt beim Training',
    },
    'personal_goal_add': {
      AppLanguage.ru: 'Новая цель',
      AppLanguage.en: 'New goal',
      AppLanguage.de: 'Neues Ziel',
    },
    'personal_goal_sheet_title': {
      AppLanguage.ru: 'Своя цель',
      AppLanguage.en: 'Custom goal',
      AppLanguage.de: 'Eigenes Ziel',
    },
    'personal_goal_template_volume': {
      AppLanguage.ru: 'Объём',
      AppLanguage.en: 'Volume',
      AppLanguage.de: 'Volumen',
    },
    'personal_goal_template_volume_desc': {
      AppLanguage.ru: 'Считаются любые режимы',
      AppLanguage.en: 'Any training mode',
      AppLanguage.de: 'Beliebiger Modus',
    },
    'personal_goal_template_perfect': {
      AppLanguage.ru: 'Идеально',
      AppLanguage.en: 'Perfect',
      AppLanguage.de: 'Perfekt',
    },
    'personal_goal_template_perfect_desc': {
      AppLanguage.ru: '100% без ошибок',
      AppLanguage.en: '100% accuracy each',
      AppLanguage.de: '100% pro Sitzung',
    },
    'personal_goal_template_mode': {
      AppLanguage.ru: 'В режиме',
      AppLanguage.en: 'In one mode',
      AppLanguage.de: 'Ein Modus',
    },
    'personal_goal_template_mode_desc': {
      AppLanguage.ru: 'Только выбранный режим',
      AppLanguage.en: 'Only the mode you pick',
      AppLanguage.de: 'Nur gewaehlter Modus',
    },
    'personal_goal_sessions_label': {
      AppLanguage.ru: 'Тренировок',
      AppLanguage.en: 'Sessions',
      AppLanguage.de: 'Sitzungen',
    },
    'personal_goal_min_items_label': {
      AppLanguage.ru: 'Мин. элементов за тренировку',
      AppLanguage.en: 'Min items per session',
      AppLanguage.de: 'Mind. Elemente / Training',
    },
    'personal_goal_mode_label': {
      AppLanguage.ru: 'Режим',
      AppLanguage.en: 'Mode',
      AppLanguage.de: 'Modus',
    },
    'personal_goal_mode_any': {
      AppLanguage.ru: 'Любой',
      AppLanguage.en: 'Any',
      AppLanguage.de: 'Beliebig',
    },
    'personal_goal_create': {
      AppLanguage.ru: 'Создать цель',
      AppLanguage.en: 'Create goal',
      AppLanguage.de: 'Ziel anlegen',
    },
    'personal_goal_pick_mode': {
      AppLanguage.ru: 'Выбери режим для этой заготовки',
      AppLanguage.en: 'Pick a mode for this template',
      AppLanguage.de: 'Modus fuer diese Vorlage waehlen',
    },
    'personal_goal_max': {
      AppLanguage.ru: 'Не больше 5 своих целей — удали одну, чтобы добавить новую',
      AppLanguage.en: 'At most 5 custom goals — remove one to add another',
      AppLanguage.de: 'Maximal 5 eigene Ziele — eines loeschen',
    },
    'personal_goal_delete_title': {
      AppLanguage.ru: 'Удалить цель?',
      AppLanguage.en: 'Remove this goal?',
      AppLanguage.de: 'Ziel loeschen?',
    },
    'personal_goal_delete_body': {
      AppLanguage.ru: 'Прогресс по этой цели будет удалён. Это нельзя отменить.',
      AppLanguage.en: 'Progress for this goal will be removed. This cannot be undone.',
      AppLanguage.de: 'Der Fortschritt fuer dieses Ziel wird geloescht. Das laesst sich nicht rueckgaengig machen.',
    },
    'personal_goal_delete_confirm': {
      AppLanguage.ru: 'Удалить',
      AppLanguage.en: 'Remove',
      AppLanguage.de: 'Loeschen',
    },
    'personal_goal_delete_cancel': {
      AppLanguage.ru: 'Отмена',
      AppLanguage.en: 'Cancel',
      AppLanguage.de: 'Abbrechen',
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
    'number_pair_trainer': {
      AppLanguage.ru: 'Тренажёр',
      AppLanguage.en: 'Trainer',
      AppLanguage.de: 'Trainer',
    },
    'number_pair_trainer_start': {
      AppLanguage.ru: 'Начать',
      AppLanguage.en: 'Start',
      AppLanguage.de: 'Start',
    },
    'number_pair_tap_reveal': {
      AppLanguage.ru: 'Нажми, чтобы увидеть образ',
      AppLanguage.en: 'Tap to reveal the image',
      AppLanguage.de: 'Tippen, um das Bild zu sehen',
    },
    'number_pair_tap_reveal_image': {
      AppLanguage.ru: 'Нажми, чтобы увидеть образ',
      AppLanguage.en: 'Tap to reveal the image',
      AppLanguage.de: 'Tippen, um das Bild zu sehen',
    },
    'number_pair_tap_reveal_code': {
      AppLanguage.ru: 'Нажми, чтобы увидеть число',
      AppLanguage.en: 'Tap to reveal the number',
      AppLanguage.de: 'Tippen, um die Zahl zu sehen',
    },
    'number_pair_revealed_code': {
      AppLanguage.ru: 'Это число',
      AppLanguage.en: 'The number',
      AppLanguage.de: 'Die Zahl',
    },
    'number_pair_direction_label': {
      AppLanguage.ru: 'Направление',
      AppLanguage.en: 'Direction',
      AppLanguage.de: 'Richtung',
    },
    'number_pair_direction_forward': {
      AppLanguage.ru: 'Число → образ',
      AppLanguage.en: 'Number → image',
      AppLanguage.de: 'Zahl → Bild',
    },
    'number_pair_direction_reverse': {
      AppLanguage.ru: 'Образ → число',
      AppLanguage.en: 'Image → number',
      AppLanguage.de: 'Bild → Zahl',
    },
    'number_pair_direction_forward_hint': {
      AppLanguage.ru: 'Вспомни образ сам. Если забыл — нажми ?',
      AppLanguage.en: 'Recall the image yourself. Tap ? if you forgot',
      AppLanguage.de: 'Erinnere dich selbst. Bei Vergessen ? tippen',
    },
    'number_pair_direction_reverse_hint': {
      AppLanguage.ru: 'Вспомни число сам. Если забыл — нажми ?',
      AppLanguage.en: 'Recall the number yourself. Tap ? if you forgot',
      AppLanguage.de: 'Erinnere dich selbst an die Zahl. Bei Vergessen ? tippen',
    },
    'number_pair_hint_image_tooltip': {
      AppLanguage.ru: 'Показать образ',
      AppLanguage.en: 'Show image',
      AppLanguage.de: 'Bild anzeigen',
    },
    'number_pair_hint_code_tooltip': {
      AppLanguage.ru: 'Показать число',
      AppLanguage.en: 'Show number',
      AppLanguage.de: 'Zahl anzeigen',
    },
    'number_pair_direction_forward_short': {
      AppLanguage.ru: 'ЧИСЛО → ОБРАЗ',
      AppLanguage.en: 'NUMBER → IMAGE',
      AppLanguage.de: 'ZAHL → BILD',
    },
    'number_pair_direction_reverse_short': {
      AppLanguage.ru: 'ОБРАЗ → ЧИСЛО',
      AppLanguage.en: 'IMAGE → NUMBER',
      AppLanguage.de: 'BILD → ZAHL',
    },
    'mode_number_pairs_rev': {
      AppLanguage.ru: 'Коды 00–99 (образ→число)',
      AppLanguage.en: 'Codes 00–99 (image→number)',
      AppLanguage.de: 'Codes 00–99 (Bild→Zahl)',
    },
    'number_pair_txt_import_btn': {
      AppLanguage.ru: 'Импорт из TXT',
      AppLanguage.en: 'Import from TXT',
      AppLanguage.de: 'Aus TXT importieren',
    },
    'number_pair_txt_export_btn': {
      AppLanguage.ru: 'Шаблон в буфер',
      AppLanguage.en: 'Template to clipboard',
      AppLanguage.de: 'Vorlage in Zwischenablage',
    },
    'number_pair_txt_help_title': {
      AppLanguage.ru: 'Формат TXT-файла',
      AppLanguage.en: 'TXT file format',
      AppLanguage.de: 'TXT-Dateiformat',
    },
    'number_pair_txt_read_error': {
      AppLanguage.ru: 'Не удалось прочитать файл',
      AppLanguage.en: 'Could not read the file',
      AppLanguage.de: 'Datei konnte nicht gelesen werden',
    },
    'number_pair_txt_empty': {
      AppLanguage.ru: 'В файле нет распознанных кодов. Проверьте формат.',
      AppLanguage.en: 'No codes recognized in the file. Check the format.',
      AppLanguage.de: 'Keine Codes erkannt. Format prüfen.',
    },
    'number_pair_txt_import_ok': {
      AppLanguage.ru: 'Импортировано записей: {n}',
      AppLanguage.en: 'Imported entries: {n}',
      AppLanguage.de: 'Importiert: {n} Einträge',
    },
    'number_pair_txt_import_fail': {
      AppLanguage.ru: 'Ошибка импорта',
      AppLanguage.en: 'Import failed',
      AppLanguage.de: 'Importfehler',
    },
    'number_pair_txt_import_title': {
      AppLanguage.ru: 'Импорт кодов',
      AppLanguage.en: 'Import codes',
      AppLanguage.de: 'Codes importieren',
    },
    'number_pair_txt_import_confirm': {
      AppLanguage.ru: 'Импортировать',
      AppLanguage.en: 'Import',
      AppLanguage.de: 'Importieren',
    },
    'number_pair_txt_merge': {
      AppLanguage.ru: 'Добавить к существующим (обновить совпадающие)',
      AppLanguage.en: 'Merge with existing (update matches)',
      AppLanguage.de: 'Mit vorhandenen verbinden (Treffer aktualisieren)',
    },
    'number_pair_txt_replace': {
      AppLanguage.ru: 'Заменить все коды этого языка',
      AppLanguage.en: 'Replace all codes for this language',
      AppLanguage.de: 'Alle Codes dieser Sprache ersetzen',
    },
    'number_pair_txt_warnings': {
      AppLanguage.ru: 'Предупреждений: {n} (дубликаты или формат)',
      AppLanguage.en: 'Warnings: {n} (duplicates or format)',
      AppLanguage.de: 'Warnungen: {n} (Duplikate oder Format)',
    },
    'number_pair_txt_export_copied': {
      AppLanguage.ru: 'Шаблон скопирован в буфер обмена — вставьте в .txt и отредактируйте',
      AppLanguage.en: 'Template copied to clipboard — paste into a .txt file and edit',
      AppLanguage.de: 'Vorlage in Zwischenablage — in .txt einfügen und bearbeiten',
    },
    'number_pair_txt_help_body': {
      AppLanguage.ru:
          'Одна строка — один код от 00 до 99.\n\nРазделители между числом и образом:\n• знак равенства: 47=Медведь\n• двоеточие: 47: Медведь\n• вертикальная черта: 47|Медведь\n• табуляция: 47<TAB>Медведь\n• тире с пробелами: 47 - Медведь\n\nСтроки с # — комментарии.\n\nВ начале файла:\n# range: 00-99\n# lang: ru\n\nТри языка в одном файле: секции [ru], [en], [de]. Для 000–999 откройте раздел 000–999 в приложении и укажите # range: 000-999.',
      AppLanguage.en:
          'One line — one code from 00 to 99.\n\nSeparators: =  :  |  tab  or  47 - Bear\n\nComments start with #.\n\nFile header:\n# range: 00-99\n# lang: en\n\nMulti-language: sections [ru], [en], [de]. For 000–999 open that section in the app and use # range: 000-999.',
      AppLanguage.de:
          'Eine Zeile — ein Code von 00 bis 99.\n\nTrennzeichen: =  :  |  Tab  oder  47 - Bär\n\n# = Kommentar.\n\nKopfzeile:\n# range: 00-99\n# lang: de\n\nMehrsprachig: [ru], [en], [de]. Für 000–999: Bereich in der App öffnen und # range: 000-999.',
    },
    'number_pair_txt_help_example_title': {
      AppLanguage.ru: 'Пример файла',
      AppLanguage.en: 'Example file',
      AppLanguage.de: 'Beispieldatei',
    },
    'number_pair_txt_help_example': {
      AppLanguage.ru:
          '# lang: ru\n00=Мяч\n01=Свеча\n02=Лебедь\n\n# lang: en\n00=Ball\n01=Candle\n\n[de]\n00=Ball\n01=Kerze',
      AppLanguage.en:
          '# lang: en\n00=Ball\n01=Candle\n02=Swan\n\n[ru]\n00=Мяч\n01=Свеча',
      AppLanguage.de:
          '# lang: de\n00=Ball\n01=Kerze\n02=Schwan\n\n[en]\n00=Ball\n01=Candle',
    },
    'number_pair_txt_help_current_lang': {
      AppLanguage.ru:
          'Сейчас в приложении: {lang}. Файл без секций и без # lang: … импортируется в этот язык.',
      AppLanguage.en:
          'App language now: {lang}. Files without sections or # lang: … import into this language.',
      AppLanguage.de:
          'App-Sprache: {lang}. Dateien ohne Abschnitt und ohne # lang: … werden dort importiert.',
    },
    'number_pair_edit_hint': {
      AppLanguage.ru: 'Твой образ для этого числа',
      AppLanguage.en: 'Your image for this number',
      AppLanguage.de: 'Dein Bild für diese Zahl',
    },
    'number_pair_filled_count': {
      AppLanguage.ru: 'Заполнено {n} из {total}',
      AppLanguage.en: '{n} of {total} filled',
      AppLanguage.de: '{n} von {total} ausgefüllt',
    },
    'number_codes_filled_count': {
      AppLanguage.ru: 'Заполнено {n} из {total} ({range})',
      AppLanguage.en: '{n} of {total} filled ({range})',
      AppLanguage.de: '{n} von {total} ({range})',
    },
    'number_codes_search_hint': {
      AppLanguage.ru: 'Поиск по коду или образу',
      AppLanguage.en: 'Search code or image',
      AppLanguage.de: 'Code oder Bild suchen',
    },
    'mode_number_triples': {
      AppLanguage.ru: 'Коды 000–999',
      AppLanguage.en: 'Codes 000–999',
      AppLanguage.de: 'Codes 000–999',
    },
    'mode_number_triples_rev': {
      AppLanguage.ru: 'Коды 000–999 (образ→число)',
      AppLanguage.en: 'Codes 000–999 (image→number)',
      AppLanguage.de: 'Codes 000–999 (Bild→Zahl)',
    },
    'number_codes_txt_help_body_triple': {
      AppLanguage.ru:
          'Те же правила, что для 00–99, но коды от 000 до 999 (ровно 3 цифры).\n\nВ начале файла укажите:\n# range: 000-999\n# lang: ru\n\nПример: 047=Медведь\n\nВ редакторе: поиск и блоки 000, 100, … 900.',
      AppLanguage.en:
          'Same rules as 00–99, but codes 000–999 (always 3 digits).\n\nStart the file with:\n# range: 000-999\n# lang: en\n\nExample: 047=Bear\n\nEditor: search and blocks 000, 100, … 900.',
      AppLanguage.de:
          'Gleiche Regeln wie 00–99, aber Codes 000–999 (immer 3 Ziffern).\n\nDateianfang:\n# range: 000-999\n# lang: de\n\nBeispiel: 047=Bär\n\nEditor: Suche und Blöcke 000, 100, … 900.',
    },
    'number_codes_txt_help_example_triple': {
      AppLanguage.ru: '# range: 000-999\n# lang: ru\n000=Мяч\n047=Медведь\n099=Воздушный шар',
      AppLanguage.en: '# range: 000-999\n# lang: en\n000=Ball\n047=Bear\n099=Balloon',
      AppLanguage.de: '# range: 000-999\n# lang: de\n000=Ball\n047=Bär\n099=Ballon',
    },
    'number_pair_need_images': {
      AppLanguage.ru: 'Заполни минимум 5 образов, чтобы начать тренажёр',
      AppLanguage.en: 'Fill at least 5 images to start the trainer',
      AppLanguage.de: 'Mindestens 5 Bilder ausfüllen, um den Trainer zu starten',
    },
    'number_pair_count_label': {
      AppLanguage.ru: 'Сколько кодов за сессию',
      AppLanguage.en: 'Codes per session',
      AppLanguage.de: 'Codes pro Sitzung',
    },
    'number_pair_available': {
      AppLanguage.ru: 'Доступно кодов с образами: {n}',
      AppLanguage.en: 'Codes with images available: {n}',
      AppLanguage.de: 'Codes mit Bildern verfügbar: {n}',
    },
    'number_pair_weak_session': {
      AppLanguage.ru: 'Самый слабый в этой сессии',
      AppLanguage.en: 'Weakest in this session',
      AppLanguage.de: 'Schwächster in dieser Sitzung',
    },
    'number_pair_best_session': {
      AppLanguage.ru: 'Самый быстрый в этой сессии',
      AppLanguage.en: 'Fastest in this session',
      AppLanguage.de: 'Schnellster in dieser Sitzung',
    },
    'number_pair_weak_overall': {
      AppLanguage.ru: 'Слабые коды (в среднем)',
      AppLanguage.en: 'Weak codes (on average)',
      AppLanguage.de: 'Schwache Codes (Durchschnitt)',
    },
    'number_pair_best_overall': {
      AppLanguage.ru: 'Сильные коды (в среднем)',
      AppLanguage.en: 'Strong codes (on average)',
      AppLanguage.de: 'Starke Codes (Durchschnitt)',
    },
    'number_pair_new_record': {
      AppLanguage.ru: 'Новый рекорд: {score} кодов (было {prev})',
      AppLanguage.en: 'New record: {score} codes (was {prev})',
      AppLanguage.de: 'Neuer Rekord: {score} Codes (vorher {prev})',
    },
    'mode_number_pairs': {
      AppLanguage.ru: 'Коды 00–99',
      AppLanguage.en: 'Codes 00–99',
      AppLanguage.de: 'Codes 00–99',
    },
    'card_codes_title': {
      AppLanguage.ru: 'Образы для карт',
      AppLanguage.en: 'Card Images',
      AppLanguage.de: 'Kartenbilder',
    },
    'card_codes_settings_title': {
      AppLanguage.ru: 'Образы для карт',
      AppLanguage.en: 'Card Images',
      AppLanguage.de: 'Kartenbilder',
    },
    'card_codes_settings_subtitle': {
      AppLanguage.ru: 'Свои образы на каждую карту и тренажёр',
      AppLanguage.en: 'Your image for each card and a trainer',
      AppLanguage.de: 'Eigenes Bild pro Karte und Trainer',
    },
    'card_codes_trainer': {
      AppLanguage.ru: 'Тренажёр',
      AppLanguage.en: 'Trainer',
      AppLanguage.de: 'Trainer',
    },
    'card_codes_trainer_start': {
      AppLanguage.ru: 'Начать',
      AppLanguage.en: 'Start',
      AppLanguage.de: 'Start',
    },
    'card_codes_edit_hint': {
      AppLanguage.ru: 'Твой образ для этой карты',
      AppLanguage.en: 'Your image for this card',
      AppLanguage.de: 'Dein Bild für diese Karte',
    },
    'card_codes_filled_count': {
      AppLanguage.ru: 'Заполнено {n} из {total}',
      AppLanguage.en: '{n} of {total} filled',
      AppLanguage.de: '{n} von {total} ausgefüllt',
    },
    'card_codes_search_hint': {
      AppLanguage.ru: 'Поиск по карте или образу',
      AppLanguage.en: 'Search card or image',
      AppLanguage.de: 'Karte oder Bild suchen',
    },
    'card_codes_need_images': {
      AppLanguage.ru: 'Заполни минимум 5 образов, чтобы начать тренажёр',
      AppLanguage.en: 'Fill at least 5 images to start the trainer',
      AppLanguage.de: 'Mindestens 5 Bilder ausfüllen, um den Trainer zu starten',
    },
    'card_codes_count_label': {
      AppLanguage.ru: 'Сколько карт за сессию',
      AppLanguage.en: 'Cards per session',
      AppLanguage.de: 'Karten pro Sitzung',
    },
    'card_codes_available': {
      AppLanguage.ru: 'Доступно карт с образами: {n}',
      AppLanguage.en: 'Cards with images available: {n}',
      AppLanguage.de: 'Karten mit Bildern verfügbar: {n}',
    },
    'card_codes_direction_label': {
      AppLanguage.ru: 'Направление',
      AppLanguage.en: 'Direction',
      AppLanguage.de: 'Richtung',
    },
    'card_codes_direction_forward': {
      AppLanguage.ru: 'Карта → образ',
      AppLanguage.en: 'Card → image',
      AppLanguage.de: 'Karte → Bild',
    },
    'card_codes_direction_reverse': {
      AppLanguage.ru: 'Образ → карта',
      AppLanguage.en: 'Image → card',
      AppLanguage.de: 'Bild → Karte',
    },
    'card_codes_direction_forward_hint': {
      AppLanguage.ru: 'Вспомни образ сам. Если забыл — нажми ?',
      AppLanguage.en: 'Recall the image yourself. Tap ? if you forgot',
      AppLanguage.de: 'Erinnere dich selbst. Bei Vergessen ? tippen',
    },
    'card_codes_direction_reverse_hint': {
      AppLanguage.ru: 'Вспомни карту сам. Если забыл — нажми ?',
      AppLanguage.en: 'Recall the card yourself. Tap ? if you forgot',
      AppLanguage.de: 'Erinnere dich selbst an die Karte. Bei Vergessen ? tippen',
    },
    'card_codes_direction_forward_short': {
      AppLanguage.ru: 'КАРТА → ОБРАЗ',
      AppLanguage.en: 'CARD → IMAGE',
      AppLanguage.de: 'KARTE → BILD',
    },
    'card_codes_direction_reverse_short': {
      AppLanguage.ru: 'ОБРАЗ → КАРТА',
      AppLanguage.en: 'IMAGE → CARD',
      AppLanguage.de: 'BILD → KARTE',
    },
    'card_codes_hint_image_tooltip': {
      AppLanguage.ru: 'Показать образ',
      AppLanguage.en: 'Show image',
      AppLanguage.de: 'Bild anzeigen',
    },
    'card_codes_hint_card_tooltip': {
      AppLanguage.ru: 'Показать карту',
      AppLanguage.en: 'Show card',
      AppLanguage.de: 'Karte anzeigen',
    },
    'card_codes_weak_session': {
      AppLanguage.ru: 'Самая слабая в этой сессии',
      AppLanguage.en: 'Weakest in this session',
      AppLanguage.de: 'Schwächste in dieser Sitzung',
    },
    'card_codes_best_session': {
      AppLanguage.ru: 'Самая быстрая в этой сессии',
      AppLanguage.en: 'Fastest in this session',
      AppLanguage.de: 'Schnellste in dieser Sitzung',
    },
    'card_codes_new_record': {
      AppLanguage.ru: 'Новый рекорд: {score} карт (было {prev})',
      AppLanguage.en: 'New record: {score} cards (was {prev})',
      AppLanguage.de: 'Neuer Rekord: {score} Karten (vorher {prev})',
    },
    'mode_card_codes': {
      AppLanguage.ru: 'Образы карт',
      AppLanguage.en: 'Card Images',
      AppLanguage.de: 'Kartenbilder',
    },
    'mode_card_codes_rev': {
      AppLanguage.ru: 'Образы карт (образ→карта)',
      AppLanguage.en: 'Card Images (image→card)',
      AppLanguage.de: 'Kartenbilder (Bild→Karte)',
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
