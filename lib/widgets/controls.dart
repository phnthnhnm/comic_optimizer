import 'package:flutter/material.dart';

import '../presets.dart';

class ControlPanel extends StatelessWidget {
  final String? rootPath;
  final VoidCallback onPickRoot;
  final String selectedPreset;
  final ValueChanged<String?> onPresetChanged;
  final bool skipPingo;
  final ValueChanged<bool?> onSkipPingoChanged;
  final String pingoPath;
  final ValueChanged<String> onPingoPathChanged;
  final String outputExt;
  final ValueChanged<String?> onOutputExtChanged;
  final bool running;
  final VoidCallback onStart;

  const ControlPanel({
    super.key,
    required this.rootPath,
    required this.onPickRoot,
    required this.selectedPreset,
    required this.onPresetChanged,
    required this.skipPingo,
    required this.onSkipPingoChanged,
    required this.pingoPath,
    required this.onPingoPathChanged,
    required this.outputExt,
    required this.onOutputExtChanged,
    required this.running,
    required this.onStart,
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
                    (p) => DropdownMenuItem(
                      value: p.name,
                      child: Tooltip(
                        message: p.args.join(' '),
                        child: Text(p.name),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onPresetChanged,
            ),
            const SizedBox(width: 16),
            Checkbox(value: skipPingo, onChanged: onSkipPingoChanged),
            const Text('Skip pingo'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Pingo path: '),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: TextEditingController(text: pingoPath),
                onChanged: onPingoPathChanged,
              ),
            ),
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
              child: Text(running ? 'Running...' : 'Start'),
            ),
          ],
        ),
      ],
    );
  }
}
