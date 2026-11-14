import 'package:freezed_annotation/freezed_annotation.dart';

part 'library_entry.freezed.dart';
part 'library_entry.g.dart';

/// A folder in the optimization queue with optional per-library overrides.
@freezed
abstract class LibraryEntry with _$LibraryEntry {
  const factory LibraryEntry({
    required String path,
    String? preset,
    String? outputDirectory,
    bool? safeRunOverride,
  }) = _LibraryEntry;

  factory LibraryEntry.fromJson(Map<String, dynamic> json) =>
      _$LibraryEntryFromJson(json);
}
