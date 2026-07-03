import 'package:freezed_annotation/freezed_annotation.dart';

part 'preset.freezed.dart';
part 'preset.g.dart';

@freezed
abstract class Preset with _$Preset {
  const factory Preset({required String name, @Default([]) List<String> args}) =
      _Preset;

  factory Preset.fromJson(Map<String, dynamic> json) => _$PresetFromJson(json);

  const Preset._();

  static const losslessName = 'Lossless';
  static const visuallyLosslessName = 'Visually Lossless';
  static const lossyName = 'Lossy';

  static const lossless = Preset(
    name: losslessName,
    args: ['--distance=0', '--lossless_jpeg=1', '--quiet'],
  );
  static const visuallyLossless = Preset(
    name: visuallyLosslessName,
    args: ['--distance=1.0', '--lossless_jpeg=0', '--quiet'],
  );
  static const lossy = Preset(
    name: lossyName,
    args: ['--distance=3.0', '--lossless_jpeg=0', '--quiet'],
  );

  static const all = [lossless, visuallyLossless, lossy];

  static Preset byName(String name) {
    return all.firstWhere((p) => p.name == name, orElse: () => lossless);
  }
}
