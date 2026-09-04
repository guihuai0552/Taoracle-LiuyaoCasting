import 'package:liuyao_engine/liuyao_engine.dart' as engine;

class CastPreview {
  const CastPreview({
    required this.schemaVersion,
    required this.engineVersion,
    required this.castAt,
    required this.lineValues,
    required this.yearPillar,
    required this.monthPillar,
    required this.dayPillar,
    required this.hourPillar,
    required this.yearVoid,
    required this.monthVoid,
    required this.dayVoid,
    required this.hourVoid,
    required this.castingRecord,
    required this.rulePackage,
    required this.chart,
    required this.annotations,
    required this.calculationTrace,
    required this.rawJson,
    this.fourPillarsSource = 'calculated',
    this.manualFourPillars,
  });

  factory CastPreview.fromJson(Map<String, dynamic> json) {
    final schemaVersion = (json['schema_version'] as num).toInt();
    if (schemaVersion < 3) return CastPreview._fromLegacy(json);
    final meta = json['meta'] as Map<String, dynamic>;
    final time = json['time'] as Map<String, dynamic>;
    final pillarVoids = time['pillar_voids'] as Map<String, dynamic>?;

    String pillarVoid(String position) {
      final item = pillarVoids?[position];
      if (item is Map<String, dynamic>) {
        return item['void'] as String? ?? '未记录';
      }
      if (item is String) return item;
      if (position == 'day') return time['day_void'] as String? ?? '未记录';
      return '未记录';
    }

    return CastPreview(
      schemaVersion: schemaVersion,
      engineVersion: json['engine_version'] as String,
      castAt: DateTime.parse(meta['cast_at'] as String),
      lineValues: (meta['line_values'] as List<dynamic>)
          .map((value) => value as int)
          .toList(growable: false),
      yearPillar: time['year'] as String,
      monthPillar: time['month'] as String,
      dayPillar: time['day'] as String,
      hourPillar: time['hour'] as String,
      yearVoid: pillarVoid('year'),
      monthVoid: pillarVoid('month'),
      dayVoid: pillarVoid('day'),
      hourVoid: pillarVoid('hour'),
      castingRecord: CastingRecord.fromJson(
        json['casting_record'] as Map<String, dynamic>,
      ),
      rulePackage: ChartRulePackage.fromJson(
        json['rule_package'] as Map<String, dynamic>,
      ),
      chart: LiuyaoChart.fromJson(json['hexagram'] as Map<String, dynamic>),
      annotations: json['annotations'] == null
          ? const RuleAnnotations.empty()
          : RuleAnnotations.fromJson(
              json['annotations'] as Map<String, dynamic>,
            ),
      calculationTrace:
          (json['calculation_trace'] as List<dynamic>? ?? const [])
              .map(
                (item) =>
                    CalculationTrace.fromJson(item as Map<String, dynamic>),
              )
              .toList(growable: false),
      rawJson: Map<String, dynamic>.unmodifiable(json),
    );
  }

  /// 从 Dart 引擎结果创建 CastPreview（离线模式）
  factory CastPreview.fromEngineResult(
    Map<String, dynamic> engineResult, {
    String? question,
  }) {
    final meta = engineResult['meta'] as Map<String, dynamic>;
    final time = engineResult['time'] as Map<String, dynamic>;
    final pillarVoids = time['pillar_voids'] as Map<String, dynamic>?;

    String pillarVoid(String position) {
      final item = pillarVoids?[position];
      if (item is Map<String, dynamic>) {
        return item['void'] as String? ?? '未记录';
      }
      if (item is String) return item;
      if (position == 'day') return time['day_void'] as String? ?? '未记录';
      return '未记录';
    }

    return CastPreview(
      schemaVersion: (engineResult['schema_version'] as num).toInt(),
      engineVersion: engineResult['engine_version'] as String,
      castAt: DateTime.parse(meta['cast_at'] as String),
      lineValues: (meta['line_values'] as List<dynamic>)
          .map((value) => value as int)
          .toList(growable: false),
      yearPillar: time['year'] as String,
      monthPillar: time['month'] as String,
      dayPillar: time['day'] as String,
      hourPillar: time['hour'] as String,
      yearVoid: pillarVoid('year'),
      monthVoid: pillarVoid('month'),
      dayVoid: pillarVoid('day'),
      hourVoid: pillarVoid('hour'),
      castingRecord: CastingRecord.fromJson(
        engineResult['casting_record'] as Map<String, dynamic>,
      ),
      rulePackage: ChartRulePackage.fromJson(
        engineResult['rule_package'] as Map<String, dynamic>,
      ),
      chart: LiuyaoChart.fromJson(
        engineResult['hexagram'] as Map<String, dynamic>,
      ),
      annotations: engineResult['annotations'] == null
          ? const RuleAnnotations.empty()
          : RuleAnnotations.fromJson(
              engineResult['annotations'] as Map<String, dynamic>,
            ),
      calculationTrace:
          (engineResult['calculation_trace'] as List<dynamic>? ?? const [])
              .map(
                (item) =>
                    CalculationTrace.fromJson(item as Map<String, dynamic>),
              )
              .toList(growable: false),
      rawJson: Map<String, dynamic>.unmodifiable(engineResult),
    );
  }

