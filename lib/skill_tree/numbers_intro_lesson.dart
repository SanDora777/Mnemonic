import 'package:flutter/material.dart';

import '../recovered_app.dart' show AppLanguage;
import 'academy_training_launcher.dart';
import 'lesson_framework.dart';

// Урок «Введение в числа» (узел numbers_intro) — контент из lesson_6.
const List<LessonSlide> _kNumbersIntroSlides = <LessonSlide>[
  LessonSlide(
    icon: Icons.calculate_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Введение в числа',
      AppLanguage.en: 'Introduction to Numbers',
      AppLanguage.de: 'Einführung in die Zahlen',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Для обычного мозга числа почти ничего не значат. Если тебе показать слово «тигр», мозг сразу создаёт картинку. Но если показать число 47, внутри головы не возникает почти ничего. Именно поэтому люди так плохо запоминают длинные числовые последовательности. Мозг не любит абстракции. Он любит образы, объекты, движение и эмоции. Мнемотехника решает эту проблему через кодирование. Ты превращаешь числа в визуальные образы, а затем работаешь с ними так же, как с обычными объектами.',
      AppLanguage.en:
          'For a regular brain, numbers mean almost nothing. If you are shown the word «tiger», the brain immediately creates a picture. But if you are shown the number 47, almost nothing arises inside your head. This is why people are so bad at remembering long numerical sequences. The brain does not like abstractions. It loves images, objects, movement, and emotions. Mnemonics solves this problem through coding. You turn numbers into visual images and then work with them just like regular objects.',
      AppLanguage.de:
          'Für ein gewöhnliches Gehirn bedeuten Zahlen fast nichts. Wenn man dir das Wort „Tiger“ zeigt, erzeugt das Gehirn sofort ein Bild. Aber wenn man dir die Zahl 47 zeigt, entsteht in deinem Kopf fast gar nichts. Deshalb können sich Menschen lange Zahlenfolgen so schlecht merken. Das Gehirn mag keine Abstraktionen. Es liebt Bilder, Objekte, Bewegung und Emotionen. Die Mnemonik löst dieses Problem durch Kodierung. Du verwandelst Zahlen in visuelle Bilder und arbeitest dann mit ihnen wie mit gewöhnlichen Objekten.',
    },
  ),
  LessonSlide(
    icon: Icons.psychology_alt_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Самое важное понять: профессиональные мнемонисты не запоминают сами цифры. Они запоминают сцены и образы, в которые цифры были превращены. Число становится не символом, а объектом. Например, если 1 — свеча, а 7 — коса, то 17 уже превращается в образ. Именно поэтому память начинает работать в разы быстрее.',
      AppLanguage.en:
          'The most important thing to understand: professional mnemonists do not memorize the digits themselves. They memorize scenes and images into which the digits have been transformed. A number becomes not a symbol, but an object. For example, if 1 is a candle and 7 is a scythe, then 17 already turns into an image. This is precisely why memory starts working many times faster.',
      AppLanguage.de:
          'Das Wichtigste ist zu verstehen: Profi-Mnemoniker merken sich nicht die Ziffern selbst. Sie merken sich Szenen und Bilder, in die die Ziffern verwandelt wurden. Eine Zahl wird nicht zum Symbol, sondern zum Objekt. Wenn zum Beispiel 1 eine Kerze und 7 eine Sense ist, dann verwandelt sich 17 bereits in ein Bild. Genau deshalb beginnt das Gedächtnis um ein Vielfaches schneller zu arbeiten.',
    },
  ),
  LessonSlide(
    icon: Icons.auto_stories_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Твой мозг не создан для хранения цифр. Но он прекрасно хранит истории, пространство и визуальные сцены. Поэтому вся система чисел в мнемотехнике строится на переводе информации с языка цифр на язык образов.',
      AppLanguage.en:
          'Your brain is not designed to store digits. But it is excellent at storing stories, space, and visual scenes. Therefore, the entire system of numbers in mnemonics is built on translating information from the language of digits to the language of images.',
      AppLanguage.de:
          'Dein Gehirn ist nicht dafür gemacht, Ziffern zu speichern. Aber es speichert hervorragend Geschichten, Raum und visuelle Szenen. Daher basiert das gesamte Zahlensystem in der Mnemonik darauf, Informationen aus der Sprache der Zahlen in die Sprache der Bilder zu übersetzen.',
    },
  ),
  LessonSlide(
    icon: Icons.edit_note_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Задание',
      AppLanguage.en: 'Task',
      AppLanguage.de: 'Aufgabe',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Теперь тебе нужно запомнить свои первые образы для чисел.',
      AppLanguage.en:
          'Now you need to remember your first images for the numbers.',
      AppLanguage.de:
          'Jetzt musst du dir deine ersten Bilder für die Zahlen merken.',
    },
    isCompletion: true,
    trainerLaunch: LessonTrainerLaunchKind.academyNumberCodes09,
    trainerCtaLabel: <AppLanguage, String>{
      AppLanguage.ru: 'Коды 0–9',
      AppLanguage.en: 'Digits 0–9',
      AppLanguage.de: 'Ziffern 0–9',
    },
    trainerCtaSubtitle: <AppLanguage, String>{
      AppLanguage.ru: 'Справочник образов для цифр 0–9',
      AppLanguage.en: 'Reference list of images for digits 0–9',
      AppLanguage.de: 'Referenzliste der Bilder für Ziffern 0–9',
    },
  ),
];

class NumbersIntroLessonScreen extends StatelessWidget {
  const NumbersIntroLessonScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return LessonScreen(
      slides: _kNumbersIntroSlides,
      onFinished: onFinished,
      onTrainerLaunch: academyLaunchLessonTrainer,
    );
  }
}

const Map<String, List<LessonSlide>> kNumbersIntroBuiltinSlides =
    <String, List<LessonSlide>>{
  'numbers_intro': _kNumbersIntroSlides,
};
