import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';
import 'app.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'core/localization/app_localizations.dart';
import 'presentation/providers/play_queue_provider.dart';
import 'presentation/providers/history_provider.dart';
import 'presentation/providers/permission_provider.dart';
import 'core/utils/intent_utils.dart';
import 'core/utils/real_path_utils.dart';
import 'core/constants/app_routes.dart';
import 'presentation/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.level = Level.WARNING;
  Logger.root.onRecord.listen((record) {
    debugPrint(
        '${record.loggerName}.${record.level.name}: ${record.time}: ${record.message}',
        wrapWidth: 0x7FFFFFFFFFFFFFFF);
  });

  String? subtitleFontFile;
  String? subtitleFontsDir;
  if (Platform.isAndroid) {
    final appDir = await getApplicationSupportDirectory();
    final mdkFontsDir = '${appDir.path}/mdk';
    final mdkFontsDirFile = Directory(mdkFontsDir);
    if (!mdkFontsDirFile.existsSync()) {
      mdkFontsDirFile.createSync(recursive: true);
    }

    const sourceFonts = [
      '/system/fonts/NotoSansCJK-Regular.ttc',
      '/system/fonts/NotoSansSC-Regular.otf',
      '/system/fonts/NotoSansCJKsc-Regular.otf',
      '/system/fonts/Roboto-Regular.ttf',
    ];

    for (final srcPath in sourceFonts) {
      final srcFile = File(srcPath);
      if (!srcFile.existsSync()) continue;

      final fileName = srcPath.split('/').last;
      final destPath = '$mdkFontsDir/$fileName';
      final destFile = File(destPath);

      if (!destFile.existsSync()) {
        try {
          await srcFile.copy(destPath);
        } catch (_) {
          continue;
        }
      }

      subtitleFontFile ??= destPath;
    }

    subtitleFontsDir = mdkFontsDir;
  }

  final fvpOptions = <String, dynamic>{
    'player': {
      'subtitle': '1',
      'cc': '1',
    },
    'subtitleFontFile': ?subtitleFontFile,
    'global': {
      'subtitle.fonts.dir': ?subtitleFontsDir,
    },
  };

  fvp.registerWith(options: fvpOptions);

  runApp(const ProviderScope(child: AppInitializer()));
}

class AppInitializer extends ConsumerStatefulWidget {
  const AppInitializer({super.key});

  @override
  ConsumerState<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<AppInitializer> {
  bool _isInitialized = false;
  ResolvedMediaPath? _pendingResolved;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final playQueueNotifier = ref.read(playQueueProvider.notifier);
      await playQueueNotifier.cleanupInvalidItems();

      final historyActions = ref.read(historyActionsProvider);
      await historyActions.cleanupInvalidRecords();

      final initialUri = await IntentUtils.getInitialFileUri();
      if (initialUri != null) {
        _pendingResolved = await IntentUtils.resolveToFilePath(initialUri);
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }

      if (_pendingResolved != null && _pendingResolved!.isPlayable && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToMedia(_pendingResolved!);
        });
      } else if (_pendingResolved != null && !_pendingResolved!.isPlayable && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final loc = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.unableToOpenFile)),
          );
        });
      }

      IntentUtils.setupIntentListener((uri) async {
        if (!mounted) return;
        final resolved = await IntentUtils.resolveToFilePath(uri);
        if (resolved.isPlayable && mounted) {
          _navigateToMedia(resolved);
        } else if (mounted) {
          final loc = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.unableToOpenFile)),
          );
        }
      });

      final permissionState = ref.read(permissionProvider);
      if (!permissionState.hasRequestedBefore &&
          permissionState.storagePermission == PermissionStatus.notDetermined) {
        final permissionNotifier = ref.read(permissionProvider.notifier);
        permissionNotifier.requestStoragePermission();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  void _navigateToMedia(ResolvedMediaPath resolved) {
    if (!mounted) return;
    final nameForType = resolved.displayName ?? resolved.path;
    final mediaType = IntentUtils.getMediaType(nameForType);
    final fileName = resolved.displayName ?? IntentUtils.getFileNameFromUri(resolved.path) ?? resolved.path.split(Platform.pathSeparator).last;

    switch (mediaType) {
      case MediaType.video:
      case MediaType.audio:
        appRouter.push(
          AppRoutes.videoPlayer,
          extra: VideoPlayerRouteExtra(
            path: resolved.path,
            name: fileName,
            originalContentUri: resolved.originalContentUri,
            canStoreInHistory: resolved.canStoreInHistory,
            needsPersistRequest: resolved.needsPersistRequest,
          ),
        );
        break;
      case MediaType.image:
        appRouter.push(
          AppRoutes.imageViewer,
          extra: ImageViewerRouteExtra(
            path: resolved.path,
            name: fileName,
            originalContentUri: resolved.originalContentUri,
          ),
        );
        break;
      case MediaType.unknown:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    return const RFPlayerApp();
  }
}
