import 'package:comic_optimizer/domain/enums/run_log_level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RunLogLevelX.fromLine', () {
    test('classifies errors', () {
      for (final line in [
        'Error: boom',
        'Failed to process',
        'cjxl exit 1',
        'Done: Comic (ERR)',
      ]) {
        expect(RunLogLevelX.fromLine(line), RunLogLevel.error, reason: line);
      }
    });

    test('classifies warnings', () {
      for (final line in [
        'Operation cancelled by user',
        'No images found in Comic',
        'Warning: encoder returned no output',
      ]) {
        expect(RunLogLevelX.fromLine(line), RunLogLevel.warning, reason: line);
      }
    });

    test('classifies successes', () {
      for (final line in [
        'Done: Comic (OK)',
        'Created archive Comic.cbz',
        'Saved 1.20 MB (68.00%)',
      ]) {
        expect(RunLogLevelX.fromLine(line), RunLogLevel.success, reason: line);
      }
    });

    test('falls back to info', () {
      for (final line in [
        'Start: Comic',
        'Root: C:\\comics',
        'Running cjxl: cjxl 001.png 001.jxl',
        'cjxl exit 0',
        'Deleted non-image: notes.txt',
        'Removed duplicate original',
      ]) {
        expect(RunLogLevelX.fromLine(line), RunLogLevel.info, reason: line);
      }
    });
  });
}
