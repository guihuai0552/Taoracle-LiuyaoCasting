/// 万年历模块（cnlunar 完整移植）
/// 实现四柱计算、纳音、旬空、节气、财神方位
/// 支持日期范围：1901-02-19 至 2100-02-08

library;

import 'constants.dart';
import 'exact_jie_terms.dart';
import 'lunar_core.dart';
import 'solar_terms.dart';
import 'shanghai_time.dart';

const _monthBranchByJie = {
  '立春': '寅',
  '惊蛰': '卯',
  '清明': '辰',
  '立夏': '巳',
  '芒种': '午',
  '小暑': '未',
  '立秋': '申',
  '白露': '酉',
  '寒露': '戌',
  '立冬': '亥',
  '大雪': '子',
  '小寒': '丑',
};

/// ============================================================================
/// 交日、交月策略
///
/// 用户指定的默认口径（`civil_23_next_day` + `solar_term_zi_hour`）：
/// - 交日：前一天 23:00:00.001 起进入当日子时，日柱按第二天算。
///   即时刻“过 23:00:00.000 整点”即换日；23:00:00.000 整点仍属当日。
/// - 交月：进入当月节气的子时后切换到新月柱。
///   子时按上述换日规则，即节气日的前一天 23:00:00.001 起已属该节气月。
///
/// 另一套口径（`astronomical_midnight` + `astronomical_moment`）：
/// - 交日：子正 0 点换日，23:00–23:59 的夜子时仍用当日日柱。
/// - 交月：按节气的天文精确时刻切换月柱（lunar_python 1.4.8 口径）。
///
/// 两种口径都可主动选择，起卦/档案记录当时使用的策略，避免历史档案
/// 随全局设置变化而被无提示重算。
/// ============================================================================

const String dayBoundaryCivil23NextDay = 'civil_23_next_day';
const String dayBoundaryAstronomicalMidnight = 'astronomical_midnight';
const String monthBoundarySolarTermZiHour = 'solar_term_zi_hour';
const String monthBoundaryAstronomicalMoment = 'astronomical_moment';

const Map<String, String> dayBoundaryLabels = {
  dayBoundaryCivil23NextDay: '过23点（23:00:00.001）即换日，日柱按次日算',
  dayBoundaryAstronomicalMidnight: '子正0点换日，夜子时用当日日柱',
};

const Map<String, String> monthBoundaryLabels = {
  monthBoundarySolarTermZiHour: '进入当月节气的子时即换月',
  monthBoundaryAstronomicalMoment: '按节气天文精确时刻换月',
};

/// 某节气日（精确时刻所在日）的“子时换月边界”：
/// 节气日的前一天 23:00:00.001。进入该时刻即已属该节气月。
DateTime solarTermZiHourBoundary(DateTime exactJieMoment) {
  return DateTime.utc(
    exactJieMoment.year,
    exactJieMoment.month,
    exactJieMoment.day - 1,
    23,
    0,
    0,
    1,
  );
}

class ExactJieContext {
  const ExactJieContext({
    required this.yearGanzhi,
    required this.monthGanzhi,
    required this.monthBranch,
    required this.activeJie,
    required this.activeJieAt,
    required this.transitionName,
    required this.transitionAt,
    required this.transitionRelation,
  });

  final String yearGanzhi;
  final String monthGanzhi;
  final String monthBranch;
  final String activeJie;
  final DateTime activeJieAt;
  final String? transitionName;
  final DateTime? transitionAt;
  final String? transitionRelation;
}

DateTime _parseExactJie(String packed) => DateTime.utc(
  int.parse(packed.substring(0, 4)),
  int.parse(packed.substring(4, 6)),
  int.parse(packed.substring(6, 8)),
  int.parse(packed.substring(8, 10)),
  int.parse(packed.substring(10, 12)),
  int.parse(packed.substring(12, 14)),
);

List<DateTime> exactJieTermsForYear(int year) {
  if (year < exactJieStartYear || year > exactJieEndYear) {
    throw RangeError.range(year, exactJieStartYear, exactJieEndYear, 'year');
  }
  return exactJieWallClockRows[year - exactJieStartYear]
      .split(',')
      .map(_parseExactJie)
      .toList(growable: false);
}

