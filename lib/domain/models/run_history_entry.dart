/// Persisted summary of a completed run, shown on the History screen.
final class RunHistoryEntry {
  final String id;
  final DateTime startedAt;
  final DateTime finishedAt;
  final List<String> libraries;
  final int comics;
  final int failed;
  final int images;
  final int? beforeBytes;
  final int? afterBytes;
  final List<String> failedFolders;

  const RunHistoryEntry({
    required this.id,
    required this.startedAt,
    required this.finishedAt,
    required this.libraries,
    required this.comics,
    required this.failed,
    required this.images,
    required this.beforeBytes,
    required this.afterBytes,
    required this.failedFolders,
  });

  Duration get duration => finishedAt.difference(startedAt);

  int get succeeded => comics - failed;

  int? get savedBytes {
    final before = beforeBytes;
    final after = afterBytes;
    if (before == null || after == null) return null;
    return before - after;
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'finishedAt': finishedAt.toIso8601String(),
    'libraries': libraries,
    'comics': comics,
    'failed': failed,
    'images': images,
    'beforeBytes': beforeBytes,
    'afterBytes': afterBytes,
    'failedFolders': failedFolders,
  };

  factory RunHistoryEntry.fromJson(Map<String, Object?> json) {
    return RunHistoryEntry(
      id: json['id']?.toString() ?? '',
      startedAt: _date(json['startedAt']),
      finishedAt: _date(json['finishedAt']),
      libraries: _strings(json['libraries']),
      comics: _int(json['comics']),
      failed: _int(json['failed']),
      images: _int(json['images']),
      beforeBytes: _nullableInt(json['beforeBytes']),
      afterBytes: _nullableInt(json['afterBytes']),
      failedFolders: _strings(json['failedFolders']),
    );
  }

  static DateTime _date(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static int _int(Object? value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  static int? _nullableInt(Object? value) =>
      value is num ? value.toInt() : int.tryParse('$value');

  static List<String> _strings(Object? value) {
    if (value is List) return value.whereType<String>().toList();
    return const [];
  }
}
