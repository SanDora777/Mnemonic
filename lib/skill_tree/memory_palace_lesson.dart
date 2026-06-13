import 'package:flutter/material.dart';

import '../recovered_app.dart' show AppLanguage;
import 'academy_training_launcher.dart';
import 'lesson_framework.dart';

const List<LessonSlide> _kMemoryPalaceMethodSlides = <LessonSlide>[
  LessonSlide(
    icon: Icons.account_balance_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Метод локи (Дворец памяти)',
      AppLanguage.en: 'Method of Loci (Memory Palace)',
      AppLanguage.de: 'Loci Methode (Gedächtnispalast)',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Метод локи это одна из самых древних и мощных техник памяти. Её использовали ещё тысячи лет назад ораторы и философы, когда нужно было запоминать огромные речи без записей. Суть метода заключается в том, что мозг невероятно хорошо запоминает пространство. Ты можешь забыть список слов, но легко вспомнишь, где находится дверь в твоей комнате или как выглядит путь до школы. Пространственная память развивалась у человека миллионы лет, потому что она была необходима для выживания. Именно на этом и построен дворец памяти. Ты берёшь знакомое место и превращаешь его в хранилище информации. Это может быть твоя квартира, дом, маршрут до магазина или любое пространство, которое ты хорошо знаешь. Внутри этого пространства существуют точки, локации. Например: дверь, шкаф, стол, диван, телевизор. На эти точки ты помещаешь образы. Когда тебе нужно вспомнить информацию, ты просто проходишься по маршруту в голове и видишь размещённые сцены.',
      AppLanguage.en:
          'The Method of Loci is one of the oldest and most powerful memory techniques. It was used thousands of years ago by orators and philosophers when they needed to memorize huge speeches without notes. The essence of the method is that the brain remembers space incredibly well. You might forget a list of words, but you easily remember where the door is in your room or what the way to school looks like. Spatial memory has evolved in humans over millions of years because it was necessary for survival. This is exactly what the memory palace is built on. You take a familiar place and turn it into a storage for information. This can be your apartment, house, the route to the store, or any space you know well. Inside this space, there are points called locations. For example: a door, a closet, a table, a sofa, a TV. You place images on these points. When you need to recall the information, you simply walk through the route in your head and see the placed scenes.',
      AppLanguage.de:
          'Die Loci Methode ist eine der ältesten und mächtigsten Gedächtnistechniken. Sie wurde schon vor tausenden von Jahren von Rednern und Philosophen genutzt, wenn sie gewaltige Reden ohne Notizen auswendig lernen mussten. Der Kern der Methode liegt darin, dass das Gehirn Räume unglaublich gut speichert. Du magst eine Liste von Wörtern vergessen, aber du erinnerst dich leicht daran, wo die Tür in deinem Zimmer ist oder wie der Weg zur Schule aussieht. Das räumliche Gedächtnis hat sich beim Menschen über Millionen von Jahren entwickelt, weil es überlebenswichtig war. Genau darauf baut der Gedächtnispalast auf. Du nimmst einen vertrauten Ort und verwandelst ihn in einen Informationsspeicher. Das kann deine Wohnung, dein Haus, der Weg zum Supermarkt oder jeder Raum sein, den du gut kennst. Innerhalb dieses Raumes gibt es Punkte, die Loci oder Standorte genannt werden. Zum Beispiel: Tür, Schrank, Tisch, Sofa, Fernseher. An diesen Punkten platzierst du Bilder. Wenn du dich an die Informationen erinnern willst, gehst du einfach die Route im Kopf ab und siehst die dort platzierten Szenen.',
    },
  ),
  LessonSlide(
    icon: Icons.route_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Главное правило дворца памяти это фиксированный порядок. Ты всегда идёшь одним и тем же путём. Если маршрут меняется, память начинает путаться. Второе важное правило это взаимодействие образа с местом. Не просто яблоко лежит на столе, а огромное яблоко проламывает стол. Чем сильнее сцена связана с локацией, тем легче её вспомнить. Пространство становится каркасом для памяти, а образы это информация внутри него.',
      AppLanguage.en:
          'The main rule of the memory palace is a fixed order. You always walk the same path. If the route changes, the memory starts to get confused. The second important rule is that the image must interact with the place. It is not just an apple lying on a table, but a giant apple smashing through the table. The stronger the scene is connected to the location, the easier it is to remember. Space becomes the framework for memory, and images are the information inside it.',
      AppLanguage.de:
          'Die wichtigste Regel des Gedächtnispalastes ist die feste Reihenfolge. Du gehst immer denselben Weg ab. Wenn sich die Route ändert, gerät das Gedächtnis durcheinander. Die zweite wichtige Regel ist die Interaktion des Bildes mit dem Ort. Nicht einfach nur ein Apfel liegt auf dem Tisch, sondern ein riesiger Apfel kracht durch den Tisch. Je stärker die Szene mit dem Standort verbunden ist, desto leichter lässt sie sich abrufen. Der Raum wird zum Gerüst für das Gedächtnis und die Bilder sind die Informationen darin.',
    },
  ),
  LessonSlide(
    icon: Icons.warning_amber_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Ошибка новичков это использование слишком абстрактных мест или попытка создать огромный дворец сразу. Память любит знакомое. Намного лучше использовать маленький, но идеально знакомый маршрут, чем огромный и размытый. Также многие ставят образы слишком близко друг к другу, из-за чего они начинают смешиваться. Один объект это одна точка.',
      AppLanguage.en:
          'A common beginner mistake is using places that are too abstract or trying to create a huge palace all at once. Memory loves the familiar. It is much better to use a small but perfectly familiar route than a huge and blurry one. Also, many people place images too close to each other, which causes them to mix. One object is one point.',
      AppLanguage.de:
          'Ein typischer Anfängerfehler ist die Nutzung von zu abstrakten Orten oder der Versuch, sofort einen riesigen Palast zu erschaffen. Das Gedächtnis liebt das Vertraute. Es ist viel besser, eine kleine, aber perfekt bekannte Route zu nutzen als eine riesige und unscharfe. Außerdem setzen viele die Bilder zu nah beieinander, wodurch sie sich vermischen. Ein Objekt entspricht einem Standort.',
    },
  ),
  LessonSlide(
    icon: Icons.check_circle_outline_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    isCompletion: true,
    hideCompletionText: true,
  ),
];

