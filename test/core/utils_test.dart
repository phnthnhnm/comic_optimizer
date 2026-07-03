import 'dart:io';

import 'package:comic_optimizer/core/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('naturalCompare', () {
    test('identical strings are equal', () {
      expect(naturalCompare('abc', 'abc'), 0);
    });

    test('basic alphabetical ordering', () {
      expect(naturalCompare('a', 'b'), lessThan(0));
      expect(naturalCompare('b', 'a'), greaterThan(0));
    });

    test('numeric chunks compared numerically', () {
      // "2" < "10" numerically (unlike lexicographic where "10" < "2")
      expect(naturalCompare('2', '10'), lessThan(0));
      expect(naturalCompare('10', '2'), greaterThan(0));
    });

    test('mixed text and numbers', () {
      expect(naturalCompare('page1', 'page2'), lessThan(0));
      expect(naturalCompare('page10', 'page2'), greaterThan(0));
      expect(naturalCompare('page1', 'page10'), lessThan(0));
    });

    test('different length strings fall back to length comparison', () {
      // "abc" shorter than "abcd" when prefix is identical
      expect(naturalCompare('abc', 'abcd'), lessThan(0));
    });

    test('multi-digit numbers compare correctly', () {
      expect(naturalCompare('img99', 'img100'), lessThan(0));
      expect(naturalCompare('img100', 'img99'), greaterThan(0));
    });

    test('leading zeros in numbers treated as numbers', () {
      // "01" = 1, "2" = 2, so "01" < "2"
      expect(naturalCompare('img01', 'img2'), lessThan(0));
    });
  });

  group('makeMaskPath', () {
    test('shortens paths inside folder to basename', () {
      final mask = makeMaskPath(r'C:\comics\manga', r'C:\comics\manga');

      // Path inside folder → basename only
      final result = mask(r'C:\comics\manga\page01.png');
      expect(result, 'page01.png');
    });

    test('shortens folder path itself to basename', () {
      final mask = makeMaskPath(r'C:\comics\manga', r'C:\comics\manga');

      final result = mask(r'C:\comics\manga');
      expect(result, 'manga');
    });

    test('shortens original path itself to basename', () {
      final mask = makeMaskPath(r'C:\temp\working', r'C:\comics\manga');

      final result = mask(r'C:\comics\manga');
      expect(result, 'manga');
    });

    test('returns unchanged for paths outside both folder and original', () {
      final mask = makeMaskPath(r'C:\comics\manga', r'C:\comics\manga');

      final unrelated = r'D:\other\file.txt';
      final result = mask(unrelated);
      expect(result, unrelated);
    });

    test('empty string returns empty', () {
      final mask = makeMaskPath(r'C:\comics', r'C:\comics');
      expect(mask(''), '');
    });
  });

  group('storageSummaryText', () {
    test('formats with folder name and includeFolderName=true', () {
      final text = storageSummaryText(
        folderName: 'MyManga',
        beforeBytes: 1048576, // 1 MB
        afterBytes: 524288, // 0.5 MB
        includeFolderName: true,
      );
      expect(text, contains('MyManga'));
    });

    test('omits folder name when includeFolderName=false', () {
      final text = storageSummaryText(
        folderName: 'MyManga',
        beforeBytes: 1048576,
        afterBytes: 524288,
        includeFolderName: false,
      );
      expect(text, isNot(contains('MyManga')));
      expect(text, contains('Storage saved'));
    });

    test('handles null beforeBytes', () {
      final text = storageSummaryText(
        folderName: 'Test',
        beforeBytes: null,
        afterBytes: 100,
      );
      expect(text, contains('size unknown'));
    });

    test('handles null afterBytes', () {
      final text = storageSummaryText(
        folderName: 'Test',
        beforeBytes: 100,
        afterBytes: null,
      );
      expect(text, contains('size unknown'));
    });

    test('shows positive savings', () {
      final text = storageSummaryText(
        beforeBytes: 1000000,
        afterBytes: 500000,
        includeFolderName: false,
      );
      expect(text, contains('saved'));
      expect(text, contains('%'));
    });

    test('shows zero savings when sizes equal', () {
      final text = storageSummaryText(
        beforeBytes: 1000,
        afterBytes: 1000,
        includeFolderName: false,
      );
      expect(text, contains('0.00%'));
    });
  });

  group('sumFileLengths', () {
    test('returns sum of file sizes', () async {
      // Create temp files with known sizes
      final dir = Directory.systemTemp.createTempSync('test_sum_');
      try {
        final f1 = File('${dir.path}/a.bin')..writeAsBytesSync([1, 2, 3]);
        final f2 = File('${dir.path}/b.bin')..writeAsBytesSync([4, 5]);
        final result = await sumFileLengths([f1, f2]);
        expect(result, 5);
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('returns 0 for empty list', () async {
      final result = await sumFileLengths([]);
      expect(result, 0);
    });
  });
}
