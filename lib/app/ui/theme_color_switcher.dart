part of 'package:flutter_application_1/recovered_app.dart';

class ThemeColorSwitcher extends StatefulWidget {
  const ThemeColorSwitcher({super.key, this.initialExpanded = true});

  final bool initialExpanded;

  @override
  State<ThemeColorSwitcher> createState() => _ThemeColorSwitcherState();
}

class _ThemeColorSwitcherState extends State<ThemeColorSwitcher> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppPalette>(
      valueListenable: appPalette,
      builder: (context, currentPalette, _) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openThemePicker(context, currentPalette),
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
                Icons.palette_outlined,
                size: 18,
                color: currentPalette.accent,
              ),
            ),
          ),
        );
      },
    );
  }

  void _openThemePicker(BuildContext context, AppPalette currentPalette) {
    uiTapClick(UiClickSound.deep);
    paletteCollapseSignal.value++;

    final darkPalettes = <(int index, AppPalette palette)>[];
    final lightPalettes = <(int index, AppPalette palette)>[];
    for (int i = 0; i < appPalettes.length; i++) {
      final palette = appPalettes[i];
      if (palette.background.computeLuminance() > 0.5) {
        lightPalettes.add((i, palette));
      } else {
        darkPalettes.add((i, palette));
      }
    }

    final currentIndex = appPalettes.indexWhere(
      (p) =>
          p.accent == currentPalette.accent &&
          p.background == currentPalette.background,
    );

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final palette = appPalette.value;
        final onSurface = Theme.of(sheetContext).colorScheme.onSurface;
        return Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: palette.border.withOpacity(0.55)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: palette.border.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Text(
                  AppTexts.translate(const {
                    AppLanguage.ru: 'Тема оформления',
                    AppLanguage.en: 'Theme',
                    AppLanguage.de: 'Design',
                  }),
                  style: TextStyle(
                    color: onSurface.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 16),
                _themeSectionTitle(
                  onSurface,
                  AppTexts.translate(const {
                    AppLanguage.ru: 'Тёмные',
                    AppLanguage.en: 'Dark',
                    AppLanguage.de: 'Dunkel',
                  }),
                ),
                const SizedBox(height: 10),
                _themeGrid(
                  sheetContext,
                  darkPalettes,
                  currentIndex,
                  onSurface,
                ),
                const SizedBox(height: 18),
                _themeSectionTitle(
                  onSurface,
                  AppTexts.translate(const {
                    AppLanguage.ru: 'Светлые',
                    AppLanguage.en: 'Light',
                    AppLanguage.de: 'Hell',
                  }),
                ),
                const SizedBox(height: 10),
                _themeGrid(
                  sheetContext,
                  lightPalettes,
                  currentIndex,
                  onSurface,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _themeSectionTitle(Color onSurface, String label) {
    return Text(
      label,
      style: TextStyle(
        color: onSurface.withOpacity(0.45),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
      ),
    );
  }

  Widget _themeGrid(
    BuildContext context,
    List<(int index, AppPalette palette)> items,
    int currentIndex,
    Color onSurface,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((entry) {
        final index = entry.$1;
        final palette = entry.$2;
        final isActive = index == currentIndex;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              uiTapClick(UiClickSound.soft);
              schedulePaletteChange(palette);
              persistPaletteIndex(index);
              Navigator.of(context).pop();
            },
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: isActive ? 40 : 32,
                  height: isActive ? 40 : 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.background,
                    border: Border.all(
                      color: isActive ? palette.accent : palette.border,
                      width: isActive ? 2.5 : 1.2,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: palette.accent.withOpacity(0.45),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Container(
                      width: isActive ? 18 : 14,
                      height: isActive ? 18 : 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: palette.accent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

// --- ГЛАВНОЕ МЕНЮ ---
