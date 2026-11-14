import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import 'package:comic_optimizer/core/interfaces/i_archive_service.dart';
import 'package:comic_optimizer/core/result.dart';

/// Creates a ZIP in a temporary file, verifies its entries, then publishes it
/// atomically. The source folder is never touched here.
final class ArchiveServiceImpl implements IArchiveService {
  const ArchiveServiceImpl();

  @override
  Future<Result<ArchiveResult>> publish(
    List<ArchiveEntry> entries,
    String targetPath, {
    void Function(String)? onLog,
    Future<void> Function()? waitIfPaused,
  }) async {
    if (entries.isEmpty) {
      return const Err('Cannot create an empty archive');
    }

    final target = File(targetPath);
    final parent = target.parent;
    final part = File(
      '$targetPath.${DateTime.now().microsecondsSinceEpoch}.part',
    );
    final backup = File('$targetPath.bak');
    var movedOldTarget = false;

    try {
      await parent.create(recursive: true);

      final names = <String>{};
      final archive = Archive();
      for (final entry in entries) {
        if (waitIfPaused != null) await waitIfPaused();
        final name = entry.name.replaceAll('\\', '/');
        if (name.isEmpty ||
            name.startsWith('/') ||
            p.isAbsolute(name) ||
            name.split('/').contains('..')) {
          return Err('Unsafe archive entry name: ${entry.name}');
        }
        if (!names.add(name)) {
          return Err('Duplicate archive entry: $name');
        }
        final bytes = await entry.file.readAsBytes();
        archive.addFile(ArchiveFile(name, bytes.length, bytes));
      }

      final outData = ZipEncoder().encode(archive, level: 0);
      final raf = await part.open(mode: FileMode.write);
      try {
        await raf.writeFrom(outData);
        await raf.flush();
      } finally {
        await raf.close();
      }

      final verify = await _verify(part, entries.length);
      if (verify != null) {
        await _deleteQuietly(part);
        return Err('Archive verification failed: $verify');
      }

      if (await backup.exists()) await backup.delete();
      if (await target.exists()) {
        await target.rename(backup.path);
        movedOldTarget = true;
      }
      try {
        await part.rename(target.path);
      } catch (e) {
        if (movedOldTarget && await backup.exists()) {
          try {
            await backup.rename(target.path);
          } catch (_) {}
        }
        await _deleteQuietly(part);
        return Err('Could not publish archive: $e');
      }
      if (await backup.exists()) await backup.delete();

      final bytes = await target.length();
      onLog?.call('Created verified archive ${p.basename(target.path)}');
      return Ok(ArchiveResult(true, bytes, target.path, verified: true));
    } catch (e) {
      await _deleteQuietly(part);
      if (movedOldTarget && await backup.exists() && !await target.exists()) {
        try {
          await backup.rename(target.path);
        } catch (_) {}
      }
      return Err('Failed to create archive: $e');
    }
  }

  Future<String?> _verify(File file, int expectedEntries) async {
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      if (archive.files.length != expectedEntries) {
        return 'expected $expectedEntries entries, found ${archive.files.length}';
      }
      final names = <String>{};
      for (final entry in archive.files) {
        if (!names.add(entry.name)) return 'duplicate entry ${entry.name}';
        if (entry.size < 0) return 'invalid size for ${entry.name}';
      }
      return null;
    } catch (e) {
      return '$e';
    }
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
