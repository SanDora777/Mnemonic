import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/core/ui_feedback.dart';
import '../cloud/cloud_sync_service.dart';
import '../recovered_app.dart'
    show appPalette, appAccentColor, appLanguage, AppLanguage, AppPalette;
import 'duel_service.dart';

String _t(Map<AppLanguage, String> map) =>
    map[appLanguage.value] ?? map[AppLanguage.ru] ?? '';

class DuelChatPanel extends StatefulWidget {
  final String roomId;
  final double height;
  const DuelChatPanel({
    super.key,
    required this.roomId,
    this.height = 240,
  });

  @override
  State<DuelChatPanel> createState() => _DuelChatPanelState();
}

class _DuelChatPanelState extends State<DuelChatPanel> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  StreamSubscription<List<DuelChatMessage>>? _sub;
  List<DuelChatMessage> _messages = const <DuelChatMessage>[];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _sub = DuelService.instance.watchMessages(widget.roomId).listen((list) {
      if (!mounted) return;
      final old = _messages.length;
      setState(() => _messages = list);
      if (list.length != old) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scrollCtrl.hasClients) return;
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text;
    if (text.trim().isEmpty || _sending) return;
    appHaptic(UiClickSound.soft);
    setState(() => _sending = true);
    _ctrl.clear();
    try {
      await DuelService.instance.sendMessage(roomId: widget.roomId, text: text);
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final me = CloudSyncService.instance.user.value?.uid;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 14, color: accent.withOpacity(0.85)),
                const SizedBox(width: 8),
                Text(
                  _t(const {
                    AppLanguage.ru: 'ЧАТ',
                    AppLanguage.en: 'CHAT',
                    AppLanguage.de: 'CHAT',
                  }),
                  style: TextStyle(
                    color: onSurface.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: widget.height,
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      _t(const {
                        AppLanguage.ru: 'Напиши первое сообщение',
                        AppLanguage.en: 'Say something first',
                        AppLanguage.de: 'Schreib eine Nachricht',
                      }),
                      style: TextStyle(color: onSurface.withOpacity(0.4), fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final mine = msg.uid == me;
                      return _bubble(msg, mine, accent, onSurface, palette);
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: palette.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: palette.border.withOpacity(0.4)),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      style: TextStyle(color: onSurface.withOpacity(0.95), fontSize: 13),
                      maxLength: 240,
                      decoration: InputDecoration(
                        counterText: '',
                        isCollapsed: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: InputBorder.none,
                        hintText: _t(const {
                          AppLanguage.ru: 'Сообщение...',
                          AppLanguage.en: 'Message...',
                          AppLanguage.de: 'Nachricht...',
                        }),
                        hintStyle: TextStyle(color: onSurface.withOpacity(0.3), fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sending ? null : _send,
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withOpacity(0.16),
                      border: Border.all(color: accent.withOpacity(0.5)),
                    ),
                    child: Icon(Icons.send_rounded, size: 16, color: accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(
    DuelChatMessage msg,
    bool mine,
    Color accent,
    Color onSurface,
    AppPalette palette,
  ) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Container(
          margin: const EdgeInsets.only(top: 4, bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: mine ? accent.withOpacity(0.18) : palette.card,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(mine ? 14 : 4),
              bottomRight: Radius.circular(mine ? 4 : 14),
            ),
            border: Border.all(
              color: mine ? accent.withOpacity(0.4) : palette.border.withOpacity(0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!mine)
                Text(
                  msg.name,
                  style: TextStyle(
                    color: accent.withOpacity(0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              Text(
                msg.text,
                style: TextStyle(
                  color: onSurface.withOpacity(0.92),
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
