import 'package:flutter/material.dart';

import '../recovered_app.dart' show AppLanguage;
import 'lesson_framework.dart';

// Контент уроков ветви «Запоминание текстов» — текст из lesson_1…lesson_5 без правок.

// ---------------------------------------------------------------------------
// Урок 1
// ---------------------------------------------------------------------------
const List<LessonSlide> _kTextsLesson1Slides = <LessonSlide>[
  LessonSlide(
    icon: Icons.route_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Урок 1: Подготовка. Линейный дворец',
      AppLanguage.en: 'Lesson 1: Preparation. Linear Palace',
      AppLanguage.de: 'Lektion 1: Vorbereitung. Linearer Palast',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Для запоминания текстов лучше всего подходят линейные маршруты. В отличие от обычных комнат, они обеспечивают строгую последовательность.',
      AppLanguage.en:
          'Linear routes are best for memorizing texts. Unlike regular rooms, they ensure a strict sequence.',
      AppLanguage.de:
          'Lineare Routen eignen sich am besten zum Einprägen von Texten. Im Gegensatz zu normalen Räumen gewährleisten sie eine strikte Abfolge.',
    },
  ),
  LessonSlide(
    icon: Icons.playlist_add_check_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Инструкция:\n1. Выбери маршрут: Используй знакомую улицу, путь до работы или длинный коридор.\n2. Правило локации: 1 локация = 1 законченная мысль или 1 предложение. Не перегружай одну точку.\n3. Навигация: Двигайся строго последовательно. Это исключит путаницу в порядке предложений.',
      AppLanguage.en:
          'Instructions:\n1. Choose a route: Use a familiar street, your commute, or a long corridor.\n2. Location Rule: 1 location = 1 complete thought or 1 sentence. Do not overload a single point.\n3. Navigation: Move strictly in sequence. This prevents confusion in the order of sentences.',
      AppLanguage.de:
          'Anleitung:\n1. Wähle eine Route: Nutze eine bekannte Straße, deinen Arbeitsweg oder einen langen Flur.\n2. Ortsregel: 1 Ort = 1 abgeschlossener Gedanke oder 1 Satz. Überlade einen einzelnen Punkt nicht.\n3. Navigation: Bewege dich streng der Reihe nach. Das verhindert Verwirrung bei der Satzreihenfolge.',
    },
    isCompletion: true,
  ),
];

// ---------------------------------------------------------------------------
// Урок 2
// ---------------------------------------------------------------------------
const List<LessonSlide> _kTextsLesson2Slides = <LessonSlide>[
  LessonSlide(
    icon: Icons.text_fields_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Урок 2: Техника первых букв',
      AppLanguage.en: 'Lesson 2: First Letter Technique',
      AppLanguage.de: 'Lektion 2: Anfangsbuchstaben-Technik',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Этот метод помогает добиться дословной точности, заставляя мозг активно вспоминать каждое слово.',
      AppLanguage.en:
          'This method helps achieve verbatim accuracy by forcing the brain to actively recall each word.',
      AppLanguage.de:
          'Diese Methode hilft dabei, Wortgenauigkeit zu erreichen, indem sie das Gehirn zwingt, sich aktiv an jedes Wort zu erinnern.',
    },
  ),
  LessonSlide(
    icon: Icons.playlist_add_check_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Инструкция:\n1. Шифровка: Выпиши текст, оставив только первые буквы каждого слова. Сохраняй знаки препинания.\n2. Чтение: Попробуй прочитать текст, глядя только на эти буквы.\n3. Закрепление: Повторяй процесс, пока не сможешь воспроизвести текст без подсказки. Эти буквы станут опорой для твоих образов во дворце.',
      AppLanguage.en:
          'Instructions:\n1. Encoding: Write out the text, leaving only the first letters of each word. Keep the punctuation.\n2. Reading: Try to read the text looking only at these letters.\n3. Consolidation: Repeat the process until you can reproduce the text without prompts. These letters will become the foundation for your images in the palace.',
      AppLanguage.de:
          'Anleitung:\n1. Kodierung: Schreibe den Text auf und lasse nur die Anfangsbuchstaben jedes Wortes stehen. Behalte die Satzzeichen bei.\n2. Lesen: Versuche, den Text zu lesen, während du nur auf diese Buchstaben schaust.\n3. Festigung: Wiederhole den Vorgang, bis du den Text ohne Hilfe wiedergeben kannst. Diese Buchstaben werden zur Stütze für deine Bilder im Palast.',
    },
    isCompletion: true,
  ),
];

