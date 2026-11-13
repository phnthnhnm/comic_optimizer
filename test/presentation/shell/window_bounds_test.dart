import 'package:comic_optimizer/presentation/shell/window_bounds.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('WindowBoundsStore', () {
    late SharedPreferences prefs;
    late WindowBoundsStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      store = WindowBoundsStore(prefs);
    });

    test('returns null when nothing is stored', () {
      expect(store.read(), isNull);
    });

    test('round-trips geometry and maximized state', () async {
      const rect = Rect.fromLTWH(120, 80, 1400, 900);
      await store.write(rect, true);

      final restored = store.read();
      expect(restored, isNotNull);
      expect(restored!.rect, rect);
      expect(restored.maximized, true);
    });

    test('ignores corrupted or undersized data', () async {
      await prefs.setString('window_bounds_v1', 'not json');
      expect(store.read(), isNull);

      await prefs.setString(
        'window_bounds_v1',
        '{"x":0,"y":0,"width":320,"height":200,"maximized":false}',
      );
      expect(store.read(), isNull);
    });
  });
}
