/// 六爻完整排盘引擎
/// 100% 离线实现，对标 Python engine.py cast_chart()
/// 输出当前版本的完整结构。

library;

import 'dart:math' as math;
import 'constants.dart';
import 'almanac.dart';
import 'shanghai_time.dart';
import 'hexagram.dart';
import 'private_reference.dart';
import 'rules.dart';
import 'twenty_eight_mansions.dart';
import 'five_stars.dart';

/// ============================================================================
/// 起卦记录结构
/// ============================================================================

/// 三枚铜钱起卦
({
  List<int> lines,
  List<List<int>> coinLines,
  Map<String, dynamic> randomSource,
})
_generateThreeCoinCast({int? seed}) {
  final rng = seed != null ? math.Random(seed) : math.Random.secure();

  final lines = <int>[];
  final coinLines = <List<int>>[];

  for (int i = 0; i < 6; i++) {
    // 每枚铜钱：正面=3，反面=2
    final coins = List.generate(3, (_) => rng.nextInt(2) == 1 ? 3 : 2);
    coinLines.add(coins);
    lines.add(coins.fold(0, (a, b) => a + b)); // 6,7,8,9
  }

  final randomSource = <String, dynamic>{
    'kind': seed != null ? 'seeded_test' : 'system',
    'generator': seed != null ? 'dart.Random(seed)' : 'dart.Random.secure()',
  };
  if (seed != null) randomSource['seed'] = seed;
  return (lines: lines, coinLines: coinLines, randomSource: randomSource);
}

/// 手动输入起卦记录
Map<String, dynamic> _castingRecordManual(List<int> lines) {
  return {
    'method': 'manual',
    'method_version': 'manual.yin_yang_moving.v1',
    'line_order': 'bottom_to_top',
    'line_values': lines,
    'lines': List.generate(6, (i) {
      final value = lines[i];
      final yinYang = (value == 7 || value == 9) ? 'yang' : 'yin';
      final changing = (value == 6 || value == 9);
      final traditionalName = {6: '老阴', 7: '少阳', 8: '少阴', 9: '老阳'}[value]!;

      return {
        'position': i + 1,
        'position_name': linePositionNames[i],
        'source': 'manual_input',
        'coins': <int>[],
        'total': value,
        'value': value,
        'yin_yang': yinYang,
        'changing': changing,
        'traditional_name': traditionalName,
      };
    }),
    'random_source': null,
  };
}

