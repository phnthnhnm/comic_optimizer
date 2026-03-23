import 'dart:io';

import 'package:path/path.dart' as p;

/// Natural string compare that treats digit runs numerically.
int naturalCompare(String a, String b) {
  final regex = RegExp(r"(\d+)|([^\d]+)");
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

/// Returns a `maskPath` closure that shortens paths for logging.
String Function(String) makeMaskPath(String folderPath, String originalPath) {
  return (String s) {
    if (s.isEmpty) return s;
    final norm = p.normalize(s);
    final folderNorm = p.normalize(folderPath);
    final origNorm = p.normalize(originalPath);
    if (norm == folderNorm || norm == origNorm) return p.basename(norm);
    if (norm.startsWith(folderNorm + p.separator) ||
        norm.startsWith(origNorm + p.separator)) {
      return p.basename(norm);
    }
    return s;
  };
}

/// Returns a `maskArgs` closure that maps args through `maskPath` and joins them.
String Function(List<String>) makeMaskArgs(String Function(String) maskPath) {
  return (List<String> args) => args.map(maskPath).join(' ');
}

/// Sort files by natural order using their basenames.
void sortFilesNaturally(List<File> files) {
  files.sort((a, b) => naturalCompare(p.basename(a.path), p.basename(b.path)));
}

/// Calculate total bytes of input images before processing
Future<int?> sumFileLengths(List<File> files) async {
  try {
    int b = 0;
    for (final f in files) {
      try {
        b += await f.length();
      } catch (_) {}
    }
    return b;
  } catch (_) {
    return null;
  }
}

/// Helpers for formatting storage summary strings used in logs.
String storageSummaryText({
  String? folderName,
  required int? beforeBytes,
  required int? afterBytes,
  bool includeFolderName = true,
}) {
  if (beforeBytes == null || afterBytes == null) {
    if (includeFolderName && folderName != null) {
      return '$folderName: size unknown';
    }
    return 'Storage saved: size unknown';
  }

  final beforeMb = beforeBytes / (1024 * 1024);
  final afterMb = afterBytes / (1024 * 1024);
  final saved = beforeBytes - afterBytes;
  final savedMb = saved / (1024 * 1024);
  final pct = beforeBytes > 0 ? (saved / beforeBytes) * 100.0 : 0.0;
  final formatted =
      '${beforeMb.toStringAsFixed(2)} MB -> ${afterMb.toStringAsFixed(2)} MB, saved ${savedMb.toStringAsFixed(2)} MB (${pct.toStringAsFixed(2)}%)';

  if (includeFolderName && folderName != null) return '$folderName: $formatted';
  return 'Storage saved: $formatted';
}
