import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:comic_optimizer/core/interfaces/i_encoder_service.dart';
import 'package:comic_optimizer/core/interfaces/i_process_runner.dart';
import 'package:comic_optimizer/core/result.dart';
import 'package:comic_optimizer/core/utils.dart';
import 'package:comic_optimizer/domain/models/image_formats.dart';
import 'package:comic_optimizer/infrastructure/services/system_process_runner.dart';

/// Implementation of [IEncoderService] that encodes images to JPEG XL using cjxl.
final class EncoderServiceImpl implements IEncoderService {
  final IProcessRunner runner;

  const EncoderServiceImpl({this.runner = const SystemProcessRunner()});

  @override
  Future<Result<String>> probeVersion(String cjxlPath) async {
    try {
      final result = await runner.run(cjxlPath, ['--version']);
      if (result.exitCode != 0) {
        final stderr = result.stderr.toString().trim();
        return Err(
          stderr.isEmpty
              ? 'cjxl exited with code ${result.exitCode}'
              : stderr.split(RegExp(r'\r?\n')).first.trim(),
        );
      }
      final stdout = result.stdout.toString().trim();
      if (stdout.isEmpty) return const Ok('cjxl (unknown version)');
      return Ok(stdout.split(RegExp(r'\r?\n')).first.trim());
    } on ProcessException catch (error) {
      return Err(error.message);
    } catch (error) {
      return Err('$error');
    }
  }

  @override
  Future<Result<bool>> encodeFolder(
    Directory folder,
    List<String> presetArgs,
    String cjxlPath,
    String Function(List<String>) maskArgs, {
    void Function(String)? onLog,
    void Function(String path, int index, int total)? onFileStart,
    bool Function()? isCancelled,
    Future<void> Function()? waitIfPaused,
  }) async {
    var success = true;
    try {
      final toEncode = await folder
          .list(recursive: false, followLinks: false)
          .where((e) => e is File)
          .cast<File>()
          .toList();

      final encodeFiles = toEncode
          .where((f) => isEncodableImage(f.path))
          .toList();
      encodeFiles.sort(
        (a, b) => naturalCompare(p.basename(a.path), p.basename(b.path)),
      );

      for (var index = 0; index < encodeFiles.length; index++) {
        final f = encodeFiles[index];
        onFileStart?.call(f.path, index + 1, encodeFiles.length);
        if (waitIfPaused != null) await waitIfPaused();
        if (isCancelled != null && isCancelled()) {
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
            final conv = await runner.run('dwebp', [
              f.path,
              '-o',
              pngPath,
              '-mt',
              '-quiet',
            ], workingDirectory: folder.path);
            if (isCancelled != null && isCancelled()) {
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
          var result = await runner.run(
            cjxlPath,
            args,
            workingDirectory: folder.path,
          );
          if (waitIfPaused != null) await waitIfPaused();
          if (isCancelled != null && isCancelled()) {
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
                  // Capture the promoted value: `await` invalidates promotion.
                  final intermediatePath = intermediatePngPath;
                  try {
                    final ip = File(intermediatePath);
                    if (await ip.exists()) {
                      await ip.delete();
                      onLog?.call(
                        'Removed intermediate PNG ${p.basename(intermediatePath)}',
                      );
                    }
                  } catch (e) {
                    onLog?.call(
                      'Failed to remove intermediate PNG ${p.basename(intermediatePath)}: $e',
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
                final magick = await runner.run('magick', [
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
                  if (waitIfPaused != null) await waitIfPaused();
                  final retry = await runner.run(
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
      return Ok(false);
    }
    return Ok(success);
  }
}
