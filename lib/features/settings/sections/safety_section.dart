import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:comic_optimizer/features/settings/providers/settings_provider.dart';
import 'package:comic_optimizer/features/settings/widgets/settings_widgets.dart';
import 'package:comic_optimizer/presentation/design_system/catppuccin.dart';

class SafetySection extends ConsumerWidget {
  const SafetySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return SettingsSection(
      title: 'Safety',
      subtitle:
          'These defaults apply to new runs and can be changed in preflight.',
      children: [
        SettingsCard(
          child: Column(
            children: [
              SettingsSwitchRow(
                title: 'Keep originals',
                subtitle: 'Process a copy of each folder and leave the source untouched.',
                value: settings.safeRun,
                onChanged: notifier.setSafeRun,
              ),
              const Divider(height: 16),
              SettingsSwitchRow(
                title: 'Delete non-image files',
                subtitle: 'Remove ComicInfo.xml, .nfo, .txt and similar files before archiving.',
                value: settings.deleteNonImageFiles,
                onChanged: notifier.setDeleteNonImageFiles,
              ),
              const Divider(height: 16),
              SettingsSwitchRow(
                title: 'Delete originals permanently',
                subtitle:
                    'Skip the Recycle Bin once an archive has been created.',
                value: settings.preferPermanentDelete,
                onChanged: notifier.setPreferPermanentDelete,
              ),
            ],
          ),
        ),
        const SettingsCard(
          child: SettingsInfo(
            icon: Icons.warning_amber_rounded,
            color: Catppuccin.yellow,
            text:
                'Comic Optimizer replaces page images with .jxl versions and '
                'deletes comic folders after archiving. Keep originals on for '
                'the first run on a new library.',
          ),
        ),
      ],
    );
  }
}
