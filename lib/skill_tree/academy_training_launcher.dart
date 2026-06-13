import 'package:flutter/material.dart';

import '../recovered_app.dart'
    show LociRoutesScreen, NumberImagesListScreen, TrainingMode, TrainingScreen;
import 'lesson_framework.dart';

/// Открывает тренажёр с параметрами, заданными из урока академии.
void academyLaunchLessonTrainer(
  BuildContext context,
  LessonTrainerLaunchKind kind,
) {
  final Widget? screen = switch (kind) {
    LessonTrainerLaunchKind.none => null,
    LessonTrainerLaunchKind.academyNumberCodes09 =>
      const NumberImagesListScreen(),
    LessonTrainerLaunchKind.academyNumbers09Elements10 =>
      const TrainingScreen(
        initialMode: TrainingMode.standard,
        academyStandardDigitsLevel: 1,
        academyElementCount: 10,
        academyChunkSize: 1,
        academyUseMemorizationTimer: false,
      ),
    LessonTrainerLaunchKind.academyNumbers09Elements15 =>
      const TrainingScreen(
        initialMode: TrainingMode.standard,
        academyStandardDigitsLevel: 1,
        academyElementCount: 15,
        academyChunkSize: 1,
        academyUseMemorizationTimer: false,
      ),
    LessonTrainerLaunchKind.academyNumbers09Elements20 =>
      const TrainingScreen(
        initialMode: TrainingMode.standard,
        academyStandardDigitsLevel: 1,
        academyElementCount: 20,
        academyChunkSize: 1,
        academyUseMemorizationTimer: false,
      ),
    LessonTrainerLaunchKind.academyNumbersTimedFree =>
      const TrainingScreen(
        initialMode: TrainingMode.standard,
        academyStandardDigitsLevel: 1,
        academyElementCount: 200,
        academyChunkSize: 1,
        academyUseMemorizationTimer: false,
      ),
    LessonTrainerLaunchKind.academyImagesMainObjectExplore =>
      const TrainingScreen(
        initialMode: TrainingMode.images,
        academyElementCount: 12,
        academyChunkSize: 1,
        academyUseMemorizationTimer: false,
      ),
    LessonTrainerLaunchKind.academyCardsElements10 =>
      const TrainingScreen(
        initialMode: TrainingMode.cards,
        academyElementCount: 10,
        academyChunkSize: 1,
        academyUseMemorizationTimer: false,
      ),
    LessonTrainerLaunchKind.academyWordsElements10 =>
      const TrainingScreen(
        initialMode: TrainingMode.words,
        academyElementCount: 10,
        academyChunkSize: 1,
        academyUseMemorizationTimer: false,
      ),
    LessonTrainerLaunchKind.academyWordsSpeedFlash2s =>
      const TrainingScreen(
        initialMode: TrainingMode.words,
        academyElementCount: 20,
        academyChunkSize: 1,
        academyUseMemorizationTimer: true,
        academyFlashSecondsPerItem: 2.0,
      ),
    LessonTrainerLaunchKind.academyBinaryElements10 =>
      const TrainingScreen(
        initialMode: TrainingMode.binary,
        academyElementCount: 10,
        academyChunkSize: 1,
        academyUseMemorizationTimer: false,
      ),
    LessonTrainerLaunchKind.academyLociRoutes => const LociRoutesScreen(),
  };

  final open = screen;
  if (open == null) return;

  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => open,
      fullscreenDialog: false,
    ),
  );
}
