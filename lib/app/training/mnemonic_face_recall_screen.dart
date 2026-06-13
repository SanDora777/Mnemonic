part of 'package:flutter_application_1/recovered_app.dart';

class MnemonicFaceRecallScreen extends StatefulWidget {
  final List<String> rawPeopleData;
  final List<int> shuffledIndices;
  final List<String> initialAnswers;
  final bool isResultsMode;
  final int memorizationElapsedMs;
  final int recallElapsedMs;
  final int xpEarned;
  final Function(List<String?>) onCompleted;

  const MnemonicFaceRecallScreen({
    super.key,
    required this.rawPeopleData,
    required this.shuffledIndices,
    required this.initialAnswers,
    required this.onCompleted,
    this.isResultsMode = false,
    this.memorizationElapsedMs = 0,
    this.recallElapsedMs = 0,
    this.xpEarned = 0,
  });

  @override
  State<MnemonicFaceRecallScreen> createState() => _MnemonicFaceRecallScreenState();
}

class _MnemonicFaceRecallScreenState extends State<MnemonicFaceRecallScreen> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  late final List<ImageProvider> _faceProviders;
  late final List<int> _displayOrder;

  ({String name, String imageUrl, String imageData}) _decodeFaceEntry(String raw) {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final name = (m['name'] as String?)?.trim() ?? '';
      final imageUrl = (m['imageUrl'] as String?)?.trim() ?? '';
      final imageData = (m['imageData'] as String?)?.trim() ?? '';
      return (name: name, imageUrl: imageUrl, imageData: imageData);
    } catch (_) {
      return (name: '', imageUrl: '', imageData: '');
    }
  }

  String _normalizeName(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<void> _precacheVisibleFaces() async {
    for (final provider in _faceProviders) {
      if (!mounted) return;
      try {
        await precacheImage(provider, context);
      } catch (_) {
        // Keep screen usable even if part of preload fails.
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.rawPeopleData.length,
      (i) => TextEditingController(text: i < widget.initialAnswers.length ? widget.initialAnswers[i] : ''),
    );
    _focusNodes = List.generate(widget.rawPeopleData.length, (_) => FocusNode());
    _faceProviders = List.generate(widget.rawPeopleData.length, (i) {
      final person = _decodeFaceEntry(widget.rawPeopleData[i]);
      return faceEntryImageProvider(
        imageUrl: person.imageUrl,
        imageData: person.imageData,
        resizeWidth: 240,
      );
    });
    final total = widget.rawPeopleData.length;
    final valid = widget.shuffledIndices.where((i) => i >= 0 && i < total).toSet().toList(growable: false);
    _displayOrder = valid.length == total ? valid : List<int>.generate(total, (i) => i)..shuffle();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _precacheVisibleFaces();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  int _correctCount() {
    int correct = 0;
    for (int i = 0; i < widget.rawPeopleData.length; i++) {
      final expected = _normalizeName(_decodeFaceEntry(widget.rawPeopleData[i]).name);
      final answer = _normalizeName(_controllers[i].text);
      if (answer.isNotEmpty && answer == expected) correct++;
    }
    return correct;
  }

  void _submit() {
    widget.onCompleted(_controllers.map((c) => c.text.trim()).toList(growable: false));
  }

  Widget _buildFaceIndexLabel({
    required int index,
    required Color onSurface,
    required Color surface,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: onSurface.withOpacity(0.12)),
      ),
      child: Text(
        '#${index + 1}',
        style: TextStyle(
          color: onSurface.withOpacity(0.68),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final int total = widget.rawPeopleData.length;
    final int correct = _correctCount();
    final double pct = total == 0 ? 0 : (correct / total) * 100;
    final double memSec = widget.memorizationElapsedMs / 1000.0;
    final double recallSec = widget.recallElapsedMs / 1000.0;

    return Column(
      children: [
        const SizedBox(height: 20),
        if (widget.isResultsMode)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.border.withOpacity(0.35)),
              ),
              child: Column(
                children: [
                  Text(
                    '${pct.toStringAsFixed(0)}% · $correct/$total',
                    style: TextStyle(color: appAccentColor.value, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppTexts.get('memorization_label')}: ${memSec.toStringAsFixed(1)} ${AppTexts.get('seconds_short')} · ${AppTexts.get('recall_label')}: ${recallSec.toStringAsFixed(1)} ${AppTexts.get('seconds_short')} · XP +${widget.xpEarned}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: onSurface.withOpacity(0.65), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
            physics: const BouncingScrollPhysics(),
            itemCount: _displayOrder.length,
            itemBuilder: (context, listIndex) {
              final personIndex = _displayOrder[listIndex];
              final person = _decodeFaceEntry(widget.rawPeopleData[personIndex]);
              final answerCtrl = _controllers[personIndex];
              final expected = _normalizeName(person.name);
              final answer = _normalizeName(answerCtrl.text);
              final isCorrect = widget.isResultsMode && answer.isNotEmpty && answer == expected;
              final isWrong = widget.isResultsMode && answer.isNotEmpty && answer != expected;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isCorrect
                          ? const Color(0xFF00E676)
                          : isWrong
                              ? const Color(0xFFFF1744)
                              : palette.border.withOpacity(0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: palette.border.withOpacity(0.25)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image(
                          image: _faceProviders[personIndex],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.person, color: onSurface.withOpacity(0.3)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFaceIndexLabel(
                              index: listIndex,
                              onSurface: onSurface,
                              surface: palette.surface,
                            ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: answerCtrl,
                              focusNode: _focusNodes[personIndex],
                              enabled: !widget.isResultsMode,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (_) {
                                if (widget.isResultsMode) return;
                                if (listIndex < _displayOrder.length - 1) {
                                  final nextOriginalIndex = _displayOrder[listIndex + 1];
                                  _focusNodes[nextOriginalIndex].requestFocus();
                                }
                              },
                              style: TextStyle(color: onSurface, fontSize: 16),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: AppTexts.get('enter_name_hint'),
                                hintStyle: TextStyle(color: onSurface.withOpacity(0.35), fontSize: 13),
                                border: InputBorder.none,
                              ),
                            ),
                            if (widget.isResultsMode)
                              Text(
                                '${AppTexts.get('correct_answer_prefix')}: ${person.name}',
                                style: TextStyle(
                                  color: isWrong ? const Color(0xFF00E676) : onSurface.withOpacity(0.45),
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: appAccentColor.value,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: _submit,
              child: Text(widget.isResultsMode ? AppTexts.get('exit') : AppTexts.get('check')),
            ),
          ),
        ),
      ],
    );
  }
}

