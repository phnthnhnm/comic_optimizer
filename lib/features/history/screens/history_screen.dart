import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'package:comic_optimizer/core/utils.dart';
import 'package:comic_optimizer/domain/models/run_history_entry.dart';
import 'package:comic_optimizer/features/history/providers/run_history_provider.dart';
import 'package:comic_optimizer/presentation/design_system/app_theme.dart';
import 'package:comic_optimizer/presentation/design_system/catppuccin.dart';

enum _HistoryFilter { all, success, failed }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _search = TextEditingController();
  _HistoryFilter _filter = _HistoryFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(runHistoryProvider);
    final entries = switch (history) {
      AsyncData(:final value) => value,
      _ => const <RunHistoryEntry>[],
    };
    final visible = _filtered(entries);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (entries.isNotEmpty)
            IconButton(
              tooltip: 'Clear history',
              onPressed: () => _clear(context, ref),
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent runs',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'The last 50 completed runs, newest first.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Catppuccin.overlay1,
                        ),
                      ),
                    ],
                  ),
                ),
                if (entries.isNotEmpty) _LifetimeSummary(entries: entries),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (entries.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      decoration: const InputDecoration(
                        hintText: 'Search by library or date',
                        prefixIcon: Icon(Icons.search_rounded, size: 18),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SegmentedButton<_HistoryFilter>(
                    segments: const [
                      ButtonSegment(
                        value: _HistoryFilter.all,
                        label: Text('All'),
                      ),
                      ButtonSegment(
                        value: _HistoryFilter.success,
                        label: Text('Succeeded'),
                      ),
                      ButtonSegment(
                        value: _HistoryFilter.failed,
                        label: Text('With failures'),
                      ),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (value) =>
                        setState(() => _filter = value.first),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Expanded(
              child: switch (history) {
                AsyncLoading() => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                AsyncError(:final error) => Center(
                  child: Text(
                    'Could not load history: $error',
                    style: const TextStyle(color: Catppuccin.red),
                  ),
                ),
                _ when entries.isEmpty => const _EmptyHistory(),
                _ when visible.isEmpty => const Center(
                  child: Text(
                    'No runs match this filter.',
                    style: TextStyle(color: Catppuccin.overlay1),
                  ),
                ),
                _ => ListView.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _HistoryCard(entry: visible[index]),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }

  List<RunHistoryEntry> _filtered(List<RunHistoryEntry> entries) {
    final query = _search.text.trim().toLowerCase();
    return entries.where((entry) {
      final matchesFilter = switch (_filter) {
        _HistoryFilter.all => true,
        _HistoryFilter.success => entry.failed == 0,
        _HistoryFilter.failed => entry.failed > 0,
      };
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      final haystack = [
        _formatDate(entry.finishedAt),
        ...entry.libraries.map((library) => p.basename(library)),
        ...entry.failedFolders.map((folder) => p.basename(folder)),
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear run history?'),
        content: const Text('This removes every saved run summary.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(runHistoryProvider.notifier).clear();
    }
  }
}

class _LifetimeSummary extends StatelessWidget {
  final List<RunHistoryEntry> entries;

  const _LifetimeSummary({required this.entries});

  @override
  Widget build(BuildContext context) {
    final saved = entries.fold<int>(
      0,
      (sum, entry) => sum + (entry.savedBytes ?? 0),
    );
    final images = entries.fold<int>(0, (sum, entry) => sum + entry.images);
    return Row(
      children: [
        _SummaryPill(label: '${entries.length} runs'),
        const SizedBox(width: 6),
        _SummaryPill(label: '$images images'),
        const SizedBox(width: 6),
        _SummaryPill(label: '${formatBytes(saved)} saved'),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;

  const _SummaryPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Catppuccin.surface0,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10.5, color: Catppuccin.subtext0),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 34, color: Catppuccin.overlay1),
          SizedBox(height: 10),
          Text(
            'No runs yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Catppuccin.subtext0,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Finished runs will appear here with their savings.',
            style: TextStyle(fontSize: 12, color: Catppuccin.overlay1),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final RunHistoryEntry entry;

  const _HistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final failed = entry.failed > 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Catppuccin.mantle,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Catppuccin.surface0),
      ),
      child: Row(
        children: [
          Icon(
            failed ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            size: 20,
            color: failed ? Catppuccin.yellow : Catppuccin.green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(entry.finishedAt),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${entry.libraries.length} '
                  '${entry.libraries.length == 1 ? 'library' : 'libraries'}'
                  ' · ${formatDuration(entry.duration)}'
                  ' · ${entry.images} images',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Catppuccin.overlay1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.succeeded}/${entry.comics} comics',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: failed ? Catppuccin.yellow : Catppuccin.text,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${formatBytes(entry.savedBytes)} saved',
                style: const TextStyle(
                  fontSize: 11,
                  color: Catppuccin.overlay2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  String two(int value) => value.toString().padLeft(2, '0');
  return '${months[date.month - 1]} ${date.day}, ${date.year}'
      ' · ${two(date.hour)}:${two(date.minute)}';
}
