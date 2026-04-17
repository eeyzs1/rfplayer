import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:fvp/fvp.dart';
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
  final List<String> _tempSubtitleFiles = [];

  final _stateController = StreamController<SubtitleState>.broadcast();
  Stream<SubtitleState> get stateStream => _stateController.stream;

  VoidCallback? onStateChanged;

  SubtitleService(this._videoController);

  List<SubtitleTrack> get tracks => List.unmodifiable(_tracks);
  SubtitleTrack? get activeTrack => _activeTrack;
  bool get enabled => _enabled;

  bool _renderingSetupDone = false;

  void _ensureRenderingSetup() {
    if (_renderingSetupDone) return;
    _setupSubtitleRendering();
    _renderingSetupDone = true;
  }

  void _setupSubtitleRendering() {
    _videoController.setProperty('subtitle', '1');
    _videoController.setProperty('cc', '1');
  }

  SubtitleState get currentState => SubtitleState(
        tracks: List.unmodifiable(_tracks),
        activeTrack: _activeTrack,
        enabled: _enabled,
      );

  Future<void> loadEmbeddedSubtitles() async {
    if (_disposed) return;
    try {
      _ensureRenderingSetup();

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
    } catch (_) {}
  }

  Future<void> loadExternalSubtitle(String subtitlePath) async {
    if (_disposed) return;
    try {
      _ensureRenderingSetup();

      final existingTrack = _tracks.where((t) => t.type == SubtitleTrackType.external).firstWhere(
        (t) => t.path == subtitlePath,
        orElse: () => SubtitleTrack(id: -1, name: '', type: SubtitleTrackType.external),
      );
      if (existingTrack.id != -1) {
        await selectTrack(existingTrack);
        return;
      }

      final id = _nextExternalId++;
      final fileName = p.basename(subtitlePath);
      final nameWithoutExt = p.withoutExtension(fileName);
      final displayName = '$nameWithoutExt [${p.extension(fileName).toUpperCase().replaceFirst('.', '')}]';
      final track = SubtitleTrack(
        id: id,
        name: displayName,
        type: SubtitleTrackType.external,
        path: subtitlePath,
      );

      _tracks.add(track);

      await selectTrack(track);
    } catch (e) {
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
      } catch (_) {}
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
      _clearExternalSubtitle();
      await Future.delayed(const Duration(milliseconds: 100));

      final effectivePath = _resolveSubtitlePath(track.path!);

      _videoController.setExternalSubtitle(effectivePath);
      _hasExternalSubtitle = true;

      await Future.delayed(const Duration(milliseconds: 500));

      final embeddedCount =
          _tracks.where((t) => t.type == SubtitleTrackType.embedded).length;
      
      _videoController.setSubtitleTracks([embeddedCount]);

      _activeTrack = track;
      _lastSelectedTrack = track;
      _enabled = true;
    } catch (_) {
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
          _clearExternalSubtitle();
          await Future.delayed(const Duration(milliseconds: 100));

          final effectivePath = _resolveSubtitlePath(trackToUse.path!);
          _videoController.setExternalSubtitle(effectivePath);
          _hasExternalSubtitle = true;

          await Future.delayed(const Duration(milliseconds: 500));

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
    } catch (_) {}
  }

  void removeTrack(SubtitleTrack track) {
    if (_disposed) return;
    if (track.type == SubtitleTrackType.external) {
      _tracks.remove(track);

      if (_activeTrack == track) {
        if (_hasActiveExternalSubtitle) {
          _clearExternalSubtitle();
        }

        if (_tracks.isEmpty) {
          _activeTrack = null;
          _enabled = false;
        } else {
          final firstEmbedded = _tracks.firstWhere(
            (t) => t.type == SubtitleTrackType.embedded,
            orElse: () => _tracks.first,
          );

          _activeTrack = firstEmbedded;
          _enabled = true;
          _videoController.setSubtitleTracks([firstEmbedded.id]);
        }
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
      if (_tracks.isEmpty) {
        _activeTrack = null;
        _enabled = false;
      } else {
        final firstEmbedded = _tracks.firstWhere(
          (t) => t.type == SubtitleTrackType.embedded,
          orElse: () => _tracks.first,
        );
        _activeTrack = firstEmbedded;
        _enabled = true;
        _videoController.setSubtitleTracks([firstEmbedded.id]);
      }
    }

    _notifyState();
  }

  Future<void> clearCurrent() async {
    if (_disposed) return;
    _lastSelectedTrack = _activeTrack;
    _enabled = false;

    try {
      _videoController.setSubtitleTracks([]);
    } catch (_) {}

    _clearExternalSubtitle();

    _notifyState();
  }

  void clearAll() {
    if (_disposed) return;
    _tracks.removeWhere((t) => t.type == SubtitleTrackType.external);
    _activeTrack = null;
    _enabled = false;

    _clearExternalSubtitle();
    _cleanupTempFiles();

    try {
      _videoController.setSubtitleTracks([]);
    } catch (_) {}

    _notifyState();
  }

  bool get _hasActiveExternalSubtitle =>
      _hasExternalSubtitle &&
      _activeTrack?.type == SubtitleTrackType.external;

  String _resolveSubtitlePath(String path) {
    if (path.startsWith('content://')) {
      return path;
    }

    final ext = p.extension(path).toLowerCase();
    if (ext == '.sub') {
      final idxPath = '${p.withoutExtension(path)}.idx';
      final idxFile = File(idxPath);
      if (idxFile.existsSync()) {
        return idxPath;
      }

      if (_isMicroDvdFile(path)) {
        final srtPath = _convertMicroDvdToSrt(path);
        if (srtPath != null) {
          return srtPath;
        }
      }
    }

    return path;
  }

  bool _isMicroDvdFile(String path) {
    try {
      final file = File(path);
      final lines = file.readAsLinesSync();
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        return RegExp(r'^\{\d+\}\{\d+\}').hasMatch(trimmed);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  String? _convertMicroDvdToSrt(String path) {
    try {
      final file = File(path);
      final bytes = file.readAsBytesSync();
      final content = _decodeSubtitleBytes(bytes);
      final lines = content.split(RegExp(r'\r?\n'));
      final srtBuffer = StringBuffer();
      double fps = 23.976;
      int index = 1;

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        final match = RegExp(r'^\{(\d+)\}\{(\d+)\}(.*)$').firstMatch(trimmed);
        if (match == null) continue;

        final startFrame = int.tryParse(match.group(1)!) ?? 0;
        final endFrame = int.tryParse(match.group(2)!) ?? 0;
        final text = match.group(3)?.trim() ?? '';

        if (startFrame == 1 && endFrame == 1) {
          final fpsValue = double.tryParse(text);
          if (fpsValue != null && fpsValue > 0) {
            fps = fpsValue;
            continue;
          }
        }

        if (text.isEmpty) continue;

        final startTime = Duration(milliseconds: (startFrame / fps * 1000).round());
        final endTime = Duration(milliseconds: (endFrame / fps * 1000).round());

        srtBuffer.writeln(index);
        srtBuffer.writeln('${_formatSrtTime(startTime)} --> ${_formatSrtTime(endTime)}');
        srtBuffer.writeln(text.replaceAll('|', '\n'));
        srtBuffer.writeln();
        index++;
      }

      if (srtBuffer.isEmpty) return null;

      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}${Platform.pathSeparator}rfplayer_sub_${DateTime.now().millisecondsSinceEpoch}.srt');
      tempFile.writeAsStringSync(srtBuffer.toString());
      _tempSubtitleFiles.add(tempFile.path);

      return tempFile.path;
    } catch (e) {
      return null;
    }
  }

  static String _decodeSubtitleBytes(List<int> bytes) {
    if (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
      return String.fromCharCodes(bytes.sublist(3));
    }
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
      return String.fromCharCodes(bytes.sublist(2));
    }
    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      return String.fromCharCodes(bytes.sublist(2));
    }
    try {
      return String.fromCharCodes(bytes);
    } catch (_) {
      return String.fromCharCodes(bytes.where((b) => b < 128));
    }
  }

  static String _formatSrtTime(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final milliseconds = (duration.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$hours:$minutes:$seconds,$milliseconds';
  }

  void _cleanupTempFiles() {
    for (final tempPath in _tempSubtitleFiles) {
      try {
        final file = File(tempPath);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (_) {}
    }
    _tempSubtitleFiles.clear();
  }

  void _clearExternalSubtitle() {
    if (_hasExternalSubtitle) {
      try {
        _videoController.setExternalSubtitle('');
      } catch (_) {}
      _hasExternalSubtitle = false;
    }
  }

  SubtitleTrack _createTrackFromStream(dynamic stream, int index) {
    final metadata = stream.metadata;
    String name;
    String? language;

    if (metadata['language'] != null) {
      language = metadata['language']!;
      name = _getLanguageName(language!, index);
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

  String _getLanguageName(String langCode, [int? index]) {
    const langMap = {
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
    return langMap[langCode.toLowerCase()] ?? 'Subtitle ${index != null ? index + 1 : ''}'.trim();
  }

  void _notifyState() {
    if (_disposed) return;
    _stateController.add(currentState);
    onStateChanged?.call();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _cleanupTempFiles();
    _stateController.close();
  }
}