const List<LessonSlide> _kCreateMemoryPalaceSlides = <LessonSlide>[
  LessonSlide(
    icon: Icons.foundation_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Как создать дворец памяти',
      AppLanguage.en: 'How to Create a Memory Palace',
      AppLanguage.de: 'Wie man einen Gedächtnispalast erstellt',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Создание хорошего дворца памяти это фундамент всей системы. Большинство ошибок появляются не из-за плохой памяти, а из-за плохой структуры. Хороший дворец должен быть максимально знакомым и стабильным. Ты должен видеть его в голове почти автоматически. Лучшие варианты для начала это твоя квартира, дом детства, путь до школы или магазин рядом с домом. Не нужно придумывать фантастические миры. Чем реальнее место, тем лучше работает память. В будущем можно использовать Google Earth для создания маршрутов. Чем больше у тебя локи, тем больше у тебя памяти. Профессионалы имеют целые города в голове на 2000 плюс локи.',
      AppLanguage.en:
          'Creating a good memory palace is the foundation of the entire system. Most mistakes occur not because of poor memory, but because of poor structure. A good palace should be as familiar and stable as possible. You should be able to see it in your head almost automatically. The best options to start with are your apartment, your childhood home, the way to school, or a shop near your house. There is no need to invent fantasy worlds. The more real the place is, the better the memory works. In the future, you can use Google Earth to create routes. The more loci you have, the more memory you have. Professionals have entire cities in their heads with over 2000 loci.',
      AppLanguage.de:
          'Die Erstellung eines guten Gedächtnispalastes ist das Fundament des gesamten Systems. Die meisten Fehler entstehen nicht durch ein schlechtes Gedächtnis, sondern durch eine schlechte Struktur. Ein guter Palast sollte so vertraut und stabil wie möglich sein. Du solltest ihn fast automatisch in deinem Kopf sehen können. Die besten Optionen für den Anfang sind deine Wohnung, dein Elternhaus, der Schulweg oder ein Geschäft in der Nähe deines Hauses. Es ist nicht nötig, Fantasiewelten zu erfinden. Je realer der Ort ist, desto besser funktioniert das Gedächtnis. In Zukunft kannst du Google Earth nutzen, um Routen zu erstellen. Je mehr Loci du hast, desto mehr Gedächtniskapazität hast du. Profis haben ganze Städte mit über 2000 Loci im Kopf.',
    },
  ),
  LessonSlide(
    icon: Icons.alt_route_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'После выбора места тебе нужно создать маршрут. Это последовательность точек, по которым ты всегда двигаешься одинаково. Например: входная дверь → коврик → зеркало → стол → диван → телевизор. Очень важно никогда не перескакивать хаотично между объектами. Дворец памяти работает как дорога. Если маршрут ломается, ломается и воспоминание.',
      AppLanguage.en:
          'After choosing a place, you need to create a route. This is a sequence of points that you always move through in the same way. For example: front door → mat → mirror → table → sofa → TV. It is very important never to jump chaotically between objects. A memory palace works like a road. If the route breaks, the memory breaks too.',
      AppLanguage.de:
          'Nachdem du einen Ort ausgewählt hast, musst du eine Route erstellen. Das ist eine Abfolge von Punkten, die du immer auf die gleiche Weise abläufst. Zum Beispiel: Eingangstür → Matte → Spiegel → Tisch → Sofa → Fernseher. Es ist sehr wichtig, niemals chaotisch zwischen Objekten hin- und herzuspringen. Ein Gedächtnispalast funktioniert wie eine Straße. Wenn die Route bricht, bricht auch die Erinnerung.',
    },
  ),
  LessonSlide(
    icon: Icons.place_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Каждая точка должна быть визуально отдельной. Не ставь несколько объектов в одно место. Если на диване уже находится один образ, следующий должен идти дальше по маршруту. Профессиональные мнемонисты могут создавать сотни и тысячи таких точек, превращая память в огромную сеть маршрутов.',
      AppLanguage.en:
          'Each point must be visually distinct. Do not put multiple objects in one place. If there is already one image on the sofa, the next one should go further along the route. Professional mnemonists can create hundreds and thousands of such points, turning memory into a vast network of routes.',
      AppLanguage.de:
          'Jeder Punkt muss visuell getrennt sein. Platziere nicht mehrere Objekte an einem Ort. Wenn sich auf dem Sofa bereits ein Bild befindet, muss das nächste weiter auf der Route liegen. Profi Mnemoniker können hunderte und tausende solcher Punkte erstellen und das Gedächtnis so in ein riesiges Netzwerk von Routen verwandeln.',
    },
  ),
  LessonSlide(
    icon: Icons.open_in_full_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Ещё одна важная вещь это размер образов. Во дворце памяти всё должно быть преувеличено. Маленькие и обычные сцены быстро исчезают. Если ты запоминаешь машину, представь огромную машину, пробивающую стену комнаты. Если это вода, пусть она затапливает помещение. Память любит масштаб и эмоцию.',
      AppLanguage.en:
          'Another important thing is the size of the images. In a memory palace, everything should be exaggerated. Small and ordinary scenes disappear quickly. If you are memorizing a car, imagine a huge car smashing through the wall of the room. If it is water, let it flood the room. Memory loves scale and emotion.',
      AppLanguage.de:
          'Eine weitere wichtige Sache ist die Größe der Bilder. In einem Gedächtnispalast sollte alles übertrieben sein. Kleine und gewöhnliche Szenen verschwinden schnell. Wenn du dir ein Auto merkst, stell dir ein riesiges Auto vor, das die Zimmerwand durchbricht. Wenn es Wasser ist, lass es den Raum überfluten. Das Gedächtnis liebt Größe und Emotionen.',
    },
  ),
  LessonSlide(
    icon: Icons.task_alt_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Задание',
      AppLanguage.en: 'Task',
      AppLanguage.de: 'Aufgabe',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Теперь создай свой первый дворец памяти. Для начала это может быть твоя квартира. Создай не менее 20 локей: ты должен с лёгкостью перемещаться по ним в голове — с начала к концу и с конца к началу.',
      AppLanguage.en:
          'Now create your first memory palace. To start with, it can be your apartment. Create at least 20 loci: you should be able to move through them effortlessly in your mind — from start to finish and from finish to start.',
      AppLanguage.de:
          'Erstelle nun deinen ersten Gedächtnispalast. Für den Anfang kann das deine Wohnung sein. Erstelle mindestens 20 Loci: Du solltest dich im Kopf mühelos von Anfang bis Ende und von Ende bis Anfang durch sie bewegen können.',
    },
    isCompletion: true,
    trainerLaunch: LessonTrainerLaunchKind.academyLociRoutes,
    trainerCtaLabel: <AppLanguage, String>{
      AppLanguage.ru: 'Создай маршрут',
      AppLanguage.en: 'Create a route',
      AppLanguage.de: 'Erstelle eine Route',
    },
    trainerCtaSubtitle: <AppLanguage, String>{
      AppLanguage.ru: 'Редактор маршрутов и локаций',
      AppLanguage.en: 'Route and loci editor',
      AppLanguage.de: 'Routen- und Loci-Editor',
    },
  ),
];

