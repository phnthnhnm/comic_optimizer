import 'package:flutter/material.dart';

class LogsPanel extends StatefulWidget {
  final Map<String, List<String>> logsByFolder;

  const LogsPanel({super.key, required this.logsByFolder});

  @override
  State<LogsPanel> createState() => _LogsPanelState();
}

class _LogsPanelState extends State<LogsPanel> {
  int _selected = 0;

  @override
  void didUpdateWidget(covariant LogsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final keys = widget.logsByFolder.keys.toList();
    if (keys.isEmpty) {
      _selected = 0;
    } else if (_selected >= keys.length) {
      _selected = keys.length - 1;
    }
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
                          onTap: () => setState(() => _selected = i),
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
                          return ListView.builder(
                            itemCount: lines.length,
                            itemBuilder: (c, i) {
                              final line = lines[i];
                              final color = _colorForLine(line, context);
                              final weight = _weightForLine(line);
                              return Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(
                                  line,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: weight,
                                  ),
                                ),
                              );
                            },
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
      (lc.contains('pingo exit') && !lc.contains('exit 0'))) {
    return Colors.redAccent;
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
  if (lc.contains('running pingo') || lc.contains('pingo')) {
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
