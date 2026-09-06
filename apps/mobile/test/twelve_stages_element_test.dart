// 十二长生五行主体参照（2026-09-01 语义修正）的 UI 防回归测试：
// 主体=所选五行、观察支=爻支——木在亥长生、在卯帝旺。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao_engine/liuyao_engine.dart' as engine;

import 'package:liuyao_archive/src/features/casting/casting_models.dart';
import 'package:liuyao_archive/src/features/casting/chart_preview.dart';

void main() {
  Future<CastPreview> buildPreview() async {
    // 山天大畜（纳支 子寅辰戌子寅），三爻动。
    return CastPreview.fromEngineResult(
      engine.manualCast(DateTime(2026, 8, 4, 22, 22, 29), const [
        7,
        7,
        9,
        8,
        8,
        7,
      ]),
      question: '五行参照',
    );
  }

  String stageOf(WidgetTester tester, int position) {
    final finder = find.byKey(Key('base-growth-$position'));
    return tester.widget<Text>(finder.last).data ?? '';
  }

  testWidgets('五行主体参照驱动卦面小字（初爻子）', (tester) async {
    final preview = await buildPreview();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LiuyaoCoreChart(
              preview: preview,
              growthReference: 'element:木',
              onGrowthTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // 木在子沐浴、在寅临官、在辰衰、在戌养。
    expect(stageOf(tester, 1), '沐浴');
    expect(stageOf(tester, 2), '临官');
    expect(stageOf(tester, 3), '衰');
    expect(stageOf(tester, 4), '养');

    // 切换火：火在子胎、在寅长生、在辰冠带、在戌墓。
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LiuyaoCoreChart(
              preview: preview,
              growthReference: 'element:火',
              onGrowthTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(stageOf(tester, 1), '胎');
    expect(stageOf(tester, 2), '长生');
    expect(stageOf(tester, 3), '冠带');
    expect(stageOf(tester, 4), '墓');

    // 金与水不同值（金在子死、水在子帝旺）。
    for (final entry in const {'element:金': '死', 'element:水': '帝旺'}.entries) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LiuyaoCoreChart(
                preview: preview,
                growthReference: entry.key,
                onGrowthTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(stageOf(tester, 1), entry.value);
    }
  });

  testWidgets('十二长生账本参照 chips 分四柱与五行两排并联动卦面', (tester) async {
    final preview = await buildPreview();
    // 受控联动：账本 chips 与卦面小字共享 reference（同详情页结构）。
    var reference = 'day';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: Column(
                children: [
                  LiuyaoCoreChart(preview: preview, growthReference: reference),
                  LiuyaoTwelveStagesPanel(
                    preview: preview,
                    selectedReference: reference,
                    onReferenceChanged: (value) =>
                        setState(() => reference = value),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 两排 chips 均存在（四柱一排、五行一排）。
    for (final key in const [
      'growth-reference-year',
      'growth-reference-month',
      'growth-reference-day',
      'growth-reference-hour',
      'growth-reference-element:木',
      'growth-reference-element:火',
      'growth-reference-element:土',
      'growth-reference-element:金',
      'growth-reference-element:水',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: '缺少 $key');
    }

    // 点五行 chip 切换主体：卦面小字联动为该五行口径（初爻子：木→沐浴、金→死）。
    for (final entry in const {'element:木': '沐浴', 'element:金': '死'}.entries) {
      final chip = find.byKey(Key('growth-reference-${entry.key}'));
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      // 卦面小字可能在滚动容器外（chip 联动后回滚顶部再读）。
      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      scrollable.position.jumpTo(0);
      await tester.pumpAndSettle();
      expect(stageOf(tester, 1), entry.value);
    }
  });
}
