import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../optimizer.dart';
import '../presets.dart';
import '../widgets/controls.dart';
import '../widgets/layouts.dart';
import 'settings/settings_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _rootPath;
  String _selectedPreset = Preset.losslessName;
  bool _skipPingo = false;
  String _pingoPath = 'pingo';
  String _outputExt = '.cbz';
  final List<String> _logs = [];
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rootPath = prefs.getString('lastRoot');
      _selectedPreset = prefs.getString('lastPreset') ?? Preset.losslessName;
      _skipPingo = prefs.getBool('skipPingo') ?? false;
      _pingoPath = prefs.getString('pingoPath') ?? 'pingo';
      _outputExt = prefs.getString('outputExt') ?? '.cbz';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rootPath != null) prefs.setString('lastRoot', _rootPath!);
    prefs.setString('lastPreset', _selectedPreset);
    prefs.setBool('skipPingo', _skipPingo);
    prefs.setString('pingoPath', _pingoPath);
    prefs.setString('outputExt', _outputExt);
  }

  void _log(String line) {
    setState(() {
      _logs.add(line);
    });
  }

  Future<void> _pickRoot() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() => _rootPath = result);
      _saveSettings();
    }
  }

  Future<void> _start() async {
    if (_rootPath == null) {
      _log('Please choose a root folder first.');
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirm'),
        content: const Text(
          'This tool will modify and delete files. Back up your data before proceeding. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Start'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await _saveSettings();

    setState(() {
      _logs.clear();
      _running = true;
    });

    final preset = Preset.byName(_selectedPreset);

    final optimizer = Optimizer(
      onLog: (s) => _log(s),
      onFolderStart: (f) => _log('Start: $f'),
      onFolderDone: (f, ok) => _log('Done: $f (${ok ? 'OK' : 'ERR'})'),
    );

    try {
      await optimizer.optimizeRoot(
        Directory(_rootPath!),
        presetArgs: preset.args,
        skipPingo: _skipPingo,
        pingoPath: _pingoPath,
        outputExtension: _outputExt,
      );
      _log('All done.');
    } catch (e, st) {
      _log('Error: $e');
      _log(st.toString());
    } finally {
      setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comic Optimizer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Report a Bug',
            onPressed: () async {
              final url = Uri.parse(
                'https://github.com/phnthnhnm/comic_optimizer/issues/new',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            ControlPanel(
              rootPath: _rootPath,
              onPickRoot: _pickRoot,
              selectedPreset: _selectedPreset,
              onPresetChanged: (v) =>
                  setState(() => _selectedPreset = v ?? Preset.losslessName),
              skipPingo: _skipPingo,
              onSkipPingoChanged: (v) =>
                  setState(() => _skipPingo = v ?? false),
              pingoPath: _pingoPath,
              onPingoPathChanged: (v) => _pingoPath = v,
              outputExt: _outputExt,
              onOutputExtChanged: (v) =>
                  setState(() => _outputExt = v ?? '.cbz'),
              running: _running,
              onStart: _start,
            ),
            const SizedBox(height: 12),
            const Divider(),
            LogsPanel(logs: _logs),
          ],
        ),
      ),
    );
  }
}
