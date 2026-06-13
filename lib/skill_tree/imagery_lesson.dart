import 'package:flutter/material.dart';

import '../recovered_app.dart' show AppLanguage;
import 'lesson_framework.dart';

// =====================================================================
//  УРОКИ блока «Образы» (узел m2 + 2 ветки).
//
//    ImageryLessonScreen        — главный урок: что такое образ, его
//                                 характеристики, ошибки новичков.
//    ImageryStrawberryTaskScreen — задание-практика: визуализация
//                                 пушистой клубники.
//    ImageryTypesLessonScreen   — справочник: типы образов
//                                 (объекты, персонажи, превращения,
//                                 символы) — отдельная мини-ветка.
//
//  Все три используют общий LessonScreen-каркас.
// =====================================================================

// ---------------------------------------------------------------------
//  1. ГЛАВНЫЙ УРОК «Образы» — теория.
// ---------------------------------------------------------------------

const List<LessonSlide> _kImagerySlides = <LessonSlide>[
  LessonSlide(
    icon: Icons.palette_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Что такое образ',
      AppLanguage.en: 'What is an image',
      AppLanguage.de: 'Was ist ein Bild',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Образ — это визуальное представление информации в голове, а не просто слово или идея. Слово не запоминается, пока оно не превращено в живую картинку.',
      AppLanguage.en:
          'An image is a visual representation of information in your mind — not just a word or an idea. A word isn\'t remembered until it\'s turned into a vivid picture.',
      AppLanguage.de:
          'Ein Bild ist eine visuelle Vorstellung von Informationen in deinem Kopf – nicht nur ein Wort oder eine Idee. Ein Wort bleibt nicht im Gedächtnis, solange es nicht in ein lebendiges Bild verwandelt wird.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Слово ≠ образ. Запоминается только образ.',
      AppLanguage.en: 'Word ≠ image. Only the image is remembered.',
      AppLanguage.de: 'Wort ≠ Bild. Nur das Bild bleibt haften.',
    },
  ),
  LessonSlide(
    icon: Icons.tag_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Информация должна иметь образ',
      AppLanguage.en: 'Information must become an image',
      AppLanguage.de: 'Information braucht ein Bild',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Для мозга число 38 — пыль, если оно не связано с чем-то важным. А вот при виде числа 67 у тебя появляются связи, которые ты вряд ли скоро забудешь. Информация без связи не держится.',
      AppLanguage.en:
          'To your brain, the number 38 is just dust unless it\'s linked to something meaningful. But when you see 67, associations appear that you won\'t forget soon. Information without connection doesn\'t stick.',
      AppLanguage.de:
          'Für dein Gehirn ist die Zahl 38 nur Staub, wenn sie nicht mit etwas Wichtigem verknüpft ist. Aber bei der Zahl 67 entstehen Verknüpfungen, die du so schnell nicht vergisst. Information ohne Verbindung hält nicht.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Образ оживает через связь.',
      AppLanguage.en: 'An image comes alive through connection.',
      AppLanguage.de: 'Ein Bild lebt durch Verbindung.',
    },
  ),
  LessonSlide(
    icon: Icons.flare_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Каким должен быть образ',
      AppLanguage.en: 'What a good image looks like',
      AppLanguage.de: 'Wie ein gutes Bild aussieht',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Хороший образ — яркий, большой и легко представляемый. Чем чётче картинка, тем глубже она впечатывается в память.',
      AppLanguage.en:
          'A good image is bright, large, and easy to visualize. The clearer the picture, the deeper it imprints into memory.',
      AppLanguage.de:
          'Ein gutes Bild ist hell, groß und leicht vorstellbar. Je klarer das Bild, desto tiefer prägt es sich ein.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Ярко · Крупно · Чётко.',
      AppLanguage.en: 'Bright · Big · Clear.',
      AppLanguage.de: 'Hell · Groß · Klar.',
    },
  ),
  LessonSlide(
    icon: Icons.diamond_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Три кита образа',
      AppLanguage.en: 'Three pillars of an image',
      AppLanguage.de: 'Die drei Säulen eines Bildes',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Движение делает образ живым. Эмоция придаёт ему значимость. Странность выделяет среди тысяч других. Эти три качества и превращают картинку в воспоминание.',
      AppLanguage.en:
          'Movement makes the image alive. Emotion makes it meaningful. Strangeness sets it apart from a thousand others. These three turn a picture into a memory.',
      AppLanguage.de:
          'Bewegung macht das Bild lebendig. Emotion verleiht ihm Bedeutung. Eigenartigkeit hebt es aus tausenden hervor. Diese drei verwandeln ein Bild in eine Erinnerung.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Движение · Эмоция · Странность.',
      AppLanguage.en: 'Movement · Emotion · Strangeness.',
      AppLanguage.de: 'Bewegung · Emotion · Eigenartigkeit.',
    },
  ),
  LessonSlide(
    icon: Icons.center_focus_strong_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Чем конкретнее — тем лучше',
      AppLanguage.en: 'The more specific, the better',
      AppLanguage.de: 'Je konkreter, desto besser',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Не просто «человек» — а злой человек, кричащий и машущий руками. Чем конкретнее образ, тем легче мозгу его удержать.',
      AppLanguage.en:
          'Not just "a person" — but an angry person, shouting and waving their arms. The more specific the image, the easier the brain holds it.',
      AppLanguage.de:
          'Nicht einfach „ein Mensch" – sondern ein wütender Mensch, der schreit und mit den Armen fuchtelt. Je konkreter das Bild, desto leichter behält es das Gehirn.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Детали закрепляют образ.',
      AppLanguage.en: 'Details lock the image in.',
      AppLanguage.de: 'Details verankern das Bild.',
    },
  ),
  LessonSlide(
    icon: Icons.warning_amber_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Ошибка новичков',
      AppLanguage.en: 'A beginner\'s mistake',
      AppLanguage.de: 'Anfängerfehler',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Делать образы слишком обычными или статичными. Скучный образ мозг не сохранит — он сразу же его сотрёт. Не бойся странности, наоборот — усиливай её.',
      AppLanguage.en:
          'Making images too ordinary or static. The brain won\'t keep a boring image — it erases it immediately. Don\'t fear strangeness — amplify it.',
      AppLanguage.de:
          'Bilder zu gewöhnlich oder statisch zu gestalten. Ein langweiliges Bild speichert das Gehirn nicht – es löscht es sofort. Hab keine Angst vor dem Eigenartigen, verstärke es.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Обычное — забывается.',
      AppLanguage.en: 'Ordinary gets forgotten.',
      AppLanguage.de: 'Gewöhnliches wird vergessen.',
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
          'Теперь ты знаешь, что делает образ сильным. Дальше — задание: создаём первый образ своими руками.',
      AppLanguage.en:
          'Now you know what makes an image strong. Next: a task — building your first image hands-on.',
      AppLanguage.de:
          'Jetzt weißt du, was ein Bild stark macht. Weiter geht\'s mit einer Übung: dein erstes Bild selbst erschaffen.',
    },
    isCompletion: true,
  ),
];

