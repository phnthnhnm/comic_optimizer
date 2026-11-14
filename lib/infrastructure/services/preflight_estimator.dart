import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as p;

import 'package:comic_optimizer/core/interfaces/i_encoder_service.dart';
import 'package:comic_optimizer/core/result.dart';
import 'package:comic_optimizer/core/utils.dart';
import 'package:comic_optimizer/domain/models/image_formats.dart';

final class PreflightEstimate {
  final int estimatedBytes;
  final int sampledImages;
  final Duration elapsed;

  const PreflightEstimate({
    required this.estimatedBytes,
    required this.sampledImages,
    required this.elapsed,
  });
}

/// Encodes a few pages to project archive size and time without touching the
/// source folders.
final class PreflightEstimator {
  final IEncoderService encoder;

  const PreflightEstimator(this.encoder);

  Future<PreflightEstimate?> estimate({
    required List<String> folders,
    required List<String> presetArgs,
    required String cjxlPath,
    int maxSamples = 3,
  }) async {
    final samples = <File>[];
    for (final folder in folders) {
      try {
        final images =
            await Directory(folder)
                  .list(recursive: false, followLinks: false)
                  .where(
                    (entry) => entry is File && isEncodableImage(entry.path),
                  )
                  .cast<File>()
                  .toList()
              ..sort(
                (a, b) =>
                    naturalCompare(p.basename(a.path), p.basename(b.path)),
              );
        if (images.isNotEmpty) samples.add(images.first);
      } catch (_) {}
      if (samples.length >= maxSamples) break;
    }
    if (samples.isEmpty) return null;

    final temp = await Directory.systemTemp.createTemp('comic_estimate_');
    final watch = Stopwatch()..start();
    var sampledOriginal = 0;
    var sampledOutput = 0;
    var used = 0;
    try {
      for (var index = 0; index < samples.length; index++) {
        final input = samples[index];
        final original = await input.length();
        final output = File(p.join(temp.path, '$index.jxl'));
        final result = await encoder.encodeImage(
          input,
          output,
          presetArgs,
          cjxlPath,
          (args) => args
              .map((arg) => p.isAbsolute(arg) ? p.basename(arg) : arg)
              .join(' '),
        );
        if (result is! Ok<EncodeOutcome> || !result.value.success) continue;
        final bytes = result.value.encoded
            ? (result.value.outputBytes ?? original)
            : original;
        sampledOriginal += original;
        sampledOutput += bytes;
        used++;
      }
      if (used == 0 || sampledOriginal == 0) return null;

      // Project from the sample ratio. Keep the result bounded: the archive
      // cannot be smaller than a few kilobytes per page, and cannot exceed
      // the source.
      final ratio = sampledOutput / sampledOriginal;
      var totalSource = 0;
      for (final folder in folders) {
        try {
          final files = await Directory(folder)
              .list(recursive: false, followLinks: false)
              .where((entry) => entry is File && isSupportedImage(entry.path))
              .cast<File>()
              .toList();
          for (final file in files) {
            totalSource += await file.length();
          }
        } catch (_) {}
      }
      if (totalSource == 0) return null;
      final estimated = math.max(
        4096,
        math.min(totalSource, (totalSource * ratio).round()),
      );
      return PreflightEstimate(
        estimatedBytes: estimated,
        sampledImages: used,
        elapsed: watch.elapsed,
      );
    } catch (_) {
      return null;
    } finally {
      try {
        if (await temp.exists()) await temp.delete(recursive: true);
      } catch (_) {}
    }
  }
}
