import 'dart:math';

import 'package:flutter/material.dart';

import '../progress/progress_service.dart';
import 'profile_session_service.dart';

class AdvancedProfileScreen extends StatefulWidget {
  const AdvancedProfileScreen({super.key});

  @override
  State<AdvancedProfileScreen> createState() => _AdvancedProfileScreenState();
}

class _AdvancedProfileScreenState extends State<AdvancedProfileScreen> {
  late Future<Map<String, ModeProfileSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = ProfileSessionService.instance.buildModeSummaries();
  }

  String _modeTitle(String mode) {
    switch (mode) {
      case 'standard':
        return 'NUMBERS';
      case 'binary':
        return 'BINARY';
      case 'words':
        return 'WORDS';
      case 'images':
        return 'IMAGES';
      case 'cards':
        return 'CARDS';
      case 'faces':
        return 'FACES';
      default:
        return mode.toUpperCase();
    }
  }

  IconData _modeIcon(String mode) {
    switch (mode) {
      case 'standard':
        return Icons.numbers_rounded;
      case 'binary':
        return Icons.data_array_rounded;
      case 'words':
        return Icons.abc_rounded;
      case 'images':
        return Icons.image_outlined;
      case 'cards':
        return Icons.style_outlined;
      case 'faces':
        return Icons.face_rounded;
      default:
        return Icons.stacked_line_chart_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Colors.black;
    const card = Color(0xFF0E1014);
    const accentBlue = Color(0xFF4CC9FF);
    const accentGreen = Color(0xFF35F0A2);
    final level = ProgressService.instance.progress.value.level;
    final xp = ProgressService.instance.progress.value.xp;
    final username = 'Memory User';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: FutureBuilder<Map<String, ModeProfileSummary>>(
        future: _future,
        builder: (context, snapshot) {
          final summaries = snapshot.data ?? const <String, ModeProfileSummary>{};
          const order = ['standard', 'binary', 'words', 'images', 'cards', 'faces'];
          return AnimatedOpacity(
            opacity: snapshot.connectionState == ConnectionState.done ? 1 : 0.35,
            duration: const Duration(milliseconds: 320),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x3316B8FF), blurRadius: 28, spreadRadius: 0.5),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [accentBlue, accentGreen],
                          ),
                        ),
                        child: const Icon(Icons.person_rounded, color: Colors.black, size: 34),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Level $level  •  XP $xp',
                              style: TextStyle(color: Colors.white.withOpacity(0.72), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...order.asMap().entries.map((entry) {
                  final i = entry.key;
                  final mode = entry.value;
                  final s = summaries[mode];
                  if (s == null) return const SizedBox.shrink();
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.94, end: 1),
                    duration: Duration(milliseconds: 260 + i * 60),
                    curve: Curves.easeOutBack,
                    builder: (context, v, child) => Transform.scale(scale: v, child: child),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ModeCard(
                        title: _modeTitle(mode),
                        icon: _modeIcon(mode),
                        summary: s,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ModeDetailScreen(
                              title: _modeTitle(mode),
                              icon: _modeIcon(mode),
                              summary: s,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final ModeProfileSummary summary;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.icon,
    required this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const card = Color(0xFF0F1117);
    const accentBlue = Color(0xFF4CC9FF);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: const [BoxShadow(color: Color(0x2216B8FF), blurRadius: 20)],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentBlue.withOpacity(0.12),
              ),
              child: Icon(icon, size: 18, color: accentBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  _AnimatedNumberLine(label: 'Best result', valueText: '${summary.bestRecordScore}'),
                  _AnimatedNumberLine(label: 'Accuracy', valueText: '${(summary.bestAccuracy * 100).toStringAsFixed(1)}%'),
                  _AnimatedNumberLine(label: 'Speed', valueText: summary.bestSpeed <= 0 || summary.bestSpeed > 9000 ? '—' : '${summary.bestSpeed.toStringAsFixed(2)} sec/item'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedNumberLine extends StatelessWidget {
  final String label;
  final String valueText;

  const _AnimatedNumberLine({required this.label, required this.valueText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.56), fontSize: 12))),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 420),
            builder: (context, v, _) {
              return Opacity(
                opacity: v,
                child: Text(
                  valueText,
                  style: const TextStyle(color: Color(0xFF89DCFF), fontSize: 12, fontWeight: FontWeight.w700),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ModeDetailScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final ModeProfileSummary summary;

  const ModeDetailScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    const bg = Colors.black;
    const card = Color(0xFF0F1117);
    final scores = summary.sessions.reversed.map((e) => e.score).toList(growable: false);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: const Color(0xFF4CC9FF), size: 18),
                    const SizedBox(width: 8),
                    const Text('Score trend', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 170,
                  child: CustomPaint(
                    painter: _ScoreChartPainter(scores: scores),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...summary.sessions.asMap().entries.map((entry) {
            final idx = entry.key;
            final s = entry.value;
            final isBest = idx == summary.bestSessionIndex;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isBest ? const Color(0xFF35F0A2) : Colors.white.withOpacity(0.05),
                ),
                boxShadow: isBest ? const [BoxShadow(color: Color(0x2235F0A2), blurRadius: 18)] : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${s.date.day.toString().padLeft(2, '0')}.${s.date.month.toString().padLeft(2, '0')}.${s.date.year} ${s.date.hour.toString().padLeft(2, '0')}:${s.date.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(color: Colors.white.withOpacity(0.58), fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Score ${s.score.toStringAsFixed(4)} • ${s.correctItems}/${s.totalItems} • ${s.timeSeconds}s',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Accuracy ${(s.accuracy * 100).toStringAsFixed(1)}% • Speed ${s.speed > 9000 ? '—' : '${s.speed.toStringAsFixed(2)} sec/item'}',
                    style: TextStyle(color: Colors.white.withOpacity(0.68), fontSize: 11),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ScoreChartPainter extends CustomPainter {
  final List<double> scores;

  _ScoreChartPainter({required this.scores});

  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), axis);
    if (scores.length < 2) return;
    final maxVal = max(0.0001, scores.reduce(max));
    final path = Path();
    for (int i = 0; i < scores.length; i++) {
      final x = size.width * (i / (scores.length - 1));
      final y = size.height - ((scores[i] / maxVal) * (size.height - 10)) - 5;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final line = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF4CC9FF), Color(0xFF35F0A2)]).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _ScoreChartPainter oldDelegate) => oldDelegate.scores != scores;
}

