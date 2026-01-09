import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeManager.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Comic Optimizer',
          theme: ThemeData(primarySwatch: Colors.indigo),
          darkTheme: ThemeData.dark(),
          themeMode: mode,
          home: const HomePage(),
        );
      },
    );
  }
}
