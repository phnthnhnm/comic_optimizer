import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A crash-safe record of comics completed in the current queue.
final class RunJournal {
  static const version = 1;

  final String fingerprint;
  final Set<String> completed;
  final DateTime updatedAt;

  const RunJournal({
    required this.fingerprint,
    required this.completed,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'fingerprint': fingerprint,
    'completed': completed.toList()..sort(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static RunJournal? fromJson(Object? raw) {
    if (raw is! Map) return null;
    try {
      final map = raw.cast<String, dynamic>();
      if (map['version'] != version) return null;
      final fingerprint = map['fingerprint'] as String?;
      if (fingerprint == null) return null;
      final completed = (map['completed'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toSet();
      final updatedAt = DateTime.tryParse(map['updatedAt'] as String? ?? '');
      return RunJournal(
        fingerprint: fingerprint,
        completed: completed,
        updatedAt: updatedAt ?? DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}

final class RunJournalStore {
  static const _key = 'runJournal_v1';

  final SharedPreferences prefs;

  const RunJournalStore(this.prefs);

  RunJournal? read() {
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return RunJournal.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> write(RunJournal journal) =>
      prefs.setString(_key, jsonEncode(journal.toJson()));

  Future<void> clear() => prefs.remove(_key);
}
