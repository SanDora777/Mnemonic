part of 'package:flutter_application_1/recovered_app.dart';

class NumberImagesScreen extends StatelessWidget {
  const NumberImagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurface.withOpacity(0.6), size: 20), onPressed: () => Navigator.pop(context)),
        title: Text(AppTexts.get('number_images_labels_title'), style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 3)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildOptionCard(context, "0 - 9", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NumberImagesListScreen()))),
            const SizedBox(height: 16),
            _buildOptionCard(context, "00 - 99", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NumberPairCodesScreen()),
              );
            }),
            const SizedBox(height: 16),
            _buildOptionCard(context, "000 - 999", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NumberTripleCodesScreen()),
              );
            }),
            const SizedBox(height: 16),
            _buildOptionCard(context, AppTexts.get('card_codes_title'), () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CardCodesScreen()),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, String label, VoidCallback onTap) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: withUiTap(onTap, sound: UiClickSound.soft),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: palette.border.withOpacity(0.3))),
        child: Center(child: Text(label, style: TextStyle(color: onSurface, fontSize: 20, fontWeight: FontWeight.w200, letterSpacing: 4))),
      ),
    );
  }
}

class NumberImagesListScreen extends StatelessWidget {
  const NumberImagesListScreen({super.key});

  static const Map<AppLanguage, Map<int, String>> _imagesByLanguage = {
    AppLanguage.ru: {
      0: 'Яйцо',
      1: 'Свеча',
      2: 'Лебедь',
      3: 'Трезубец',
      4: 'Стул',
      5: 'Крючок',
      6: 'Шест',
      7: 'Коса',
      8: 'Очки',
      9: 'Воздушный шар',
    },
    AppLanguage.en: {
      0: 'Apple',
      1: 'Spear',
      2: 'Swan',
      3: 'Trident',
      4: 'Chair',
      5: 'Hook',
      6: 'Chest',
      7: 'Scythe',
      8: 'Glasses',
      9: 'Balloon',
    },
    AppLanguage.de: {
      0: 'Apfel',
      1: 'Speer',
      2: 'Schwan',
      3: 'Dreizack',
      4: 'Stuhl',
      5: 'Haken',
      6: 'Truhe',
      7: 'Sense',
      8: 'Brille',
      9: 'Luftballon',
    },
  };

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final language = appLanguage.value;
    final images = _imagesByLanguage[language] ?? _imagesByLanguage[AppLanguage.ru]!;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurface.withOpacity(0.6), size: 20), onPressed: () => Navigator.pop(context)),
        title: const Text("0 - 9", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 3)),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: 10,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: palette.border.withOpacity(0.2))),
            child: Row(
              children: [
                Text("$index", style: TextStyle(color: appAccentColor.value, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(width: 24),
                Text(images[index]!, style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.w300)),
              ],
            ),
          );
        },
      ),
    );
  }
}

