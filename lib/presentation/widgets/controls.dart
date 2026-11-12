import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:comic_optimizer/domain/enums/post_run_action.dart';
import 'package:comic_optimizer/domain/models/image_formats.dart';
import 'package:comic_optimizer/domain/models/preset.dart';
import 'package:comic_optimizer/features/home/providers/optimization_provider.dart';
import 'package:comic_optimizer/features/settings/providers/settings_provider.dart';

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
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final state = ref.watch(optimizationProvider);

    final rootPath = settings.lastRoot;
    final selectedPreset = Preset.byName(settings.lastPreset).name;
    final skipCjxl = settings.skipCjxl;
    final preferPermanentDelete = settings.preferPermanentDelete;
    final safeRun = settings.safeRun;
    final outputExt = settings.outputExt;
    final postRunAction = settings.postRunAction;
    final postRunConfirmEnabled = settings.postRunConfirmEnabled;
    final postRunConfirmSeconds = settings.postRunConfirmSeconds;
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
              onPressed: () async {
                final dir = await FilePicker.getDirectoryPath();
                if (dir != null) await settingsNotifier.setLastRoot(dir);
              },
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
              onChanged: (v) =>
                  settingsNotifier.setLastPreset(v ?? Preset.losslessName),
            ),
            const SizedBox(width: 12),
            Checkbox(
              value: skipCjxl,
              onChanged: (v) => settingsNotifier.setSkipCjxl(v ?? false),
            ),
            const SizedBox(width: 4),
            const Text('Skip cjxl'),
            const SizedBox(width: 12),
            Checkbox(
              value: preferPermanentDelete,
              onChanged: (v) =>
                  settingsNotifier.setPreferPermanentDelete(v ?? false),
            ),
            const SizedBox(width: 4),
            const Text('Delete permanently'),
            const SizedBox(width: 12),
            Checkbox(
              value: safeRun,
              onChanged: (v) => settingsNotifier.setSafeRun(v ?? false),
            ),
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
              items: kOutputExtensions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => settingsNotifier.setOutputExt(v ?? '.cbz'),
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
              onChanged: (v) =>
                  settingsNotifier.setPostRunAction(v ?? PostRunAction.none),
            ),
            const SizedBox(width: 12),
            Checkbox(
              value: postRunConfirmEnabled,
              onChanged: (v) =>
                  settingsNotifier.setPostRunConfirmEnabled(v ?? true),
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
                  settingsNotifier.setPostRunConfirmSeconds(iv);
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