class ImageryLessonScreen extends StatelessWidget {
  const ImageryLessonScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return LessonScreen(slides: _kImagerySlides, onFinished: onFinished);
  }
}

// ---------------------------------------------------------------------
//  2. ЗАДАНИЕ · КЛУБНИКА — практика визуализации.
// ---------------------------------------------------------------------

const List<LessonSlide> _kStrawberryTaskSlides = <LessonSlide>[
  LessonSlide(
    icon: Icons.visibility_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Задание · Образ клубники',
      AppLanguage.en: 'Task · The strawberry image',
      AppLanguage.de: 'Übung · Das Erdbeer-Bild',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Закрой глаза или оставь открытыми — как удобно. Сейчас ты создашь свой первый яркий, осязаемый образ.',
      AppLanguage.en:
          'Close your eyes or keep them open — whichever feels easier. You\'re about to build your first vivid, tangible image.',
      AppLanguage.de:
          'Schließe die Augen oder lass sie offen – wie es dir leichter fällt. Jetzt erschaffst du dein erstes lebendiges, greifbares Bild.',
    },
  ),
  LessonSlide(
    icon: Icons.pan_tool_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Большая клубника в руках',
      AppLanguage.en: 'A big strawberry in your hands',
      AppLanguage.de: 'Eine große Erdbeere in deinen Händen',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Представь, что ты держишь в руках большую, спелую клубнику. Чувствуешь её вес. Видишь её ярко-красный цвет, глянцевую кожицу, маленькие жёлтые семечки.',
      AppLanguage.en:
          'Imagine holding a big, ripe strawberry in your hands. Feel its weight. See its bright red color, the glossy skin, the tiny yellow seeds.',
      AppLanguage.de:
          'Stell dir vor, du hältst eine große, reife Erdbeere in deinen Händen. Spüre ihr Gewicht. Sieh ihre leuchtend rote Farbe, die glänzende Haut, die kleinen gelben Kerne.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Тяжёлая. Красная. Реальная.',
      AppLanguage.en: 'Heavy. Red. Real.',
      AppLanguage.de: 'Schwer. Rot. Echt.',
    },
  ),
  LessonSlide(
    icon: Icons.air_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Запах и вкус',
      AppLanguage.en: 'Smell and taste',
      AppLanguage.de: 'Geruch und Geschmack',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Поднеси клубнику к лицу. Ощути её сладкий запах. А теперь попробуй её на вкус — сочный, чуть сладкий, чуть кислый. Получилось?',
      AppLanguage.en:
          'Bring the strawberry close to your face. Smell its sweet scent. Now taste it — juicy, a little sweet, a little tart. Got it?',
      AppLanguage.de:
          'Halte die Erdbeere ans Gesicht. Nimm ihren süßen Duft wahr. Probiere jetzt – saftig, etwas süß, etwas säuerlich. Hat es geklappt?',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Запах · Вкус — два чувства уже работают.',
      AppLanguage.en: 'Smell · Taste — two senses already engaged.',
      AppLanguage.de: 'Geruch · Geschmack — zwei Sinne sind schon dabei.',
    },
  ),
  LessonSlide(
    icon: Icons.auto_awesome,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'А теперь — превращение',
      AppLanguage.en: 'And now — the twist',
      AppLanguage.de: 'Und jetzt — die Verwandlung',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Клубника в твоих руках становится мягкой и пушистой, как мех. Шерсть лёгкая, тёплая, чуть щекочет ладонь. Но цвет — всё тот же ярко-красный.',
      AppLanguage.en:
          'The strawberry in your hands turns soft and fluffy — like fur. The fur is light, warm, tickles your palm. But the color stays the same bright red.',
      AppLanguage.de:
          'Die Erdbeere in deinen Händen wird weich und flauschig — wie Fell. Das Fell ist leicht, warm, kitzelt deine Handfläche. Doch die Farbe bleibt das leuchtende Rot.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Странность врезается в память.',
      AppLanguage.en: 'Strangeness carves into memory.',
      AppLanguage.de: 'Eigenartigkeit gräbt sich ein.',
    },
  ),
  LessonSlide(
    icon: Icons.touch_app_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Почувствуй её',
      AppLanguage.en: 'Feel it',
      AppLanguage.de: 'Spüre sie',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Сожми клубнику в ладони — пушистая шерсть мягко поддаётся. Тёплая. Яркий красный сияет, как маленькое солнце. Запомни этот момент.',
      AppLanguage.en:
          'Squeeze the strawberry in your palm — the fluffy fur gently gives way. Warm. The bright red glows like a tiny sun. Remember this moment.',
      AppLanguage.de:
          'Drücke die Erdbeere in deiner Handfläche – das flauschige Fell gibt sanft nach. Warm. Das leuchtende Rot glüht wie eine kleine Sonne. Merk dir diesen Moment.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Тактильность · Цвет · Тепло.',
      AppLanguage.en: 'Touch · Color · Warmth.',
      AppLanguage.de: 'Tasten · Farbe · Wärme.',
    },
  ),
  LessonSlide(
    icon: Icons.psychology_alt_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Это и есть образ',
      AppLanguage.en: 'This is what an image is',
      AppLanguage.de: 'Das ist ein Bild',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'То, что ты только что создал — образ. Не слово, не идея. Живая, странная, многосенсорная картинка. Именно такие мозг хранит сам, без усилий.',
      AppLanguage.en:
          'What you just built — that\'s an image. Not a word, not an idea. A vivid, strange, multi-sensory picture. Exactly the kind your brain stores effortlessly.',
      AppLanguage.de:
          'Was du gerade erschaffen hast – das ist ein Bild. Kein Wort, keine Idee. Ein lebendiges, eigenartiges, multisensorisches Bild. Genau solche speichert dein Gehirn von selbst.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Цель: превращать любую информацию в образ.',
      AppLanguage.en: 'Goal: turn any information into an image.',
      AppLanguage.de: 'Ziel: jede Information in ein Bild verwandeln.',
    },
  ),
  LessonSlide(
    icon: Icons.workspace_premium_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Задание выполнено',
      AppLanguage.en: 'Task complete',
      AppLanguage.de: 'Übung abgeschlossen',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Теперь у тебя в голове живёт пушистая красная клубника — и ты её не забудешь. Ты только что использовал мнемотехнику.',
      AppLanguage.en:
          'A fluffy red strawberry now lives in your mind — and you won\'t forget it. You\'ve just used mnemonics.',
      AppLanguage.de:
          'Eine flauschige rote Erdbeere lebt jetzt in deinem Kopf – und du wirst sie nicht vergessen. Du hast gerade Mnemotechnik angewendet.',
    },
    isCompletion: true,
  ),
];

