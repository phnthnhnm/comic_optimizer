import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:comic_optimizer/core/providers/service_providers.dart';
import 'package:comic_optimizer/domain/enums/post_run_action.dart';
import 'package:comic_optimizer/domain/models/preflight_summary.dart';
import 'package:comic_optimizer/features/home/providers/optimization_provider.dart';
import 'package:comic_optimizer/features/home/widgets/library_panel.dart';
import 'package:comic_optimizer/features/home/widgets/preflight_sheet.dart';
import 'package:comic_optimizer/features/home/widgets/run_workspace.dart';
import 'package:comic_optimizer/features/settings/providers/settings_provider.dart';
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
      await ref.read(postRunServiceProvider).perform(action);
    } catch (e) {
      _logMessage('Failed to perform post-run action: $e');
    }
  }

  void _logMessage(String line) {
    ref.read(optimizationProvider.notifier).addLog(line);
  }

  Future<void> _start() async {
    final settings = ref.read(settingsProvider);
    final hasRoots =
        settings.libraryRoots.isNotEmpty || settings.lastRoot != null;
    PreflightSummary? summary;
    if (hasRoots) {
      summary = await showPreflightSheet(context, ref);
      if (summary == null) return;
    }

    _performedPostRun = false;
    await ref.read(optimizationProvider.notifier).start(summary: summary);
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
        title: const Text('Library'),
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
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
        child: state.running || state.logs.isNotEmpty
            ? const RunWorkspace()
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
    );
  }
}
