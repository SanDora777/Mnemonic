part of 'package:flutter_application_1/recovered_app.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, _, __) {
        final palette = appPalette.value;
        final onSurface = Theme.of(context).colorScheme.onSurface;
        return Scaffold(
          backgroundColor: palette.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurface.withOpacity(0.6), size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(AppTexts.get('language'),
              style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 3)),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: Column(
                key: ValueKey(appLanguage.value),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLanguageOption(context, 'Русский', AppLanguage.ru),
                  const SizedBox(height: 12),
                  _buildLanguageOption(context, 'English', AppLanguage.en),
                  const SizedBox(height: 12),
                  _buildLanguageOption(context, 'Deutsch', AppLanguage.de),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(BuildContext context, String label, AppLanguage lang) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isSelected = appLanguage.value == lang;

    return GestureDetector(
      onTap: () async {
        uiTapClick(UiClickSound.soft);
        if (appLanguage.value == lang) return;
        appLanguage.value = lang;
        await persistLanguage(lang);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? appAccentColor.value.withOpacity(0.1) : palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? appAccentColor.value : palette.border.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(color: onSurface, fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.w300)),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle_rounded, color: appAccentColor.value, size: 20),
          ],
        ),
      ),
    );
  }
}

// --- ЭКРАН СТАТИСТИКИ ---
