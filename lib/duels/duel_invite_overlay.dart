import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/core/app_session.dart';
import '../app/core/ui_feedback.dart';
import '../chat/global_chat_service.dart';
import '../cloud/cloud_sync_service.dart';
import '../recovered_app.dart' show appAccentColor, appLanguage, appPalette, AppLanguage;
import 'duel_invite_accept.dart';

String _t(Map<AppLanguage, String> map) =>
    map[appLanguage.value] ?? map[AppLanguage.ru] ?? '';

/// Shows incoming duel invites on top of any screen except active training.
class DuelInviteGlobalOverlay extends StatefulWidget {
  const DuelInviteGlobalOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<DuelInviteGlobalOverlay> createState() => _DuelInviteGlobalOverlayState();
}

class _DuelInviteGlobalOverlayState extends State<DuelInviteGlobalOverlay> {
  StreamSubscription<List<DuelInviteNotification>>? _inviteSub;
  VoidCallback? _userListener;
  List<DuelInviteNotification> _invites = const [];
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _userListener = () => _subscribeInvites();
    CloudSyncService.instance.user.addListener(_userListener!);
    _subscribeInvites();
  }

  void _subscribeInvites() {
    _inviteSub?.cancel();
    if (CloudSyncService.instance.user.value == null) {
      if (mounted) setState(() => _invites = const []);
      return;
    }
    _inviteSub = GlobalChatService.instance.watchIncomingInvites().listen((list) {
      if (!mounted) return;
      setState(() => _invites = list);
    });
  }

  @override
  void dispose() {
    _inviteSub?.cancel();
    if (_userListener != null) {
      CloudSyncService.instance.user.removeListener(_userListener!);
    }
    super.dispose();
  }

  Future<void> _acceptInvite(DuelInviteNotification invite) async {
    if (_joining) return;
    appHaptic(UiClickSound.bright);
    setState(() => _joining = true);
    try {
      await acceptDuelInvite(context: context, invite: invite);
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Widget _buildBanner(DuelInviteNotification invite) {
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withOpacity(0.45)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.flash_on_rounded, color: accent, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _t({
                  AppLanguage.ru: '${invite.fromName} зовёт на дуэль',
                  AppLanguage.en: '${invite.fromName} invited you to a duel',
                  AppLanguage.de: '${invite.fromName} lädt zum Duell ein',
                }),
                style: TextStyle(color: onSurface.withOpacity(0.92), fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: _joining ? null : () => _acceptInvite(invite),
              child: Text(
                _joining
                    ? _t(const {
                        AppLanguage.ru: 'Вход…',
                        AppLanguage.en: 'Joining…',
                        AppLanguage.de: 'Beitritt…',
                      })
                    : _t(const {
                        AppLanguage.ru: 'Войти',
                        AppLanguage.en: 'Join',
                        AppLanguage.de: 'Beitreten',
                      }),
                style: TextStyle(color: accent, fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              onPressed: () => GlobalChatService.instance.dismissInvite(invite.fromUid),
              icon: Icon(Icons.close_rounded, size: 18, color: onSurface.withOpacity(0.45)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: trainingSessionDepth,
      builder: (context, depth, child) {
        final showBanner = depth == 0 && _invites.isNotEmpty;
        return Stack(
          children: [
            child!,
            if (showBanner)
              Positioned(
                top: MediaQuery.paddingOf(context).top,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: _buildBanner(_invites.first),
                ),
              ),
          ],
        );
      },
      child: widget.child,
    );
  }
}
