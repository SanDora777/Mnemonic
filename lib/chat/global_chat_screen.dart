import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_creator.dart';
import '../cloud/cloud_sync_service.dart';
import '../widgets/creator_badge.dart';
import '../duels/duel_auth_sheet.dart';
import '../duels/duel_invite_accept.dart';
import '../duels/duel_screens.dart';
import '../app/core/ui_feedback.dart';
import '../recovered_app.dart'
    show
        appPalette,
        appAccentColor,
        appLanguage,
        AppLanguage,
        AppPalette,
        initializeFirebaseSafely,
        PublicUserProfileScreen;
import 'global_chat_service.dart';

String _t(Map<AppLanguage, String> map) =>
    map[appLanguage.value] ?? map[AppLanguage.ru] ?? '';

const String _kIntroSeenPrefs = 'global_chat_intro_seen_v1';

class GlobalChatScreen extends StatefulWidget {
  const GlobalChatScreen({super.key, this.embedded = false});

  /// When true, renders only chat body (no [Scaffold]/[AppBar]) for [CommunityHubScreen].
  final bool embedded;

  @override
  State<GlobalChatScreen> createState() => _GlobalChatScreenState();
}

class _GlobalChatScreenState extends State<GlobalChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  StreamSubscription<List<GlobalChatMessage>>? _msgSub;
  StreamSubscription<List<DuelInviteNotification>>? _inviteSub;
  StreamSubscription<ChatMuteStatus?>? _muteSub;
  List<GlobalChatMessage> _messages = const <GlobalChatMessage>[];
  List<DuelInviteNotification> _invites = const <DuelInviteNotification>[];
  ChatMuteStatus? _muteStatus;
  String _dayKey = '';
  bool _sending = false;
  bool _loading = true;
  String? _error;
  Timer? _dayWatchTimer;
  final Set<String> _knownMessageIds = <String>{};
  final Set<String> _entranceAnimateIds = <String>{};

  bool get _isCreator => GlobalChatService.instance.isCreator;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final ready = CloudSyncService.instance.firebaseReady || await initializeFirebaseSafely();
    if (!ready) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _t(const {
            AppLanguage.ru: 'Нужен интернет и Firebase для чата',
            AppLanguage.en: 'Chat needs internet and Firebase',
            AppLanguage.de: 'Chat braucht Internet und Firebase',
          });
        });
      }
      return;
    }
    await CloudSyncService.instance.init(firebaseReady: true);

    if (!CloudSyncService.instance.isSignedIn) {
      if (!mounted) return;
      final ok = await showDuelAuthSheet(context);
      if (!mounted) return;
      if (!ok) {
        Navigator.of(context).maybePop();
        return;
      }
    }

    if (!mounted) return;
    setState(() => _loading = false);
    _subscribeMessages();
    _inviteSub = GlobalChatService.instance.watchIncomingInvites().listen((list) {
      if (!mounted) return;
      setState(() => _invites = list);
    });
    _muteSub = GlobalChatService.instance.watchMyMuteStatus().listen((status) {
      if (!mounted) return;
      setState(() => _muteStatus = status);
    });
    await AppCreator.syncProfileBadgeIfNeeded();
    _dayWatchTimer = Timer.periodic(const Duration(minutes: 1), (_) => _maybeRollDay());
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowIntro());
  }

  void _subscribeMessages() {
    _msgSub?.cancel();
    _dayKey = GlobalChatService.instance.europeDayKey();
    _knownMessageIds.clear();
    _entranceAnimateIds.clear();
    _msgSub = GlobalChatService.instance.watchMessages().listen(_onMessagesUpdated);
  }

  void _onMessagesUpdated(List<GlobalChatMessage> list) {
    if (!mounted) return;
    final hadHistory = _knownMessageIds.isNotEmpty;
    final newIds = <String>{};
    for (final msg in list) {
      if (!_knownMessageIds.contains(msg.id)) {
        newIds.add(msg.id);
      }
      _knownMessageIds.add(msg.id);
    }
    final grew = list.length > _messages.length;
    setState(() {
      _messages = list;
      _entranceAnimateIds
        ..clear()
        ..addAll(hadHistory ? newIds : const <String>{});
    });
    if (grew || newIds.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd(animated: hadHistory));
    }
  }

  void _maybeRollDay() {
    final next = GlobalChatService.instance.europeDayKey();
    if (next != _dayKey) _subscribeMessages();
  }

  void _scrollToEnd({bool animated = true}) {
    if (!_scrollCtrl.hasClients) return;
    final position = _scrollCtrl.position;
    final target = position.maxScrollExtent;
    if (!target.isFinite) return;

    if (!animated) {
      _scrollCtrl.jumpTo(target);
      return;
    }

    final distanceFromBottom = target - position.pixels;
    if (distanceFromBottom > 160) return;

    if (distanceFromBottom < 4) {
      _scrollCtrl.jumpTo(target);
      return;
    }

    _scrollCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _maybeShowIntro() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kIntroSeenPrefs) == true) return;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _IntroDialog(
        onOk: () async {
          await prefs.setBool(_kIntroSeenPrefs, true);
          if (ctx.mounted) Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  void dispose() {
    _dayWatchTimer?.cancel();
    _msgSub?.cancel();
    _inviteSub?.cancel();
    _muteSub?.cancel();
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_muteStatus?.isActive == true) {
      _snack(_muteMessage());
      return;
    }
    final text = _ctrl.text;
    if (text.trim().isEmpty || _sending) return;
    if (GlobalChatService.looksLikeEmbeddedMedia(text)) {
      _snack(_t(const {
        AppLanguage.ru: 'Фото, GIF и ссылки на медиа запрещены',
        AppLanguage.en: 'Photos, GIFs and media links are not allowed',
        AppLanguage.de: 'Fotos, GIFs und Medienlinks sind nicht erlaubt',
      }));
      return;
    }
    uiTapClick(UiClickSound.soft);
    setState(() => _sending = true);
    _ctrl.clear();
    try {
      await GlobalChatService.instance.sendMessage(text);
    } catch (e) {
      _snack(_errorText(e));
    }
    if (mounted) setState(() => _sending = false);
  }

  String _muteMessage() {
    final left = _muteStatus?.remaining;
    if (left == null) {
      return _t(const {
        AppLanguage.ru: 'Вы в муте',
        AppLanguage.en: 'You are muted',
        AppLanguage.de: 'Du bist stummgeschaltet',
      });
    }
    final h = left.inHours;
    final m = left.inMinutes % 60;
    return _t({
      AppLanguage.ru: 'Мут ещё ${h}ч ${m}м',
      AppLanguage.en: 'Muted for ${h}h ${m}m',
      AppLanguage.de: 'Stumm für ${h}h ${m}m',
    });
  }

  Future<void> _pickAndSendImage() async {
    if (!_isCreator || _sending) return;
    if (_muteStatus?.isActive == true) {
      _snack(_muteMessage());
      return;
    }
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 72,
      maxWidth: 960,
      maxHeight: 960,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final ext = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'jpg';
    final mime = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    uiTapClick(UiClickSound.soft);
    setState(() => _sending = true);
    try {
      await GlobalChatService.instance.sendImageMessage(
        bytes: bytes,
        mime: mime,
        caption: _ctrl.text,
      );
      _ctrl.clear();
    } catch (e) {
      final raw = e.toString();
      if (raw.contains('too_large')) {
        _snack(_t(const {
          AppLanguage.ru: 'Изображение слишком большое',
          AppLanguage.en: 'Image is too large',
          AppLanguage.de: 'Bild ist zu groß',
        }));
      } else {
        _snack(_errorText(e));
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  String _errorText(Object e) {
    final raw = e.toString();
    if (raw.contains('muted')) return _muteMessage();
    if (raw.contains('media_not_allowed')) {
      return _t(const {
        AppLanguage.ru: 'Только текст и смайлики',
        AppLanguage.en: 'Text and emoji only',
        AppLanguage.de: 'Nur Text und Emoji',
      });
    }
    if (raw.contains('not_signed_in')) {
      return _t(const {
        AppLanguage.ru: 'Войди в аккаунт',
        AppLanguage.en: 'Sign in required',
        AppLanguage.de: 'Anmeldung erforderlich',
      });
    }
    return _t(const {
      AppLanguage.ru: 'Не удалось отправить',
      AppLanguage.en: 'Could not send',
      AppLanguage.de: 'Senden fehlgeschlagen',
    });
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _onOtherMessageTap(GlobalChatMessage msg) async {
    uiTapClick(UiClickSound.soft);
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _isCreator
          ? _CreatorModSheet(displayName: msg.name, targetUid: msg.uid)
          : _OtherUserSheet(displayName: msg.name),
    );
    if (!mounted || action == null) return;
    if (action == 'profile') {
      _openUserProfile(msg.uid, msg.name);
      return;
    }
    if (action == 'duel') {
      await _inviteToDuel(msg.uid, msg.name);
      return;
    }
    if (action == 'delete') {
      try {
        await GlobalChatService.instance.deleteMessage(msg.id, authorUid: msg.uid);
      } catch (_) {
        _snack(_t(const {
          AppLanguage.ru: 'Не удалось удалить',
          AppLanguage.en: 'Could not delete',
          AppLanguage.de: 'Löschen fehlgeschlagen',
        }));
      }
      return;
    }
    if (action.startsWith('mute_')) {
      final minutes = int.tryParse(action.replaceFirst('mute_', '')) ?? 60;
      try {
        await GlobalChatService.instance.muteUser(
          targetUid: msg.uid,
          duration: Duration(minutes: minutes),
        );
        _snack(_t(const {
          AppLanguage.ru: 'Пользователь в муте',
          AppLanguage.en: 'User muted',
          AppLanguage.de: 'Nutzer stummgeschaltet',
        }));
      } catch (_) {
        _snack(_t(const {
          AppLanguage.ru: 'Не удалось замутить',
          AppLanguage.en: 'Could not mute',
          AppLanguage.de: 'Stummschalten fehlgeschlagen',
        }));
      }
    }
  }

  void _openUserProfile(String uid, String fallbackName) {
    uiTapClick(UiClickSound.soft);
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PublicUserProfileScreen(
          uid: uid,
          fallbackName: fallbackName,
        ),
      ),
    );
  }

  Future<void> _inviteToDuel(String targetUid, String targetName) async {
    try {
      final room = await GlobalChatService.instance.inviteToDuel(
        targetUid: targetUid,
        targetName: targetName,
      );
      if (!mounted) return;
      _snack(_t({
        AppLanguage.ru: 'Приглашение отправлено. Код: ${room.roomId}',
        AppLanguage.en: 'Invite sent. Code: ${room.roomId}',
        AppLanguage.de: 'Einladung gesendet. Code: ${room.roomId}',
      }));
      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => DuelWaitingScreen(roomId: room.roomId)),
      );
    } catch (e) {
      _snack(_errorText(e));
    }
  }

  Future<void> _onOwnMessageTap(GlobalChatMessage msg) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OwnMessageSheet(),
    );
    if (!mounted || action == null) return;
    if (action == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => _ConfirmDeleteDialog(),
      );
      if (ok != true || !mounted) return;
      try {
        await GlobalChatService.instance.deleteMessage(msg.id);
      } catch (_) {
        _snack(_t(const {
          AppLanguage.ru: 'Не удалось удалить',
          AppLanguage.en: 'Could not delete',
          AppLanguage.de: 'Löschen fehlgeschlagen',
        }));
      }
      return;
    }
    if (action == 'edit') {
      if (msg.hasImage) {
        _snack(_t(const {
          AppLanguage.ru: 'Изображения нельзя редактировать',
          AppLanguage.en: 'Images cannot be edited',
          AppLanguage.de: 'Bilder können nicht bearbeitet werden',
        }));
        return;
      }
      final updated = await showDialog<String>(
        context: context,
        builder: (ctx) => _EditMessageDialog(initial: msg.text),
      );
      if (updated == null || updated.trim().isEmpty) return;
      try {
        await GlobalChatService.instance.editMessage(messageId: msg.id, text: updated);
      } catch (e) {
        _snack(_errorText(e));
      }
    }
  }

  Future<void> _acceptInvite(DuelInviteNotification invite) async {
    uiTapClick(UiClickSound.bright);
    await acceptDuelInvite(context: context, invite: invite);
  }

  Widget _buildChatBody(
    AppPalette palette,
    Color accent,
    Color onSurface,
    String? me,
  ) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: accent.withOpacity(0.7)));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: onSurface.withOpacity(0.7))),
        ),
      );
    }
    return Column(
      children: [
        if (_muteStatus?.isActive == true) _buildMuteBanner(palette, accent, onSurface),
        if (_invites.isNotEmpty) _buildInvitesBanner(palette, accent, onSurface),
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Text(
                    _t(const {
                      AppLanguage.ru: 'Напиши первое сообщение',
                      AppLanguage.en: 'Be the first to write',
                      AppLanguage.de: 'Schreib die erste Nachricht',
                    }),
                    style: TextStyle(color: onSurface.withOpacity(0.42), fontSize: 13),
                  ),
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final mine = msg.uid == me;
                    return _MessageBubble(
                      key: ValueKey(msg.id),
                      msg: msg,
                      mine: mine,
                      accent: accent,
                      onSurface: onSurface,
                      palette: palette,
                      animateEntrance: _entranceAnimateIds.contains(msg.id),
                      onTap: () {
                        if (mine) {
                          _onOwnMessageTap(msg);
                        } else {
                          _onOtherMessageTap(msg);
                        }
                      },
                    );
                  },
                ),
        ),
        _buildComposer(palette, accent, onSurface),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final me = CloudSyncService.instance.user.value?.uid;

    final body = _buildChatBody(palette, accent, onSurface, me);

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurface.withOpacity(0.7), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t(const {
                AppLanguage.ru: 'СООБЩЕСТВО',
                AppLanguage.en: 'COMMUNITY',
                AppLanguage.de: 'COMMUNITY',
              }),
              style: TextStyle(
                color: onSurface.withOpacity(0.92),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.4,
              ),
            ),
            Text(
              _t(const {
                AppLanguage.ru: 'Очистка в 00:00 по Европе',
                AppLanguage.en: 'Clears at 00:00 Europe time',
                AppLanguage.de: 'Leert um 00:00 Uhr (Europa)',
              }),
              style: TextStyle(
                color: accent.withOpacity(0.75),
                fontSize: 10,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
      body: body,
    );
  }

  Widget _buildMuteBanner(AppPalette palette, Color accent, Color onSurface) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.volume_off_rounded, color: Colors.redAccent.shade200, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _muteMessage(),
              style: TextStyle(color: onSurface.withOpacity(0.88), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitesBanner(AppPalette palette, Color accent, Color onSurface) {
    final invite = _invites.first;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.45)),
      ),
      child: Row(
        children: [
          Icon(Icons.flash_on_rounded, color: accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _t({
                AppLanguage.ru: '${invite.fromName} зовёт на дуэль',
                AppLanguage.en: '${invite.fromName} invited you to a duel',
                AppLanguage.de: '${invite.fromName} lädt zum Duell ein',
              }),
              style: TextStyle(color: onSurface.withOpacity(0.9), fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => _acceptInvite(invite),
            child: Text(
              _t(const {
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
    );
  }

  Widget _buildComposer(AppPalette palette, Color accent, Color onSurface) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
        child: Row(
          children: [
            if (_isCreator) ...[
              GestureDetector(
                onTap: _sending ? null : _pickAndSendImage,
                child: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accent.withOpacity(0.45)),
                  ),
                  child: Icon(Icons.image_outlined, size: 20, color: accent),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: palette.border.withOpacity(0.5)),
                ),
                child: TextField(
                  controller: _ctrl,
                  enabled: _muteStatus?.isActive != true,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  maxLength: GlobalChatService.kMaxMessageLength,
                  style: TextStyle(color: onSurface.withOpacity(0.95), fontSize: 14),
                  decoration: InputDecoration(
                    counterText: '',
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: InputBorder.none,
                    hintText: _t(_isCreator
                        ? const {
                            AppLanguage.ru: 'Сообщение или подпись к фото...',
                            AppLanguage.en: 'Message or image caption...',
                            AppLanguage.de: 'Nachricht oder Bildunterschrift...',
                          }
                        : const {
                            AppLanguage.ru: 'Сообщение... 😊',
                            AppLanguage.en: 'Message... 😊',
                            AppLanguage.de: 'Nachricht... 😊',
                          }),
                    hintStyle: TextStyle(color: onSurface.withOpacity(0.32), fontSize: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _sending ? null : _send,
              child: Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [accent.withOpacity(0.92), accent]),
                  boxShadow: [BoxShadow(color: accent.withOpacity(0.35), blurRadius: 12)],
                ),
                child: _sending
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black.withOpacity(0.7)),
                      )
                    : Icon(Icons.send_rounded, size: 18, color: Colors.black.withOpacity(0.82)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatefulWidget {
  final GlobalChatMessage msg;
  final bool mine;
  final Color accent;
  final Color onSurface;
  final AppPalette palette;
  final bool animateEntrance;
  final VoidCallback onTap;

  const _MessageBubble({
    super.key,
    required this.msg,
    required this.mine,
    required this.accent,
    required this.onSurface,
    required this.palette,
    required this.animateEntrance,
    required this.onTap,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  AnimationController? _entranceCtrl;
  Animation<double>? _opacity;
  Animation<Offset>? _slide;

  @override
  void initState() {
    super.initState();
    _setupEntranceAnimation();
  }

  @override
  void didUpdateWidget(covariant _MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.animateEntrance && widget.animateEntrance) {
      _setupEntranceAnimation();
    }
  }

  void _setupEntranceAnimation() {
    if (!widget.animateEntrance) return;
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    final curve = CurvedAnimation(parent: _entranceCtrl!, curve: Curves.easeOutCubic);
    _opacity = curve;
    _slide = Tween<Offset>(
      begin: Offset(0, widget.mine ? 0.06 : 0.08),
      end: Offset.zero,
    ).animate(curve);
    _entranceCtrl!.forward();
  }

  void _disposeEntranceAnimation() {
    _entranceCtrl?.dispose();
    _entranceCtrl = null;
    _opacity = null;
    _slide = null;
  }

  @override
  void dispose() {
    _disposeEntranceAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bubble = Align(
      alignment: widget.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
          child: Container(
            margin: const EdgeInsets.only(top: 5, bottom: 5),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: widget.mine ? widget.accent.withOpacity(0.18) : widget.palette.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(widget.mine ? 16 : 5),
                bottomRight: Radius.circular(widget.mine ? 5 : 16),
              ),
              border: Border.all(
                color: widget.mine
                    ? widget.accent.withOpacity(0.42)
                    : widget.palette.border.withOpacity(0.45),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.mine)
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.msg.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: widget.accent.withOpacity(0.88),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (widget.msg.isCreator) ...[
                        const SizedBox(width: 6),
                        const CreatorBadge(compact: true),
                      ] else ...[
                        const SizedBox(width: 6),
                        Icon(Icons.flash_on_outlined,
                            size: 11, color: widget.onSurface.withOpacity(0.28)),
                      ],
                    ],
                  ),
                if (widget.mine && widget.msg.isCreator) ...[
                  const CreatorBadge(compact: true),
                  const SizedBox(height: 4),
                ],
                if (widget.msg.hasImage && widget.msg.imageBytes != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      widget.msg.imageBytes!,
                      width: 220,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),
                  ),
                  if (widget.msg.text.trim().isNotEmpty) const SizedBox(height: 6),
                ],
                if (widget.msg.text.trim().isNotEmpty)
                  Text(
                    widget.msg.text,
                    style: TextStyle(
                      color: widget.onSurface.withOpacity(0.93),
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                if (widget.msg.isEdited)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _t(const {
                        AppLanguage.ru: 'изменено',
                        AppLanguage.en: 'edited',
                        AppLanguage.de: 'bearbeitet',
                      }),
                      style: TextStyle(
                        color: widget.onSurface.withOpacity(0.35),
                        fontSize: 9,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (_entranceCtrl == null || _opacity == null || _slide == null) {
      return bubble;
    }

    return FadeTransition(
      opacity: _opacity!,
      child: SlideTransition(position: _slide!, child: bubble),
    );
  }
}

class _IntroDialog extends StatelessWidget {
  final VoidCallback onOk;
  const _IntroDialog({required this.onOk});

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: palette.border.withOpacity(0.55)),
          boxShadow: [BoxShadow(color: accent.withOpacity(0.15), blurRadius: 28)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_rounded, color: accent, size: 36),
            const SizedBox(height: 14),
            Text(
              _t(const {
                AppLanguage.ru: 'Чат сообщества',
                AppLanguage.en: 'Community chat',
                AppLanguage.de: 'Community-Chat',
              }),
              style: TextStyle(
                color: onSurface.withOpacity(0.95),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _t(const {
                AppLanguage.ru:
                    'Все сообщения автоматически очищаются каждые 24 часа в 00:00 по европейскому времени (Europe/Berlin). Только текст и смайлики — без фото и GIF.',
                AppLanguage.en:
                    'All messages are cleared every 24 hours at 00:00 European time (Europe/Berlin). Text and emoji only — no photos or GIFs.',
                AppLanguage.de:
                    'Alle Nachrichten werden alle 24 Stunden um 00:00 Uhr europäischer Zeit (Europe/Berlin) gelöscht. Nur Text und Emoji — keine Fotos oder GIFs.',
              }),
              textAlign: TextAlign.center,
              style: TextStyle(color: onSurface.withOpacity(0.72), fontSize: 13, height: 1.45),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onOk,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black.withOpacity(0.85),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _t(const {
                    AppLanguage.ru: 'Понятно',
                    AppLanguage.en: 'Got it',
                    AppLanguage.de: 'Verstanden',
                  }),
                  style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatorModSheet extends StatelessWidget {
  final String displayName;
  final String targetUid;
  const _CreatorModSheet({required this.displayName, required this.targetUid});

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    Widget tile({
      required IconData icon,
      required String label,
      required String action,
      Color? iconColor,
    }) {
      return ListTile(
        leading: Icon(icon, color: iconColor ?? accent),
        title: Text(label, style: TextStyle(color: onSurface.withOpacity(0.9))),
        onTap: () => Navigator.pop(context, action),
      );
    }

    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
            child: Row(
              children: [
                const CreatorBadge(compact: true),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayName,
                    style: TextStyle(
                      color: onSurface.withOpacity(0.92),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          tile(
            icon: Icons.person_outline_rounded,
            label: _t(const {
              AppLanguage.ru: 'Профиль и статистика',
              AppLanguage.en: 'Profile & stats',
              AppLanguage.de: 'Profil & Statistik',
            }),
            action: 'profile',
          ),
          tile(
            icon: Icons.flash_on_rounded,
            label: _t(const {
              AppLanguage.ru: 'Пригласить на дуэль',
              AppLanguage.en: 'Invite to duel',
              AppLanguage.de: 'Zum Duell einladen',
            }),
            action: 'duel',
          ),
          tile(
            icon: Icons.delete_outline_rounded,
            label: _t(const {
              AppLanguage.ru: 'Удалить сообщение',
              AppLanguage.en: 'Delete message',
              AppLanguage.de: 'Nachricht löschen',
            }),
            action: 'delete',
            iconColor: Colors.redAccent,
          ),
          const Divider(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _t(const {
                  AppLanguage.ru: 'ЗАМУТИТЬ',
                  AppLanguage.en: 'MUTE',
                  AppLanguage.de: 'STUMMSCHALTEN',
                }),
                style: TextStyle(
                  color: onSurface.withOpacity(0.45),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          tile(
            icon: Icons.timer_outlined,
            label: _t(const {
              AppLanguage.ru: '15 минут',
              AppLanguage.en: '15 minutes',
              AppLanguage.de: '15 Minuten',
            }),
            action: 'mute_15',
          ),
          tile(
            icon: Icons.timer_outlined,
            label: _t(const {
              AppLanguage.ru: '1 час',
              AppLanguage.en: '1 hour',
              AppLanguage.de: '1 Stunde',
            }),
            action: 'mute_60',
          ),
          tile(
            icon: Icons.timer_outlined,
            label: _t(const {
              AppLanguage.ru: '6 часов',
              AppLanguage.en: '6 hours',
              AppLanguage.de: '6 Stunden',
            }),
            action: 'mute_360',
          ),
          tile(
            icon: Icons.timer_outlined,
            label: _t(const {
              AppLanguage.ru: '24 часа',
              AppLanguage.en: '24 hours',
              AppLanguage.de: '24 Stunden',
            }),
            action: 'mute_1440',
          ),
          tile(
            icon: Icons.block_rounded,
            label: _t(const {
              AppLanguage.ru: '7 дней',
              AppLanguage.en: '7 days',
              AppLanguage.de: '7 Tage',
            }),
            action: 'mute_10080',
            iconColor: Colors.redAccent,
          ),
        ],
      ),
    );
  }
}

class _OtherUserSheet extends StatelessWidget {
  final String displayName;
  const _OtherUserSheet({required this.displayName});

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            displayName,
            style: TextStyle(
              color: onSurface.withOpacity(0.92),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.person_outline_rounded, color: accent),
            title: Text(
              _t(const {
                AppLanguage.ru: 'Профиль и статистика',
                AppLanguage.en: 'Profile & stats',
                AppLanguage.de: 'Profil & Statistik',
              }),
              style: TextStyle(color: onSurface.withOpacity(0.9)),
            ),
            onTap: () => Navigator.pop(context, 'profile'),
          ),
          ListTile(
            leading: Icon(Icons.flash_on_rounded, color: accent),
            title: Text(
              _t(const {
                AppLanguage.ru: 'Пригласить на дуэль',
                AppLanguage.en: 'Invite to duel',
                AppLanguage.de: 'Zum Duell einladen',
              }),
              style: TextStyle(color: onSurface.withOpacity(0.9)),
            ),
            onTap: () => Navigator.pop(context, 'duel'),
          ),
        ],
      ),
    );
  }
}

class _OwnMessageSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.edit_outlined, color: onSurface.withOpacity(0.75)),
            title: Text(
              _t(const {
                AppLanguage.ru: 'Изменить',
                AppLanguage.en: 'Edit',
                AppLanguage.de: 'Bearbeiten',
              }),
            ),
            onTap: () => Navigator.pop(context, 'edit'),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline_rounded, color: Colors.redAccent.withOpacity(0.9)),
            title: Text(
              _t(const {
                AppLanguage.ru: 'Удалить',
                AppLanguage.en: 'Delete',
                AppLanguage.de: 'Löschen',
              }),
            ),
            onTap: () => Navigator.pop(context, 'delete'),
          ),
        ],
      ),
    );
  }
}

