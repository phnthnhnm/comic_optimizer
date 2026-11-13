import 'package:comic_optimizer/domain/models/run_history_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RunHistoryEntry', () {
    final started = DateTime(2026, 5, 1, 10, 30);
    final finished = DateTime(2026, 5, 1, 10, 33, 12);

    RunHistoryEntry entry({
      int comics = 4,
      int failed = 1,
      int? before = 1000,
      int? after = 400,
    }) {
      return RunHistoryEntry(
        id: 'run-1',
        startedAt: started,
        finishedAt: finished,
        libraries: const [r'C:\Comics'],
        comics: comics,
        failed: failed,
        images: 42,
        beforeBytes: before,
        afterBytes: after,
        failedFolders: const [r'C:\Comics\Bad'],
      );
    }

    test('derives duration, successes and savings', () {
      final value = entry();
      expect(value.duration, const Duration(minutes: 3, seconds: 12));
      expect(value.succeeded, 3);
      expect(value.savedBytes, 600);
    });

    test('savings are unknown without both sizes', () {
      expect(entry(before: null).savedBytes, isNull);
      expect(entry(after: null).savedBytes, isNull);
    });

    test('round-trips through JSON', () {
      final original = entry();
      final restored = RunHistoryEntry.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.startedAt, original.startedAt);
      expect(restored.finishedAt, original.finishedAt);
      expect(restored.libraries, original.libraries);
      expect(restored.comics, original.comics);
      expect(restored.failed, original.failed);
      expect(restored.images, original.images);
      expect(restored.beforeBytes, original.beforeBytes);
      expect(restored.afterBytes, original.afterBytes);
      expect(restored.failedFolders, original.failedFolders);
    });

    test('tolerates missing or malformed JSON fields', () {
      final restored = RunHistoryEntry.fromJson({
        'id': 7,
        'startedAt': 'not-a-date',
        'libraries': 'nope',
        'comics': '3',
        'beforeBytes': '1000',
      });

      expect(restored.id, '7');
      expect(restored.startedAt.millisecondsSinceEpoch, 0);
      expect(restored.libraries, isEmpty);
      expect(restored.comics, 3);
      expect(restored.beforeBytes, 1000);
      expect(restored.afterBytes, isNull);
    });
  });
}
