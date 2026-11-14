import 'package:comic_optimizer/domain/models/image_formats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('image formats', () {
    test('recognizes supported images case-insensitively', () {
      for (final name in [
        'page.png',
        'page.JPG',
        'page.jpeg',
        'page.webp',
        'page.apng',
        'page.jxl',
        r'C:\comics\001.PNG',
      ]) {
        expect(isSupportedImage(name), true, reason: name);
      }
    });

    test('rejects unsupported extensions', () {
      for (final name in ['page.gif', 'page.bmp', 'ComicInfo.xml', 'page']) {
        expect(isSupportedImage(name), false, reason: name);
      }
    });

    test('existing jxl pages are kept but not re-encoded', () {
      expect(isSupportedImage('001.jxl'), true);
      expect(isEncodableImage('001.jxl'), false);
      expect(isEncodableImage('001.png'), true);
      expect(isEncodableImage('001.webp'), true);
    });

    test('output extensions are the ones offered in the UI', () {
      expect(kOutputExtensions, ['.cbz', '.zip']);
      expect(kOutputExtensions, isNot(contains('.cbr')));
    });
  });
}
