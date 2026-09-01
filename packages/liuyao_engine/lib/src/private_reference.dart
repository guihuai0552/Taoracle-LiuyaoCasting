/// Audited Dart port of the mechanical contract in `liuyao-private`.
///
/// This module deliberately keeps two representations of hidden information:
/// `plate.base.lines[].hidden_spirits` follows the private reference contract
/// and only exposes relatives missing from the visible base hexagram, while
/// the product schema continues to retain the user's full six-line Fu
/// hexagram at `hexagram.base.lines[].hidden`.
library;

import 'almanac.dart';
import 'constants.dart';
import 'exact_jie_terms.dart';
import 'hexagram.dart';
import 'lunar_core.dart';
import 'shanghai_time.dart';

const String privateSpecVersion = '1.0.0-draft';
const String privateProfileId = 'classic-wenwang-v1';
const String privateReferenceRevision = '6ca3d3e';
const String privateGrowthProfile = 'wuxing-dayi-four-earth-v1';
const String privateShenshaProfile = 'classic-day-body-markers-v2';
const String privateRelationshipProfile = 'zengshan-buyi-basic-relations-v1';
const String privateMovingProfile = 'zengshan-buyi-moving-change-v1';

const _earthSourcePhases = <String, Map<String, List<String>>>{
  '丑': {
    '子': ['临官'],
    '丑': ['王'],
    '寅': ['衰病'],
    '卯': ['死'],
    '辰': ['葬'],
    '巳': ['受气'],
    '午': ['受气'],
    '未': ['胎'],
    '申': ['养'],
    '酉': ['生'],
    '戌': ['沐浴'],
    '亥': ['冠带'],
  },
  '辰': {
    '子': ['生'],
    '丑': ['沐浴'],
    '寅': ['冠带'],
    '卯': ['临官'],
    '辰': ['王'],
    '巳': ['衰病'],
    '午': ['死'],
    '未': ['葬'],
    '申': ['受气'],
    '酉': ['受气'],
    '戌': ['胎'],
    '亥': ['养'],
  },
  '未': {
    '子': ['受气'],
    '丑': ['胎'],
    '寅': ['养'],
    '卯': ['生'],
    '辰': ['沐浴'],
    '巳': ['冠带'],
    '午': ['临官'],
    '未': ['王'],
    '申': ['衰病'],
    '酉': ['死'],
    '戌': ['葬'],
    '亥': ['受气'],
  },
  '戌': {
    '子': ['死'],
    '丑': ['葬'],
    '寅': ['受气'],
    '卯': ['受气'],
    '辰': ['胎'],
    '巳': ['养'],
    '午': ['生'],
    '未': ['沐浴'],
    '申': ['冠带'],
    '酉': ['临官'],
    '戌': ['王'],
    '亥': ['衰病'],
  },
};

/// 《五行大义》原始段名 → 标准十二长生段名（display 层统一，source 保留原文）。
/// 受气即标准「绝」位（四土表跨两支）；衰病为原文合并段，无对应单一标准段，保留原样。
const _growthAliases = {'生': '长生', '王': '帝旺', '葬': '墓', '受气': '绝'};

Map<String, dynamic> lookupPrivateBranchGrowth(
  String subjectBranch,
  String observedBranch,
) {
  final element = branchElements[subjectBranch];
  if (element == null || !branchElements.containsKey(observedBranch)) {
    throw ArgumentError('十二长生输入必须是合法地支');
  }
  late final String sourceModel;
  late final List<String> sourcePhases;
  if (element == '土') {
    sourceModel = 'four_earth_source_native';
    sourcePhases = List<String>.from(
      _earthSourcePhases[subjectBranch]![observedBranch]!,
    );
  } else {
    sourceModel = 'non_earth_element_cycle';
    sourcePhases = [twelveStagesTable[element]![observedBranch]!];
  }
  return {
    'profile': privateGrowthProfile,
    'subject': {'branch': subjectBranch, 'element': element},
    'observed_branch': observedBranch,
    'source_model': sourceModel,
    'source_phases': sourcePhases,
    'display_phases': [
      for (final phase in sourcePhases) _growthAliases[phase] ?? phase,
    ],
    'rule_id': 'twelve-growth.branch-subject-lookup',
  };
}

