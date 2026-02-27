import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
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
  bool _skipCjxl = false;
  bool _preferPermanentDelete = false;
  bool _safeRun = false;

  String _outputExt = '.cbz';
  dynamic _logs = {};
  String? _currentLogFolder;
  bool _running = false;
  final Map<String, Map<String, int?>> _folderSizes = {};

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
        _outputExt = model.outputExt;
        _skipCjxl = model.skipCjxl;
        _preferPermanentDelete = model.preferPermanentDelete;
        _safeRun = model.safeRun;
      });
    });
  }

  Future<void> _saveSettings() async {
    final model = context.read<SettingsModel>();
    if (_rootPath != null) await model.setLastRoot(_rootPath);
    await model.setLastPreset(_selectedPreset);
    await model.setSkipCjxl(_skipCjxl);
    await model.setPreferPermanentDelete(_preferPermanentDelete);
    await model.setSafeRun(_safeRun);
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

    final preferPermanentDelete = _preferPermanentDelete;

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
      _folderSizes.clear();
    });

    final preset = Preset.byName(_selectedPreset);
    final presetArgs = preset.args;

    final optimizer = Optimizer(
      onLog: (s) => _log(s),
      onFolderStart: (f) {
        _log('Start: $f', folder: f);
        setState(() => _currentLogFolder = f);
      },
      onFolderDone: (f, ok, beforeBytes, afterBytes) {
        _folderSizes[f] = {'before': beforeBytes, 'after': afterBytes};
        _log('Done: $f (${ok ? 'OK' : 'ERR'})', folder: f);
        setState(() => _currentLogFolder = null);
      },
    );

    try {
      if (!mounted) return;
      final model = context.read<SettingsModel>();
      await optimizer.optimizeRoot(
        Directory(_rootPath!),
        presetArgs: presetArgs,
        skipCjxl: _skipCjxl,
        cjxlPath: model.cjxlPath,
        safeRun: _safeRun,
        outputExtension: _outputExt,
        preferPermanentDelete: preferPermanentDelete,
      );
      // Instead of a single 'All done.' line, log storage summary per folder
      if (_folderSizes.isNotEmpty) {
        _log('Storage summary:');
        _folderSizes.forEach((folder, map) {
          final before = map['before'];
          final after = map['after'];
          final name = p.basename(folder);
          if (before == null || after == null) {
            _log('$name: size unknown');
            return;
          }
          final beforeMb = before / (1024 * 1024);
          final afterMb = after / (1024 * 1024);
          final saved = before - after;
          final savedMb = saved / (1024 * 1024);
          final pct = before > 0 ? (saved / before) * 100.0 : 0.0;
          _log(
            '$name: ${beforeMb.toStringAsFixed(2)} MB -> ${afterMb.toStringAsFixed(2)} MB, saved ${savedMb.toStringAsFixed(2)} MB (${pct.toStringAsFixed(2)}%)',
          );
        });
        // ensure General tab is selected so user sees summary
        setState(() => _currentLogFolder = 'General');
      } else {
        _log('All done.');
      }
    } catch (e, st) {
      _log('Error: $e');
      _log(st.toString());
    } finally {
      setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              skipCjxl: _skipCjxl,
              onSkipCjxlChanged: (v) => setState(() => _skipCjxl = v ?? false),
              preferPermanentDelete: _preferPermanentDelete,
              onPreferPermanentDeleteChanged: (v) =>
                  setState(() => _preferPermanentDelete = v ?? false),
              safeRun: _safeRun,
              onSafeRunChanged: (v) => setState(() => _safeRun = v ?? false),
              outputExt: _outputExt,
              onOutputExtChanged: (v) =>
                  setState(() => _outputExt = v ?? '.cbz'),
              running: _running,
              onStart: _start,
            ),
            const SizedBox(height: 12),
            const Divider(),
            LogsPanel(
              logsByFolder: logsForPanel,
              selectedFolder: _currentLogFolder,
            ),
          ],
        ),
      ),
    );
  }
}
