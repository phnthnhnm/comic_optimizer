enum PostRunAction { none, quit, sleep, hibernate, shutdown, restart }

extension PostRunActionX on PostRunAction {
  String get toName {
    switch (this) {
      case PostRunAction.quit:
        return 'quit';
      case PostRunAction.sleep:
        return 'sleep';
      case PostRunAction.hibernate:
        return 'hibernate';
      case PostRunAction.shutdown:
        return 'shutdown';
      case PostRunAction.restart:
        return 'restart';
      case PostRunAction.none:
        return 'none';
    }
  }

  static PostRunAction fromName(String s) {
    switch (s) {
      case 'quit':
        return PostRunAction.quit;
      case 'sleep':
        return PostRunAction.sleep;
      case 'hibernate':
        return PostRunAction.hibernate;
      case 'shutdown':
        return PostRunAction.shutdown;
      case 'restart':
        return PostRunAction.restart;
      default:
        return PostRunAction.none;
    }
  }
}
