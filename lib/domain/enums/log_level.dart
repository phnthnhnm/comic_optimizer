enum LogLevel { none, normal, error }

extension LogLevelX on LogLevel {
  String get toName {
    switch (this) {
      case LogLevel.none:
        return 'none';
      case LogLevel.normal:
        return 'normal';
      case LogLevel.error:
        return 'error';
    }
  }

  static LogLevel fromName(String s) {
    switch (s) {
      case 'normal':
        return LogLevel.normal;
      case 'error':
        return LogLevel.error;
      default:
        return LogLevel.none;
    }
  }
}
