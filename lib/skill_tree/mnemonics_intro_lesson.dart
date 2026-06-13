import 'package:flutter/material.dart';

import '../recovered_app.dart' show AppLanguage;
import 'lesson_framework.dart';

// =====================================================================
//  УРОК «Что такое мнемотехника» (узел m1).
//
//  Используем общий LessonScreen-каркас. Здесь только контент.
// =====================================================================

const List<LessonSlide> _kIntroSlides = <LessonSlide>[
  LessonSlide(
    icon: Icons.psychology_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Что такое мнемотехника',
      AppLanguage.en: 'What is mnemonics',
      AppLanguage.de: 'Was ist Mnemotechnik',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Система методов, которая позволяет запоминать через образы — а не через монотонное повторение. Обычное запоминание — это попытка удержать информацию силой. Но мозг работает иначе.',
      AppLanguage.en:
          'A system of methods that lets you memorize through images — not through monotonous repetition. Standard memorization tries to hold information by force. But your brain works differently.',
      AppLanguage.de:
          'Ein System von Methoden, mit dem du dir Informationen durch Bilder merkst – nicht durch monotones Wiederholen. Normales Auswendiglernen versucht, Informationen mit Gewalt festzuhalten. Doch so funktioniert dein Gehirn nicht.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru:
          'Мозг помнит только то, что важно, необычно или эмоционально.',
      AppLanguage.en:
          'The brain only remembers what feels important, unusual, or emotional.',
      AppLanguage.de:
          'Das Gehirn speichert nur, was ihm wichtig, ungewöhnlich oder emotional erscheint.',
    },
  ),
  LessonSlide(
    icon: Icons.spa_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Пример из детства',
      AppLanguage.en: 'A childhood memory',
      AppLanguage.de: 'Eine Kindheitserinnerung',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Ты не помнишь, что учил вчера. Не помнишь, что ел на завтрак три дня назад. Но ты помнишь, как стоял в детстве летом на улице — тёплый воздух, запах пыли, голоса вдали.',
      AppLanguage.en:
          'You don\'t remember what you studied yesterday. You don\'t remember breakfast three days ago. But you remember standing outside as a child in summer — warm air, the smell of dust, voices in the distance.',
      AppLanguage.de:
          'Du weißt nicht mehr, was du gestern gelernt hast. Nicht, was du vor drei Tagen gefrühstückt hast. Aber du erinnerst dich, wie du als Kind im Sommer draußen standest – warme Luft, Staubgeruch, ferne Stimmen.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Память — про то, что зацепило.',
      AppLanguage.en: 'Memory is about what hooks you.',
      AppLanguage.de: 'Gedächtnis ist das, was dich berührt.',
    },
  ),
  LessonSlide(
    icon: Icons.palette_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Образы — язык мозга',
      AppLanguage.en: 'Images: the brain\'s language',
      AppLanguage.de: 'Bilder: die Sprache des Gehirns',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Превращая информацию в образ, ты делаешь её понятной для мозга. Миллионы лет эволюции учили тебя помнить эмоции и объекты — а не чернила на бумаге. Память работает через ассоциации.',
      AppLanguage.en:
          'When you turn information into an image, you make it readable for your brain. Millions of years of evolution taught you to remember emotions and objects — not ink on paper. Memory works through associations.',
      AppLanguage.de:
          'Wenn du Informationen in ein Bild verwandelst, machst du sie für dein Gehirn verständlich. Millionen Jahre Evolution haben dich gelehrt, Emotionen und Objekte zu speichern – nicht Tinte auf Papier. Gedächtnis arbeitet über Assoziationen.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Каждая мысль вызывает следующую.',
      AppLanguage.en: 'Every thought triggers the next.',
      AppLanguage.de: 'Jeder Gedanke ruft den nächsten hervor.',
    },
  ),
  LessonSlide(
    icon: Icons.auto_delete_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Почему мы забываем',
      AppLanguage.en: 'Why we forget',
      AppLanguage.de: 'Warum wir vergessen',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Мы забываем не потому, что мало старались. Мы забываем, потому что информация была слабой — без образа, без эмоции, без связи. Мозг автоматически стирает всё, что ему не нужно.',
      AppLanguage.en:
          'We forget not because we didn\'t try hard enough. We forget because the information was weak — no image, no emotion, no connection. The brain automatically erases what it doesn\'t need.',
      AppLanguage.de:
          'Wir vergessen nicht, weil wir uns zu wenig anstrengen. Wir vergessen, weil die Information schwach war – ohne Bild, ohne Emotion, ohne Verbindung. Das Gehirn löscht automatisch alles, was es nicht braucht.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Без связи мозг не удержит ничего.',
      AppLanguage.en: 'Without connection, the brain holds nothing.',
      AppLanguage.de: 'Ohne Verbindung hält das Gehirn nichts.',
    },
  ),
  LessonSlide(
    icon: Icons.auto_awesome_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Сила образов',
      AppLanguage.en: 'The power of images',
      AppLanguage.de: 'Die Kraft der Bilder',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Визуальная информация обрабатывается быстрее и глубже, чем текст. Текст не материален — мозгу труднее его уловить. Чем ярче, страннее и динамичнее образ — тем прочнее он закрепляется.',
      AppLanguage.en:
          'Visual information is processed faster and deeper than text. Text isn\'t tangible — harder for the brain to grasp. The brighter, weirder, and more dynamic the image, the stronger it locks in.',
      AppLanguage.de:
          'Visuelle Informationen werden schneller und tiefer verarbeitet als Text. Text ist nicht greifbar – das Gehirn tut sich schwerer damit. Je lebendiger, seltsamer und dynamischer ein Bild ist, desto fester brennt es sich ein.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Ярче — значит сильнее.',
      AppLanguage.en: 'Brighter means stronger.',
      AppLanguage.de: 'Lebendiger heißt stärker.',
    },
  ),
  LessonSlide(
    icon: Icons.tune_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Управляй памятью',
      AppLanguage.en: 'Take control of memory',
      AppLanguage.de: 'Steuere dein Gedächtnis',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Цель мнемотехники — научиться управлять памятью самому. Не запомнить силой, а создать такую форму информации, которую мозг сам захочет сохранить.',
      AppLanguage.en:
          'The goal of mnemonics is to control your memory yourself. Not to force memorization, but to create a form of information that your brain wants to keep.',
      AppLanguage.de:
          'Das Ziel der Mnemotechnik ist es, dein Gedächtnis selbst zu steuern. Nicht etwas mit Mühe einzuhämmern, sondern eine Form von Information zu erschaffen, die dein Gehirn von sich aus behalten will.',
    },
    highlight: <AppLanguage, String>{
      AppLanguage.ru: 'Не запоминай. Создавай.',
      AppLanguage.en: 'Don\'t memorize. Create.',
      AppLanguage.de: 'Lerne nicht. Erschaffe.',
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
          'Теперь ты понимаешь, как работает память. Дальше — практика: учимся создавать живые образы.',
      AppLanguage.en:
          'Now you understand how memory works. Next: practice — learning to create vivid images.',
      AppLanguage.de:
          'Jetzt verstehst du, wie das Gedächtnis funktioniert. Weiter geht\'s mit der Praxis: lebendige Bilder erschaffen.',
    },
    isCompletion: true,
  ),
];

class MnemonicsIntroLessonScreen extends StatelessWidget {
  const MnemonicsIntroLessonScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return LessonScreen(slides: _kIntroSlides, onFinished: onFinished);
  }
}

const Map<String, List<LessonSlide>> kMnemonicsIntroBuiltinSlides =
    <String, List<LessonSlide>>{
  'm1': _kIntroSlides,
};
