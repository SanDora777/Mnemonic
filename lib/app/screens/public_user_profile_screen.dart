part of 'package:flutter_application_1/recovered_app.dart';

class PublicUserProfileScreen extends StatefulWidget {
  final String uid;
  final String fallbackName;

  const PublicUserProfileScreen({
    super.key,
    required this.uid,
    required this.fallbackName,
  });

  @override
  State<PublicUserProfileScreen> createState() => _PublicUserProfileScreenState();
}

class _PublicUserProfileScreenState extends State<PublicUserProfileScreen> {
  late Future<Map<String, dynamic>?> _future;
  bool _inviting = false;

  @override
  void initState() {
    super.initState();
    _future = CloudSyncService.instance.fetchPublicProfile(widget.uid);
  }

  bool get _isSelf {
    final me = CloudSyncService.instance.user.value?.uid;
    return me != null && me == widget.uid;
  }

  Future<void> _inviteToDuel(String targetName) async {
    if (_inviting || _isSelf) return;
    if (!CloudSyncService.instance.isSignedIn) {
      final ok = await showDuelAuthSheet(context);
      if (!ok || !mounted) return;
    }
    setState(() => _inviting = true);
    try {
      final room = await GlobalChatService.instance.inviteToDuel(
        targetUid: widget.uid,
        targetName: targetName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTexts.translate({
            AppLanguage.ru: 'Приглашение отправлено. Код: ${room.roomId}',
            AppLanguage.en: 'Invite sent. Code: ${room.roomId}',
            AppLanguage.de: 'Einladung gesendet. Code: ${room.roomId}',
          })),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => DuelWaitingScreen(roomId: room.roomId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _inviting = false);
    }
  }

