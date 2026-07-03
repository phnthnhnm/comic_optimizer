import 'package:comic_optimizer/domain/enums/log_level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LogLevel', () {
    test('all values are defined', () {
      expect(LogLevel.values, hasLength(3));
      expect(LogLevel.values, contains(LogLevel.none));
      expect(LogLevel.values, contains(LogLevel.normal));
      expect(LogLevel.values, contains(LogLevel.error));
    });

    group('fromName', () {
      test('round-trips all values', () {
        for (final level in LogLevel.values) {
          final name = level.toName;
          final parsed = LogLevelX.fromName(name);
          expect(parsed, level);
        }
      });

      test('handles unknown input', () {
        expect(LogLevelX.fromName('invalid'), LogLevel.none);
        expect(LogLevelX.fromName(''), LogLevel.none);
      });

      test('handles known names exactly', () {
        expect(LogLevelX.fromName('none'), LogLevel.none);
        expect(LogLevelX.fromName('normal'), LogLevel.normal);
        expect(LogLevelX.fromName('error'), LogLevel.error);
      });
    });

    group('toName', () {
      test('produces correct strings', () {
        expect(LogLevel.none.toName, 'none');
        expect(LogLevel.normal.toName, 'normal');
        expect(LogLevel.error.toName, 'error');
      });
    });
  });
}
