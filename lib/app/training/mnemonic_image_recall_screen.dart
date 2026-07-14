part of 'package:flutter_application_1/recovered_app.dart';

// --- V2 ---

// --- ????????: ???????????????? ????????? ??????????? (V2) ---

class MnemonicImageRecallScreen extends StatefulWidget {
  final List<String> imageUrls;
  final List<int> shuffledIndices;
  final List<int?> initialSelections;
  /// Order of slot positions to focus during recall (matches memorizer display order).
  final List<int>? focusAdvanceOrder;
  final Function(List<int?>) onCompleted;
  final bool isResultsMode;
  final int memorizationElapsedMs;
  final int recallElapsedMs;
  final int xpEarned;
  final VoidCallback? onElementStatsTap;

  const MnemonicImageRecallScreen({
    super.key,
    required this.imageUrls,
    required this.shuffledIndices,
    required this.initialSelections,
    this.focusAdvanceOrder,
    required this.onCompleted,
    this.isResultsMode = false,
    this.memorizationElapsedMs = 0,
    this.recallElapsedMs = 0,
    this.xpEarned = 0,
    this.onElementStatsTap,
  });

  @override
  State<MnemonicImageRecallScreen> createState() => _MnemonicImageRecallScreenState();
}

class _MnemonicImageRecallScreenState extends State<MnemonicImageRecallScreen> with TickerProviderStateMixin {
  // ??????? (0-indexed) -> ?????? ???????? (?? imageUrls)
  late Map<int, int?> _placements;
  late Set<int> _usedImageIndices;
  int _focusedPosition = 0;
  int _currentPage = 0;
  final int _pageSize = 6; // 2x3 grid for more focus
  bool _isOverviewOpen = false;
  int? _selectedFromSource;
  late final PageController _pageController;
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _placements = {};
    _usedImageIndices = {};
    _pageController = PageController(initialPage: 0);
    
    // ????????????? ?? ?????????? ????????? (???? ????)
    for (int imgIdx = 0; imgIdx < widget.initialSelections.length; imgIdx++) {
      final posPlusOne = widget.initialSelections[imgIdx];
      if (posPlusOne != null && posPlusOne > 0) {
        final pos = posPlusOne - 1;
        _placements[pos] = imgIdx;
        _usedImageIndices.add(imgIdx);
      }
    }
    
