import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/core/ui_feedback.dart';
import '../recovered_app.dart'
    show appPalette, AppPalette, appLanguage, AppLanguage, LociRoutesScreen, TrainingScreen;
import '../cloud/cloud_sync_service.dart';
import '../public_stats_scoring.dart';
import '../training_history_service.dart';
import 'profile_session_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Localization helper (RU / EN / DE) — lightweight, screen-scoped.
// ─────────────────────────────────────────────────────────────────────────────
class _L10n {
  static const Map<String, Map<AppLanguage, String>> _m = {
    'title': {
      AppLanguage.ru: 'Аналитика',
      AppLanguage.en: 'Analytics',
      AppLanguage.de: 'Analytik',
    },
    'overview': {
      AppLanguage.ru: 'Обзор',
      AppLanguage.en: 'Overview',
      AppLanguage.de: 'Übersicht',
    },
    'rank': {
      AppLanguage.ru: 'Ранг',
      AppLanguage.en: 'Rank',
      AppLanguage.de: 'Rang',
    },
    'avg_score': {
      AppLanguage.ru: 'Средний счёт',
      AppLanguage.en: 'Average score',
      AppLanguage.de: 'Durchschnitt',
    },
    'best_score': {
      AppLanguage.ru: 'Лучший счёт',
      AppLanguage.en: 'Best score',
      AppLanguage.de: 'Bestleistung',
    },
    'sessions': {
      AppLanguage.ru: 'Сессии',
      AppLanguage.en: 'Sessions',
      AppLanguage.de: 'Sitzungen',
    },
    'best_result': {
      AppLanguage.ru: 'Лучший результат',
      AppLanguage.en: 'Best result',
      AppLanguage.de: 'Bestes Ergebnis',
    },
    'accuracy': {
      AppLanguage.ru: 'Точность',
      AppLanguage.en: 'Accuracy',
      AppLanguage.de: 'Genauigkeit',
    },
    'speed': {
      AppLanguage.ru: 'Скорость',
      AppLanguage.en: 'Speed',
      AppLanguage.de: 'Tempo',
    },
    'details': {
      AppLanguage.ru: 'Подробнее',
      AppLanguage.en: 'Details',
      AppLanguage.de: 'Details',
    },
    'history': {
      AppLanguage.ru: 'История',
      AppLanguage.en: 'History',
      AppLanguage.de: 'Verlauf',
    },
    'history_empty': {
      AppLanguage.ru: 'История пуста',
      AppLanguage.en: 'No history yet',
      AppLanguage.de: 'Noch kein Verlauf',
    },
    'history_empty_hint': {
      AppLanguage.ru: 'Заверши тренировку в этой дисциплине, и попытка появится здесь.',
      AppLanguage.en: 'Complete a session in this mode and it will appear here.',
      AppLanguage.de: 'Schließe ein Training in diesem Modus ab, dann erscheint es hier.',
    },
    'history_replay_unavailable': {
      AppLanguage.ru:
          'Для этой попытки не сохранены данные воспроизведения (только дата и результат). Новые тренировки сохраняются полностью.',
      AppLanguage.en:
          'This session has no stored replay data (date and score only). New sessions are saved in full.',
      AppLanguage.de:
          'Für diese Sitzung gibt es keine Wiedergabedaten (nur Datum und Ergebnis). Neue Sitzungen werden vollständig gespeichert.',
    },
    'open_result': {
      AppLanguage.ru: 'Открыть результат',
      AppLanguage.en: 'Open result',
      AppLanguage.de: 'Ergebnis öffnen',
    },
    'history_delete_title': {
      AppLanguage.ru: 'Удалить тренировку?',
      AppLanguage.en: 'Delete this session?',
      AppLanguage.de: 'Sitzung loeschen?',
    },
    'history_delete_body': {
      AppLanguage.ru:
          'Запись исчезнет из истории, а результат этой попытки будет исключён из статистики этого режима (средний %, лучший счёт, число сессий).',
      AppLanguage.en:
          'This removes the session from history and excludes it from this mode’s stats (average %, best score, session count).',
      AppLanguage.de:
          'Die Sitzung wird aus dem Verlauf entfernt und aus den Statistiken dieses Modus ausgeschlossen (Durchschnitt %, Bestwert, Anzahl).',
    },
    'history_deleted': {
      AppLanguage.ru: 'Тренировка удалена',
      AppLanguage.en: 'Session removed',
      AppLanguage.de: 'Sitzung entfernt',
    },
    'history_delete_cancel': {
      AppLanguage.ru: 'Отмена',
      AppLanguage.en: 'Cancel',
      AppLanguage.de: 'Abbrechen',
    },
    'history_delete_confirm': {
      AppLanguage.ru: 'Удалить',
      AppLanguage.en: 'Delete',
      AppLanguage.de: 'Loeschen',
    },
    'numbers': {
      AppLanguage.ru: 'Числа',
      AppLanguage.en: 'Numbers',
      AppLanguage.de: 'Zahlen',
    },
    'binary': {
      AppLanguage.ru: 'Бинарные',
      AppLanguage.en: 'Binary',
      AppLanguage.de: 'Binär',
    },
    'words': {
      AppLanguage.ru: 'Слова',
      AppLanguage.en: 'Words',
      AppLanguage.de: 'Wörter',
    },
    'images': {
      AppLanguage.ru: 'Изображения',
      AppLanguage.en: 'Images',
      AppLanguage.de: 'Bilder',
    },
    'cards': {
      AppLanguage.ru: 'Карты',
      AppLanguage.en: 'Cards',
      AppLanguage.de: 'Karten',
    },
    'faces': {
      AppLanguage.ru: 'Лица',
      AppLanguage.en: 'Faces',
      AppLanguage.de: 'Gesichter',
    },
    'no_data': {
      AppLanguage.ru: 'Пока нет данных',
      AppLanguage.en: 'No data yet',
      AppLanguage.de: 'Noch keine Daten',
    },
    'no_data_hint': {
      AppLanguage.ru: 'Заверши пару тренировок, чтобы увидеть аналитику.',
      AppLanguage.en: 'Complete a few training sessions to unlock analytics.',
      AppLanguage.de: 'Schließe ein paar Sitzungen ab, um Analysen zu sehen.',
    },
    'session_score': {
      AppLanguage.ru: 'Счёт сессии',
      AppLanguage.en: 'Session score',
      AppLanguage.de: 'Sitzungsscore',
    },
    'best_session': {
      AppLanguage.ru: 'Лучшая сессия',
      AppLanguage.en: 'Best session',
      AppLanguage.de: 'Beste Sitzung',
    },
    'speed_per_segment': {
      AppLanguage.ru: 'Скорость по сегментам',
      AppLanguage.en: 'Speed per segment',
      AppLanguage.de: 'Tempo pro Segment',
    },
    'memory_degradation': {
      AppLanguage.ru: 'Деградация памяти',
      AppLanguage.en: 'Memory degradation',
      AppLanguage.de: 'Gedächtnisverlust',
    },
    'consistency': {
      AppLanguage.ru: 'Стабильность',
      AppLanguage.en: 'Consistency',
      AppLanguage.de: 'Konstanz',
    },
    'optimal_length': {
      AppLanguage.ru: 'Оптимальная длина',
      AppLanguage.en: 'Optimal length',
      AppLanguage.de: 'Optimale Länge',
    },
    'prediction': {
      AppLanguage.ru: 'Прогноз',
      AppLanguage.en: 'Prediction',
      AppLanguage.de: 'Prognose',
    },
    'encoding_recall': {
      AppLanguage.ru: 'Кодирование vs. Воспроизведение',
      AppLanguage.en: 'Encoding vs. Recall',
      AppLanguage.de: 'Codierung vs. Abruf',
    },
    'encoding': {
      AppLanguage.ru: 'Кодирование',
      AppLanguage.en: 'Encoding',
      AppLanguage.de: 'Codierung',
    },
    'recall': {
      AppLanguage.ru: 'Воспроизведение',
      AppLanguage.en: 'Recall',
      AppLanguage.de: 'Abruf',
    },
    'sec_per_item': {
      AppLanguage.ru: 'сек/эл',
      AppLanguage.en: 'sec/item',
      AppLanguage.de: 's/El',
    },
    'block': {
      AppLanguage.ru: 'Блок',
      AppLanguage.en: 'Block',
      AppLanguage.de: 'Block',
    },
    'stable': {
      AppLanguage.ru: 'Стабильно',
      AppLanguage.en: 'Stable',
      AppLanguage.de: 'Stabil',
    },
    'unstable': {
      AppLanguage.ru: 'Нестабильно',
      AppLanguage.en: 'Unstable',
      AppLanguage.de: 'Instabil',
    },
    'avg': {
      AppLanguage.ru: 'Среднее',
      AppLanguage.en: 'Average',
      AppLanguage.de: 'Durchschnitt',
    },
    'best': {
      AppLanguage.ru: 'Лучшее',
      AppLanguage.en: 'Best',
      AppLanguage.de: 'Beste',
    },
    'optimal_msg': {
      AppLanguage.ru: 'Твоя оптимальная длина — {n} элементов',
      AppLanguage.en: 'Your optimal length is {n} items',
      AppLanguage.de: 'Optimale Länge: {n} Elemente',
    },
    'expected_in_7': {
      AppLanguage.ru: 'Через 7 дней: {n} элементов',
      AppLanguage.en: 'In 7 days: {n} items',
      AppLanguage.de: 'In 7 Tagen: {n} Elemente',
    },
    'expected_in_30': {
      AppLanguage.ru: 'Через 30 дней: {n} элементов',
      AppLanguage.en: 'In 30 days: {n} items',
      AppLanguage.de: 'In 30 Tagen: {n} Elemente',
    },
    'accuracy_drops_after': {
      AppLanguage.ru: 'Точность падает после {n} элементов',
      AppLanguage.en: 'Accuracy drops after {n} items',
      AppLanguage.de: 'Genauigkeit sinkt nach {n} Elementen',
    },
    'no_drop': {
      AppLanguage.ru: 'Точность стабильна по всей сессии',
      AppLanguage.en: 'Accuracy is stable across the session',
      AppLanguage.de: 'Genauigkeit ist stabil',
    },
    'last_sessions': {
      AppLanguage.ru: 'Последние сессии',
      AppLanguage.en: 'Recent sessions',
      AppLanguage.de: 'Letzte Sitzungen',
    },
    'progress': {
      AppLanguage.ru: 'Прогресс',
      AppLanguage.en: 'Progress',
      AppLanguage.de: 'Fortschritt',
    },
    'rank_beginner': {
      AppLanguage.ru: 'Новичок',
      AppLanguage.en: 'Beginner',
      AppLanguage.de: 'Anfänger',
    },
    'rank_advanced': {
      AppLanguage.ru: 'Продвинутый',
      AppLanguage.en: 'Advanced',
      AppLanguage.de: 'Fortgeschritten',
    },
    'rank_elite': {
      AppLanguage.ru: 'Элита',
      AppLanguage.en: 'Elite',
      AppLanguage.de: 'Elite',
    },
    'rank_master': {
      AppLanguage.ru: 'Мастер',
      AppLanguage.en: 'Master',
      AppLanguage.de: 'Meister',
    },
    'help': {
      AppLanguage.ru: 'Справка',
      AppLanguage.en: 'Help',
      AppLanguage.de: 'Hilfe',
    },
    'close': {
      AppLanguage.ru: 'Понятно',
      AppLanguage.en: 'Got it',
      AppLanguage.de: 'Verstanden',
    },
    'score_subtitle': {
      AppLanguage.ru: 'формула: правильные × точность / время',
      AppLanguage.en: 'formula: correct × accuracy / time',
      AppLanguage.de: 'Formel: richtige × Genauigkeit / Zeit',
    },
    'speed_segment_subtitle': {
      AppLanguage.ru: 'время / правильные элементы в блоке',
      AppLanguage.en: 'time / correct items per chunk',
      AppLanguage.de: 'Zeit / richtige Elemente pro Block',
    },
    'degradation_subtitle': {
      AppLanguage.ru: 'точность по ходу сессии',
      AppLanguage.en: 'accuracy across the session',
      AppLanguage.de: 'Genauigkeit im Sitzungsverlauf',
    },
    'consistency_subtitle': {
      AppLanguage.ru: 'ниже разброс — выше стабильность',
      AppLanguage.en: 'lower deviation = higher consistency',
      AppLanguage.de: 'geringere Abweichung = höhere Konstanz',
    },
    'optimal_subtitle': {
      AppLanguage.ru: 'эффективность = точность / скорость',
      AppLanguage.en: 'efficiency = accuracy / speed',
      AppLanguage.de: 'Effizienz = Genauigkeit / Tempo',
    },
    'prediction_subtitle': {
      AppLanguage.ru: 'линейный прогноз прогресса',
      AppLanguage.en: 'linear projection of progress',
      AppLanguage.de: 'lineare Fortschrittsprognose',
    },
    'prediction_items_subtitle': {
      AppLanguage.ru: 'ожидаемое количество элементов',
      AppLanguage.en: 'expected items count',
      AppLanguage.de: 'erwartete Elementanzahl',
    },
    'loci_quality': {
      AppLanguage.ru: 'Качество Loci',
      AppLanguage.en: 'Loci quality',
      AppLanguage.de: 'Loci-Qualitaet',
    },
    'loci_quality_subtitle': {
      AppLanguage.ru: 'ошибки и время по привязанным точкам маршрута',
      AppLanguage.en: 'errors and speed by attached route points',
      AppLanguage.de: 'Fehler und Tempo pro verknuepftem Routenpunkt',
    },
    'loci_no_data': {
      AppLanguage.ru: 'Нет данных по привязкам Loci',
      AppLanguage.en: 'No loci binding data yet',
      AppLanguage.de: 'Noch keine Loci-Bindungsdaten',
    },
    'loci_top_risk': {
      AppLanguage.ru: 'Точка риска',
      AppLanguage.en: 'Top risk locus',
      AppLanguage.de: 'Risikopunkt',
    },
    'loci_error_rate': {
      AppLanguage.ru: 'Ошибка',
      AppLanguage.en: 'Error rate',
      AppLanguage.de: 'Fehlerrate',
    },
    'loci_avg_time': {
      AppLanguage.ru: 'Среднее время',
      AppLanguage.en: 'Average time',
      AppLanguage.de: 'Durchschnittszeit',
    },
    'loci_confidence': {
      AppLanguage.ru: 'Надежность',
      AppLanguage.en: 'Confidence',
      AppLanguage.de: 'Vertrauen',
    },
    'loci_risk': {
      AppLanguage.ru: 'Риск',
      AppLanguage.en: 'Risk',
      AppLanguage.de: 'Risiko',
    },
    'loci_attempts': {
      AppLanguage.ru: 'попыток',
      AppLanguage.en: 'attempts',
      AppLanguage.de: 'Versuche',
    },
    'help_loci_quality': {
      AppLanguage.ru: 'Для каждой точки Loci считаются попытки, ошибки и среднее время на элемент. Risk score = (0.7 × errorRate + 0.3 × timePenalty) × confidence, где confidence растёт с числом попыток. Так ты видишь, какие точки маршрута дают больше всего сбоев.',
      AppLanguage.en: 'For each locus we compute attempts, mistakes, and average time per item. Risk score = (0.7 × errorRate + 0.3 × timePenalty) × confidence, where confidence increases with sample count. This highlights the loci that cause the most failures.',
      AppLanguage.de: 'Fuer jeden Locus berechnen wir Versuche, Fehler und die durchschnittliche Zeit pro Element. Risk score = (0.7 × Fehlerrate + 0.3 × Zeitstrafe) × Vertrauen, wobei Vertrauen mit der Anzahl der Versuche steigt. So erkennst du problematische Loci.',
    },
    'help_session_score': {
      AppLanguage.ru: 'Показывает качество сессии одним числом. Счёт растёт, когда ты запоминаешь больше, делаешь меньше ошибок и тратишь меньше времени. Это удобно для сравнения разных попыток между собой.',
      AppLanguage.en: 'Shows session quality as one number. The score improves when you remember more, make fewer mistakes, and spend less time. Use it to compare attempts fairly.',
      AppLanguage.de: 'Zeigt die Sitzungsqualität als eine Zahl. Der Score steigt, wenn du mehr behältst, weniger Fehler machst und weniger Zeit brauchst. So kannst du Versuche fair vergleichen.',
    },
    'help_encoding_recall': {
      AppLanguage.ru: 'Разделяет скорость запоминания и скорость воспроизведения. Если кодирование медленное, стоит улучшать способ создания образов. Если медленное воспроизведение — тренировать извлечение и порядок.',
      AppLanguage.en: 'Separates memorization speed from recall speed. Slow encoding means the image-building method needs work. Slow recall means retrieval and order practice matter more.',
      AppLanguage.de: 'Trennt Einprägungstempo und Abruftempo. Langsame Codierung deutet auf bessere Bildbildung hin. Langsamer Abruf bedeutet: Abruf und Reihenfolge üben.',
    },
    'help_speed_segment': {
      AppLanguage.ru: 'Делит последнюю сессию на блоки по 5 или 10 элементов и считает секунды на один правильный элемент. Жёлтые блоки — места, где темп заметно проседает.',
      AppLanguage.en: 'Splits the latest session into 5- or 10-item blocks and calculates seconds per correct item. Yellow blocks show where your pace drops noticeably.',
      AppLanguage.de: 'Teilt die letzte Sitzung in Blöcke mit 5 oder 10 Elementen und berechnet Sekunden pro richtiges Element. Gelbe Blöcke zeigen deutliche Tempoeinbrüche.',
    },
    'help_memory_degradation': {
      AppLanguage.ru: 'Показывает, где в последовательности начинает падать точность. Это помогает понять, после какого количества элементов память перегружается и где нужно делать паузу или менять стратегию.',
      AppLanguage.en: 'Shows where accuracy starts dropping across the sequence. It helps identify when memory load becomes too high and where you may need a pause or strategy change.',
      AppLanguage.de: 'Zeigt, wo die Genauigkeit in der Sequenz sinkt. So erkennst du, ab wann die Belastung zu hoch wird und wo Pause oder Strategieänderung helfen.',
    },
    'help_consistency': {
      AppLanguage.ru: 'Оценивает стабильность последних результатов через разброс счёта. Высокая стабильность значит, что результат предсказуемый, низкая — что попытки сильно скачут.',
      AppLanguage.en: 'Measures stability of recent results using score deviation. High consistency means results are predictable; low consistency means attempts vary a lot.',
      AppLanguage.de: 'Misst die Stabilität der letzten Ergebnisse über die Score-Abweichung. Hohe Konstanz bedeutet vorhersagbare Ergebnisse; niedrige Konstanz starke Schwankungen.',
    },
    'help_optimal_length': {
      AppLanguage.ru: 'Ищет длину тренировки, где эффективность максимальна: точность высокая, а скорость не проседает. Это подсказка, с каким количеством элементов сейчас лучше тренироваться.',
      AppLanguage.en: 'Finds the training length with the best efficiency: high accuracy without a major speed drop. It suggests how many items are best for your current level.',
      AppLanguage.de: 'Findet die Trainingslänge mit der besten Effizienz: hohe Genauigkeit ohne starken Tempoverlust. Das zeigt, wie viele Elemente aktuell sinnvoll sind.',
    },
    'help_prediction': {
      AppLanguage.ru: 'Строит простой линейный прогноз по последним сессиям. Он не гарантирует результат, но показывает направление прогресса и примерный ожидаемый уровень через 7 и 30 дней.',
      AppLanguage.en: 'Builds a simple linear forecast from recent sessions. It does not guarantee results, but shows progress direction and a rough expected level in 7 and 30 days.',
      AppLanguage.de: 'Erstellt eine einfache lineare Prognose aus den letzten Sitzungen. Sie garantiert nichts, zeigt aber Richtung und grobe Erwartung für 7 und 30 Tage.',
    },
    'readiness': {
      AppLanguage.ru: 'Готовность',
      AppLanguage.en: 'Readiness',
      AppLanguage.de: 'Bereitschaft',
    },
    'readiness_subtitle': {
      AppLanguage.ru: 'насколько ты готов к сильной следующей сессии',
      AppLanguage.en: 'how ready you are for a strong next session',
      AppLanguage.de: 'wie bereit du fuer eine starke naechste Sitzung bist',
    },
    'plateau_detector': {
      AppLanguage.ru: 'Детектор плато',
      AppLanguage.en: 'Plateau detector',
      AppLanguage.de: 'Plateau-Erkennung',
    },
    'retention_drift': {
      AppLanguage.ru: 'Сдвиг удержания',
      AppLanguage.en: 'Retention drift',
      AppLanguage.de: 'Behalte-Drift',
    },
    'pb_chance': {
      AppLanguage.ru: 'Шанс нового рекорда',
      AppLanguage.en: 'PB probability',
      AppLanguage.de: 'PB-Wahrscheinlichkeit',
    },
    'circadian': {
      AppLanguage.ru: 'Циркадные часы',
      AppLanguage.en: 'Circadian window',
      AppLanguage.de: 'Zirkadianes Fenster',
    },
    'error_taxonomy': {
      AppLanguage.ru: 'Классификация ошибок',
      AppLanguage.en: 'Error taxonomy',
      AppLanguage.de: 'Fehler-Taxonomie',
    },
    'show_loci_full': {
      AppLanguage.ru: 'Показать полный список Loci ({n})',
      AppLanguage.en: 'Show full loci list ({n})',
      AppLanguage.de: 'Vollstaendige Loci-Liste anzeigen ({n})',
    },
    'hide_loci_full': {
      AppLanguage.ru: 'Скрыть полный список Loci',
      AppLanguage.en: 'Hide full loci list',
      AppLanguage.de: 'Vollstaendige Loci-Liste ausblenden',
    },
    'readiness_high': {
      AppLanguage.ru: 'Высокая готовность',
      AppLanguage.en: 'High readiness',
      AppLanguage.de: 'Hohe Bereitschaft',
    },
    'readiness_mid': {
      AppLanguage.ru: 'Средняя готовность',
      AppLanguage.en: 'Moderate readiness',
      AppLanguage.de: 'Mittlere Bereitschaft',
    },
    'readiness_low': {
      AppLanguage.ru: 'Низкая готовность',
      AppLanguage.en: 'Low readiness',
      AppLanguage.de: 'Niedrige Bereitschaft',
    },
    'plateau_subtitle': {
      AppLanguage.ru: 'определение застоя по тренду рекордного счёта',
      AppLanguage.en: 'detects stagnation from record-score trend',
      AppLanguage.de: 'erkennt Stagnation aus dem Rekordscore-Trend',
    },
    'plateau_yes': {
      AppLanguage.ru: 'Похоже на плато. Попробуй изменить длину сессии или добавить восстановительные паузы.',
      AppLanguage.en: 'Possible plateau detected. Try changing session length or adding recovery breaks.',
      AppLanguage.de: 'Moegliches Plateau erkannt. Versuche Sitzungslaenge zu aendern oder Erholungspausen einzubauen.',
    },
    'plateau_no': {
      AppLanguage.ru: 'Прогресс продолжается. Сохраняй текущую структуру и отслеживай стабильность.',
      AppLanguage.en: 'Progress is still moving. Keep current structure and monitor consistency.',
      AppLanguage.de: 'Der Fortschritt bewegt sich weiter. Behalte die Struktur bei und beobachte die Konstanz.',
    },
    'retention_subtitle': {
      AppLanguage.ru: 'последние 5 сессий против предыдущих 5',
      AppLanguage.en: 'last 5 sessions versus previous 5',
      AppLanguage.de: 'letzte 5 Sitzungen gegen die vorherigen 5',
    },
    'retention_delta': {
      AppLanguage.ru: 'Последние 5 сессий vs предыдущие 5: {v}',
      AppLanguage.en: 'Last 5 sessions vs previous 5: {v}',
      AppLanguage.de: 'Letzte 5 Sitzungen vs vorherige 5: {v}',
    },
    'pb_subtitle': {
      AppLanguage.ru: 'вероятность обновить личный рекорд',
      AppLanguage.en: 'chance to beat your personal best',
      AppLanguage.de: 'Chance, den persoenlichen Rekord zu schlagen',
    },
    'pb_estimate': {
      AppLanguage.ru: 'Оценка шанса побить рекорд в следующих 5 сессиях: {n}%',
      AppLanguage.en: 'Estimated chance to beat PB in next 5 sessions: {n}%',
      AppLanguage.de: 'Geschaetzte Chance, PB in den naechsten 5 Sitzungen zu schlagen: {n}%',
    },
    'circadian_subtitle': {
      AppLanguage.ru: 'лучшее окно суток по твоим фактическим результатам',
      AppLanguage.en: 'best hour window from your actual performance',
      AppLanguage.de: 'bestes Zeitfenster basierend auf deiner Leistung',
    },
    'circadian_window': {
      AppLanguage.ru: 'Лучшее окно производительности: {from}:00-{to}:00',
      AppLanguage.en: 'Best performance window: {from}:00-{to}:00',
      AppLanguage.de: 'Bestes Leistungsfenster: {from}:00-{to}:00',
    },
    'error_subtitle': {
      AppLanguage.ru: 'распределение ошибок по типам',
      AppLanguage.en: 'breakdown of mistakes by type',
      AppLanguage.de: 'Aufteilung der Fehler nach Typ',
    },
    'error_substitution': {
      AppLanguage.ru: 'Подмена',
      AppLanguage.en: 'Substitution',
      AppLanguage.de: 'Ersetzung',
    },
    'error_omission': {
      AppLanguage.ru: 'Пропуск',
      AppLanguage.en: 'Omission',
      AppLanguage.de: 'Auslassung',
    },
    'error_order': {
      AppLanguage.ru: 'Нарушение порядка',
      AppLanguage.en: 'Order mistakes',
      AppLanguage.de: 'Reihenfolgefehler',
    },
    'help_readiness': {
      AppLanguage.ru: 'Готовность = 45% точность + 35% стабильность + 20% темп (обратная сек/элемент) по последним сессиям. Чем выше значение, тем выше шанс на сильную следующую попытку.',
      AppLanguage.en: 'Readiness = 45% accuracy + 35% consistency + 20% pace (inverse sec/item) from recent sessions. Higher value means you are more likely to deliver a strong next attempt.',
      AppLanguage.de: 'Bereitschaft = 45% Genauigkeit + 35% Konstanz + 20% Tempo (inverse Sek/Element) aus den letzten Sitzungen. Hoeherer Wert bedeutet hoehere Chance auf eine starke naechste Leistung.',
    },
    'help_plateau': {
      AppLanguage.ru: 'Считается линейный тренд рекордного счёта за последние сессии. Если наклон почти нулевой, система помечает возможное плато.',
      AppLanguage.en: 'A linear trend of record score is computed over recent sessions. If the slope is close to zero, the system marks a possible plateau.',
      AppLanguage.de: 'Es wird ein linearer Trend des Rekordscores ueber die letzten Sitzungen berechnet. Ist die Steigung nahezu null, wird ein moegliches Plateau markiert.',
    },
    'help_retention': {
      AppLanguage.ru: 'Сравнивается средняя точность последних 5 сессий со средними 5 сессиями до них. Плюс значит улучшение удержания, минус — просадка.',
      AppLanguage.en: 'Average accuracy of the last 5 sessions is compared with the previous 5. Positive means retention improved, negative means decline.',
      AppLanguage.de: 'Die durchschnittliche Genauigkeit der letzten 5 Sitzungen wird mit den vorherigen 5 verglichen. Positiv bedeutet bessere Behaltensleistung, negativ einen Rueckgang.',
    },
    'help_pb': {
      AppLanguage.ru: 'Оценивается вероятность побить PB по распределению последних результатов (среднее и разброс). Это вероятностная подсказка, а не гарантия.',
      AppLanguage.en: 'PB probability is estimated from recent result distribution (mean and variance). It is a probabilistic hint, not a guarantee.',
      AppLanguage.de: 'Die PB-Wahrscheinlichkeit wird aus der Verteilung der letzten Ergebnisse (Mittelwert und Streuung) geschaetzt. Das ist ein probabilistischer Hinweis, keine Garantie.',
    },
    'help_circadian': {
      AppLanguage.ru: 'Сессии группируются по часу начала, и для каждого часа считается средний рекордный счёт. Показывается окно с лучшим средним значением.',
      AppLanguage.en: 'Sessions are grouped by start hour, and average record score is computed for each hour. The best-performing hour window is shown.',
      AppLanguage.de: 'Sitzungen werden nach Startstunde gruppiert und pro Stunde wird der durchschnittliche Rekordscore berechnet. Angezeigt wird das beste Zeitfenster.',
    },
    'help_error_taxonomy': {
      AppLanguage.ru: 'Ошибки делятся на три типа: подмена (неверный ответ), пропуск (пустой/отсутствующий ответ), нарушение порядка (элемент всплыл на соседней позиции). Это помогает понять, что именно тренировать.',
      AppLanguage.en: 'Mistakes are split into three types: substitution (wrong answer), omission (empty/missing answer), and order mistakes (item appears at neighboring position). This shows what to train next.',
      AppLanguage.de: 'Fehler werden in drei Typen aufgeteilt: Ersetzung (falsche Antwort), Auslassung (leere/fehlende Antwort) und Reihenfolgefehler (Element an benachbarter Position). So siehst du, woran du arbeiten solltest.',
    },
  };

