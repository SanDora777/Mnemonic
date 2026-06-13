import 'package:flutter/widgets.dart';

import '../../audio/app_background_music.dart';

/// Pauses background music when the app goes to background.
class AppLifecycleMusic extends StatefulWidget {
  const AppLifecycleMusic({super.key, required this.child});

  final Widget child;

  @override
  State<AppLifecycleMusic> createState() => _AppLifecycleMusicState();
}

class _AppLifecycleMusicState extends State<AppLifecycleMusic> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        AppBackgroundMusic.instance.onAppResumed();
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        AppBackgroundMusic.instance.onAppPaused();
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
