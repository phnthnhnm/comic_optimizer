import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:comic_optimizer/core/providers/service_providers.dart';
import 'package:comic_optimizer/domain/models/run_history_entry.dart';

final runHistoryProvider =
    AsyncNotifierProvider<RunHistoryNotifier, List<RunHistoryEntry>>(
      RunHistoryNotifier.new,
    );

class RunHistoryNotifier extends AsyncNotifier<List<RunHistoryEntry>> {
  @override
  Future<List<RunHistoryEntry>> build() =>
      ref.watch(runHistoryServiceProvider).load();

  Future<void> append(RunHistoryEntry entry) async {
    final service = ref.read(runHistoryServiceProvider);
    await service.append(entry);
    state = AsyncData(await service.load());
  }

  Future<void> clear() async {
    await ref.read(runHistoryServiceProvider).clear();
    state = const AsyncData([]);
  }
}
