import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../audio/app_background_music.dart';
import '../../cloud/cloud_sync_service.dart';
import '../../cloud/presence_service.dart';
import '../../news/news_service.dart';
import '../../notifications/creator_broadcast_inbox_service.dart';
import '../../recovered_app.dart' show initializeFirebaseSafely;
import 'app_lifecycle_music.dart';

/// Keeps community news unread state in sync while the user is signed in.
class AppOnlineServicesHost extends StatefulWidget {
  const AppOnlineServicesHost({super.key, required this.child});

  final Widget child;

  @override
  State<AppOnlineServicesHost> createState() => _AppOnlineServicesHostState();
}

class _AppOnlineServicesHostState extends State<AppOnlineServicesHost> {
  @override
  void initState() {
    super.initState();
    unawaited(_startOnlineServices());
    unawaited(AppBackgroundMusic.instance.init());
  }

  Future<void> _startOnlineServices() async {
    // Web build was experimental; mobile uses native Firebase (google-services.json).
    if (kIsWeb) return;
    final ready = await initializeFirebaseSafely();
    if (!ready) return;
    if (!CloudSyncService.instance.firebaseReady) {
      try {
        await CloudSyncService.instance.init(firebaseReady: true);
      } catch (_) {
        return;
      }
    }
    if (!mounted) return;
    NewsService.instance.startWatching();
    PresenceService.instance.startHeartbeat();
    CreatorBroadcastInboxService.instance.bindAuth();
  }

  @override
  void dispose() {
    NewsService.instance.stopWatching();
    PresenceService.instance.stopHeartbeat();
    CreatorBroadcastInboxService.instance.unbindAuth();
    // Background music is an app-level singleton; do not stop it when this host
    // rebuilds (e.g. auth transitions). It is prepared in main() and paused only
    // for training or when the user disables melody in settings.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLifecycleMusic(child: widget.child);
  }
}
