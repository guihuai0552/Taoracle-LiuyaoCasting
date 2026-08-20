/// 京房八宫六十四卦五星排布。
///
/// 规则来源（用户 2026-08-19 确认）：
/// - 五星固定顺序：镇土星 → 太白金星 → 太阴水星 → 岁木星 → 荧惑火星；
/// - 八宫顺序：乾 → 震 → 坎 → 艮 → 坤 → 巽 → 离 → 兑；
/// - 乾为天（乾宫首卦）世爻起镇土星；下一宫首卦沿八宫顺序取上一宫首卦的
///   克制星（同「后三位」：五星索引 +3 mod 5）；
/// - 宫内世爻星：世爻星 = 宫首卦世爻星 +（宫内卦序 - 1）mod 5；
/// - 卦内排布：从世爻起按初爻→上爻循环方向依次排入五星，世爻为第一位，
///   每爻顺推一星；世应相隔三位，应爻即世爻的克制星。
///
/// 爻位一律按初爻到上爻编号 1..6。

library;

const fiveStarsPackageId = 'liuyao.five_stars.jingfang.v1';
const fiveStarsPackageVersion = '1.0.0';
const fiveStarsRuleId = 'mansion.jingfang.world_line_five_stars.v1';

const List<String> fiveStarNames = ['镇土星', '太白金星', '太阴水星', '岁木星', '荧惑火星'];

const List<String> fiveStarShortNames = ['镇土', '太白', '太阴', '岁木', '荧惑'];

const List<String> fiveStarElements = ['土', '金', '水', '木', '火'];

const List<String> fiveStarPalaceOrder = [
  '乾',
  '震',
  '坎',
  '艮',
  '坤',
  '巽',
  '离',
  '兑',
];

const int fiveStarOriginIndex = 0; // 乾宫首卦世爻起镇土星

Map<String, dynamic> fiveStarsRulePackage() => {
  'id': fiveStarsPackageId,
  'version': fiveStarsPackageVersion,
  'status': 'confirmed_user_rule',
  'source_ids': ['SRC-USER-2026-08-19'],
  'system': 'jingfang_64_hexagrams_world_line_five_stars',
};

