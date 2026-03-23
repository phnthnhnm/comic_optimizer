import 'package:flutter/material.dart';

class LogsPanel extends StatefulWidget {
  final Map<String, List<String>> logsByFolder;
  final String? selectedFolder;

  const LogsPanel({super.key, required this.logsByFolder, this.selectedFolder});

  @override
  State<LogsPanel> createState() => _LogsPanelState();
}

class _LogsPanelState extends State<LogsPanel> {
  int _selected = 0;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _hScrollController = ScrollController();
  bool _autoScroll = true;
  bool _isProgrammaticScroll = false;
  final Map<String, int> _lastCounts = {};
  // Resizable left column width
  double _leftWidth = 220.0;
  final double _minLeftWidth = 120.0;
  bool _isDragging = false;

  @override
  void didUpdateWidget(covariant LogsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final keys = widget.logsByFolder.keys.toList();
    if (keys.isEmpty) {
      _selected = 0;
    } else if (_selected >= keys.length) {
      _selected = keys.length - 1;
    }

    // If the logs for the currently selected key changed and auto-scroll is enabled,
    // scroll to bottom after the frame. Use a stored count so we detect changes
    // even when the underlying list is mutated in-place.
    if (keys.isNotEmpty && _selected < keys.length) {
      final sel = keys[_selected];
      final newLen = widget.logsByFolder[sel]?.length ?? 0;
      final prevLen = _lastCounts[sel] ?? 0;
      if (newLen != prevLen) {
        _lastCounts[sel] = newLen;
        if (_autoScroll) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToBottom(),
          );
        }
      }
    }

    // Auto-switch selected tab if parent requested a folder selection change
    if (widget.selectedFolder != null &&
        widget.selectedFolder != oldWidget.selectedFolder) {
      final idx = keys.indexOf(widget.selectedFolder!);
      if (idx != -1 && idx != _selected) {
        setState(() => _selected = idx);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_autoScroll) _scrollToBottom();
        });
      }
    }
  }

  Future<void> _scrollToBottom() async {
    if (!_scrollController.hasClients) return;
    try {
      _isProgrammaticScroll = true;
      final max = _scrollController.position.maxScrollExtent;
      await _scrollController.animateTo(
        max,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    } catch (_) {
      try {
        final max = _scrollController.position.maxScrollExtent;
        _scrollController.jumpTo(max);
      } catch (_) {}
    } finally {
      _isProgrammaticScroll = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_isProgrammaticScroll) return;
      if (!_scrollController.hasClients ||
          !_scrollController.position.hasContentDimensions) {
        return;
      }
      final max = _scrollController.position.maxScrollExtent;
      final cur = _scrollController.offset;
      // If user scrolled away from bottom by more than 20px, disable auto-scroll.
      if (max - cur > 20) {
        if (_autoScroll) setState(() => _autoScroll = false);
      } else {
        if (!_autoScroll) setState(() => _autoScroll = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _hScrollController.dispose();
    super.dispose();
  }

  Color? _statusColorForKey(String key) {
    final lines = widget.logsByFolder[key];
    if (lines == null || lines.isEmpty) return null;

    var hadNonZeroExit = false;
    var hadZeroExit = false;
    var hadErrorText = false;
    for (final ln in lines) {
      final l = ln.toLowerCase();
      if (l.contains('cjxl retry exit') || l.contains('cjxl exit')) {
        if (l.contains('exit 0')) {
          hadZeroExit = true;
        } else {
          hadNonZeroExit = true;
        }
      }
      if (l.contains('error') || l.contains('failed') || l.contains('err')) {
        hadErrorText = true;
      }
    }

    if (hadNonZeroExit || hadErrorText) return Colors.redAccent;
    if (hadZeroExit) return Colors.green;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final keys = widget.logsByFolder.keys.toList();

    return Expanded(
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
        child: keys.isEmpty
            ? const Center(child: Text('No logs yet.'))
            : Row(
                children: [
                  // Left tab column with adjustable width
                  SizedBox(
                    width: _leftWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.black12),
                        ),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: keys.length,
                        itemBuilder: (c, i) {
                          final k = keys[i];
                          final selected = i == _selected;
                          final statusColor = _statusColorForKey(k);
                          return InkWell(
                            onTap: () {
                              setState(() => _selected = i);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (_autoScroll) _scrollToBottom();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                                horizontal: 8.0,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Theme.of(context).colorScheme.primary
                                          .withAlpha((0.12 * 255).round())
                                    : null,
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 28,
                                    margin: const EdgeInsets.only(right: 8.0),
                                    decoration: BoxDecoration(
                                      color: statusColor ?? Colors.transparent,
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      k.split(RegExp(r'[\\/]')).last,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Draggable divider
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragStart: (_) =>
                        setState(() => _isDragging = true),
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        final screenWidth = MediaQuery.of(context).size.width;
                        // Allow the left column to grow up to nearly the full window width;
                        // leave a small margin so the right pane still exists and can scroll.
                        final maxAllowed = (screenWidth - 64.0).clamp(
                          _minLeftWidth,
                          double.infinity,
                        );
                        _leftWidth = (_leftWidth + details.delta.dx).clamp(
                          _minLeftWidth,
                          maxAllowed,
                        );
                      });
                    },
                    onHorizontalDragEnd: (_) =>
                        setState(() => _isDragging = false),
                    onDoubleTap: () {
                      // Expand to fit longest tab name (no ellipsis). Use the actual DefaultTextStyle
                      final dir = Directionality.of(context);
                      final TextStyle textStyle = DefaultTextStyle.of(
                        context,
                      ).style;
                      double maxTextWidth = 0.0;
                      for (final k in keys) {
                        final name = k.split(RegExp(r'[\\/]')).last;
                        final tp = TextPainter(
                          text: TextSpan(text: name, style: textStyle),
                          textDirection: dir,
                          textScaler: MediaQuery.textScalerOf(context),
                          maxLines: 1,
                        )..layout(minWidth: 0, maxWidth: double.infinity);
                        if (tp.width > maxTextWidth) maxTextWidth = tp.width;
                      }

                      const extras = 8.0 + 8.0 + 8.0 + 8.0 + 8.0 + 8.0;
                      const safetyBuffer = 24.0;
                      final desired = maxTextWidth + extras + safetyBuffer;
                      final screenWidth = MediaQuery.of(context).size.width;
                      final minLogArea = 200.0;
                      final maxAllowed = (screenWidth - minLogArea).clamp(
                        _minLeftWidth,
                        screenWidth - minLogArea,
                      );
                      final newWidth = desired.clamp(_minLeftWidth, maxAllowed);
                      setState(() => _leftWidth = newWidth);
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeLeftRight,
                      child: Container(
                        width: 8,
                        color: Colors.transparent,
                        child: Center(
                          child: Container(
                            width: _isDragging ? 2.0 : 1.0,
                            color: _isDragging
                                ? Theme.of(context).colorScheme.primary
                                      .withAlpha((0.7 * 255).round())
                                : Theme.of(context).dividerColor,
                            height: double.infinity,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Builder(
                        builder: (context) {
                          final selectedKey = keys[_selected];
                          final lines = widget.logsByFolder[selectedKey] ?? [];
                          // Use a Stack so we can overlay a resume-auto-scroll button.
                          return Stack(
                            children: [
                              Positioned.fill(
                                child: SingleChildScrollView(
                                  controller: _scrollController,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6.0,
                                      horizontal: 2.0,
                                    ),
                                    child: LayoutBuilder(
                                      builder: (ctx, constraints) {
                                        // Measure longest log line so we can avoid wrapping
                                        final dir = Directionality.of(ctx);
                                        final TextStyle textStyle =
                                            DefaultTextStyle.of(ctx).style;
                                        double maxLineWidth = 0.0;
                                        for (final line in lines) {
                                          final tp =
                                              TextPainter(
                                                text: TextSpan(
                                                  text: line,
                                                  style: textStyle,
                                                ),
                                                textDirection: dir,
                                                textScaler:
                                                    MediaQuery.textScalerOf(
                                                      ctx,
                                                    ),
                                                maxLines: 1,
                                              )..layout(
                                                minWidth: 0,
                                                maxWidth: double.infinity,
                                              );
                                          if (tp.width > maxLineWidth) {
                                            maxLineWidth = tp.width;
                                          }
                                        }

                                        // Add padding/margins similar to left calculations
                                        const sideExtras =
                                            16.0; // small safety margin
                                        final desiredWidth =
                                            (maxLineWidth + sideExtras).clamp(
                                              0.0,
                                              double.infinity,
                                            );

                                        final minWidth =
                                            desiredWidth > constraints.maxWidth
                                            ? desiredWidth
                                            : constraints.maxWidth;

                                        final overflow =
                                            desiredWidth > constraints.maxWidth;

                                        // If horizontal overflow will be present, add extra bottom padding
                                        // so the horizontal scrollbar doesn't overlap the last message.
                                        final bottomPadding = overflow
                                            ? 24.0
                                            : 6.0;

                                        return Scrollbar(
                                          controller: _hScrollController,
                                          thumbVisibility: overflow,
                                          trackVisibility: false,
                                          child: SingleChildScrollView(
                                            controller: _hScrollController,
                                            scrollDirection: Axis.horizontal,
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                minWidth: minWidth,
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                  bottom: bottomPadding,
                                                ),
                                                child: SelectableText.rich(
                                                  TextSpan(
                                                    children: List.generate(
                                                      lines.length,
                                                      (i) {
                                                        final line = lines[i];
                                                        final color =
                                                            _colorForLine(
                                                              line,
                                                              ctx,
                                                            );
                                                        final weight =
                                                            _weightForLine(
                                                              line,
                                                            );
                                                        return TextSpan(
                                                          text:
                                                              line +
                                                              (i == lines.length - 1
                                                                  ? ''
                                                                  : '\n'),
                                                          style: TextStyle(
                                                            color: color,
                                                            fontWeight: weight,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  contextMenuBuilder:
                                                      (
                                                        BuildContext ctx2,
                                                        selectableTextState,
                                                      ) {
                                                        return AdaptiveTextSelectionToolbar.buttonItems(
                                                          anchors:
                                                              selectableTextState
                                                                  .contextMenuAnchors,
                                                          buttonItems:
                                                              selectableTextState
                                                                  .contextMenuButtonItems,
                                                        );
                                                      },
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              if (!_autoScroll)
                                Positioned(
                                  right: 8,
                                  bottom: 8,
                                  child: FloatingActionButton.small(
                                    onPressed: () {
                                      setState(() => _autoScroll = true);
                                      WidgetsBinding.instance
                                          .addPostFrameCallback(
                                            (_) => _scrollToBottom(),
                                          );
                                    },
                                    tooltip: 'Resume auto-scroll',
                                    child: const Icon(Icons.arrow_downward),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

Color _colorForLine(String line, BuildContext ctx) {
  final lc = line.toLowerCase();
  if (lc.contains('error') ||
      lc.contains('failed') ||
      lc.contains('err') ||
      (lc.contains('cjxl exit') && !lc.contains('exit 0'))) {
    return Colors.redAccent;
  }
  // Storage summary lines: color by percentage saved (within parentheses):
  // >=50% -> blue, >=30% and <50% -> green, >=0% and <30% -> yellow, <0% -> red
  if (lc.contains('saved') && lc.contains('%')) {
    final reg = RegExp(r"\(([-+]?\d+(?:\.\d+)?)%\)");
    final m = reg.firstMatch(lc);
    if (m != null) {
      final pct = double.tryParse(m.group(1)!) ?? 0.0;
      if (pct >= 50.0) return Colors.blueAccent;
      if (pct >= 30.0) return Colors.greenAccent;
      if (pct >= 0.0) return Colors.amberAccent.shade700;
      return Colors.redAccent;
    }
  }
  if (lc.startsWith('done:') && lc.contains('ok')) {
    return Colors.greenAccent.shade200;
  }
  if (lc.startsWith('start:')) {
    return Theme.of(ctx).colorScheme.primary.withAlpha(220);
  }
  if (lc.contains('removed') ||
      lc.contains('deleted') ||
      lc.contains('removed duplicate')) {
    return Colors.orangeAccent;
  }
  if (lc.contains('created archive')) {
    return Colors.greenAccent;
  }
  if (lc.contains('running cjxl') || lc.contains('created safe copy')) {
    return Colors.cyanAccent;
  }
  return Theme.of(ctx).textTheme.bodyMedium?.color ??
      Theme.of(ctx).colorScheme.onSurface;
}

FontWeight _weightForLine(String line) {
  final lc = line.toLowerCase();
  if (lc.contains('error') || lc.contains('failed') || lc.contains('err')) {
    return FontWeight.w700;
  }
  if (lc.startsWith('start:') || lc.startsWith('done:')) return FontWeight.w600;
  return FontWeight.normal;
}
