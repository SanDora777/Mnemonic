part of 'package:flutter_application_1/recovered_app.dart';

/// Запрос плавной смены темы (без оверлея — цвета интерполируются на месте).
final ValueNotifier<AppPalette?> paletteChangeRequest = ValueNotifier<AppPalette?>(null);

void schedulePaletteChange(AppPalette palette) {
  paletteChangeRequest.value = palette;
}

/// Плавно смешивает текущую палитру в новую (~260 ms), без затемнения экрана.
class PaletteThemeTransition extends StatefulWidget {
  const PaletteThemeTransition({super.key, required this.child});

  final Widget child;

  @override
  State<PaletteThemeTransition> createState() => _PaletteThemeTransitionState();
}

class _PaletteThemeTransitionState extends State<PaletteThemeTransition>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 260);

  late final AnimationController _controller;
  late final Animation<double> _progress;
  late final VoidCallback _requestListener;
  late final VoidCallback _tickListener;

  AppPalette? _from;
  AppPalette? _to;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _requestListener = _onChangeRequest;
    _tickListener = _onTick;
    paletteChangeRequest.addListener(_requestListener);
    _progress.addListener(_tickListener);
    _controller.addStatusListener(_onAnimStatus);
  }

  @override
  void dispose() {
    paletteChangeRequest.removeListener(_requestListener);
    _progress.removeListener(_tickListener);
    _controller.removeStatusListener(_onAnimStatus);
    _controller.dispose();
    super.dispose();
  }

  bool _samePalette(AppPalette a, AppPalette b) =>
      a.accent == b.accent && a.background == b.background;

  void _onChangeRequest() {
    final target = paletteChangeRequest.value;
    if (target == null || !mounted) return;
    paletteChangeRequest.value = null;

    if (_samePalette(target, appPalette.value)) return;

    _from = appPalette.value;
    _to = target;
    _controller.forward(from: 0);
  }

  void _onTick() {
    final from = _from;
    final to = _to;
    if (from == null || to == null || !_controller.isAnimating) return;

    final blended = from.lerp(to, _progress.value);
    appPalette.value = blended;
    appAccentColor.value = blended.accent;
  }

  void _onAnimStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    final to = _to;
    if (to != null) {
      appPalette.value = to;
      appAccentColor.value = to.accent;
    }
    _from = null;
    _to = null;
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
