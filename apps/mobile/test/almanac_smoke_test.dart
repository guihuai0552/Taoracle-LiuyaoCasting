import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao_archive/src/features/almanac/almanac_client.dart';
import 'package:liuyao_engine/liuyao_engine.dart';

void main() {
  group('almanac month grid', () {
    test('2024年3月 月历生成42格且含农历', () async {
      final client = AlmanacClient();
      final month = await client.loadMonth(year: 2024, month: 3);
      expect(month.cells.length, 42);
      // 3月有31天
      final inMonth = month.cells.where((c) => c.inCurrentMonth).toList();
      expect(inMonth.length, 31);
      // 每个格有农历
      expect(month.cells.first.lunar, isNotNull);
      expect(month.cells.first.dayPillar, isNotNull);
      // 3月15日 → 农历二月初六
      final day15 = month.cells.firstWhere(
        (c) => c.inCurrentMonth && c.solarDay == 15,
      );
      expect(day15.lunar!.month, 2);
      expect(day15.lunar!.day, 6);
      expect(day15.dayPillar!.ganzhi.length, 2);
    });

    test('非当月格也有农历与日柱', () async {
      final client = AlmanacClient();
      final month = await client.loadMonth(year: 2024, month: 3);
      final outOfMonth = month.cells.where((c) => !c.inCurrentMonth).toList();
      expect(outOfMonth, isNotEmpty);
      for (final c in outOfMonth) {
        expect(c.lunar, isNotNull, reason: '${c.date} 缺农历');
        expect(c.dayPillar, isNotNull, reason: '${c.date} 缺日柱');
      }
    });

    test('黄金案例 2026-08-09 网格显示六月廿七乙卯日（不错位）', () async {
      final client = AlmanacClient();
      final month = await client.loadMonth(year: 2026, month: 8);
      final cell = month.cells.firstWhere(
        (c) => c.inCurrentMonth && c.solarDay == 9,
      );
      expect(cell.lunar!.month, 6);
      expect(cell.lunar!.day, 27);
      expect(cell.dayPillar!.ganzhi, '乙卯');
      // 相邻日期连续序列，防止单点碰巧正确
      String pillarOn(int day) => month.cells
          .firstWhere((c) => c.inCurrentMonth && c.solarDay == day)
          .dayPillar!
          .ganzhi;
      expect(pillarOn(7), '癸丑');
      expect(pillarOn(8), '甲寅');
      expect(pillarOn(10), '丙辰');
    });
  });

  group('almanac day snapshot', () {
    test('日详情含真实农历与时辰', () async {
      final client = AlmanacClient();
      final snap = await client.loadDay(date: DateTime(2024, 3, 15), hour: 10);
      expect(snap.lunar.month, 2);
      expect(snap.lunar.day, 6);
      expect(snap.fourPillars.length, 4);
      expect(snap.twoHourPillars.length, 13);
      expect(snap.currentTwoHourIndex, 5);
      expect(snap.twoHourPillars[5].selected, isTrue);
      final dayP = snap.fourPillars.firstWhere((p) => p.position == "day");
      expect(dayP.ganzhi.length, 2);
    });
  });

  group('cnlunar 精确合同', () {
    test('压缩节气表逐项解码', () {
      expect(solarTermDaysForYear(2024), [
        6,
        20,
        4,
        19,
        5,
        20,
        4,
        19,
        5,
        20,
        5,
        21,
        6,
        22,
        7,
        22,
        7,
        22,
        8,
        23,
        7,
        22,
        6,
        21,
      ]);
      expect(solarTermDaysForYear(2026), [
        5,
        20,
        4,
        18,
        5,
        20,
        5,
        20,
        5,
        21,
        5,
        21,
        7,
        23,
        7,
        23,
        7,
        23,
        8,
        23,
        7,
        22,
        7,
        22,
      ]);
    });

    test('2024-03-15 四柱、纳音、时辰与财神对齐', () {
      final value = calculateAlmanac(DateTime(2024, 3, 15, 10, 30));
      final pillars = (value['four_pillars'] as List).cast<Map>();
      expect(pillars.map((item) => item['ganzhi']).toList(), [
        '甲辰',
        '丁卯',
        '戊寅',
        '丁巳',
      ]);
      expect(pillars.map((item) => item['nayin']).toList(), [
        '覆灯火',
        '炉中火',
        '城头土',
        '沙中土',
      ]);
      expect((value['wealth_god'] as Map)['direction'], '正北');
      expect((value['solar_terms'] as Map)['next'], {
        'name': '春分',
        'date': '2024-03-20',
      });
      expect(value['current_two_hour_index'], 5);
      final hours = (value['two_hour_pillars'] as List).cast<Map>();
      expect(hours.length, 13);
      expect(hours[5]['ganzhi'], '丁巳');
      expect(hours[5]['selected'], isTrue);
    });

    test('cnlunar 23点换日与第13时辰语义', () {
      final before = calculateAlmanac(DateTime(2026, 2, 4, 22, 30));
      final after = calculateAlmanac(DateTime(2026, 2, 4, 23, 30));
      List<dynamic> pillars(Map<String, dynamic> value) =>
          (value['four_pillars'] as List)
              .map((item) => (item as Map)['ganzhi'])
              .toList();
      expect(pillars(before), ['丙午', '庚寅', '己酉', '乙亥']);
      expect(pillars(after), ['丙午', '庚寅', '庚戌', '丙子']);
      expect(after['current_two_hour_index'], 12);
      expect(
        ((after['two_hour_pillars'] as List)[12] as Map)['selected'],
        isTrue,
      );
      expect((after['solar_terms'] as Map)['today'], '立春');
    });
  });
}
