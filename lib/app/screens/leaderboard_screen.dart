part of 'package:flutter_application_1/recovered_app.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

enum _LeaderboardRange { day, week, allTime }

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  _LeaderboardRange _range = _LeaderboardRange.day;
  late Future<LeaderboardEntry?> _previousChampionFuture;
  bool _entered = false;
  final Map<String, int> _presenceMs = <String, int>{};
  Timer? _presenceRefreshTimer;
  List<String> _lastPresenceUids = const [];
  String? _lastPresenceSyncKey;

  @override
  void initState() {
    super.initState();
    unawaited(_ensureLeaderboardAccess());
    _previousChampionFuture = LeaderboardService.instance.fetchPreviousDayChampion();
    _presenceRefreshTimer = Timer.periodic(const Duration(seconds: 50), (_) {
      if (_lastPresenceUids.isEmpty) return;
      unawaited(_refreshPresence(_lastPresenceUids));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _entered = true);
    });
  }

  @override
  void dispose() {
    _presenceRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshPresence(List<String> uids) async {
    final fetched = await PresenceService.instance.fetchLastSeenMs(uids);
    if (!mounted || fetched.isEmpty) return;
    var changed = false;
    for (final e in fetched.entries) {
      if (_presenceMs[e.key] != e.value) {
        _presenceMs[e.key] = e.value;
        changed = true;
      }
    }
    if (changed) setState(() {});
  }

  void _syncPresenceForEntries(List<LeaderboardEntry> entries) {
    final uids = entries
        .map((e) => e.uid)
        .where((u) => u.isNotEmpty && u != '-')
        .toList(growable: false);
    if (uids.isEmpty) return;
    final syncKey = uids.join('\u0001');
    if (syncKey == _lastPresenceSyncKey) return;
    _lastPresenceSyncKey = syncKey;
    _lastPresenceUids = uids;
    unawaited(_refreshPresence(uids));
  }

  bool _isOnline(LeaderboardEntry entry) {
    final ms = _presenceMs[entry.uid] ?? entry.lastSeenMs;
    return PresenceService.instance.isOnline(ms);
  }

  Future<void> _ensureLeaderboardAccess() async {
    final ready = await initializeFirebaseSafely();
    if (!ready) return;
    try {
      await CloudSyncService.instance.init(firebaseReady: true);
      if (CloudSyncService.instance.user.value == null) {
        await CloudSyncService.instance.signInAnonymously();
      }
    } catch (_) {}
  }

  Future<void> _reloadLeaderboard() async {
    await _ensureLeaderboardAccess();
    if (!mounted) return;
    setState(() {
      _previousChampionFuture = LeaderboardService.instance.fetchPreviousDayChampion();
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final stream = _safeStreamForRange();

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: palette.background,
        foregroundColor: onSurface,
        title: Text(
          AppTexts.get('leaderboard_open'),
          style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: StreamBuilder<List<LeaderboardEntry>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildLeaderboardErrorState(onSurface, snapshot.error);
            }
            final data = snapshot.data ?? const <LeaderboardEntry>[];
            if (snapshot.hasData && data.isNotEmpty) {
              _syncPresenceForEntries(data);
            }
            final meUid = CloudSyncService.instance.user.value?.uid;
            final myIndex = meUid == null ? -1 : data.indexWhere((e) => e.uid == meUid);
            final myEntry = myIndex >= 0 ? data[myIndex] : null;
            final nextEntry = (myIndex > 0) ? data[myIndex - 1] : null;
            final pointsToNext = (myEntry == null || nextEntry == null)
                ? 0
                : max(0, nextEntry.points - myEntry.points + 1);
            final progressToNext = (myEntry == null || nextEntry == null || nextEntry.points <= 0)
                ? 1.0
                : (myEntry.points / nextEntry.points).clamp(0.0, 1.0);

            return AnimatedOpacity(
              duration: const Duration(milliseconds: 340),
              curve: Curves.easeOutCubic,
              opacity: _entered ? 1 : 0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 340),
                curve: Curves.easeOutCubic,
                offset: _entered ? Offset.zero : const Offset(0, 0.025),
                child: Column(
                  children: [
                    _buildRangeTabs(onSurface),
                    const SizedBox(height: 12),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 360),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          final slide = Tween<Offset>(
                            begin: const Offset(0.03, 0),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(position: slide, child: child),
                          );
                        },
                        child: Column(
                          key: ValueKey(_range),
                          children: [
                            if (_range == _LeaderboardRange.day) ...[
                              _buildPreviousChampionCard(onSurface),
                              const SizedBox(height: 12),
                            ],
                            if (data.isNotEmpty)
                              _buildPodium(
                                data.take(3).toList(growable: false),
                                onSurface,
                                isOnlineFor: _isOnline,
                              ),
                            if (data.isEmpty)
                              Expanded(
                                child: Center(
                                  child: Text(
                                    AppTexts.get('leaderboard_empty'),
                                    style: TextStyle(color: onSurface.withOpacity(0.45), fontSize: 12),
                                  ),
                                ),
                              )
                            else ...[
                              const SizedBox(height: 12),
                              _buildYourRankCard(
                                onSurface,
                                myIndex: myIndex,
                                myEntry: myEntry,
                                pointsToNext: pointsToNext,
                                progressToNext: progressToNext,
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: data.length,
                                  itemBuilder: (context, index) {
                                    final row = data[index];
                                    return _LeaderboardRow(
                                      rank: index + 1,
                                      entry: row,
                                      isMe: row.uid == meUid,
                                      isOnline: _isOnline(row),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PublicUserProfileScreen(
                                              uid: row.uid,
                                              fallbackName: row.displayName,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Stream<List<LeaderboardEntry>> _safeStreamForRange() {
    try {
      return switch (_range) {
        _LeaderboardRange.day =>
          LeaderboardService.instance.watchDailyTop(limit: 50),
        _LeaderboardRange.week =>
          LeaderboardService.instance.watchWeeklyTop(limit: 50),
        _LeaderboardRange.allTime =>
          LeaderboardService.instance.watchAllTimeTop(limit: 50),
      };
    } catch (e) {
      CloudSyncService.instance.lastError.value = e.toString();
      return const Stream<List<LeaderboardEntry>>.empty();
    }
  }

  Widget _buildLeaderboardErrorState(Color onSurface, Object? error) {
    final errorText = switch (appLanguage.value) {
      AppLanguage.ru =>
        '?? ??????? ????????? ??????? ???????. ??????? ????????, ???? ? ??????? ? ??????? Firestore.',
      AppLanguage.en =>
        'Failed to load leaderboard. Check internet, account sign-in, and Firestore rules.',
      AppLanguage.de =>
        'Bestenliste konnte nicht geladen werden. Pr�fe Internet, Anmeldung und Firestore-Regeln.',
    };
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: appPalette.value.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: appPalette.value.border.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              errorText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: onSurface.withOpacity(0.78),
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              (error ?? '').toString(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: onSurface.withOpacity(0.5),
                fontSize: 10.5,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 34,
              child: FilledButton.tonal(
                onPressed: _reloadLeaderboard,
                child: Text(
                  switch (appLanguage.value) {
                    AppLanguage.ru => '?????????',
                    AppLanguage.de => 'Erneut laden',
                    AppLanguage.en => 'Retry',
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeTabs(Color onSurface) {
    Widget tab(String label, _LeaderboardRange value) {
      final active = _range == value;
      return Expanded(
        child: _TapScale(
          onTap: () {
            setState(() {
              _range = value;
              if (value == _LeaderboardRange.day) {
                _previousChampionFuture = LeaderboardService.instance.fetchPreviousDayChampion();
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: active
                  ? LinearGradient(
                      colors: [
                        appAccentColor.value.withOpacity(0.28),
                        const Color(0xFF52C8FF).withOpacity(0.22),
                      ],
                    )
                  : null,
              color: active ? null : appPalette.value.surface,
              border: Border.all(
                color: active
                    ? appAccentColor.value.withOpacity(0.5)
                    : appPalette.value.border.withOpacity(0.35),
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: const Color(0xFF52C8FF).withOpacity(0.16),
                        blurRadius: 18,
                        spreadRadius: 0.3,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: onSurface.withOpacity(active ? 0.96 : 0.6),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.9,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tab('Day', _LeaderboardRange.day),
        const SizedBox(width: 8),
        tab('Week', _LeaderboardRange.week),
        const SizedBox(width: 8),
        tab('All-time', _LeaderboardRange.allTime),
      ],
    );
  }

  Widget _buildPodium(
    List<LeaderboardEntry> top,
    Color onSurface, {
    required bool Function(LeaderboardEntry entry) isOnlineFor,
  }) {
    final accentHsl = HSLColor.fromColor(appAccentColor.value);
    Color podiumColor(int place) {
      if (place == 1) {
        return accentHsl.withLightness((accentHsl.lightness + 0.16).clamp(0.0, 1.0)).toColor();
      }
      if (place == 2) {
        return accentHsl.withLightness((accentHsl.lightness + 0.07).clamp(0.0, 1.0)).toColor();
      }
      return accentHsl.withLightness((accentHsl.lightness - 0.04).clamp(0.0, 1.0)).toColor();
    }

    Widget podiumCard({
      required int place,
      required LeaderboardEntry entry,
      required double height,
      required bool highlight,
    }) {
      final base = podiumColor(place);
      return Expanded(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.94, end: 1),
          duration: Duration(milliseconds: 420 + place * 80),
          curve: Curves.easeOutBack,
          builder: (context, v, child) => Transform.scale(scale: v, child: child),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  base.withOpacity(highlight ? 0.35 : 0.24),
                  appPalette.value.surface.withOpacity(0.92),
                ],
              ),
              border: Border.all(color: base.withOpacity(highlight ? 0.6 : 0.42)),
              boxShadow: highlight
                  ? [
                      BoxShadow(
                        color: base.withOpacity(0.34),
                        blurRadius: 24,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _LeaderboardAvatar(
                  entry: entry,
                  size: highlight ? 40 : 34,
                  place: place,
                  isOnline: isOnlineFor(entry),
                ),
                const SizedBox(height: 8),
                _LeaderboardNameRow(
                  name: entry.displayName,
                  onSurface: onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  center: true,
                ),
                const SizedBox(height: 4),
                _AnimatedScoreText(
                  value: entry.points,
                  style: TextStyle(
                    color: base.withOpacity(0.95),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final first = top.isNotEmpty ? top[0] : const LeaderboardEntry(uid: '-', displayName: '-', points: 0);
    final second = top.length > 1 ? top[1] : const LeaderboardEntry(uid: '-', displayName: '-', points: 0);
    final third = top.length > 2 ? top[2] : const LeaderboardEntry(uid: '-', displayName: '-', points: 0);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      decoration: BoxDecoration(
        color: appPalette.value.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appPalette.value.border.withOpacity(0.42)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          podiumCard(place: 2, entry: second, height: 130, highlight: false),
          podiumCard(place: 1, entry: first, height: 158, highlight: true),
          podiumCard(place: 3, entry: third, height: 118, highlight: false),
        ],
      ),
    );
  }

  Widget _buildYourRankCard(
    Color onSurface, {
    required int myIndex,
    required LeaderboardEntry? myEntry,
    required int pointsToNext,
    required double progressToNext,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: appPalette.value.surface.withOpacity(0.9),
        border: Border.all(color: appAccentColor.value.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: appAccentColor.value.withOpacity(0.16),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your rank',
            style: TextStyle(
              color: onSurface.withOpacity(0.7),
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Text(
                myIndex >= 0 ? '#${myIndex + 1}' : '--',
                style: TextStyle(
                  color: onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(width: 10),
              if (myEntry != null) ...[
                _LeaderboardAvatar(
                  entry: myEntry,
                  size: 34,
                  isOnline: myEntry != null && _isOnline(myEntry),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: _LeaderboardNameRow(
                  name: myEntry?.displayName ?? 'Not ranked yet',
                  onSurface: onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _AnimatedScoreText(
                value: myEntry?.points ?? 0,
                style: TextStyle(
                  color: appAccentColor.value,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressToNext,
              minHeight: 6,
              backgroundColor: onSurface.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation(const Color(0xFF52C8FF).withOpacity(0.9)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            (myIndex <= 0 || myEntry == null)
                ? 'You are at the top'
                : '$pointsToNext points to reach next position',
            style: TextStyle(color: onSurface.withOpacity(0.55), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousChampionCard(Color onSurface) {
    return FutureBuilder<LeaderboardEntry?>(
      future: _previousChampionFuture,
      builder: (context, snapshot) {
        final champion = snapshot.data;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: Container(
            key: ValueKey(champion?.uid ?? 'none'),
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  appAccentColor.value.withOpacity(0.16),
                  const Color(0xFF52C8FF).withOpacity(0.12),
                ],
              ),
              border: Border.all(color: appAccentColor.value.withOpacity(0.38)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF52C8FF).withOpacity(0.12),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                    border: Border.all(color: appAccentColor.value.withOpacity(0.5)),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, size: 16, color: Color(0xFF52C8FF)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    champion == null
                        ? AppTexts.get('leaderboard_prev_champion_none')
                        : AppTexts.get(
                            'leaderboard_prev_champion',
                            params: {
                              'name': champion.displayName,
                              'points': champion.points.toString(),
                            },
                          ),
                    style: TextStyle(
                      color: onSurface.withOpacity(0.86),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LeaderboardAvatar extends StatelessWidget {
  final LeaderboardEntry entry;
  final double size;
  final int? place;
  final bool isOnline;

  const _LeaderboardAvatar({
    required this.entry,
    required this.size,
    this.place,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = appAccentColor.value;
    final bytes = CloudSyncService.decodePublicAvatarBytes(
      photoData: entry.photoData,
      photoUrl: entry.photoUrl,
    );
    final httpPhoto = CloudSyncService.resolveHttpAvatarUrl(entry.photoUrl);
    final trimmed = entry.displayName.trim();
    final initial = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';

    Widget avatarContent;
    if (bytes != null) {
      avatarContent = Image.memory(
        bytes,
        key: ValueKey('lb-avatar-${entry.uid}'),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => _initialFallback(initial, onSurface),
      );
    } else if (httpPhoto.isNotEmpty) {
      avatarContent = Image.network(
        httpPhoto,
        key: ValueKey('lb-avatar-${entry.uid}'),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => _initialFallback(initial, onSurface),
      );
    } else {
      avatarContent = _initialFallback(initial, onSurface);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.12),
              border: Border.all(color: onSurface.withOpacity(0.14)),
            ),
            clipBehavior: Clip.antiAlias,
            child: avatarContent,
          ),
          if (place != null)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: appPalette.value.surface,
                  border: Border.all(color: accent.withOpacity(0.55)),
                ),
                child: Center(
                  child: Text(
                    '$place',
                    style: TextStyle(
                      color: onSurface.withOpacity(0.9),
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
            ),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4CD964),
                  border: Border.all(
                    color: appPalette.value.surface,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CD964).withOpacity(0.45),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _initialFallback(String initial, Color onSurface) {
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: onSurface.withOpacity(0.82),
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}

class _LeaderboardNameRow extends StatelessWidget {
  final String name;
  final Color onSurface;
  final double fontSize;
  final FontWeight fontWeight;
  final bool center;

  const _LeaderboardNameRow({
    required this.name,
    required this.onSurface,
    required this.fontSize,
    required this.fontWeight,
    this.center = false,
  });

  @override
  Widget build(BuildContext context) {
    final nameText = Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        color: onSurface.withOpacity(0.9),
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );

    if (center) {
      return Center(child: nameText);
    }
    return nameText;
  }
}

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final bool isMe;
  final bool isOnline;
  final VoidCallback? onTap;

  const _LeaderboardRow({
    required this.rank,
    required this.entry,
    required this.isMe,
    required this.isOnline,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = appAccentColor.value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: _TapScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isMe ? accent.withOpacity(0.12) : appPalette.value.surface.withOpacity(0.7),
            border: Border.all(
              color: isMe ? accent.withOpacity(0.5) : appPalette.value.border.withOpacity(0.25),
            ),
            boxShadow: isMe
                ? [
                    BoxShadow(
                      color: accent.withOpacity(0.18),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 26,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    color: rank <= 3 ? const Color(0xFF52C8FF) : onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _LeaderboardAvatar(
                entry: entry,
                size: 36,
                isOnline: isOnline,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LeaderboardNameRow(
                  name: entry.displayName,
                  onSurface: isMe ? accent : onSurface,
                  fontSize: 14,
                  fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              _AnimatedScoreText(
                value: entry.points,
                style: TextStyle(
                  color: onSurface.withOpacity(0.95),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

