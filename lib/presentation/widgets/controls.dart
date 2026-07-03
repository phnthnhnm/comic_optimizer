import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:comic_optimizer/domain/enums/post_run_action.dart';
import 'package:comic_optimizer/domain/models/preset.dart';
import 'package:comic_optimizer/features/home/providers/optimization_provider.dart';

class ControlPanel extends ConsumerWidget {
  final VoidCallback onStart;
  final VoidCallback? onCancel;
  final VoidCallback? onPause;
  final VoidCallback? onResume;

  const ControlPanel({
    super.key,
    required this.onStart,
    this.onCancel,
    this.onPause,
    this.onResume,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(optimizationProvider);
    final notifier = ref.read(optimizationProvider.notifier);

    final rootPath = state.rootPath;
    final selectedPreset = state.selectedPreset;
    final skipCjxl = state.skipCjxl;
    final preferPermanentDelete = state.preferPermanentDelete;
    final safeRun = state.safeRun;
    final outputExt = state.outputExt;
    final postRunAction = state.postRunAction;
    final postRunConfirmEnabled = state.postRunConfirmEnabled;
    final postRunConfirmSeconds = state.postRunConfirmSeconds;
    final running = state.running;
    final paused = state.paused;
    final starting = state.starting;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: rootPath == null
                  ? const Text('No root selected')
                  : Tooltip(
                      message: rootPath,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha((0.08 * 255).round()),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary
                                .withAlpha((0.18 * 255).round()),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                rootPath,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => notifier.pickRoot(),
              child: const Text('Choose Root'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Preset: '),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: selectedPreset,
              items: Preset.all
                  .map(
                    (p) => DropdownMenuItem(value: p.name, child: Text(p.name)),
                  )
                  .toList(),
              onChanged: (v) => notifier.setSelectedPreset(v),
            ),
            const SizedBox(width: 12),
            Checkbox(
              value: skipCjxl,
              onChanged: (v) => notifier.setSkipCjxl(v),
            ),
            const SizedBox(width: 4),
            const Text('Skip cjxl'),
            const SizedBox(width: 12),
            Checkbox(
              value: preferPermanentDelete,
              onChanged: (v) => notifier.setPreferPermanentDelete(v),
            ),
            const SizedBox(width: 4),
            const Text('Delete permanently'),
            const SizedBox(width: 12),
            Checkbox(value: safeRun, onChanged: (v) => notifier.setSafeRun(v)),
            const SizedBox(width: 4),
            const Text('Safe run'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Output ext: '),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: outputExt,
              items: [
                '.cbz',
                '.cbr',
                '.zip',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => notifier.setOutputExt(v),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: !running
                  ? onStart
                  : (starting ? null : (paused ? onResume : onPause)),
              child: Text(
                !running
                    ? 'Start'
                    : (starting ? 'Starting' : (paused ? 'Resume' : 'Pause')),
              ),
            ),
            const SizedBox(width: 8),
            if (running)
              OutlinedButton(onPressed: onCancel, child: const Text('Cancel')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('After finish: '),
            const SizedBox(width: 8),
            DropdownButton<PostRunAction>(
              value: postRunAction,
              items: [
                DropdownMenuItem(
                  value: PostRunAction.none,
                  child: Text('None'),
                ),
                DropdownMenuItem(
                  value: PostRunAction.quit,
                  child: Text('Quit app'),
                ),
                DropdownMenuItem(
                  value: PostRunAction.sleep,
                  child: Text('Sleep'),
                ),
                DropdownMenuItem(
                  value: PostRunAction.hibernate,
                  child: Text('Hibernate'),
                ),
                DropdownMenuItem(
                  value: PostRunAction.shutdown,
                  child: Text('Shutdown'),
                ),
                DropdownMenuItem(
                  value: PostRunAction.restart,
                  child: Text('Restart'),
                ),
              ],
              onChanged: (v) => notifier.setPostRunAction(v),
            ),
            const SizedBox(width: 12),
            Checkbox(
              value: postRunConfirmEnabled,
              onChanged: (v) => notifier.setPostRunConfirmEnabled(v),
            ),
            const SizedBox(width: 4),
            const Text('Confirm before action'),
            const SizedBox(width: 12),
            const Text('Timeout (s):'),
            const SizedBox(width: 6),
            SizedBox(
              width: 80,
              child: TextFormField(
                key: ValueKey(postRunConfirmSeconds),
                initialValue: postRunConfirmSeconds.toString(),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final iv = int.tryParse(v) ?? 0;
                  notifier.setPostRunConfirmSeconds(iv);
                },
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
