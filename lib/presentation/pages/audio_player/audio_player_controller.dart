import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';
import '../../../domain/services/playback_history_service.dart';
import '../../../domain/services/play_queue_service.dart';
import 'dart:async';
import 'dart:io';

class AudioPlayerController {
  late final VideoPlayerController _videoController;
  final String path;
  final String? fileName;
  final String _historyPath;
  final PlaybackHistoryService _historyService;
  final PlayQueueService _playQueueService;
  final void Function() _onStateChanged;
  Timer? _positionTimer;
  VoidCallback? _videoControllerListener;
  bool _disposed = false;

  AudioPlayerController(
    this.path, {
    this.fileName,
    String? historyPath,
    required PlaybackHistoryService historyService,
    required PlayQueueService playQueueService,
    required void Function() onStateChanged,
  })  : _historyPath = historyPath ?? path,
        _historyService = historyService,
        _playQueueService = playQueueService,
        _onStateChanged = onStateChanged {
    _videoController = VideoPlayerController.file(File(path));
  }

  VideoPlayerController get videoController => _videoController;

  Future<void> initialize() async {
    if (_disposed) return;

    try {
      await _videoController.initialize();
    } catch (e) {
      debugPrint('[AudioPlayerController] Error initializing: $e');
      rethrow;
    }

    if (_disposed) return;

    final duration = _videoController.value.duration;

    final history = await _historyService.getOrCreateHistory(
      _historyPath,
      fileName: fileName,
      totalDuration: duration != Duration.zero ? duration : null,
    );

    if (_disposed) return;

    if (history != null &&
        history.lastPosition != null &&
        history.lastPosition!.inMilliseconds > 0) {
      await _videoController.seekTo(history.lastPosition!);
    }

    if (_disposed) return;

    _videoControllerListener = () {
      if (_disposed) return;

      final currentDuration = _videoController.value.duration;
      if (currentDuration != Duration.zero) {
        _historyService.updateDuration(path, currentDuration);
      }

      if (_videoController.value.position >= _videoController.value.duration &&
          _videoController.value.duration != Duration.zero &&
          _videoController.value.isPlaying) {
        _handleAudioComplete();
      }

      _onStateChanged();
    };
    _videoController.addListener(_videoControllerListener!);

    _positionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      updatePlaybackPosition();
    });
  }

  Future<void> updatePlaybackPosition() async {
    if (_disposed) return;

    try {
      final position = _videoController.value.position;
      final duration = _videoController.value.duration;

      await _historyService.updatePosition(_historyPath, position);

      if (duration != Duration.zero) {
        try {
          final progress = position.inMilliseconds / duration.inMilliseconds;
          final currentPlaying = await _playQueueService.getCurrentPlaying();
          if (currentPlaying != null && currentPlaying.path == _historyPath) {
            await _playQueueService.updatePlayProgress(
                currentPlaying.id, progress);
          }
        } catch (e) {
          if (!_disposed) {
            debugPrint(
                '[AudioPlayerController] Error updating play queue progress: $e');
          }
        }
      }
    } catch (e) {
      if (!_disposed) {
        debugPrint(
            '[AudioPlayerController] Error updating playback position: $e');
      }
    }
  }

  void play() {
    if (!_disposed) {
      _videoController.play();
    }
  }

  void pause() {
    if (!_disposed) {
      _videoController.pause();
    }
  }

  void seek(Duration position) {
    _videoController.seekTo(position);
  }

  void setVolume(double volume) {
    _videoController.setVolume(volume);
  }

  double get volume => _videoController.value.volume;

  void setPlaybackSpeed(double speed) {
    _videoController.setPlaybackSpeed(speed);
  }

  double get playbackSpeed => _videoController.value.playbackSpeed;

  Duration get duration => _videoController.value.duration;
  Duration get position => _videoController.value.position;
  bool get isPlaying => _videoController.value.isPlaying;

  Future<void> _handleAudioComplete() async {
    if (_disposed) return;
    try {
      await _playQueueService.playNext();
    } catch (e) {
      if (!_disposed) {
        debugPrint('[AudioPlayerController] Error playing next: $e');
      }
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;

    _positionTimer?.cancel();
    _positionTimer = null;

    if (_videoControllerListener != null) {
      _videoController.removeListener(_videoControllerListener!);
      _videoControllerListener = null;
    }

    _historyService.dispose();

    try {
      _videoController.setVolume(0);
    } catch (_) {}

    try {
      _videoController.pause();
    } catch (_) {}

    try {
      _videoController.dispose();
    } catch (_) {}
  }
}
