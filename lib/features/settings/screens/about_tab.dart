import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:comic_optimizer/features/settings/widgets/settings_widgets.dart';
import 'package:comic_optimizer/presentation/design_system/catppuccin.dart';

class _ShortcutRow extends StatelessWidget {
  final String keys;
  final String action;

  const _ShortcutRow({required this.keys, required this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              keys,
              style: const TextStyle(
                fontSize: 11.5,
                fontFamily: 'monospace',
                color: Catppuccin.subtext0,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(action, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

class AboutTab extends StatelessWidget {
  const AboutTab({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.hasData ? snapshot.data!.version : '…';
        return SettingsSection(
          title: 'About',
          subtitle: 'Comic Optimizer converts comic libraries to JPEG XL.',
          children: [
            SettingsCard(
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Catppuccin.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: Catppuccin.base,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Comic Optimizer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Version $version',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Catppuccin.overlay1,
                          ),
                        ),
                        Text(
                          'Copyright © ${DateTime.now().year} Phan Thành Nam',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Catppuccin.overlay2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SettingsCard(
              title: 'Source code',
              child: InkWell(
                onTap: () async {
                  final url = Uri.parse(
                    'https://github.com/phnthnhnm/comic_optimizer',
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 15,
                        color: Catppuccin.blue,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'github.com/phnthnhnm/comic_optimizer',
                        style: TextStyle(
                          fontSize: 12,
                          color: Catppuccin.blue,
                          decoration: TextDecoration.underline,
                          decorationColor: Catppuccin.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SettingsCard(
              title: 'Keyboard shortcuts',
              child: Column(
                children: [
                  _ShortcutRow(keys: 'Ctrl+O', action: 'Add a library folder'),
                  _ShortcutRow(keys: 'Ctrl+Enter', action: 'Start a run'),
                  _ShortcutRow(keys: 'Ctrl+P', action: 'Pause or resume'),
                  _ShortcutRow(keys: 'Ctrl+E', action: 'Export the run report'),
                  _ShortcutRow(keys: 'Ctrl+1', action: 'Open Library'),
                  _ShortcutRow(keys: 'Ctrl+2', action: 'Open History'),
                  _ShortcutRow(keys: 'Ctrl+,', action: 'Open Settings'),
                ],
              ),
            ),
            const SettingsCard(
              title: 'Built with',
              child: SettingsInfo(
                icon: Icons.code_rounded,
                text:
                    'Flutter, Riverpod, go_router, cjxl (libjxl), ImageMagick '
                    'and dwebp. JPEG XL encoding is performed by the external '
                    'cjxl binary.',
              ),
            ),
          ],
        );
      },
    );
  }
}
