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
    '-d',
    '0',
    '--lossless_jpeg=1',
  ]);
  static const lossy = Preset(lossyName, ['-q', '90', '-d', '1.0', '-e', '8']);

  static const all = [lossless, lossy];

  static Preset byName(String name) {
    return all.firstWhere((p) => p.name == name, orElse: () => lossless);
  }
}
