import 'package:flutter_test/flutter_test.dart';
import 'package:rfplayer/core/constants/supported_formats.dart';

void main() {
  group('supported_formats', () {
    test('videoFormats contains expected formats', () {
      expect(videoFormats.contains('mp4'), isTrue);
      expect(videoFormats.contains('mkv'), isTrue);
      expect(videoFormats.contains('avi'), isTrue);
      expect(videoFormats.contains('mov'), isTrue);
      expect(videoFormats.contains('webm'), isTrue);
      expect(videoFormats.contains('rmvb'), isTrue);
    });

    test('imageFormats contains expected formats', () {
      expect(imageFormats.contains('jpg'), isTrue);
      expect(imageFormats.contains('jpeg'), isTrue);
      expect(imageFormats.contains('png'), isTrue);
      expect(imageFormats.contains('gif'), isTrue);
      expect(imageFormats.contains('webp'), isTrue);
    });

    test('audioFormats contains expected formats', () {
      expect(audioFormats.contains('mp3'), isTrue);
      expect(audioFormats.contains('flac'), isTrue);
      expect(audioFormats.contains('wav'), isTrue);
      expect(audioFormats.contains('opus'), isTrue);
      expect(audioFormats.contains('alac'), isTrue);
    });

    test('subtitleFormats contains expected formats', () {
      expect(subtitleFormats.contains('srt'), isTrue);
      expect(subtitleFormats.contains('ass'), isTrue);
      expect(subtitleFormats.contains('ssa'), isTrue);
      expect(subtitleFormats.contains('vtt'), isTrue);
      expect(subtitleFormats.contains('sub'), isTrue);
    });

    test('format sets do not overlap', () {
      final allFormats = <String>{
        ...videoFormats,
        ...imageFormats,
        ...audioFormats,
        ...subtitleFormats,
      };
      expect(
        allFormats.length,
        videoFormats.length + imageFormats.length + audioFormats.length + subtitleFormats.length,
        reason: 'Format sets should not overlap',
      );
    });

    test('isVideoFile returns true for video paths', () {
      expect(isVideoFile('/path/to/movie.mp4'), isTrue);
      expect(isVideoFile('/path/to/movie.mkv'), isTrue);
    });

    test('isVideoFile returns false for non-video paths', () {
      expect(isVideoFile('/path/to/photo.jpg'), isFalse);
      expect(isVideoFile('/path/to/song.mp3'), isFalse);
    });

    test('isImageFile returns true for image paths', () {
      expect(isImageFile('/path/to/photo.jpg'), isTrue);
      expect(isImageFile('/path/to/photo.png'), isTrue);
    });

    test('isAudioFile returns true for audio paths', () {
      expect(isAudioFile('/path/to/song.mp3'), isTrue);
      expect(isAudioFile('/path/to/song.flac'), isTrue);
    });

    test('isSubtitleFile returns true for subtitle paths', () {
      expect(isSubtitleFile('/path/to/sub.srt'), isTrue);
      expect(isSubtitleFile('/path/to/sub.ass'), isTrue);
    });

    test('isVideoFile handles case insensitivity', () {
      expect(isVideoFile('/path/to/movie.MP4'), isTrue);
      expect(isVideoFile('/path/to/movie.Mkv'), isTrue);
    });

    test('isVideoFile returns false for path without extension', () {
      expect(isVideoFile('/path/to/noextension'), isFalse);
    });
  });
}
