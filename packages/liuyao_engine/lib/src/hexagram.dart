/// 64卦纳甲结构与卦面计算
/// 完整移植自 Python najia 2.0.1 + liuyao-engine base_chart.py
/// 实现六十四卦查表、纳甲天干地支、六亲、世应、伏神等核心功能

library;

import 'almanac.dart' show getNayin;
import 'constants.dart';

/// ============================================================================
/// 64卦定义（从 najia.const.GUA64 移植）
/// ============================================================================

/// 64卦：六爻编码（bottom->top） -> 卦名
/// 编码规则：初爻=第0位，上爻=第5位，'1'=阳，'0'=阴
const Map<String, String> gua64 = {
  '111111': '乾为天',
  '011111': '天风姤',
  '001111': '天山遁',
  '000111': '天地否',
  '000011': '风地观',
  '000001': '山地剥',
  '000101': '火地晋',
  '111101': '火天大有',
  '110110': '兑为泽',
  '010110': '泽水困',
  '000110': '泽地萃',
  '001110': '泽山咸',
  '001010': '水山蹇',
  '001000': '地山谦',
  '001100': '雷山小过',
  '110100': '雷泽归妹',
  '101101': '离为火',
  '001101': '火山旅',
  '011101': '火风鼎',
  '010101': '火水未济',
  '010001': '山水蒙',
  '010011': '风水涣',
  '010111': '天水讼',
  '101111': '天火同人',
  '100100': '震为雷',
  '000100': '雷地豫',
  '010100': '雷水解',
  '011100': '雷风恒',
  '011000': '地风升',
  '011010': '水风井',
  '011110': '泽风大过',
  '100110': '泽雷随',
  '011011': '巽为风',
  '111011': '风天小畜',
  '101011': '风火家人',
  '100011': '风雷益',
  '100111': '天雷无妄',
  '100101': '火雷噬嗑',
  '100001': '山雷颐',
  '011001': '山风蛊',
  '010010': '坎为水',
  '110010': '水泽节',
  '100010': '水雷屯',
  '101010': '水火既济',
  '101110': '泽火革',
  '101100': '雷火丰',
  '101000': '地火明夷',
  '010000': '地水师',
  '001001': '艮为山',
  '101001': '山火贲',
  '111001': '山天大畜',
  '110001': '山泽损',
  '110101': '火泽睽',
  '110111': '天泽履',
  '110011': '风泽中孚',
  '001011': '风山渐',
  '000000': '坤为地',
  '100000': '地雷复',
  '110000': '地泽临',
  '111000': '地天泰',
  '111100': '雷天大壮',
  '111110': '泽天夬',
  '111010': '水天需',
  '000010': '水地比',
};

/// ============================================================================
/// 世应定位算法（_shi_ying）
/// ============================================================================

/// 计算世应位置
/// 返回: (世爻位置1-6, 应爻位置1-6, 宫序1-8, 类型)
/// 类型: 'pure'/'wandering_soul'/'returning_soul'/'regular'
({int shi, int ying, int palaceSequence, String kind}) calculateShiYing(
  String code,
) {
  assert(code.length == 6, '卦码必须是6位');

  final outer = code.substring(3, 6); // 上卦
  final inner = code.substring(0, 3); // 下卦

  ({int shi, int ying, int palaceSequence, String kind}) result(
    int shi, [
    String kind = 'regular',
  ]) {
    final ying = shi > 3 ? shi - 3 : shi + 3;
    final palaceSequence =
        {'pure': 1, 'wandering_soul': 7, 'returning_soul': 8}[kind] ??
        (shi + 1);
    return (shi: shi, ying: ying, palaceSequence: palaceSequence, kind: kind);
  }

  // 天同二世，天变五。
  if (outer[2] == inner[2] && outer[1] != inner[1] && outer[0] != inner[0]) {
    return result(2);
  }
  if (outer[1] == inner[1] && outer[0] == inner[0] && outer[2] != inner[2]) {
    return result(5);
  }

  // 人同游魂，人变归。
  if (outer[1] == inner[1] && outer[0] != inner[0] && outer[2] != inner[2]) {
    return result(4, 'wandering_soul');
  }
  if (outer[0] == inner[0] && outer[2] == inner[2] && outer[1] != inner[1]) {
    return result(3, 'returning_soul');
  }

  // 地同四世，地变初。
  if (outer[0] == inner[0] && outer[1] != inner[1] && outer[2] != inner[2]) {
    return result(4);
  }
  if (outer[1] == inner[1] && outer[2] == inner[2] && outer[0] != inner[0]) {
    return result(1);
  }

  // 本宫六世，三世异。
  if (outer == inner) {
    return result(6, 'pure');
  }
  return result(3);
}

