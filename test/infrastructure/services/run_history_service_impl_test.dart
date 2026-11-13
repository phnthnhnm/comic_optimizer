import 'package:comic_optimizer/domain/models/run_history_entry.dart';
import 'package:comic_optimizer/infrastructure/services/run_history_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('RunHistoryServiceImpl', () {
    late SharedPreferences prefs;
    late RunHistoryServiceImpl service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = RunHistoryServiceImpl(prefs);
    });

    RunHistoryEntry entry(int minute) {
      return RunHistoryEntry(
        id: 'run-$minute',
        startedAt: DateTime(2026, 1, 1, 10, minute),
        finishedAt: DateTime(2026, 1, 1, 10, minute + 1),
        libraries: const [r'C:\Comics'],
        comics: 2,
        failed: 0,
        images: 10,
        beforeBytes: 100,
        afterBytes: 40,
        failedFolders: const [],
      );
    }

    test('starts empty', () async {
      expect(await service.load(), isEmpty);
    });

    test('appends newest first', () async {
      await service.append(entry(1));
      await service.append(entry(3));
      await service.append(entry(2));

      final loaded = await service.load();
      expect(loaded.map((item) => item.id), ['run-3', 'run-2', 'run-1']);
    });

    test('keeps at most 50 entries', () async {
      for (var i = 0; i < 55; i++) {
        await service.append(entry(i));
      }

      final loaded = await service.load();
      expect(loaded, hasLength(50));
      expect(loaded.first.id, 'run-54');
      expect(loaded.last.id, 'run-5');
    });

    test('clear removes everything', () async {
      await service.append(entry(1));
      await service.clear();
      expect(await service.load(), isEmpty);
      expect(prefs.getString('runHistory_v1'), isNull);
    });

    test('malformed storage loads as empty', () async {
      await prefs.setString('runHistory_v1', 'not json');
      expect(await service.load(), isEmpty);
    });
  });
}
