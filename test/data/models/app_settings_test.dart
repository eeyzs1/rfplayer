import 'package:flutter_test/flutter_test.dart';
import 'package:rfplayer/data/models/app_settings.dart';

void main() {
  group('AppSettings', () {
    test('has correct default values', () {
      const settings = AppSettings();

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

    group('copyWith', () {
      test('copies with new themeMode', () {
        const settings = AppSettings();
        final newSettings = settings.copyWith(themeMode: AppThemeMode.dark);

        expect(newSettings.themeMode, AppThemeMode.dark);
        expect(newSettings.uiStyle, settings.uiStyle);
      });

      test('copies with new uiStyle', () {
        const settings = AppSettings();
        final newSettings = settings.copyWith(uiStyle: UIStyle.fluent);

        expect(newSettings.uiStyle, UIStyle.fluent);
        expect(newSettings.themeMode, settings.themeMode);
      });

      test('copies with new language', () {
        const settings = AppSettings();
        final newSettings = settings.copyWith(language: AppLanguage.zhCn);

        expect(newSettings.language, AppLanguage.zhCn);
      });

      test('copies with new rememberPlaybackPosition', () {
        const settings = AppSettings();
        final newSettings = settings.copyWith(rememberPlaybackPosition: false);

        expect(newSettings.rememberPlaybackPosition, isFalse);
      });

      test('copies with new historyMaxItems', () {
        const settings = AppSettings();
        final newSettings = settings.copyWith(historyMaxItems: 200);

        expect(newSettings.historyMaxItems, 200);
      });

      test('copies with new defaultOpenPath', () {
        const settings = AppSettings();
        final newSettings = settings.copyWith(defaultOpenPath: '/new/path');

        expect(newSettings.defaultOpenPath, '/new/path');
      });

      test('copies with null defaultOpenPath', () {
        const settings = AppSettings(defaultOpenPath: '/some/path');
        final newSettings = settings.copyWith(defaultOpenPath: null);

        expect(newSettings.defaultOpenPath, isNull);
      });

      test('preserves existing defaultOpenPath when not specified', () {
        const settings = AppSettings(defaultOpenPath: '/some/path');
        final newSettings = settings.copyWith(themeMode: AppThemeMode.dark);

        expect(newSettings.defaultOpenPath, '/some/path');
      });

      test('copies with new showHiddenFiles', () {
        const settings = AppSettings();
        final newSettings = settings.copyWith(showHiddenFiles: true);

        expect(newSettings.showHiddenFiles, isTrue);
      });

      test('copies with new defaultPlaybackSpeed', () {
        const settings = AppSettings();
        final newSettings = settings.copyWith(defaultPlaybackSpeed: 1.5);

        expect(newSettings.defaultPlaybackSpeed, 1.5);
      });

      test('copies with new historySaveMode', () {
        const settings = AppSettings();
        final newSettings = settings.copyWith(historySaveMode: HistorySaveMode.none);

        expect(newSettings.historySaveMode, HistorySaveMode.none);
      });
    });

    group('Enums', () {
      test('AppThemeMode has all values', () {
        expect(AppThemeMode.values.length, 3);
        expect(AppThemeMode.values, contains(AppThemeMode.system));
        expect(AppThemeMode.values, contains(AppThemeMode.light));
        expect(AppThemeMode.values, contains(AppThemeMode.dark));
      });

      test('UIStyle has all values', () {
        expect(UIStyle.values.length, 3);
        expect(UIStyle.values, contains(UIStyle.material3));
        expect(UIStyle.values, contains(UIStyle.fluent));
        expect(UIStyle.values, contains(UIStyle.adaptive));
      });

      test('AppLanguage has all values', () {
        expect(AppLanguage.values.length, 3);
        expect(AppLanguage.values, contains(AppLanguage.system));
        expect(AppLanguage.values, contains(AppLanguage.zhCn));
        expect(AppLanguage.values, contains(AppLanguage.enUs));
      });

      test('HistorySaveMode has all values', () {
        expect(HistorySaveMode.values.length, 3);
        expect(HistorySaveMode.values, contains(HistorySaveMode.none));
        expect(HistorySaveMode.values, contains(HistorySaveMode.realPath));
        expect(HistorySaveMode.values, contains(HistorySaveMode.virtualPath));
      });
    });
  });
}
