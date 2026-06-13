import 'package:flutter/foundation.dart';

/// Tracks active [TrainingScreen] instances (solo, duel, academy, etc.).
final ValueNotifier<int> trainingSessionDepth = ValueNotifier<int>(0);

bool get isTrainingSessionActive => trainingSessionDepth.value > 0;

/// True while user is memorizing or entering recall answers — UI clicks stay silent.
final ValueNotifier<bool> trainingQuietMode = ValueNotifier<bool>(false);

void setTrainingQuietMode(bool value) {
  if (trainingQuietMode.value == value) return;
  trainingQuietMode.value = value;
}

void enterTrainingSession() {
  trainingSessionDepth.value = trainingSessionDepth.value + 1;
}

void leaveTrainingSession() {
  final next = trainingSessionDepth.value - 1;
  trainingSessionDepth.value = next < 0 ? 0 : next;
  if (trainingSessionDepth.value == 0) {
    setTrainingQuietMode(false);
  }
}
