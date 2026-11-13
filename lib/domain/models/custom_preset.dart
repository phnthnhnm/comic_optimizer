/// A user-defined cjxl preset, edited in Settings → Presets.
final class CustomPreset {
  final String name;
  final double distance;
  final bool losslessJpeg;
  final String extraArgs;

  const CustomPreset({
    required this.name,
    required this.distance,
    this.losslessJpeg = false,
    this.extraArgs = '',
  });

  String get distanceLabel {
    final fixed = distance.toStringAsFixed(2);
    return fixed.endsWith('0') ? fixed.substring(0, fixed.length - 1) : fixed;
  }

  List<String> get args => [
    '--distance=$distanceLabel',
    '--lossless_jpeg=${losslessJpeg ? 1 : 0}',
    if (extraArgs.trim().isNotEmpty) ...extraArgs.trim().split(RegExp(r'\s+')),
    '--quiet',
  ];

  String get description =>
      'Distance $distanceLabel · ${losslessJpeg ? 'JPEG lossless' : 'pixel re-encode'}';

  CustomPreset copyWith({
    String? name,
    double? distance,
    bool? losslessJpeg,
    String? extraArgs,
  }) {
    return CustomPreset(
      name: name ?? this.name,
      distance: distance ?? this.distance,
      losslessJpeg: losslessJpeg ?? this.losslessJpeg,
      extraArgs: extraArgs ?? this.extraArgs,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'distance': distance,
    'losslessJpeg': losslessJpeg,
    'extraArgs': extraArgs,
  };

  factory CustomPreset.fromJson(Map<String, dynamic> json) {
    return CustomPreset(
      name: json['name']?.toString() ?? '',
      distance: (json['distance'] as num?)?.toDouble() ?? 1.0,
      losslessJpeg: json['losslessJpeg'] as bool? ?? false,
      extraArgs: json['extraArgs']?.toString() ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomPreset &&
          other.name == name &&
          other.distance == distance &&
          other.losslessJpeg == losslessJpeg &&
          other.extraArgs == extraArgs;

  @override
  int get hashCode => Object.hash(name, distance, losslessJpeg, extraArgs);
}
