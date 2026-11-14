import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:comic_optimizer/domain/enums/post_run_action.dart';
import 'package:comic_optimizer/domain/models/app_settings.dart';
import 'package:comic_optimizer/domain/models/custom_preset.dart';
import 'package:comic_optimizer/domain/models/image_formats.dart';
import 'package:comic_optimizer/domain/models/library_entry.dart';
import 'package:comic_optimizer/domain/models/preset.dart';
import 'package:comic_optimizer/features/home/providers/optimization_provider.dart';
import 'package:comic_optimizer/features/home/run_launcher.dart';
import 'package:comic_optimizer/features/home/widgets/archive_import_dialog.dart';
import 'package:comic_optimizer/features/home/widgets/library_overrides_dialog.dart';
import 'package:comic_optimizer/features/settings/providers/settings_provider.dart';
import 'package:comic_optimizer/presentation/design_system/app_theme.dart';
import 'package:comic_optimizer/presentation/design_system/catppuccin.dart';

/// Short, human descriptions for the encoder presets.
const _presetCopy = <String, (String, String)>{
  Preset.losslessName: ('Lossless', 'Perfect quality, largest files'),
  Preset.visuallyLosslessName: (
    'Visually lossless',
    'Recommended · identical to the eye',
  ),
  Preset.lossyName: ('Smaller files', 'Lossy · smallest output'),
};

/// The Library home: optimization queue, quality preset and run options.
class LibraryPanel extends ConsumerWidget {
  final VoidCallback onStart;

