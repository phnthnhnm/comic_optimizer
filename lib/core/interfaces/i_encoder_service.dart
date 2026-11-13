import 'dart:io';

import '../../core/result.dart';

/// Contract for encoding images to JPEG XL via cjxl.
abstract interface class IEncoderService {
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
