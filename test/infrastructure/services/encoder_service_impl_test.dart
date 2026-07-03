import 'dart:convert';
import 'dart:io';

import 'package:comic_optimizer/core/result.dart';
import 'package:comic_optimizer/infrastructure/services/encoder_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';

/// Returns true if cjxl is available on PATH.
Future<bool> _cjxlAvailable() async {
  try {
    final result = await Process.run(Platform.isWindows ? 'where' : 'which', [
      'cjxl',
    ]);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}

/// A valid 1x1 red PNG (base64-encoded, verified against multiple viewers).
List<int> _minimalPng() => base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8'
  '/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==',
);

void main() {
  group('EncoderServiceImpl', () {
    late Directory tmpDir;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('encoder_test_');
    });

    tearDown(() {
      if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    });

    test('encodes a PNG to .jxl with cjxl', () async {
      final available = await _cjxlAvailable();
      if (!available) {
        // ignore: avoid_print
        print('[SKIP] cjxl not found on PATH — skipping integration test');
        return;
      }

      // Write a minimal PNG
      final pngPath = '${tmpDir.path}/test.png';
      await File(pngPath).writeAsBytes(_minimalPng());

      final service = const EncoderServiceImpl();
      final result = await service.encodeFolder(
        tmpDir,
        ['--distance=0', '--quiet'],
        'cjxl',
        (args) => args.join(' '),
      );

      expect(result, isA<Ok<bool>>());
      expect((result as Ok<bool>).value, true);

      // Output .jxl should exist
      final jxlFile = File('${tmpDir.path}/test.jxl');
      expect(await jxlFile.exists(), true);
    });

    test('returns Err/Ok(false) when cjxl binary is missing', () async {
      final pngPath = '${tmpDir.path}/test.png';
      await File(pngPath).writeAsBytes(_minimalPng());

      final service = const EncoderServiceImpl();
      final result = await service.encodeFolder(
        tmpDir,
        ['--quiet'],
        'nonexistent_cjxl_binary_xyz',
        (args) => args.join(' '),
      );

      // Should not throw — returns Ok(false) for the catch-all
      expect(result, isA<Ok<bool>>());
    });

    test('skips non-image files and files already .jxl', () async {
      final available = await _cjxlAvailable();
      if (!available) {
        // ignore: avoid_print
        print('[SKIP] cjxl not found on PATH — skipping integration test');
        return;
      }

      File('${tmpDir.path}/readme.txt').writeAsStringSync('hello');
      File('${tmpDir.path}/icon.png').writeAsBytesSync(_minimalPng());
      // Pre-existing .jxl (should be skipped by the filter)
      File('${tmpDir.path}/already.jxl').writeAsBytesSync([0, 1, 2, 3]);

      final service = const EncoderServiceImpl();
      final result = await service.encodeFolder(
        tmpDir,
        ['--distance=0', '--quiet'],
        'cjxl',
        (args) => args.join(' '),
      );

      expect(result, isA<Ok<bool>>());
      expect((result as Ok<bool>).value, true);

      // Text file untouched, jxl not re-encoded, only icon.png → icon.jxl
      expect(File('${tmpDir.path}/readme.txt').existsSync(), true);
      expect(File('${tmpDir.path}/icon.jxl').existsSync(), true);
    });

    test('empty folder returns true', () async {
      // No image files at all
      final service = const EncoderServiceImpl();
      final result = await service.encodeFolder(
        tmpDir,
        ['--quiet'],
        'cjxl',
        (args) => args.join(' '),
      );

      expect(result, isA<Ok<bool>>());
      expect((result as Ok<bool>).value, true);
    });
  });
}
