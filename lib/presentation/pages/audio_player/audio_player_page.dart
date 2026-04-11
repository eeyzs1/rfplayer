import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../core/utils/real_path_utils.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/services/player_service.dart';
import '../../../domain/services/playback_history_service.dart';
import '../../../data/models/app_settings.dart' show HistorySaveMode;
import '../../providers/database_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/play_queue_provider.dart';
import '../../providers/volume_provider.dart';
import '../../providers/thumbnail_provider.dart';
import 'audio_player_controller.dart';

class AudioPlayerPage extends ConsumerStatefulWidget {
  final String path;
  final Duration? initialPosition;
  final String? fileName;
  final String? originalContentUri;

  const AudioPlayerPage({
    super.key,
    required this.path,
    this.initialPosition,
    this.fileName,
    this.originalContentUri,
  });

  @override
  ConsumerState<AudioPlayerPage> createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends ConsumerState<AudioPlayerPage>
    with SingleTickerProviderStateMixin {
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;
  bool _showSpeedControl = false;
  String? _currentFileName;

  late FocusNode _focusNode;
  late FocusAttachment _focusAttachment;
  bool _isUpdateLoopRunning = false;
  bool _isDisposing = false;
  bool _isInitializing = false;

  VoidCallback? _playerServiceListener;
  ProviderSubscription? _playQueueSubscription;
  PlayerService? _cachedPlayerService;

  bool _isSliderDragging = false;
  bool _wasPlayingBeforeDrag = false;
  bool _isCompleted = false;

  Timer? _debounceTimer;
  DateTime? _lastSeekTime;
  static const Duration _debounceDuration = Duration(milliseconds: 200);
  static const Duration _throttleDuration = Duration(milliseconds: 300);

  late AnimationController _discAnimationController;

  @override
  void initState() {
    super.initState();
    _currentFileName = widget.fileName;

    _discAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _focusNode = FocusNode(debugLabel: 'AudioPlayerFocusNode');
    _focusAttachment = _focusNode.attach(context, onKeyEvent: (node, event) {
      _handleKey(event);
      return KeyEventResult.handled;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
        _focusAttachment.reparent();
        _initializePlayer();
        _playQueueSubscription = ref.listenManual(playQueueProvider, (previous, next) {
          if (mounted && !_isDisposing) {
            _handlePlayQueueChange();
          }
        });
      }
    });
  }

  @override
  void deactivate() {
    _isDisposing = true;
    _cachedPlayerService = ref.read(playerServiceProvider);
    _playQueueSubscription?.close();
    _playQueueSubscription = null;
    _stopListeningToPlayer();
    super.deactivate();
  }

  @override
  void dispose() {
    _isDisposing = true;
    _playQueueSubscription?.close();
    _playQueueSubscription = null;
    _stopListeningToPlayer();
    _focusAttachment.detach();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    _discAnimationController.dispose();
    _cachedPlayerService = null;
    super.dispose();
  }

  bool _pathsMatch(String path1, String path2) {
    if (path1 == path2) return true;
    final name1 = RealPathUtils.getFileName(path1);
    final name2 = RealPathUtils.getFileName(path2);
    return name1 == name2;
  }

