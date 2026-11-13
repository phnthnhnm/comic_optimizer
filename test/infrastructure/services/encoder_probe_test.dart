import 'dart:io';

import 'package:comic_optimizer/core/result.dart';
import 'package:comic_optimizer/infrastructure/services/encoder_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_process_runner.dart';

void main() {
  group('EncoderServiceImpl.probeVersion', () {
    late FakeProcessRunner runner;
    late EncoderServiceImpl service;

    setUp(() {
      runner = FakeProcessRunner();
      service = EncoderServiceImpl(runner: runner);
    });

    test('returns the first version line', () async {
      runner.onRun = (executable, arguments) async {
        return ProcessResult(0, 0, 'cjxl v0.13.0 abc123\nbuilt on Linux', '');
      };

      final result = await service.probeVersion('cjxl');

      expect(result, isA<Ok<String>>());
      expect((result as Ok<String>).value, 'cjxl v0.13.0 abc123');
      expect(runner.calls.single.executable, 'cjxl');
      expect(runner.calls.single.arguments, ['--version']);
    });

    test('returns stderr when the encoder exits non-zero', () async {
      runner.onRun = (executable, arguments) async {
        return ProcessResult(0, 1, '', 'not a cjxl binary\nmore detail');
      };

      final result = await service.probeVersion('broken');

      expect(result, isA<Err<String>>());
      expect((result as Err<String>).message, 'not a cjxl binary');
    });

    test('reports a missing executable', () async {
      runner.onRun = (executable, arguments) async {
        throw const ProcessException('cjxl', ['--version'], 'not found', 2);
      };

      final result = await service.probeVersion('missing');

      expect(result, isA<Err<String>>());
      expect((result as Err<String>).message, isNotEmpty);
    });

    test('handles empty output', () async {
      runner.onRun = (executable, arguments) async {
        return ProcessResult(0, 0, '', '');
      };

      final result = await service.probeVersion('cjxl');
      expect((result as Ok<String>).value, 'cjxl (unknown version)');
    });
  });
}