/// ============================================================================
/// 宫位计算（_palace）
/// ============================================================================

/// 计算本宫信息
Map<String, String> calculatePalace(String code, int shi, String kind) {
  assert(code.length == 6);

  final outer = code.substring(3, 6);
  final inner = code.substring(0, 3);

  String palaceCode;
  if (kind == 'returning_soul') {
    palaceCode = inner;
  } else if ([1, 2, 3, 6].contains(shi)) {
    palaceCode = outer;
  } else {
    palaceCode = _invertTrigram(inner);
  }

  final trigram = trigrams[palaceCode]!;
  return {
    'code': palaceCode,
    'name': trigram['name'] as String,
    'element': trigram['element'] as String,
  };
}

/// 三爻取反
String _invertTrigram(String code) {
  return code.split('').map((c) => c == '1' ? '0' : '1').join();
}

/// ============================================================================
/// 纳甲天干地支（_najia）
/// ============================================================================

/// 为六爻生成纳甲信息
/// 返回 6 条线的信息：天干、地支、五行、干支
List<Map<String, String>> buildNajiaLines(String code) {
  assert(code.length == 6);

  final lowerCode = code.substring(0, 3); // 下卦
  final upperCode = code.substring(3, 6); // 上卦

  final lower = trigrams[lowerCode]!;
  final upper = trigrams[upperCode]!;

  final (lowerStem, lowerBranches) = lower['inner'] as (String, String);
  final (upperStem, upperBranches) = upper['outer'] as (String, String);

  // 下卦三爻 + 上卦三爻
  final values = [
    for (final b in lowerBranches.split('')) (lowerStem, b),
    for (final b in upperBranches.split('')) (upperStem, b),
  ];

  return values.map((v) {
    final stem = v.$1;
    final branch = v.$2;
    return {
      'heavenly_stem': stem,
      'earthly_branch': branch,
      'branch': branch,
      'gan_zhi': '$stem$branch',
      'element': branchElements[branch]!,
    };
  }).toList();
}

/// ============================================================================
/// 六亲计算（_relation）
/// ============================================================================

/// 计算六亲关系
/// palaceElement: 宫位五行
/// lineElement: 爻位五行
String calculateRelation(String palaceElement, String lineElement) {
  if (palaceElement == lineElement) return '兄弟';
  if (generates[palaceElement] == lineElement) return '子孙';
  if (generates[lineElement] == palaceElement) return '父母';
  if (controls[palaceElement] == lineElement) return '妻财';
  if (controls[lineElement] == palaceElement) return '官鬼';
  throw ArgumentError('无法确定六亲: palace=$palaceElement, line=$lineElement');
}

/// ============================================================================
/// 六神计算
/// ============================================================================

/// 根据日干起六神
List<String> calculateSixGods(String dayStem) {
  final startGod = sixGodStart[dayStem];
  if (startGod == null) {
    throw ArgumentError('未知日干: $dayStem');
  }

  final startIndex = sixGods.indexOf(startGod);
  return List.generate(6, (i) => sixGods[(startIndex + i) % 6]);
}

/// ============================================================================
/// 变卦计算
/// ============================================================================

/// 生成变卦编码（动爻变，静爻不变）
String buildChangedCode(String originalCode, List<bool> changing) {
  assert(originalCode.length == 6);
  assert(changing.length == 6);

  final chars = originalCode.split('');
  for (int i = 0; i < 6; i++) {
    if (changing[i]) {
      chars[i] = chars[i] == '1' ? '0' : '1';
    }
  }
  return chars.join();
}

