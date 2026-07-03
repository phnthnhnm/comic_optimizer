import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/optimizer.dart';
import '../core/utils.dart';
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
  PostRunAction _postRunAction = PostRunAction.none;
  bool _postRunConfirmEnabled = true;
  int _postRunConfirmSeconds = 60;
  dynamic _logs = {};
  String? _currentLogFolder;
  bool _running = false;
  bool _starting = false;
  bool _paused = false;
  Optimizer? _currentOptimizer;
  final Map<String, Map<String, int?>> _folderSizes = {};
  final Map<String, Map<String, Map<String, int?>>> _perFileSizes = {};

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
        _postRunAction = model.postRunAction;
        _postRunConfirmEnabled = model.postRunConfirmEnabled;
        _postRunConfirmSeconds = model.postRunConfirmSeconds;
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
    await model.setPostRunAction(_postRunAction);
    await model.setPostRunConfirmEnabled(_postRunConfirmEnabled);
    await model.setPostRunConfirmSeconds(_postRunConfirmSeconds);
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
    final result = await FilePicker.getDirectoryPath();
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
      _starting = true;
      _folderSizes.clear();
    });

    final preset = Preset.byName(_selectedPreset);
    final presetArgs = preset.args;

    final optimizer = Optimizer(
      onLog: (s) => _log(s),
      onFolderStart: (f) {
        _log('Start: $f', folder: f);
        setState(() {
          _currentLogFolder = f;
          _starting = false;
        });
      },
      onFolderDone: (f, ok, beforeBytes, afterBytes, perFileSizes) async {
        _folderSizes[f] = {'before': beforeBytes, 'after': afterBytes};
        if (perFileSizes != null) {
          _perFileSizes[f] = perFileSizes.map(
            (k, v) => MapEntry(k, Map<String, int?>.from(v)),
          );
        }
        _log('Done: $f (${ok ? 'OK' : 'ERR'})', folder: f);
        setState(() => _currentLogFolder = null);

        // Also log a per-folder storage summary immediately into that folder's
        // own log tab so users can see saved space per-folder as it completes.
        try {
          final name = p.basename(f);
          final summary = storageSummaryText(
            folderName: name,
            beforeBytes: beforeBytes,
            afterBytes: afterBytes,
            includeFolderName: false,
          );
          _log(summary, folder: f);
        } catch (_) {}

        try {
          final model = context.read<SettingsModel>();
          final level = model.logLevel;
          if (level == LogLevel.none) return;

          final Map<String, List<String>> logsForPanel = {};
          if (_logs is Map<String, List<String>>) {
            logsForPanel.addAll(_logs as Map<String, List<String>>);
          } else if (_logs is List<String>) {
            logsForPanel['General'] = List<String>.from(_logs as List<String>);
          }

          final lines = logsForPanel[f];
          if (lines == null || lines.isEmpty) return;

          // Determine if any error occurred during processing of this folder.
          var hadError = false;
          for (final ln in lines) {
            final l = ln.toLowerCase();
            if (l.contains('cjxl retry exit') || l.contains('cjxl exit')) {
              if (!l.contains('exit 0')) hadError = true;
            } else if (l.contains('error') ||
                l.contains('failed') ||
                l.contains('err')) {
              hadError = true;
            }
          }

          // Also consider storage not saved (0% or negative) as an error condition
          var hadBadStorage = false;
          try {
            if (beforeBytes != null && afterBytes != null && beforeBytes > 0) {
              final pct = ((beforeBytes - afterBytes) / beforeBytes) * 100.0;
              if (pct <= 0.0) hadBadStorage = true;
            }
          } catch (_) {}

          if (level == LogLevel.error && !hadError && !hadBadStorage) return;

          final appData = Platform.environment['APPDATA'] ?? '';
          if (appData.isEmpty) return;
          final logsDir = p.join(
            appData,
            'com.phanthanhnam',
            'comic_optimizer',
            'logs',
          );
          try {
            await Directory(logsDir).create(recursive: true);
            final iso = DateTime.now().toIso8601String().replaceAll(':', '-');
            final filename = '${p.basename(f)}_$iso.log';
            final file = File(p.join(logsDir, filename));
            await file.writeAsString(lines.join('\n'));
          } catch (e) {
            // ignore file write errors but log them
            _log('Failed to write log file for ${p.basename(f)}: $e');
          }
        } catch (e) {
          _log('Error while attempting to write log file: $e');
        }
      },
    );
    _currentOptimizer = optimizer;

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
          final summary = storageSummaryText(
            folderName: name,
            beforeBytes: before,
            afterBytes: after,
            includeFolderName: true,
          );
          _log(summary);
        });
        // ensure General tab is selected so user sees summary
        setState(() => _currentLogFolder = 'General');
      } else {
        _log('All done.');
      }
      // perform configured post-run action (may show confirm dialog)
      await _maybePerformPostRunAction();
    } catch (e, st) {
      _log('Error: $e');
      _log(st.toString());
    } finally {
      setState(() {
        _running = false;
        _starting = false;
        _paused = false;
        _currentOptimizer = null;
      });
    }
  }

  void _cancel() {
    if (_currentOptimizer != null) {
      _currentOptimizer!.cancel();
      setState(() => _paused = false);
    }
  }

  void _pause() {
    if (_currentOptimizer != null) {
      _currentOptimizer!.pause();
      setState(() => _paused = true);
    }
  }

  void _resume() {
    if (_currentOptimizer != null) {
      _currentOptimizer!.resume();
      setState(() => _paused = false);
    }
  }

  Future<void> _maybePerformPostRunAction() async {
    final model = context.read<SettingsModel>();
    final action = model.postRunAction;
    if (action == PostRunAction.none) return;

    Future<bool> confirmDialog(int seconds) async {
      var remaining = seconds;
      Timer? timer;
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (c) {
          return StatefulBuilder(
            builder: (c2, setState2) {
              timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
                remaining -= 1;
                if (remaining <= 0) {
                  timer?.cancel();
                  Navigator.of(c2).pop(true);
                } else {
                  setState2(() {});
                }
              });
              return AlertDialog(
                title: const Text('Post-run action'),
                content: Text(
                  'The system will perform "$action" in $remaining seconds. Cancel to abort.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      timer?.cancel();
                      Navigator.of(c2).pop(false);
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      timer?.cancel();
                      Navigator.of(c2).pop(true);
                    },
                    child: const Text('Proceed Now'),
                  ),
                ],
              );
            },
          );
        },
      );
      timer?.cancel();
      return result == true;
    }

    final confirmEnabled = model.postRunConfirmEnabled;
    final seconds = model.postRunConfirmSeconds;
    var ok = true;
    if (confirmEnabled) {
      ok = await confirmDialog(seconds);
    }
    if (!ok) {
      _log('Post-run action cancelled by user.');
      return;
    }
    await _performPostRunAction(action);
  }

  Future<void> _performPostRunAction(PostRunAction action) async {
    _log('Performing post-run action: $action');
    try {
      switch (action) {
        case PostRunAction.quit:
          _log('Quitting app...');
          await Future.delayed(const Duration(milliseconds: 200));
          exit(0);
        case PostRunAction.shutdown:
          _log('Shutting down...');
          await Process.run('shutdown', ['/s', '/t', '0']);
          break;
        case PostRunAction.restart:
          _log('Restarting...');
          await Process.run('shutdown', ['/r', '/t', '0']);
          break;
        case PostRunAction.hibernate:
          _log('Hibernating...');
          await Process.run('shutdown', ['/h']);
          break;
        case PostRunAction.sleep:
          _log('Sleeping...');
          await Process.run('rundll32.exe', [
            'powrprof.dll,SetSuspendState',
            '0,1,0',
          ]);
          break;
        case PostRunAction.none:
          break;
      }
    } catch (e) {
      _log('Failed to perform post-run action: $e');
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
              postRunAction: _postRunAction,
              onPostRunActionChanged: (v) =>
                  setState(() => _postRunAction = v ?? PostRunAction.none),
              postRunConfirmEnabled: _postRunConfirmEnabled,
              onPostRunConfirmEnabledChanged: (v) =>
                  setState(() => _postRunConfirmEnabled = v ?? true),
              postRunConfirmSeconds: _postRunConfirmSeconds,
              onPostRunConfirmSecondsChanged: (v) =>
                  setState(() => _postRunConfirmSeconds = v ?? 60),
              running: _running,
              paused: _paused,
              starting: _starting,
              onStart: _start,
              onCancel: _cancel,
              onPause: _pause,
              onResume: _resume,
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
