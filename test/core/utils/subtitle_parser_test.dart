import 'package:flutter_test/flutter_test.dart';
import 'package:rfplayer/core/utils/subtitle_parser.dart';

void main() {
  group('SubtitleParser.parseContent', () {
    group('SRT', () {
      test('parses valid SRT content', () {
        const content = '''
1
00:00:01,000 --> 00:00:04,000
Hello, World!

2
00:00:05,000 --> 00:00:08,000
This is a test.
''';
        final items = SubtitleParser.parseContent(content, 'srt');

        expect(items.length, 2);
        expect(items[0].index, 1);
        expect(items[0].startTime, const Duration(hours: 0, minutes: 0, seconds: 1, milliseconds: 0));
        expect(items[0].endTime, const Duration(hours: 0, minutes: 0, seconds: 4, milliseconds: 0));
        expect(items[0].content, 'Hello, World!');
        expect(items[1].index, 2);
        expect(items[1].content, 'This is a test.');
      });

      test('parses SRT with hours', () {
        const content = '''
1
01:30:00,500 --> 02:00:00,500
Long video subtitle
''';
        final items = SubtitleParser.parseContent(content, 'srt');

        expect(items.length, 1);
        expect(items[0].startTime, const Duration(hours: 1, minutes: 30, seconds: 0, milliseconds: 500));
        expect(items[0].endTime, const Duration(hours: 2, minutes: 0, seconds: 0, milliseconds: 500));
      });

      test('parses SRT with multiline content', () {
        const content = '''
1
00:00:01,000 --> 00:00:04,000
Line 1
Line 2
''';
        final items = SubtitleParser.parseContent(content, 'srt');

        expect(items.length, 1);
        expect(items[0].content, 'Line 1\nLine 2');
      });

      test('handles empty SRT content', () {
        final items = SubtitleParser.parseContent('', 'srt');
        expect(items, isEmpty);
      });

      test('skips entries with invalid time format', () {
        const content = '''
1
invalid time
Hello
''';
        final items = SubtitleParser.parseContent(content, 'srt');
        expect(items, isEmpty);
      });

      test('handles SRT with comma as decimal separator', () {
        const content = '''
1
00:00:01,500 --> 00:00:04,500
Test
''';
        final items = SubtitleParser.parseContent(content, 'srt');
        expect(items.length, 1);
        expect(items[0].startTime, const Duration(seconds: 1, milliseconds: 500));
      });

      test('handles SRT with period as decimal separator', () {
        const content = '''
1
00:00:01.500 --> 00:00:04.500
Test
''';
        final items = SubtitleParser.parseContent(content, 'srt');
        expect(items.length, 1);
        expect(items[0].startTime, const Duration(seconds: 1, milliseconds: 500));
      });
    });

    group('ASS/SSA', () {
      test('parses valid ASS content', () {
        const content = '''
[Script Info]
Title: Test

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:04.00,Default,,0,0,0,,Hello, World!
Dialogue: 0,0:00:05.00,0:00:08.00,Default,,0,0,0,,Second line
''';
        final items = SubtitleParser.parseContent(content, 'ass');

        expect(items.length, 2);
        expect(items[0].startTime, const Duration(seconds: 1));
        expect(items[0].endTime, const Duration(seconds: 4));
        expect(items[0].content, 'Hello, World!');
        expect(items[1].content, 'Second line');
      });

      test('parses SSA format', () {
        const content = '''
[Events]
Dialogue: 0,0:00:01.00,0:00:04.00,Default,,0,0,0,,Test SSA
''';
        final items = SubtitleParser.parseContent(content, 'ssa');
        expect(items.length, 1);
        expect(items[0].content, 'Test SSA');
      });

      test('handles ASS with \\N line breaks', () {
        const content = '''
[Events]
Dialogue: 0,0:00:01.00,0:00:04.00,Default,,0,0,0,,Line 1\\NLine 2
''';
        final items = SubtitleParser.parseContent(content, 'ass');
        expect(items.length, 1);
        expect(items[0].content, 'Line 1\nLine 2');
      });

      test('ignores non-Dialogue lines in Events section', () {
        const content = '''
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Comment: This is a comment
Dialogue: 0,0:00:01.00,0:00:04.00,Default,,0,0,0,,Actual subtitle
''';
        final items = SubtitleParser.parseContent(content, 'ass');
        expect(items.length, 1);
        expect(items[0].content, 'Actual subtitle');
      });

      test('handles empty ASS content', () {
        const content = '[Events]\nFormat: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text\n';
        final items = SubtitleParser.parseContent(content, 'ass');
        expect(items, isEmpty);
      });
    });

    group('VTT', () {
      test('parses valid VTT content', () {
        const content = '''
WEBVTT

1
00:00:01.000 --> 00:00:04.000
Hello, VTT!

2
00:00:05.000 --> 00:00:08.000
Second cue
''';
        final items = SubtitleParser.parseContent(content, 'vtt');

        expect(items.length, 2);
        expect(items[0].content, 'Hello, VTT!');
        expect(items[1].content, 'Second cue');
      });

      test('parses VTT with short time format (MM:SS.mmm)', () {
        const content = '''
WEBVTT

00:01.000 --> 00:04.000
Short time format
''';
        final items = SubtitleParser.parseContent(content, 'vtt');

        expect(items.length, 1);
        expect(items[0].startTime, const Duration(seconds: 1));
        expect(items[0].endTime, const Duration(seconds: 4));
      });

      test('skips NOTE blocks', () {
        const content = '''
WEBVTT

NOTE This is a note

1
00:00:01.000 --> 00:00:04.000
Actual subtitle
''';
        final items = SubtitleParser.parseContent(content, 'vtt');
        expect(items.length, 1);
        expect(items[0].content, 'Actual subtitle');
      });

      test('handles empty VTT content', () {
        const content = 'WEBVTT\n';
        final items = SubtitleParser.parseContent(content, 'vtt');
        expect(items, isEmpty);
      });
    });

    group('SUB (MicroDVD)', () {
      test('parses MicroDVD format', () {
        const content = '''{100}{200}Hello, MicroDVD!
{300}{400}Second line
''';
        final items = SubtitleParser.parseContent(content, 'sub');

        expect(items.length, 2);
        expect(items[0].content, 'Hello, MicroDVD!');
        expect(items[1].content, 'Second line');
      });

      test('parses MicroDVD with pipe as line separator', () {
        const content = '''{100}{200}Line 1|Line 2
''';
        final items = SubtitleParser.parseContent(content, 'sub');

        expect(items.length, 1);
        expect(items[0].content, 'Line 1\nLine 2');
      });

      test('skips empty text entries', () {
        const content = '{100}{200}\n{300}{400}Valid\n';
        final items = SubtitleParser.parseContent(content, 'sub');
        expect(items.length, 1);
        expect(items[0].content, 'Valid');
      });

      test('parses SubViewer format', () {
        const content = '[00:00:01.00][00:00:04.00]Hello SubViewer\n';
        final items = SubtitleParser.parseContent(content, 'sub');
        expect(items.length, 1);
        expect(items[0].content, 'Hello SubViewer');
      });
    });

    group('TTML/DFXP', () {
      test('parses TTML content', () {
        const content = '''
<tt xmlns="http://www.w3.org/ns/ttml">
<body>
<div>
<p begin="00:00:01.000" end="00:00:04.000">Hello, TTML!</p>
<p begin="00:00:05.000" end="00:00:08.000">Second line</p>
</div>
</body>
</tt>
''';
        final items = SubtitleParser.parseContent(content, 'ttml');

        expect(items.length, 2);
        expect(items[0].content, 'Hello, TTML!');
        expect(items[1].content, 'Second line');
      });

      test('parses DFXP format', () {
        const content = '''
<tt>
<body>
<div>
<p begin="00:00:01.000" end="00:00:04.000">DFXP content</p>
</div>
</body>
</tt>
''';
        final items = SubtitleParser.parseContent(content, 'dfxp');
        expect(items.length, 1);
        expect(items[0].content, 'DFXP content');
      });

      test('handles TTML with HTML entities', () {
        const content = '''
<tt>
<body>
<div>
<p begin="00:00:01.000" end="00:00:04.000">&amp; &lt; &gt;</p>
</div>
</body>
</tt>
''';
        final items = SubtitleParser.parseContent(content, 'ttml');
        expect(items.length, 1);
        expect(items[0].content, '& < >');
      });

      test('skips empty text entries', () {
        const content = '''
<tt>
<body>
<div>
<p begin="00:00:01.000" end="00:00:04.000">   </p>
<p begin="00:00:05.000" end="00:00:08.000">Valid</p>
</div>
</body>
</tt>
''';
        final items = SubtitleParser.parseContent(content, 'ttml');
        expect(items.length, 1);
        expect(items[0].content, 'Valid');
      });

      test('parses TTML with seconds-only time format', () {
        const content = '''
<tt>
<body>
<div>
<p begin="1.5" end="4.5">Seconds format</p>
</div>
</body>
</tt>
''';
        final items = SubtitleParser.parseContent(content, 'ttml');
        expect(items.length, 1);
        expect(items[0].startTime, const Duration(milliseconds: 1500));
        expect(items[0].endTime, const Duration(milliseconds: 4500));
      });

      test('parses TTML with HH:MM:SS time format (no ms)', () {
        const content = '''
<tt>
<body>
<div>
<p begin="00:01:30" end="00:02:00">No ms</p>
</div>
</body>
</tt>
''';
        final items = SubtitleParser.parseContent(content, 'ttml');
        expect(items.length, 1);
        expect(items[0].startTime, const Duration(minutes: 1, seconds: 30));
        expect(items[0].endTime, const Duration(minutes: 2));
      });
    });

    group('SAMI', () {
      test('parses SAMI content', () {
        const content = '''
<SAMI>
<BODY>
<SYNC Start=1000>
<P Class=ENCC>Hello, SAMI!
<SYNC Start=4000>
<P Class=ENCC>&nbsp;
<SYNC Start=5000>
<P Class=ENCC>Second line
<SYNC Start=8000>
<P Class=ENCC>&nbsp;
</BODY>
</SAMI>
''';
        final items = SubtitleParser.parseContent(content, 'smi');

        expect(items.length, 2);
        expect(items[0].content, 'Hello, SAMI!');
        expect(items[0].startTime, const Duration(seconds: 1));
        expect(items[0].endTime, const Duration(seconds: 4));
        expect(items[1].content, 'Second line');
      });

      test('handles SAMI with HTML entities', () {
        const content = '''
<SAMI>
<BODY>
<SYNC Start=1000>
<P Class=ENCC>&amp; &lt; &gt;
<SYNC Start=4000>
<P Class=ENCC>&nbsp;
</BODY>
</SAMI>
''';
        final items = SubtitleParser.parseContent(content, 'smi');
        expect(items.length, 1);
        expect(items[0].content, '& < >');
      });
    });

    group('Error handling', () {
      test('throws for unsupported format', () {
        expect(
          () => SubtitleParser.parseContent('content', 'xyz'),
          throwsUnsupportedError,
        );
      });

      test('throws for empty extension', () {
        expect(
          () => SubtitleParser.parseContent('content', ''),
          throwsUnsupportedError,
        );
      });
    });
  });
}
