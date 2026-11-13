import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'package:comic_optimizer/core/utils.dart';
import 'package:comic_optimizer/domain/enums/run_log_level.dart';
import 'package:comic_optimizer/domain/models/folder_run_result.dart';
import 'package:comic_optimizer/features/home/providers/optimization_provider.dart';
import 'package:comic_optimizer/features/home/run_report_exporter.dart';
import 'package:comic_optimizer/presentation/design_system/app_theme.dart';
import 'package:comic_optimizer/presentation/design_system/catppuccin.dart';
import 'package:comic_optimizer/presentation/widgets/logs_panel.dart';

/// Post-run results: totals, savings, failures with retry, and export.
class ResultsView extends ConsumerWidget {
  const ResultsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(optimizationProvider);
    final notifier = ref.read(optimizationProvider.notifier);
    final results = state.results.values.toList();
    final failed = results.where((r) => !r.success).toList();
    final succeeded = results.length - failed.length;
    final successes = results.where((r) => r.success).toList();
    final before = _sum(successes.map((r) => r.beforeBytes));
    final after = _sum(successes.map((r) => r.afterBytes));
    final saved = before != null && after != null ? before - after : null;
    final percent = before != null && before > 0 && saved != null
        ? saved / before * 100
        : null;
    final savedLabel = saved == null
        ? ''
        : saved >= 0
        ? ' · ${formatBytes(saved)} saved'
        : ' · ${formatBytes(-saved)} larger';
    final duration = state.startedAt != null && state.finishedAt != null
        ? state.finishedAt!.difference(state.startedAt!)
        : Duration.zero;
    final libraries = state.libraries.isNotEmpty
        ? state.libraries
        : results
              .map((r) => r.root)
              .where((r) => r.isNotEmpty)
              .toSet()
              .toList();
    final errors = state.logs.values
        .expand((lines) => lines)
        .where((entry) => entry.level == RunLogLevel.error)
        .length;
    final warnings = state.logs.values
        .expand((lines) => lines)
        .where((entry) => entry.level == RunLogLevel.warning)
        .length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Catppuccin.mantle,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: Catppuccin.surface0),
            ),
            child: Row(
              children: [
                Icon(
                  failed.isEmpty
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  color: failed.isEmpty ? Catppuccin.green : Catppuccin.yellow,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        failed.isEmpty
                            ? 'Run complete'
                            : 'Run finished with errors',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${libraries.length} ${libraries.length == 1 ? 'library' : 'libraries'}'
                        ' · ${formatDuration(duration)}$savedLabel',
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
                const SizedBox(width: 12),
                Tooltip(
                  message: 'Export report (Ctrl+E)',
                  child: OutlinedButton.icon(
                    onPressed: () => exportRunReport(context, state),
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: const Text('Export report'),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: notifier.reset,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('New run'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _StatCard(
                label: 'Comics',
                value: '$succeeded/${results.length}',
                detail: failed.isEmpty
                    ? 'all succeeded'
                    : '${failed.length} failed',
                tone: failed.isEmpty ? Catppuccin.green : Catppuccin.yellow,
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: 'Images',
                value: '${state.imagesDone}',
                detail: 'processed',
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: 'Space saved',
                value: formatBytes(saved),
                detail: percent == null
                    ? (succeeded == 0 ? 'no successful comics' : 'unknown')
                    : percent >= 0
                    ? '${percent.toStringAsFixed(1)}% smaller'
                    : '${(-percent).toStringAsFixed(1)}% larger',
                tone: Catppuccin.green,
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: 'Duration',
                value: formatDuration(duration),
                detail: 'elapsed',
              ),
            ],
          ),
          if (failed.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _FailureCard(failures: failed, onRetry: () => _retry(context, ref)),
          ],
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'By library',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (libraries.isEmpty)
            const Text(
              'No completed folders to report.',
              style: TextStyle(fontSize: 12, color: Catppuccin.overlay1),
            )
          else
            for (final library in libraries) ...[
              _LibraryCard(
                library: library,
                results: results.where((r) => r.root == library).toList(),
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: Catppuccin.mantle,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: Catppuccin.surface0),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text(
                'Diagnostics · $errors errors · $warnings warnings',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Catppuccin.subtext0,
                ),
              ),
              children: [
                SizedBox(
                  height: 220,
                  child: LogsPanel(
                    logsByFolder: state.logs,
                    selectedFolder: state.currentLogFolder,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static int? _sum(Iterable<int?> values) {
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

  Future<void> _retry(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Retry failed comics?'),
        content: const Text(
          'The affected libraries are scanned again. Comics that already '
          'succeeded are skipped when their source folders were removed; with '
          'Keep originals on, their originals are processed again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(optimizationProvider.notifier).retryFailed();
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String detail;
  final Color? tone;

  const _StatCard({
    required this.label,
    required this.value,
    required this.detail,
    this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Catppuccin.mantle,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Catppuccin.surface0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                color: Catppuccin.overlay2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: tone ?? Catppuccin.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Catppuccin.overlay1),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailureCard extends StatelessWidget {
  final List<FolderRunResult> failures;
  final VoidCallback onRetry;

  const _FailureCard({required this.failures, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Catppuccin.redContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Catppuccin.red.withAlpha(110)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Catppuccin.red,
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${failures.length} ${failures.length == 1 ? 'comic' : 'comics'} failed',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: const Text('Retry failed'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final failure in failures) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: Catppuccin.red,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.basename(failure.path),
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (failure.error != null)
                        Text(
                          failure.error!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Catppuccin.subtext0,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _LibraryCard extends StatelessWidget {
  final String library;
  final List<FolderRunResult> results;

  const _LibraryCard({required this.library, required this.results});

  @override
  Widget build(BuildContext context) {
    final failed = results.where((r) => !r.success).length;
    final successes = results.where((r) => r.success).toList();
    final before = ResultsView._sum(successes.map((r) => r.beforeBytes));
    final after = ResultsView._sum(successes.map((r) => r.afterBytes));
    final saved = before != null && after != null ? before - after : null;
    final percent = before != null && before > 0 && saved != null
        ? saved / before * 100
        : null;

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
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.folder_outlined,
                  size: 17,
                  color: Catppuccin.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    library.isEmpty ? 'Unknown library' : p.basename(library),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${results.length - failed}/${results.length} comics',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Catppuccin.overlay1,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${formatBytes(before)} → ${formatBytes(after)}'
                  '${percent == null ? '' : ' · ${percent.toStringAsFixed(0)}%'}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Catppuccin.overlay2,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final result in results)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              child: Row(
                children: [
                  Icon(
                    result.success
                        ? Icons.check_circle_rounded
                        : Icons.close_rounded,
                    size: 13,
                    color: result.success ? Catppuccin.green : Catppuccin.red,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      p.basename(result.path),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Text(
                    '${formatBytes(result.beforeBytes)} → '
                    '${formatBytes(result.afterBytes)}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Catppuccin.overlay2,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
