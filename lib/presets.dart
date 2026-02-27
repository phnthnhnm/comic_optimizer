class Preset {
  final String name;
  final List<String> args;

  const Preset(this.name, this.args);

  Map<String, dynamic> toJson() => {'name': name, 'args': args};

  factory Preset.fromJson(Map<String, dynamic> m) {
    final a =
        (m['args'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        <String>[];
    return Preset(m['name']?.toString() ?? '', a);
  }

  static const losslessName = 'Lossless';
  static const lossyName = 'Lossy';

  static const lossless = Preset(losslessName, [
    '--distance=0',
    '--lossless_jpeg=1',
    '--quiet',
  ]);
  static const lossy = Preset(lossyName, [
    '--distance=3.0',
    '--lossless_jpeg=0',
    '--quiet',
  ]);

  static const all = [lossless, lossy];

  static Preset byName(String name) {
    return all.firstWhere((p) => p.name == name, orElse: () => lossless);
  }
}
