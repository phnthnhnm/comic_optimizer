class Preset {
  final String name;
  final List<String> args;

  const Preset(this.name, this.args);

  static const losslessName = 'Lossless';
  static const lossyName = 'Lossy';

  static const lossless = Preset(losslessName, [
    '-s4',
    '-lossless',
    '-webp',
    '-process=4',
    '-no-jpeg',
  ]);
  static const lossy = Preset(lossyName, ['-s8', '-webp', '-q', '80']);

  static const all = [lossless, lossy];

  static Preset byName(String name) {
    return all.firstWhere((p) => p.name == name, orElse: () => lossless);
  }
}
