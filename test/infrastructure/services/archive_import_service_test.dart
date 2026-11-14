import 'dart:io';

import 'package:archive/archive.dart';
import 'package:comic_optimizer/core/interfaces/i_optimizer_service.dart';
import 'package:comic_optimizer/core/result.dart';
import 'package:comic_optimizer/domain/enums/collision_policy.dart';
import 'package:comic_optimizer/domain/enums/output_mode.dart';
import 'package:comic_optimizer/domain/models/app_settings.dart';
import 'package:comic_optimizer/infrastructure/services/archive_import_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

class _FakeOptimizer implements IOptimizerService {
  @override
  Future<Result<void>> optimizeRoot(
    Directory root, {
    required List<String> presetArgs,
    required bool skipCjxl,
    required bool deleteNonImageFiles,
    required String cjxlPath,
    required String outputExtension,
    bool safeRun = false,
    bool preferPermanentDelete = false,
    String presetName = '',
    String namingTemplate = '{folder}',
    String globalOutputDirectory = '',
    String? libraryOutputDirectory,
    OutputMode outputMode = OutputMode.besideSource,
    CollisionPolicy collisionPolicy = CollisionPolicy.overwrite,
    bool skipExistingArchives = false,
    int maxParallelEncodes = 2,
    Set<String> completedFolders = const {},
    void Function(String)? onLog,
    void Function(String, String, int, int)? onFileStart,
    void Function(String)? onFolderStart,
    void Function(
      String,
      bool,
      int?,
      int?,
      Map<String, Map<String, int?>>?,
      String?,
    )?
    onFolderDone,
  }) async {
    final comic = root.listSync().whereType<Directory>().first;
    final target = p.join(
      root.path,
      '${p.basename(comic.path)}$outputExtension',
    );
    await File(target).writeAsString('archive');
    onFolderDone?.call(comic.path, true, 100, 50, const {}, target);
    return const Ok<void>(null);
  }

  @override
  void cancel() {}
  @override
  void pause() {}
  @override
  void resume() {}
}

void main() {
  group('ArchiveImportService', () {
    late Directory tmp;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('import_test_');
    });

    tearDown(() {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });

    Future<File> makeArchive(String name, String entryName) async {
      final archive = Archive()..addFile(ArchiveFile(entryName, 3, [1, 2, 3]));
      final file = File(p.join(tmp.path, name));
      await file.writeAsBytes(ZipEncoder().encode(archive));
      return file;
    }

    test('extracts, optimizes and publishes a new archive', () async {
      final source = await makeArchive('Comic.cbz', '001.jpg');
      final service = ArchiveImportService(_FakeOptimizer());
      final result = await service.importArchive(source, const AppSettings());

      expect(result, isA<Ok<ArchiveImportResult>>());
      final value = (result as Ok<ArchiveImportResult>).value;
      expect(value.success, true);
      expect(value.archivePath, endsWith('Comic (optimized).cbz'));
      expect(File(value.archivePath!).existsSync(), true);
      expect(source.existsSync(), true);
      expect(await source.length(), greaterThan(0));
    });

    test('rejects traversal entries and leaves the source untouched', () async {
      final source = await makeArchive('Bad.cbz', '../escape.jpg');
      final service = ArchiveImportService(_FakeOptimizer());
      final result = await service.importArchive(source, const AppSettings());

      expect(result, isA<Err<ArchiveImportResult>>());
      expect(source.existsSync(), true);
    });

    test('uses the custom output directory', () async {
      final source = await makeArchive('Comic.zip', '001.jpg');
      final output = Directory(p.join(tmp.path, 'Out'))..createSync();
      final result = await ArchiveImportService(_FakeOptimizer()).importArchive(
        source,
        AppSettings(
          outputMode: OutputMode.custom,
          outputDirectory: output.path,
        ),
      );

      final value = (result as Ok<ArchiveImportResult>).value;
      expect(value.archivePath, p.join(output.path, 'Comic (optimized).cbz'));
    });
  });
}
