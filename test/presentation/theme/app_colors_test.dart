import 'package:comic_optimizer/presentation/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppColors.colorForLine', () {
    testWidgets('error lines return redAccent', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      expect(
        AppColors.colorForLine('Error: something failed', ctx),
        Colors.redAccent,
      );
      expect(
        AppColors.colorForLine('failed to process', ctx),
        Colors.redAccent,
      );
      expect(AppColors.colorForLine('an err occurred', ctx), Colors.redAccent);
    });

    testWidgets('cjxl non-zero exit returns redAccent', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      expect(AppColors.colorForLine('cjxl exit 1', ctx), Colors.redAccent);
    });

    testWidgets('cjxl exit 0 does NOT return redAccent', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      final color = AppColors.colorForLine('cjxl exit 0', ctx);
      expect(color, isNot(Colors.redAccent));
    });

    testWidgets('storage saved >= 50% returns blueAccent', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      expect(
        AppColors.colorForLine('Storage saved: saved 5.00 MB (50.00%)', ctx),
        Colors.blueAccent,
      );
      expect(
        AppColors.colorForLine('saved 10.00 MB (75.50%)', ctx),
        Colors.blueAccent,
      );
    });

    testWidgets('storage saved >= 30% and < 50% returns greenAccent', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      expect(
        AppColors.colorForLine('saved 1.00 MB (30.00%)', ctx),
        Colors.greenAccent,
      );
      expect(
        AppColors.colorForLine('saved 1.00 MB (49.99%)', ctx),
        Colors.greenAccent,
      );
    });

    testWidgets('storage saved >= 0% and < 30% returns amber', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      expect(
        AppColors.colorForLine('saved 0.10 MB (0.00%)', ctx),
        isA<Color>(),
      );
      expect(
        AppColors.colorForLine('saved 0.10 MB (29.99%)', ctx),
        isA<Color>(),
      );
    });

    testWidgets('storage saved < 0% (negative) returns redAccent', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      expect(
        AppColors.colorForLine('saved 1.00 MB (-5.00%)', ctx),
        Colors.redAccent,
      );
    });

    testWidgets('start: lines use primary color', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      final color = AppColors.colorForLine('Start: myfolder', ctx);
      // Should be the theme's primary color with alpha (not redAccent or
      // greenAccent)
      expect(color, isNotNull);
      expect(color, isNot(Colors.redAccent));
    });

    testWidgets('done with ok returns greenAccent shade', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      expect(
        AppColors.colorForLine('Done: myfolder (OK)', ctx),
        Colors.greenAccent.shade200,
      );
    });

    testWidgets('removed/deleted lines return orangeAccent', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      expect(
        AppColors.colorForLine('Removed duplicate original', ctx),
        Colors.orangeAccent,
      );
      expect(
        AppColors.colorForLine('deleted non-image', ctx),
        Colors.orangeAccent,
      );
      expect(
        AppColors.colorForLine('removed duplicate foo.png', ctx),
        Colors.orangeAccent,
      );
    });

    testWidgets('created archive returns greenAccent', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      expect(
        AppColors.colorForLine('Created archive mycomic.cbz', ctx),
        Colors.greenAccent,
      );
    });

    testWidgets('running cjxl returns cyanAccent', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      expect(
        AppColors.colorForLine('Running cjxl: cjxl file.png file.jxl', ctx),
        Colors.cyanAccent,
      );
      expect(
        AppColors.colorForLine('Created safe copy', ctx),
        Colors.cyanAccent,
      );
    });

    testWidgets('plain text falls back to default text color', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      final color = AppColors.colorForLine('some ordinary log message', ctx);
      expect(color, isNotNull);
      // Should not be any of the special colors
      expect(color, isNot(Colors.redAccent));
      expect(color, isNot(Colors.greenAccent));
      expect(color, isNot(Colors.orangeAccent));
      expect(color, isNot(Colors.cyanAccent));
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