  static String t(String key, [Map<String, String>? params]) {
    final m = _m[key];
    if (m == null) return key;
    String s = m[appLanguage.value] ?? m[AppLanguage.en] ?? key;
    if (params != null) {
      params.forEach((k, v) => s = s.replaceAll('{$k}', v));
    }
    return s;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme-adaptive surface tokens. Reads `appPalette` for accent + dark surfaces,
// flips background/surface/onSurface for light theme.
// ─────────────────────────────────────────────────────────────────────────────
class _Surface {
  final Color background;
  final Color card;
  final Color cardSubtle;
  final Color border;
  final Color onSurface;
  final Color onSurfaceMuted;
  final Color accent;
  final Color warning;
  final Color success;
  final Color danger;
  final bool isDark;

  const _Surface({
    required this.background,
    required this.card,
    required this.cardSubtle,
    required this.border,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.accent,
    required this.warning,
    required this.success,
    required this.danger,
    required this.isDark,
  });

  static _Surface of(BuildContext context, AppPalette palette) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return _Surface(
        background: palette.background,
        card: palette.surface,
        cardSubtle: palette.card,
        border: palette.border,
        onSurface: Colors.white,
        onSurfaceMuted: Colors.white.withOpacity(0.55),
        accent: palette.accent,
        warning: const Color(0xFFFFB454),
        success: const Color(0xFF34D399),
        danger: const Color(0xFFFF6B6B),
        isDark: true,
      );
    }
    return _Surface(
      background: const Color(0xFFF8F9FB),
      card: Colors.white,
      cardSubtle: const Color(0xFFF1F3F6),
      border: const Color(0xFFE2E5EA),
      onSurface: const Color(0xFF0E1014),
      onSurfaceMuted: const Color(0xFF0E1014).withOpacity(0.55),
      accent: palette.accent,
      warning: const Color(0xFFE08A2E),
      success: const Color(0xFF1FA37A),
      danger: const Color(0xFFD24C4C),
      isDark: false,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mode metadata.
// ─────────────────────────────────────────────────────────────────────────────
const List<String> _kModeOrder = [
  'standard',
  'binary',
  'words',
  'images',
  'cards',
  'faces',
];

String _modeKeyToLabel(String mode) {
  switch (mode) {
    case 'standard':
      return _L10n.t('numbers');
    case 'binary':
      return _L10n.t('binary');
    case 'words':
      return _L10n.t('words');
    case 'images':
      return _L10n.t('images');
    case 'cards':
      return _L10n.t('cards');
    case 'faces':
      return _L10n.t('faces');
  }
  return mode;
}

IconData _modeIcon(String mode) {
  switch (mode) {
    case 'standard':
      return Icons.numbers_rounded;
    case 'binary':
      return Icons.data_array_rounded;
    case 'words':
      return Icons.abc_rounded;
    case 'images':
      return Icons.image_outlined;
    case 'cards':
      return Icons.style_outlined;
    case 'faces':
      return Icons.face_retouching_natural_outlined;
  }
  return Icons.stacked_line_chart_rounded;
}

// ─────────────────────────────────────────────────────────────────────────────
// Rank model.
// ─────────────────────────────────────────────────────────────────────────────
enum _RankTier { beginner, advanced, elite, master }

class _RankInfo {
  final _RankTier tier;
  final String label;
  final double progress; // 0..1 within current tier toward next
  final double avgScore;

  const _RankInfo({
    required this.tier,
    required this.label,
    required this.progress,
    required this.avgScore,
  });

  Color color(_Surface s) {
    switch (tier) {
      case _RankTier.beginner:
        return const Color(0xFF7AB7E6);
      case _RankTier.advanced:
        return const Color(0xFF35F0A2);
      case _RankTier.elite:
        return const Color(0xFFB983FF);
      case _RankTier.master:
        return const Color(0xFFFFC94A);
    }
  }
}

_RankInfo _computeRank(List<ProfileSessionEntry> all) {
  if (all.isEmpty) {
    return _RankInfo(
      tier: _RankTier.beginner,
      label: _L10n.t('rank_beginner'),
      progress: 0,
      avgScore: 0,
    );
  }
  // Use average of last 20 sessions for responsiveness.
  final recent = all.length <= 20 ? all : all.sublist(0, 20);
  final scores = recent.map((e) => e.score).toList();
  final avg = scores.reduce((a, b) => a + b) / scores.length;

  const t1 = 0.10;
  const t2 = 0.25;
  const t3 = 0.50;

  _RankTier tier;
  double progress;
  if (avg < t1) {
    tier = _RankTier.beginner;
    progress = (avg / t1).clamp(0.0, 1.0);
  } else if (avg < t2) {
    tier = _RankTier.advanced;
    progress = ((avg - t1) / (t2 - t1)).clamp(0.0, 1.0);
  } else if (avg < t3) {
    tier = _RankTier.elite;
    progress = ((avg - t2) / (t3 - t2)).clamp(0.0, 1.0);
  } else {
    tier = _RankTier.master;
    progress = 1.0;
  }

  String label;
  switch (tier) {
    case _RankTier.beginner:
      label = _L10n.t('rank_beginner');
      break;
    case _RankTier.advanced:
      label = _L10n.t('rank_advanced');
      break;
    case _RankTier.elite:
      label = _L10n.t('rank_elite');
      break;
    case _RankTier.master:
      label = _L10n.t('rank_master');
      break;
  }
  return _RankInfo(tier: tier, label: label, progress: progress, avgScore: avg);
}

// ─────────────────────────────────────────────────────────────────────────────
// Main entry — Premium Statistics Screen.
// ─────────────────────────────────────────────────────────────────────────────
class PremiumStatisticsScreen extends StatefulWidget {
  const PremiumStatisticsScreen({super.key});

  @override
  State<PremiumStatisticsScreen> createState() =>
      _PremiumStatisticsScreenState();
}

class _PremiumStatisticsScreenState extends State<PremiumStatisticsScreen> {
  late Future<_Snapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadSnapshot();
  }

  Future<_Snapshot> _loadSnapshot() async {
    final cloudHistory = await CloudSyncService.instance.fetchTrainingHistory();
    if (cloudHistory.isNotEmpty) {
      for (final mode in _kModeOrder) {
        await TrainingHistoryService.instance.mergeFromCloud(
          mode,
          cloudHistory.where((e) => e.mode == mode).toList(growable: false),
        );
      }
    }
    final profileSessions = await ProfileSessionService.instance.loadSessions();
    final historySessions = await _loadHistoryAsProfileSessions();
    final all = profileSessions.isEmpty ? historySessions : profileSessions;
    final summaries = profileSessions.isEmpty
        ? _buildSummariesFromSessions(historySessions)
        : await ProfileSessionService.instance.buildModeSummaries();
    return _Snapshot(summaries: summaries, allSessions: all);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadSnapshot();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppPalette>(
      valueListenable: appPalette,
      builder: (context, palette, _) {
        final s = _Surface.of(context, palette);
        return Scaffold(
          backgroundColor: s.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: s.onSurface,
            title: Text(
              _L10n.t('title'),
              style: TextStyle(
                color: s.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
              ),
            ),
          ),
          body: FutureBuilder<_Snapshot>(
            future: _future,
            builder: (context, snap) {
              final ready = snap.connectionState == ConnectionState.done;
              final snapshot = snap.data;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                child: !ready || snapshot == null
                    ? const Center(
                        key: ValueKey('loading'),
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 1.6),
                        ),
                      )
                    : _buildBody(s, snapshot),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBody(_Surface s, _Snapshot snap) {
    final rank = _computeRank(snap.allSessions);
    final hasAny = snap.allSessions.isNotEmpty;

    return RefreshIndicator(
      onRefresh: _refresh,
      color: s.accent,
      backgroundColor: s.card,
      child: ListView(
        key: const ValueKey('list'),
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          _RankHeader(surface: s, info: rank, totalSessions: snap.allSessions.length),
          const SizedBox(height: 18),
          if (!hasAny)
            _EmptyHint(surface: s)
          else ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                _L10n.t('overview').toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 2,
                  color: s.onSurfaceMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ..._kModeOrder.asMap().entries.map((entry) {
              final i = entry.key;
              final mode = entry.value;
              final summary = snap.summaries[mode];
              if (summary == null) return const SizedBox.shrink();
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 320 + i * 70),
                curve: Curves.easeOutCubic,
                builder: (context, t, child) {
                  return Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, (1 - t) * 12),
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ModeCard(
                    surface: s,
                    mode: mode,
                    summary: summary,
                    onHistory: () async {
                      uiTapClick(UiClickSound.soft);
                      await Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => TrainingHistoryScreen(mode: mode),
                          settings: RouteSettings(name: 'TrainingHistory/$mode'),
                        ),
                      );
                      if (!mounted) return;
                      await _refresh();
                    },
                    onDetails: () {
                      if (summary.totalSessions == 0) return;
                      uiTapClick(UiClickSound.soft);
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration:
                              const Duration(milliseconds: 320),
                          pageBuilder: (_, __, ___) =>
                              ModeStatsDetailScreen(mode: mode),
                          transitionsBuilder: (_, anim, __, child) =>
                              FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.04),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: anim,
                                curve: Curves.easeOutCubic,
                              )),
                              child: child,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _Snapshot {
  final Map<String, ModeProfileSummary> summaries;
  final List<ProfileSessionEntry> allSessions;
  const _Snapshot({required this.summaries, required this.allSessions});
}

Future<List<ProfileSessionEntry>> _loadHistoryAsProfileSessions() async {
  final out = <ProfileSessionEntry>[];
  for (final mode in _kModeOrder) {
    final entries = await TrainingHistoryService.instance.loadMode(mode);
    for (final e in entries) {
      out.add(ProfileSessionEntry(
        mode: e.mode,
        totalItems: e.totalItems,
        correctItems: e.correctItems,
        timeSeconds: math.max(1, ((e.memorizationMs + e.recallMs) / 1000).round()),
        date: e.date,
        encodingMs: e.memorizationMs,
        recallMs: e.recallMs,
        correctnessPattern: e.correctnessPattern,
        recordScore: PublicStatsScoring.scoreFromTrainingEntry(e),
      ));
    }
  }
  out.sort((a, b) => b.date.compareTo(a.date));
  return out;
}

Map<String, ModeProfileSummary> _buildSummariesFromSessions(List<ProfileSessionEntry> all) {
  final byMode = <String, List<ProfileSessionEntry>>{
    for (final m in _kModeOrder) m: <ProfileSessionEntry>[],
  };
  for (final s in all) {
    if (byMode.containsKey(s.mode)) byMode[s.mode]!.add(s);
  }

  final result = <String, ModeProfileSummary>{};
  for (final mode in _kModeOrder) {
    final sessions = byMode[mode] ?? const <ProfileSessionEntry>[];
    if (sessions.isEmpty) {
      result[mode] = ModeProfileSummary(
        mode: mode,
        bestCorrectItems: 0,
        bestRecordScore: 0,
        bestAccuracy: 0,
        bestSpeed: 0,
        bestScore: 0,
        bestTime: 0,
        totalSessions: 0,
        sessions: const [],
        bestSessionIndex: -1,
      );
      continue;
    }
    final records = sessions.map((s) => s.toSessionRecord()).toList(growable: false);
    final picked = PublicStatsScoring.pickBestSessionIndex(records);
    if (picked < 0) {
      result[mode] = ModeProfileSummary(
        mode: mode,
        bestCorrectItems: 0,
        bestRecordScore: 0,
        bestAccuracy: 0,
        bestSpeed: 0,
        bestScore: 0,
        bestTime: 0,
        totalSessions: sessions.length,
        sessions: sessions,
        bestSessionIndex: -1,
      );
      continue;
    }
    final best = sessions[picked];
    result[mode] = ModeProfileSummary(
      mode: mode,
      bestCorrectItems: best.correctItems,
      bestRecordScore: records[picked].displayScore,
      bestAccuracy: best.accuracy,
      bestSpeed: best.speed,
      bestScore: best.score,
      bestTime: best.timeSeconds,
      totalSessions: sessions.length,
      sessions: sessions,
      bestSessionIndex: picked,
    );
  }
  return result;
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state.
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyHint extends StatelessWidget {
  final _Surface surface;
  const _EmptyHint({required this.surface});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surface.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: surface.border.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Icon(Icons.insights_rounded, size: 32, color: surface.accent.withOpacity(0.7)),
          const SizedBox(height: 10),
          Text(
            _L10n.t('no_data'),
            style: TextStyle(color: surface.onSurface, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            _L10n.t('no_data_hint'),
            textAlign: TextAlign.center,
            style: TextStyle(color: surface.onSurfaceMuted, fontSize: 12, height: 1.45),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rank header card with glowing badge.
// ─────────────────────────────────────────────────────────────────────────────
class _RankHeader extends StatelessWidget {
  final _Surface surface;
  final _RankInfo info;
  final int totalSessions;

  const _RankHeader({
    required this.surface,
    required this.info,
    required this.totalSessions,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = info.color(surface);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: surface.border.withOpacity(0.55)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            surface.card,
            Color.alphaBlend(rankColor.withOpacity(surface.isDark ? 0.05 : 0.03), surface.card),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: rankColor.withOpacity(surface.isDark ? 0.18 : 0.08),
            blurRadius: 28,
            spreadRadius: 0.4,
          ),
        ],
      ),
      child: Row(
        children: [
          _RankBadge(color: rankColor, tier: info.tier, surface: surface),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _L10n.t('rank').toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 2,
                    color: surface.onSurfaceMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  info.label,
                  style: TextStyle(
                    color: surface.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 8),
                _ProgressRail(
                  value: info.progress,
                  color: rankColor,
                  bg: surface.border.withOpacity(0.6),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MiniMetric(
                      label: _L10n.t('avg_score'),
                      value: info.avgScore.toStringAsFixed(3),
                      surface: surface,
                    ),
                    const SizedBox(width: 18),
                    _MiniMetric(
                      label: _L10n.t('sessions'),
                      value: totalSessions.toString(),
                      surface: surface,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRail extends StatelessWidget {
  final double value;
  final Color color;
  final Color bg;

  const _ProgressRail({required this.value, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Container(
                height: 6,
                color: bg,
              ),
              FractionallySizedBox(
                widthFactor: v,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.7), color],
                    ),
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.6), blurRadius: 6, spreadRadius: 0.2),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RankBadge extends StatelessWidget {
  final Color color;
  final _RankTier tier;
  final _Surface surface;

  const _RankBadge({required this.color, required this.tier, required this.surface});

  IconData get _icon {
    switch (tier) {
      case _RankTier.beginner:
        return Icons.emoji_objects_outlined;
      case _RankTier.advanced:
        return Icons.bolt_rounded;
      case _RankTier.elite:
        return Icons.workspace_premium_rounded;
      case _RankTier.master:
        return Icons.military_tech_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      builder: (context, t, _) {
        return Transform.scale(
          scale: t,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withOpacity(surface.isDark ? 0.35 : 0.18),
                  color.withOpacity(0.05),
                ],
              ),
              border: Border.all(color: color.withOpacity(0.5), width: 1.2),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.32), blurRadius: 22, spreadRadius: 1),
              ],
            ),
            child: Icon(_icon, color: color, size: 26),
          ),
        );
      },
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final _Surface surface;

  const _MiniMetric({required this.label, required this.value, required this.surface});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: surface.onSurfaceMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: surface.onSurface,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mode card.
// ─────────────────────────────────────────────────────────────────────────────
class _ModeCard extends StatelessWidget {
  final _Surface surface;
  final String mode;
  final ModeProfileSummary summary;
  final VoidCallback onHistory;
  final VoidCallback onDetails;

  const _ModeCard({
    required this.surface,
    required this.mode,
    required this.summary,
    required this.onHistory,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final empty = summary.totalSessions == 0;
    final accent = surface.accent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: surface.border.withOpacity(0.55)),
        boxShadow: surface.isDark
            ? [
                BoxShadow(
                  color: accent.withOpacity(0.05),
                  blurRadius: 14,
                  spreadRadius: 0.4,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(surface.isDark ? 0.14 : 0.1),
                ),
                child: Icon(_modeIcon(mode), color: accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _modeKeyToLabel(mode),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: surface.onSurface,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      empty
                          ? _L10n.t('no_data')
                          : '${summary.totalSessions} ${_L10n.t('sessions').toLowerCase()}',
                      style: TextStyle(
                        fontSize: 11,
                        color: surface.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _HistoryIconButton(surface: surface, onTap: onHistory),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: _L10n.t('best_result'),
                  value: empty ? '—' : summary.bestRecordScore.toString(),
                  surface: surface,
                ),
              ),
              Expanded(
                child: _StatTile(
                  label: _L10n.t('accuracy'),
                  value: empty ? '—' : '${(summary.bestAccuracy * 100).toStringAsFixed(0)}%',
                  surface: surface,
                ),
              ),
              Expanded(
                child: _StatTile(
                  label: _L10n.t('speed'),
                  value: (empty || summary.bestSpeed > 9000)
                      ? '—'
                      : '${summary.bestSpeed.toStringAsFixed(2)}s',
                  surface: surface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: AnimatedOpacity(
              opacity: empty ? 0.35 : 1,
              duration: const Duration(milliseconds: 220),
              child: _DetailsButton(
                surface: surface,
                onTap: empty ? null : onDetails,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryIconButton extends StatelessWidget {
  final _Surface surface;
  final VoidCallback onTap;

  const _HistoryIconButton({required this.surface, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _L10n.t('history'),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: surface.accent.withOpacity(surface.isDark ? 0.1 : 0.08),
              border: Border.all(color: surface.accent.withOpacity(0.28)),
            ),
            child: Icon(Icons.history_rounded, size: 18, color: surface.accent),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final _Surface surface;

  const _StatTile({required this.label, required this.value, required this.surface});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: surface.onSurfaceMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: surface.onSurface,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _DetailsButton extends StatelessWidget {
  final _Surface surface;
  final VoidCallback? onTap;

  const _DetailsButton({required this.surface, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = surface.accent;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: accent.withOpacity(surface.isDark ? 0.12 : 0.08),
            border: Border.all(color: accent.withOpacity(0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _L10n.t('details'),
                style: TextStyle(
                  fontSize: 11,
                  color: accent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded, color: accent, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class TrainingHistoryScreen extends StatefulWidget {
  final String mode;

  const TrainingHistoryScreen({super.key, required this.mode});

  @override
  State<TrainingHistoryScreen> createState() => _TrainingHistoryScreenState();
}

class _TrainingHistoryScreenState extends State<TrainingHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  List<TrainingHistoryEntry> _entries = const <TrainingHistoryEntry>[];
  bool _isLoading = true;
  bool _isSyncingCloud = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<TrainingHistoryEntry>> _loadLocal() async {
    try {
      return await TrainingHistoryService.instance.loadMode(widget.mode);
    } catch (_) {
      return const <TrainingHistoryEntry>[];
    }
  }

  Future<void> _loadInitial() async {
    final local = await _loadLocal();
    if (!mounted) return;
    setState(() {
      _entries = local;
      _isLoading = false;
    });
    unawaited(_syncCloudAndReload());
  }

  Future<void> _syncCloudAndReload() async {
    if (_isSyncingCloud) return;
    if (mounted) {
      setState(() => _isSyncingCloud = true);
    }
    try {
      final cloud = await CloudSyncService.instance
          .fetchTrainingHistory(mode: widget.mode)
          .timeout(const Duration(seconds: 12));
      if (cloud.isNotEmpty) {
        await TrainingHistoryService.instance.mergeFromCloud(widget.mode, cloud);
      }
    } catch (_) {
      // Keep local history visible even if cloud sync fails.
    }
    final local = await _loadLocal();
    if (!mounted) return;
    setState(() {
      _entries = local;
      _isSyncingCloud = false;
    });
  }

  Future<void> _refresh() async {
    await _syncCloudAndReload();
  }

  Future<void> _deleteEntry(TrainingHistoryEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(_L10n.t('history_delete_title')),
          content: Text(_L10n.t('history_delete_body')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_L10n.t('history_delete_cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_L10n.t('history_delete_confirm')),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    setState(() {
      _entries = _entries.where((e) => e.id != entry.id).toList(growable: false);
    });
    await TrainingHistoryService.instance.removeLocalSessionAndDisciplineAggregates(entry);
    if (!mounted) return;
    await ProfileSessionService.instance.removeSessionMatchingTrainingHistory(
      mode: entry.mode,
      date: entry.date,
      totalItems: entry.totalItems,
      correctItems: entry.correctItems,
      memorizationMs: entry.memorizationMs,
      recallMs: entry.recallMs,
    );
    if (!mounted) return;
    await CloudSyncService.instance.deleteTrainingHistoryEntry(entry.id);
    unawaited(CloudSyncService.instance.enqueueSync());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_L10n.t('history_deleted'))),
    );
    await _refresh();
  }

  Widget _buildHistoryList(_Surface s) {
    if (_isLoading) {
      return ColoredBox(
        color: s.background,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 1.6, color: s.accent),
        ),
      );
    }
    if (_entries.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        color: s.accent,
        backgroundColor: s.card,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(22, 120, 22, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: s.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: s.border.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Icon(Icons.history_toggle_off_rounded, color: s.accent, size: 34),
                  const SizedBox(height: 12),
                  Text(
                    _L10n.t('history_empty'),
                    style: TextStyle(color: s.onSurface, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _L10n.t('history_empty_hint'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: s.onSurfaceMuted, fontSize: 12, height: 1.45),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return ColoredBox(
      color: s.background,
      child: RefreshIndicator(
        onRefresh: _refresh,
        color: s.accent,
        backgroundColor: s.card,
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            itemCount: _entries.length,
            itemBuilder: (context, index) {
              final entry = _entries[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _HistoryAttemptCard(
                  key: ValueKey(entry.id),
                  surface: s,
                  entry: entry,
                  onTap: () {
                    if (entry.isBriefProfileBackfill) {
                      uiTapClick(UiClickSound.soft);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_L10n.t('history_replay_unavailable'))),
                      );
                      return;
                    }
                    uiTapClick(UiClickSound.soft);
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => TrainingScreen(historyEntry: entry),
                        settings: RouteSettings(name: 'TrainingReplay/${entry.id}'),
                      ),
                    );
                  },
                  onDelete: () {
                    uiTapClick(UiClickSound.bright);
                    _deleteEntry(entry);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppPalette>(
      valueListenable: appPalette,
      builder: (context, palette, _) {
        final s = _Surface.of(context, palette);
        return Scaffold(
          backgroundColor: s.background,
          appBar: AppBar(
            backgroundColor: s.background,
            elevation: 0,
            foregroundColor: s.onSurface,
            title: Text(
              '${_L10n.t('history')} · ${_modeKeyToLabel(widget.mode)}',
              style: TextStyle(
                color: s.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.4,
              ),
            ),
            actions: [
              if (_isSyncingCloud)
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: s.accent,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: _buildHistoryList(s),
        );
      },
    );
  }
}

class _HistoryAttemptCard extends StatelessWidget {
  final _Surface surface;
  final TrainingHistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryAttemptCard({
    super.key,
    required this.surface,
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  String _dateText(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$d.$m.$y  $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final pct = (entry.accuracy * 100).toStringAsFixed(0);
    final enc = entry.totalItems <= 0 || entry.memorizationMs <= 0
        ? 0.0
        : (entry.memorizationMs / 1000.0) / entry.totalItems;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: surface.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: surface.border.withOpacity(0.55)),
            boxShadow: surface.isDark
                ? [BoxShadow(color: surface.accent.withOpacity(0.05), blurRadius: 16)]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: surface.accent.withOpacity(surface.isDark ? 0.14 : 0.1),
                      ),
                      child: Icon(Icons.history_rounded, color: surface.accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _dateText(entry.date),
                            style: TextStyle(
                              color: surface.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${entry.correctItems}/${entry.totalItems} · $pct%',
                            style: TextStyle(color: surface.onSurfaceMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: _L10n.t('history_delete_confirm'),
                      icon: Icon(Icons.delete_outline_rounded, color: surface.onSurfaceMuted, size: 22),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    Icon(Icons.arrow_forward_rounded, color: surface.accent, size: 18),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _HistoryMetric(
                        surface: surface,
                        label: _L10n.t('accuracy'),
                        value: '$pct%',
                      ),
                    ),
                    Expanded(
                      child: _HistoryMetric(
                        surface: surface,
                        label: _L10n.t('speed'),
                        value: enc <= 0 ? '—' : '${enc.toStringAsFixed(2)}s',
                      ),
                    ),
                    Expanded(
                      child: _HistoryMetric(
                        surface: surface,
                        label: 'XP',
                        value: '+${entry.xpEarned}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryMetric extends StatelessWidget {
  final _Surface surface;
  final String label;
  final String value;

  const _HistoryMetric({
    required this.surface,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: surface.onSurfaceMuted, fontSize: 10, letterSpacing: 0.5)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(color: surface.onSurface, fontSize: 15, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail screen — per-mode analytics.
// ─────────────────────────────────────────────────────────────────────────────
class ModeStatsDetailScreen extends StatefulWidget {
  final String mode;
  const ModeStatsDetailScreen({super.key, required this.mode});

  @override
  State<ModeStatsDetailScreen> createState() => _ModeStatsDetailScreenState();
}

class _ModeStatsDetailScreenState extends State<ModeStatsDetailScreen> {
  late Future<_ModeDetailSnapshot> _future;
  int _segmentSize = 5; // 5 or 10

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ModeDetailSnapshot> _load() async {
    final all = await ProfileSessionService.instance.loadSessions();
    final sessions = all.where((e) => e.mode == widget.mode).toList(growable: false);
    final history = await TrainingHistoryService.instance.loadMode(widget.mode);
    return _ModeDetailSnapshot(
      sessions: sessions,
      history: history,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppPalette>(
      valueListenable: appPalette,
      builder: (context, palette, _) {
        final s = _Surface.of(context, palette);
        return Scaffold(
          backgroundColor: s.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: s.onSurface,
            title: Row(
              children: [
                Icon(_modeIcon(widget.mode), color: s.accent, size: 18),
                const SizedBox(width: 8),
                Text(
                  _modeKeyToLabel(widget.mode),
                  style: TextStyle(
                    color: s.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          body: FutureBuilder<_ModeDetailSnapshot>(
            future: _future,
            builder: (context, snap) {
              final ready = snap.connectionState == ConnectionState.done;
              final sessions = snap.data?.sessions ?? const <ProfileSessionEntry>[];
              final history = snap.data?.history ?? const <TrainingHistoryEntry>[];
              if (!ready) {
                return const Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 1.6),
                  ),
                );
              }
              if (sessions.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: _EmptyHint(surface: s),
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                physics: const BouncingScrollPhysics(),
                children: _buildSections(s, sessions, history),
              );
            },
          ),
        );
      },
    );
  }

  List<Widget> _buildSections(
    _Surface s,
    List<ProfileSessionEntry> sessions,
    List<TrainingHistoryEntry> history,
  ) {
    // Sessions arrive newest→oldest. We need oldest→newest for trend math.
    final chrono = sessions.reversed.toList(growable: false);
    final latest = sessions.first;

    final widgets = <Widget>[];

    widgets.add(_SectionAnimator(
      delayMs: 0,
      child: _SessionScoreSection(surface: s, sessions: chrono),
    ));
    widgets.add(const SizedBox(height: 14));

    widgets.add(_SectionAnimator(
      delayMs: 90,
      child: _EncodingRecallSection(surface: s, latest: latest, all: sessions),
    ));
    widgets.add(const SizedBox(height: 14));

    widgets.add(_SectionAnimator(
      delayMs: 180,
      child: _SpeedPerSegmentSection(
        surface: s,
        latest: latest,
        segmentSize: _segmentSize,
        onSegmentChange: (v) => setState(() => _segmentSize = v),
      ),
    ));
    widgets.add(const SizedBox(height: 14));

    widgets.add(_SectionAnimator(
      delayMs: 270,
      child: _MemoryDegradationSection(
        surface: s,
        latest: latest,
        segmentSize: _segmentSize,
      ),
    ));
    widgets.add(const SizedBox(height: 14));

    widgets.add(_SectionAnimator(
      delayMs: 360,
      child: _ConsistencySection(surface: s, sessions: sessions),
    ));
    widgets.add(const SizedBox(height: 14));

    widgets.add(_SectionAnimator(
      delayMs: 450,
      child: _OptimalLengthSection(surface: s, sessions: sessions),
    ));
    widgets.add(const SizedBox(height: 14));

    widgets.add(_SectionAnimator(
      delayMs: 540,
      child: _ProgressPredictionSection(surface: s, chrono: chrono),
    ));
    widgets.add(const SizedBox(height: 14));

    widgets.add(_SectionAnimator(
      delayMs: 620,
      child: _LociQualitySection(surface: s, history: history),
    ));
    widgets.add(const SizedBox(height: 14));

    widgets.add(_SectionAnimator(
      delayMs: 700,
      child: _ReadinessSection(surface: s, sessions: sessions),
    ));
    widgets.add(const SizedBox(height: 14));

    widgets.add(_SectionAnimator(
      delayMs: 780,
      child: _PlateauSection(surface: s, chrono: chrono),
    ));
    widgets.add(const SizedBox(height: 14));

    widgets.add(_SectionAnimator(
      delayMs: 860,
      child: _RetentionDriftSection(surface: s, sessions: sessions),
    ));
    widgets.add(const SizedBox(height: 14));

    widgets.add(_SectionAnimator(
      delayMs: 940,
      child: _PbProbabilitySection(surface: s, sessions: sessions),
    ));
    widgets.add(const SizedBox(height: 14));

    widgets.add(_SectionAnimator(
      delayMs: 1020,
      child: _CircadianSection(surface: s, sessions: sessions),
    ));
    widgets.add(const SizedBox(height: 14));

    widgets.add(_SectionAnimator(
      delayMs: 1100,
      child: _ErrorTaxonomySection(surface: s, history: history),
    ));

    return widgets;
  }
}

class _ModeDetailSnapshot {
  final List<ProfileSessionEntry> sessions;
  final List<TrainingHistoryEntry> history;

  const _ModeDetailSnapshot({
    required this.sessions,
    required this.history,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Section animator — staggered fade-in / slide-up.
// ─────────────────────────────────────────────────────────────────────────────
class _SectionAnimator extends StatelessWidget {
  final int delayMs;
  final Widget child;
  const _SectionAnimator({required this.delayMs, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, t, c) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 14),
            child: c,
          ),
        );
      },
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Common section card scaffold.
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final _Surface surface;
  final String title;
  final String? subtitle;
  final String? helpKey;
  final IconData? icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.surface,
    required this.title,
    required this.child,
    this.subtitle,
    this.helpKey,
    this.icon,
    this.trailing,
  });

  void _showHelp(BuildContext context) {
    final text = helpKey == null ? '' : _L10n.t(helpKey!);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: surface.card,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: surface.border.withOpacity(0.6)),
          ),
          title: Row(
            children: [
              Icon(Icons.help_outline_rounded, color: surface.accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: surface.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            text,
            style: TextStyle(
              color: surface.onSurface.withOpacity(0.76),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                _L10n.t('close'),
                style: TextStyle(color: surface.accent, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: surface.border.withOpacity(0.5)),
        boxShadow: surface.isDark
            ? [
                BoxShadow(
                  color: surface.accent.withOpacity(0.04),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: surface.accent.withOpacity(0.8)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: surface.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: surface.onSurfaceMuted,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (helpKey != null) ...[
                if (trailing != null) const SizedBox(width: 6),
                Tooltip(
                  message: _L10n.t('help'),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      uiTapClick(UiClickSound.soft);
                      _showHelp(context);
                    },
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: surface.cardSubtle,
                        border: Border.all(color: surface.border.withOpacity(0.55)),
                      ),
                      child: Icon(
                        Icons.question_mark_rounded,
                        size: 13,
                        color: surface.onSurfaceMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section: Session Score (best, average, line chart over time).
// ─────────────────────────────────────────────────────────────────────────────
class _SessionScoreSection extends StatelessWidget {
  final _Surface surface;
  final List<ProfileSessionEntry> sessions; // chronological oldest→newest

  const _SessionScoreSection({required this.surface, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final scores = sessions.map((e) => e.score).toList(growable: false);
    final best = scores.isEmpty ? 0.0 : scores.reduce(math.max);
    final avg = scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;
    final bestIdx = scores.indexOf(best);

    return _SectionCard(
      surface: surface,
      icon: Icons.insights_rounded,
      title: _L10n.t('session_score'),
      subtitle: _L10n.t('score_subtitle'),
      helpKey: 'help_session_score',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _BigStat(
                  surface: surface,
                  label: _L10n.t('best'),
                  value: best.toStringAsFixed(3),
                  accent: true,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: surface.border.withOpacity(0.6),
              ),
              Expanded(
                child: _BigStat(
                  surface: surface,
                  label: _L10n.t('avg'),
                  value: avg.toStringAsFixed(3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 130,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) {
                return CustomPaint(
                  painter: _LineChartPainter(
                    values: scores,
                    color: surface.accent,
                    bgGrid: surface.border.withOpacity(0.5),
                    fillFrom: surface.accent.withOpacity(0.18),
                    fillTo: surface.accent.withOpacity(0.0),
                    highlightIndex: bestIdx,
                    highlightColor: surface.success,
                    progress: t,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_L10n.t('best_session')}: ${(bestIdx + 1)}/${sessions.length}',
            style: TextStyle(color: surface.onSurfaceMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final _Surface surface;
  final String label;
  final String value;
  final bool accent;

  const _BigStat({
    required this.surface,
    required this.label,
    required this.value,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: surface.onSurfaceMuted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: accent ? surface.accent : surface.onSurface,
            height: 1,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section: Encoding vs Recall — two side-by-side cards.
// ─────────────────────────────────────────────────────────────────────────────
class _EncodingRecallSection extends StatelessWidget {
  final _Surface surface;
  final ProfileSessionEntry latest;
  final List<ProfileSessionEntry> all;

  const _EncodingRecallSection({
    required this.surface,
    required this.latest,
    required this.all,
  });

  @override
  Widget build(BuildContext context) {
    // Average encoding/recall speed across sessions where data is available.
    double avgEnc = 0;
    double avgRec = 0;
    int encCount = 0;
    int recCount = 0;
    for (final e in all) {
      if (e.encodingSpeed > 0) {
        avgEnc += e.encodingSpeed;
        encCount++;
      }
      if (e.recallSpeed > 0) {
        avgRec += e.recallSpeed;
        recCount++;
      }
    }
    if (encCount > 0) avgEnc /= encCount;
    if (recCount > 0) avgRec /= recCount;

    final encSpeed = latest.encodingSpeed > 0 ? latest.encodingSpeed : avgEnc;
    final recSpeed = latest.recallSpeed > 0 ? latest.recallSpeed : avgRec;

    final maxV = math.max(encSpeed, recSpeed);
    final encFrac = maxV <= 0 ? 0.0 : encSpeed / maxV;
    final recFrac = maxV <= 0 ? 0.0 : recSpeed / maxV;

    return _SectionCard(
      surface: surface,
      icon: Icons.compare_arrows_rounded,
      title: _L10n.t('encoding_recall'),
      helpKey: 'help_encoding_recall',
      child: Row(
        children: [
          Expanded(
            child: _SpeedTile(
              surface: surface,
              label: _L10n.t('encoding'),
              icon: Icons.psychology_alt_outlined,
              valueSec: encSpeed,
              fraction: encFrac,
              color: surface.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SpeedTile(
              surface: surface,
              label: _L10n.t('recall'),
              icon: Icons.history_edu_outlined,
              valueSec: recSpeed,
              fraction: recFrac,
              color: surface.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedTile extends StatelessWidget {
  final _Surface surface;
  final String label;
  final IconData icon;
  final double valueSec;
  final double fraction;
  final Color color;

  const _SpeedTile({
    required this.surface,
    required this.label,
    required this.icon,
    required this.valueSec,
    required this.fraction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface.cardSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: surface.border.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: surface.onSurfaceMuted,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            valueSec <= 0 ? '—' : valueSec.toStringAsFixed(2),
            style: TextStyle(
              color: surface.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _L10n.t('sec_per_item'),
            style: TextStyle(
              color: surface.onSurfaceMuted,
              fontSize: 10,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    Container(
                      height: 4,
                      color: surface.border.withOpacity(0.6),
                    ),
                    FractionallySizedBox(
                      widthFactor: t,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color.withOpacity(0.65), color],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section: Speed per Segment — uses correctnessPattern when available.
// ─────────────────────────────────────────────────────────────────────────────
class _SegmentRow {
  final int index;
  final int correctInSegment;
  final int totalInSegment;
  final double seconds;
  double get speed => correctInSegment <= 0 ? -1 : seconds / correctInSegment;

  const _SegmentRow({
    required this.index,
    required this.correctInSegment,
    required this.totalInSegment,
    required this.seconds,
  });
}

List<_SegmentRow> _buildSegments(ProfileSessionEntry s, int chunk) {
  final out = <_SegmentRow>[];
  final n = s.totalItems;
  if (n <= 0) return out;
  final encMs = s.encodingMs > 0 ? s.encodingMs : s.timeSeconds * 1000;
  final secPerItem = (encMs / 1000.0) / n;

  for (int start = 0; start < n; start += chunk) {
    final end = math.min(start + chunk, n);
    final size = end - start;
    int correct;
    if (s.hasPattern) {
      correct = 0;
      for (int i = start; i < end; i++) {
        if (s.correctnessPattern[i] == 1) correct++;
      }
    } else {
      // Fallback: distribute evenly. Floor first, top off the last segment.
      correct = ((s.correctItems / n) * size).round();
    }
    out.add(_SegmentRow(
      index: out.length,
      correctInSegment: correct,
      totalInSegment: size,
      seconds: secPerItem * size,
    ));
  }
  return out;
}

class _SpeedPerSegmentSection extends StatelessWidget {
  final _Surface surface;
  final ProfileSessionEntry latest;
  final int segmentSize;
  final ValueChanged<int> onSegmentChange;

  const _SpeedPerSegmentSection({
    required this.surface,
    required this.latest,
    required this.segmentSize,
    required this.onSegmentChange,
  });

  @override
  Widget build(BuildContext context) {
    final segments = _buildSegments(latest, segmentSize);
    final maxSpeed = segments
        .where((e) => e.speed > 0)
        .fold<double>(0, (acc, e) => math.max(acc, e.speed));
    final avgSpeed = (() {
      final valid = segments.where((e) => e.speed > 0).toList();
      if (valid.isEmpty) return 0.0;
      return valid.fold<double>(0, (a, b) => a + b.speed) / valid.length;
    })();
    final slowThreshold = avgSpeed * 1.25;

    return _SectionCard(
      surface: surface,
      icon: Icons.speed_rounded,
      title: _L10n.t('speed_per_segment'),
      subtitle: _L10n.t('speed_segment_subtitle'),
      helpKey: 'help_speed_segment',
      trailing: _SegmentSizeToggle(
        surface: surface,
        value: segmentSize,
        onChange: onSegmentChange,
      ),
      child: Column(
        children: [
          for (int i = 0; i < segments.length; i++)
            _SegmentBarRow(
              surface: surface,
              row: segments[i],
              maxSpeed: maxSpeed,
              isSlow: segments[i].speed > 0 && segments[i].speed > slowThreshold,
              isLast: i == segments.length - 1,
            ),
        ],
      ),
    );
  }
}

class _SegmentSizeToggle extends StatelessWidget {
  final _Surface surface;
  final int value;
  final ValueChanged<int> onChange;

  const _SegmentSizeToggle({
    required this.surface,
    required this.value,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: surface.cardSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: surface.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [5, 10].map((v) {
          final active = v == value;
          return GestureDetector(
            onTap: () {
              uiTapClick(UiClickSound.soft);
              onChange(v);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: active ? surface.accent.withOpacity(0.18) : Colors.transparent,
              ),
              child: Text(
                '$v',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: active ? surface.accent : surface.onSurfaceMuted,
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _SegmentBarRow extends StatelessWidget {
  final _Surface surface;
  final _SegmentRow row;
  final double maxSpeed;
  final bool isSlow;
  final bool isLast;

  const _SegmentBarRow({
    required this.surface,
    required this.row,
    required this.maxSpeed,
    required this.isSlow,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSlow ? surface.warning : surface.accent;
    final fraction = row.speed > 0 && maxSpeed > 0
        ? (row.speed / maxSpeed).clamp(0.05, 1.0)
        : 0.0;
    final speedText = row.speed <= 0
        ? '—'
        : '${row.speed.toStringAsFixed(2)} ${_L10n.t('sec_per_item')}';
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              '${_L10n.t('block')} ${row.index + 1}',
              style: TextStyle(
                fontSize: 11,
                color: surface.onSurfaceMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fraction),
              duration: Duration(milliseconds: 500 + row.index * 60),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    children: [
                      Container(height: 14, color: surface.cardSubtle),
                      FractionallySizedBox(
                        widthFactor: t,
                        child: Container(
                          height: 14,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color.withOpacity(0.6), color],
                            ),
                            boxShadow: isSlow
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.45),
                                      blurRadius: 6,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 96,
            child: Text(
              speedText,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSlow ? surface.warning : surface.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section: Memory Degradation — accuracy by segment in latest session.
// ─────────────────────────────────────────────────────────────────────────────
class _MemoryDegradationSection extends StatelessWidget {
  final _Surface surface;
  final ProfileSessionEntry latest;
  final int segmentSize;

  const _MemoryDegradationSection({
    required this.surface,
    required this.latest,
    required this.segmentSize,
  });

  @override
  Widget build(BuildContext context) {
    final segments = _buildSegments(latest, segmentSize);
    final accuracies = segments
        .map((e) => e.totalInSegment <= 0 ? 0.0 : e.correctInSegment / e.totalInSegment)
        .toList(growable: false);

    int? dropIdx;
    for (int i = 1; i < accuracies.length; i++) {
      if (accuracies[i] < accuracies[i - 1] - 0.15) {
        dropIdx = i;
        break;
      }
    }

    final insight = dropIdx == null || !latest.hasPattern
        ? _L10n.t('no_drop')
        : _L10n.t('accuracy_drops_after', {
            'n': (dropIdx * segmentSize).toString(),
          });

    return _SectionCard(
      surface: surface,
      icon: Icons.show_chart_rounded,
      title: _L10n.t('memory_degradation'),
      subtitle: _L10n.t('degradation_subtitle'),
      helpKey: 'help_memory_degradation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 120,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) {
                return CustomPaint(
                  painter: _LineChartPainter(
                    values: accuracies,
                    color: surface.accent,
                    bgGrid: surface.border.withOpacity(0.5),
                    fillFrom: surface.accent.withOpacity(0.16),
                    fillTo: surface.accent.withOpacity(0.0),
                    fixedMax: 1.0,
                    fixedMin: 0.0,
                    highlightIndex: dropIdx,
                    highlightColor: surface.danger,
                    progress: t,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dropIdx != null ? surface.danger : surface.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  insight,
                  style: TextStyle(
                    fontSize: 12,
                    color: surface.onSurface.withOpacity(0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section: Consistency Score (std dev of recent scores).
// ─────────────────────────────────────────────────────────────────────────────
class _ConsistencySection extends StatelessWidget {
  final _Surface surface;
  final List<ProfileSessionEntry> sessions; // newest→oldest

  const _ConsistencySection({required this.surface, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final recent = sessions.length <= 12 ? sessions : sessions.sublist(0, 12);
    final scores = recent.map((e) => e.score).toList(growable: false);
    final mean = scores.isEmpty
        ? 0.0
        : scores.reduce((a, b) => a + b) / scores.length;
    final variance = scores.isEmpty
        ? 0.0
        : scores.fold<double>(0, (a, b) => a + (b - mean) * (b - mean)) /
            scores.length;
    final std = math.sqrt(variance);

    // Coefficient-of-variation flipped to a 0..100% consistency score.
    final cv = mean <= 1e-6 ? 0.0 : std / mean;
    final consistency = ((1.0 - cv).clamp(0.0, 1.0)) * 100;

    final stable = consistency >= 70;
    final label = stable ? _L10n.t('stable') : _L10n.t('unstable');
    final color = stable ? surface.success : surface.warning;

    final reversed = scores.reversed.toList(growable: false);

    return _SectionCard(
      surface: surface,
      icon: Icons.timeline_rounded,
      title: _L10n.t('consistency'),
      subtitle: _L10n.t('consistency_subtitle'),
      helpKey: 'help_consistency',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: consistency),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, t, _) {
                  return Text(
                    '${t.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: surface.onSurface,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(surface.isDark ? 0.16 : 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.35)),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: SizedBox(
              height: 60,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, t, _) {
                  return CustomPaint(
                    painter: _SparklinePainter(
                      values: reversed,
                      color: color,
                      progress: t,
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section: Optimal Length (best efficiency by item count).
// ─────────────────────────────────────────────────────────────────────────────
class _OptimalLengthSection extends StatelessWidget {
  final _Surface surface;
  final List<ProfileSessionEntry> sessions;

  const _OptimalLengthSection({required this.surface, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final byLength = <int, List<double>>{};
    for (final s in sessions) {
      if (s.efficiency <= 0) continue;
      byLength.putIfAbsent(s.totalItems, () => <double>[]).add(s.efficiency);
    }

    int optimalN = 0;
    double optimalAvg = -1;
    final entries = <_OptEntry>[];
    byLength.forEach((n, list) {
      final avg = list.reduce((a, b) => a + b) / list.length;
      entries.add(_OptEntry(n: n, avgEff: avg, samples: list.length));
      if (avg > optimalAvg) {
        optimalAvg = avg;
        optimalN = n;
      }
    });
    entries.sort((a, b) => a.n.compareTo(b.n));
    final maxAvg = entries.isEmpty
        ? 1.0
        : entries.fold<double>(0, (a, b) => math.max(a, b.avgEff));

    return _SectionCard(
      surface: surface,
      icon: Icons.tune_rounded,
      title: _L10n.t('optimal_length'),
      subtitle: _L10n.t('optimal_subtitle'),
      helpKey: 'help_optimal_length',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.85, end: 1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutBack,
                  builder: (context, t, _) {
                    return Transform.scale(
                      scale: t,
                      child: Text(
                        optimalN > 0 ? optimalN.toString() : '—',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          color: surface.accent,
                          height: 1,
                          letterSpacing: -1,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  optimalN > 0
                      ? _L10n.t('optimal_msg', {'n': optimalN.toString()})
                      : _L10n.t('no_data_hint'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: surface.onSurfaceMuted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (entries.length > 1) ...[
            const SizedBox(height: 8),
            Column(
              children: entries.map((e) {
                final fraction = (e.avgEff / maxAvg).clamp(0.0, 1.0);
                final isOpt = e.n == optimalN;
                final color = isOpt ? surface.accent : surface.onSurfaceMuted;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 36,
                        child: Text(
                          '${e.n}',
                          style: TextStyle(
                            color: surface.onSurfaceMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: fraction),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (context, t, _) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Stack(
                                children: [
                                  Container(
                                    height: 6,
                                    color: surface.border.withOpacity(0.5),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: t,
                                    child: Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(isOpt ? 1 : 0.6),
                                        boxShadow: isOpt
                                            ? [
                                                BoxShadow(
                                                  color: color.withOpacity(0.5),
                                                  blurRadius: 6,
                                                ),
                                              ]
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptEntry {
  final int n;
  final double avgEff;
  final int samples;
  const _OptEntry({required this.n, required this.avgEff, required this.samples});
}

// ─────────────────────────────────────────────────────────────────────────────
// Section: Progress Prediction — linear regression on score over time.
// ─────────────────────────────────────────────────────────────────────────────
class _ProgressPredictionSection extends StatelessWidget {
  final _Surface surface;
  final List<ProfileSessionEntry> chrono; // oldest→newest

  const _ProgressPredictionSection({required this.surface, required this.chrono});

  @override
  Widget build(BuildContext context) {
    if (chrono.length < 2) {
      return _SectionCard(
        surface: surface,
        icon: Icons.trending_up_rounded,
        title: _L10n.t('prediction'),
        subtitle: _L10n.t('prediction_subtitle'),
        helpKey: 'help_prediction',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            _L10n.t('no_data_hint'),
            style: TextStyle(color: surface.onSurfaceMuted, fontSize: 12, height: 1.4),
          ),
        ),
      );
    }

    final scoresOverTime =
        chrono.map((e) => e.effectiveRecordScore.toDouble()).toList(growable: false);

    final firstDate = chrono.first.date;
    final dayValues = chrono
        .map((e) => e.date.difference(firstDate).inHours / 24.0)
        .toList(growable: false);

    // Simple linear regression: y = a + b·x.
    final n = chrono.length;
    double sx = 0, sy = 0, sxx = 0, sxy = 0;
    for (int i = 0; i < n; i++) {
      final x = dayValues[i];
      final y = scoresOverTime[i];
      sx += x;
      sy += y;
      sxx += x * x;
      sxy += x * y;
    }
    final den = (n * sxx - sx * sx);
    final slope = den.abs() < 1e-9 ? 0.0 : (n * sxy - sx * sy) / den;
    final intercept = (sy - slope * sx) / n;

    final lastDay = dayValues.last;
    final pred7 = math.max(0, intercept + slope * (lastDay + 7)).round();
    final pred30 = math.max(0, intercept + slope * (lastDay + 30)).round();

    return _SectionCard(
      surface: surface,
      icon: Icons.trending_up_rounded,
      title: _L10n.t('prediction'),
      subtitle: _L10n.t('prediction_items_subtitle'),
      helpKey: 'help_prediction',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 130,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) {
                return CustomPaint(
                  painter: _PredictionChartPainter(
                    values: scoresOverTime,
                    color: surface.accent,
                    bgGrid: surface.border.withOpacity(0.5),
                    fillFrom: surface.accent.withOpacity(0.18),
                    fillTo: surface.accent.withOpacity(0.0),
                    futureColor: surface.success,
                    futurePoints: [
                      // Project 7-day and 30-day points relative to current.
                      pred7.toDouble(),
                      pred30.toDouble(),
                    ],
                    progress: t,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _PredictPill(
                surface: surface,
                color: surface.success,
                text: _L10n.t('expected_in_7', {'n': pred7.toString()}),
              ),
              _PredictPill(
                surface: surface,
                color: surface.accent,
                text: _L10n.t('expected_in_30', {'n': pred30.toString()}),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PredictPill extends StatelessWidget {
  final _Surface surface;
  final Color color;
  final String text;
  const _PredictPill({required this.surface, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(surface.isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: surface.onSurface.withOpacity(0.95),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocusQualityRow {
  final String locus;
  final int attempts;
  final int errors;
  final double avgSec;
  final double errorRate;
  final double confidence;
  final double riskScore;

  const _LocusQualityRow({
    required this.locus,
    required this.attempts,
    required this.errors,
    required this.avgSec,
    required this.errorRate,
    required this.confidence,
    required this.riskScore,
  });
}

List<_LocusQualityRow> _buildLocusQualityRows(List<TrainingHistoryEntry> history) {
  final attempts = <String, int>{};
  final errors = <String, int>{};
  final totalSec = <String, double>{};
  final secSamples = <String, int>{};

  for (final entry in history) {
    if (entry.lociBindings.isEmpty) continue;
    final n = math.min(entry.totalItems, entry.lociBindings.length);
    if (n <= 0) continue;
    final fallbackSec = entry.totalItems <= 0
        ? 0.0
        : (entry.memorizationMs / 1000.0) / entry.totalItems;

    for (int i = 0; i < n; i++) {
      final locus = entry.lociBindings[i].trim();
      if (locus.isEmpty) continue;
      attempts[locus] = (attempts[locus] ?? 0) + 1;

      final isCorrect =
          i < entry.correctnessPattern.length ? entry.correctnessPattern[i] == 1 : true;
      if (!isCorrect) {
        errors[locus] = (errors[locus] ?? 0) + 1;
      }

      final sec = (i < entry.memorizationMsByElement.length)
          ? entry.memorizationMsByElement[i] / 1000.0
          : fallbackSec;
      if (sec > 0) {
        totalSec[locus] = (totalSec[locus] ?? 0) + sec;
        secSamples[locus] = (secSamples[locus] ?? 0) + 1;
      }
    }
  }

  if (attempts.isEmpty) return const <_LocusQualityRow>[];

  final loci = attempts.keys.toList(growable: false);
  final avgByLocus = <String, double>{
    for (final locus in loci)
      locus: (secSamples[locus] ?? 0) > 0
          ? (totalSec[locus] ?? 0) / (secSamples[locus] ?? 1)
          : 0.0,
  };

  final baselineSec = (() {
    final values = avgByLocus.values.where((v) => v > 0).toList(growable: false)
      ..sort();
    if (values.isEmpty) return 1.0;
    return values[values.length ~/ 2];
  })();

  final rows = <_LocusQualityRow>[];
  for (final locus in loci) {
    final a = attempts[locus] ?? 0;
    final e = errors[locus] ?? 0;
    final avgSec = avgByLocus[locus] ?? 0.0;
    final errorRate = a <= 0 ? 0.0 : e / a;
    final timePenalty = avgSec <= 0 ? 0.0 : ((avgSec - baselineSec) / baselineSec).clamp(0.0, 1.0);
    final confidence = (a / (a + 6)).clamp(0.0, 1.0);
    final riskScore = ((0.7 * errorRate) + (0.3 * timePenalty)) * confidence;
    rows.add(_LocusQualityRow(
      locus: locus,
      attempts: a,
      errors: e,
      avgSec: avgSec,
      errorRate: errorRate,
      confidence: confidence,
      riskScore: riskScore,
    ));
  }

  rows.sort((a, b) {
    final byRisk = b.riskScore.compareTo(a.riskScore);
    if (byRisk != 0) return byRisk;
    return b.attempts.compareTo(a.attempts);
  });
  return rows;
}

class _LociQualitySection extends StatefulWidget {
  final _Surface surface;
  final List<TrainingHistoryEntry> history;

  const _LociQualitySection({
    required this.surface,
    required this.history,
  });

  @override
  State<_LociQualitySection> createState() => _LociQualitySectionState();
}

class _LociQualitySectionState extends State<_LociQualitySection> {
  bool _expanded = false;

  String _fmtSec(double s) => s <= 0 ? '—' : '${s.toStringAsFixed(2)} ${_L10n.t('sec_per_item')}';

  void _openLociRoutes(BuildContext context, String locusName) {
    final trimmed = locusName.trim();
    if (trimmed.isEmpty) return;
    uiTapClick(UiClickSound.soft);
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LociRoutesScreen(highlightLocusName: trimmed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = widget.surface;
    final rows = _buildLocusQualityRows(widget.history);
    if (rows.isEmpty) {
      return _SectionCard(
        surface: surface,
        icon: Icons.alt_route_rounded,
        title: _L10n.t('loci_quality'),
        subtitle: _L10n.t('loci_quality_subtitle'),
        helpKey: 'help_loci_quality',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            _L10n.t('loci_no_data'),
            style: TextStyle(color: surface.onSurfaceMuted, fontSize: 12, height: 1.4),
          ),
        ),
      );
    }

    final top = rows.first;
    return _SectionCard(
      surface: surface,
      icon: Icons.alt_route_rounded,
      title: _L10n.t('loci_quality'),
      subtitle: _L10n.t('loci_quality_subtitle'),
      helpKey: 'help_loci_quality',
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openLociRoutes(context, top.locus),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surface.cardSubtle,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: surface.border.withOpacity(0.45)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: surface.warning, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _L10n.t('loci_top_risk'),
                            style: TextStyle(
                              color: surface.onSurfaceMuted,
                              fontSize: 10,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            top.locus,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: surface.onSurface, fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(top.riskScore * 100).toStringAsFixed(0)}%',
                      style: TextStyle(color: surface.warning, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.open_in_new_rounded, size: 14, color: surface.onSurfaceMuted),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: surface.cardSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: surface.border.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: surface.accent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _expanded
                            ? _L10n.t('hide_loci_full')
                            : _L10n.t('show_loci_full', {'n': rows.length.toString()}),
                        style: TextStyle(
                          color: surface.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 10),
            ...rows.take(12).map((row) {
              final riskColor =
                  Color.lerp(surface.success, surface.warning, row.riskScore.clamp(0.0, 1.0))!;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openLociRoutes(context, row.locus),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: surface.cardSubtle,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: surface.border.withOpacity(0.38)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                row.locus,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: surface.onSurface,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13),
                              ),
                            ),
                            Text(
                              '${row.attempts} ${_L10n.t('loci_attempts')}',
                              style: TextStyle(color: surface.onSurfaceMuted, fontSize: 10),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.open_in_new_rounded, size: 12, color: surface.onSurfaceMuted),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_L10n.t('loci_error_rate')}: ${(row.errorRate * 100).toStringAsFixed(1)}%',
                                style: TextStyle(color: surface.onSurfaceMuted, fontSize: 11),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${_L10n.t('loci_avg_time')}: ${_fmtSec(row.avgSec)}',
                                textAlign: TextAlign.right,
                                style: TextStyle(color: surface.onSurfaceMuted, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            minHeight: 5,
                            value: row.riskScore.clamp(0.0, 1.0),
                            backgroundColor: surface.border.withOpacity(0.5),
                            valueColor: AlwaysStoppedAnimation(riskColor),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Text(
                              '${_L10n.t('loci_risk')}: ${(row.riskScore * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                  color: riskColor, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            Text(
                              '${_L10n.t('loci_confidence')}: ${(row.confidence * 100).toStringAsFixed(0)}%',
                              style: TextStyle(color: surface.onSurfaceMuted, fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _ReadinessSection extends StatelessWidget {
  final _Surface surface;
  final List<ProfileSessionEntry> sessions; // newest -> oldest
  const _ReadinessSection({required this.surface, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final recent = sessions.length <= 8 ? sessions : sessions.sublist(0, 8);
    if (recent.isEmpty) {
      return _SectionCard(
        surface: surface,
        icon: Icons.bolt_rounded,
        title: _L10n.t('readiness'),
        subtitle: _L10n.t('readiness_subtitle'),
        helpKey: 'help_readiness',
        child: Text(_L10n.t('no_data_hint'), style: TextStyle(color: surface.onSurfaceMuted, fontSize: 12)),
      );
    }

    final avgAcc = recent.fold<double>(0, (a, b) => a + b.accuracy) / recent.length;
    final avgSpeed = recent
            .where((s) => s.speed < 9000)
            .fold<double>(0, (a, b) => a + b.speed) /
        math.max(1, recent.where((s) => s.speed < 9000).length);
    final scoreList = recent.map((e) => e.effectiveRecordScore.toDouble()).toList(growable: false);
    final meanScore = scoreList.reduce((a, b) => a + b) / scoreList.length;
    final variance =
        scoreList.fold<double>(0, (a, b) => a + (b - meanScore) * (b - meanScore)) / scoreList.length;
    final consistency = (1 - (math.sqrt(variance) / math.max(1, meanScore))).clamp(0.0, 1.0);
    final readiness = (0.45 * avgAcc + 0.35 * consistency + 0.20 * (1 / math.max(1.0, avgSpeed)))
        .clamp(0.0, 1.0);
    final readinessPct = (readiness * 100).round();
    final color = readinessPct >= 75
        ? surface.success
        : readinessPct >= 50
            ? surface.warning
            : surface.danger;

    return _SectionCard(
      surface: surface,
      icon: Icons.bolt_rounded,
      title: _L10n.t('readiness'),
      subtitle: _L10n.t('readiness_subtitle'),
      helpKey: 'help_readiness',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$readinessPct%',
                style: TextStyle(color: color, fontSize: 30, fontWeight: FontWeight.w800, height: 1),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  readinessPct >= 75
                      ? _L10n.t('readiness_high')
                      : readinessPct >= 50
                          ? _L10n.t('readiness_mid')
                          : _L10n.t('readiness_low'),
                  style: TextStyle(color: surface.onSurface, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: readiness,
              minHeight: 8,
              backgroundColor: surface.border.withOpacity(0.5),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlateauSection extends StatelessWidget {
  final _Surface surface;
  final List<ProfileSessionEntry> chrono; // oldest -> newest
  const _PlateauSection({required this.surface, required this.chrono});

  @override
  Widget build(BuildContext context) {
    final sample = chrono.length <= 12 ? chrono : chrono.sublist(chrono.length - 12);
    final y = sample.map((e) => e.effectiveRecordScore.toDouble()).toList(growable: false);
    if (y.length < 4) {
      return _SectionCard(
        surface: surface,
        icon: Icons.stacked_line_chart_rounded,
        title: _L10n.t('plateau_detector'),
        subtitle: _L10n.t('plateau_subtitle'),
        helpKey: 'help_plateau',
        child: Text(_L10n.t('no_data_hint'), style: TextStyle(color: surface.onSurfaceMuted, fontSize: 12)),
      );
    }
    double sx = 0, sy = 0, sxx = 0, sxy = 0;
    for (int i = 0; i < y.length; i++) {
      final x = i.toDouble();
      sx += x;
      sy += y[i];
      sxx += x * x;
      sxy += x * y[i];
    }
    final den = y.length * sxx - sx * sx;
    final slope = den.abs() < 1e-9 ? 0.0 : (y.length * sxy - sx * sy) / den;
    final isPlateau = slope.abs() < 0.12;

    return _SectionCard(
      surface: surface,
      icon: Icons.stacked_line_chart_rounded,
      title: _L10n.t('plateau_detector'),
      subtitle: _L10n.t('plateau_subtitle'),
      helpKey: 'help_plateau',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surface.cardSubtle,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: surface.border.withOpacity(0.45)),
        ),
        child: Text(
          isPlateau
              ? _L10n.t('plateau_yes')
              : _L10n.t('plateau_no'),
          style: TextStyle(
            color: isPlateau ? surface.warning : surface.success,
            fontSize: 12,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _RetentionDriftSection extends StatelessWidget {
  final _Surface surface;
  final List<ProfileSessionEntry> sessions; // newest -> oldest
  const _RetentionDriftSection({required this.surface, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final n = sessions.length;
    final current = sessions.take(math.min(5, n)).toList(growable: false);
    final previous = n > 5 ? sessions.skip(5).take(math.min(5, n - 5)).toList(growable: false) : const <ProfileSessionEntry>[];
    if (current.isEmpty || previous.isEmpty) {
      return _SectionCard(
        surface: surface,
        icon: Icons.memory_rounded,
        title: _L10n.t('retention_drift'),
        subtitle: _L10n.t('retention_subtitle'),
        helpKey: 'help_retention',
        child: Text(_L10n.t('no_data_hint'), style: TextStyle(color: surface.onSurfaceMuted, fontSize: 12)),
      );
    }
    final curAcc = current.fold<double>(0, (a, b) => a + b.accuracy) / current.length;
    final prevAcc = previous.fold<double>(0, (a, b) => a + b.accuracy) / previous.length;
    final drift = (curAcc - prevAcc) * 100.0;
    final color = drift >= 0 ? surface.success : surface.danger;
    return _SectionCard(
      surface: surface,
      icon: Icons.memory_rounded,
      title: _L10n.t('retention_drift'),
      subtitle: _L10n.t('retention_subtitle'),
      helpKey: 'help_retention',
      child: Text(
        _L10n.t('retention_delta', {'v': '${drift >= 0 ? '+' : ''}${drift.toStringAsFixed(1)}%'}),
        style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PbProbabilitySection extends StatelessWidget {
  final _Surface surface;
  final List<ProfileSessionEntry> sessions; // newest -> oldest
  const _PbProbabilitySection({required this.surface, required this.sessions});

  @override
  Widget build(BuildContext context) {
    if (sessions.length < 4) {
      return _SectionCard(
        surface: surface,
        icon: Icons.emoji_events_rounded,
        title: _L10n.t('pb_chance'),
        subtitle: _L10n.t('pb_subtitle'),
        helpKey: 'help_pb',
        child: Text(_L10n.t('no_data_hint'), style: TextStyle(color: surface.onSurfaceMuted, fontSize: 12)),
      );
    }
    final recent = sessions.take(12).map((e) => e.effectiveRecordScore.toDouble()).toList(growable: false);
    final best = recent.reduce(math.max);
    final mean = recent.reduce((a, b) => a + b) / recent.length;
    final variance = recent.fold<double>(0, (a, b) => a + (b - mean) * (b - mean)) / recent.length;
    final std = math.sqrt(variance);
    final z = std <= 1e-6 ? 0.0 : (best - mean) / std;
    final prob = (1 / (1 + math.exp(1.2 * (z - 0.8)))).clamp(0.05, 0.95);
    final pct = (prob * 100).round();
    return _SectionCard(
      surface: surface,
      icon: Icons.emoji_events_rounded,
      title: _L10n.t('pb_chance'),
      subtitle: _L10n.t('pb_subtitle'),
      helpKey: 'help_pb',
      child: Text(
        _L10n.t('pb_estimate', {'n': pct.toString()}),
        style: TextStyle(color: surface.accent, fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CircadianSection extends StatelessWidget {
  final _Surface surface;
  final List<ProfileSessionEntry> sessions;
  const _CircadianSection({required this.surface, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final byHour = <int, List<double>>{};
    for (final s in sessions) {
      byHour.putIfAbsent(s.date.hour, () => <double>[]).add(s.effectiveRecordScore.toDouble());
    }
    if (byHour.isEmpty) {
      return _SectionCard(
        surface: surface,
        icon: Icons.schedule_rounded,
        title: _L10n.t('circadian'),
        subtitle: _L10n.t('circadian_subtitle'),
        helpKey: 'help_circadian',
        child: Text(_L10n.t('no_data_hint'), style: TextStyle(color: surface.onSurfaceMuted, fontSize: 12)),
      );
    }
    int bestHour = 0;
    double bestScore = -1;
    byHour.forEach((hour, list) {
      final avg = list.reduce((a, b) => a + b) / list.length;
      if (avg > bestScore) {
        bestScore = avg;
        bestHour = hour;
      }
    });
    return _SectionCard(
      surface: surface,
      icon: Icons.schedule_rounded,
      title: _L10n.t('circadian'),
      subtitle: _L10n.t('circadian_subtitle'),
      helpKey: 'help_circadian',
      child: Text(
        _L10n.t('circadian_window', {
          'from': bestHour.toString().padLeft(2, '0'),
          'to': ((bestHour + 1) % 24).toString().padLeft(2, '0'),
        }),
        style: TextStyle(color: surface.onSurface, fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ErrorTaxonomySection extends StatelessWidget {
  final _Surface surface;
  final List<TrainingHistoryEntry> history;
  const _ErrorTaxonomySection({required this.surface, required this.history});

  @override
  Widget build(BuildContext context) {
    var substitution = 0;
    var omission = 0;
    var transposition = 0;
    for (final h in history.take(20)) {
      final n = math.min(h.data.length, h.answers.length);
      for (int i = 0; i < n; i++) {
        final expected = h.data[i].trim();
        final answer = h.answers[i].trim();
        if (expected.isEmpty || answer.isEmpty) {
          if (expected.isNotEmpty || answer.isNotEmpty) omission++;
          continue;
        }
        if (expected == answer) continue;
        if (i + 1 < n && h.answers[i + 1].trim() == expected) {
          transposition++;
        } else {
          substitution++;
        }
      }
    }
    final total = substitution + omission + transposition;
    return _SectionCard(
      surface: surface,
      icon: Icons.bug_report_rounded,
      title: _L10n.t('error_taxonomy'),
      subtitle: _L10n.t('error_subtitle'),
      helpKey: 'help_error_taxonomy',
      child: total <= 0
          ? Text(_L10n.t('no_data_hint'), style: TextStyle(color: surface.onSurfaceMuted, fontSize: 12))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _errorLine(surface, _L10n.t('error_substitution'), substitution, total, surface.danger),
                const SizedBox(height: 6),
                _errorLine(surface, _L10n.t('error_omission'), omission, total, surface.warning),
                const SizedBox(height: 6),
                _errorLine(surface, _L10n.t('error_order'), transposition, total, surface.accent),
              ],
            ),
    );
  }

  Widget _errorLine(_Surface s, String label, int value, int total, Color color) {
    final pct = total <= 0 ? 0.0 : value / total;
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: TextStyle(color: s.onSurfaceMuted, fontSize: 11)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: s.border.withOpacity(0.5),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('${(pct * 100).toStringAsFixed(0)}%', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painters.
// ─────────────────────────────────────────────────────────────────────────────
class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final Color bgGrid;
  final Color fillFrom;
  final Color fillTo;
  final double progress;
  final double? fixedMax;
  final double? fixedMin;
  final int? highlightIndex;
  final Color? highlightColor;

  _LineChartPainter({
    required this.values,
    required this.color,
    required this.bgGrid,
    required this.fillFrom,
    required this.fillTo,
    required this.progress,
    this.fixedMax,
    this.fixedMin,
    this.highlightIndex,
    this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size, bgGrid);

    if (values.isEmpty) return;

    final minV = fixedMin ??
        values.reduce(math.min);
    final maxV = math.max(
      fixedMax ?? values.reduce(math.max),
      minV + 1e-9,
    );

    final n = values.length;
    final pts = List<Offset>.generate(n, (i) {
      final x = n == 1 ? size.width / 2 : size.width * (i / (n - 1));
      final y = size.height -
          ((values[i] - minV) / (maxV - minV)).clamp(0.0, 1.0) *
              (size.height - 10) -
          5;
      return Offset(x, y.clamp(2.0, size.height - 2));
    });

    final reveal = (size.width * progress.clamp(0.0, 1.0));

    if (n >= 2) {
      final line = Path()..moveTo(pts.first.dx, pts.first.dy);
      final fill = Path()
        ..moveTo(pts.first.dx, size.height)
        ..lineTo(pts.first.dx, pts.first.dy);
      for (int i = 1; i < n; i++) {
        line.lineTo(pts[i].dx, pts[i].dy);
        fill.lineTo(pts[i].dx, pts[i].dy);
      }
      fill.lineTo(pts.last.dx, size.height);
      fill.close();

      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, reveal, size.height));
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fillFrom, fillTo],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;
      canvas.drawPath(fill, fillPaint);

      final linePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(line, linePaint);
      canvas.restore();
    }

    if (highlightIndex != null &&
        highlightIndex! >= 0 &&
        highlightIndex! < n &&
        highlightColor != null) {
      final p = pts[highlightIndex!];
      if (p.dx <= reveal) {
        final glow = Paint()..color = highlightColor!.withOpacity(0.3);
        canvas.drawCircle(p, 9, glow);
        final dot = Paint()..color = highlightColor!;
        canvas.drawCircle(p, 4, dot);
        final ring = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6;
        canvas.drawCircle(p, 4, ring);
      }
    }
  }

  void _drawGrid(Canvas canvas, Size size, Color color) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    for (int i = 0; i <= 3; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.values != values ||
      old.color != color ||
      old.bgGrid != bgGrid ||
      old.fillFrom != fillFrom ||
      old.fillTo != fillTo ||
      old.progress != progress ||
      old.highlightIndex != highlightIndex ||
      old.highlightColor != highlightColor ||
      old.fixedMax != fixedMax ||
      old.fixedMin != fixedMin;
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double progress;

  _SparklinePainter({
    required this.values,
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV = math.max(values.reduce(math.max), 1e-9);
    final minV = values.reduce(math.min);
    final range = math.max(maxV - minV, 1e-9);
    final n = values.length;

    final path = Path();
    for (int i = 0; i < n; i++) {
      final x = n == 1 ? size.width / 2 : size.width * (i / (n - 1));
      final y =
          size.height - ((values[i] - minV) / range) * (size.height - 6) - 3;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final reveal = (size.width * progress.clamp(0.0, 1.0));
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, reveal, size.height));
    final p = Paint()
      ..color = color.withOpacity(0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, p);

    final dot = Paint()..color = color;
    if (n > 0) {
      final i = n - 1;
      final x = n == 1 ? size.width / 2 : size.width * (i / (n - 1));
      final y =
          size.height - ((values[i] - minV) / range) * (size.height - 6) - 3;
      canvas.drawCircle(Offset(x, y), 2.6, dot);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.values != values || old.color != color || old.progress != progress;
}

class _PredictionChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final Color bgGrid;
  final Color fillFrom;
  final Color fillTo;
  final Color futureColor;
  final List<double> futurePoints; // [pred7, pred30]
  final double progress;

  _PredictionChartPainter({
    required this.values,
    required this.color,
    required this.bgGrid,
    required this.fillFrom,
    required this.fillTo,
    required this.futureColor,
    required this.futurePoints,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = bgGrid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    for (int i = 0; i <= 3; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (values.isEmpty) return;

    final allValues = <double>[...values, ...futurePoints];
    final maxV = math.max(allValues.reduce(math.max), 1.0);
    final minV = math.min(allValues.reduce(math.min), 0.0);
    final range = math.max(maxV - minV, 1e-9);

    final n = values.length;
    final pastWidth = size.width * 0.6;
    final futureWidth = size.width - pastWidth;

    final pastPts = List<Offset>.generate(n, (i) {
      final x = n == 1 ? pastWidth / 2 : pastWidth * (i / (n - 1));
      final y = size.height -
          ((values[i] - minV) / range).clamp(0.0, 1.0) * (size.height - 10) -
          5;
      return Offset(x, y);
    });

    final futurePts = <Offset>[];
    if (futurePoints.length >= 2) {
      final v7 = futurePoints[0];
      final v30 = futurePoints[1];
      final last = pastPts.isNotEmpty ? pastPts.last : Offset(pastWidth, size.height / 2);
      double yOf(double v) => size.height -
          ((v - minV) / range).clamp(0.0, 1.0) * (size.height - 10) -
          5;
      futurePts
        ..add(last)
        ..add(Offset(pastWidth + futureWidth * 0.35, yOf(v7)))
        ..add(Offset(pastWidth + futureWidth * 1.0, yOf(v30)));
    }

    final reveal = (size.width * progress.clamp(0.0, 1.0));

    if (n >= 2) {
      final line = Path()..moveTo(pastPts.first.dx, pastPts.first.dy);
      final fill = Path()
        ..moveTo(pastPts.first.dx, size.height)
        ..lineTo(pastPts.first.dx, pastPts.first.dy);
      for (int i = 1; i < n; i++) {
        line.lineTo(pastPts[i].dx, pastPts[i].dy);
        fill.lineTo(pastPts[i].dx, pastPts[i].dy);
      }
      fill.lineTo(pastPts.last.dx, size.height);
      fill.close();

      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, reveal, size.height));
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fillFrom, fillTo],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;
      canvas.drawPath(fill, fillPaint);

      final linePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(line, linePaint);
      canvas.restore();
    }

    // Dashed future projection.
    if (futurePts.length >= 2) {
      final dashPaint = Paint()
        ..color = futureColor.withOpacity(0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;

      for (int i = 1; i < futurePts.length; i++) {
        _drawDashedLine(
          canvas,
          futurePts[i - 1],
          futurePts[i],
          dashPaint,
          dashWidth: 4,
          dashGap: 4,
          maxX: reveal,
        );
      }

      // Dots at projection points.
      final dot = Paint()..color = futureColor;
      for (int i = 1; i < futurePts.length; i++) {
        if (futurePts[i].dx <= reveal) {
          canvas.drawCircle(futurePts[i], 3, dot);
        }
      }
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset a,
    Offset b,
    Paint paint, {
    required double dashWidth,
    required double dashGap,
    required double maxX,
  }) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist <= 0) return;
    final ux = dx / dist;
    final uy = dy / dist;
    double traveled = 0;
    bool drawing = true;
    while (traveled < dist) {
      final step = drawing ? dashWidth : dashGap;
      final endLen = math.min(traveled + step, dist);
      if (drawing) {
        final p1 = Offset(a.dx + ux * traveled, a.dy + uy * traveled);
        final p2 = Offset(a.dx + ux * endLen, a.dy + uy * endLen);
        if (p1.dx <= maxX) {
          final clipped = p2.dx <= maxX
              ? p2
              : Offset(maxX, a.dy + uy * ((maxX - a.dx) / ux.abs().clamp(1e-6, double.infinity)));
          canvas.drawLine(p1, clipped, paint);
        }
      }
      traveled = endLen;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(covariant _PredictionChartPainter old) =>
      old.values != values ||
      old.futurePoints != futurePoints ||
      old.color != color ||
      old.futureColor != futureColor ||
      old.progress != progress;
}
