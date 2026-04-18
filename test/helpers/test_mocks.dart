import 'package:mockito/annotations.dart';
import 'package:rfplayer/data/database/daos/bookmark_dao.dart';
import 'package:rfplayer/data/database/daos/history_dao.dart';
import 'package:rfplayer/data/database/daos/image_bookmark_dao.dart';
import 'package:rfplayer/data/database/daos/play_queue_dao.dart';
import 'package:rfplayer/data/database/daos/video_bookmark_dao.dart';
import 'package:rfplayer/data/repositories/bookmark_repository.dart';
import 'package:rfplayer/data/repositories/history_repository.dart';
import 'package:rfplayer/data/repositories/image_bookmark_repository.dart';
import 'package:rfplayer/data/repositories/play_queue_repository.dart';
import 'package:rfplayer/data/repositories/settings_repository.dart';
import 'package:rfplayer/data/repositories/video_bookmark_repository.dart';
import 'package:rfplayer/domain/services/thumbnail_service.dart';

@GenerateNiceMocks([
  MockSpec<HistoryDao>(),
  MockSpec<BookmarkDao>(),
  MockSpec<PlayQueueDao>(),
  MockSpec<VideoBookmarkDao>(),
  MockSpec<ImageBookmarkDao>(),
  MockSpec<HistoryRepository>(),
  MockSpec<BookmarkRepository>(),
  MockSpec<PlayQueueRepository>(),
  MockSpec<SettingsRepository>(),
  MockSpec<VideoBookmarkRepository>(),
  MockSpec<ImageBookmarkRepository>(),
  MockSpec<ThumbnailService>(),
])
void main() {}
