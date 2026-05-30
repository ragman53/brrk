import 'package:flutter_test/flutter_test.dart';

void main() {
  group('page marker splitting', () {
    final pageMarkerRegex = RegExp(r'<!-- page:\s*(\d+)\s*-->');

    List<String> splitByPageMarkers(String markdown) {
      final matches = pageMarkerRegex.allMatches(markdown).toList();
      if (matches.isEmpty) return [markdown.trim()];
      final sections = <String>[];
      for (int i = 0; i < matches.length; i++) {
        final start = matches[i].end;
        final end = i + 1 < matches.length ? matches[i + 1].start : markdown.length;
        sections.add(markdown.substring(start, end).trim());
      }
      return sections;
    }

    test('no markers returns single section', () {
      final result = splitByPageMarkers('# Hello\n\nSome text.');
      expect(result.length, equals(1));
      expect(result[0], contains('Hello'));
    });

    test('splits by page markers', () {
      const md = '<!-- page: 1 -->\n# Intro\n\nText.\n<!-- page: 2 -->\n# Chapter\n\nMore.';
      final result = splitByPageMarkers(md);
      expect(result.length, equals(2));
      expect(result[0], contains('Intro'));
      expect(result[1], contains('Chapter'));
    });

    test('handles single marker', () {
      const md = '<!-- page: 1 -->\n# Start\n\nText.\n<!-- page: 2 -->\n# End';
      final result = splitByPageMarkers(md);
      expect(result.length, equals(2));
      expect(result[1], contains('End'));
    });
  });

  group('TOC extraction', () {
    final headingRegex = RegExp(r'^(#{1,6})\s+(.+)$', multiLine: true);

    List<Map<String, dynamic>> extractToc(String markdown) {
      final entries = <Map<String, dynamic>>[];
      for (final match in headingRegex.allMatches(markdown)) {
        final level = match.group(1)!.length;
        final text = match.group(2)!.trim();
        if (text.isNotEmpty) entries.add({'level': level, 'text': text});
      }
      return entries;
    }

    test('extracts headings with levels', () {
      const md = '# H1\n## H2\n### H3\n#### H4';
      final toc = extractToc(md);
      expect(toc.length, equals(4));
      expect(toc[0], equals({'level': 1, 'text': 'H1'}));
      expect(toc[3], equals({'level': 4, 'text': 'H4'}));
    });

    test('strips whitespace from heading text', () {
      const md = '#   Hello World   \n##   Section Text  ';
      final toc = extractToc(md);
      expect(toc.length, equals(2));
      expect(toc[0]['text'], equals('Hello World'));
      expect(toc[1]['text'], equals('Section Text'));
    });
  });
}
