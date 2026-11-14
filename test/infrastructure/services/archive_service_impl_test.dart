import 'dart:io';

import 'package:archive/archive.dart';
import 'package:comic_optimizer/core/interfaces/i_archive_service.dart';
import 'package:comic_optimizer/core/result.dart';
import 'package:comic_optimizer/infrastructure/services/archive_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('ArchiveServiceImpl', () {
    late Directory tmpDir;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('archive_test_');
    });

    tearDown(() {
      if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    });

    test(
      'publishes a verified archive and leaves the source untouched',
      () async {
        final source = File(p.join(tmpDir.path, 'page01.txt'))
          ..writeAsStringSync('hello');
        final target = p.join(tmpDir.path, 'MyComic.cbz');

        const service = ArchiveServiceImpl();
        final result = await service.publish([
          ArchiveEntry('page01.txt', source),
        ], target);

        expect(result, isA<Ok<ArchiveResult>>());
        final archive = (result as Ok<ArchiveResult>).value;
        expect(archive.success, true);
        expect(archive.verified, true);
        expect(archive.path, target);
        expect(source.existsSync(), true);
        expect(File(target).existsSync(), true);

        final decoded = ZipDecoder().decodeBytes(
          await File(target).readAsBytes(),
        );
        expect(decoded.files, hasLength(1));
        expect(decoded.files.first.name, 'page01.txt');
        expect(
          tmpDir.listSync().where((entry) => entry.path.endsWith('.part')),
          isEmpty,
        );
      },
    );

    test('rejects unsafe archive entry names', () async {
      final source = File(p.join(tmpDir.path, 'page01.txt'))
        ..writeAsStringSync('hello');
      final target = p.join(tmpDir.path, 'Bad.cbz');

      const service = ArchiveServiceImpl();
      final result = await service.publish([
        ArchiveEntry('../escape.txt', source),
      ], target);

      expect(result, isA<Err<ArchiveResult>>());
      expect(File(target).existsSync(), false);
    });

    test('rejects empty archives', () async {
      const service = ArchiveServiceImpl();
      final result = await service.publish(
        [],
        p.join(tmpDir.path, 'Empty.cbz'),
      );
      expect(result, isA<Err<ArchiveResult>>());
    });

    test('replaces an existing archive and removes temporary files', () async {
      final source = File(p.join(tmpDir.path, 'page01.txt'))
        ..writeAsStringSync('hello');
      final target = p.join(tmpDir.path, 'Comic.cbz');
      File(target).writeAsStringSync('old');

      const service = ArchiveServiceImpl();
      final result = await service.publish([
        ArchiveEntry('page01.txt', source),
      ], target);

      expect(result, isA<Ok<ArchiveResult>>());
      final decoded = ZipDecoder().decodeBytes(
        await File(target).readAsBytes(),
      );
      expect(decoded.files, hasLength(1));
      expect(File('$target.bak').existsSync(), false);
    });

    test('logs the published archive name', () async {
      final source = File(p.join(tmpDir.path, 'page01.txt'))
        ..writeAsStringSync('hello');
      final logs = <String>[];
      const service = ArchiveServiceImpl();
      await service.publish(
        [ArchiveEntry('page01.txt', source)],
        p.join(tmpDir.path, 'Logged.cbz'),
        onLog: logs.add,
      );
      expect(
        logs.any((line) => line.contains('Created verified archive')),
        true,
      );
    });
  });
}