  const LibraryPanel({super.key, required this.onStart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final run = ref.watch(optimizationProvider);
    final runNotifier = ref.read(optimizationProvider.notifier);
    final roots = settings.libraries;
    final preset = Preset.resolve(settings.lastPreset, settings.customPresets);
    final presets = [
      ...Preset.all,
      for (final custom in settings.customPresets)
        Preset(name: custom.name, args: custom.args),
    ];

    return DropTarget(
      onDragDone: (details) => _handleDrop(
        context,
        settingsNotifier,
        settings.libraries,
        details.files.map((file) => file.path).toList(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Optimization queue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Folders are processed in order. Add as many libraries as you need.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Catppuccin.overlay1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Tooltip(
                message: 'Import .cbz or .zip archives',
                child: OutlinedButton.icon(
                  onPressed: () => showArchiveImportDialog(context, ref),
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: const Text('Import'),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Add folder (Ctrl+O)',
                child: FilledButton.tonalIcon(
                  onPressed: () => _addRoot(context, ref),
                  icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                  label: const Text('Add folder'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _QueueCard(
            roots: roots,
            onRemove: (root) async {
              await settingsNotifier.removeLibraryRoot(root);
            },
            onEdit: (entry) async {
              final edited = await showDialog<LibraryEntry>(
                context: context,
                builder: (_) => LibraryOverridesDialog(
                  entry: entry,
                  settings: settings,
                  presetNames: presets.map((preset) => preset.name).toList(),
                ),
              );
              if (edited == null) return;
              final updated = roots
                  .map((item) => item.path == edited.path ? edited : item)
                  .toList();
              await settingsNotifier.setLibraries(updated);
            },
            onReorder: (oldIndex, newIndex) {
              final updated = List<LibraryEntry>.from(roots);
              final moved = updated.removeAt(oldIndex);
              updated.insert(newIndex, moved);
              settingsNotifier.setLibraries(updated);
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'Quality preset',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          _PresetStrip(
            presets: presets,
            selectedName: preset.name,
            subtitleFor: (item) =>
                _presetSubtitle(item, settings.customPresets),
            onSelected: settingsNotifier.setLastPreset,
          ),
          const SizedBox(height: AppSpacing.xl),
          _OptionsCard(settings: settings, settingsNotifier: settingsNotifier),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  roots.isEmpty
                      ? 'Add a folder to get started'
                      : '${roots.length} ${roots.length == 1 ? 'library' : 'libraries'} · ${preset.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Catppuccin.overlay1,
                  ),
                ),
              ),
              if (run.running) ...[
                FilledButton.tonal(
                  onPressed: run.paused
                      ? runNotifier.resume
                      : runNotifier.pause,
                  child: Text(run.paused ? 'Resume' : 'Pause'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: runNotifier.cancel,
                  child: const Text('Cancel'),
                ),
              ] else
                Tooltip(
                  message: 'Start (Ctrl+Enter)',
                  child: FilledButton.icon(
                    onPressed: roots.isEmpty ? null : onStart,
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text('Start'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleDrop(
    BuildContext context,
    SettingsNotifier notifier,
    List<LibraryEntry> current,
    List<String> paths,
  ) async {
    final existing = current.map((entry) => entry.path).toSet();
    var added = 0;
    for (final path in paths) {
      if (!await Directory(path).exists()) continue;
      if (existing.contains(path)) continue;
      await notifier.addLibraryEntry(LibraryEntry(path: path));
      existing.add(path);
      added++;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added == 0
              ? 'No new folders were added.'
              : 'Added $added ${added == 1 ? 'folder' : 'folders'} to the queue.',
        ),
      ),
    );
  }

  Future<void> _addRoot(BuildContext context, WidgetRef ref) =>
      addLibraryFolder(context, ref);
}

class _QueueCard extends StatelessWidget {
  final List<LibraryEntry> roots;
  final ValueChanged<String> onRemove;
  final ValueChanged<LibraryEntry> onEdit;
  final ReorderCallback onReorder;

  const _QueueCard({
    required this.roots,
    required this.onRemove,
    required this.onEdit,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Catppuccin.mantle,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Catppuccin.surface0),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: roots.isEmpty
          ? const _QueueEmpty()
          : ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: roots.length,
              onReorderItem: onReorder,
              itemBuilder: (context, index) {
                final root = roots[index];
                return _QueueTile(
                  key: ValueKey(root.path),
                  root: root,
                  index: index,
                  onRemove: () => onRemove(root.path),
                  onEdit: () => onEdit(root),
                );
              },
            ),
    );
  }
}

class _QueueEmpty extends StatelessWidget {
  const _QueueEmpty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 26),
      child: Column(
        children: [
          Icon(Icons.folder_open_rounded, size: 28, color: Catppuccin.overlay1),
          SizedBox(height: 8),
          Text(
            'No folders queued yet',
            style: TextStyle(
              color: Catppuccin.subtext0,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Use “Add folder” to choose a comic library.',
            style: TextStyle(fontSize: 12, color: Catppuccin.overlay1),
          ),
        ],
      ),
    );
  }
}

class _QueueTile extends StatelessWidget {
  final LibraryEntry root;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onEdit;

  const _QueueTile({
    super.key,
    required this.root,
    required this.index,
    required this.onRemove,
    required this.onEdit,
  });

  bool get _hasOverrides =>
      root.preset != null ||
      root.outputDirectory != null ||
      root.safeRunOverride != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.only(left: 6, right: 2),
      decoration: BoxDecoration(
        color: Catppuccin.base,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Catppuccin.surface1),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Icon(
                Icons.drag_indicator_rounded,
                size: 18,
                color: Catppuccin.overlay1,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.folder_outlined, size: 17, color: Catppuccin.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              root.path,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, color: Catppuccin.text),
            ),
          ),
          if (_hasOverrides)
            const Tooltip(
              message: 'This library has custom settings',
              child: Icon(
                Icons.tune_rounded,
                size: 15,
                color: Catppuccin.green,
              ),
            ),
          IconButton(
            onPressed: onEdit,
            tooltip: 'Library settings',
            visualDensity: VisualDensity.compact,
            iconSize: 16,
            icon: const Icon(
              Icons.settings_outlined,
              color: Catppuccin.overlay1,
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: 'Remove from queue',
            visualDensity: VisualDensity.compact,
            iconSize: 16,
            icon: const Icon(Icons.close_rounded, color: Catppuccin.overlay1),
          ),
        ],
      ),
    );
  }
}

class _PresetStrip extends StatefulWidget {
  final List<Preset> presets;
  final String selectedName;
  final String Function(Preset) subtitleFor;
  final ValueChanged<String> onSelected;

  const _PresetStrip({
    required this.presets,
    required this.selectedName,
    required this.subtitleFor,
    required this.onSelected,
  });

  @override
  State<_PresetStrip> createState() => _PresetStripState();
}

class _PresetStripState extends State<_PresetStrip> {
  final Map<String, GlobalKey> _keys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
  }

