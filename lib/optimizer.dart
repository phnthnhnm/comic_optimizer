import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

typedef LogCallback = void Function(String);
typedef FolderCallback = void Function(String folderPath);
typedef FolderDoneCallback = void Function(String folderPath, bool success);

class Optimizer {
  final LogCallback? onLog;
  final FolderCallback? onFolderStart;
  final FolderDoneCallback? onFolderDone;

  Optimizer({this.onLog, this.onFolderStart, this.onFolderDone});

  static final _imgExts = {'.png', '.jpg', '.jpeg', '.webp', '.apng', '.jxl'};

  Future<void> optimizeRoot(
    Directory root, {
    required List<String> presetArgs,
    required bool skipCjxl,
    required String cjxlPath,
    required String outputExtension,
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
        presetArgs,
        skipCjxl,
        cjxlPath,
        outputExtension,
        preferPermanentDelete,
      );
      return;
    }

    await for (final entity in root.list(
      recursive: false,
      followLinks: false,
    )) {
      if (entity is Directory) {
        // If directory contains subdirectories, process each subdir; else process the directory itself
        final children = await entity.list(followLinks: false).toList();
        final hasDirs = children.any((e) => e is Directory);
        if (hasDirs) {
          for (final sub in children.whereType<Directory>()) {
            await _processFolder(
              sub,
              presetArgs,
              skipCjxl,
              cjxlPath,
              outputExtension,
              preferPermanentDelete,
            );
          }
        } else {
          await _processFolder(
            entity,
            presetArgs,
            skipCjxl,
            cjxlPath,
            outputExtension,
            preferPermanentDelete,
          );
        }
      }
    }
  }

  Future<void> _processFolder(
    Directory folder,
    List<String> presetArgs,
    bool skipCjxl,
    String cjxlPath,
    String outputExtension,
    bool preferPermanentDelete,
  ) async {
    onFolderStart?.call(folder.path);
    var success = true;
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
        onLog?.call('No images in ${folder.path}, skipping');
        return;
      }

      // Clean non-image files: delete files that are not images
      for (final f in files) {
        if (!_imgExts.contains(p.extension(f.path).toLowerCase())) {
          try {
            await f.delete();
            onLog?.call('Deleted non-image: ${f.path}');
          } catch (e) {
            onLog?.call('Failed to delete ${f.path}: $e');
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
            onLog?.call('Failed to finalize rename ${f.path} -> $target: $e');
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
            final base = p.basenameWithoutExtension(f.path);
            final outPath = p.join(folder.path, '$base.jxl');

            // If input is .webp, convert losslessly to PNG first using dwebp,
            // then feed the PNG to cjxl (cjxl doesn't accept webp).
            var inputPath = f.path;
            final ext = p.extension(f.path).toLowerCase();
            if (ext == '.webp') {
              final pngPath = p.join(folder.path, '$base.png');
              onLog?.call(
                'Converting WEBP -> PNG: dwebp ${f.path} -o $pngPath',
              );
              try {
                final conv = await Process.run('dwebp', [
                  f.path,
                  '-o',
                  pngPath,
                ], workingDirectory: folder.path);
                if (conv.stdout != null && conv.stdout.toString().isNotEmpty) {
                  onLog?.call(conv.stdout.toString());
                }
                if (conv.stderr != null && conv.stderr.toString().isNotEmpty) {
                  onLog?.call(conv.stderr.toString());
                }
                if (conv.exitCode != 0) {
                  onLog?.call('dwebp exit ${conv.exitCode} for ${f.path}');
                  success = false;
                  // skip running cjxl for this file
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
            onLog?.call('Running cjxl: cjxl ${args.join(' ')}');
            try {
              final result = await Process.run(
                cjxlPath,
                args,
                workingDirectory: folder.path,
              );
              if (result.stdout != null &&
                  result.stdout.toString().isNotEmpty) {
                onLog?.call(result.stdout.toString());
              }
              if (result.stderr != null &&
                  result.stderr.toString().isNotEmpty) {
                onLog?.call(result.stderr.toString());
              }
              if (result.exitCode != 0) {
                onLog?.call('cjxl exit ${result.exitCode}');
                success = false;
              }
            } catch (e) {
              onLog?.call('Failed to run cjxl for $inputPath: $e');
              success = false;
            }
          }
        } catch (e) {
          onLog?.call('Failed during cjxl encoding: $e');
          success = false;
        }
      } else {
        onLog?.call(
          'Skipping cjxl encoding for ${folder.path} (skip flag set)',
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
                onLog?.call('Removed duplicate original ${f.path}');
              } catch (e) {
                onLog?.call('Failed to remove ${f.path}: $e');
              }
            }
          }
        }
      }

      // Create archive in parent directory using store (no compression)
      final parent = Directory(folder.parent.path);
      final archiveName = '${p.basename(folder.path)}$outputExtension';
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
        onLog?.call('Created archive $archivePath');
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
                'Removed source folder ${folder.path} (permanent delete)',
              );
            } else {
              await _recycleOrDelete(folder);
              onLog?.call(
                'Removed source folder ${folder.path} (moved to Recycle Bin)',
              );
            }
          } catch (e) {
            onLog?.call('Failed to remove source folder ${folder.path}: $e');
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
      onLog?.call('Error processing ${folder.path}: $e');
      success = false;
    } finally {
      onFolderDone?.call(folder.path, success);
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
