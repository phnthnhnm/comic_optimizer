import 'package:comic_optimizer/domain/enums/post_run_action.dart';
import 'package:comic_optimizer/infrastructure/services/post_run_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_process_runner.dart';

void main() {
  group('PostRunServiceImpl', () {
    late FakeProcessRunner runner;
    late PostRunServiceImpl service;

    setUp(() {
      runner = FakeProcessRunner();
      service = PostRunServiceImpl(runner: runner);
    });

    test('none does nothing', () async {
      await service.perform(PostRunAction.none);
      expect(runner.calls, isEmpty);
    });

    test('shutdown uses the Windows shutdown flags', () async {
      await service.perform(PostRunAction.shutdown);
      expect(runner.calls.single.executable, 'shutdown');
      expect(runner.calls.single.arguments, ['/s', '/t', '0']);
    });

    test('restart uses the reboot flag', () async {
      await service.perform(PostRunAction.restart);
      expect(runner.calls.single.arguments, ['/r', '/t', '0']);
    });

    test('hibernate uses the hibernate flag', () async {
      await service.perform(PostRunAction.hibernate);
      expect(runner.calls.single.arguments, ['/h']);
    });

    test('sleep suspends through rundll32', () async {
      await service.perform(PostRunAction.sleep);
      expect(runner.calls.single.executable, 'rundll32.exe');
      expect(runner.calls.single.arguments, [
        'powrprof.dll,SetSuspendState',
        '0,1,0',
      ]);
    });

    test('quit invokes the injected exit callback', () async {
      int? exitCode;
      final quitting = PostRunServiceImpl(
        runner: runner,
        exitApp: (code) => exitCode = code,
      );

      await quitting.perform(PostRunAction.quit);

      expect(exitCode, 0);
      expect(runner.calls, isEmpty);
    });
  });
}
