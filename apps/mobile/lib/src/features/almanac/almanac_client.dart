import 'almanac_models.dart';
import 'package:liuyao_engine/liuyao_engine.dart' as engine;
import 'package:liuyao_engine/liuyao_engine.dart' as lunar;

/// ============================================================================
/// 离线万年历数据源（100% 纯 Dart 实现，无需后端服务）
/// ============================================================================

abstract class AlmanacDataSource {
  Future<AlmanacMonth> loadMonth({required int year, required int month});

  Future<AlmanacSnapshot> loadDay({required DateTime date, required int hour});

  void close();
}

/// 离线实现：直接调用本地 Dart 引擎
class AlmanacClient implements AlmanacDataSource {
  AlmanacClient();

  @override
  Future<AlmanacMonth> loadMonth({
    required int year,
    required int month,
  }) async {
    final cells = <AlmanacDayCell>[];
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // 当月所有日期，填入农历标注、日柱、节气
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      cells.add(
        _buildCell(
          date,
          inCurrentMonth: true,
          available: engine.isDateSupported(date),
        ),
      );
    }

    // 补充前月日期填满首周（周一为一周之首，weekday: 1=周一）
    final startWeekday = firstDay.weekday;
    for (int i = 0; i < startWeekday - 1; i++) {
      final prevDate = firstDay.subtract(Duration(days: startWeekday - 1 - i));
      cells.insert(
        0,
        _buildCell(
          prevDate,
          inCurrentMonth: false,
          available: engine.isDateSupported(prevDate),
        ),
      );
    }

    // 补充下月日期填满 6×7 网格
    while (cells.length < 42) {
      final nextDate = cells.last.date.add(const Duration(days: 1));
      cells.add(
        _buildCell(
          nextDate,
          inCurrentMonth: false,
          available: engine.isDateSupported(nextDate),
        ),
      );
    }

    return AlmanacMonth(year: year, month: month, cells: cells);
  }

  /// 构建单日格：农历、日柱、节气
  AlmanacDayCell _buildCell(
    DateTime date, {
    required bool inCurrentMonth,
    required bool available,
  }) {
    if (!available) {
      return AlmanacDayCell(
        date: date,
        solarDay: date.day,
        weekday: date.weekday,
        inCurrentMonth: inCurrentMonth,
        available: false,
      );
    }
    final ld = lunar.solarToLunar(date);
    final dayPillar = engine.calculateDayGanzhi(date);
    final term = lunar.getSolarTerm(date);
    return AlmanacDayCell(
      date: date,
      solarDay: date.day,
      weekday: date.weekday,
      inCurrentMonth: inCurrentMonth,
      available: available,
      lunar: AlmanacLunarDate(
        month: ld.month,
        day: ld.day,
        isLeapMonth: ld.isLeapMonth,
        monthCn: ld.monthCn,
        dayCn: ld.dayCn,
        yearCn: ld.yearCn,
        zodiac: ld.zodiac,
      ),
      dayPillar: AlmanacPillar(
        position: 'day',
        ganzhi: dayPillar,
        stem: dayPillar[0],
        branch: dayPillar[1],
        nayin: engine.getNayin(dayPillar),
      ),
      solarTerm: term,
    );
  }

  @override
  Future<AlmanacSnapshot> loadDay({
    required DateTime date,
    required int hour,
    String dayBoundary = engine.dayBoundaryCivil23NextDay,
    String monthBoundary = engine.monthBoundarySolarTermZiHour,
  }) async {
    final timestamp = DateTime(date.year, date.month, date.day, hour);
    if (!engine.isDateSupported(timestamp)) {
      throw RangeError('万年历仅支持 1901-02-19 至 2100-02-08');
    }

    // 直接调用本地引擎（完全离线），透传交日/交月策略
    final result = engine.calculateAlmanac(
      timestamp,
      dayBoundary: dayBoundary,
      monthBoundary: monthBoundary,
    );

    return AlmanacSnapshot.fromEngineResult(result);
  }

  @override
  void close() {
    // 无需关闭（纯内存计算）
  }
}