const List<LessonSlide> _kPlacingImagesSlides = <LessonSlide>[
  LessonSlide(
    icon: Icons.add_location_alt_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Как размещать образы',
      AppLanguage.en: 'How to Place Images',
      AppLanguage.de: 'Wie man Bilder platziert',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Создать дворец недостаточно. Главное — научиться правильно помещать в него информацию. Самая частая ошибка новичков заключается в том, что они ставят образы рядом с местом, а не делают их частью пространства. Если образ не взаимодействует с локацией, мозг воспринимает его как отдельный объект и быстро теряет.',
      AppLanguage.en:
          'Creating a palace is not enough. The key is learning how to correctly place information inside it. The most common mistake beginners make is placing images next to a location rather than making them part of the space. If the image does not interact with the location, the brain perceives it as a separate object and quickly loses it.',
      AppLanguage.de:
          'Einen Palast zu erstellen reicht nicht aus. Das Wichtigste ist zu lernen, wie man Informationen richtig darin platziert. Der häufigste Fehler von Anfängern ist, dass sie Bilder neben den Ort stellen, anstatt sie zu einem Teil des Raumes zu machen. Wenn das Bild nicht mit dem Standort interagiert, nimmt das Gehirn es als separates Objekt wahr und verliert es schnell.',
    },
  ),
  LessonSlide(
    icon: Icons.touch_app_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Каждый образ должен физически влиять на место. Например, если твоя локация это стол, то образ должен что-то делать со столом. Пусть арбуз раздавливает его. Пусть кошка царапает поверхность. Пусть телевизор взрывается прямо на нём. Чем сильнее взаимодействие, тем прочнее память.',
      AppLanguage.en:
          'Each image must physically affect the place. For example, if your location is a table, the image should do something to that table. Let a watermelon crush it. Let a cat scratch the surface. Let a TV explode right on top of it. The stronger the interaction, the more durable the memory.',
      AppLanguage.de:
          'Jedes Bild muss den Ort physisch beeinflussen. Wenn dein Standort zum Beispiel ein Tisch ist, dann muss das Bild etwas mit dem Tisch machen. Lass eine Wassermelone ihn zerquetschen. Lass eine Katze die Oberfläche zerkratzen. Lass einen Fernseher direkt darauf explodieren. Je stärker die Interaktion, desto dauerhafter ist die Erinnerung.',
    },
  ),
  LessonSlide(
    icon: Icons.visibility_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Также важно использовать правило одного взгляда. Когда ты смотришь на локацию в голове, ты должен сразу видеть образ. Если тебе приходится думать или искать, значит сцена слишком слабая. Хорошая мнемоника работает мгновенно.',
      AppLanguage.en:
          'It is also important to use the one-glance rule. When you look at a location in your mind, you should see the image immediately. If you have to think or search for it, the scene is too weak. Good mnemonics work instantly.',
      AppLanguage.de:
          'Es ist auch wichtig, die Ein-Blick-Regel anzuwenden. Wenn du einen Ort im Kopf betrachtest, solltest du das Bild sofort sehen. Wenn du nachdenken oder suchen musst, ist die Szene zu schwach. Gute Mnemotechnik funktioniert augenblicklich.',
    },
  ),
  LessonSlide(
    icon: Icons.motion_photos_on_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Следующий важный момент это движение. Статичные сцены быстро стираются. Мозг любит события. Если объект движется, ломается, кричит, взрывается или меняется, он становится заметным для памяти. Эмоции работают так же. Страх, смех, удивление, абсурд — всё это усиливает фиксацию.',
      AppLanguage.en:
          'The next crucial point is movement. Static scenes are erased quickly. The brain loves events. If an object moves, breaks, screams, explodes, or changes, it becomes noticeable to the memory. Emotions work the same way. Fear, laughter, surprise, absurdity — all of this strengthens the fixation.',
      AppLanguage.de:
          'Der nächste wichtige Punkt ist Bewegung. Statische Szenen werden schnell gelöscht. Das Gehirn liebt Ereignisse. Wenn sich ein Objekt bewegt, bricht, schreit, explodiert oder sich verändert, wird es für das Gedächtnis auffällig. Emotionen funktionieren genauso. Angst, Lachen, Überraschung, Absurdität — all das verstärkt die Verankerung.',
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
          'Профессиональные мнемонисты часто делают образы намеренно нелепыми или даже невозможными. Именно это позволяет мозгу отличать их от обычных воспоминаний.',
      AppLanguage.en:
          'Professional mnemonists often make images intentionally ridiculous or even impossible. This is exactly what allows the brain to distinguish them from ordinary memories.',
      AppLanguage.de:
          'Profi-Mnemoniker machen Bilder oft absichtlich lächerlich oder sogar unmöglich. Genau das ermöglicht es dem Gehirn, sie von gewöhnlichen Erinnerungen zu unterscheiden.',
    },
  ),
];

