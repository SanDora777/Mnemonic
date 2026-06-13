import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/core/ui_feedback.dart';
import '../cloud/cloud_sync_service.dart';
import '../recovered_app.dart'
    show
        appPalette,
        appAccentColor,
        appLanguage,
        AppLanguage,
        AppPalette,
        TrainingScreen;
import '../trainer/trainer_lobby_settings.dart';
import 'duel_trainer_bridge.dart' show TrainerMode;
import 'duel_answer_review.dart';
import 'duel_auth_sheet.dart';
import 'duel_avatar.dart';
import 'duel_chat.dart';
import 'duel_disciplines.dart';
import 'duel_rating_service.dart';
import 'duel_invite_accept.dart';
import 'duel_service.dart';

const int _kDuelCountdownMs = 3500;

String _t(Map<AppLanguage, String> map) =>
    map[appLanguage.value] ?? map[AppLanguage.ru] ?? '';

PageRoute<T> _fadeRoute<T>(Widget child) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, anim, _) => child,
    transitionsBuilder: (context, anim, _, c) => FadeTransition(opacity: anim, child: c),
    transitionDuration: const Duration(milliseconds: 320),
  );
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: appPalette.value.surface,
      content: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: appPalette.value.border.withOpacity(0.5)),
      ),
    ),
  );
}

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _PressableScale({required this.child, required this.onTap});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _scale = 0.96),
      onTapCancel: () => setState(() => _scale = 1),
      onTapUp: (_) => setState(() => _scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

// =====================================================================
// LOBBY SCREEN
// =====================================================================

class DuelLobbyScreen extends StatefulWidget {
  const DuelLobbyScreen({super.key});

  @override
  State<DuelLobbyScreen> createState() => _DuelLobbyScreenState();
}

class _DuelLobbyScreenState extends State<DuelLobbyScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  bool _busy = false;
  bool _entered = false;
  late AnimationController _heroController;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _entered = true);
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _heroController.dispose();
    super.dispose();
  }

  Future<bool> _ensureAuthed() async {
    if (CloudSyncService.instance.isSignedIn) return true;
    return await showDuelAuthSheet(context);
  }

  Future<void> _createRoom() async {
    if (_busy) return;
    if (!await _ensureAuthed()) return;
    uiTapClick(UiClickSound.soft);
    setState(() => _busy = true);
    try {
      final room = await DuelService.instance.createRoom();
      if (!mounted) return;
      await Navigator.of(context).push(
        _fadeRoute(DuelWaitingScreen(roomId: room.roomId)),
      );
    } catch (_) {
      if (!mounted) return;
      _showSnack(
        context,
        _t(const {
          AppLanguage.ru: 'Не удалось создать комнату',
          AppLanguage.en: 'Could not create room',
          AppLanguage.de: 'Raum konnte nicht erstellt werden',
        }),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _joinRoom() async {
    if (_busy) return;
    if (!await _ensureAuthed()) return;
    final code = _codeController.text.trim();
    if (code.length < 4) {
      _showSnack(
        context,
        _t(const {
          AppLanguage.ru: 'Введи код комнаты',
          AppLanguage.en: 'Enter a room code',
          AppLanguage.de: 'Raumcode eingeben',
        }),
      );
      return;
    }
    uiTapClick(UiClickSound.soft);
    setState(() => _busy = true);
    try {
      final room = await DuelService.instance.joinRoom(code);
      if (!mounted) return;
      await Navigator.of(context).push(
        _fadeRoute(DuelWaitingScreen(roomId: room.roomId)),
      );
    } catch (e) {
      if (!mounted) return;
      final code = e is StateError ? e.message : null;
      _showSnack(
        context,
        code != null ? _mapJoinError(code) : mapDuelJoinError(e),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _mapJoinError(String code) {
    if (code == 'empty_code') {
      return _t(const {
        AppLanguage.ru: 'Введи код комнаты',
        AppLanguage.en: 'Enter a room code',
        AppLanguage.de: 'Raumcode eingeben',
      });
    }
    return mapDuelJoinError(StateError(code));
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: palette.background,
        foregroundColor: onSurface,
        title: Text(
          _t(const {
            AppLanguage.ru: 'Дуэли',
            AppLanguage.en: 'Duels',
            AppLanguage.de: 'Duelle',
          }),
          style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4),
        ),
      ),
      body: AnimatedOpacity(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        opacity: _entered ? 1 : 0,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
          offset: _entered ? Offset.zero : const Offset(0, 0.03),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(palette, accent, onSurface),
                const SizedBox(height: 28),
                _buildPrimaryAction(
                  label: _t(const {
                    AppLanguage.ru: 'Создать комнату',
                    AppLanguage.en: 'Create room',
                    AppLanguage.de: 'Raum erstellen',
                  }),
                  icon: Icons.add_circle_outline_rounded,
                  accent: accent,
                  onTap: _busy ? null : _createRoom,
                ),
                const SizedBox(height: 26),
                _buildDivider(onSurface),
                const SizedBox(height: 22),
                Text(
                  _t(const {
                    AppLanguage.ru: 'У ТЕБЯ ЕСТЬ КОД?',
                    AppLanguage.en: 'HAVE A CODE?',
                    AppLanguage.de: 'EINEN CODE?',
                  }),
                  style: TextStyle(
                    color: onSurface.withOpacity(0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                _buildCodeField(palette, onSurface, accent),
                const SizedBox(height: 12),
                _buildSecondaryAction(
                  label: _t(const {
                    AppLanguage.ru: 'Присоединиться',
                    AppLanguage.en: 'Join room',
                    AppLanguage.de: 'Beitreten',
                  }),
                  accent: accent,
                  surface: palette.surface,
                  onTap: _busy ? null : _joinRoom,
                ),
                const SizedBox(height: 28),
                _buildHowItWorks(palette, onSurface, accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(AppPalette palette, Color accent, Color onSurface) {
    return AnimatedBuilder(
      animation: _heroController,
      builder: (context, _) {
        final t = _heroController.value;
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withOpacity(0.10 + 0.04 * t),
                accent.withOpacity(0.02),
              ],
            ),
            border: Border.all(color: accent.withOpacity(0.25 + 0.10 * t)),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(0.16),
                  border: Border.all(color: accent.withOpacity(0.45)),
                ),
                child: Icon(Icons.flash_on_rounded, color: accent, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t(const {
                        AppLanguage.ru: 'Дуэль 1 на 1',
                        AppLanguage.en: '1-on-1 duel',
                        AppLanguage.de: '1-gegen-1 Duell',
                      }),
                      style: TextStyle(
                        color: onSurface.withOpacity(0.95),
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrimaryAction({
    required String label,
    required IconData icon,
    required Color accent,
    required VoidCallback? onTap,
  }) {
    final disabled = onTap == null;
    return _PressableScale(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.55 : 1,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(colors: [accent.withOpacity(0.96), accent]),
            boxShadow: [
              BoxShadow(color: accent.withOpacity(0.32), blurRadius: 20, spreadRadius: 1),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.65),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 14),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: Colors.black.withOpacity(0.85),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryAction({
    required String label,
    required Color accent,
    required Color surface,
    required VoidCallback? onTap,
  }) {
    final disabled = onTap == null;
    return _PressableScale(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.55 : 1,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: surface,
            border: Border.all(color: accent.withOpacity(0.45)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login_rounded, color: accent, size: 18),
              const SizedBox(width: 10),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeField(AppPalette palette, Color onSurface, Color accent) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border.withOpacity(0.5)),
      ),
      child: TextField(
        controller: _codeController,
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.characters,
        autocorrect: false,
        enableSuggestions: false,
        maxLength: 8,
        style: TextStyle(
          color: onSurface.withOpacity(0.95),
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 8,
        ),
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          hintText: 'XXXXXX',
          hintStyle: TextStyle(
            color: onSurface.withOpacity(0.25),
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 8,
          ),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
          TextInputFormatter.withFunction((oldValue, newValue) {
            return newValue.copyWith(text: newValue.text.toUpperCase());
          }),
        ],
        onSubmitted: (_) => _joinRoom(),
      ),
    );
  }

  Widget _buildDivider(Color onSurface) {
    return Row(
      children: [
        Expanded(child: Divider(color: onSurface.withOpacity(0.10), height: 1)),
        const SizedBox(width: 14),
        Text(
          _t(const {
            AppLanguage.ru: 'или',
            AppLanguage.en: 'or',
            AppLanguage.de: 'oder',
          }),
          style: TextStyle(
            color: onSurface.withOpacity(0.4),
            fontSize: 12,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Divider(color: onSurface.withOpacity(0.10), height: 1)),
      ],
    );
  }

  Widget _buildHowItWorks(AppPalette palette, Color onSurface, Color accent) {
    final items = [
      _t(const {
        AppLanguage.ru: 'Создайте комнату и отправьте код другу',
        AppLanguage.en: 'Create a room and send the code to a friend',
        AppLanguage.de: 'Erstellt einen Raum und schickt den Code an einen Freund',
      }),
      _t(const {
        AppLanguage.ru: 'Выберите режим и нажмите «Готов» — оба должны быть готовы',
        AppLanguage.en: 'Pick a mode and tap Ready — both players need to be ready',
        AppLanguage.de: 'Modus wählen und auf Bereit tippen — beide müssen bereit sein',
      }),
      _t(const {
        AppLanguage.ru: 'Запоминайте одновременно: побеждает точность и скорость',
        AppLanguage.en: 'Memorize at the same time — accuracy and speed decide the winner',
        AppLanguage.de: 'Gleichzeitig merken — Genauigkeit und Tempo entscheiden',
      }),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t(const {
              AppLanguage.ru: 'КАК ИГРАТЬ',
              AppLanguage.en: 'HOW TO PLAY',
              AppLanguage.de: 'SO GEHT\'S',
            }),
            style: TextStyle(
              color: onSurface.withOpacity(0.45),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < items.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withOpacity(0.12),
                    border: Border.all(color: accent.withOpacity(0.45)),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    items[i],
                    style: TextStyle(
                      color: onSurface.withOpacity(0.78),
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            if (i < items.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

// =====================================================================
// WAITING ROOM SCREEN — avatars + discipline picker (host) + chat
// =====================================================================

class DuelWaitingScreen extends StatefulWidget {
  final String roomId;
  const DuelWaitingScreen({super.key, required this.roomId});

  @override
  State<DuelWaitingScreen> createState() => _DuelWaitingScreenState();
}

class _DuelWaitingScreenState extends State<DuelWaitingScreen>
    with TickerProviderStateMixin {
  StreamSubscription<DuelRoom?>? _sub;
  DuelRoom? _room;
  bool _navigated = false;
  bool _starting = false;
  bool _autoStartAttempted = false;
  late AnimationController _pulseController;
  DuelLobbySettings? _localDraft;
  bool _hasPendingGuestSuggestion = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _sub = DuelService.instance.watchRoom(widget.roomId).listen(_onRoom);
    unawaited(DuelService.instance.refreshMyPlayerInRoom(widget.roomId));
  }

  void _onRoom(DuelRoom? room) {
    if (!mounted || _leaving) return;
    final myUid = CloudSyncService.instance.user.value?.uid;
    if (room != null &&
        myUid != null &&
        !room.players.any((p) => p.uid == myUid)) {
      _navigateBackWithMessage(_t(const {
        AppLanguage.ru: 'Вы вышли из комнаты',
        AppLanguage.en: 'You left the room',
        AppLanguage.de: 'Du hast den Raum verlassen',
      }));
      return;
    }
    setState(() {
      _room = room;
      if (room != null && room.pendingSuggestion == null) {
        _hasPendingGuestSuggestion = false;
        _localDraft = null;
      }
    });
    if (room == null) {
      _navigateBackWithMessage(_t(const {
        AppLanguage.ru: 'Комната закрыта',
        AppLanguage.en: 'Room closed',
        AppLanguage.de: 'Raum geschlossen',
      }));
      return;
    }
    if (_navigated) return;
    if (!room.allPlayersReady || room.pendingSuggestion != null) {
      _autoStartAttempted = false;
    }
    if (room.status == DuelStatus.playing && room.task != null && room.startAtMs != null) {
      _navigated = true;
      final chunk = myUid != null ? room.prefsFor(myUid).chunkSize : 1;
      Navigator.of(context).pushReplacement(
        _fadeRoute(DuelGameScreen(
          roomId: room.roomId,
          initialItemsPerScreen: chunk,
        )),
      );
      return;
    }
    unawaited(_maybeAutoStart(room));
  }

  DuelLobbySettings _effectiveSettings(DuelRoom room) {
    return _localDraft ?? room.lobbySettings;
  }

  Future<void> _onSettingsChanged(DuelLobbySettings next) async {
    final room = _room;
    if (room == null) return;
    final myUid = CloudSyncService.instance.user.value?.uid;
    if (myUid == null) return;
    final isHost = myUid == room.hostId;

    setState(() {
      _localDraft = next;
      if (!isHost) _hasPendingGuestSuggestion = true;
    });

    try {
      if (isHost) {
        await DuelService.instance.updateLobbySettings(
          roomId: widget.roomId,
          settings: next,
        );
      } else {
        await DuelService.instance.suggestLobbySettings(
          roomId: widget.roomId,
          settings: next,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _localDraft = null;
          _hasPendingGuestSuggestion = false;
        });
      }
    }
  }

  Future<void> _toggleReady() async {
    final room = _room;
    if (room == null || room.players.length < 2) return;
    final myUid = CloudSyncService.instance.user.value?.uid;
    if (myUid == null) return;
    final currentlyReady = room.isPlayerReady(myUid);
    uiTapClick(UiClickSound.soft);
    await DuelService.instance.setReady(roomId: widget.roomId, ready: !currentlyReady);
  }

  Future<void> _maybeAutoStart(DuelRoom room) async {
    if (_starting || _autoStartAttempted) return;
    if (!room.isFull || !room.allPlayersReady) return;
    if (room.status != DuelStatus.ready && room.status != DuelStatus.waiting) return;
    if (room.pendingSuggestion != null) return;

    setState(() => _starting = true);
    try {
      final settings = room.lobbySettings;
      final discipline = disciplineFromLobbySettings(settings);
      final count = settings.count;
      final List<String> items = discipline.sharedContent
          ? await generateSharedDuelItems(discipline: discipline, count: count)
          : <String>[];
      final task = DuelTask(
        discipline: discipline,
        items: items,
        count: count,
        memorizeSeconds: settings.memorizeSeconds,
        digitGroupSize: settings.standardDigits,
      );
      final started = await DuelService.instance.tryAutoStartDuel(
        roomId: widget.roomId,
        task: task,
        countdownMs: _kDuelCountdownMs,
      );
      if (started) {
        _autoStartAttempted = true;
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _onPersonalChunkChanged(int chunk) async {
    try {
      await DuelService.instance.updatePlayerPrefs(
        roomId: widget.roomId,
        chunkSize: chunk,
      );
    } catch (_) {}
  }

  Future<void> _acceptSuggestion() async {
    uiTapClick(UiClickSound.soft);
    await DuelService.instance.acceptSuggestion(roomId: widget.roomId);
  }

  Future<void> _rejectSuggestion() async {
    uiTapClick(UiClickSound.soft);
    await DuelService.instance.rejectSuggestion(roomId: widget.roomId);
  }

  void _navigateBackWithMessage(String message) {
    if (!mounted) return;
    _showSnack(context, message);
    Navigator.of(context).maybePop();
  }

  Future<void> _copyCode() async {
    uiTapClick(UiClickSound.soft);
    await Clipboard.setData(ClipboardData(text: widget.roomId));
    if (!mounted) return;
    _showSnack(
      context,
      _t(const {
        AppLanguage.ru: 'Код скопирован',
        AppLanguage.en: 'Code copied',
        AppLanguage.de: 'Code kopiert',
      }),
    );
  }

  Future<bool> _confirmLeave() async {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _t(const {
            AppLanguage.ru: 'Покинуть комнату?',
            AppLanguage.en: 'Leave room?',
            AppLanguage.de: 'Raum verlassen?',
          }),
          style: TextStyle(color: onSurface.withOpacity(0.92), fontWeight: FontWeight.w600),
        ),
        content: Text(
          _t(const {
            AppLanguage.ru: 'Соперник останется в комнате. Вы сможете зайти снова по коду.',
            AppLanguage.en: 'Your opponent stays in the room. You can rejoin with the code.',
            AppLanguage.de: 'Der Gegner bleibt im Raum. Du kannst mit dem Code wieder beitreten.',
          }),
          style: TextStyle(color: onSurface.withOpacity(0.65), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              _t(const {
                AppLanguage.ru: 'Остаться',
                AppLanguage.en: 'Stay',
                AppLanguage.de: 'Bleiben',
              }),
              style: TextStyle(color: onSurface.withOpacity(0.55)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              _t(const {
                AppLanguage.ru: 'Выйти',
                AppLanguage.en: 'Leave',
                AppLanguage.de: 'Verlassen',
              }),
              style: TextStyle(color: accent, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _leave() async {
    if (_leaving) return;
    if (!await _confirmLeave()) return;
    _leaving = true;
    uiTapClick(UiClickSound.soft);
    try {
      await DuelService.instance.leaveRoom(widget.roomId);
    } catch (_) {}
    await _sub?.cancel();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final room = _room;
    final myUid = CloudSyncService.instance.user.value?.uid;
    final isHost = room != null && myUid == room.hostId;
    final hasOpponent = room != null && room.players.length >= 2;
    final iAmReady = room != null && myUid != null && room.isPlayerReady(myUid);
    final allReady = room != null && room.allPlayersReady && hasOpponent;
    final pending = room?.pendingSuggestion;
    final showSuggestionBanner = isHost && pending != null && pending.suggestedBy != myUid;

    final myChunk = myUid != null && room != null ? room.prefsFor(myUid).chunkSize : 1;

    return WillPopScope(
      onWillPop: () async {
        await _leave();
        return false;
      },
      child: Scaffold(
        backgroundColor: palette.background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: palette.background,
          foregroundColor: onSurface,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _leave,
          ),
          title: Text(
            _t(const {
              AppLanguage.ru: 'Комната',
              AppLanguage.en: 'Room',
              AppLanguage.de: 'Raum',
            }),
            style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(2, 8, 2, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _buildCodeStrip(onSurface, accent, palette),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _buildVsRow(room, accent, onSurface, palette),
                ),
                if (showSuggestionBanner) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: _buildSuggestionBanner(pending, accent, onSurface, palette),
                  ),
                ],
                if (!isHost && _hasPendingGuestSuggestion && pending != null) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: _buildGuestWaitingBanner(onSurface, accent, palette),
                  ),
                ],
                const SizedBox(height: 10),
                Expanded(
                  child: room == null
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TrainerLobbySettingsPanel(
                                settings: _effectiveSettings(room),
                                onChanged: _onSettingsChanged,
                                enabled: showSuggestionBanner ? false : true,
                                personalChunkSize: myChunk,
                                onPersonalChunkChanged: _onPersonalChunkChanged,
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: DuelChatPanel(roomId: widget.roomId, height: 180),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _buildReadyButton(
                    hasOpponent: hasOpponent,
                    iAmReady: iAmReady,
                    allReady: allReady,
                    starting: _starting,
                    accent: accent,
                    onSurface: onSurface,
                    palette: palette,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionBanner(
    DuelPendingSuggestion suggestion,
    Color accent,
    Color onSurface,
    AppPalette palette,
  ) {
    final s = suggestion.settings;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t(const {
              AppLanguage.ru: 'Соперник предлагает изменения',
              AppLanguage.en: 'Opponent suggests changes',
              AppLanguage.de: 'Gegner schlägt Änderungen vor',
            }),
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _suggestionSummary(s),
            style: TextStyle(color: onSurface.withOpacity(0.72), fontSize: 11.5),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PressableScale(
                  onTap: _rejectSuggestion,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: palette.surface,
                      border: Border.all(color: palette.border.withOpacity(0.45)),
                    ),
                    child: Center(
                      child: Text(
                        _t(const {
                          AppLanguage.ru: 'Отклонить',
                          AppLanguage.en: 'Decline',
                          AppLanguage.de: 'Ablehnen',
                        }),
                        style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PressableScale(
                  onTap: _acceptSuggestion,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(colors: [accent.withOpacity(0.9), accent]),
                    ),
                    child: Center(
                      child: Text(
                        _t(const {
                          AppLanguage.ru: 'Принять',
                          AppLanguage.en: 'Accept',
                          AppLanguage.de: 'Annehmen',
                        }),
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _suggestionSummary(DuelLobbySettings s) {
    final modeLabel = _lobbyModeLabel(s.mode);
    final timePart = s.memorizeSeconds > 0
        ? '${s.memorizeSeconds}${_t(const {AppLanguage.ru: 'с', AppLanguage.en: 's', AppLanguage.de: 's'})}'
        : _t(const {
            AppLanguage.ru: 'без лимита',
            AppLanguage.en: 'no limit',
            AppLanguage.de: 'kein Limit',
          });
    final digitsLabel = s.mode == 'standard' && !s.matrixMode
        ? switch (s.standardDigits) {
            1 => '0-9',
            3 => '000-999',
            _ => '00-99',
          }
        : '';
    final digitsPart = digitsLabel.isEmpty ? '' : ' · $digitsLabel';
    return _t(const {
      AppLanguage.ru: 'MODE · COUNT эл. · TIME',
      AppLanguage.en: 'MODE · COUNT items · TIME',
      AppLanguage.de: 'MODE · COUNT Elem. · TIME',
    })
        .replaceAll('MODE', modeLabel)
        .replaceAll('COUNT', '${s.count}$digitsPart')
        .replaceAll('TIME', timePart);
  }

  String _lobbyModeLabel(String mode) {
    switch (mode) {
      case 'binary':
        return _t(const {AppLanguage.ru: 'Биты', AppLanguage.en: 'Bits', AppLanguage.de: 'Bits'});
      case 'words':
        return _t(const {AppLanguage.ru: 'Слова', AppLanguage.en: 'Words', AppLanguage.de: 'Worte'});
      case 'cards':
        return _t(const {AppLanguage.ru: 'Карты', AppLanguage.en: 'Cards', AppLanguage.de: 'Karten'});
      case 'images':
        return _t(const {AppLanguage.ru: 'Изображения', AppLanguage.en: 'Images', AppLanguage.de: 'Bilder'});
      case 'faces':
        return _t(const {AppLanguage.ru: 'Лица', AppLanguage.en: 'Faces', AppLanguage.de: 'Gesichter'});
      default:
        if (_room?.lobbySettings.matrixMode == true) {
          return _t(const {AppLanguage.ru: 'Числа · матрица', AppLanguage.en: 'Numbers · matrix', AppLanguage.de: 'Zahlen · Matrix'});
        }
        return _t(const {AppLanguage.ru: 'Числа', AppLanguage.en: 'Numbers', AppLanguage.de: 'Zahlen'});
    }
  }

  Widget _buildGuestWaitingBanner(Color onSurface, Color accent, AppPalette palette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: accent.withOpacity(0.7)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _t(const {
                AppLanguage.ru: 'Ждём подтверждения хоста…',
                AppLanguage.en: 'Waiting for host approval…',
                AppLanguage.de: 'Warte auf Host-Bestätigung…',
              }),
              style: TextStyle(color: onSurface.withOpacity(0.65), fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyButton({
    required bool hasOpponent,
    required bool iAmReady,
    required bool allReady,
    required bool starting,
    required Color accent,
    required Color onSurface,
    required AppPalette palette,
  }) {
    if (!hasOpponent) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: palette.surface,
          border: Border.all(color: palette.border.withOpacity(0.45)),
        ),
        child: Center(
          child: Text(
            _t(const {
              AppLanguage.ru: 'Ждём соперника…',
              AppLanguage.en: 'Waiting for opponent…',
              AppLanguage.de: 'Warte auf Gegner…',
            }),
            style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12, letterSpacing: 0.6),
          ),
        ),
      );
    }

    if (allReady && starting) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(colors: [accent.withOpacity(0.96), accent]),
        ),
        child: Center(
          child: Text(
            _t(const {
              AppLanguage.ru: '3 · 2 · 1 · СТАРТ…',
              AppLanguage.en: '3 · 2 · 1 · START…',
              AppLanguage.de: '3 · 2 · 1 · START…',
            }),
            style: TextStyle(
              color: Colors.black.withOpacity(0.85),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ),
      );
    }

    final label = iAmReady
        ? _t(const {
            AppLanguage.ru: 'НЕ ГОТОВ',
            AppLanguage.en: 'NOT READY',
            AppLanguage.de: 'NICHT BEREIT',
          })
        : _t(const {
            AppLanguage.ru: 'ГОТОВ',
            AppLanguage.en: 'READY',
            AppLanguage.de: 'BEREIT',
          });

    return _PressableScale(
      onTap: _toggleReady,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: iAmReady
              ? null
              : LinearGradient(colors: [accent.withOpacity(0.96), accent]),
          color: iAmReady ? palette.surface : null,
          border: iAmReady ? Border.all(color: accent.withOpacity(0.5)) : null,
          boxShadow: iAmReady
              ? null
              : [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 16)],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: iAmReady ? accent : Colors.black.withOpacity(0.85),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCodeStrip(Color onSurface, Color accent, AppPalette palette) {
    return GestureDetector(
      onTap: _copyCode,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withOpacity(0.5)),
                color: accent.withOpacity(0.08),
              ),
              child: Text(
                _t(const {
                  AppLanguage.ru: 'КОД',
                  AppLanguage.en: 'CODE',
                  AppLanguage.de: 'CODE',
                }),
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.roomId,
                style: TextStyle(
                  color: accent,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 8,
                ),
              ),
            ),
            Icon(Icons.copy_rounded, size: 16, color: onSurface.withOpacity(0.55)),
          ],
        ),
      ),
    );
  }

  Widget _buildVsRow(DuelRoom? room, Color accent, Color onSurface, AppPalette palette) {
    final hostId = room?.hostId;
    final players = room?.players ?? const <DuelPlayer>[];
    final host = players.cast<DuelPlayer?>().firstWhere(
          (p) => p?.uid == hostId,
          orElse: () => null,
        );
    final guest = players.cast<DuelPlayer?>().firstWhere(
          (p) => p != null && p.uid != hostId,
          orElse: () => null,
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border.withOpacity(0.45)),
      ),
      child: Row(
        children: [
          Expanded(child: _vsSlot(host, true, accent, onSurface, palette, room)),
          ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.05)
                .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withOpacity(0.5)),
                color: accent.withOpacity(0.08),
              ),
              child: Text(
                'VS',
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.4,
                ),
              ),
            ),
          ),
          Expanded(child: _vsSlot(guest, false, accent, onSurface, palette, room)),
        ],
      ),
    );
  }

  Widget _vsSlot(
    DuelPlayer? player,
    bool leftAlign,
    Color accent,
    Color onSurface,
    AppPalette palette,
    DuelRoom? room,
  ) {
    final filled = player != null;
    final isReady = filled && room != null && room.isPlayerReady(player.uid);
    final children = <Widget>[
      Stack(
        clipBehavior: Clip.none,
        children: [
          DuelAvatar(
            photoUrl: player?.photoUrl,
            photoData: player?.photoData,
            name: player?.name ?? '?',
            accent: accent,
            border: palette.border,
            size: 50,
            dim: !filled,
          ),
          if (isReady)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.surface,
                ),
                child: Icon(Icons.check_circle_rounded, size: 16, color: accent),
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        filled
            ? player.name
            : _t(const {
                AppLanguage.ru: 'Ждём...',
                AppLanguage.en: 'Waiting...',
                AppLanguage.de: 'Warte...',
              }),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: filled ? onSurface.withOpacity(0.9) : onSurface.withOpacity(0.45),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        filled
            ? (isReady
                ? _t(const {
                    AppLanguage.ru: 'готов',
                    AppLanguage.en: 'ready',
                    AppLanguage.de: 'bereit',
                  })
                : _t(const {
                    AppLanguage.ru: 'не готов',
                    AppLanguage.en: 'not ready',
                    AppLanguage.de: 'nicht bereit',
                  }))
            : (leftAlign
                ? _t(const {
                    AppLanguage.ru: 'хост',
                    AppLanguage.en: 'host',
                    AppLanguage.de: 'Host',
                  })
                : _t(const {
                    AppLanguage.ru: 'гость',
                    AppLanguage.en: 'guest',
                    AppLanguage.de: 'Gast',
                  })),
        style: TextStyle(
          color: isReady ? accent.withOpacity(0.85) : accent.withOpacity(0.55),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    ];
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: children);
  }
}

// =====================================================================
// GAME SCREEN — reuses TrainingScreen (solo trainer UI) in duel mode
// =====================================================================

class DuelGameScreen extends StatelessWidget {
  final String roomId;
  final int initialItemsPerScreen;
  const DuelGameScreen({
    super.key,
    required this.roomId,
    this.initialItemsPerScreen = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TrainingScreen(
      trainerMode: TrainerMode.duel,
      duelRoomId: roomId,
      duelInitialChunkSize: initialItemsPerScreen,
    );
  }
}


// =====================================================================
// RESULT SCREEN — verdict, session stats comparison, chat
// =====================================================================

class DuelResultScreen extends StatefulWidget {
  final String roomId;
  final List<String> items; // local items used by this player (for review)
  const DuelResultScreen({
    super.key,
    required this.roomId,
    this.items = const <String>[],
  });

  @override
  State<DuelResultScreen> createState() => _DuelResultScreenState();
}

class _DuelResultScreenState extends State<DuelResultScreen>
    with SingleTickerProviderStateMixin {
  StreamSubscription<DuelRoom?>? _sub;
  DuelRoom? _room;
  bool _entered = false;
  bool _navigatedToLobby = false;
  bool _rematchStarting = false;
  int? _myRating;
  late AnimationController _verdictController;

  @override
  void initState() {
    super.initState();
    _verdictController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _sub = DuelService.instance.watchRoom(widget.roomId).listen(_onResultRoom);
    _loadMyRating();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _entered = true);
      _verdictController.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _verdictController.dispose();
    super.dispose();
  }

  Future<void> _loadMyRating() async {
    final uid = CloudSyncService.instance.user.value?.uid;
    if (uid == null) return;
    final rating = await DuelRatingService.instance.fetchRating(uid);
    if (mounted) setState(() => _myRating = rating);
  }

  void _onResultRoom(DuelRoom? room) {
    if (!mounted) return;
    setState(() => _room = room);
    if (room == null) {
      _exit();
      return;
    }
    final myUid = CloudSyncService.instance.user.value?.uid;
    if (myUid != null && !room.players.any((p) => p.uid == myUid)) {
      _exit();
      return;
    }
    if (_navigatedToLobby) return;
    if ((room.status == DuelStatus.ready || room.status == DuelStatus.waiting) &&
        room.task == null &&
        room.results.isEmpty) {
      _navigatedToLobby = true;
      Navigator.of(context).pushReplacement(
        _fadeRoute(DuelWaitingScreen(roomId: widget.roomId)),
      );
      return;
    }
    if (room.status == DuelStatus.finished &&
        room.isFull &&
        room.allPlayersReady &&
        !_rematchStarting) {
      unawaited(_maybeStartNextRound(room));
    }
  }

  Future<void> _maybeStartNextRound(DuelRoom room) async {
    if (_rematchStarting) return;
    setState(() => _rematchStarting = true);
    try {
      await DuelService.instance.tryStartNextRound(roomId: widget.roomId);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _rematchStarting = false);
    }
  }

  Future<void> _toggleRematchReady() async {
    final room = _room;
    if (room == null || room.players.length < 2) return;
    final myUid = CloudSyncService.instance.user.value?.uid;
    if (myUid == null) return;
    uiTapClick(UiClickSound.soft);
    final ready = !room.isPlayerReady(myUid);
    await DuelService.instance.setReady(roomId: widget.roomId, ready: ready);
  }

  Future<void> _exit() async {
    uiTapClick(UiClickSound.soft);
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final room = _room;
    final me = CloudSyncService.instance.user.value?.uid;

    if (room == null) {
      return Scaffold(
        backgroundColor: palette.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final winnerUid = DuelService.instance.determineWinner(room);
    final isDraw = room.results.length >= 2 && winnerUid == null;
    final amWinner = winnerUid != null && winnerUid == me;
    final hasOpponent = room.players.length >= 2;
    final iRematchReady = me != null && room.isPlayerReady(me);
    final allRematchReady = hasOpponent && room.allPlayersReady;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: palette.background,
        foregroundColor: onSurface,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _exit,
        ),
        title: Text(
          _t(const {
            AppLanguage.ru: 'Результаты',
            AppLanguage.en: 'Results',
            AppLanguage.de: 'Ergebnisse',
          }),
          style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4),
        ),
      ),
      body: AnimatedOpacity(
        duration: const Duration(milliseconds: 380),
        opacity: _entered ? 1 : 0,
        curve: Curves.easeOutCubic,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 380),
          offset: _entered ? Offset.zero : const Offset(0, 0.04),
          curve: Curves.easeOutCubic,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildVerdict(
                  amWinner: amWinner,
                  isDraw: isDraw,
                  haveBoth: room.results.length >= 2,
                  accent: accent,
                  onSurface: onSurface,
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      if (me != null && room.results[me] != null)
                        _buildMySummaryCard(
                          room.results[me]!,
                          room.ratingDeltaBy[me],
                          accent,
                          onSurface,
                        ),
                      const SizedBox(height: 12),
                      _buildComparison(room, accent, onSurface, palette, me),
                      if (room.results.length >= 2) ...[
                        const SizedBox(height: 18),
                        DuelAnswerReviewSection(
                          room: room,
                          myItems: widget.items,
                          onSurface: onSurface,
                        ),
                      ],
                      const SizedBox(height: 12),
                      DuelChatPanel(roomId: widget.roomId, height: 160),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                if (hasOpponent && room.status == DuelStatus.finished) ...[
                  _PressableScale(
                    onTap: _rematchStarting ? null : _toggleRematchReady,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: iRematchReady
                            ? null
                            : LinearGradient(colors: [accent.withOpacity(0.96), accent]),
                        color: iRematchReady ? palette.surface : null,
                        border: iRematchReady
                            ? Border.all(color: accent.withOpacity(0.5))
                            : null,
                        boxShadow: iRematchReady
                            ? null
                            : [BoxShadow(color: accent.withOpacity(0.28), blurRadius: 14)],
                      ),
                      child: Center(
                        child: Text(
                          _rematchStarting
                              ? _t(const {
                                  AppLanguage.ru: 'ПОДГОТОВКА…',
                                  AppLanguage.en: 'PREPARING…',
                                  AppLanguage.de: 'VORBEREITUNG…',
                                })
                              : allRematchReady
                                  ? _t(const {
                                      AppLanguage.ru: 'ЗАПУСК НОВОГО РАУНДА…',
                                      AppLanguage.en: 'STARTING NEW ROUND…',
                                      AppLanguage.de: 'NEUE RUNDE STARTET…',
                                    })
                                  : iRematchReady
                                      ? _t(const {
                                          AppLanguage.ru: 'ЖДЁМ СОПЕРНИКА',
                                          AppLanguage.en: 'WAITING FOR OPPONENT',
                                          AppLanguage.de: 'WARTE AUF GEGNER',
                                        })
                                      : _t(const {
                                          AppLanguage.ru: 'НОВЫЙ РАУНД',
                                          AppLanguage.en: 'NEW ROUND',
                                          AppLanguage.de: 'NEUE RUNDE',
                                        }),
                          style: TextStyle(
                            color: iRematchReady && !allRematchReady
                                ? accent
                                : Colors.black.withOpacity(0.85),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                _PressableScale(
                  onTap: _exit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accent.withOpacity(0.5)),
                      color: palette.surface,
                    ),
                    child: Center(
                      child: Text(
                        _t(const {
                          AppLanguage.ru: 'НА ГЛАВНУЮ',
                          AppLanguage.en: 'GO HOME',
                          AppLanguage.de: 'STARTSEITE',
                        }),
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerdict({
    required bool amWinner,
    required bool isDraw,
    required bool haveBoth,
    required Color accent,
    required Color onSurface,
  }) {
    final IconData icon;
    final String title;
    final Color color;
    if (!haveBoth) {
      icon = Icons.hourglass_top_rounded;
      title = _t(const {
        AppLanguage.ru: 'Ждём результат соперника...',
        AppLanguage.en: 'Waiting for opponent...',
        AppLanguage.de: 'Warte auf Gegnerergebnis...',
      });
      color = onSurface.withOpacity(0.6);
    } else if (isDraw) {
      icon = Icons.balance_rounded;
      title = _t(const {
        AppLanguage.ru: 'Ничья',
        AppLanguage.en: 'Draw',
        AppLanguage.de: 'Unentschieden',
      });
      color = onSurface.withOpacity(0.85);
    } else if (amWinner) {
      icon = Icons.emoji_events_rounded;
      title = _t(const {
        AppLanguage.ru: 'Победа!',
        AppLanguage.en: 'Victory!',
        AppLanguage.de: 'Sieg!',
      });
      color = accent;
    } else {
      icon = Icons.flag_rounded;
      title = _t(const {
        AppLanguage.ru: 'Поражение',
        AppLanguage.en: 'Defeat',
        AppLanguage.de: 'Niederlage',
      });
      color = onSurface.withOpacity(0.78);
    }

    return ScaleTransition(
      scale: Tween<double>(begin: 0.94, end: 1.0).animate(
        CurvedAnimation(parent: _verdictController, curve: Curves.easeOutBack),
      ),
      child: FadeTransition(
        opacity: _verdictController,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.16), color.withOpacity(0.04)],
            ),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.16),
                  border: Border.all(color: color.withOpacity(0.5)),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMySummaryCard(
    DuelResult result,
    int? ratingDelta,
    Color accent,
    Color onSurface,
  ) {
    final pct = (result.accuracy * 100).round();
    final mistakes = result.total - result.correct;
    final recallSec = result.timeMs / 1000.0;
    final memSec = result.memorizeMs / 1000.0;
    final speedPerEl = result.total > 0 ? memSec / result.total : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      decoration: BoxDecoration(
        color: appPalette.value.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appPalette.value.border.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$pct%',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w100,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${result.correct}/${result.total} ${_t(const {
              AppLanguage.ru: 'верно',
              AppLanguage.en: 'correct',
              AppLanguage.de: 'richtig',
            })}',
            style: TextStyle(
              color: onSurface.withOpacity(0.55),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _miniStat(
                _t(const {
                  AppLanguage.ru: 'Запом.',
                  AppLanguage.en: 'Mem.',
                  AppLanguage.de: 'Merken',
                }),
                '${memSec.toStringAsFixed(1)}s',
                onSurface,
              ),
              _miniStat(
                _t(const {
                  AppLanguage.ru: 'Ввод',
                  AppLanguage.en: 'Recall',
                  AppLanguage.de: 'Eingabe',
                }),
                '${recallSec.toStringAsFixed(1)}s',
                onSurface,
              ),
              _miniStat(
                _t(const {
                  AppLanguage.ru: 'Ошибки',
                  AppLanguage.en: 'Mistakes',
                  AppLanguage.de: 'Fehler',
                }),
                '$mistakes',
                onSurface,
              ),
              _miniStat(
                _t(const {
                  AppLanguage.ru: 'Скорость',
                  AppLanguage.en: 'Speed',
                  AppLanguage.de: 'Tempo',
                }),
                '${speedPerEl.toStringAsFixed(2)}s',
                onSurface,
              ),
            ],
          ),
          if (ratingDelta != null || _myRating != null) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_myRating != null)
                  Text(
                    _t(const {
                      AppLanguage.ru: 'Рейтинг',
                      AppLanguage.en: 'Rating',
                      AppLanguage.de: 'Rating',
                    }) +
                        ': $_myRating',
                    style: TextStyle(
                      color: onSurface.withOpacity(0.5),
                      fontSize: 11,
                      letterSpacing: 0.4,
                    ),
                  ),
                if (ratingDelta != null) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (ratingDelta >= 0 ? accent : onSurface).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (ratingDelta >= 0 ? accent : onSurface).withOpacity(0.35),
                      ),
                    ),
                    child: Text(
                      ratingDelta >= 0 ? '+$ratingDelta' : '$ratingDelta',
                      style: TextStyle(
                        color: ratingDelta >= 0 ? accent : onSurface.withOpacity(0.75),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color onSurface) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: onSurface.withOpacity(0.42),
            fontSize: 9,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: onSurface.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildComparison(
    DuelRoom room,
    Color accent,
    Color onSurface,
    AppPalette palette,
    String? me,
  ) {
    final winnerUid = DuelService.instance.determineWinner(room);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final p in room.players)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _playerCard(
              player: p,
              result: room.results[p.uid],
              isMe: p.uid == me,
              isWinner: p.uid == winnerUid,
              accent: accent,
              onSurface: onSurface,
              palette: palette,
              task: room.task,
              lobbySettings: room.lobbySettings,
              ratingDelta: room.ratingDeltaBy[p.uid],
            ),
          ),
      ],
    );
  }

  Widget _playerCard({
    required DuelPlayer player,
    required DuelResult? result,
    required bool isMe,
    required bool isWinner,
    required Color accent,
    required Color onSurface,
    required AppPalette palette,
    required DuelTask? task,
    required DuelLobbySettings lobbySettings,
    int? ratingDelta,
  }) {
    final accuracyPct = result == null ? '--' : '${(result.accuracy * 100).round()}%';
    final timeLabel = result == null ? '--' : '${(result.timeMs / 1000).toStringAsFixed(1)}s';
    final correctLabel = result == null ? '--' : '${result.correct}/${result.total}';
    final memorizeLabel =
        result == null ? '--' : '${(result.memorizeMs / 1000).toStringAsFixed(1)}s';
    final mistakesLabel =
        result == null ? '--' : '${result.total - result.correct}';
    final speedLabel = result == null || result.total <= 0
        ? '--'
        : '${(result.memorizeMs / 1000 / result.total).toStringAsFixed(2)}s';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isWinner ? accent.withOpacity(0.6) : palette.border.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DuelAvatar(
                photoUrl: player.photoUrl,
                photoData: player.photoData,
                name: player.name,
                accent: accent,
                border: palette.border,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isMe
                          ? '${player.name} · ${_t(const {
                              AppLanguage.ru: 'Ты',
                              AppLanguage.en: 'You',
                              AppLanguage.de: 'Du',
                            })}'
                          : player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: onSurface.withOpacity(0.95),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (task != null)
                      Text(
                        '${lobbyModeLabel(lobbySettings)} · ${task.count}',
                        style: TextStyle(
                          color: onSurface.withOpacity(0.45),
                          fontSize: 11,
                          letterSpacing: 0.6,
                        ),
                      ),
                  ],
                ),
              ),
              if (isWinner)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accent.withOpacity(0.5)),
                  ),
                  child: Text(
                    'WIN',
                    style: TextStyle(
                      color: accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statTile(
                  label: _t(const {
                    AppLanguage.ru: 'Точность',
                    AppLanguage.en: 'Accuracy',
                    AppLanguage.de: 'Genauigkeit',
                  }),
                  value: accuracyPct,
                  accent: accent,
                  onSurface: onSurface,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _statTile(
                  label: _t(const {
                    AppLanguage.ru: 'Верных',
                    AppLanguage.en: 'Correct',
                    AppLanguage.de: 'Richtig',
                  }),
                  value: correctLabel,
                  accent: accent,
                  onSurface: onSurface,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _statTile(
                  label: _t(const {
                    AppLanguage.ru: 'Запом.',
                    AppLanguage.en: 'Mem.',
                    AppLanguage.de: 'Merken',
                  }),
                  value: memorizeLabel,
                  accent: accent,
                  onSurface: onSurface,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _statTile(
                  label: _t(const {
                    AppLanguage.ru: 'Ввод',
                    AppLanguage.en: 'Recall',
                    AppLanguage.de: 'Eingabe',
                  }),
                  value: timeLabel,
                  accent: accent,
                  onSurface: onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _statTile(
                  label: _t(const {
                    AppLanguage.ru: 'Ошибки',
                    AppLanguage.en: 'Mistakes',
                    AppLanguage.de: 'Fehler',
                  }),
                  value: mistakesLabel,
                  accent: accent,
                  onSurface: onSurface,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _statTile(
                  label: _t(const {
                    AppLanguage.ru: 'Скорость',
                    AppLanguage.en: 'Speed',
                    AppLanguage.de: 'Tempo',
                  }),
                  value: speedLabel,
                  accent: accent,
                  onSurface: onSurface,
                ),
              ),
              if (ratingDelta != null) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: _statTile(
                    label: _t(const {
                      AppLanguage.ru: 'Рейтинг',
                      AppLanguage.en: 'Rating',
                      AppLanguage.de: 'Rating',
                    }),
                    value: ratingDelta >= 0 ? '+$ratingDelta' : '$ratingDelta',
                    accent: accent,
                    onSurface: onSurface,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    required Color accent,
    required Color onSurface,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: onSurface.withOpacity(0.04),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: onSurface.withOpacity(0.45),
              fontSize: 9,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: onSurface.withOpacity(0.95),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
