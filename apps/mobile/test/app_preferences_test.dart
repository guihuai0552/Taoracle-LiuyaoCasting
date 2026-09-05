import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao_archive/src/features/settings/app_preferences.dart';
import 'package:liuyao_engine/liuyao_engine.dart' as engine;

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('liuyao_prefs_test');
    preferencesDirectoryOverride = () async => tempDir;
    resetPreferencesCacheForTest();
  });

  tearDown(() async {
    resetPreferencesCacheForTest();
    preferencesDirectoryOverride = null;
    await tempDir.delete(recursive: true);
  });

  test('默认偏好：口径为过23点换日/节气子时换月，记录与依据默认关闭', () async {
    final prefs = await loadPreferences();

    expect(prefs.calendarPolicySetupCompleted, isFalse);
    expect(prefs.dayBoundaryStrategy, engine.dayBoundaryCivil23NextDay);
    expect(prefs.monthBoundaryStrategy, engine.monthBoundarySolarTermZiHour);
    expect(prefs.showCastingRecord, isFalse);
    expect(prefs.showCalculationBasis, isFalse);
  });

  test('主题模式：默认浅色，三态可往返保存', () async {
    final defaults = await loadPreferences();
    expect(defaults.themeMode, AppThemeMode.light);

    await savePreferences(defaults.copyWith(themeMode: AppThemeMode.dark));
    resetPreferencesCacheForTest();
    final reloaded = await loadPreferences();
    expect(reloaded.themeMode, AppThemeMode.dark);

    await savePreferences(reloaded.copyWith(themeMode: AppThemeMode.auto));
    resetPreferencesCacheForTest();
    final auto = await loadPreferences();
    expect(auto.themeMode, AppThemeMode.auto);
  });

  test('主题模式：旧偏好文件（无 themeMode 字段）回退浅色默认', () async {
    final file = File('${tempDir.path}/liuyao_settings.json');
    await file.writeAsString('{"showNayin": true}');
    resetPreferencesCacheForTest();
    final legacy = await loadPreferences();
    expect(legacy.themeMode, AppThemeMode.light);
  });

  test('主题模式：非法 themeMode 值回退浅色默认', () async {
    final file = File('${tempDir.path}/liuyao_settings.json');
    await file.writeAsString('{"themeMode": "neon"}');
    resetPreferencesCacheForTest();
    final prefs = await loadPreferences();
    expect(prefs.themeMode, AppThemeMode.light);
  });

  test('保存后重新加载可恢复全部字段', () async {
    await savePreferences(
      const AppPreferences().copyWith(
        calendarPolicySetupCompleted: true,
        dayBoundaryStrategy: engine.dayBoundaryAstronomicalMidnight,
        monthBoundaryStrategy: engine.monthBoundaryAstronomicalMoment,
        showCastingRecord: true,
        showCalculationBasis: true,
      ),
    );

    resetPreferencesCacheForTest();
    final reloaded = await loadPreferences();

    expect(reloaded.calendarPolicySetupCompleted, isTrue);
    expect(
      reloaded.dayBoundaryStrategy,
      engine.dayBoundaryAstronomicalMidnight,
    );
    expect(
      reloaded.monthBoundaryStrategy,
      engine.monthBoundaryAstronomicalMoment,
    );
    expect(reloaded.showCastingRecord, isTrue);
    expect(reloaded.showCalculationBasis, isTrue);
  });

  test('损坏或非法 JSON 回退默认值且不抛异常', () async {
    final file = File('${tempDir.path}/liuyao_settings.json');
    await file.writeAsString('not a valid json {{{');

    resetPreferencesCacheForTest();
    final prefs = await loadPreferences();

    expect(prefs.dayBoundaryStrategy, engine.dayBoundaryCivil23NextDay);
    expect(prefs.showCastingRecord, isFalse);
  });

  test('缺字段 JSON 按默认值补齐', () async {
    final file = File('${tempDir.path}/liuyao_settings.json');
    await file.writeAsString('{"showCastingRecord": true}');

    resetPreferencesCacheForTest();
    final prefs = await loadPreferences();

    expect(prefs.showCastingRecord, isTrue);
    expect(prefs.calendarPolicySetupCompleted, isFalse);
    expect(prefs.monthBoundaryStrategy, engine.monthBoundarySolarTermZiHour);
  });

  test('2026-09-04 导出设置：默认未完成且含历史版本，保存后往返保留', () async {
    // 默认值：未做过首启选择、默认包含历史版本（与既有导出行为一致）。
    final defaults = await loadPreferences();
    expect(defaults.exportSetupCompleted, isFalse);
    expect(defaults.exportAnalysisHistoryDefault, isTrue);

    // 旧偏好文件（无新字段）回退安全默认。
    final file = File('${tempDir.path}/liuyao_settings.json');
    await file.writeAsString('{"showNayin": true}');
    resetPreferencesCacheForTest();
    final legacy = await loadPreferences();
    expect(legacy.exportSetupCompleted, isFalse);
    expect(legacy.exportAnalysisHistoryDefault, isTrue);

    // 首启选择「仅最新版本」后往返保留。
    await savePreferences(
      legacy.copyWith(
        exportSetupCompleted: true,
        exportAnalysisHistoryDefault: false,
      ),
    );
    resetPreferencesCacheForTest();
    final reloaded = await loadPreferences();
    expect(reloaded.exportSetupCompleted, isTrue);
    expect(reloaded.exportAnalysisHistoryDefault, isFalse);
  });
}
