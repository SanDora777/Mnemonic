part of 'package:flutter_application_1/recovered_app.dart';

class ThemeColorSwitcher extends StatefulWidget {
  const ThemeColorSwitcher({super.key, this.initialExpanded = true});

  final bool initialExpanded;

  @override
  State<ThemeColorSwitcher> createState() => _ThemeColorSwitcherState();
}

class _ThemeColorSwitcherState extends State<ThemeColorSwitcher> {
  late bool _isExpanded;
  late final VoidCallback _collapseListener;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
    _collapseListener = () {
      if (_isExpanded && mounted) {
        setState(() => _isExpanded = false);
      }
    };
    paletteCollapseSignal.addListener(_collapseListener);
  }

  @override
  void dispose() {
    paletteCollapseSignal.removeListener(_collapseListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppPalette>(
      valueListenable: appPalette,
      builder: (context, currentPalette, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: currentPalette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: currentPalette.accent.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl, // Расширение влево
            children: [
              _buildPaletteButton(currentPalette),
              Flexible(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: _isExpanded
                      ? ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              textDirection: TextDirection.ltr, // Точки внутри в обычном порядке
                              children: [
                                const SizedBox(width: 8),
                                ...appPalettes.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final palette = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 5),
                                    child: _buildColorDot(idx, palette, currentPalette),
                                  );
                                }),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaletteButton(AppPalette currentPalette) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          uiTapClick(UiClickSound.deep);
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: currentPalette.accent.withOpacity(0.22),
            shape: BoxShape.circle,
            border: Border.all(color: currentPalette.accent, width: 1.4),
          ),
          child: Icon(
            _isExpanded ? Icons.close_rounded : Icons.palette_outlined,
            size: 18,
            color: currentPalette.accent,
          ),
        ),
      ),
    );
  }

  Widget _buildColorDot(int index, AppPalette palette, AppPalette currentPalette) {
    final currentIndex = appPalettes.indexWhere(
      (p) => p.accent == currentPalette.accent && p.background == currentPalette.background,
    );
    final isActive = index == currentIndex;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          uiTapClick(UiClickSound.soft);
          schedulePaletteChange(palette);
          persistPaletteIndex(index);
          setState(() => _isExpanded = false);
        },
        customBorder: const CircleBorder(),
        splashColor: palette.accent.withOpacity(0.22),
        highlightColor: palette.accent.withOpacity(0.12),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: isActive ? 30 : 14,
              height: isActive ? 30 : 14,
              decoration: BoxDecoration(
                color: palette.accent,
                shape: BoxShape.circle,
                border: isActive ? Border.all(color: palette.accent, width: 2) : null,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: palette.accent.withOpacity(0.55),
                          blurRadius: 10,
                          spreadRadius: 1.2,
                        ),
                      ]
                    : [],
              ),
              child: isActive
                  ? Center(
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: palette.background,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

// --- ГЛАВНОЕ МЕНЮ ---