/// 时刻起卦法的爻值（6/7/8/9）与原始输入。
///
/// 时刻起卦法 2.0（用户 2026-09-01 确认，替代 1.0）：
/// 1.0 的缺陷：内卦取时支后天八卦，而人类活动时间集中在 7-23 点，
/// 导致内卦为巽/坤/乾的概率过大。2.0 改为：
/// 1. 念头起时锁定时刻干支：时柱依万年历（日上起子时五鼠遁）；
///    刻柱按时上起刻法推算——一时辰 120 分钟十二均分，每刻十分钟，
///    刻干从时干起子刻，依六十甲子顺推到刻支。
/// 2. 本卦：刻柱天干按六爻纳甲翻卦为内卦（下卦）——
///    甲壬乾、乙癸坤、丙艮、丁兑、戊坎、己离、庚震、辛巽；
///    刻柱地支按后天方位翻卦为外卦（上卦）——
///    子坎、丑寅艮、卯震、辰巳巽、午离、未申坤、酉兑、戌亥乾。
/// 3. 动爻：日柱天干序数 + 时柱天干序数 之和 mod 6，余 0 则上爻（天爻）动。
/// 动爻处取老变（阳动 9 / 阴动 6），其余取少阳 7 / 少阴 8。
({List<int> lines, Map<String, dynamic> rawInput}) _computeTimePillar(
  DateTime timestamp,
  Map<String, dynamic> almanac,
) {
  const branches = '子丑寅卯辰巳午未申酉戌亥';
  // 地支 → 后天八卦（外卦，取刻支）。
  const branchTrigram = {
    '子': '坎',
    '丑': '艮',
    '寅': '艮',
    '卯': '震',
    '辰': '巽',
    '巳': '巽',
    '午': '离',
    '未': '坤',
    '申': '坤',
    '酉': '兑',
    '戌': '乾',
    '亥': '乾',
  };
  // 天干 → 纳甲八卦（内卦，取刻干）。六爻纳甲：
  // 乾纳甲壬、坤纳乙癸、艮纳丙、兑纳丁、坎纳戊、离纳己、震纳庚、巽纳辛。
  const stemTrigram = {
    '甲': '乾',
    '乙': '坤',
    '丙': '艮',
    '丁': '兑',
    '戊': '坎',
    '己': '离',
    '庚': '震',
    '辛': '巽',
    '壬': '乾',
    '癸': '坤',
  };
  // 后天八卦 → 卦象位（1 阳 0 阴，自下而上）。
  const trigramBits = {
    '乾': [1, 1, 1],
    '兑': [1, 1, 0],
    '离': [1, 0, 1],
    '震': [1, 0, 0],
    '巽': [0, 1, 1],
    '坎': [0, 1, 0],
    '艮': [0, 0, 1],
    '坤': [0, 0, 0],
  };
  // 各时辰起始小时（24 小时制）：子 23、丑 1、寅 3 … 亥 21。
  const shichenStartHour = [23, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21];
  // 天干序数（附件表 2）。
  const stemOrdinals = {
    '甲': 1,
    '乙': 2,
    '丙': 3,
    '丁': 4,
    '戊': 5,
    '己': 6,
    '庚': 7,
    '辛': 8,
    '壬': 9,
    '癸': 10,
  };

  final wall = toShanghaiWallClock(timestamp);
  final pillars = almanac['four_pillars'] as List;
  final dayPillar = pillars[2]['ganzhi'] as String; // 日柱
  final hourPillar = pillars[3]['ganzhi'] as String; // 时柱

  // 1. 时柱解析。
  final hourBranch = hourPillar[1];
  final hourBranchIndex = branches.indexOf(hourBranch);
  final hourCycleIndex = the60HeavenlyEarth.indexOf(hourPillar);

  // 2. 刻支：时辰内分钟偏移 // 10（每刻十分钟）。
  final startMinuteOfDay = shichenStartHour[hourBranchIndex] * 60;
  final currentMinuteOfDay = wall.hour * 60 + wall.minute;
  final offsetMinutes = (currentMinuteOfDay - startMinuteOfDay + 1440) % 120;
  final keBranchIndex = offsetMinutes ~/ 10;
  final keBranch = branches[keBranchIndex];

  // 3. 刻干：时上起子刻（五鼠遁），依六十甲子顺推到刻支。
  final keCycleIndex = (hourCycleIndex * 12 + keBranchIndex) % 60;
  final kePillar = the60HeavenlyEarth[keCycleIndex];
  final keStem = kePillar[0];

  // 4. 本卦（2.0）：刻干纳甲翻卦为内卦（下），刻支后天方位翻卦为外卦（上）。
  final innerTrigram = stemTrigram[keStem]!;
  final outerTrigram = branchTrigram[keBranch]!;
  final bits = [...trigramBits[innerTrigram]!, ...trigramBits[outerTrigram]!];
  final hexagramName = gua64[bits.join('')] ?? '未知卦';

  // 5. 动爻（2.0）：日干序 + 时干序 之和 mod 6，余 0 取上爻（天爻）。
  final dayStemOrdinal = stemOrdinals[dayPillar[0]]!;
  final hourStemOrdinal = stemOrdinals[hourPillar[0]]!;
  final keStemOrdinal = stemOrdinals[keStem]!;
  final movingSum = dayStemOrdinal + hourStemOrdinal;
  final moving = movingSum % 6;
  final movingPosition = moving == 0 ? 6 : moving;

  final lines = List.generate(6, (index) {
    final isYang = bits[index] == 1;
    if (index + 1 == movingPosition) return isYang ? 9 : 6;
    return isYang ? 7 : 8;
  });
  final rawInput = <String, dynamic>{
    'day_pillar': dayPillar,
    'day_stem_ordinal': dayStemOrdinal,
    'hour_pillar': hourPillar,
    'hour_branch': hourBranch,
    'hour_stem_ordinal': hourStemOrdinal,
    'ke_pillar': kePillar,
    'ke_stem': keStem,
    'ke_stem_ordinal': keStemOrdinal,
    'ke_branch': keBranch,
    'ke_branch_index': keBranchIndex,
    'minute_offset_in_shichen': offsetMinutes,
    'inner_trigram': innerTrigram, // 内卦（下卦，2.0 取刻干纳甲）
    'inner_trigram_source': 'ke_stem_najia',
    'outer_trigram': outerTrigram, // 外卦（上卦，取刻支后天方位）
    'outer_trigram_source': 'ke_branch_houtian',
    'moving_sum': movingSum,
    'moving': moving,
    'moving_position': movingPosition,
    'moving_position_name': linePositionNames[movingPosition - 1],
    'hexagram_name': hexagramName,
    'bits': bits.join(''),
  };
  return (lines: lines, rawInput: rawInput);
}

