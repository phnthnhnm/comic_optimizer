/// What a run will touch, computed before it starts.
final class PreflightSummary {
  final int roots;
  final int comics;
  final int images;
  final int nonImageFiles;
  final List<String> folders;

  const PreflightSummary({
    required this.roots,
    required this.comics,
    required this.images,
    required this.nonImageFiles,
    this.folders = const [],
  });

  bool get isEmpty => comics == 0;

  static const empty = PreflightSummary(
    roots: 0,
    comics: 0,
    images: 0,
    nonImageFiles: 0,
  );
}
