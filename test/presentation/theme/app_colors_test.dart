import 'package:comic_optimizer/presentation/design_system/catppuccin.dart';
import 'package:comic_optimizer/presentation/theme/app_colors.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppColors.colorForLine', () {
    testWidgets('error lines return Catppuccin red', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      expect(
        AppColors.colorForLine('Error: something failed', ctx),
        Catppuccin.red,
      );
      expect(AppColors.colorForLine('failed to process', ctx), Catppuccin.red);
      expect(AppColors.colorForLine('an err occurred', ctx), Catppuccin.red);
    });

    testWidgets('cjxl non-zero exit returns Catppuccin red', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      expect(AppColors.colorForLine('cjxl exit 1', ctx), Catppuccin.red);
    });

    testWidgets('cjxl exit 0 does NOT return red', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      final color = AppColors.colorForLine('cjxl exit 0', ctx);
      expect(color, isNot(Catppuccin.red));
    });

    testWidgets('storage saved >= 50% returns Catppuccin blue', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      expect(
        AppColors.colorForLine('Storage saved: saved 5.00 MB (50.00%)', ctx),
        Catppuccin.blue,
      );
      expect(
        AppColors.colorForLine('saved 10.00 MB (75.50%)', ctx),
        Catppuccin.blue,
      );
    });

    testWidgets('storage saved >= 30% and < 50% returns Catppuccin green', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      expect(
        AppColors.colorForLine('saved 1.00 MB (30.00%)', ctx),
        Catppuccin.green,
      );
      expect(
        AppColors.colorForLine('saved 1.00 MB (49.99%)', ctx),
        Catppuccin.green,
      );
    });

    testWidgets('storage saved >= 0% and < 30% returns Catppuccin yellow', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      expect(
        AppColors.colorForLine('saved 0.10 MB (0.00%)', ctx),
        Catppuccin.yellow,
      );
      expect(
        AppColors.colorForLine('saved 0.10 MB (29.99%)', ctx),
        Catppuccin.yellow,
      );
    });

    testWidgets('storage saved < 0% (negative) returns Catppuccin red', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      expect(
        AppColors.colorForLine('saved 1.00 MB (-5.00%)', ctx),
        Catppuccin.red,
      );
    });

    testWidgets('start: lines use primary color', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      final color = AppColors.colorForLine('Start: myfolder', ctx);
      expect(color, isNotNull);
      expect(color, isNot(Catppuccin.red));
    });

    testWidgets('done with ok returns Catppuccin green', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      expect(
        AppColors.colorForLine('Done: myfolder (OK)', ctx),
        Catppuccin.green,
      );
    });

    testWidgets('removed/deleted lines return Catppuccin peach', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      expect(
        AppColors.colorForLine('Removed duplicate original', ctx),
        Catppuccin.peach,
      );
      expect(
        AppColors.colorForLine('deleted non-image', ctx),
        Catppuccin.peach,
      );
      expect(
        AppColors.colorForLine('removed duplicate foo.png', ctx),
        Catppuccin.peach,
      );
    });

    testWidgets('created archive returns Catppuccin green', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      expect(
        AppColors.colorForLine('Created archive mycomic.cbz', ctx),
        Catppuccin.green,
      );
    });

    testWidgets('running cjxl returns Catppuccin teal', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      expect(
        AppColors.colorForLine('Running cjxl: cjxl file.png file.jxl', ctx),
        Catppuccin.teal,
      );
      expect(AppColors.colorForLine('Created safe copy', ctx), Catppuccin.teal);
    });

    testWidgets('plain text falls back to default text color', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      final color = AppColors.colorForLine('some ordinary log message', ctx);
      expect(color, isNotNull);
      expect(color, isNot(Catppuccin.red));
      expect(color, isNot(Catppuccin.green));
      expect(color, isNot(Catppuccin.peach));
      expect(color, isNot(Catppuccin.teal));
    });
  });

  group('AppColors.weightForLine', () {
    test('error lines are bold', () {
      expect(AppColors.weightForLine('Error: fail'), FontWeight.w700);
      expect(AppColors.weightForLine('failed'), FontWeight.w700);
      expect(AppColors.weightForLine('err'), FontWeight.w700);
    });

    test('start/done lines are semi-bold', () {
      expect(AppColors.weightForLine('Start: folder'), FontWeight.w600);
      expect(AppColors.weightForLine('Done: folder (OK)'), FontWeight.w600);
    });

    test('ordinary lines are normal weight', () {
      expect(AppColors.weightForLine('some log'), FontWeight.normal);
    });
  });
}
