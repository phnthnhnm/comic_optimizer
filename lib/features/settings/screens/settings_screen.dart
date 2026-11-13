import 'package:material_ui/material_ui.dart';

import 'package:comic_optimizer/features/settings/screens/about_tab.dart';
import 'package:comic_optimizer/features/settings/screens/data_tab.dart';
import 'package:comic_optimizer/features/settings/sections/encoding_section.dart';
import 'package:comic_optimizer/features/settings/sections/general_section.dart';
import 'package:comic_optimizer/features/settings/sections/presets_section.dart';
import 'package:comic_optimizer/features/settings/sections/safety_section.dart';
import 'package:comic_optimizer/presentation/design_system/catppuccin.dart';

enum SettingsSectionId {
  general('General', Icons.tune_rounded),
  encoding('Encoding', Icons.memory_rounded),
  presets('Presets', Icons.auto_awesome_rounded),
  safety('Safety', Icons.shield_outlined),
  data('Data', Icons.storage_rounded),
  about('About', Icons.info_outline_rounded);

  final String label;
  final IconData icon;

  const SettingsSectionId(this.label, this.icon);
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SettingsSectionId _selected = SettingsSectionId.general;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 24, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 190,
              child: _SettingsNav(
                selected: _selected,
                onSelected: (section) => setState(() => _selected = section),
              ),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: SingleChildScrollView(
                child: switch (_selected) {
                  SettingsSectionId.general => const GeneralSection(),
                  SettingsSectionId.encoding => const EncodingSection(),
                  SettingsSectionId.presets => const PresetsSection(),
                  SettingsSectionId.safety => const SafetySection(),
                  SettingsSectionId.data => const DataTab(),
                  SettingsSectionId.about => const AboutTab(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsNav extends StatelessWidget {
  final SettingsSectionId selected;
  final ValueChanged<SettingsSectionId> onSelected;

  const _SettingsNav({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Text(
            'SETTINGS',
            style: TextStyle(
              color: Catppuccin.overlay1,
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        for (final section in SettingsSectionId.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: _NavItem(
              section: section,
              selected: section == selected,
              onTap: () => onSelected(section),
            ),
          ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final SettingsSectionId section;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? Catppuccin.surface0 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                section.icon,
                size: 17,
                color: selected ? Catppuccin.green : Catppuccin.overlay1,
              ),
              const SizedBox(width: 9),
              Text(
                section.label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? Catppuccin.text : Catppuccin.subtext0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
