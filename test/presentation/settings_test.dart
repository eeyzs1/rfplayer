import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rfplayer/data/models/app_settings.dart';

void main() {
  group('AppSettings Widget rendering', () {
    testWidgets('renders AppSettings enum values correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(builder: (context) {
                return Column(
                  children: [
                    Text(AppThemeMode.system.name, key: const Key('system')),
                    Text(AppThemeMode.dark.name, key: const Key('dark')),
                    Text(AppThemeMode.light.name, key: const Key('light')),
                    Text(UIStyle.material3.name, key: const Key('material3')),
                    Text(UIStyle.fluent.name, key: const Key('fluent')),
                    Text(UIStyle.adaptive.name, key: const Key('adaptive')),
                  ],
                );
              }),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('system')), findsOneWidget);
      expect(find.byKey(const Key('dark')), findsOneWidget);
      expect(find.byKey(const Key('light')), findsOneWidget);
      expect(find.byKey(const Key('material3')), findsOneWidget);
      expect(find.byKey(const Key('fluent')), findsOneWidget);
      expect(find.byKey(const Key('adaptive')), findsOneWidget);
    });

    testWidgets('AppSettings default values are correct', (tester) async {
      const settings = AppSettings();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Text(settings.themeMode.name, key: const Key('theme')),
                  Text(settings.uiStyle.name, key: const Key('ui')),
                  Text(settings.language.name, key: const Key('lang')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('theme')), findsOneWidget);
      expect(find.byKey(const Key('ui')), findsOneWidget);
      expect(find.byKey(const Key('lang')), findsOneWidget);
    });
  });
}
