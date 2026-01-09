import 'package:flutter/material.dart';

class LogsPanel extends StatelessWidget {
  final List<String> logs;

  const LogsPanel({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
        child: ListView.builder(
          itemCount: logs.length,
          itemBuilder: (c, i) =>
              Padding(padding: const EdgeInsets.all(6.0), child: Text(logs[i])),
        ),
      ),
    );
  }
}
