import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../pingo/pingo_args.dart';
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
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Preset deleted')),
                        );
                      }
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
  final qualityCtrl = TextEditingController();
  final resizeCtrl = TextEditingController();

  // Controls for pingo options
  int? sLevel;
  var lossless = false;
  int? quality;
  int? savedQuality;
  String? qualityError;
  int? resize;
  String? resizeError;
  var notrans = false;
  var grayscale = false;
  int? enhance;
  var srgb = false;
  var rotate = false;
  String outputFormat = 'none'; // 'none', 'jpeg', 'webp'
  var nostrip = false;
  var noalpha = false;
  var notime = false;
  final excludedFormats = <String>{}; // png, jpeg, apng, webp
  int? processLevel;
  var quiet = false;

  // Initialize controls from any existing args using shared parser
  final parseResult = parseArgs(initialArgs);
  final values = parseResult.values;

  ArgSpec? findSpec(String id) {
    for (final s in pingoArgSpecs) {
      if (s.id == id) return s;
    }
    return null;
  }

  String tooltipFor(String id) {
    final spec = findSpec(id);
    if (spec == null) return id;
    final parts = <String>[];
    parts.add(spec.label);
    if (spec.type == ArgType.enumString && spec.choices != null) {
      parts.add('Choices: ${spec.choices!.join(', ')}');
    }
    if (spec.help != null && spec.help!.isNotEmpty) parts.add(spec.help!);
    return parts.join('. ');
  }

  sLevel = values['s'] as int?;
  lossless = values['lossless'] == true;
  quality = values['quality'] as int?;
  savedQuality = quality;
  qualityCtrl.text = quality?.toString() ?? '';
  resize = values['resize'] as int?;
  resizeCtrl.text = resize?.toString() ?? '';
  notrans = values['notrans'] == true;
  grayscale = values['grayscale'] == true;
  enhance = values['enhance'] as int?;
  srgb = values['srgb'] == true;
  rotate = values['rotate'] == true;
  outputFormat = (values['output'] as String?) ?? 'none';
  nostrip = values['nostrip'] == true;
  noalpha = values['noalpha'] == true;
  notime = values['notime'] == true;
  final excl = values['exclude'];
  if (excl is Iterable) excludedFormats.addAll(excl.cast<String>());
  processLevel = values['process'] as int?;
  quiet = values['quiet'] == true;

  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          bool isDuplicateName(String name) {
            final lower = name.toLowerCase();
            for (final bp in Preset.all) {
              if (bp.name.toLowerCase() == lower) return true;
            }
            for (var i = 0; i < model.customPresets.length; i++) {
              if (index != null && i == index) continue;
              // Dispose controllers created for dialog fields
              nameCtrl.dispose();
              qualityCtrl.dispose();
              resizeCtrl.dispose();
              if (model.customPresets[i].name.toLowerCase() == lower) {
                return true;
              }
            }
            return false;
          }

          List<String> buildArgs() {
            final v = <String, dynamic>{
              's': sLevel,
              'lossless': lossless,
              'quality': quality,
              'resize': resize,
              'notrans': notrans,
              'grayscale': grayscale,
              'enhance': enhance,
              'srgb': srgb,
              'rotate': rotate,
              'output': outputFormat,
              'nostrip': nostrip,
              'noalpha': noalpha,
              'notime': notime,
              'exclude': excludedFormats,
              'process': processLevel,
              'quiet': quiet,
            };
            return buildArgsFromValues(v);
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
                  const Text('Options'),
                  const SizedBox(height: 8),
                  // Compression level and lossless/quality
                  Row(
                    children: [
                      Tooltip(
                        message: tooltipFor('s'),
                        child: const Text('Compression:'),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<int?>(
                        value: sLevel,
                        hint: const Text('auto'),
                        items: [null, 1, 2, 3, 4]
                            .map(
                              (v) => DropdownMenuItem<int?>(
                                value: v,
                                child: Text(v == null ? 'auto' : 's$v'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => sLevel = v),
                      ),
                      const SizedBox(width: 12),
                      Checkbox(
                        value: lossless,
                        onChanged: (v) => setState(() {
                          lossless = v ?? false;
                          if (lossless) {
                            savedQuality = quality;
                            quality = null;
                          } else {
                            quality = savedQuality;
                            savedQuality = null;
                          }
                        }),
                      ),
                      Tooltip(
                        message: tooltipFor('lossless'),
                        child: const Text('Lossless'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Tooltip(
                        message: tooltipFor('quality'),
                        child: const Text('Quality:'),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          enabled: !lossless,
                          controller: qualityCtrl,
                          decoration: InputDecoration(
                            hintText: '1-100',
                            errorText: qualityError,
                          ),
                          onChanged: (v) => setState(() {
                            final num = int.tryParse(v);
                            if (num == null) {
                              quality = null;
                              qualityError = null;
                            } else if (num < 1 || num > 100) {
                              quality = null;
                              qualityError = 'Enter 1-100';
                            } else {
                              quality = num;
                              qualityError = null;
                              savedQuality = quality;
                            }
                          }),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const Text('Resize / Color / Enhance'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Tooltip(
                        message: tooltipFor('resize'),
                        child: const Text('Resize:'),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          controller: resizeCtrl,
                          decoration: InputDecoration(
                            hintText: '24-4096',
                            errorText: resizeError,
                          ),
                          onChanged: (v) => setState(() {
                            final num = int.tryParse(v);
                            if (num == null) {
                              resize = null;
                              resizeError = null;
                            } else if (num < 24 || num > 4096) {
                              resize = null;
                              resizeError = 'Enter 24-4096';
                            } else {
                              resize = num;
                              resizeError = null;
                            }
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Checkbox(
                        value: notrans,
                        onChanged: (v) => setState(() => notrans = v ?? false),
                      ),
                      Tooltip(
                        message: tooltipFor('notrans'),
                        child: const Text('Remove transparency'),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: grayscale,
                        onChanged: (v) =>
                            setState(() => grayscale = v ?? false),
                      ),
                      Tooltip(
                        message: tooltipFor('grayscale'),
                        child: const Text('Grayscale'),
                      ),
                      const SizedBox(width: 12),
                      Tooltip(
                        message: tooltipFor('enhance'),
                        child: const Text('Enhance:'),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<int?>(
                        value: enhance,
                        hint: const Text('none'),
                        items: [null, 1, 2, 3, 4, 5, 6]
                            .map(
                              (v) => DropdownMenuItem<int?>(
                                value: v,
                                child: Text(v == null ? 'none' : v.toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => enhance = v),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: srgb,
                        onChanged: (v) => setState(() => srgb = v ?? false),
                      ),
                      Tooltip(
                        message: tooltipFor('srgb'),
                        child: const Text('sRGB'),
                      ),
                      const SizedBox(width: 12),
                      Checkbox(
                        value: rotate,
                        onChanged: (v) => setState(() => rotate = v ?? false),
                      ),
                      Tooltip(
                        message: tooltipFor('rotate'),
                        child: const Text('Rotate'),
                      ),
                    ],
                  ),
                  const Divider(),
                  const Text('Conversion'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Tooltip(
                        message: tooltipFor('output'),
                        child: const Text('Output:'),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: outputFormat,
                        items: const [
                          DropdownMenuItem(value: 'none', child: Text('none')),
                          DropdownMenuItem(value: 'jpeg', child: Text('jpeg')),
                          DropdownMenuItem(value: 'webp', child: Text('webp')),
                        ],
                        onChanged: (v) =>
                            setState(() => outputFormat = v ?? 'none'),
                      ),
                    ],
                  ),
                  const Divider(),
                  const Text('Other'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: nostrip,
                        onChanged: (v) => setState(() => nostrip = v ?? false),
                      ),
                      Tooltip(
                        message: tooltipFor('nostrip'),
                        child: const Text('nostrip'),
                      ),
                      const SizedBox(width: 12),
                      Checkbox(
                        value: noalpha,
                        onChanged: (v) => setState(() => noalpha = v ?? false),
                      ),
                      Tooltip(
                        message: tooltipFor('noalpha'),
                        child: const Text('noalpha'),
                      ),
                      const SizedBox(width: 12),
                      Checkbox(
                        value: notime,
                        onChanged: (v) => setState(() => notime = v ?? false),
                      ),
                      Tooltip(
                        message: tooltipFor('notime'),
                        child: const Text('notime'),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Tooltip(
                        message: tooltipFor('process'),
                        child: const Text('Process:'),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<int?>(
                        value: processLevel,
                        hint: const Text('default'),
                        items: [null, 0, 1, 2, 3, 4]
                            .map(
                              (v) => DropdownMenuItem<int?>(
                                value: v,
                                child: Text(
                                  v == null ? 'default' : v.toString(),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => processLevel = v),
                      ),
                      const SizedBox(width: 12),
                      Checkbox(
                        value: quiet,
                        onChanged: (v) => setState(() => quiet = v ?? false),
                      ),
                      Tooltip(
                        message: tooltipFor('quiet'),
                        child: const Text('Quiet'),
                      ),
                    ],
                  ),
                  const Divider(),
                  const Text('Exclude Formats'),
                  Row(
                    children: [
                      for (final fmt in ['png', 'jpeg', 'apng', 'webp'])
                        Row(
                          children: [
                            Checkbox(
                              value: excludedFormats.contains(fmt),
                              onChanged: (v) => setState(
                                () => v == true
                                    ? excludedFormats.add(fmt)
                                    : excludedFormats.remove(fmt),
                              ),
                            ),
                            Tooltip(
                              message: tooltipFor('exclude'),
                              child: Text(fmt),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                    ],
                  ),

                  Builder(
                    builder: (ctx) {
                      final preview = buildArgs().join(' ');
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Preview'),
                          const SizedBox(height: 4),
                          Text(preview, style: const TextStyle(fontSize: 12)),
                        ],
                      );
                    },
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
                  final argsList = buildArgs();
                  if (argsList.isEmpty) return;
                  if (isDuplicateName(name)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Preset name already exists'),
                      ),
                    );
                    return;
                  }
                  final p = Preset(name, argsList);
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
