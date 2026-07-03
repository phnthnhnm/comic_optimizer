import 'dart:io';

import '../../core/result.dart';

/// Result of creating an archive.
final class ArchiveResult {
  final bool success;
  final int? bytes;
  final String? path;

  const ArchiveResult(this.success, this.bytes, this.path);
}

/// Contract for creating ZIP archives from comic folders.
abstract interface class IArchiveService {
  Future<Result<ArchiveResult>> createArchiveAndMaybeRemoveSource(
    Directory folder,
    String originalPath,
    String outputExtension,
    bool preferPermanentDelete, {
    void Function(String)? onLog,
    Future<void> Function()? waitIfPaused,
  });
}
