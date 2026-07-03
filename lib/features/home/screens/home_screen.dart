import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:comic_optimizer/domain/enums/post_run_action.dart';
import 'package:comic_optimizer/features/home/providers/optimization_provider.dart';
import 'package:comic_optimizer/features/settings/providers/settings_provider.dart';
import 'package:comic_optimizer/presentation/widgets/controls.dart';
import 'package:comic_optimizer/presentation/widgets/logs_panel.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _performedPostRun = false;

  @override
  void initState() {
    super.initState();
    // Load settings on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsProvider.notifier).load();
    });
  }

  Future<void> _maybePerformPostRunAction() async {
    if (_performedPostRun) return;
    _performedPostRun = true;

    final settings = ref.read(settingsProvider);
    final action = settings.postRunAction;
    if (action == PostRunAction.none) return;

    final confirmEnabled = settings.postRunConfirmEnabled;
    final seconds = settings.postRunConfirmSeconds;
    var ok = true;
    if (confirmEnabled) {
      ok = await _confirmDialog(action, seconds);
    }
    if (!ok) {
      _logMessage('Post-run action cancelled by user.');
      return;
    }
    await _performPostRunAction(action);
  }

  Future<bool> _confirmDialog(PostRunAction action, int seconds) async {
    var remaining = seconds;
    Timer? timer;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) {
        return StatefulBuilder(
          builder: (c2, setState2) {
            timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
              remaining -= 1;
              if (remaining <= 0) {
                timer?.cancel();
                Navigator.of(c2).pop(true);
              } else {
                setState2(() {});
              }
            });
            return AlertDialog(
              title: const Text('Post-run action'),
              content: Text(
                'The system will perform "$action" in $remaining seconds. Cancel to abort.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    timer?.cancel();
                    Navigator.of(c2).pop(false);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    timer?.cancel();
                    Navigator.of(c2).pop(true);
                  },
                  child: const Text('Proceed Now'),
                ),
              ],
            );
          },
        );
      },
    );
    timer?.cancel();
    return result == true;
  }

  Future<void> _performPostRunAction(PostRunAction action) async {
    _logMessage('Performing post-run action: $action');
    try {
      switch (action) {
        case PostRunAction.quit:
          _logMessage('Quitting app...');
          await Future.delayed(const Duration(milliseconds: 200));
          if (mounted) exit(0);
        case PostRunAction.shutdown:
          _logMessage('Shutting down...');
          await Process.run('shutdown', ['/s', '/t', '0']);
        case PostRunAction.restart:
          _logMessage('Restarting...');
          await Process.run('shutdown', ['/r', '/t', '0']);
        case PostRunAction.hibernate:
          _logMessage('Hibernating...');
          await Process.run('shutdown', ['/h']);
        case PostRunAction.sleep:
          _logMessage('Sleeping...');
          await Process.run('rundll32.exe', [
            'powrprof.dll,SetSuspendState',
            '0,1,0',
          ]);
        case PostRunAction.none:
          break;
      }
    } catch (e) {
      _logMessage('Failed to perform post-run action: $e');
    }
  }

  void _logMessage(String line) {
    ref.read(optimizationProvider.notifier).addLog(line);
  }

  void _start() {
    ref.read(optimizationProvider.notifier).start(context);
    _performedPostRun = false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(optimizationProvider);

    // Detect when optimization completes to trigger post-run action
    ref.listen(optimizationProvider, (prev, next) {
      if (prev?.running == true && !next.running) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _maybePerformPostRunAction();
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comic Optimizer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Report a Bug',
            onPressed: () async {
              final url = Uri.parse(
                'https://github.com/phnthnhnm/comic_optimizer/issues/new',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              context.push('/settings');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            ControlPanel(
              onStart: _start,
              onCancel: () => ref.read(optimizationProvider.notifier).cancel(),
              onPause: () => ref.read(optimizationProvider.notifier).pause(),
              onResume: () => ref.read(optimizationProvider.notifier).resume(),
            ),
            const SizedBox(height: 12),
            const Divider(),
            LogsPanel(
              logsByFolder: state.logs,
              selectedFolder: state.currentLogFolder,
            ),
          ],
        ),
      ),
    );
  }
}
