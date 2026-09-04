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

  test('2026-09-05 字体设置：默认 system/daoyu，往返保留且非法值回退', () async {
    // 默认与现状一致：界面系统字体、导出道谕宋（老用户升级无感）。
    final defaults = await loadPreferences();
    expect(defaults.uiFontFamily, kUiFontSystem);
    expect(defaults.exportFontFamily, kExportFontDaoyu);

    // 选择后往返保留。
    await savePreferences(
      defaults.copyWith(uiFontFamily: 'daoyu', exportFontFamily: 'system'),
    );
    resetPreferencesCacheForTest();
    final reloaded = await loadPreferences();
    expect(reloaded.uiFontFamily, 'daoyu');
    expect(reloaded.exportFontFamily, 'system');
    // 保存时同步全局通知器（MaterialApp 主题据此即时重建）。
    expect(uiFontFamilyNotifier.value, 'daoyu');

    // 非法值（损坏文件注入）回退安全默认，不透传到 fontFamily。
    final file = File('${tempDir.path}/liuyao_settings.json');
    await file.writeAsString(
      '{"uiFontFamily": "ComicSans", "exportFontFamily": 42}',
    );
    resetPreferencesCacheForTest();
    final corrupted = await loadPreferences();
    expect(corrupted.uiFontFamily, kUiFontSystem);
    expect(corrupted.exportFontFamily, kExportFontDaoyu);
  });
}
