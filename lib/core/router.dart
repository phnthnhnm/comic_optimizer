import 'package:go_router/go_router.dart';

import 'package:comic_optimizer/features/home/screens/home_screen.dart';
import 'package:comic_optimizer/features/settings/screens/settings_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
