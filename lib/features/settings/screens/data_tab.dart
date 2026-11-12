import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:comic_optimizer/features/settings/providers/settings_provider.dart';

class DataTab extends ConsumerStatefulWidget {
  const DataTab({super.key});

  @override
  ConsumerState<DataTab> createState() => _DataTabState();
}

class _DataTabState extends ConsumerState<DataTab> {
  late final TextEditingController _cjxlController;

  @override
  void initState() {
    super.initState();
    _cjxlController = TextEditingController(
      text: ref.read(settingsProvider).cjxlPath,
    );
  }

  @override
  void dispose() {
    _cjxlController.dispose();
    super.dispose();
  }

  Future<void> _pickCjxl() async {
    final files = await FilePicker.pickFiles(
      dialogTitle: 'Select the cjxl executable',
      type: FileType.any,
    );
    final path = files.isEmpty ? null : files.first.path;
    if (path == null) return;
    _cjxlController.text = path;
    await ref.read(settingsProvider.notifier).setCjxlPath(path);
  }

  Future<void> _backupData() async {
    final notifier = ref.read(settingsProvider.notifier);
    final prefsMap = notifier.getAllPrefs();
    final Map<String, dynamic> dump = {};
    for (var key in prefsMap.keys) {
      final value = prefsMap[key];
      if (value is bool) {
        dump[key] = {'type': 'bool', 'value': value};
      } else if (value is int) {
        dump[key] = {'type': 'int', 'value': value};
      } else if (value is double) {
        dump[key] = {'type': 'double', 'value': value};
      } else if (value is String) {
        dump[key] = {'type': 'string', 'value': value};
      } else if (value is List<String>) {
        dump[key] = {'type': 'stringList', 'value': value};
      }
    }

    String? selectedDirectory = await FilePicker.getDirectoryPath(
      dialogTitle: 'Select folder to save backup',
    );
    if (selectedDirectory != null) {
      final now = DateTime.now();
      final formatted =
          '${now.year.toString().padLeft(4, '0')}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}';
      final filename = 'tdt_backup_$formatted.json';
      final backupFile = File(
        '$selectedDirectory${Platform.pathSeparator}$filename',
      );
      await backupFile.writeAsString(jsonEncode(dump));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Backup saved as $filename')));
    }
  }

  Future<void> _restoreData() async {
    final notifier = ref.read(settingsProvider.notifier);
    final files = await FilePicker.pickFiles(
      dialogTitle: 'Select backup JSON file',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final path = files.isEmpty ? null : files.first.path;
    if (path != null) {
      final file = File(path);
      final inputJson = await file.readAsString();
      try {
        final Map<String, dynamic> data = jsonDecode(inputJson);
        await notifier.clearAllPrefs();
        for (var entry in data.entries) {
          final k = entry.key;
          final v = entry.value as Map<String, dynamic>;
          final type = v['type'] as String?;
          final val = v['value'];
          if (type == 'bool') {
            await notifier.setRawBool(k, val as bool);
          } else if (type == 'int') {
            await notifier.setRawInt(k, val as int);
          } else if (type == 'double') {
            await notifier.setRawDouble(k, (val as num).toDouble());
          } else if (type == 'string') {
            await notifier.setRawString(k, val as String);
          } else if (type == 'stringList') {
            await notifier.setRawStringList(k, List<String>.from(val));
          }
        }
        await notifier.load();
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Data restored!')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Invalid backup data')));
      }
    }
  }

  Future<void> _resetData() async {
    final notifier = ref.read(settingsProvider.notifier);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Reset'),
        content: const Text(
          'Are you sure you want to reset all data and settings? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await notifier.clearAllPrefs();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data and settings have been reset')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(settingsProvider.notifier);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Encoder',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cjxlController,
                  decoration: const InputDecoration(
                    labelText: 'cjxl executable',
                    hintText: 'cjxl',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    final path = value.trim();
                    notifier.setCjxlPath(path.isEmpty ? 'cjxl' : path);
                  },
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _pickCjxl,
                icon: const Icon(Icons.folder_open),
                label: const Text('Browse'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Leave as "cjxl" to resolve the encoder from PATH.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _backupData,
            icon: const Icon(Icons.save),
            label: const Text('Backup Data'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _restoreData,
            icon: const Icon(Icons.restore),
            label: const Text('Restore Data'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withAlpha((0.1 * 255).toInt()),
              foregroundColor: Colors.red,
            ),
            onPressed: _resetData,
            icon: const Icon(Icons.delete_forever),
            label: const Text('Reset All Data'),
          ),
          const SizedBox(height: 12),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
