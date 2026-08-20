/// 京房六十四卦配二十八宿。
///
/// 本文件逐字段移植 Python `twenty_eight_mansions.py` 的逐爻装宿合同。
/// 合同；爻位一律按初爻到上爻编号 1..6。

library;

const mansionPackageId = 'liuyao.mansions.jingfang_world_line.v1';
const mansionPackageVersion = '1.0.0';
const mansionRuleId = 'mansion.jingfang.world_line_and_six_lines.v1';

const List<String> mansions = [
  '角',
  '亢',
  '氐',
  '房',
  '心',
  '尾',
  '箕',
  '斗',
  '牛',
  '女',
  '虚',
  '危',
  '室',
  '壁',
  '奎',
  '娄',
  '胃',
  '昴',
  '毕',
  '觜',
  '参',
  '井',
  '鬼',
  '柳',
  '星',
  '张',
  '翼',
  '轸',
];

const List<String> mansionPalaceOrder = [
  '乾',
  '震',
  '坎',
  '艮',
  '坤',
  '巽',
  '离',
  '兑',
];
const int mansionWorldStartIndex = 20; // 参

const Map<int, List<int>> mansionPlacementPositions = {
  1: [1, 4, 2, 6, 3, 5],
  2: [2, 5, 1, 6, 3, 4],
  3: [3, 6, 1, 5, 2, 4],
  4: [4, 1, 6, 2, 5, 3],
  5: [5, 2, 6, 1, 4, 3],
  6: [6, 3, 5, 1, 4, 2],
};

const List<String> mansionPlacementRoles = ['世', '应', '世卦', '应卦', '世卦', '应卦'];

Map<String, dynamic> mansionRulePackage() => {
  'id': mansionPackageId,
  'version': mansionPackageVersion,
  'status': 'confirmed_user_rule',
  'source_ids': ['SRC-006'],
  'system': 'jingfang_64_hexagrams_world_line',
};

({Map<String, dynamic> result, Map<String, dynamic> trace})
buildTwentyEightMansions(Map<String, dynamic> base, {String layer = 'base'}) {
  final palaceName = base['palace_name'] as String;
  final palaceSequence = base['palace_sequence'] as int;
  final shiPosition = base['shi_position'] as int;
  final yingPosition = base['ying_position'] as int;
  final lines = (base['lines'] as List).cast<Map<String, dynamic>>();

  final palaceIndex = mansionPalaceOrder.indexOf(palaceName);
  if (palaceIndex < 0) throw ArgumentError('未知卦宫：$palaceName');
  if (palaceSequence < 1 || palaceSequence > 8) {
    throw ArgumentError('八宫序位必须是 1..8');
  }
  final positions = mansionPlacementPositions[shiPosition];
  if (positions == null) throw ArgumentError('世爻位置必须是 1..6');
  final expectedYing = shiPosition > 3 ? shiPosition - 3 : shiPosition + 3;
  if (yingPosition != expectedYing) throw ArgumentError('应爻必须与世爻相隔三位');
  if (lines.length != 6) throw ArgumentError('本卦必须包含六爻');

  final globalIndex = palaceIndex * 8 + palaceSequence - 1;
  final worldIndex = (mansionWorldStartIndex + globalIndex) % mansions.length;
  final lineByPosition = {
    for (final line in lines) line['position'] as int: line,
  };

  final placements = <Map<String, dynamic>>[];
  for (var offset = 0; offset < positions.length; offset++) {
    final position = positions[offset];
    final line = lineByPosition[position]!;
    final mansionIndex = (worldIndex + offset) % mansions.length;
    placements.add({
      'order': offset + 1,
      'line_id': line['id'],
      'position': position,
      'position_name': line['position_name'],
      'placement_role': mansionPlacementRoles[offset],
      'mansion_index': mansionIndex,
      'mansion': mansions[mansionIndex],
    });
  }

  final result = <String, dynamic>{
    'rule_id': mansionRuleId,
    'rule_version': mansionPackageVersion,
    'system': 'jingfang_64_hexagrams_world_line',
    'scope': '${layer}_lines',
    'mansion_order': List<String>.from(mansions),
    'palace_order': List<String>.from(mansionPalaceOrder),
    'hexagram': {
      'code': base['code'],
      'name': base['name'],
      'palace_name': palaceName,
      'palace_index': palaceIndex,
      'palace_sequence': palaceSequence,
      'global_index': globalIndex,
    },
    'world_line': {
      'position': shiPosition,
      'position_name': lineByPosition[shiPosition]!['position_name'],
      'mansion_index': worldIndex,
      'mansion': mansions[worldIndex],
    },
    'response_line': {
      'position': yingPosition,
      'position_name': lineByPosition[yingPosition]!['position_name'],
    },
    'placement_position_order': List<int>.from(positions),
    'line_placements': placements,
  };

  final trace = <String, dynamic>{
    'rule_id': mansionRuleId,
    'label': layer == 'base'
        ? '京房六十四卦配二十八宿'
        : '京房六十四卦配二十八宿（${layer == 'hidden' ? '伏卦' : '变卦'}）',
    'scope': 'rule_annotations',
    'inputs': {
      'hexagram_code': base['code'],
      'hexagram_name': base['name'],
      'palace_name': palaceName,
      'palace_sequence': palaceSequence,
      'shi_position': shiPosition,
      'ying_position': yingPosition,
      'palace_order': List<String>.from(mansionPalaceOrder),
      'mansion_order': List<String>.from(mansions),
    },
    'steps': [
      '八宫顺序为 ${mansionPalaceOrder.join('、')}；$palaceName宫序号为 $palaceIndex',
      '${base['name']} 为$palaceName宫第 $palaceSequence 卦，六十四卦全局序号 = $palaceIndex × 8 + ${palaceSequence - 1} = $globalIndex',
      '乾为天世爻从参宿（索引 $mansionWorldStartIndex）起，($mansionWorldStartIndex + $globalIndex) mod 28 = $worldIndex，故${lineByPosition[shiPosition]!['position_name']}世爻配${mansions[worldIndex]}宿',
      '世在${lineByPosition[shiPosition]!['position_name']}、应在${lineByPosition[yingPosition]!['position_name']}，按世应两卦交替得到爻位次序：${positions.join('、')}',
      for (final item in placements)
        '第${item['order']}宿 ${item['mansion']} → ${item['position_name']}（${item['placement_role']}）',
    ],
    'result': result,
    'rule_version': mansionPackageVersion,
    'source_ids': ['SRC-006'],
  };
  return (result: result, trace: trace);
}