/// 以「五行」为主体的十二长生查询：观察该五行在各爻地支上的状态。
///
/// 与 [lookupPrivateBranchGrowth]（主体=地支）互补：卦面标注的
/// 「五行参照」语义是「木在亥长生、在卯帝旺…」，即主体为所选五行、
/// 观察支为爻支。土无单一四土表（四土表以丑辰未戌各自为主体），
/// 此处按引擎通用土表（长生在申）取值。
Map<String, dynamic> lookupElementGrowth(
  String element,
  String observedBranch,
) {
  if (!twelveStagesTable.containsKey(element) ||
      !branchElements.containsKey(observedBranch)) {
    throw ArgumentError('五行主体必须是木火土金水，观察支必须是合法地支');
  }
  final stage = twelveStagesTable[element]![observedBranch]!;
  return {
    'profile': privateGrowthProfile,
    'subject': {'element': element, 'branch': null},
    'observed_branch': observedBranch,
    'source_model': 'element_subject_cycle',
    'source_phases': [stage],
    'display_phases': [_growthAliases[stage] ?? stage],
    'rule_id': 'twelve-growth.element-subject-lookup',
  };
}

Map<String, dynamic> _derivedForms(String bits) {
  String invert(String value) =>
      value.split('').map((item) => item == '1' ? '0' : '1').join();
  final mutual = '${bits[1]}${bits[2]}${bits[3]}${bits[2]}${bits[3]}${bits[4]}';
  final opposite = invert(bits);
  final reversed = bits.split('').reversed.join();
  Map<String, String> row(String value) => {
    'bits': value,
    'name': gua64[value]!,
  };
  return {
    'profile': 'mechanical-derived-forms-v1',
    'mutual': row(mutual),
    'opposite': row(opposite),
    'reversed': row(reversed),
  };
}

const _harmonyPairs = {
  '子丑',
  '丑子',
  '寅亥',
  '亥寅',
  '卯戌',
  '戌卯',
  '辰酉',
  '酉辰',
  '巳申',
  '申巳',
  '午未',
  '未午',
};
const _clashPairs = {
  '子午',
  '午子',
  '丑未',
  '未丑',
  '寅申',
  '申寅',
  '卯酉',
  '酉卯',
  '辰戌',
  '戌辰',
  '巳亥',
  '亥巳',
};
Map<String, dynamic> lookupPrivateElementRelation(
  String subjectElement,
  String actorElement,
) {
  late final String relation;
  late final String ruleId;
  if (subjectElement == actorElement) {
    relation = 'same_element';
    ruleId = 'five-elements.same';
  } else if (generates[actorElement] == subjectElement) {
    relation = 'actor_generates_subject';
    ruleId = 'five-elements.generation';
  } else if (controls[actorElement] == subjectElement) {
    relation = 'actor_controls_subject';
    ruleId = 'five-elements.control';
  } else if (generates[subjectElement] == actorElement) {
    relation = 'subject_generates_actor';
    ruleId = 'five-elements.generation';
  } else {
    relation = 'subject_controls_actor';
    ruleId = 'five-elements.control';
  }
  return {
    'profile': privateRelationshipProfile,
    'subject_element': subjectElement,
    'actor_element': actorElement,
    'relation': relation,
    'rule_id': ruleId,
  };
}

Map<String, dynamic> lookupPrivateBranchRelation(String left, String right) {
  final pair = '$left$right';
  final relation = left == right
      ? 'same_branch'
      : _harmonyPairs.contains(pair)
      ? 'six_harmony'
      : _clashPairs.contains(pair)
      ? 'six_clash'
      : 'none';
  return {
    'profile': privateRelationshipProfile,
    'left_branch': left,
    'right_branch': right,
    'relation': relation,
    'rule_id': switch (relation) {
      'same_branch' => 'earthly-branches.identity',
      'six_harmony' => 'earthly-branches.six-harmony',
      'six_clash' => 'earthly-branches.six-clash',
      _ => null,
    },
  };
}

