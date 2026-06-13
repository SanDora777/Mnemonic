part of 'package:flutter_application_1/recovered_app.dart';

class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _TapScale({required this.child, this.onTap});

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapCancel: () => setState(() => _scale = 1),
      onTapUp: (_) => setState(() => _scale = 1),
      onTap: widget.onTap == null
          ? null
          : () {
              uiTapClick(UiClickSound.soft);
              widget.onTap!();
            },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 110),
        scale: _scale,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _AnimatedScoreText extends StatefulWidget {
  final int value;
  final TextStyle style;

  const _AnimatedScoreText({
    required this.value,
    required this.style,
  });

  @override
  State<_AnimatedScoreText> createState() => _AnimatedScoreTextState();
}

class _AnimatedScoreTextState extends State<_AnimatedScoreText> {
  int _old = 0;

  @override
  void initState() {
    super.initState();
    _old = widget.value;
  }

  @override
  void didUpdateWidget(covariant _AnimatedScoreText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _old = oldWidget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _old.toDouble(), end: widget.value.toDouble()),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return Text(v.round().toString(), style: widget.style);
      },
    );
  }
}

// --- ВИДЖЕТ ПЕРЕКЛЮЧЕНИЯ ТЕМЫ ---
