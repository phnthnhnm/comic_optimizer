import '../../domain/models/run_history_entry.dart';

/// Persistence for completed-run summaries.
abstract interface class IRunHistoryService {
  Future<List<RunHistoryEntry>> load();
  Future<void> append(RunHistoryEntry entry);
  Future<void> clear();
}
