/// 六爻规则注解的纯 Dart 实现。
///
/// 公开对象保持既有 Python `rule_annotations.py` 合同，并附加版本化 v2 字段。当前规则包
/// 只启用已经完成资料核验的五行十二长生、驿马、桃花、禄神、华盖、
/// 天乙贵人，以及独立建模的卦身、命爻；其他神煞不得用占位算法混入存档。

library;

import 'constants.dart';
import 'private_reference.dart'
    show lookupElementGrowth, lookupPrivateBranchGrowth;

const _annotationPackageId = 'liuyao.annotations.wuxing_changsheng.v2';
const _luShenPackageId = 'liuyao.shensha.lushen_day_stem.v1';
const _tianYiPackageId = 'liuyao.shensha.tianyi_day_stem.v1';
const _yiMaPackageId = 'liuyao.shensha.yima_day_branch.v1';
const _taoHuaPackageId = 'liuyao.shensha.taohua_day_branch.v1';
const _jiangXingPackageId = 'liuyao.shensha.jiangxing_day_branch.v1';
const _huaGaiPackageId = 'liuyao.shensha.huagai_day_branch.v1';
const _bodyMarkersPackageId = 'liuyao.auxiliary.guashen_mingyao.v1';
const _packageVersion = '2.0.0';

const _pillarOrder = ['year', 'month', 'day', 'hour'];
const _pillarLabels = {'year': '年', 'month': '月', 'day': '日', 'hour': '时'};
const _stageOrder = [
  '长生',
  '沐浴',
  '冠带',
  '临官',
  '帝旺',
  '衰',
  '病',
  '死',
  '墓',
  '绝',
  '胎',
  '养',
];
const _startBranches = {'木': '亥', '火': '寅', '金': '巳', '水': '申', '土': '四土独立表'};

/// 十二长生表的「具体选择五行」参照：以五行长生起点为观察支。
/// 土无统一长生，采用火土同宫（起点寅）；土爻本身仍走四土独立表，
/// 观察支取自身地支，避免土爻随参照列漂移。
const _elementReferenceOrder = [
  'element:木',
  'element:火',
  'element:金',
  'element:水',
  'element:土',
];

Map<String, dynamic> buildFiveElementTwelveStages(
  List<Map<String, dynamic>> lines,
  Map<String, Map<String, String>> pillars, {
  String layer = 'base',
}) {
  for (final position in _pillarOrder) {
    if (!pillars.containsKey(position)) {
      throw ArgumentError('五行十二长生缺少 $position 柱');
    }
  }

  final lineResults = <Map<String, dynamic>>[];
  final steps = <String>[
    '木火金水采用顺行十二长生；土采用《五行大义》丑辰未戌四土独立表',
    '四土保留受气、衰病、生、王、葬原始阶段，并声明显示别名',
  ];
  for (final line in lines) {
    final element = line['element'] as String;
    final pillarResults = <Map<String, dynamic>>[];
    for (final reference in _pillarOrder) {
      final pillar = pillars[reference]!;
      final branch = pillar['branch']!;
      final subjectBranch = line['earthly_branch'] as String;
      final growth = lookupPrivateBranchGrowth(subjectBranch, branch);
      final sourcePhases = (growth['source_phases'] as List).cast<String>();
      final displayPhases = (growth['display_phases'] as List).cast<String>();
      final stage = displayPhases.join('、');
      pillarResults.add({
        'reference': reference,
        'reference_label': _pillarLabels[reference],
        'pillar_gan_zhi': pillar['gan_zhi'],
        'reference_branch': branch,
        'stage': stage,
        'source_model': growth['source_model'],
        'source_phases': sourcePhases,
        'display_phases': displayPhases,
      });
      steps.add(
        '${line['position_name']}$element：${_pillarLabels[reference]}支$branch → $stage',
      );
    }
    for (final refKey in _elementReferenceOrder) {
      final elementName = refKey.substring('element:'.length);
      final observedBranch = line['earthly_branch'] as String;
      // 五行参照（2026-09-01 修正）：主体为所选五行、观察支为爻支——
      // 即「木在亥长生、在卯帝旺…」。旧实现以爻支为主体、固定观察该
      // 五行长生起点，结果只随爻支自身五行变化（火/土参照完全同值、
      // 土爻恒帝旺），不符合五行主体语义。
      final growth = lookupElementGrowth(elementName, observedBranch);
      final sourcePhases = (growth['source_phases'] as List).cast<String>();
      final displayPhases = (growth['display_phases'] as List).cast<String>();
      final stage = displayPhases.join('、');
      pillarResults.add({
        'reference': refKey,
        'reference_label': elementName,
        'pillar_gan_zhi': elementName,
        'reference_branch': observedBranch,
        'stage': stage,
        'source_model': growth['source_model'],
        'source_phases': sourcePhases,
        'display_phases': displayPhases,
      });
      steps.add(
        '${line['position_name']}$element：五行$elementName 主体观察爻支$observedBranch → $stage',
      );
    }
    lineResults.add({
      'line_id': line['id'],
      'position': line['position'],
      'position_name': line['position_name'],
      'line_element': element,
      'pillar_results': pillarResults,
    });
  }

  final object = <String, dynamic>{
    'rule_id': 'annotation.wuxing_twelve_stages.four_earth.v2',
    'rule_version': _packageVersion,
    'system': 'four_elements_forward_plus_four_earth_source_native',
    'scope': '${layer}_lines',
    'reference_order': List<String>.from([
      ..._pillarOrder,
      ..._elementReferenceOrder,
    ]),
    'stage_order': List<String>.from(_stageOrder),
    'start_branches': Map<String, String>.from(_startBranches),
    'line_results': lineResults,
  };
  final trace = <String, dynamic>{
    'rule_id': object['rule_id'],
    'label': layer == 'base' ? '五行十二长生' : '五行十二长生（${_layerLabel(layer)}）',
    'scope': 'rule_annotations',
    'inputs': {
      'line_elements': [
        for (final line in lines)
          {'line_id': line['id'], 'element': line['element']},
      ],
      'pillars': {for (final name in _pillarOrder) name: pillars[name]},
      'start_branches': Map<String, String>.from(_startBranches),
    },
    'steps': steps,
    'result': lineResults,
    'rule_version': _packageVersion,
    'source_ids': ['SRC-011', 'SRC-012'],
  };
  return {'object': object, 'trace': trace};
}

