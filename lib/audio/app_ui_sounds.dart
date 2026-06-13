import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../app/core/app_session.dart';
import 'app_background_music.dart';

/// Kept for call sites; all variants use the same [ui_click.mp3].
enum UiClickSound {
  soft,
  bright,
  deep,
}

/// UI click + level/academy event sounds.
class AppUiSounds {
  AppUiSounds._();
  static final AppUiSounds instance = AppUiSounds._();

  static const String _clickAsset = 'assets/audio/sfx/ui_click.mp3';
  static const String _levelFailAsset = 'assets/audio/sfx/level_fail.mp3';
  static const String _levelSuccessAsset = 'assets/audio/sfx/level_success.mp3';
  static const String _academyLessonCompleteAsset =
      'assets/audio/sfx/academy_lesson_complete.mp3';

  static const double _clickVolume = 0.42;
  static const double _eventVolume = 0.48;

  final AudioPlayer _click = AudioPlayer();
  final AudioPlayer _levelFail = AudioPlayer();
  final AudioPlayer _levelSuccess = AudioPlayer();
  final AudioPlayer _academyLessonComplete = AudioPlayer();

  bool _ready = false;
  Future<void>? _prepareFuture;

  Future<void> prepare() {
    return _prepareFuture ??= _prepareImpl();
  }

  Future<void> _prepareImpl() async {
    if (_ready) return;
    try {
      await Future.wait<void>([
        _click.setAsset(_clickAsset),
        _levelFail.setAsset(_levelFailAsset),
        _levelSuccess.setAsset(_levelSuccessAsset),
        _academyLessonComplete.setAsset(_academyLessonCompleteAsset),
      ]);
      await _click.setVolume(_clickVolume);
      for (final player in [_levelFail, _levelSuccess, _academyLessonComplete]) {
        await player.setVolume(_eventVolume);
      }
      _ready = true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('AppUiSounds: prepare failed: $e\n$st');
      }
    }
  }

  void play(UiClickSound sound) {
    _play(_click, respectTrainingQuiet: true);
  }

  void playLevelFail() {
    _play(_levelFail, respectTrainingQuiet: false);
  }

  void playLevelSuccess() {
    _play(_levelSuccess, respectTrainingQuiet: false);
  }

  void playAcademyLessonComplete() {
    _play(_academyLessonComplete, respectTrainingQuiet: false);
  }

  void _play(AudioPlayer player, {required bool respectTrainingQuiet}) {
    if (!appSoundEnabled.value) return;
    if (respectTrainingQuiet && trainingQuietMode.value) return;
    if (!_ready) return;
    unawaited(_playClip(player));
  }

  Future<void> _playClip(AudioPlayer player) async {
    try {
      await player.seek(Duration.zero);
      await player.play();
    } catch (e) {
      if (kDebugMode) debugPrint('AppUiSounds: play failed: $e');
    }
  }
}
