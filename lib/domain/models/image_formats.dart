import 'package:path/path.dart' as p;

/// Image formats the optimizer understands.
///
/// `.jxl` is included because existing JPEG XL pages are kept as-is, but it is
/// never re-encoded (see [isEncodableImage]).
const Set<String> kImageExtensions = {
  '.png',
  '.jpg',
  '.jpeg',
  '.webp',
  '.apng',
  '.jxl',
};

/// Archive extensions offered as output.
const List<String> kOutputExtensions = ['.cbz', '.zip'];

/// Whether [path] points at a supported image, regardless of case.
bool isSupportedImage(String path) =>
    kImageExtensions.contains(p.extension(path).toLowerCase());

/// Whether [path] should be passed to the encoder.
///
/// Every supported image except `.jxl` is encodable; existing `.jxl` files are
/// preserved instead of being re-encoded.
bool isEncodableImage(String path) {
  final ext = p.extension(path).toLowerCase();
  return kImageExtensions.contains(ext) && ext != '.jxl';
}