String _layerLabel(String layer) => switch (layer) {
  'hidden' => '伏卦',
  'changed' => '变卦',
  _ => '本卦',
};

({Map<String, dynamic> result, Map<String, dynamic> trace}) _buildShensha({
  required String ruleId,
  required String displayName,
  required String canonicalName,
  required List<String> aliases,
  required String category,
  required String basisType,
  required Map<String, String> dayPillar,
  required String basisValue,
  required List<String> targetBranches,
  required List<Map<String, dynamic>> lines,
  required String traceLabel,
  required String lookupDescription,
  required Map<String, dynamic> lookupTable,
  required List<String> sourceIds,
  bool includeTargetIndex = false,
  String finalScopeNote = 'v1 不扫描伏神与变卦爻',
}) {
  if (!dayPillar.containsKey('gan_zhi')) {
    throw ArgumentError('神煞计算缺少日柱干支');
  }
  final matches = <Map<String, dynamic>>[];
  for (final line in lines) {
    final branch = line['earthly_branch'] as String;
    if (!targetBranches.contains(branch)) continue;
    matches.add({
      'line_id': line['id'],
      'position': line['position'],
      'position_name': line['position_name'],
      'gan_zhi': line['gan_zhi'],
      'branch': branch,
      'relation': line['relation'],
      if (includeTargetIndex) 'target_index': targetBranches.indexOf(branch),
    });
  }
  if (includeTargetIndex) {
    matches.sort((left, right) {
      final target = (left['target_index'] as int).compareTo(
        right['target_index'] as int,
      );
      return target != 0
          ? target
          : (left['position'] as int).compareTo(right['position'] as int);
    });
  }

  final result = <String, dynamic>{
    'rule_id': ruleId,
    'rule_version': _packageVersion,
    'display_name': displayName,
    'canonical_name': canonicalName,
    'aliases': aliases,
    'category': category,
    'scope': 'base_visible_lines',
    'basis': {
      'type': basisType,
      'pillar_gan_zhi': dayPillar['gan_zhi'],
      'value': basisValue,
    },
    'target_branches': targetBranches,
    'status': matches.isEmpty ? 'computed_no_match' : 'computed_match',
    'matches': matches,
    'excluded_scopes': ['hidden', 'changed'],
  };
  final branchLabel = basisType == 'day_stem' ? '日干' : '日支';
  final comparison = targetBranches.length == 1 ? '=' : '∈';
  final inverseComparison = targetBranches.length == 1 ? '≠' : '∉';
  final trace = <String, dynamic>{
    'rule_id': ruleId,
    'label': traceLabel,
    'scope': 'rule_annotations',
    'inputs': {
      'day_pillar': dayPillar,
      'lookup_table': lookupTable,
      'base_visible_line_branches': [
        for (final line in lines)
          {'line_id': line['id'], 'branch': line['earthly_branch']},
      ],
    },
    'steps': [
      '读取项目日柱 ${dayPillar['gan_zhi']}，取$branchLabel $basisValue',
      lookupDescription,
      for (final line in lines)
        '${line['position_name']}${line['gan_zhi']}：爻支${line['earthly_branch']} ${targetBranches.contains(line['earthly_branch']) ? comparison : inverseComparison} ${targetBranches.join('、')} → ${targetBranches.contains(line['earthly_branch']) ? '命中' : '未命中'}',
      matches.isEmpty
          ? '本卦六个明爻均无${targetBranches.join('、')}支，结果为已计算未命中'
          : '命中本卦明爻：${matches.map((item) => item['position_name']).join('、')}',
      finalScopeNote,
    ],
    'result': result,
    'rule_version': _packageVersion,
    'source_ids': sourceIds,
  };
  return (result: result, trace: trace);
}

