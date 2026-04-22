import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rfplayer/core/utils/real_path_utils.dart';

class PlayerService extends ChangeNotifier {
  dynamic _controller;
  bool _isInitialized = false;
  String? _currentPath;
  bool _isInitializing = false;

  PlayerService();

  Future<void> initialize(
    String path, {
    String? fileName,
    required Future<void> Function(String safePath, String? fileName, String originalPath) onCreateController,
    required void Function() onDisposeController,
  }) async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      _disposeController();

      final String safePath;
      if (RealPathUtils.isContentUri(path)) {
        safePath = path;
      } else {
        final resolved = await RealPathUtils.getSafePath(path);
        if (resolved == null) return;
        safePath = resolved;
      }

      await onCreateController(safePath, fileName, path);

      _currentPath = safePath;
      _isInitialized = true;
      notifyStateChanged();
    } finally {
      _isInitializing = false;
    }
  }

  void markInitialized() {
    _isInitialized = true;
    notifyStateChanged();
  }

  void setController(dynamic controller) {
    _controller = controller;
  }

  void play() {
    if (_controller != null && _isInitialized) {
      _controller!.play();
    }
  }

  void pause() {
    if (_controller != null && _isInitialized) {
      _controller!.pause();
    }
  }

  void setPlaybackSpeed(double speed) {
    if (_controller != null && _isInitialized) {
      _controller!.setPlaybackSpeed(speed);
    }
  }

  void seek(Duration position) {
    if (_controller != null && _isInitialized) {
      _controller!.seek(position);
    }
  }

  void _disposeController() {
    if (_controller != null) {
      try { _controller!.pause(); } catch (_) {}
      try { _controller!.dispose(); } catch (_) {}
      _controller = null;
    }
    _isInitialized = false;
    _currentPath = null;
  }

  void stopAndRelease() {
    _controller = null;
    _isInitialized = false;
    _currentPath = null;
    notifyListeners();
  }

  dynamic get controller => _controller;
  bool get isInitialized => _isInitialized;
  String? get currentPath => _currentPath;

  void notifyStateChanged() {
    notifyListeners();
  }
}

final playerServiceProvider = ChangeNotifierProvider<PlayerService>((ref) {
  final service = PlayerService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});
