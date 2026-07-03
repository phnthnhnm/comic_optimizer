import 'package:comic_optimizer/core/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result<T>', () {
    test('Ok holds value', () {
      const result = Ok<int>(42);
      expect(result.value, 42);
    });

    test('Err holds message and optional cause', () {
      const result = Err<int>('something went wrong');
      expect(result.message, 'something went wrong');
      expect(result.cause, isNull);
    });

    test('Err with cause', () {
      final cause = Exception('root cause');
      final result = Err<int>('wrapped error', cause: cause);
      expect(result.cause, cause);
    });

    test('Ok value accessible directly', () {
      const result = Ok<String>('hello');
      expect(result.value, 'hello');
    });

    test('Err message accessible directly', () {
      const result = Err<String>('bad');
      expect(result.message, 'bad');
    });

    test('Result is sealed — Ok and Err are the only variants', () {
      const ok = Ok<int>(1);
      const err = Err<int>('msg');
      expect(ok, isA<Result<int>>());
      expect(err, isA<Result<int>>());
    });
  });
}