  void _showProfileSheet({
    required String displayName,
    required String about,
    required bool isCreator,
    required ImageProvider<Object>? avatarImage,
    required bool hasAvatar,
    required Color onSurface,
    required AppPalette palette,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: onSurface.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 22),
                CircleAvatar(
                  radius: 52,
                  backgroundColor: appAccentColor.value.withOpacity(0.14),
                  backgroundImage: avatarImage,
                  child: !hasAvatar
                      ? Icon(Icons.person_rounded, size: 48, color: onSurface.withOpacity(0.75))
                      : null,
                ),
                const SizedBox(height: 18),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                if (isCreator) ...[
                  const SizedBox(height: 10),
                  const CreatorBadge(),
                ],
                if (about.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppTexts.get('profile_about_me'),
                      style: TextStyle(
                        color: appAccentColor.value,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    about.trim(),
                    style: TextStyle(
                      color: onSurface.withOpacity(0.78),
                      fontSize: 16,
                      height: 1.45,
                    ),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      '—',
                      style: TextStyle(color: onSurface.withOpacity(0.35), fontSize: 16),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _modeLabel(String mode) {
    switch (mode) {
      case 'standard':
        return AppTexts.get('mode_numbers');
      case 'binary':
        return AppTexts.get('mode_binary');
      case 'words':
        return AppTexts.get('mode_words');
      case 'images':
        return AppTexts.get('mode_photo');
      case 'cards':
        return AppTexts.get('mode_cards');
      case 'faces':
        return AppTexts.get('mode_faces');
      default:
        return mode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final palette = appPalette.value;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        foregroundColor: onSurface,
        title: Text(AppTexts.get('profile_user_results')),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data == null) {
            return Center(
              child: Text(widget.fallbackName, style: TextStyle(color: onSurface.withOpacity(0.75))),
            );
          }
          final displayName = (data['displayName'] as String?)?.trim().isNotEmpty == true
              ? (data['displayName'] as String)
              : widget.fallbackName;
          final photo = (data['photoUrl'] as String?) ?? '';
          final photoB64 = (data['photoData'] as String?) ?? '';
          final photoBytes = CloudSyncService.decodePublicAvatarBytes(
            photoData: photoB64,
            photoUrl: photo,
          );
          final httpPhoto = CloudSyncService.resolveHttpAvatarUrl(photo);
          final about = (data['aboutMe'] as String?) ?? '';
          final isCreator = data['isCreator'] == true;
          final canSeeStats = (data['canSeeStats'] as bool?) ?? false;
          final stats = (data['publicStats'] as Map<String, dynamic>?) ?? const {};
          final statsVersion = (stats['v'] as num?)?.toInt() ?? 1;
          const modes = ['standard', 'binary', 'words', 'images', 'cards', 'faces'];
          final hasAvatar = photoBytes != null || httpPhoto.isNotEmpty;
          final ImageProvider<Object>? avatarImage = photoBytes != null
              ? MemoryImage(photoBytes)
              : (httpPhoto.isNotEmpty ? NetworkImage(httpPhoto) as ImageProvider<Object> : null);

          int statValue(String mode, Map<String, dynamic> s, String key) {
            final raw = (s[key] as num?)?.toInt() ?? 0;
            return PublicStatsScoring.displayValue(
              mode: mode,
              raw: raw,
              statsVersion: statsVersion,
            );
          }

          Widget statLine(String label, int value) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: onSurface.withOpacity(0.58),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '$value',
                    style: TextStyle(
                      color: onSurface.withOpacity(0.95),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              if (!_isSelf) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _inviting ? null : () => _inviteToDuel(displayName),
                    icon: _inviting
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: palette.background,
                            ),
                          )
                        : const Icon(Icons.flash_on_rounded, size: 20),
                    label: Text(AppTexts.translate({
                      AppLanguage.ru: 'Пригласить на дуэль',
                      AppLanguage.en: 'Invite to duel',
                      AppLanguage.de: 'Zum Duell einladen',
                    })),
                    style: FilledButton.styleFrom(
                      backgroundColor: appAccentColor.value,
                      foregroundColor: palette.background,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showProfileSheet(
                    displayName: displayName,
                    about: about,
                    isCreator: isCreator,
                    avatarImage: avatarImage,
                    hasAvatar: hasAvatar,
                    onSurface: onSurface,
                    palette: palette,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: palette.border.withOpacity(0.32)),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: appAccentColor.value.withOpacity(0.14),
                          backgroundImage: avatarImage,
                          child: !hasAvatar
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 34,
                                  color: onSurface.withOpacity(0.78),
                                )
                              : null,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          displayName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: onSurface,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (isCreator) ...[
                          const SizedBox(height: 10),
                          const CreatorBadge(),
                        ],
                        if (about.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              AppTexts.get('profile_about_me'),
                              style: TextStyle(
                                color: appAccentColor.value,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            about.trim(),
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: onSurface.withOpacity(0.78),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 6),
                          Text(
                            AppTexts.get('profile_tap_for_profile'),
                            style: TextStyle(
                              color: onSurface.withOpacity(0.42),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (!canSeeStats)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: palette.border.withOpacity(0.32)),
                  ),
                  child: Text(
                    AppTexts.get('profile_results_hidden'),
                    style: TextStyle(
                      color: onSurface.withOpacity(0.72),
                      fontSize: 16,
                      height: 1.35,
                    ),
                  ),
                )
              else
                ...modes.map((mode) {
                  final raw = stats[mode];
                  final s = raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
                  final best1m = statValue(mode, s, 'best1m');
                  final best5m = statValue(mode, s, 'best5m');
                  final maxMem = statValue(mode, s, 'maxMem');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: palette.border.withOpacity(0.28)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _modeLabel(mode).toUpperCase(),
                            style: TextStyle(
                              color: appAccentColor.value,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          statLine(AppTexts.get('profile_best_1m'), best1m),
                          statLine(AppTexts.get('profile_best_5m'), best5m),
                          statLine(AppTexts.get('profile_max_mem'), maxMem),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

