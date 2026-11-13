/// Severity of a run log line, used for colours and diagnostics filters.
enum RunLogLevel { info, success, warning, error }

extension RunLogLevelX on RunLogLevel {
  /// Classifies a log message produced by the optimizer/encoder.
  ///
  /// The pipeline still emits plain strings; this is the single place that
  /// turns them into structured severities until callbacks carry levels.
  static RunLogLevel fromLine(String line) {
    final text = line.toLowerCase();
    if (text.contains('error') ||
        text.contains('failed') ||
        text.contains('err') ||
        (text.contains('cjxl exit') && !text.contains('exit 0'))) {
      return RunLogLevel.error;
    }
    if (text.contains('warning') ||
        text.contains('cancelled') ||
        text.contains('no images')) {
      return RunLogLevel.warning;
    }
    if (text.startsWith('done:') ||
        text.contains('created archive') ||
        text.contains('saved')) {
      return RunLogLevel.success;
    }
    return RunLogLevel.info;
  }
}
