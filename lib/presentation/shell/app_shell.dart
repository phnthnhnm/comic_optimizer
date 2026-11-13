import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nativeapi/nativeapi.dart' as nativeapi;
import 'package:package_info_plus/package_info_plus.dart';

import 'package:comic_optimizer/domain/models/optimization_state.dart';
import 'package:comic_optimizer/features/home/providers/optimization_provider.dart';
import 'package:comic_optimizer/features/home/run_launcher.dart';
import 'package:comic_optimizer/features/home/run_report_exporter.dart';

import '../design_system/app_theme.dart';
import '../design_system/catppuccin.dart';

/// Persistent application frame: brand and navigation on the left, content on
/// the right.
class AppShell extends ConsumerStatefulWidget {
  final String location;
  final Widget child;

  const AppShell({super.key, required this.location, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  Timer? _clearProgress;
  double? _lastProgress;
  bool _notificationsReady = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleShortcut);
    try {
      final notifications = nativeapi.NotificationManager.instance;
      if (notifications.isSupported()) {
        _notificationsReady = notifications.initialize();
      }
    } catch (_) {
      // Native notifications are optional.
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleShortcut);
    _clearProgress?.cancel();
    super.dispose();
  }

  bool _handleShortcut(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final keyboard = HardwareKeyboard.instance;
    if (!keyboard.isControlPressed) return false;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.digit1) {
      context.go('/');
      return true;
    }
    if (key == LogicalKeyboardKey.digit2) {
      context.go('/history');
      return true;
    }
    if (key == LogicalKeyboardKey.comma) {
      context.go('/settings');
      return true;
    }
    if (key == LogicalKeyboardKey.keyO) {
      unawaited(_addFolder());
      return true;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      unawaited(_startRun());
      return true;
    }
    if (key == LogicalKeyboardKey.keyP) {
      _togglePause();
      return true;
    }
    if (key == LogicalKeyboardKey.keyE) {
      unawaited(_exportReport());
      return true;
    }
    return false;
  }

  void _syncTaskbar(OptimizationState state) {
    _clearProgress?.cancel();
    final progress = state.imagesTotal > 0
        ? (state.imagesDone / state.imagesTotal).clamp(0.0, 1.0)
        : state.rootsTotal > 0
        ? (state.rootsDone / state.rootsTotal).clamp(0.0, 1.0)
        : null;

    if (state.running) {
      _lastProgress = progress;
      if (progress != null) _setProgress(progress);
      return;
    }

    if (state.finishedAt != null) {
      _setProgress(1.0);
      _lastProgress = null;
      _notifyCompletion(state);
      _clearProgress = Timer(
        const Duration(seconds: 6),
        () => _setProgress(-1),
      );
      return;
    }

    if (_lastProgress != null) {
      _lastProgress = null;
      _setProgress(-1);
    }
  }

  void _notifyCompletion(OptimizationState state) {
    if (!_notificationsReady) return;
    final results = state.results.values;
    if (results.isEmpty) return;
    final failed = results.where((result) => !result.success).length;
    final title = failed == 0
        ? 'Comic Optimizer finished'
        : 'Comic Optimizer finished with errors';
    final message =
        '${results.length - failed}/${results.length} comics · '
        '${state.imagesDone} images processed';
    try {
      nativeapi.NotificationManager.instance.show(
        title,
        message,
        'run-complete',
        'Open',
      );
    } catch (_) {
      // Notifications are best-effort.
    }
  }

  void _setProgress(double value) {
    try {
      nativeapi.Application.instance.setProgressBar(value);
    } catch (_) {
      // Taskbar progress is best-effort and must never break the UI.
    }
  }

  Future<void> _goToLibrary() async {
    if (widget.location == '/') return;
    context.go('/');
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _addFolder() async {
    if (ref.read(optimizationProvider).running) return;
    await _goToLibrary();
    if (!mounted) return;
    await addLibraryFolder(context, ref);
  }

  Future<void> _startRun() async {
    if (ref.read(optimizationProvider).running) return;
    await _goToLibrary();
    if (!mounted) return;
    await startRunWithPreflight(context, ref);
  }

  void _togglePause() {
    final state = ref.read(optimizationProvider);
    if (!state.running) return;
    final notifier = ref.read(optimizationProvider.notifier);
    if (state.paused) {
      notifier.resume();
    } else {
      notifier.pause();
    }
  }

  Future<void> _exportReport() async {
    final state = ref.read(optimizationProvider);
    if (state.finishedAt == null) return;
    await exportRunReport(context, state);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(optimizationProvider, (_, next) => _syncTaskbar(next));

    return Focus(
      autofocus: true,
      child: Scaffold(
        backgroundColor: Catppuccin.base,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Sidebar(location: widget.location),
            Expanded(child: widget.child),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final String location;

  const _Sidebar({required this.location});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Catppuccin.mantle,
      child: Container(
        width: 232,
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: Catppuccin.surface0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Brand(),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 6),
              child: Text(
                'WORKSPACE',
                style: TextStyle(
                  color: Catppuccin.overlay1,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _NavItem(
              label: 'Library',
              icon: Icons.grid_view_rounded,
              shortcut: 'Ctrl+1',
              selected: location == '/',
              onTap: () => context.go('/'),
            ),
            _NavItem(
              label: 'History',
              icon: Icons.history_rounded,
              shortcut: 'Ctrl+2',
              selected: location.startsWith('/history'),
              onTap: () => context.go('/history'),
            ),
            _NavItem(
              label: 'Settings',
              icon: Icons.tune_rounded,
              shortcut: 'Ctrl+,',
              selected: location.startsWith('/settings'),
              onTap: () => context.go('/settings'),
            ),
            const Spacer(),
            const _SidebarFooter(),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Catppuccin.green,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.photo_library_rounded,
              size: 18,
              color: Catppuccin.base,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Comic Optimizer',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Catppuccin.text,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? shortcut;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    this.shortcut,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Catppuccin.green : Catppuccin.subtext0;
    return Tooltip(
      message: shortcut == null ? label : '$label ($shortcut)',
      waitDuration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            hoverColor: Catppuccin.surface0.withAlpha(140),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? Catppuccin.surface0 : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: foreground),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? Catppuccin.text : Catppuccin.subtext0,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final version = snapshot.data?.version;
          return Text(
            version == null ? '' : 'Version $version',
            style: const TextStyle(color: Catppuccin.overlay0, fontSize: 11),
          );
        },
      ),
    );
  }
}
