import 'package:flutter/material.dart';

import '../recovered_app.dart' show AppLanguage;
import 'academy_training_launcher.dart';
import 'lesson_framework.dart';

const List<LessonSlide> _kMemorizingPicturesSlides = <LessonSlide>[
  LessonSlide(
    icon: Icons.photo_camera_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Как запоминать картинки',
      AppLanguage.en: 'How to memorize pictures',
      AppLanguage.de: 'Wie man sich Bilder merkt',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Многие думают, что память — как камера: «сфотографировать» картинку в голове и держать её целиком. Мозг так не устроен: он не сохраняет полную копию изображения.',
      AppLanguage.en:
          'Many people think memory works like a camera—"photograph" the picture in your head and keep it whole. The brain doesn’t work that way: it does not store a full copy of an image.',
      AppLanguage.de:
          'Viele denken, das Gedächtnis sei wie eine Kamera — ein Bild „fotografieren“ und ganz halten. So arbeitet das Gehirn nicht: Es speichert keine vollständige Kopie.',
    },
  ),
  LessonSlide(
    icon: Icons.account_tree_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Он выделяет главные детали и связывает их в ассоциации. Поэтому ты помнишь лицо, но не цвет каждой пуговицы. В мнемотехнике задача не удержать всё поле зрения, а быстро найти главный объект и сделать из него сильный образ.',
      AppLanguage.en:
          'It highlights key details and links them into associations. That’s why you remember a face but not every button color. In mnemonics, the goal is not to hold the whole frame, but to quickly find the main object and turn it into a strong image.',
      AppLanguage.de:
          'Es hebt wichtige Details hervor und verknüpft sie zu Assoziationen. Darum erinnerst du dich ans Gesicht, aber nicht an jeden Knopf. In der Mnemotechnik geht es nicht darum, alles festzuhalten, sondern schnell das Hauptobjekt zu finden und ein starkes Bild daraus zu machen.',
    },
  ),
  LessonSlide(
    icon: Icons.pedal_bike_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'На картинке велосипеда возле дерева мозгу проще держать велосипед, чем весь фон. Главный объект становится основой памяти.',
      AppLanguage.en:
          'In a bicycle-by-a-tree picture, your brain hangs onto the bicycle more easily than the whole background. The main object becomes the anchor of memory.',
      AppLanguage.de:
          'Bei Fahrrad neben Baum hält sich das Gehirn leichter am Fahrrad als am ganzen Hintergrund fest. Das Hauptobjekt wird zur Basis der Erinnerung.',
    },
  ),
  LessonSlide(
    icon: Icons.touch_app_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Практика',
      AppLanguage.en: 'Practice',
      AppLanguage.de: 'Übung',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Посмотри на любой предмет рядом с собой и пойми, какая деталь первой бросается в глаза — чаще всего именно она станет главным образом для памяти.',
      AppLanguage.en:
          'Look at any object nearby and notice which detail catches your eye first—that detail will most often become your main memory image.',
      AppLanguage.de:
          'Schau einen Gegenstand in deiner Nähe an und merke, welches Detail dir als Erstes ins Auge fällt — meist wird genau dieses zum Hauptbild.',
    },
    isCompletion: true,
  ),
];

