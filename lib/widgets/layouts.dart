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
                        return InkWell(
                          onTap: () => setState(() => _selected = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 8.0,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.12)
                                  : null,
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Text(
                              k.split(RegExp(r'[\\/]')).last,
                              overflow: TextOverflow.ellipsis,
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
                            itemBuilder: (c, i) => Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Text(lines[i]),
                            ),
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