Map<String, dynamic> _branchPairPattern(List<Map<String, dynamic>> lines) {
  final pairs = <Map<String, dynamic>>[];
  for (final positions in const [(1, 4), (2, 5), (3, 6)]) {
    final left = lines[positions.$1 - 1]['earthly_branch'] as String;
    final right = lines[positions.$2 - 1]['earthly_branch'] as String;
    final relation = lookupPrivateBranchRelation(left, right);
    pairs.add({
      'positions': [positions.$1, positions.$2],
      'branches': [left, right],
      'relation': relation['relation'],
      'rule_id': relation['rule_id'],
    });
  }
  return {
    'derived_profile': 'mechanical-derived-forms-v1',
    'relationship_profile': privateRelationshipProfile,
    'pairs': pairs,
    'is_six_harmony_hexagram': pairs.every(
      (item) => item['relation'] == 'six_harmony',
    ),
    'is_six_clash_hexagram': pairs.every(
      (item) => item['relation'] == 'six_clash',
    ),
  };
}

List<List<Map<String, dynamic>>> _missingHiddenSpirits(
  Map<String, dynamic> base,
) {
  final lines = (base['lines'] as List).cast<Map<String, dynamic>>();
  final present = lines.map((line) => line['relation'] as String).toSet();
  const relatives = {'兄弟', '父母', '子孙', '官鬼', '妻财'};
  final missing = relatives.difference(present);
  final palace = base['palace'] as Map<String, dynamic>;
  final palaceCode = palace['code'] as String;
  final pureLines = buildNajiaLines('$palaceCode$palaceCode');
  return List.generate(6, (index) {
    final row = pureLines[index];
    final relation = calculateRelation(
      palace['element'] as String,
      row['element']!,
    );
    if (!missing.contains(relation)) return <Map<String, dynamic>>[];
    return [
      {
        'relation': relation,
        'stem': row['heavenly_stem'],
        'branch': row['earthly_branch'],
        'element': row['element'],
        'source_palace': palace['name'],
      },
    ];
  }, growable: false);
}

Map<String, dynamic> _plateFromProduct(
  List<int> values,
  Map<String, dynamic> chart,
  String dayGanzhi,
  List<String> voidBranches,
) {
  final base = chart['base'] as Map<String, dynamic>;
  final changed = chart['changed'] as Map<String, dynamic>?;
  final baseLines = (base['lines'] as List).cast<Map<String, dynamic>>();
  final hidden = _missingHiddenSpirits(base);

  Map<String, dynamic> hexagramSummary(
    Map<String, dynamic> source, {
    required bool isBase,
  }) {
    final lines = (source['lines'] as List).cast<Map<String, dynamic>>();
    final shiYing = calculateShiYing(source['code'] as String);
    final result = <String, dynamic>{
      'bits': source['code'],
      'name': source['name'],
      'palace': source['palace_name'],
      'palace_element': source['palace_element'],
      'palace_index': (source['palace_sequence'] as int) - 1,
      'palace_type': const [
        '八纯',
        '一世',
        '二世',
        '三世',
        '四世',
        '五世',
        '游魂',
        '归魂',
      ][(source['palace_sequence'] as int) - 1],
      'shi_position': isBase ? source['shi_position'] : shiYing.shi,
      'ying_position': isBase ? source['ying_position'] : shiYing.ying,
      'lower_trigram': (source['lower_trigram'] as Map)['name'],
      'upper_trigram': (source['upper_trigram'] as Map)['name'],
      'relation_reference': isBase
          ? 'own_palace_element'
          : 'base_palace_element',
      if (!isBase) ...{
        'base_palace': base['palace_name'],
        'base_palace_element': base['palace_element'],
        'own_palace': source['palace_name'],
        'own_palace_element': source['palace_element'],
      },
      'lines': List.generate(6, (index) {
        final line = lines[index];
        final sourceValue = values[index];
        final value = isBase
            ? sourceValue
            : ((sourceValue == 6 || sourceValue == 9)
                  ? (sourceValue == 6 ? 7 : 8)
                  : sourceValue);
        return {
          'position': index + 1,
          'value': value,
          'yin_yang': (line['yin_yang'] == 'yang') ? '阳' : '阴',
          'moving': isBase ? line['changing'] : false,
          if (!isBase) 'source_value': sourceValue,
          if (!isBase)
            'changed_from_position': sourceValue == 6 || sourceValue == 9
                ? index + 1
                : null,
          'stem': line['heavenly_stem'],
          'branch': line['earthly_branch'],
          'element': line['element'],
          'relation': line['relation'],
          'six_spirit': isBase ? line['six_god'] : baseLines[index]['six_god'],
          if (isBase) 'shi_ying': line['role'],
          if (isBase) 'hidden_spirits': hidden[index],
        };
      }),
      'derived_forms': _derivedForms(source['code'] as String),
      'branch_pair_pattern': _branchPairPattern(lines),
    };
    return result;
  }

  final hiddenHexagram = base['hidden_hexagram'] as Map<String, dynamic>;
  return {
    'spec_version': privateSpecVersion,
    'profile': privateProfileId,
    'line_order': 'bottom_up',
    'input_lines': List<int>.from(values),
    'moving_positions': List<int>.from(chart['moving_positions'] as List),
    'base': hexagramSummary(base, isBase: true),
    'changed': changed == null ? null : hexagramSummary(changed, isBase: false),
    'fu_hexagram': {
      'profile': 'palace-opposite-v1',
      'bits': hiddenHexagram['code'],
      'name': hiddenHexagram['name'],
      'lower_trigram': (hiddenHexagram['lower_trigram'] as Map)['name'],
      'upper_trigram': (hiddenHexagram['upper_trigram'] as Map)['name'],
      'source_palace': base['palace_name'],
    },
    'calendar_context': {
      'day_ganzhi': dayGanzhi,
      'xun_kong': List<String>.from(voidBranches),
    },
  };
}

