import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'package:liuyao_engine/liuyao_engine.dart' as engine;

/// 应用偏好（显示与历法口径），持久化到应用私有目录 settings.json。
///
/// 设计要点：
/// - 字段全部有安全默认值，旧版本 / 缺字段 / 损坏文件均回退默认；
/// - 读写经过内存缓存，避免高频 IO；写入采用简单覆盖；
/// - [directoryOverride] 供测试注入临时目录，与 ArchiveClient 同一模式。
@immutable
class AppPreferences {
  const AppPreferences({
    this.calendarPolicySetupCompleted = false,
    this.dayBoundaryStrategy = engine.dayBoundaryCivil23NextDay,
    this.monthBoundaryStrategy = engine.monthBoundarySolarTermZiHour,
    this.showCastingRecord = false,
    this.showCalculationBasis = false,
    this.showNayin = true,
    this.showFiveStarsAndMansions = true,
    this.showShenshaAndTwelveGrowth = true,
    this.showAuxAlmanac = true,
    this.customTags = const <String>[],
  });

  /// 首次进入六爻功能的历法口径选择是否已完成。
  final bool calendarPolicySetupCompleted;

  /// 交日口径：过 23 点换日（默认）或子正 0 点换日。
  final String dayBoundaryStrategy;

  /// 交月口径：节气子时换月（默认）或节气精确时刻换月。
  final String monthBoundaryStrategy;

  /// 卦面是否显示「起卦记录」区块（默认不显示）。
  final bool showCastingRecord;

  /// 卦面是否显示「计算依据」区块（默认不显示）。
  final bool showCalculationBasis;

  /// 卦面是否显示「纳音」标注（默认显示，卦面信息极大保留）。
  final bool showNayin;

  /// 卦面是否显示「五星与二十八宿」标注（默认显示）。
  final bool showFiveStarsAndMansions;

  /// 卦面是否显示「神煞与十二长生」（默认显示）。
  final bool showShenshaAndTwelveGrowth;

  /// 是否显示辅助黄历字段（值神/冲煞/星宿/建除等，默认显示）。
  final bool showAuxAlmanac;

  /// 档案页「＋」新建的自定义标签集（未挂到档案前也保留，供筛选与快速选用）。
  final List<String> customTags;

  AppPreferences copyWith({
    bool? calendarPolicySetupCompleted,
    String? dayBoundaryStrategy,
    String? monthBoundaryStrategy,
    bool? showCastingRecord,
    bool? showCalculationBasis,
    bool? showNayin,
    bool? showFiveStarsAndMansions,
    bool? showShenshaAndTwelveGrowth,
    bool? showAuxAlmanac,
    List<String>? customTags,
  }) => AppPreferences(
    calendarPolicySetupCompleted:
        calendarPolicySetupCompleted ?? this.calendarPolicySetupCompleted,
    dayBoundaryStrategy: dayBoundaryStrategy ?? this.dayBoundaryStrategy,
    monthBoundaryStrategy: monthBoundaryStrategy ?? this.monthBoundaryStrategy,
    showCastingRecord: showCastingRecord ?? this.showCastingRecord,
    showCalculationBasis: showCalculationBasis ?? this.showCalculationBasis,
    showNayin: showNayin ?? this.showNayin,
    showFiveStarsAndMansions:
        showFiveStarsAndMansions ?? this.showFiveStarsAndMansions,
    showShenshaAndTwelveGrowth:
        showShenshaAndTwelveGrowth ?? this.showShenshaAndTwelveGrowth,
    showAuxAlmanac: showAuxAlmanac ?? this.showAuxAlmanac,
    customTags: customTags ?? this.customTags,
  );

  Map<String, dynamic> toJson() => {
    'calendarPolicySetupCompleted': calendarPolicySetupCompleted,
    'dayBoundaryStrategy': dayBoundaryStrategy,
    'monthBoundaryStrategy': monthBoundaryStrategy,
    'showCastingRecord': showCastingRecord,
    'showCalculationBasis': showCalculationBasis,
    'showNayin': showNayin,
    'showFiveStarsAndMansions': showFiveStarsAndMansions,
    'showShenshaAndTwelveGrowth': showShenshaAndTwelveGrowth,
    'showAuxAlmanac': showAuxAlmanac,
    'customTags': customTags,
  };

  factory AppPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AppPreferences();
    String strategy(String key, String fallback) {
      final value = json[key];
      return value is String && value.isNotEmpty ? value : fallback;
    }

    return AppPreferences(
      calendarPolicySetupCompleted:
          json['calendarPolicySetupCompleted'] == true,
      dayBoundaryStrategy: strategy(
        'dayBoundaryStrategy',
        engine.dayBoundaryCivil23NextDay,
      ),
      monthBoundaryStrategy: strategy(
        'monthBoundaryStrategy',
        engine.monthBoundarySolarTermZiHour,
      ),
      showCastingRecord: json['showCastingRecord'] == true,
      showCalculationBasis: json['showCalculationBasis'] == true,
      showNayin: json['showNayin'] != false,
      showFiveStarsAndMansions: json['showFiveStarsAndMansions'] != false,
      showShenshaAndTwelveGrowth:
          json['showShenshaAndTwelveGrowth'] != false,
      showAuxAlmanac: json['showAuxAlmanac'] != false,
      customTags: [
        for (final value in (json['customTags'] as List<dynamic>? ?? const []))
          if (value is String && value.trim().isNotEmpty) value.trim(),
      ],
    );
  }
}

/// 目录解析注入点：生产用应用文档目录；测试可覆盖。
Future<Directory> Function()? preferencesDirectoryOverride;

String? _cachedPath;
AppPreferences? _cached;

/// 当前已加载的偏好；未加载时返回默认值。
AppPreferences get currentPreferences => _cached ?? const AppPreferences();

/// 从磁盘加载偏好（幂等，应用启动调用一次）。
Future<AppPreferences> loadPreferences() async {
  try {
    final path = await _resolvePath();
    final file = File(path);
    if (await file.exists()) {
      final decoded = jsonDecode(await file.readAsString());
      _cached = AppPreferences.fromJson(
        decoded is Map<String, dynamic> ? decoded : null,
      );
    } else {
      _cached = const AppPreferences();
    }
  } catch (_) {
    // 文件损坏或不可读：回退默认值，不阻塞应用启动。
    _cached = const AppPreferences();
  }
  return currentPreferences;
}

/// 覆盖保存偏好并写盘。
Future<void> savePreferences(AppPreferences preferences) async {
  _cached = preferences;
  try {
    final path = await _resolvePath();
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(preferences.toJson()), flush: true);
  } catch (_) {
    // 写盘失败仅影响持久化，内存态已更新，下次启动回退上次成功值。
  }
}

/// 测试辅助：重置内存与路径缓存。
@visibleForTesting
void resetPreferencesCacheForTest() {
  _cached = null;
  _cachedPath = null;
}

Future<String> _resolvePath() async {
  if (_cachedPath != null) return _cachedPath!;
  final dir = preferencesDirectoryOverride != null
      ? await preferencesDirectoryOverride!()
      : await getApplicationDocumentsDirectory();
  _cachedPath = '${dir.path}/liuyao_settings.json';
  return _cachedPath!;
}