    _autoAdvanceFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.isResultsMode && trainerKeyboardShortcutsEnabled(context)) {
        _keyboardFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  List<int> get _focusAdvanceOrder {
    final custom = widget.focusAdvanceOrder;
    if (custom != null && custom.isNotEmpty) return custom;
    return List<int>.generate(widget.imageUrls.length, (i) => i);
  }

  void _autoAdvanceFocus() {
    for (final pos in _focusAdvanceOrder) {
      if (!_placements.containsKey(pos) || _placements[pos] == null) {
        _setFocusPosition(pos);
        return;
      }
    }
  }

  void _setFocusPosition(int pos, {bool animate = true}) {
    final total = widget.imageUrls.length;
    if (total <= 0) return;
    final clamped = pos.clamp(0, total - 1);
    setState(() {
      _focusedPosition = clamped;
      _currentPage = clamped ~/ _pageSize;
    });
    if (_pageController.hasClients && _pageController.page?.toInt() != _currentPage) {
      if (animate) {
        _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      } else {
        _pageController.jumpToPage(_currentPage);
      }
    }
  }

  void _autoAdvanceForwardFrom(int fromPos) {
    final total = widget.imageUrls.length;
    final order = _focusAdvanceOrder;
    final fromIdx = order.indexOf(fromPos);
    if (fromIdx >= 0) {
      for (int i = fromIdx + 1; i < order.length; i++) {
        final pos = order[i];
        if (_placements[pos] == null) {
          _setFocusPosition(pos);
          return;
        }
      }
    }
    _setFocusPosition(min(fromPos + 1, total - 1));
  }

  void _onImagePlaced(int pos, int imgIdx) {
    if (widget.isResultsMode) return;
    
    setState(() {
      // ???? ? ????? ??? ???? ????????, ?????????? ?? ? ???
      final oldImg = _placements[pos];
      if (oldImg != null) _usedImageIndices.remove(oldImg);

      _placements[pos] = imgIdx;
      _usedImageIndices.add(imgIdx);
      
      _selectedFromSource = null;
    });
    _autoAdvanceForwardFrom(pos);
    uiTapClick(UiClickSound.bright);
  }

  void _onSlotTap(int position) {
    if (widget.isResultsMode) {
      setState(() => _focusedPosition = position);
      return;
    }
    
    if (_selectedFromSource != null) {
      _onImagePlaced(position, _selectedFromSource!);
      uiTapClick(UiClickSound.soft);
      return;
    }

    setState(() {
      if (_focusedPosition == position) {
        final img = _placements[position];
        if (img != null) {
          _usedImageIndices.remove(img);
          _placements.remove(position);
        }
      } else {
        _focusedPosition = position;
      }
    });
    uiTapClick(UiClickSound.soft);
  }

  void _onSourceTap(int imgIdx) {
    if (widget.isResultsMode) return;
    if (_usedImageIndices.contains(imgIdx)) return;

    setState(() {
      if (_selectedFromSource == imgIdx) {
        _selectedFromSource = null;
      } else {
        _selectedFromSource = imgIdx;
        // ????????????? ?????? ? ???????? ????, ???? ?????? ????? Tap-to-fill
        _onImagePlaced(_focusedPosition, imgIdx);
      }
    });
    uiTapClick(UiClickSound.soft);
  }

  void _jumpToPosition(int pos) {
    setState(() => _isOverviewOpen = false);
    _setFocusPosition(pos, animate: false);
  }

  void _onArrowNav(int delta, {bool isLongPress = false}) {
    final total = widget.imageUrls.length;
    int actualDelta = isLongPress ? (delta * 10) : delta;
    int newPos = (_focusedPosition + actualDelta).clamp(0, total - 1);
    
    if (newPos != _focusedPosition) {
      setState(() {
        _focusedPosition = newPos;
        _currentPage = _focusedPosition ~/ _pageSize;
      });
      if (_pageController.hasClients && _pageController.page?.toInt() != _currentPage) {
        _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
      uiTapClick(UiClickSound.soft);
    }
  }

  bool _handleRecallKeyDown(KeyDownEvent event) {
    if (widget.isResultsMode || trainerShortcutBlockedByTextField()) return false;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.pageDown) {
      _onArrowNav(1);
      return true;
    }
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.pageUp) {
      _onArrowNav(-1);
      return true;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      _finishRecall();
      return true;
    }
    if (key == LogicalKeyboardKey.backspace || key == LogicalKeyboardKey.delete) {
      final img = _placements[_focusedPosition];
      if (img != null) {
        setState(() {
          _usedImageIndices.remove(img);
          _placements.remove(_focusedPosition);
        });
        uiTapClick(UiClickSound.soft);
      }
      return true;
    }
    return false;
  }

  Widget _buildIndexBadge({
    required String label,
    required Color textColor,
    required Color backgroundColor,
    double fontSize = 10,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.imageUrls.length;
    final totalPages = (total / _pageSize).ceil();
    final palette = appPalette.value;
    final wide = isTrainerWideLayout(context) && !widget.isResultsMode;

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) _handleRecallKeyDown(event);
      },
      child: Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: trainerRecallMaxWidth(context)),
              child: Stack(
                children: [
                  wide
                      ? _buildWideLayout(totalPages)
                      : _buildNarrowLayout(totalPages),
                  if (_isOverviewOpen) _buildOverviewOverlay(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNarrowLayout(int totalPages) {
    return Column(
      children: [
        _buildHeader(totalPages),
        if (widget.isResultsMode) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: _buildResultsDashboard(),
          ),
        ],
        Expanded(
          child: Column(
            children: [
              widget.isResultsMode
                  ? Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (p) => setState(() => _currentPage = p),
                        itemCount: totalPages,
                        itemBuilder: (context, pageIdx) => _buildTargetTable(pageIdx),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final h = min(280.0, constraints.maxHeight * 0.44).clamp(200.0, 280.0);
                        return SizedBox(
                          height: h,
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (p) => setState(() => _currentPage = p),
                            itemCount: totalPages,
                            itemBuilder: (context, pageIdx) => _buildTargetTable(pageIdx),
                          ),
                        );
                      },
                    ),
              _buildSourceDeck(expanded: true),
            ],
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildWideLayout(int totalPages) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 11,
          child: Column(
            children: [
              _buildHeader(totalPages, compact: true),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (p) => setState(() => _currentPage = p),
                  itemCount: totalPages,
                  itemBuilder: (context, pageIdx) => _buildTargetTable(pageIdx, compact: true),
                ),
              ),
              _buildBottomBar(compact: true),
            ],
          ),
        ),
        Container(
          width: 1,
          margin: const EdgeInsets.symmetric(vertical: 12),
          color: appPalette.value.border.withOpacity(0.2),
        ),
        Expanded(
          flex: 9,
          child: _buildSourceDeck(expanded: true, sidePanel: true),
        ),
      ],
    );
  }

  Widget _buildResultsDashboard() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final int n = widget.imageUrls.length;
    int correct = 0;
    for (int i = 0; i < n; i++) {
      if (_placements[i] == i) correct++;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${pct.toStringAsFixed(0)}% · $correct/$n',
                style: TextStyle(
                  color: appAccentColor.value,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (widget.onElementStatsTap != null) ...[
                const SizedBox(width: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onElementStatsTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.query_stats_rounded,
                        size: 22,
                        color: appAccentColor.value.withOpacity(0.85),
                      ),
                    ),
                  ),
                ),
              ],
            ],
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

  Widget _buildHeader(int totalPages, {bool compact = false}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: EdgeInsets.fromLTRB(20, compact ? 8 : 12, 20, compact ? 6 : 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTexts.get('image_recall_table_page')
                    .replaceAll('{current}', '${_currentPage + 1}')
                    .replaceAll('{total}', '$totalPages'),
                style: TextStyle(color: onSurface.withOpacity(0.3), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                AppTexts.get('element_stats_slot_value').replaceAll('{n}', '${_focusedPosition + 1}'),
                style: TextStyle(
                  color: onSurface,
                  fontSize: compact ? 18 : 22,
                  fontWeight: FontWeight.w200,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _headerButton(Icons.apps_rounded, () => setState(() => _isOverviewOpen = true)),
              const SizedBox(width: 12),
              if (widget.isResultsMode)
                _headerButton(
                  Icons.check_rounded,
                  _finishRecall,
                  color: appAccentColor.value,
                  size: 28,
                )
              else
                _headerButton(Icons.done_all_rounded, _finishRecall, color: appAccentColor.value, size: 28),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerButton(IconData icon, VoidCallback onTap, {Color? color, double size = 24}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final palette = appPalette.value;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.border.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color ?? onSurface.withOpacity(0.6), size: size),
      ),
    );
  }

  Widget _buildTargetTable(int pageIdx, {bool compact = false}) {
    final start = pageIdx * _pageSize;
    final end = min(start + _pageSize, widget.imageUrls.length);
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = compact ? 10.0 : 14.0;
        final radius = compact ? 18.0 : 24.0;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16, vertical: compact ? 8 : 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: 1.0,
            ),
            itemCount: end - start,
            itemBuilder: (context, index) {
              final pos = start + index;
              final isFocused = _focusedPosition == pos;
              final imgIdx = _placements[pos];
              
              Color borderColor = isFocused ? appAccentColor.value : palette.border.withOpacity(0.15);
              if (widget.isResultsMode && imgIdx != null) {
                borderColor = (imgIdx == pos) ? const Color(0xFF00E676) : const Color(0xFFFF1744);
              }

              return DragTarget<int>(
                onWillAcceptWithDetails: (details) => !widget.isResultsMode,
                onAcceptWithDetails: (details) => _onImagePlaced(pos, details.data),
                builder: (context, candidateData, rejectedData) {
                  final isHovering = candidateData.isNotEmpty;
                  return GestureDetector(
                    onTap: () => _onSlotTap(pos),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: isFocused 
                            ? appAccentColor.value.withOpacity(0.08) 
                            : (isHovering ? appAccentColor.value.withOpacity(0.15) : palette.card.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(radius),
                        border: Border.all(
                          color: isHovering ? appAccentColor.value : borderColor, 
                          width: (isFocused || isHovering) ? 2 : 1,
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (imgIdx != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(radius - 2),
                              child: Image.network(
                                widget.imageUrls[imgIdx],
                                fit: BoxFit.cover,
                                cacheWidth: compact ? 200 : 250,
                              ),
                            ),
                          Positioned(
                            top: compact ? 6 : 8,
                            left: compact ? 6 : 8,
                            child: _buildIndexBadge(
                              label: "${pos + 1}",
                              textColor: imgIdx != null ? Colors.white : onSurface.withOpacity(0.76),
                              backgroundColor: imgIdx != null
                                  ? Colors.black.withOpacity(0.52)
                                  : palette.surface.withOpacity(0.94),
                              fontSize: compact ? 9.5 : 10.5,
                            ),
                          ),
                          if (widget.isResultsMode && imgIdx != null && imgIdx != pos)
                            Positioned(
                              bottom: 0, right: 0, left: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.8),
                                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius - 2)),
                                ),
                                child: Text(
                                  "#${imgIdx + 1}",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Color(0xFF00E676), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSourceDeck({required bool expanded, bool sidePanel = false}) {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    if (widget.isResultsMode) return const SizedBox.shrink();

    // ????????? ?????? ???????????????? ???????????
    final availableIndices = widget.shuffledIndices.where((idx) => !_usedImageIndices.contains(idx)).toList();

    final deck = Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: sidePanel ? 16 : 24, vertical: sidePanel ? 6 : 8),
          child: Row(
            children: [
              Text(
                AppTexts.get('image_recall_deck_label'),
                style: TextStyle(
                  color: onSurface.withOpacity(0.2),
                  fontSize: sidePanel ? 9 : 10,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showAllImagesPicker(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: appAccentColor.value.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.filter_rounded, size: 12, color: appAccentColor.value),
                      const SizedBox(width: 4),
                      Text(AppTexts.get('image_recall_all_short'), style: TextStyle(color: appAccentColor.value, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "${_usedImageIndices.length} / ${widget.imageUrls.length}",
                style: TextStyle(color: onSurface.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cols = imageRecallSourceColumns(constraints.maxWidth);
              return GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: sidePanel ? 12 : 16, vertical: 8),
                physics: const BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: sidePanel ? 8 : 10,
                  crossAxisSpacing: sidePanel ? 8 : 10,
                  childAspectRatio: 1.0,
                ),
                itemCount: availableIndices.length,
                itemBuilder: (context, index) {
                  final imgIdx = availableIndices[index];
                  
                  final imageWidget = Container(
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(sidePanel ? 12 : 16),
                      border: Border.all(
                        color: _selectedFromSource == imgIdx ? appAccentColor.value : palette.border.withOpacity(0.1),
                        width: _selectedFromSource == imgIdx ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      widget.imageUrls[imgIdx],
                      fit: BoxFit.cover,
                      cacheWidth: sidePanel ? 160 : 200,
                    ),
                  );

                  return Draggable<int>(
                    data: imgIdx,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Transform.scale(
                        scale: 1.05,
                        child: Container(
                          width: sidePanel ? 64 : 80,
                          height: sidePanel ? 64 : 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(widget.imageUrls[imgIdx], fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(opacity: 0.3, child: imageWidget),
                    onDragStarted: () => uiTapClick(UiClickSound.soft),
                    child: GestureDetector(
                      onTap: () => _onSourceTap(imgIdx),
                      child: imageWidget,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );

    if (expanded) return Expanded(child: deck);
    return deck;
  }

  void _showAllImagesPicker() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final wide = isTrainerWideLayout(context);
    showTrainerAdaptivePicker(
      context: context,
      builder: (sheetContext) {
        Widget buildGrid({ScrollController? scrollController, required int cols}) {
          return GridView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, idx) {
              final displayIdx = idx;
              final isUsed = _usedImageIndices.contains(displayIdx);
              return GestureDetector(
                onTap: () {
                  if (!isUsed) {
                    _onImagePlaced(_focusedPosition, displayIdx);
                    Navigator.pop(sheetContext);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isUsed ? Colors.transparent : onSurface.withOpacity(0.1)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Opacity(
                        opacity: isUsed ? 0.2 : 1.0,
                        child: Image.network(widget.imageUrls[displayIdx], fit: BoxFit.cover, cacheWidth: 300),
                      ),
                      if (isUsed) Center(child: Icon(Icons.check_circle_outline_rounded, color: onSurface.withOpacity(0.3))),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _buildIndexBadge(
                          label: "${displayIdx + 1}",
                          textColor: Colors.white,
                          backgroundColor: Colors.black.withOpacity(0.52),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        if (wide) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppTexts.get('image_recall_all_images'),
                      style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.w300),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: onSurface.withOpacity(0.7)),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
              ),
              Expanded(child: buildGrid(cols: 5)),
            ],
          );
        }

        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: onSurface.withOpacity(0.1), borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppTexts.get('image_recall_all_images'), style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.w200, letterSpacing: 1)),
                    Text("${widget.imageUrls.length}", style: TextStyle(color: appAccentColor.value, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: buildGrid(scrollController: scrollController, cols: 3)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar({bool compact = false}) {
    final palette = appPalette.value;
    final total = widget.imageUrls.length;
    final totalPages = (total / _pageSize).ceil();
    
    return Container(
      padding: EdgeInsets.fromLTRB(24, 0, 24, compact ? 10 : 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navButton(
            Icons.arrow_back_ios_new_rounded, 
            () => _onArrowNav(-1),
            onLongPress: () => _onArrowNav(-1, isLongPress: true),
            compact: compact,
          ),
          Row(
            children: List.generate(totalPages, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _currentPage == i ? 12 : 4,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: _currentPage == i ? appAccentColor.value : palette.border.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            )),
          ),
          _navButton(
            Icons.arrow_forward_ios_rounded, 
            () => _onArrowNav(1),
            onLongPress: () => _onArrowNav(1, isLongPress: true),
            compact: compact,
          ),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap, {VoidCallback? onLongPress, bool compact = false}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final palette = appPalette.value;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: onSurface, size: compact ? 22 : 28),
      ),
    );
  }

  Widget _buildOverviewOverlay() {
    final palette = appPalette.value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Material(
      color: palette.background.withOpacity(0.95),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppTexts.get('image_recall_positions_map'), style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  IconButton(icon: Icon(Icons.close, color: onSurface), onPressed: () => setState(() => _isOverviewOpen = false)),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 10,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemCount: widget.imageUrls.length,
                itemBuilder: (context, i) {
                  final imgIdx = _placements[i];
                  final isFilled = imgIdx != null;
                  
                  Color color = isFilled ? onSurface.withOpacity(0.1) : Colors.transparent;
                  Color textColor = isFilled ? onSurface.withOpacity(0.7) : onSurface.withOpacity(0.24);
                  Color borderColor = isFilled ? onSurface.withOpacity(0.24) : onSurface.withOpacity(0.05);

                  if (widget.isResultsMode && isFilled) {
                    final correct = (imgIdx == i);
                    color = correct ? const Color(0xFF00E676).withOpacity(0.2) : const Color(0xFFFF1744).withOpacity(0.2);
                    borderColor = correct ? const Color(0xFF00E676) : const Color(0xFFFF1744);
                    textColor = onSurface;
                  }

                  return GestureDetector(
                    onTap: () => _jumpToPosition(i),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text("${i + 1}", style: TextStyle(fontSize: 10, color: textColor, fontWeight: isFilled ? FontWeight.bold : FontWeight.normal)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _finishRecall() {
    // ???????????? ??????? ? ?????? _imageAnswerOrder
    // ????????? List<int?> ??? index=imageIdx, value=position+1
    final result = List<int?>.filled(widget.imageUrls.length, null);
    _placements.forEach((pos, imgIdx) {
      if (imgIdx != null) {
        result[imgIdx] = pos + 1;
      }
    });
    widget.onCompleted(result);
  }
}

