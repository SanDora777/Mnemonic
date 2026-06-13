import 'package:flutter/material.dart';

/// Maps Firestore icon names to [IconData] for academy lessons/sections.
class AcademyIconRegistry {
  AcademyIconRegistry._();

  static const IconData fallback = Icons.school_outlined;

  static final Map<String, IconData> _icons = <String, IconData>{
    'psychology_outlined': Icons.psychology_outlined,
    'psychology_alt_outlined': Icons.psychology_alt_outlined,
    'palette_outlined': Icons.palette_outlined,
    'link_rounded': Icons.link_rounded,
    'account_balance_outlined': Icons.account_balance_outlined,
    'calculate_outlined': Icons.calculate_outlined,
    'image_outlined': Icons.image_outlined,
    'style_rounded': Icons.style_rounded,
    'short_text_rounded': Icons.short_text_rounded,
    'translate_rounded': Icons.translate_rounded,
    'article_outlined': Icons.article_outlined,
    'speed_rounded': Icons.speed_rounded,
    'fitness_center_rounded': Icons.fitness_center_rounded,
    'emoji_events_outlined': Icons.emoji_events_outlined,
    'spa_outlined': Icons.spa_outlined,
    'auto_delete_outlined': Icons.auto_delete_outlined,
    'lightbulb_outline': Icons.lightbulb_outline,
    'memory_outlined': Icons.memory_outlined,
    'hub_outlined': Icons.hub_outlined,
    'extension_outlined': Icons.extension_outlined,
    'format_list_bulleted_rounded': Icons.format_list_bulleted_rounded,
    'timer_outlined': Icons.timer_outlined,
    'visibility_outlined': Icons.visibility_outlined,
    'category_outlined': Icons.category_outlined,
    'casino_outlined': Icons.casino_outlined,
    'abc_rounded': Icons.abc_rounded,
    'menu_book_outlined': Icons.menu_book_outlined,
    'edit_note_outlined': Icons.edit_note_outlined,
    'bolt_rounded': Icons.bolt_rounded,
    'star_outline_rounded': Icons.star_outline_rounded,
    'check_circle_outline': Icons.check_circle_outline,
    'add_circle_outline': Icons.add_circle_outline,
    'photo_outlined': Icons.photo_outlined,
    'sentiment_satisfied_alt_outlined': Icons.sentiment_satisfied_alt_outlined,
  };

  static List<String> get names => _icons.keys.toList()..sort();

  static IconData resolve(String? name) {
    if (name == null || name.isEmpty) return fallback;
    return _icons[name] ?? fallback;
  }

  static String nameFor(IconData icon) {
    for (final e in _icons.entries) {
      if (e.value.codePoint == icon.codePoint) return e.key;
    }
    return 'school_outlined';
  }
}
