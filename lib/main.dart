import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:comic_optimizer/core/providers/shared_preferences_provider.dart';
import 'package:comic_optimizer/core/router.dart';
import 'package:comic_optimizer/features/settings/providers/settings_provider.dart';
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

class ComicOptimizerApp extends ConsumerWidget {
  const ComicOptimizerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animationsEnabled = ref.watch(
      settingsProvider.select((settings) => settings.animationsEnabled),
    );
    final theme = AppTheme.mocha(animationsEnabled: animationsEnabled);

    return MaterialApp.router(
      title: 'Comic Optimizer',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            disableAnimations: !animationsEnabled || media.disableAnimations,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