/// Resolve year/month pillars with a selectable 交月 (month-boundary) policy.
///
/// DateTime.utc is deliberately used as a timezone-neutral container for the
/// Asia/Shanghai wall clock.  No UTC conversion is performed in this table.
///
/// - [monthBoundarySolarTermZiHour]: 进入当月节气的子时即换月（默认，用户指定）。
///   子时按 23:00:00.001 换日规则，即节气日的前一天 23:00:00.001 起已属该节气月。
///   年柱同样以立春子时（立春日前一天 23:00:00.001）为界换年，与月柱一致。
/// - [monthBoundaryAstronomicalMoment]: 按节气天文精确时刻切换月柱
///   （lunar_python 1.4.8 口径），年柱以立春精确时刻为界。
ExactJieContext calculateExactJieContext(
  DateTime date, {
  String monthBoundary = monthBoundarySolarTermZiHour,
}) {
  final wallClock = toShanghaiWallClock(date);
  if (wallClock.year < exactJieStartYear || wallClock.year > exactJieEndYear) {
    throw RangeError.range(
      wallClock.year,
      exactJieStartYear,
      exactJieEndYear,
      'year',
    );
  }
  final current = exactJieTermsForYear(wallClock.year);
  final moment = DateTime.utc(
    wallClock.year,
    wallClock.month,
    wallClock.day,
    wallClock.hour,
    wallClock.minute,
    wallClock.second,
    wallClock.millisecond,
    wallClock.microsecond,
  );
  final useZiHour = monthBoundary == monthBoundarySolarTermZiHour;

  var activeName = '大雪';
  late DateTime activeAt;
  if (useZiHour) {
    final firstBoundary = solarTermZiHourBoundary(current.first);
    if (moment.isBefore(firstBoundary)) {
      if (wallClock.year == exactJieStartYear) {
        // This only affects 1901-01-01..小寒.  The product lunar table starts at
        // 1901-02-19, but keeping the branch deterministic makes this helper
        // honest when used independently.
        activeAt = DateTime.utc(wallClock.year - 1, 12, 7);
      } else {
        activeAt = exactJieTermsForYear(wallClock.year - 1).last;
        activeName = exactJieNames.last;
      }
    } else {
      var index = 0;
      for (; index < current.length - 1; index++) {
        if (moment.isBefore(solarTermZiHourBoundary(current[index + 1]))) {
          break;
        }
      }
      activeAt = current[index];
      activeName = exactJieNames[index];
    }
  } else {
    if (moment.isBefore(current.first)) {
      if (wallClock.year == exactJieStartYear) {
        activeAt = DateTime.utc(wallClock.year - 1, 12, 7);
      } else {
        activeAt = exactJieTermsForYear(wallClock.year - 1).last;
      }
    } else {
      activeAt = current.first;
      activeName = exactJieNames.first;
      for (var index = 0; index < current.length; index++) {
        if (moment.isBefore(current[index])) break;
        activeAt = current[index];
        activeName = exactJieNames[index];
      }
    }
  }

  final liChun = current[1];
  final yearBoundaryMoment = useZiHour
      ? solarTermZiHourBoundary(liChun)
      : liChun;
  final pillarYear = moment.isBefore(yearBoundaryMoment)
      ? wallClock.year - 1
      : wallClock.year;
  final yearGanzhi = calculateYearGanzhi(pillarYear);
  final monthBranch = _monthBranchByJie[activeName]!;
  const branches = '子丑寅卯辰巳午未申酉戌亥';
  const stems = '甲乙丙丁戊己庚辛壬癸';
  const yinMonthStart = {
    '甲': 2,
    '己': 2,
    '乙': 4,
    '庚': 4,
    '丙': 6,
    '辛': 6,
    '丁': 8,
    '壬': 8,
    '戊': 0,
    '癸': 0,
  };
  final monthOrdinal = (branches.indexOf(monthBranch) - 2) % 12;
  final monthStem = stems[(yinMonthStart[yearGanzhi[0]]! + monthOrdinal) % 10];
  final monthGanzhi = '$monthStem$monthBranch';

  String? transitionName;
  DateTime? transitionAt;
  String? transitionRelation;
  for (var index = 0; index < current.length; index++) {
    final candidate = current[index];
    if (candidate.year == moment.year &&
        candidate.month == moment.month &&
        candidate.day == moment.day) {
      transitionName = exactJieNames[index];
      transitionAt = candidate;
      transitionRelation = moment.isBefore(candidate)
          ? 'before'
          : 'at_or_after';
      break;
    }
  }
  return ExactJieContext(
    yearGanzhi: yearGanzhi,
    monthGanzhi: monthGanzhi,
    monthBranch: monthBranch,
    activeJie: activeName,
    activeJieAt: activeAt,
    transitionName: transitionName,
    transitionAt: transitionAt,
    transitionRelation: transitionRelation,
  );
}

