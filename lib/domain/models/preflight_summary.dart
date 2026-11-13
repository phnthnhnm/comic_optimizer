/// What a run will touch, computed before it starts.
final class PreflightSummary {
  final int roots;
  final int comics;
  final int images;
  final int nonImageFiles;

  const PreflightSummary({
    required this.roots,
    required this.comics,
    required this.images,
    required this.nonImageFiles,
  });

  bool get isEmpty => comics == 0;

  static const empty = PreflightSummary(
    roots: 0,
    comics: 0,
    images: 0,
    nonImageFiles: 0,
  );
}
