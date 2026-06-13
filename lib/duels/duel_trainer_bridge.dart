import 'dart:async';
import 'dart:math';



import 'package:flutter/material.dart';

import 'package:flutter/services.dart';



import '../cloud/cloud_sync_service.dart';

import '../app/core/ui_feedback.dart';
import '../recovered_app.dart' show TrainingMode, appLanguage, AppLanguage;

import 'duel_avatar.dart';
import 'duel_service.dart';



/// Solo practice vs multiplayer duel on top of the same trainer UI.

enum TrainerMode { solo, duel }



enum DuelTrainerPhase { loading, countdown, memorize, recall, submitted, finished }



/// Maps a [DuelTask] discipline to [TrainingScreen] mode flags.

class DuelTrainerPreset {

  final TrainingMode mode;

  final bool matrixMode;

  final int standardDigits;

  final DuelDiscipline discipline;



  const DuelTrainerPreset({

    required this.mode,

    required this.matrixMode,

    required this.standardDigits,

    required this.discipline,

  });

}



DuelTrainerPreset duelPresetFromDiscipline(DuelDiscipline discipline) {

  switch (discipline) {

    case DuelDiscipline.numbersMatrix:

      return DuelTrainerPreset(

        mode: TrainingMode.standard,

        matrixMode: true,

        standardDigits: 1,

        discipline: discipline,

      );

    case DuelDiscipline.numbersPairs:

      return DuelTrainerPreset(

        mode: TrainingMode.standard,

        matrixMode: false,

        standardDigits: 2,

        discipline: discipline,

      );

    case DuelDiscipline.numbersTriples:

      return DuelTrainerPreset(

        mode: TrainingMode.standard,

        matrixMode: false,

        standardDigits: 3,

        discipline: discipline,

      );

    case DuelDiscipline.binaryBits:

      return DuelTrainerPreset(

        mode: TrainingMode.binary,

        matrixMode: false,

        standardDigits: 1,

        discipline: discipline,

      );

    case DuelDiscipline.binaryTriplets:

      return DuelTrainerPreset(

        mode: TrainingMode.binary,

        matrixMode: false,

        standardDigits: 1,

        discipline: discipline,

      );

    case DuelDiscipline.words:

      return DuelTrainerPreset(

        mode: TrainingMode.words,

        matrixMode: false,

        standardDigits: 1,

        discipline: discipline,

      );

    case DuelDiscipline.cards:

      return DuelTrainerPreset(

        mode: TrainingMode.cards,

        matrixMode: false,

        standardDigits: 1,

        discipline: discipline,

      );

    case DuelDiscipline.images:

      return DuelTrainerPreset(

        mode: TrainingMode.images,

        matrixMode: false,

        standardDigits: 1,

        discipline: discipline,

      );

    case DuelDiscipline.faces:

      return DuelTrainerPreset(

        mode: TrainingMode.faces,

        matrixMode: false,

        standardDigits: 1,

        discipline: discipline,

      );

  }

}



/// Server-synced duel session on top of [TrainingScreen].

class DuelTrainerController {

  DuelTrainerController({

    required this.roomId,

    required this.onRoomUpdate,

    required this.onPhaseChanged,

    required this.onForceRecall,

    required this.onRecallExpired,

    required this.onNavigateToResults,

    required this.onRoomClosed,

  });



  final String roomId;

  final void Function(DuelRoom? room) onRoomUpdate;

  final void Function(DuelTrainerPhase phase) onPhaseChanged;

  final VoidCallback onForceRecall;

  final VoidCallback onRecallExpired;

  final VoidCallback onNavigateToResults;

  final VoidCallback onRoomClosed;



  StreamSubscription<DuelRoom?>? _sub;

  Timer? _ticker;

  DuelRoom? room;

  DuelTrainerPhase phase = DuelTrainerPhase.loading;

  int countdownLeft = 3;

  int memorizeLeftMs = 0;

  int recallLeftMs = 0;

  bool sessionStarted = false;

  bool navigatedToResults = false;

  bool _recallExpiredFired = false;



  void start() {

    unawaited(DuelService.instance.refreshMyPlayerInRoom(roomId));

    _sub = DuelService.instance.watchRoom(roomId).listen(_onRoom);

  }



  void dispose() {

    _sub?.cancel();

    _ticker?.cancel();

  }