// ---------------------------------------------------------------------------
// Урок 3
// ---------------------------------------------------------------------------
const List<LessonSlide> _kTextsLesson3Slides = <LessonSlide>[
  LessonSlide(
    icon: Icons.hub_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Урок 3: Ключевые образы и связки',
      AppLanguage.en: 'Lesson 3: Keywords and Fillers',
      AppLanguage.de: 'Lektion 3: Schlüsselbilder und Füllwörter',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Метод для запоминания сути текста с сохранением его структуры.',
      AppLanguage.en:
          'A method for memorizing the essence of a text while preserving its structure.',
      AppLanguage.de:
          'Eine Methode, um den Kern eines Textes zu speichern und dabei seine Struktur beizubehalten.',
    },
  ),
  LessonSlide(
    icon: Icons.playlist_add_check_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Инструкция:\n1. Скелет: Найди в предложении главные слова (обычно существительное и глагол). Создай из них один яркий образ.\n2. Связки: Для служебных слов (и, но, если) используй стандартные образы. Например, \'НО\' — это всегда кирпичная стена.\n3. Композиция: Помести главный образ в локацию, а связки прикрепи к нему как мелкие детали.',
      AppLanguage.en:
          'Instructions:\n1. Skeleton: Find the main words in a sentence (usually a noun and a verb). Create one vivid image from them.\n2. Fillers: Use standard images for function words (and, but, if). For example, \'BUT\' is always a brick wall.\n3. Composition: Place the main image in a location and attach the fillers to it as small details.',
      AppLanguage.de:
          'Anleitung:\n1. Gerüst: Finde die Hauptwörter im Satz (meist Nomen und Verb). Erstelle daraus ein lebendiges Bild.\n2. Füllwörter: Nutze Standardbilder für Bindewörter (und, aber, wenn). Zum Beispiel: \'ABER\' ist immer eine Ziegelmauer.\n3. Komposition: Platziere das Hauptbild an einem Ort und hänge die Füllwörter als kleine Details daran.',
    },
    isCompletion: true,
  ),
];

// ---------------------------------------------------------------------------
// Урок 4
// ---------------------------------------------------------------------------
const List<LessonSlide> _kTextsLesson4Slides = <LessonSlide>[
  LessonSlide(
    icon: Icons.view_week_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Урок 4: Построчный метод',
      AppLanguage.en: 'Lesson 4: Line-by-Line Method',
      AppLanguage.de: 'Lektion 4: Zeile-für-Zeile-Methode',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Используется для стихов или текстов с жесткой структурой строк.',
      AppLanguage.en:
          'Used for poetry or texts with a rigid line structure.',
      AppLanguage.de:
          'Wird für Gedichte oder Texte mit einer starren Zeilenstruktur verwendet.',
    },
  ),
  LessonSlide(
    icon: Icons.playlist_add_check_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Инструкция:\n1. Зонирование: Раздели одну локацию (например, стол) на три части: лево, центр, право.\n2. Распределение: Размести первую строку слева, вторую в центре, третью справа.\n3. Эффект: Это позволяет хранить сразу три блока информации в одной точке маршрута, не теряя их порядок.',
      AppLanguage.en:
          'Instructions:\n1. Zoning: Divide one location (e.g., a table) into three parts: left, center, right.\n2. Distribution: Place the first line on the left, the second in the center, and the third on the right.\n3. Effect: This allows you to store three blocks of information at a single point on the route without losing their order.',
      AppLanguage.de:
          'Anleitung:\n1. Zonierung: Unterteile einen Ort (z. B. einen Tisch) in drei Teile: links, Mitte, rechts.\n2. Verteilung: Platziere die erste Zeile links, die zweite in der Mitte und die dritte rechts.\n3. Effekt: Dies ermöglicht es dir, drei Informationsblöcke an einem einzigen Punkt der Route zu speichern, ohne die Reihenfolge zu verlieren.',
    },
    isCompletion: true,
  ),
];

