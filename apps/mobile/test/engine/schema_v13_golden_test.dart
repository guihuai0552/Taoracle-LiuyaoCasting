import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao_engine/liuyao_engine.dart';

List<int> _valuesFor(String name) {
  final code = gua64.entries.singleWhere((item) => item.value == name).key;
  return code.split('').map((bit) => bit == '1' ? 7 : 8).toList();
}

void main() {
  group('schema v16 私有参考合同', () {
    test('大畜三爻动之损：宫序、完整伏神、变卦六亲', () {
      final chart = manualCast(DateTime(2026, 8, 5, 15, 26), [
        7,
        7,
        9,
        8,
        8,
        7,
      ]);
      expect(chart['schema_version'], 16);
      final hexagram = chart['hexagram'] as Map<String, dynamic>;
      final base = hexagram['base'] as Map<String, dynamic>;
      final changed = hexagram['changed'] as Map<String, dynamic>;

      expect(
        [base['name'], base['palace_name'], base['palace_sequence']],
        ['山天大畜', '艮', 3],
      );
      expect(
        [changed['name'], changed['palace_name'], changed['palace_sequence']],
        ['山泽损', '艮', 4],
      );
      expect((base['hidden_hexagram'] as Map)['name'], '泽山咸');
      expect((base['hidden_hexagram'] as Map)['code'], '001110');
      final baseLines = (base['lines'] as List).cast<Map<String, dynamic>>();
      expect(
        baseLines.map((line) => (line['hidden'] as Map)['gan_zhi']).toList(),
        ['丙辰', '丙午', '丙申', '丁亥', '丁酉', '丁未'],
      );
      expect(baseLines.every((line) => line['hidden'] != null), isTrue);
      expect(changed['relative_basis'], 'base_palace');
      expect(changed['shi_position'], 3);
      expect(changed['ying_position'], 6);
      final changedLines = (changed['lines'] as List).cast<Map>();
      expect(changedLines[2]['role'], '世');
      expect(changedLines[5]['role'], '应');
    });

    test('确认过的三个二十八宿修正被冻结', () {
      Map<String, dynamic> mansionOf(String name) {
        final chart = manualCast(
          DateTime(2026, 8, 5, 15, 26),
          _valuesFor(name),
        );
        return ((chart['annotations'] as Map)['twenty_eight_mansions'] as Map)
            .cast<String, dynamic>();
      }

      expect((mansionOf('天山遁')['world_line'] as Map)['mansion'], '鬼');
      expect((mansionOf('离为火')['world_line'] as Map)['mansion'], '室');
      final qian = mansionOf('乾为天');
      final qianByPosition = {
        for (final item in (qian['line_placements'] as List).cast<Map>())
          item['position']: item['mansion'],
      };
      expect(qianByPosition[2], '张');
    });

    test('固定起卦时间四柱、旬空、纳音和财神与 cnlunar 一致', () {
      final chart = manualCast(DateTime(2026, 8, 4, 22, 22, 29), [
        7,
        7,
        7,
        7,
        7,
        7,
      ]);
      final time = chart['time'] as Map<String, dynamic>;
      expect(
        [time['year'], time['month'], time['day'], time['hour']],
        ['丙午', '乙未', '庚戌', '丁亥'],
      );
      final voids = time['pillar_voids'] as Map<String, dynamic>;
      expect(
        [
          'year',
          'month',
          'day',
          'hour',
        ].map((key) => (voids[key] as Map)['void']).toList(),
        ['寅卯', '辰巳', '寅卯', '午未'],
      );
    });

    test('64卦均有稳定八宫序位和六条伏神', () {
      for (final entry in gua64.entries) {
        final chart = manualCast(
          DateTime(2026, 8, 5, 15, 26),
          entry.key.split('').map((bit) => bit == '1' ? 7 : 8).toList(),
        );
        final base = ((chart['hexagram'] as Map)['base'] as Map);
        expect(base['name'], entry.value);
        expect(base['palace_sequence'], inInclusiveRange(1, 8));
        expect(
          (base['lines'] as List).every(
            (line) => (line as Map)['hidden'] != null,
          ),
          isTrue,
          reason: entry.value,
        );
      }
    });
  });
}
