/// Trainer actions that can be bound to keyboard shortcuts.
enum TrainerShortcutId {
  startTraining,
  nextChunk,
  prevChunk,
  firstChunk,
  recallNow,
  scrollDown,
  scrollUp,
  toggleLociMap,
  saveCheckpoint,
}

extension TrainerShortcutIdLabels on TrainerShortcutId {
  String label(String lang) {
    final ru = switch (this) {
      TrainerShortcutId.startTraining => 'Начать тренировку',
      TrainerShortcutId.nextChunk => 'Следующий чанк',
      TrainerShortcutId.prevChunk => 'Предыдущий чанк',
      TrainerShortcutId.firstChunk => 'Первый чанк',
      TrainerShortcutId.recallNow => 'К вспоминанию',
      TrainerShortcutId.scrollDown => 'Прокрутка вниз',
      TrainerShortcutId.scrollUp => 'Прокрутка вверх',
      TrainerShortcutId.toggleLociMap => 'Карта локи',
      TrainerShortcutId.saveCheckpoint => 'Сохранить чекпоинт',
    };
    final en = switch (this) {
      TrainerShortcutId.startTraining => 'Start training',
      TrainerShortcutId.nextChunk => 'Next chunk',
      TrainerShortcutId.prevChunk => 'Previous chunk',
      TrainerShortcutId.firstChunk => 'First chunk',
      TrainerShortcutId.recallNow => 'Start recall',
      TrainerShortcutId.scrollDown => 'Scroll down',
      TrainerShortcutId.scrollUp => 'Scroll up',
      TrainerShortcutId.toggleLociMap => 'Toggle loci map',
      TrainerShortcutId.saveCheckpoint => 'Save checkpoint',
    };
    final de = switch (this) {
      TrainerShortcutId.startTraining => 'Training starten',
      TrainerShortcutId.nextChunk => 'Nächster Chunk',
      TrainerShortcutId.prevChunk => 'Vorheriger Chunk',
      TrainerShortcutId.firstChunk => 'Erster Chunk',
      TrainerShortcutId.recallNow => 'Zum Abruf',
      TrainerShortcutId.scrollDown => 'Nach unten scrollen',
      TrainerShortcutId.scrollUp => 'Nach oben scrollen',
      TrainerShortcutId.toggleLociMap => 'Loci-Karte umschalten',
      TrainerShortcutId.saveCheckpoint => 'Checkpoint speichern',
    };
    return switch (lang) {
      'en' => en,
      'de' => de,
      _ => ru,
    };
  }

  static List<TrainerShortcutId> forPhase(TrainerShortcutPhase phase) {
    return switch (phase) {
      TrainerShortcutPhase.setup => const [
          TrainerShortcutId.startTraining,
          TrainerShortcutId.toggleLociMap,
          TrainerShortcutId.saveCheckpoint,
        ],
      TrainerShortcutPhase.memorize => const [
          TrainerShortcutId.nextChunk,
          TrainerShortcutId.prevChunk,
          TrainerShortcutId.firstChunk,
          TrainerShortcutId.recallNow,
          TrainerShortcutId.scrollDown,
          TrainerShortcutId.scrollUp,
          TrainerShortcutId.toggleLociMap,
          TrainerShortcutId.saveCheckpoint,
        ],
      TrainerShortcutPhase.inactive => const [],
    };
  }
}

enum TrainerShortcutPhase { setup, memorize, inactive }
