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
    expect(reloaded.dayBoundaryStrategy, engine.dayBoundaryAstronomicalMidnight);
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
}
