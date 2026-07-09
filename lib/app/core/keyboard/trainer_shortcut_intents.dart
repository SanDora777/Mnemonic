import 'package:flutter/widgets.dart';

import 'trainer_shortcut_id.dart';

abstract class TrainerShortcutIntent extends Intent {
  const TrainerShortcutIntent(this.id);
  final TrainerShortcutId id;
}

class StartTrainingIntent extends TrainerShortcutIntent {
  const StartTrainingIntent() : super(TrainerShortcutId.startTraining);
}

class NextChunkIntent extends TrainerShortcutIntent {
  const NextChunkIntent() : super(TrainerShortcutId.nextChunk);
}

class PrevChunkIntent extends TrainerShortcutIntent {
  const PrevChunkIntent() : super(TrainerShortcutId.prevChunk);
}

class FirstChunkIntent extends TrainerShortcutIntent {
  const FirstChunkIntent() : super(TrainerShortcutId.firstChunk);
}

class RecallNowIntent extends TrainerShortcutIntent {
  const RecallNowIntent() : super(TrainerShortcutId.recallNow);
}

class ScrollDownIntent extends TrainerShortcutIntent {
  const ScrollDownIntent() : super(TrainerShortcutId.scrollDown);
}

class ScrollUpIntent extends TrainerShortcutIntent {
  const ScrollUpIntent() : super(TrainerShortcutId.scrollUp);
}

class ToggleLociMapIntent extends TrainerShortcutIntent {
  const ToggleLociMapIntent() : super(TrainerShortcutId.toggleLociMap);
}

class SaveCheckpointIntent extends TrainerShortcutIntent {
  const SaveCheckpointIntent() : super(TrainerShortcutId.saveCheckpoint);
}

TrainerShortcutIntent intentForId(TrainerShortcutId id) {
  return switch (id) {
    TrainerShortcutId.startTraining => const StartTrainingIntent(),
    TrainerShortcutId.nextChunk => const NextChunkIntent(),
    TrainerShortcutId.prevChunk => const PrevChunkIntent(),
    TrainerShortcutId.firstChunk => const FirstChunkIntent(),
    TrainerShortcutId.recallNow => const RecallNowIntent(),
    TrainerShortcutId.scrollDown => const ScrollDownIntent(),
    TrainerShortcutId.scrollUp => const ScrollUpIntent(),
    TrainerShortcutId.toggleLociMap => const ToggleLociMapIntent(),
    TrainerShortcutId.saveCheckpoint => const SaveCheckpointIntent(),
  };
}

Type intentTypeForId(TrainerShortcutId id) => intentForId(id).runtimeType;
