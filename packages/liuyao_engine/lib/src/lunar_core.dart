/// 农历核心算法（纯 Dart 实现，无需后端服务）
///
/// 基于 cnlunar 1901-2099 月份数据表实现公历转农历。
/// 支持产品合同 1901-02-19 至 2100-02-08。

library;

import 'solar_terms.dart';

/// ============================================================================
/// 农历数据表（cnlunar.config.lunarMonthData，1901-2099）
/// bits 0..11 为正月到腊月大小，bit 12 为闰月大小，bits 13..16 为闰月。
/// ============================================================================

const String _encodedLunarMonthData =
    '752,ea5,ab2a,64b,a9b,9aa6,56a,b59,4baa,752,cda5,b25,a4b,ba4b,2ad,56b,45b5,da9,fe92,e92,d25,ad2d,a56,2b6,9ad5,6d4,ea9,4f4a,e92,c6a6,52b,a57,b956,b5a,6d4,7761,749,fb13,a93,52b,d51b,aad,56a,9da5,ba4,b49,4d4b,a95,eaad,536,aad,baca,5b2,da5,7ea2,d4a,10595,a97,556,c575,ad5,6d2,8755,ea5,64a,664f,a9b,eada,56a,b69,abb2,b52,b25,8b2b,a4b,10aab,2ad,56d,d5a9,da9,d92,8e95,d25,14e4d,a56,2b6,c2f5,6d5,ea9,af52,e92,d26,652e,a57,10ad6,35a,6d5,ab69,749,693,8a9b,52b,a5b,4aae,56a,edd5,ba4,b49,ad53,a95,52d,855d,ab5,12baa,5d2,da5,de8a,d4a,c95,8a9e,556,ab5,4ada,6d2,c765,725,64b,a657,cab,55a,656e,b69,16f52,b52,b25,dd0b,a4b,4ab,a2bb,5ad,b6a,4daa,d92,eea5,d25,a55,ba4d,4b6,5b5,76d2,ec9,10f92,e92,d26,d516,a57,556,9365,755,749,674b,693,eaab,52b,a5b,aaba,56a,b65,8baa,b4a,10d95,a95,52d,c56d,ab5,5aa,85d5,da5,d4a,6e4d,c96,ecce,556,ab5,bad2,6d2,ea5,872a,68b,10697,4ab,55b,d556,b6a,752,8b95,b45,a8b,4a4f';

final List<int> _lunarMonthData = _encodedLunarMonthData
    .split(',')
    .map((value) => int.parse(value, radix: 16))
    .toList(growable: false);

/// 生肖
const List<String> zodiacAnimals = [
  '鼠',
  '牛',
  '虎',
  '兔',
  '龙',
  '蛇',
  '马',
  '羊',
  '猴',
  '鸡',
  '狗',
  '猪',
];

/// 农历月中文
const List<String> _lunarMonthCn = [
  '正月',
  '二月',
  '三月',
  '四月',
  '五月',
  '六月',
  '七月',
  '八月',
  '九月',
  '十月',
  '冬月',
  '腊月',
];

/// 农历日中文
const List<String> _lunarDayCn = [
  '初一',
  '初二',
  '初三',
  '初四',
  '初五',
  '初六',
  '初七',
  '初八',
  '初九',
  '初十',
  '十一',
  '十二',
  '十三',
  '十四',
  '十五',
  '十六',
  '十七',
  '十八',
  '十九',
  '二十',
  '廿一',
  '廿二',
  '廿三',
  '廿四',
  '廿五',
  '廿六',
  '廿七',
  '廿八',
  '廿九',
  '三十',
];

/// 农历日期结构
class LunarDate {
  final int year;
  final int month;
  final int day;
  final bool isLeapMonth;
  final String monthCn;
  final String dayCn;
  final String? yearCn;
  final String? zodiac;

  const LunarDate({
    required this.year,
    required this.month,
    required this.day,
    required this.isLeapMonth,
    required this.monthCn,
    required this.dayCn,
    this.yearCn,
    this.zodiac,
  });

  Map<String, dynamic> toJson() => {
    'year': year,
    'month': month,
    'day': day,
    'is_leap_month': isLeapMonth,
    'month_cn': monthCn,
    'day_cn': dayCn,
    'year_cn': yearCn,
    'zodiac': zodiac,
  };
}

/// ============================================================================
/// 数据表解码
/// ============================================================================

/// 某农历年闰月月份（0=无闰月）
int _leapMonth(int lunarYear) {
  return (_lunarMonthData[lunarYear - 1901] >> 13) & 0xf;
}

/// 某农历年闰月天数（29 或 30）
int _leapDays(int lunarYear) {
  if (_leapMonth(lunarYear) == 0) return 0;
  return (_lunarMonthData[lunarYear - 1901] & (1 << 12)) != 0 ? 30 : 29;
}

