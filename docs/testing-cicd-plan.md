# RFPlayer 测试与 CI/CD 计划

## 一、项目现状

- **测试覆盖**：仅有 1 个 Widget 冒烟测试（`test/widget_test.dart`），验证 App 能启动
- **CI/CD**：零配置，无 `.github/workflows/`、无构建脚本
- **代码质量工具**：仅有 `flutter_lints` 基础配置

## 二、测试体系建设

### 2.1 测试基础设施

**添加依赖（pubspec.yaml dev_dependencies）：**

- `mockito: ^5.4.4` — Mock 生成
- `integration_test: sdk: flutter` — 集成测试（预留）

**创建测试辅助工具（test/helpers/）：**

- `test_database.dart` — 基于 Drift `NativeDatabase.memory()` 的内存数据库，用于 DAO/Repository 测试
- `test_mocks.dart` — 通过 mockito 生成的 Mock 类

### 2.2 单元测试

#### 优先级 1：Core 层（纯函数，ROI 最高）

| 测试目标 | 测试内容 |
|----------|----------|
| `subtitle_parser.dart` | SRT/ASS/VTT/MicroDVD/TTML/SAMI 格式解析正确性、边界情况、空输入、格式错误 |
| `format_utils.dart` | 时长格式化、文件大小格式化、进度百分比 |
| `duration_extensions.dart` | Duration 扩展方法 |
| `string_extensions.dart` | String 扩展方法 |
| `supported_formats.dart` | 格式分类判断（isVideo/isAudio/isImage/isSubtitle） |

#### 优先级 2：Model 层

| 测试目标 | 测试内容 |
|----------|----------|
| `PlayHistory` | `progress` 计算、`isCompleted` 判断（边界 0.95）、`progressString` 格式化 |
| `PlayQueueItem` | `fromPath` 工厂方法、`fromPathAsync` 异步有效性检查 |
| `Bookmark` | `fromDb` 映射 |
| `AppSettings` | 枚举值、默认值 |
| `SubtitleItem` | `isActive(position)` 时间范围判断 |
| `VideoBookmark` / `ImageBookmark` | Freezed 模型的 copyWith、equality、序列化 |
| `SubtitleTrack` | 轨道类型区分 |

#### 优先级 3：DAO 层（使用内存数据库）

| 测试目标 | 测试内容 |
|----------|----------|
| `HistoryDao` | CRUD、upsert 去重、watchHistory 响应式流、按路径查询 |
| `BookmarkDao` | CRUD、路径去重、排序、watchAll |
| `PlayQueueDao` | CRUD、当前播放项管理、getNextItem、reorder、markAsPlayed |
| `VideoBookmarkDao` | CRUD、按视频路径查询/删除 |
| `ImageBookmarkDao` | CRUD、按图片路径查询/删除 |

#### 优先级 4：Repository 层（Mock DAO）

| 测试目标 | 测试内容 |
|----------|----------|
| `BookmarkRepository` | 清理无效记录逻辑、委托 DAO 操作 |
| `HistoryRepository` | 清理无效记录、位置更新、缩略图更新 |
| `PlayQueueRepository` | 去重添加、当前播放项管理、排序 |
| `SettingsRepository` | SharedPreferences 读写、默认值 |
| `VideoBookmarkRepository` | 按视频路径查询 |
| `ImageBookmarkRepository` | 去重添加、按图片路径查询/删除 |

#### 优先级 5：Domain Service 层（Mock Repository）

| 测试目标 | 测试内容 |
|----------|----------|
| `PlayQueueService` | 添加/删除/排序/清理、删除当前播放项时自动切换、playNext/playPrevious |
| `PlaybackHistoryService` | getOrCreate、防抖位置更新、时长更新、HistorySaveMode 逻辑 |
| `SubtitleService` | 字幕轨道选择/切换/移除、MicroDVD 转 SRT、状态广播 |
| `ThumbnailService` | 缓存命中/未命中、LRU 淘汰、缓存清理 |

### 2.3 Widget 测试

