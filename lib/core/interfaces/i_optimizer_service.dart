import 'dart:io';

import '../../core/result.dart';
import '../../domain/enums/collision_policy.dart';
import '../../domain/enums/output_mode.dart';

/// Contract for orchestrating comic folder optimization.
abstract interface class IOptimizerService {
  void cancel();
  void pause();
  void resume();

  Future<Result<void>> optimizeRoot(
    Directory root, {
    required List<String> presetArgs,
    required bool skipCjxl,
    required bool deleteNonImageFiles,
    required String cjxlPath,
    required String outputExtension,
    bool safeRun = false,
    bool preferPermanentDelete = false,
    String presetName = '',
    String namingTemplate = '{folder}',
    String globalOutputDirectory = '',
    String? libraryOutputDirectory,
    OutputMode outputMode = OutputMode.besideSource,
    CollisionPolicy collisionPolicy = CollisionPolicy.overwrite,
    bool skipExistingArchives = false,
    int maxParallelEncodes = 2,
    Set<String> completedFolders = const {},
    void Function(String)? onLog,
    void Function(String folder, String file, int index, int total)?
    onFileStart,
    void Function(String)? onFolderStart,
    void Function(
      String folderPath,
      bool success,
      int? beforeBytes,
      int? afterBytes,
      Map<String, Map<String, int?>>? perFileSizes,
      String? archivePath,
    )?
    onFolderDone,
  });
}
