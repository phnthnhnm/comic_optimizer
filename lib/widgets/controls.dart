import 'package:flutter/material.dart';

import '../presets.dart';
import '../settings/settings_model.dart';

class ControlPanel extends StatelessWidget {
  final String? rootPath;
  final VoidCallback onPickRoot;
  final String selectedPreset;
  final ValueChanged<String?> onPresetChanged;
  final bool skipCjxl;
  final ValueChanged<bool?> onSkipCjxlChanged;
  final bool preferPermanentDelete;
  final ValueChanged<bool?> onPreferPermanentDeleteChanged;
  final bool safeRun;
  final ValueChanged<bool?> onSafeRunChanged;
  final PostRunAction postRunAction;
  final ValueChanged<PostRunAction?> onPostRunActionChanged;
  final bool postRunConfirmEnabled;
  final ValueChanged<bool?> onPostRunConfirmEnabledChanged;
  final int postRunConfirmSeconds;
  final ValueChanged<int?> onPostRunConfirmSecondsChanged;

  final String outputExt;
  final ValueChanged<String?> onOutputExtChanged;
  final bool running;
  final VoidCallback onStart;
  final VoidCallback? onCancel;
  final bool starting;

  const ControlPanel({
    super.key,
    required this.rootPath,
    required this.onPickRoot,
    required this.selectedPreset,
    required this.onPresetChanged,
    required this.outputExt,
    required this.onOutputExtChanged,
    required this.skipCjxl,
    required this.onSkipCjxlChanged,
    required this.preferPermanentDelete,
    required this.onPreferPermanentDeleteChanged,
    required this.safeRun,
    required this.onSafeRunChanged,
    required this.postRunAction,
    required this.onPostRunActionChanged,
    required this.postRunConfirmEnabled,
    required this.onPostRunConfirmEnabledChanged,
    required this.postRunConfirmSeconds,
    required this.onPostRunConfirmSecondsChanged,
    required this.running,
    required this.onStart,
    this.onCancel,
    this.starting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: rootPath == null
                  ? const Text('No root selected')
                  : Tooltip(
                      message: rootPath!,
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
                                rootPath!,
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
              onPressed: onPickRoot,
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
              onChanged: onPresetChanged,
            ),
            const SizedBox(width: 12),
            Checkbox(value: skipCjxl, onChanged: onSkipCjxlChanged),
            const SizedBox(width: 4),
            const Text('Skip cjxl'),
            const SizedBox(width: 12),
            Checkbox(
              value: preferPermanentDelete,
              onChanged: onPreferPermanentDeleteChanged,
            ),
            const SizedBox(width: 4),
            const Text('Delete permanently'),
            const SizedBox(width: 12),
            Checkbox(value: safeRun, onChanged: onSafeRunChanged),
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
              onChanged: onOutputExtChanged,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: running ? null : onStart,
              child: Text(
                running ? (starting ? 'Starting' : 'Running...') : 'Start',
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
              onChanged: onPostRunActionChanged,
            ),
            const SizedBox(width: 12),
            Checkbox(
              value: postRunConfirmEnabled,
              onChanged: onPostRunConfirmEnabledChanged,
            ),
            const SizedBox(width: 4),
            const Text('Confirm before action'),
            const SizedBox(width: 12),
            const Text('Timeout (s):'),
            const SizedBox(width: 6),
            SizedBox(
              width: 80,
              child: TextFormField(
                initialValue: postRunConfirmSeconds.toString(),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final iv = int.tryParse(v) ?? 0;
                  onPostRunConfirmSecondsChanged(iv);
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