Map<String, dynamic> _growthExtension(
  Map<String, dynamic> plate,
  String monthBranch,
  String dayBranch,
) {
  List<Map<String, dynamic>> contexts(
    String subject,
    List<(String, String)> observations,
  ) => [
    for (final observation in observations)
      {
        'role': observation.$1,
        'observed_branch': observation.$2,
        'growth': lookupPrivateBranchGrowth(subject, observation.$2),
      },
  ];

  final base = plate['base'] as Map<String, dynamic>;
  final baseLines = (base['lines'] as List).cast<Map<String, dynamic>>();
  final changed = plate['changed'] as Map<String, dynamic>?;
  final changedLines = changed == null
      ? <Map<String, dynamic>>[]
      : (changed['lines'] as List).cast<Map<String, dynamic>>();
  final moving = (plate['moving_positions'] as List).cast<int>().toSet();
  final hiddenRows = <Map<String, dynamic>>[];
  final baseRows = <Map<String, dynamic>>[];
  for (final line in baseLines) {
    final position = line['position'] as int;
    final observations = <(String, String)>[
      ('month', monthBranch),
      ('day', dayBranch),
      if (moving.contains(position))
        ('changed', changedLines[position - 1]['branch'] as String),
    ];
    baseRows.add({
      'position': position,
      'ganzhi': '${line['stem']}${line['branch']}',
      'relation': line['relation'],
      'subject': {'branch': line['branch'], 'element': line['element']},
      'contexts': contexts(line['branch'] as String, observations),
    });
    for (final hidden
        in (line['hidden_spirits'] as List).cast<Map<String, dynamic>>()) {
      hiddenRows.add({
        'position': position,
        'ganzhi': '${hidden['stem']}${hidden['branch']}',
        'relation': hidden['relation'],
        'subject': {'branch': hidden['branch'], 'element': hidden['element']},
        'contexts': contexts(hidden['branch'] as String, [
          ('month', monthBranch),
          ('day', dayBranch),
          ('flying', line['branch'] as String),
        ]),
      });
    }
  }
  return {
    'enabled': true,
    'profile': privateGrowthProfile,
    'base_lines': baseRows,
    'changed_lines': [
      for (final line in changedLines)
        {
          'position': line['position'],
          'ganzhi': '${line['stem']}${line['branch']}',
          'relation': line['relation'],
          'subject': {'branch': line['branch'], 'element': line['element']},
          'contexts': contexts(line['branch'] as String, [
            ('month', monthBranch),
            ('day', dayBranch),
          ]),
        },
    ],
    'hidden_spirits': hiddenRows,
    'interpretation_decision': null,
  };
}

