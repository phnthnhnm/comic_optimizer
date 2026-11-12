import 'dart:io';

/// Abstraction over [Process.run].
///
/// Services that drive external binaries depend on this instead of calling
/// [Process.run] directly, which keeps their logic testable without spawning
/// real programs.
abstract interface class IProcessRunner {
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  });
}
