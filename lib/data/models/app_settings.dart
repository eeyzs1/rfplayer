enum AppThemeMode {
  system,
  light,
  dark,
}

enum UIStyle {
  material3,
  fluent,
  adaptive,
}

enum AppLanguage {
  system,
  zhCn,
  enUs,
}

class AppSettings {
  final AppThemeMode themeMode;
  final UIStyle uiStyle;
  final AppLanguage language;
  final bool rememberPlaybackPosition;
  final int historyMaxItems;
  final String? defaultOpenPath;
  final bool showHiddenFiles;
  final double defaultPlaybackSpeed;

  static const _sentinel = Object();

  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.uiStyle = UIStyle.adaptive,
    this.language = AppLanguage.system,
    this.rememberPlaybackPosition = true,
    this.historyMaxItems = 100,
    this.defaultOpenPath,
    this.showHiddenFiles = false,
    this.defaultPlaybackSpeed = 1.0,
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    UIStyle? uiStyle,
    AppLanguage? language,
    bool? rememberPlaybackPosition,
    int? historyMaxItems,
    Object? defaultOpenPath = _sentinel,
    bool? showHiddenFiles,
    double? defaultPlaybackSpeed,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      uiStyle: uiStyle ?? this.uiStyle,
      language: language ?? this.language,
      rememberPlaybackPosition: rememberPlaybackPosition ?? this.rememberPlaybackPosition,
      historyMaxItems: historyMaxItems ?? this.historyMaxItems,
      defaultOpenPath: identical(defaultOpenPath, _sentinel) ? this.defaultOpenPath : defaultOpenPath as String?,
      showHiddenFiles: showHiddenFiles ?? this.showHiddenFiles,
      defaultPlaybackSpeed: defaultPlaybackSpeed ?? this.defaultPlaybackSpeed,
    );
  }
}
