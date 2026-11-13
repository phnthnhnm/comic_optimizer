import 'package:comic_optimizer/presentation/design_system/app_theme.dart';
import 'package:comic_optimizer/presentation/design_system/catppuccin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('AppTheme', () {
    test('is the fixed Catppuccin Mocha dark theme', () {
      final theme = AppTheme.mocha;
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, Catppuccin.base);
      expect(theme.colorScheme.surface, Catppuccin.base);
      expect(theme.colorScheme.onSurface, Catppuccin.text);
      expect(theme.colorScheme.primary, Catppuccin.green);
      expect(theme.colorScheme.onPrimary, Catppuccin.base);
      expect(theme.colorScheme.error, Catppuccin.red);
    });

    test('uses green for progress and selection accents', () {
      final theme = AppTheme.mocha;
      expect(theme.progressIndicatorTheme.color, Catppuccin.green);
      expect(theme.colorScheme.surfaceTint, Catppuccin.green);
    });
  });
}
