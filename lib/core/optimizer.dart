import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'archive.dart';
import 'encoder.dart';
import 'io.dart';
import 'utils.dart';

typedef LogCallback = void Function(String);
typedef FolderCallback = void Function(String folderPath);
typedef FolderDoneCallback =
    void Function(
      String folderPath,
      bool success,
      int? beforeBytes,
      int? afterBytes,
      Map<String, Map<String, int?>>? perFileSizes,
    );

class Optimizer {
  final LogCallback? onLog;
  final FolderCallback? onFolderStart;
  final FolderDoneCallback? onFolderDone;
  bool _cancelRequested = false;

  Optimizer({this.onLog, this.onFolderStart, this.onFolderDone});

  /// Request cancellation of the current operation. Optimizer will stop
  /// between files / folders as soon as it observes the request.
  void cancel() {
    _cancelRequested = true;
  }

  static final _imgExts = {'.png', '.jpg', '.jpeg', '.webp', '.apng', '.jxl'};

  Future<void> optimizeRoot(
    Directory root, {
    required List<String> presetArgs,
    required bool skipCjxl,
    required String cjxlPath,
    required String outputExtension,
    bool safeRun = false,
    bool preferPermanentDelete = false,
  }) async {
    if (!await root.exists()) {
      throw Exception('Root does not exist: ${root.path}');
    }

    // If the selected root folder contains only image files (no subfolders),
    // optimize the root folder itself instead of skipping.
    final rootChildren = await root
        .list(recursive: false, followLinks: false)
        .toList();
    final rootHasDirs = rootChildren.any((e) => e is Directory);
    final rootFiles = rootChildren.whereType<File>().toList();
    final rootHasImages = rootFiles.any(
      (f) => _imgExts.contains(p.extension(f.path).toLowerCase()),
    );
    if (!rootHasDirs && rootHasImages) {
      await _processFolder(
        root,
        root.path,
        presetArgs,
        skipCjxl,
        cjxlPath,
        outputExtension,
        preferPermanentDelete || safeRun,
      );
      return;
    }

    await for (final entity in root.list(
      recursive: false,
      followLinks: false,
    )) {
      if (_cancelRequested) {
        onLog?.call('Operation cancelled by user');
        break;
      }
      if (entity is Directory) {
        // If directory contains subdirectories, process each subdir; else process the directory itself
        final children = await entity.list(followLinks: false).toList();
        final hasDirs = children.any((e) => e is Directory);
        if (hasDirs) {
          for (final sub in children.whereType<Directory>()) {
            if (_cancelRequested) break;
            Directory working = sub;
            var startEmitted = false;
            final safeResult = await makeSafeCopyIfRequested(
              sub,
              safeRun,
              onLog: onLog,
              onFolderStart: onFolderStart,
            );
            working = safeResult.working;
            startEmitted = safeResult.startEmitted;
            await _processFolder(
              working,
              sub.path,
              presetArgs,
              skipCjxl,
              cjxlPath,
              outputExtension,
              preferPermanentDelete || safeRun,
              emitStart: !startEmitted,
            );
            // If we created a working copy and it still exists, attempt to delete it now
            if (safeRun && working.path != sub.path) {
              try {
                if (await Directory(working.path).exists()) {
                  await Directory(working.path).delete(recursive: true);
                  onLog?.call('Removed safe copy ${working.path}');
                }
              } catch (e) {
                onLog?.call('Failed to remove safe copy ${working.path}: $e');
              }
            }
          }
        } else {
          {
            Directory working = entity;
            var startEmitted = false;
            final safeResult = await makeSafeCopyIfRequested(
              entity,
              safeRun,
              onLog: onLog,
              onFolderStart: onFolderStart,
            );
            working = safeResult.working;
            startEmitted = safeResult.startEmitted;
            await _processFolder(
              working,
              entity.path,
              presetArgs,
              skipCjxl,
              cjxlPath,
              outputExtension,
              preferPermanentDelete || safeRun,
              emitStart: !startEmitted,
            );
            if (safeRun && working.path != entity.path) {
              try {
                if (await Directory(working.path).exists()) {
                  await Directory(working.path).delete(recursive: true);
                  onLog?.call('Removed safe copy ${working.path}');
                }
              } catch (e) {
                onLog?.call('Failed to remove safe copy ${working.path}: $e');
              }
            }
          }
        }
      }
    }
  }

