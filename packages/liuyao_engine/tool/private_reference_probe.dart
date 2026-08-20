import 'dart:convert';

import 'package:liuyao_engine/liuyao_engine.dart';

Map<String, dynamic> _staticCase(int mask) {
  final lines = List.generate(
    6,
    (index) => (mask & (1 << index)) == 0 ? 8 : 7,
    growable: false,
  );
  final result = manualCast(DateTime.parse('2026-08-04T22:22:29+08:00'), lines);
  final reference =
      result['private_reference_contract'] as Map<String, dynamic>;
  return {'mask': mask, 'lines': lines, 'plate': reference['plate']};
}

Map<String, dynamic> _calendarCase(String timestamp) {
  final almanac = calculateAlmanac(DateTime.parse(timestamp));
  final pillars = (almanac['four_pillars'] as List)
      .map((item) => item['ganzhi'])
      .toList(growable: false);
  return {
    'timestamp': timestamp,
    'pillars': pillars,
    'day_void_branches': almanac['day_void_branches'],
    'solar_terms': almanac['solar_terms'],
    'daily_mansion':
        ((almanac['provider_extensions'] as Map)['twenty_eight_mansion']
            as Map)['name'],
  };
}

Map<String, dynamic> _jieBoundaryCase(int year, int index, DateTime wall) {
  final instant = shanghaiWallClockToUtc(wall);
  final before = calculateExactJieContext(
    instant.subtract(const Duration(seconds: 1)),
  );
  final at = calculateExactJieContext(instant);
  return {
    'year': year,
    'index': index,
    'wall_clock': wall.toIso8601String(),
    'before': [before.yearGanzhi, before.monthGanzhi],
    'at': [at.yearGanzhi, at.monthGanzhi],
  };
}

void main() {
  const calendarTimestamps = [
    '2026-02-04T04:02:07+08:00',
    '2026-02-04T04:02:08+08:00',
    '2026-08-04T22:22:29+08:00',
    '2026-08-04T23:00:00+08:00',
    '2026-08-07T19:42:42+08:00',
    '2026-08-07T19:42:43+08:00',
    '1991-09-15T01:59:59+08:00',
  ];
  final output = {
    'static_hexagrams': [
      for (var mask = 0; mask < 64; mask++) _staticCase(mask),
    ],
    'growth': [
      for (final subject in '子丑寅卯辰巳午未申酉戌亥'.split(''))
        for (final observed in '子丑寅卯辰巳午未申酉戌亥'.split(''))
          lookupPrivateBranchGrowth(subject, observed),
    ],
    'nayin': {
      for (final ganzhi in the60HeavenlyEarth) ganzhi: getNayin(ganzhi),
    },
    'calendar': [for (final value in calendarTimestamps) _calendarCase(value)],
    'moving_sample':
        (manualCast(DateTime.parse('2026-08-04T22:22:29+08:00'), const [
              7,
              7,
              9,
              8,
              8,
              7,
            ])['private_reference_contract']
            as Map<String, dynamic>),
    'exact_jie_boundaries': [
      for (var year = 1901; year <= 2099; year++)
        for (final indexed in exactJieTermsForYear(year).indexed)
          _jieBoundaryCase(year, indexed.$1, indexed.$2),
    ],
  };
  print(jsonEncode(output));
}
