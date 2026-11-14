import 'dart:io';

import '../../core/result.dart';

/// Result of encoding one image.
final class EncodeOutcome {
  final bool success;
  final bool encoded;
  final bool cancelled;
  final int? originalBytes;
  final int? outputBytes;

  const EncodeOutcome({
    required this.success,
    this.encoded = false,
    this.cancelled = false,
    this.originalBytes,
    this.outputBytes,
  });
}

/// Contract for encoding images to JPEG XL via cjxl.
abstract interface class IEncoderService {
  /// Runs `cjxl --version` and returns its first output line.
  Future<Result<String>> probeVersion(String cjxlPath);

  /// Encodes [input] into [output]. If the result is not smaller, [output] is
  /// removed and [EncodeOutcome.encoded] is false.
  Future<Result<EncodeOutcome>> encodeImage(
    File input,
    File output,
    List<String> presetArgs,
    String cjxlPath,
    String Function(List<String>) maskArgs, {
    void Function(String)? onLog,
    bool Function()? isCancelled,
    Future<void> Function()? waitIfPaused,
  });

  /// Legacy folder encoder retained for compatibility with older callers.
  Future<Result<bool>> encodeFolder(
    Directory folder,
    List<String> presetArgs,
    String cjxlPath,
    String Function(List<String>) maskArgs, {
    void Function(String)? onLog,
    void Function(String path, int index, int total)? onFileStart,
    bool Function()? isCancelled,
    Future<void> Function()? waitIfPaused,
  });
}
