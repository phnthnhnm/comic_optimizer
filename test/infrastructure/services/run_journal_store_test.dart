import 'package:comic_optimizer/infrastructure/services/run_journal_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('RunJournalStore', () {
    late SharedPreferences prefs;
    late RunJournalStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      store = RunJournalStore(prefs);
    });

    test('round-trips completed folders and fingerprint', () async {
      await store.write(
        RunJournal(
          fingerprint: 'abc123',
          completed: {'/comics/A', '/comics/B'},
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      );

      final loaded = store.read();
      expect(loaded, isNotNull);
      expect(loaded!.fingerprint, 'abc123');
      expect(loaded.completed, {'/comics/A', '/comics/B'});
    });

    test('clear removes the journal', () async {
      await store.write(
        RunJournal(
          fingerprint: 'x',
          completed: {'/a'},
          updatedAt: DateTime.now(),
        ),
      );
      await store.clear();
      expect(store.read(), isNull);
    });

    test('ignores malformed data', () async {
      await prefs.setString('runJournal_v1', 'not-json');
      expect(store.read(), isNull);
    });
  });
}
