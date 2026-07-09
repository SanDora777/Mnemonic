import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Smooth, inertial scroll on Flutter Web desktop (mouse wheel + trackpad).
class WebDesktopScrollBehavior extends MaterialScrollBehavior {
  const WebDesktopScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    if (kIsWeb && MediaQuery.sizeOf(context).width >= 520) {
      return const WebSmoothScrollPhysics();
    }
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}

/// Bouncy inertia tuned for laptop trackpads and mouse wheels on web.
class WebSmoothScrollPhysics extends BouncingScrollPhysics {
  const WebSmoothScrollPhysics({super.parent});

  @override
  WebSmoothScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return WebSmoothScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 0.35,
        stiffness: 110,
        damping: 18,
      );

  @override
  double get dragStartDistanceMotionThreshold => 3.5;

  @override
  double get minFlingVelocity => 25;
}
