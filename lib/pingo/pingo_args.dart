// Data-driven spec and helpers for pingo CLI flags.
// Keeps all flag definitions centralized so the UI and parsing/generation
// logic can be driven from a single source of truth.

class ArgSpec {
  final String id;
  final String flag; // base flag, e.g. '-quality' or '-s'
  final ArgType type;
  final String label;
  final String? help;
  final int? min;
  final int? max;
  final List<String>? choices;

  const ArgSpec({
    required this.id,
    required this.flag,
    required this.type,
    required this.label,
    this.help,
    this.min,
    this.max,
    this.choices,
  });
}

enum ArgType { boolean, integer, enumString, multiExclude }

class ParseResult {
  final Map<String, dynamic> values;

  ParseResult(this.values);
}

// Canonical list of pingo supported args. Update here when pingo adds/removes flags.
const List<ArgSpec> pingoArgSpecs = [
  ArgSpec(
    id: 's',
    flag: '-s',
    type: ArgType.integer,
    label: 'Compression level',
    min: 1,
    max: 4,
  ),
  ArgSpec(
    id: 'lossless',
    flag: '-lossless',
    type: ArgType.boolean,
    label: 'Use web-lossless optimizer',
  ),
  ArgSpec(
    id: 'quality',
    flag: '-quality',
    type: ArgType.integer,
    label: 'Lossy quality',
    min: 1,
    max: 100,
  ),
  ArgSpec(
    id: 'resize',
    flag: '-resize',
    type: ArgType.integer,
    label: 'Image downscaler (keep ratio)',
    min: 24,
    max: 4096,
  ),
  ArgSpec(
    id: 'notrans',
    flag: '-notrans',
    type: ArgType.boolean,
    label: 'Remove transparency from PNG',
  ),
  ArgSpec(
    id: 'grayscale',
    flag: '-grayscale',
    type: ArgType.boolean,
    label: 'Convert image to grayscale',
  ),
  ArgSpec(
    id: 'enhance',
    flag: '-enhance',
    type: ArgType.integer,
    label: 'Increase details',
    min: 1,
    max: 6,
  ),
  ArgSpec(
    id: 'srgb',
    flag: '-srgb',
    type: ArgType.boolean,
    label: 'Convert image from color profile (sRGB)',
  ),
  ArgSpec(
    id: 'rotate',
    flag: '-rotate',
    type: ArgType.boolean,
    label: 'Rotate image from the orientation flag (JPEG)',
  ),
  ArgSpec(
    id: 'output',
    flag: '-output',
    type: ArgType.enumString,
    label: 'Output format',
    choices: ['none', 'jpeg', 'webp'],
  ),
  ArgSpec(
    id: 'nostrip',
    flag: '-nostrip',
    type: ArgType.boolean,
    label: 'Do not remove metadata',
  ),
  ArgSpec(
    id: 'noalpha',
    flag: '-noalpha',
    type: ArgType.boolean,
    label: 'Keep all RGB data (even if a=0)',
  ),
  ArgSpec(
    id: 'notime',
    flag: '-notime',
    type: ArgType.boolean,
    label: 'Keep the modification date',
  ),
  ArgSpec(
    id: 'exclude',
    flag: '-no-',
    type: ArgType.multiExclude,
    label: 'Exclude formats (png,jpeg,apng,webp)',
  ),
  ArgSpec(
    id: 'process',
    flag: '-process',
    type: ArgType.integer,
    label: 'Resource level allocation',
    min: 0,
    max: 4,
  ),
  ArgSpec(
    id: 'quiet',
    flag: '-quiet',
    type: ArgType.boolean,
    label: 'Do not show progress or report',
  ),
];

