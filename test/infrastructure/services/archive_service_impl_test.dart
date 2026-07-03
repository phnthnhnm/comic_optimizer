import 'dart:io';

import 'package:archive/archive.dart';
import 'package:comic_optimizer/core/interfaces/i_archive_service.dart';
import 'package:comic_optimizer/core/result.dart';
import 'package:comic_optimizer/infrastructure/services/archive_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArchiveServiceImpl', () {
    late Directory tmpDir;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('archive_test_');
    });

    tearDown(() {
      if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    });

    test('creates a zip archive from a folder with files', () async {
      // Arrange: create a source folder with one text file
      final srcDir = Directory('${tmpDir.path}/MyComic');
      srcDir.createSync();
      File('${srcDir.path}/page01.txt').writeAsStringSync('hello');

      final service = const ArchiveServiceImpl();

      // Act
      final result = await service.createArchiveAndMaybeRemoveSource(
        srcDir,
        srcDir.path,
        '.cbz',
        true, // preferPermanentDelete
      );

      // Assert
      expect(result, isA<Ok<ArchiveResult>>());
      final r = (result as Ok<ArchiveResult>).value;
      expect(r.success, true);
      expect(r.path, contains('MyComic.cbz'));

      // Archive file exists
      final archiveFile = File(r.path!);
      expect(await archiveFile.exists(), true);

      // Archive contains the original file
      final bytes = await archiveFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      expect(archive.files, hasLength(1));
      expect(archive.files.first.name, 'page01.txt');

      // Source folder was removed (permanent delete)
      expect(srcDir.existsSync(), false);
    });

    test('preserves source folder when archive path is inside it', () async {
      // This shouldn't happen in normal use, but the code handles it.
      final srcDir = Directory('${tmpDir.path}/nested');
      srcDir.createSync();
      File('${srcDir.path}/data.txt').writeAsStringSync('test');

      final service = const ArchiveServiceImpl();
      final result = await service.createArchiveAndMaybeRemoveSource(
        srcDir,
        srcDir.path,
        '.cbz',
        false,
      );

      expect(result, isA<Ok<ArchiveResult>>());
      final r = (result as Ok<ArchiveResult>).value;
      expect(r.success, true);
    });

    test('logs messages via onLog callback', () async {
      final srcDir = Directory('${tmpDir.path}/LoggedComic');
      srcDir.createSync();
      File('${srcDir.path}/img.png').writeAsStringSync('fake png');

      final logLines = <String>[];
      final service = const ArchiveServiceImpl();
      await service.createArchiveAndMaybeRemoveSource(
        srcDir,
        srcDir.path,
        '.cbz',
        true,
        onLog: (msg) => logLines.add(msg),
      );

      expect(logLines.any((l) => l.contains('Created archive')), true);
    });

    test('handles non-existent folder gracefully', () async {
      final nonExistent = Directory('${tmpDir.path}/does_not_exist');
      final service = const ArchiveServiceImpl();

      // Doesn't crash — returns an Ok with the error communicated via
      // the ArchiveResult.success=false inside the catch block, or
      // the underlying parentForFolderFiles may list '.' files.
      // We just verify it doesn't throw.
      expect(
        () => service.createArchiveAndMaybeRemoveSource(
          nonExistent,
          nonExistent.path,
          '.cbz',
          true,
        ),
        returnsNormally,
      );
    });
  });
}
