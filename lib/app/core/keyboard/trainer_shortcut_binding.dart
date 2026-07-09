import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'trainer_shortcut_id.dart';

/// Serializable keyboard binding (one trigger key + optional modifiers).
class TrainerShortcutBinding {
  const TrainerShortcutBinding({
    required this.triggerKeyId,
    this.control = false,
    this.shift = false,
    this.alt = false,
    this.meta = false,
  });

  final int triggerKeyId;
  final bool control;
  final bool shift;
  final bool alt;
  final bool meta;

  LogicalKeyboardKey? get triggerKey {
    try {
      return LogicalKeyboardKey(triggerKeyId);
    } catch (_) {
      return null;
    }
  }

  SingleActivator toActivator() {
    final key = triggerKey;
    if (key == null) {
      return const SingleActivator(LogicalKeyboardKey.unidentified);
    }
    return SingleActivator(
      key,
      control: control,
      shift: shift,
      alt: alt,
      meta: meta,
    );
  }

  String displayLabel() {
    final key = triggerKey;
    if (key == null) return '?';
    final parts = <String>[];
    if (control) parts.add('Ctrl');
    if (shift) parts.add('Shift');
    if (alt) parts.add('Alt');
    if (meta) parts.add('Meta');
    parts.add(_friendlyKeyName(key));
    return parts.join(' + ');
  }

  static String _friendlyKeyName(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.space) return 'Space';
    if (key == LogicalKeyboardKey.enter) return 'Enter';
    if (key == LogicalKeyboardKey.numpadEnter) return 'Numpad Enter';
    if (key == LogicalKeyboardKey.arrowLeft) return '←';
    if (key == LogicalKeyboardKey.arrowRight) return '→';
    if (key == LogicalKeyboardKey.arrowUp) return '↑';
    if (key == LogicalKeyboardKey.arrowDown) return '↓';
    if (key == LogicalKeyboardKey.pageUp) return 'Page Up';
    if (key == LogicalKeyboardKey.pageDown) return 'Page Down';
    if (key == LogicalKeyboardKey.home) return 'Home';
    if (key == LogicalKeyboardKey.escape) return 'Esc';
    final name = key.keyLabel;
    if (name.isNotEmpty && name.length <= 3) return name.toUpperCase();
    return key.debugName ?? 'Key';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'triggerKeyId': triggerKeyId,
        'control': control,
        'shift': shift,
        'alt': alt,
        'meta': meta,
      };

  static TrainerShortcutBinding? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final id = json['triggerKeyId'];
    if (id is! num) return null;
    return TrainerShortcutBinding(
      triggerKeyId: id.toInt(),
      control: json['control'] == true,
      shift: json['shift'] == true,
      alt: json['alt'] == true,
      meta: json['meta'] == true,
    );
  }

  static TrainerShortcutBinding fromKeyDown({
    required LogicalKeyboardKey trigger,
    required Set<LogicalKeyboardKey> pressed,
  }) {
    return TrainerShortcutBinding(
      triggerKeyId: trigger.keyId,
      control: pressed.contains(LogicalKeyboardKey.controlLeft) ||
          pressed.contains(LogicalKeyboardKey.controlRight) ||
          pressed.contains(LogicalKeyboardKey.control),
      shift: pressed.contains(LogicalKeyboardKey.shiftLeft) ||
          pressed.contains(LogicalKeyboardKey.shiftRight) ||
          pressed.contains(LogicalKeyboardKey.shift),
      alt: pressed.contains(LogicalKeyboardKey.altLeft) ||
          pressed.contains(LogicalKeyboardKey.altRight) ||
          pressed.contains(LogicalKeyboardKey.alt),
      meta: pressed.contains(LogicalKeyboardKey.metaLeft) ||
          pressed.contains(LogicalKeyboardKey.metaRight) ||
          pressed.contains(LogicalKeyboardKey.meta),
    );
  }
}
