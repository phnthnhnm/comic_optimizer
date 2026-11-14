import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:comic_optimizer/core/providers/service_providers.dart';
import 'package:comic_optimizer/core/result.dart';
import 'package:comic_optimizer/features/settings/providers/settings_provider.dart';
import 'package:comic_optimizer/infrastructure/services/archive_import_service.dart';
import 'package:comic_optimizer/presentation/design_system/app_theme.dart';
import 'package:comic_optimizer/presentation/design_system/catppuccin.dart';

Future<void> showArchiveImportDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final picked = await FilePicker.pickFiles(
    dialogTitle: 'Import comic archives',
    type: FileType.custom,
    allowedExtensions: const ['cbz', 'zip'],
  );
  if (picked.isEmpty) return;
  if (!context.mounted) return;

  final paths = picked.map((file) => file.path).whereType<String>().toList();
  if (paths.isEmpty) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ArchiveImportDialog(paths: paths),
  );
}

class ArchiveImportDialog extends ConsumerStatefulWidget {
  final List<String> paths;

  const ArchiveImportDialog({super.key, required this.paths});

  @override
  ConsumerState<ArchiveImportDialog> createState() =>
      _ArchiveImportDialogState();
}

class _ArchiveImportDialogState extends ConsumerState<ArchiveImportDialog> {
  final _results = <ArchiveImportResult>[];
  var _running = true;
  var _current = 'Preparing…';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final settings = ref.read(settingsProvider);
    final service = ArchiveImportService(ref.read(optimizerServiceProvider));
    for (final path in widget.paths) {
      setState(
        () => _current = 'Importing ${path.split(RegExp(r'[\\/]')).last}…',
      );
      final result = await service.importArchive(
        File(path),
        settings,
        onProgress: (message) {
          if (mounted) setState(() => _current = message);
        },
      );
      if (!mounted) return;
      setState(() {
        if (result case Ok(value: final value)) {
          _results.add(value);
        } else if (result case Err(:final message)) {
          _results.add(
            ArchiveImportResult(
              sourcePath: path,
              success: false,
              error: message,
            ),
          );
        }
      });
    }
    if (mounted) {
      setState(() {
        _running = false;
        _current = 'Finished';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import archives'),
      content: SizedBox(
        width: 540,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _running
                  ? _current
                  : '${_results.where((r) => r.success).length} imported · '
                        '${_results.where((r) => !r.success).length} failed',
              style: const TextStyle(fontSize: 12, color: Catppuccin.overlay1),
            ),
            if (_running) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(minHeight: 4),
            ],
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _results.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final result = _results[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Catppuccin.base,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: Catppuccin.surface1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          result.success
                              ? Icons.check_circle_rounded
                              : Icons.error_outline_rounded,
                          size: 16,
                          color: result.success
                              ? Catppuccin.green
                              : Catppuccin.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                result.sourcePath.split(RegExp(r'[\\/]')).last,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11.5),
                              ),
                              Text(
                                result.success
                                    ? result.archivePath ?? ''
                                    : result.error ?? 'Import failed',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Catppuccin.overlay1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: _running ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
