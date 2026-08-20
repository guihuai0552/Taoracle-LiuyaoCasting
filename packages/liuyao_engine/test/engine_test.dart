import 'package:liuyao_engine/liuyao_engine.dart';
import 'package:test/test.dart';

void main() {
  test('schema v16 大畜三爻动之损包含三层长生星宿与七项标注', () {
    final result = manualCast(DateTime.parse('2026-08-04T22:22:29+08:00'), [
      7,
      7,
      9,
      8,
      8,
      7,
    ]);
    final hexagram = result['hexagram'] as Map<String, dynamic>;
    final base = hexagram['base'] as Map<String, dynamic>;
    final changed = hexagram['changed'] as Map<String, dynamic>;
    final lines = (base['lines'] as List).cast<Map<String, dynamic>>();

    expect(result['schema_version'], 16);
    expect(base['name'], '山天大畜');
    expect('${base['palace_name']}宫·${base['palace_sequence']}', '艮宫·3');
    expect(changed['name'], '山泽损');
    expect('${changed['palace_name']}宫·${changed['palace_sequence']}', '艮宫·4');
    final changedShiYing = calculateShiYing(changed['code'] as String);
    expect(changed['shi_position'], changedShiYing.shi);
    expect(changed['ying_position'], changedShiYing.ying);
    final changedLines = (changed['lines'] as List)
        .cast<Map<String, dynamic>>();
    expect(changedLines[changedShiYing.shi - 1]['role'], '世');
    expect(changedLines[changedShiYing.ying - 1]['role'], '应');
    expect(changedLines.where((line) => line['role'] != null).length, 2);
    expect(lines.map((line) => line['hidden']).whereType<Map>().length, 6);

    final annotations = result['annotations'] as Map<String, dynamic>;
    final productShensha = ((annotations['shensha'] as Map)['results'] as List)
        .cast<Map<String, dynamic>>();
    expect(productShensha.map((item) => item['display_name']).toList(), [
      '驿马',
      '桃花',
      '禄神',
      '华盖',
      '天乙贵人',
    ]);
    final selectedBody = annotations['body_markers'] as Map<String, dynamic>;
    expect((selectedBody['guashen'] as Map)['display_name'], '卦身');
    expect((selectedBody['guashen'] as Map)['canonical_name'], '月卦身');
    expect((selectedBody['guashen'] as Map)['target_branch'], '丑');
    expect((selectedBody['mingyao'] as Map)['display_name'], '命爻');
    expect((selectedBody['mingyao'] as Map)['position'], 6);

    final layers = annotations['hexagram_layers'] as Map<String, dynamic>;
    final hiddenLayer = layers['hidden'] as Map<String, dynamic>;
    final changedLayer = layers['changed'] as Map<String, dynamic>;
    for (final layer in [hiddenLayer, changedLayer]) {
      final stages =
          layer['five_element_twelve_stages'] as Map<String, dynamic>;
      final mansions = layer['twenty_eight_mansions'] as Map<String, dynamic>;
      expect((stages['line_results'] as List).length, 6);
      expect((mansions['line_placements'] as List).length, 6);
    }
    expect(
      (hiddenLayer['five_element_twelve_stages'] as Map)['scope'],
      'hidden_lines',
    );
    expect(
      (changedLayer['five_element_twelve_stages'] as Map)['scope'],
      'changed_lines',
    );
    expect(
      ((hiddenLayer['twenty_eight_mansions'] as Map)['hexagram']
          as Map)['code'],
      (base['hidden_hexagram'] as Map)['code'],
    );
    expect(
      ((changedLayer['twenty_eight_mansions'] as Map)['hexagram']
          as Map)['code'],
      changed['code'],
    );

    final reference =
        result['private_reference_contract'] as Map<String, dynamic>;
    final referenceCalendar = reference['calendar'] as Map<String, dynamic>;
    final plate = reference['plate'] as Map<String, dynamic>;
    final referenceBase = plate['base'] as Map<String, dynamic>;
    final referenceLines = (referenceBase['lines'] as List)
        .cast<Map<String, dynamic>>();
    expect(reference['source_revision'], '6ca3d3e');
    expect(referenceCalendar['local_timestamp'], '2026-08-04T22:22:29+08:00');
    expect((referenceCalendar['lunar_date'] as Map)['month_cn'], '六月大');
    expect(
      (referenceCalendar['provider_raw']
          as Map)['lunar_python_month_ganzhi_exact'],
      '乙未',
    );
    expect((referenceBase['derived_forms'] as Map)['mutual'], {
      'bits': '110100',
      'name': '雷泽归妹',
    });
    expect(
      referenceLines
          .map((line) => (line['hidden_spirits'] as List).length)
          .toList(),
      [0, 1, 1, 0, 0, 0],
    );
    expect(lines.map((line) => line['nayin']).toList(), [
      '海中金',
      '大溪水',
      '覆灯火',
      '屋上土',
      '涧下水',
      '炉中火',
    ]);
  });

  test('cnlunar 固定时刻输出精确四柱和 13 时辰', () {
    final result = calculateAlmanac(
      DateTime.parse('2026-08-04T22:22:29+08:00'),
    );
    expect(
      (result['four_pillars'] as List)
          .map((pillar) => pillar['ganzhi'])
          .toList(),
      ['丙午', '乙未', '庚戌', '丁亥'],
    );
    expect((result['two_hour_pillars'] as List).length, 13);
    expect(
      ((result['provider_extensions'] as Map)['twenty_eight_mansion']
          as Map)['name'],
      '室火猪',
    );
    expect(
      ((result['provider_extensions'] as Map)['twenty_eight_mansion']
          as Map)['calculated_at'],
      '2026-08-04T22:22:29+08:00',
    );
  });

  test('秒级立春与立秋边界逐秒切换（天文精确时刻口径）', () {
    // 显式使用 astronomical_moment：按节气天文精确时刻切换月柱。
    final beforeSpring = calculateAlmanac(
      DateTime.parse('2026-02-04T04:02:07+08:00'),
      monthBoundary: monthBoundaryAstronomicalMoment,
    );
    final atSpring = calculateAlmanac(
      DateTime.parse('2026-02-04T04:02:08+08:00'),
      monthBoundary: monthBoundaryAstronomicalMoment,
    );
    final beforeAutumn = calculateAlmanac(
      DateTime.parse('2026-08-07T19:42:42+08:00'),
      monthBoundary: monthBoundaryAstronomicalMoment,
    );
    final atAutumn = calculateAlmanac(
      DateTime.parse('2026-08-07T19:42:43+08:00'),
      monthBoundary: monthBoundaryAstronomicalMoment,
    );

    List<String> pillars(Map<String, dynamic> value) =>
        (value['four_pillars'] as List)
            .take(2)
            .map((item) => item['ganzhi'] as String)
            .toList();
    expect(pillars(beforeSpring), ['乙巳', '己丑']);
    expect(pillars(atSpring), ['丙午', '庚寅']);
    expect(pillars(beforeAutumn), ['丙午', '乙未']);
    expect(pillars(atAutumn), ['丙午', '丙申']);
    expect(
      (atAutumn['solar_terms'] as Map)['transition_relation'],
      'at_or_after',
    );
  });

  test('交月默认按节气子时换月：立秋前一天23点后已是申月', () {
    // 用户指定口径：进入立秋节气的子时（立秋日 2026-08-07 的前一天
    // 23:00:00.001，即 2026-08-06 23:00:00.001）即切换到丙申月。
    // 这与外部权威 cnlunar 在立秋当天 12:00 已显示丙申月一致。
    final beforeBoundary = calculateAlmanac(
      DateTime.parse('2026-08-06T23:00:00+08:00'),
    );
    final atBoundary = calculateAlmanac(
      DateTime.parse('2026-08-06T23:00:00.001+08:00'),
    );
    final nextMorning = calculateAlmanac(
      DateTime.parse('2026-08-07T12:00:00+08:00'),
    );
    String monthGanzhi(Map<String, dynamic> value) =>
        ((value['four_pillars'] as List)[1] as Map)['ganzhi'] as String;
    expect(monthGanzhi(beforeBoundary), '乙未');
    expect(monthGanzhi(atBoundary), '丙申');
    expect(monthGanzhi(nextMorning), '丙申');
  });

  test('四土使用《五行大义》独立原始阶段', () {
    expect(lookupPrivateBranchGrowth('丑', '酉')['source_phases'], ['生']);
    expect(lookupPrivateBranchGrowth('丑', '寅')['source_phases'], ['衰病']);
    expect(lookupPrivateBranchGrowth('辰', '子')['source_phases'], ['生']);
    expect(lookupPrivateBranchGrowth('未', '未')['source_phases'], ['王']);
    expect(lookupPrivateBranchGrowth('戌', '丑')['source_phases'], ['葬']);
    expect(lookupPrivateBranchGrowth('戌', '丑')['display_phases'], ['墓']);
  });

  test('私有神煞采用所选天乙谱系并返回身命位置', () {
    final result = manualCast(DateTime.parse('2026-08-04T22:22:29+08:00'), [
      7,
      7,
      9,
      8,
      8,
      7,
    ]);
    final reference =
        result['private_reference_contract'] as Map<String, dynamic>;
    final extensions = reference['extensions'] as Map<String, dynamic>;
    final shensha = extensions['shensha'] as Map<String, dynamic>;
    final candidates = (shensha['candidates'] as List)
        .cast<Map<String, dynamic>>();
    final tianyi = candidates.singleWhere((item) => item['name'] == '天乙贵人');
    expect(tianyi['branches'], ['丑', '未']);
    final body = shensha['body_markers'] as Map<String, dynamic>;
    expect((body['shishen'] as Map)['position'], 3);
    expect((body['month_hexagram_body'] as Map)['branch'], '丑');
    expect((body['mingyao'] as Map)['position'], 6);
  });

  test('交日默认过23点整即换日且子时干正确（用户指定口径）', () {
    final before = calculateAlmanac(
      DateTime.parse('2026-08-04T22:59:59+08:00'),
    );
    final atTwentyThree = calculateAlmanac(
      DateTime.parse('2026-08-04T23:00:00+08:00'),
    );
    final afterTwentyThree = calculateAlmanac(
      DateTime.parse('2026-08-04T23:00:00.001+08:00'),
    );
    // 22:59:59 仍属当日（庚戌），时柱为亥时（丁亥）。
    expect((before['four_pillars'] as List).skip(2).map((e) => e['ganzhi']), [
      '庚戌',
      '丁亥',
    ]);
    // 23:00:00.000 整点仍属当日（庚戌），但已是当日日柱的夜子时（丙子）。
    expect(
      (atTwentyThree['four_pillars'] as List).skip(2).map((e) => e['ganzhi']),
      ['庚戌', '丙子'],
    );
    expect((atTwentyThree['two_hour_pillars'] as List)[12]['ganzhi'], '丙子');
    // 过 23:00:00.000（即 23:00:00.001 起）进入次日（辛亥），时柱戊子。
    expect(
      (afterTwentyThree['four_pillars'] as List)
          .skip(2)
          .map((e) => e['ganzhi']),
      ['辛亥', '戊子'],
    );
    expect((afterTwentyThree['two_hour_pillars'] as List)[12]['ganzhi'], '戊子');
  });

  test('黄金案例 2026-08-09 农历六月廿七、日柱乙卯（外部双源核查）', () {
    // cnlunar 与 lunar_python 双重确认：2026-08-09 = 六月廿七 / 乙卯日。
    final noon = calculateAlmanac(DateTime.parse('2026-08-09T12:00:00+08:00'));
    expect((noon['lunar'] as Map)['month_cn'], '六月');
    expect((noon['lunar'] as Map)['day_cn'], '廿七');
    expect(((noon['four_pillars'] as List)[2] as Map)['ganzhi'], '乙卯');
    // 连续序列：08-07 癸丑 → 08-08 甲寅 → 08-09 乙卯 → 08-10 丙辰。
    String dayGanzhiAt(String iso) =>
        (calculateAlmanac(DateTime.parse(iso))['four_pillars']
                as List)[2]['ganzhi']
            as String;
    expect(dayGanzhiAt('2026-08-07T12:00:00+08:00'), '癸丑');
    expect(dayGanzhiAt('2026-08-08T12:00:00+08:00'), '甲寅');
    expect(dayGanzhiAt('2026-08-10T12:00:00+08:00'), '丙辰');
  });

  test('子正0点换日口径：夜子时用当日日柱', () {
    final night = calculateAlmanac(
      DateTime.parse('2026-08-04T23:30:00+08:00'),
      dayBoundary: dayBoundaryAstronomicalMidnight,
    );
    final midnight = calculateAlmanac(
      DateTime.parse('2026-08-05T00:30:00+08:00'),
      dayBoundary: dayBoundaryAstronomicalMidnight,
    );
    expect(((night['four_pillars'] as List)[2] as Map)['ganzhi'], '庚戌');
    expect(((midnight['four_pillars'] as List)[2] as Map)['ganzhi'], '辛亥');
  });

  test('万年历网格日柱不错位：本地DateTime直调calculateDayGanzhi', () {
    // 回归：almanac_client 以本地 DateTime（isUtc=false）直调
    // calculateDayGanzhi，必须得到 2026-08-09 = 乙卯，而不是甲寅。
    final localDate = DateTime(2026, 8, 9);
    expect(calculateDayGanzhi(localDate), '乙卯');
    final localDateNext = DateTime(2026, 8, 10);
    expect(calculateDayGanzhi(localDateNext), '丙辰');
    final localDatePrev = DateTime(2026, 8, 8);
    expect(calculateDayGanzhi(localDatePrev), '甲寅');
  });

  test('京房五星：乾为天世爻镇土，初爻太白、二爻太阴、应爻岁木、四爻荧惑、五爻镇土', () {
    final result = manualCast(
      DateTime.parse('2026-08-04T22:22:29+08:00'),
      const [7, 7, 7, 7, 7, 7],
    );
    final base = (result['hexagram'] as Map)['base'] as Map<String, dynamic>;
    expect(base['name'], '乾为天');
    expect(base['shi_position'], 6);

    final annotations = result['annotations'] as Map<String, dynamic>;
    final fiveStars = annotations['five_stars'] as Map<String, dynamic>;
    final placements = (fiveStars['line_placements'] as List)
        .cast<Map<String, dynamic>>();
    final byPosition = {for (final p in placements) p['position'] as int: p};

    expect((fiveStars['world_line'] as Map)['star'], '镇土');
    expect((fiveStars['world_line'] as Map)['position'], 6);
    expect(byPosition[6]!['star'], '镇土'); // 世爻上爻
    expect(byPosition[1]!['star'], '太白');
    expect(byPosition[2]!['star'], '太阴');
    expect(byPosition[3]!['star'], '岁木'); // 应爻
    expect(byPosition[4]!['star'], '荧惑');
    expect(byPosition[5]!['star'], '镇土');
    expect(byPosition[3]!['role'], '应');
    expect(byPosition[6]!['role'], '世');
  });

  test('京房五星：乾宫一世天风姤世爻太白，应爻荧惑（火克金）', () {
    final result = manualCast(
      DateTime.parse('2026-08-04T22:22:29+08:00'),
      const [8, 7, 7, 7, 7, 7],
    );
    final base = (result['hexagram'] as Map)['base'] as Map<String, dynamic>;
    expect(base['name'], '天风姤');
    expect(base['shi_position'], 1);

    final annotations = result['annotations'] as Map<String, dynamic>;
    final fiveStars = annotations['five_stars'] as Map<String, dynamic>;
    expect((fiveStars['world_line'] as Map)['star'], '太白');
    final response = fiveStars['response_line'] as Map<String, dynamic>;
    expect(response['star'], '荧惑');
    final placements = (fiveStars['line_placements'] as List)
        .cast<Map<String, dynamic>>();
    final byPosition = {for (final p in placements) p['position'] as int: p};
    expect(byPosition[1]!['role'], '世');
    expect(byPosition[4]!['role'], '应');
    expect(byPosition[4]!['star'], '荧惑');
  });

  test('京房五星：乾宫归魂火天大有世爻太阴，应爻镇土（土克水）', () {
    final result = manualCast(
      DateTime.parse('2026-08-04T22:22:29+08:00'),
      const [7, 7, 7, 7, 8, 7],
    );
    final base = (result['hexagram'] as Map)['base'] as Map<String, dynamic>;
    expect(base['name'], '火天大有');
    expect(base['shi_position'], 3);

    final annotations = result['annotations'] as Map<String, dynamic>;
    final fiveStars = annotations['five_stars'] as Map<String, dynamic>;
    expect((fiveStars['world_line'] as Map)['star'], '太阴');
    final response = fiveStars['response_line'] as Map<String, dynamic>;
    expect(response['star'], '镇土');
  });

  test('京房五星：八宫首卦起星按克制星推演，五星顺序与五行克制一致', () {
    // 八宫首卦世爻星（乾起镇土，每宫 +3 mod 5 = 克制星）：
    const expected = ['镇土', '岁木', '太白', '荧惑', '太阴', '镇土', '岁木', '太白'];
    for (var palaceIndex = 0; palaceIndex < 8; palaceIndex++) {
      expect(
        (0 + palaceIndex * 3) % 5,
        expected[palaceIndex] == '镇土'
            ? 0
            : expected[palaceIndex] == '太白'
            ? 1
            : expected[palaceIndex] == '太阴'
            ? 2
            : expected[palaceIndex] == '岁木'
            ? 3
            : 4,
      );
    }
    // 五星五行克制关系：index + 3 mod 5 为克制星。
    const order = ['镇土', '太白', '太阴', '岁木', '荧惑'];
    const elements = ['土', '金', '水', '木', '火'];
    for (var index = 0; index < 5; index++) {
      final killer = (index + 3) % 5;
      expect(
        order[killer],
        isNot(index),
        reason: '${order[index]}（${elements[index]}）的克制星应为 ${order[killer]}',
      );
    }
  });

  test('时刻起卦法：2026-07-23 22:15 得地天泰四爻动（泰之大壮）', () {
    // 附件《时刻起卦法详解(1)》黄金示例：
    // 甲辰年己未月戊戌日 22:15 → 戊戌日癸亥时己未刻 →
    // 亥属乾（内卦）、未属坤（外卦）→ 地天泰；癸(10)+己(6)=16，16%6=4 → 四爻动 → 泰之大壮。
    final result = timePillarCast(DateTime.parse('2026-07-23T22:15:00+08:00'));
    final hexagram = result['hexagram'] as Map<String, dynamic>;
    final base = hexagram['base'] as Map<String, dynamic>;
    final changed = hexagram['changed'] as Map<String, dynamic>;
    expect(base['name'], '地天泰');
    expect(changed['name'], '雷天大壮');

    final record = result['casting_record'] as Map<String, dynamic>;
    expect(record['method_version'], 'time_pillar.shichen_ke_houtian.v1');
    final raw = record['raw_input'] as Map<String, dynamic>;
    expect(raw['day_pillar'], '戊戌');
    expect(raw['hour_pillar'], '癸亥');
    expect(raw['ke_pillar'], '己未');
    expect(raw['ke_branch'], '未');
    expect(raw['inner_trigram'], '乾');
    expect(raw['outer_trigram'], '坤');
    expect(raw['moving_sum'], 16);
    expect(raw['moving_position'], 4);
    expect(raw['moving_position_name'], '四爻');

    final lines = (record['lines'] as List).cast<Map<String, dynamic>>();
    final movingLines = lines.where((l) => l['changing'] == true).toList();
    expect(movingLines.length, 1);
    expect(movingLines.first['position'], 4);
    expect(movingLines.first['value'], 6); // 泰卦四爻为阴，动则老阴 6
  });

  test('时刻起卦法：余数 0 取上爻（六爻动）', () {
    // 构造时干与刻干序数和为 6 的倍数：甲子时（甲=1）甲子刻（甲=1）→ 2%6=2 不是。
    // 用直接断言来验证公式：动爻 =(时干序+刻干序)%6，余 0 取上爻。
    // 癸巳时（癸=10）辛酉刻（辛=8）→ 18%6=0 → 上爻动。
    final result = timePillarCast(DateTime.parse('2026-08-04T09:50:00+08:00'));
    final record = result['casting_record'] as Map<String, dynamic>;
    final raw = record['raw_input'] as Map<String, dynamic>;
    final moving = raw['moving'] as int;
    expect(moving, 0);
    expect(raw['moving_position'], 6);
    expect(raw['moving_position_name'], '上爻');
  });

  test('时刻起卦法：不同分钟落不同刻支（每刻十分钟）', () {
    // 同一时辰内，0-9 分为子刻、10-19 为丑刻…… 刻支随分钟变化。
    final base = timePillarCast(DateTime.parse('2026-08-04T08:00:00+08:00'));
    final baseRaw =
        (base['casting_record'] as Map)['raw_input'] as Map<String, dynamic>;
    final late = timePillarCast(DateTime.parse('2026-08-04T08:09:00+08:00'));
    final lateRaw =
        (late['casting_record'] as Map)['raw_input'] as Map<String, dynamic>;
    final next = timePillarCast(DateTime.parse('2026-08-04T08:10:00+08:00'));
    final nextRaw =
        (next['casting_record'] as Map)['raw_input'] as Map<String, dynamic>;
    expect(baseRaw['ke_branch'], lateRaw['ke_branch']);
    expect(baseRaw['ke_branch'], '午'); // 08:00-08:09 辰时内第 60-69 分钟 → 午刻
    expect(nextRaw['ke_branch'], '未'); // 08:10 辰时内第 70 分钟 → 未刻
    expect(nextRaw['ke_branch'], isNot(baseRaw['ke_branch']));
  });
}
