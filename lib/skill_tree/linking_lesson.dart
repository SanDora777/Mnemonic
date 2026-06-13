import 'package:flutter/material.dart';

import '../recovered_app.dart' show AppLanguage;
import 'lesson_framework.dart';

// Урок «Связка образов»: тексты из linking_lesson_all_languages.txt,
// символ за символом как у автора файла.

const Map<AppLanguage, String> _kLinkingLessonEmptyTitle = <AppLanguage, String>{
  AppLanguage.ru: '',
  AppLanguage.en: '',
  AppLanguage.de: '',
};

const List<LessonSlide> _kLinkingSlides = <LessonSlide>[
  LessonSlide(
    icon: Icons.link_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Связывание',
      AppLanguage.en: 'Linking',
      AppLanguage.de: 'Verknüpfung',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Отдельные образы — это только половина системы. Настоящая память начинается тогда, когда ты соединяешь их между собой. Мозг не хранит списки, он хранит цепочки событий. Если элементы не связаны, они распадаются и исчезают. Связывание — это процесс превращения отдельных образов в одну сцену. Например, если тебе нужно запомнить: яблоко, книга, собака, ты не держишь их отдельно.',
      AppLanguage.en:
          'Isolated images are only half of the system. Real memory begins when you connect them together. The brain does not store lists, it stores chains of events. If elements are not linked, they fall apart and disappear. Linking is the process of turning separate images into a single scene. For example, if you need to remember apple, book, dog, you do not keep them separately.',
      AppLanguage.de:
          'Einzelne Bilder sind nur die halbe Miete. Echtes Erinnern beginnt erst, wenn du sie miteinander verbindest. Das Gehirn speichert keine Listen, sondern Ereignisketten. Wenn Elemente nicht verknüpft sind, zerfallen sie und verschwinden. Verknüpfen ist der Prozess, einzelne Bilder in eine einzige Szene zu verwandeln. Wenn du dir zum Beispiel merken musst Apfel, Buch, Hund, dann behältst du sie nicht getrennt im Kopf.',
    },
  ),
  LessonSlide(
    icon: Icons.theater_comedy_rounded,
    title: _kLinkingLessonEmptyTitle,
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Ты создаёшь сцену: яблоко падает на книгу, книга раскрывается, и из неё выпрыгивает собака. Теперь это не три элемента, а одно событие.',
      AppLanguage.en:
          'You create a scene: an apple falls on a book, the book opens, and a dog jumps out of it. Now it is not three elements but one single event.',
      AppLanguage.de:
          'Du erschaffst eine Szene: Ein Apfel fällt auf ein Buch, das Buch klappt auf und ein Hund springt heraus. Jetzt sind es nicht mehr drei Elemente, sondern ein einziges Ereignis.',
    },
  ),
  LessonSlide(
    icon: Icons.bolt_rounded,
    title: _kLinkingLessonEmptyTitle,
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Очень важно понимать: просто поставить образы рядом недостаточно. Между ними должно быть действие. Контакт, движение, изменение, вот что создаёт сильную связь. Чем страннее и нелогичнее сцена, тем лучше она запоминается. Обычные ситуации мозг игнорирует, потому что он видит их каждый день.',
      AppLanguage.en:
          'It is very important to understand that simply putting images next to each other is not enough. There must be action between them. Contact, movement, change, this is what creates a strong bond. The weirder and more illogical the scene, the better it is remembered. The brain ignores ordinary situations because it sees them every day.',
      AppLanguage.de:
          'Es ist sehr wichtig zu verstehen, dass Bilder einfach nur nebeneinander zu stellen nicht ausreicht. Es muss eine Handlung zwischen ihnen stattfinden. Kontakt, Bewegung, Veränderung, das ist es, was eine starke Verbindung schafft. Je seltsamer und unlogischer die Szene ist, desto besser bleibt sie im Gedächtnis. Alltägliche Situationen ignoriert das Gehirn, weil es sie jeden Tag sieht.',
    },
  ),
  LessonSlide(
    icon: Icons.psychology_alt_outlined,
    title: _kLinkingLessonEmptyTitle,
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Но если происходит что-то абсурдное, мозг фиксирует это как важное. Ошибка новичков — делать связи слабыми, логичными или статичными.',
      AppLanguage.en:
          'But if something absurd happens, the brain marks it as important. A common beginner mistake is making links weak, logical, or static.',
      AppLanguage.de:
          'Aber wenn etwas Absurdes passiert, stuft das Gehirn dies als wichtig ein. Ein typischer Anfängerfehler ist es, Verbindungen zu schwach, zu logisch oder zu statisch zu gestalten.',
    },
  ),
  LessonSlide(
    icon: Icons.edit_note_rounded,
    title: _kLinkingLessonEmptyTitle,
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Задание: Представь кошку, молоко и велосипед. Не просто рядом, а в действии. Например: кошка едет на велосипеде и обливается молоком. Сделай сцену максимально странной и живой. Именно так создаётся память.',
      AppLanguage.en:
          'Task: Imagine a cat, milk, and a bicycle. Not just side by side, but in action. For example: a cat is riding a bicycle and getting splashed with milk. Make the scene as strange and vivid as possible. This is exactly how memory is created.',
      AppLanguage.de:
          'Übung: Stell dir eine Katze, Milch und ein Fahrrad vor. Nicht einfach nur nebeneinander, sondern in Aktion. Zum Beispiel: Eine Katze fährt Fahrrad und wird dabei mit Milch übergossen. Mach die Szene so seltsam und lebendig wie möglich. Genau so entstehen Erinnerungen.',
    },
    isCompletion: true,
  ),
];

class LinkingLessonScreen extends StatelessWidget {
  const LinkingLessonScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return LessonScreen(slides: _kLinkingSlides, onFinished: onFinished);
  }
}

const Map<String, List<LessonSlide>> kLinkingBuiltinSlides =
    <String, List<LessonSlide>>{
  'm3': _kLinkingSlides,
};
