import 'package:flutter/material.dart';

import '../recovered_app.dart' show AppLanguage;
import 'academy_training_launcher.dart';
import 'lesson_framework.dart';

// =====================================================================
//  ТРЕК «Слова» — уроки под колонкой disc_words в Skill Tree.
//  Контент синхронизирован с теорией: визуализация слов, абстракции,
//  быстрое кодирование.
// =====================================================================

const List<LessonSlide> _kWordsMemorizingSlides = <LessonSlide>[
  LessonSlide(
    icon: Icons.short_text_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Введение и предметные слова',
      AppLanguage.en: 'Introduction and concrete words',
      AppLanguage.de: 'Einführung und konkrete Wörter',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Запоминание списков слов — одна из самых полезных и универсальных дисциплин в мнемотехнике. На соревнованиях чемпионы запоминают сотни случайных слов за короткое время, а в повседневной жизни этот навык помогает учить иностранные языки, готовиться к экзаменам и запоминать списки покупок, задач или терминов.',
      AppLanguage.en:
          'Memorizing lists of words is one of the most useful and universal disciplines in mnemonics. At competitions, champions memorize hundreds of random words in a short time, and in everyday life this skill helps with learning foreign languages, exam preparation, and remembering shopping lists, tasks, or terms.',
      AppLanguage.de:
          'Das Merken von Wortlisten ist eine der nützlichsten und universellsten Disziplinen der Mnemotechnik. Bei Wettbewerben merken sich Champions Hunderte zufälliger Wörter in kurzer Zeit, und im Alltag hilft dir dieser Skill beim Lernen von Fremdsprachen, Prüfungsvorbereitung und dem Merken von Einkaufslisten, Aufgaben oder Fachbegriffen.',
    },
  ),
  LessonSlide(
    icon: Icons.category_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Предметные слова',
      AppLanguage.en: 'Concrete words',
      AppLanguage.de: 'Konkrete Wörter',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Предметные слова (стол, яблоко, машина, собака) запоминать проще всего. Ты уже умеешь создавать яркие образы и связки. Просто возьми само слово как объект и сделай его максимально запоминающимся: увеличь, деформируй, добавь эмоции, движение, цвет или абсурд.',
      AppLanguage.en:
          'Concrete words (table, apple, car, dog) are the easiest to memorize. You already know how to create vivid images and links. Simply take the word itself as an object and make it extremely memorable: enlarge it, distort it, add emotions, movement, color, or absurdity.',
      AppLanguage.de:
          'Konkrete Wörter (Tisch, Apfel, Auto, Hund) sind am einfachsten zu merken. Du kannst bereits lebendige Bilder und Verknüpfungen erstellen. Nimm das Wort einfach als Objekt und mache es extrem einprägsam: vergrößere es, verforme es, füge Emotionen, Bewegung, Farbe oder Absurdität hinzu.',
    },
  ),
  LessonSlide(
    icon: Icons.pets_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Пример',
      AppLanguage.en: 'Example',
      AppLanguage.de: 'Beispiel',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Слово «слон» → огромный розовый слон в балетной пачке, который танцует на твоей кухне.',
      AppLanguage.en:
          'The word “elephant” → a huge pink elephant in a ballet tutu dancing in your kitchen.',
      AppLanguage.de:
          'Wort „Elefant“ → ein riesiger pinker Elefant im Ballett-Tütü, der in deiner Küche tanzt.',
    },
  ),
  LessonSlide(
    icon: Icons.link_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Связки и маршрут',
      AppLanguage.en: 'Links and journey',
      AppLanguage.de: 'Verknüpfung und Route',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Для коротких списков используй метод связок, для длинных — метод локусов (маршрут). Главное — делай образы живыми, эмоциональными и интерактивными.',
      AppLanguage.en:
          'Use the linking method for short lists or the method of loci (memory journey) for long ones. The key is to make your images vivid, emotional, and interactive.',
      AppLanguage.de:
          'Nutze die Verknüpfungsmethode für kurze Listen oder die Loci-Methode (Reiseroute) für lange Listen. Das Wichtigste: Mach deine Bilder lebendig, emotional und interaktiv.',
    },
    isCompletion: true,
    trainerLaunch: LessonTrainerLaunchKind.academyWordsElements10,
    trainerCtaLabel: <AppLanguage, String>{
      AppLanguage.ru: 'Открыть тренажёр · слова',
      AppLanguage.en: 'Open trainer · words',
      AppLanguage.de: 'Trainer öffnen · Wörter',
    },
    trainerCtaSubtitle: <AppLanguage, String>{
      AppLanguage.ru: 'Случайные слова — закрепляй образ, не буквы',
      AppLanguage.en: 'Random words — anchor images, not letters',
      AppLanguage.de: 'Zufallswörter — Bilder verankern, keine Buchstaben',
    },
  ),
];

