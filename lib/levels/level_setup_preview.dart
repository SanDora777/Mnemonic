import '../recovered_app.dart'
    show AppLanguage, TrainingMode, appLanguage;
import 'level_definitions.dart';
import 'level_i18n.dart';

/// Read-only snapshot of user trainer settings for level detail screen.
class TrainerSetupPreview {
  const TrainerSetupPreview({
    required this.digitsLabel,
    required this.chunkLabel,
    required this.lociLabel,
    required this.timerLabel,
    required this.extraLines,
  });

  final String digitsLabel;
  final String chunkLabel;
  final String lociLabel;
  final String timerLabel;
  final List<String> extraLines;
}

TrainerSetupPreview buildSetupPreview({
  required TrainingMode mode,
  required int standardDigits,
  required bool isMatrixMode,
  required int chunkSize,
  required bool lociOn,
  required int sessionMemCapSec,
  required bool useMemorizationTimer,
  required double flashSeconds,
  required bool cardsShuffledDeck,
  required String faceNamePool,
}) {
  String txt(Map<AppLanguage, String> m) =>
      m[appLanguage.value] ?? m[AppLanguage.ru] ?? '';

  final timer = sessionMemCapSec > 0
      ? txt({
          AppLanguage.ru: '$sessionMemCapSec с · запоминание',
          AppLanguage.en: '${sessionMemCapSec}s · memorize',
          AppLanguage.de: '${sessionMemCapSec}s · merken',
        })
      : useMemorizationTimer
          ? txt({
              AppLanguage.ru: '${flashSeconds.toStringAsFixed(1)} с / элемент',
              AppLanguage.en: '${flashSeconds.toStringAsFixed(1)}s / element',
              AppLanguage.de: '${flashSeconds.toStringAsFixed(1)}s / Element',
            })
          : txt({
              AppLanguage.ru: 'Без лимита',
              AppLanguage.en: 'Unlimited',
              AppLanguage.de: 'Unbegrenzt',
            });

  final loci = lociOn
      ? txt({
          AppLanguage.ru: 'Локусы ВКЛ',
          AppLanguage.en: 'Loci ON',
          AppLanguage.de: 'Loci AN',
        })
      : txt({
          AppLanguage.ru: 'Локусы ВЫКЛ',
          AppLanguage.en: 'Loci OFF',
          AppLanguage.de: 'Loci AUS',
        });

  final chunk = txt({
    AppLanguage.ru: '$chunkSize на экран',
    AppLanguage.en: '$chunkSize / screen',
    AppLanguage.de: '$chunkSize / Bildschirm',
  });

  var digits = '';
  final extras = <String>[];

  switch (mode) {
    case TrainingMode.standard:
      if (isMatrixMode) {
        digits = txt({
          AppLanguage.ru: 'Матрица',
          AppLanguage.en: 'Matrix',
          AppLanguage.de: 'Matrix',
        });
      } else {
        final range = standardDigits == 1
            ? '0–9'
            : standardDigits == 2
                ? '00–99'
                : '000–999';
        digits = range;
      }
      break;
    case TrainingMode.binary:
      digits = txt({
        AppLanguage.ru: 'Бинар',
        AppLanguage.en: 'Binary',
        AppLanguage.de: 'Binär',
      });
      break;
    case TrainingMode.cards:
      digits = cardsShuffledDeck
          ? txt({
              AppLanguage.ru: 'Полная колода',
              AppLanguage.en: 'Full deck',
              AppLanguage.de: 'Volles Deck',
            })
          : txt({
              AppLanguage.ru: 'Случайные карты',
              AppLanguage.en: 'Random cards',
              AppLanguage.de: 'Zufällige Karten',
            });
      break;
    case TrainingMode.faces:
      digits = faceNamePool;
      break;
    case TrainingMode.words:
      digits = txt({
        AppLanguage.ru: 'Слова',
        AppLanguage.en: 'Words',
        AppLanguage.de: 'Wörter',
      });
      break;
    case TrainingMode.images:
      digits = txt({
        AppLanguage.ru: 'Образы',
        AppLanguage.en: 'Images',
        AppLanguage.de: 'Bilder',
      });
      break;
  }

  return TrainerSetupPreview(
    digitsLabel: digits,
    chunkLabel: chunk,
    lociLabel: loci,
    timerLabel: timer,
    extraLines: extras,
  );
}

String levelTimeRequirementLabel(TrainerLevelDef level) {
  if (level.memTimeLimitSec != null && level.memTimeLimitSec! > 0) {
    final sec = level.memTimeLimitSec!;
    return levelTxt({
      AppLanguage.ru: '$sec с на запоминание',
      AppLanguage.en: '${sec}s memorize cap',
      AppLanguage.de: '${sec}s Merk-Limit',
    });
  }
  return levelTxt({
    AppLanguage.ru: 'Без лимита',
    AppLanguage.en: 'Unlimited',
    AppLanguage.de: 'Unbegrenzt',
  });
}