({Map<String, dynamic> result, Map<String, dynamic> trace}) buildLuShen(
  List<Map<String, dynamic>> lines,
  Map<String, String> dayPillar,
) {
  final stem = dayPillar['stem'];
  final target = stem == null ? null : luShenTable[stem];
  if (stem == null || target == null) throw ArgumentError('禄神需要有效日干');
  return _buildShensha(
    ruleId: 'shensha.lushen.day_stem.v1',
    displayName: '禄神',
    canonicalName: '天元禄',
    aliases: ['禄神', '天元禄'],
    category: 'stem_shensha',
    basisType: 'day_stem',
    dayPillar: dayPillar,
    basisValue: stem,
    targetBranches: [target],
    lines: lines,
    traceLabel: '禄神',
    lookupDescription: '查天元禄表：$stem干禄在$target',
    lookupTable: Map<String, String>.from(luShenTable),
    sourceIds: ['SRC-011', 'SRC-012'],
  );
}

({Map<String, dynamic> result, Map<String, dynamic> trace}) buildTianYi(
  List<Map<String, dynamic>> lines,
  Map<String, String> dayPillar,
) {
  final stem = dayPillar['stem'];
  final targets = stem == null ? null : tianYiTable[stem];
  if (stem == null || targets == null) throw ArgumentError('天乙需要有效日干');
  return _buildShensha(
    ruleId: 'shensha.tianyi.day_stem.v1',
    displayName: '天乙贵人',
    canonicalName: '天乙贵人',
    aliases: ['天乙', '天乙贵人'],
    category: 'stem_shensha',
    basisType: 'day_stem',
    dayPillar: dayPillar,
    basisValue: stem,
    targetBranches: List<String>.from(targets),
    lines: lines,
    traceLabel: '天乙贵人',
    lookupDescription: '查天乙贵人表：$stem干天乙在${targets.join('、')}',
    lookupTable: {
      for (final entry in tianYiTable.entries)
        entry.key: List<String>.from(entry.value),
    },
    sourceIds: ['SRC-011', 'SRC-012'],
    includeTargetIndex: true,
  );
}

({Map<String, dynamic> result, Map<String, dynamic> trace}) _dayBranchShensha(
  List<Map<String, dynamic>> lines,
  Map<String, String> dayPillar, {
  required Map<String, String> table,
  required String ruleId,
  required String displayName,
  required String canonicalName,
  required List<String> aliases,
  required String traceLabel,
  required String lookupName,
  required List<String> sourceIds,
  String finalScopeNote = 'v1 不扫描伏神与变卦爻',
}) {
  final branch = dayPillar['branch'];
  final target = branch == null ? null : table[branch];
  if (branch == null || target == null) {
    throw ArgumentError('$displayName 需要有效日支');
  }
  return _buildShensha(
    ruleId: ruleId,
    displayName: displayName,
    canonicalName: canonicalName,
    aliases: aliases,
    category: 'branch_shensha',
    basisType: 'day_branch',
    dayPillar: dayPillar,
    basisValue: branch,
    targetBranches: [target],
    lines: lines,
    traceLabel: traceLabel,
    lookupDescription: '查$lookupName表：$branch日$lookupName在$target',
    lookupTable: Map<String, String>.from(table),
    sourceIds: sourceIds,
    finalScopeNote: finalScopeNote,
  );
}