  factory CastPreview._fromLegacy(Map<String, dynamic> json) {
    final schemaVersion = (json['schema_version'] as num?)?.toInt() ?? 1;
    final engineVersion = json['engine_version'] as String? ?? 'legacy';
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    final time = json['time'] as Map<String, dynamic>? ?? const {};
    final hexagram = json['hexagram'] as Map<String, dynamic>? ?? const {};
    final baseJson = hexagram['base'] as Map<String, dynamic>? ?? const {};
    final changedJson = hexagram['changed'] as Map<String, dynamic>?;
    final rawLines = baseJson['lines'] as List<dynamic>? ?? const [];
    final lines = rawLines
        .map((item) => _legacyBaseLine(item as Map<String, dynamic>))
        .toList(growable: false);
    final lineValues = (meta['line_values'] as List<dynamic>? ?? const [])
        .map((item) => (item as num).toInt())
        .toList(growable: false);
    final resolvedValues = lineValues.isEmpty
        ? lines.map((line) => line.value).toList(growable: false)
        : lineValues;
    final movingPositions = lines
        .where((line) => line.changing)
        .map((line) => line.position)
        .toList(growable: false);
    final method = meta['casting_method'] as String? ?? 'manual';
    final palaceName = baseJson['palace_name'] as String? ?? '未记录';
    final palaceElement = baseJson['palace_element'] as String? ?? '';
    final shiPosition = _rolePosition(lines, '世');
    final yingPosition = _rolePosition(lines, '应');
    final castAtText = meta['cast_at'] as String?;
    final castAt =
        DateTime.tryParse(castAtText ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    return CastPreview(
      schemaVersion: schemaVersion,
      engineVersion: engineVersion,
      castAt: castAt,
      lineValues: resolvedValues,
      yearPillar: time['year'] as String? ?? '未记录',
      monthPillar: time['month'] as String? ?? '未记录',
      dayPillar: time['day'] as String? ?? '未记录',
      hourPillar: time['hour'] as String? ?? '未记录',
      yearVoid: '未记录',
      monthVoid: '未记录',
      dayVoid: time['day_void'] as String? ?? '未记录',
      hourVoid: '未记录',
      castingRecord: CastingRecord(
        method: method,
        methodVersion: 'legacy.schema$schemaVersion',
        lineOrder: meta['line_order'] as String? ?? 'bottom_to_top',
        lineValues: resolvedValues,
        lines: List.generate(resolvedValues.length, (index) {
          final value = resolvedValues[index];
          return CastingLineRecord(
            position: index + 1,
            positionName: _positionName(index + 1),
            source: 'legacy_snapshot',
            coins: const [],
            total: value,
            value: value,
            yinYang: value.isEven ? 'yin' : 'yang',
            changing: value == 6 || value == 9,
            traditionalName: _traditionalName(value),
          );
        }),
        randomSource: null,
      ),
      rulePackage: ChartRulePackage(
        id: 'legacy.snapshot.schema$schemaVersion',
        version: '$schemaVersion',
        status: 'historical_read_only',
        sourceIds: const [],
        upstreamVersion: engineVersion,
        auditedCommit: 'not_recorded',
      ),
      chart: LiuyaoChart(
        lineOrder: 'bottom_to_top',
        displayOrder: 'top_to_bottom',
        movingPositions: movingPositions,
        base: BaseHexagram(
          id: 'base',
          code: baseJson['code'] as String? ?? '',
          name: baseJson['name'] as String? ?? '未记录',
          lowerTrigram: const TrigramSummary(
            code: '',
            name: '资料未存',
            element: '',
          ),
          upperTrigram: const TrigramSummary(
            code: '',
            name: '资料未存',
            element: '',
          ),
          palace: TrigramSummary(
            code: '',
            name: palaceName,
            element: palaceElement,
          ),
          palaceSequence: _legacyPalaceSequence(baseJson),
          hexagramKind: 'legacy',
          shiPosition: shiPosition,
          yingPosition: yingPosition,
          movingPositions: movingPositions,
          hiddenHexagram: null,
          lines: lines,
        ),
        changed: changedJson == null
            ? null
            : _legacyChangedHexagram(
                changedJson,
                basePalaceName: palaceName,
                basePalaceElement: palaceElement,
                movingPositions: movingPositions,
              ),
      ),
      annotations: const RuleAnnotations.empty(),
      calculationTrace: const [],
      rawJson: Map<String, dynamic>.unmodifiable(json),
    );
  }

  final int schemaVersion;
  final String engineVersion;
  final DateTime castAt;
  final List<int> lineValues;
  final String yearPillar;
  final String monthPillar;
  final String dayPillar;
  final String hourPillar;
  final String yearVoid;
  final String monthVoid;
  final String dayVoid;
  final String hourVoid;
  final CastingRecord castingRecord;
  final ChartRulePackage rulePackage;
  final LiuyaoChart chart;
  final RuleAnnotations annotations;
  final List<CalculationTrace> calculationTrace;
  final Map<String, dynamic> rawJson;

  /// 四柱来源：'calculated'（自动，默认）| 'manual'（手动填写）。
  final String fourPillarsSource;

  /// 手动填写的四柱；仅 [fourPillarsSource] == 'manual' 时有值。
  final ManualFourPillars? manualFourPillars;

  String get baseHexagram => chart.base.name;
  String? get changedHexagram => chart.changed?.name;

  bool get isLegacySnapshot => schemaVersion < 3;
  bool get hasCanonicalPalaceSequence =>
      _versionAtLeast(rulePackage.version, 1, 1, 0) ||
      chart.base.palaceSequence > 0;

  /// 以手动四柱覆盖显示值，返回新 [CastPreview]。
  ///
  /// 引擎自动计算的原始四柱仍在 [rawJson] 中保留可追溯；覆盖只影响
  /// year/month/day/hourPillar 与来源标记，不重写卦象。
  CastPreview applyManualFourPillars(ManualFourPillars manual) {
    return CastPreview(
      schemaVersion: schemaVersion,
      engineVersion: engineVersion,
      castAt: castAt,
      lineValues: lineValues,
      yearPillar: manual.year,
      monthPillar: manual.month,
      dayPillar: manual.day,
      hourPillar: manual.hour,
      yearVoid: yearVoid,
      monthVoid: monthVoid,
      dayVoid: dayVoid,
      hourVoid: hourVoid,
      castingRecord: castingRecord,
      rulePackage: rulePackage,
      chart: chart,
      annotations: annotations,
      calculationTrace: calculationTrace,
      rawJson: rawJson,
      fourPillarsSource: 'manual',
      manualFourPillars: manual,
    );
  }
}

/// 手动填写的完整四柱（年/月/日/时，每柱天干+地支）。
class ManualFourPillars {
  const ManualFourPillars({
    required this.yearGan,
    required this.yearZhi,
    required this.monthGan,
    required this.monthZhi,
    required this.dayGan,
    required this.dayZhi,
    required this.hourGan,
    required this.hourZhi,
  });

  factory ManualFourPillars.fromJson(Map<String, dynamic> json) {
    return ManualFourPillars(
      yearGan: json['year_gan'] as String? ?? '',
      yearZhi: json['year_zhi'] as String? ?? '',
      monthGan: json['month_gan'] as String? ?? '',
      monthZhi: json['month_zhi'] as String? ?? '',
      dayGan: json['day_gan'] as String? ?? '',
      dayZhi: json['day_zhi'] as String? ?? '',
      hourGan: json['hour_gan'] as String? ?? '',
      hourZhi: json['hour_zhi'] as String? ?? '',
    );
  }

  final String yearGan;
  final String yearZhi;
  final String monthGan;
  final String monthZhi;
  final String dayGan;
  final String dayZhi;
  final String hourGan;
  final String hourZhi;

