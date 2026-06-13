import 'package:flutter/material.dart';

import '../cloud/cloud_sync_service.dart';
import '../recovered_app.dart' show appAccentColor, appLanguage, AppLanguage, appPalette, AppPalette;
import 'duel_disciplines.dart';
import 'duel_service.dart';

/// Per-element answer breakdown for duel results (me vs opponent).
class DuelAnswerReviewSection extends StatefulWidget {
  final DuelRoom room;
  final List<String> myItems;
  final Color onSurface;

  const DuelAnswerReviewSection({
    super.key,
    required this.room,
    required this.myItems,
    required this.onSurface,
  });

  @override
  State<DuelAnswerReviewSection> createState() => _DuelAnswerReviewSectionState();
}

class _DuelAnswerReviewSectionState extends State<DuelAnswerReviewSection> {
  int _tab = 0;

  String _t(Map<AppLanguage, String> map) =>
      map[appLanguage.value] ?? map[AppLanguage.ru] ?? '';

  @override
  Widget build(BuildContext context) {
    final task = widget.room.task;
    if (task == null) return const SizedBox.shrink();

    final accent = appAccentColor.value;
    final palette = appPalette.value;
    final me = CloudSyncService.instance.user.value?.uid;
    final discipline = task.discipline;
    final shared = discipline.sharedContent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _t(const {
            AppLanguage.ru: 'РАЗБОР ОТВЕТОВ',
            AppLanguage.en: 'ANSWER REVIEW',
            AppLanguage.de: 'ANTWORTEN',
          }),
          style: TextStyle(
            color: widget.onSurface.withOpacity(0.4),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.border.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              _tabChip(
                0,
                _t(const {
                  AppLanguage.ru: 'Мои',
                  AppLanguage.en: 'Mine',
                  AppLanguage.de: 'Meine',
                }),
                accent,
              ),
              _tabChip(
                1,
                _t(const {
                  AppLanguage.ru: 'Соперник',
                  AppLanguage.en: 'Opponent',
                  AppLanguage.de: 'Gegner',
                }),
                accent,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_tab == 1 && !shared)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              _t(const {
                AppLanguage.ru:
                    'У соперника свой набор (картинки/лица). Ниже — его ответы по каждому элементу.',
                AppLanguage.en:
                    'Opponent had a different set (images/faces). Below: their per-item answers.',
                AppLanguage.de:
                    'Gegner hatte ein anderes Set. Unten: Antworten pro Element.',
              }),
              style: TextStyle(
                color: widget.onSurface.withOpacity(0.5),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
        ..._buildRows(
          tab: _tab,
          discipline: discipline,
          me: me,
          shared: shared,
          task: task,
          accent: accent,
          palette: palette,
        ),
      ],
    );
  }

  Widget _tabChip(int index, String label, Color accent) {
    final selected = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? accent.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? accent : widget.onSurface.withOpacity(0.55),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRows({
    required int tab,
    required DuelDiscipline discipline,
    required String? me,
    required bool shared,
    required DuelTask task,
    required Color accent,
    required AppPalette palette,
  }) {
    final uid = tab == 0 ? me : _opponentUid(me);
    if (uid == null) {
      return [
        Text(
          _t(const {
            AppLanguage.ru: 'Нет данных',
            AppLanguage.en: 'No data',
            AppLanguage.de: 'Keine Daten',
          }),
          style: TextStyle(color: widget.onSurface.withOpacity(0.5)),
        ),
      ];
    }

    final result = widget.room.results[uid];
    if (result == null) {
      return [
        Text(
          _t(const {
            AppLanguage.ru: 'Игрок ещё не отправил ответы',
            AppLanguage.en: 'Player has not submitted yet',
            AppLanguage.de: 'Spieler hat noch nicht abgegeben',
          }),
          style: TextStyle(color: widget.onSurface.withOpacity(0.5)),
        ),
      ];
    }

    final List<String> items;
    if (tab == 0) {
      items = widget.myItems;
    } else if (shared && task.items.isNotEmpty) {
      items = task.items;
    } else {
      final n = result.total > 0 ? result.total : result.answers.length;
      items = List<String>.generate(n, (i) => '${i + 1}');
    }

    final n = items.length.clamp(0, result.answers.length);
    if (n == 0) {
      return [
        Text(
          _t(const {
            AppLanguage.ru: 'Нет ответов для разбора',
            AppLanguage.en: 'No answers to review',
            AppLanguage.de: 'Keine Antworten',
          }),
          style: TextStyle(color: widget.onSurface.withOpacity(0.5)),
        ),
      ];
    }

    final rows = <Widget>[];
    for (int i = 0; i < n; i++) {
      final expected = discipline == DuelDiscipline.images
          ? (i + 1).toString()
          : items[i];
      final user = result.answers[i];
      final ok = answerMatches(discipline, expected, user);
      rows.add(
        _answerRow(
          index: i,
          expected: _formatExpected(discipline, expected),
          answer: _formatAnswer(discipline, user),
          ok: ok,
          accent: accent,
        ),
      );
    }
    return rows;
  }

  String? _opponentUid(String? me) {
    for (final p in widget.room.players) {
      if (p.uid != me) return p.uid;
    }
    return null;
  }

  String _formatExpected(DuelDiscipline d, String raw) {
    if (d == DuelDiscipline.cards) return _formatCard(raw);
    if (d == DuelDiscipline.faces) {
      final face = decodeFaceItem(raw);
      return face.name.isEmpty ? raw : face.name;
    }
    if (d == DuelDiscipline.images) {
      return _t(const {
        AppLanguage.ru: 'Позиция',
        AppLanguage.en: 'Position',
        AppLanguage.de: 'Position',
      }) + ' $raw';
    }
    return raw;
  }

  String _formatAnswer(DuelDiscipline d, String raw) {
    if (raw.isEmpty) return '—';
    if (d == DuelDiscipline.cards) return _formatCard(raw);
    if (d == DuelDiscipline.images) return '#$raw';
    return raw;
  }

  String _formatCard(String code) {
    if (code.length < 2) return code.toUpperCase();
    final suit = code[0].toLowerCase();
    final rank = code.substring(1).toUpperCase();
    final suitChar = suit == 'h'
        ? '♥'
        : suit == 'd'
            ? '♦'
            : suit == 'c'
                ? '♣'
                : suit == 's'
                    ? '♠'
                    : suit;
    return '$rank$suitChar';
  }

  Widget _answerRow({
    required int index,
    required String expected,
    required String answer,
    required bool ok,
    required Color accent,
  }) {
    final border = ok ? accent.withOpacity(0.45) : Colors.red.withOpacity(0.45);
    final bg = ok ? accent.withOpacity(0.08) : Colors.red.withOpacity(0.06);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ok ? accent.withOpacity(0.15) : Colors.red.withOpacity(0.12),
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: ok ? accent : Colors.red.shade300,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              ok ? Icons.check_rounded : Icons.close_rounded,
              size: 18,
              color: ok ? accent : Colors.red.shade300,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expected,
                    style: TextStyle(
                      color: widget.onSurface.withOpacity(0.45),
                      fontSize: 10,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    answer,
                    style: TextStyle(
                      color: widget.onSurface.withOpacity(0.92),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
