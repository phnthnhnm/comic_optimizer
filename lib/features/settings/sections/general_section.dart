import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:comic_optimizer/domain/enums/post_run_action.dart';
import 'package:comic_optimizer/domain/models/image_formats.dart';
import 'package:comic_optimizer/domain/models/preset.dart';
import 'package:comic_optimizer/features/settings/providers/settings_provider.dart';
import 'package:comic_optimizer/features/settings/widgets/settings_widgets.dart';
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
      ],
    );
  }
}