Map<String, dynamic> _analyzeLineContext(
  String subjectBranch,
  String monthBranch,
  String dayBranch,
  List<String> voidBranches,
) {
  final subjectElement = branchElements[subjectBranch]!;
  final contexts = <Map<String, dynamic>>[];
  for (final observation in [('month', monthBranch), ('day', dayBranch)]) {
    final actorElement = branchElements[observation.$2]!;
    final element = lookupPrivateElementRelation(subjectElement, actorElement);
    final branch = lookupPrivateBranchRelation(subjectBranch, observation.$2);
    final branchRelation = branch['relation'] as String;
    final candidateTag = switch (branchRelation) {
      'same_branch' => 'lin_${observation.$1}',
      'six_harmony' => '${observation.$1}_harmony',
      'six_clash' => '${observation.$1}_clash_candidate',
      _ => null,
    };
    contexts.add({
      'role': observation.$1,
      'actor': {'branch': observation.$2, 'element': actorElement},
      'element_relation': element['relation'],
      'branch_relation': branchRelation,
      'candidate_tag': candidateTag,
      'rule_ids': [
        element['rule_id'],
        if (branch['rule_id'] != null) branch['rule_id'],
      ],
    });
  }
  return {
    'profile': privateRelationshipProfile,
    'subject': {'branch': subjectBranch, 'element': subjectElement},
    'contexts': contexts,
    'is_xun_kong': voidBranches.contains(subjectBranch),
    'xun_kong_evidence': {
      'void_branches': List<String>.from(voidBranches),
      'rule_id': 'xun-kong.membership',
    },
  };
}

const _progressionPairs = {'亥子', '寅卯', '巳午', '申酉', '丑辰', '辰未', '未戌'};
const _retreatPairs = {'子亥', '卯寅', '午巳', '酉申', '辰丑', '未辰', '戌未'};
const _movingElementTags = {
  'actor_generates_subject': 'return_generates_base',
  'actor_controls_subject': 'return_controls_base',
  'subject_generates_actor': 'base_generates_changed',
  'subject_controls_actor': 'base_controls_changed',
  'same_element': 'same_element',
};
const _movingBranchTags = {
  'six_harmony': 'change_harmony',
  'six_clash': 'change_clash',
  'same_branch': 'same_branch',
};
const _flyingHiddenTags = {
  'actor_generates_subject': 'flying_generates_hidden',
  'actor_controls_subject': 'flying_controls_hidden',
  'subject_generates_actor': 'hidden_generates_flying',
  'subject_controls_actor': 'hidden_controls_flying',
  'same_element': 'same_element',
};

Map<String, dynamic> _classifyMovingChange(String base, String changed) {
  final element = lookupPrivateElementRelation(
    branchElements[base]!,
    branchElements[changed]!,
  );
  final branch = lookupPrivateBranchRelation(base, changed);
  final pair = '$base$changed';
  final progression = _progressionPairs.contains(pair);
  final retreat = _retreatPairs.contains(pair);
  final tags = <String>[
    if (progression) 'progress_candidate',
    if (retreat) 'retreat_candidate',
    _movingElementTags[element['relation']]!,
    if (_movingBranchTags.containsKey(branch['relation']))
      _movingBranchTags[branch['relation']]!,
  ];
  return {
    'profile': privateMovingProfile,
    'base': {'branch': base, 'element': branchElements[base]},
    'changed': {'branch': changed, 'element': branchElements[changed]},
    'element_relation': element,
    'branch_relation': branch,
    'progression_candidate': progression,
    'retreat_candidate': retreat,
    'directional_tags': tags,
    'rule_ids': [
      if (progression) 'moving-change.progression',
      if (retreat) 'moving-change.retreat',
      element['rule_id'],
      if (branch['rule_id'] != null) branch['rule_id'],
    ],
    'effect_decision': null,
  };
}

Map<String, dynamic> _classifyFlyingHidden(String flying, String hidden) {
  // Source helper describes actor=flying and subject=hidden.
  final relation = lookupPrivateElementRelation(
    branchElements[hidden]!,
    branchElements[flying]!,
  );
  return {
    'profile': privateRelationshipProfile,
    'flying': {'branch': flying, 'element': branchElements[flying]},
    'hidden': {'branch': hidden, 'element': branchElements[hidden]},
    'element_relation': relation,
    'tag': _flyingHiddenTags[relation['relation']],
    'rule_ids': [relation['rule_id'], 'hidden-spirit.same-position'],
    'effect_decision': null,
  };
}

