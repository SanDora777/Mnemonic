import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../audio/app_ui_sounds.dart';

export '../../audio/app_ui_sounds.dart' show UiClickSound;

const String kPrefsHapticEnabled = 'app_haptic_enabled_v1';

final ValueNotifier<bool> appHapticEnabled = ValueNotifier<bool>(true);

Future<void> loadHapticPreference(SharedPreferences prefs) async {
  appHapticEnabled.value = prefs.getBool(kPrefsHapticEnabled) ?? true;
}

Future<void> persistHapticEnabled(bool value) async {
  appHapticEnabled.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kPrefsHapticEnabled, value);
}

/// Haptic only — respects [appHapticEnabled].
void appHaptic([UiClickSound sound = UiClickSound.soft]) {
  if (!appHapticEnabled.value) return;
  switch (sound) {
    case UiClickSound.soft:
      HapticFeedback.lightImpact();
    case UiClickSound.bright:
      HapticFeedback.mediumImpact();
    case UiClickSound.deep:
      HapticFeedback.selectionClick();
  }
}

/// Plays haptic + UI click (if sound enabled and not in memorization/input).
void uiTapClick([UiClickSound sound = UiClickSound.soft]) {
  appHaptic(sound);
  AppUiSounds.instance.play(sound);
}

VoidCallback? withUiTap(
  VoidCallback? action, {
  UiClickSound sound = UiClickSound.soft,
}) {
  if (action == null) return null;
  return () {
    uiTapClick(sound);
    action();
  };
}

void uiPlayLevelFail() => AppUiSounds.instance.playLevelFail();

void uiPlayLevelSuccess() => AppUiSounds.instance.playLevelSuccess();

void uiPlayAcademyLessonComplete() =>
    AppUiSounds.instance.playAcademyLessonComplete();