const List<LessonSlide> _kWordsAbstractSlides = <LessonSlide>[
  LessonSlide(
    icon: Icons.public_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Абстрактные слова',
      AppLanguage.en: 'Abstract words',
      AppLanguage.de: 'Abstrakte Wörter',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Абстрактные слова (свобода, любовь, успех, демократия, Америка) не имеют физической формы, поэтому их нужно превращать в конкретные, яркие образы.',
      AppLanguage.en:
          'Abstract words (freedom, love, success, democracy, America) have no physical form, so they must be turned into concrete, vivid images.',
      AppLanguage.de:
          'Abstrakte Wörter (Freiheit, Liebe, Erfolg, Demokratie, Amerika) haben keine physische Form, deshalb musst du sie in konkrete, lebendige Bilder verwandeln.',
    },
  ),
  LessonSlide(
    icon: Icons.lightbulb_outline_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Примеры образов',
      AppLanguage.en: 'Image examples',
      AppLanguage.de: 'Beispiel-Bilder',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          '• Америка → белоголовый орёл, который держит в когтях гамбургер и флаг\n'
          '• Свобода → статуя Свободы, разрывающая цепи, или птица, вылетающая из клетки\n'
          '• Счастье → улыбающийся человек, прыгающий в кучу золотых монет под радугой',
      AppLanguage.en:
          '• America → a bald eagle holding a hamburger and a flag in its talons\n'
          '• Freedom → the Statue of Liberty breaking chains, or a bird flying out of a cage\n'
          '• Happiness → a smiling person jumping into a pile of gold coins under a rainbow',
      AppLanguage.de:
          '• Amerika → ein Weißkopfseeadler, der einen Hamburger und eine Flagge in den Krallen hält\n'
          '• Freiheit → die Freiheitsstatue, die Ketten zerreißt, oder ein Vogel, der aus einem Käfig fliegt\n'
          '• Glück → ein lächelnder Mensch, der in einen Haufen Goldmünzen unter einem Regenbogen springt',
    },
  ),
  LessonSlide(
    icon: Icons.favorite_border_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Эмоции',
      AppLanguage.en: 'Emotions',
      AppLanguage.de: 'Emotionen',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Создавай образы, которые вызывают сильные эмоции (смех, удивление, отвращение, восторг). Чем абсурднее и ярче — тем лучше.',
      AppLanguage.en:
          'Create images that evoke strong emotions (laughter, surprise, disgust, joy). The more absurd and vivid, the better.',
      AppLanguage.de:
          'Erstelle Bilder, die starke Emotionen auslösen (Lachen, Staunen, Ekel, Begeisterung). Je absurder und lebendiger, desto besser.',
    },
  ),
  LessonSlide(
    icon: Icons.task_alt_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Практика',
      AppLanguage.en: 'Practice',
      AppLanguage.de: 'Praxis',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Возьми 10 абстрактных слов (например: мир, знание, страх, будущее, справедливость, творчество, сила, гармония, время, доверие). Придумай для каждого свой уникальный яркий образ. Запиши их и попробуй связать в короткую историю или разместить на простом маршруте из 5 локаций. Повтори упражнение несколько раз.',
      AppLanguage.en:
          'Take 10 abstract words (e.g., peace, knowledge, fear, future, justice, creativity, strength, harmony, time, trust). Create your own unique vivid image for each. Write them down and try linking them into a short story or placing them on a simple journey with 5 loci. Repeat the exercise several times.',
      AppLanguage.de:
          'Nimm 10 abstrakte Wörter (z. B. Frieden, Wissen, Angst, Zukunft, Gerechtigkeit, Kreativität, Kraft, Harmonie, Zeit, Vertrauen). Erfinde für jedes ein eigenes starkes Bild. Schreibe sie auf und versuche, sie in eine kurze Geschichte zu verknüpfen oder auf einer einfachen Route mit 5 Stationen zu platzieren. Wiederhole die Übung mehrmals.',
    },
    isCompletion: true,
    trainerLaunch: LessonTrainerLaunchKind.academyWordsElements10,
    trainerCtaLabel: <AppLanguage, String>{
      AppLanguage.ru: 'Открыть тренажёр · слова',
      AppLanguage.en: 'Open trainer · words',
      AppLanguage.de: 'Trainer öffnen · Wörter',
    },
    trainerCtaSubtitle: <AppLanguage, String>{
      AppLanguage.ru: 'Случайные слова — тренируй личные символы',
      AppLanguage.en: 'Random words — train personal symbols',
      AppLanguage.de: 'Zufallswörter — persönliche Symbole trainieren',
    },
  ),
];

