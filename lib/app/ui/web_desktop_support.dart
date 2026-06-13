part of 'package:flutter_application_1/recovered_app.dart';

/// Платформы, где ожидается физическая клавиатура (веб на ноутбуке, десктоп).
bool trainerKeyboardShortcutsEnabled(BuildContext context) {
  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux) {
    return true;
  }
  if (kIsWeb) {
    return MediaQuery.sizeOf(context).width >= 600;
  }
  return false;
}

bool trainerShortcutBlockedByTextField() {
  final focus = FocusManager.instance.primaryFocus;
  final ctx = focus?.context;
  if (ctx == null) return false;
  return ctx.findAncestorWidgetOfExactType<EditableText>() != null;
}

double webDesktopContentMaxWidth(
  BuildContext context, {
  double narrow = 480,
  double medium = 640,
  double wide = 880,
}) {
  final isWidePlatform = kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;
  if (!isWidePlatform) return double.infinity;
  final w = MediaQuery.sizeOf(context).width;
  if (w < 600) return narrow;
  if (w < 1024) return medium;
  return wide;
}

Widget webDesktopFrame({
  required BuildContext context,
  required Widget child,
  double? maxWidth,
}) {
  final cap = maxWidth ?? webDesktopContentMaxWidth(context);
  final isWidePlatform = kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;
  if (!isWidePlatform) return child;
  return Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: cap),
      child: child,
    ),
  );
}

String trainerKeyboardHintText({
  required bool settings,
  required bool memorizing,
}) {
  if (settings) {
    return AppTexts.translate(const {
      AppLanguage.ru: 'Пробел или Enter — начать тренировку',
      AppLanguage.en: 'Space or Enter — start training',
      AppLanguage.de: 'Leertaste oder Enter — Training starten',
    });
  }
  if (memorizing) {
    return AppTexts.translate(const {
      AppLanguage.ru: '← → чанки · ↑ ↓ прокрутка · Home — в начало · Пробел — вспоминание',
      AppLanguage.en: '← → chunks · ↑ ↓ scroll · Home — first · Space — recall',
      AppLanguage.de: '← → Chunks · ↑ ↓ scrollen · Pos1 — Anfang · Leertaste — Abruf',
    });
  }
  return '';
}

Widget trainerKeyboardHintBar(BuildContext context, {required String text}) {
  if (text.isEmpty) return const SizedBox.shrink();
  final onSurface = Theme.of(context).colorScheme.onSurface;
  return SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: onSurface.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: onSurface.withOpacity(0.1)),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: onSurface.withOpacity(0.45),
              fontSize: 11,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    ),
  );
}

({double width, double height, double cellFont, double headerFont}) matrixGridMetrics(
  double maxWidth, {
  double baseWidth = 320,
  double baseHeight = 360,
}) {
  final width = min(max(baseWidth, maxWidth * 0.92), 480.0);
  final scale = width / baseWidth;
  return (
    width: width,
    height: baseHeight * scale,
    cellFont: 16 * scale,
    headerFont: 32 * scale,
  );
}

bool handleTrainerStartKeyDown(KeyDownEvent event) {
  if (trainerShortcutBlockedByTextField()) return false;
  return event.logicalKey == LogicalKeyboardKey.space ||
      event.logicalKey == LogicalKeyboardKey.enter ||
      event.logicalKey == LogicalKeyboardKey.numpadEnter;
}

bool handleTrainerMemorizeKeyDown({
  required KeyDownEvent event,
  required VoidCallback onNext,
  required VoidCallback onPrev,
  required VoidCallback onFirst,
  required VoidCallback onRecallNow,
  ScrollController? scrollController,
}) {
  final key = event.logicalKey;
  if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.pageDown) {
    onNext();
    return true;
  }
  if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.pageUp) {
    onPrev();
    return true;
  }
  if (key == LogicalKeyboardKey.home) {
    onFirst();
    return true;
  }
  if (key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.numpadEnter ||
      key == LogicalKeyboardKey.space) {
    onRecallNow();
    return true;
  }
  if (scrollController != null && scrollController.hasClients) {
    if (key == LogicalKeyboardKey.arrowDown) {
      final target = (scrollController.offset + 72).clamp(
        0.0,
        scrollController.position.maxScrollExtent,
      );
      scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
      return true;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      final target = (scrollController.offset - 72).clamp(
        0.0,
        scrollController.position.maxScrollExtent,
      );
      scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
      return true;
    }
  }
  return false;
}