| 测试目标 | 测试内容 |
|----------|----------|
| `SettingsPage` | 设置项渲染、切换主题/语言/速度 |
| `HistoryPage` | 历史列表渲染、删除操作 |
| `BookmarkPage` | 书签列表渲染、删除操作 |

> 视频播放器页面因依赖平台播放器，Widget 测试 ROI 较低，暂不纳入。

### 2.4 测试文件组织结构

```
test/
├── helpers/
│   ├── test_database.dart
│   └── test_mocks.dart
├── core/
│   ├── utils/
│   │   ├── subtitle_parser_test.dart
│   │   ├── format_utils_test.dart
│   │   ├── duration_extensions_test.dart
│   │   └── string_extensions_test.dart
│   └── constants/
│       └── supported_formats_test.dart
├── data/
│   ├── models/
│   │   ├── play_history_test.dart
│   │   ├── play_queue_test.dart
│   │   ├── bookmark_test.dart
│   │   ├── app_settings_test.dart
│   │   ├── subtitle_test.dart
│   │   ├── video_bookmark_test.dart
│   │   └── image_bookmark_test.dart
│   ├── database/
│   │   └── daos/
│   │       ├── history_dao_test.dart
│   │       ├── bookmark_dao_test.dart
│   │       ├── play_queue_dao_test.dart
│   │       ├── video_bookmark_dao_test.dart
│   │       └── image_bookmark_dao_test.dart
│   └── repositories/
│       ├── bookmark_repository_test.dart
│       ├── history_repository_test.dart
│       ├── play_queue_repository_test.dart
│       ├── settings_repository_test.dart
│       ├── video_bookmark_repository_test.dart
│       └── image_bookmark_repository_test.dart
├── domain/
│   └── services/
│       ├── play_queue_service_test.dart
│       ├── playback_history_service_test.dart
│       ├── subtitle_service_test.dart
│       └── thumbnail_service_test.dart
├── presentation/
│   └── pages/
│       ├── settings_test.dart
│       ├── history_test.dart
│       └── bookmark_test.dart
└── widget_test.dart
```

## 三、CI/CD 流水线

### 3.1 Workflow 1：PR 质量检查（`.github/workflows/pr-check.yml`）

**触发条件：** Pull Request 到 main 分支

| Job | 步骤 |
|-----|------|
| `analyze` | `flutter analyze` |
| `test` | `flutter test --coverage` |
| `coverage` | 覆盖率报告上传（codecov） |

### 3.2 Workflow 2：主分支构建（`.github/workflows/build.yml`）

**触发条件：** Push 到 main 分支

| Job | 步骤 |
|-----|------|
| `analyze + test` | 同 PR 检查 |
| `build-android` | `flutter build apk --release` |
| `build-windows` | `flutter build windows --release` |
| `upload-artifacts` | 构建产物上传（APK + Windows ZIP） |

### 3.3 Workflow 3：发布（`.github/workflows/release.yml`）

**触发条件：** 创建 tag `v*`

| Job | 步骤 |
|-----|------|
| `build-android` | `flutter build apk --release` |
| `build-windows` | `flutter build windows --release` |
| `create-release` | GitHub Release + 产物上传 |

### 3.4 CI 关键配置

- **Flutter SDK**：`subosito/flutter-action@v2`，指定 `3.11.3+`
- **Windows 构建**：`windows-latest` runner
- **Android 构建**：`ubuntu-latest` runner + Java 17
- **FVP 本地包**：确保 `dependency_overrides` 中的 `packages/fvp` 在 CI 中可用
- **代码覆盖率**：`flutter test --coverage` + `codecov/codecov-action`
- **缓存策略**：缓存 `pub-cache`、`gradle`、`flutter-sdk`

## 四、执行优先级

```
优先级 1（核心）：Core 层单元测试 + Model 层单元测试
优先级 2（重要）：DAO 层测试 + Repository 层测试
优先级 3（重要）：Domain Service 层测试
优先级 4（补充）：Widget 测试
优先级 5（基建）：CI/CD 工作流
```

预计新增约 30+ 个测试文件，覆盖 100+ 个测试用例。
