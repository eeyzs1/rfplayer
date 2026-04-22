import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fast_file_picker/fast_file_picker.dart';
import 'package:file_selector/file_selector.dart';
import '../../../router/app_router.dart';
import '../../../../core/utils/real_path_utils.dart';
import '../../../../core/utils/file_utils.dart';

class FeatureCard extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String description;
  final String route;
  final List<String> allowedExtensions;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
    required this.allowedExtensions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          final isAndroid = Platform.isAndroid;
          final typeGroup = XTypeGroup(
            label: 'Allowed Files',
            extensions: allowedExtensions,
            mimeTypes: isAndroid ? FileUtils.buildMimeTypes(allowedExtensions) : null,
          );
          final result = await FastFilePicker.pickFile(
            acceptedTypeGroups: [typeGroup],
          );

          if (result != null) {
            String? pathToUse;
            String? originalContentUri;
            bool needsPersistRequest = false;
            bool canStoreInHistory = true;
            
            if (result.path != null) {
              pathToUse = result.path;
            } else if (result.uri != null) {
              final contentUri = result.uri.toString();
              
              final resolved = await RealPathUtils.resolveContentUri(contentUri);
              if (!resolved.isPlayable) return;
              pathToUse = resolved.path;
              originalContentUri = resolved.originalContentUri;
              needsPersistRequest = resolved.needsPersistRequest;
              canStoreInHistory = resolved.canStoreInHistory;
            }
            
            if (pathToUse != null) {
              appRouter.push(route, extra: {
                'path': pathToUse,
                'name': result.name,
                'originalContentUri': originalContentUri,
                'needsPersistRequest': needsPersistRequest,
                'canStoreInHistory': canStoreInHistory,
              });
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
