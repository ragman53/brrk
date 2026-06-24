import 'package:brrk/src/app/reader/reader_markdown_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('planReaderMarkdown', () {
    test('empty markdown produces an empty native plan', () {
      final plan = planReaderMarkdown('');
      expect(plan, isA<NativeReaderPlan>());
      expect(plan.strategy, ReaderRenderStrategy.nativeProse);
      expect((plan as NativeReaderPlan).blocks, isEmpty);
    });

    test('single plain paragraph', () {
      final plan = planReaderMarkdown('A philosophical investigation.');
      expect(plan, isA<NativeReaderPlan>());
      final blocks = (plan as NativeReaderPlan).blocks;
      expect(blocks, hasLength(1));
      final p = blocks.single as ReaderParagraphBlock;
      expect(p.text, 'A philosophical investigation.');
      expect(p.sourceStart, 0);
      expect(p.sourceEnd, 'A philosophical investigation.'.length);
    });

    test('multiple plain paragraphs separated by blank lines', () {
      const source = 'First paragraph.\n\nSecond paragraph.';
      final plan = planReaderMarkdown(source);
      final blocks = (plan as NativeReaderPlan).blocks;
      expect(blocks, hasLength(2));
      expect((blocks[0] as ReaderParagraphBlock).text, 'First paragraph.');
      expect((blocks[1] as ReaderParagraphBlock).text, 'Second paragraph.');
      expect(
        (blocks[1] as ReaderParagraphBlock).sourceStart,
        source.indexOf('Second paragraph.'),
      );
    });

    test('h1..h6 + plain paragraphs render as native blocks', () {
      const source =
          '# H1\n\n## H2\n\n### H3\n\n#### H4\n\n##### H5\n\n###### H6\n\nbody';
      final plan = planReaderMarkdown(source);
      expect(plan, isA<NativeReaderPlan>());
      final blocks = (plan as NativeReaderPlan).blocks;
      expect(blocks.length, 7);
      for (var i = 0; i < 6; i++) {
        final heading = blocks[i] as ReaderHeadingBlock;
        expect(heading.level, i + 1);
        expect(heading.text, 'H${i + 1}');
      }
      expect((blocks[6] as ReaderParagraphBlock).text, 'body');
    });

    test('horizontal rule', () {
      final plan = planReaderMarkdown('a\n\n---\n\nb');
      final blocks = (plan as NativeReaderPlan).blocks;
      expect(blocks.length, 3);
      expect(blocks[1], isA<ReaderHorizontalRuleBlock>());
    });

    test('ignorable HTML comment is silently skipped', () {
      const source = '<!-- page: 1 -->\n\nHello.';
      final plan = planReaderMarkdown(source);
      final blocks = (plan as NativeReaderPlan).blocks;
      expect(blocks, hasLength(1));
      expect((blocks.single as ReaderParagraphBlock).text, 'Hello.');
    });

    test('heading source offsets exclude the marker', () {
      const source = '# Hello world';
      final plan = planReaderMarkdown(source);
      final heading =
          (plan as NativeReaderPlan).blocks.single as ReaderHeadingBlock;
      expect(heading.text, 'Hello world');
      expect(heading.sourceStart, 2);
      expect(heading.sourceEnd, 2 + 'Hello world'.length);
    });

    test('paragraph source offsets cover paragraph text only', () {
      const source = 'alpha\n\nbeta';
      final plan = planReaderMarkdown(source);
      final blocks = (plan as NativeReaderPlan).blocks;
      final p = blocks.last as ReaderParagraphBlock;
      expect(p.text, 'beta');
      expect(p.sourceStart, source.indexOf('beta'));
      expect(p.sourceEnd, source.length);
    });

    test('inline emphasis forces fallback', () {
      final plan = planReaderMarkdown('this is *italic*');
      expect(plan, isA<LegacyMarkdownPlan>());
      expect(
        (plan as LegacyMarkdownPlan).reason,
        contains('unsupported inline syntax'),
      );
    });

    test('strong forces fallback', () {
      final plan = planReaderMarkdown('this is **bold**');
      expect(plan, isA<LegacyMarkdownPlan>());
    });

    test('link forces fallback', () {
      final plan = planReaderMarkdown('see [docs](https://example.com)');
      expect(plan, isA<LegacyMarkdownPlan>());
    });

    test('image forces fallback', () {
      final plan = planReaderMarkdown('![alt](https://example.com/x.png)');
      expect(plan, isA<LegacyMarkdownPlan>());
    });

    test('inline code forces fallback', () {
      final plan = planReaderMarkdown('use `foo()` here');
      expect(plan, isA<LegacyMarkdownPlan>());
    });

    test('fenced code forces fallback', () {
      final plan = planReaderMarkdown('text\n\n```\ncode\n```');
      expect(plan, isA<LegacyMarkdownPlan>());
      expect((plan as LegacyMarkdownPlan).reason, contains('fenced code'));
    });

    test('unordered list forces fallback', () {
      final plan = planReaderMarkdown('- one\n- two');
      expect(plan, isA<LegacyMarkdownPlan>());
    });

    test('ordered list forces fallback', () {
      final plan = planReaderMarkdown('1. one\n2. two');
      expect(plan, isA<LegacyMarkdownPlan>());
    });

    test('blockquote forces fallback', () {
      final plan = planReaderMarkdown('> quoted');
      expect(plan, isA<LegacyMarkdownPlan>());
    });

    test('table forces fallback', () {
      final plan = planReaderMarkdown('| a | b |\n| - | - |\n| 1 | 2 |');
      expect(plan, isA<LegacyMarkdownPlan>());
    });

    test('raw HTML forces fallback', () {
      final plan = planReaderMarkdown('<div>raw</div>');
      expect(plan, isA<LegacyMarkdownPlan>());
    });

    test('multiline plain paragraph joins source lines with spaces', () {
      const source =
          'This is one OCR text line\ncontinued on the next visual line\nand continued again.';
      final plan = planReaderMarkdown(source);
      expect(plan, isA<NativeReaderPlan>());
      final blocks = (plan as NativeReaderPlan).blocks;
      expect(blocks, hasLength(1));
      final p = blocks.single as ReaderParagraphBlock;
      expect(
        p.text,
        'This is one OCR text line continued on the next visual line'
        ' and continued again.',
      );
      expect(p.sourceStart, isNull);
      expect(p.sourceEnd, isNull);
    });

    test('multiline paragraph visible text contains no U+00AD', () {
      final plan = planReaderMarkdown('line one\nline two');
      final p =
          (plan as NativeReaderPlan).blocks.single as ReaderParagraphBlock;
      expect(p.text.contains('\u00AD'), isFalse);
    });

    test('multiline with unsupported inline still falls back', () {
      final plan = planReaderMarkdown('line one\nline *italic*');
      expect(plan, isA<LegacyMarkdownPlan>());
    });

    test('single line plain paragraph is still native with exact offsets', () {
      final plan = planReaderMarkdown('A single line.');
      final blocks = (plan as NativeReaderPlan).blocks;
      expect(blocks, hasLength(1));
      final p = blocks.single as ReaderParagraphBlock;
      expect(p.text, 'A single line.');
      expect(p.sourceStart, 0);
      expect(p.sourceEnd, 'A single line.'.length);
    });

    test('heading punctuation such as colon remains native', () {
      final plan = planReaderMarkdown('## Chapter 1: Overview');
      expect(plan, isA<NativeReaderPlan>());
      final heading =
          (plan as NativeReaderPlan).blocks.single as ReaderHeadingBlock;
      expect(heading.text, 'Chapter 1: Overview');
    });

    test('isolated HTML comment between blocks is silently skipped', () {
      const source = 'Hello\n\n<!-- page: 1 -->\n\nWorld';
      final plan = planReaderMarkdown(source);
      expect(plan, isA<NativeReaderPlan>());
      final blocks = (plan as NativeReaderPlan).blocks;
      expect(blocks, hasLength(2));
      expect((blocks[0] as ReaderParagraphBlock).text, 'Hello');
      expect((blocks[1] as ReaderParagraphBlock).text, 'World');
    });

    test('page marker comment alone is skipped as native', () {
      final plan = planReaderMarkdown('<!-- page: 1 -->\n\nHello');
      expect(plan, isA<NativeReaderPlan>());
      final blocks = (plan as NativeReaderPlan).blocks;
      expect(blocks, hasLength(1));
      expect((blocks.single as ReaderParagraphBlock).text, 'Hello');
    });

    test('setext-style underline after a paragraph forces fallback', () {
      final plan = planReaderMarkdown('Title\n---');
      expect(plan, isA<LegacyMarkdownPlan>());
      expect(
        (plan as LegacyMarkdownPlan).reason,
        contains('possible setext heading'),
      );
    });

    test('indented heading-like line forces fallback', () {
      final plan = planReaderMarkdown('    # Not a native heading');
      expect(plan, isA<LegacyMarkdownPlan>());
      expect((plan as LegacyMarkdownPlan).reason, contains('indented block'));
    });

    test('indented rule-like line forces fallback', () {
      final plan = planReaderMarkdown('    ---');
      expect(plan, isA<LegacyMarkdownPlan>());
      expect((plan as LegacyMarkdownPlan).reason, contains('indented block'));
    });

    test('ATX closing marker forces fallback', () {
      final plan = planReaderMarkdown('# Heading #');
      expect(plan, isA<LegacyMarkdownPlan>());
      expect(
        (plan as LegacyMarkdownPlan).reason,
        contains('unsupported heading close marker'),
      );
    });

    test('unsupported ATX heading forms force fallback', () {
      final hashtag = planReaderMarkdown('# #hashtag');
      expect(hashtag, isA<LegacyMarkdownPlan>());
      expect(
        (hashtag as LegacyMarkdownPlan).reason,
        contains('unsupported heading syntax'),
      );

      final empty = planReaderMarkdown('# #');
      expect(empty, isA<LegacyMarkdownPlan>());
      expect(
        (empty as LegacyMarkdownPlan).reason,
        contains('unsupported heading syntax'),
      );

      final extraSpace = planReaderMarkdown('#  Heading');
      expect(extraSpace, isA<LegacyMarkdownPlan>());
      expect(
        (extraSpace as LegacyMarkdownPlan).reason,
        contains('unsupported heading syntax'),
      );
    });

    test('backslash escapes force fallback', () {
      final plan = planReaderMarkdown(r'Escaped \[bracket]');
      expect(plan, isA<LegacyMarkdownPlan>());
      expect(
        (plan as LegacyMarkdownPlan).reason,
        contains('unsupported inline'),
      );
    });

    test('reference-style links force fallback', () {
      final plan = planReaderMarkdown(
        'See [foo][bar].\n\n[bar]: https://example.com',
      );
      expect(plan, isA<LegacyMarkdownPlan>());
    });
  });
}