({Map<String, dynamic> result, Map<String, dynamic> trace}) buildFiveStars(
  Map<String, dynamic> base, {
  String layer = 'base',
}) {
  final palaceName = base['palace_name'] as String;
  final palaceSequence = base['palace_sequence'] as int;
  final shiPosition = base['shi_position'] as int;
  final yingPosition = base['ying_position'] as int;
  final lines = (base['lines'] as List).cast<Map<String, dynamic>>();

  final palaceIndex = fiveStarPalaceOrder.indexOf(palaceName);
  if (palaceIndex < 0) throw ArgumentError('未知卦宫：$palaceName');
  if (palaceSequence < 1 || palaceSequence > 8) {
    throw ArgumentError('八宫序位必须是 1..8');
  }
  if (shiPosition < 1 || shiPosition > 6) {
    throw ArgumentError('世爻位置必须是 1..6');
  }
  if (lines.length != 6) throw ArgumentError('本卦必须包含六爻');

  // 宫首卦世爻星：乾宫起镇土星，下一宫沿八宫顺序 +3 mod 5（克制星）。
  final palaceOriginStar = (fiveStarOriginIndex + palaceIndex * 3) % 5;
  // 世爻星 = 宫首卦星 +（宫内卦序 - 1）mod 5。
  final worldStar = (palaceOriginStar + (palaceSequence - 1)) % 5;

  // 卦内排布：从世爻位置起按初爻→上爻循环，每爻顺推一星。
  final lineByPosition = {
    for (final line in lines) line['position'] as int: line,
  };
  final placements = <Map<String, dynamic>>[];
  for (var offset = 0; offset < 6; offset++) {
    final position = (shiPosition - 1 + offset) % 6 + 1;
    final starIndex = (worldStar + offset) % 5;
    final role = position == shiPosition
        ? '世'
        : position == yingPosition
        ? '应'
        : '爻';
    placements.add({
      'order': offset + 1,
      'line_id': lineByPosition[position]!['id'],
      'position': position,
      'position_name': lineByPosition[position]!['position_name'],
      'role': role,
      'star_index': starIndex,
      'star': fiveStarShortNames[starIndex],
      'star_name': fiveStarNames[starIndex],
      'element': fiveStarElements[starIndex],
      'sequence_index': offset,
    });
  }

  final result = <String, dynamic>{
    'rule_id': fiveStarsRuleId,
    'rule_version': fiveStarsPackageVersion,
    'system': 'jingfang_64_hexagrams_world_line_five_stars',
    'scope': '${layer}_lines',
    'star_order': List<String>.from(fiveStarShortNames),
    'palace_order': List<String>.from(fiveStarPalaceOrder),
    'hexagram': {
      'code': base['code'],
      'name': base['name'],
      'palace_name': palaceName,
      'palace_index': palaceIndex,
      'palace_sequence': palaceSequence,
      'global_index': palaceIndex * 8 + palaceSequence - 1,
    },
    'world_line': {
      'position': shiPosition,
      'position_name': lineByPosition[shiPosition]!['position_name'],
      'star_index': worldStar,
      'star': fiveStarShortNames[worldStar],
      'star_name': fiveStarNames[worldStar],
      'element': fiveStarElements[worldStar],
    },
    'response_line': {
      'position': yingPosition,
      'position_name': lineByPosition[yingPosition]!['position_name'],
      'star_index': (worldStar + 3) % 5,
      'star': fiveStarShortNames[(worldStar + 3) % 5],
      'star_name': fiveStarNames[(worldStar + 3) % 5],
      'element': fiveStarElements[(worldStar + 3) % 5],
    },
    'line_placements': placements,
    'trace': <String, dynamic>{
      'palace_origin_star': fiveStarShortNames[palaceOriginStar],
      'palace_origin_star_index': palaceOriginStar,
      'world_star': fiveStarShortNames[worldStar],
      'world_star_index': worldStar,
      'kills_relation':
          '${fiveStarElements[(worldStar + 3) % 5]}克${fiveStarElements[worldStar]}',
    },
  };

  final trace = <String, dynamic>{
    'rule_id': fiveStarsRuleId,
    'label': layer == 'base'
        ? '京房八宫六十四卦五星排布'
        : '京房八宫六十四卦五星排布（${layer == 'hidden' ? '伏卦' : '变卦'}）',
    'scope': 'rule_annotations',
    'inputs': {
      'hexagram_code': base['code'],
      'hexagram_name': base['name'],
      'palace_name': palaceName,
      'palace_sequence': palaceSequence,
      'shi_position': shiPosition,
      'ying_position': yingPosition,
    },
    'steps': [
      '八宫顺序为 ${fiveStarPalaceOrder.join('、')}，$palaceName宫序号 $palaceIndex',
      '乾宫首卦世爻起镇土星；宫首卦世爻星沿八宫顺序每次 +3 mod 5（克制星），'
          '$palaceName宫首卦世爻星 = ${fiveStarShortNames[palaceOriginStar]}',
      '${base['name']} 为$palaceName宫第 $palaceSequence 卦，世爻星 = '
          '${fiveStarShortNames[palaceOriginStar]} + ${palaceSequence - 1} mod 5 = '
          '${fiveStarShortNames[worldStar]}',
      '世在${lineByPosition[shiPosition]!['position_name']}，从世爻起沿初爻→上爻循环排星，'
          '应爻（${lineByPosition[yingPosition]!['position_name']}）为世爻的克制星 '
          '${fiveStarNames[(worldStar + 3) % 5]}',
      for (final item in placements)
        '第${item['order']}位 ${item['star_name']} → ${item['position_name']}（${item['role']}）',
    ],
    'result': result,
    'rule_version': fiveStarsPackageVersion,
    'source_ids': ['SRC-USER-2026-08-19'],
  };
  return (result: result, trace: trace);
}
