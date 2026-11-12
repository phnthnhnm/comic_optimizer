import 'dart:io';

import 'package:comic_optimizer/core/interfaces/i_post_run_service.dart';
import 'package:comic_optimizer/core/interfaces/i_process_runner.dart';
import 'package:comic_optimizer/domain/enums/post_run_action.dart';
import 'package:comic_optimizer/infrastructure/services/system_process_runner.dart';

/// Performs the platform power actions with the configured process runner.
///
/// Keeping this out of the UI makes the widget testable and confines
/// Windows-specific commands to one place.
final class PostRunServiceImpl implements IPostRunService {
  final IProcessRunner runner;

  /// Injected in tests; defaults to [exit].
  final void Function(int code)? exitApp;

  const PostRunServiceImpl({
    this.runner = const SystemProcessRunner(),
    this.exitApp,
  });

  @override
  Future<void> perform(PostRunAction action) async {
    switch (action) {
      case PostRunAction.none:
        return;
      case PostRunAction.quit:
        await Future<void>.delayed(const Duration(milliseconds: 200));
        (exitApp ?? exit)(0);
        return;
      case PostRunAction.shutdown:
        await runner.run('shutdown', ['/s', '/t', '0']);
        return;
      case PostRunAction.restart:
        await runner.run('shutdown', ['/r', '/t', '0']);
        return;
      case PostRunAction.hibernate:
        await runner.run('shutdown', ['/h']);
        return;
      case PostRunAction.sleep:
        await runner.run('rundll32.exe', [
          'powrprof.dll,SetSuspendState',
          '0,1,0',
        ]);
        return;
    }
  }
}
