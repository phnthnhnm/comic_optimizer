import 'package:flutter/material.dart';

class LogsPanel extends StatelessWidget {
  final Map<String, List<String>> logsByFolder;

  const LogsPanel({super.key, required this.logsByFolder});

  @override
  Widget build(BuildContext context) {
    final keys = logsByFolder.keys.toList();

    if (keys.isEmpty) {
      return Expanded(
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
          child: const Text('No logs yet.'),
        ),
      );
    }

    return Expanded(
      child: DefaultTabController(
        length: keys.length,
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
          child: Column(
            children: [
              Material(
                color: Colors.transparent,
                child: TabBar(
                  isScrollable: true,
                  tabs: keys
                      .map((k) => Tab(text: k.split(RegExp(r'[\\/]')).last))
                      .toList(),
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: keys.map((k) {
                    final lines = logsByFolder[k] ?? [];
                    return ListView.builder(
                      itemCount: lines.length,
                      itemBuilder: (c, i) => Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Text(lines[i]),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
