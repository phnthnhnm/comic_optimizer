import 'package:comic_optimizer/domain/models/preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Preset', () {
    test('static constants exist', () {
      expect(Preset.lossless.name, 'Lossless');
      expect(Preset.visuallyLossless.name, 'Visually Lossless');
      expect(Preset.lossy.name, 'Lossy');
    });

    test('all contains three presets', () {
      expect(Preset.all, hasLength(3));
    });

    test('lossless has correct args', () {
      expect(Preset.lossless.args, contains('--distance=0'));
      expect(Preset.lossless.args, contains('--lossless_jpeg=1'));
    });

    test('visuallyLossless has correct args', () {
      expect(Preset.visuallyLossless.args, contains('--distance=1.0'));
      expect(Preset.visuallyLossless.args, contains('--lossless_jpeg=0'));
    });

    test('lossy has correct args', () {
      expect(Preset.lossy.args, contains('--distance=3.0'));
    });

    group('byName', () {
      test('returns correct preset by name', () {
        expect(Preset.byName('Lossless'), Preset.lossless);
        expect(Preset.byName('Visually Lossless'), Preset.visuallyLossless);
        expect(Preset.byName('Lossy'), Preset.lossy);
      });

      test('returns lossless for unknown name', () {
        final result = Preset.byName('Unknown');
        expect(result, Preset.lossless);
      });
    });

    group('toJson / fromJson', () {
      test('round-trips correctly', () {
        final preset = Preset.lossless;
        final json = preset.toJson();
        final restored = Preset.fromJson(json);
        expect(restored.name, preset.name);
        expect(restored.args, preset.args);
      });

      test('handles missing args', () {
        final restored = Preset.fromJson({'name': 'Test'});
        expect(restored.name, 'Test');
        expect(restored.args, isEmpty);
      });
    });

    test('copyWith works with args', () {
      final modified = Preset.lossless.copyWith(args: ['--custom']);
      expect(modified.args, ['--custom']);
      expect(modified.name, 'Lossless');
    });
  });
}
