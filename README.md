# RFPlayer

**R**eal **F**ree Player — 一个真正自由的跨平台媒体播放器。

为什么叫 RFPlayer？因为市面上的播放器要么塞广告，要么卖会员，要么偷偷收集数据。我只想做一个干干净净的播放器：没有广告，没有订阅，没有追踪，没有套路。你打开它，它就播放你的文件，仅此而已。

## 它能做什么

播放你电脑和手机上的视频、音频、图片文件。不多不少。

- **视频** — mp4, mkv, avi, mov, wmv, flv, webm, 3gp, m4v, mpg, mpeg, rmvb, ts, vob, ogv
- **音频** — mp3, wav, flac, aac, ogg, wma, m4a, opus, ape, alac
- **图片** — jpg, jpeg, png, gif, bmp, webp, svg, tiff, tif, ico
- **字幕** — SRT, ASS, SSA, VTT, SUB, DFXP, TTML, SMI, IDX

## 功能

- 播放控制（速度、进度、音量）
- 外挂字幕加载
- 播放队列
- 书签（视频可标记时间点）
- 播放历史
- 文件浏览器
- 右键"打开方式"直接播放（Windows / Android）
- 中英文界面

## 下载

[最新版本](https://github.com/eeyzs1/rfplayer/releases/latest)

| 文件 | 平台 | 说明 |
|---|---|---|
| `rfplayer_installer.exe` | Windows x64 | 安装程序，注册右键菜单 |
| `rfplayer_installer.zip` | Windows x64 | 便携版，解压即用 |
| `rfplayer_installer_arm64-v8a.apk` | Android ARM64 | 手机 |
| `rfplayer_installer_x86_64.apk` | Android x86_64 | 模拟器 |

## 系统要求

- Windows 10+（64位）
- Android 5.0+

## 从源码构建

```bash
# 安装依赖
flutter pub get

# 代码生成
dart run build_runner build --delete-conflicting-outputs

# Windows
flutter build windows --release

# Android
flutter build apk --split-per-abi --target-platform android-arm64,android-x64 --release
```

## 技术栈

- [Flutter](https://flutter.dev) — 跨平台 UI 框架
- [fvp / mdk](https://pub.dev/packages/fvp) — 基于 FFmpeg 的媒体播放引擎
- [Drift](https://drift.simonbinder.eu) — SQLite 数据库
- [Riverpod](https://riverpod.dev) — 状态管理

## 许可

MIT