const List<LessonSlide> _kHighlightingMainObjectSlides = <LessonSlide>[
  LessonSlide(
    icon: Icons.center_focus_strong_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Выделение главного объекта',
      AppLanguage.en: 'Highlighting the main object',
      AppLanguage.de: 'Das Hauptobjekt hervorheben',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Не нужно разбирать каждую мелочь — это только перегружает мозг. Сразу ищи главный объект сцены: человек, животное, предмет или действие.',
      AppLanguage.en:
          'You don’t need to analyze every tiny detail—it overloads the brain. Immediately look for the main object of the scene: a person, animal, thing, or action.',
      AppLanguage.de:
          'Du musst nicht jedes Detail analysieren — das überlastet das Gehirn. Finde sofort das Hauptobjekt: Person, Tier, Ding oder Handlung.',
    },
  ),
  LessonSlide(
    icon: Icons.auto_fix_high_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Объект нужно усилить — ярче, крупнее, страннее. Обычный лев стань огромным, размером с дом: рычит, ломает стены. Чем дальше от «нормы», тем крепче держится память.',
      AppLanguage.en:
          'Amplify the object—brighter, bigger, stranger. An ordinary lion becomes house-sized: roaring, tearing walls down. The further from normal, the more memory grips it.',
      AppLanguage.de:
          'Verstärke das Objekt — heller, größer, seltsamer. Ein gewöhnlicher Löwe wird hausgroß und reißt Wänden ein. Je weiter von „normal“, desto fester bleibt es im Gedächtnis.',
    },
  ),
  LessonSlide(
    icon: Icons.psychology_alt_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Профи не запоминают «картинку целиком» — они запоминают выделенные образы. Упрощённая информация обрабатывается гораздо быстрее.',
      AppLanguage.en:
          'Pros don’t memorize the whole photograph—they memorize highlighted images. Simplified information is processed far faster.',
      AppLanguage.de:
          'Profis merken nicht das ganze Foto — sie merken sich hervorgehobene Bilder. Vereinfachte Information verarbeitet sich viel schneller.',
    },
  ),
  LessonSlide(
    icon: Icons.collections_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Практика',
      AppLanguage.en: 'Practice',
      AppLanguage.de: 'Übung',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Открой тренажёр с картинками. Не запоминая их целенаправленно, в каждой находи объект, который выделяется и поможет потом узнать, что ты запоминал.',
      AppLanguage.en:
          'Open the image trainer. Without trying to cram them all in, spot one standout object per picture—the one that will help you recognize what you memorized.',
      AppLanguage.de:
          'Öffne den Bildertrainer. Ohne Auswendiglernen finde je Bild ein herausragendes Objekt, an dem du später erkennst, woran du gearbeitet hast.',
    },
    isCompletion: true,
    trainerLaunch: LessonTrainerLaunchKind.academyImagesMainObjectExplore,
    trainerCtaLabel: <AppLanguage, String>{
      AppLanguage.ru: 'Открыть тренажёр · картинки',
      AppLanguage.en: 'Open trainer · images',
      AppLanguage.de: 'Trainer öffnen · Bilder',
    },
    trainerCtaSubtitle: <AppLanguage, String>{
      AppLanguage.ru: 'Режим «Фото»: ищи главный объект без спешки',
      AppLanguage.en: 'Photos mode: find the main object, your own pace',
      AppLanguage.de: 'Foto-Modus: Hauptobjekt finden, in deinem Tempo',
    },
  ),
];

const List<LessonSlide> _kImageEncodingSlides = <LessonSlide>[
  LessonSlide(
    icon: Icons.transform_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Кодировка изображений',
      AppLanguage.en: 'Image encoding',
      AppLanguage.de: 'Bildkodierung',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Когда главный объект найден, начинается кодировка — превращение изображения в образ, понятный памяти. Картинка перестаёт быть просто файлом на сетчатке и входит в твою систему запоминания.',
      AppLanguage.en:
          'Once the main object is found, encoding begins—turning the image into a shape memory can handle. The picture stops being just a retina snapshot and enters your memorization system.',
      AppLanguage.de:
          'Ist das Hauptobjekt gefunden, beginnt die Kodierung — das Bild wird in eine Form gebracht, die das Gedächtnis kann. Das Bild wird Teil deines Merksystems.',
    },
  ),
  LessonSlide(
    icon: Icons.pets_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Тигр на экране — не нужно хранить «фото» полностью. Достаточно сильного образа рычащего тигра и связи с локи или другой сценой — так связь становится устойчивой.',
      AppLanguage.en:
          'A tiger on screen—you don’t need the full snapshot. A strong roaring tiger linked to a locus or another scene is enough for stable storage.',
      AppLanguage.de:
          'Ein Tiger auf dem Bild — du brauchst nicht das ganze JPEG. Ein brüllender Tiger, verknüpft mit einem Locus, reicht für stabiles Halten.',
    },
  ),
  LessonSlide(
    icon: Icons.layers_clear_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Правило кодировки — простота. Не утрамбовывай лишние детали. На скорости мнемонисты режут картинку до одной самой мощной части и сразу переводят её в образ.',
      AppLanguage.en:
          'The rule of encoding is simplicity—don’t pack in extra detail. Under speed, mnemonists strip the picture to its strongest shard and flip it straight into an image.',
      AppLanguage.de:
          'Regel der Kodierung: Einfachkeit. Bei Tempo halten Mnemoniker nur den stärksten Ausschnitt und machen sofort ein Bild daraus.',
    },
  ),
  LessonSlide(
    icon: Icons.task_alt_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Дальше',
      AppLanguage.en: 'Wrap up',
      AppLanguage.de: 'Weiter',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Применяй кодировку в паре с выделением объекта и локами: простой образ + место дают предсказуемый результат.',
      AppLanguage.en:
          'Combine encoding with main-object spotting and loci—a simple image plus a location gives predictable recall.',
      AppLanguage.de:
          'Kombiniere Kodierung mit Hauptobjekt und Loci — einfaches Bild plus Ort gibt planbaren Abruf.',
    },
    isCompletion: true,
  ),
];

