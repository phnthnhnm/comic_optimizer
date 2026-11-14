import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:comic_optimizer/domain/enums/collision_policy.dart';
import 'package:comic_optimizer/domain/enums/output_mode.dart';
import 'package:comic_optimizer/domain/enums/post_run_action.dart';
import 'package:comic_optimizer/domain/models/image_formats.dart';
import 'package:comic_optimizer/domain/models/preset.dart';
import 'package:comic_optimizer/features/settings/providers/settings_provider.dart';
import 'package:comic_optimizer/features/settings/widgets/settings_widgets.dart';
import 'package:comic_optimizer/features/tutorial/tutorial_dialog.dart';
import 'package:comic_optimizer/presentation/design_system/catppuccin.dart';

class GeneralSection extends ConsumerWidget {
  const GeneralSection({super.key});

  static const _actionLabels = <PostRunAction, String>{
    PostRunAction.none: 'Do nothing',
    PostRunAction.quit: 'Quit Comic Optimizer',
    PostRunAction.sleep: 'Sleep the PC',
    PostRunAction.hibernate: 'Hibernate the PC',
    PostRunAction.shutdown: 'Shut down the PC',
    PostRunAction.restart: 'Restart the PC',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final presetNames = [
      ...Preset.all.map((preset) => preset.name),
      ...settings.customPresets.map((preset) => preset.name),
    ];
    final selectedPreset = Preset.resolve(
      settings.lastPreset,
      settings.customPresets,
    ).name;
    final confirmSeconds = {
      10,
      30,
      60,
      120,
      settings.postRunConfirmSeconds,
    }.toList()..sort();

    return SettingsSection(
      title: 'General',
      subtitle: 'Defaults used when you start a run from the Library.',
      children: [
        SettingsCard(
          title: 'Defaults',
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: presetNames.contains(selectedPreset)
                    ? selectedPreset
                    : Preset.losslessName,
                decoration: const InputDecoration(
                  labelText: 'Quality preset',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                dropdownColor: Catppuccin.mantle,
                items: [
                  for (final name in presetNames)
                    DropdownMenuItem(value: name, child: Text(name)),
                ],
                onChanged: (value) {
                  if (value != null) notifier.setLastPreset(value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: settings.outputExt,
                decoration: const InputDecoration(
                  labelText: 'Archive format',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                dropdownColor: Catppuccin.mantle,
                items: [
                  for (final ext in kOutputExtensions)
                    DropdownMenuItem(value: ext, child: Text(ext)),
                ],
                onChanged: (value) {
                  if (value != null) notifier.setOutputExt(value);
                },
              ),
            ],
          ),
        ),
        SettingsCard(
          title: 'After a run finishes',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<PostRunAction>(
                initialValue: settings.postRunAction,
                decoration: const InputDecoration(
                  labelText: 'Action',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                dropdownColor: Catppuccin.mantle,
                items: [
                  for (final action in PostRunAction.values)
                    DropdownMenuItem(
                      value: action,
                      child: Text(_actionLabels[action] ?? action.toName),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) notifier.setPostRunAction(value);
                },
              ),
              const SizedBox(height: 8),
              SettingsSwitchRow(
                title: 'Confirm before the action',
                subtitle: 'Shows a countdown so you can cancel the shutdown or sleep.',
                value: settings.postRunConfirmEnabled,
                onChanged: notifier.setPostRunConfirmEnabled,
              ),
              if (settings.postRunConfirmEnabled)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      const Text('Countdown', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 12),
                      DropdownButton<int>(
                        value: settings.postRunConfirmSeconds,
                        underline: const SizedBox.shrink(),
                        dropdownColor: Catppuccin.mantle,
                        items: [
                          for (final seconds in confirmSeconds)
                            DropdownMenuItem(
                              value: seconds,
                              child: Text('$seconds s'),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            notifier.setPostRunConfirmSeconds(value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SettingsCard(
          title: 'Output',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<OutputMode>(
                initialValue: settings.outputMode,
                decoration: const InputDecoration(
                  labelText: 'Archive location',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                dropdownColor: Catppuccin.mantle,
                items: const [
                  DropdownMenuItem(
                    value: OutputMode.besideSource,
                    child: Text('Beside the source folder'),
                  ),
                  DropdownMenuItem(
                    value: OutputMode.custom,
                    child: Text('Custom folder'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) notifier.setOutputMode(value);
                },
              ),
              if (settings.outputMode == OutputMode.custom) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: settings.outputDirectory,
                        decoration: const InputDecoration(
                          labelText: 'Output folder',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: notifier.setOutputDirectory,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () async {
                        final directory = await FilePicker.getDirectoryPath(
                          dialogTitle: 'Choose an output folder',
                        );
                        if (directory != null) {
                          await notifier.setOutputDirectory(directory);
                        }
                      },
                      child: const Text('Browse'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                initialValue: settings.namingTemplate,
                decoration: const InputDecoration(
                  labelText: 'Archive name',
                  helperText:
                      'Tokens: {folder}, {library}, {preset}, {date}, {index}',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: notifier.setNamingTemplate,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CollisionPolicy>(
                initialValue: settings.collisionPolicy,
                decoration: const InputDecoration(
                  labelText: 'If the archive already exists',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                dropdownColor: Catppuccin.mantle,
                items: const [
                  DropdownMenuItem(
                    value: CollisionPolicy.overwrite,
                    child: Text('Overwrite'),
                  ),
                  DropdownMenuItem(
                    value: CollisionPolicy.skip,
                    child: Text('Skip'),
                  ),
                  DropdownMenuItem(
                    value: CollisionPolicy.suffix,
                    child: Text('Add a numeric suffix'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) notifier.setCollisionPolicy(value);
                },
              ),
              const SizedBox(height: 4),
              SettingsSwitchRow(
                title: 'Skip up-to-date archives',
                subtitle: 'Ignore comics whose archive is newer than the source folder.',
                value: settings.skipExistingArchives,
                onChanged: notifier.setSkipExistingArchives,
              ),
            ],
          ),
        ),
        SettingsCard(
          title: 'Performance',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                initialValue: settings.maxParallelEncodes.clamp(1, 4),
                decoration: const InputDecoration(
                  labelText: 'Parallel encoders',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                dropdownColor: Catppuccin.mantle,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 (sequential)')),
                  DropdownMenuItem(value: 2, child: Text('2')),
                  DropdownMenuItem(value: 3, child: Text('3')),
                  DropdownMenuItem(value: 4, child: Text('4')),
                ],
                onChanged: (value) {
                  if (value != null) notifier.setMaxParallelEncodes(value);
                },
              ),
              SettingsSwitchRow(
                title: 'Prevent sleep while running',
                subtitle: 'Keep the PC awake until the queue finishes.',
                value: settings.preventSleep,
                onChanged: notifier.setPreventSleep,
              ),
            ],
          ),
        ),
        SettingsCard(
          title: 'Getting started',
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'New here, or want a refresher? Replay the short welcome tour.',
                  style: TextStyle(fontSize: 11.5, color: Catppuccin.overlay2),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => showTutorial(context, ref),
                icon: const Icon(Icons.school_outlined, size: 17),
                label: const Text('Show tutorial'),
              ),
            ],
          ),
        ),
        SettingsCard(
          title: 'Motion',
          child: SettingsSwitchRow(
            title: 'Enable animations',
            subtitle:
                'Page and view transitions, tutorials, and selection motion. '
                'Turn off if motion feels distracting.',
            value: settings.animationsEnabled,
            onChanged: notifier.setAnimationsEnabled,
          ),
        ),
      ],
    );
  }
}
