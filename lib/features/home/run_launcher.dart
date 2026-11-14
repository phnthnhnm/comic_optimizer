import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:comic_optimizer/domain/models/preflight_summary.dart';
import 'package:comic_optimizer/features/home/providers/optimization_provider.dart';
import 'package:comic_optimizer/features/home/widgets/preflight_sheet.dart';
import 'package:comic_optimizer/features/settings/providers/settings_provider.dart';

/// Adds a folder to the library queue, de-duplicating the selection.
Future<void> addLibraryFolder(BuildContext context, WidgetRef ref) async {
  final settings = ref.read(settingsProvider);
  final notifier = ref.read(settingsProvider.notifier);
  final directory = await FilePicker.getDirectoryPath(
    dialogTitle: 'Add a comic library',
  );
  if (directory == null) return;

  if (!context.mounted) return;
  if (settings.libraries.any((entry) => entry.path == directory)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('That folder is already in the queue.')),
    );
    return;
  }
  await notifier.addLibraryRoot(directory);
  if (settings.lastRoot == null) {
    await notifier.setLastRoot(directory);
  }
}

/// Runs the preflight sheet and starts the queue when the user confirms.
Future<void> startRunWithPreflight(BuildContext context, WidgetRef ref) async {
  final settings = ref.read(settingsProvider);
  final hasRoots = settings.libraries.isNotEmpty || settings.lastRoot != null;
  PreflightSummary? summary;
  if (hasRoots) {
    summary = await showPreflightSheet(context, ref);
    if (summary == null) return;
  }
  await ref.read(optimizationProvider.notifier).start(summary: summary);
}
