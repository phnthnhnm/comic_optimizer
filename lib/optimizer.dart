import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

typedef LogCallback = void Function(String);
typedef FolderCallback = void Function(String folderPath);
typedef FolderDoneCallback =
    void Function(
      String folderPath,
      bool success,
      int? beforeBytes,
      int? afterBytes,
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
            if (safeRun) {
              try {
                // Emit folder start for the original folder so subsequent logs
                // (like copy creation) are associated with that folder tab instead of General
                onFolderStart?.call(sub.path);
                startEmitted = true;
                working = await _makeCopyDirectory(sub);
                onLog?.call(
                  'Created safe copy ${working.path} for ${sub.path}',
                );
              } catch (e) {
                onLog?.call('Failed to create safe copy for ${sub.path}: $e');
                working = sub;
              }
            }
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
            if (safeRun) {
              try {
                onFolderStart?.call(entity.path);
                startEmitted = true;
                working = await _makeCopyDirectory(entity);
                onLog?.call(
                  'Created safe copy ${working.path} for ${entity.path}',
                );
              } catch (e) {
                onLog?.call(
                  'Failed to create safe copy for ${entity.path}: $e',
                );
                working = entity;
              }
            }
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

  Future<Directory> _makeCopyDirectory(Directory src) async {
    final parent = src.parent;
    final base = p.basename(src.path);
    // find non-colliding name like 'name (1)', 'name (2)', ...
    var idx = 1;
    String candidate;
    do {
      candidate = p.join(parent.path, '$base ($idx)');
      idx++;
    } while (await Directory(candidate).exists());
    final dest = Directory(candidate);
    await dest.create(recursive: true);

    Future<void> copyRecursive(Directory from, Directory to) async {
      await for (final ent in from.list(recursive: false, followLinks: false)) {
        if (ent is File) {
          final rel = p.relative(ent.path, from: from.path);
          final target = File(p.join(to.path, rel));
          await target.parent.create(recursive: true);
          await ent.copy(target.path);
        } else if (ent is Directory) {
          final sub = Directory(p.join(to.path, p.basename(ent.path)));
          await sub.create(recursive: true);
          await copyRecursive(ent, sub);
        }
      }
    }

    await copyRecursive(src, dest);
    return dest;
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
    // Helper to shorten paths in logs: keep full folder path only on the initial Start message;
    // for subsequent messages, display only basenames for files and folder names.
    String maskPath(String s) {
      if (s.isEmpty) return s;
      final norm = p.normalize(s);
      final folderNorm = p.normalize(folder.path);
      final origNorm = p.normalize(originalPath);
      if (norm == folderNorm || norm == origNorm) return p.basename(norm);
      if (norm.startsWith(folderNorm + p.separator) ||
          norm.startsWith(origNorm + p.separator)) {
        return p.basename(norm);
      }
      return s;
    }

    String maskArgs(List<String> args) => args.map(maskPath).join(' ');

    if (emitStart) onFolderStart?.call(originalPath);
    var success = true;
    int? beforeTotalBytes;
    int? archiveBytes;
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

      // Calculate total bytes of input images before processing
      try {
        int b = 0;
        for (final f in images) {
          try {
            b += await f.length();
          } catch (_) {}
        }
        beforeTotalBytes = b;
      } catch (_) {
        beforeTotalBytes = null;
      }

      // Clean non-image files: delete files that are not images
      for (final f in files) {
        if (!_imgExts.contains(p.extension(f.path).toLowerCase())) {
          try {
            await f.delete();
            onLog?.call('Deleted non-image: ${p.basename(f.path)}');
          } catch (e) {
            onLog?.call('Failed to delete ${p.basename(f.path)}: $e');
          }
        }
      }

      // Refresh images after deletion
      final remaining = await folder
          .list(recursive: false, followLinks: false)
          .where((e) => e is File)
          .cast<File>()
          .toList();
      final imageFiles = remaining
          .where((f) => _imgExts.contains(p.extension(f.path).toLowerCase()))
          .toList();

      // Normalize filenames in natural order
      imageFiles.sort(
        (a, b) => _naturalCompare(p.basename(a.path), p.basename(b.path)),
      );
      final count = imageFiles.length;
      final pad = count.toString().length;
      // Use atomic temp rename to avoid collisions
      var idx = 1;
      final tempPrefix = '._tmp_';
      for (final f in imageFiles) {
        final ext = p.extension(f.path);
        final paddedIdx = idx.toString().padLeft(pad, '0');
        final temp = p.join(
          folder.path,
          '$tempPrefix${DateTime.now().microsecondsSinceEpoch}_$paddedIdx$ext',
        );
        try {
          await f.rename(temp);
        } catch (e) {
          // fallback to copy+delete
          try {
            await f.copy(temp);
            await f.delete();
          } catch (_) {}
        }
        idx++;
      }

      // Finalize renames from temp to sequential names
      final temps = await folder
          .list(recursive: false, followLinks: false)
          .where((e) => e is File && p.basename(e.path).startsWith(tempPrefix))
          .cast<File>()
          .toList();
      temps.sort(
        (a, b) => _naturalCompare(p.basename(a.path), p.basename(b.path)),
      );
      idx = 1;
      for (final f in temps) {
        if (_cancelRequested) {
          onLog?.call('Operation cancelled by user');
          break;
        }
        final ext = p.extension(f.path);
        final targetName = '${idx.toString().padLeft(pad, '0')}$ext';
        final target = p.join(folder.path, targetName);
        try {
          await f.rename(target);
        } catch (e) {
          try {
            await f.copy(target);
            await f.delete();
          } catch (e) {
            onLog?.call(
              'Failed to finalize rename ${p.basename(f.path)} -> ${p.basename(target)}: $e',
            );
          }
        }
        idx++;
      }

      // Encode each image to JPEG XL using `cjxl` and the provided preset args
      if (!skipCjxl) {
        try {
          final toEncode = await folder
              .list(recursive: false, followLinks: false)
              .where((e) => e is File)
              .cast<File>()
              .toList();
          // Only consider image extensions (but do not re-encode existing .jxl)
          final encodeFiles = toEncode.where((f) {
            final ext = p.extension(f.path).toLowerCase();
            return _imgExts.contains(ext) && ext != '.jxl';
          }).toList();
          encodeFiles.sort(
            (a, b) => _naturalCompare(p.basename(a.path), p.basename(b.path)),
          );
          for (final f in encodeFiles) {
            if (_cancelRequested) {
              onLog?.call('Operation cancelled by user');
              break;
            }
            final base = p.basenameWithoutExtension(f.path);
            final outPath = p.join(folder.path, '$base.jxl');

            // If input is .webp, convert losslessly to PNG first using dwebp,
            // then feed the PNG to cjxl (cjxl doesn't accept webp).
            var inputPath = f.path;
            final ext = p.extension(f.path).toLowerCase();
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
                  '-quiet',
                ], workingDirectory: folder.path);
                if (_cancelRequested) {
                  onLog?.call('Operation cancelled by user');
                  break;
                }
                if (conv.exitCode != 0) {
                  if (conv.stderr != null &&
                      conv.stderr.toString().isNotEmpty) {
                    onLog?.call(conv.stderr.toString());
                  } else {
                    onLog?.call(
                      'dwebp exit ${conv.exitCode} for ${p.basename(f.path)}',
                    );
                  }
                  success = false;
                  // skip running cjxl for this file
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
              if (_cancelRequested) {
                onLog?.call('Operation cancelled by user');
                break;
              }
              if (result.stdout != null &&
                  result.stdout.toString().isNotEmpty) {
                onLog?.call(result.stdout.toString());
              }
              if (result.stderr != null &&
                  result.stderr.toString().isNotEmpty) {
                onLog?.call(result.stderr.toString());
              }

              // If cjxl failed with exit code 1, try to resave the input losslessly
              // with ImageMagick and retry cjxl using the resaved PNG.
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
                      // Retry cjxl with the resaved file
                      final retryArgs = [resavedPath, outPath, ...presetArgs];
                      onLog?.call('Retrying cjxl: cjxl ${maskArgs(retryArgs)}');
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
                      }
                    } else {
                      onLog?.call(
                        'ImageMagick resave failed (exit ${magick.exitCode}), not retrying cjxl',
                      );
                      success = false;
                    }
                    // Attempt to remove the resaved temp file if it exists
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
              }
            } catch (e) {
              onLog?.call(
                'Failed to run cjxl for ${p.basename(inputPath)}: $e',
              );
              success = false;
            }
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
      final afterOpt = await folder
          .list(recursive: false, followLinks: false)
          .where((e) => e is File)
          .cast<File>()
          .toList();
      final grouped = <String, List<File>>{};
      for (final f in afterOpt) {
        final base = p.basenameWithoutExtension(f.path);
        grouped.putIfAbsent(base, () => []).add(f);
      }
      for (final entry in grouped.entries) {
        final hasJxl = entry.value.any(
          (f) => p.extension(f.path).toLowerCase() == '.jxl',
        );
        if (hasJxl) {
          for (final f in entry.value) {
            final ext = p.extension(f.path).toLowerCase();
            if (ext != '.jxl') {
              try {
                await f.delete();
                onLog?.call('Removed duplicate original ${p.basename(f.path)}');
              } catch (e) {
                onLog?.call('Failed to remove ${p.basename(f.path)}: $e');
              }
            }
          }
        }
      }

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

      try {
        // Build archive in memory using store (level 0)
        final archive = Archive();
        final finalFiles = await parentForFolderFiles(folder);
        for (final f in finalFiles) {
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
        success = false;
      }

      // Remove source folder if archive is outside
      try {
        final arch = p.normalize(p.absolute(p.join(parent.path, archiveName)));
        final folderAbs = p.normalize(p.absolute(folder.path));
        if (!p.isWithin(folderAbs, arch)) {
          try {
            if (preferPermanentDelete) {
              await folder.delete(recursive: true);
              onLog?.call(
                'Removed source folder ${p.basename(originalPath)} (permanent delete)',
              );
            } else {
              await _recycleOrDelete(folder);
              onLog?.call(
                'Removed source folder ${p.basename(originalPath)} (moved to Recycle Bin on Windows)',
              );
            }
          } catch (e) {
            onLog?.call(
              'Failed to remove source folder ${p.basename(originalPath)}: $e',
            );
            success = false;
          }
        } else {
          onLog?.call('Archive is inside source; not deleting source folder');
        }
      } catch (e) {
        onLog?.call('Failed to delete source folder: $e');
        success = false;
      }
    } catch (e) {
      onLog?.call('Error processing ${p.basename(originalPath)}: $e');
      success = false;
    } finally {
      onFolderDone?.call(originalPath, success, beforeTotalBytes, archiveBytes);
    }
  }

  Future<List<File>> parentForFolderFiles(Directory folder) async {
    final files = await folder
        .list(recursive: false, followLinks: false)
        .where((e) => e is File)
        .cast<File>()
        .toList();
    files.sort(
      (a, b) => _naturalCompare(p.basename(a.path), p.basename(b.path)),
    );
    return files;
  }

  Future<void> _recycleOrDelete(Directory folder) async {
    try {
      if (Platform.isWindows) {
        final safePath = folder.path.replaceAll("'", "''");
        final cmd =
            "Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory('$safePath', [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs, [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin)";
        onLog?.call('Sending ${folder.path} to Recycle Bin via PowerShell');
        final result = await Process.run('powershell', [
          '-NoProfile',
          '-Command',
          cmd,
        ]);
        if (result.stdout != null && result.stdout.toString().isNotEmpty) {
          onLog?.call(result.stdout.toString());
        }
        if (result.stderr != null && result.stderr.toString().isNotEmpty) {
          onLog?.call(result.stderr.toString());
        }
        if (result.exitCode != 0) {
          throw Exception('PowerShell exit ${result.exitCode}');
        }
      } else {
        await folder.delete(recursive: true);
      }
    } catch (e) {
      rethrow;
    }
  }

  int _naturalCompare(String a, String b) {
    final regex = RegExp(r"(\\d+)|([^\\d]+)");
    final ma = regex.allMatches(a);
    final mb = regex.allMatches(b);
    final len = ma.length < mb.length ? ma.length : mb.length;
    for (var i = 0; i < len; i++) {
      final sa = ma.elementAt(i).group(0)!;
      final sb = mb.elementAt(i).group(0)!;
      final ai = int.tryParse(sa);
      final bi = int.tryParse(sb);
      if (ai != null && bi != null) {
        final cmp = ai.compareTo(bi);
        if (cmp != 0) return cmp;
      } else {
        final cmp = sa.compareTo(sb);
        if (cmp != 0) return cmp;
      }
    }
    return a.length.compareTo(b.length);
  }
}
