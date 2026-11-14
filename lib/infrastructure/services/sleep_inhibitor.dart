import 'dart:ffi';
import 'dart:io';

import 'package:comic_optimizer/core/interfaces/i_sleep_inhibitor.dart';

/// Windows implementation using SetThreadExecutionState.
final class WindowsSleepInhibitor implements ISleepInhibitor {
  static const _esContinuous = 0x80000000;
  static const _esSystemRequired = 0x00000001;

  int Function(int)? _setThreadExecutionState;
  bool _active = false;

  @override
  void inhibit() {
    if (!Platform.isWindows || _active) return;
    try {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      _setThreadExecutionState = kernel32
          .lookupFunction<Int32 Function(Uint32), int Function(int)>(
            'SetThreadExecutionState',
          );
      _setThreadExecutionState!(_esContinuous | _esSystemRequired);
      _active = true;
    } catch (_) {
      // Best effort: a failed call must never stop a run.
    }
  }

  @override
  void release() {
    if (!_active) return;
    try {
      _setThreadExecutionState?.call(_esContinuous);
    } catch (_) {}
    _active = false;
  }
}
