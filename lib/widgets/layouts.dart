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
  bool _autoScroll = true;
  bool _isProgrammaticScroll = false;
  final Map<String, int> _lastCounts = {};

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
    super.dispose();
  }

  Color? _statusColorForKey(String key) {
    final lines = widget.logsByFolder[key];
    if (lines == null || lines.isEmpty) return null;

    for (final ln in lines) {
      final l = ln.toLowerCase();
      if (l.contains('error') || l.contains('err') || l.contains('failed')) {
        return Colors.redAccent;
      }
    }

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
                  Container(
                    width: 220,
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.black12)),
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
                  const VerticalDivider(width: 1),
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
                              ListView.builder(
                                controller: _scrollController,
                                itemCount: lines.length,
                                itemBuilder: (c, i) {
                                  final line = lines[i];
                                  final color = _colorForLine(line, context);
                                  final weight = _weightForLine(line);
                                  final bg = _bgForLine(line, context, i);
                                  return Container(
                                    color: bg,
                                    child: Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Text(
                                        line,
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: weight,
                                        ),
                                      ),
                                    ),
                                  );
                                },
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
  // >=35% -> green, >=15% -> yellow, <15% -> red
  if (lc.contains('saved') && lc.contains('%')) {
    final reg = RegExp(r"\(([-+]?\d+(?:\.\d+)?)%\)");
    final m = reg.firstMatch(lc);
    if (m != null) {
      final pct = double.tryParse(m.group(1)!) ?? 0.0;
      if (pct >= 35.0) return Colors.greenAccent;
      if (pct >= 15.0) return Colors.amberAccent.shade700;
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

Color? _bgForLine(String line, BuildContext ctx, int index) {
  final lc = line.toLowerCase();
  // Slight zebra striping for readability
  final base = index % 2 == 0
      ? Theme.of(ctx).colorScheme.surface.withAlpha(8)
      : null;
  if (lc.contains('error') || lc.contains('failed') || lc.contains('err')) {
    return Colors.redAccent.withAlpha(30);
  }
  if (lc.startsWith('done:') && lc.contains('ok')) {
    return Colors.green.withAlpha(30);
  }
  if (lc.startsWith('start:')) {
    return Theme.of(ctx).colorScheme.primary.withAlpha(16);
  }
  if (lc.contains('removed') ||
      lc.contains('deleted') ||
      lc.contains('removed duplicate')) {
    return Colors.orange.withAlpha(20);
  }
  if (lc.contains('created archive')) return Colors.green.withAlpha(16);
  if (lc.contains('running cjxl') || lc.contains('created safe copy')) {
    return Colors.cyan.withAlpha(16);
  }
  return base;
}
