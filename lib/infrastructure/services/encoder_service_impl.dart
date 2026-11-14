import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:comic_optimizer/core/interfaces/i_encoder_service.dart';
import 'package:comic_optimizer/core/interfaces/i_process_runner.dart';
import 'package:comic_optimizer/core/result.dart';
import 'package:comic_optimizer/core/utils.dart';
import 'package:comic_optimizer/domain/models/image_formats.dart';
import 'package:comic_optimizer/infrastructure/services/system_process_runner.dart';

/// Implementation of [IEncoderService] that encodes images to JPEG XL using cjxl.
final class EncoderServiceImpl implements IEncoderService {
  final IProcessRunner runner;

  const EncoderServiceImpl({this.runner = const SystemProcessRunner()});

  @override
  Future<Result<String>> probeVersion(String cjxlPath) async {
    try {
      final result = await runner.run(cjxlPath, ['--version']);
      if (result.exitCode != 0) {
        final stderr = result.stderr.toString().trim();
        return Err(
          stderr.isEmpty
              ? 'cjxl exited with code ${result.exitCode}'
              : stderr.split(RegExp(r'\r?\n')).first.trim(),
        );
      }
      final stdout = result.stdout.toString().trim();
      if (stdout.isEmpty) return const Ok('cjxl (unknown version)');
      return Ok(stdout.split(RegExp(r'\r?\n')).first.trim());
    } on ProcessException catch (error) {
      return Err(error.message);
    } catch (error) {
      return Err('$error');
    }
  }

  @override
  Future<Result<EncodeOutcome>> encodeImage(
    File input,
    File output,
    List<String> presetArgs,
    String cjxlPath,
    String Function(List<String>) maskArgs, {
    void Function(String)? onLog,
    bool Function()? isCancelled,
    Future<void> Function()? waitIfPaused,
  }) async {
    final originalSize = await _lengthOrNull(input);
    var inputPath = input.path;
    File? intermediatePng;
    File? resaved;

    Future<bool> cancelled() async {
      if (isCancelled != null && isCancelled()) {
        onLog?.call('Operation cancelled by user');
        await _deleteQuietly(output);
        return true;
      }
      return false;
    }

    try {
      await output.parent.create(recursive: true);
      if (p.extension(input.path).toLowerCase() == '.webp') {
        final png = File(
          p.join(
            output.parent.path,
            '${p.basenameWithoutExtension(output.path)}_webp.png',
          ),
        );
        intermediatePng = png;
        onLog?.call(
          'Converting WEBP -> PNG: dwebp ${p.basename(input.path)} -o ${p.basename(png.path)}',
        );
        final conv = await runner.run('dwebp', [
          input.path,
          '-o',
          png.path,
          '-mt',
          '-quiet',
        ], workingDirectory: output.parent.path);
        if (await cancelled()) {
          return const Ok(EncodeOutcome(success: false, cancelled: true));
        }
        if (conv.exitCode != 0) {
          onLog?.call(
            conv.stderr != null && conv.stderr.toString().isNotEmpty
                ? conv.stderr.toString()
                : 'dwebp exit ${conv.exitCode} for ${p.basename(input.path)}',
          );
          return const Ok(EncodeOutcome(success: false));
        }
        if (!await png.exists()) {
          onLog?.call('dwebp did not produce ${p.basename(png.path)}');
          return const Ok(EncodeOutcome(success: false));
        }
        inputPath = png.path;
      }

      final args = [inputPath, output.path, ...presetArgs];
      onLog?.call('Running cjxl: cjxl ${maskArgs(args)}');
      var result = await runner.run(
        cjxlPath,
        args,
        workingDirectory: output.parent.path,
      );
      if (waitIfPaused != null) await waitIfPaused();
      if (await cancelled()) {
        return const Ok(EncodeOutcome(success: false, cancelled: true));
      }
      _logProcess(result, onLog);

      if (result.exitCode != 0) {
        if (result.exitCode != 1) {
          onLog?.call('cjxl exit ${result.exitCode}');
          return const Ok(EncodeOutcome(success: false));
        }

        resaved = File(
          p.join(
            output.parent.path,
            '${p.basenameWithoutExtension(output.path)}_magick_'
            '${DateTime.now().microsecondsSinceEpoch}.png',
          ),
        );
        onLog?.call(
          'cjxl exit 1 for ${p.basename(input.path)}; attempting ImageMagick resave',
        );
        final magick = await runner.run('magick', [
          inputPath,
          '-strip',
          resaved.path,
        ], workingDirectory: output.parent.path);
        _logProcess(magick, onLog);
        if (magick.exitCode != 0 || !await resaved.exists()) {
          onLog?.call('ImageMagick resave failed; not retrying cjxl');
          return const Ok(EncodeOutcome(success: false));
        }

        final retryArgs = [resaved.path, output.path, ...presetArgs];
        onLog?.call('Retrying cjxl: cjxl ${maskArgs(retryArgs)}');
        if (waitIfPaused != null) await waitIfPaused();
        result = await runner.run(
          cjxlPath,
          retryArgs,
          workingDirectory: output.parent.path,
        );
        _logProcess(result, onLog);
        if (result.exitCode != 0) {
          onLog?.call('cjxl retry exit ${result.exitCode}');
          return const Ok(EncodeOutcome(success: false));
        }
      }

      if (!await output.exists()) {
        onLog?.call('cjxl did not produce ${p.basename(output.path)}');
        return const Ok(EncodeOutcome(success: false));
      }

      final outputSize = await output.length();
      if (originalSize != null && outputSize >= originalSize) {
        await _deleteQuietly(output);
        onLog?.call(
          'Reverted larger .jxl: ${p.basename(output.path)} '
          '(was $outputSize bytes >= original $originalSize bytes)',
        );
        return Ok(
          EncodeOutcome(
            success: true,
            encoded: false,
            originalBytes: originalSize,
            outputBytes: originalSize,
          ),
        );
      }

      return Ok(
        EncodeOutcome(
          success: true,
          encoded: true,
          originalBytes: originalSize,
          outputBytes: outputSize,
        ),
      );
    } catch (e) {
      onLog?.call('Failed to run cjxl for ${p.basename(input.path)}: $e');
      await _deleteQuietly(output);
      return const Ok(EncodeOutcome(success: false));
    } finally {
      if (intermediatePng != null) await _deleteQuietly(intermediatePng);
      if (resaved != null) await _deleteQuietly(resaved);
    }
  }

