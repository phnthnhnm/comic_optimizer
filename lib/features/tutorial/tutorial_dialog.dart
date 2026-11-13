import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:comic_optimizer/features/settings/providers/settings_provider.dart';
import 'package:comic_optimizer/presentation/design_system/app_theme.dart';
import 'package:comic_optimizer/presentation/design_system/catppuccin.dart';
import 'package:comic_optimizer/presentation/widgets/app_logo.dart';

/// Opens the welcome tour and records that it has been seen.
Future<void> showTutorial(BuildContext context, WidgetRef ref) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => const TutorialDialog(),
  );
  await ref.read(settingsProvider.notifier).completeTutorial();
}

class TutorialDialog extends StatefulWidget {
  const TutorialDialog({super.key});

  @override
  State<TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<TutorialDialog> {
  int _index = 0;

  static const _steps = <_TutorialStep>[
    _TutorialStep(
      icon: Icons.auto_awesome_rounded,
      title: 'Welcome to Comic Optimizer',
      body:
          'Turn folders of comic pages into compact .cbz archives, encoded '
          'with JPEG XL. This quick tour takes about a minute.',
      tip: 'You can skip anytime and reopen the tour from the ? button later.',
      showLogo: true,
    ),
    _TutorialStep(
      icon: Icons.create_new_folder_outlined,
      title: 'Build your library queue',
      body:
          'Add one or more folders with Add folder (Ctrl+O). Drag the handle '
          'to reorder them; each library is processed in order.',
      tip:
          'A comic is a folder of images, or a folder whose direct subfolders '
          'contain the images.',
    ),
    _TutorialStep(
      icon: Icons.tune_rounded,
      title: 'Choose quality and safety',
      body:
          'Pick a preset, then decide whether to encode to JPEG XL, delete '
          'non-image files, and keep originals. Keep originals on for your '
          'first run.',
      tip:
          'Custom presets are available in Settings → Presets, and every '
          'choice is confirmed again in preflight.',
    ),
    _TutorialStep(
      icon: Icons.rocket_launch_outlined,
      title: 'Review, run, and check results',
      body:
          'Start (Ctrl+Enter) opens a preflight summary with exact counts. '
          'Confirm, watch progress in the run workspace, then review savings '
          'and retry failures from Results.',
      tip: 'Finished runs are kept in History for later reference.',
    ),
  ];

  bool get _isLast => _index == _steps.length - 1;

  @override
  Widget build(BuildContext context) {
    final step = _steps[_index];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          padding: const EdgeInsets.fromLTRB(26, 18, 26, 22),
          decoration: BoxDecoration(
            color: Catppuccin.mantle,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Catppuccin.surface0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const AppLogo(size: 28),
                  const SizedBox(width: 9),
                  const Text(
                    'Comic Optimizer',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_index + 1} of ${_steps.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Catppuccin.overlay1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Skip'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Column(
                  key: ValueKey(_index),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 74,
                          height: 74,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Catppuccin.surface0,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: Catppuccin.surface1),
                          ),
                          child: step.showLogo
                              ? const AppLogo(size: 52)
                              : Icon(
                                  step.icon,
                                  size: 36,
                                  color: Catppuccin.green,
                                ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                step.body,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  height: 1.45,
                                  color: Catppuccin.subtext0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Catppuccin.base,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: Catppuccin.surface1),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 16,
                              color: Catppuccin.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              step.tip,
                              style: const TextStyle(
                                fontSize: 11.5,
                                height: 1.35,
                                color: Catppuccin.overlay1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  for (var i = 0; i < _steps.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      margin: const EdgeInsets.only(right: 5),
                      width: i == _index ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? Catppuccin.green
                            : Catppuccin.surface2,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  const Spacer(),
                  if (_index > 0) ...[
                    TextButton(
                      onPressed: () => setState(() => _index -= 1),
                      child: const Text('Back'),
                    ),
                    const SizedBox(width: 6),
                  ],
                  FilledButton.icon(
                    onPressed: _isLast
                        ? () => Navigator.of(context).pop()
                        : () => setState(() => _index += 1),
                    icon: Icon(
                      _isLast
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      size: 18,
                    ),
                    label: Text(_isLast ? 'Get started' : 'Next'),
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

class _TutorialStep {
  final IconData icon;
  final String title;
  final String body;
  final String tip;
  final bool showLogo;

  const _TutorialStep({
    required this.icon,
    required this.title,
    required this.body,
    required this.tip,
    this.showLogo = false,
  });
}