  Future<void> _processFolder(
    Directory folder,
    String originalPath,
    List<String> presetArgs,
    bool skipCjxl,
    String cjxlPath,
    String outputExtension,
    bool preferPermanentDelete, {
    bool emitStart = true,
  }) async {
    // Helper closures for masking paths and arguments in logs
    final maskPath = makeMaskPath(folder.path, originalPath);
    final maskArgs = makeMaskArgs(maskPath);

    if (emitStart) onFolderStart?.call(originalPath);
    var success = true;
    int? beforeTotalBytes;
    int? archiveBytes;
    final perFileSizes = <String, Map<String, int?>>{};
    try {
      // list images
      final files = await folder
          .list(recursive: false, followLinks: false)
          .where((e) => e is File)
          .cast<File>()
          .toList();

      final images = files
          .where((f) => _imgExts.contains(p.extension(f.path).toLowerCase()))
          .toList();
      if (images.isEmpty) {
        onLog?.call('No images in ${p.basename(originalPath)}, skipping');
        return;
      }

      // Record per-file sizes before optimization
      for (final img in images) {
        try {
          final len = await img.length();
          perFileSizes[p.basename(img.path)] = {'before': len, 'after': null};
        } catch (_) {
          perFileSizes[p.basename(img.path)] = {'before': null, 'after': null};
        }
      }

      beforeTotalBytes = await sumFileLengths(images);

      await removeNonImageFiles(folder, _imgExts, onLog: onLog);

      final imageFiles = await listImageFiles(folder, _imgExts);

      await normalizeFilenamesSequential(
        folder,
        imageFiles,
        onLog: onLog,
        isCancelled: () => _cancelRequested,
      );

      // Encode each image to JPEG XL using `cjxl` and the provided preset args
      if (!skipCjxl) {
        final encoder = Encoder(
          onLog: onLog,
          isCancelled: () => _cancelRequested,
        );
        try {
          final ok = await encoder.encodeFolder(
            folder,
            presetArgs,
            cjxlPath,
            maskArgs,
          );
          if (!ok) success = false;
        } catch (e) {
          onLog?.call('Failed during cjxl encoding: $e');
          success = false;
        }
      } else {
        onLog?.call(
          'Skipping cjxl encoding for ${p.basename(originalPath)} (skip flag set)',
        );
      }

      // Remove redundant originals: if .jxl exists with same base, remove non-jxl
      await removeDuplicateOriginals(folder, onLog: onLog);

      // Create archive in parent directory using store (no compression)
      final parent = Directory(folder.parent.path);
      final archiveName = '${p.basename(originalPath)}$outputExtension';
      final archivePath = p.join(parent.path, archiveName);
      if (p.isWithin(folder.path, archivePath)) {
        // avoid archive inside folder
        onLog?.call(
          'Archive path would be inside source folder; skipping delete: $archivePath',
        );
      }

      final archiveResult = await createArchiveAndMaybeRemoveSource(
        folder,
        originalPath,
        outputExtension,
        preferPermanentDelete,
        onLog: onLog,
      );
      archiveBytes = archiveResult.bytes;
      if (!archiveResult.success) success = false;
    } catch (e) {
      onLog?.call('Error processing ${p.basename(originalPath)}: $e');
      success = false;
    } finally {
      // Compute per-file after sizes: determine for each original whether a
      // .jxl exists for the same base; use its size if present, else original.
      try {
        final afterFiles = await folder
            .list(recursive: false, followLinks: false)
            .where((e) => e is File)
            .cast<File>()
            .toList();
        final afterMap = <String, File>{};
        for (final f in afterFiles) {
          afterMap[p.basename(f.path)] = f;
        }
        perFileSizes.forEach((origName, map) {
          final base = origName.contains('.')
              ? origName.substring(0, origName.lastIndexOf('.'))
              : origName;
          final jxlName = '$base.jxl';
          if (afterMap.containsKey(jxlName)) {
            try {
              map['after'] = afterMap[jxlName]!.lengthSync();
            } catch (_) {
              map['after'] = null;
            }
          } else if (afterMap.containsKey(origName)) {
            try {
              map['after'] = afterMap[origName]!.lengthSync();
            } catch (_) {
              map['after'] = null;
            }
          } else {
            // File disappeared (e.g., removed), leave after as null
            map['after'] = null;
          }
        });
      } catch (_) {}

      onFolderDone?.call(
        originalPath,
        success,
        beforeTotalBytes,
        archiveBytes,
        perFileSizes,
      );
    }
  }
}
