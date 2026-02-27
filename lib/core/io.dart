import 'dart:io';

import 'package:path/path.dart' as p;

import 'utils.dart';

typedef LogCallback = void Function(String);
typedef FolderCallback = void Function(String folderPath);

class SafeCopyResult {
  final Directory working;
  final bool startEmitted;
  SafeCopyResult(this.working, this.startEmitted);
}

Future<SafeCopyResult> makeSafeCopyIfRequested(
  Directory entity,
  bool safeRun, {
  LogCallback? onLog,
  FolderCallback? onFolderStart,
}) async {
  Directory working = entity;
  var startEmitted = false;
  if (safeRun) {
    try {
      onFolderStart?.call(entity.path);
      startEmitted = true;
      working = await makeCopyDirectory(entity);
      onLog?.call('Created safe copy ${working.path} for ${entity.path}');
    } catch (e) {
      onLog?.call('Failed to create safe copy for ${entity.path}: $e');
      working = entity;
    }
  }
  return SafeCopyResult(working, startEmitted);
}

/// Clean non-image files: delete files that are not images
Future<void> removeNonImageFiles(
  Directory folder,
  Set<String> exts, {
  LogCallback? onLog,
}) async {
  final files = await folder
      .list(recursive: false, followLinks: false)
      .where((e) => e is File)
      .cast<File>()
      .toList();
  for (final f in files) {
    if (!exts.contains(p.extension(f.path).toLowerCase())) {
      try {
        await f.delete();
        onLog?.call('Deleted non-image: ${p.basename(f.path)}');
      } catch (e) {
        onLog?.call('Failed to delete ${p.basename(f.path)}: $e');
      }
    }
  }
}

/// Refresh images after deletion
Future<List<File>> listImageFiles(Directory folder, Set<String> exts) async {
  final files = await folder
      .list(recursive: false, followLinks: false)
      .where((e) => e is File)
      .cast<File>()
      .toList();
  final imgs = files
      .where((f) => exts.contains(p.extension(f.path).toLowerCase()))
      .toList();
  imgs.sort((a, b) => naturalCompare(p.basename(a.path), p.basename(b.path)));
  return imgs;
}

Future<void> removeDuplicateOriginals(
  Directory folder, {
  LogCallback? onLog,
}) async {
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
}

Future<Directory> makeCopyDirectory(Directory src) async {
  final parent = src.parent;
  final base = p.basename(src.path);
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

/// Rename [files] inside [folder] into sequential padded names while using
/// atomic temp names to avoid collisions. This mirrors the behavior that was
/// previously inline in `optimizer.dart`.
Future<void> normalizeFilenamesSequential(
  Directory folder,
  List<File> files, {
  String tempPrefix = '._tmp_',
  LogCallback? onLog,
  bool Function()? isCancelled,
}) async {
  files.sort((a, b) => naturalCompare(p.basename(a.path), p.basename(b.path)));
  final count = files.length;
  final pad = count.toString().length;

  var idx = 1;
  for (final f in files) {
    if (isCancelled != null && isCancelled()) {
      onLog?.call('Operation cancelled by user');
      break;
    }
    final ext = p.extension(f.path);
    final paddedIdx = idx.toString().padLeft(pad, '0');
    final temp = p.join(
      folder.path,
      '$tempPrefix${DateTime.now().microsecondsSinceEpoch}_$paddedIdx$ext',
    );
    try {
      await f.rename(temp);
    } catch (e) {
      try {
        await f.copy(temp);
        await f.delete();
      } catch (_) {}
    }
    idx++;
  }

  // Finalize renames
  final temps = await folder
      .list(recursive: false, followLinks: false)
      .where((e) => e is File && p.basename(e.path).startsWith(tempPrefix))
      .cast<File>()
      .toList();
  temps.sort((a, b) => naturalCompare(p.basename(a.path), p.basename(b.path)));
  idx = 1;
  for (final f in temps) {
    if (isCancelled != null && isCancelled()) {
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
}

Future<List<File>> parentForFolderFiles(Directory folder) async {
  final files = await folder
      .list(recursive: false, followLinks: false)
      .where((e) => e is File)
      .cast<File>()
      .toList();
  files.sort((a, b) => naturalCompare(p.basename(a.path), p.basename(b.path)));
  return files;
}

Future<void> recycleOrDelete(Directory folder, {LogCallback? onLog}) async {
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