const List<LessonSlide> _kImageryErrorsSlides = <LessonSlide>[
  LessonSlide(
    icon: Icons.error_outline_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Ошибки при запоминании картинок',
      AppLanguage.en: 'Errors memorizing pictures',
      AppLanguage.de: 'Fehler beim Bilder-Merken',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Частая ошибка — запоминать кадр целиком. Внимание перегружается, темп падает. Вторая — слишком «бытовые» сцены: если всё выглядит нормально, мозгу не за что цепляться.',
      AppLanguage.en:
          'A classic mistake is trying to hold the entire frame—it overloads attention and slows you down. Another is overly ordinary scenes: if everything looks normal, the brain has nothing to grip.',
      AppLanguage.de:
          'Klassiker: Das ganze Bild speichern wollen — die Aufmerksamkeit kollabiert. Zweitens zu gewöhnliche Szenen: Wenn alles „normal“ ist, hat das Gehirn keinen Hakens.',
    },
  ),
  LessonSlide(
    icon: Icons.directions_run_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Не забывай действие: стоячий объект слабее, чем движущийся, ломающийся, горящий или меняющий форму. И структура: без лок или цепочки при большой серии образы смешиваются.',
      AppLanguage.en:
          'Don’t forget action—a static prop is weaker than something moving, breaking, burning, or morphing. And structure—without loci or a chain, many images blur together.',
      AppLanguage.de:
          'Nicht ohne Bewegung: Stillstand ist schwächer als Bewegen, Brennen, Zerbrechen. Und Struktur: Ohne Loci oder Kette verschwimmen viele Bilder.',
    },
  ),
  LessonSlide(
    icon: Icons.auto_awesome_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Суть',
      AppLanguage.en: 'Takeaway',
      AppLanguage.de: 'Kern',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Мнемотехника сильна не «родной памятью», а тем, что информация переводится в язык образов — его мозг держит легче, чем сухие данные.',
      AppLanguage.en:
          'Mnemonics works not thanks to magic recall, but because data becomes a language of images the brain holds more easily than raw facts.',
      AppLanguage.de:
          'Mnemotechnik wirkt nicht durch „Talent“, sondern weil Daten in Bildersprache werden — die hält das Gehirn leichter als bloße Daten.',
    },
    isCompletion: true,
  ),
];

class MemorizingPicturesLessonScreen extends StatelessWidget {
  const MemorizingPicturesLessonScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return LessonScreen(
      slides: _kMemorizingPicturesSlides,
      onFinished: onFinished,
    );
  }
}

class HighlightingMainObjectLessonScreen extends StatelessWidget {
  const HighlightingMainObjectLessonScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return LessonScreen(
      slides: _kHighlightingMainObjectSlides,
      onFinished: onFinished,
      onTrainerLaunch: academyLaunchLessonTrainer,
    );
  }
}

class ImageEncodingLessonScreen extends StatelessWidget {
  const ImageEncodingLessonScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return LessonScreen(
      slides: _kImageEncodingSlides,
      onFinished: onFinished,
    );
  }
}

class ImageryPictureErrorsLessonScreen extends StatelessWidget {
  const ImageryPictureErrorsLessonScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return LessonScreen(
      slides: _kImageryErrorsSlides,
      onFinished: onFinished,
    );
  }
}

const Map<String, List<LessonSlide>> kImageryTrackBuiltinSlides =
    <String, List<LessonSlide>>{
  'disc_imagery': _kMemorizingPicturesSlides,
  'imagery_main_object': _kHighlightingMainObjectSlides,
  'imagery_encoding': _kImageEncodingSlides,
  'imagery_picture_errors': _kImageryErrorsSlides,
};
