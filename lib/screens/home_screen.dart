import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../optimizer.dart';
import '../presets.dart';
import '../settings/settings_model.dart';
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
  dynamic _logs = {};
  String? _currentLogFolder;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final model = context.read<SettingsModel>();
      setState(() {
        _rootPath = model.lastRoot;
        _selectedPreset = model.lastPreset.isNotEmpty
            ? model.lastPreset
            : Preset.losslessName;
        _skipPingo = model.skipPingo;
        _pingoPath = model.pingoPath;
        _outputExt = model.outputExt;
      });
    });
  }

  Future<void> _saveSettings() async {
    final model = context.read<SettingsModel>();
    if (_rootPath != null) await model.setLastRoot(_rootPath);
    await model.setLastPreset(_selectedPreset);
    await model.setSkipPingo(_skipPingo);
    await model.setPingoPath(_pingoPath);
    await model.setOutputExt(_outputExt);
  }

  void _log(String line, {String? folder}) {
    setState(() {
      if (_logs is List<String>) {
        final existing = List<String>.from(_logs as List<String>);
        _logs = <String, List<String>>{'General': existing};
      }
      if (_logs is! Map<String, List<String>>) {
        _logs = <String, List<String>>{};
      }
      final key = folder ?? _currentLogFolder ?? 'General';
      (_logs as Map<String, List<String>>).putIfAbsent(key, () => []).add(line);
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

    final preferPermanentDelete = context
        .read<SettingsModel>()
        .preferPermanentDelete;

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
      _logs = {};
      _currentLogFolder = null;
      _running = true;
    });

    final preset = Preset.byName(_selectedPreset);

    final optimizer = Optimizer(
      onLog: (s) => _log(s),
      onFolderStart: (f) {
        _log('Start: $f', folder: f);
        setState(() => _currentLogFolder = f);
      },
      onFolderDone: (f, ok) {
        _log('Done: $f (${ok ? 'OK' : 'ERR'})', folder: f);
        setState(() => _currentLogFolder = null);
      },
    );

    try {
      await optimizer.optimizeRoot(
        Directory(_rootPath!),
        presetArgs: preset.args,
        skipPingo: _skipPingo,
        pingoPath: _pingoPath,
        outputExtension: _outputExt,
        preferPermanentDelete: preferPermanentDelete,
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
    // Safely handle legacy hot-reload state where `_logs` might still be a
    // `List<String>` from an older version. Access via `dynamic` and
    // normalize to `Map<String,List<String>>` for the `LogsPanel`.
    final dynamic rawLogs = (this as dynamic)._logs;
    final Map<String, List<String>> logsForPanel = {};
    if (rawLogs is Map<String, List<String>>) {
      logsForPanel.addAll(rawLogs);
    } else if (rawLogs is List<String>) {
      logsForPanel['General'] = List<String>.from(rawLogs);
    }

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
            LogsPanel(logsByFolder: logsForPanel),
          ],
        ),
      ),
    );
  }
}
