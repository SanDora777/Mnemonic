import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'trainer_shortcut_binding.dart';
import 'trainer_shortcut_id.dart';
import 'trainer_shortcut_intents.dart';

/// Loads, saves, and resolves trainer keyboard shortcuts (web + desktop).
class WebKeyboardManager extends ChangeNotifier {
  WebKeyboardManager._();

  static final WebKeyboardManager instance = WebKeyboardManager._();

  static const String prefsKey = 'trainer_shortcuts_v1';

  Map<TrainerShortcutId, TrainerShortcutBinding> _bindings = defaultBindings();

  Map<TrainerShortcutId, TrainerShortcutBinding> get bindings =>
      Map<TrainerShortcutId, TrainerShortcutBinding>.unmodifiable(_bindings);

  Future<void> ensureLoaded() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      final merged = Map<TrainerShortcutId, TrainerShortcutBinding>.from(defaultBindings());
      for (final id in TrainerShortcutId.values) {
        final entry = decoded[id.name];
        if (entry is Map) {
          final binding = TrainerShortcutBinding.fromJson(
            Map<String, dynamic>.from(entry),
          );
          if (binding != null && !isReserved(binding)) {
            merged[id] = binding;
          }
        }
      }
      _bindings = merged;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setBinding(TrainerShortcutId id, TrainerShortcutBinding binding) async {
    if (isReserved(binding)) {
      throw ReservedShortcutException(id);
    }
    for (final entry in _bindings.entries) {
      if (entry.key != id && _activatorsEqual(entry.value, binding)) {
        throw DuplicateShortcutException(entry.key);
      }
    }
    _bindings = Map<TrainerShortcutId, TrainerShortcutBinding>.from(_bindings)
      ..[id] = binding;
    notifyListeners();
    await _persist();
  }

  Future<void> resetToDefaults() async {
    _bindings = defaultBindings();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonMap = <String, dynamic>{
      for (final e in _bindings.entries) e.key.name: e.value.toJson(),
    };
    await prefs.setString(prefsKey, jsonEncode(jsonMap));
  }

  static Map<TrainerShortcutId, TrainerShortcutBinding> defaultBindings() {
    TrainerShortcutBinding b(
      LogicalKeyboardKey key, {
      bool control = false,
      bool shift = false,
      bool alt = false,
      bool meta = false,
    }) {
      return TrainerShortcutBinding(
        triggerKeyId: key.keyId,
        control: control,
        shift: shift,
        alt: alt,
        meta: meta,
      );
    }

    return <TrainerShortcutId, TrainerShortcutBinding>{
      TrainerShortcutId.startTraining: b(LogicalKeyboardKey.space),
      TrainerShortcutId.nextChunk: b(LogicalKeyboardKey.arrowRight),
      TrainerShortcutId.prevChunk: b(LogicalKeyboardKey.arrowLeft),
      TrainerShortcutId.firstChunk: b(LogicalKeyboardKey.home),
      TrainerShortcutId.recallNow: b(LogicalKeyboardKey.enter),
      TrainerShortcutId.scrollDown: b(LogicalKeyboardKey.arrowDown),
      TrainerShortcutId.scrollUp: b(LogicalKeyboardKey.arrowUp),
      TrainerShortcutId.toggleLociMap: b(LogicalKeyboardKey.keyM),
      TrainerShortcutId.saveCheckpoint: b(LogicalKeyboardKey.keyS, control: true),
    };
  }

