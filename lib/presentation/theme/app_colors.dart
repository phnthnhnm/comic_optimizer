import 'package:material_ui/material_ui.dart';

import 'package:comic_optimizer/presentation/design_system/catppuccin.dart';

/// Static color utility for log line colors used in the logs panel.
abstract final class AppColors {
  static Color colorForLine(String line, BuildContext context) {
    final lc = line.toLowerCase();
    if (lc.contains('error') ||
        lc.contains('failed') ||
        lc.contains('err') ||
        (lc.contains('cjxl exit') && !lc.contains('exit 0'))) {
      return Catppuccin.red;
    }
    // Storage summary lines: color by percentage saved
    if (lc.contains('saved') && lc.contains('%')) {
      final reg = RegExp(r"\(([-+]?\d+(?:\.\d+)?)%\)");
      final m = reg.firstMatch(lc);
      if (m != null) {
        final pct = double.tryParse(m.group(1)!) ?? 0.0;
        if (pct >= 50.0) return Catppuccin.blue;
        if (pct >= 30.0) return Catppuccin.green;
        if (pct >= 0.0) return Catppuccin.yellow;
        return Catppuccin.red;
      }
    }
    if (lc.startsWith('done:') && lc.contains('ok')) {
      return Catppuccin.green;
    }
    if (lc.startsWith('start:')) {
      return Theme.of(context).colorScheme.primary;
    }
    if (lc.contains('removed') ||
        lc.contains('deleted') ||
        lc.contains('removed duplicate')) {
      return Catppuccin.peach;
    }
    if (lc.contains('created archive')) {
      return Catppuccin.green;
    }
    if (lc.contains('running cjxl') || lc.contains('created safe copy')) {
      return Catppuccin.teal;
    }
    return Theme.of(context).textTheme.bodyMedium?.color ??
        Theme.of(context).colorScheme.onSurface;
  }

  static FontWeight weightForLine(String line) {
    final lc = line.toLowerCase();
    if (lc.contains('error') || lc.contains('failed') || lc.contains('err')) {
      return FontWeight.w700;
    }
    if (lc.startsWith('start:') || lc.startsWith('done:')) {
      return FontWeight.w600;
    }
    return FontWeight.normal;
  }
}