({Map<String, dynamic> result, Map<String, dynamic> trace}) buildYiMa(
  List<Map<String, dynamic>> lines,
  Map<String, String> dayPillar,
) => _dayBranchShensha(
  lines,
  dayPillar,
  table: yiMaTable,
  ruleId: 'shensha.yima.day_branch.v1',
  displayName: '驿马',
  canonicalName: '驿马',
  aliases: ['驿马', '驛馬'],
  traceLabel: '驿马',
  lookupName: '驿马',
  sourceIds: ['SRC-011', 'SRC-012', 'SRC-016'],
);

({Map<String, dynamic> result, Map<String, dynamic> trace}) buildTaoHua(
  List<Map<String, dynamic>> lines,
  Map<String, String> dayPillar,
) => _dayBranchShensha(
  lines,
  dayPillar,
  table: taoHuaTable,
  ruleId: 'shensha.taohua.day_branch.v1',
  displayName: '桃花',
  canonicalName: '咸池',
  aliases: ['桃花', '桃花煞', '咸池', '咸池杀'],
  traceLabel: '桃花（咸池）',
  lookupName: '桃花（咸池）',
  sourceIds: ['SRC-011', 'SRC-012', 'SRC-015', 'SRC-017'],
  finalScopeNote: 'v1 不扫描伏神与变卦爻，也不读取月支或年支',
);

({Map<String, dynamic> result, Map<String, dynamic> trace}) buildJiangXing(
  List<Map<String, dynamic>> lines,
  Map<String, String> dayPillar,
) => _dayBranchShensha(
  lines,
  dayPillar,
  table: jiangXingTable,
  ruleId: 'shensha.jiangxing.day_branch.v1',
  displayName: '将星',
  canonicalName: '将星',
  aliases: ['将星', '將星', '将曜', '將曜'],
  traceLabel: '将星',
  lookupName: '将星',
  sourceIds: ['SRC-011', 'SRC-012', 'SRC-015'],
  finalScopeNote: 'v1 不扫描伏神与变卦爻，也不读取年支或农历月序将星',
);

({Map<String, dynamic> result, Map<String, dynamic> trace}) buildHuaGai(
  List<Map<String, dynamic>> lines,
  Map<String, String> dayPillar,
) => _dayBranchShensha(
  lines,
  dayPillar,
  table: huaGaiTable,
  ruleId: 'shensha.huagai.day_branch.v1',
  displayName: '华盖',
  canonicalName: '华盖',
  aliases: ['华盖', '華蓋'],
  traceLabel: '华盖',
  lookupName: '华盖',
  sourceIds: ['SRC-011', 'SRC-012', 'SRC-015'],
  finalScopeNote: 'v1 包含本卦动爻，但不扫描伏神、变卦爻、年支或农历月序华盖',
);