  /// Browser / OS shortcuts that must not be rebound.
  static bool isReserved(TrainerShortcutBinding binding) {
    final key = binding.triggerKey;
    if (key == null) return true;

    if (binding.control) {
      final blockedCtrl = <LogicalKeyboardKey>{
        LogicalKeyboardKey.keyR,
        LogicalKeyboardKey.keyW,
        LogicalKeyboardKey.keyT,
        LogicalKeyboardKey.keyN,
        LogicalKeyboardKey.keyP,
        LogicalKeyboardKey.keyF,
        LogicalKeyboardKey.keyL,
        LogicalKeyboardKey.equal,
        LogicalKeyboardKey.minus,
        LogicalKeyboardKey.digit0,
      };
      if (blockedCtrl.contains(key)) return true;
    }

    if (binding.meta) {
      return true;
    }

    final blockedSingleton = <LogicalKeyboardKey>{
      LogicalKeyboardKey.f1,
      LogicalKeyboardKey.f2,
      LogicalKeyboardKey.f3,
      LogicalKeyboardKey.f4,
      LogicalKeyboardKey.f5,
      LogicalKeyboardKey.f6,
      LogicalKeyboardKey.f7,
      LogicalKeyboardKey.f8,
      LogicalKeyboardKey.f9,
      LogicalKeyboardKey.f10,
      LogicalKeyboardKey.f11,
      LogicalKeyboardKey.f12,
      LogicalKeyboardKey.browserRefresh,
      LogicalKeyboardKey.browserBack,
      LogicalKeyboardKey.browserForward,
      LogicalKeyboardKey.tab,
    };
    if (!binding.control && !binding.alt && !binding.shift && blockedSingleton.contains(key)) {
      return true;
    }

    return false;
  }

  static bool _activatorsEqual(
    TrainerShortcutBinding a,
    TrainerShortcutBinding b,
  ) {
    return a.triggerKeyId == b.triggerKeyId &&
        a.control == b.control &&
        a.shift == b.shift &&
        a.alt == b.alt &&
        a.meta == b.meta;
  }

  Map<ShortcutActivator, Intent> shortcutMapForPhase(TrainerShortcutPhase phase) {
    final out = <ShortcutActivator, Intent>{};
    final ids = TrainerShortcutIdLabels.forPhase(phase);
    for (final id in ids) {
      final binding = _bindings[id];
      if (binding == null) continue;
      final activator = binding.toActivator();
      out[activator] = intentForId(id);

      // Legacy aliases from the original trainer (page keys, numpad enter, space on memorize).
      if (id == TrainerShortcutId.nextChunk) {
        out[const SingleActivator(LogicalKeyboardKey.pageDown)] = intentForId(id);
        out[const SingleActivator(LogicalKeyboardKey.space)] = intentForId(id);
      }
      if (id == TrainerShortcutId.prevChunk) {
        out[const SingleActivator(LogicalKeyboardKey.pageUp)] = intentForId(id);
      }
      if (id == TrainerShortcutId.recallNow) {
        out[const SingleActivator(LogicalKeyboardKey.numpadEnter)] = intentForId(id);
      }
      if (id == TrainerShortcutId.startTraining) {
        out[const SingleActivator(LogicalKeyboardKey.enter)] = intentForId(id);
      }
    }
    return out;
  }

  String hintLineForPhase(TrainerShortcutPhase phase, String lang) {
    String label(TrainerShortcutId id) => id.label(lang);
    String key(TrainerShortcutId id) =>
        _bindings[id]?.displayLabel() ?? '';

    if (phase == TrainerShortcutPhase.setup) {
      return '${key(TrainerShortcutId.startTraining)} — ${label(TrainerShortcutId.startTraining)}';
    }
    if (phase == TrainerShortcutPhase.memorize) {
      final next = label(TrainerShortcutId.nextChunk);
      final prev = label(TrainerShortcutId.prevChunk);
      final recall = label(TrainerShortcutId.recallNow);
      return switch (lang) {
        'en' =>
          '${key(TrainerShortcutId.nextChunk)} — $next · ${key(TrainerShortcutId.prevChunk)} — $prev · ${key(TrainerShortcutId.recallNow)} — $recall',
        'de' =>
          '${key(TrainerShortcutId.nextChunk)} — $next · ${key(TrainerShortcutId.prevChunk)} — $prev · ${key(TrainerShortcutId.recallNow)} — $recall',
        _ =>
          '${key(TrainerShortcutId.nextChunk)} — $next · ${key(TrainerShortcutId.prevChunk)} — $prev · ${key(TrainerShortcutId.recallNow)} — $recall',
      };
    }
    return '';
  }
}

class ReservedShortcutException implements Exception {
  ReservedShortcutException(this.id);
  final TrainerShortcutId id;
}

class DuplicateShortcutException implements Exception {
  DuplicateShortcutException(this.existingId);
  final TrainerShortcutId existingId;
}
