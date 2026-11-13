import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:comic_optimizer/domain/models/app_settings.dart';
import 'package:comic_optimizer/domain/models/custom_preset.dart';
import 'package:comic_optimizer/domain/models/preset.dart';
import 'package:comic_optimizer/features/settings/providers/settings_provider.dart';
import 'package:comic_optimizer/features/settings/widgets/settings_widgets.dart';
import 'package:comic_optimizer/presentation/design_system/catppuccin.dart';

class PresetsSection extends ConsumerWidget {
  const PresetsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return SettingsSection(
      title: 'Presets',
      subtitle: 'Built-in quality levels plus your own cjxl argument sets.',
      children: [
        SettingsCard(
          title: 'Built-in',
          child: Column(
            children: [
              for (final preset in Preset.all)
                _PresetRow(
                  name: preset.name,
                  subtitle: preset.args.join(' '),
                  selected: settings.lastPreset == preset.name,
                  onUse: () => notifier.setLastPreset(preset.name),
                ),
            ],
          ),
        ),
        SettingsCard(
          title: 'Custom presets',
          subtitle: 'Stored locally. The name appears next to the built-in cards on the Library screen.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: () => _edit(context, ref, settings),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('New preset'),
                ),
              ),
              if (settings.customPresets.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No custom presets yet.',
                    style: TextStyle(fontSize: 12, color: Catppuccin.overlay1),
                  ),
                )
              else ...[
                const SizedBox(height: 10),
                for (final preset in settings.customPresets)
                  _CustomPresetRow(
                    preset: preset,
                    selected: settings.lastPreset == preset.name,
                    onUse: () => notifier.setLastPreset(preset.name),
                    onEdit: () =>
                        _edit(context, ref, settings, existing: preset),
                    onDelete: () => _delete(context, ref, preset),
                  ),
              ],
            ],
          ),
        ),
        const SettingsCard(
          child: SettingsInfo(
            icon: Icons.tune_rounded,
            text:
                'Distance 0 is mathematically lossless; higher values get '
                'smaller but lossier. Extra arguments are passed to cjxl '
                'verbatim and must be space-separated.',
          ),
        ),
      ],
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings, {
    CustomPreset? existing,
  }) async {
    final result = await showDialog<CustomPreset>(
      context: context,
      builder: (dialogContext) => _PresetEditorDialog(
        existing: existing,
        existingNames: [
          for (final preset in settings.customPresets) preset.name,
        ],
      ),
    );
    if (result == null) return;
    await ref
        .read(settingsProvider.notifier)
        .saveCustomPreset(result, previousName: existing?.name);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    CustomPreset preset,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete preset?'),
        content: Text(
          '“${preset.name}” will be removed. Runs using it fall back to Lossless.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(settingsProvider.notifier).removeCustomPreset(preset.name);
    }
  }
}

class _PresetRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final bool selected;
  final VoidCallback onUse;

  const _PresetRow({
    required this.name,
    required this.subtitle,
    required this.selected,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            selected ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 16,
            color: selected ? Catppuccin.green : Catppuccin.overlay1,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Catppuccin.overlay2,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          if (!selected) TextButton(onPressed: onUse, child: const Text('Use')),
        ],
      ),
    );
  }
}

class _CustomPresetRow extends StatelessWidget {
  final CustomPreset preset;
  final bool selected;
  final VoidCallback onUse;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomPresetRow({
    required this.preset,
    required this.selected,
    required this.onUse,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: selected ? Catppuccin.surface0 : Catppuccin.base,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? Catppuccin.green : Catppuccin.surface1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            selected ? Icons.check_circle_rounded : Icons.tune_rounded,
            size: 16,
            color: selected ? Catppuccin.green : Catppuccin.overlay1,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preset.name,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${preset.description} · ${preset.args.join(' ')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Catppuccin.overlay2,
                  ),
                ),
              ],
            ),
          ),
          if (!selected) TextButton(onPressed: onUse, child: const Text('Use')),
          IconButton(
            tooltip: 'Edit preset',
            visualDensity: VisualDensity.compact,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 16),
          ),
          IconButton(
            tooltip: 'Delete preset',
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 16,
              color: Catppuccin.red,
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetEditorDialog extends StatefulWidget {
  final CustomPreset? existing;
  final List<String> existingNames;

  const _PresetEditorDialog({
    required this.existing,
    required this.existingNames,
  });

  @override
  State<_PresetEditorDialog> createState() => _PresetEditorDialogState();
}

class _PresetEditorDialogState extends State<_PresetEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _argsController;
  late double _distance;
  late bool _losslessJpeg;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _argsController = TextEditingController(text: existing?.extraArgs ?? '');
    _distance = (existing?.distance ?? 1.0).clamp(0.0, 10.0);
    _losslessJpeg = existing?.losslessJpeg ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _argsController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Give the preset a name';
    if (name.length > 40) return 'Keep the name under 40 characters';
    if (Preset.all.any((preset) => preset.name == name)) {
      return 'That name is reserved for a built-in preset';
    }
    final others = widget.existingNames
        .where((existing) => existing != widget.existing?.name)
        .toSet();
    if (others.contains(name)) return 'A preset with that name already exists';
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      CustomPreset(
        name: _nameController.text.trim(),
        distance: _distance,
        losslessJpeg: _losslessJpeg,
        extraArgs: _argsController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = CustomPreset(
      name: _nameController.text.trim().isEmpty
          ? 'Preview'
          : _nameController.text.trim(),
      distance: _distance,
      losslessJpeg: _losslessJpeg,
      extraArgs: _argsController.text.trim(),
    );
    return AlertDialog(
      title: Text(widget.existing == null ? 'New preset' : 'Edit preset'),
      content: SizedBox(
        width: 470,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: _validateName,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Distance',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      preview.distanceLabel,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Catppuccin.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _distance,
                  min: 0,
                  max: 10,
                  divisions: 100,
                  label: preview.distanceLabel,
                  onChanged: (value) =>
                      setState(() => _distance = (value * 10).round() / 10),
                ),
                const Text(
                  '0 = lossless, 1 ≈ visually lossless, higher = smaller and lossier.',
                  style: TextStyle(fontSize: 10.5, color: Catppuccin.overlay2),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text(
                    'Lossless JPEG reconstruction',
                    style: TextStyle(fontSize: 12.5),
                  ),
                  subtitle: const Text(
                    'Only affects JPEG pages; other formats re-encode from pixels.',
                    style: TextStyle(fontSize: 10.5),
                  ),
                  value: _losslessJpeg,
                  onChanged: (value) => setState(() => _losslessJpeg = value),
                ),
                TextFormField(
                  controller: _argsController,
                  decoration: const InputDecoration(
                    labelText: 'Extra cjxl arguments (optional)',
                    hintText: '--effort=7',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Catppuccin.base,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Catppuccin.surface1),
                  ),
                  child: Text(
                    preview.args.join(' '),
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontFamily: 'monospace',
                      color: Catppuccin.subtext0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(widget.existing == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}