/// ============================================================================
/// 干支计算
/// ============================================================================

/// 计算年干支（以立春为界或春节为界）
/// yearBoundary: 'lunar_new_year' | 'beginning_of_spring'
String calculateYearGanzhi(int year, {String yearBoundary = 'lunar_new_year'}) {
  // 甲子年 = 1984
  // 公式：干 = (year - 3) % 10 -> 甲=0
  //       支 = (year - 3) % 12 -> 子=0

  final stemIndex = (year - 4) % 10;
  final branchIndex = (year - 4) % 12;

  final stems = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
  final branches = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

  return '${stems[stemIndex]}${branches[branchIndex]}';
}

/// 计算月干支
/// yearGanzhi: 年干支
/// month: 公历月份 1-12
String calculateMonthGanzhi(String yearGanzhi, int month) {
  final yearStem = yearGanzhi[0];
  final stems = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
  final branches = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

  // 月支：寅=1月，卯=2月...丑=12月
  final monthBranchIndex = (month + 1) % 12; // 1月->2(寅), 12月->1(丑)
  final monthBranch = branches[monthBranchIndex];

  // 月干：年干决定月干起始
  // 甲己之年丙作首，乙庚之岁戊为头...
  final monthStemOffsets = {
    '甲': 2, '己': 2, // 丙作首
    '乙': 4, '庚': 4, // 戊为头
    '丙': 6, '辛': 6, // 庚起头
    '丁': 8, '壬': 8, // 壬位排
    '戊': 0, '癸': 0, // 甲顺行
  };

  final offset = monthStemOffsets[yearStem] ?? 0;
  final monthStemIndex = (offset + month - 1) % 10;
  final monthStem = stems[monthStemIndex];

  return '$monthStem$monthBranch';
}

String calculateSolarMonthGanzhi(String yearGanzhi, DateTime date) {
  final terms = solarTermSnapshot(date);
  var nextIndex = terms.nextIndex;
  if (nextIndex == 0 && date.month == 12) nextIndex = 24;
  final elapsedSolarMonths = (nextIndex + 1) ~/ 2;
  final cycleIndex = ((date.year - 2019) * 12 + elapsedSolarMonths) % 60;
  return the60HeavenlyEarth[cycleIndex];
}

/// 计算日干支
/// 使用已知基准：1900-01-31 为甲辰日（六十甲子索引 40）。
/// 计算 targetDate 与基准日的差值。
///
/// 关键修复：本函数把传入对象仅当作“上海墙上时间容器”，忽略 isUtc / 时区
/// 标志，内部先重建为 UTC 容器再求差值。若直接调用 `date.difference(base)`，
/// Dart 会把 isUtc=false 的本地 DateTime 先按 UTC 换算，在 UTC+8 设备上会
/// 少算 1 天，导致日柱整体错位一天（如 2026-08-09 被算成甲寅而非乙卯）。
///
/// [dayBoundary] 交日策略：
/// - [dayBoundaryCivil23NextDay]（默认）：前一天 23:00:00.001 起进入当日
///   子时，日柱按第二天算。即“过 23:00:00.000 整点”即换日。
/// - [dayBoundaryAstronomicalMidnight]：子正 0 点换日，23:00–23:59 的
///   夜子时仍用当日日柱。
String calculateDayGanzhi(
  DateTime date, {
  String dayBoundary = dayBoundaryCivil23NextDay,
}) {
  final wall = DateTime.utc(
    date.year,
    date.month,
    date.day,
    date.hour,
    date.minute,
    date.second,
    date.millisecond,
    date.microsecond,
  );
  final baseDate = DateTime.utc(1900, 1, 31);
  final daysDiff = wall.difference(baseDate).inDays;

  final stems = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
  final branches = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

  var cycleIndex = ((daysDiff + 40) % 60 + 60) % 60;
  if (dayBoundary == dayBoundaryCivil23NextDay) {
    final boundary = DateTime.utc(wall.year, wall.month, wall.day, 23, 0, 0, 1);
    if (!wall.isBefore(boundary)) {
      cycleIndex = (cycleIndex + 1) % 60;
    }
  }
  final stemIndex = cycleIndex % 10;
  final branchIndex = cycleIndex % 12;

  return '${stems[stemIndex]}${branches[branchIndex]}';
}

