import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:comic_optimizer/core/providers/shared_preferences_provider.dart';
import 'package:comic_optimizer/core/router.dart';
import 'package:comic_optimizer/presentation/design_system/app_theme.dart';
import 'package:comic_optimizer/presentation/shell/window_bounds.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  try {
    await configureWindow(prefs);
  } catch (error) {
    // Window chrome is a polish layer; never stop the app from starting.
    debugPrint('Window setup failed: $error');
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ComicOptimizerApp(),
    ),
  );
}

class ComicOptimizerApp extends StatelessWidget {
  const ComicOptimizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Comic Optimizer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mocha,
      darkTheme: AppTheme.mocha,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
