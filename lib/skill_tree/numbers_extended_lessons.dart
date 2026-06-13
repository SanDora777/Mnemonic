import 'package:flutter/material.dart';

import '../recovered_app.dart' show AppLanguage;
import 'academy_training_launcher.dart';
import 'lesson_framework.dart';

const List<LessonSlide> _kNumbersMemorizationSpeedSlides = <LessonSlide>[
  LessonSlide(
    icon: Icons.speed_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Скорость запоминания',
      AppLanguage.en: 'Memorization speed',
      AppLanguage.de: 'Merkgeschwindigkeit',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Настоящий рост в мнемотехнике начинается, когда кодировка перестаёт быть сознательным процессом. Новички медленно переводят цифры в образы, потому что мозг ещё не привык. Профессионалы видят числа и почти мгновенно получают сцены в голове.',
      AppLanguage.en:
          'Real growth in mnemonics begins when coding stops being a conscious process. Beginners slowly translate numbers into images because the brain is not used to it yet. Professionals see numbers and get scenes in their heads almost instantly.',
      AppLanguage.de:
          'Echtes Wachstum in der Mnemotechnik beginnt dann, wenn das Kodieren kein bewusster Prozess mehr ist. Anfänger übersetzen Zahlen langsam in Bilder, weil das Gehirn noch nicht daran gewöhnt ist. Profis sehen Zahlen und haben fast augenblicklich Szenen im Kopf.',
    },
  ),
  LessonSlide(
    icon: Icons.tune_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Скорость строится на трёх вещах: автоматизация, простота образов и структура хранения. Если кодировка слабая, локи хаотичны или образы нечёткие — скорость ломается.',
      AppLanguage.en:
          'Speed is built on three things: automation, simplicity of images, and storage structure. If coding is weak, loci chaotic, or images fuzzy—the speed breaks.',
      AppLanguage.de:
          'Geschwindigkeit basiert auf drei Dingen: Automatisierung, Einfachheit der Bilder und Speicherstruktur. Wenn die Kodierung schwach ist, die Loci chaotisch oder die Bilder unscharf — bricht die Geschwindigkeit ein.',
    },
  ),
  LessonSlide(
    icon: Icons.bolt_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Во время быстрого запоминания мозг не должен думать — он автоматически реагирует на цифры визуальными сценами. Поэтому тренировки скорости так важны. Есть и предел перегруза: если кодировать быстрее, чем удерживаешь сцены, качество резко падает. Задача — баланс скорости и стабильности.',
      AppLanguage.en:
          'During fast memorization, the brain should not think—it reacts to numbers with visual scenes automatically. That is why speed training matters. There is also an overload limit: if you code faster than you can hold the scenes, quality drops sharply. The goal is a balance of speed and stability.',
      AppLanguage.de:
          'Beim schnellen Merken sollte das Gehirn nicht nachdenken — es reagiert automatisch mit Szenen. Deshalb ist Geschwindigkeitstraining so wichtig. Es gibt auch eine Überlastungsgrenze: Wenn du schneller kodierst, als du die Szenen halten kannst, sinkt die Qualität stark. Gesucht wird die Balance aus Tempo und Stabilität.',
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
          'Попробуй запомнить 10 цифр без спешки. Затем сделай то же чуть быстрее. Заметь, в какой момент сцены начинают «плыть» — это текущий предел скорости.',
      AppLanguage.en:
          'Try to memorize 10 digits without rushing. Then do the same a little faster. Notice when scenes start getting blurry—that is your current speed limit.',
      AppLanguage.de:
          'Versuche, dir 10 Ziffern ohne Eile zu merken. Mach es dann etwas schneller. Achte darauf, wann die Szenen unscharf werden — das ist dein aktuelles Tempolimit.',
    },
    isCompletion: true,
    trainerLaunch: LessonTrainerLaunchKind.academyNumbers09Elements10,
    trainerCtaLabel: <AppLanguage, String>{
      AppLanguage.ru: 'В тренажёр · 10 цифр (0–9)',
      AppLanguage.en: 'Open trainer · 10 digits (0–9)',
      AppLanguage.de: 'Zum Trainer · 10 Ziffern (0–9)',
    },
  ),
];

