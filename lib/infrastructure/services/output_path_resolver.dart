import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:comic_optimizer/domain/enums/collision_policy.dart';
import 'package:comic_optimizer/domain/enums/output_mode.dart';

/// Pure path resolution for finished archives.
final class OutputPathResolver {
  const OutputPathResolver();

  Future<String> resolve({
    required String libraryPath,
    required String comicPath,
    required String presetName,
    required String outputExtension,
    required OutputMode outputMode,
    required String globalOutputDirectory,
    required String namingTemplate,
    required CollisionPolicy collisionPolicy,
    String? libraryOutputDirectory,
    int? index,
  }) async {
    final overrideDirectory = libraryOutputDirectory?.trim();
    final globalDirectory = globalOutputDirectory.trim();

    String directory;
    if (overrideDirectory != null && overrideDirectory.isNotEmpty) {
      directory = overrideDirectory;
      if (!p.isAbsolute(directory)) {
        directory = p.join(libraryPath, directory);
      }
    } else if (outputMode == OutputMode.custom && globalDirectory.isNotEmpty) {
      directory = globalDirectory;
      if (!p.isAbsolute(directory)) {
        directory = p.join(libraryPath, directory);
      }
    } else {
      directory = p.dirname(comicPath);
    }

    final extension = outputExtension.startsWith('.')
        ? outputExtension
        : '.$outputExtension';
    final template = namingTemplate.trim().isEmpty
        ? '{folder}'
        : namingTemplate;
    var name = _applyTemplate(
      template,
      comicPath: comicPath,
      libraryPath: libraryPath,
      presetName: presetName,
      index: index,
    );
    name = _sanitize(name);
    if (name.isEmpty) name = _sanitize(p.basename(comicPath));
    if (name.toLowerCase().endsWith(extension.toLowerCase())) {
      name = name.substring(0, name.length - extension.length);
    }
    name = '${name.trimRight()}$extension';

    var target = p.join(directory, name);
    if (collisionPolicy == CollisionPolicy.suffix) {
      target = await _availablePath(target);
    }
    return p.normalize(p.absolute(target));
  }

  String _applyTemplate(
    String template, {
    required String comicPath,
    required String libraryPath,
    required String presetName,
    int? index,
  }) {
    final now = DateTime.now();
    final date =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return template
        .replaceAll('{folder}', p.basename(comicPath))
        .replaceAll('{library}', p.basename(libraryPath))
        .replaceAll('{preset}', presetName)
        .replaceAll('{date}', date)
        .replaceAll('{index}', '${index ?? 1}');
  }

  static String _sanitize(String value) {
    var cleaned = value
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceAll(RegExp(r'[. ]+$'), '');
    if (cleaned.isEmpty) return '';
    const reserved = {
      'con',
      'prn',
      'aux',
      'nul',
      'com1',
      'com2',
      'com3',
      'com4',
      'com5',
      'com6',
      'com7',
      'com8',
      'com9',
      'lpt1',
      'lpt2',
      'lpt3',
      'lpt4',
      'lpt5',
      'lpt6',
      'lpt7',
      'lpt8',
      'lpt9',
    };
    final stem = cleaned.split('.').first.toLowerCase();
    if (reserved.contains(stem)) cleaned = '${cleaned}_';
    return cleaned;
  }

  Future<String> _availablePath(String target) async {
    if (!await File(target).exists() && !await Directory(target).exists()) {
      return target;
    }
    final dir = p.dirname(target);
    final ext = p.extension(target);
    final base = p.basenameWithoutExtension(target);
    for (var i = 2; i < 10000; i++) {
      final candidate = p.join(dir, '$base ($i)$ext');
      if (!await File(candidate).exists() &&
          !await Directory(candidate).exists()) {
        return candidate;
      }
    }
    return target;
  }
}
