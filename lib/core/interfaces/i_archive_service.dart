import 'dart:io';

import '../../core/result.dart';

/// One file to place inside the finished archive.
final class ArchiveEntry {
  final String name;
  final File file;

  const ArchiveEntry(this.name, this.file);
}

/// Result of creating and publishing an archive.
final class ArchiveResult {
  final bool success;
  final int? bytes;
  final String? path;
  final bool verified;
  final bool skipped;

  const ArchiveResult(
    this.success,
    this.bytes,
    this.path, {
    this.verified = false,
    this.skipped = false,
  });
}

/// Contract for creating verified ZIP archives.
abstract interface class IArchiveService {
  Future<Result<ArchiveResult>> publish(
    List<ArchiveEntry> entries,
    String targetPath, {
    void Function(String)? onLog,
    Future<void> Function()? waitIfPaused,
  });
}
