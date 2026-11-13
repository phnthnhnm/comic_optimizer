import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../design_system/app_theme.dart';
import '../design_system/catppuccin.dart';

/// Persistent application frame: brand and navigation on the left, content on
/// the right.
class AppShell extends StatelessWidget {
  final String location;
  final Widget child;

  const AppShell({super.key, required this.location, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Catppuccin.base,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Sidebar(location: location),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final String location;

  const _Sidebar({required this.location});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Catppuccin.mantle,
      child: Container(
        width: 232,
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: Catppuccin.surface0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Brand(),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 6),
              child: Text(
                'WORKSPACE',
                style: TextStyle(
                  color: Catppuccin.overlay1,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _NavItem(
              label: 'Library',
              icon: Icons.grid_view_rounded,
              selected: location == '/',
              onTap: () => context.go('/'),
            ),
            _NavItem(
              label: 'Settings',
              icon: Icons.tune_rounded,
              selected: location.startsWith('/settings'),
              onTap: () => context.go('/settings'),
            ),
            const Spacer(),
            const _SidebarFooter(),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Catppuccin.green,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.photo_library_rounded,
              size: 18,
              color: Catppuccin.base,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Comic Optimizer',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Catppuccin.text,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Catppuccin.green : Catppuccin.subtext0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          hoverColor: Catppuccin.surface0.withAlpha(140),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? Catppuccin.surface0 : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Catppuccin.text : Catppuccin.subtext0,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final version = snapshot.data?.version;
          return Text(
            version == null ? '' : 'Version $version',
            style: const TextStyle(color: Catppuccin.overlay0, fontSize: 11),
          );
        },
      ),
    );
  }
}
