import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fast_file_picker/fast_file_picker.dart';
import 'package:file_selector/file_selector.dart';
import '../../router/app_router.dart';
import '../../providers/history_provider.dart';
import '../../providers/thumbnail_provider.dart';
import '../../providers/permission_provider.dart';
import '../../../data/models/play_history.dart';
import '../../../core/extensions/string_extensions.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/constants/supported_formats.dart';
import '../../../core/utils/real_path_utils.dart';
import '../../../core/utils/file_utils.dart';

class FileBrowserPage extends ConsumerStatefulWidget {
  const FileBrowserPage({super.key});

  @override
  ConsumerState<FileBrowserPage> createState() => _FileBrowserPageState();
}

class _FileBrowserPageState extends ConsumerState<FileBrowserPage> {

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final historyListAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.fileBrowser),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              _showClearAllDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => _pickFile(),
              icon: const Icon(Icons.folder_open, size: 48),
              label: Text(loc.openFile, style: const TextStyle(fontSize: 32)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 96),
                padding: const EdgeInsets.symmetric(vertical: 24),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: historyListAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('${loc.loadingFailed}: $error')),
              data: (historyList) {
                if (historyList.isEmpty) {
                  return Center(child: Text(loc.noRecentFiles));
                }
                return ListView.builder(
                  itemCount: historyList.length,
                  itemBuilder: (context, index) {
                    final history = historyList[index];
                    return _HistoryListItem(history: history);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    final videoTypeGroup = XTypeGroup(
      label: 'Video Files',
      extensions: videoFormats.toList(),
      mimeTypes: Platform.isAndroid ? FileUtils.buildMimeTypes(videoFormats.toList()) : null,
    );
    final imageTypeGroup = XTypeGroup(
      label: 'Image Files',
      extensions: imageFormats.toList(),
      mimeTypes: Platform.isAndroid ? FileUtils.buildMimeTypes(imageFormats.toList()) : null,
    );
    final audioTypeGroup = XTypeGroup(
      label: 'Audio Files',
      extensions: audioFormats.toList(),
      mimeTypes: Platform.isAndroid ? FileUtils.buildMimeTypes(audioFormats.toList()) : null,
    );

    final result = await FastFilePicker.pickFile(
      acceptedTypeGroups: [videoTypeGroup, imageTypeGroup, audioTypeGroup],
    );

    if (result != null) {
      String? pathToUse;
      String? originalContentUri;
      Uint8List? imageBytes;

      if (result.path != null) {
        pathToUse = result.path;
      } else if (result.uri != null) {
        final contentUri = result.uri.toString();

        final resolved = await RealPathUtils.resolveContentUri(contentUri);
        if (!resolved.isPlayable) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.fileAccessDeniedReselect),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
        pathToUse = resolved.path;
        originalContentUri = resolved.originalContentUri;
      }

      if (pathToUse != null && mounted) {
        final isVideo = result.name.isVideoFile || pathToUse.isVideoFile;
        final isImage = result.name.isImageFile || pathToUse.isImageFile;
        final isAudio = result.name.isAudioFile || pathToUse.isAudioFile;

        if (isVideo) {
          appRouter.push('/video-player', extra: {
            'path': pathToUse,
            'name': result.name,
            'originalContentUri': originalContentUri,
            'needsPersistRequest': RealPathUtils.isContentUri(result.uri?.toString() ?? ''),
            'canStoreInHistory': !RealPathUtils.isContentUri(result.uri?.toString() ?? ''),
          });
        } else if (isImage) {
          if (!RealPathUtils.isContentUri(pathToUse)) {
            try {
              final file = File(pathToUse);
              if (await file.exists()) {
                imageBytes = await file.readAsBytes();
              }
            } catch (_) {}
          }

          appRouter.push('/image-viewer', extra: {
            'path': pathToUse,
            'name': result.name,
            'bytes': imageBytes,
            'originalContentUri': originalContentUri,
          });
        } else if (isAudio) {
          appRouter.push('/video-player', extra: {
            'path': pathToUse,
            'name': result.name,
            'originalContentUri': originalContentUri,
            'needsPersistRequest': RealPathUtils.isContentUri(result.uri?.toString() ?? ''),
            'canStoreInHistory': !RealPathUtils.isContentUri(result.uri?.toString() ?? ''),
          });
        }
      }
    }
  }

  void _showClearAllDialog() {
    final loc = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.clearHistory),
        content: Text(loc.sureToClearHistory),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(historyActionsProvider).clearAllHistory();
              if (!mounted) return;
              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text(loc.historyCleared)),
              );
            },
            child: Text(loc.clearAll),
          ),
        ],
      ),
    );
  }
}

