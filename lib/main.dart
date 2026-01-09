import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'settings/settings_model.dart';
import 'settings/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = SettingsRepository();
  final model = SettingsModel(repo);
  await model.load();
  runApp(ChangeNotifierProvider.value(value: model, child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<SettingsModel>();
    return MaterialApp(
      title: 'Comic Optimizer',
      theme: ThemeData(primarySwatch: Colors.indigo),
      darkTheme: ThemeData.dark(),
      themeMode: model.themeMode,
      home: const HomePage(),
    );
  }
}