  @override
  void didUpdateWidget(covariant _PresetStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedName != widget.selectedName) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
    }
  }

  void _revealSelected() {
    final context = _keys[widget.selectedName]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      alignment: 0.5,
      duration: MediaQuery.of(context).disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final preset in widget.presets)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: KeyedSubtree(
                key: _keys.putIfAbsent(preset.name, GlobalKey.new),
                child: SizedBox(
                  width: 186,
                  child: _PresetCard(
                    preset: preset,
                    subtitle: widget.subtitleFor(preset),
                    selected: widget.selectedName == preset.name,
                    onTap: () => widget.onSelected(preset.name),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _presetSubtitle(Preset preset, List<CustomPreset> customPresets) {
  final copy = _presetCopy[preset.name];
  if (copy != null) return copy.$2;
  for (final custom in customPresets) {
    if (custom.name == preset.name) return custom.description;
  }
  return '';
}

class _PresetCard extends StatelessWidget {
  final Preset preset;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PresetCard({
    required this.preset,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = _presetCopy[preset.name]?.$1 ?? preset.name;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: MediaQuery.of(context).disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 140),
          height: 88,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? Catppuccin.surface0 : Catppuccin.mantle,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? Catppuccin.green : Catppuccin.surface1,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: selected ? Catppuccin.green : Catppuccin.text,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: Catppuccin.green,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.25,
                  color: Catppuccin.overlay2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionsCard extends StatelessWidget {
  final AppSettings settings;
  final SettingsNotifier settingsNotifier;

  const _OptionsCard({required this.settings, required this.settingsNotifier});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Catppuccin.mantle,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Catppuccin.surface0),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Archive format',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              DropdownButton<String>(
                value: settings.outputExt,
                underline: const SizedBox.shrink(),
                style: const TextStyle(color: Catppuccin.text, fontSize: 13),
                dropdownColor: Catppuccin.mantle,
                items: kOutputExtensions
                    .map(
                      (ext) => DropdownMenuItem(value: ext, child: Text(ext)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) settingsNotifier.setOutputExt(value);
                },
              ),
            ],
          ),
          const Divider(height: 16),
          _OptionRow(
            title: 'Encode to JPEG XL',
            subtitle: 'Run cjxl before archiving',
            value: !settings.skipCjxl,
            onChanged: (value) => settingsNotifier.setSkipCjxl(!value),
          ),
          _OptionRow(
            title: 'Delete non-image files',
            subtitle: 'Removes ComicInfo.xml, .nfo, .txt and similar files',
            value: settings.deleteNonImageFiles,
            onChanged: (value) =>
                settingsNotifier.setDeleteNonImageFiles(value),
          ),
          _OptionRow(
            title: 'Keep originals',
            subtitle: 'Work on a copy and leave the source folders untouched',
            value: settings.safeRun,
            onChanged: (value) => settingsNotifier.setSafeRun(value),
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            shape: const Border(),
            collapsedShape: const Border(),
            iconColor: Catppuccin.subtext0,
            collapsedIconColor: Catppuccin.overlay1,
            title: const Text(
              'Advanced',
              style: TextStyle(fontSize: 13, color: Catppuccin.subtext0),
            ),
            children: [
              _OptionRow(
                title: 'Delete originals permanently',
                subtitle: 'Skip the Recycle Bin after a successful archive',
                value: settings.preferPermanentDelete,
                onChanged: (value) =>
                    settingsNotifier.setPreferPermanentDelete(value),
              ),
              Row(
                children: [
                  const Text('After finish', style: TextStyle(fontSize: 12.5)),
                  const SizedBox(width: 12),
                  DropdownButton<PostRunAction>(
                    value: settings.postRunAction,
                    underline: const SizedBox.shrink(),
                    style: const TextStyle(
                      color: Catppuccin.text,
                      fontSize: 12.5,
                    ),
                    dropdownColor: Catppuccin.mantle,
                    items: PostRunAction.values
                        .map(
                          (action) => DropdownMenuItem(
                            value: action,
                            child: Text(action.toName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        settingsNotifier.setPostRunAction(value);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _OptionRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Catppuccin.overlay2,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}