// ---------------------------------------------------------------------------
// Урок 5
// ---------------------------------------------------------------------------
const List<LessonSlide> _kTextsLesson5Slides = <LessonSlide>[
  LessonSlide(
    icon: Icons.auto_awesome_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Урок 5: Эмоциональный резонанс',
      AppLanguage.en: 'Lesson 5: Emotional Resonance',
      AppLanguage.de: 'Lektion 5: Emotionale Resonanz',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Техника оживления сухих данных для долгосрочного запоминания.',
      AppLanguage.en:
          'A technique to bring dry data to life for long-term retention.',
      AppLanguage.de:
          'Eine Technik, um trockene Daten für die langfristige Speicherung zum Leben zu erwecken.',
    },
  ),
  LessonSlide(
    icon: Icons.playlist_add_check_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Инструкция:\n1. Озвучка: Проговаривай текст вслух, меняя интонацию в зависимости от смысла. Мозг запомнит мышечные усилия.\n2. Атмосфера: Добавь образу в локации температуру (холод/жар), запах или звук.\n3. Эмоция: Если фраза несет призыв — пусть образ будет агрессивным или вдохновляющим. Эмоциональные образы не стираются неделями.',
      AppLanguage.en:
          'Instructions:\n1. Voice-over: Say the text aloud, changing your intonation based on the meaning. The brain will remember the muscular effort.\n2. Atmosphere: Add temperature (cold/heat), smell, or sound to the image in the location.\n3. Emotion: If a phrase conveys a call to action, make the image aggressive or inspiring. Emotional images stay in memory for weeks.',
      AppLanguage.de:
          'Anleitung:\n1. Vertonung: Sprich den Text laut aus und ändere deine Intonation je nach Bedeutung. Das Gehirn merkt sich die Muskelanstrengung.\n2. Atmosphäre: Füge dem Bild am Ort Temperatur (Kälte/Hitze), Geruch oder Klang hinzu.\n3. Emotion: Wenn ein Satz einen Aufruf enthält, mache das Bild aggressiv oder inspirierend. Emotionale Bilder bleiben wochenlang im Gedächtnis.',
    },
    isCompletion: true,
  ),
];

class TextsMemorizationLesson1Screen extends StatelessWidget {
  const TextsMemorizationLesson1Screen({super.key, this.onFinished});
  final VoidCallback? onFinished;
  @override
  Widget build(BuildContext context) {
    return LessonScreen(slides: _kTextsLesson1Slides, onFinished: onFinished);
  }
}

class TextsMemorizationLesson2Screen extends StatelessWidget {
  const TextsMemorizationLesson2Screen({super.key, this.onFinished});
  final VoidCallback? onFinished;
  @override
  Widget build(BuildContext context) {
    return LessonScreen(slides: _kTextsLesson2Slides, onFinished: onFinished);
  }
}

class TextsMemorizationLesson3Screen extends StatelessWidget {
  const TextsMemorizationLesson3Screen({super.key, this.onFinished});
  final VoidCallback? onFinished;
  @override
  Widget build(BuildContext context) {
    return LessonScreen(slides: _kTextsLesson3Slides, onFinished: onFinished);
  }
}

class TextsMemorizationLesson4Screen extends StatelessWidget {
  const TextsMemorizationLesson4Screen({super.key, this.onFinished});
  final VoidCallback? onFinished;
  @override
  Widget build(BuildContext context) {
    return LessonScreen(slides: _kTextsLesson4Slides, onFinished: onFinished);
  }
}

class TextsMemorizationLesson5Screen extends StatelessWidget {
  const TextsMemorizationLesson5Screen({super.key, this.onFinished});
  final VoidCallback? onFinished;
  @override
  Widget build(BuildContext context) {
    return LessonScreen(slides: _kTextsLesson5Slides, onFinished: onFinished);
  }
}

const Map<String, List<LessonSlide>> kTextMemorizationBuiltinSlides =
    <String, List<LessonSlide>>{
  'disc_texts': _kTextsLesson1Slides,
  'texts_l2': _kTextsLesson2Slides,
  'texts_l3': _kTextsLesson3Slides,
  'texts_l4': _kTextsLesson4Slides,
  'texts_l5': _kTextsLesson5Slides,
};