class ImageryStrawberryTaskScreen extends StatelessWidget {
  const ImageryStrawberryTaskScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return LessonScreen(
      slides: _kStrawberryTaskSlides,
      continueLabel: <AppLanguage, String>{
        AppLanguage.ru: 'Дальше',
        AppLanguage.en: 'Continue',
        AppLanguage.de: 'Weiter',
      },
      finishLabel: <AppLanguage, String>{
        AppLanguage.ru: 'Готово',
        AppLanguage.en: 'Done',
        AppLanguage.de: 'Fertig',
      },
      onFinished: onFinished,
    );
  }
}

// ---------------------------------------------------------------------
//  3. ТИПЫ ОБРАЗОВ — отдельная справочная мини-ветка.
// ---------------------------------------------------------------------

const List<LessonSlide> _kImageTypesSlides = <LessonSlide>[
  LessonSlide(
    icon: Icons.category_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Типы образов',
      AppLanguage.en: 'Types of images',
      AppLanguage.de: 'Arten von Bildern',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Образы бывают разные — каждый со своей силой. Мнемотехника использует их все. Знать типы — значит выбрать инструмент под задачу.',
      AppLanguage.en:
          'Images come in different kinds — each with its own strength. Mnemonics uses them all. Knowing the types means choosing the right tool.',
      AppLanguage.de:
          'Bilder gibt es in verschiedenen Arten – jede mit eigener Stärke. Mnemotechnik nutzt sie alle. Die Arten zu kennen heißt, das richtige Werkzeug zu wählen.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Знать тип — выбрать инструмент.',
      AppLanguage.en: 'Know the type — pick the tool.',
      AppLanguage.de: 'Art kennen — Werkzeug wählen.',
    },
  ),
  LessonSlide(
    icon: Icons.emoji_objects_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Реальные объекты',
      AppLanguage.en: 'Real objects',
      AppLanguage.de: 'Reale Objekte',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Самый простой и самый сильный тип — то, что ты можешь потрогать. Кружка, дерево, камень, ключ. Мозг знает их с рождения, поэтому не сопротивляется.',
      AppLanguage.en:
          'The simplest and strongest type — things you can touch. A mug, a tree, a stone, a key. The brain knows them by heart and doesn\'t resist.',
      AppLanguage.de:
          'Die einfachste und stärkste Art — Dinge, die du anfassen kannst. Eine Tasse, ein Baum, ein Stein, ein Schlüssel. Das Gehirn kennt sie von Geburt an und wehrt sich nicht.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Конкретное запоминается легче.',
      AppLanguage.en: 'Concrete is easier to remember.',
      AppLanguage.de: 'Konkretes merkt man leichter.',
    },
  ),
  LessonSlide(
    icon: Icons.person_outline_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Персонажи',
      AppLanguage.en: 'Characters',
      AppLanguage.de: 'Charaktere',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Человек или существо со своими эмоциями и движением. Эмоция — мощный крючок для памяти, поэтому персонажи запоминаются глубже статичных вещей.',
      AppLanguage.en:
          'A person or creature with their own emotions and movement. Emotion is a powerful memory hook, so characters stick deeper than static things.',
      AppLanguage.de:
          'Eine Person oder ein Wesen mit eigenen Emotionen und Bewegung. Emotion ist ein starker Erinnerungshaken — Charaktere bleiben tiefer hängen als statische Dinge.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Лицо запоминается лучше слова.',
      AppLanguage.en: 'A face is remembered better than a word.',
      AppLanguage.de: 'Ein Gesicht bleibt besser als ein Wort.',
    },
  ),
  LessonSlide(
    icon: Icons.transform_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Абстрактные превращения',
      AppLanguage.en: 'Abstract transformations',
      AppLanguage.de: 'Abstrakte Verwandlungen',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Когда обычное превращается в странное: дом тает как воск, гора становится медузой, телефон оживает и хрюкает. Странность даёт прочность памяти.',
      AppLanguage.en:
          'When the ordinary turns strange: a house melts like wax, a mountain becomes a jellyfish, a phone comes alive and oinks. Strangeness gives memory its grip.',
      AppLanguage.de:
          'Wenn das Gewöhnliche eigenartig wird: ein Haus zerfließt wie Wachs, ein Berg wird zur Qualle, ein Telefon wird lebendig und grunzt. Eigenartigkeit gibt Halt.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Странное держится крепче.',
      AppLanguage.en: 'Strange holds tighter.',
      AppLanguage.de: 'Eigenartiges hält fester.',
    },
  ),
  LessonSlide(
    icon: Icons.brightness_auto_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Символы',
      AppLanguage.en: 'Symbols',
      AppLanguage.de: 'Symbole',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Сердце, молния, корона, череп. Один знак — много смысла. Полезно для абстрактных понятий, которые сложно нарисовать напрямую.',
      AppLanguage.en:
          'A heart, a lightning bolt, a crown, a skull. One symbol — lots of meaning. Useful for abstract concepts that are hard to draw directly.',
      AppLanguage.de:
          'Ein Herz, ein Blitz, eine Krone, ein Totenkopf. Ein Zeichen — viel Bedeutung. Nützlich für abstrakte Begriffe, die schwer direkt zu zeichnen sind.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Символ = сжатый смысл.',
      AppLanguage.en: 'Symbol = compressed meaning.',
      AppLanguage.de: 'Symbol = verdichtete Bedeutung.',
    },
  ),
  LessonSlide(
    icon: Icons.tune_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Какой выбрать',
      AppLanguage.en: 'Which one to pick',
      AppLanguage.de: 'Welche Art wählen',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Чем ярче и страннее — тем лучше. Но самое важное: образ должен быть твой. Тот, что вызывает эмоцию именно у тебя — даже если другим он покажется странным.',
      AppLanguage.en:
          'The brighter and stranger, the better. But the key thing: the image must be yours. The one that stirs emotion in you — even if others find it odd.',
      AppLanguage.de:
          'Je heller und eigenartiger, desto besser. Wichtig: das Bild muss deins sein. Eines, das in dir Emotion weckt – auch wenn andere es seltsam finden.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Твой образ — твой ключ.',
      AppLanguage.en: 'Your image — your key.',
      AppLanguage.de: 'Dein Bild — dein Schlüssel.',
    },
  ),
  LessonSlide(
    icon: Icons.workspace_premium_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Готово',
      AppLanguage.en: 'Done',
      AppLanguage.de: 'Geschafft',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Теперь ты знаешь, какие бывают образы. Возвращайся сюда, когда захочешь подобрать тип под задачу.',
      AppLanguage.en:
          'Now you know the kinds of images. Come back any time to pick the type that fits the task.',
      AppLanguage.de:
          'Jetzt kennst du die Arten von Bildern. Komm jederzeit zurück, um die passende Art für deine Aufgabe zu wählen.',
    },
    isCompletion: true,
  ),
];

class ImageryTypesLessonScreen extends StatelessWidget {
  const ImageryTypesLessonScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return LessonScreen(slides: _kImageTypesSlides, onFinished: onFinished);
  }
}

const Map<String, List<LessonSlide>> kImageryBuiltinSlides =
    <String, List<LessonSlide>>{
  'm2': _kImagerySlides,
  'task_strawberry': _kStrawberryTaskSlides,
  'image_types': _kImageTypesSlides,
};
