part of 'package:flutter_application_1/recovered_app.dart';

class AppPalette {
  final Color accent;
  final Color background;
  final Color surface;
  final Color card;
  final Color border;

  const AppPalette({
    required this.accent,
    required this.background,
    required this.surface,
    required this.card,
    required this.border,
  });

  AppPalette lerp(AppPalette other, double t) {
    final x = t.clamp(0.0, 1.0);
    Color blend(Color a, Color b) => Color.lerp(a, b, x)!;
    return AppPalette(
      accent: blend(accent, other.accent),
      background: blend(background, other.background),
      surface: blend(surface, other.surface),
      card: blend(card, other.card),
      border: blend(border, other.border),
    );
  }
}

const List<AppPalette> appPalettes = [
  // --- Dark: Neon ---
  AppPalette(
    // Neon Lime
    accent: Color(0xFFCCFF00),
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    card: Color(0xFF111111),
    border: Color(0xFF222222),
  ),
  AppPalette(
    // Electric Cyan
    accent: Color(0xFF49B8FF),
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    card: Color(0xFF111111),
    border: Color(0xFF222222),
  ),
  AppPalette(
    // Vivid Purple
    accent: Color(0xFFBF00FF),
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    card: Color(0xFF111111),
    border: Color(0xFF222222),
  ),
  AppPalette(
    // Neon Green
    accent: Color(0xFF00FF6A),
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    card: Color(0xFF111111),
    border: Color(0xFF222222),
  ),
  AppPalette(
    // Neon Red
    accent: Color(0xFFFF3B30),
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    card: Color(0xFF111111),
    border: Color(0xFF222222),
  ),
  AppPalette(
    // Blue
    accent: Color(0xFF2F80FF),
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    card: Color(0xFF111111),
    border: Color(0xFF222222),
  ),
  AppPalette(
    // Purple
    accent: Color(0xFF8B5CFF),
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    card: Color(0xFF111111),
    border: Color(0xFF222222),
  ),
  AppPalette(
    // Gold
    accent: Color(0xFFFFC94A),
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    card: Color(0xFF111111),
    border: Color(0xFF2A2312),
  ),
  // --- Dark: Minimal ---
  AppPalette(
    // Minimal Slate (Dark)
    accent: Color(0xFF7DA2FF),
    background: Color(0xFF0F1115),
    surface: Color(0xFF171A21),
    card: Color(0xFF1E232C),
    border: Color(0xFF2A303B),
  ),
  AppPalette(
    // Minimal Mint (Dark)
    accent: Color(0xFF5FD3B3),
    background: Color(0xFF0E1413),
    surface: Color(0xFF15201E),
    card: Color(0xFF1B2926),
    border: Color(0xFF2A3A36),
  ),
  // --- Dark: Signature ---
  AppPalette(
    // Aurora Mist — глубокий сине-бирюзовый
    accent: Color(0xFF5EEAD4),
    background: Color(0xFF081A1F),
    surface: Color(0xFF0C242B),
    card: Color(0xFF103033),
    border: Color(0xFF1A4550),
  ),
  AppPalette(
    // Velvet Wine — тёплый тёмный с розовым акцентом
    accent: Color(0xFFE879A9),
    background: Color(0xFF14081C),
    surface: Color(0xFF1C0E24),
    card: Color(0xFF251432),
    border: Color(0xFF3D2845),
  ),
  AppPalette(
    // Honey Ember — тёплый графит с янтарным акцентом
    accent: Color(0xFFF6B73C),
    background: Color(0xFF12100A),
    surface: Color(0xFF1C1810),
    card: Color(0xFF252016),
    border: Color(0xFF3A3428),
  ),
  // --- Light: Minimal ---
  AppPalette(
    // Minimal Fog (Light)
    accent: Color(0xFF3C5368),
    background: Color(0xFFF4F7FA),
    surface: Color(0xFFEAF0F5),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFC8D5E1),
  ),
  AppPalette(
    // Minimal Sand (Light)
    accent: Color(0xFF5C4636),
    background: Color(0xFFF8F4ED),
    surface: Color(0xFFF0E9DE),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFD6C8B7),
  ),
  AppPalette(
    // Minimal Pearl (Light)
    accent: Color(0xFF4A5A78),
    background: Color(0xFFF9FAFC),
    surface: Color(0xFFEEF2F7),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFD6DEE8),
  ),
  AppPalette(
    // Minimal Blush (Light)
    accent: Color(0xFF7A4F62),
    background: Color(0xFFFCF7F9),
    surface: Color(0xFFF4EAF0),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE3CEDA),
  ),
];

// Глобальные контроллеры темы
final ValueNotifier<AppPalette> appPalette = ValueNotifier(appPalettes.first);
final ValueNotifier<Color> appAccentColor = ValueNotifier(appPalettes.first.accent);
final ValueNotifier<int> paletteCollapseSignal = ValueNotifier(0);

