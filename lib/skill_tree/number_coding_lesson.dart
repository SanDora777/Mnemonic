import 'package:flutter/material.dart';

import '../recovered_app.dart' show AppLanguage;
import 'academy_training_launcher.dart';
import 'lesson_framework.dart';

const List<LessonSlide> _kNumberCodingSlides = <LessonSlide>[
  LessonSlide(
    icon: Icons.dialpad_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Система кодирования чисел',
      AppLanguage.en: 'Number Coding System',
      AppLanguage.de: 'Zahlencodierungssystem',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Основа всей числовой мнемотехники — кодировка цифр. Каждая цифра получает свой постоянный образ или символ. Ты уже знаешь коды для 0 до 9. Именно это превращает сухие числа в визуальный язык памяти.',
      AppLanguage.en:
          'The foundation of all numerical mnemonics is the coding of digits. Each digit is assigned its own permanent image or symbol. You already know the codes for 0 to 9. This is exactly what turns dry numbers into the visual language of memory.',
      AppLanguage.de:
          'Die Basis der gesamten Zahlen-Mnemotechnik ist die Kodierung von Ziffern. Jede Ziffer bekommt ihr eigenes festes Bild oder Symbol. Du kennst bereits die Codes für 0 bis 9. Genau das verwandelt trockene Zahlen in die visuelle Sprache des Gedächtnisses.',
    },
  ),
  LessonSlide(
    icon: Icons.lock_clock_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Главное правило системы кодирования — стабильность. Одна цифра всегда должна означать одно и то же. Если сегодня 4 — это стул, а завтра меч, мозг начнёт путаться. Когда система закрепляется, кодировка происходит автоматически. Ты больше не думаешь о цифрах — сразу видишь образы.',
      AppLanguage.en:
          'The main rule of the coding system is stability. One digit must always mean the same thing. If today 4 is a chair and tomorrow it is a sword, the brain will start to get confused. Once the system is fixed, coding begins to happen automatically. You no longer think about numbers—you immediately see images.',
      AppLanguage.de:
          'Die wichtigste Regel des Kodierungssystems ist Stabilität. Eine Ziffer muss immer dasselbe bedeuten. Wenn heute die 4 ein Stuhl ist und morgen ein Schwert, fängt das Gehirn an, durcheinanderzukommen. Wenn sich das System festigt, geschieht die Kodierung automatisch. Du denkst nicht mehr an Zahlen — du siehst sofort Bilder.',
    },
  ),
  LessonSlide(
    icon: Icons.speed_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Более продвинутые мнемонисты создают образы для 00 до 99, 000 до 999 и даже 0000 до 9999 — это даёт больше скорости при отработке кодов до автоматизма. Главное, чтобы образы были простыми, яркими и мгновенно узнаваемыми лично для тебя.',
      AppLanguage.en:
          'More advanced mnemonists create images for 00 to 99, 000 to 999, and even 0000 to 9999, which gives them more speed as they master the codes to the point of being automatic. The most important thing is that the images are simple, bright, and instantly recognizable to you personally.',
      AppLanguage.de:
          'Fortgeschrittene Mnemoniker erstellen Bilder für 00 bis 99, 000 bis 999 und sogar 0000 bis 9999 — das verleiht mehr Geschwindigkeit, wenn sie die Codes bis zum Automatismus beherrschen. Das Wichtigste ist, dass die Bilder einfach, lebendig und für dich persönlich sofort erkennbar sind.',
    },
  ),
  LessonSlide(
    icon: Icons.auto_awesome_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Со временем цифры перестают быть числами: они становятся объектами, персонажами и действиями. Именно это позволяет работать с огромными последовательностями почти без напряжения.',
      AppLanguage.en:
          'Over time, digits stop being numbers—they become objects, characters, and actions. This is exactly what allows mnemonists to work with massive sequences with almost no effort.',
      AppLanguage.de:
          'Mit der Zeit hören Ziffern auf, Zahlen zu sein — sie werden zu Objekten, Figuren und Handlungen. Genau das ermöglicht es, mit riesigen Folgen fast ohne Anstrengung zu arbeiten.',
    },
  ),
  LessonSlide(
    icon: Icons.swap_horiz_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Два главных процесса: кодировка — превращение числа в образ; декодировка — обратный процесс, когда ты видишь образ и мгновенно понимаешь цифру. На первых этапах декодировка может быть медленной — это нормально: мозг ещё не привык к новому «языку».',
      AppLanguage.en:
          'There are two main processes: coding turns a number into an image; decoding is the reverse— you see an image and instantly understand the digit. Early on, decoding can be slow. That’s normal—the brain is not yet used to the new language.',
      AppLanguage.de:
          'Zwei Hauptprozesse: Kodierung verwandelt eine Zahl in ein Bild; Dekodierung ist der umgekehrte Vorgang — du siehst ein Bild und verstehst sofort die Ziffer. Am Anfang kann Dekodierung langsam sein — das ist normal; das Gehirn gewöhnt sich erst an die neue Sprache.',
    },
  ),
  LessonSlide(
    icon: Icons.trending_up_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Со временем кодировка и декодировка начинают происходить автоматически, почти как чтение текста.',
      AppLanguage.en:
          'Over time, coding and decoding start to happen automatically—almost like reading text.',
      AppLanguage.de:
          'Mit der Zeit geschehen Kodierung und Dekodierung automatisch — fast wie das Lesen von Text.',
    },
  ),
  LessonSlide(
    icon: Icons.fitness_center_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Практика',
      AppLanguage.en: 'Practice',
      AppLanguage.de: 'Übung',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Теперь самое интересное. Запомни свои первые цифры с помощью мнемотехники. Не смотри на время, делай всё не спеша, ша ша ша, черемша. По началу будет трудно, что абсолютно нормально.',
      AppLanguage.en:
          'Now for the most interesting part. Remember your first digits using mnemonics. Don\'t look at the time, take your time. It will be difficult at first, which is absolutely normal.',
      AppLanguage.de:
          'Jetzt kommt der interessanteste Teil. Merke dir deine ersten Zahlen mithilfe von Mnemotechnik. Schau nicht auf die Uhr, mach alles ganz in Ruhe. Am Anfang wird es schwierig sein, was absolut normal ist.',
    },
    isCompletion: true,
    trainerLaunch: LessonTrainerLaunchKind.academyNumbers09Elements15,
    trainerCtaLabel: <AppLanguage, String>{
      AppLanguage.ru: 'Тренажёр · 15 цифр (0–9)',
      AppLanguage.en: 'Trainer · 15 digits (0–9)',
      AppLanguage.de: 'Trainer · 15 Ziffern (0–9)',
    },
    trainerCtaSubtitle: <AppLanguage, String>{
      AppLanguage.ru: 'Откроется тренажёр памяти · диапазон 0–9 · 15 элементов',
      AppLanguage.en: 'Opens the memory trainer · range 0–9 · 15 items',
      AppLanguage.de: 'Öffnet den Gedächtnistrainer · Bereich 0–9 · 15 Elemente',
    },
  ),
];

class NumberCodingSystemLessonScreen extends StatelessWidget {
  const NumberCodingSystemLessonScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return LessonScreen(
      slides: _kNumberCodingSlides,
      onFinished: onFinished,
      onTrainerLaunch: academyLaunchLessonTrainer,
    );
  }
}

const Map<String, List<LessonSlide>> kNumberCodingBuiltinSlides =
    <String, List<LessonSlide>>{
  'disc_numbers': _kNumberCodingSlides,
};
