import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fast_file_picker/fast_file_picker.dart';
import 'package:path/path.dart' as p;
import '../../../core/constants/supported_formats.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/file_utils.dart';

class SubtitleFilePicker {
  static Future<String?> pickSubtitleFile(BuildContext context) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const _SubtitlePickerDialog(),
    );
  }
}

class _SubtitlePickerDialog extends StatefulWidget {
  const _SubtitlePickerDialog();

  @override
  State<_SubtitlePickerDialog> createState() => _SubtitlePickerDialogState();
}

class _SubtitlePickerDialogState extends State<_SubtitlePickerDialog> {
  String? _currentPath;
  List<FileSystemEntity> _subtitleFiles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initDefaultDir();
  }

  Future<void> _initDefaultDir() async {
    List<String> candidates = [];

    if (Platform.isAndroid) {
      candidates = [
        '/sdcard/Download',
        '/sdcard/Movies',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Movies',
      ];
    } else if (Platform.isWindows) {
      final home = Platform.environment['USERPROFILE'];
      if (home != null) {
        candidates = [
          p.join(home, 'Downloads'),
          p.join(home, 'Videos'),
          p.join(home, 'Desktop'),
          '.',
        ];
      } else {
        candidates = ['.'];
      }
    } else {
      candidates = ['.'];
    }

    for (final dirPath in candidates) {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        setState(() { _currentPath = dirPath; });
        _loadFiles(dirPath);
        return;
      }
    }

    setState(() {
      _isLoading = false;
      _currentPath = Platform.isAndroid ? '/sdcard' : '.';
    });
    _loadFiles(_currentPath!);
  }

  Future<void> _loadFiles(String directoryPath) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _subtitleFiles = [];
    });

    try {
      final dir = Directory(directoryPath);
      if (!await dir.exists()) {
        setState(() {
          _error = 'Directory does not exist';
          _isLoading = false;
        });
        return;
      }

      final allFiles = await dir.list().toList();

      final subtitleFiles = <FileSystemEntity>[];
      for (final entity in allFiles) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase().replaceFirst('.', '');
          if (subtitleFormats.contains(ext)) {
            subtitleFiles.add(entity);
          }
        }
      }

      subtitleFiles.sort((a, b) =>
          p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase()));

      setState(() {
        _subtitleFiles = subtitleFiles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _browseDirectory() async {
    try {
      final result = await FastFilePicker.pickFile();
      if (result != null && result.path != null) {
        final selectedDir = File(result.path!).parent.path;
        setState(() { _currentPath = selectedDir; });
        _loadFiles(selectedDir);
      }
    } catch (_) {}
  }

  void _goUp() {
    if (_currentPath == null || _currentPath == '/' || _currentPath == '.') return;
    final parent = p.dirname(_currentPath!);
    if (parent != _currentPath && parent.isNotEmpty) {
      setState(() { _currentPath = parent; });
      _loadFiles(parent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            _buildHeader(context),
            const Divider(height: 1),
            _buildPathBar(context),
            Expanded(child: _buildFileList(context)),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.subtitles, size: 24),
          const SizedBox(width: 12),
          Text(AppLocalizations.of(context)!.selectSubtitleFile, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }

  Widget _buildPathBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_upward, size: 20), onPressed: _canGoUp ? _goUp : null, tooltip: 'Parent Directory'),
          const SizedBox(width: 4),
          Expanded(child: Text(_currentPath ?? '...', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 4),
          TextButton.icon(onPressed: _browseDirectory, icon: const Icon(Icons.folder_open, size: 18), label: Text(AppLocalizations.of(context)!.browse, style: TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  bool get _canGoUp => _currentPath != null && _currentPath != '/' && _currentPath != '.';

  Widget _buildFileList(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: Colors.red[400])),
          const SizedBox(height: 12),
          TextButton(onPressed: () => _loadFiles(_currentPath!), child: Text(AppLocalizations.of(context)!.retry)),
        ]),
      );
    }

    if (_subtitleFiles.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.description_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context)!.noSubtitleFiles, style: TextStyle(color: Colors.grey[500])),
          const SizedBox(height: 4),
          Text('${AppLocalizations.of(context)!.format}: ${subtitleFormats.join(', ')}', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          const SizedBox(height: 8),
          TextButton.icon(onPressed: _browseDirectory, icon: const Icon(Icons.folder_open), label: Text(AppLocalizations.of(context)!.chooseAnotherFolder)),
        ]),
      );
    }

    return ListView.separated(
      itemCount: _subtitleFiles.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final file = _subtitleFiles[index] as File;
        final name = p.basename(file.path);
        final ext = p.extension(file.path).toUpperCase().replaceFirst('.', '');
        final stat = file.statSync();
        final sizeStr = FileUtils.getFileSizeString(stat.size);

        return ListTile(
          dense: true,
          leading: Icon(_getIconForExt(ext.toLowerCase()), color: Colors.blue[300], size: 28),
          title: Text(name, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
          subtitle: Text('$ext  $sizeStr', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          onTap: () => Navigator.of(context).pop(file.path),
        );
      },
    );
  }

  IconData _getIconForExt(String ext) {
    switch (ext) {
      case 'ass': case 'ssa': return Icons.closed_caption;
      case 'srt': return Icons.subtitles;
      case 'vtt': return Icons.web;
      default: return Icons.description;
    }
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(AppLocalizations.of(context)!.cancel)),
      ]),
    );
  }
}