  Future<void> _handleBackPress() async {
    if (_isDisposing) return;
    _isDisposing = true;

    final playerService = ref.read(playerServiceProvider);

    if (playerService.isInitialized && playerService.controller != null) {
      try {
        playerService.controller!.setVolume(0);
        playerService.pause();
      } catch (_) {}
    }

    if (playerService.isInitialized && playerService.controller != null) {
      try {
        final position = playerService.controller!.position;
        final duration = playerService.controller!.duration;

        final historyRepo = ref.read(historyRepositoryProvider);
        await historyRepo.updatePosition(widget.path, position);

        if (duration != Duration.zero) {
          final progress = position.inMilliseconds / duration.inMilliseconds;
          final playQueueService = ref.read(playQueueServiceProvider);
          final currentPlaying = await playQueueService.getCurrentPlaying();
          if (currentPlaying != null && currentPlaying.path == widget.path) {
            await playQueueService.updatePlayProgress(currentPlaying.id, progress);
          }
        }
      } catch (e) {
        debugPrint('Error updating data on back press: $e');
      }
    }

    final controller = playerService.controller;
    if (controller != null && controller is AudioPlayerController) {
      try {
        controller.dispose();
      } catch (e) {
        debugPrint('[AudioPlayerPage] Error disposing AudioPlayerController: $e');
      }
    }
    playerService.stopAndRelease();

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _handlePlayQueueChange() async {
    if (!mounted || _isDisposing || _isInitializing) return;

    try {
      final playQueueService = ref.read(playQueueServiceProvider);
      final currentPlaying = await playQueueService.getCurrentPlaying();

      if (!mounted || _isDisposing || currentPlaying == null) return;

      final playerService = ref.read(playerServiceProvider);
      final currentPath = playerService.currentPath;

      if (currentPath == currentPlaying.path) {
        if (playerService.isInitialized) {
          playerService.play();
          if (mounted) _startListeningToPlayer();
        }
      } else {
        final newFileName = currentPlaying.displayName;
        await playerService.initialize(
          currentPlaying.path,
          fileName: newFileName,
          onCreateController: (safePath, fName, originalPath) async {
            final settings = ref.read(settingsProvider);
            final effectiveHistoryPath = settings.historySaveMode == HistorySaveMode.virtualPath
                ? (RealPathUtils.isContentUri(originalPath) ? originalPath : null)
                : null;
            final controller = AudioPlayerController(
              safePath,
              fileName: fName,
              historyPath: effectiveHistoryPath,
              historyService: PlaybackHistoryService(
                repository: ref.read(historyRepositoryProvider),
                thumbnailService: ref.read(thumbnailServiceProvider),
                historySaveMode: settings.historySaveMode,
              ),
              playQueueService: ref.read(playQueueServiceProvider),
              onStateChanged: () => playerService.notifyStateChanged(),
            );
            await controller.initialize();
            playerService.setController(controller);
          },
          onDisposeController: () {
            final oldController = playerService.controller;
            if (oldController != null) {
              try { oldController.pause(); } catch (_) {}
              oldController.dispose();
            }
          },
        );
        playerService.setPlaybackSpeed(_playbackSpeed);

        if (mounted) {
          setState(() {
            _currentFileName = newFileName;
          });
        }

        playerService.play();
        if (mounted) _startListeningToPlayer();
      }
    } catch (e, stackTrace) {
      debugPrint('Error handling play queue change: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> _initializePlayer() async {
    if (!mounted) return;

    setState(() {
      _isInitializing = true;
    });

    try {
      final settings = ref.read(settingsProvider);
      _playbackSpeed = settings.defaultPlaybackSpeed;

      final playQueueNotifier = ref.read(playQueueProvider.notifier);
      final playQueueService = ref.read(playQueueServiceProvider);
      final fileName = widget.fileName ?? p.basename(widget.path);
      await playQueueNotifier.addToQueue(widget.path, fileName);

      final queue = await playQueueService.getQueue();
      var itemToPlay = queue.where((item) => _pathsMatch(item.path, widget.path)).firstOrNull;
      if (itemToPlay != null) {
        await playQueueNotifier.playItem(itemToPlay.id);
      }

      final playerService = ref.read(playerServiceProvider);
      await playerService.initialize(
        widget.path,
        fileName: fileName,
        onCreateController: (safePath, fName, originalPath) async {
          final settings = ref.read(settingsProvider);
          final virtualPathCandidate = widget.originalContentUri ?? originalPath;
          final effectiveHistoryPath = settings.historySaveMode == HistorySaveMode.virtualPath
              ? (RealPathUtils.isContentUri(virtualPathCandidate) ? virtualPathCandidate : null)
              : null;
          final controller = AudioPlayerController(
            safePath,
            fileName: fName,
            historyPath: effectiveHistoryPath,
            historyService: PlaybackHistoryService(
              repository: ref.read(historyRepositoryProvider),
              thumbnailService: ref.read(thumbnailServiceProvider),
              historySaveMode: settings.historySaveMode,
            ),
            playQueueService: ref.read(playQueueServiceProvider),
            onStateChanged: () => playerService.notifyStateChanged(),
          );
          await controller.initialize();
          playerService.setController(controller);
        },
        onDisposeController: () {
          final oldController = playerService.controller;
          if (oldController != null) {
            try { oldController.pause(); } catch (_) {}
            oldController.dispose();
          }
        },
      );

      playerService.setPlaybackSpeed(_playbackSpeed);
      if (widget.initialPosition != null) {
        playerService.seek(widget.initialPosition!);
      }

      if (mounted) {
        setState(() {
          _currentFileName = fileName;
        });
      }

      playerService.play();
      if (mounted) _startListeningToPlayer();
    } catch (e, stackTrace) {
      debugPrint('Error initializing audio player: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  void _startListeningToPlayer() {
    if (_isUpdateLoopRunning) return;
    _isUpdateLoopRunning = true;

    final playerService = ref.read(playerServiceProvider);
    _cachedPlayerService = playerService;
    _playerServiceListener = () {
      if (!mounted || _isDisposing) return;
      if (_isSliderDragging) return;

      if (playerService.isInitialized && playerService.controller != null) {
        try {
          final controller = playerService.controller as AudioPlayerController;
          final position = controller.position;
          final duration = controller.duration;
          final isPlaying = controller.isPlaying;
          final completed = duration.inMilliseconds > 0 &&
              position.inMilliseconds >= duration.inMilliseconds * 0.99 &&
              !isPlaying;

          if (mounted && !_isDisposing) {
            setState(() {
              _position = position;
              _duration = duration;
              _isPlaying = isPlaying;
              _isCompleted = completed;
            });
          }
        } catch (e) {
          debugPrint('Error getting player state: $e');
        }
      }
    };
    playerService.addListener(_playerServiceListener!);
  }

  void _stopListeningToPlayer() {
    if (_playerServiceListener != null) {
      final playerService = _cachedPlayerService;
      if (playerService != null) {
        playerService.removeListener(_playerServiceListener!);
      }
      _playerServiceListener = null;
    }
    _isUpdateLoopRunning = false;
  }

  void _togglePlayPause() {
    if (!mounted) return;
    final playerService = ref.read(playerServiceProvider);
    if (!playerService.isInitialized || playerService.controller == null) return;

    final isCompleted = _duration.inMilliseconds > 0 &&
        _position.inMilliseconds >= _duration.inMilliseconds * 0.99;

    if (isCompleted) {
      playerService.controller!.seek(Duration.zero);
      if (mounted) playerService.play();
    } else if (_isPlaying) {
      if (mounted) playerService.pause();
    } else {
      if (mounted) playerService.play();
    }
  }

  void _onSliderChangeStart(double value) {
    _wasPlayingBeforeDrag = _isPlaying;
    _isSliderDragging = true;

    if (_isPlaying) {
      final playerService = ref.read(playerServiceProvider);
      if (playerService.isInitialized && playerService.controller != null) {
        playerService.pause();
        if (mounted) {
          setState(() { _isPlaying = false; });
        }
      }
    }
  }

  void _onSliderChanged(double value) {
    if (!mounted || !_isSliderDragging) return;
    final newPosition = Duration(
      milliseconds: (value * _duration.inMilliseconds).toInt(),
    );
    setState(() { _position = newPosition; });
  }

  Future<void> _onSliderChangeEnd(double value) async {
    if (!mounted) return;
    final targetPosition = Duration(
      milliseconds: (value * _duration.inMilliseconds).toInt(),
    );

    setState(() {
      _position = targetPosition;
      _isPlaying = _wasPlayingBeforeDrag;
    });

    _debounceTimer?.cancel();

    _debounceTimer = Timer(_debounceDuration, () {
      if (!mounted) return;

      final now = DateTime.now();
      if (_lastSeekTime != null && now.difference(_lastSeekTime!) < _throttleDuration) {
        return;
      }
      _lastSeekTime = now;

      final playerService = ref.read(playerServiceProvider);
      if (playerService.isInitialized && playerService.controller != null) {
        playerService.controller!.seek(targetPosition);
        if (_wasPlayingBeforeDrag) {
          playerService.play();
        }
      }
      if (mounted) {
        setState(() {
          _isSliderDragging = false;
        });
      }
    });
  }

  void _handleSpeedChangeFinal(double speed) {
    if (!mounted) return;
    final playerService = ref.read(playerServiceProvider);
    if (playerService.isInitialized && playerService.controller != null) {
      playerService.controller!.setPlaybackSpeed(speed);
      setState(() {
        _playbackSpeed = speed;
      });
      _saveSpeedSetting(speed);
    }
  }

  Future<void> _saveSpeedSetting(double speed) async {
    if (!mounted) return;
    try {
      final settings = ref.read(settingsProvider);
      await ref.read(settingsProvider.notifier).update(
            settings.copyWith(defaultPlaybackSpeed: speed),
          );
    } catch (e) {
      debugPrint('Error saving playback speed: $e');
    }
  }

  void _handleVolumeChange(double volume) {
    final clampedVolume = volume.clamp(0.0, 1.0);
    final playerService = ref.read(playerServiceProvider);
    if (playerService.isInitialized && playerService.controller != null) {
      playerService.controller!.setVolume(clampedVolume);
      ref.read(volumeProvider.notifier).setVolume(clampedVolume);
    }
  }

  Future<void> _keyboardSeek(Duration targetPosition) async {
    if (!mounted) return;

    setState(() {
      _isSliderDragging = true;
      _position = targetPosition;
    });

    _debounceTimer?.cancel();

    _debounceTimer = Timer(_debounceDuration, () {
      if (!mounted) return;

      final now = DateTime.now();
      if (_lastSeekTime != null && now.difference(_lastSeekTime!) < _throttleDuration) {
        if (mounted) {
          setState(() {
            _isSliderDragging = false;
          });
        }
        return;
      }
      _lastSeekTime = now;

      final playerService = ref.read(playerServiceProvider);
      if (playerService.isInitialized && playerService.controller != null) {
        playerService.controller!.seek(targetPosition);
      }
      if (mounted) {
        setState(() {
          _isSliderDragging = false;
        });
      }
    });
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.space) {
      _togglePlayPause();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (_duration.inMilliseconds > 0) {
        final newMs = (_position.inMilliseconds - (_duration.inMilliseconds * 0.05).round()).clamp(0, _duration.inMilliseconds);
        _keyboardSeek(Duration(milliseconds: newMs));
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (_duration.inMilliseconds > 0) {
        final newMs = (_position.inMilliseconds + (_duration.inMilliseconds * 0.05).round()).clamp(0, _duration.inMilliseconds);
        _keyboardSeek(Duration(milliseconds: newMs));
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final currentVolume = ref.read(volumeProvider);
      _handleVolumeChange(currentVolume + 0.1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      final currentVolume = ref.read(volumeProvider);
      _handleVolumeChange(currentVolume - 0.1);
    } else if (event.logicalKey == LogicalKeyboardKey.equal) {
      _handleSpeedChangeFinal((_playbackSpeed + 0.1).clamp(0.25, 4.0));
    } else if (event.logicalKey == LogicalKeyboardKey.minus) {
      _handleSpeedChangeFinal((_playbackSpeed - 0.1).clamp(0.25, 4.0));
    } else if (event.logicalKey == LogicalKeyboardKey.digit0) {
      _handleSpeedChangeFinal(1.0);
    }

    if (mounted) _focusNode.requestFocus();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (_isPlaying && !_isCompleted) {
      _discAnimationController.repeat();
    } else {
      _discAnimationController.stop();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A2E),
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            loc.audioPlayer,
            style: const TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            onPressed: _handleBackPress,
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              onPressed: () => _showAudioInfo(context),
            ),
          ],
        ),
        body: Focus(
          focusNode: _focusNode,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: _buildDiscArea(),
                ),
              ),
              _buildFileName(),
              const SizedBox(height: 8),
              _buildProgressBar(),
              const SizedBox(height: 16),
              _buildControls(),
              const SizedBox(height: 16),
              if (_showSpeedControl) _buildSpeedControl(),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscArea() {
    return AnimatedBuilder(
      animation: _discAnimationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _discAnimationController.value * 2 * 3.14159,
          child: child,
        );
      },
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [
              Color(0xFF2D2D5E),
              Color(0xFF1A1A3E),
              Color(0xFF0F0F2E),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
          border: Border.all(
            color: Colors.blue.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
            ),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3D3D6E),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.music_note,
                color: Colors.white70,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileName() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        _currentFileName ?? p.basename(widget.path),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: Colors.blue,
              inactiveTrackColor: Colors.grey[700],
              thumbColor: Colors.blue,
            ),
            child: Slider(
              value: _duration.inMilliseconds > 0
                  ? (_position.inMilliseconds / _duration.inMilliseconds)
                      .clamp(0.0, 1.0)
                  : 0.0,
              onChangeStart: _onSliderChangeStart,
              onChanged: _onSliderChanged,
              onChangeEnd: _onSliderChangeEnd,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_position),
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
                Text(
                  _formatDuration(_duration),
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous, color: Colors.white, size: 28),
            onPressed: () async {
              _focusNode.requestFocus();
              final playQueueNotifier = ref.read(playQueueProvider.notifier);
              await playQueueNotifier.playPrevious();
            },
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                _isCompleted
                    ? Icons.replay
                    : (_isPlaying ? Icons.pause : Icons.play_arrow),
                color: Colors.white,
                size: 28,
              ),
              onPressed: () {
                _focusNode.requestFocus();
                _togglePlayPause();
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.white, size: 28),
            onPressed: () async {
              _focusNode.requestFocus();
              final playQueueNotifier = ref.read(playQueueProvider.notifier);
              await playQueueNotifier.playNext();
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              final volume = ref.watch(volumeProvider);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    volume == 0
                        ? Icons.volume_mute
                        : volume < 0.5
                            ? Icons.volume_down
                            : Icons.volume_up,
                    color: Colors.white,
                    size: 22,
                  ),
                  SizedBox(
                    width: 80,
                    child: Slider(
                      value: volume,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      onChanged: (newVolume) {
                        _handleVolumeChange(newVolume);
                      },
                      activeColor: Colors.blue,
                      inactiveColor: Colors.grey[700],
                    ),
                  ),
                ],
              );
            },
          ),
          ElevatedButton(
            onPressed: () {
              _focusNode.requestFocus();
              if (mounted) {
                setState(() {
                  _showSpeedControl = !_showSpeedControl;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              '${_playbackSpeed.toStringAsFixed(1)}x',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedControl() {
    final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0, 4.0];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.playbackSpeed,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: speeds.map((speed) {
              final isSelected = (_playbackSpeed - speed).abs() < 0.01;
              return ChoiceChip(
                label: Text(
                  '${speed}x',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                selected: isSelected,
                selectedColor: Colors.blue,
                backgroundColor: Colors.grey[800],
                side: BorderSide(
                  color: isSelected ? Colors.blue : Colors.grey[600]!,
                ),
                onSelected: (_) => _handleSpeedChangeFinal(speed),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showAudioInfo(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final playerService = ref.read(playerServiceProvider);
    if (!playerService.isInitialized || playerService.controller == null) return;

    final displayPath = playerService.currentPath ?? widget.path;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${loc.fileName}: ${_currentFileName ?? p.basename(displayPath)}',
                  style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              Text('${loc.filePath}: $displayPath',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              Text('Duration: ${_formatDuration(_duration)}',
                  style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
