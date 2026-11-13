import 'package:go_router/go_router.dart';

import 'package:comic_optimizer/features/home/screens/home_screen.dart';
import 'package:comic_optimizer/features/settings/screens/settings_screen.dart';
import 'package:comic_optimizer/presentation/shell/app_shell.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
