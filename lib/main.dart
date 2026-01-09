import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'optimizer.dart';
import 'presets.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comic Optimizer',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const HomePage(),
    );
  }
}

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

    // confirm destructive action
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
      appBar: AppBar(title: const Text('Comic Optimizer')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text(_rootPath ?? 'No root selected')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _pickRoot,
                  child: const Text('Choose Root'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Preset: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedPreset,
                  items: Preset.all
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.name,
                          child: Text(p.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(
                    () => _selectedPreset = v ?? Preset.losslessName,
                  ),
                ),
                const SizedBox(width: 16),
                Checkbox(
                  value: _skipPingo,
                  onChanged: (v) => setState(() => _skipPingo = v ?? false),
                ),
                const Text('Skip pingo'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Pingo path: '),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: _pingoPath),
                    onChanged: (v) => _pingoPath = v,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Output ext: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _outputExt,
                  items: ['.cbz', '.zip']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _outputExt = v ?? '.cbz'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _running ? null : _start,
                  child: Text(_running ? 'Running...' : 'Start'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (c, i) => Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Text(_logs[i]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