/// 时刻起卦法记录
Map<String, dynamic> _castingRecordTimePillar(
  List<int> lines,
  Map<String, dynamic> rawInput,
) {
  return {
    'method': 'time_pillar',
    'method_version': 'time_pillar.ke_gan_najia.v2',
    'line_order': 'bottom_to_top',
    'line_values': lines,
    'raw_input': rawInput,
    'lines': List.generate(6, (index) {
      final value = lines[index];
      final yinYang = (value == 7 || value == 9) ? 'yang' : 'yin';
      final changing = (value == 6 || value == 9);
      final traditionalName = {6: '老阴', 7: '少阳', 8: '少阴', 9: '老阳'}[value]!;

      return {
        'position': index + 1,
        'position_name': linePositionNames[index],
        'source': 'time_pillar',
        'coins': <int>[],
        'total': value,
        'value': value,
        'yin_yang': yinYang,
        'changing': changing,
        'traditional_name': traditionalName,
      };
    }),
    'random_source': null,
  };
}

/// 三枚铜钱起卦记录
Map<String, dynamic> _castingRecordThreeCoins(
  List<int> lines,
  List<List<int>> coinLines,
  Map<String, dynamic> randomSource,
) {
  return {
    'method': 'three_coins',
    'method_version': 'three_coins.sum_2_3.v1',
    'line_order': 'bottom_to_top',
    'line_values': lines,
    'lines': List.generate(6, (i) {
      final value = lines[i];
      final coins = coinLines[i];
      final yinYang = (value == 7 || value == 9) ? 'yang' : 'yin';
      final changing = (value == 6 || value == 9);
      final traditionalName = {6: '老阴', 7: '少阳', 8: '少阴', 9: '老阳'}[value]!;

      return {
        'position': i + 1,
        'position_name': linePositionNames[i],
        'source': 'three_coins',
        'coins': coins,
        'total': coins.fold(0, (a, b) => a + b),
        'value': value,
        'yin_yang': yinYang,
        'changing': changing,
        'traditional_name': traditionalName,
      };
    }),
    'random_source': randomSource,
  };
}

/// ============================================================================
/// 起卦轨迹
/// ============================================================================

