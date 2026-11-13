import 'dart:io';

import 'package:comic_optimizer/domain/models/image_formats.dart';
import 'package:comic_optimizer/domain/models/preflight_summary.dart';

/// Counts what a run will process without modifying anything.
///
/// The traversal mirrors [OptimizerServiceImpl]: a root with only image files
/// is one comic, otherwise each direct subfolder is a comic, and a subfolder
/// that contains subfolders contributes its own direct subfolders.
final class PreflightService {
  const PreflightService();

  Future<PreflightSummary> scan(Iterable<String> roots) async {
    var rootCount = 0;
    var comics = 0;
    var images = 0;
    var nonImageFiles = 0;

    for (final rootPath in roots) {
      final root = Directory(rootPath);
      if (!await root.exists()) continue;
      rootCount++;

      final entries = await root.list(followLinks: false).toList();
      final hasDirectories = entries.any((entry) => entry is Directory);

      final folders = <Directory>[];
      if (!hasDirectories) {
        folders.add(root);
      } else {
        for (final entry in entries.whereType<Directory>()) {
          final children = await entry.list(followLinks: false).toList();
          if (children.any((child) => child is Directory)) {
            folders.addAll(children.whereType<Directory>());
          } else {
            folders.add(entry);
          }
        }
      }

      for (final folder in folders) {
        final files = await folder
            .list(followLinks: false)
            .where((entry) => entry is File)
            .cast<File>()
            .toList();
        final folderImages = files.where((file) => isSupportedImage(file.path));
        if (folderImages.isEmpty) continue;

        comics++;
        images += folderImages.length;
        nonImageFiles += files.length - folderImages.length;
      }
    }

    return PreflightSummary(
      roots: rootCount,
      comics: comics,
      images: images,
      nonImageFiles: nonImageFiles,
    );
  }
}