  static const List<String> heavenlyStems = [
    '甲',
    '乙',
    '丙',
    '丁',
    '戊',
    '己',
    '庚',
    '辛',
    '壬',
    '癸',
  ];
  static const List<String> earthlyBranches = [
    '子',
    '丑',
    '寅',
    '卯',
    '辰',
    '巳',
    '午',
    '未',
    '申',
    '酉',
    '戌',
    '亥',
  ];

  String get year => '$yearGan$yearZhi';
  String get month => '$monthGan$monthZhi';
  String get day => '$dayGan$dayZhi';
  String get hour => '$hourGan$hourZhi';

  bool get isComplete =>
      _all(_stemValid(yearGan), _branchValid(yearZhi)) &&
      _all(_stemValid(monthGan), _branchValid(monthZhi)) &&
      _all(_stemValid(dayGan), _branchValid(dayZhi)) &&
      _all(_stemValid(hourGan), _branchValid(hourZhi));

  /// 引擎可用的四柱干支 Map（{'year': '甲子', ...}）。
  Map<String, String> toPillarsMap() => <String, String>{
    'year': year,
    'month': month,
    'day': day,
    'hour': hour,
  };

  /// 干支组合不在六十甲子内的柱位（如「甲丑」），返回中文柱名列表。
  List<String> invalidPillarNames() {
    const labels = {'year': '年柱', 'month': '月柱', 'day': '日柱', 'hour': '时柱'};
    return [
      for (final entry in toPillarsMap().entries)
        if (!engine.the60HeavenlyEarth.contains(entry.value))
          labels[entry.key]!,
    ];
  }

  static bool _all(bool first, bool second) => first && second;

  static bool _stemValid(String value) => heavenlyStems.contains(value);
  static bool _branchValid(String value) => earthlyBranches.contains(value);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'year_gan': yearGan,
    'year_zhi': yearZhi,
    'month_gan': monthGan,
    'month_zhi': monthZhi,
    'day_gan': dayGan,
    'day_zhi': dayZhi,
    'hour_gan': hourGan,
    'hour_zhi': hourZhi,
  };
}

bool _versionAtLeast(String value, int major, int minor, int patch) {
  final parts = value.split('.');
  if (parts.length < 3) return false;
  final current = parts.take(3).map(int.tryParse).toList(growable: false);
  if (current.any((item) => item == null)) return false;
  final expected = [major, minor, patch];
  for (var index = 0; index < expected.length; index++) {
    final item = current[index]!;
    if (item != expected[index]) return item > expected[index];
  }
  return true;
}

class RuleAnnotations {
  const RuleAnnotations({
    required this.fiveElementTwelveStages,
    required this.shenshaResults,
    required this.bodyMarkers,
    required this.twentyEightMansions,
    required this.fiveStars,
    required this.hiddenHexagramAnnotations,
    required this.changedHexagramAnnotations,
  });

  const RuleAnnotations.empty()
    : fiveElementTwelveStages = const FiveElementTwelveStages(
        ruleId: 'not_recorded',
        ruleVersion: '0',
        system: 'not_recorded',
        scope: 'none',
        lineResults: [],
      ),
      shenshaResults = const [],
      bodyMarkers = null,
      twentyEightMansions = null,
      fiveStars = null,
      hiddenHexagramAnnotations = null,
      changedHexagramAnnotations = null;

  factory RuleAnnotations.fromJson(Map<String, dynamic> json) {
    final twelveStages = json['five_element_twelve_stages'];
    final shensha = json['shensha'] as Map<String, dynamic>?;
    final layers = json['hexagram_layers'] as Map<String, dynamic>?;
    final hiddenLayer = layers?['hidden'] as Map<String, dynamic>?;
    final changedLayer = layers?['changed'] as Map<String, dynamic>?;
    return RuleAnnotations(
      fiveElementTwelveStages: twelveStages == null
          ? const FiveElementTwelveStages(
              ruleId: 'not_recorded',
              ruleVersion: '0',
              system: 'not_recorded',
              scope: 'none',
              lineResults: [],
            )
          : FiveElementTwelveStages.fromJson(
              twelveStages as Map<String, dynamic>,
            ),
      shenshaResults: (shensha?['results'] as List<dynamic>? ?? const [])
          .map((item) => ShenshaResult.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      bodyMarkers: json['body_markers'] == null
          ? null
          : SelectedBodyMarkers.fromJson(
              json['body_markers'] as Map<String, dynamic>,
            ),
      twentyEightMansions: json['twenty_eight_mansions'] == null
          ? null
          : TwentyEightMansions.fromJson(
              json['twenty_eight_mansions'] as Map<String, dynamic>,
            ),
      fiveStars: json['five_stars'] == null
          ? null
          : FiveStars.fromJson(json['five_stars'] as Map<String, dynamic>),
      hiddenHexagramAnnotations: hiddenLayer == null
          ? null
          : HexagramLayerAnnotations.fromJson(hiddenLayer),
      changedHexagramAnnotations: changedLayer == null
          ? null
          : HexagramLayerAnnotations.fromJson(changedLayer),
    );
  }

  final FiveElementTwelveStages fiveElementTwelveStages;
  final List<ShenshaResult> shenshaResults;
  final SelectedBodyMarkers? bodyMarkers;
  final TwentyEightMansions? twentyEightMansions;
  final FiveStars? fiveStars;
  final HexagramLayerAnnotations? hiddenHexagramAnnotations;
  final HexagramLayerAnnotations? changedHexagramAnnotations;
}

/// 京房八宫六十四卦五星排布（用户 2026-08-19 确认规则）。
class FiveStars {
  const FiveStars({
    required this.ruleId,
    required this.ruleVersion,
    required this.system,
    required this.hexagram,
    required this.worldLine,
    required this.responseLine,
    required this.linePlacements,
  });

