import 'package:flutter/material.dart';

import '../recovered_app.dart' show appAccentColor, appLanguage, AppLanguage;

String creatorBadgeLabel(AppLanguage lang) {
  switch (lang) {
    case AppLanguage.en:
      return 'CREATOR';
    case AppLanguage.de:
      return 'ERSTELLER';
    case AppLanguage.ru:
      return 'СОЗДАТЕЛЬ';
  }
}

/// Badge shown on creator profiles and chat messages.
class CreatorBadge extends StatelessWidget {
  final bool compact;
  const CreatorBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final accent = appAccentColor.value;
    final label = creatorBadgeLabel(appLanguage.value);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withOpacity(0.85), accent],
        ),
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        boxShadow: [
          BoxShadow(color: accent.withOpacity(0.28), blurRadius: compact ? 4 : 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: compact ? 10 : 12,
            color: Colors.black.withOpacity(0.82),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.black.withOpacity(0.84),
              fontSize: compact ? 8 : 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