Map<String, dynamic> _mechanicalRelations(
  Map<String, dynamic> plate,
  String monthBranch,
  String dayBranch,
  List<String> voidBranches,
) {
  final base = plate['base'] as Map<String, dynamic>;
  final baseLines = (base['lines'] as List).cast<Map<String, dynamic>>();
  final changed = plate['changed'] as Map<String, dynamic>?;
  final changedLines = changed == null
      ? <Map<String, dynamic>>[]
      : (changed['lines'] as List).cast<Map<String, dynamic>>();
  final moving = (plate['moving_positions'] as List).cast<int>();
  return {
    'profile': privateRelationshipProfile,
    'base_line_contexts': [
      for (final line in baseLines)
        {
          'position': line['position'],
          ..._analyzeLineContext(
            line['branch'] as String,
            monthBranch,
            dayBranch,
            voidBranches,
          ),
        },
    ],
    'moving_line_changes': [
      for (final position in moving)
        {
          'position': position,
          'subject': {
            'branch': baseLines[position - 1]['branch'],
            'element': baseLines[position - 1]['element'],
          },
          'actor': {
            'branch': changedLines[position - 1]['branch'],
            'element': changedLines[position - 1]['element'],
          },
          'element_relation': lookupPrivateElementRelation(
            baseLines[position - 1]['element'] as String,
            changedLines[position - 1]['element'] as String,
          ),
          'branch_relation': lookupPrivateBranchRelation(
            baseLines[position - 1]['branch'] as String,
            changedLines[position - 1]['branch'] as String,
          ),
          'change_candidates': _classifyMovingChange(
            baseLines[position - 1]['branch'] as String,
            changedLines[position - 1]['branch'] as String,
          ),
        },
    ],
    'hidden_spirit_relations': [
      for (final line in baseLines)
        for (final hidden
            in (line['hidden_spirits'] as List).cast<Map<String, dynamic>>())
          {
            'position': line['position'],
            'flying': {
              'stem': line['stem'],
              'branch': line['branch'],
              'element': line['element'],
              'relation': line['relation'],
            },
            'hidden': Map<String, dynamic>.from(hidden),
            'classification': _classifyFlyingHidden(
              line['branch'] as String,
              hidden['branch'] as String,
            ),
          },
    ],
  };
}

const _privateTianyi = {
  '甲': ['丑', '未'],
  '戊': ['丑', '未'],
  '庚': ['丑', '未'],
  '乙': ['子', '申'],
  '己': ['子', '申'],
  '丙': ['亥', '酉'],
  '丁': ['亥', '酉'],
  '壬': ['卯', '巳'],
  '癸': ['卯', '巳'],
  '辛': ['寅', '午'],
};
const _privateLushen = {
  '甲': '寅',
  '乙': '卯',
  '丙': '巳',
  '丁': '午',
  '戊': '巳',
  '己': '午',
  '庚': '申',
  '辛': '酉',
  '壬': '亥',
  '癸': '子',
};
const _dayGroupMarkers = {
  '申子辰': {'驿马': '寅', '桃花': '酉', '华盖': '辰'},
  '寅午戌': {'驿马': '申', '桃花': '卯', '华盖': '戌'},
  '巳酉丑': {'驿马': '亥', '桃花': '午', '华盖': '丑'},
  '亥卯未': {'驿马': '巳', '桃花': '子', '华盖': '未'},
};

