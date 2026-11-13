import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:comic_optimizer/domain/models/preflight_summary.dart';
import 'package:comic_optimizer/features/settings/providers/settings_provider.dart';
import 'package:comic_optimizer/infrastructure/services/preflight_service.dart';
import 'package:comic_optimizer/presentation/design_system/app_theme.dart';
import 'package:comic_optimizer/presentation/design_system/catppuccin.dart';

/// Shows the preflight sheet and returns the scanned summary when confirmed.
Future<PreflightSummary?> showPreflightSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  return showModalBottomSheet<PreflightSummary>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Catppuccin.mantle,
    barrierColor: Colors.black.withAlpha(140),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => const PreflightSheet(),
  );
}

class PreflightSheet extends ConsumerStatefulWidget {
  const PreflightSheet({super.key});

  @override
  ConsumerState<PreflightSheet> createState() => _PreflightSheetState();
}

class _PreflightSheetState extends ConsumerState<PreflightSheet> {
  late final Future<PreflightSummary> _summary;
  PreflightSummary? _data;

  @override
  void initState() {
    super.initState();
    _summary = _scan();
    _summary.then((value) {
      if (mounted) setState(() => _data = value);
    });
  }

  Future<PreflightSummary> _scan() {
    final settings = ref.read(settingsProvider);
    final roots = settings.libraryRoots.isNotEmpty
        ? settings.libraryRoots
        : [if (settings.lastRoot != null) settings.lastRoot!];
    return const PreflightService().scan(roots);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.fact_check_outlined,
                    color: Catppuccin.green,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Ready to optimize',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Review what this run will touch before it starts.',
                style: TextStyle(fontSize: 12, color: Catppuccin.overlay1),
              ),
              const SizedBox(height: 18),
              FutureBuilder<PreflightSummary>(
                future: _summary,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Column(
                        children: [
                          CircularProgressIndicator(strokeWidth: 2.5),
                          SizedBox(height: 12),
                          Text(
                            'Counting folders and images…',
                            style: TextStyle(
                              fontSize: 12,
                              color: Catppuccin.overlay1,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Text(
                      'Could not scan the queue: ${snapshot.error}',
                      style: const TextStyle(color: Catppuccin.red),
                    );
                  }
                  return _SummaryBody(
                    summary: snapshot.data ?? PreflightSummary.empty,
                  );
                },
              ),
              const SizedBox(height: 18),
              _PolicySwitch(
                title: 'Delete non-image files',
                subtitle: 'ComicInfo.xml, .nfo and other non-image files are removed before archiving.',
                value: settings.deleteNonImageFiles,
                onChanged: notifier.setDeleteNonImageFiles,
              ),
              _PolicySwitch(
                title: 'Keep originals',
                subtitle: 'Process a copy of each folder and leave the source untouched.',
                value: settings.safeRun,
                onChanged: notifier.setSafeRun,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _data == null || _data!.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(_data),
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text('Start run'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryBody extends StatelessWidget {
  final PreflightSummary summary;

  const _SummaryBody({required this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Catppuccin.surface0,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Catppuccin.surface1),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: Catppuccin.yellow,
              size: 20,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No comics were found in the queue. Add a folder that contains image files.',
                style: TextStyle(fontSize: 12.5),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            _Stat(value: summary.comics, label: 'Comics'),
            const SizedBox(width: 10),
            _Stat(value: summary.images, label: 'Images'),
            const SizedBox(width: 10),
            _Stat(value: summary.roots, label: 'Libraries'),
          ],
        ),
        const SizedBox(height: 12),
        if (summary.nonImageFiles > 0)
          _Notice(
            icon: Icons.delete_outline_rounded,
            color: Catppuccin.peach,
            text:
                '${summary.nonImageFiles} non-image ${summary.nonImageFiles == 1 ? 'file' : 'files'} will be handled by the deletion setting below.',
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Catppuccin.surface0,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Catppuccin.surface1),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Catppuccin.green,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Catppuccin.overlay2),
            ),
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _Notice({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 17),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Catppuccin.subtext0,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _PolicySwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PolicySwitch({
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
                      fontSize: 13.5,
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
