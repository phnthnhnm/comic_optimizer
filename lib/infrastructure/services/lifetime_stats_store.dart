import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:comic_optimizer/domain/models/run_history_entry.dart';

final class LifetimeStats {
  final int runs;
  final int comics;
  final int images;
  final int savedBytes;

  const LifetimeStats({
    this.runs = 0,
    this.comics = 0,
    this.images = 0,
    this.savedBytes = 0,
  });

  Map<String, dynamic> toJson() => {
    'runs': runs,
    'comics': comics,
    'images': images,
    'savedBytes': savedBytes,
  };

  static LifetimeStats? fromJson(Object? raw) {
    if (raw is! Map) return null;
    try {
      final map = raw.cast<String, dynamic>();
      return LifetimeStats(
        runs: (map['runs'] as num?)?.toInt() ?? 0,
        comics: (map['comics'] as num?)?.toInt() ?? 0,
        images: (map['images'] as num?)?.toInt() ?? 0,
        savedBytes: (map['savedBytes'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}

final class LifetimeStatsStore {
  static const _key = 'lifetimeStats_v1';

  final SharedPreferences prefs;

  const LifetimeStatsStore(this.prefs);

  LifetimeStats read() {
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const LifetimeStats();
    try {
      return LifetimeStats.fromJson(jsonDecode(raw)) ?? const LifetimeStats();
    } catch (_) {
      return const LifetimeStats();
    }
  }

  Future<void> record(RunHistoryEntry entry) async {
    final current = read();
    final next = LifetimeStats(
      runs: current.runs + 1,
      comics: current.comics + entry.comics,
      images: current.images + entry.images,
      savedBytes: current.savedBytes + (entry.savedBytes ?? 0),
    );
    await prefs.setString(_key, jsonEncode(next.toJson()));
  }
}
