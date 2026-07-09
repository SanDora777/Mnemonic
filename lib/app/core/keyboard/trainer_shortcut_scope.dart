import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'trainer_shortcut_id.dart';
import 'trainer_shortcut_intents.dart';
import 'web_keyboard_manager.dart';

/// Callbacks invoked when a trainer shortcut fires.
class TrainerShortcutCallbacks {
  const TrainerShortcutCallbacks({
    this.onStartTraining,
    this.onNextChunk,
    this.onPrevChunk,
    this.onFirstChunk,
    this.onRecallNow,
    this.onScrollDown,
    this.onScrollUp,
    this.onToggleLociMap,
    this.onSaveCheckpoint,
    this.scrollController,
    this.enabled = true,
  });

  final VoidCallback? onStartTraining;
  final VoidCallback? onNextChunk;
  final VoidCallback? onPrevChunk;
  final VoidCallback? onFirstChunk;
  final VoidCallback? onRecallNow;
  final VoidCallback? onScrollDown;
  final VoidCallback? onScrollUp;
  final VoidCallback? onToggleLociMap;
  final VoidCallback? onSaveCheckpoint;
  final ScrollController? scrollController;
  final bool enabled;

  void handle(TrainerShortcutId id) {
    if (!enabled) return;
    switch (id) {
      case TrainerShortcutId.startTraining:
        onStartTraining?.call();
      case TrainerShortcutId.nextChunk:
        onNextChunk?.call();
      case TrainerShortcutId.prevChunk:
        onPrevChunk?.call();
      case TrainerShortcutId.firstChunk:
        onFirstChunk?.call();
      case TrainerShortcutId.recallNow:
        onRecallNow?.call();
      case TrainerShortcutId.scrollDown:
        _scrollBy(72);
        onScrollDown?.call();
      case TrainerShortcutId.scrollUp:
        _scrollBy(-72);
        onScrollUp?.call();
      case TrainerShortcutId.toggleLociMap:
        onToggleLociMap?.call();
      case TrainerShortcutId.saveCheckpoint:
        onSaveCheckpoint?.call();
    }
  }

  void _scrollBy(double delta) {
    final sc = scrollController;
    if (sc == null || !sc.hasClients) return;
    final target = (sc.offset + delta).clamp(0.0, sc.position.maxScrollExtent);
    sc.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }
}

bool trainerShortcutBlockedByTextField() {
  final focus = FocusManager.instance.primaryFocus;
  final ctx = focus?.context;
  if (ctx == null) return false;
  return ctx.findAncestorWidgetOfExactType<EditableText>() != null;
}

/// Wraps trainer UI with [Shortcuts] + [Actions] + [FocusableActionDetector].
class TrainerShortcutScope extends StatelessWidget {
  const TrainerShortcutScope({
    super.key,
    required this.phase,
    required this.callbacks,
    required this.child,
    this.autofocus = true,
  });

  final TrainerShortcutPhase phase;
  final TrainerShortcutCallbacks callbacks;
  final Widget child;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WebKeyboardManager.instance,
      builder: (context, _) {
        final shortcuts = WebKeyboardManager.instance.shortcutMapForPhase(phase);
        return Shortcuts(
          shortcuts: shortcuts,
          child: Actions(
            actions: _buildActions(callbacks),
            child: FocusableActionDetector(
              autofocus: autofocus && callbacks.enabled,
              child: child,
            ),
          ),
        );
      },
    );
  }

  Map<Type, Action<Intent>> _buildActions(TrainerShortcutCallbacks cb) {
    Action<TrainerShortcutIntent> action(void Function() invoke) {
      return CallbackAction<TrainerShortcutIntent>(
        onInvoke: (_) {
          if (trainerShortcutBlockedByTextField()) return null;
          invoke();
          return null;
        },
      );
    }

    return <Type, Action<Intent>>{
      StartTrainingIntent: action(() => cb.handle(TrainerShortcutId.startTraining)),
      NextChunkIntent: action(() => cb.handle(TrainerShortcutId.nextChunk)),
      PrevChunkIntent: action(() => cb.handle(TrainerShortcutId.prevChunk)),
      FirstChunkIntent: action(() => cb.handle(TrainerShortcutId.firstChunk)),
      RecallNowIntent: action(() => cb.handle(TrainerShortcutId.recallNow)),
      ScrollDownIntent: action(() => cb.handle(TrainerShortcutId.scrollDown)),
      ScrollUpIntent: action(() => cb.handle(TrainerShortcutId.scrollUp)),
      ToggleLociMapIntent: action(() => cb.handle(TrainerShortcutId.toggleLociMap)),
      SaveCheckpointIntent: action(() => cb.handle(TrainerShortcutId.saveCheckpoint)),
    };
  }
}
