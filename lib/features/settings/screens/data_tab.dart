import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:comic_optimizer/features/settings/providers/settings_provider.dart';
import 'package:comic_optimizer/features/settings/widgets/settings_widgets.dart';
import 'package:comic_optimizer/presentation/design_system/catppuccin.dart';

class DataTab extends ConsumerStatefulWidget {
  const DataTab({super.key});

  @override
  ConsumerState<DataTab> createState() => _DataTabState();
}

class _DataTabState extends ConsumerState<DataTab> {
  Future<void> _backupData() async {
    final notifier = ref.read(settingsProvider.notifier);
    final prefsMap = notifier.getAllPrefs();
    final Map<String, dynamic> dump = {};
    for (final key in prefsMap.keys) {
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

    final selectedDirectory = await FilePicker.getDirectoryPath(
      dialogTitle: 'Select folder to save backup',
    );
    if (selectedDirectory == null) return;

    final now = DateTime.now();
    final formatted =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    final filename = 'comic_optimizer_backup_$formatted.json';
    final backupFile = File(
      '$selectedDirectory${Platform.pathSeparator}$filename',
    );
    await backupFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(dump),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Backup saved as $filename')));
  }

  Future<void> _restoreData() async {
    final notifier = ref.read(settingsProvider.notifier);
    final files = await FilePicker.pickFiles(
      dialogTitle: 'Select backup JSON file',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final path = files.isEmpty ? null : files.first.path;
    if (path == null) return;

    final file = File(path);
    final inputJson = await file.readAsString();
    try {
      final Map<String, dynamic> data = jsonDecode(inputJson);
      await notifier.clearAllPrefs();
      for (final entry in data.entries) {
        final value = entry.value as Map<String, dynamic>;
        final type = value['type'] as String?;
        final raw = value['value'];
        if (type == 'bool') {
          await notifier.setRawBool(entry.key, raw as bool);
        } else if (type == 'int') {
          await notifier.setRawInt(entry.key, raw as int);
        } else if (type == 'double') {
          await notifier.setRawDouble(entry.key, (raw as num).toDouble());
        } else if (type == 'string') {
          await notifier.setRawString(entry.key, raw as String);
        } else if (type == 'stringList') {
          await notifier.setRawStringList(
            entry.key,
            List<String>.from(raw as List),
          );
        }
      }
      await notifier.load();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Data restored')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That file is not a valid backup')),
      );
    }
  }

  Future<void> _resetData() async {
    final notifier = ref.read(settingsProvider.notifier);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset all data?'),
        content: const Text(
          'Every setting, custom preset, queue entry and window position will '
          'be cleared. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Catppuccin.redContainer,
              foregroundColor: Catppuccin.red,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await notifier.clearAllPrefs();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All data and settings have been reset')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Data',
      subtitle: 'Move settings between installations or start over.',
      children: [
        SettingsCard(
          title: 'Backup',
          subtitle: 'Saves every stored setting, queue entry and custom preset as JSON.',
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: _backupData,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Save backup'),
            ),
          ),
        ),
        SettingsCard(
          title: 'Restore',
          subtitle: 'Replaces the current settings with the contents of a backup file.',
          child: Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _restoreData,
              icon: const Icon(Icons.restore, size: 18),
              label: const Text('Restore backup'),
            ),
          ),
        ),
        SettingsCard(
          title: 'Reset',
          subtitle: 'Clears all settings and returns the app to its first-run defaults.',
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Catppuccin.redContainer,
                foregroundColor: Catppuccin.red,
              ),
              onPressed: _resetData,
              icon: const Icon(Icons.delete_forever_outlined, size: 18),
              label: const Text('Reset all data'),
            ),
          ),
        ),
      ],
    );
  }
}