/// ============================================================================
/// 伏卦与伏神计算
/// ============================================================================

Map<String, dynamic> _buildHiddenHexagram(
  String baseCode,
  Map<String, String> palace,
) {
  final palaceCode = palace['code']!;
  final oppositeCode = oppositeTrigrams[palaceCode]!;
  final innerCode = baseCode.substring(0, 3);
  final outerCode = baseCode.substring(3, 6);
  final hiddenInnerCode = innerCode == palaceCode ? oppositeCode : palaceCode;
  final hiddenOuterCode = outerCode == palaceCode ? oppositeCode : palaceCode;
  final hiddenCode = '$hiddenInnerCode$hiddenOuterCode';

  Map<String, String> summary(String code) {
    final trigram = trigrams[code]!;
    return {
      'code': code,
      'name': trigram['name'] as String,
      'element': trigram['element'] as String,
    };
  }

  Map<String, dynamic> selectionRule(
    String scope,
    String originalCode,
    String selectedCode,
  ) {
    final matched = originalCode == palaceCode;
    return {
      'scope': scope,
      'original_trigram': summary(originalCode),
      'matches_palace_trigram': matched,
      'selected_trigram': summary(selectedCode),
      'selection': matched ? 'palace_opposite' : 'palace_trigram',
    };
  }

  return {
    'id': 'hidden',
    'code': hiddenCode,
    'name': gua64[hiddenCode]!,
    'lower_trigram': summary(hiddenInnerCode),
    'upper_trigram': summary(hiddenOuterCode),
    'palace_basis': Map<String, String>.from(palace),
    'palace_opposite': summary(oppositeCode),
    'inner_rule': selectionRule('inner', innerCode, hiddenInnerCode),
    'outer_rule': selectionRule('outer', outerCode, hiddenOuterCode),
  };
}

/// ============================================================================
/// 基础卦面构建入口
/// ============================================================================