/// 计算时干支（支持 13 时辰）
/// dayGanzhi: 日干支
/// hour: 小时 0-23
/// minute: 分钟 0-59（用于判断子时前后）
/// 返回: {ganzhi: 干支, period: 时段名称, isZiHourSplit: 是否子时分前后}
Map<String, dynamic> calculateHourGanzhi13(
  String dayGanzhi,
  int hour, [
  int minute = 0,
]) {
  final dayStem = dayGanzhi[0];
  final stems = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
  final branches = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

  int hourBranchIndex;
  String periodName;
  bool isZiHourSplit = false;

  // 13 时辰：子时分前后
  if (hour == 23 || (hour == 0 && minute < 60)) {
    // 子时前 (23:00-00:59) 或 子时后 (00:00-00:59)
    hourBranchIndex = 0; // 子
    periodName = hour == 23 ? '子时前' : '子时后';
    isZiHourSplit = true;
  } else if (hour >= 1 && hour < 3) {
    hourBranchIndex = 1; // 丑
    periodName = '丑时';
  } else if (hour >= 3 && hour < 5) {
    hourBranchIndex = 2; // 寅
    periodName = '寅时';
  } else if (hour >= 5 && hour < 7) {
    hourBranchIndex = 3; // 卯
    periodName = '卯时';
  } else if (hour >= 7 && hour < 9) {
    hourBranchIndex = 4; // 辰
    periodName = '辰时';
  } else if (hour >= 9 && hour < 11) {
    hourBranchIndex = 5; // 巳
    periodName = '巳时';
  } else if (hour >= 11 && hour < 13) {
    hourBranchIndex = 6; // 午
    periodName = '午时';
  } else if (hour >= 13 && hour < 15) {
    hourBranchIndex = 7; // 未
    periodName = '未时';
  } else if (hour >= 15 && hour < 17) {
    hourBranchIndex = 8; // 申
    periodName = '申时';
  } else if (hour >= 17 && hour < 19) {
    hourBranchIndex = 9; // 酉
    periodName = '酉时';
  } else if (hour >= 19 && hour < 21) {
    hourBranchIndex = 10; // 戌
    periodName = '戌时';
  } else {
    hourBranchIndex = 11; // 亥
    periodName = '亥时';
  }

  final hourBranch = branches[hourBranchIndex];

  // 时干：日干决定时干
  final hourStemOffsets = {
    '甲': 0,
    '己': 0,
    '乙': 2,
    '庚': 2,
    '丙': 4,
    '辛': 4,
    '丁': 6,
    '壬': 6,
    '戊': 8,
    '癸': 8,
  };

  final offset = hourStemOffsets[dayStem] ?? 0;
  final hourStemIndex = (offset + hourBranchIndex) % 10;
  final hourStem = stems[hourStemIndex];

  return {
    'ganzhi': '$hourStem$hourBranch',
    'period': periodName,
    'is_zi_hour_split': isZiHourSplit,
    'branch_index': hourBranchIndex,
    'stem_index': hourStemIndex,
  };
}

/// 向后兼容：返回简化版时干支字符串
String calculateHourGanzhi(String dayGanzhi, int hour) {
  final result = calculateHourGanzhi13(dayGanzhi, hour);
  return result['ganzhi'] as String;
}

