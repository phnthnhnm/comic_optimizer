/// Outcome of processing one comic folder.
final class FolderRunResult {
  final String path;
  final String root;
  final bool success;
  final int? beforeBytes;
  final int? afterBytes;
  final String? error;
  final String? archivePath;

  const FolderRunResult({
    required this.path,
    required this.root,
    required this.success,
    this.beforeBytes,
    this.afterBytes,
    this.error,
    this.archivePath,
  });
}
