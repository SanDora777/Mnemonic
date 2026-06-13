import 'package:flutter/material.dart';

import '../recovered_app.dart' show AppLanguage;
import 'academy_training_launcher.dart';
import 'lesson_framework.dart';

const List<LessonSlide> _kCardBasicsSlides = <LessonSlide>[
  LessonSlide(
    icon: Icons.style_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Введение в запоминание игральных карт',
      AppLanguage.en: 'Introduction to memorizing playing cards',
      AppLanguage.de: 'Einführung ins Merken von Spielkarten',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Запоминание колоды игральных карт — одна из самых эффектных дисциплин в мире мнемотехники. На мировых чемпионатах топовые мнемонисты запоминают полную перемешанную колоду из 52 карт за 20–60 секунд.',
      AppLanguage.en:
          'Memorizing a deck of playing cards is one of the most spectacular disciplines in the world of mnemonics. At world championships, top memory athletes memorize a fully shuffled deck of 52 cards in 20–60 seconds.',
      AppLanguage.de:
          'Das Merken eines Spielkarten-Decks ist eine der spektakulärsten Disziplinen der Mnemotechnik. Auf Weltmeisterschaften merken sich Top-Mnemotechniker ein komplett gemischtes Deck mit 52 Karten in 20–60 Sekunden.',
    },
  ),
  LessonSlide(
    icon: Icons.fitness_center_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Это не просто красивый трюк. Это мощнейшая тренировка скорости создания образов, работы с методом локусов и многозадачности мозга. После освоения карт обычно резко улучшаются результаты в запоминании чисел, слов и бинарных последовательностей.',
      AppLanguage.en:
          'This is not just a fancy trick. It is an extremely powerful workout for the speed of image creation, working with the method of loci, and your brain’s multitasking ability. After mastering cards, your results in numbers, words, and binary usually improve dramatically.',
      AppLanguage.de:
          'Das ist kein bloßer Trick. Es ist ein extrem starkes Training für die Geschwindigkeit der Bildererzeugung, die Arbeit mit der Loci-Methode und die Multitasking-Fähigkeit deines Gehirns. Nachdem du Karten gemeistert hast, verbessern sich deine Ergebnisse bei Zahlen, Wörtern und Binärzahlen meist stark.',
    },
  ),
  LessonSlide(
    icon: Icons.school_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'В этом курсе мы пройдём путь от простых методов до продвинутых систем, которые используют чемпионы. Ты уже знаешь, как создавать яркие образы и размещать их на маршруте. Теперь применим эти навыки к картам.',
      AppLanguage.en:
          'In this course we will go from simple methods to the advanced systems used by champions. You already know how to create vivid images and place them on a memory journey. Now we will apply these skills to cards.',
      AppLanguage.de:
          'In diesem Kurs gehen wir den Weg von einfachen Methoden bis hin zu den fortgeschrittenen Systemen der Champions. Du weißt bereits, wie man lebendige Bilder erstellt und sie auf einer Reiseroute platziert. Jetzt wenden wir diese Fähigkeiten auf Karten an.',
    },
    isCompletion: true,
  ),
];