/// 构建完整基础卦面（schema v12）
/// 输出结构严格匹配 LiuyaoChart.fromJson / BaseHexagram.fromJson
Map<String, dynamic> buildBaseChart(
  List<int> rawLines, // 6个爻值 [初爻, ..., 上爻]
  Map<String, Map<String, String>> projectPillars, // 四柱
) {
  assert(rawLines.length == 6);

  // 1. 阴阳编码（7/9=阳=1, 6/8=阴=0）
  final code = rawLines.map((v) => (v == 7 || v == 9) ? '1' : '0').join();
  final guaName = gua64[code] ?? '未知卦';

  // 2. 上下卦摘要
  final lowerCode = code.substring(0, 3);
  final upperCode = code.substring(3, 6);

  Map<String, String> triSummary(String c) {
    final t = trigrams[c]!;
    return {
      'code': c,
      'name': t['name'] as String,
      'element': t['element'] as String,
    };
  }

  // 3. 世应定位 + 宫位
  final shiYing = calculateShiYing(code);
  final palace = calculatePalace(code, shiYing.shi, shiYing.kind);

  // 4. 纳甲六爻 + 六亲
  final najiaLines = buildNajiaLines(code);
  final relations = najiaLines
      .map((line) => calculateRelation(palace['element']!, line['element']!))
      .toList();

  // 5. 六神（日干起）
  final dayStem = projectPillars['day']?['stem'] ?? '甲';
  final sixGodsList = calculateSixGods(dayStem);

  // 6. 动爻
  final changing = List<bool>.generate(
    6,
    (i) => rawLines[i] == 6 || rawLines[i] == 9,
    growable: false,
  );
  final movingPositions = <int>[
    for (int i = 0; i < 6; i++)
      if (changing[i]) i + 1,
  ];

  // 7. 本卦六爻（含 role 世应、完整 najia 平铺字段）
  final baseLines = List<Map<String, dynamic>>.generate(6, (i) {
    final String? role = (i + 1 == shiYing.shi)
        ? '世'
        : (i + 1 == shiYing.ying)
        ? '应'
        : null;
    return <String, dynamic>{
      'id': 'base-${i + 1}',
      'position': i + 1,
      'position_name': linePositionNames[i],
      'value': rawLines[i],
      'yin_yang': (rawLines[i] == 7 || rawLines[i] == 9) ? 'yang' : 'yin',
      'changing': changing[i],
      'six_god': sixGodsList[i],
      'relation': relations[i],
      'heavenly_stem': najiaLines[i]['heavenly_stem'],
      'earthly_branch': najiaLines[i]['earthly_branch'],
      'branch': najiaLines[i]['branch'],
      'gan_zhi': najiaLines[i]['gan_zhi'],
      'nayin': getNayin(najiaLines[i]['gan_zhi']!),
      'element': najiaLines[i]['element'],
      'role': role,
      'hidden': null,
    };
  });

  // 8. 变卦（有动爻时）
  Map<String, dynamic>? changedJson;
  if (movingPositions.isNotEmpty) {
    final changedCode = buildChangedCode(code, changing);
    final changedGuaName = gua64[changedCode] ?? '未知卦';
    final cLower = changedCode.substring(0, 3);
    final cUpper = changedCode.substring(3, 6);
    final cShiYing = calculateShiYing(changedCode);
    final cPalace = calculatePalace(changedCode, cShiYing.shi, cShiYing.kind);
    final cNajia = buildNajiaLines(changedCode);
    final changedLines = List<Map<String, dynamic>>.generate(6, (i) {
      final String? changedRole = (i + 1 == cShiYing.shi)
          ? '世'
          : (i + 1 == cShiYing.ying)
          ? '应'
          : null;
      return <String, dynamic>{
        'id': 'changed-${i + 1}',
        'position': i + 1,
        'position_name': linePositionNames[i],
        'yin_yang': changedCode[i] == '1' ? 'yang' : 'yin',
        'changed_from_base': changing[i],
        // 变卦六亲仍以本卦宫五行为基准，而不是变卦所属宫。
        'relation': calculateRelation(
          palace['element']!,
          cNajia[i]['element']!,
        ),
        'heavenly_stem': cNajia[i]['heavenly_stem'],
        'earthly_branch': cNajia[i]['earthly_branch'],
        'branch': cNajia[i]['branch'],
        'gan_zhi': cNajia[i]['gan_zhi'],
        'nayin': getNayin(cNajia[i]['gan_zhi']!),
        'element': cNajia[i]['element'],
        'role': changedRole,
      };
    });
    changedJson = {
      'id': 'changed',
      'code': changedCode,
      'name': changedGuaName,
      'lower_trigram': triSummary(cLower),
      'upper_trigram': triSummary(cUpper),
      'palace': {
        'code': cPalace['code'],
        'name': cPalace['name'],
        'element': cPalace['element'],
      },
      'palace_name': cPalace['name'],
      'palace_element': cPalace['element'],
      'palace_sequence': cShiYing.palaceSequence,
      'hexagram_kind': cShiYing.kind,
      'shi_position': cShiYing.shi,
      'ying_position': cShiYing.ying,
      'relative_basis': 'base_palace',
      'relative_basis_element': palace['element'],
      'lines': changedLines,
    };
  }

  // 9. 按用户确认的内外卦匹配规则生成伏卦，并把六爻伏神逐位挂回本卦。
  final hiddenHexagram = _buildHiddenHexagram(code, palace);
  final hiddenCode = hiddenHexagram['code'] as String;
  final hiddenNajia = buildNajiaLines(hiddenCode);
  final presentRelations = relations.toSet();
  for (var i = 0; i < 6; i++) {
    final relation = calculateRelation(
      palace['element']!,
      hiddenNajia[i]['element']!,
    );
    baseLines[i]['hidden'] = {
      'id': 'hidden-${i + 1}-$relation',
      'position': i + 1,
      'position_name': linePositionNames[i],
      'relation': relation,
      'heavenly_stem': hiddenNajia[i]['heavenly_stem'],
      'earthly_branch': hiddenNajia[i]['earthly_branch'],
      'branch': hiddenNajia[i]['branch'],
      'gan_zhi': hiddenNajia[i]['gan_zhi'],
      'nayin': getNayin(hiddenNajia[i]['gan_zhi']!),
      'element': hiddenNajia[i]['element'],
      'source_hexagram': {'code': hiddenCode, 'name': hiddenHexagram['name']},
      'source_trigram': i < 3 ? 'inner' : 'outer',
      'flying_line_id': 'base-${i + 1}',
      'relation_missing_from_base': !presentRelations.contains(relation),
      'note': '伏神',
    };
  }

  // 10. 组装 schema v12 hexagram 结构
  return {
    'line_order': 'bottom_to_top',
    'display_order': 'top_to_bottom',
    'moving_positions': movingPositions,
    'base': {
      'id': 'base',
      'code': code,
      'name': guaName,
      'lower_trigram': triSummary(lowerCode),
      'upper_trigram': triSummary(upperCode),
      'palace': {
        'code': palace['code'],
        'name': palace['name'],
        'element': palace['element'],
      },
      'palace_name': palace['name'],
      'palace_element': palace['element'],
      'palace_sequence': shiYing.palaceSequence,
      'hexagram_kind': shiYing.kind,
      'shi_position': shiYing.shi,
      'ying_position': shiYing.ying,
      'moving_positions': movingPositions,
      'hidden_hexagram': hiddenHexagram,
      'lines': baseLines,
    },
    'changed': changedJson,
  };
}

