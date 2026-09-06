import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao_archive/src/features/settings/app_preferences.dart';
import 'package:liuyao_archive/src/ui/design_system/app_theme_v1.dart';
import 'package:liuyao_archive/src/ui/design_system/tokens/ds_theme_extension.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('liuyao_theme_test');
    preferencesDirectoryOverride = () async => tempDir;
    resetPreferencesCacheForTest();
    await savePreferences(const AppPreferences());
  });

  tearDown(() async {
    resetPreferencesCacheForTest();
    preferencesDirectoryOverride = null;
    await tempDir.delete(recursive: true);
  });

  test('buildDaoyuTheme 与 buildDaoyuDarkTheme 输出 ThemeData', () {
    final light = buildDaoyuTheme();
    final dark = buildDaoyuDarkTheme();
    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(light.extension<DSColorsScheme>()?.background, isNotNull);
    expect(dark.extension<DSColorsScheme>()?.background, isNotNull);
  });

  test('浅色与暗色色板在关键 token 上不同', () {
    final light = DSColorsScheme.light;
    final dark = DSColorsScheme.dark;
    expect(light.background, isNot(equals(dark.background)));
    expect(light.surface, isNot(equals(dark.surface)));
    expect(light.textPrimary, isNot(equals(dark.textPrimary)));
    expect(light.celadon, isNot(equals(dark.celadon)));
  });

  testWidgets('BuildContext.ds 在浅色与暗色 ThemeData 下解析正确', (tester) async {
    final captured = <DSColorsScheme>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: buildDaoyuTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              captured.add(context.ds);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildDaoyuTheme(),
        darkTheme: buildDaoyuDarkTheme(),
        themeMode: ThemeMode.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              captured.add(context.ds);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(captured.first.background, DSColorsScheme.light.background);
    expect(captured.last.background, DSColorsScheme.dark.background);
  });

  test('主题模式持久化：auto/light/dark 往返与缺字段回退', () async {
    for (final mode in AppThemeMode.values) {
      await savePreferences(currentPreferences.copyWith(themeMode: mode));
      resetPreferencesCacheForTest();
      final reloaded = await loadPreferences();
      expect(reloaded.themeMode, mode);
    }
  });
}
