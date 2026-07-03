import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:comic_optimizer/core/interfaces/i_optimizer_service.dart';
import 'package:comic_optimizer/core/result.dart';
import 'package:comic_optimizer/core/utils.dart';
import 'package:comic_optimizer/infrastructure/services/archive_service_impl.dart';
import 'package:comic_optimizer/infrastructure/services/encoder_service_impl.dart';
import 'package:comic_optimizer/infrastructure/services/file_io_service.dart';

/// Implementation of [IOptimizerService] that orchestrates comic folder
/// optimization: cleaning, renaming, encoding, and archiving.
final class OptimizerServiceImpl implements IOptimizerService {
  bool _cancelRequested = false;
  bool _paused = false;
  Completer<void>? _pauseCompleter;

  @override
  void cancel() {
    _cancelRequested = true;
  }

  @override
  void pause() {
    if (!_paused) {
      _paused = true;
      _pauseCompleter = Completer<void>();
    }
  }

  @override
  void resume() {
    if (_paused) {
      _paused = false;
      try {
        _pauseCompleter?.complete();
      } catch (_) {}
      _pauseCompleter = null;
    }
  }

  /// Await while paused; returns immediately when not paused.
  Future<void> waitIfPaused() async {
    if (_paused) {
      final c = _pauseCompleter;
      if (c != null) await c.future;
    }
  }

  static final _imgExts = {'.png', '.jpg', '.jpeg', '.webp', '.apng', '.jxl'};

  @override
  Future<Result<void>> optimizeRoot(
    Directory root, {
    required List<String> presetArgs,
    required bool skipCjxl,
    required String cjxlPath,
    required String outputExtension,
    bool safeRun = false,
    bool preferPermanentDelete = false,
    void Function(String)? onLog,
    void Function(String)? onFolderStart,
    void Function(
      String folderPath,
      bool success,
      int? beforeBytes,
      int? afterBytes,
      Map<String, Map<String, int?>>? perFileSizes,
    )?
    onFolderDone,
  }) async {
    try {
      if (!await root.exists()) {
        return Err('Root does not exist: ${root.path}');
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
        Directory working = root;
        var startEmitted = false;
        final safeResult = await makeSafeCopyIfRequested(
          root,
          safeRun,
          onLog: onLog,
          onFolderStart: onFolderStart,
        );
        working = safeResult.working;
        startEmitted = safeResult.startEmitted;
        await _processFolder(
          working,
          root.path,
          presetArgs,
          skipCjxl,
          cjxlPath,
          outputExtension,
          preferPermanentDelete || safeRun,
          emitStart: !startEmitted,
          onLog: onLog,
          onFolderStart: onFolderStart,
          onFolderDone: onFolderDone,
        );
        if (safeRun && working.path != root.path) {
          try {
            if (await Directory(working.path).exists()) {
              await Directory(working.path).delete(recursive: true);
              onLog?.call('Removed safe copy ${working.path}');
            }
          } catch (e) {
            onLog?.call('Failed to remove safe copy ${working.path}: $e');
          }
        }
        return const Ok<void>(null);
      }

      await for (final entity in root.list(
        recursive: false,
        followLinks: false,
      )) {
        await waitIfPaused();
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
              await waitIfPaused();
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
                onLog: onLog,
                onFolderStart: onFolderStart,
                onFolderDone: onFolderDone,
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
              await waitIfPaused();
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
                onLog: onLog,
                onFolderStart: onFolderStart,
                onFolderDone: onFolderDone,
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

      return const Ok<void>(null);
    } catch (e, st) {
      onLog?.call('Optimizer error: $e');
      onLog?.call(st.toString());
      return Err('$e', cause: e);
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
    void Function(String)? onLog,
    void Function(String)? onFolderStart,
    void Function(
      String folderPath,
      bool success,
      int? beforeBytes,
      int? afterBytes,
      Map<String, Map<String, int?>>? perFileSizes,
    )?
    onFolderDone,
  }) async {
    await waitIfPaused();
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

      await removeNonImageFiles(
        folder,
        _imgExts,
        onLog: onLog,
        waitIfPaused: waitIfPaused,
      );

      final imageFiles = await listImageFiles(
        folder,
        _imgExts,
        waitIfPaused: waitIfPaused,
      );

      await normalizeFilenamesSequential(
        folder,
        imageFiles,
        onLog: onLog,
        isCancelled: () => _cancelRequested,
        waitIfPaused: waitIfPaused,
      );

      // Encode each image to JPEG XL using `cjxl` and the provided preset args
      if (!skipCjxl) {
        final encoder = const EncoderServiceImpl();
        try {
          final encodeResult = await encoder.encodeFolder(
            folder,
            presetArgs,
            cjxlPath,
            maskArgs,
            onLog: onLog,
            isCancelled: () => _cancelRequested,
            waitIfPaused: waitIfPaused,
          );
          if (encodeResult case Ok(value: final ok)) {
            if (!ok) success = false;
          } else {
            success = false;
          }
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
      await removeDuplicateOriginals(
        folder,
        onLog: onLog,
        waitIfPaused: waitIfPaused,
      );

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

      final archiveService = const ArchiveServiceImpl();
      final archiveResult = await archiveService
          .createArchiveAndMaybeRemoveSource(
            folder,
            originalPath,
            outputExtension,
            preferPermanentDelete,
            onLog: onLog,
            waitIfPaused: waitIfPaused,
          );
      if (archiveResult case Ok(value: final ar)) {
        archiveBytes = ar.bytes;
        if (!ar.success) success = false;
      } else {
        success = false;
      }
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
