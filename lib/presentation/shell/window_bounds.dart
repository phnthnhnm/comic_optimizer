import 'dart:async';
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import '../design_system/catppuccin.dart';

/// Window geometry remembered between launches.
final class WindowBounds {
  final Rect rect;
  final bool maximized;

  const WindowBounds(this.rect, this.maximized);
}

/// Persists window geometry in the same preferences file as app settings.
final class WindowBoundsStore {
  static const _key = 'window_bounds_v1';

  final SharedPreferences prefs;

  const WindowBoundsStore(this.prefs);

  WindowBounds? read() {
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final rect = Rect.fromLTWH(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
        (json['width'] as num).toDouble(),
        (json['height'] as num).toDouble(),
      );
      if (rect.width < 960 || rect.height < 640) return null;
      return WindowBounds(rect, json['maximized'] == true);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(Rect rect, bool maximized) {
    return prefs.setString(
      _key,
      jsonEncode({
        'x': rect.left,
        'y': rect.top,
        'width': rect.width,
        'height': rect.height,
        'maximized': maximized,
      }),
    );
  }
}

/// Configures the native window and restores its last geometry.
///
/// The window is created by the Windows runner before Flutter starts, so this
/// runs before `runApp`; the runner shows it on the first frame.
Future<void> configureWindow(SharedPreferences prefs) async {
  final window = WindowManager.instance.getCurrent();
  if (window == null) return;

  final store = WindowBoundsStore(prefs);
  final saved = store.read();

  window.title = 'Comic Optimizer';
  window.minimumSize = const Size(960, 640).toNative();
  window.backgroundColor = Catppuccin.base.toNative();

  if (saved != null) {
    final rect = _fitToScreen(saved.rect);
    if (rect != null) {
      window.bounds = rect.toNative();
    } else {
      _applyDefaultGeometry(window);
    }
  } else {
    _applyDefaultGeometry(window);
  }

  if (saved?.maximized ?? false) window.maximize();

  WindowBoundsKeeper(window: window, store: store);
  window.show();
  window.focus();
}

void _applyDefaultGeometry(Window window) {
  window.setSize(const Size(1280, 800).toNative(), false);
  window.center();
}

/// Keeps a restored window on the primary display's work area.
Rect? _fitToScreen(Rect rect) {
  final display = DisplayManager.instance.getPrimary();
  if (display == null) return rect;

  final workArea = display.workArea.toRect();
  if (workArea.width < 960 || workArea.height < 640) return null;

  final width = rect.width.clamp(960.0, workArea.width);
  final height = rect.height.clamp(640.0, workArea.height);
  final left = rect.left.clamp(workArea.left, workArea.right - width);
  final top = rect.top.clamp(workArea.top, workArea.bottom - height);
  return Rect.fromLTWH(left, top, width, height);
}

/// Debounces window move/resize events and saves the normal bounds.
final class WindowBoundsKeeper {
  final Window window;
  final WindowBoundsStore store;

  Rect? _normalBounds;
  Timer? _timer;
  late final ListenerId _listenerId;

  WindowBoundsKeeper({required this.window, required this.store}) {
    _normalBounds = window.bounds.toRect();
    _listenerId = window.addListener(_onEvent);
  }

  void _onEvent(WindowEvent event) {
    if (event is WindowCloseRequestedEvent) {
      unawaited(_save());
      return;
    }
    if (event is WindowMovedEvent ||
        event is WindowResizedEvent ||
        event is WindowMaximizedEvent ||
        event is WindowRestoredEvent) {
      _schedule();
    }
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 350), () {
      unawaited(_save());
    });
  }

  Future<void> _save() async {
    if (!window.isMaximized) {
      _normalBounds = window.bounds.toRect();
    }
    await store.write(
      _normalBounds ?? window.bounds.toRect(),
      window.isMaximized,
    );
  }

  void dispose() {
    _timer?.cancel();
    window.removeListener(_listenerId);
  }
}
