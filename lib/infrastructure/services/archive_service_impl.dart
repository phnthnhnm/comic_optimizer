import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import 'package:comic_optimizer/core/interfaces/i_archive_service.dart';
import 'package:comic_optimizer/core/result.dart';
import 'package:comic_optimizer/infrastructure/services/file_io_service.dart';

/// Implementation of [IArchiveService] that creates ZIP archives from comic
/// folders using store (no compression).
final class ArchiveServiceImpl implements IArchiveService {
  const ArchiveServiceImpl();

  @override
  Future<Result<ArchiveResult>> createArchiveAndMaybeRemoveSource(
    Directory folder,
    String originalPath,
    String outputExtension,
    bool preferPermanentDelete, {
    void Function(String)? onLog,
    Future<void> Function()? waitIfPaused,
  }) async {
    final parent = Directory(folder.parent.path);
    final archiveName = '${p.basename(originalPath)}$outputExtension';
    final archivePath = p.join(parent.path, archiveName);
    if (p.isWithin(folder.path, archivePath)) {
      onLog?.call(
        'Archive path would be inside source folder; skipping delete: $archivePath',
      );
    }

    int? archiveBytes;
    try {
      final archive = Archive();
      final finalFiles = await parentForFolderFiles(folder);
      for (final f in finalFiles) {
        if (waitIfPaused != null) await waitIfPaused();
        final rel = p.relative(f.path, from: folder.path);
        final bytes = await File(f.path).readAsBytes();
        final file = ArchiveFile(rel, bytes.length, bytes);
        archive.addFile(file);
      }
      final encoder = ZipEncoder();
      final outData = encoder.encode(archive, level: 0);
      final out = File(archivePath);
      await out.writeAsBytes(outData);
      try {
        archiveBytes = await out.length();
      } catch (_) {
        archiveBytes = null;
      }
      onLog?.call('Created archive ${p.basename(archivePath)}');
    } catch (e) {
      onLog?.call('Failed to create archive: $e');
      return Ok(ArchiveResult(false, null, null));
    }

    // Remove source folder if archive is outside
    try {
      final arch = p.normalize(p.absolute(p.join(parent.path, archiveName)));
      final folderAbs = p.normalize(p.absolute(folder.path));
      if (!p.isWithin(folderAbs, arch)) {
        try {
          if (preferPermanentDelete) {
            if (waitIfPaused != null) await waitIfPaused();
            await folder.delete(recursive: true);
            onLog?.call(
              'Removed source folder ${p.basename(originalPath)} (permanent delete)',
            );
          } else {
            if (waitIfPaused != null) await waitIfPaused();
            await recycleOrDelete(folder, onLog: onLog);
            onLog?.call(
              'Removed source folder ${p.basename(originalPath)} (moved to Recycle Bin)',
            );
          }
        } catch (e) {
          onLog?.call(
            'Failed to remove source folder ${p.basename(originalPath)}: $e',
          );
          return Ok(ArchiveResult(false, archiveBytes, archivePath));
        }
      } else {
        onLog?.call('Archive is inside source; not deleting source folder');
      }
    } catch (e) {
      onLog?.call('Failed to delete source folder: $e');
      return Ok(ArchiveResult(false, archiveBytes, archivePath));
    }

    return Ok(ArchiveResult(true, archiveBytes, archivePath));
  }
}
