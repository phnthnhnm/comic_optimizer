import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';

import 'package:comic_optimizer/domain/models/optimization_state.dart';

/// Writes the current run to a caller-chosen JSON file.
Future<void> exportRunReport(
  BuildContext context,
  OptimizationState state,
) async {
  final results = state.results.values.toList();
  final before = _sum(results.map((result) => result.beforeBytes));
  final after = _sum(results.map((result) => result.afterBytes));
  final report = {
    'app': 'Comic Optimizer',
    'startedAt': state.startedAt?.toIso8601String(),
    'finishedAt': state.finishedAt?.toIso8601String(),
    'durationSeconds': state.startedAt != null && state.finishedAt != null
        ? state.finishedAt!.difference(state.startedAt!).inSeconds
        : null,
    'libraries': state.libraries,
    'totals': {
      'comics': results.length,
      'succeeded': results.where((result) => result.success).length,
      'failed': results.where((result) => !result.success).length,
      'images': state.imagesDone,
      'beforeBytes': before,
      'afterBytes': after,
      'savedBytes': before != null && after != null ? before - after : null,
    },
    'folders': [
      for (final result in results)
        {
          'path': result.path,
          'root': result.root,
          'success': result.success,
          'beforeBytes': result.beforeBytes,
          'afterBytes': result.afterBytes,
          'error': result.error,
        },
    ],
  };

  try {
    final bytes = Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(report)),
    );
    final uri = await FilePicker.saveFile(
      dialogTitle: 'Save run report',
      fileName: 'comic_optimizer_report_${_stamp(DateTime.now())}.json',
      bytes: bytes,
      mimeType: 'application/json',
    );
    if (uri != null && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Report saved to $uri')));
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save report: $error')));
    }
  }
}

int? _sum(Iterable<int?> values) {
  var total = 0;
  var any = false;
  for (final value in values) {
    if (value != null) {
      total += value;
      any = true;
    }
  }
  return any ? total : null;
}

String _stamp(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year}${two(date.month)}${two(date.day)}'
      '_${two(date.hour)}${two(date.minute)}';
}