  Future<void> _onRoom(DuelRoom? next) async {

    room = next;

    onRoomUpdate(next);

    if (next == null) {

      onRoomClosed();

      return;

    }

    if (next.status == DuelStatus.finished) {

      _setPhase(DuelTrainerPhase.finished);

      if (!navigatedToResults) {

        navigatedToResults = true;

        onNavigateToResults();

      }

      return;

    }

    if (_ticker == null && next.task != null && next.startAtMs != null) {

      _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) => _onTick());

      _onTick();

    }

  }



  void _onTick() {

    final r = room;

    if (r == null || r.task == null || r.startAtMs == null) return;

    onRoomUpdate(r);

    final now = DateTime.now().millisecondsSinceEpoch;

    final startAt = r.startAtMs!;

    final task = r.task!;

    final hasTimer = task.memorizeSeconds > 0;

    final memorizeEnd = hasTimer ? startAt + task.memorizeSeconds * 1000 : startAt;

    final recallCapMs = duelRecallCapMsForTask(task);

    final recallEnd = memorizeEnd + recallCapMs;



    if (now < startAt) {

      final secondsLeft = ((startAt - now) / 1000).ceil().clamp(1, 9);

      countdownLeft = secondsLeft;

      _setPhase(DuelTrainerPhase.countdown);

      return;

    }



    if (!sessionStarted) {

      sessionStarted = true;

      appHaptic(UiClickSound.soft);

    }



    if (!hasTimer) {

      if (phase != DuelTrainerPhase.recall &&

          phase != DuelTrainerPhase.submitted &&

          phase != DuelTrainerPhase.memorize) {

        memorizeLeftMs = 0;

        _setPhase(DuelTrainerPhase.memorize);

      } else if (phase == DuelTrainerPhase.countdown) {

        memorizeLeftMs = 0;

        _setPhase(DuelTrainerPhase.memorize);

      }

      return;

    }



    if (now < memorizeEnd) {

      memorizeLeftMs = memorizeEnd - now;

      if (phase != DuelTrainerPhase.memorize) {

        appHaptic(UiClickSound.soft);

      }

      _setPhase(DuelTrainerPhase.memorize);

      return;

    }



    if (phase != DuelTrainerPhase.recall &&

        phase != DuelTrainerPhase.submitted) {

      _recallExpiredFired = false;

      _setPhase(DuelTrainerPhase.recall);

      onForceRecall();

      appHaptic(UiClickSound.bright);

    }



    if (phase == DuelTrainerPhase.recall || phase == DuelTrainerPhase.submitted) {

      recallLeftMs = max(0, recallEnd - now);

      if (now >= recallEnd && phase == DuelTrainerPhase.recall && !_recallExpiredFired) {

        _recallExpiredFired = true;

        onRecallExpired();

      }

    } else {

      recallLeftMs = 0;

    }

  }



  void markSubmitted() {

    _setPhase(DuelTrainerPhase.submitted);

  }



  void _setPhase(DuelTrainerPhase next) {

    if (phase == next) return;

    phase = next;

    onPhaseChanged(next);

  }



  DuelPlayer? opponentPlayer() {

    final r = room;

    final me = CloudSyncService.instance.user.value?.uid;

    if (r == null || me == null) return null;

    for (final p in r.players) {

      if (p.uid != me) return p;

    }

    return null;

  }



  DuelPlayer? mePlayer() {

    final r = room;

    final me = CloudSyncService.instance.user.value?.uid;

    if (r == null || me == null) return null;

    for (final p in r.players) {

      if (p.uid == me) return p;

    }

    return null;

  }



  bool opponentSubmitted() {

    final r = room;

    final other = opponentPlayer();

    if (r == null || other == null) return false;

    return r.results.containsKey(other.uid);

  }



  bool meSubmitted() {

    final r = room;

    final me = CloudSyncService.instance.user.value?.uid;

    if (r == null || me == null) return false;

    return r.results.containsKey(me);

  }



  DuelPlayerPhase? opponentLivePhase() {

    final r = room;

    final other = opponentPlayer();

    if (r == null || other == null) return null;

    return r.phaseFor(other.uid);

  }



  DuelPlayerPhase? meLivePhase() {

    final r = room;

    final me = CloudSyncService.instance.user.value?.uid;

    if (r == null || me == null) return null;

    return r.phaseFor(me);

  }

}



/// Live opponent status bar (Memory League style) above the standard trainer.

class DuelTrainerOverlayBar extends StatelessWidget {

  final DuelRoom? room;

  final DuelTrainerController? controller;

  final Color accent;

  final Color onSurface;

