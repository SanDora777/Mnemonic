import 'package:flutter/material.dart';

import '../recovered_app.dart'
    show
        AppLanguage,
        AppPalette,
        appAccentColor,
        appPalette,
        blackSuitAlwaysWhite;
import '../widgets/playing_card_suit.dart';

/// Animated playing-card face used in the card codes editor and trainer.
class PlayingCardFace extends StatelessWidget {
  const PlayingCardFace({
    super.key,
    required this.cardCode,
    this.width = 120,
    this.height = 168,
    this.elevated = true,
    this.animateIn = false,
  });

  final String cardCode;
  final double width;
  final double height;
  final bool elevated;
  final bool animateIn;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable:
          Listenable.merge([blackSuitAlwaysWhite, appAccentColor, appPalette]),
      builder: (context, _) {
        final palette = appPalette.value;
        final card = _buildCardBody(palette);
        if (!animateIn) return card;
        return TweenAnimationBuilder<double>(
          key: ValueKey(cardCode),
          tween: Tween(begin: 0.86, end: 1.0),
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: card,
        );
      },
    );
  }

  Widget _buildCardBody(AppPalette palette) {
    final suitLetter = parsePlayingCardSuitLetter(cardCode);
    if (suitLetter == null) {
      return _cardShell(
        palette: palette,
        child: Icon(
          Icons.style_outlined,
          size: width * 0.32,
          color: Colors.black26,
        ),
      );
    }

    final rank = CardCodesDeckDisplay.rankLabel(cardCode);
    final suitColor = semanticPlayingCardSuitColor(
      suitLetter: suitLetter,
      accent: appAccentColor.value,
      blackSuitsWhite: blackSuitAlwaysWhite.value,
    );
    final glyphShadows = playingCardGlyphShadows(suitColor, palette.surface);
    final rankStyle = TextStyle(
      color: suitColor,
      fontSize: width * 0.2,
      fontWeight: FontWeight.w800,
      height: 1,
      shadows: glyphShadows,
    );
    final cornerSuit = width * 0.16;

    return _cardShell(
      palette: palette,
      child: Stack(
        children: [
          Center(
            child: Opacity(
              opacity: 0.18,
              child: PlayingCardSuitIcon(
                suitLetter: suitLetter,
                color: suitColor,
                size: width * 0.72,
                cardSurfaceColor: palette.surface,
              ),
            ),
          ),
          Positioned(
            top: height * 0.08,
            left: width * 0.1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rank, style: rankStyle),
                SizedBox(height: height * 0.012),
                PlayingCardSuitIcon(
                  suitLetter: suitLetter,
                  color: suitColor,
                  size: cornerSuit,
                  cardSurfaceColor: palette.surface,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: height * 0.08,
            right: width * 0.1,
            child: RotatedBox(
              quarterTurns: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rank, style: rankStyle),
                  SizedBox(height: height * 0.012),
                  PlayingCardSuitIcon(
                    suitLetter: suitLetter,
                    color: suitColor,
                    size: cornerSuit,
                    cardSurfaceColor: palette.surface,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardShell({required AppPalette palette, required Widget child}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(width * 0.14),
        border: Border.all(color: palette.border.withOpacity(0.42), width: 1.4),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.14),
                  blurRadius: width * 0.12,
                  offset: Offset(0, width * 0.06),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// Localized labels for suits and ranks.
class CardCodesDeckDisplay {
  static String rankLabel(String code) =>
      code.length > 1 ? code.substring(1).toUpperCase() : '';

  static String suitLabel(String suit, AppLanguage lang) {
    switch (suit) {
      case 'h':
        return switch (lang) {
          AppLanguage.en => 'Hearts',
          AppLanguage.de => 'Herz',
          _ => 'Черви',
        };
      case 'd':
        return switch (lang) {
          AppLanguage.en => 'Diamonds',
          AppLanguage.de => 'Karo',
          _ => 'Бубны',
        };
      case 'c':
        return switch (lang) {
          AppLanguage.en => 'Clubs',
          AppLanguage.de => 'Kreuz',
          _ => 'Трефы',
        };
      case 's':
      default:
        return switch (lang) {
          AppLanguage.en => 'Spades',
          AppLanguage.de => 'Pik',
          _ => 'Пики',
        };
    }
  }

  static String suitGlyph(String suit) {
    switch (suit) {
      case 'h':
        return '♥';
      case 'd':
        return '♦';
      case 'c':
        return '♣';
      case 's':
      default:
        return '♠';
    }
  }
}
