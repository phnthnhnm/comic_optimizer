import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:comic_optimizer/core/result.dart';
import 'package:comic_optimizer/infrastructure/services/archive_service_impl.dart';
import 'package:comic_optimizer/infrastructure/services/encoder_service_impl.dart';
import 'package:comic_optimizer/infrastructure/services/optimizer_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

List<int> _minimalPng() => base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8'
  '/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==',
);

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

void main() {
  test('real cjxl pipeline publishes a verified archive', () async {
    if (!await _cjxlAvailable()) {
      // ignore: avoid_print
      print('[SKIP] cjxl not found on PATH');
      return;
    }

    final tmp = await Directory.systemTemp.createTemp('real_pipeline_');
    addTearDown(() {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });
    final root = Directory(p.join(tmp.path, 'Library'))..createSync();
    final comic = Directory(p.join(root.path, 'Comic A'))..createSync();
    File(p.join(comic.path, '001.png')).writeAsBytesSync(_minimalPng());
    File(p.join(comic.path, '002.png')).writeAsBytesSync(_minimalPng());

    final done = <bool>[];
    final result =
        await OptimizerServiceImpl(
          const ArchiveServiceImpl(),
          const EncoderServiceImpl(),
        ).optimizeRoot(
          root,
          presetArgs: const ['--distance=0', '--lossless_jpeg=1', '--quiet'],
          skipCjxl: false,
          deleteNonImageFiles: true,
          cjxlPath: 'cjxl',
          outputExtension: '.cbz',
          safeRun: false,
          preferPermanentDelete: true,
          presetName: 'Lossless',
          onLog: (_) {},
          onFolderDone: (_, success, _, _, _, _) => done.add(success),
        );

    expect(result, isA<Ok<void>>());
    expect(done, [true]);
    expect(comic.existsSync(), false);
    final archiveFile = File(p.join(root.path, 'Comic A.cbz'));
    expect(archiveFile.existsSync(), true);
    final archive = ZipDecoder().decodeBytes(await archiveFile.readAsBytes());
    expect(archive.files, hasLength(2));
    expect(archive.files.map((file) => file.name), ['001.jxl', '002.jxl']);
    expect(
      root.listSync().where((entry) => entry.path.contains('.part')),
      isEmpty,
    );
  });
}
