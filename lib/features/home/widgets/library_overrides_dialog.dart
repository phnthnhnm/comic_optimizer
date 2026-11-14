import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';

import 'package:comic_optimizer/domain/models/app_settings.dart';
import 'package:comic_optimizer/domain/models/library_entry.dart';
import 'package:comic_optimizer/presentation/design_system/catppuccin.dart';

class LibraryOverridesDialog extends StatefulWidget {
  final LibraryEntry entry;
  final AppSettings settings;
  final List<String> presetNames;

  const LibraryOverridesDialog({
    super.key,
    required this.entry,
    required this.settings,
    required this.presetNames,
  });

  @override
  State<LibraryOverridesDialog> createState() => _LibraryOverridesDialogState();
}

class _LibraryOverridesDialogState extends State<LibraryOverridesDialog> {
  late String _preset = widget.entry.preset ?? '';
  late final TextEditingController _output = TextEditingController(
    text: widget.entry.outputDirectory ?? '',
  );
  late String _safeMode = switch (widget.entry.safeRunOverride) {
    null => 'global',
    true => 'keep',
    false => 'delete',
  };

  @override
  void dispose() {
    _output.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final globalPreset = widget.settings.lastPreset;
    return AlertDialog(
      title: const Text('Library settings'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.entry.path,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Catppuccin.overlay1,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _preset,
                decoration: const InputDecoration(
                  labelText: 'Quality preset',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                dropdownColor: Catppuccin.mantle,
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text('Use global ($globalPreset)'),
                  ),
                  for (final name in widget.presetNames)
                    DropdownMenuItem(value: name, child: Text(name)),
                ],
                onChanged: (value) => setState(() => _preset = value ?? ''),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _output,
                      decoration: const InputDecoration(
                        labelText: 'Output folder',
                        helperText: 'Leave blank to use the global output.',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () async {
                      final directory = await FilePicker.getDirectoryPath(
                        dialogTitle: 'Choose an output folder',
                      );
                      if (directory != null) {
                        _output.text = directory;
                      }
                    },
                    child: const Text('Browse'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _safeMode,
                decoration: const InputDecoration(
                  labelText: 'Source folder',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                dropdownColor: Catppuccin.mantle,
                items: const [
                  DropdownMenuItem(value: 'global', child: Text('Use global')),
                  DropdownMenuItem(
                    value: 'keep',
                    child: Text('Keep originals'),
                  ),
                  DropdownMenuItem(
                    value: 'delete',
                    child: Text('Delete source after archiving'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _safeMode = value ?? 'global'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            widget.entry.copyWith(
              preset: _preset.isEmpty ? null : _preset,
              outputDirectory: _output.text.trim().isEmpty
                  ? null
                  : _output.text.trim(),
              safeRunOverride: switch (_safeMode) {
                'keep' => true,
                'delete' => false,
                _ => null,
              },
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
