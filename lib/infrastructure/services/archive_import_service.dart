import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import 'package:comic_optimizer/core/interfaces/i_optimizer_service.dart';
import 'package:comic_optimizer/core/result.dart';
import 'package:comic_optimizer/domain/enums/output_mode.dart';
import 'package:comic_optimizer/domain/models/app_settings.dart';
import 'package:comic_optimizer/domain/models/image_formats.dart';
import 'package:comic_optimizer/domain/models/preset.dart';

final class ArchiveImportResult {
  final String sourcePath;
  final bool success;
  final String? archivePath;
  final String? error;

  const ArchiveImportResult({
    required this.sourcePath,
    required this.success,
    this.archivePath,
    this.error,
  });
}

/// Imports a CBZ/ZIP into a temporary comic folder, runs the staged pipeline,
/// and publishes a new archive without modifying the source archive.
final class ArchiveImportService {
  static const _maxEntries = 20000;
  static const _maxTotalBytes = 8 * 1024 * 1024 * 1024;

  final IOptimizerService optimizer;

  const ArchiveImportService(this.optimizer);

  Future<Result<ArchiveImportResult>> importArchive(
    File source,
    AppSettings settings, {
    void Function(String message)? onProgress,
  }) async {
    if (!await source.exists()) {
      return Err('Archive does not exist: ${source.path}');
    }
    final extension = p.extension(source.path).toLowerCase();
    if (extension != '.cbz' && extension != '.zip') {
      return Err('Only .cbz and .zip archives can be imported');
    }

    Directory? temp;
    try {
      temp = await Directory.systemTemp.createTemp('comic_import_');
      final base = _safeName(p.basenameWithoutExtension(source.path));
      final comic = Directory(p.join(temp.path, base))..createSync();
      final archive = ZipDecoder().decodeBytes(await source.readAsBytes());
      if (archive.files.length > _maxEntries) {
        return const Err('Archive has too many entries');
      }

      var totalBytes = 0;
      var imageCount = 0;
      final usedNames = <String>{};
      for (final entry in archive.files) {
        if (!entry.isFile) continue;
        final normalized = entry.name.replaceAll('\\', '/');
        if (normalized.isEmpty ||
            normalized.startsWith('/') ||
            p.isAbsolute(normalized) ||
            normalized.split('/').contains('..')) {
          return Err('Unsafe archive entry: ${entry.name}');
        }
        final content = entry.content;
        totalBytes += content.length;
        if (totalBytes > _maxTotalBytes) {
          return const Err('Archive is too large to import safely');
        }

        var name = p.basename(normalized);
        if (name.isEmpty) name = 'page';
        var unique = name;
        var suffix = 2;
        while (!usedNames.add(unique.toLowerCase())) {
          final ext = p.extension(name);
          final stem = p.basenameWithoutExtension(name);
          unique = '$stem ($suffix)$ext';
          suffix++;
        }
        final output = File(p.join(comic.path, unique));
        await output.writeAsBytes(content);
        if (isSupportedImage(output.path)) imageCount++;
      }

      if (imageCount == 0) {
        return const Err('Archive contains no supported images');
      }

      onProgress?.call('Optimizing ${p.basename(source.path)}');
      final preset = Preset.resolve(
        settings.lastPreset,
        settings.customPresets,
      );
      String? generated;
      final optimizeResult = await optimizer.optimizeRoot(
        temp,
        presetArgs: preset.args,
        skipCjxl: settings.skipCjxl,
        deleteNonImageFiles: settings.deleteNonImageFiles,
        cjxlPath: settings.cjxlPath,
        outputExtension: settings.outputExt,
        safeRun: true,
        preferPermanentDelete: false,
        presetName: preset.name,
        namingTemplate: '{folder}',
        globalOutputDirectory: '',
        outputMode: OutputMode.besideSource,
        maxParallelEncodes: settings.maxParallelEncodes,
        onFolderDone: (_, success, _, _, _, archivePath) {
          if (success) generated = archivePath;
        },
      );
      if (optimizeResult is Err<void>) {
        return Err(optimizeResult.message);
      }
      if (generated == null) {
        return const Err('The archive could not be optimized');
      }

      final target = await _targetPath(source, settings);
      final moved = await _moveArchive(File(generated!), target);
      if (!moved.success) return Err(moved.error!);
      return Ok(
        ArchiveImportResult(
          sourcePath: source.path,
          success: true,
          archivePath: target,
        ),
      );
    } catch (e) {
      return Err('Import failed: $e');
    } finally {
      if (temp != null) {
        try {
          if (await temp.exists()) await temp.delete(recursive: true);
        } catch (_) {}
      }
    }
  }

  Future<String> _targetPath(File source, AppSettings settings) async {
    String directory;
    if (settings.outputMode == OutputMode.custom &&
        settings.outputDirectory.trim().isNotEmpty) {
      directory = settings.outputDirectory;
    } else {
      directory = source.parent.path;
    }
    final base = '${p.basenameWithoutExtension(source.path)} (optimized)';
    var target = p.join(directory, '$base${settings.outputExt}');
    if (!await File(target).exists()) return target;
    for (var i = 2; i < 10000; i++) {
      target = p.join(directory, '$base ($i)${settings.outputExt}');
      if (!await File(target).exists()) return target;
    }
    return target;
  }

  Future<({bool success, String? error})> _moveArchive(
    File source,
    String target,
  ) async {
    try {
      await Directory(p.dirname(target)).create(recursive: true);
      await source.rename(target);
      return (success: true, error: null);
    } catch (_) {
      try {
        await source.copy(target);
        await source.delete();
        return (success: true, error: null);
      } catch (e) {
        return (success: false, error: 'Could not write $target: $e');
      }
    }
  }

  String _safeName(String value) {
    final cleaned = value.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), ' ');
    return cleaned.trim().isEmpty ? 'Imported comic' : cleaned.trim();
  }
}
