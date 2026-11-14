import 'dart:io';

import 'package:comic_optimizer/core/interfaces/i_encoder_service.dart';
import 'package:comic_optimizer/core/result.dart';
import 'package:comic_optimizer/domain/enums/collision_policy.dart';
import 'package:comic_optimizer/domain/enums/output_mode.dart';
import 'package:comic_optimizer/infrastructure/services/archive_service_impl.dart';
import 'package:comic_optimizer/infrastructure/services/optimizer_service_impl.dart';
import 'package:comic_optimizer/infrastructure/services/output_path_resolver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

class _FakeEncoder implements IEncoderService {
  bool fail = false;
  int calls = 0;
  int active = 0;
  int maxActive = 0;
  Duration delay = Duration.zero;

  @override
  Future<Result<String>> probeVersion(String cjxlPath) async =>
      const Ok('fake cjxl');

  @override
  Future<Result<EncodeOutcome>> encodeImage(
    File input,
    File output,
    List<String> presetArgs,
    String cjxlPath,
    String Function(List<String>) maskArgs, {
    void Function(String)? onLog,
    bool Function()? isCancelled,
    Future<void> Function()? waitIfPaused,
  }) async {
    calls++;
    active++;
    if (active > maxActive) maxActive = active;
    try {
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      if (fail) return const Ok(EncodeOutcome(success: false));
      final size = await input.length();
      await output.writeAsBytes(List.filled(4, 1));
      return Ok(
        EncodeOutcome(
          success: true,
          encoded: true,
          originalBytes: size,
          outputBytes: 4,
        ),
      );
    } finally {
      active--;
    }
  }

  @override
  Future<Result<bool>> encodeFolder(
    Directory folder,
    List<String> presetArgs,
    String cjxlPath,
    String Function(List<String>) maskArgs, {
    void Function(String)? onLog,
    void Function(String path, int index, int total)? onFileStart,
    bool Function()? isCancelled,
    Future<void> Function()? waitIfPaused,
  }) async => const Ok(true);
}

