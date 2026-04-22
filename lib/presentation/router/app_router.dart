import 'dart:typed_data';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../shell/main_shell.dart';
import '../pages/home/home_page.dart';
import '../pages/history/history_page.dart';
import '../pages/file_browser/file_browser_page.dart';
import '../pages/bookmark/bookmark_page.dart';
import '../pages/settings/settings_page.dart';
import '../pages/video_player/video_player_page.dart';
import '../pages/image_viewer/image_viewer_page.dart';

class VideoPlayerRouteExtra {
  final String path;
  final String? name;
  final Duration? position;
  final String? originalContentUri;
  final bool canStoreInHistory;
  final bool needsPersistRequest;

  const VideoPlayerRouteExtra({required this.path, this.name, this.position, this.originalContentUri, this.canStoreInHistory = true, this.needsPersistRequest = false});
}

class ImageViewerRouteExtra {
  final String path;
  final String? name;
  final Uint8List? bytes;
  final String? originalContentUri;

  const ImageViewerRouteExtra({required this.path, this.name, this.bytes, this.originalContentUri});
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: AppRoutes.home, builder: (_, _) => const HomePage()),
        GoRoute(path: AppRoutes.history, builder: (_, _) => const HistoryPage()),
        GoRoute(path: AppRoutes.files, builder: (_, _) => const FileBrowserPage()),
        GoRoute(path: AppRoutes.bookmark, builder: (_, _) => const BookmarkPage()),
        GoRoute(path: AppRoutes.settings, builder: (_, _) => const SettingsPage()),
      ],
    ),
    GoRoute(
      path: AppRoutes.videoPlayer,
      builder: (_, state) {
        final extra = state.extra;
        if (extra is VideoPlayerRouteExtra) {
          return VideoPlayerPage(
            path: extra.path,
            fileName: extra.name,
            initialPosition: extra.position,
            originalContentUri: extra.originalContentUri,
            canStoreInHistory: extra.canStoreInHistory,
            needsPersistRequest: extra.needsPersistRequest,
          );
        }
        if (extra is Map<String, dynamic>) {
          final path = extra['path'] as String? ?? '';
          final name = extra['name'] as String?;
          final position = extra['position'] as Duration?;
          final originalContentUri = extra['originalContentUri'] as String?;
          final canStoreInHistory = extra['canStoreInHistory'] as bool? ?? true;
          final needsPersistRequest = extra['needsPersistRequest'] as bool? ?? false;
          return VideoPlayerPage(path: path, fileName: name, initialPosition: position, originalContentUri: originalContentUri, canStoreInHistory: canStoreInHistory, needsPersistRequest: needsPersistRequest);
        }
        if (extra is String) {
          return VideoPlayerPage(path: extra);
        }
        return const VideoPlayerPage(path: '');
      },
    ),
    GoRoute(
      path: AppRoutes.imageViewer,
      builder: (_, state) {
        final extra = state.extra;
        if (extra is ImageViewerRouteExtra) {
          return ImageViewerPage(path: extra.path, fileName: extra.name, bytes: extra.bytes, originalContentUri: extra.originalContentUri);
        }
        if (extra is Map<String, dynamic>) {
          final path = extra['path'] as String? ?? '';
          final name = extra['name'] as String?;
          final bytes = extra['bytes'] as Uint8List?;
          final originalContentUri = extra['originalContentUri'] as String?;
          return ImageViewerPage(path: path, fileName: name, bytes: bytes, originalContentUri: originalContentUri);
        }
        if (extra is String) {
          return ImageViewerPage(path: extra);
        }
        return const ImageViewerPage(path: '');
      },
    ),
  ],
);
