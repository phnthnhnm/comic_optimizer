import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../presets.dart';
import '../settings/settings_model.dart';

class PresetsScreen extends StatelessWidget {
  const PresetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presets')),
      body: const _PresetsList(),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showPresetEditor(context),
      ),
    );
  }
}

class _PresetsList extends StatelessWidget {
  const _PresetsList();

  @override
  Widget build(BuildContext context) {
    final model = context.watch<SettingsModel>();
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        const ListTile(title: Text('Built-in')),
        ...Preset.all.map(
          (p) => ListTile(
            title: Text(p.name),
            subtitle: Text(p.args.join(' ')),
            onTap: () {},
          ),
        ),
        const Divider(),
        const ListTile(title: Text('Custom')),
        ...List.generate(model.customPresets.length, (i) {
          final p = model.customPresets[i];
          return ListTile(
            title: Text(p.name),
            subtitle: Text(p.args.join(' ')),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      _showPresetEditor(context, preset: p, index: i),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete preset?'),
                        content: Text('Delete preset "${p.name}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await model.removePreset(i);
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Preset deleted')),
                        );
                    }
                  },
                ),
              ],
            ),
            onTap: () {},
          );
        }),
      ],
    );
  }
}

Future<void> _showPresetEditor(
  BuildContext context, {
  Preset? preset,
  int? index,
}) async {
  final model = context.read<SettingsModel>();
  final nameCtrl = TextEditingController(text: preset?.name ?? '');
  final initialArgs = preset?.args.toList() ?? <String>[];

  final args = List<String>.from(initialArgs);
  final newArgCtrl = TextEditingController();

  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          void addArgFromField() {
            final a = newArgCtrl.text.trim();
            if (a.isEmpty) return;
            if (!args.contains(a)) {
              setState(() {
                args.add(a);
                newArgCtrl.clear();
              });
            } else {
              newArgCtrl.clear();
            }
          }

          bool isDuplicateName(String name) {
            final lower = name.toLowerCase();
            for (final bp in Preset.all) {
              if (bp.name.toLowerCase() == lower) return true;
            }
            for (var i = 0; i < model.customPresets.length; i++) {
              if (index != null && i == index) continue;
              if (model.customPresets[i].name.toLowerCase() == lower)
                return true;
            }
            return false;
          }

          return AlertDialog(
            title: Text(preset == null ? 'New Preset' : 'Edit Preset'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Args'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var a in args)
                        InputChip(
                          label: Text(a),
                          onDeleted: () => setState(() => args.remove(a)),
                        ),
                      SizedBox(
                        width: 200,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: newArgCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'Add arg',
                                ),
                                onSubmitted: (_) => addArgFromField(),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: addArgFromField,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  if (args.isEmpty) return;
                  if (isDuplicateName(name)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Preset name already exists'),
                      ),
                    );
                    return;
                  }
                  final p = Preset(name, args);
                  if (preset == null) {
                    await model.addPreset(p);
                  } else if (index != null) {
                    await model.updatePreset(index, p);
                  }
                  if (context.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}
