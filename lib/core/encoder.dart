import 'dart:io';

import 'package:path/path.dart' as p;

import 'utils.dart';

typedef LogCallback = void Function(String);

class Encoder {
  final LogCallback? onLog;
  final bool Function() isCancelled;
  final Future<void> Function()? waitIfPaused;

  Encoder({this.onLog, required this.isCancelled, this.waitIfPaused});

  static final _imgExts = {'.png', '.jpg', '.jpeg', '.webp', '.apng', '.jxl'};

  /// Encode images in [folder] to `.jxl` using [cjxlPath] and [presetArgs].
  /// [maskArgs] is used to format args for logging (same as in Optimizer).
  Future<bool> encodeFolder(
    Directory folder,
    List<String> presetArgs,
    String cjxlPath,
    String Function(List<String>) maskArgs,
  ) async {
    var success = true;
    try {
      final toEncode = await folder
          .list(recursive: false, followLinks: false)
          .where((e) => e is File)
          .cast<File>()
          .toList();

      final encodeFiles = toEncode.where((f) {
        final ext = p.extension(f.path).toLowerCase();
        return _imgExts.contains(ext) && ext != '.jxl';
      }).toList();
      encodeFiles.sort(
        (a, b) => naturalCompare(p.basename(a.path), p.basename(b.path)),
      );

      for (final f in encodeFiles) {
        if (waitIfPaused != null) await waitIfPaused!();
        if (isCancelled()) {
          onLog?.call('Operation cancelled by user');
          break;
        }
        final base = p.basenameWithoutExtension(f.path);
        final outPath = p.join(folder.path, '$base.jxl');
        var inputPath = f.path;
        final ext = p.extension(f.path).toLowerCase();
        // Remember original file path & size for per-file comparison.
        final originalPath = f.path;
        int? originalSize;
        try {
          originalSize = await File(originalPath).length();
        } catch (_) {
          originalSize = null;
        }
        var createdIntermediatePng = false;
        String? intermediatePngPath;
        if (ext == '.webp') {
          final pngPath = p.join(folder.path, '$base.png');
          onLog?.call(
            'Converting WEBP -> PNG: dwebp ${p.basename(f.path)} -o ${p.basename(pngPath)}',
          );
          try {
            final conv = await Process.run('dwebp', [
              f.path,
              '-o',
              pngPath,
              '-mt',
              '-quiet',
            ], workingDirectory: folder.path);
            if (isCancelled()) {
              onLog?.call('Operation cancelled by user');
              break;
            }
            if (conv.exitCode != 0) {
              if (conv.stderr != null && conv.stderr.toString().isNotEmpty) {
                onLog?.call(conv.stderr.toString());
              } else {
                onLog?.call(
                  'dwebp exit ${conv.exitCode} for ${p.basename(f.path)}',
                );
              }
              success = false;
              continue;
            }
            final outFile = File(pngPath);
            if (!await outFile.exists()) {
              onLog?.call(
                'dwebp did not produce ${p.basename(pngPath)} for ${p.basename(f.path)}',
              );
              success = false;
              continue;
            }
            inputPath = pngPath;
            createdIntermediatePng = true;
            intermediatePngPath = pngPath;
          } catch (e) {
            onLog?.call('Failed to run dwebp for ${f.path}: $e');
            success = false;
            continue;
          }
        }

        final args = [inputPath, outPath, ...presetArgs];
        onLog?.call('Running cjxl: cjxl ${maskArgs(args)}');
        try {
          var result = await Process.run(
            cjxlPath,
            args,
            workingDirectory: folder.path,
          );
          if (waitIfPaused != null) await waitIfPaused!();
          if (isCancelled()) {
            onLog?.call('Operation cancelled by user');
            break;
          }
          if (result.stdout != null && result.stdout.toString().isNotEmpty) {
            onLog?.call(result.stdout.toString());
          }
          if (result.stderr != null && result.stderr.toString().isNotEmpty) {
            onLog?.call(result.stderr.toString());
          }

          // After cjxl run, if output exists compare sizes to original and
          // revert (delete) the .jxl if it's larger than the original.
          Future<void> maybeRevertIfLarger(String jxlPath) async {
            try {
              final jxlFile = File(jxlPath);
              if (!await jxlFile.exists()) return;
              final jxlSize = await jxlFile.length();
              if (originalSize != null && jxlSize >= originalSize) {
                try {
                  await jxlFile.delete();
                  onLog?.call(
                    'Reverted larger .jxl: ${p.basename(jxlPath)} (was $jxlSize bytes > original $originalSize bytes)',
                  );
                } catch (e) {
                  onLog?.call(
                    'Failed to delete larger .jxl ${p.basename(jxlPath)}: $e',
                  );
                }
                // If we created an intermediate PNG from WEBP, remove it too.
                if (createdIntermediatePng && intermediatePngPath != null) {
                  try {
                    final ip = File(intermediatePngPath);
                    if (await ip.exists()) {
                      await ip.delete();
                      onLog?.call(
                        'Removed intermediate PNG ${p.basename(intermediatePngPath)}',
                      );
                    }
                  } catch (e) {
                    onLog?.call(
                      'Failed to remove intermediate PNG ${p.basename(intermediatePngPath)}: $e',
                    );
                  }
                }
              }
            } catch (_) {}
          }

          if (result.exitCode != 0) {
            if (result.exitCode == 1) {
              final resavedPath = p.join(
                folder.path,
                '${base}_magick_resaved_${DateTime.now().microsecondsSinceEpoch}.png',
              );
              onLog?.call(
                'cjxl exit 1 for ${p.basename(inputPath)}; attempting ImageMagick resave -> ${p.basename(resavedPath)}',
              );
              try {
                final magick = await Process.run('magick', [
                  inputPath,
                  '-strip',
                  resavedPath,
                ], workingDirectory: folder.path);
                if (magick.stdout != null &&
                    magick.stdout.toString().isNotEmpty) {
                  onLog?.call(magick.stdout.toString());
                }
                if (magick.stderr != null &&
                    magick.stderr.toString().isNotEmpty) {
                  onLog?.call(magick.stderr.toString());
                }
                final resavedFile = File(resavedPath);
                if (magick.exitCode == 0 && await resavedFile.exists()) {
                  final retryArgs = [resavedPath, outPath, ...presetArgs];
                  onLog?.call('Retrying cjxl: cjxl ${maskArgs(retryArgs)}');
                  if (waitIfPaused != null) await waitIfPaused!();
                  final retry = await Process.run(
                    cjxlPath,
                    retryArgs,
                    workingDirectory: folder.path,
                  );
                  if (retry.stdout != null &&
                      retry.stdout.toString().isNotEmpty) {
                    onLog?.call(retry.stdout.toString());
                  }
                  if (retry.stderr != null &&
                      retry.stderr.toString().isNotEmpty) {
                    onLog?.call(retry.stderr.toString());
                  }
                  if (retry.exitCode != 0) {
                    onLog?.call('cjxl retry exit ${retry.exitCode}');
                    success = false;
                  } else {
                    // Successful retry; check size and possibly revert
                    await maybeRevertIfLarger(outPath);
                  }
                } else {
                  onLog?.call(
                    'ImageMagick resave failed (exit ${magick.exitCode}), not retrying cjxl',
                  );
                  success = false;
                }
                try {
                  if (await File(resavedPath).exists()) {
                    await File(resavedPath).delete();
                  }
                } catch (_) {}
              } catch (e) {
                onLog?.call(
                  'Failed to run ImageMagick for ${p.basename(inputPath)}: $e',
                );
                success = false;
              }
            } else {
              onLog?.call('cjxl exit ${result.exitCode}');
              success = false;
            }
          } else {
            // Successful first cjxl run; check size and possibly revert.
            await maybeRevertIfLarger(outPath);
          }
        } catch (e) {
          onLog?.call('Failed to run cjxl for ${p.basename(inputPath)}: $e');
          success = false;
        }
      }
    } catch (e) {
      onLog?.call('Failed during cjxl encoding: $e');
      return false;
    }
    return success;
  }
}