/// ============================================================================
/// 纳音计算
/// ============================================================================

/// 获取干支对应的纳音
String getNayin(String ganzhi) {
  final index = the60HeavenlyEarth.indexOf(ganzhi);
  if (index == -1) {
    throw ArgumentError('未知干支: $ganzhi');
  }
  return nayinList[index];
}

const _dailyMansions = [
  '角木蛟',
  '亢金龙',
  '氐土貉',
  '房日兔',
  '心月狐',
  '尾火虎',
  '箕水豹',
  '斗木獬',
  '牛金牛',
  '女土蝠',
  '虚日鼠',
  '危月燕',
  '室火猪',
  '壁水貐',
  '奎木狼',
  '娄金狗',
  '胃土雉',
  '昴日鸡',
  '毕月乌',
  '觜火猴',
  '参水猿',
  '井木犴',
  '鬼金羊',
  '柳土獐',
  '星日马',
  '张月鹿',
  '翼火蛇',
  '轸水蚓',
];

/// cnlunar 0.2.0 `get_the28Stars` daily provider value.
String calculateDailyMansion(DateTime date) {
  final wall = toShanghaiWallClock(date);
  final day = DateTime.utc(wall.year, wall.month, wall.day);
  final base = DateTime.utc(2019, 1, 17);
  final index = ((day.difference(base).inDays % 28) + 28) % 28;
  return _dailyMansions[index];
}

/// ============================================================================
/// 旬空计算
/// ============================================================================

/// 计算某干支的旬空
/// 返回: (旬空描述, 空亡地支列表)
({String voidText, List<String> voidBranches}) calculateDayVoid(String ganzhi) {
  final index = the60HeavenlyEarth.indexOf(ganzhi);
  if (index == -1) {
    throw ArgumentError('未知干支: $ganzhi');
  }

  const branches = '子丑寅卯辰巳午未申酉戌亥';
  const stems = '甲乙丙丁戊己庚辛壬癸';
  final start =
      (branches.indexOf(ganzhi[1]) - stems.indexOf(ganzhi[0]) - 2) % 12;
  final voidBranches = [branches[start], branches[(start + 1) % 12]];
  final voidText = voidBranches.join();

  return (voidText: voidText, voidBranches: voidBranches);
}

/// ============================================================================
/// 财神方位
/// ============================================================================

/// 根据日干计算财神方位
/// 返回: (方位, 描述)
({String direction, String description}) calculateWealthGodDirection(
  String dayStem,
) {
  // cnlunar.config wealthGodDirection + chinese8Trigrams 的逐日干映射。
  final directions = {
    '甲': ('东北', '财神东北'),
    '乙': ('东北', '财神东北'),
    '丙': ('西南', '财神西南'),
    '丁': ('西南', '财神西南'),
    '戊': ('正北', '财神正北'),
    '己': ('正北', '财神正北'),
    '庚': ('正东', '财神正东'),
    '辛': ('正东', '财神正东'),
    '壬': ('正南', '财神正南'),
    '癸': ('正南', '财神正南'),
  };

  final result = directions[dayStem];
  if (result == null) {
    return (direction: '南', description: '财神南方');
  }
  return (direction: result.$1, description: result.$2);
}

/// ============================================================================
/// 完整万年历计算入口
/// ============================================================================