class MemoryPalaceMethodLessonScreen extends StatelessWidget {
  const MemoryPalaceMethodLessonScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return LessonScreen(
      slides: _kMemoryPalaceMethodSlides,
      onFinished: onFinished,
    );
  }
}

class MemoryPalaceCreateLessonScreen extends StatelessWidget {
  const MemoryPalaceCreateLessonScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return LessonScreen(
      slides: _kCreateMemoryPalaceSlides,
      onFinished: onFinished,
      onTrainerLaunch: academyLaunchLessonTrainer,
    );
  }
}

class MemoryPalacePlacingImagesLessonScreen extends StatelessWidget {
  const MemoryPalacePlacingImagesLessonScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return LessonScreen(slides: _kPlacingImagesSlides, onFinished: onFinished);
  }
}

const List<LessonSlide> _kLociMistakesSlides = <LessonSlide>[
  LessonSlide(
    icon: Icons.error_outline_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: 'Ошибки в методе локи',
      AppLanguage.en: 'Mistakes in the Method of Loci',
      AppLanguage.de: 'Fehler bei der Loci-Methode',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Большинство людей думают, что у них плохая память, хотя на самом деле проблема в неправильных образах и слабой структуре. Первая ошибка это делать сцены обычными. Если образ выглядит нормально и реалистично, мозг считает его неважным. Память цепляется за странное и эмоциональное, а не за привычное.',
      AppLanguage.en:
          'Most people think they have a poor memory, but in reality, the problem lies in incorrect images and weak structure. The first mistake is making scenes ordinary. If an image looks normal and realistic, the brain considers it unimportant. Memory clings to the strange and emotional, not the mundane.',
      AppLanguage.de:
          'Die meisten Menschen denken, sie hätten ein schlechtes Gedächtnis, obwohl das Problem in Wirklichkeit bei falschen Bildern und einer schwachen Struktur liegt. Der erste Fehler ist es, Szenen gewöhnlich zu gestalten. Wenn ein Bild normal und realistisch aussieht, hält das Gehirn es für unwichtig. Das Gedächtnis klammert sich an das Seltsame und Emotionale, nicht an das Alltägliche.',
    },
  ),
  LessonSlide(
    icon: Icons.motion_photos_off_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Вторая ошибка это отсутствие движения. Статичная картинка быстро исчезает. Если объект просто лежит, мозг почти не обращает на него внимания. Любая сцена должна быть живой: что-то падает, ломается, горит, двигается или меняется.',
      AppLanguage.en:
          'The second mistake is a lack of movement. A static picture disappears quickly. If an object is just lying there, the brain pays almost no attention to it. Every scene must be alive: something falls, breaks, burns, moves, or changes.',
      AppLanguage.de:
          'Der zweite Fehler ist fehlende Bewegung. Ein statisches Bild verschwindet schnell. Wenn ein Objekt einfach nur da liegt, schenkt das Gehirn ihm kaum Beachtung. Jede Szene muss lebendig sein: Etwas fällt, bricht, brennt, bewegt sich oder verändert sich.',
    },
  ),
  LessonSlide(
    icon: Icons.layers_clear_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Третья ошибка это перегрузка локаций. Многие пытаются разместить слишком много информации в одной точке. Из-за этого сцены смешиваются. Один образ — одна локация. Простота всегда сильнее хаоса.',
      AppLanguage.en:
          'The third mistake is overloading locations. Many people try to place too much information at a single point. Because of this, the scenes get mixed up. One image per location. Simplicity is always more powerful than chaos.',
      AppLanguage.de:
          'Der dritte Fehler ist die Überlastung der Standorte. Viele versuchen, zu viele Informationen an einem einzigen Punkt zu platzieren. Dadurch vermischen sich die Szenen. Ein Bild entspricht einem Standort. Einfachheit ist immer stärker als Chaos.',
    },
  ),
  LessonSlide(
    icon: Icons.wrong_location_outlined,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru:
          'Четвёртая ошибка это плохой маршрут. Если ты не знаешь путь автоматически, память начинает путаться. Хороший дворец это место, которое ты можешь пройти в голове даже ночью с закрытыми глазами.',
      AppLanguage.en:
          'The fourth mistake is a poor route. If you do not know the path automatically, your memory will start to get confused. A good palace is a place you can walk through in your head even at night with your eyes closed.',
      AppLanguage.de:
          'Der vierte Fehler ist eine schlechte Route. Wenn du den Weg nicht automatisch kennst, gerät dein Gedächtnis durcheinander. Ein guter Palast ist ein Ort, den du im Kopf sogar nachts mit geschlossenen Augen ablaufen kannst.',
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
          'И последняя ошибка это отсутствие практики. Мнемотехника это навык. Первые попытки могут казаться медленными или странными, но со временем мозг начинает создавать связи автоматически. Именно тогда память начинает работать на совершенно другом уровне.',
      AppLanguage.en:
          'The final mistake is a lack of practice. Mnemonics is a skill. Early attempts may seem slow or strange, but over time, the brain begins to create connections automatically. That is when memory starts working on a completely different level.',
      AppLanguage.de:
          'Und der letzte Fehler ist mangelnde Praxis. Mnemotechnik ist eine Fertigkeit. Die ersten Versuche mögen langsam oder seltsam erscheinen, aber mit der Zeit beginnt das Gehirn, Verbindungen automatisch zu erstellen. Genau dann beginnt das Gedächtnis auf einer völlig anderen Ebene zu arbeiten.',
    },
  ),
  LessonSlide(
    icon: Icons.check_circle_outline_rounded,
    title: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    body: <AppLanguage, String>{
      AppLanguage.ru: '',
      AppLanguage.en: '',
      AppLanguage.de: '',
    },
    isCompletion: true,
    hideCompletionText: true,
  ),
];

class MemoryPalaceMistakesLessonScreen extends StatelessWidget {
  const MemoryPalaceMistakesLessonScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return LessonScreen(slides: _kLociMistakesSlides, onFinished: onFinished);
  }
}

const Map<String, List<LessonSlide>> kMemoryPalaceBuiltinSlides =
    <String, List<LessonSlide>>{
  'm4': _kMemoryPalaceMethodSlides,
  'palace_create': _kCreateMemoryPalaceSlides,
  'palace_place_images': _kPlacingImagesSlides,
  'palace_mistakes': _kLociMistakesSlides,
};
