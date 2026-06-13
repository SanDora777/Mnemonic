import 'package:flutter/material.dart';

import '../recovered_app.dart' show AppLanguage;
import 'lesson_framework.dart';

// =====================================================================
//  ДОП. УРОКИ блока «Что такое мнемотехника» (две ветки от m1).
//
//    MnemonicsCapabilitiesLessonScreen — узел intro1 (слева, «Что она
//                                        может»): на что способна
//                                        мнемотехника.
//    MnemonicsHistoryLessonScreen      — узел intro2 (справа,
//                                        «История»): откуда она
//                                        пришла, тысячелетняя школа.
//
//  Обе ветки используют общий LessonScreen-каркас.
// =====================================================================

// ---------------------------------------------------------------------
//  1. ЧТО МОЖЕТ МНЕМОТЕХНИКА — узел intro1 (слева).
// ---------------------------------------------------------------------

const List<LessonSlide> _kCapabilitiesSlides = <LessonSlide>[
  LessonSlide(
    icon: Icons.bolt_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Не просто память',
      AppLanguage.en: 'More than memory',
      AppLanguage.de: 'Mehr als Gedächtnis',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Мнемотехника — это не способ запомнить чуть больше. Это инструмент, который расширяет возможности мозга. С правильной тренировкой ты впитываешь огромные объёмы за минуты.',
      AppLanguage.en:
          'Mnemonics isn\'t a way to remember just a little more. It\'s a tool that expands the brain\'s capabilities. With proper training, you absorb huge amounts of information in minutes.',
      AppLanguage.de:
          'Mnemotechnik ist keine Methode, um etwas mehr zu behalten. Sie ist ein Werkzeug, das die Möglichkeiten deines Gehirns erweitert. Mit richtigem Training nimmst du riesige Mengen an Informationen in Minuten auf.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Не лайфхак. Апгрейд.',
      AppLanguage.en: 'Not a hack. An upgrade.',
      AppLanguage.de: 'Kein Trick. Ein Upgrade.',
    },
  ),
  LessonSlide(
    icon: Icons.tag_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Тысячи цифр за час',
      AppLanguage.en: 'Thousands of digits per hour',
      AppLanguage.de: 'Tausende Ziffern pro Stunde',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Опытные мнемонисты запоминают тысячи цифр за час и точно воспроизводят их в правильном порядке. Каждая цифра — образ. Каждая последовательность — связная история.',
      AppLanguage.en:
          'Experienced mnemonists memorize thousands of digits in an hour and reproduce them flawlessly in the correct order. Each digit is an image. Each sequence is a connected story.',
      AppLanguage.de:
          'Erfahrene Mnemoniker speichern in einer Stunde tausende Ziffern und geben sie fehlerfrei in der richtigen Reihenfolge wieder. Jede Ziffer wird zum Bild. Jede Sequenz wird zur Geschichte.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: '1000+ цифр. По памяти. Без ошибок.',
      AppLanguage.en: '1000+ digits. From memory. Flawlessly.',
      AppLanguage.de: '1000+ Ziffern. Aus dem Kopf. Fehlerfrei.',
    },
  ),
  LessonSlide(
    icon: Icons.style_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Колода карт за секунды',
      AppLanguage.en: 'A deck of cards in seconds',
      AppLanguage.de: 'Ein Kartendeck in Sekunden',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Целую колоду карт мнемонист запоминает за секунды: каждой карте — яркий образ, всем вместе — связная цепочка-история. Это не магия. Это натренированное визуальное мышление.',
      AppLanguage.en:
          'A whole deck of cards memorized in seconds: every card gets a vivid image, all of them strung into a single story chain. Not magic — just trained visual thinking.',
      AppLanguage.de:
          'Ein ganzes Kartendeck — in Sekunden: Jede Karte bekommt ein lebendiges Bild, alle zusammen werden zu einer Geschichte. Keine Magie — trainiertes bildhaftes Denken.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: '52 карты → одна история.',
      AppLanguage.en: '52 cards → one story.',
      AppLanguage.de: '52 Karten → eine Geschichte.',
    },
  ),
  LessonSlide(
    icon: Icons.library_books_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Любая информация',
      AppLanguage.en: 'Any information',
      AppLanguage.de: 'Jede Information',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'С мнемотехникой запоминают почти всё: сложные тексты, учебники, исторические события, священные книги. Даже языки идут в разы быстрее — слово сразу становится образом. Программирование тоже легче: код превращается в связи и картинки.',
      AppLanguage.en:
          'With mnemonics you can memorize almost anything: complex texts, textbooks, history, sacred books. Languages run several times faster — every word becomes an image. Even programming gets easier as code turns into connections and pictures.',
      AppLanguage.de:
          'Mit Mnemotechnik kannst du fast alles speichern: komplexe Texte, Lehrbücher, Geschichte, heilige Schriften. Sprachen beschleunigen sich um ein Vielfaches — jedes Wort wird zum Bild. Auch Programmieren wird leichter: Code wird zu Verbindungen und Bildern.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'От текстов до кода — всё через образ.',
      AppLanguage.en: 'From texts to code — everything through images.',
      AppLanguage.de: 'Von Texten bis Code — alles durch Bilder.',
    },
  ),
  LessonSlide(
    icon: Icons.emoji_events_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Мнемоспорт',
      AppLanguage.en: 'Memory sport',
      AppLanguage.de: 'Gedächtnissport',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Мнемотехника — это и спорт. На официальных соревнованиях атлеты состязаются в запоминании чисел, карт, слов и абстрактной информации за ограниченное время. Лучшие удерживают сотни элементов без ошибок.',
      AppLanguage.en:
          'Mnemonics is also a sport. At official competitions, memory athletes compete in memorizing numbers, cards, words, and abstract information under strict time limits. The best hold hundreds of items without a single mistake.',
      AppLanguage.de:
          'Mnemotechnik ist auch Sport. Bei offiziellen Wettkämpfen messen sich Gedächtnissportler im Merken von Zahlen, Karten, Wörtern und abstrakten Informationen unter Zeitdruck. Die Besten halten hunderte Elemente fehlerfrei.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Скорость · Концентрация · Структура.',
      AppLanguage.en: 'Speed · Focus · Structure.',
      AppLanguage.de: 'Geschwindigkeit · Konzentration · Struktur.',
    },
  ),
  LessonSlide(
    icon: Icons.all_inclusive_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Граница — в голове',
      AppLanguage.en: 'The limit is in your mind',
      AppLanguage.de: 'Die Grenze liegt im Kopf',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Память не ограничена природой. Она ограничена только тем, как ты ею пользуешься. Когда начинаешь думать образами — ты не учишь информацию. Ты её видишь.',
      AppLanguage.en:
          'Memory isn\'t limited by nature. It\'s limited only by how you use it. When you start thinking in images, you stop studying information — you start seeing it.',
      AppLanguage.de:
          'Gedächtnis ist nicht von Natur aus begrenzt. Es ist nur dadurch begrenzt, wie du es benutzt. Wenn du in Bildern denkst, lernst du Informationen nicht — du siehst sie.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Не учишь. Видишь.',
      AppLanguage.en: 'Don\'t study. See.',
      AppLanguage.de: 'Nicht lernen. Sehen.',
    },
  ),
  LessonSlide(
    icon: Icons.workspace_premium_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Урок пройден',
      AppLanguage.en: 'Lesson complete',
      AppLanguage.de: 'Lektion abgeschlossen',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Теперь ты знаешь, на что способна мнемотехника. Дальше — практика: образы, связи, дворцы.',
      AppLanguage.en:
          'Now you know what mnemonics is capable of. Next — practice: images, links, palaces.',
      AppLanguage.de:
          'Jetzt weißt du, was Mnemotechnik kann. Weiter geht\'s mit der Praxis: Bilder, Verbindungen, Paläste.',
    },
    isCompletion: true,
  ),
];