Map<String, dynamic> _shenshaExtension(
  Map<String, dynamic> plate,
  String dayGanzhi,
) {
  final stem = dayGanzhi[0];
  final branch = dayGanzhi[1];
  final group = _dayGroupMarkers.entries.firstWhere(
    (entry) => entry.key.contains(branch),
  );
  final candidates = <Map<String, dynamic>>[
    for (final entry in group.value.entries)
      {
        'name': entry.key,
        'branches': [entry.value],
        'candidate_semantics': 'single_table_branch',
      },
    {
      'name': '天乙贵人',
      'branches': List<String>.from(_privateTianyi[stem]!),
      'candidate_semantics':
          'union_of_yang_and_yin_candidates_without_day_night_selection',
      'lineage': 'jia_wu_geng_niu_yang_and_liu_xin_ma_hu',
    },
    {
      'name': '禄神',
      'branches': [_privateLushen[stem]!],
      'candidate_semantics': 'single_day_stem_table_branch',
    },
  ];
  final base = plate['base'] as Map<String, dynamic>;
  final baseLines = (base['lines'] as List).cast<Map<String, dynamic>>();
  final changed = plate['changed'] as Map<String, dynamic>?;
  final changedLines = changed == null
      ? <Map<String, dynamic>>[]
      : (changed['lines'] as List).cast<Map<String, dynamic>>();
  for (final candidate in candidates) {
    final branches = (candidate['branches'] as List).cast<String>().toSet();
    candidate['matches'] = {
      'base_line_positions': [
        for (final line in baseLines)
          if (branches.contains(line['branch'])) line['position'],
      ],
      'changed_line_positions': [
        for (final line in changedLines)
          if (branches.contains(line['branch'])) line['position'],
      ],
      'hidden_spirits': [
        for (final line in baseLines)
          for (final hidden
              in (line['hidden_spirits'] as List).cast<Map<String, dynamic>>())
            if (branches.contains(hidden['branch']))
              {
                'position': line['position'],
                'ganzhi': '${hidden['stem']}${hidden['branch']}',
                'relation': hidden['relation'],
              },
      ],
    };
  }
  final shiPosition = base['shi_position'] as int;
  final shi = baseLines[shiPosition - 1];
  final shiBranch = shi['branch'] as String;
  final shiYinYang = shi['yin_yang'] as String;
  const shishenPositions = {
    '子': 1,
    '午': 1,
    '丑': 2,
    '未': 2,
    '寅': 3,
    '申': 3,
    '卯': 4,
    '酉': 4,
    '辰': 5,
    '戌': 5,
    '巳': 6,
    '亥': 6,
  };
  const mingyaoPositions = {
    '卯': 1,
    '酉': 1,
    '辰': 2,
    '未': 2,
    '巳': 3,
    '亥': 3,
    '午': 4,
    '子': 4,
    '丑': 5,
    '戌': 5,
    '寅': 6,
    '申': 6,
  };
  const yangMonthBody = ['子', '丑', '寅', '卯', '辰', '巳'];
  const yinMonthBody = ['午', '未', '申', '酉', '戌', '亥'];
  final monthBodyBranch = (shiYinYang == '阳'
      ? yangMonthBody
      : yinMonthBody)[shiPosition - 1];
  final monthBodyPositions = [
    for (final line in baseLines)
      if (line['branch'] == monthBodyBranch) line['position'],
  ];
  return {
    'enabled': true,
    'profile': privateShenshaProfile,
    'day_ganzhi': dayGanzhi,
    'candidates': candidates,
    'body_markers': {
      'profile': privateShenshaProfile,
      'shi_line': {
        'position': shiPosition,
        'branch': shiBranch,
        'yin_yang': shiYinYang,
      },
      'shishen': {
        'position': shishenPositions[shiBranch],
        'basis': 'shi_line_branch',
        'source_status': 'historically_attested_but_explicitly_disputed',
      },
      'month_hexagram_body': {
        'branch': monthBodyBranch,
        'positions': monthBodyPositions,
        'present_in_base_hexagram': monthBodyPositions.isNotEmpty,
        'basis': 'shi_line_yin_yang_and_position',
        'match_semantics': 'all_base_line_positions_with_target_branch',
        'source_status': 'historically_attested_selected_method',
      },
      'mingyao': {
        'position': mingyaoPositions[shiBranch],
        'basis': 'shi_line_branch',
        'variant_id':
            'maosi_one_chenwei_two_sihai_three_wuzi_four_chouxu_five_yinshen_six',
        'source_status':
            'selected_transmitted_variant_with_documented_variants',
      },
      'interpretation_decision': null,
    },
    'interpretation_enabled': false,
    'interpretation_decision': null,
  };
}

Map<String, dynamic> _nayinExtension(
  Map<String, dynamic> plate,
  Map<String, Map<String, String>> pillars,
) {
  Map<String, dynamic> lookup(String ganzhi) => {
    'ganzhi': ganzhi,
    'name': getNayin(ganzhi),
    'aliases': switch (getNayin(ganzhi)) {
      '路旁土' => ['路傍土'],
      '白蜡金' => ['白鑞金'],
      '泉中水' => ['井泉水'],
      '沙中金' => ['砂中金'],
      '覆灯火' => ['佛灯火'],
      '沙中土' => ['砂中土'],
      _ => <String>[],
    },
  };
  final base = plate['base'] as Map<String, dynamic>;
  final changed = plate['changed'] as Map<String, dynamic>?;
  List<Map<String, dynamic>> lineRows(Map<String, dynamic> hexagram) => [
    for (final line in (hexagram['lines'] as List).cast<Map<String, dynamic>>())
      {
        'position': line['position'],
        ...lookup('${line['stem']}${line['branch']}'),
      },
  ];
  return {
    'enabled': true,
    'spec_version': privateSpecVersion,
    'calendar_pillars': {
      for (final role in const ['year', 'month', 'day', 'hour'])
        role: {'status': 'resolved', ...lookup(pillars[role]!['gan_zhi']!)},
    },
    'base_lines': lineRows(base),
    'changed_lines': changed == null ? [] : lineRows(changed),
  };
}