const List<LessonSlide> _kSuitCategoriesSlides = <LessonSlide>[
  LessonSlide(
    icon: Icons.category_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Метод категорий мастей',
      AppLanguage.en: 'Suit categories method',
      AppLanguage.de: 'Farbkategorien-Methode',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Самый простой способ начать — присвоить каждой масти свою категорию и превращать карты в образы внутри этой темы.',
      AppLanguage.en:
          'The easiest way to start is to assign each suit its own category and turn cards into images within that theme.',
      AppLanguage.de:
          'Der einfachste Einstieg ist, jeder Farbe eine eigene Kategorie zuzuweisen und die Karten in Bilder innerhalb dieses Themas zu verwandeln.',
    },
  ),
  LessonSlide(
    icon: Icons.favorite_outline_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Примеры категорий',
      AppLanguage.en: 'Example categories',
      AppLanguage.de: 'Beispiel-Kategorien',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          '• Червы — любовь, семья, романтика, красивые люди\n'
          '• Бубны — деньги, богатство, роскошь, знаменитости\n'
          '• Трефы — война, борьба, инструменты, сильные личности\n'
          '• Пики — оружие, смерть, «тёмные» персонажи',
      AppLanguage.en:
          '• Hearts — love, family, romance, beautiful people\n'
          '• Diamonds — money, wealth, luxury, celebrities\n'
          '• Clubs — war, fighting, tools, strong personalities\n'
          '• Spades — weapons, death, “dark” characters',
      AppLanguage.de:
          '• Herz — Liebe, Familie, Romantik, schöne Menschen\n'
          '• Karo — Geld, Reichtum, Luxus, Berühmtheiten\n'
          '• Kreuz — Krieg, Kampf, Werkzeuge, starke Persönlichkeiten\n'
          '• Pik — Waffen, Tod, „dunkle“ Charaktere',
    },
  ),
  LessonSlide(
    icon: Icons.person_outline_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Примеры образов',
      AppLanguage.en: 'Image examples',
      AppLanguage.de: 'Beispiel-Bilder',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          '• Король червей → Купидон или твой любимый романтический герой\n'
          '• Дама бубен → Опра Уинфри или богатая бизнесвумен\n'
          '• Туз пик → острый меч или Александр Македонский',
      AppLanguage.en:
          '• King of Hearts → Cupid or your favorite romantic hero\n'
          '• Queen of Diamonds → Oprah Winfrey or a wealthy businesswoman\n'
          '• Ace of Spades → sharp sword or Alexander the Great',
      AppLanguage.de:
          '• Herzkönig → Amor oder dein Lieblings-Romanheld\n'
          '• Karodame → Oprah Winfrey oder eine reiche Geschäftsfrau\n'
          '• Pik-Ass → scharfes Schwert oder Alexander der Große',
    },
  ),
  LessonSlide(
    icon: Icons.balance_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Плюсы и минусы',
      AppLanguage.en: 'Pros and cons',
      AppLanguage.de: 'Vor- und Nachteile',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Преимущество: быстро начать. Недостаток: нужно создать 52 отдельных образа.',
      AppLanguage.en:
          'Advantage: quick to start. Disadvantage: you need 52 separate images.',
      AppLanguage.de:
          'Vorteil: schneller Einstieg. Nachteil: Du brauchst 52 separate Bilder.',
    },
  ),
  LessonSlide(
    icon: Icons.route_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Практика',
      AppLanguage.en: 'Practice',
      AppLanguage.de: 'Praxis',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Возьми одну масть, придумай 13 образов и размести их на маршруте из 13 локаций.',
      AppLanguage.en:
          'Take one suit, create 13 images and place them on a journey of 13 loci.',
      AppLanguage.de:
          'Nimm eine Farbe, erfinde 13 Bilder und platziere sie auf einer Route mit 13 Stationen.',
    },
    isCompletion: true,
    trainerLaunch: LessonTrainerLaunchKind.academyCardsElements10,
    trainerCtaLabel: <AppLanguage, String>{
      AppLanguage.ru: 'В тренажёр · 10 карт',
      AppLanguage.en: 'Open trainer · 10 cards',
      AppLanguage.de: 'Zum Trainer · 10 Karten',
    },
    trainerCtaSubtitle: <AppLanguage, String>{
      AppLanguage.ru: 'Режим игральных карт — закрепи образы на практике',
      AppLanguage.en: 'Playing-card mode — drill your images',
      AppLanguage.de: 'Kartenmodus — Bilder einüben',
    },
  ),
];

const List<LessonSlide> _kMajorSystemCardsSlides = <LessonSlide>[
  LessonSlide(
    icon: Icons.pin_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Major System для карт',
      AppLanguage.en: 'Major System for cards',
      AppLanguage.de: 'Major-System für Karten',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Этот метод превращает каждую карту в двухзначное число и использует уже знакомую тебе Major System.',
      AppLanguage.en:
          'This method turns every card into a two-digit number and uses your familiar Major System.',
      AppLanguage.de:
          'Diese Methode verwandelt jede Karte in eine zweistellige Zahl und nutzt dein bereits bekanntes Major-System.',
    },
  ),
  LessonSlide(
    icon: Icons.vpn_key_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Кодировка мастей',
      AppLanguage.en: 'Suit coding',
      AppLanguage.de: 'Farbkodierung',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Популярный вариант кодирования мастей:\n'
          '• Пики → 0\n'
          '• Червы → 4\n'
          '• Бубны → 1\n'
          '• Трефы → 7',
      AppLanguage.en:
          'Popular suit coding:\n'
          '• Spades → 0\n'
          '• Hearts → 4\n'
          '• Diamonds → 1\n'
          '• Clubs → 7',
      AppLanguage.de:
          'Beliebte Farbkodierung:\n'
          '• Pik → 0\n'
          '• Herz → 4\n'
          '• Karo → 1\n'
          '• Kreuz → 7',
    },
  ),
  LessonSlide(
    icon: Icons.calculate_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Формула',
      AppLanguage.en: 'The formula',
      AppLanguage.de: 'Die Formel',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Номер карты + код масти = число.\n\n'
          'Примеры:\n'
          '• 2 пик → 02 → «Зебра»\n'
          '• 4 червей → 44 → «Рай» или связанный образ\n'
          '• Туз бубен → 11 → «Дэдди» / «Титаник»',
      AppLanguage.en:
          'Card value + suit code = number.\n\n'
          'Examples:\n'
          '• 2 of Spades → 02 → “Zebra”\n'
          '• 4 of Hearts → 44 → “Paradise” or related image\n'
          '• Ace of Diamonds → 11 → “Daddy” / “Titanic”',
      AppLanguage.de:
          'Kartenwert + Farbcode = Zahl.\n\n'
          'Beispiele:\n'
          '• 2 Pik → 02 → „Zebra“\n'
          '• 4 Herz → 44 → „Paradies“ oder ein passendes Bild\n'
          '• Karo-Ass → 11 → „Daddy“ / „Titanic“',
    },
  ),
  LessonSlide(
    icon: Icons.bolt_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Автоматизм',
      AppLanguage.en: 'Automation',
      AppLanguage.de: 'Automatisierung',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Ты можешь комбинировать этот метод с категориями мастей. Главное — довести преобразование карты в образ до автоматизма.',
      AppLanguage.en:
          'You can combine this with suit categories. The key is to automate turning a card into an image.',
      AppLanguage.de:
          'Du kannst diese Methode mit den Farbkategorien kombinieren. Das Wichtigste ist, die Umwandlung von Karte zu Bild zu automatisieren.',
    },
    isCompletion: true,
  ),
];

