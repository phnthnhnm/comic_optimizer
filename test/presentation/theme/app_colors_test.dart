import 'package:comic_optimizer/domain/enums/run_log_level.dart';
import 'package:comic_optimizer/presentation/design_system/catppuccin.dart';
import 'package:comic_optimizer/presentation/theme/app_colors.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppColors.colorForLevel', () {
    testWidgets('maps severity to Catppuccin colours', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      expect(AppColors.colorForLevel(RunLogLevel.error, ctx), Catppuccin.red);
      expect(
        AppColors.colorForLevel(RunLogLevel.warning, ctx),
        Catppuccin.peach,
      );
      expect(
        AppColors.colorForLevel(RunLogLevel.success, ctx),
        Catppuccin.green,
      );
      expect(AppColors.colorForLevel(RunLogLevel.info, ctx), isA<Color>());
    });
  });

  group('AppColors.weightForLevel', () {
    test('emphasises non-info severities', () {
      expect(AppColors.weightForLevel(RunLogLevel.error), FontWeight.w700);
      expect(AppColors.weightForLevel(RunLogLevel.warning), FontWeight.w600);
      expect(AppColors.weightForLevel(RunLogLevel.success), FontWeight.w600);
      expect(AppColors.weightForLevel(RunLogLevel.info), FontWeight.normal);
    });
  });
}