/// Build the ported private-reference contract from the product's canonical
/// chart.  The result is embedded verbatim in every new archive snapshot.
Map<String, dynamic> buildPrivateReferenceContract({
  required List<int> lines,
  required DateTime timestamp,
  required Map<String, dynamic> almanac,
  required Map<String, dynamic> chart,
  required Map<String, Map<String, String>> pillars,
  required List<String> dayVoidBranches,
  required String method,
}) {
  final dayGanzhi = pillars['day']!['gan_zhi']!;
  final plate = _plateFromProduct(lines, chart, dayGanzhi, dayVoidBranches);
  final providerExtensions =
      almanac['provider_extensions'] as Map<String, dynamic>;
  final solarTerms = almanac['solar_terms'] as Map<String, dynamic>;
  final lunar = almanac['lunar'] as Map<String, dynamic>;
  final localTimestamp = formatShanghaiInstantIso(timestamp);
  final lunarMonthDays = lunarMonthLength(
    lunar['year'] as int,
    lunar['month'] as int,
    isLeapMonth: lunar['is_leap_month'] as bool,
  );
  final calendar = {
    'provider': 'cnlunar',
    'provider_version': '0.2.0',
    'provider_revision': '1d7f868967cc533c9b577ed0c3ffb3cb67bb5352',
    'solar_term_provider': 'lunar_python',
    'solar_term_provider_version': exactJieProviderVersion,
    'solar_term_provider_revision': exactJieProviderRevision,
    'profile': privateProfileId,
    // Dart DateTime retains the instant but not the source offset text. Both
    // fields therefore use the normalized Asia/Shanghai representation.
    'original_timestamp': localTimestamp,
    'local_timestamp': localTimestamp,
    'timezone': 'Asia/Shanghai',
    'tzdata_version': '2025.3',
    // Executable cnlunar behavior advances day8Char at 23:00.  This field is
    // intentionally truthful even though liuyao-private's draft JSON says
    // `civil_midnight`; see the local conflict audit.
    'day_boundary': 'zi_initial_23_cnlunar_compat',
    'boundary_precision': 'second',
    'year_ganzhi': pillars['year']!['gan_zhi'],
    'month_ganzhi': pillars['month']!['gan_zhi'],
    'month_branch': pillars['month']!['branch'],
    'month_branch_status': 'resolved',
    'day_ganzhi': dayGanzhi,
    'hour_ganzhi': pillars['hour']!['gan_zhi'],
    'xun_kong': List<String>.from(dayVoidBranches),
    'lunar_date': {
      'year': lunar['year'],
      'month': lunar['month'],
      'day': lunar['day'],
      'is_leap_month': lunar['is_leap_month'],
      'month_cn': '${lunar['month_cn']}${lunarMonthDays == 30 ? '大' : '小'}',
      'day_cn': lunar['day_cn'],
    },
    'solar_term_transition': solarTerms['transition_name'],
    'solar_term_transition_at': solarTerms['transition_at'],
    'solar_term_transition_relation': solarTerms['transition_relation'],
    'provider_extensions': providerExtensions,
    'provider_raw': almanac['provider_raw'],
  };
  return {
    'spec_version': privateSpecVersion,
    'profile': privateProfileId,
    'source_revision': privateReferenceRevision,
    'port_language': 'Dart',
    'casting_provenance': {
      'method': method == 'manual' ? 'manual_lines' : 'three_coin',
      'lines_bottom_up': List<int>.from(lines),
    },
    'request_context': <String, dynamic>{},
    'calendar': calendar,
    'plate': plate,
    'mechanical_relations': _mechanicalRelations(
      plate,
      pillars['month']!['branch']!,
      pillars['day']!['branch']!,
      dayVoidBranches,
    ),
    'extensions': {
      'nayin': _nayinExtension(plate, pillars),
      'twelve_growth': _growthExtension(
        plate,
        pillars['month']!['branch']!,
        pillars['day']!['branch']!,
      ),
      'shensha': _shenshaExtension(plate, dayGanzhi),
    },
    'focus_context': null,
  };
}
