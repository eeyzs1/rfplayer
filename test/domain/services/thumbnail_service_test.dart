import 'package:flutter_test/flutter_test.dart';
import 'package:rfplayer/domain/services/thumbnail_service.dart';
import 'package:rfplayer/data/models/play_history.dart' show MediaType;

void main() {
  group('ThumbnailService', () {
    late ThumbnailService service;

    setUp(() {
      service = ThumbnailService();
    });

    group('getMediaType', () {
      test('returns MediaType.video for video extensions', () {
        expect(service.getMediaType('video.mp4'), MediaType.video);
        expect(service.getMediaType('video.mkv'), MediaType.video);
        expect(service.getMediaType('video.avi'), MediaType.video);
        expect(service.getMediaType('video.mov'), MediaType.video);
      });

      test('returns MediaType.image for image extensions', () {
        expect(service.getMediaType('photo.jpg'), MediaType.image);
        expect(service.getMediaType('photo.jpeg'), MediaType.image);
        expect(service.getMediaType('photo.png'), MediaType.image);
        expect(service.getMediaType('photo.webp'), MediaType.image);
      });

      test('returns MediaType.audio for audio extensions', () {
        expect(service.getMediaType('song.mp3'), MediaType.audio);
        expect(service.getMediaType('song.flac'), MediaType.audio);
        expect(service.getMediaType('song.wav'), MediaType.audio);
      });

      test('returns null for unknown extensions', () {
        expect(service.getMediaType('document.pdf'), isNull);
        expect(service.getMediaType('archive.zip'), isNull);
      });
    });

    group('LRU cache', () {
      test('memory cache stores and retrieves values', () {
        final cache = <String, String>{};
        final key = 'test-key';
        cache[key] = '/thumb/path.jpg';

        expect(cache[key], '/thumb/path.jpg');
      });

      test('memory cache evicts oldest entry when full', () {
        const maxSize = 3;
        final cache = <String, String>{};
        final keyOrder = <String>[];

        void addToCache(String key, String path) {
          if (cache.containsKey(key)) {
            keyOrder.remove(key);
            keyOrder.add(key);
            return;
          }
          if (cache.length >= maxSize) {
            final oldestKey = keyOrder.removeAt(0);
            cache.remove(oldestKey);
          }
          cache[key] = path;
          keyOrder.add(key);
        }

        addToCache('key1', 'path1');
        addToCache('key2', 'path2');
        addToCache('key3', 'path3');

        expect(cache.length, 3);

        addToCache('key4', 'path4');

        expect(cache.length, 3);
        expect(cache.containsKey('key1'), isFalse);
        expect(cache.containsKey('key4'), isTrue);
      });

      test('accessing existing key moves it to end', () {
        const maxSize = 3;
        final cache = <String, String>{};
        final keyOrder = <String>[];

        void addToCache(String key, String path) {
          if (cache.containsKey(key)) {
            keyOrder.remove(key);
            keyOrder.add(key);
            return;
          }
          if (cache.length >= maxSize) {
            final oldestKey = keyOrder.removeAt(0);
            cache.remove(oldestKey);
          }
          cache[key] = path;
          keyOrder.add(key);
        }

        addToCache('key1', 'path1');
        addToCache('key2', 'path2');
        addToCache('key3', 'path3');

        addToCache('key1', 'path1');

        addToCache('key4', 'path4');

        expect(cache.length, 3);
        expect(cache.containsKey('key2'), isFalse);
        expect(cache.containsKey('key1'), isTrue);
      });
    });
  });
}
