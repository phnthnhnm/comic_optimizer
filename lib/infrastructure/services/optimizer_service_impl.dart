import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as p;

import 'package:comic_optimizer/core/interfaces/i_archive_service.dart';
import 'package:comic_optimizer/core/interfaces/i_encoder_service.dart';
import 'package:comic_optimizer/core/interfaces/i_optimizer_service.dart';
import 'package:comic_optimizer/core/result.dart';
import 'package:comic_optimizer/core/utils.dart';
import 'package:comic_optimizer/domain/enums/collision_policy.dart';
import 'package:comic_optimizer/domain/enums/output_mode.dart';
import 'package:comic_optimizer/domain/models/image_formats.dart';
import 'package:comic_optimizer/infrastructure/services/file_io_service.dart';
import 'package:comic_optimizer/infrastructure/services/output_path_resolver.dart';

/// Orchestrates comic optimization without mutating the source folder until a
/// verified archive has been published.
final class OptimizerServiceImpl implements IOptimizerService {
  final IArchiveService _archive;
  final IEncoderService _encoder;
  final OutputPathResolver _outputs;

  OptimizerServiceImpl(
    this._archive,
    this._encoder, [
    this._outputs = const OutputPathResolver(),
  ]);

  bool _cancelRequested = false;
  bool _paused = false;
  Completer<void>? _pauseCompleter;

  @override
  void cancel() => _cancelRequested = true;

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