void main() {
  group('OptimizerServiceImpl staged pipeline', () {
    late Directory tmp;
    late Directory root;
    late Directory comic;
    late _FakeEncoder encoder;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('optimizer_test_');
      root = Directory(p.join(tmp.path, 'Library'))..createSync();
      comic = Directory(p.join(root.path, 'Comic A'))..createSync();
      File(p.join(comic.path, '010.png')).writeAsStringSync('ten');
      File(p.join(comic.path, '002.png')).writeAsStringSync('two');
      File(p.join(comic.path, 'ComicInfo.xml')).writeAsStringSync('<xml/>');
      encoder = _FakeEncoder();
    });

    tearDown(() {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });

    Future<({Result<void> result, List<bool> done, List<String> logs})> run({
      bool safeRun = true,
      bool skipCjxl = false,
      bool deleteNonImageFiles = true,
      bool preferPermanentDelete = false,
      bool skipExistingArchives = false,
      Set<String> completedFolders = const {},
      int maxParallelEncodes = 2,
      OutputMode outputMode = OutputMode.besideSource,
      String outputDirectory = '',
      String namingTemplate = '{folder}',
      CollisionPolicy collisionPolicy = CollisionPolicy.overwrite,
    }) async {
      final done = <bool>[];
      final logs = <String>[];
      final result =
          await OptimizerServiceImpl(
            const ArchiveServiceImpl(),
            encoder,
          ).optimizeRoot(
            root,
            presetArgs: const ['--distance=0', '--quiet'],
            skipCjxl: skipCjxl,
            deleteNonImageFiles: deleteNonImageFiles,
            cjxlPath: 'fake',
            outputExtension: '.cbz',
            safeRun: safeRun,
            preferPermanentDelete: preferPermanentDelete,
            skipExistingArchives: skipExistingArchives,
            completedFolders: completedFolders,
            maxParallelEncodes: maxParallelEncodes,
            outputMode: outputMode,
            globalOutputDirectory: outputDirectory,
            namingTemplate: namingTemplate,
            collisionPolicy: collisionPolicy,
            onLog: logs.add,
            onFolderDone: (_, success, _, _, _, _) => done.add(success),
          );
      return (result: result, done: done, logs: logs);
    }

    test(
      'publishes a verified archive and deletes the source only after it',
      () async {
        final runResult = await run(
          safeRun: false,
          preferPermanentDelete: true,
        );

        expect(runResult.result, isA<Ok<void>>());
        expect(comic.existsSync(), false);
        expect(runResult.done, [true]);
        final archive = File(p.join(root.path, 'Comic A.cbz'));
        expect(archive.existsSync(), true);
        expect(
          runResult.logs.any((line) => line.contains('Created verified')),
          true,
        );
      },
    );

    test('keeps the source when safe run is enabled', () async {
      await run(safeRun: true);

      expect(comic.existsSync(), true);
      expect(File(p.join(root.path, 'Comic A.cbz')).existsSync(), true);
      expect(File(p.join(comic.path, '002.png')).existsSync(), true);
    });

    test(
      'an encoding failure leaves the source untouched and writes no archive',
      () async {
        encoder.fail = true;
        final runResult = await run(
          safeRun: false,
          preferPermanentDelete: true,
        );

        expect(runResult.done, [false]);
        expect(comic.existsSync(), true);
        expect(File(p.join(root.path, 'Comic A.cbz')).existsSync(), false);
        expect(
          root.listSync().where((entry) => entry.path.endsWith('.part')),
          isEmpty,
        );
      },
    );

    test(
      'skipCjxl archives normalized originals and can keep non-images',
      () async {
        await run(skipCjxl: true, deleteNonImageFiles: false);

        final archive = File(p.join(root.path, 'Comic A.cbz'));
        expect(archive.existsSync(), true);
        final bytes = await archive.readAsBytes();
        expect(bytes, isNotEmpty);
        // The fake encoder is never used when encoding is skipped.
        expect(encoder.calls, 0);
      },
    );

    test('skips an archive that is already up to date', () async {
      await run(safeRun: true, skipExistingArchives: true);
      final callsAfterFirst = encoder.calls;
      final second = await run(
        safeRun: false,
        preferPermanentDelete: true,
        skipExistingArchives: true,
      );

      expect(second.done, [true]);
      expect(comic.existsSync(), true);
      expect(encoder.calls, callsAfterFirst);
    });

    test('limits concurrent encoding to the configured value', () async {
      encoder.delay = const Duration(milliseconds: 40);
      final runResult = await run(safeRun: true, maxParallelEncodes: 2);

      expect(runResult.result, isA<Ok<void>>());
      expect(encoder.calls, 2);
      expect(encoder.maxActive, 2);
    });

    test('skips a comic recorded as completed in the journal', () async {
      final runResult = await run(
        safeRun: true,
        completedFolders: {comic.path},
      );

      expect(runResult.done, [true]);
      expect(encoder.calls, 0);
      expect(comic.existsSync(), true);
      expect(File(p.join(root.path, 'Comic A.cbz')).existsSync(), false);
    });

    test('uses a custom output directory and naming template', () async {
      final output = Directory(p.join(tmp.path, 'Output'))..createSync();
      await run(
        safeRun: true,
        outputMode: OutputMode.custom,
        outputDirectory: output.path,
        namingTemplate: '{library} - {folder}',
      );

      expect(
        File(p.join(output.path, 'Library - Comic A.cbz')).existsSync(),
        true,
      );
    });

    test('archive target inside the source is rejected', () async {
      final runResult = await run(
        safeRun: true,
        outputMode: OutputMode.custom,
        outputDirectory: comic.path,
      );

      expect(runResult.done, [false]);
      expect(comic.existsSync(), true);
    });

    test('output path resolver sanitizes Windows-invalid names', () async {
      final target = await const OutputPathResolver().resolve(
        libraryPath: root.path,
        comicPath: comic.path,
        presetName: 'Lossless',
        outputExtension: '.cbz',
        outputMode: OutputMode.custom,
        globalOutputDirectory: tmp.path,
        namingTemplate: 'CON',
        collisionPolicy: CollisionPolicy.overwrite,
      );
      expect(p.basename(target), 'CON_.cbz');
    });
  });
}