class MnemonicsCapabilitiesLessonScreen extends StatelessWidget {
  const MnemonicsCapabilitiesLessonScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return LessonScreen(slides: _kCapabilitiesSlides, onFinished: onFinished);
  }
}

// ---------------------------------------------------------------------
//  2. ИСТОРИЯ МНЕМОТЕХНИКИ — узел intro2 (справа).
// ---------------------------------------------------------------------

const List<LessonSlide> _kHistorySlides = <LessonSlide>[
  LessonSlide(
    icon: Icons.history_edu_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Древнее искусство',
      AppLanguage.en: 'An ancient art',
      AppLanguage.de: 'Eine alte Kunst',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Мнемотехника появилась задолго до компьютеров и даже до книг. Когда не было ни блокнотов, ни шпаргалок — была память. И её тренировали серьёзно.',
      AppLanguage.en:
          'Mnemonics appeared long before computers — and even before books. When there were no notes and no cheat sheets, there was memory. And it was trained seriously.',
      AppLanguage.de:
          'Mnemotechnik gab es lange vor Computern – und sogar vor Büchern. Als es keine Notizen, keine Spickzettel gab, gab es das Gedächtnis. Und das wurde ernsthaft trainiert.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Старше письменности.',
      AppLanguage.en: 'Older than writing.',
      AppLanguage.de: 'Älter als die Schrift.',
    },
  ),
  LessonSlide(
    icon: Icons.account_balance_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Греция и Рим',
      AppLanguage.en: 'Greece and Rome',
      AppLanguage.de: 'Griechenland und Rom',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Ораторы Древней Греции и Рима выходили на трибуну без единой записи. Им нужно было удержать в голове целые многочасовые речи — слово в слово, без единой ошибки.',
      AppLanguage.en:
          'Orators of Ancient Greece and Rome took the stage without a single note. They had to hold entire hours-long speeches in their heads — word for word, without a single mistake.',
      AppLanguage.de:
          'Redner im alten Griechenland und Rom traten ohne eine einzige Notiz auf. Sie mussten stundenlange Reden im Kopf behalten – Wort für Wort, fehlerfrei.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Без листка. Без подсказок.',
      AppLanguage.en: 'No notes. No prompts.',
      AppLanguage.de: 'Kein Blatt. Kein Soufflieren.',
    },
  ),
  LessonSlide(
    icon: Icons.castle_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Дворцы памяти',
      AppLanguage.en: 'Memory palaces',
      AppLanguage.de: 'Gedächtnispaläste',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Они строили в голове целые дворцы — комнату за комнатой — и расставляли по ним идеи. Во время речи они мысленно проходили по этим комнатам и вспоминали каждую часть выступления.',
      AppLanguage.en:
          'They built whole palaces in their minds — room by room — and placed ideas inside. During a speech they mentally walked through the rooms and recalled every part of the talk.',
      AppLanguage.de:
          'Sie bauten in ihren Köpfen ganze Paläste – Raum für Raum – und legten Ideen darin ab. Während der Rede gingen sie diese Räume gedanklich ab und erinnerten sich an jeden Teil.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Информация — это архитектура.',
      AppLanguage.en: 'Information is architecture.',
      AppLanguage.de: 'Information ist Architektur.',
    },
  ),
  LessonSlide(
    icon: Icons.place_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Метод локусов',
      AppLanguage.en: 'The method of loci',
      AppLanguage.de: 'Die Loci-Methode',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Один из первых известных приёмов — метод локусов: размещать информацию в воображаемом пространстве. Им пользовались философы, учёные и даже религиозные деятели для запоминания огромных текстов.',
      AppLanguage.en:
          'One of the first known techniques — the method of loci: placing information in an imagined space. Philosophers, scientists, and even religious figures used it to memorize enormous texts.',
      AppLanguage.de:
          'Eine der ersten bekannten Techniken – die Loci-Methode: Informationen in einem vorgestellten Raum platzieren. Philosophen, Wissenschaftler und sogar religiöse Persönlichkeiten nutzten sie, um riesige Texte zu behalten.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Локус — место, где живёт мысль.',
      AppLanguage.en: 'A locus is where a thought lives.',
      AppLanguage.de: 'Ein Locus ist der Ort eines Gedankens.',
    },
  ),
  LessonSlide(
    icon: Icons.menu_book_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Монахи и тексты',
      AppLanguage.en: 'Monks and sacred texts',
      AppLanguage.de: 'Mönche und heilige Texte',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'В Средние века монахи использовали похожие техники, чтобы держать в голове священные книги целиком. Многие методы потом были утеряны и заново открыты лишь в наше время.',
      AppLanguage.en:
          'In the Middle Ages, monks used similar techniques to keep entire sacred books in their heads. Many of those methods were lost and only rediscovered in modern times.',
      AppLanguage.de:
          'Im Mittelalter nutzten Mönche ähnliche Techniken, um ganze heilige Bücher im Kopf zu behalten. Viele dieser Methoden gingen verloren und wurden erst in der Neuzeit wiederentdeckt.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Утеряно — переоткрыто.',
      AppLanguage.en: 'Lost — and found again.',
      AppLanguage.de: 'Verloren — wiederentdeckt.',
    },
  ),
  LessonSlide(
    icon: Icons.emoji_events_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Сегодня — спорт',
      AppLanguage.en: 'Today — a sport',
      AppLanguage.de: 'Heute — ein Sport',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Сейчас мнемотехника — это и наука, и спортивная дисциплина. Чемпионы соревнуются: кто запомнит больше и быстрее. По тем же принципам, что использовали тысячи лет назад.',
      AppLanguage.en:
          'Today mnemonics is both a science and a sport. Champions compete to see who memorizes more, faster — using the same principles people used thousands of years ago.',
      AppLanguage.de:
          'Heute ist Mnemotechnik Wissenschaft und Sportdisziplin zugleich. Champions wetteifern, wer schneller mehr behält — mit denselben Prinzipien wie vor Jahrtausenden.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Принципы те же. Скорости — нет.',
      AppLanguage.en: 'Same principles. New speed.',
      AppLanguage.de: 'Gleiche Prinzipien. Andere Geschwindigkeit.',
    },
  ),
  LessonSlide(
    icon: Icons.workspace_premium_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Урок пройден',
      AppLanguage.en: 'Lesson complete',
      AppLanguage.de: 'Lektion abgeschlossen',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Теперь ты знаешь: мнемотехника — это не модный лайфхак, а тысячелетняя школа мышления. И ты её часть.',
      AppLanguage.en:
          'Now you know: mnemonics isn\'t a trendy hack — it\'s a thousand-year-old school of thinking. And you\'re part of it.',
      AppLanguage.de:
          'Jetzt weißt du: Mnemotechnik ist kein moderner Trick — sie ist eine jahrtausendealte Denkschule. Und du bist Teil davon.',
    },
    isCompletion: true,
  ),
];

class MnemonicsHistoryLessonScreen extends StatelessWidget {
  const MnemonicsHistoryLessonScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return LessonScreen(slides: _kHistorySlides, onFinished: onFinished);
  }
}

const Map<String, List<LessonSlide>> kMnemonicsExtrasBuiltinSlides =
    <String, List<LessonSlide>>{
  'intro1': _kCapabilitiesSlides,
  'intro2': _kHistorySlides,
};
