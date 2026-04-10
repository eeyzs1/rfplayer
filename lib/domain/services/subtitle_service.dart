import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:path/path.dart' as p;
import '../../data/models/subtitle_track.dart';
import '../models/subtitle_state.dart';

class SubtitleService {
  final VideoPlayerController _videoController;
  final List<SubtitleTrack> _tracks = [];
  SubtitleTrack? _activeTrack;
  SubtitleTrack? _lastSelectedTrack;
  bool _enabled = true;
  bool _hasExternalSubtitle = false;
  int _nextExternalId = 1000;
  bool _disposed = false;

  final _stateController = StreamController<SubtitleState>.broadcast();
  Stream<SubtitleState> get stateStream => _stateController.stream;

  VoidCallback? onStateChanged;

  SubtitleService(this._videoController);

  List<SubtitleTrack> get tracks => List.unmodifiable(_tracks);
  SubtitleTrack? get activeTrack => _activeTrack;
  bool get enabled => _enabled;

  SubtitleState get currentState => SubtitleState(
        tracks: List.unmodifiable(_tracks),
        activeTrack: _activeTrack,
        enabled: _enabled,
      );

  Future<void> loadEmbeddedSubtitles() async {
    if (_disposed) return;
    try {
      try {
        _videoController.setProperty('subtitle', '1');
        _videoController.setProperty('cc', '1');
      } catch (e) {
        debugPrint('[SubtitleService] Error setting subtitle properties: $e');
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (_disposed) return;

      final mediaInfo = _videoController.getMediaInfo();

      if (mediaInfo == null ||
          mediaInfo.subtitle == null ||
          mediaInfo.subtitle!.isEmpty) {
        return;
      }

      for (int i = 0; i < mediaInfo.subtitle!.length; i++) {
        final subtitleStream = mediaInfo.subtitle![i];
        final track = _createTrackFromStream(subtitleStream, i);
        _tracks.add(track);
      }

      if (_tracks.isNotEmpty) {
        _activeTrack = _tracks.first;
        _lastSelectedTrack = _tracks.first;
        _enabled = true;

        _videoController.setSubtitleTracks([0]);
        _notifyState();
      }
    } catch (e) {
      if (!_disposed) {
        debugPrint('[SubtitleService] Error loading embedded subtitles: $e');
      }
    }
  }

  Future<void> loadExternalSubtitle(String subtitlePath) async {
    if (_disposed) return;
    try {
      final id = _nextExternalId++;
      final name = p.basename(subtitlePath);
      final track = SubtitleTrack(
        id: id,
        name: name,
        type: SubtitleTrackType.external,
        path: subtitlePath,
      );

      _tracks.add(track);
      await selectTrack(track);
    } catch (e) {
      if (!_disposed) debugPrint('[SubtitleService] Error loading subtitle: $e');
      rethrow;
    }
  }

  Future<void> selectTrack(SubtitleTrack? track) async {
    if (_disposed) return;
    if (track == null) {
      _lastSelectedTrack = _activeTrack;
      _enabled = false;
      try {
        _videoController.setSubtitleTracks([]);
      } catch (e) {
        debugPrint('[SubtitleService] Error in setSubtitleTracks([]): $e');
      }
    } else {
      if (track.type == SubtitleTrackType.external) {
        await _selectExternalTrack(track);
      } else {
        _selectEmbeddedTrack(track);
      }
    }
    _notifyState();
  }

  Future<void> _selectExternalTrack(SubtitleTrack track) async {
    try {
      _videoController.setExternalSubtitle(track.path!);
      _hasExternalSubtitle = true;

      await Future.delayed(const Duration(milliseconds: 300));
      if (_disposed) return;

      final embeddedCount =
          _tracks.where((t) => t.type == SubtitleTrackType.embedded).length;
      _videoController.setSubtitleTracks([embeddedCount]);

      _activeTrack = track;
      _lastSelectedTrack = track;
      _enabled = true;
    } catch (e) {
      debugPrint('[SubtitleService] Error in setExternalSubtitle: $e');
      _activeTrack = track;
      _lastSelectedTrack = track;
      _enabled = true;
    }
  }

  void _selectEmbeddedTrack(SubtitleTrack track) {
    try {
      _clearExternalSubtitle();
      _videoController.setSubtitleTracks([track.id]);
      _activeTrack = track;
      _lastSelectedTrack = track;
      _enabled = true;
    } catch (e) {
      debugPrint('[SubtitleService] Error in embedded subtitle selection: $e');
      _activeTrack = track;
      _lastSelectedTrack = track;
      _enabled = true;
    }
  }

  Future<void> toggle() async {
    if (_disposed) return;
    if (!_enabled) {
      await _enableSubtitle();
    } else {
      _disableSubtitle();
    }
    _notifyState();
  }

  Future<void> _enableSubtitle() async {
    SubtitleTrack? trackToUse;

    if (_activeTrack != null && _tracks.contains(_activeTrack)) {
      trackToUse = _activeTrack;
    } else if (_lastSelectedTrack != null &&
        _tracks.contains(_lastSelectedTrack)) {
      trackToUse = _lastSelectedTrack;
    } else if (_tracks.isNotEmpty) {
      trackToUse = _tracks.first;
    }

    if (trackToUse != null) {
      try {
        if (trackToUse.type == SubtitleTrackType.external) {
          _videoController.setExternalSubtitle(trackToUse.path!);
          _hasExternalSubtitle = true;

          await Future.delayed(const Duration(milliseconds: 300));
          if (_disposed) return;

          final embeddedCount =
              _tracks.where((t) => t.type == SubtitleTrackType.embedded).length;
          _videoController.setSubtitleTracks([embeddedCount]);
        } else {
          _clearExternalSubtitle();
          _videoController.setSubtitleTracks([trackToUse.id]);
        }
        _enabled = true;
        _activeTrack = trackToUse;
      } catch (e) {
        debugPrint('[SubtitleService] Error toggling on subtitle: $e');
        _enabled = true;
        _activeTrack = trackToUse;
      }
    }
  }

  void _disableSubtitle() {
    _lastSelectedTrack = _activeTrack;
    _enabled = false;

    _clearExternalSubtitle();

    try {
      _videoController.setSubtitleTracks([]);
    } catch (e) {
      debugPrint('[SubtitleService] Error toggling off subtitle: $e');
    }
  }

  void removeTrack(SubtitleTrack track) {
    if (_disposed) return;
    if (track.type == SubtitleTrackType.external) {
      _tracks.remove(track);

      if (_activeTrack == track) {
        if (_hasActiveExternalSubtitle) {
          _clearExternalSubtitle();
        }

        final firstEmbedded = _tracks.firstWhere(
          (t) => t.type == SubtitleTrackType.embedded,
          orElse: () => _tracks.first,
        );

        _activeTrack = firstEmbedded;
        _enabled = true;
        _videoController.setSubtitleTracks([firstEmbedded.id]);
      }
      _notifyState();
    }
  }

  void removeAllExternalTracks() {
    if (_disposed) return;
    final externalTracks =
        _tracks.where((t) => t.type == SubtitleTrackType.external).toList();

    if (externalTracks.isEmpty) return;

    final wasExternalActive = _activeTrack?.type == SubtitleTrackType.external;

    _tracks.removeWhere((t) => t.type == SubtitleTrackType.external);

    _clearExternalSubtitle();

    if (wasExternalActive) {
      final firstEmbedded = _tracks.firstWhere(
        (t) => t.type == SubtitleTrackType.embedded,
        orElse: () => _tracks.first,
      );
      _activeTrack = firstEmbedded;
      _enabled = true;
      _videoController.setSubtitleTracks([firstEmbedded.id]);
    }

    _notifyState();
  }

  Future<void> clearCurrent() async {
    if (_disposed) return;
    _lastSelectedTrack = _activeTrack;
    _enabled = false;

    try {
      _videoController.setSubtitleTracks([]);
    } catch (e) {
      debugPrint('[SubtitleService] Error clearing current subtitle: $e');
    }

    _clearExternalSubtitle();
    _notifyState();
  }

  void clearAll() {
    if (_disposed) return;
    _tracks.removeWhere((t) => t.type == SubtitleTrackType.external);
    _activeTrack = null;
    _enabled = false;

    _clearExternalSubtitle();

    try {
      _videoController.setSubtitleTracks([]);
    } catch (e) {
      debugPrint('[SubtitleService] Error clearing subtitles: $e');
    }
    _notifyState();
  }

  bool get _hasActiveExternalSubtitle =>
      _hasExternalSubtitle &&
      _activeTrack?.type == SubtitleTrackType.external;

  void _clearExternalSubtitle() {
    if (_hasExternalSubtitle) {
      try {
        _videoController.setExternalSubtitle('');
      } catch (e) {
        debugPrint('[SubtitleService] Error clearing external subtitle: $e');
      }
      _hasExternalSubtitle = false;
    }
  }

  SubtitleTrack _createTrackFromStream(dynamic stream, int index) {
    final metadata = stream.metadata;
    String name;
    String? language;

    if (metadata['language'] != null) {
      language = metadata['language']!;
      name = _getLanguageName(language!);
    } else if (metadata['title'] != null) {
      name = metadata['title']!;
    } else {
      name = 'Subtitle ${index + 1}';
    }

    return SubtitleTrack(
      id: index,
      name: name,
      language: language,
      type: SubtitleTrackType.embedded,
    );
  }

  String _getLanguageName(String langCode) {
    final langMap = {
      'zh': '中文', 'chi': '中文', 'zho': '中文', 'cn': '中文',
      'en': 'English', 'eng': 'English',
      'ja': '日本語', 'jpn': '日本語',
      'ko': '한국어', 'kor': '한국어',
      'es': 'Español', 'spa': 'Español',
      'fr': 'Français', 'fre': 'Français',
      'de': 'Deutsch', 'ger': 'Deutsch',
      'ru': 'Русский', 'rus': 'Русский',
      'ar': 'العربية', 'ara': 'العربية',
      'pt': 'Português', 'por': 'Português',
      'it': 'Italiano', 'ita': 'Italiano',
    };
    return langMap[langCode.toLowerCase()] ?? 'Subtitle';
  }

  void _notifyState() {
    if (_disposed) return;
    _stateController.add(currentState);
    onStateChanged?.call();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _stateController.close();
  }
}
