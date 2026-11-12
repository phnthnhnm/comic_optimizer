import 'dart:convert';
import 'dart:io';

import 'package:comic_optimizer/core/interfaces/i_process_runner.dart';
import 'package:comic_optimizer/core/result.dart';
import 'package:comic_optimizer/infrastructure/services/encoder_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Records process invocations and lets each test decide what the external
/// binaries "do" (including writing output files).
class FakeProcessRunner implements IProcessRunner {
  final List<ProcessCall> calls = [];

  Future<ProcessResult> Function(String executable, List<String> arguments)?
  onRun;

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) async {
    calls.add(ProcessCall(executable, arguments, workingDirectory));
    final handler = onRun;
    if (handler == null) return ProcessResult(0, 0, '', '');
    return handler(executable, arguments);
  }
}

class ProcessCall {
  final String executable;
  final List<String> arguments;
  final String? workingDirectory;

  const ProcessCall(this.executable, this.arguments, this.workingDirectory);
}

List<int> _minimalPng() => base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8'
  '/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==',
);

void main() {
  group('EncoderServiceImpl', () {
    late Directory tmp;
    late FakeProcessRunner runner;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('encoder_unit_');
      runner = FakeProcessRunner();
    });

    tearDown(() {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });

    Future<Result<bool>> encode({
      List<String> presetArgs = const ['--distance=0', '--quiet'],
      bool Function()? isCancelled,
      void Function(String)? onLog,
    }) {
      return EncoderServiceImpl(runner: runner).encodeFolder(
        tmp,
        presetArgs,
        'cjxl',
        (args) => args.join(' '),
        isCancelled: isCancelled,
        onLog: onLog,
      );
    }

    test('encodes a PNG with the preset arguments', () async {
      final input = p.join(tmp.path, '001.png');
      final output = p.join(tmp.path, '001.jxl');
      await File(input).writeAsBytes(_minimalPng());
      runner.onRun = (exe, args) async {
        await File(args[1]).writeAsBytes([1, 2, 3]);
        return ProcessResult(0, 0, '', '');
      };

      final result = await encode();

      expect((result as Ok<bool>).value, true);
      expect(runner.calls, hasLength(1));
      expect(runner.calls.single.executable, 'cjxl');
      expect(runner.calls.single.arguments, [
        input,
        output,
        '--distance=0',
        '--quiet',
      ]);
      expect(File(output).existsSync(), true);
    });

    test('retries through ImageMagick after exit code 1', () async {
      final input = p.join(tmp.path, '001.png');
      final output = p.join(tmp.path, '001.jxl');
      await File(input).writeAsBytes(_minimalPng());
      var cjxlCalls = 0;
      runner.onRun = (exe, args) async {
        if (exe == 'cjxl') {
          cjxlCalls++;
          if (cjxlCalls == 1) return ProcessResult(0, 1, '', 'transcode failed');
          await File(args[1]).writeAsBytes([1, 2, 3]);
          return ProcessResult(0, 0, '', '');
        }
        if (exe == 'magick') {
          await File(args[2]).writeAsBytes(_minimalPng());
          return ProcessResult(0, 0, '', '');
        }
        return ProcessResult(0, 0, '', '');
      };

      final logs = <String>[];
      final result = await encode(onLog: logs.add);

      expect((result as Ok<bool>).value, true);
      expect(
        runner.calls.where((call) => call.executable == 'cjxl'),
        hasLength(2),
      );
      final magick = runner.calls.singleWhere(
        (call) => call.executable == 'magick',
      );
      expect(magick.arguments[0], input);
      expect(magick.arguments[1], '-strip');
      expect(magick.arguments[2], endsWith('.png'));
      expect(File(output).existsSync(), true);
      expect(logs.any((line) => line.contains('Retrying cjxl')), true);
    });

    test('reports failure for other exit codes without retrying', () async {
      await File(
        p.join(tmp.path, '001.png'),
      ).writeAsBytes(_minimalPng());
      runner.onRun = (exe, args) async => ProcessResult(0, 2, '', 'boom');

      final result = await encode();

      expect((result as Ok<bool>).value, false);
      expect(runner.calls, hasLength(1));
    });

    test('deletes a jxl that is not smaller than the original', () async {
      final input = p.join(tmp.path, '001.png');
      final output = p.join(tmp.path, '001.jxl');
      await File(input).writeAsBytes(List.filled(100, 7));
      runner.onRun = (exe, args) async {
        await File(args[1]).writeAsBytes(List.filled(200, 1));
        return ProcessResult(0, 0, '', '');
      };

      final logs = <String>[];
      final result = await encode(onLog: logs.add);

      expect((result as Ok<bool>).value, true);
      expect(File(output).existsSync(), false);
      expect(File(input).existsSync(), true);
      expect(logs.any((line) => line.contains('Reverted larger')), true);
    });

    test('converts webp to png before encoding', () async {
      final webp = p.join(tmp.path, '001.webp');
      final png = p.join(tmp.path, '001.png');
      await File(webp).writeAsBytes([1, 2, 3]);
      runner.onRun = (exe, args) async {
        if (exe == 'dwebp') {
          await File(args[2]).writeAsBytes(_minimalPng());
        } else if (exe == 'cjxl') {
          await File(args[1]).writeAsBytes([1, 2, 3]);
        }
        return ProcessResult(0, 0, '', '');
      };

      final result = await encode();

      expect((result as Ok<bool>).value, true);
      expect(runner.calls.first.executable, 'dwebp');
      expect(runner.calls.first.arguments, [
        webp,
        '-o',
        png,
        '-mt',
        '-quiet',
      ]);
      final cjxl = runner.calls.firstWhere((call) => call.executable == 'cjxl');
      expect(cjxl.arguments[0], png);
    });

    test('stops before encoding when cancelled', () async {
      await File(
        p.join(tmp.path, '001.png'),
      ).writeAsBytes(_minimalPng());
      runner.onRun = (exe, args) async => ProcessResult(0, 0, '', '');

      final result = await encode(isCancelled: () => true);

      expect((result as Ok<bool>).value, true);
      expect(runner.calls, isEmpty);
    });

    test('returns Ok(false) when the runner throws', () async {
      await File(
        p.join(tmp.path, '001.png'),
      ).writeAsBytes(_minimalPng());
      runner.onRun = (exe, args) async =>
          throw ProcessException(exe, args, 'not found');

      final result = await encode();

      expect((result as Ok<bool>).value, false);
    });
  });
}
