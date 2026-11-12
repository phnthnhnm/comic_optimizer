import 'dart:io';

import 'package:comic_optimizer/core/interfaces/i_process_runner.dart';

/// [IProcessRunner] backed by the real [Process.run].
final class SystemProcessRunner implements IProcessRunner {
  const SystemProcessRunner();

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) {
    return Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
    );
  }
}