/// 生成与既有 Python 合同同序的基础卦计算轨迹。
List<Map<String, dynamic>> buildBaseChartTraces(
  Map<String, dynamic> chart,
  List<int> lineValues,
  Map<String, Map<String, String>> pillars,
) {
  final base = chart['base'] as Map<String, dynamic>;
  final changed = chart['changed'] as Map<String, dynamic>?;
  final lines = (base['lines'] as List).cast<Map<String, dynamic>>();
  final hidden = base['hidden_hexagram'] as Map<String, dynamic>;
  final hiddenLines = lines
      .map((line) => line['hidden'] as Map<String, dynamic>)
      .toList(growable: false);
  final palace = base['palace'] as Map<String, dynamic>;
  final moving = (base['moving_positions'] as List).cast<int>();

  Map<String, dynamic> trace(
    String ruleId,
    String label,
    dynamic inputs,
    List<String> steps,
    dynamic result, {
    List<String> sourceIds = const ['SRC-009'],
  }) => {
    'rule_id': ruleId,
    'label': label,
    'scope': 'base_chart',
    'inputs': inputs,
    'steps': steps,
    'result': result,
    'rule_version': '1.3.0',
    'source_ids': sourceIds,
  };

  final result = <Map<String, dynamic>>[
    trace(
      'chart.hexagram.identify.v1',
      '本卦与变卦识别',
      {'line_values': lineValues, 'line_order': 'bottom_to_top'},
      [
        '6/8 记阴(0)，7/9 记阳(1)，得到本卦码 ${base['code']}',
        changed == null
            ? '没有 6/9 动爻，本次为静卦，不生成变卦'
            : '动爻位 $moving 逐位反转，得到变卦码 ${changed['code']}',
        '查 64 卦表：${base['name']}${changed == null ? '' : ' → ${changed['name']}'}',
      ],
      {'base': base['name'], 'changed': changed?['name']},
    ),
    trace(
      'chart.trigrams.split.v1',
      '上下卦拆分',
      {'base_code': base['code']},
      [
        '前三位 ${(base['code'] as String).substring(0, 3)} 为下卦：${(base['lower_trigram'] as Map)['name']}(${(base['lower_trigram'] as Map)['element']})',
        '后三位 ${(base['code'] as String).substring(3)} 为上卦：${(base['upper_trigram'] as Map)['name']}(${(base['upper_trigram'] as Map)['element']})',
      ],
      {'lower': base['lower_trigram'], 'upper': base['upper_trigram']},
    ),
    trace(
      'chart.palace.shi_ying.v1',
      '卦宫与世应',
      {'base_code': base['code']},
      [
        '按寻世诀判定：世在${linePositionNames[(base['shi_position'] as int) - 1]}，应在${linePositionNames[(base['ying_position'] as int) - 1]}',
        '按认宫诀判定：${palace['name']}宫，宫五行${palace['element']}',
        '卦型标识：${base['hexagram_kind']}；八宫序位：${base['palace_sequence']}',
        if (changed != null)
          '变卦独立按寻世诀判定：世在${linePositionNames[(changed['shi_position'] as int) - 1]}，应在${linePositionNames[(changed['ying_position'] as int) - 1]}；${changed['palace_name']}宫·${changed['palace_sequence']}',
      ],
      {
        'palace': palace,
        'shi_position': base['shi_position'],
        'ying_position': base['ying_position'],
        'kind': base['hexagram_kind'],
        if (changed != null)
          'changed': {
            'palace': changed['palace'],
            'shi_position': changed['shi_position'],
            'ying_position': changed['ying_position'],
            'kind': changed['hexagram_kind'],
          },
      },
    ),
    trace(
      'chart.najia.table.v1',
      '纳甲',
      {
        'lower_trigram': (base['code'] as String).substring(0, 3),
        'upper_trigram': (base['code'] as String).substring(3),
      },
      [
        for (final line in lines)
          '${line['position_name']}：查纳甲表得 ${line['gan_zhi']}，${line['earthly_branch']}属${line['element']}',
      ],
      [
        for (final line in lines)
          {
            'position': line['position'],
            'gan_zhi': line['gan_zhi'],
            'element': line['element'],
          },
      ],
    ),
    trace(
      'chart.six_relatives.five_elements.v1',
      '六亲',
      {'base_palace_element': palace['element']},
      [
        for (final line in lines)
          '${line['position_name']}：宫${palace['element']} 对 爻${line['element']} → ${line['relation']}',
      ],
      [for (final line in lines) line['relation']],
    ),
    trace(
      'chart.six_gods.day_stem.v1',
      '六神',
      {
        'day_gan_zhi': pillars['day']!['gan_zhi'],
        'day_stem': pillars['day']!['stem'],
      },
      [
        '${pillars['day']!['stem']}日起${lines.first['six_god']}，按固定次序从初爻排至上爻',
        for (final line in lines) '${line['position_name']}：${line['six_god']}',
      ],
      [for (final line in lines) line['six_god']],
      sourceIds: const ['SRC-008', 'SRC-009'],
    ),
    trace(
      'chart.hidden_hexagram.trigram_match.v3',
      '伏卦与伏神',
      {
        'display_mode': 'full_hidden_hexagram_six_lines',
        'base_code': base['code'],
        'present_relations':
            lines.map((line) => line['relation']).toSet().toList()..sort(),
        'palace': palace,
        'palace_opposite': hidden['palace_opposite'],
      },
      [
        '内卦按与宫卦是否相同选择宫卦或宫卦错卦，伏内卦取${(hidden['lower_trigram'] as Map)['name']}',
        '外卦按与宫卦是否相同选择宫卦或宫卦错卦，伏外卦取${(hidden['upper_trigram'] as Map)['name']}',
        '伏内卦与伏外卦合成 ${hidden['name']}（${hidden['code']}）',
        for (final item in hiddenLines)
          '查${(item['source_hexagram'] as Map)['name']}${item['position_name']}：${item['relation']}${item['gan_zhi']}${item['element']}，逐爻伏于 ${item['flying_line_id']}',
      ],
      {'hidden_hexagram': hidden, 'lines': hiddenLines},
      sourceIds: const ['SRC-009', 'SRC-019'],
    ),
  ];

  if (changed != null) {
    final changedLines = (changed['lines'] as List)
        .cast<Map<String, dynamic>>();
    result.add(
      trace(
        'chart.changed.relatives.v1',
        '变卦纳甲与六亲',
        {
          'changed_code': changed['code'],
          'relative_basis': 'base_palace',
          'base_palace': palace,
        },
        [
          for (final line in changedLines)
            '${line['position_name']}：${line['gan_zhi']}${line['element']}；仍以本卦${palace['name']}宫${palace['element']}定为${line['relation']}',
        ],
        {
          'name': changed['name'],
          'relative_basis': changed['relative_basis'],
          'lines': changedLines,
        },
      ),
    );
  }
  return result;
}