  /// Countdown during recall (e.g. `04:32`), shown under the VS row.
  final String? recallCountdownLabel;



  const DuelTrainerOverlayBar({

    super.key,

    required this.room,

    required this.controller,

    required this.accent,

    required this.onSurface,

    this.recallCountdownLabel,

  });



  @override

  Widget build(BuildContext context) {

    final r = room;

    if (r == null) return const SizedBox.shrink();

    final meUid = CloudSyncService.instance.user.value?.uid;

    final me = controller?.mePlayer();

    final other = controller?.opponentPlayer();

    final oppPhase = controller?.opponentLivePhase();

    final mePhase = controller?.meLivePhase();

    final oppResult = other != null ? r.results[other.uid] : null;

    final meResult = meUid != null ? r.results[meUid] : null;



    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),

      decoration: BoxDecoration(

        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.94),

        border: Border(

          bottom: BorderSide(color: onSurface.withOpacity(0.08)),

        ),

        boxShadow: [

          BoxShadow(

            color: accent.withOpacity(0.06),

            blurRadius: 12,

            offset: const Offset(0, 4),

          ),

        ],

      ),

      child: Column(

        mainAxisSize: MainAxisSize.min,

        children: [

          Row(

            children: [

              Expanded(

                child: _DuelPlayerStatusChip(

                  player: me,

                  phase: mePhase,

                  result: meResult,

                  accent: accent,

                  onSurface: onSurface,

                  alignEnd: false,

                ),

              ),

              Padding(

                padding: const EdgeInsets.symmetric(horizontal: 6),

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    Text(

                      'VS',

                      style: TextStyle(

                        color: accent,

                        fontSize: 11,

                        fontWeight: FontWeight.w800,

                        letterSpacing: 3,

                      ),

                    ),

                    const SizedBox(height: 4),

                    _OpponentStatusLine(

                      phase: oppPhase,

                      result: oppResult,

                      accent: accent,

                      onSurface: onSurface,

                    ),

                  ],

                ),

              ),

              Expanded(

                child: _DuelPlayerStatusChip(

                  player: other,

                  phase: oppPhase,

                  result: oppResult,

                  accent: accent,

                  onSurface: onSurface,

                  alignEnd: true,

                  dim: other == null,

                ),

              ),

            ],

          ),

          if (recallCountdownLabel != null) ...[

            const SizedBox(height: 8),

            Text(

              recallCountdownLabel!,

              style: TextStyle(

                color: accent.withOpacity(0.85),

                fontSize: 16,

                fontWeight: FontWeight.w500,

                letterSpacing: 3,

                fontFeatures: const [FontFeature.tabularFigures()],

              ),

            ),

          ],

        ],

      ),

    );

  }

}



class _OpponentStatusLine extends StatelessWidget {

  final DuelPlayerPhase? phase;

  final DuelResult? result;

  final Color accent;

  final Color onSurface;



  const _OpponentStatusLine({

    required this.phase,

    required this.result,

    required this.accent,

    required this.onSurface,

  });



  @override

  Widget build(BuildContext context) {

    if (result != null) {

      final pct = (result!.accuracy * 100).round();

      return Text(

        _duelOverlayText(

          ru: 'Готово · $pct%',

          en: 'Done · $pct%',

          de: 'Fertig · $pct%',

        ),

        style: TextStyle(

          color: accent.withOpacity(0.85),

          fontSize: 10,

          fontWeight: FontWeight.w600,

          letterSpacing: 0.3,

        ),

      );

    }

    return Text(

      _phaseLabel(phase),

      style: TextStyle(

        color: onSurface.withOpacity(0.5),

        fontSize: 10,

        letterSpacing: 0.3,

      ),

    );

  }



  String _phaseLabel(DuelPlayerPhase? p) {

    switch (p) {

      case DuelPlayerPhase.memorizing:

        return _duelOverlayText(

          ru: 'Запоминает…',

          en: 'Memorizing…',

          de: 'Merkt…',

        );

      case DuelPlayerPhase.recalling:

        return _duelOverlayText(

          ru: 'Восстанавливает…',

          en: 'Recalling…',

          de: 'Erinnert…',

        );

      case DuelPlayerPhase.countdown:

        return _duelOverlayText(

          ru: 'Готовится…',

          en: 'Get ready…',

          de: 'Bereit…',

        );

      case DuelPlayerPhase.finished:

        return _duelOverlayText(

          ru: 'Отправил',

          en: 'Submitted',

          de: 'Gesendet',

        );

      case DuelPlayerPhase.disconnected:

        return _duelOverlayText(

          ru: 'Отключился',

          en: 'Disconnected',

          de: 'Getrennt',

        );

      default:

        return _duelOverlayText(

          ru: 'В игре',

          en: 'In match',

          de: 'Im Spiel',

        );

    }

  }



