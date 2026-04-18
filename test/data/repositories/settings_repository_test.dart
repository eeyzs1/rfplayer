import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rfplayer/data/repositories/settings_repository.dart';
import 'package:rfplayer/data/models/app_settings.dart';

void main() {
  late SettingsRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = SettingsRepository();
  });

  group('SettingsRepository', () {
    test('load returns default values when no preferences set', () async {
      final settings = await repository.load();

      expect(settings.themeMode, AppThemeMode.system);
      expect(settings.uiStyle, UIStyle.adaptive);
      expect(settings.language, AppLanguage.system);
      expect(settings.rememberPlaybackPosition, isTrue);
      expect(settings.historyMaxItems, 100);
      expect(settings.defaultOpenPath, isNull);
      expect(settings.showHiddenFiles, isFalse);
      expect(settings.defaultPlaybackSpeed, 1.0);
      expect(settings.historySaveMode, HistorySaveMode.realPath);
    });

    test('save and load roundtrip', () async {
      const settings = AppSettings(
        themeMode: AppThemeMode.dark,
        uiStyle: UIStyle.fluent,
        language: AppLanguage.zhCn,
        rememberPlaybackPosition: false,
        historyMaxItems: 200,
        defaultOpenPath: '/custom/path',
        showHiddenFiles: true,
        defaultPlaybackSpeed: 1.5,
        historySaveMode: HistorySaveMode.none,
      );

      await repository.save(settings);
      final loaded = await repository.load();

      expect(loaded.themeMode, AppThemeMode.dark);
      expect(loaded.uiStyle, UIStyle.fluent);
      expect(loaded.language, AppLanguage.zhCn);
      expect(loaded.rememberPlaybackPosition, isFalse);
      expect(loaded.historyMaxItems, 200);
      expect(loaded.defaultOpenPath, '/custom/path');
      expect(loaded.showHiddenFiles, isTrue);
      expect(loaded.defaultPlaybackSpeed, 1.5);
      expect(loaded.historySaveMode, HistorySaveMode.none);
    });

    test('save with null defaultOpenPath removes key', () async {
      const settingsWith = AppSettings(defaultOpenPath: '/some/path');
      await repository.save(settingsWith);

      var loaded = await repository.load();
      expect(loaded.defaultOpenPath, '/some/path');

      const settingsWithout = AppSettings(defaultOpenPath: null);
      await repository.save(settingsWithout);

      loaded = await repository.load();
      expect(loaded.defaultOpenPath, isNull);
    });

    test('load handles invalid enum values gracefully', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'invalid_value',
        'ui_style': 'invalid_value',
        'language': 'invalid_value',
        'history_save_mode': 'invalid_value',
      });

      final settings = await repository.load();

      expect(settings.themeMode, AppThemeMode.system);
      expect(settings.uiStyle, UIStyle.adaptive);
      expect(settings.language, AppLanguage.system);
      expect(settings.historySaveMode, HistorySaveMode.realPath);
    });
  });
}
