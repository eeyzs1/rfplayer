import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import '../constants/supported_formats.dart';
import '../../data/models/subtitle.dart';

class SubtitleParser {
  static Future<List<SubtitleItem>> parse(String filePath) async {
    final ext = p.extension(filePath).toLowerCase();
    if (ext.isEmpty) {
      throw UnsupportedError('File has no extension: $filePath');
    }
    final extension = ext.substring(1);

    if (!subtitleFormats.contains(extension)) {
      throw UnsupportedError('Unsupported subtitle format: $extension');
    }

    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final content = _decodeBytes(bytes);

    return parseContent(content, extension);
  }

  static List<SubtitleItem> parseContent(String content, String extension) {
    if (!subtitleFormats.contains(extension)) {
      throw UnsupportedError('Unsupported subtitle format: $extension');
    }

    switch (extension) {
      case 'srt':
        return _parseSrt(content);
      case 'ass':
      case 'ssa':
        return _parseAss(content);
      case 'vtt':
        return _parseVtt(content);
      case 'sub':
        return _parseSub(content);
      case 'dfxp':
      case 'ttml':
        return _parseTtml(content);
      case 'smi':
        return _parseSami(content);
      default:
        throw UnsupportedError('Unsupported subtitle format: $extension');
    }
  }

  static String _decodeBytes(List<int> bytes) {
    if (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
      return utf8.decode(bytes.sublist(3));
    }
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
      return utf8.decode(bytes.sublist(2), allowMalformed: true);
    }
    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      return utf8.decode(bytes.sublist(2), allowMalformed: true);
    }
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return utf8.decode(bytes, allowMalformed: true);
    }
  }

  static List<SubtitleItem> _parseSrt(String content) {
    final items = <SubtitleItem>[];
    final lines = content.split(RegExp(r'\r?\n'));
    int i = 0;

    while (i < lines.length) {
      while (i < lines.length && lines[i].trim().isEmpty) {
        i++;
      }
      if (i >= lines.length) break;

      final indexStr = lines[i].trim();
      final index = int.tryParse(indexStr);
      if (index == null) {
        i++;
        continue;
      }
      i++;

      if (i >= lines.length) break;
      final timeLine = lines[i].trim();
      i++;

      final timeMatch = RegExp(r'(\d{1,2}):(\d{2}):(\d{2})[,.](\d{3})\s*-->\s*(\d{1,2}):(\d{2}):(\d{2})[,.](\d{3})').firstMatch(timeLine);
      if (timeMatch == null) continue;

      final startTime = Duration(
        hours: int.parse(timeMatch.group(1)!),
        minutes: int.parse(timeMatch.group(2)!),
        seconds: int.parse(timeMatch.group(3)!),
        milliseconds: int.parse(timeMatch.group(4)!),
      );

      final endTime = Duration(
        hours: int.parse(timeMatch.group(5)!),
        minutes: int.parse(timeMatch.group(6)!),
        seconds: int.parse(timeMatch.group(7)!),
        milliseconds: int.parse(timeMatch.group(8)!),
      );

      final contentBuffer = StringBuffer();
      while (i < lines.length && lines[i].trim().isNotEmpty) {
        if (contentBuffer.isNotEmpty) contentBuffer.write('\n');
        contentBuffer.write(lines[i].trim());
        i++;
      }

      items.add(SubtitleItem(
        index: index,
        startTime: startTime,
        endTime: endTime,
        content: contentBuffer.toString(),
      ));
    }

    return items;
  }

  static List<SubtitleItem> _parseAss(String content) {
    final items = <SubtitleItem>[];
    final lines = content.split(RegExp(r'\r?\n'));
    bool inEvents = false;

    for (final line in lines) {
      final trimmedLine = line.trim();

      if (trimmedLine.startsWith('[Events]')) {
        inEvents = true;
        continue;
      }

      if (trimmedLine.startsWith('[')) {
        inEvents = false;
        continue;
      }

      if (!inEvents || !trimmedLine.startsWith('Dialogue:')) continue;

      final parts = trimmedLine.substring('Dialogue:'.length).split(',');
      if (parts.length < 10) continue;

      final startTime = _parseAssTime(parts[1].trim());
      final endTime = _parseAssTime(parts[2].trim());
      final content = parts.sublist(9).join(',').replaceAll(r'\N', '\n').replaceAll(r'\n', '\n');

      items.add(SubtitleItem(
        index: items.length + 1,
        startTime: startTime,
        endTime: endTime,
        content: content,
      ));
    }

    return items;
  }

  static Duration _parseAssTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length == 3) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      final secondsParts = parts[2].split('.');
      final seconds = int.tryParse(secondsParts[0]) ?? 0;
      int milliseconds = 0;
      if (secondsParts.length > 1) {
        final msStr = secondsParts[1];
        if (msStr.length == 2) {
          milliseconds = (int.tryParse(msStr) ?? 0) * 10;
        } else if (msStr.length >= 3) {
          milliseconds = int.tryParse(msStr.substring(0, 3)) ?? 0;
        }
      }
      return Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds,
        milliseconds: milliseconds,
      );
    }
    return Duration.zero;
  }

  static List<SubtitleItem> _parseVtt(String content) {
    final items = <SubtitleItem>[];
    final lines = content.split(RegExp(r'\r?\n'));
    int i = 0;

    while (i < lines.length && !lines[i].trim().startsWith('WEBVTT')) {
      i++;
    }
    if (i < lines.length) i++;

    while (i < lines.length) {
      while (i < lines.length && (lines[i].trim().isEmpty || lines[i].trim().startsWith('NOTE'))) {
        i++;
      }
      if (i >= lines.length) break;

      int? index;
      final indexStr = lines[i].trim();
      if (RegExp(r'^\d+$').hasMatch(indexStr)) {
        index = int.parse(indexStr);
        i++;
      }

      if (i >= lines.length) break;

      final timeLine = lines[i].trim();
      i++;

      final timeMatch = RegExp(r'(\d{1,2}):(\d{2}):(\d{2})\.(\d{3})\s*-->\s*(\d{1,2}):(\d{2}):(\d{2})\.(\d{3})').firstMatch(timeLine);
      final shortTimeMatch = RegExp(r'(\d{1,2}):(\d{2})\.(\d{3})\s*-->\s*(\d{1,2}):(\d{2})\.(\d{3})').firstMatch(timeLine);

      Duration startTime;
      Duration endTime;

      if (timeMatch != null) {
        startTime = Duration(
          hours: int.parse(timeMatch.group(1)!),
          minutes: int.parse(timeMatch.group(2)!),
          seconds: int.parse(timeMatch.group(3)!),
          milliseconds: int.parse(timeMatch.group(4)!),
        );
        endTime = Duration(
          hours: int.parse(timeMatch.group(5)!),
          minutes: int.parse(timeMatch.group(6)!),
          seconds: int.parse(timeMatch.group(7)!),
          milliseconds: int.parse(timeMatch.group(8)!),
        );
      } else if (shortTimeMatch != null) {
        startTime = Duration(
          minutes: int.parse(shortTimeMatch.group(1)!),
          seconds: int.parse(shortTimeMatch.group(2)!),
          milliseconds: int.parse(shortTimeMatch.group(3)!),
        );
        endTime = Duration(
          minutes: int.parse(shortTimeMatch.group(4)!),
          seconds: int.parse(shortTimeMatch.group(5)!),
          milliseconds: int.parse(shortTimeMatch.group(6)!),
        );
      } else {
        continue;
      }

      final contentBuffer = StringBuffer();
      while (i < lines.length && lines[i].trim().isNotEmpty && !lines[i].trim().startsWith('NOTE')) {
        if (contentBuffer.isNotEmpty) contentBuffer.write('\n');
        contentBuffer.write(lines[i].trim());
        i++;
      }

      items.add(SubtitleItem(
        index: index ?? items.length + 1,
        startTime: startTime,
        endTime: endTime,
        content: contentBuffer.toString(),
      ));
    }

    return items;
  }

  static List<SubtitleItem> _parseSub(String content) {
    final items = <SubtitleItem>[];
    final lines = content.split(RegExp(r'\r?\n'));
    double fps = 23.976;

    final firstLineMatch = RegExp(r'^\{1\}\{1\}(\d+(?:\.\d+)?)$').firstMatch(lines.first.trim());
    if (firstLineMatch != null) {
      fps = double.tryParse(firstLineMatch.group(1)!) ?? 23.976;
    }

    final microDvdRegex = RegExp(r'^\{(\d+)\}\{(\d+)\}(.*)$');
    final subViewerRegex = RegExp(r'^\[(\d{1,2}:\d{2}:\d{2}\.\d{2,3})\]\[(\d{1,2}:\d{2}:\d{2}\.\d{2,3})\](.*)$');

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      final microMatch = microDvdRegex.firstMatch(trimmedLine);
      if (microMatch != null) {
        final startFrame = int.tryParse(microMatch.group(1)!) ?? 0;
        final endFrame = int.tryParse(microMatch.group(2)!) ?? 0;
        final text = microMatch.group(3)?.trim() ?? '';
        if (text.isEmpty) continue;

        final startTime = Duration(milliseconds: (startFrame / fps * 1000).round());
        final endTime = Duration(milliseconds: (endFrame / fps * 1000).round());

        items.add(SubtitleItem(
          index: items.length + 1,
          startTime: startTime,
          endTime: endTime,
          content: text.replaceAll('|', '\n'),
        ));
        continue;
      }

      final svMatch = subViewerRegex.firstMatch(trimmedLine);
      if (svMatch != null) {
        final startTime = _parseSubViewerTime(svMatch.group(1)!);
        final endTime = _parseSubViewerTime(svMatch.group(2)!);
        final text = svMatch.group(3)?.trim() ?? '';
        if (text.isEmpty) continue;

        items.add(SubtitleItem(
          index: items.length + 1,
          startTime: startTime,
          endTime: endTime,
          content: text,
        ));
      }
    }

    return items;
  }

  static Duration _parseSubViewerTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length == 3) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      final secParts = parts[2].split('.');
      final seconds = int.tryParse(secParts[0]) ?? 0;
      int milliseconds = 0;
      if (secParts.length > 1) {
        final msStr = secParts[1];
        if (msStr.length == 2) {
          milliseconds = (int.tryParse(msStr) ?? 0) * 10;
        } else if (msStr.length >= 3) {
          milliseconds = int.tryParse(msStr.substring(0, 3)) ?? 0;
        }
      }
      return Duration(hours: hours, minutes: minutes, seconds: seconds, milliseconds: milliseconds);
    }
    return Duration.zero;
  }

  static List<SubtitleItem> _parseTtml(String content) {
    final items = <SubtitleItem>[];
    final pRegex = RegExp(r'<p\b[^>]*\bbegin="([^"]*)"[^>]*\bend="([^"]*)"[^>]*>(.*?)</p>', dotAll: true);
    final pRegexAlt = RegExp(r'<p\b[^>]*\bend="([^"]*)"[^>]*\bbegin="([^"]*)"[^>]*>(.*?)</p>', dotAll: true);

    for (final regex in [pRegex, pRegexAlt]) {
      for (final match in regex.allMatches(content)) {
        final beginStr = match.group(1)!;
        final endStr = match.group(2)!;
        final rawText = match.group(3) ?? '';

        final startTime = _parseTtmlTime(beginStr);
        final endTime = _parseTtmlTime(endStr);
        final text = rawText
            .replaceAll(RegExp(r'<[^>]+>'), '')
            .replaceAll('&amp;', '&')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&nbsp;', ' ')
            .replaceAll('&#160;', ' ')
            .trim();

        if (text.isEmpty) continue;

        items.add(SubtitleItem(
          index: items.length + 1,
          startTime: startTime,
          endTime: endTime,
          content: text,
        ));
      }
    }

    return items;
  }

  static Duration _parseTtmlTime(String timeStr) {
    final hhmmssms = RegExp(r'(\d{1,2}):(\d{2}):(\d{2})\.(\d{1,3})').firstMatch(timeStr);
    if (hhmmssms != null) {
      final hours = int.tryParse(hhmmssms.group(1)!) ?? 0;
      final minutes = int.tryParse(hhmmssms.group(2)!) ?? 0;
      final seconds = int.tryParse(hhmmssms.group(3)!) ?? 0;
      var msStr = hhmmssms.group(4)!;
      while (msStr.length < 3) {
        msStr += '0';
      }
      final milliseconds = int.tryParse(msStr.substring(0, 3)) ?? 0;
      return Duration(hours: hours, minutes: minutes, seconds: seconds, milliseconds: milliseconds);
    }

    final hhmmss = RegExp(r'(\d{1,2}):(\d{2}):(\d{2})').firstMatch(timeStr);
    if (hhmmss != null) {
      return Duration(
        hours: int.tryParse(hhmmss.group(1)!) ?? 0,
        minutes: int.tryParse(hhmmss.group(2)!) ?? 0,
        seconds: int.tryParse(hhmmss.group(3)!) ?? 0,
      );
    }

    final secondsOnly = double.tryParse(timeStr);
    if (secondsOnly != null) {
      return Duration(milliseconds: (secondsOnly * 1000).round());
    }

    return Duration.zero;
  }

  static List<SubtitleItem> _parseSami(String content) {
    final items = <SubtitleItem>[];
    final syncRegex = RegExp(r'<SYNC\s+Start=(\d+)>', caseSensitive: false);
    final allSyncs = <int>[];
    final allTexts = <String>[];

    for (final match in syncRegex.allMatches(content)) {
      allSyncs.add(int.tryParse(match.group(1)!) ?? 0);
      final afterSync = content.substring(match.end);
      final nextSync = syncRegex.firstMatch(afterSync);
      final block = nextSync != null ? afterSync.substring(0, nextSync.start) : afterSync;

      final pMatch = RegExp(r'<P\b[^>]*>(.*?)(?=</P>|<SYNC|$)', caseSensitive: false, dotAll: true).firstMatch(block);
      String text;
      if (pMatch != null) {
        text = pMatch.group(1)!;
      } else {
        final afterP = RegExp(r'<P\b[^>]*>', caseSensitive: false).firstMatch(block);
        if (afterP != null) {
          text = block.substring(afterP.end);
        } else {
          text = block;
        }
      }

      text = text
          .replaceAll(RegExp(r'<[^>]+>'), '')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&#160;', ' ')
          .trim();

      allTexts.add(text);
    }

    for (int i = 0; i < allSyncs.length; i++) {
      final text = allTexts[i];
      if (text.isEmpty) continue;

      final startTime = Duration(milliseconds: allSyncs[i]);
      final endTime = i + 1 < allSyncs.length
          ? Duration(milliseconds: allSyncs[i + 1])
          : startTime + const Duration(seconds: 3);

      items.add(SubtitleItem(
        index: items.length + 1,
        startTime: startTime,
        endTime: endTime,
        content: text,
      ));
    }

    return items;
  }
}
