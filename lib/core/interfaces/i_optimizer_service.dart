import 'dart:io';

import '../../core/result.dart';

/// Contract for orchestrating comic folder optimization.
abstract interface class IOptimizerService {
  void cancel();
  void pause();
  void resume();

  Future<Result<void>> optimizeRoot(
    Directory root, {
    required List<String> presetArgs,
    required bool skipCjxl,
    required String cjxlPath,
    required String outputExtension,
    bool safeRun = false,
    bool preferPermanentDelete = false,
    void Function(String)? onLog,
    void Function(String)? onFolderStart,
    void Function(
      String folderPath,
      bool success,
      int? beforeBytes,
      int? afterBytes,
      Map<String, Map<String, int?>>? perFileSizes,
    )?
    onFolderDone,
  });
}