const List<LessonSlide> _kNumbersLongSequencesSlides = <LessonSlide>[
  LessonSlide(
    icon: Icons.straighten_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Длинные числа',
      AppLanguage.en: 'Long numbers',
      AppLanguage.de: 'Lange Zahlen',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Короткие последовательности можно удержать и без системы. Длинные числа быстро ломают обычную память — здесь мнемотехника раскрывается полностью.',
      AppLanguage.en:
          'Short sequences can stick even without a system. Long numbers quickly overwhelm ordinary memory—this is where mnemonics shows its full strength.',
      AppLanguage.de:
          'Kurze Folgen kann man auch ohne System behalten. Lange Zahlen zerstören schnell das gewöhnliche Gedächtnis — hier zeigt die Mnemotechnik ihre wahre Stärke.',
    },
  ),
  LessonSlide(
    icon: Icons.view_week_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Большие последовательности делятся на блоки — мозг лучше держит группы, чем хаос цифр. Мнемонисты режут числа на пары, тройки или целые сцены.',
      AppLanguage.en:
          'Large sequences are chunked—the brain holds groups better than chaotic streams of digits. Mnemonists split numbers into pairs, triplets, or full scenes.',
      AppLanguage.de:
          'Große Folgen werden in Blöcke geteilt — das Gehirn behält Gruppen besser als einen Ziffernwirrwarr. Mnemoniker zerlegen Zahlen in Paare, Dreier oder ganze Szenen.',
    },
  ),
  LessonSlide(
    icon: Icons.map_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'После кодировки образы ставятся в локи — пространство становится каркасом памяти. Не нужно держать всё сразу: ты проходишь маршрут и «читаешь» сцены по порядку. Так возможны сотни и тысячи цифр.',
      AppLanguage.en:
          'After coding, images go into loci—space becomes your framework. You do not hold everything at once: you walk the route and read the scenes in order. That is how hundreds and thousands of digits become possible.',
      AppLanguage.de:
          'Nach der Kodierung wandern Bilder in Loci — der Raum wird zum Gerüst. Du behältst nicht alles gleichzeitig: du gehst die Route ab und liest die Szenen der Reihe nach. So werden hunderte und tausende Ziffern möglich.',
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
          'Возьми 20 случайных цифр, разбей на блоки и размести по маршруту. Пройди локи и восстанови порядок, затем попробуй с конца к началу и вспомни цифры на позициях 17, 10 и 2.',
      AppLanguage.en:
          'Take 20 random digits, split into blocks and place them along your route. Walk your loci to restore order, try end-to-beginning, then recall digits at positions 17, 10 and 2.',
      AppLanguage.de:
          'Nimm 20 zufällige Ziffern, teile sie in Blöcke und platziere sie auf der Route. Geh die Loci ab, stelle die Reihenfolge her, dann von hinten nach vorne und erinnere Ziffern an den Positionen 17, 10 und 2.',
    },
    isCompletion: true,
    trainerLaunch: LessonTrainerLaunchKind.academyNumbers09Elements20,
    trainerCtaLabel: <AppLanguage, String>{
      AppLanguage.ru: 'В тренажёр · 20 цифр (0–9)',
      AppLanguage.en: 'Open trainer · 20 digits (0–9)',
      AppLanguage.de: 'Zum Trainer · 20 Ziffern (0–9)',
    },
  ),
];