const List<LessonSlide> _kCardsPaoSlides = <LessonSlide>[
  LessonSlide(
    icon: Icons.groups_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'PAO-система',
      AppLanguage.en: 'PAO system',
      AppLanguage.de: 'PAO-System',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'PAO (Person – Action – Object) — самая эффективная система для соревнований. Каждой карте присваивается человек, действие и объект.',
      AppLanguage.en:
          'PAO (Person – Action – Object) is the most effective system for competitions. Each card is assigned a person, an action, and an object.',
      AppLanguage.de:
          'PAO (Person – Action – Object) ist das effektivste System für Wettbewerbe. Jeder Karte werden Person, Handlung und Objekt zugeordnet.',
    },
  ),
  LessonSlide(
    icon: Icons.view_column_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Как собирать образ',
      AppLanguage.en: 'Building the image',
      AppLanguage.de: 'Das Bild bauen',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'При запоминании три карты образуют один сложный образ:\n'
          '• 1-я карта = Person\n'
          '• 2-я карта = Action\n'
          '• 3-я карта = Object',
      AppLanguage.en:
          'When memorizing, three cards form one complex image:\n'
          '• 1st card = Person\n'
          '• 2nd card = Action\n'
          '• 3rd card = Object',
      AppLanguage.de:
          'Beim Merken bilden drei Karten ein komplexes Bild:\n'
          '• 1. Karte = Person\n'
          '• 2. Karte = Action\n'
          '• 3. Karte = Object',
    },
  ),
  LessonSlide(
    icon: Icons.movie_creation_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Пример',
      AppLanguage.en: 'Example',
      AppLanguage.de: 'Beispiel',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Король червей (дедушка) + 8 бубен (Мадонна поёт) + 2 пик (Майкл Джордан с мячом) → дедушка поёт в баскетбольный мяч.',
      AppLanguage.en:
          'King of Hearts (Grandpa) + 8 of Diamonds (Madonna singing) + 2 of Spades (Michael Jordan with ball) → Grandpa is singing into a basketball.',
      AppLanguage.de:
          'Herzkönig (Opa) + 8 Karo (Madonna singt) + 2 Pik (Michael Jordan mit Ball) → Opa singt in einen Basketball.',
    },
  ),
  LessonSlide(
    icon: Icons.layers_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Преимущество',
      AppLanguage.en: 'The advantage',
      AppLanguage.de: 'Der Vorteil',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          '3 карты на одну локацию. Для всей колоды нужно всего 17–18 станций маршрута. Это позволяет запоминать колоду за минуту и быстрее.',
      AppLanguage.en:
          'Three cards per locus. A full deck needs only 17–18 stations. This allows memorizing a deck in under a minute.',
      AppLanguage.de:
          '3 Karten pro Station. Für ein ganzes Deck brauchst du nur 17–18 Orte auf deiner Route. So kannst du ein Deck in unter einer Minute merken.',
    },
    isCompletion: true,
  ),
];