/// 计算单个时刻的万年历
/// 对应 Python calculate_almanac()
Map<String, dynamic> calculateAlmanac(
  DateTime timestamp, {
  String timezoneName = 'Asia/Shanghai',
  String yearBoundary = 'lunar_new_year',
  String dayBoundary = dayBoundaryCivil23NextDay,
  String monthBoundary = monthBoundarySolarTermZiHour,
}) {
  // Dart 会把带 offset 的 ISO 时刻规范化为 UTC。规则层统一转换成
  // Asia/Shanghai(+08:00) 墙上时间，保证设备时区不影响排盘。
  final wallClock = toShanghaiWallClock(timestamp);
  // 1. 四柱
  final lunar = solarToLunar(wallClock);
  final exactJie = calculateExactJieContext(
    timestamp,
    monthBoundary: monthBoundary,
  );
  final yearGanzhi = exactJie.yearGanzhi;
  final monthGanzhi = exactJie.monthGanzhi;
  final dayGanzhi = calculateDayGanzhi(wallClock, dayBoundary: dayBoundary);
  final currentTwoHourIndex = (wallClock.hour + 1) ~/ 2;
  final dayCycleIndex = the60HeavenlyEarth.indexOf(dayGanzhi);

  // 13 时辰的日柱归属（对齐 cnlunar twohour8CharList 语义）：
  // index 0-11（子正→亥）用当前时刻日柱 dayGanzhi 起时干；
  // index 12（23 点子初）用次日日柱（dayCycleIndex+1）起子时。
  // 这样「子初 / 子正」干支不同，不再重复同一时辰。
  final nextDayCycleIndex = (dayCycleIndex + 1) % 60;
  final twoHourPillars = List.generate(13, (index) {
    final cycleIndex = index == 12 ? nextDayCycleIndex : dayCycleIndex;
    final branchIndex = index == 12 ? 0 : index;
    final ganzhi = the60HeavenlyEarth[(cycleIndex * 12 + branchIndex) % 60];
    return {
      'index': index,
      'ganzhi': ganzhi,
      'stem': ganzhi[0],
      'branch': ganzhi[1],
      'selected': index == currentTwoHourIndex,
    };
  });
  // 时柱独立计算：按当前时刻日柱与时支（保持 dayBoundary 口径），
  // 不随展示列表 index 12 的次日日柱变化。
  final hourGanzhi =
      calculateHourGanzhi13(
            dayGanzhi,
            wallClock.hour,
            wallClock.minute,
          )['ganzhi']
          as String;
  final terms = solarTermSnapshot(wallClock);
  final normalizedLocalTimestamp = formatShanghaiInstantIso(timestamp);
  final dailyMansion = calculateDailyMansion(timestamp);
  final legacyMonthGanzhi = calculateSolarMonthGanzhi(
    calculateYearGanzhi(lunar.year),
    wallClock,
  );

  final pillars = {
    'year': {
      'ganzhi': yearGanzhi,
      'stem': yearGanzhi[0],
      'branch': yearGanzhi[1],
      'nayin': getNayin(yearGanzhi),
    },
    'month': {
      'ganzhi': monthGanzhi,
      'stem': monthGanzhi[0],
      'branch': monthGanzhi[1],
      'nayin': getNayin(monthGanzhi),
    },
    'day': {
      'ganzhi': dayGanzhi,
      'stem': dayGanzhi[0],
      'branch': dayGanzhi[1],
      'nayin': getNayin(dayGanzhi),
    },
    'hour': {
      'ganzhi': hourGanzhi,
      'stem': hourGanzhi[0],
      'branch': hourGanzhi[1],
      'nayin': getNayin(hourGanzhi),
    },
  };

  // 2. 旬空
  final dayVoid = calculateDayVoid(dayGanzhi);

  // 3. 财神
  final wealthGod = calculateWealthGodDirection(dayGanzhi[0]);

  // 4. 组装返回
  return {
    'schema_version': 1,
    'adapter_version': '0.2.0+private-reference-v1',
    'provider': {
      'name': 'cnlunar-dart-port',
      'source': 'OPN48/cnlunar',
      'supported_local_dates': {
        'start': supportedDateStart,
        'end': supportedDateEnd,
      },
    },
    'timestamp': timestamp.toIso8601String(),
    'timezone': timezoneName,
    'year_boundary': yearBoundary,
    'calendar_policy': {
      'day_boundary': dayBoundary,
      'day_boundary_label': dayBoundaryLabels[dayBoundary],
      'month_boundary': monthBoundary,
      'month_boundary_label': monthBoundaryLabels[monthBoundary],
      'day_boundary_rule': dayBoundary == dayBoundaryCivil23NextDay
          ? '过 23:00:00.000 整点（即 23:00:00.001 起）进入当日子时，'
                '日柱按次日算；23:00:00.000 整点仍属当日'
          : '子正 0 点换日，23:00–23:59 夜子时仍用当日日柱',
      'month_boundary_rule': monthBoundary == monthBoundarySolarTermZiHour
          ? '进入当月节气的子时（节气日前一天 23:00:00.001）即切换到新月柱'
          : '按节气天文精确时刻切换到新月柱（lunar_python 口径）',
    },
    'lunar': lunar.toJson(),
    'four_pillars': [
      {'position': 'year', ...pillars['year']!},
      {'position': 'month', ...pillars['month']!},
      {'position': 'day', ...pillars['day']!},
      {'position': 'hour', ...pillars['hour']!},
    ],
    'two_hour_pillars': twoHourPillars,
    'current_two_hour_index': currentTwoHourIndex,
    'solar_terms': {
      'today': terms.today,
      'next': {
        'name': terms.nextName,
        'date':
            '${terms.nextDate.year.toString().padLeft(4, '0')}-${terms.nextDate.month.toString().padLeft(2, '0')}-${terms.nextDate.day.toString().padLeft(2, '0')}',
      },
      'boundary_precision': 'second',
      'active_jie': exactJie.activeJie,
      'active_jie_at': formatShanghaiWallClockIso(exactJie.activeJieAt),
      'transition_name': exactJie.transitionName,
      'transition_at': exactJie.transitionAt == null
          ? null
          : formatShanghaiWallClockIso(exactJie.transitionAt!),
      'transition_relation': exactJie.transitionRelation,
      'provider': {
        'name': 'lunar_python',
        'version': exactJieProviderVersion,
        'revision': exactJieProviderRevision,
      },
    },
    'provider_extensions': {
      'twenty_eight_mansion': {
        'name': dailyMansion,
        'provider': 'cnlunar',
        'provider_version': '0.2.0',
        'provider_revision': '1d7f868967cc533c9b577ed0c3ffb3cb67bb5352',
        'calculated_at': normalizedLocalTimestamp,
        'raw_value': dailyMansion,
        'enabled_for_interpretation': false,
      },
    },
    'provider_raw': {
      'month_ganzhi': legacyMonthGanzhi,
      'cnlunar_year_ganzhi': calculateYearGanzhi(lunar.year),
      'cnlunar_month_ganzhi': legacyMonthGanzhi,
      'lunar_python_year_ganzhi_exact': exactJie.yearGanzhi,
      'lunar_python_month_ganzhi_exact': exactJie.monthGanzhi,
      'today_solar_term': terms.today ?? '无',
    },
    'day_void': dayVoid.voidText,
    'day_void_branches': dayVoid.voidBranches,
    'wealth_god': {
      'direction': wealthGod.direction,
      'description': wealthGod.description,
      'raw': wealthGod.description,
    },
    'calculation_trace': [
      {
        'rule_id': 'almanac.cnlunar.four_pillars.v1',
        'input': timestamp.toIso8601String(),
        'options': {
          'god_type': '8char',
          'year_boundary': yearBoundary,
          'day_boundary': dayBoundary,
          'month_boundary': monthBoundary,
        },
        'output': [yearGanzhi, monthGanzhi, dayGanzhi, hourGanzhi],
      },
      {
        'rule_id': 'almanac.nayin.sixty_jiazi.v1',
        'input': [yearGanzhi, monthGanzhi, dayGanzhi, hourGanzhi],
        'output': [
          getNayin(yearGanzhi),
          getNayin(monthGanzhi),
          getNayin(dayGanzhi),
          getNayin(hourGanzhi),
        ],
      },
      {
        'rule_id': 'almanac.cnlunar.wealth_god.v1',
        'input': {'day_stem': dayGanzhi[0]},
        'output': wealthGod.direction,
      },
    ],
    'supported_range': {'start': supportedDateStart, 'end': supportedDateEnd},
  };
}

/// 验证日期是否在支持范围内
bool isDateSupported(DateTime date) {
  final start = DateTime.utc(1901, 2, 19);
  final end = DateTime.utc(2100, 2, 8);
  final localDate = DateTime.utc(date.year, date.month, date.day);
  return !localDate.isBefore(start) && !localDate.isAfter(end);
}
