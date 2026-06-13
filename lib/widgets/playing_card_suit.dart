import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Standard French-suited deck colors; black suits follow app accent unless forced white in settings.
const Color kPlayingCardRedSuit = Color(0xFFFF3B30);

double _relativeLuminance(Color c) {
  double lin(double channel) {
    final v = channel / 255.0;
    return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = lin(c.red.toDouble());
  final g = lin(c.green.toDouble());
  final b = lin(c.blue.toDouble());
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double suitContrastRatio(Color a, Color b) {
  final l1 = _relativeLuminance(a);
  final l2 = _relativeLuminance(b);
  final lighter = max(l1, l2);
  final darker = min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

/// First character must be suit letter [h,d,c,s]; ranks may be multi-char ('10').
String? parsePlayingCardSuitLetter(String code) {
  if (code.isEmpty) return null;
  switch (code[0].toLowerCase()) {
    case 'h':
    case 'd':
    case 'c':
    case 's':
      return code[0].toLowerCase();
    default:
      return null;
  }
}

String playingCardSuitAsset(String suitLetter) {
  switch (suitLetter) {
    case 'h':
      return 'assets/cards/suits/heart.svg';
    case 'd':
      return 'assets/cards/suits/diamond.svg';
    case 'c':
      return 'assets/cards/suits/club.svg';
    case 's':
    default:
      return 'assets/cards/suits/spade.svg';
  }
}

Color semanticPlayingCardSuitColor({
  required String suitLetter,
  required Color accent,
  required bool blackSuitsWhite,
}) {
  final isRed = suitLetter == 'h' || suitLetter == 'd';
  if (isRed) return kPlayingCardRedSuit;
  return blackSuitsWhite ? Colors.white : accent;
}

/// Keeps corner ranks readable when white suits sit on a light card or accent blends into [bg].
List<Shadow> playingCardGlyphShadows(Color fg, Color bg,
    {double minContrast = 2.65}) {
  final soft = Shadow(color: Colors.black.withOpacity(0.35), blurRadius: 3);
  if (suitContrastRatio(fg, bg) >= minContrast) {
    return [soft];
  }
  final rim = bg.computeLuminance() > 0.52 ? Colors.black54 : Colors.white70;
  return [
    Shadow(
        color: rim.withOpacity(0.92),
        blurRadius: 2,
        offset: const Offset(0, 0.5)),
    soft,
  ];
}

/// Twemoji SVG paths with runtime tint ([ColorFilter.mode]). Adds a subtle rim when the fill would disappear on the card face.
class PlayingCardSuitIcon extends StatelessWidget {
  const PlayingCardSuitIcon({
    super.key,
    required this.suitLetter,
    required this.color,
    required this.size,
    required this.cardSurfaceColor,
    this.minContrast = 2.65,
  });

  final String suitLetter;
  final Color color;
  final double size;
  final Color cardSurfaceColor;
  final double minContrast;

  @override
  Widget build(BuildContext context) {
    final asset = playingCardSuitAsset(suitLetter);
    final front = SvgPicture.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );

    if (suitContrastRatio(color, cardSurfaceColor) >= minContrast) {
      return front;
    }

    final rim = cardSurfaceColor.computeLuminance() > 0.52
        ? const Color(0xFF242424)
        : Colors.white;
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Transform.scale(
          scale: 1.12,
          child: SvgPicture.asset(
            asset,
            width: size,
            height: size,
            fit: BoxFit.contain,
            colorFilter:
                ColorFilter.mode(rim.withOpacity(0.42), BlendMode.srcIn),
          ),
        ),
        front,
      ],
    );
  }
}
