import 'dart:io';

import 'package:comic_optimizer/infrastructure/services/preflight_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('PreflightService', () {
    late Directory tmp;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('preflight_test_');
    });

    tearDown(() {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });

    Future<void> write(String relativePath) async {
      final file = File(p.join(tmp.path, relativePath));
      await file.parent.create(recursive: true);
      await file.writeAsBytes([1, 2, 3]);
    }

    test('counts comics, images and non-image files', () async {
      await write(p.join('Comic A', '001.png'));
      await write(p.join('Comic A', '002.jpg'));
      await write(p.join('Comic A', 'notes.txt'));
      await write(p.join('Comic B', 'page.webp'));
      await write('cover.png'); // root-level image is ignored when dirs exist

      final summary = await const PreflightService().scan([tmp.path]);

      expect(summary.roots, 1);
      expect(summary.comics, 2);
      expect(summary.images, 3);
      expect(summary.nonImageFiles, 1);
    });

    test('treats a root containing only images as one comic', () async {
      await write('001.png');
      await write('002.png');
      await write('ComicInfo.xml');

      final summary = await const PreflightService().scan([tmp.path]);

      expect(summary.comics, 1);
      expect(summary.images, 2);
      expect(summary.nonImageFiles, 1);
    });

    test('walks one level deeper when a subfolder contains folders', () async {
      await write(p.join('Series', 'Vol 1', '001.png'));
      await write(p.join('Series', 'Vol 2', '001.png'));
      await write(p.join('Series', 'Vol 2', '002.png'));

      final summary = await const PreflightService().scan([tmp.path]);

      expect(summary.comics, 2);
      expect(summary.images, 3);
    });

    test('ignores roots that do not exist', () async {
      await write(p.join('Comic', '001.png'));

      final summary = await const PreflightService().scan([
        tmp.path,
        p.join(tmp.path, 'missing'),
      ]);

      expect(summary.roots, 1);
      expect(summary.comics, 1);
    });
  });
}