class _HistoryListItem extends ConsumerStatefulWidget {
  final PlayHistory history;

  const _HistoryListItem({required this.history});

  @override
  ConsumerState<_HistoryListItem> createState() => _HistoryListItemState();
}

class _HistoryListItemState extends ConsumerState<_HistoryListItem> {

  Widget _buildThumbnail(BuildContext context, WidgetRef ref) {
    final isVideo = widget.history.type == MediaType.video;
    final isAudio = widget.history.type == MediaType.audio;

    return Consumer(
      builder: (context, ref, child) {
        final thumbnailAsync = ref.watch(thumbnailGeneratorProvider((
          filePath: widget.history.path,
          displayName: widget.history.displayName,
          type: widget.history.type,
        )));

        return thumbnailAsync.when(
          data: (thumbPath) {
            if (thumbPath != null && File(thumbPath).existsSync()) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(
                  File(thumbPath),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              );
            }
            return Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                isVideo ? Icons.video_file : isAudio ? Icons.audio_file : Icons.image,
                size: 24,
                color: isVideo ? Colors.blue : isAudio ? Colors.orange : Colors.green,
              ),
            );
          },
          loading: () => Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (error, stackTrace) => Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              isVideo ? Icons.video_file : isAudio ? Icons.audio_file : Icons.image,
              size: 24,
              color: isVideo ? Colors.blue : isAudio ? Colors.orange : Colors.green,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final isVideo = widget.history.type == MediaType.video;
        final isAudio = widget.history.type == MediaType.audio;
        bool isFileExists;
        if (RealPathUtils.isContentUri(widget.history.path)) {
          isFileExists = true;
        } else {
          isFileExists = File(widget.history.path).existsSync();
        }

        return ListTile(
          leading: _buildThumbnail(context, ref),
          title: Text(
            widget.history.displayName,
            style: TextStyle(
              decoration: !isFileExists ? TextDecoration.lineThrough : null,
              color: !isFileExists ? Colors.grey : null,
            ),
          ),
          subtitle: Text(
            _formatDateTime(widget.history.lastPlayedAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await ref.read(historyActionsProvider).deleteHistory(widget.history.id);
            },
          ),
          onTap: () async {
            String? originalContentUri;
            if (RealPathUtils.isContentUri(widget.history.path)) {
              originalContentUri = widget.history.path;
            }

            final resolved = await RealPathUtils.resolveContentUri(widget.history.path);
            if (!resolved.isPlayable) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.fileAccessDeniedRetry),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
              return;
            }
            final pathToUse = resolved.path;
            originalContentUri = resolved.originalContentUri ?? originalContentUri;

            if (isVideo || isAudio) {
              appRouter.push('/video-player', extra: {
                'path': pathToUse,
                'name': widget.history.displayName,
                'originalContentUri': originalContentUri,
                'needsPersistRequest': resolved.needsPersistRequest,
                'canStoreInHistory': resolved.canStoreInHistory,
              });
            } else {
              appRouter.push('/image-viewer', extra: {
                'path': pathToUse,
                'name': widget.history.displayName,
                'originalContentUri': originalContentUri,
              });
            }
          },
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '今天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return '昨天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }
}
