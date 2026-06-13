part of 'package:flutter_application_1/recovered_app.dart';

class MnemonicCardRecallScreen extends StatefulWidget {
  final List<String> correctData;
  final bool isResultsMode;
  final List<String> initialSelections;
  final int memorizationElapsedMs;
  final int recallElapsedMs;
  final int xpEarned;
  final Function(List<String?>) onCompleted;

  const MnemonicCardRecallScreen({
    super.key,
    required this.correctData,
    required this.isResultsMode,
    this.initialSelections = const <String>[],
    this.memorizationElapsedMs = 0,
    this.recallElapsedMs = 0,
    this.xpEarned = 0,
    required this.onCompleted,
  });

  @override
  State<MnemonicCardRecallScreen> createState() => _MnemonicCardRecallScreenState();
}
class _MnemonicCardRecallScreenState extends State<MnemonicCardRecallScreen> {
  static const Color _redSuitColor = Color(0xFFFF3B30);
  final List<String?> _selections = [];
  int _focusedIndex = 0;
  String _selectedSuit = 'h';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.correctData.length; i++) {
      final initial = i < widget.initialSelections.length ? widget.initialSelections[i].trim() : '';
      _selections.add(initial.isEmpty ? null : initial);
    }
  }

  void _onCardSelect(String rank) {
    if (widget.isResultsMode) return;
    uiTapClick(UiClickSound.soft);
    setState(() {
      _selections[_focusedIndex] = '$_selectedSuit$rank';
      if (_focusedIndex < _selections.length - 1) {
        _focusedIndex++;
        _scrollToFocused();
      }
    });
  }

  Color _blackSuitColor() {
    if (blackSuitAlwaysWhite.value) return Colors.white;
    return appAccentColor.value;
  }

  void _scrollToFocused() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          max(0, _focusedIndex * 90.0 - 100.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Widget _buildSlotIndexLabel(int index, Color onSurface, Color surface) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: onSurface.withOpacity(0.14)),
      ),
      child: Text(
        "${index + 1}",
        style: TextStyle(
          color: onSurface.withOpacity(0.72),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([blackSuitAlwaysWhite, appAccentColor, appPalette]),
      builder: (context, _) {
        final palette = appPalette.value;
        final onSurface = Theme.of(context).colorScheme.onSurface;

        return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          const SizedBox(height: 20),
          if (widget.isResultsMode) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: _buildResultsDashboard(onSurface),
            ),
          ],
          // ?????? ????????? ????
          SizedBox(
            height: 180,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _selections.length,
              itemBuilder: (context, index) {
                final card = _selections[index];
                final isFocused = _focusedIndex == index && !widget.isResultsMode;
                final isCorrect = widget.isResultsMode && _selections[index] == widget.correctData[index];
                final isWrong = widget.isResultsMode && _selections[index] != widget.correctData[index];

                return GestureDetector(
                  onTap: () => setState(() => _focusedIndex = index),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        _buildSlotIndexLabel(index, onSurface, palette.surface),
                        const SizedBox(height: 8),
                        _buildSmallCard(
                          card, 
                          isFocused: isFocused,
                          isCorrect: isCorrect,
                          isWrong: isWrong,
                          correctCard: widget.isResultsMode ? widget.correctData[index] : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const Spacer(),

          if (!widget.isResultsMode) ...[
            // ???????? ?????
             Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: ['h', 'd', 'c', 's'].map((s) {
                 final isSel = _selectedSuit == s;
                 final isRed = s == 'h' || s == 'd';
                 final tileBg = isSel ? appAccentColor.value.withOpacity(0.15) : palette.surface;
                 final iconColor = isRed
                     ? (isSel ? _redSuitColor : _redSuitColor.withOpacity(0.72))
                     : (isSel ? _blackSuitColor() : _blackSuitColor().withOpacity(0.78));
                 return GestureDetector(
                   onTap: () => setState(() => _selectedSuit = s),
                   child: AnimatedContainer(
                     duration: const Duration(milliseconds: 200),
                     margin: const EdgeInsets.symmetric(horizontal: 10),
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: tileBg,
                       borderRadius: BorderRadius.circular(14),
                       border: Border.all(color: isSel ? appAccentColor.value : palette.border.withOpacity(0.3)),
                     ),
                     child: PlayingCardSuitIcon(
                       suitLetter: s,
                       color: iconColor,
                       size: 28,
                       cardSurfaceColor: tileBg,
                     ),
                   ),
                 );
               }).toList(),
             ),
            const SizedBox(height: 30),
            // ???????? ?????
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: ['a', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'j', 'q', 'k'].map((r) {
                  return GestureDetector(
                    onTap: () => _onCardSelect(r),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: palette.border.withOpacity(0.3)),
                      ),
                      child: Center(
                        child: Text(r.toUpperCase(), style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.w300)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 40),
            _buildActionBtn(AppTexts.get('finish'), () => widget.onCompleted(_selections)),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
      },
    );
  }

  Widget _buildResultsDashboard(Color onSurface) {
    final int n = widget.correctData.length;
    int correct = 0;
    for (int i = 0; i < n; i++) {
      if (_selections[i] == widget.correctData[i]) correct++;
    }
    final double pct = n == 0 ? 0 : (correct / n) * 100.0;
    final double memSec = widget.memorizationElapsedMs / 1000.0;
    final double recallSec = widget.recallElapsedMs / 1000.0;
    final double secPerEl = n == 0 ? 0 : memSec / n;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appPalette.value.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appPalette.value.border.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          Text(
            AppTexts.translate({
              AppLanguage.ru: '${pct.toStringAsFixed(0)}% · $correct/$n',
              AppLanguage.en: '${pct.toStringAsFixed(0)}% · $correct/$n',
              AppLanguage.de: '${pct.toStringAsFixed(0)}% · $correct/$n',
            }),
            style: TextStyle(color: appAccentColor.value, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _resultRow(
            onSurface,
            Icons.speed_rounded,
            AppTexts.get('speed_label'),
            '${secPerEl.toStringAsFixed(2)} ${AppTexts.get('seconds_short')}/${AppTexts.get('per_element')}',
          ),
          const SizedBox(height: 5),
          _resultRow(onSurface, Icons.psychology_rounded, AppTexts.get('memorization_label'), '${memSec.toStringAsFixed(1)} ${AppTexts.get('seconds_short')}'),
          const SizedBox(height: 5),
          _resultRow(onSurface, Icons.timer_outlined, AppTexts.get('recall_label'), '${recallSec.toStringAsFixed(1)} ${AppTexts.get('seconds_short')}'),
          const SizedBox(height: 5),
          _resultRow(onSurface, Icons.bolt_rounded, 'XP', '+${widget.xpEarned}'),
        ],
      ),
    );
  }

  Widget _resultRow(Color onSurface, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: onSurface.withOpacity(0.6)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: TextStyle(color: onSurface.withOpacity(0.7), fontSize: 12)),
        ),
        Text(
          value,
          style: TextStyle(color: onSurface, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildSmallCard(String? code, {bool isFocused = false, bool isCorrect = false, bool isWrong = false, String? correctCard}) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    
    Color borderColor = isFocused ? appAccentColor.value : palette.border.withOpacity(0.2);
    if (isCorrect) borderColor = const Color(0xFF00E676);
    if (isWrong) borderColor = const Color(0xFFFF1744);

    if (code == null) {
      return Container(
        width: 80,
        height: 120,
        decoration: BoxDecoration(
          color: palette.card.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isFocused ? 2 : 1),
        ),
        child: Center(child: Icon(Icons.add, color: onSurface.withOpacity(0.05))),
      );
    }

    final suitLetter = parsePlayingCardSuitLetter(code);
    if (suitLetter == null) {
      return Container(
        width: 80,
        height: 120,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: (isFocused || isWrong || isCorrect) ? 2 : 1),
        ),
        child: Center(child: Icon(Icons.help_outline, color: onSurface.withOpacity(0.22), size: 28)),
      );
    }

    final rank = code.substring(1).toUpperCase();
    final color = semanticPlayingCardSuitColor(
      suitLetter: suitLetter,
      accent: appAccentColor.value,
      blackSuitsWhite: blackSuitAlwaysWhite.value,
    );
    final shadows = playingCardGlyphShadows(color, palette.surface);

    return Container(
      width: 80,
      height: 120,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: (isFocused || isWrong || isCorrect) ? 2 : 1),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rank,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    shadows: shadows,
                  ),
                ),
                const SizedBox(height: 2),
                PlayingCardSuitIcon(
                  suitLetter: suitLetter,
                  color: color,
                  size: 14,
                  cardSurfaceColor: palette.surface,
                ),
              ],
            ),
          ),
          Center(
            child: Opacity(
              opacity: 0.18,
              child: PlayingCardSuitIcon(
                suitLetter: suitLetter,
                color: color,
                size: 44,
                cardSurfaceColor: palette.surface,
              ),
            ),
          ),
          if (isWrong && correctCard != null)
            Positioned(
              bottom: 4, left: 0, right: 0,
              child: Text(
                correctCard.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF00E676), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () {
          uiTapClick(UiClickSound.bright);
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          decoration: BoxDecoration(
            color: appAccentColor.value,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: appAccentColor.value.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
            ],
          ),
          child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 14)),
        ),
      ),
    );
  }
}

