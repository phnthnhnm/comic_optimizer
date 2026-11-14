import 'dart:io';

/// Opens Explorer with [path] selected, falling back to its parent folder.
Future<void> revealInExplorer(String path) async {
  if (!Platform.isWindows) return;
  final file = File(path);
  final exists = await file.exists();
  if (exists) {
    await Process.run('explorer.exe', ['/select,', path]);
  } else {
    final parent = file.parent;
    if (await parent.exists()) {
      await Process.run('explorer.exe', [parent.path]);
    }
  }
}

/// Opens a folder in Explorer.
Future<void> openFolder(String path) async {
  if (!Platform.isWindows) return;
  if (await Directory(path).exists()) {
    await Process.run('explorer.exe', [path]);
  }
}