  Future<void> waitIfPaused() async {
    if (_paused) {
      final completer = _pauseCompleter;
      if (completer != null) await completer.future;
    }
  }

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
    void Function(String folder, String file, int index, int total)?
    onFileStart,
    void Function(String)? onFolderStart,
    void Function(
      String folderPath,
      bool success,
      int? beforeBytes,
      int? afterBytes,
      Map<String, Map<String, int?>>? perFileSizes,
      String? archivePath,
    )?
    onFolderDone,
  }) async {
    try {
      if (!await root.exists()) {
        return Err('Root does not exist: ${root.path}');
      }

      final comics = await _collectComics(root);
      for (var index = 0; index < comics.length; index++) {
        await waitIfPaused();
        if (_cancelRequested) {
          onLog?.call('Operation cancelled by user');
          break;
        }
        await _processComic(
          comics[index],
          root,
          index + 1,
          presetArgs: presetArgs,
          skipCjxl: skipCjxl,
          deleteNonImageFiles: deleteNonImageFiles,
          cjxlPath: cjxlPath,
          outputExtension: outputExtension,
          safeRun: safeRun,
          preferPermanentDelete: preferPermanentDelete,
          presetName: presetName,
          namingTemplate: namingTemplate,
          globalOutputDirectory: globalOutputDirectory,
          libraryOutputDirectory: libraryOutputDirectory,
          outputMode: outputMode,
          collisionPolicy: collisionPolicy,
          skipExistingArchives: skipExistingArchives,
          maxParallelEncodes: maxParallelEncodes,
          completedFolders: completedFolders,
          onLog: onLog,
          onFileStart: onFileStart,
          onFolderStart: onFolderStart,
          onFolderDone: onFolderDone,
        );
      }
      return const Ok<void>(null);
    } catch (e, st) {
      onLog?.call('Optimizer error: $e');
      onLog?.call(st.toString());
      return Err('$e', cause: e);
    }
  }

  Future<List<Directory>> _collectComics(Directory root) async {
    final children = await root
        .list(recursive: false, followLinks: false)
        .toList();
    final directories = children.whereType<Directory>().toList()
      ..sort((a, b) => naturalCompare(p.basename(a.path), p.basename(b.path)));
    final rootImages = children
        .whereType<File>()
        .where((file) => isSupportedImage(file.path))
        .toList();

    if (directories.isEmpty) {
      return rootImages.isEmpty ? const [] : [root];
    }

    final comics = <Directory>[];
    for (final directory in directories) {
      final nested = await directory
          .list(recursive: false, followLinks: false)
          .toList();
      final subdirectories = nested.whereType<Directory>().toList()
        ..sort(
          (a, b) => naturalCompare(p.basename(a.path), p.basename(b.path)),
        );
      if (subdirectories.isEmpty) {
        if (await _hasImages(directory)) comics.add(directory);
      } else {
        for (final subdirectory in subdirectories) {
          if (await _hasImages(subdirectory)) comics.add(subdirectory);
        }
      }
    }
    return comics;
  }

  Future<bool> _hasImages(Directory directory) async {
    return directory
        .list(recursive: false, followLinks: false)
        .any((entity) => entity is File && isSupportedImage(entity.path));
  }

  Future<void> _processComic(
    Directory comic,
    Directory root,
    int comicIndex, {
    required List<String> presetArgs,
    required bool skipCjxl,
    required bool deleteNonImageFiles,
    required String cjxlPath,
    required String outputExtension,
    required bool safeRun,
    required bool preferPermanentDelete,
    required String presetName,
    required String namingTemplate,
    required String globalOutputDirectory,
    required String? libraryOutputDirectory,
    required OutputMode outputMode,
    required CollisionPolicy collisionPolicy,
    required bool skipExistingArchives,
    required int maxParallelEncodes,
    required Set<String> completedFolders,
    void Function(String)? onLog,
    void Function(String folder, String file, int index, int total)?
    onFileStart,
    void Function(String)? onFolderStart,
    void Function(
      String folderPath,
      bool success,
      int? beforeBytes,
      int? afterBytes,
      Map<String, Map<String, int?>>? perFileSizes,
      String? archivePath,
    )?
    onFolderDone,
  }) async {
    final originalPath = comic.path;
    onFolderStart?.call(originalPath);
    final perFileSizes = <String, Map<String, int?>>{};
    int? beforeBytes;
    int? archiveBytes;
    String? archivePath;
    var success = false;
    Directory? staging;

    if (completedFolders.contains(originalPath)) {
      onLog?.call('Resumed: ${p.basename(originalPath)} was already complete');
      success = true;
      onFolderDone?.call(originalPath, true, null, null, const {}, null);
      return;
    }

    try {
      final images = await listImageFiles(comic, waitIfPaused: waitIfPaused);
      if (images.isEmpty) {
        onLog?.call('No images in ${p.basename(originalPath)}, skipping');
        return;
      }
      beforeBytes = await sumFileLengths(images);

      final target = await _outputs.resolve(
        libraryPath: root.path,
        comicPath: comic.path,
        presetName: presetName,
        outputExtension: outputExtension,
        outputMode: outputMode,
        globalOutputDirectory: globalOutputDirectory,
        namingTemplate: namingTemplate,
        collisionPolicy: collisionPolicy,
        libraryOutputDirectory: libraryOutputDirectory,
        index: comicIndex,
      );
      archivePath = target;

      if (p.isWithin(comic.path, target) || target == comic.path) {
        onLog?.call('Archive target is inside the source folder: $target');
        return;
      }

      if (collisionPolicy == CollisionPolicy.skip &&
          await File(target).exists()) {
        archiveBytes = await _lengthOrNull(File(target));
        success = true;
        onLog?.call('Skipped (archive already exists): ${p.basename(target)}');
        return;
      }

      if (skipExistingArchives && await _archiveIsCurrent(target, comic)) {
        archiveBytes = await _lengthOrNull(File(target));
        success = true;
        onLog?.call('Skipped (archive is up to date): ${p.basename(target)}');
        return;
      }

      staging = await Directory.systemTemp.createTemp('comic_optimizer_');
      final entries = <ArchiveEntry>[];
      final pad = math.max(3, images.length.toString().length);
      final maskArgs = _argumentMasker(comic.path);
      final concurrency = maxParallelEncodes.clamp(1, 4).toInt();

      for (var start = 0; start < images.length; start += concurrency) {
        await waitIfPaused();
        if (_cancelRequested) {
          onLog?.call('Operation cancelled by user');
          return;
        }

        final end = math.min(start + concurrency, images.length);
        for (var index = start; index < end; index++) {
          onFileStart?.call(
            originalPath,
            images[index].path,
            index + 1,
            images.length,
          );
        }

        final results = await Future.wait([
          for (var index = start; index < end; index++)
            _stageImage(
              images[index],
              (index + 1).toString().padLeft(pad, '0'),
              staging.path,
              presetArgs,
              skipCjxl,
              cjxlPath,
              maskArgs,
              waitIfPaused,
            ),
        ]);

        for (final result in results) {
          for (final line in result.logs) {
            onLog?.call(line);
          }
          if (result.cancelled) {
            onLog?.call('Operation cancelled by user');
            return;
          }
          if (!result.success || result.entry == null) {
            onLog?.call(
              result.error ??
                  'Encoding failed for ${result.originalName}; '
                      'leaving source untouched',
            );
            return;
          }
          perFileSizes[result.originalName] = {
            'before': result.beforeBytes,
            'after': result.afterBytes,
          };
          entries.add(result.entry!);
        }
      }

      if (!deleteNonImageFiles) {
        final files = await comic
            .list(recursive: false, followLinks: false)
            .where((entity) => entity is File)
            .cast<File>()
            .where((file) => !isSupportedImage(file.path))
            .toList();
        for (final file in files) {
          await waitIfPaused();
          final staged = File(p.join(staging.path, p.basename(file.path)));
          await file.copy(staged.path);
          entries.add(ArchiveEntry(p.basename(file.path), staged));
        }
      }

      entries.sort((a, b) => naturalCompare(a.name, b.name));
      if (entries.isEmpty) {
        onLog?.call('No files to archive in ${p.basename(originalPath)}');
        return;
      }

      final result = await _archive.publish(
        entries,
        target,
        onLog: onLog,
        waitIfPaused: waitIfPaused,
      );
      if (result case Ok(value: final archive)) {
        archiveBytes = archive.bytes;
        success = archive.success && archive.verified;
      } else if (result case Err(:final message)) {
        onLog?.call('Archive failed: $message');
        return;
      }

      if (!success) return;

      if (safeRun) {
        onLog?.call('Kept original folder ${p.basename(originalPath)}');
      } else {
        try {
          if (preferPermanentDelete) {
            await comic.delete(recursive: true);
            onLog?.call(
              'Removed source folder ${p.basename(originalPath)} '
              '(permanent delete)',
            );
          } else {
            await recycleOrDelete(comic, onLog: onLog);
            onLog?.call(
              'Removed source folder ${p.basename(originalPath)} '
              '(moved to Recycle Bin)',
            );
          }
        } catch (e) {
          success = false;
          onLog?.call(
            'Failed to remove source folder ${p.basename(originalPath)}: $e',
          );
        }
      }
    } catch (e) {
      onLog?.call('Error processing ${p.basename(originalPath)}: $e');
      success = false;
    } finally {
      if (staging != null) {
        try {
          if (await staging.exists()) {
            await staging.delete(recursive: true);
          }
        } catch (e) {
          onLog?.call('Failed to clean temporary files: $e');
        }
      }
      onFolderDone?.call(
        originalPath,
        success,
        beforeBytes,
        archiveBytes,
        perFileSizes,
        archivePath,
      );
    }
  }

  Future<_StagedPage> _stageImage(
    File image,
    String ordinal,
    String stagingPath,
    List<String> presetArgs,
    bool skipCjxl,
    String cjxlPath,
    String Function(List<String>) maskArgs,
    Future<void> Function()? waitIfPaused,
  ) async {
    final logs = <String>[];
    final originalName = p.basename(image.path);
    final beforeBytes = await _lengthOrNull(image);
    if (waitIfPaused != null) await waitIfPaused();
    if (_cancelRequested) {
      return _StagedPage(
        originalName: originalName,
        beforeBytes: beforeBytes,
        cancelled: true,
        logs: logs,
      );
    }

    final extension = p.extension(image.path);
    try {
      if (skipCjxl ||
          extension.toLowerCase() == '.jxl' ||
          !isEncodableImage(image.path)) {
        final staged = File(p.join(stagingPath, '$ordinal$extension'));
        await image.copy(staged.path);
        return _StagedPage(
          originalName: originalName,
          beforeBytes: beforeBytes,
          afterBytes: await _lengthOrNull(staged),
          entry: ArchiveEntry('$ordinal$extension', staged),
          logs: logs,
        );
      }

      final staged = File(p.join(stagingPath, '$ordinal.jxl'));
      final result = await _encoder.encodeImage(
        image,
        staged,
        presetArgs,
        cjxlPath,
        maskArgs,
        onLog: logs.add,
        isCancelled: () => _cancelRequested,
        waitIfPaused: waitIfPaused,
      );
      switch (result) {
        case Ok(value: final outcome):
          if (outcome.cancelled) {
            return _StagedPage(
              originalName: originalName,
              beforeBytes: beforeBytes,
              cancelled: true,
              logs: logs,
            );
          }
          if (!outcome.success) {
            return _StagedPage(
              originalName: originalName,
              beforeBytes: beforeBytes,
              error:
                  'Encoding failed for $originalName; leaving source untouched',
              logs: logs,
            );
          }
          if (outcome.encoded) {
            return _StagedPage(
              originalName: originalName,
              beforeBytes: beforeBytes,
              afterBytes: outcome.outputBytes,
              entry: ArchiveEntry('$ordinal.jxl', staged),
              logs: logs,
            );
          }
          final original = File(p.join(stagingPath, '$ordinal$extension'));
          await image.copy(original.path);
          return _StagedPage(
            originalName: originalName,
            beforeBytes: beforeBytes,
            afterBytes: await _lengthOrNull(original),
            entry: ArchiveEntry('$ordinal$extension', original),
            logs: logs,
          );
        case Err(:final message):
          return _StagedPage(
            originalName: originalName,
            beforeBytes: beforeBytes,
            error: 'Encoding failed for $originalName: $message',
            logs: logs,
          );
      }
    } catch (e) {
      return _StagedPage(
        originalName: originalName,
        beforeBytes: beforeBytes,
        error: 'Failed to stage $originalName: $e',
        logs: logs,
      );
    }
  }

  String Function(List<String>) _argumentMasker(String originalPath) {
    final maskPath = makeMaskPath(originalPath, originalPath);
    return (args) => args
        .map((arg) {
          if (p.isAbsolute(arg) || arg.contains(p.separator)) {
            return maskPath(arg);
          }
          return arg;
        })
        .join(' ');
  }

  Future<bool> _archiveIsCurrent(String target, Directory comic) async {
    final file = File(target);
    if (!await file.exists()) return false;
    try {
      final archiveTime = (await file.stat()).modified;
      final sourceTime = (await comic.stat()).modified;
      return !archiveTime.isBefore(sourceTime);
    } catch (_) {
      return false;
    }
  }

  Future<int?> _lengthOrNull(File file) async {
    try {
      return await file.length();
    } catch (_) {
      return null;
    }
  }
}

final class _StagedPage {
  final String originalName;
  final int? beforeBytes;
  final int? afterBytes;
  final ArchiveEntry? entry;
  final bool cancelled;
  final String? error;
  final List<String> logs;

  const _StagedPage({
    required this.originalName,
    required this.beforeBytes,
    this.afterBytes,
    this.entry,
    this.cancelled = false,
    this.error,
    this.logs = const [],
  });

  bool get success => entry != null;
}
