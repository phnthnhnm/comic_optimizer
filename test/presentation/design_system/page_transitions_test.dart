import 'package:comic_optimizer/presentation/design_system/app_theme.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openSecondPage(
    WidgetTester tester, {
    required bool animationsEnabled,
  }) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.mocha(animationsEnabled: animationsEnabled),
        navigatorKey: navigatorKey,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => navigatorKey.currentState!.push(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Text('Second')),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
  }

  testWidgets('page transitions fade without zooming', (tester) async {
    await openSecondPage(tester, animationsEnabled: true);

    final fades = find.ancestor(
      of: find.text('Second'),
      matching: find.byType(FadeTransition),
    );
    expect(fades, findsWidgets);
    expect(
      tester.widget<FadeTransition>(fades.first).opacity.value,
      lessThan(1),
    );
    expect(
      find.ancestor(
        of: find.text('Second'),
        matching: find.byType(ScaleTransition),
      ),
      findsNothing,
    );

    await tester.pumpAndSettle();
    expect(find.text('Second'), findsOneWidget);
  });

  testWidgets('disabling animations removes the page fade', (tester) async {
    await openSecondPage(tester, animationsEnabled: false);

    expect(find.text('Second'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Second'),
        matching: find.byType(FadeTransition),
      ),
      findsNothing,
    );
    expect(
      find.ancestor(
        of: find.text('Second'),
        matching: find.byType(ScaleTransition),
      ),
      findsNothing,
    );
  });
}
