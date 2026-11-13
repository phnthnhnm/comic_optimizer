import '../enums/run_log_level.dart';

/// One structured line in the run diagnostics.
final class RunLogEntry {
  final String message;
  final RunLogLevel level;
  final DateTime time;

  const RunLogEntry(this.message, this.level, this.time);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunLogEntry &&
          other.message == message &&
          other.level == level &&
          other.time == time;

  @override
  int get hashCode => Object.hash(message, level, time);
}
