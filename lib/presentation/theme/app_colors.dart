import 'package:flutter/material.dart';

/// Static color utility for log line colors used in the logs panel.
abstract final class AppColors {
  AppColors._();

  static Color colorForLine(String line, BuildContext context) {
    final lc = line.toLowerCase();
    if (lc.contains('error') ||
        lc.contains('failed') ||
        lc.contains('err') ||
        (lc.contains('cjxl exit') && !lc.contains('exit 0'))) {
      return Colors.redAccent;
    }
    // Storage summary lines: color by percentage saved
    if (lc.contains('saved') && lc.contains('%')) {
      final reg = RegExp(r"\(([-+]?\d+(?:\.\d+)?)%\)");
      final m = reg.firstMatch(lc);
      if (m != null) {
        final pct = double.tryParse(m.group(1)!) ?? 0.0;
        if (pct >= 50.0) return Colors.blueAccent;
        if (pct >= 30.0) return Colors.greenAccent;
        if (pct >= 0.0) return Colors.amberAccent.shade700;
        return Colors.redAccent;
      }
    }
    if (lc.startsWith('done:') && lc.contains('ok')) {
      return Colors.greenAccent.shade200;
    }
    if (lc.startsWith('start:')) {
      return Theme.of(context).colorScheme.primary.withAlpha(220);
    }
    if (lc.contains('removed') ||
        lc.contains('deleted') ||
        lc.contains('removed duplicate')) {
      return Colors.orangeAccent;
    }
    if (lc.contains('created archive')) {
      return Colors.greenAccent;
    }
    if (lc.contains('running cjxl') || lc.contains('created safe copy')) {
      return Colors.cyanAccent;
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
