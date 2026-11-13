import 'package:material_ui/material_ui.dart';

import 'package:comic_optimizer/presentation/design_system/app_theme.dart';
import 'package:comic_optimizer/presentation/design_system/catppuccin.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Catppuccin.overlay1),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final child in children) ...[child, const SizedBox(height: 12)],
      ],
    );
  }
}

class SettingsCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget child;

  const SettingsCard({
    super.key,
    this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Catppuccin.mantle,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Catppuccin.surface0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Catppuccin.overlay2,
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class SettingsSwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchRow({
    super.key,
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
                    style: const TextStyle(
                      fontSize: 11,
                      color: Catppuccin.overlay2,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class SettingsInfo extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const SettingsInfo({
    super.key,
    required this.icon,
    required this.text,
    this.color = Catppuccin.overlay1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              color: Catppuccin.overlay1,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
