import 'package:comic_optimizer/domain/models/run_history_entry.dart';
import 'package:comic_optimizer/infrastructure/services/lifetime_stats_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LifetimeStatsStore', () {
    late SharedPreferences prefs;
    late LifetimeStatsStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      store = LifetimeStatsStore(prefs);
    });

    test('starts empty and accumulates runs', () async {
      expect(store.read().runs, 0);

      await store.record(_entry(images: 10, before: 1000, after: 400));
      await store.record(_entry(images: 5, before: 600, after: 500));

      final stats = store.read();
      expect(stats.runs, 2);
      expect(stats.images, 15);
      expect(stats.savedBytes, 700);
    });

    test('ignores unknown values safely', () async {
      await prefs.setString('lifetimeStats_v1', 'not-json');
      expect(store.read().runs, 0);
    });
  });
}

RunHistoryEntry _entry({
  required int images,
  required int before,
  required int after,
}) {
  final now = DateTime(2026, 1, 1);
  return RunHistoryEntry(
    id: now.microsecondsSinceEpoch.toString(),
    startedAt: now,
    finishedAt: now.add(const Duration(seconds: 1)),
    libraries: const ['/library'],
    comics: 1,
    failed: 0,
    images: images,
    beforeBytes: before,
    afterBytes: after,
    failedFolders: const [],
  );
}
