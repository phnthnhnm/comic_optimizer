import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'package:comic_optimizer/domain/enums/folder_run_status.dart';
import 'package:comic_optimizer/domain/enums/run_log_level.dart';
import 'package:comic_optimizer/domain/models/optimization_state.dart';
import 'package:comic_optimizer/features/home/providers/optimization_provider.dart';
import 'package:comic_optimizer/presentation/design_system/app_theme.dart';
import 'package:comic_optimizer/presentation/design_system/catppuccin.dart';
import 'package:comic_optimizer/presentation/widgets/logs_panel.dart';

/// Live view of the current run: progress, folders and diagnostics.
class RunWorkspace extends ConsumerStatefulWidget {
  const RunWorkspace({super.key});

  @override
  ConsumerState<RunWorkspace> createState() => _RunWorkspaceState();
}

class _RunWorkspaceState extends ConsumerState<RunWorkspace> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(optimizationProvider);
    final notifier = ref.read(optimizationProvider.notifier);
    final entries = state.logs.values.expand((lines) => lines);
    final errorCount = entries
        .where((entry) => entry.level == RunLogLevel.error)
        .length;
    final warningCount = entries
        .where((entry) => entry.level == RunLogLevel.warning)
        .length;

    return Column(
      children: [
        _RunHeader(state: state, notifier: notifier),
        const SizedBox(height: AppSpacing.md),
        Expanded(flex: 3, child: _FolderTable(state: state)),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text(
                    'Diagnostics',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    '$errorCount errors · $warningCount warnings',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Catppuccin.overlay1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: LogsPanel(
                  logsByFolder: state.logs,
                  selectedFolder: state.currentLogFolder,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RunHeader extends StatelessWidget {
  final OptimizationState state;
  final OptimizationNotifier notifier;

  const _RunHeader({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final complete = !state.running && state.startedAt != null;
    final paused = state.paused;
    final progress = state.imagesTotal > 0
        ? (state.imagesDone / state.imagesTotal).clamp(0.0, 1.0)
        : state.rootsTotal > 0
        ? (state.rootsDone / state.rootsTotal).clamp(0.0, 1.0)
        : null;
    final elapsed = _elapsed(state);
    final remaining = _remaining(state, elapsed);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: Catppuccin.mantle,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Catppuccin.surface0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                complete
                    ? Icons.check_circle_rounded
                    : paused
                    ? Icons.pause_circle_filled_rounded
                    : Icons.sync_rounded,
                color: complete
                    ? Catppuccin.green
                    : paused
                    ? Catppuccin.yellow
                    : Catppuccin.green,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complete
                          ? 'Run complete'
                          : paused
                          ? 'Paused'
                          : 'Running',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Catppuccin.overlay1,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.running) ...[
                Tooltip(
                  message: paused ? 'Resume (Ctrl+P)' : 'Pause (Ctrl+P)',
                  child: FilledButton.tonal(
                    onPressed: paused ? notifier.resume : notifier.pause,
                    child: Text(paused ? 'Resume' : 'Pause'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: notifier.cancel,
                  child: const Text('Cancel'),
                ),
              ] else
                FilledButton.icon(
                  onPressed: notifier.reset,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('New run'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Semantics(
            label: 'Run progress',
            value: progress == null
                ? 'Preparing'
                : '${(progress * 100).round()} percent',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Catppuccin.surface0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniStat(
                label: 'Comics',
                value: _ratio(state.comicsDone, state.comicsTotal),
              ),
              const SizedBox(width: 10),
              _MiniStat(
                label: 'Images',
                value: _ratio(state.imagesDone, state.imagesTotal),
              ),
              const SizedBox(width: 10),
              _MiniStat(label: 'Elapsed', value: _format(elapsed)),
              const SizedBox(width: 10),
              _MiniStat(
                label: 'Remaining',
                value: state.running
                    ? (remaining == null ? '—' : _format(remaining))
                    : '—',
              ),
            ],
          ),
          if (state.running && state.currentFolder != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.photo_outlined,
                  size: 15,
                  color: Catppuccin.teal,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    '${p.basename(state.currentFolder!)}'
                    '${state.currentFile == null ? '' : ' · ${state.currentFile}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Catppuccin.subtext0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _subtitle() {
    if (state.rootsTotal == 0) return 'Preparing…';
    final root =
        state.currentRoot ??
        (state.logs.isEmpty ? null : state.logs.keys.first);
    final rootName = root == null ? 'Library queue' : p.basename(root);
    final count = state.rootsTotal;
    return '$rootName · $count ${count == 1 ? 'library' : 'libraries'}';
  }

  static String _ratio(int done, int total) =>
      total > 0 ? '$done/$total' : '$done';

  Duration _elapsed(OptimizationState state) {
    final start = state.startedAt;
    if (start == null) return Duration.zero;
    final end = state.finishedAt ?? DateTime.now();
    final value = end.difference(start);
    return value.isNegative ? Duration.zero : value;
  }

  Duration? _remaining(OptimizationState state, Duration elapsed) {
    if (!state.running ||
        state.imagesTotal == 0 ||
        state.imagesDone == 0 ||
        elapsed.inSeconds < 1) {
      return null;
    }
    final secondsPerImage = elapsed.inMilliseconds / state.imagesDone;
    final left = state.imagesTotal - state.imagesDone;
    if (left <= 0) return Duration.zero;
    return Duration(milliseconds: (secondsPerImage * left).round());
  }

  static String _format(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
        decoration: BoxDecoration(
          color: Catppuccin.base,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: Catppuccin.surface1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Catppuccin.overlay2,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Catppuccin.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderTable extends StatelessWidget {
  final OptimizationState state;

  const _FolderTable({required this.state});

  @override
  Widget build(BuildContext context) {
    final entries = state.folders.entries.toList();
    return Container(
      decoration: BoxDecoration(
        color: Catppuccin.mantle,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Catppuccin.surface0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Text(
                  'Folders',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  entries.isEmpty ? 'Waiting' : '${entries.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Catppuccin.overlay1,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: entries.isEmpty
                ? const Center(
                    child: Text(
                      'Waiting for the first comic…',
                      style: TextStyle(
                        fontSize: 12,
                        color: Catppuccin.overlay1,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return _FolderRow(path: entry.key, status: entry.value);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FolderRow extends StatelessWidget {
  final String path;
  final FolderRunStatus status;

  const _FolderRow({required this.path, required this.status});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            status == FolderRunStatus.running
                ? Icons.autorenew_rounded
                : Icons.folder_outlined,
            size: 16,
            color: status == FolderRunStatus.running
                ? Catppuccin.teal
                : Catppuccin.overlay1,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              p.basename(path),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
          _StatusChip(status: status),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final FolderRunStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      FolderRunStatus.pending => (
        'Queued',
        Catppuccin.overlay2,
        Icons.schedule_rounded,
      ),
      FolderRunStatus.running => (
        'Running',
        Catppuccin.teal,
        Icons.autorenew_rounded,
      ),
      FolderRunStatus.success => (
        'Done',
        Catppuccin.green,
        Icons.check_rounded,
      ),
      FolderRunStatus.failed => ('Failed', Catppuccin.red, Icons.close_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
