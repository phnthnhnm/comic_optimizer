import 'package:flutter/material.dart';

import '../../theme_manager.dart';

class AppearanceTab extends StatelessWidget {
  const AppearanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeMode,
      builder: (context, mode, _) {
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text(
              'Theme',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 8),
            DropdownButtonFormField<ThemeMode>(
              initialValue: mode,
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System'),
                ),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (v) {
                if (v != null) ThemeManager.setThemeMode(v);
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        );
      },
    );
  }
}
