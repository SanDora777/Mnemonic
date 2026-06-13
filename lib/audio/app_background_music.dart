import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/core/app_session.dart';

const String kPrefsMusicEnabled = 'app_music_enabled_v1';
const String kPrefsSoundEnabled = 'app_sound_enabled_v1';
const String kBackgroundMusicAsset = 'assets/audio/music/where_light_rests.mp3';

final ValueNotifier<bool> appMusicEnabled = ValueNotifier<bool>(true);
final ValueNotifier<bool> appSoundEnabled = ValueNotifier<bool>(true);

const double kBackgroundMusicVolume = 0.22;
const double kBackgroundMusicBootstrapVolume = 0.07;

const Duration _fadeInDuration = Duration(milliseconds: 1000);
const Duration _fadeOutDuration = Duration(milliseconds: 900);
const Duration _fadeOutTrainingDuration = Duration(milliseconds: 1200);

Future<void> loadAudioPreferences(SharedPreferences prefs) async {
  appMusicEnabled.value = prefs.getBool(kPrefsMusicEnabled) ?? true;
  appSoundEnabled.value = prefs.getBool(kPrefsSoundEnabled) ?? true;
}

Future<void> persistMusicEnabled(bool value) async {
  appMusicEnabled.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kPrefsMusicEnabled, value);
}

Future<void> persistSoundEnabled(bool value) async {
  appSoundEnabled.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kPrefsSoundEnabled, value);
}

class AppBackgroundMusic {
  AppBackgroundMusic._();

  static final AppBackgroundMusic instance = AppBackgroundMusic._();

  final AudioPlayer _player = AudioPlayer();
  bool _initialized = false;
  bool _assetReady = false;
  bool _playing = false;
  bool _pausedByLifecycle = false;
  double _currentVolume = 0;
  Timer? _fadeTimer;
  int _fadeGeneration = 0;
  Future<void>? _prepareFuture;

  Future<void> prepare() {
    return _prepareFuture ??= _prepareImpl();
  }

  Future<void> _prepareImpl() async {
    if (_assetReady) return;
    try {
      await _player.setLoopMode(LoopMode.one);
      await _player.setAsset(kBackgroundMusicAsset);
      await _player.setVolume(0);
      _currentVolume = 0;
      _assetReady = true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('AppBackgroundMusic: failed to load asset: $e\n$st');
      }
    }
  }

  Future<void> init() async {
    if (_initialized) {
      unawaited(_sync());
      return;
    }
    await prepare();
    if (!_assetReady) return;

    _initialized = true;
    appMusicEnabled.addListener(_onMusicEnabledChanged);
    trainingSessionDepth.addListener(_onTrainingDepthChanged);
    unawaited(_sync());
  }

  Future<void> shutdown() async {
    appMusicEnabled.removeListener(_onMusicEnabledChanged);
    trainingSessionDepth.removeListener(_onTrainingDepthChanged);
    await _stopImmediately();
    _fadeGeneration++;
    _fadeTimer?.cancel();
    await _player.stop();
    await _player.dispose();
    _initialized = false;
    _assetReady = false;
    _prepareFuture = null;
    _playing = false;
    _pausedByLifecycle = false;
  }

  /// App moved to background — pause menu music.
  void onAppPaused() {
    if (_pausedByLifecycle) return;
    _pausedByLifecycle = true;
    unawaited(_fadeOutAndPause(duration: _fadeOutDuration));
  }

  /// App returned to foreground.
  void onAppResumed() {
    if (!_pausedByLifecycle) return;
    _pausedByLifecycle = false;
    unawaited(_sync());
  }

  void _onMusicEnabledChanged() {
    if (!appMusicEnabled.value) {
      unawaited(_stopImmediately());
      return;
    }
    if (!_pausedByLifecycle && !isTrainingSessionActive) {
      unawaited(_sync());
    }
  }

  void _onTrainingDepthChanged() => unawaited(_sync());

  bool get _shouldPlay =>
      appMusicEnabled.value && !isTrainingSessionActive && !_pausedByLifecycle;

  Future<void> _sync() async {
    if (!_initialized || !_assetReady) return;

    final want = _shouldPlay;
    if (want) {
      if (_playing && _currentVolume >= kBackgroundMusicVolume * 0.9) return;
      await _fadeInAndPlay();
      return;
    }

    if (!appMusicEnabled.value) {
      await _stopImmediately();
      return;
    }

    if (_playing || _player.playing) {
      await _fadeOutAndPause();
    }
  }

  Future<void> _stopImmediately() async {
    _fadeGeneration++;
    _fadeTimer?.cancel();
    _playing = false;
    _currentVolume = 0;
    try {
      await _player.pause();
      await _player.setVolume(0);
    } catch (_) {}
  }

  Future<void> _fadeInAndPlay() async {
    if (!appMusicEnabled.value || isTrainingSessionActive || _pausedByLifecycle) {
      return;
    }

    final gen = ++_fadeGeneration;
    _fadeTimer?.cancel();

    try {
      if (!_player.playing) {
        await _player.setVolume(kBackgroundMusicBootstrapVolume);
        _currentVolume = kBackgroundMusicBootstrapVolume;
        await _player.play();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('AppBackgroundMusic: play failed: $e');
      return;
    }

    _playing = true;
    await _runVolumeFade(
      generation: gen,
      from: _currentVolume,
      to: kBackgroundMusicVolume,
      duration: _fadeInDuration,
    );
  }

  Future<void> _fadeOutAndPause({Duration duration = _fadeOutTrainingDuration}) async {
    final gen = ++_fadeGeneration;
    _fadeTimer?.cancel();
    _playing = false;

    final from = _currentVolume;
    if (from <= 0.001) {
      await _stopImmediately();
      return;
    }

    await _runVolumeFade(
      generation: gen,
      from: from,
      to: 0,
      duration: duration,
      onComplete: () async {
        if (gen != _fadeGeneration) return;
        await _stopImmediately();
      },
    );
  }

  Future<void> _runVolumeFade({
    required int generation,
    required double from,
    required double to,
    required Duration duration,
    Future<void> Function()? onComplete,
  }) async {
    const steps = 20;
    final stepMs = math.max(12, duration.inMilliseconds ~/ steps);
    var step = 0;

    final completer = Completer<void>();
    _fadeTimer?.cancel();
    _fadeTimer = Timer.periodic(Duration(milliseconds: stepMs), (timer) {
      if (generation != _fadeGeneration) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete();
        return;
      }

      step++;
      final t = Curves.easeInOut.transform((step / steps).clamp(0.0, 1.0));
      final volume = (from + (to - from) * t).clamp(0.0, 1.0);
      _currentVolume = volume;
      unawaited(_player.setVolume(volume));

      if (step >= steps) {
        timer.cancel();
        _currentVolume = to.clamp(0.0, 1.0);
        unawaited(_player.setVolume(_currentVolume));
        if (onComplete != null) unawaited(onComplete());
        if (!completer.isCompleted) completer.complete();
      }
    });

    return completer.future;
  }
}