/// 把私有参考合同中已经逐字段校验的“月卦身、命爻”机械位置提升为
/// 产品注解。二者不是普通神煞：卦身按目标支匹配本卦全部同支爻，命爻则
/// 由世爻支直接映射绝对爻位。
({Map<String, dynamic> result, Map<String, dynamic> trace})
buildSelectedBodyMarkers(
  Map<String, dynamic> privateMarkers,
  List<Map<String, dynamic>> baseLines,
) {
  final monthBody =
      privateMarkers['month_hexagram_body'] as Map<String, dynamic>;
  final mingyao = privateMarkers['mingyao'] as Map<String, dynamic>;
  final shiLine = privateMarkers['shi_line'] as Map<String, dynamic>;
  final guashenPositions = (monthBody['positions'] as List).cast<int>();
  final mingyaoPosition = mingyao['position'] as int;

  Map<String, dynamic> lineAt(int position) {
    final line = baseLines[position - 1];
    return {
      'line_id': line['id'],
      'position': position,
      'position_name': line['position_name'],
      'gan_zhi': line['gan_zhi'],
      'branch': line['earthly_branch'],
      'relation': line['relation'],
    };
  }

  final object = <String, dynamic>{
    'rule_id': 'auxiliary.body_markers.guashen_mingyao.v1',
    'rule_version': _packageVersion,
    'profile': privateMarkers['profile'],
    'scope': 'base_hexagram',
    'interpretation_enabled': false,
    'guashen': {
      'display_name': '卦身',
      'canonical_name': '月卦身',
      'aliases': ['卦身', '月卦身'],
      'basis': monthBody['basis'],
      'target_branch': monthBody['branch'],
      'positions': guashenPositions,
      'matches': [for (final position in guashenPositions) lineAt(position)],
      'status': guashenPositions.isEmpty
          ? 'computed_no_match'
          : 'computed_match',
      'match_semantics': monthBody['match_semantics'],
      'source_status': monthBody['source_status'],
    },
    'mingyao': {
      'display_name': '命爻',
      'canonical_name': '命爻',
      'basis': mingyao['basis'],
      'position': mingyaoPosition,
      'line': lineAt(mingyaoPosition),
      'status': 'computed_position',
      'variant_id': mingyao['variant_id'],
      'source_status': mingyao['source_status'],
    },
  };
  final trace = <String, dynamic>{
    'rule_id': object['rule_id'],
    'label': '卦身与命爻',
    'scope': 'rule_annotations',
    'inputs': {
      'shi_line': shiLine,
      'base_line_branches': [
        for (final line in baseLines)
          {'position': line['position'], 'branch': line['earthly_branch']},
      ],
    },
    'steps': [
      '世爻位于${shiLine['position']}爻，世爻支${shiLine['branch']}，阴阳为${shiLine['yin_yang']}',
      '按世爻阴阳与世位取月卦身支：${monthBody['branch']}',
      guashenPositions.isEmpty
          ? '本卦明爻没有${monthBody['branch']}支，卦身不上卦'
          : '本卦${guashenPositions.map((position) => linePositionNames[position - 1]).join('、')}见${monthBody['branch']}支，全部记为卦身位置',
      '按所选命爻传本表，以世爻支${shiLine['branch']}取命爻在${linePositionNames[mingyaoPosition - 1]}',
      '仅保存机械位置，不自动输出吉凶、旺衰或应期',
    ],
    'result': object,
    'rule_version': _packageVersion,
    'source_ids': ['SRC-020', 'SRC-024'],
  };
  return (result: object, trace: trace);
}

Map<String, dynamic> annotationRulePackage() => {
  'id': _annotationPackageId,
  'version': _packageVersion,
  'status': 'provisional_authority',
  'source_ids': ['SRC-011', 'SRC-012'],
  'system': 'five_elements_forward',
};

Map<String, dynamic> _shenshaPackage(
  String id,
  List<String> sourceIds,
  String system,
) => {
  'id': id,
  'version': _packageVersion,
  'status': 'provisional_authority',
  'source_ids': sourceIds,
  'system': system,
};

Map<String, dynamic> luShenRulePackage() => _shenshaPackage(_luShenPackageId, [
  'SRC-011',
  'SRC-012',
], 'day_stem_to_visible_base_line_branch');
Map<String, dynamic> tianYiRulePackage() => _shenshaPackage(_tianYiPackageId, [
  'SRC-011',
  'SRC-012',
], 'day_stem_to_visible_base_line_branches');
Map<String, dynamic> yiMaRulePackage() => _shenshaPackage(_yiMaPackageId, [
  'SRC-011',
  'SRC-012',
  'SRC-016',
], 'day_branch_to_visible_base_line_branch');
Map<String, dynamic> taoHuaRulePackage() => _shenshaPackage(_taoHuaPackageId, [
  'SRC-011',
  'SRC-012',
  'SRC-015',
  'SRC-017',
], 'day_branch_to_visible_base_line_branch');
Map<String, dynamic> jiangXingRulePackage() => _shenshaPackage(
  _jiangXingPackageId,
  ['SRC-011', 'SRC-012', 'SRC-015'],
  'day_branch_to_visible_base_line_branch',
);
Map<String, dynamic> huaGaiRulePackage() => _shenshaPackage(_huaGaiPackageId, [
  'SRC-011',
  'SRC-012',
  'SRC-015',
], 'day_branch_to_visible_base_line_branch');
Map<String, dynamic> bodyMarkersRulePackage() => _shenshaPackage(
  _bodyMarkersPackageId,
  ['SRC-020', 'SRC-024'],
  'shi_line_to_guashen_branch_and_mingyao_position',
);
