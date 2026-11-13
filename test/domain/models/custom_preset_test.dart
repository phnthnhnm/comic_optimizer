import 'package:comic_optimizer/domain/models/custom_preset.dart';
import 'package:comic_optimizer/domain/models/preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CustomPreset', () {
    test('builds cjxl arguments', () {
      const preset = CustomPreset(
        name: 'Archival',
        distance: 1.5,
        losslessJpeg: true,
        extraArgs: '--effort=7  --modular=1',
      );

      expect(preset.args, [
        '--distance=1.5',
        '--lossless_jpeg=1',
        '--effort=7',
        '--modular=1',
        '--quiet',
      ]);
      expect(preset.description, 'Distance 1.5 · JPEG lossless');
    });

    test('formats whole and fractional distances', () {
      expect(const CustomPreset(name: 'A', distance: 1).distanceLabel, '1.0');
      expect(
        const CustomPreset(name: 'B', distance: 2.25).distanceLabel,
        '2.25',
      );
    });

    test('round-trips through JSON', () {
      const original = CustomPreset(
        name: 'Mine',
        distance: 3.4,
        losslessJpeg: true,
        extraArgs: '--effort=5',
      );
      final restored = CustomPreset.fromJson(original.toJson());

      expect(restored, original);
    });

    test('tolerates missing JSON fields', () {
      final restored = CustomPreset.fromJson(const {});
      expect(restored.name, isEmpty);
      expect(restored.distance, 1.0);
      expect(restored.losslessJpeg, false);
      expect(restored.extraArgs, isEmpty);
    });
  });

  group('Preset.resolve', () {
    test('resolves built-ins', () {
      expect(Preset.resolve('Lossy', const []).args, Preset.lossy.args);
    });

    test('resolves a custom preset', () {
      const custom = CustomPreset(name: 'Mine', distance: 2);
      expect(Preset.resolve('Mine', [custom]).args, custom.args);
    });

    test('falls back to Lossless for unknown or deleted names', () {
      expect(Preset.resolve('Missing', const []).name, Preset.losslessName);
    });
  });
}
