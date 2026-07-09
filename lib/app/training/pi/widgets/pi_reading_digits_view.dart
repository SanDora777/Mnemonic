import 'package:flutter/material.dart';

import 'package:flutter_application_1/trainer/pi/pi_session_builder.dart';

/// Efficient scrollable π reading view — one [ListView.builder] row per digit block.
class PiReadingDigitsView extends StatefulWidget {
  const PiReadingDigitsView({
    super.key,
    required this.blocks,
    required this.accentColor,
    required this.onSurface,
    required this.surfaceColor,
    required this.borderColor,
    required this.highlightGlobalDigitStart,
    required this.showLoci,
    required this.positionLabel,
    this.onBlockTap,
  });

  final List<PiDigitBlock> blocks;
  final Color accentColor;
  final Color onSurface;
  final Color surfaceColor;
  final Color borderColor;
  final int highlightGlobalDigitStart;
  final bool showLoci;
  final String positionLabel;
  final void Function(PiDigitBlock block)? onBlockTap;

  @override
  State<PiReadingDigitsView> createState() => _PiReadingDigitsViewState();
}

class _PiReadingDigitsViewState extends State<PiReadingDigitsView> {
  final ScrollController _scrollController = ScrollController();
  int? _lastScrolledHighlight;

  @override
  void didUpdateWidget(covariant PiReadingDigitsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlightGlobalDigitStart != oldWidget.highlightGlobalDigitStart) {
      _scrollToHighlight();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToHighlight());
  }

  void _scrollToHighlight() {
    final target = widget.highlightGlobalDigitStart;
    if (_lastScrolledHighlight == target) return;
    final index = widget.blocks.indexWhere((b) => b.globalDigitStart == target);
    if (index < 0 || !_scrollController.hasClients) return;
    _lastScrolledHighlight = target;
    final offset = (index * 72.0).clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
          child: Text(
            widget.positionLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.onSurface.withOpacity(0.35),
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: widget.blocks.length,
            itemBuilder: (context, index) {
              final block = widget.blocks[index];
              final highlighted = block.globalDigitStart == widget.highlightGlobalDigitStart;
              return _DigitBlockTile(
                block: block,
                highlighted: highlighted,
                showLoci: widget.showLoci,
                accentColor: widget.accentColor,
                onSurface: widget.onSurface,
                surfaceColor: widget.surfaceColor,
                borderColor: widget.borderColor,
                onTap: widget.onBlockTap == null ? null : () => widget.onBlockTap!(block),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DigitBlockTile extends StatelessWidget {
  const _DigitBlockTile({
    required this.block,
    required this.highlighted,
    required this.showLoci,
    required this.accentColor,
    required this.onSurface,
    required this.surfaceColor,
    required this.borderColor,
    this.onTap,
  });

  final PiDigitBlock block;
  final bool highlighted;
  final bool showLoci;
  final Color accentColor;
  final Color onSurface;
  final Color surfaceColor;
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: highlighted ? accentColor.withOpacity(0.08) : surfaceColor.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: highlighted
                    ? accentColor.withOpacity(0.45)
                    : borderColor.withOpacity(0.28),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    '#${block.displayDigitNumber}',
                    style: TextStyle(
                      color: accentColor.withOpacity(0.75),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    block.digits,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w100,
                      letterSpacing: 6,
                      fontFamily: 'monospace',
                      color: onSurface.withOpacity(highlighted ? 0.95 : 0.78),
                    ),
                  ),
                ),
                if (showLoci && block.locusName != null)
                  SizedBox(
                    width: 96,
                    child: Text(
                      block.locusName!,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: onSurface.withOpacity(0.38),
                        fontSize: 9.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
