import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:comic_optimizer/core/providers/service_providers.dart';
import 'package:comic_optimizer/domain/enums/post_run_action.dart';
import 'package:comic_optimizer/domain/models/optimization_state.dart';
import 'package:comic_optimizer/domain/models/run_history_entry.dart';
import 'package:comic_optimizer/features/history/providers/run_history_provider.dart';
import 'package:comic_optimizer/features/home/providers/optimization_provider.dart';
import 'package:comic_optimizer/features/home/run_launcher.dart';
import 'package:comic_optimizer/features/home/widgets/library_panel.dart';
import 'package:comic_optimizer/features/home/widgets/results_view.dart';
import 'package:comic_optimizer/features/home/widgets/run_workspace.dart';
import 'package:comic_optimizer/features/settings/providers/settings_provider.dart';
import 'package:comic_optimizer/features/tutorial/tutorial_dialog.dart';
import 'package:comic_optimizer/presentation/widgets/logs_panel.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _performedPostRun = false;
  bool _recordedHistory = false;
  bool _tutorialAttempted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    await ref.read(settingsProvider.notifier).load();
    if (!mounted) return;
    await _maybeShowTutorial();
  }

  Future<void> _maybeShowTutorial() async {
    if (_tutorialAttempted) return;
    _tutorialAttempted = true;
    if (ref.read(settingsProvider).tutorialCompleted) return;
    await showTutorial(context, ref);
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
      await ref.read(postRunServiceProvider).perform(action);
    } catch (e) {
      _logMessage('Failed to perform post-run action: $e');
    }
  }

  void _logMessage(String line) {
    ref.read(optimizationProvider.notifier).addLog(line);
  }

  Future<void> _recordHistory(OptimizationState state) async {
    if (_recordedHistory) return;
    _recordedHistory = true;

    final finished = state.finishedAt;
    final results = state.results.values.toList();
    if (finished == null || results.isEmpty) return;

    final entry = RunHistoryEntry(
      id: '${state.startedAt?.millisecondsSinceEpoch ?? finished.millisecondsSinceEpoch}',
      startedAt: state.startedAt ?? finished,
      finishedAt: finished,
      libraries: state.libraries,
      comics: results.length,
      failed: results.where((result) => !result.success).length,
      images: state.imagesDone,
      beforeBytes: _sumBytes(
        results
            .where((result) => result.success)
            .map((result) => result.beforeBytes),
      ),
      afterBytes: _sumBytes(
        results
            .where((result) => result.success)
            .map((result) => result.afterBytes),
      ),
      failedFolders: results
          .where((result) => !result.success)
          .map((result) => result.path)
          .toList(),
    );
    await ref.read(runHistoryProvider.notifier).append(entry);
    await ref.read(lifetimeStatsStoreProvider).record(entry);
  }

  static int? _sumBytes(Iterable<int?> values) {
    var total = 0;
    var any = false;
    for (final value in values) {
      if (value != null) {
        total += value;
        any = true;
      }
    }
    return any ? total : null;
  }

  Future<void> _start() async {
    _performedPostRun = false;
    _recordedHistory = false;
    await startRunWithPreflight(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(optimizationProvider);

    // Detect when optimization completes to trigger post-run action
    ref.listen(optimizationProvider, (prev, next) {
      if (prev?.running != true && next.running) {
        _performedPostRun = false;
        _recordedHistory = false;
      }
      if (prev?.running == true && !next.running) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _recordHistory(next);
          _maybePerformPostRunAction();
        });
      }
    });

    final mode = state.running
        ? 'run'
        : state.finishedAt != null
        ? 'results'
        : 'library';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Welcome tutorial',
            onPressed: () => showTutorial(context, ref),
          ),
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
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
        child: AnimatedSwitcher(
          duration: MediaQuery.of(context).disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: KeyedSubtree(
            key: ValueKey(mode),
            child: state.running
                ? const RunWorkspace()
                : state.finishedAt != null
                ? const ResultsView()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final panel = SingleChildScrollView(
                        child: LibraryPanel(onStart: _start),
                      );
                      final logs = LogsPanel(
                        logsByFolder: state.logs,
                        selectedFolder: state.currentLogFolder,
                      );

                      if (constraints.maxWidth >= 820) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 3, child: panel),
                            const SizedBox(width: 20),
                            Expanded(flex: 2, child: logs),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          Expanded(flex: 3, child: panel),
                          const SizedBox(height: 16),
                          Expanded(flex: 2, child: logs),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