  @override
  Future<Result<bool>> encodeFolder(
    Directory folder,
    List<String> presetArgs,
    String cjxlPath,
    String Function(List<String>) maskArgs, {
    void Function(String)? onLog,
    void Function(String path, int index, int total)? onFileStart,
    bool Function()? isCancelled,
    Future<void> Function()? waitIfPaused,
  }) async {
    var success = true;
    try {
      final files = await folder
          .list(recursive: false, followLinks: false)
          .where((entry) => entry is File)
          .cast<File>()
          .toList();
      files.sort(
        (a, b) => naturalCompare(p.basename(a.path), p.basename(b.path)),
      );
      final encodable = files
          .where((file) => isEncodableImage(file.path))
          .toList();

      for (var index = 0; index < encodable.length; index++) {
        final input = encodable[index];
        onFileStart?.call(input.path, index + 1, encodable.length);
        if (waitIfPaused != null) await waitIfPaused();
        if (isCancelled != null && isCancelled()) {
          onLog?.call('Operation cancelled by user');
          break;
        }
        final output = File(
          p.join(folder.path, '${p.basenameWithoutExtension(input.path)}.jxl'),
        );
        final result = await encodeImage(
          input,
          output,
          presetArgs,
          cjxlPath,
          maskArgs,
          onLog: onLog,
          isCancelled: isCancelled,
          waitIfPaused: waitIfPaused,
        );
        switch (result) {
          case Ok(value: final outcome):
            if (outcome.cancelled) return const Ok(true);
            if (!outcome.success) success = false;
          case Err():
            success = false;
        }
      }
    } catch (e) {
      onLog?.call('Failed during cjxl encoding: $e');
      return const Ok(false);
    }
    return Ok(success);
  }

  void _logProcess(ProcessResult result, void Function(String)? onLog) {
    if (result.stdout != null && result.stdout.toString().isNotEmpty) {
      onLog?.call(result.stdout.toString());
    }
    if (result.stderr != null && result.stderr.toString().isNotEmpty) {
      onLog?.call(result.stderr.toString());
    }
  }

  Future<int?> _lengthOrNull(File file) async {
    try {
      return await file.length();
    } catch (_) {
      return null;
    }
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
