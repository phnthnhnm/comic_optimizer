import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:comic_optimizer/core/interfaces/i_run_history_service.dart';
import 'package:comic_optimizer/domain/models/run_history_entry.dart';

final class RunHistoryServiceImpl implements IRunHistoryService {
  static const _key = 'runHistory_v1';
  static const _maxEntries = 50;

  final SharedPreferences _prefs;

  const RunHistoryServiceImpl(this._prefs);

  @override
  Future<List<RunHistoryEntry>> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => RunHistoryEntry.fromJson(item.cast<String, Object?>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> append(RunHistoryEntry entry) async {
    final entries = [...await load(), entry];
    entries.sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
    final trimmed = entries.take(_maxEntries).toList();
    await _prefs.setString(
      _key,
      jsonEncode(trimmed.map((item) => item.toJson()).toList()),
    );
  }

  @override
  Future<void> clear() => _prefs.remove(_key);
}
