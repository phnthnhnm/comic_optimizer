import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataTab extends StatefulWidget {
  const DataTab({super.key});

  @override
  State<DataTab> createState() => _DataTabState();
}

class _DataTabState extends State<DataTab> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _backupData() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> dump = {};
    for (var key in prefs.getKeys()) {
      final value = prefs.get(key);
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

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup saved as $filename')));
    }
  }

  Future<void> _restoreData() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select backup JSON file',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final inputJson = await file.readAsString();
      try {
        final Map<String, dynamic> data = jsonDecode(inputJson);
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        for (var entry in data.entries) {
          final k = entry.key;
          final v = entry.value as Map<String, dynamic>;
          final type = v['type'] as String?;
          final val = v['value'];
          if (type == 'bool') {
            await prefs.setBool(k, val as bool);
          } else if (type == 'int') {
            await prefs.setInt(k, val as int);
          } else if (type == 'double') {
            await prefs.setDouble(k, (val as num).toDouble());
          } else if (type == 'string') {
            await prefs.setString(k, val as String);
          } else if (type == 'stringList') {
            await prefs.setStringList(k, List<String>.from(val));
          }
        }
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Data restored!')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid backup data')));
      }
    }
  }

  Future<void> _resetData() async {
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data and settings have been reset')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
        ],
      ),
    );
  }
}
