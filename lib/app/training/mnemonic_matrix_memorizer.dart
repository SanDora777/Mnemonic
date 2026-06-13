part of 'package:flutter_application_1/recovered_app.dart';

class MnemonicMatrixMemorizer extends StatefulWidget {
  final List<String> data;
  final int currentChunkIndex;
  final int chunkSize;
  final String formattedTime;
  /// ??????? ??? ???????? (????????, ??????? ?????? ??????).
  final String? memorizationSubtitle;
  /// ????????? ???????? (????? ??????, ????-???).
  final VoidCallback? onTimerSettingsTap;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onFirst;
  final VoidCallback onRecallNow;

  const MnemonicMatrixMemorizer({
    super.key,
    required this.data,
    required this.currentChunkIndex,
    required this.chunkSize,
    required this.formattedTime,
    this.memorizationSubtitle,
    this.onTimerSettingsTap,
    required this.onNext,
    required this.onPrev,
    required this.onFirst,
    required this.onRecallNow,
  });

  @override
  State<MnemonicMatrixMemorizer> createState() => _MnemonicMatrixMemorizerState();
}

class _MnemonicMatrixMemorizerState extends State<MnemonicMatrixMemorizer> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MnemonicMatrixMemorizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentChunkIndex != oldWidget.currentChunkIndex) {
      _scrollToRow();
    }
  }

  void _scrollToRow() {
    int currentRow = (widget.currentChunkIndex * widget.chunkSize) ~/ 6;
    // ???????? ???????? ? 5-?? ????? (?????? 4)
    if (currentRow >= 4) {
      double offset = (currentRow - 3) * 48.0; // 40 (??????) + 8 (spacing)
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
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final palette = appPalette.value;
    int start = widget.currentChunkIndex * widget.chunkSize;
    int end = min(start + widget.chunkSize, widget.data.length);

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = matrixGridMetrics(constraints.maxWidth);

        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTimerSettingsTap,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.formattedTime,
                    style: TextStyle(
                      color: onSurface.withOpacity(0.1),
                      fontSize: 16,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 4,
                      decoration: widget.onTimerSettingsTap == null
                          ? TextDecoration.none
                          : TextDecoration.underline,
                      decorationColor: onSurface.withOpacity(0.08),
                    ),
                  ),
                  if (widget.memorizationSubtitle != null &&
                      widget.memorizationSubtitle!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.memorizationSubtitle!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: appAccentColor.value.withOpacity(0.88),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: appAccentColor.value.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: appAccentColor.value.withOpacity(0.2)),
              ),
              child: Text(
                widget.data.sublist(start, end).join(" "),
                style: TextStyle(
                  color: onSurface,
                  fontSize: metrics.headerFont,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Container(
              width: metrics.width,
              height: metrics.height,
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
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: widget.data.length,
                    itemBuilder: (context, i) {
                      final isCurrent = i >= start && i < end;
                      final rowNum = i ~/ 6;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          if (i % 6 == 0 && rowNum > 0)
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
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isCurrent ? appAccentColor.value.withOpacity(0.15) : palette.card,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isCurrent ? appAccentColor.value : Colors.transparent, width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                widget.data[i],
                                style: TextStyle(
                                  color: isCurrent ? onSurface : onSurface.withOpacity(0.15),
                                  fontSize: metrics.cellFont,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
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
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _circleNavBtn(Icons.arrow_back_ios_new_rounded, widget.onPrev),
                const SizedBox(width: 20),
                _circleNavBtn(Icons.circle, widget.onFirst),
                const SizedBox(width: 20),
                _circleNavBtn(Icons.arrow_forward_ios_rounded, widget.onNext),
                const SizedBox(width: 20),
                _circleNavBtn(Icons.bolt_rounded, widget.onRecallNow, isPrimary: true),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _circleNavBtn(IconData icon, VoidCallback onTap, {bool isPrimary = false}) {
    final palette = appPalette.value;
    final accent = appAccentColor.value;
    return GestureDetector(
      onTap: () {
        uiTapClick(UiClickSound.soft);
        onTap();
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isPrimary ? accent.withOpacity(0.1) : palette.surface,
          shape: BoxShape.circle,
          border: Border.all(color: isPrimary ? accent.withOpacity(0.5) : palette.border.withOpacity(0.3)),
        ),
        child: Icon(icon, color: isPrimary ? accent : Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: 20),
      ),
    );
  }
}