/// 某农历年某月（1-12）天数（29 或 30）
int _monthDays(int lunarYear, int month) {
  return (_lunarMonthData[lunarYear - 1901] & (1 << (month - 1))) != 0
      ? 30
      : 29;
}

/// Return the length of a regular or leap lunar month in the frozen cnlunar
/// table.  This is exposed for reference-contract serialization only.
int lunarMonthLength(int lunarYear, int month, {bool isLeapMonth = false}) {
  if (lunarYear < 1901 || lunarYear > 2099) {
    throw RangeError.range(lunarYear, 1901, 2099, 'lunarYear');
  }
  if (month < 1 || month > 12) {
    throw RangeError.range(month, 1, 12, 'month');
  }
  if (isLeapMonth) {
    if (_leapMonth(lunarYear) != month) {
      throw ArgumentError('$lunarYear 年没有闰 $month 月');
    }
    return _leapDays(lunarYear);
  }
  return _monthDays(lunarYear, month);
}

/// 某农历年总天数（含闰月）
int _yearDays(int lunarYear) {
  var sum = 0;
  for (var month = 1; month <= 12; month++) {
    sum += _monthDays(lunarYear, month);
  }
  return sum + _leapDays(lunarYear);
}

/// 生肖
String _zodiac(int year) {
  // 以正月初一为界，此处用农历年
  return zodiacAnimals[(year - 4) % 12];
}

String _yearChinese(int year) {
  const digits = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九'];
  return year
      .toString()
      .split('')
      .map((item) => digits[int.parse(item)])
      .join();
}

/// ============================================================================
/// 公历 → 农历（核心算法）
/// ============================================================================

/// 公历转农历
/// 返回农历年月日（含闰月标记）与中文表示
LunarDate solarToLunar(DateTime solarDate) {
  // cnlunar 支持区间起点：1901-02-19 = 农历辛丑年正月初一。
  final baseDate = DateTime.utc(1901, 2, 19);
  // 农历换算只读取用户看到的公历年月日，不把 DateTime 当作绝对瞬间。
  // 否则在 UTC+8 设备上，本地午夜与 UTC 基准相减会被截到前一天。
  final calendarDate = DateTime.utc(
    solarDate.year,
    solarDate.month,
    solarDate.day,
  );
  int offset = calendarDate.difference(baseDate).inDays;

  if (offset < 0) {
    throw RangeError('农历仅支持 1901-02-19 至 2100-02-08');
  }

  // 逐年扣减，定位农历年
  int lunarYear = 1901;
  int yearDays;
  for (; lunarYear < 2100 && offset > 0; lunarYear++) {
    yearDays = _yearDays(lunarYear);
    if (offset < yearDays) break;
    offset -= yearDays;
  }

  // 把正常月与闰月显式展开为有序段，避免离开闰月后月份状态回退。
  final leap = _leapMonth(lunarYear);
  final segments = <({int month, bool isLeap, int days})>[];
  for (var month = 1; month <= 12; month++) {
    segments.add((
      month: month,
      isLeap: false,
      days: _monthDays(lunarYear, month),
    ));
    if (month == leap) {
      segments.add((month: month, isLeap: true, days: _leapDays(lunarYear)));
    }
  }
  var lunarMonth = 1;
  var isLeap = false;
  for (final segment in segments) {
    lunarMonth = segment.month;
    isLeap = segment.isLeap;
    if (offset < segment.days) break;
    offset -= segment.days;
  }

  // offset 为 0 的边界处理（当月第 1 天）
  int lunarDay = offset + 1;

  // 确保月名索引合法
  final displayMonth = isLeap ? lunarMonth : lunarMonth;
  final monthCnIndex = (displayMonth - 1).clamp(0, 11);
  final dayCnIndex = (lunarDay - 1).clamp(0, 29);

  return LunarDate(
    year: lunarYear,
    month: lunarMonth,
    day: lunarDay,
    isLeapMonth: isLeap,
    monthCn: isLeap
        ? '闰${_lunarMonthCn[monthCnIndex]}'
        : _lunarMonthCn[monthCnIndex],
    dayCn: _lunarDayCn[dayCnIndex],
    yearCn: _yearChinese(lunarYear),
    zodiac: _zodiac(lunarYear),
  );
}

/// 获取指定日期的节气（如果有），否则 null
String? getSolarTerm(DateTime date) {
  return solarTermSnapshot(date).today;
}

/// 日期范围验证
bool isLunarSupported(DateTime date) {
  final value = DateTime.utc(date.year, date.month, date.day);
  final start = DateTime.utc(1901, 2, 19);
  final end = DateTime.utc(2100, 2, 8);
  return !value.isBefore(start) && !value.isAfter(end);
}