  String _duelOverlayText({required String ru, required String en, required String de}) {

    switch (appLanguage.value) {

      case AppLanguage.ru:

        return ru;

      case AppLanguage.de:

        return de;

      case AppLanguage.en:

        return en;

    }

  }

}



class _DuelPlayerStatusChip extends StatelessWidget {

  final DuelPlayer? player;

  final DuelPlayerPhase? phase;

  final DuelResult? result;

  final Color accent;

  final Color onSurface;

  final bool alignEnd;

  final bool dim;



  const _DuelPlayerStatusChip({

    required this.player,

    required this.phase,

    required this.result,

    required this.accent,

    required this.onSurface,

    this.alignEnd = false,

    this.dim = false,

  });



  @override

  Widget build(BuildContext context) {

    final name = player?.name ?? '—';

    final done = result != null || phase == DuelPlayerPhase.finished;

    final phaseLabel = _shortPhaseLabel(phase, done);



    return Column(

      crossAxisAlignment:

          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,

      mainAxisSize: MainAxisSize.min,

      children: [

        Row(

          mainAxisSize: MainAxisSize.min,

          mainAxisAlignment:

              alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,

          children: [

            if (alignEnd) ...[

              _phasePill(phaseLabel, done),

              const SizedBox(width: 6),

            ],

            Stack(

              clipBehavior: Clip.none,

              children: [

                DuelAvatar(

                  photoUrl: player?.photoUrl,

                  photoData: player?.photoData,

                  name: name,

                  accent: accent,

                  border: onSurface.withOpacity(0.2),

                  size: 38,

                  dim: dim,

                ),

                if (done)

                  Positioned(

                    right: -2,

                    bottom: -2,

                    child: Icon(Icons.check_circle_rounded, size: 15, color: accent),

                  ),

              ],

            ),

            if (!alignEnd) ...[

              const SizedBox(width: 6),

              _phasePill(phaseLabel, done),

            ],

          ],

        ),

        const SizedBox(height: 4),

        Text(

          name,

          maxLines: 1,

          overflow: TextOverflow.ellipsis,

          textAlign: alignEnd ? TextAlign.end : TextAlign.start,

          style: TextStyle(fontSize: 10, color: onSurface.withOpacity(0.82)),

        ),

      ],

    );

  }



  Widget _phasePill(String label, bool done) {

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),

      decoration: BoxDecoration(

        color: done ? accent.withOpacity(0.14) : onSurface.withOpacity(0.05),

        borderRadius: BorderRadius.circular(8),

        border: Border.all(

          color: done ? accent.withOpacity(0.35) : onSurface.withOpacity(0.1),

        ),

      ),

      child: Text(

        label,

        style: TextStyle(

          color: done ? accent : onSurface.withOpacity(0.55),

          fontSize: 8,

          fontWeight: FontWeight.w700,

          letterSpacing: 0.6,

        ),

      ),

    );

  }



  String _shortPhaseLabel(DuelPlayerPhase? p, bool done) {

    if (done) {

      return _t(ru: 'ГОТОВ', en: 'DONE', de: 'FERTIG');

    }

    switch (p) {

      case DuelPlayerPhase.memorizing:

        return _t(ru: 'МЕМ', en: 'MEM', de: 'MERK');

      case DuelPlayerPhase.recalling:

        return _t(ru: 'ВВОД', en: 'REC', de: 'ABR');

      case DuelPlayerPhase.countdown:

        return _t(ru: 'СТАРТ', en: 'GO', de: 'LOS');

      default:

        return _t(ru: '…', en: '…', de: '…');

    }

  }



  String _t({required String ru, required String en, required String de}) {

    switch (appLanguage.value) {

      case AppLanguage.ru:

        return ru;

      case AppLanguage.de:

        return de;

      case AppLanguage.en:

        return en;

    }

  }

}



String _duelOverlayText({required String ru, required String en, required String de}) {

  switch (appLanguage.value) {

    case AppLanguage.ru:

      return ru;

    case AppLanguage.de:

      return de;

    case AppLanguage.en:

      return en;

  }

}