const List<LessonSlide> _kNumbersAgainstTheClockSlides = <LessonSlide>[
  LessonSlide(
    icon: Icons.timer_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Числа на время',
      AppLanguage.en: 'Numbers against the clock',
      AppLanguage.de: 'Zahlen auf Zeit',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'На соревнованиях важны и точность, и скорость: память почти как спорт. Нужно быстро кодировать и ставить сцены в локи без потери качества.',
      AppLanguage.en:
          'In competitions, both accuracy and speed matter—memory becomes almost like a sport. You must code quickly and place scenes in loci without losing quality.',
      AppLanguage.de:
          'Bei Wettkämpfen zählen Genauigkeit und Geschwindigkeit — das Gedächtnis wird fast zur Sportdisziplin. Zahlen schnell kodieren und Szenen in Loci setzen, ohne Qualität zu verlieren.',
    },
  ),
  LessonSlide(
    icon: Icons.psychology_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Время давит на память: паника или долгие раздумья роняют темп. Профи доводят автоматизм почти до рефлекса.',
      AppLanguage.en:
          'Time pressure hits memory—panic or overthinking kills pace. Pros train automation until it is almost reflexive.',
      AppLanguage.de:
          'Zeitdruck belastet das Gedächtnis — Panik oder Grübeln kostet Tempo. Profis trainieren Automatismus bis fast zum Reflex.',
    },
  ),
  LessonSlide(
    icon: Icons.flash_on_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'В скоростном режиме сцены чаще грубее и проще: цель — мгновенное считывание, не «красота» кадра. Концентрация критична: потеря внимания на секунды может разрушить цепочку.',
      AppLanguage.en:
          'At high speed, scenes get rougher and simpler—the goal is instant recognition, not pretty pictures. Concentration is critical: even a few seconds of lost focus can break the chain.',
      AppLanguage.de:
          'Im Hochtempo werden Szenen rauer und einfacher — es geht um sofortiges Erkennen, nicht um Schönheit. Konzentration ist kritisch: wenige Sekunden Unaufmerksamkeit können die Kette zerstören.',
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
          'Поставь таймер на одну минуту и запоминай как можно больше цифр через свою систему. Ошибки не страшны — цель почувствовать ритм и скорость. В тренажёре смотри на часы сверху: перейди к вводу, когда пройдёт минута.',
      AppLanguage.en:
          'Set a timer for one minute and memorize as many digits as you can with your system. Mistakes are fine—the goal is rhythm and speed. In the trainer, watch the clock at the top and move to recall when one minute is up.',
      AppLanguage.de:
          'Stell eine Minute auf dem Timer und speichere so viele Ziffern wie möglich mit deinem System. Fehler sind okay — Ziel sind Rhythmus und Tempo. Im Trainer oben die Uhr beobachten und nach einer Minute zur Eingabe wechseln.',
    },
    isCompletion: true,
    trainerLaunch: LessonTrainerLaunchKind.academyNumbersTimedFree,
    trainerCtaLabel: <AppLanguage, String>{
      AppLanguage.ru: 'В тренажёр · 0–9, запас 200 цифр',
      AppLanguage.en: 'Open trainer · 0–9, up to 200 digits',
      AppLanguage.de: 'Zum Trainer · 0–9, bis 200 Ziffern',
    },
  ),
];

class NumbersMemorizationSpeedLessonScreen extends StatelessWidget {
  const NumbersMemorizationSpeedLessonScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return LessonScreen(
      slides: _kNumbersMemorizationSpeedSlides,
      onFinished: onFinished,
      onTrainerLaunch: academyLaunchLessonTrainer,
    );
  }
}

class NumbersLongSequencesLessonScreen extends StatelessWidget {
  const NumbersLongSequencesLessonScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return LessonScreen(
      slides: _kNumbersLongSequencesSlides,
      onFinished: onFinished,
      onTrainerLaunch: academyLaunchLessonTrainer,
    );
  }
}

class NumbersAgainstTheClockLessonScreen extends StatelessWidget {
  const NumbersAgainstTheClockLessonScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return LessonScreen(
      slides: _kNumbersAgainstTheClockSlides,
      onFinished: onFinished,
      onTrainerLaunch: academyLaunchLessonTrainer,
    );
  }
}

const Map<String, List<LessonSlide>> kNumbersExtendedBuiltinSlides =
    <String, List<LessonSlide>>{
  'numbers_speed': _kNumbersMemorizationSpeedSlides,
  'numbers_long': _kNumbersLongSequencesSlides,
  'numbers_clock': _kNumbersAgainstTheClockSlides,
};
