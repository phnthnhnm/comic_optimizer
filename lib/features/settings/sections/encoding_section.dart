import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:comic_optimizer/core/providers/service_providers.dart';
import 'package:comic_optimizer/core/result.dart';
import 'package:comic_optimizer/features/settings/providers/settings_provider.dart';
import 'package:comic_optimizer/features/settings/widgets/settings_widgets.dart';
import 'package:comic_optimizer/presentation/design_system/catppuccin.dart';

class EncodingSection extends ConsumerStatefulWidget {
  const EncodingSection({super.key});

  @override
  ConsumerState<EncodingSection> createState() => _EncodingSectionState();
}

class _EncodingSectionState extends ConsumerState<EncodingSection> {
  late final TextEditingController _controller;
  Result<String>? _probe;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(settingsProvider).cjxlPath,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _probeEncoder());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _probeEncoder() async {
    final path = _controller.text.trim();
    if (path.isEmpty || _checking) return;
    setState(() => _checking = true);
    final result = await ref.read(encoderServiceProvider).probeVersion(path);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _probe = result;
    });
  }

  Future<void> _pickEncoder() async {
    final files = await FilePicker.pickFiles(
      dialogTitle: 'Select the cjxl executable',
      type: FileType.any,
    );
    final path = files.isEmpty ? null : files.first.path;
    if (path == null) return;
    _controller.text = path;
    await ref.read(settingsProvider.notifier).setCjxlPath(path);
    await _probeEncoder();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(settingsProvider.notifier);

    return SettingsSection(
      title: 'Encoding',
      subtitle: 'The encoder converts each page to JPEG XL before archiving.',
      children: [
        SettingsCard(
          title: 'cjxl executable',
          subtitle: 'Leave as “cjxl” to resolve it from PATH, or choose the binary explicitly.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        labelText: 'Path or command',
                        hintText: 'cjxl',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        final path = value.trim();
                        notifier.setCjxlPath(path.isEmpty ? 'cjxl' : path);
                      },
                      onSubmitted: (_) => _probeEncoder(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _pickEncoder,
                    icon: const Icon(Icons.folder_open, size: 18),
                    label: const Text('Browse'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ProbeStatus(probe: _probe, checking: _checking),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _checking ? null : _probeEncoder,
                    icon: const Icon(Icons.refresh_rounded, size: 17),
                    label: const Text('Check version'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SettingsCard(
          child: SettingsInfo(
            icon: Icons.info_outline_rounded,
            text:
                'Comic Optimizer runs “cjxl --version” to confirm the encoder. '
                'Detection never encodes anything and is only a convenience.',
          ),
        ),
      ],
    );
  }
}

class _ProbeStatus extends StatelessWidget {
  final Result<String>? probe;
  final bool checking;

  const _ProbeStatus({required this.probe, required this.checking});

  @override
  Widget build(BuildContext context) {
    if (checking) {
      return const Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text(
            'Checking cjxl…',
            style: TextStyle(fontSize: 12, color: Catppuccin.overlay1),
          ),
        ],
      );
    }

    return switch (probe) {
      Ok(:final value) => Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: Catppuccin.green,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: SelectableText(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 12,
                color: Catppuccin.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      Err(:final message) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: Catppuccin.red,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                color: Catppuccin.red,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
      _ => const Text(
        'Not checked yet.',
        style: TextStyle(fontSize: 12, color: Catppuccin.overlay1),
      ),
    };
  }
}
