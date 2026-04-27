import '../recovered_app.dart';

class BinaryLessonContent {
  static const binaryData = {
    'title': {
      AppLanguage.ru: 'Бинарные числа: как запоминать сотни нулей и единиц',
      AppLanguage.en: 'Binary Numbers: How to Memorize Hundreds of Zeros and Ones',
      AppLanguage.de: 'Binärzahlen: Wie man Hunderte von Nullen und Einsen auswendig lernt',
    },
    'why_title': {
      AppLanguage.ru: '🧠 Почему мозг не может запоминать бинарный код',
      AppLanguage.en: '🧠 Why the Brain Can\'t Remember Binary Code',
      AppLanguage.de: '🧠 Warum das Gehirn binären Code nicht speichern kann',
    },
    'why_text': {
      AppLanguage.ru:
          'Бинарная лента — это самая абстрактная информация, которую только можно представить: нет образов, эмоций, смысла или структуры. Для мозга «001111010101…» — это просто белый шум.',
      AppLanguage.en:
          'A binary sequence is the most abstract information imaginable: no images, emotions, meaning, or structure. For the brain, "001111010101…" is just white noise.',
      AppLanguage.de:
          'Eine binäre Sequenz ist die abstrakteste Information, die man sich vorstellen kann: keine Bilder, Emotionen, Bedeutung oder Struktur. Für das Gehirn ist „001111010101…“ einfach nur weißes Rauschen.',
    },
    'coding_title': {
      AppLanguage.ru: 'Как работает кодирование бинаров',
      AppLanguage.en: 'How Binary Coding Works',
      AppLanguage.de: 'Wie binäre Kodierung funktioniert',
    },
    'coding_text': {
      AppLanguage.ru:
          'Профессионалы разбивают бинарную ленту на группы по 3 цифры. Почему по 3? Потому что 3 бита дают всего 8 комбинаций — легко запомнить. Каждой комбинации ты назначаешь число от 0 до 7, а затем — образ.',
      AppLanguage.en:
          'Professionals break the binary sequence into groups of 3 digits. Why 3? Because 3 bits give only 8 combinations — easy to remember. You assign a number from 0 to 7 to each combination, and then an image.',
      AppLanguage.de:
          'Profis unterteilen die binäre Sequenz in Gruppen von 3 Ziffern. Warum 3? Weil 3 Bits nur 8 Kombinationen ergeben – leicht zu merken. Jeder Kombination ordnen Sie eine Zahl von 0 bis 7 zu und dann ein Bild.',
    },
    'example_title': {
      AppLanguage.ru: 'Как превращать бинарную ленту в образы',
      AppLanguage.en: 'How to Turn a Binary Sequence into Images',
      AppLanguage.de: 'Wie man eine binäre Sequenz in Bilder verwandelt',
    },
    'example_text': {
      AppLanguage.ru:
          'Бинарная строка: 001111011\nРазбиваем по 3: 001 – 111 – 011\nПревращаем в числа: 1 – 3 – 2\nПревращаем в образы: Лебедь – Тризуб – Лебедь\nСвязываем в цепочку: Лебедь держит огромный тризуб, который пронзает второго лебедя.',
      AppLanguage.en:
          'Binary string: 001111011\nSplit by 3: 001 – 111 – 011\nConvert to numbers: 1 – 3 – 2\nConvert to images: Swan – Trident – Swan\nLink in a chain: A swan holds a huge trident that pierces the second swan.',
      AppLanguage.de:
          'Binärstring: 001111011\nAufgeteilt in 3er-Gruppen: 001 – 111 – 011\nIn Zahlen umwandeln: 1 – 3 – 2\nIn Bilder umwandeln: Schwan – Dreizack – Schwan\nIn einer Kette verbinden: Ein Schwan hält einen riesigen Dreizack, der den zweiten Schwan durchbohrt.',
    },
    'loci_title': {
      AppLanguage.ru: 'Как использовать локи для бинаров',
      AppLanguage.en: 'How to Use Loci for Binaries',
      AppLanguage.de: 'Wie man Loci für Binärzahlen verwendet',
    },
    'loci_text': {
      AppLanguage.ru:
          '1. Создай 10–20 локи (кухня, спальня, коридор...)\n2. Возьми бинарную ленту: 001 111 011 100 010 101\n3. Преврати тройки в образы: Лебедь, Тризуб, Лебедь, Стул...\n4. Размести образы в локи: Локация 1 → Лебедь, Локация 2 → Тризуб...\n5. Визуализируй: всё нужно видеть на мысленном экране.',
      AppLanguage.en:
          '1. Create 10–20 loci (kitchen, bedroom, hallway...)\n2. Take a binary sequence: 001 111 011 100 010 101\n3. Turn triplets into images: Swan, Trident, Swan, Chair...\n4. Place images in loci: Location 1 → Swan, Location 2 → Trident...\n5. Visualize: you need to see everything on your mental screen.',
      AppLanguage.de:
          '1. Erstellen Sie 10–20 Loci (Küche, Schlafzimmer, Flur...)\n2. Nehmen Sie eine Binärsequenz: 001 111 011 100 010 101\n3. Tripletts in Bilder verwandeln: Schwan, Dreizack, Schwan, Stuhl...\n4. Platzieren Sie Bilder in Loci: Ort 1 → Schwan, Ort 2 → Dreizack...\n5. Visualisieren: Sie müssen alles auf Ihrem mentalen Bildschirm sehen.',
    },
    'task_title': {
      AppLanguage.ru: 'Интерактивное упражнение',
      AppLanguage.en: 'Interactive Exercise',
      AppLanguage.de: 'Interaktive Übung',
    },
    'task_text': {
      AppLanguage.ru:
          'Задание 1: Закодируй строку 000 101 010 111 (яблоко, сундук, коса, тризуб).\nЗадание 2: Размести эти 4 образа в первых 4 точках кухни.\nЗадание 3: Проверь себя через 2 минуты: воспроизведи вперёд и назад.',
      AppLanguage.en:
          'Task 1: Code the string 000 101 010 111 (apple, chest, scythe, trident).\nTask 2: Place these 4 images in the first 4 points of the kitchen.\nTask 3: Check yourself in 2 minutes: recall forward and backward.',
      AppLanguage.de:
          'Aufgabe 1: Kodieren Sie den String 000 101 010 111 (Apfel, Truhe, Sense, Dreizack).\nAufgabe 2: Platzieren Sie diese 4 Bilder an den ersten 4 Punkten der Küche.\nAufgabe 3: Überprüfen Sie sich in 2 Minuten: Vorwärts und rückwärts abrufen.',
    },
    'training_text': {
      AppLanguage.ru:
          'Ты можешь тренироваться в разделе “Тренажёр → Бинары”. Там ты будешь кодировать тройки, создавать образы и размещать их в своих локи.',
      AppLanguage.en:
          'You can practice in the "Trainer → Binaries" section. There you will code triplets, create images, and place them in your loci.',
      AppLanguage.de:
          'Du kannst im Bereich „Trainer → Binär“ üben. Dort kodierst du Tripletts, erstellst Bilder und platzierst sie in deinen Loci.',
    },
  };

  static const codingSystem = [
    {'bin': '000', 'num': '0', 'img_ru': 'Яблоко', 'img_en': 'Apple', 'img_de': 'Apfel'},
    {'bin': '001', 'num': '1', 'img_ru': 'Лебедь', 'img_en': 'Swan', 'img_de': 'Schwan'},
    {'bin': '011', 'num': '2', 'img_ru': 'Лебедь (2)', 'img_en': 'Swan (2)', 'img_de': 'Schwan (2)'},
    {'bin': '111', 'num': '3', 'img_ru': 'Тризуб', 'img_en': 'Trident', 'img_de': 'Dreizack'},
    {'bin': '100', 'num': '4', 'img_ru': 'Стул', 'img_en': 'Chair', 'img_de': 'Stuhl'},
    {'bin': '110', 'num': '5', 'img_ru': 'Крюк', 'img_en': 'Hook', 'img_de': 'Haken'},
    {'bin': '101', 'num': '6', 'img_ru': 'Сундук', 'img_en': 'Chest', 'img_de': 'Truhe'},
    {'bin': '010', 'num': '7', 'img_ru': 'Коса', 'img_en': 'Scythe', 'img_de': 'Sense'},
  ];
}

