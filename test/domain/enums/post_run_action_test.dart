import 'package:comic_optimizer/domain/enums/post_run_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PostRunAction', () {
    test('all values are defined', () {
      expect(PostRunAction.values, hasLength(6));
      expect(PostRunAction.values, contains(PostRunAction.none));
      expect(PostRunAction.values, contains(PostRunAction.quit));
      expect(PostRunAction.values, contains(PostRunAction.sleep));
      expect(PostRunAction.values, contains(PostRunAction.hibernate));
      expect(PostRunAction.values, contains(PostRunAction.shutdown));
      expect(PostRunAction.values, contains(PostRunAction.restart));
    });

    group('fromName', () {
      test('round-trips all values', () {
        for (final action in PostRunAction.values) {
          final name = action.toName;
          final parsed = PostRunActionX.fromName(name);
          expect(parsed, action);
        }
      });

      test('handles unknown input', () {
        expect(PostRunActionX.fromName('invalid'), PostRunAction.none);
        expect(PostRunActionX.fromName(''), PostRunAction.none);
      });

      test('handles known names exactly', () {
        expect(PostRunActionX.fromName('none'), PostRunAction.none);
        expect(PostRunActionX.fromName('quit'), PostRunAction.quit);
        expect(PostRunActionX.fromName('sleep'), PostRunAction.sleep);
        expect(PostRunActionX.fromName('hibernate'), PostRunAction.hibernate);
        expect(PostRunActionX.fromName('shutdown'), PostRunAction.shutdown);
        expect(PostRunActionX.fromName('restart'), PostRunAction.restart);
      });
    });

    group('toName', () {
      test('produces correct strings', () {
        expect(PostRunAction.none.toName, 'none');
        expect(PostRunAction.quit.toName, 'quit');
        expect(PostRunAction.sleep.toName, 'sleep');
        expect(PostRunAction.hibernate.toName, 'hibernate');
        expect(PostRunAction.shutdown.toName, 'shutdown');
        expect(PostRunAction.restart.toName, 'restart');
      });
    });
  });
}
