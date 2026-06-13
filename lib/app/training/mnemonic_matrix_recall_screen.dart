part of 'package:flutter_application_1/recovered_app.dart';

class MnemonicMatrixRecallScreen extends StatefulWidget {
  final List<String> correctData;
  final bool isResultsMode;
  final List<String> initialSelections;
  final Function(List<String?>) onCompleted;

  const MnemonicMatrixRecallScreen({
    super.key,
    required this.correctData,
    required this.isResultsMode,
    this.initialSelections = const <String>[],
    required this.onCompleted,
  });

  @override
  State<MnemonicMatrixRecallScreen> createState() => _MnemonicMatrixRecallScreenState();
}

class _MnemonicMatrixRecallScreenState extends State<MnemonicMatrixRecallScreen> {
  late final List<String?> _selections;
  int _focusedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selections = List<String?>.generate(widget.correctData.length, (i) {
      final initial = i < widget.initialSelections.length ? widget.initialSelections[i].trim() : '';
      return initial.isEmpty ? null : initial;
    });
    // ??????????? ????? ??? ?????? ??????????
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.isResultsMode) {
        _keyboardFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _onDigitInput(String digit) {
    if (widget.isResultsMode) return;
    uiTapClick(UiClickSound.soft);
    setState(() {
      _selections[_focusedIndex] = digit;
      if (_focusedIndex < _selections.length - 1) {
        _focusedIndex++;
        _scrollToRow();
      }
    });
  }

  void _onBackspace() {
    if (widget.isResultsMode) return;
    if (_focusedIndex > 0) {
      uiTapClick(UiClickSound.soft);
      setState(() {
        _selections[_focusedIndex] = null;
        _focusedIndex--;
        _scrollToRow();
      });
    }
  }

  void _scrollToRow() {
    int currentRow = _focusedIndex ~/ 6;
    if (currentRow >= 4) {
      double offset = (currentRow - 3) * 48.0;
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Widget _buildRowIndexLabel({
    required String label,
    required Color onSurface,
    required Color surface,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: onSurface.withOpacity(0.12)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: onSurface.withOpacity(0.68),
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (event) {
         if (event is KeyDownEvent) {
           final char = event.logicalKey.keyLabel;
           // ????????? ??????? ???? ? Numpad
           bool isDigit = RegExp(r'^[0-9]$').hasMatch(char) || 
                          (event.logicalKey.keyId >= LogicalKeyboardKey.numpad0.keyId && 
                           event.logicalKey.keyId <= LogicalKeyboardKey.numpad9.keyId);
           
           if (isDigit) {
             // ????????? ????? ?? keyLabel ??? ?? Numpad ????????
             final digit = char.length == 1 ? char : char.replaceAll(RegExp(r'[^0-9]'), '');
             if (digit.isNotEmpty) _onDigitInput(digit);
           } else if (event.logicalKey == LogicalKeyboardKey.backspace || event.logicalKey == LogicalKeyboardKey.delete) {
             _onBackspace();
           } else if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
             widget.onCompleted(_selections);
           }
         }
       },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = matrixGridMetrics(constraints.maxWidth);
          return Column(
            children: [
              if (widget.isResultsMode) _buildSummaryHeader(),
              const SizedBox(height: 30),
              Container(
                width: metrics.width,
                height: metrics.height,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.only(left: 24, right: 16, top: 16, bottom: 16),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: palette.border.withOpacity(0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const NeverScrollableScrollPhysics(),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: widget.isResultsMode ? 0.68 : 1.0,
                  ),
                  itemCount: widget.correctData.length,
                  itemBuilder: (context, index) {
                    final val = _selections[index];
                    final expected = widget.correctData[index];
                    final userVal = (val ?? '').trim();
                    final isFocused = _focusedIndex == index && !widget.isResultsMode;
                    final isCorrect = widget.isResultsMode &&
                        userVal.isNotEmpty &&
                        userVal == expected;
                    final isWrong = widget.isResultsMode && !isCorrect;
                    final rowNum = index ~/ 6;

                    Color borderColor = isFocused ? appAccentColor.value : palette.border.withOpacity(0.2);
                    if (isCorrect) borderColor = const Color(0xFF00E676);
                    if (isWrong) borderColor = const Color(0xFFFF1744);

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (index % 6 == 0 && rowNum > 0)
                          Positioned(
                            left: -22, top: 0, bottom: 0,
                            child: Center(
                              child: _buildRowIndexLabel(
                                label: "${rowNum * 6}",
                                onSurface: onSurface,
                                surface: palette.surface,
                              ),
                            ),
                          ),
                        GestureDetector(
                          onTap: widget.isResultsMode
                              ? null
                              : () => setState(() {
                                    _focusedIndex = index;
                                    _scrollToRow();
                                    _keyboardFocusNode.requestFocus();
                                  }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isFocused ? appAccentColor.value.withOpacity(0.1) : palette.card,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderColor, width: isFocused ? 2 : 1),
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                child: _buildMatrixCellContent(
                                  userVal: userVal,
                                  expected: expected,
                                  isResultsMode: widget.isResultsMode,
                                  isCorrect: isCorrect,
                                  isWrong: isWrong,
                                  onSurface: onSurface,
                                  fontSize: metrics.cellFont,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          if (!widget.isResultsMode) ...[
            const SizedBox(height: 20),
            // ??????????
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: List.generate(10, (i) => i.toString()).map((d) {
                  return GestureDetector(
                    onTap: () => _onDigitInput(d),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: palette.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.border.withOpacity(0.3)),
                      ),
                      child: Center(child: Text(d, style: TextStyle(color: onSurface, fontSize: 18))),
                    ),
                  );
                }).toList()..add(
                  GestureDetector(
                    onTap: _onBackspace,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: palette.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.border.withOpacity(0.3)),
                      ),
                      child: Icon(Icons.backspace_outlined, color: onSurface.withOpacity(0.5), size: 18),
                    ),
                  )
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildActionBtn(AppTexts.get('check'), () => widget.onCompleted(_selections)),
          ],
          if (widget.isResultsMode) ...[
            const SizedBox(height: 20),
            _buildActionBtn(AppTexts.get('exit'), () => widget.onCompleted(const [])),
          ],
          const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMatrixCellContent({
    required String userVal,
    required String expected,
    required bool isResultsMode,
    required bool isCorrect,
    required bool isWrong,
    required Color onSurface,
    double fontSize = 16,
  }) {
    if (!isResultsMode) {
      return Text(
        userVal,
        style: TextStyle(
          color: onSurface,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    if (isCorrect) {
      return Text(
        expected,
        style: TextStyle(
          color: onSurface,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    if (isWrong) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              userVal.isEmpty ? '�' : userVal,
              style: const TextStyle(
                color: Color(0xFFFF1744),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              expected,
              style: const TextStyle(
                color: Color(0xFF00E676),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSummaryHeader() {
    int correct = 0;
    for (int i = 0; i < widget.correctData.length; i++) {
      final userVal = (_selections[i] ?? '').trim();
      if (userVal.isNotEmpty && userVal == widget.correctData[i]) correct++;
    }
    final n = widget.correctData.length;
    final pct = n <= 0 ? 0.0 : (correct / n) * 100;
    return Column(
      children: [
        Text(
          '${pct.toStringAsFixed(0)}%',
          style: TextStyle(color: appAccentColor.value, fontSize: 36, fontWeight: FontWeight.w100),
        ),
        const SizedBox(height: 6),
        Text(
          AppTexts.get('standard_digits_result', params: {
            'correct': correct.toString(),
            'total': n.toString(),
          }),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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
    );
  }
}