class _ConfirmDeleteDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return AlertDialog(
      backgroundColor: palette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        _t(const {
          AppLanguage.ru: 'Удалить сообщение?',
          AppLanguage.en: 'Delete message?',
          AppLanguage.de: 'Nachricht löschen?',
        }),
        style: TextStyle(color: onSurface.withOpacity(0.9), fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(_t(const {
            AppLanguage.ru: 'Отмена',
            AppLanguage.en: 'Cancel',
            AppLanguage.de: 'Abbrechen',
          })),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            _t(const {
              AppLanguage.ru: 'Удалить',
              AppLanguage.en: 'Delete',
              AppLanguage.de: 'Löschen',
            }),
            style: TextStyle(color: accent, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _EditMessageDialog extends StatefulWidget {
  final String initial;
  const _EditMessageDialog({required this.initial});

  @override
  State<_EditMessageDialog> createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends State<_EditMessageDialog> {
  late final TextEditingController _editCtrl;

  @override
  void initState() {
    super.initState();
    _editCtrl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _editCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return AlertDialog(
      backgroundColor: palette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        _t(const {
          AppLanguage.ru: 'Изменить сообщение',
          AppLanguage.en: 'Edit message',
          AppLanguage.de: 'Nachricht bearbeiten',
        }),
        style: TextStyle(color: onSurface.withOpacity(0.9), fontSize: 16),
      ),
      content: TextField(
        controller: _editCtrl,
        autofocus: true,
        maxLength: GlobalChatService.kMaxMessageLength,
        style: TextStyle(color: onSurface.withOpacity(0.95)),
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accent),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_t(const {
            AppLanguage.ru: 'Отмена',
            AppLanguage.en: 'Cancel',
            AppLanguage.de: 'Abbrechen',
          })),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _editCtrl.text),
          child: Text(
            _t(const {
              AppLanguage.ru: 'Сохранить',
              AppLanguage.en: 'Save',
              AppLanguage.de: 'Speichern',
            }),
            style: TextStyle(color: accent, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