const List<LessonSlide> _kCardsPracticeSpeedSlides = <LessonSlide>[
  LessonSlide(
    icon: Icons.playlist_play_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Практика и скорость',
      AppLanguage.en: 'Practice and speed',
      AppLanguage.de: 'Praxis und Tempo',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Алгоритм запоминания полной колоды:\n'
          '1. Подготовь маршрут из 17–20 знакомых локаций.\n'
          '2. Переворачивай карты по 3 штуки.\n'
          '3. Создавай один яркий, абсурдный, эмоциональный образ на каждой локации.\n'
          '4. Двигайся быстро.',
      AppLanguage.en:
          'Algorithm for memorizing a full deck:\n'
          '1. Prepare a journey with 17–20 familiar loci.\n'
          '2. Turn over cards in groups of three.\n'
          '3. Create one vivid, absurd, emotional image per locus.\n'
          '4. Move quickly.',
      AppLanguage.de:
          'Algorithmus zum Merken eines ganzen Decks:\n'
          '1. Bereite eine Route mit 17–20 vertrauten Orten vor.\n'
          '2. Drehe die Karten zu dreien um.\n'
          '3. Erstelle an jeder Station ein lebendiges, absurdes, emotionales Bild.\n'
          '4. Bewege dich schnell.',
    },
  ),
  LessonSlide(
    icon: Icons.timer_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Тренировка',
      AppLanguage.en: 'Training',
      AppLanguage.de: 'Training',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Начни с цели 5–10 минут на колоду, затем снижай время. Тренируйся ежедневно, веди дневник рекордов. Используй тренажёр в приложении.',
      AppLanguage.en:
          'Start with a goal of 5–10 minutes per deck, then reduce the time. Train daily and keep a record of your best times. Use the trainer in the app.',
      AppLanguage.de:
          'Starte mit dem Ziel 5–10 Minuten pro Deck, dann reduziere die Zeit. Trainiere täglich und führe ein Rekord-Tagebuch. Nutze den Trainer in der App.',
    },
  ),
  LessonSlide(
    icon: Icons.auto_awesome_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Цель',
      AppLanguage.en: 'Your goal',
      AppLanguage.de: 'Dein Ziel',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'С постоянной практикой запоминание колоды за минуту станет для тебя нормой. Это один из лучших способов прокачать мозг.',
      AppLanguage.en:
          'With consistent practice, memorizing a deck in under a minute will become normal for you. It is one of the best ways to train your brain.',
      AppLanguage.de:
          'Mit regelmäßiger Übung wird das Merken eines Decks in einer Minute für dich normal. Es ist eine der besten Möglichkeiten, dein Gehirn zu trainieren.',
    },
    isCompletion: true,
    trainerLaunch: LessonTrainerLaunchKind.academyCardsElements10,
    trainerCtaLabel: <AppLanguage, String>{
      AppLanguage.ru: 'В тренажёр · карты',
      AppLanguage.en: 'Open card trainer',
      AppLanguage.de: 'Zum Karten-Trainer',
    },
    trainerCtaSubtitle: <AppLanguage, String>{
      AppLanguage.ru: 'Тренируй скорость и точность на колоде',
      AppLanguage.en: 'Drill speed and accuracy with a deck',
      AppLanguage.de: 'Tempo und Genauigkeit mit dem Deck üben',
    },
  ),
];

class CardBasicsLessonScreen extends StatelessWidget {
  const CardBasicsLessonScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return LessonScreen(
      slides: _kCardBasicsSlides,
      onFinished: onFinished,
    );
  }
}

class CardsSuitCategoriesLessonScreen extends StatelessWidget {
  const CardsSuitCategoriesLessonScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return LessonScreen(
      slides: _kSuitCategoriesSlides,
      onFinished: onFinished,
      onTrainerLaunch: academyLaunchLessonTrainer,
    );
  }
}

class CardsMajorSystemLessonScreen extends StatelessWidget {
  const CardsMajorSystemLessonScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return LessonScreen(
      slides: _kMajorSystemCardsSlides,
      onFinished: onFinished,
    );
  }
}

class CardsPaoLessonScreen extends StatelessWidget {
  const CardsPaoLessonScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return LessonScreen(
      slides: _kCardsPaoSlides,
      onFinished: onFinished,
    );
  }
}

class CardsPracticeSpeedLessonScreen extends StatelessWidget {
  const CardsPracticeSpeedLessonScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return LessonScreen(
      slides: _kCardsPracticeSpeedSlides,
      onFinished: onFinished,
      onTrainerLaunch: academyLaunchLessonTrainer,
    );
  }
}

const Map<String, List<LessonSlide>> kCardsTrackBuiltinSlides =
    <String, List<LessonSlide>>{
  'disc_cards': _kCardBasicsSlides,
  'cards_suit_categories': _kSuitCategoriesSlides,
  'cards_major_system': _kMajorSystemCardsSlides,
  'cards_pao': _kCardsPaoSlides,
  'cards_practice_speed': _kCardsPracticeSpeedSlides,
};