  factory FiveStars.fromJson(Map<String, dynamic> json) {
    return FiveStars(
      ruleId: json['rule_id'] as String,
      ruleVersion: json['rule_version'] as String,
      system: json['system'] as String,
      hexagram: FiveStarHexagram.fromJson(
        json['hexagram'] as Map<String, dynamic>,
      ),
      worldLine: FiveStarLine.fromJson(
        json['world_line'] as Map<String, dynamic>,
      ),
      responseLine: FiveStarLine.fromJson(
        json['response_line'] as Map<String, dynamic>,
      ),
      linePlacements: (json['line_placements'] as List<dynamic>)
          .map(
            (item) => FiveStarPlacement.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  final String ruleId;
  final String ruleVersion;
  final String system;
  final FiveStarHexagram hexagram;
  final FiveStarLine worldLine;
  final FiveStarLine responseLine;
  final List<FiveStarPlacement> linePlacements;

  FiveStarPlacement? placementAt(int position) {
    for (final item in linePlacements) {
      if (item.position == position) return item;
    }
    return null;
  }
}

class FiveStarHexagram {
  const FiveStarHexagram({
    required this.code,
    required this.name,
    required this.palaceName,
    required this.palaceIndex,
    required this.palaceSequence,
  });

  factory FiveStarHexagram.fromJson(Map<String, dynamic> json) {
    return FiveStarHexagram(
      code: json['code'] as String,
      name: json['name'] as String,
      palaceName: json['palace_name'] as String,
      palaceIndex: json['palace_index'] as int,
      palaceSequence: json['palace_sequence'] as int,
    );
  }

  final String code;
  final String name;
  final String palaceName;
  final int palaceIndex;
  final int palaceSequence;
}

class FiveStarLine {
  const FiveStarLine({
    required this.position,
    required this.positionName,
    required this.star,
    required this.starName,
    required this.element,
  });

  factory FiveStarLine.fromJson(Map<String, dynamic> json) {
    return FiveStarLine(
      position: json['position'] as int,
      positionName: json['position_name'] as String,
      star: json['star'] as String,
      starName: json['star_name'] as String,
      element: json['element'] as String,
    );
  }

  final int position;
  final String positionName;
  final String star;
  final String starName;
  final String element;
}

class FiveStarPlacement {
  const FiveStarPlacement({
    required this.position,
    required this.positionName,
    required this.role,
    required this.star,
    required this.starName,
    required this.element,
    required this.sequenceIndex,
  });

  factory FiveStarPlacement.fromJson(Map<String, dynamic> json) {
    return FiveStarPlacement(
      position: json['position'] as int,
      positionName: json['position_name'] as String,
      role: json['role'] as String,
      star: json['star'] as String,
      starName: json['star_name'] as String,
      element: json['element'] as String,
      sequenceIndex: json['sequence_index'] as int,
    );
  }

  final int position;
  final String positionName;
  final String role;
  final String star;
  final String starName;
  final String element;
  final int sequenceIndex;
}

class HexagramLayerAnnotations {
  const HexagramLayerAnnotations({
    required this.fiveElementTwelveStages,
    required this.twentyEightMansions,
    required this.fiveStars,
  });

  factory HexagramLayerAnnotations.fromJson(Map<String, dynamic> json) {
    return HexagramLayerAnnotations(
      fiveElementTwelveStages: FiveElementTwelveStages.fromJson(
        json['five_element_twelve_stages'] as Map<String, dynamic>,
      ),
      twentyEightMansions: TwentyEightMansions.fromJson(
        json['twenty_eight_mansions'] as Map<String, dynamic>,
      ),
      fiveStars: json['five_stars'] == null
          ? null
          : FiveStars.fromJson(json['five_stars'] as Map<String, dynamic>),
    );
  }

  final FiveElementTwelveStages fiveElementTwelveStages;
  final TwentyEightMansions twentyEightMansions;
  final FiveStars? fiveStars;
}

class SelectedBodyMarkers {
  const SelectedBodyMarkers({
    required this.ruleId,
    required this.ruleVersion,
    required this.guaShen,
    required this.mingYao,
  });

  factory SelectedBodyMarkers.fromJson(Map<String, dynamic> json) {
    return SelectedBodyMarkers(
      ruleId: json['rule_id'] as String,
      ruleVersion: json['rule_version'] as String,
      guaShen: GuaShenMarker.fromJson(json['guashen'] as Map<String, dynamic>),
      mingYao: MingYaoMarker.fromJson(json['mingyao'] as Map<String, dynamic>),
    );
  }

  final String ruleId;
  final String ruleVersion;
  final GuaShenMarker guaShen;
  final MingYaoMarker mingYao;
}

class BodyMarkerLine {
  const BodyMarkerLine({
    required this.position,
    required this.positionName,
    required this.ganZhi,
    required this.branch,
    required this.relation,
  });

  factory BodyMarkerLine.fromJson(Map<String, dynamic> json) {
    return BodyMarkerLine(
      position: json['position'] as int,
      positionName: json['position_name'] as String,
      ganZhi: json['gan_zhi'] as String,
      branch: json['branch'] as String,
      relation: json['relation'] as String,
    );
  }

  final int position;
  final String positionName;
  final String ganZhi;
  final String branch;
  final String relation;
}

class GuaShenMarker {
  const GuaShenMarker({
    required this.displayName,
    required this.canonicalName,
    required this.targetBranch,
    required this.status,
    required this.matches,
  });

  factory GuaShenMarker.fromJson(Map<String, dynamic> json) {
    return GuaShenMarker(
      displayName: json['display_name'] as String,
      canonicalName: json['canonical_name'] as String,
      targetBranch: json['target_branch'] as String,
      status: json['status'] as String,
      matches: (json['matches'] as List<dynamic>)
          .map((item) => BodyMarkerLine.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final String displayName;
  final String canonicalName;
  final String targetBranch;
  final String status;
  final List<BodyMarkerLine> matches;
}

class MingYaoMarker {
  const MingYaoMarker({
    required this.displayName,
    required this.position,
    required this.line,
    required this.variantId,
  });

  factory MingYaoMarker.fromJson(Map<String, dynamic> json) {
    return MingYaoMarker(
      displayName: json['display_name'] as String,
      position: json['position'] as int,
      line: BodyMarkerLine.fromJson(json['line'] as Map<String, dynamic>),
      variantId: json['variant_id'] as String,
    );
  }

  final String displayName;
  final int position;
  final BodyMarkerLine line;
  final String variantId;
}

class TwentyEightMansions {
  const TwentyEightMansions({
    required this.ruleId,
    required this.ruleVersion,
    required this.system,
    required this.scope,
    required this.hexagramGlobalIndex,
    required this.worldLinePosition,
    required this.worldMansion,
    required this.responseLinePosition,
    required this.placementPositionOrder,
    required this.linePlacements,
  });

  factory TwentyEightMansions.fromJson(Map<String, dynamic> json) {
    final hexagram = json['hexagram'] as Map<String, dynamic>;
    final worldLine = json['world_line'] as Map<String, dynamic>;
    final responseLine = json['response_line'] as Map<String, dynamic>;
    return TwentyEightMansions(
      ruleId: json['rule_id'] as String,
      ruleVersion: json['rule_version'] as String,
      system: json['system'] as String,
      scope: json['scope'] as String,
      hexagramGlobalIndex: hexagram['global_index'] as int,
      worldLinePosition: worldLine['position'] as int,
      worldMansion: worldLine['mansion'] as String,
      responseLinePosition: responseLine['position'] as int,
      placementPositionOrder:
          (json['placement_position_order'] as List<dynamic>)
              .map((item) => item as int)
              .toList(growable: false),
      linePlacements: (json['line_placements'] as List<dynamic>)
          .map(
            (item) =>
                MansionLinePlacement.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  final String ruleId;
  final String ruleVersion;
  final String system;
  final String scope;
  final int hexagramGlobalIndex;
  final int worldLinePosition;
  final String worldMansion;
  final int responseLinePosition;
  final List<int> placementPositionOrder;
  final List<MansionLinePlacement> linePlacements;

  MansionLinePlacement? placementAt(int position) {
    for (final placement in linePlacements) {
      if (placement.position == position) return placement;
    }
    return null;
  }
}

class MansionLinePlacement {
  const MansionLinePlacement({
    required this.order,
    required this.lineId,
    required this.position,
    required this.positionName,
    required this.placementRole,
    required this.mansionIndex,
    required this.mansion,
  });

  factory MansionLinePlacement.fromJson(Map<String, dynamic> json) {
    return MansionLinePlacement(
      order: json['order'] as int,
      lineId: json['line_id'] as String,
      position: json['position'] as int,
      positionName: json['position_name'] as String,
      placementRole: json['placement_role'] as String,
      mansionIndex: json['mansion_index'] as int,
      mansion: json['mansion'] as String,
    );
  }

  final int order;
  final String lineId;
  final int position;
  final String positionName;
  final String placementRole;
  final int mansionIndex;
  final String mansion;
}

class ShenshaResult {
  const ShenshaResult({
    required this.ruleId,
    required this.ruleVersion,
    required this.displayName,
    required this.canonicalName,
    required this.category,
    required this.scope,
    required this.basisType,
    required this.basisPillarGanZhi,
    required this.basisValue,
    required this.targetBranches,
    required this.status,
    required this.matches,
    required this.excludedScopes,
  });

  factory ShenshaResult.fromJson(Map<String, dynamic> json) {
    final basis = json['basis'] as Map<String, dynamic>;
    return ShenshaResult(
      ruleId: json['rule_id'] as String,
      ruleVersion: json['rule_version'] as String,
      displayName: json['display_name'] as String,
      canonicalName: json['canonical_name'] as String,
      category: json['category'] as String,
      scope: json['scope'] as String,
      basisType: basis['type'] as String,
      basisPillarGanZhi: basis['pillar_gan_zhi'] as String,
      basisValue: basis['value'] as String,
      targetBranches: (json['target_branches'] as List<dynamic>)
          .map((item) => item as String)
          .toList(growable: false),
      status: json['status'] as String,
      matches: (json['matches'] as List<dynamic>)
          .map((item) => ShenshaMatch.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      excludedScopes: (json['excluded_scopes'] as List<dynamic>)
          .map((item) => item as String)
          .toList(growable: false),
    );
  }

  final String ruleId;
  final String ruleVersion;
  final String displayName;
  final String canonicalName;
  final String category;
  final String scope;
  final String basisType;
  final String basisPillarGanZhi;
  final String basisValue;
  final List<String> targetBranches;
  final String status;
  final List<ShenshaMatch> matches;
  final List<String> excludedScopes;
}

class ShenshaMatch {
  const ShenshaMatch({
    required this.lineId,
    required this.position,
    required this.positionName,
    required this.ganZhi,
    required this.branch,
    required this.relation,
  });

  factory ShenshaMatch.fromJson(Map<String, dynamic> json) {
    return ShenshaMatch(
      lineId: json['line_id'] as String,
      position: json['position'] as int,
      positionName: json['position_name'] as String,
      ganZhi: json['gan_zhi'] as String,
      branch: json['branch'] as String,
      relation: json['relation'] as String,
    );
  }

  final String lineId;
  final int position;
  final String positionName;
  final String ganZhi;
  final String branch;
  final String relation;
}

class FiveElementTwelveStages {
  const FiveElementTwelveStages({
    required this.ruleId,
    required this.ruleVersion,
    required this.system,
    required this.scope,
    required this.lineResults,
  });

  factory FiveElementTwelveStages.fromJson(Map<String, dynamic> json) {
    return FiveElementTwelveStages(
      ruleId: json['rule_id'] as String,
      ruleVersion: json['rule_version'] as String,
      system: json['system'] as String,
      scope: json['scope'] as String,
      lineResults: (json['line_results'] as List<dynamic>)
          .map(
            (item) =>
                TwelveStageLineResult.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  final String ruleId;
  final String ruleVersion;
  final String system;
  final String scope;
  final List<TwelveStageLineResult> lineResults;
}

class TwelveStageLineResult {
  const TwelveStageLineResult({
    required this.lineId,
    required this.position,
    required this.positionName,
    required this.lineElement,
    required this.pillarResults,
  });

  factory TwelveStageLineResult.fromJson(Map<String, dynamic> json) {
    return TwelveStageLineResult(
      lineId: json['line_id'] as String,
      position: json['position'] as int,
      positionName: json['position_name'] as String,
      lineElement: json['line_element'] as String,
      pillarResults: (json['pillar_results'] as List<dynamic>)
          .map(
            (item) =>
                TwelveStagePillarResult.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  final String lineId;
  final int position;
  final String positionName;
  final String lineElement;
  final List<TwelveStagePillarResult> pillarResults;
}

class TwelveStagePillarResult {
  const TwelveStagePillarResult({
    required this.reference,
    required this.referenceLabel,
    required this.pillarGanZhi,
    required this.referenceBranch,
    required this.stage,
  });

  factory TwelveStagePillarResult.fromJson(Map<String, dynamic> json) {
    return TwelveStagePillarResult(
      reference: json['reference'] as String,
      referenceLabel: json['reference_label'] as String,
      pillarGanZhi: json['pillar_gan_zhi'] as String,
      referenceBranch: json['reference_branch'] as String,
      stage: json['stage'] as String,
    );
  }

  final String reference;
  final String referenceLabel;
  final String pillarGanZhi;
  final String referenceBranch;
  final String stage;
}

class ChartRulePackage {
  const ChartRulePackage({
    required this.id,
    required this.version,
    required this.status,
    required this.sourceIds,
    required this.upstreamVersion,
    required this.auditedCommit,
  });

  factory ChartRulePackage.fromJson(Map<String, dynamic> json) {
    final upstream = json['upstream'] as Map<String, dynamic>;
    return ChartRulePackage(
      id: json['id'] as String,
      version: json['version'] as String,
      status: json['status'] as String,
      sourceIds: (json['source_ids'] as List<dynamic>)
          .map((item) => item as String)
          .toList(growable: false),
      upstreamVersion: upstream['installed_version'] as String,
      auditedCommit: upstream['audited_commit'] as String,
    );
  }

  final String id;
  final String version;
  final String status;
  final List<String> sourceIds;
  final String upstreamVersion;
  final String auditedCommit;
}

class LiuyaoChart {
  const LiuyaoChart({
    required this.lineOrder,
    required this.displayOrder,
    required this.movingPositions,
    required this.base,
    required this.changed,
  });

  factory LiuyaoChart.fromJson(Map<String, dynamic> json) {
    final changed = json['changed'];
    return LiuyaoChart(
      lineOrder: json['line_order'] as String,
      displayOrder: json['display_order'] as String,
      movingPositions: (json['moving_positions'] as List<dynamic>)
          .map((item) => item as int)
          .toList(growable: false),
      base: BaseHexagram.fromJson(json['base'] as Map<String, dynamic>),
      changed: changed == null
          ? null
          : ChangedHexagram.fromJson(changed as Map<String, dynamic>),
    );
  }

  final String lineOrder;
  final String displayOrder;
  final List<int> movingPositions;
  final BaseHexagram base;
  final ChangedHexagram? changed;
}

class TrigramSummary {
  const TrigramSummary({
    required this.code,
    required this.name,
    required this.element,
  });

  factory TrigramSummary.fromJson(Map<String, dynamic> json) {
    return TrigramSummary(
      code: json['code'] as String,
      name: json['name'] as String,
      element: json['element'] as String,
    );
  }

  final String code;
  final String name;
  final String element;
}

class BaseHexagram {
  const BaseHexagram({
    required this.id,
    required this.code,
    required this.name,
    required this.lowerTrigram,
    required this.upperTrigram,
    required this.palace,
    required this.palaceSequence,
    required this.hexagramKind,
    required this.shiPosition,
    required this.yingPosition,
    required this.movingPositions,
    this.liuChong = false,
    this.liuHe = false,
    this.hexagramProperty,
    required this.hiddenHexagram,
    required this.lines,
  });

  factory BaseHexagram.fromJson(Map<String, dynamic> json) {
    return BaseHexagram(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      lowerTrigram: TrigramSummary.fromJson(
        json['lower_trigram'] as Map<String, dynamic>,
      ),
      upperTrigram: TrigramSummary.fromJson(
        json['upper_trigram'] as Map<String, dynamic>,
      ),
      palace: TrigramSummary.fromJson(json['palace'] as Map<String, dynamic>),
      palaceSequence: json['palace_sequence'] as int,
      hexagramKind: json['hexagram_kind'] as String,
      shiPosition: json['shi_position'] as int,
      yingPosition: json['ying_position'] as int,
      movingPositions: (json['moving_positions'] as List<dynamic>)
          .map((item) => item as int)
          .toList(growable: false),
      liuChong: json['liu_chong'] as bool? ?? false,
      liuHe: json['liu_he'] as bool? ?? false,
      hexagramProperty: json['hexagram_property'] as String?,
      hiddenHexagram: json['hidden_hexagram'] == null
          ? null
          : HiddenHexagram.fromJson(
              json['hidden_hexagram'] as Map<String, dynamic>,
            ),
      lines: (json['lines'] as List<dynamic>)
          .map((item) => BaseChartLine.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final String id;
  final String code;
  final String name;
  final TrigramSummary lowerTrigram;
  final TrigramSummary upperTrigram;
  final TrigramSummary palace;
  final int palaceSequence;
  final String hexagramKind;
  final int shiPosition;
  final int yingPosition;
  final List<int> movingPositions;
  final bool liuChong;
  final bool liuHe;
  final String? hexagramProperty;
  final HiddenHexagram? hiddenHexagram;
  final List<BaseChartLine> lines;
}

class HiddenHexagram {
  const HiddenHexagram({
    required this.code,
    required this.name,
    required this.lowerTrigram,
    required this.upperTrigram,
    required this.palaceBasis,
    required this.palaceOpposite,
  });

  factory HiddenHexagram.fromJson(Map<String, dynamic> json) {
    return HiddenHexagram(
      code: json['code'] as String,
      name: json['name'] as String,
      lowerTrigram: TrigramSummary.fromJson(
        json['lower_trigram'] as Map<String, dynamic>,
      ),
      upperTrigram: TrigramSummary.fromJson(
        json['upper_trigram'] as Map<String, dynamic>,
      ),
      palaceBasis: TrigramSummary.fromJson(
        json['palace_basis'] as Map<String, dynamic>,
      ),
      palaceOpposite: TrigramSummary.fromJson(
        json['palace_opposite'] as Map<String, dynamic>,
      ),
    );
  }

  final String code;
  final String name;
  final TrigramSummary lowerTrigram;
  final TrigramSummary upperTrigram;
  final TrigramSummary palaceBasis;
  final TrigramSummary palaceOpposite;
}

class ChangedHexagram {
  const ChangedHexagram({
    required this.id,
    required this.code,
    required this.name,
    required this.lowerTrigram,
    required this.upperTrigram,
    required this.palace,
    required this.palaceSequence,
    required this.hexagramKind,
    required this.shiPosition,
    required this.yingPosition,
    this.liuChong = false,
    this.liuHe = false,
    this.hexagramProperty,
    required this.relativeBasis,
    required this.relativeBasisElement,
    required this.lines,
  });

  factory ChangedHexagram.fromJson(Map<String, dynamic> json) {
    return ChangedHexagram(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      lowerTrigram: TrigramSummary.fromJson(
        json['lower_trigram'] as Map<String, dynamic>,
      ),
      upperTrigram: TrigramSummary.fromJson(
        json['upper_trigram'] as Map<String, dynamic>,
      ),
      palace: TrigramSummary.fromJson(json['palace'] as Map<String, dynamic>),
      palaceSequence: json['palace_sequence'] as int? ?? 0,
      hexagramKind: json['hexagram_kind'] as String? ?? 'unrecorded',
      shiPosition: json['shi_position'] as int? ?? 0,
      yingPosition: json['ying_position'] as int? ?? 0,
      relativeBasis: json['relative_basis'] as String,
      relativeBasisElement: json['relative_basis_element'] as String,
      liuChong: json['liu_chong'] as bool? ?? false,
      liuHe: json['liu_he'] as bool? ?? false,
      hexagramProperty: json['hexagram_property'] as String?,
      lines: (json['lines'] as List<dynamic>)
          .map(
            (item) => ChangedChartLine.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  final String id;
  final String code;
  final String name;
  final TrigramSummary lowerTrigram;
  final TrigramSummary upperTrigram;
  final TrigramSummary palace;
  final int palaceSequence;
  final String hexagramKind;
  final int shiPosition;
  final int yingPosition;
  final bool liuChong;
  final bool liuHe;
  final String? hexagramProperty;
  final String relativeBasis;
  final String relativeBasisElement;
  final List<ChangedChartLine> lines;
}

class NajiaFields {
  const NajiaFields({
    required this.heavenlyStem,
    required this.earthlyBranch,
    required this.ganZhi,
    required this.element,
    this.nayin,
  });

  factory NajiaFields.fromJson(Map<String, dynamic> json) {
    return NajiaFields(
      heavenlyStem: json['heavenly_stem'] as String,
      earthlyBranch: json['earthly_branch'] as String,
      ganZhi: json['gan_zhi'] as String,
      element: json['element'] as String,
      nayin: json['nayin'] as String?,
    );
  }

  final String heavenlyStem;
  final String earthlyBranch;
  final String ganZhi;
  final String element;
  final String? nayin;
}

class BaseChartLine {
  const BaseChartLine({
    required this.id,
    required this.position,
    required this.positionName,
    required this.value,
    required this.yinYang,
    required this.changing,
    required this.sixGod,
    required this.relation,
    required this.najia,
    required this.role,
    required this.hidden,
  });

  factory BaseChartLine.fromJson(Map<String, dynamic> json) {
    final hidden = json['hidden'];
    return BaseChartLine(
      id: json['id'] as String,
      position: json['position'] as int,
      positionName: json['position_name'] as String,
      value: json['value'] as int,
      yinYang: json['yin_yang'] as String,
      changing: json['changing'] as bool,
      sixGod: json['six_god'] as String,
      relation: json['relation'] as String,
      najia: NajiaFields.fromJson(json),
      role: json['role'] as String?,
      hidden: hidden == null
          ? null
          : HiddenSpirit.fromJson(hidden as Map<String, dynamic>),
    );
  }

  final String id;
  final int position;
  final String positionName;
  final int value;
  final String yinYang;
  final bool changing;
  final String sixGod;
  final String relation;
  final NajiaFields najia;
  final String? role;
  final HiddenSpirit? hidden;
}

class HiddenSpirit {
  const HiddenSpirit({
    required this.id,
    required this.position,
    required this.positionName,
    required this.relation,
    required this.najia,
    required this.sourceHexagram,
    required this.flyingLineId,
    required this.relationMissingFromBase,
  });

  factory HiddenSpirit.fromJson(Map<String, dynamic> json) {
    final source = json['source_hexagram'] as Map<String, dynamic>;
    return HiddenSpirit(
      id: json['id'] as String,
      position: json['position'] as int,
      positionName: json['position_name'] as String,
      relation: json['relation'] as String,
      najia: NajiaFields.fromJson(json),
      sourceHexagram: source['name'] as String,
      flyingLineId: json['flying_line_id'] as String,
      relationMissingFromBase:
          json['relation_missing_from_base'] as bool? ?? true,
    );
  }

  final String id;
  final int position;
  final String positionName;
  final String relation;
  final NajiaFields najia;
  final String sourceHexagram;
  final String flyingLineId;
  final bool relationMissingFromBase;
}

class ChangedChartLine {
  const ChangedChartLine({
    required this.id,
    required this.position,
    required this.positionName,
    required this.yinYang,
    required this.changedFromBase,
    required this.relation,
    required this.najia,
    required this.role,
  });

  factory ChangedChartLine.fromJson(Map<String, dynamic> json) {
    return ChangedChartLine(
      id: json['id'] as String,
      position: json['position'] as int,
      positionName: json['position_name'] as String,
      yinYang: json['yin_yang'] as String,
      changedFromBase: json['changed_from_base'] as bool,
      relation: json['relation'] as String,
      najia: NajiaFields.fromJson(json),
      role: json['role'] as String?,
    );
  }

  final String id;
  final int position;
  final String positionName;
  final String yinYang;
  final bool changedFromBase;
  final String relation;
  final NajiaFields najia;
  final String? role;
}

class CalculationTrace {
  const CalculationTrace({
    required this.ruleId,
    required this.label,
    required this.scope,
    required this.steps,
    required this.ruleVersion,
    required this.sourceIds,
  });

  factory CalculationTrace.fromJson(Map<String, dynamic> json) {
    return CalculationTrace(
      ruleId: json['rule_id'] as String? ?? 'unknown',
      label: json['label'] as String? ?? '',
      scope: json['scope'] as String? ?? '',
      steps: (json['steps'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      ruleVersion: json['rule_version'] as String? ?? '0',
      sourceIds: (json['source_ids'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
    );
  }

  final String ruleId;
  final String label;
  final String scope;
  final List<String> steps;
  final String ruleVersion;
  final List<String> sourceIds;
}

class CastingRecord {
  const CastingRecord({
    required this.method,
    required this.methodVersion,
    required this.lineOrder,
    required this.lineValues,
    required this.lines,
    required this.randomSource,
  });

  factory CastingRecord.fromJson(Map<String, dynamic> json) {
    final randomSource = json['random_source'];
    return CastingRecord(
      method: json['method'] as String,
      methodVersion: json['method_version'] as String,
      lineOrder: json['line_order'] as String,
      lineValues: (json['line_values'] as List<dynamic>)
          .map((value) => value as int)
          .toList(growable: false),
      lines: (json['lines'] as List<dynamic>)
          .map(
            (item) => CastingLineRecord.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      randomSource: randomSource == null
          ? null
          : CastingRandomSource.fromJson(randomSource as Map<String, dynamic>),
    );
  }

  final String method;
  final String methodVersion;
  final String lineOrder;
  final List<int> lineValues;
  final List<CastingLineRecord> lines;
  final CastingRandomSource? randomSource;
}

class CastingLineRecord {
  const CastingLineRecord({
    required this.position,
    required this.positionName,
    required this.source,
    required this.coins,
    required this.total,
    required this.value,
    required this.yinYang,
    required this.changing,
    required this.traditionalName,
  });

  factory CastingLineRecord.fromJson(Map<String, dynamic> json) {
    return CastingLineRecord(
      position: json['position'] as int,
      positionName: json['position_name'] as String,
      source: json['source'] as String,
      coins: (json['coins'] as List<dynamic>)
          .map((value) => value as int)
          .toList(growable: false),
      total: json['total'] as int,
      value: json['value'] as int,
      yinYang: json['yin_yang'] as String,
      changing: json['changing'] as bool,
      traditionalName: json['traditional_name'] as String,
    );
  }

  final int position;
  final String positionName;
  final String source;
  final List<int> coins;
  final int total;
  final int value;
  final String yinYang;
  final bool changing;
  final String traditionalName;
}

class CastingRandomSource {
  const CastingRandomSource({
    required this.kind,
    required this.generator,
    this.seed,
  });

  factory CastingRandomSource.fromJson(Map<String, dynamic> json) {
    return CastingRandomSource(
      kind: json['kind'] as String,
      generator: json['generator'] as String,
      seed: json['seed'],
    );
  }

  final String kind;
  final String generator;
  final Object? seed;
}

BaseChartLine _legacyBaseLine(Map<String, dynamic> json) {
  final position = (json['position'] as num).toInt();
  final hiddenJson = json['hidden'] as Map<String, dynamic>?;
  return BaseChartLine(
    id: json['id'] as String? ?? 'base-line-$position',
    position: position,
    positionName: json['position_name'] as String? ?? _positionName(position),
    value: (json['value'] as num).toInt(),
    yinYang: json['yin_yang'] as String,
    changing: json['changing'] as bool,
    sixGod: json['six_god'] as String? ?? '未记录',
    relation: json['relation'] as String? ?? '未记录',
    najia: _legacyNajia(json),
    role: json['role'] as String?,
    hidden: hiddenJson == null
        ? null
        : HiddenSpirit(
            id: hiddenJson['id'] as String? ?? 'hidden-$position',
            position: position,
            positionName:
                hiddenJson['position_name'] as String? ??
                _positionName(position),
            relation: hiddenJson['relation'] as String? ?? '未记录',
            najia: _legacyNajia(hiddenJson),
            sourceHexagram:
                (hiddenJson['source_hexagram']
                        as Map<String, dynamic>?)?['name']
                    as String? ??
                '旧档案未记录',
            flyingLineId:
                hiddenJson['flying_line_id'] as String? ??
                'base-line-$position',
            relationMissingFromBase:
                hiddenJson['relation_missing_from_base'] as bool? ?? true,
          ),
  );
}

/// 旧档案卦序补算：优先读存储的 `palace_sequence`；缺失或为 0 时，
/// 从卦码按京房八宫寻世诀计算宫内卦序（1..8）。无法计算返回 0。
int _legacyPalaceSequence(Map<String, dynamic> json) {
  final stored = (json['palace_sequence'] as num?)?.toInt();
  if (stored != null && stored > 0) return stored;
  final code = json['code'] as String? ?? '';
  if (code.length != 6) return 0;
  try {
    return engine.calculateShiYing(code).palaceSequence;
  } catch (_) {
    return 0;
  }
}

ChangedHexagram _legacyChangedHexagram(
  Map<String, dynamic> json, {
  required String basePalaceName,
  required String basePalaceElement,
  required List<int> movingPositions,
}) {
  final changedPalaceName = json['palace_name'] as String? ?? '未记录';
  final changedPalaceElement = json['palace_element'] as String? ?? '';
  final rawLines = json['lines'] as List<dynamic>? ?? const [];
  return ChangedHexagram(
    id: 'changed',
    code: json['code'] as String? ?? '',
    name: json['name'] as String? ?? '未记录',
    lowerTrigram: const TrigramSummary(code: '', name: '资料未存', element: ''),
    upperTrigram: const TrigramSummary(code: '', name: '资料未存', element: ''),
    palace: TrigramSummary(
      code: '',
      name: changedPalaceName,
      element: changedPalaceElement,
    ),
    palaceSequence: _legacyPalaceSequence(json),
    hexagramKind: json['hexagram_kind'] as String? ?? 'unrecorded',
    shiPosition: (json['shi_position'] as num?)?.toInt() ?? 0,
    yingPosition: (json['ying_position'] as num?)?.toInt() ?? 0,
    relativeBasis: 'base_palace:$basePalaceName',
    relativeBasisElement: basePalaceElement,
    lines: rawLines
        .map((item) {
          final line = item as Map<String, dynamic>;
          final position = (line['position'] as num).toInt();
          return ChangedChartLine(
            id: line['id'] as String? ?? 'changed-line-$position',
            position: position,
            positionName:
                line['position_name'] as String? ?? _positionName(position),
            yinYang: line['yin_yang'] as String,
            changedFromBase: movingPositions.contains(position),
            relation: line['relation'] as String? ?? '未记录',
            najia: _legacyNajia(line),
            role: line['role'] as String?,
          );
        })
        .toList(growable: false),
  );
}

NajiaFields _legacyNajia(Map<String, dynamic> json) {
  final ganZhi =
      json['gan_zhi'] as String? ?? json['branch'] as String? ?? '未记录';
  return NajiaFields(
    heavenlyStem: json['heavenly_stem'] as String? ?? _characterAt(ganZhi, 0),
    earthlyBranch: json['earthly_branch'] as String? ?? _characterAt(ganZhi, 1),
    ganZhi: ganZhi,
    element: json['element'] as String? ?? '未记录',
  );
}

String _characterAt(String value, int index) {
  final characters = value.runes.toList(growable: false);
  if (characters.length <= index) return '？';
  return String.fromCharCode(characters[index]);
}

int _rolePosition(List<BaseChartLine> lines, String role) {
  for (final line in lines) {
    if (line.role == role) return line.position;
  }
  return 0;
}

String _positionName(int position) => switch (position) {
  1 => '初爻',
  2 => '二爻',
  3 => '三爻',
  4 => '四爻',
  5 => '五爻',
  6 => '上爻',
  _ => '第$position爻',
};

String _traditionalName(int value) => switch (value) {
  6 => '老阴',
  7 => '少阳',
  8 => '少阴',
  9 => '老阳',
  _ => '旧档案记录',
};
