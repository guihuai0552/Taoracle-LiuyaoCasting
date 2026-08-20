import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao_engine/liuyao_engine.dart';
import 'package:liuyao_archive/src/features/casting/casting_models.dart';

/// 引擎冒烟测试：验证离线排盘链路运行时不再崩溃，
/// 且引擎输出能被 CastPreview.fromEngineResult（UI 解析入口）完整解析。
void main() {
  group('cast engine', () {
    test('manualCast 输出 schema v16 且结构完整', () {
      final result = manualCast(DateTime(2024, 3, 15, 10, 30), [
        7,
        7,
        7,
        8,
        8,
        6,
      ]);
      expect(result['schema_version'], 16);
      final hexagram = result['hexagram'] as Map<String, dynamic>;
      expect(hexagram['line_order'], 'bottom_to_top');
      expect(hexagram['display_order'], 'top_to_bottom');
      final base = hexagram['base'] as Map<String, dynamic>;
      expect((base['name'] as String).isNotEmpty, true);
      final lines = base['lines'] as List;
      expect(lines.length, 6);
      final firstLine = lines.first as Map<String, dynamic>;
      expect(firstLine['earthly_branch'], isNotNull);
      expect(firstLine['gan_zhi'], isNotNull);
      expect(firstLine['six_god'], isNotNull);
      expect(firstLine['relation'], isNotNull);
    });

    test('autoCast 不崩溃', () {
      final result = autoCast(DateTime(2024, 3, 15, 10, 30), seed: 42);
      expect(result['schema_version'], 16);
    });

    test('CastPreview.fromEngineResult 完整解析引擎输出（UI 崩溃入口）', () {
      // 9=老阳动, 8=少阴, 7=少阳, 6=老阴动, 8, 7 → 动爻在 1、4
      final result = manualCast(DateTime(2024, 3, 15, 10, 30), [
        9,
        8,
        7,
        6,
        8,
        7,
      ]);
      final preview = CastPreview.fromEngineResult(result, question: '测试');
      expect(preview.schemaVersion, 16);
      expect(preview.baseHexagram, isNotEmpty);
      expect(preview.chart.base.lines.length, 6);
      // 产品所选 5 项神煞 + 卦身、命爻
      expect(
        preview.annotations.shenshaResults
            .map((item) => item.displayName)
            .toList(),
        ['驿马', '桃花', '禄神', '华盖', '天乙贵人'],
      );
      expect(preview.annotations.bodyMarkers?.guaShen.displayName, '卦身');
      expect(preview.annotations.bodyMarkers?.mingYao.displayName, '命爻');
      expect(
        preview
            .annotations
            .hiddenHexagramAnnotations
            ?.fiveElementTwelveStages
            .lineResults
            .length,
        6,
      );
      expect(
        preview
            .annotations
            .hiddenHexagramAnnotations
            ?.twentyEightMansions
            .linePlacements
            .length,
        6,
      );
      expect(
        preview
            .annotations
            .changedHexagramAnnotations
            ?.fiveElementTwelveStages
            .lineResults
            .length,
        6,
      );
      expect(
        preview
            .annotations
            .changedHexagramAnnotations
            ?.twentyEightMansions
            .linePlacements
            .length,
        6,
      );
      // 十二长生：6 爻 ×（4 柱 + 5 五行参照）
      final stages = preview.annotations.fiveElementTwelveStages;
      expect(stages.lineResults.length, 6);
      expect(stages.lineResults.first.pillarResults.length, 9);
      // 世应
      expect(preview.chart.base.shiPosition, greaterThan(0));
      expect(preview.chart.base.yingPosition, greaterThan(0));
      // 动爻
      expect(preview.chart.movingPositions, contains(1));
      expect(preview.chart.movingPositions, contains(4));
      // 变卦
      expect(preview.chart.changed, isNotNull);
      expect(preview.chart.changed!.lines.length, 6);
      expect(preview.chart.changed!.shiPosition, greaterThan(0));
      expect(preview.chart.changed!.yingPosition, greaterThan(0));
      expect(
        preview.chart.changed!.lines
            .singleWhere(
              (line) => line.position == preview.chart.changed!.shiPosition,
            )
            .role,
        '世',
      );
      expect(
        preview.chart.changed!.lines
            .singleWhere(
              (line) => line.position == preview.chart.changed!.yingPosition,
            )
            .role,
        '应',
      );
      // 四柱与旬空非默认未记录
      expect(preview.dayPillar, isNot('未记录'));
      // 计算轨迹可遍历
      expect(preview.calculationTrace.length, greaterThan(0));
      for (final trace in preview.calculationTrace) {
        expect(trace.ruleId, isNotEmpty);
      }
    });

    test('静卦（无动爻）不崩溃且无变卦', () {
      final result = manualCast(DateTime(2024, 3, 15, 10, 30), [
        7,
        7,
        7,
        7,
        7,
        7,
      ]);
      final preview = CastPreview.fromEngineResult(result, question: '静卦');
      expect(preview.chart.changed, isNull);
      expect(preview.chart.movingPositions, isEmpty);
      // 伏卦仍存在
      expect(preview.chart.base.hiddenHexagram, isNotNull);
    });
  });

  group('almanac', () {
    test('calculateAlmanac 输出四柱', () {
      final result = calculateAlmanac(DateTime(2024, 3, 15, 10, 30));
      final pillars = result['four_pillars'] as List;
      expect(pillars.length, 4);
      for (final p in pillars) {
        final map = p as Map<String, dynamic>;
        expect((map['ganzhi'] as String).isNotEmpty, true);
      }
    });
  });
}