Map<String, dynamic> _castingTrace(Map<String, dynamic> record) {
  if (record['method'] == 'three_coins') {
    final steps = (record['lines'] as List).map((line) {
      final coins = (line['coins'] as List).join(' + ');
      final total = line['total'];
      final name = line['traditional_name'];
      return '${line['position_name']}：$coins = $total → $name';
    }).toList();

    return {
      'rule_id': 'casting.three_coins.sum_2_3.v1',
      'label': '起卦原始过程',
      'scope': 'casting',
      'inputs': (record['lines'] as List).map((l) => l['coins']).toList(),
      'steps': steps,
      'result': record['line_values'],
      'rule_version': '1.0.0',
    };
  } else if (record['method'] == 'time_pillar') {
    final raw = record['raw_input'] as Map<String, dynamic>;
    final steps = [
      '时刻起卦法2.0：${raw['day_pillar']}日 ${raw['hour_pillar']}时 ${raw['ke_pillar']}刻'
          '（念头起时锁定时刻干支）',
      '内卦取刻干 ${raw['ke_stem']} 纳甲翻卦为 ${raw['inner_trigram']}，'
          '外卦取刻支 ${raw['ke_branch']} 后天方位翻卦为 ${raw['outer_trigram']}',
      '卦象 ${raw['bits']} → 本卦 ${raw['hexagram_name']}',
      '动爻 =（日干序 ${raw['day_stem_ordinal']} + 时干序 ${raw['hour_stem_ordinal']}）'
          'mod 6 = ${raw['moving']}，余 0 取上爻 → '
          '${raw['moving_position_name']}动',
      ...(record['lines'] as List).map((line) {
        return '${line['position_name']}：${line['value']} → ${line['traditional_name']}';
      }),
    ];

    return {
      'rule_id': 'casting.time_pillar.ke_gan_najia.v2',
      'label': '时刻起卦法原始过程',
      'scope': 'casting',
      'inputs': raw,
      'steps': steps,
      'result': record['line_values'],
      'rule_version': '2.0.0',
    };
  } else {
    final steps = (record['lines'] as List).map((line) {
      return '${line['position_name']}：${line['value']} → ${line['traditional_name']}';
    }).toList();

    return {
      'rule_id': 'casting.manual.normalize.v1',
      'label': '起卦原始过程',
      'scope': 'casting',
      'inputs': record['line_values'],
      'steps': steps,
      'result': record['line_values'],
      'rule_version': '1.0.0',
    };
  }
}

/// ============================================================================
/// 核心排盘函数
/// ============================================================================

