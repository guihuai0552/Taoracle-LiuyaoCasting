/// cnlunar 1901—2100 二十四节气压缩表的纯 Dart 解码。
///
/// 数据与 OPN48/cnlunar `config.SOLAR_TERMS_DATA_LIST` 逐项一致；每年
/// 48 bit，以每个节气 2 bit 的增量叠加 `solarTermMinimumDays`。

library;

const int solarTermStartYear = 1901;
const int solarTermEndYear = 2100;

const List<String> solarTermNames = [
  '小寒',
  '大寒',
  '立春',
  '雨水',
  '惊蛰',
  '春分',
  '清明',
  '谷雨',
  '立夏',
  '小满',
  '芒种',
  '夏至',
  '小暑',
  '大暑',
  '立秋',
  '处暑',
  '白露',
  '秋分',
  '寒露',
  '霜降',
  '立冬',
  '小雪',
  '大雪',
  '冬至',
];

const List<int> solarTermMinimumDays = [
  4,
  19,
  3,
  18,
  4,
  19,
  4,
  19,
  4,
  20,
  4,
  20,
  6,
  22,
  6,
  22,
  6,
  22,
  7,
  22,
  6,
  21,
  6,
  21,
];

// 使用字符串承载 200 个 48-bit 值，避免在 32-bit Web 编译目标上损失精度。
const String _encodedSolarTerms =
    '6aaaa6aa9a5a,aaaaaabaaa6a,aaabbabbafaa,5aa665a65aab,6aaaa6aa9a5a,aaaaaaaaaa6a,aaabbabbafaa,5aa665a65aab,6aaaa6aa9a5a,aaaaaaaaaa6a,aaabbabbafaa,5aa665a65aab,6aaaa6aa9a56,aaaaaaaa9a5a,aaabaabaaeaa,569665a65aaa,5aa6a6a69a56,6aaaaaaa9a5a,aaabaabaaeaa,569665a65aaa,5aa6a6a65a56,6aaaaaaa9a5a,aaabaabaaa6a,569665a65aaa,5aa6a6a65a56,6aaaa6aa9a5a,aaaaaabaaa6a,555665665aaa,5aa665a65a56,6aaaa6aa9a5a,aaaaaabaaa6a,555665665aaa,5aa665a65a56,6aaaa6aa9a5a,aaaaaaaaaa6a,555665665aaa,5aa665a65a56,6aaaa6aa9a5a,aaaaaaaaaa6a,555665665aaa,5aa665a65a56,6aaaa6aa9a5a,aaaaaaaaaa6a,555665655aaa,569665a65a56,6aa6a6aa9a56,aaaaaaaa9a5a,5556556559aa,569665a65a55,6aa6a6a65a56,aaaaaaaa9a5a,5556556559aa,569665a65a55,5aa6a6a65a56,6aaaa6aa9a5a,5556556555aa,569665a65a55,5aa665a65a56,6aaaa6aa9a5a,55555565556a,555665665a55,5aa665a65a56,6aaaa6aa9a5a,55555565556a,555665665a55,5aa665a65a56,6aaaa6aa9a5a,55555555556a,555665665a55,5aa665a65a56,6aaaa6aa9a5a,55555555556a,555665655a55,5aa665a65a56,6aa6a6aa9a5a,55555555456a,555655655a55,5a9665a65a56,6aa6a6a69a5a,55555555456a,555655655a55,569665a65a56,6aa6a6a65a56,55555155455a,555655655955,569665a65a55,5aa6a5a65a56,15555155455a,555555655555,569665665a55,5aa665a65a56,15555155455a,555555655515,555665665a55,5aa665a65a56,15555155455a,555555555515,555665665a55,5aa665a65a56,15555155455a,555555555515,555665665a55,5aa665a65a56,15555155455a,555555555515,555655655a55,5aa665a65a56,15515155455a,555555554515,555655655a55,5a9665a65a56,15515151455a,555551554515,555655655a55,569665a65a56,155151510556,555551554505,555655655955,569665665a55,155110510556,155551554505,555555655555,569665665a55,55110510556,155551554505,555555555515,555665665a55,55110510556,155551554505,555555555515,555665665a55,55110510556,155551554505,555555555515,555655655a55,55110510556,155551554505,555555555515,555655655a55,55110510556,155151514505,555555554515,555655655a55,54110510556,155151510505,555551554515,555655655a55,14110110556,155110510501,555551554505,555555655555,14110110555,155110510501,555551554505,555555555555,14110110555,55110510501,155551554505,555555555555,110110555,55110510501,155551554505,555555555515,110110555,55110510501,155551554505,555555555515,100100555,55110510501,155151514505,555555555515,100100555,54110510501,155151514505,555551554515,100100555,54110510501,155150510505,555551554515,100100555,14110110501,155110510505,555551554505,100055,14110110500,155110510501,555551554505,55,14110110500,55110510501,155551554505,55,110110500,55110510501,155551554505,15,100110500,55110510501,155551554505,555555555515';

List<int> solarTermDaysForYear(int year) {
  if (year < solarTermStartYear || year > solarTermEndYear) {
    throw RangeError.range(year, solarTermStartYear, solarTermEndYear, 'year');
  }
  final encoded = BigInt.parse(
    _encodedSolarTerms.split(',')[year - solarTermStartYear],
    radix: 16,
  );
  final deltas = <int>[];
  for (var index = 0; index < 24; index++) {
    final shift = 2 * index;
    deltas.add(((encoded >> shift) & BigInt.from(3)).toInt());
  }
  return List.generate(
    24,
    (index) => solarTermMinimumDays[index] + deltas[index],
    growable: false,
  );
}

class SolarTermSnapshot {
  const SolarTermSnapshot({
    required this.today,
    required this.nextName,
    required this.nextDate,
    required this.nextIndex,
  });

  final String? today;
  final String nextName;
  final DateTime nextDate;
  final int nextIndex;
}

SolarTermSnapshot solarTermSnapshot(DateTime date) {
  final days = solarTermDaysForYear(date.year);
  String? today;
  var nextIndex = 0;
  DateTime? nextDate;
  for (var index = 0; index < 24; index++) {
    final candidate = DateTime.utc(date.year, index ~/ 2 + 1, days[index]);
    if (candidate.year == date.year &&
        candidate.month == date.month &&
        candidate.day == date.day) {
      today = solarTermNames[index];
    }
    if (candidate.isAfter(DateTime.utc(date.year, date.month, date.day))) {
      nextIndex = index;
      nextDate = candidate;
      break;
    }
  }
  if (nextDate == null) {
    nextIndex = 0;
    nextDate = DateTime.utc(
      date.year + 1,
      1,
      solarTermDaysForYear(date.year + 1)[0],
    );
  }
  return SolarTermSnapshot(
    today: today,
    nextName: solarTermNames[nextIndex],
    nextDate: nextDate,
    nextIndex: nextIndex,
  );
}
