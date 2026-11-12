import 'dart:io';

import 'package:comic_optimizer/core/interfaces/i_process_runner.dart';

/// Shared test double: records invocations and lets each test decide what the
/// external binaries "do" (including writing output files).
class FakeProcessRunner implements IProcessRunner {
  final List<ProcessCall> calls = [];

  Future<ProcessResult> Function(String executable, List<String> arguments)?
  onRun;

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) async {
    calls.add(ProcessCall(executable, arguments, workingDirectory));
    final handler = onRun;
    if (handler == null) return ProcessResult(0, 0, '', '');
    return handler(executable, arguments);
  }
}

class ProcessCall {
  final String executable;
  final List<String> arguments;
  final String? workingDirectory;

  const ProcessCall(this.executable, this.arguments, this.workingDirectory);
}