/// 完整排盘（对标 Python cast_chart）
///
/// 参数:
/// - timestamp: 起卦时间（必须带时区信息）
/// - lineValues: 手动输入的6个爻值（6/7/8/9），null 表示自动摇卦
/// - seed: 随机种子（仅自动摇卦时有效）
/// - castingMethod: 'manual' | 'three_coins' | 'time_pillar'
///
/// 返回: schema v12 完整结构
Map<String, dynamic> castChart({
  required DateTime timestamp,
  List<int>? lineValues,
  int? seed,
  String castingMethod = 'three_coins',
  String dayBoundary = dayBoundaryCivil23NextDay,
  String monthBoundary = monthBoundarySolarTermZiHour,
}) {
  // 1. 验证参数
  if (!['manual', 'three_coins', 'time_pillar'].contains(castingMethod)) {
    throw ArgumentError('castingMethod 必须是 manual、three_coins 或 time_pillar');
  }

  if (castingMethod == 'manual') {
    if (lineValues == null || lineValues.length != 6) {
      throw ArgumentError('manual 模式需要提供 6 个爻值');
    }
    if (seed != null) {
      throw ArgumentError('manual 模式不支持 seed');
    }
    for (final v in lineValues) {
      if (!validLineValues.contains(v)) {
        throw ArgumentError('爻值必须是 6/7/8/9 之一');
      }
    }
  } else {
    if (lineValues != null) {
      throw ArgumentError('three_coins 模式不需要 lineValues');
    }
  }

  // 2. 生成起卦记录
  late final List<int> lines;
  late final Map<String, dynamic> castingRecord;

  // 时刻起卦需要先计算四柱，再按年支、农历月日和时支取数。
  // 这里先在统一历法上下文中计算，避免把时间法误当作随机铜钱法。
  final almanac = calculateAlmanac(
    timestamp,
    timezoneName: 'Asia/Shanghai',
    dayBoundary: dayBoundary,
    monthBoundary: monthBoundary,
  );

  if (castingMethod == 'manual') {
    lines = List.from(lineValues!);
    castingRecord = _castingRecordManual(lines);
  } else if (castingMethod == 'time_pillar') {
    if (lineValues != null || seed != null) {
      throw ArgumentError('time_pillar 模式不接受 lineValues 或 seed');
    }
    final result = _computeTimePillar(timestamp, almanac);
    lines = result.lines;
    castingRecord = _castingRecordTimePillar(lines, result.rawInput);
  } else {
    final result = _generateThreeCoinCast(seed: seed);
    lines = result.lines;
    castingRecord = _castingRecordThreeCoins(
      lines,
      result.coinLines,
      result.randomSource,
    );
  }

  // 3. 万年历（四柱）
  final projectPillars = <String, Map<String, String>>{};
  for (final p in almanac['four_pillars'] as List) {
    projectPillars[p['position']] = {
      'gan_zhi': p['ganzhi'],
      'stem': p['stem'],
      'branch': p['branch'],
    };
  }

  // 4. 旬空
  final dayPillar = projectPillars['day'];
  final dayVoid = dayPillar != null
      ? calculateDayVoid(dayPillar['gan_zhi']!)
      : (voidText: '未记录', voidBranches: <String>[]);

  // 5. 基础卦面
  final hexagram = buildBaseChart(lines, projectPillars);
  final chartTraces = buildBaseChartTraces(hexagram, lines, projectPillars);

  // 6. 五行十二长生
  final twelveStagesResult = buildFiveElementTwelveStages(
    (hexagram['base']['lines'] as List).cast<Map<String, dynamic>>(),
    projectPillars,
  );

  // 伏卦与变卦使用各自的六爻地支计算十二长生，并使用各自的卦宫、世应
  // 计算京房逐爻宿。伏神六爻仍保持本卦宫五行所定的六亲，只把完整伏卦
  // 当作独立卦象确定其卦宫、世应和星宿起点。
  final baseHexagram = hexagram['base'] as Map<String, dynamic>;
  final hiddenIdentity =
      baseHexagram['hidden_hexagram'] as Map<String, dynamic>;
  final hiddenCode = hiddenIdentity['code'] as String;
  final hiddenShiYing = calculateShiYing(hiddenCode);
  final hiddenPalace = calculatePalace(
    hiddenCode,
    hiddenShiYing.shi,
    hiddenShiYing.kind,
  );
  final hiddenLines = (baseHexagram['lines'] as List)
      .cast<Map<String, dynamic>>()
      .map((line) => line['hidden'] as Map<String, dynamic>)
      .toList(growable: false);
  final hiddenLayer = <String, dynamic>{
    'code': hiddenCode,
    'name': hiddenIdentity['name'],
    'palace_name': hiddenPalace['name'],
    'palace_sequence': hiddenShiYing.palaceSequence,
    'shi_position': hiddenShiYing.shi,
    'ying_position': hiddenShiYing.ying,
    'lines': hiddenLines,
  };
  final changedLayer = hexagram['changed'] as Map<String, dynamic>?;
  final hiddenTwelveStagesResult = buildFiveElementTwelveStages(
    hiddenLines,
    projectPillars,
    layer: 'hidden',
  );
  final changedTwelveStagesResult = changedLayer == null
      ? null
      : buildFiveElementTwelveStages(
          (changedLayer['lines'] as List).cast<Map<String, dynamic>>(),
          projectPillars,
          layer: 'changed',
        );

  // 7. 用户确认的五项神煞与两项身命位置
  final dayPillarForRules =
      projectPillars['day'] ?? {'stem': '甲', 'branch': '子'};
  final luShen = buildLuShen(
    (hexagram['base']['lines'] as List).cast<Map<String, dynamic>>(),
    dayPillarForRules,
  );
  final tianYi = buildTianYi(
    (hexagram['base']['lines'] as List).cast<Map<String, dynamic>>(),
    dayPillarForRules,
  );
  final yiMa = buildYiMa(
    (hexagram['base']['lines'] as List).cast<Map<String, dynamic>>(),
    dayPillarForRules,
  );
  final taoHua = buildTaoHua(
    (hexagram['base']['lines'] as List).cast<Map<String, dynamic>>(),
    dayPillarForRules,
  );
  final huaGai = buildHuaGai(
    (hexagram['base']['lines'] as List).cast<Map<String, dynamic>>(),
    dayPillarForRules,
  );
  final mansion = buildTwentyEightMansions(
    hexagram['base'] as Map<String, dynamic>,
  );
  final hiddenMansion = buildTwentyEightMansions(hiddenLayer, layer: 'hidden');
  final changedMansion = changedLayer == null
      ? null
      : buildTwentyEightMansions(changedLayer, layer: 'changed');
  final fiveStars = buildFiveStars(hexagram['base'] as Map<String, dynamic>);
  final hiddenFiveStars = buildFiveStars(hiddenLayer, layer: 'hidden');
  final changedFiveStars = changedLayer == null
      ? null
      : buildFiveStars(changedLayer, layer: 'changed');
  final privateReference = buildPrivateReferenceContract(
    lines: lines,
    timestamp: timestamp,
    almanac: almanac,
    chart: hexagram,
    pillars: projectPillars,
    dayVoidBranches: dayVoid.voidBranches,
    method: castingMethod,
  );
  final privateBodyMarkers =
      (((privateReference['extensions'] as Map)['shensha']
              as Map)['body_markers']
          as Map<String, dynamic>);
  final bodyMarkers = buildSelectedBodyMarkers(
    privateBodyMarkers,
    (hexagram['base']['lines'] as List).cast<Map<String, dynamic>>(),
  );

  Map<String, dynamic> pillarVoid(String position) {
    final value = calculateDayVoid(projectPillars[position]!['gan_zhi']!);
    return {'void': value.voidBranches.join(), 'branches': value.voidBranches};
  }

  // 8. 时间上下文轨迹
  final timeTrace = {
    'rule_id': 'chart.time_context.cnlunar.v1',
    'label': '排盘时间上下文',
    'scope': 'base_chart',
    'inputs': {
      'timestamp': timestamp.toIso8601String(),
      'timezone': 'Asia/Shanghai',
      'year_boundary': 'lunar_new_year',
    },
    'steps': [
      '将起卦时刻转换为 Asia/Shanghai 本地时间',
      '通过 Dart DateTime 计算四柱干支',
      '分别以年、月、日、时四柱干支计算各柱旬空',
      '日柱 ${projectPillars['day']!['gan_zhi']} 旬空 ${dayVoid.voidText}，并以日干起六神',
    ],
    'result': {
      'pillars': projectPillars,
      'pillar_voids': {
        'year': calculateDayVoid(projectPillars['year']!['gan_zhi']!).voidText,
        'month': calculateDayVoid(
          projectPillars['month']!['gan_zhi']!,
        ).voidText,
        'day': dayVoid.voidText,
        'hour': calculateDayVoid(projectPillars['hour']!['gan_zhi']!).voidText,
      },
      'day_void': dayVoid.voidBranches.join(),
    },
    'rule_version': '1.1.0',
    'source_ids': ['SRC-008'],
  };

  // 9. 组装完整输出（schema v16）
  return {
    'schema_version': schemaVersion,
    'engine_version': engineVersion,
    'calendar_policy': {
      'day_boundary': dayBoundary,
      'month_boundary': monthBoundary,
      'timezone': 'Asia/Shanghai',
    },
    'rule_package': {
      'id': 'liuyao.classic_wenwang.private_reference.v1',
      'version': '1.0.0-draft+dart-port.1',
      'status': 'audited_profile_with_documented_variants',
      'source_ids': [
        'SRC-001',
        'SRC-008',
        'SRC-009',
        'SRC-010',
        'SRC-019',
        'SRC-020',
      ],
      'upstream': {
        'name': 'liuyao-private',
        'installed_version': privateSpecVersion,
        'audited_tag': privateProfileId,
        'audited_commit': privateReferenceRevision,
      },
    },
    'meta': {
      'cast_at': timestamp.toIso8601String(),
      'casting_method': castingMethod,
      'line_order': 'bottom_to_top',
      'line_values': lines,
    },
    'casting_record': castingRecord,
    'time': {
      'timezone': 'Asia/Shanghai',
      'rule_status': 'provisional',
      'source': 'dart_almanac',
      'year': projectPillars['year']!['gan_zhi'],
      'month': projectPillars['month']!['gan_zhi'],
      'day': projectPillars['day']!['gan_zhi'],
      'hour': projectPillars['hour']!['gan_zhi'],
      'pillars': projectPillars,
      'pillar_voids': {
        'year': pillarVoid('year'),
        'month': pillarVoid('month'),
        'day': pillarVoid('day'),
        'hour': pillarVoid('hour'),
      },
      'day_void': dayVoid.voidText,
      'day_void_branches': dayVoid.voidBranches,
    },
    'hexagram': hexagram,
    'private_reference_contract': privateReference,
    'annotations': {
      'rule_packages': [
        annotationRulePackage(),
        yiMaRulePackage(),
        taoHuaRulePackage(),
        luShenRulePackage(),
        huaGaiRulePackage(),
        tianYiRulePackage(),
        bodyMarkersRulePackage(),
        mansionRulePackage(),
        fiveStarsRulePackage(),
      ],
      'five_element_twelve_stages': twelveStagesResult['object'],
      'hexagram_layers': {
        'base': {
          'five_element_twelve_stages': twelveStagesResult['object'],
          'twenty_eight_mansions': mansion.result,
          'five_stars': fiveStars.result,
        },
        'hidden': {
          'five_element_twelve_stages': hiddenTwelveStagesResult['object'],
          'twenty_eight_mansions': hiddenMansion.result,
          'five_stars': hiddenFiveStars.result,
        },
        'changed': changedLayer == null
            ? null
            : {
                'five_element_twelve_stages':
                    changedTwelveStagesResult!['object'],
                'twenty_eight_mansions': changedMansion!.result,
                'five_stars': changedFiveStars!.result,
              },
      },
      'shensha': {
        'catalog_version': '1.0.0',
        'results': [
          yiMa.result,
          taoHua.result,
          luShen.result,
          huaGai.result,
          tianYi.result,
        ],
      },
      'body_markers': bodyMarkers.result,
      'twenty_eight_mansions': mansion.result,
      'five_stars': fiveStars.result,
    },
    'calculation_trace': [
      _castingTrace(castingRecord),
      timeTrace,
      ...chartTraces,
      twelveStagesResult['trace'],
      hiddenTwelveStagesResult['trace'],
      if (changedTwelveStagesResult != null) changedTwelveStagesResult['trace'],
      yiMa.trace,
      taoHua.trace,
      luShen.trace,
      huaGai.trace,
      tianYi.trace,
      bodyMarkers.trace,
      mansion.trace,
      hiddenMansion.trace,
      if (changedMansion != null) changedMansion.trace,
      fiveStars.trace,
      hiddenFiveStars.trace,
      if (changedFiveStars != null) changedFiveStars.trace,
    ],
    'diagnostics': {
      'supported_date_range': {
        'start': supportedDateStart,
        'end': supportedDateEnd,
      },
    },
    'raw_najia': null, // Dart 版无原始 najia 数据
  };
}

