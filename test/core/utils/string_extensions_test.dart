import 'package:flutter_test/flutter_test.dart';
import 'package:rfplayer/core/extensions/string_extensions.dart';

void main() {
  group('StringExtensions.fileExtension', () {
    test('extracts extension from filename', () {
      expect('video.mp4'.fileExtension, 'mp4');
    });

    test('extracts extension from full path', () {
      expect('/path/to/video.mkv'.fileExtension, 'mkv');
    });

    test('returns lowercase extension', () {
      expect('video.MP4'.fileExtension, 'mp4');
    });

    test('returns empty string for no extension', () {
      expect('noextension'.fileExtension, '');
    });

    test('returns empty string for trailing dot', () {
      expect('trailing.'.fileExtension, '');
    });

    test('extracts last extension from double extension', () {
      expect('archive.tar.gz'.fileExtension, 'gz');
    });
  });

  group('StringExtensions.isVideoFile', () {
    test('returns true for video files', () {
      expect('movie.mp4'.isVideoFile, isTrue);
      expect('movie.mkv'.isVideoFile, isTrue);
      expect('movie.avi'.isVideoFile, isTrue);
    });

    test('returns false for non-video files', () {
      expect('photo.jpg'.isVideoFile, isFalse);
      expect('song.mp3'.isVideoFile, isFalse);
      expect('sub.srt'.isVideoFile, isFalse);
    });
  });

  group('StringExtensions.isImageFile', () {
    test('returns true for image files', () {
      expect('photo.jpg'.isImageFile, isTrue);
      expect('photo.png'.isImageFile, isTrue);
      expect('photo.webp'.isImageFile, isTrue);
    });

    test('returns false for non-image files', () {
      expect('movie.mp4'.isImageFile, isFalse);
      expect('song.mp3'.isImageFile, isFalse);
    });
  });

  group('StringExtensions.isAudioFile', () {
    test('returns true for audio files', () {
      expect('song.mp3'.isAudioFile, isTrue);
      expect('song.flac'.isAudioFile, isTrue);
      expect('song.opus'.isAudioFile, isTrue);
    });

    test('returns false for non-audio files', () {
      expect('movie.mp4'.isAudioFile, isFalse);
      expect('photo.jpg'.isAudioFile, isFalse);
    });
  });

  group('StringExtensionChecks', () {
    test('isVideoExtension checks correctly', () {
      expect('mp4'.isVideoExtension, isTrue);
      expect('mkv'.isVideoExtension, isTrue);
      expect('jpg'.isVideoExtension, isFalse);
    });

    test('isImageExtension checks correctly', () {
      expect('jpg'.isImageExtension, isTrue);
      expect('png'.isImageExtension, isTrue);
      expect('mp4'.isImageExtension, isFalse);
    });

    test('isAudioExtension checks correctly', () {
      expect('mp3'.isAudioExtension, isTrue);
      expect('flac'.isAudioExtension, isTrue);
      expect('mp4'.isAudioExtension, isFalse);
    });
  });
}
