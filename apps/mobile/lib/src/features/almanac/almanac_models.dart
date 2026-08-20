import 'package:liuyao_engine/liuyao_engine.dart' as lunar_engine;

class AlmanacMonth {
  const AlmanacMonth({
    required this.year,
    required this.month,
    required this.cells,
  });

  factory AlmanacMonth.fromJson(Map<String, dynamic> json) {
    final request = json['request'] as Map<String, dynamic>;
    final cells = json['cells'] as List<dynamic>;
    return AlmanacMonth(
      year: request['year'] as int,
      month: request['month'] as int,
      cells: cells
          .map((item) => AlmanacDayCell.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final int year;
  final int month;
  final List<AlmanacDayCell> cells;
}

class AlmanacDayCell {
  const AlmanacDayCell({
    required this.date,
    required this.solarDay,
    required this.weekday,
    required this.inCurrentMonth,
    required this.available,
    this.lunar,
    this.dayPillar,
    this.solarTerm,
  });

  factory AlmanacDayCell.fromJson(Map<String, dynamic> json) {
    final lunar = json['lunar'];
    final dayPillar = json['day_pillar'];
    return AlmanacDayCell(
      date: DateTime.parse(json['date'] as String),
      solarDay: json['solar_day'] as int,
      weekday: json['weekday'] as int,
      inCurrentMonth: json['in_current_month'] as bool,
      available: json['available'] as bool,
      lunar: lunar == null
          ? null
          : AlmanacLunarDate.fromJson(lunar as Map<String, dynamic>),
      dayPillar: dayPillar == null
          ? null
          : AlmanacPillar.fromJson(dayPillar as Map<String, dynamic>),
      solarTerm: json['solar_term'] as String?,
    );
  }

  final DateTime date;
  final int solarDay;
  final int weekday;
  final bool inCurrentMonth;
  final bool available;
  final AlmanacLunarDate? lunar;
  final AlmanacPillar? dayPillar;
  final String? solarTerm;

  String get lunarLabel {
    if (solarTerm != null) return solarTerm!;
    final value = lunar;
    if (value == null) return '';
    return value.day == 1 ? value.monthCn : value.dayCn;
  }
}

class AlmanacSnapshot {
  const AlmanacSnapshot({
    required this.solarDate,
    required this.weekday,
    required this.localDateTime,
    required this.lunar,
    required this.fourPillars,
    required this.twoHourPillars,
    required this.currentTwoHourIndex,
    required this.wealthGodDirection,
    this.solarTerm,
  });

  /// 从 Dart 引擎结果创建 AlmanacSnapshot（离线模式）
  factory AlmanacSnapshot.fromEngineResult(Map<String, dynamic> engineResult) {
    final fourPillarsRaw = engineResult['four_pillars'] as List<dynamic>? ?? [];
    final fourPillars = fourPillarsRaw.map((item) {
      final map = item as Map<String, dynamic>? ?? {};
      return AlmanacPillar(
        position: (map['position'] as String?) ?? '',
        ganzhi: (map['ganzhi'] as String?) ?? '',
        stem: (map['stem'] as String?) ?? '',
        branch: (map['branch'] as String?) ?? '',
        nayin: (map['nayin'] as String?) ?? '',
      );
    }).toList();

    final wealthGod =
        engineResult['wealth_god'] as Map<String, dynamic>? ??
        {'direction': '南'};
    final timestampStr = engineResult['timestamp'] as String?;
    final timestamp = timestampStr != null
        ? DateTime.parse(timestampStr)
        : DateTime.now();

    final lunarJson = engineResult['lunar'] as Map<String, dynamic>?;
    final ld = lunarJson == null ? lunar_engine.solarToLunar(timestamp) : null;
    final lunar = lunarJson == null
        ? AlmanacLunarDate(
            month: ld!.month,
            day: ld.day,
            isLeapMonth: ld.isLeapMonth,
            monthCn: ld.monthCn,
            dayCn: ld.dayCn,
            yearCn: ld.yearCn,
            zodiac: ld.zodiac,
          )
        : AlmanacLunarDate.fromJson(lunarJson);
    final twoHourPillars =
        (engineResult['two_hour_pillars'] as List<dynamic>? ?? const [])
            .map(
              (item) =>
                  AlmanacTwoHourPillar.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false);
    final solarTerms = engineResult['solar_terms'] as Map<String, dynamic>?;

    return AlmanacSnapshot(
      solarDate: DateTime(timestamp.year, timestamp.month, timestamp.day),
      weekday: _weekdayName(timestamp.weekday),
      localDateTime: timestamp,
      lunar: lunar,
      fourPillars: fourPillars,
      twoHourPillars: twoHourPillars,
      currentTwoHourIndex: engineResult['current_two_hour_index'] as int? ?? 0,
      wealthGodDirection: (wealthGod['direction'] as String?) ?? '南',
      solarTerm: solarTerms?['today'] as String?,
    );
  }

  static String _weekdayName(int weekday) {
    const names = ['一', '二', '三', '四', '五', '六', '日'];
    return '周${names[weekday - 1]}';
  }

  factory AlmanacSnapshot.fromJson(Map<String, dynamic> json) {
    final input = json['input'] as Map<String, dynamic>;
    final solar = json['solar'] as Map<String, dynamic>;
    final solarTerms = json['solar_terms'] as Map<String, dynamic>;
    final wealthGod = json['wealth_god'] as Map<String, dynamic>;
    return AlmanacSnapshot(
      solarDate: DateTime.parse(solar['date'] as String),
      weekday: solar['weekday'] as String,
      localDateTime: DateTime.parse(input['local_datetime'] as String),
      lunar: AlmanacLunarDate.fromJson(json['lunar'] as Map<String, dynamic>),
      fourPillars: (json['four_pillars'] as List<dynamic>)
          .map((item) => AlmanacPillar.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      twoHourPillars: (json['two_hour_pillars'] as List<dynamic>)
          .map(
            (item) =>
                AlmanacTwoHourPillar.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      currentTwoHourIndex: json['current_two_hour_index'] as int,
      wealthGodDirection: wealthGod['direction'] as String,
      solarTerm: solarTerms['today'] as String?,
    );
  }

  final DateTime solarDate;
  final String weekday;
  final DateTime localDateTime;
  final AlmanacLunarDate lunar;
  final List<AlmanacPillar> fourPillars;
  final List<AlmanacTwoHourPillar> twoHourPillars;
  final int currentTwoHourIndex;
  final String wealthGodDirection;
  final String? solarTerm;
}

class AlmanacLunarDate {
  const AlmanacLunarDate({
    required this.month,
    required this.day,
    required this.isLeapMonth,
    required this.monthCn,
    required this.dayCn,
    this.yearCn,
    this.zodiac,
  });

  factory AlmanacLunarDate.fromJson(Map<String, dynamic> json) {
    return AlmanacLunarDate(
      month: json['month'] as int,
      day: json['day'] as int,
      isLeapMonth: json['is_leap_month'] as bool,
      monthCn: json['month_cn'] as String,
      dayCn: json['day_cn'] as String,
      yearCn: json['year_cn'] as String?,
      zodiac: json['zodiac'] as String?,
    );
  }

  final int month;
  final int day;
  final bool isLeapMonth;
  final String monthCn;
  final String dayCn;
  final String? yearCn;
  final String? zodiac;

  String get fullLabel => '${isLeapMonth ? '闰' : ''}$monthCn$dayCn';
}

class AlmanacPillar {
  const AlmanacPillar({
    required this.position,
    required this.ganzhi,
    required this.stem,
    required this.branch,
    required this.nayin,
  });

  factory AlmanacPillar.fromJson(Map<String, dynamic> json) {
    return AlmanacPillar(
      position: json['position'] as String,
      ganzhi: json['ganzhi'] as String,
      stem: json['stem'] as String,
      branch: json['branch'] as String,
      nayin: json['nayin'] as String,
    );
  }

  final String position;
  final String ganzhi;
  final String stem;
  final String branch;
  final String nayin;
}

class AlmanacTwoHourPillar {
  const AlmanacTwoHourPillar({
    required this.index,
    required this.ganzhi,
    required this.stem,
    required this.branch,
    required this.selected,
  });

  factory AlmanacTwoHourPillar.fromJson(Map<String, dynamic> json) {
    return AlmanacTwoHourPillar(
      index: json['index'] as int,
      ganzhi: json['ganzhi'] as String,
      stem: json['stem'] as String,
      branch: json['branch'] as String,
      selected: json['selected'] as bool,
    );
  }

  final int index;
  final String ganzhi;
  final String stem;
  final String branch;
  final bool selected;
}
