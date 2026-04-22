import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';
import '../../../core/utils/real_path_utils.dart';
import '../../../data/models/subtitle_track.dart';
import '../../../domain/services/subtitle_service.dart';
import '../../../domain/services/playback_history_service.dart';
import '../../../domain/services/play_queue_service.dart';
import 'dart:async';
import 'dart:io';

class MyVideoPlayerController {
  late final VideoPlayerController videoController;
  final String path;
  final String? fileName;
  final String _historyPath;
  final PlaybackHistoryService _historyService;
  final PlayQueueService _playQueueService;
  late final SubtitleService _subtitleService;
  final void Function() _onStateChanged;
  Timer? _positionTimer;
  VoidCallback? _videoControllerListener;
  bool _disposed = false;

  MyVideoPlayerController(
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
    if (RealPathUtils.isContentUri(path)) {
      videoController = VideoPlayerController.contentUri(Uri.parse(path));
    } else {
      videoController = VideoPlayerController.file(File(path));
    }
    _subtitleService = SubtitleService(videoController);
    _subtitleService.onStateChanged = _onStateChanged;
  }

  List<SubtitleTrack> get subtitleTracks => _subtitleService.tracks;
  SubtitleTrack? get activeSubtitleTrack => _subtitleService.activeTrack;
  bool get subtitleEnabled => _subtitleService.enabled;

  Future<void> initialize() async {
    if (_disposed) return;

    try {
      await videoController.initialize();

      if (_disposed) return;
    } catch (e) {
      rethrow;
    }

    if (_disposed) return;

    final duration = videoController.value.duration;

    final history = await _historyService.getOrCreateHistory(
      _historyPath,
      fileName: fileName,
      totalDuration: duration != Duration.zero ? duration : null,
    );

    if (_disposed) return;

    if (history != null &&
        history.lastPosition != null &&
        history.lastPosition!.inMilliseconds > 0) {
      await videoController.seekTo(history.lastPosition!);
    }

    if (_disposed) return;

    _videoControllerListener = () {
      if (_disposed) return;

      final currentDuration = videoController.value.duration;
      if (currentDuration != Duration.zero) {
        _historyService.updateDuration(path, currentDuration);
      }

      if (videoController.value.position >= videoController.value.duration &&
          videoController.value.duration != Duration.zero &&
          videoController.value.isPlaying) {
        _handleVideoComplete();
      }

      _onStateChanged();
    };
    videoController.addListener(_videoControllerListener!);

    await _subtitleService.loadEmbeddedSubtitles();

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
      final position = videoController.value.position;
      final duration = videoController.value.duration;

      await _historyService.updatePosition(_historyPath, position);

      if (duration != Duration.zero) {
        try {
          final progress = position.inMilliseconds / duration.inMilliseconds;
          final currentPlaying = await _playQueueService.getCurrentPlaying();
          if (currentPlaying != null && currentPlaying.path == _historyPath) {
            await _playQueueService.updatePlayProgress(
                currentPlaying.id, progress);
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  void play() {
    if (!_disposed) {
      videoController.play();
    }
  }

  void pause() {
    if (!_disposed) {
      videoController.pause();
    }
  }

  void seek(Duration position) {
    videoController.seekTo(position);
  }

  void setVolume(double volume) {
    videoController.setVolume(volume);
  }

  double get volume => videoController.value.volume;

  void setPlaybackSpeed(double speed) {
    videoController.setPlaybackSpeed(speed);
  }

  double get playbackSpeed => videoController.value.playbackSpeed;

  Duration get duration => videoController.value.duration;
  Duration get position => videoController.value.position;
  bool get isPlaying => videoController.value.isPlaying;

  Future<void> loadSubtitle(String subtitlePath) async {
    await _subtitleService.loadExternalSubtitle(subtitlePath);
  }

  Future<void> selectSubtitleTrack(SubtitleTrack? track) async {
    await _subtitleService.selectTrack(track);
  }

  void removeSubtitleTrack(SubtitleTrack track) {
    _subtitleService.removeTrack(track);
  }

  void removeAllSubtitleTracks() {
    _subtitleService.removeAllExternalTracks();
  }

  Future<void> toggleSubtitle() async {
    await _subtitleService.toggle();
  }

  Future<void> clearCurrentSubtitle() async {
    await _subtitleService.clearCurrent();
  }

  void clearSubtitle() {
    _subtitleService.clearAll();
  }

  Future<void> _handleVideoComplete() async {
    if (_disposed) return;
    try {
      await _playQueueService.playNext();
    } catch (_) {}
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;

    _positionTimer?.cancel();
    _positionTimer = null;

    if (_videoControllerListener != null) {
      videoController.removeListener(_videoControllerListener!);
      _videoControllerListener = null;
    }

    _subtitleService.dispose();
    _historyService.dispose();

    try {
      videoController.setVolume(0);
    } catch (_) {}

    try {
      videoController.pause();
    } catch (_) {}

    try {
      videoController.dispose();
    } catch (_) {}
  }
}