/// ============================================================================
/// 便捷方法
/// ============================================================================

/// 自动摇卦（三枚铜钱）
Map<String, dynamic> autoCast(
  DateTime timestamp, {
  int? seed,
  String dayBoundary = dayBoundaryCivil23NextDay,
  String monthBoundary = monthBoundarySolarTermZiHour,
}) {
  return castChart(
    timestamp: timestamp,
    castingMethod: 'three_coins',
    seed: seed,
    dayBoundary: dayBoundary,
    monthBoundary: monthBoundary,
  );
}

Map<String, dynamic> timePillarCast(
  DateTime timestamp, {
  String dayBoundary = dayBoundaryCivil23NextDay,
  String monthBoundary = monthBoundarySolarTermZiHour,
}) {
  return castChart(
    timestamp: timestamp,
    castingMethod: 'time_pillar',
    dayBoundary: dayBoundary,
    monthBoundary: monthBoundary,
  );
}

/// 手动输入卦象
Map<String, dynamic> manualCast(
  DateTime timestamp,
  List<int> lineValues, {
  String dayBoundary = dayBoundaryCivil23NextDay,
  String monthBoundary = monthBoundarySolarTermZiHour,
}) {
  return castChart(
    timestamp: timestamp,
    castingMethod: 'manual',
    lineValues: lineValues,
    dayBoundary: dayBoundary,
    monthBoundary: monthBoundary,
  );
}
