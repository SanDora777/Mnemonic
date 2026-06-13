part of 'package:flutter_application_1/recovered_app.dart';

// --- АКАДЕМИЯ: SKILL TREE ---
// Прежний экран с уроками заменён на ветвящееся дерево навыков.
// Реализация — в `lib/skill_tree/skill_tree_screen.dart`. Класс
// `TechniquesScreen` оставлен как фасад, чтобы существующие точки
// входа в академию продолжали работать без правок.
class TechniquesScreen extends StatelessWidget {
  const TechniquesScreen({super.key});

  @override
  Widget build(BuildContext context) => const SkillTreeScreen();
}