const List<LessonSlide> _kWordsFastCodingSlides = <LessonSlide>[
  LessonSlide(
    icon: Icons.bolt_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Быстрое кодирование',
      AppLanguage.en: 'Fast coding',
      AppLanguage.de: 'Schnelles Kodieren',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Профи-уровень начинается, когда мозг не «думает» над словом, а первым делом рисует образ. Это и есть быстрое кодирование: слово → картинка → локус.',
      AppLanguage.en:
          'The real jump is when the brain doesn’t debate the word—it paints an image first. That’s fast coding: word → image → locus.',
      AppLanguage.de:
          'Der Sprung kommt, wenn das Wort nicht diskutiert wird, sondern sofort als Bild da ist: schnelles Kodieren — Wort → Bild → Locus.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Важнее мгновенность, чем «идеальная» ассоциация.',
      AppLanguage.en: 'Instant beats “perfect” associations.',
      AppLanguage.de: 'Schnelligkeit schlägt „perfekte“ Assoziationen.',
    },
  ),
  LessonSlide(
    icon: Icons.flash_on_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Первый образ — лучший',
      AppLanguage.en: 'First image wins',
      AppLanguage.de: 'Erstes Bild gewinnt',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Новички теряют темп, гоняясь за умнейшей метафорой. Услышал слово — поймал первую яркую картинку и пошёл дальше: «Америка» дала орла — бери орла. На скорости мозг работает почти автоматически — так держат длинные списки.',
      AppLanguage.en:
          'Beginners stall chasing a cleverer metaphor. Hear the word—grab the first vivid frame and move on: if America gives you an eagle, take the eagle. At speed the brain runs almost on autopilot—that’s how long lists stick.',
      AppLanguage.de:
          'Anfänger bleiben hängen, weil sie die klügste Metapher suchen. Nimm das erste lebendige Bild — wenn Amerika einen Adler liefert, nimm den Adler. In hohem Tempo läuft das Gehirn fast von selbst — so halten Mnemoniker lange Listen.',
    },
  ),
  LessonSlide(
    icon: Icons.tune_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Простота и поток',
      AppLanguage.en: 'Simplicity and flow',
      AppLanguage.de: 'Einfachheit und Flow',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Не перегружай сцену деталями — чем проще и ярче ядро, тем быстрее код и декод. Со временем слова перестают ощущаться как текст и превращаются в поток визуальных эпизодов.',
      AppLanguage.en:
          'Don’t clutter the scene—the simpler and brighter the core, the faster encode and recall. Over time words feel less like text and more like a stream of visual episodes.',
      AppLanguage.de:
          'Überfrachte die Szene nicht — je klarer der Kern, desto schneller Kodierung und Abruf. Mit der Zeit werden Wörter weniger Text und mehr ein Strom aus Bildern.',
    },
  ),
  LessonSlide(
    icon: Icons.timer_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Задание со скоростью',
      AppLanguage.en: 'Speed drill',
      AppLanguage.de: 'Tempo-Übung',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Включи тренажёр слов в режиме автопоказа: не больше двух секунд на слово, чтобы поймать образ. Цель — научить мозг реагировать автоматически, а не выискивать идеал.',
      AppLanguage.en:
          'Use the words trainer with timed reveal—about two seconds per word to force an image. The goal is reflex, not hunting for a perfect scene.',
      AppLanguage.de:
          'Nutze den Wörter-Trainer mit Zeitlimit — etwa zwei Sekunden pro Wort, um ein Bild zu erzwingen. Ziel: Reflex statt Perfektionssuche.',
    },
    isCompletion: true,
    trainerLaunch: LessonTrainerLaunchKind.academyWordsSpeedFlash2s,
    trainerCtaLabel: <AppLanguage, String>{
      AppLanguage.ru: 'Тренажёр · 2 с на слово',
      AppLanguage.en: 'Trainer · 2s per word',
      AppLanguage.de: 'Trainer · 2 s pro Wort',
    },
    trainerCtaSubtitle: <AppLanguage, String>{
      AppLanguage.ru: 'Автопоказ: лови первый образ под давлением темпа',
      AppLanguage.en: 'Timed flash: grab the first image under pace',
      AppLanguage.de: 'Zeitlimit: erstes Bild unter Tempo fangen',
    },
  ),
];

class WordsMemorizingLessonScreen extends StatelessWidget {
  const WordsMemorizingLessonScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return LessonScreen(
      slides: _kWordsMemorizingSlides,
      onFinished: onFinished,
      onTrainerLaunch: academyLaunchLessonTrainer,
    );
  }
}

class WordsAbstractLessonScreen extends StatelessWidget {
  const WordsAbstractLessonScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return LessonScreen(
      slides: _kWordsAbstractSlides,
      onFinished: onFinished,
      onTrainerLaunch: academyLaunchLessonTrainer,
    );
  }
}

class WordsFastCodingLessonScreen extends StatelessWidget {
  const WordsFastCodingLessonScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return LessonScreen(
      slides: _kWordsFastCodingSlides,
      onFinished: onFinished,
      onTrainerLaunch: academyLaunchLessonTrainer,
    );
  }
}

const Map<String, List<LessonSlide>> kWordsTrackBuiltinSlides =
    <String, List<LessonSlide>>{
  'disc_words': _kWordsMemorizingSlides,
  'words_abstract': _kWordsAbstractSlides,
  'words_fast_coding': _kWordsFastCodingSlides,
};