/// Build the arg list from a values map and optional custom args.
///
/// values: keys are spec ids (see `pingoArgSpecs`) mapping to typed values:
/// - integer -> int
/// - boolean -> true/false
/// - enumString for `output` -> 'none'|'jpeg'|'webp'
/// - multiExclude -> `Iterable<String>` of format ids
List<String> buildArgsFromValues(
  Map<String, dynamic> values, [
  List<String>? customArgs,
]) {
  final out = <String>[];

  // compression level 's'
  final s = values['s'];
  if (s is int) {
    out.add('-s$s');
  }

  if (values['lossless'] == true) {
    out.add('-lossless');
  }

  final q = values['quality'];
  if (q is int) {
    out.add('-quality=$q');
  }

  final r = values['resize'];
  if (r is int) {
    out.add('-resize=$r');
  }

  if (values['notrans'] == true) {
    out.add('-notrans');
  }
  if (values['grayscale'] == true) {
    out.add('-grayscale');
  }

  final e = values['enhance'];
  if (e is int) {
    out.add('-enhance=$e');
  }

  if (values['srgb'] == true) {
    out.add('-srgb');
  }
  if (values['rotate'] == true) {
    out.add('-rotate');
  }

  final outFmt = values['output'];
  if (outFmt == 'jpeg') {
    out.add('-jpeg');
  }
  if (outFmt == 'webp') {
    out.add('-webp');
  }

  if (values['nostrip'] == true) {
    out.add('-nostrip');
  }
  if (values['noalpha'] == true) {
    out.add('-noalpha');
  }
  if (values['notime'] == true) {
    out.add('-notime');
  }

  final excludes = values['exclude'];
  if (excludes is Iterable) {
    for (final f in excludes) {
      out.add('-no-$f');
    }
  }

  final proc = values['process'];
  if (proc is int) {
    out.add('-process=$proc');
  }

  if (values['quiet'] == true) {
    out.add('-quiet');
  }

  if (customArgs != null && customArgs.isNotEmpty) {
    out.addAll(customArgs);
  }

  return out;
}

/// Parse a raw pingo arg list into a values map and unknown args.
ParseResult parseArgs(List<String> args) {
  final values = <String, dynamic>{};
  final excludes = <String>{};

  for (var a in args) {
    if (a.startsWith('-s')) {
      final v = int.tryParse(a.substring(2));
      if (v != null) {
        values['s'] = v;
      }
    } else if (a == '-lossless') {
      values['lossless'] = true;
    } else if (a.startsWith('-quality')) {
      final parts = a.split('=');
      var num = parts.length == 2
          ? int.tryParse(parts[1])
          : int.tryParse(a.substring(8));
      if (num != null) {
        values['quality'] = num;
      }
    } else if (a.startsWith('-resize')) {
      final parts = a.split('=');
      var num = parts.length == 2
          ? int.tryParse(parts[1])
          : int.tryParse(a.substring(7));
      if (num != null) {
        values['resize'] = num;
      }
    } else if (a == '-notrans') {
      values['notrans'] = true;
    } else if (a == '-grayscale' || a == '-grayline') {
      values['grayscale'] = true;
    } else if (a.startsWith('-enhance')) {
      final parts = a.split('=');
      var num = parts.length == 2
          ? int.tryParse(parts[1])
          : int.tryParse(a.substring(8));
      if (num != null) {
        values['enhance'] = num;
      }
    } else if (a == '-srgb') {
      values['srgb'] = true;
    } else if (a == '-rotate') {
      values['rotate'] = true;
    } else if (a == '-jpeg') {
      values['output'] = 'jpeg';
    } else if (a == '-webp') {
      values['output'] = 'webp';
    } else if (a == '-nostrip') {
      values['nostrip'] = true;
    } else if (a == '-noalpha') {
      values['noalpha'] = true;
    } else if (a == '-notime') {
      values['notime'] = true;
    } else if (a.startsWith('-no-')) {
      final fmt = a.substring(4);
      if (fmt.isNotEmpty) {
        excludes.add(fmt);
      }
    } else if (a.startsWith('-process')) {
      final parts = a.split('=');
      var num = parts.length == 2
          ? int.tryParse(parts[1])
          : int.tryParse(a.substring(8));
      if (num != null) {
        values['process'] = num;
      }
    } else if (a == '-quiet') {
      values['quiet'] = true;
    }
  }

  if (excludes.isNotEmpty) values['exclude'] = excludes.toList();

  return ParseResult(values);
}
