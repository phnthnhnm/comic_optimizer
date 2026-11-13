import 'package:material_ui/material_ui.dart';

import 'package:comic_optimizer/domain/enums/run_log_level.dart';
import 'package:comic_optimizer/presentation/design_system/catppuccin.dart';

/// Colours for structured run log entries.
abstract final class AppColors {
  static Color colorForLevel(RunLogLevel level, BuildContext context) {
    switch (level) {
      case RunLogLevel.error:
        return Catppuccin.red;
      case RunLogLevel.warning:
        return Catppuccin.peach;
      case RunLogLevel.success:
        return Catppuccin.green;
      case RunLogLevel.info:
        return Theme.of(context).textTheme.bodyMedium?.color ??
            Theme.of(context).colorScheme.onSurface;
    }
  }

  static FontWeight weightForLevel(RunLogLevel level) {
    switch (level) {
      case RunLogLevel.error:
        return FontWeight.w700;
      case RunLogLevel.warning:
      case RunLogLevel.success:
        return FontWeight.w600;
      case RunLogLevel.info:
        return FontWeight.normal;
    }
  }
}
