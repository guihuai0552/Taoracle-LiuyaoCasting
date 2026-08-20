import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao_archive/src/app.dart';
import 'package:liuyao_archive/src/features/almanac/almanac_client.dart';
import 'package:liuyao_archive/src/features/almanac/almanac_models.dart';
import 'package:liuyao_archive/src/features/almanac/almanac_page.dart';
import 'package:liuyao_archive/src/features/archive/archive_client.dart';
import 'package:liuyao_archive/src/features/archive/archive_image_export.dart';
import 'package:liuyao_archive/src/features/archive/archive_models.dart';
import 'package:liuyao_archive/src/features/archive/archive_page.dart';
import 'package:liuyao_archive/src/features/archive/case_detail_page.dart';
import 'package:liuyao_archive/src/features/casting/casting_client.dart';
import 'package:liuyao_archive/src/features/casting/casting_models.dart';
import 'package:liuyao_archive/src/features/casting/chart_preview.dart';
import 'package:liuyao_archive/src/features/casting/automatic_casting_page.dart';
import 'package:liuyao_archive/src/features/casting/manual_casting_page.dart';
import 'package:liuyao_archive/src/features/casting/time_pillar_casting_page.dart';
import 'package:liuyao_engine/liuyao_engine.dart' as liuyao_engine;

void main() {
  test('cast preview parses the automatic audit record', () {
    final preview = CastPreview.fromJson(
      _castJson(
        castAt: DateTime.parse('2026-07-26T15:30:00+08:00'),
        values: const [8, 7, 6, 8, 8, 7],
        baseName: '山水蒙',
        changedName: '山风蛊',
        method: 'three_coins',
        randomKind: 'seeded_test',
      ),
    );

    expect(preview.castingRecord.lines.first.coins, [2, 3, 3]);
    expect(preview.castingRecord.lines[2].traditionalName, '老阴');
    expect(preview.castingRecord.randomSource?.kind, 'seeded_test');
    expect(preview.baseHexagram, '山水蒙');
    expect(preview.changedHexagram, '山风蛊');
    expect(preview.schemaVersion, 13);
    expect(preview.chart.base.hiddenHexagram?.name, '坤为地');
    expect(preview.yearVoid, '寅卯');
    expect(preview.monthVoid, '辰巳');
    expect(preview.dayVoid, '寅卯');
    expect(preview.hourVoid, '辰巳');
    expect(preview.chart.base.lines[1].hidden?.relation, '父母');
    expect(preview.chart.base.lines.first.najia.earthlyBranch, '子');
    expect(
      preview
          .annotations
          .fiveElementTwelveStages
          .lineResults
          .first
          .pillarResults[2]
          .stage,
      '临官',
    );
    expect(preview.annotations.shenshaResults.first.status, 'computed_match');
    expect(
      preview.annotations.shenshaResults.first.matches.single.lineId,
      'base-5',
    );
    expect(preview.annotations.shenshaResults[1].targetBranches, ['午', '寅']);
    expect(
      preview.annotations.shenshaResults[1].matches.single.lineId,
      'base-2',
    );
    expect(preview.annotations.shenshaResults[2].basisType, 'day_branch');
    expect(preview.annotations.shenshaResults[2].basisValue, '亥');
    expect(preview.annotations.shenshaResults[2].targetBranches, ['巳']);
    expect(preview.annotations.shenshaResults[2].status, 'computed_no_match');
    expect(preview.annotations.shenshaResults[3].displayName, '桃花');
    expect(preview.annotations.shenshaResults[3].canonicalName, '咸池');
    expect(preview.annotations.shenshaResults[3].basisType, 'day_branch');
    expect(preview.annotations.shenshaResults[3].targetBranches, ['子']);
    expect(preview.annotations.shenshaResults[3].status, 'computed_match');
    expect(
      preview.annotations.shenshaResults[3].matches.single.lineId,
      'base-1',
    );
    expect(preview.annotations.shenshaResults[4].displayName, '将星');
    expect(preview.annotations.shenshaResults[4].basisType, 'day_branch');
    expect(preview.annotations.shenshaResults[4].targetBranches, ['卯']);
    expect(preview.annotations.shenshaResults[4].status, 'computed_no_match');
    expect(preview.annotations.shenshaResults[5].displayName, '华盖');
    expect(preview.annotations.shenshaResults[5].basisType, 'day_branch');
    expect(preview.annotations.shenshaResults[5].targetBranches, ['未']);
    expect(preview.annotations.shenshaResults[5].status, 'computed_match');
    expect(
      preview.annotations.shenshaResults[5].matches.single.lineId,
      'base-6',
    );
    expect(preview.annotations.twentyEightMansions?.worldMansion, '亢');
    expect(
      preview.annotations.twentyEightMansions?.placementAt(5)?.mansion,
      '亢',
    );
    expect(
      preview.calculationTrace.last.ruleId,
      'mansion.jingfang.world_line_and_six_lines.v1',
    );
  });

  testWidgets(
    'schema v16 renders three-layer annotations and changed Shi/Ying',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final preview = CastPreview.fromEngineResult(
        liuyao_engine.manualCast(DateTime(2026, 8, 4, 22, 22, 29), [
          7,
          7,
          9,
          8,
          8,
          7,
        ]),
        question: '验证七项标注与变卦世应',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LiuyaoChartPreview(preview: preview),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('body-marker-卦身')), findsOneWidget);
      expect(find.byKey(const Key('body-marker-命爻')), findsOneWidget);
      expect(find.text('天乙贵人'), findsWidgets);
      expect(find.text('将星'), findsNothing);
      for (var position = 1; position <= 6; position++) {
        expect(find.byKey(Key('hidden-mansion-$position')), findsOneWidget);
        expect(find.byKey(Key('changed-mansion-$position')), findsOneWidget);
        // 爻位标注行分段：纳音 · 十二长生 · 五星 · 二十八宿。
        final hiddenNayin = tester.widget<Text>(
          find.byKey(Key('hidden-nayin-$position')),
        );
        final baseNayin = tester.widget<Text>(
          find.byKey(Key('base-nayin-$position')),
        );
        final changedNayin = tester.widget<Text>(
          find.byKey(Key('changed-nayin-$position')),
        );
        expect(
          hiddenNayin.data,
          preview.chart.base.lines[position - 1].hidden!.najia.nayin,
        );
        expect(
          baseNayin.data,
          preview.chart.base.lines[position - 1].najia.nayin,
        );
        expect(
          changedNayin.data,
          preview.chart.changed!.lines[position - 1].najia.nayin,
        );
        // 三层各爻位均有十二长生与五星标注段。
        expect(find.byKey(Key('hidden-growth-$position')), findsOneWidget);
        expect(find.byKey(Key('base-growth-$position')), findsOneWidget);
        expect(find.byKey(Key('changed-growth-$position')), findsOneWidget);
        expect(find.byKey(Key('hidden-fivestar-$position')), findsOneWidget);
        expect(find.byKey(Key('base-fivestar-$position')), findsOneWidget);
        expect(find.byKey(Key('changed-fivestar-$position')), findsOneWidget);
      }
      expect(
        tester
            .widget<Text>(
              find.byKey(
                Key('changed-role-${preview.chart.changed!.shiPosition}'),
              ),
            )
            .data,
        '世',
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(
                Key('changed-role-${preview.chart.changed!.yingPosition}'),
              ),
            )
            .data,
        '应',
      );
    },
  );

  testWidgets('five stars mode renders the jingfang star ledger', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final preview = CastPreview.fromEngineResult(
      liuyao_engine.manualCast(DateTime(2026, 8, 4, 22, 22, 29), const [
        7,
        7,
        7,
        7,
        7,
        7,
      ]),
      question: '京房五星',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LiuyaoChartPreview(preview: preview),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('annotation-mode-switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('京房五星'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('five-stars-ledger')), findsOneWidget);
    expect(find.text('镇土星'), findsWidgets);
    expect(find.text('岁木星'), findsOneWidget);
    expect(find.text('世'), findsWidgets);

    // 爻位方向：上爻在上、初爻在下（与卦面爻线方向一致）。
    final ledger = find.byKey(const Key('five-stars-ledger'));
    final shangYaoY = tester
        .getTopLeft(
          find.descendant(of: ledger, matching: find.text('上爻')),
        )
        .dy;
    final chuYaoY = tester
        .getTopLeft(
          find.descendant(of: ledger, matching: find.text('初爻')),
        )
        .dy;
    expect(shangYaoY, lessThan(chuYaoY));
  });

  testWidgets('line glyph is uniform and moving marker sits in its own lane', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final preview = CastPreview.fromEngineResult(
      liuyao_engine.manualCast(DateTime(2026, 8, 4, 22, 22, 29), const [
        7,
        7,
        9,
        8,
        8,
        7,
      ]),
      question: '爻线统一',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LiuyaoChartPreview(preview: preview),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 动爻爻线（含动爻标志占位）与静爻爻线（无动爻标志）整体宽度一致。
    final movingGlyphSize = tester.getSize(
      find.byKey(const Key('base-glyph-3')),
    );
    final stillGlyphSize = tester.getSize(
      find.byKey(const Key('base-glyph-1')),
    );
    expect(movingGlyphSize.width, stillGlyphSize.width);
    expect(movingGlyphSize.height, stillGlyphSize.height);

    // 动爻标志位于爻线右侧，不与爻线重叠。
    final markerLeft = tester
        .getTopLeft(find.byKey(const Key('moving-marker-3')))
        .dx;
    final glyphLeft = tester
        .getTopLeft(find.byKey(const Key('base-glyph-3')))
        .dx;
    expect(markerLeft, greaterThan(glyphLeft));

    // 爻位标注行顺序：纳音 · 十二长生 · 五星 · 二十八宿。
    final nayin = tester
        .widget<Text>(find.byKey(const Key('base-nayin-1')))
        .data;
    final growth = tester
        .widget<Text>(find.byKey(const Key('base-growth-1')))
        .data;
    final fivestar = tester
        .widget<Text>(find.byKey(const Key('base-fivestar-1')))
        .data;
    final mansion = tester
        .widget<Text>(find.byKey(const Key('mansion-1')))
        .data;
    expect(nayin, isNotEmpty);
    expect(growth, isNotEmpty);
    expect(fivestar, isNotEmpty);
    expect(mansion, endsWith('宿'));
    final starShort = preview.annotations.fiveStars!.placementAt(1)!.star;
    expect(fivestar, switch (starShort) {
      '镇土' => '镇',
      '岁木' => '岁',
      _ => starShort,
    });
  });

  testWidgets('line annotation toggles hide and show segments', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final preview = CastPreview.fromEngineResult(
      liuyao_engine.manualCast(DateTime(2026, 8, 4, 22, 22, 29), const [
        7,
        7,
        7,
        7,
        7,
        7,
      ]),
      question: '信息开关',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LiuyaoChartPreview(preview: preview),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('base-nayin-1')), findsOneWidget);
    expect(find.byKey(const Key('base-growth-1')), findsOneWidget);

    // 细分开关：关闭纳音。
    await tester.ensureVisible(
      find.byKey(const Key('line-annotations-toggle')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('show-nayin')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('base-nayin-1')), findsNothing);
    expect(find.byKey(const Key('base-growth-1')), findsOneWidget);

    // 总开关：关闭全部。
    await tester.tap(find.byKey(const Key('line-annotations-switch')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('base-nayin-1')), findsNothing);
    expect(find.byKey(const Key('base-growth-1')), findsNothing);
    expect(find.byKey(const Key('base-fivestar-1')), findsNothing);
    expect(find.byKey(const Key('mansion-1')), findsNothing);

    // 重新打开总开关：纳音细分仍为关闭，其余恢复。
    await tester.tap(find.byKey(const Key('line-annotations-switch')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('base-nayin-1')), findsNothing);
    expect(find.byKey(const Key('base-growth-1')), findsOneWidget);
    expect(find.byKey(const Key('base-fivestar-1')), findsOneWidget);
  });

  testWidgets('tapping line growth switches reference and mode across layers', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final preview = CastPreview.fromEngineResult(
      liuyao_engine.manualCast(DateTime(2026, 8, 4, 22, 22, 29), const [
        7,
        7,
        9,
        8,
        8,
        7,
      ]),
      question: '参照联动',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LiuyaoChartPreview(preview: preview),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    String layerStage(
      HexagramLayerAnnotations? layer,
      int position,
      String ref,
    ) {
      final stages = layer == null
          ? preview.annotations.fiveElementTwelveStages
          : layer.fiveElementTwelveStages;
      for (final result in stages.lineResults) {
        if (result.position != position) continue;
        for (final pillar in result.pillarResults) {
          if (pillar.reference == ref) return pillar.stage;
        }
      }
      return '';
    }

    String layerStar(HexagramLayerAnnotations? layer, int position) {
      final stars = layer == null
          ? preview.annotations.fiveStars
          : layer.fiveStars;
      final star = stars?.placementAt(position)?.star;
      return switch (star) {
        '镇土' => '镇',
        '岁木' => '岁',
        _ => star ?? '',
      };
    }

    // 默认参照为日柱。
    expect(
      tester.widget<Text>(find.byKey(const Key('base-growth-1'))).data,
      layerStage(null, 1, 'day'),
    );

    // 点击本卦十二长生文字 → 弹出参照选择 → 选年柱。
    await tester.tap(find.byKey(const Key('base-growth-tap-1')));
    await tester.pumpAndSettle();
    expect(find.text('卦爻标注参照'), findsOneWidget);
    await tester.tap(find.byKey(const Key('growth-choice-year')));
    await tester.pumpAndSettle();

    // 伏神/本卦/变卦三层十二长生同步切换为年柱。
    expect(
      tester.widget<Text>(find.byKey(const Key('hidden-growth-1'))).data,
      layerStage(preview.annotations.hiddenHexagramAnnotations, 1, 'year'),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('base-growth-1'))).data,
      layerStage(null, 1, 'year'),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('changed-growth-1'))).data,
      layerStage(preview.annotations.changedHexagramAnnotations, 1, 'year'),
    );

    // 再点击 → 选京房五星 → 五星模式。
    await tester.tap(find.byKey(const Key('base-growth-tap-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('growth-choice-five_stars')));
    await tester.pumpAndSettle();

    // 本卦十二长生槽位显示五星短名，独立五星段隐藏避免重复。
    expect(
      tester.widget<Text>(find.byKey(const Key('base-growth-1'))).data,
      layerStar(null, 1),
    );
    expect(find.byKey(const Key('base-fivestar-1')), findsNothing);
    // 伏神/变卦同步切换为各自层五星。
    expect(
      tester.widget<Text>(find.byKey(const Key('hidden-growth-1'))).data,
      layerStar(preview.annotations.hiddenHexagramAnnotations, 1),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('changed-growth-1'))).data,
      layerStar(preview.annotations.changedHexagramAnnotations, 1),
    );
  });

  testWidgets('legacy schema v1 archive remains readable without recomputing', (
    tester,
  ) async {
    final preview = CastPreview.fromJson(_legacyCastJson());
    expect(preview.schemaVersion, 1);
    expect(preview.baseHexagram, '坎为水');
    expect(preview.changedHexagram, '雷地豫');
    expect(preview.lineValues, [8, 9, 8, 6, 9, 8]);
    expect(preview.rawJson['schema_version'], 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LiuyaoChartPreview(preview: preview, archived: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('legacy-snapshot-notice')), findsOneWidget);
    expect(find.text('坎为水 → 雷地豫'), findsOneWidget);
    expect(find.byKey(const Key('liuyao-chart-table')), findsOneWidget);
    expect(find.byKey(const Key('shensha-annotations')), findsNothing);
    expect(find.byKey(const Key('twelve-stages-ledger')), findsNothing);
    expect(find.byKey(const Key('chart-calculation-details')), findsNothing);
  });

  test('archive keeps the original +08:00 casting wall time', () {
    final detail = CaseDetail.fromJson({
      'id': 'legacy-time',
      'title': '旧档案时间',
      'question': '时间是否保持？',
      'castAt': '2026-07-26T15:30:00+08:00',
      'castingMethod': 'manual',
      'baseHexagram': '坎为水',
      'changedHexagram': '雷地豫',
      'latestAnalysisRevision': 0,
      'createdAt': '2026-07-26T00:11:37.124Z',
      'updatedAt': '2026-07-26T00:11:37.124Z',
      'chart': _legacyCastJson(),
      'analyses': const [],
      'feedbacks': const [],
    });
    expect(detail.castAt.hour, 15);
    expect(detail.castAt.minute, 30);
  });

  testWidgets('renders month calendar and the selected day details', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final source = _FakeAlmanacDataSource();
    await tester.pumpWidget(
      MaterialApp(
        home: AlmanacPage(
          dataSource: source,
          initialDate: DateTime(2026, 8, 5, 15),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2026年08月'), findsOneWidget);
    expect(find.byKey(const Key('almanac-month-grid')), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('六月廿三'), findsOneWidget);
    expect(find.text('丙午'), findsWidgets);
    expect(find.text('正东'), findsOneWidget);
    expect(source.lastDay, DateTime(2026, 8, 5));
    expect(source.lastHour, 15);
  });

  testWidgets('changes month, day and two-hour selection through the engine', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final source = _FakeAlmanacDataSource();
    await tester.pumpWidget(
      MaterialApp(
        home: AlmanacPage(
          dataSource: source,
          initialDate: DateTime(2026, 8, 5, 15),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('下个月'));
    await tester.pumpAndSettle();
    expect(find.text('2026年09月'), findsOneWidget);
    expect(source.lastMonth, (year: 2026, month: 9));

    await tester.tap(find.byKey(const Key('calendar-day-2026-09-06')));
    await tester.pumpAndSettle();
    expect(source.lastDay, DateTime(2026, 9, 6));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('two-hour-2')), findsOneWidget);
    await tester.tap(find.byKey(const Key('two-hour-2')));
    await tester.pumpAndSettle();
    expect(source.lastHour, 4);
  });

  testWidgets('almanac selected date flows into casting page', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final almanac = _FakeAlmanacDataSource();
    final casting = _FakeCastingDataSource();
    await tester.pumpWidget(
      LiuyaoArchiveApp(almanacDataSource: almanac, castingDataSource: casting),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('calendar-day-2026-08-09')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('六爻'));
    await tester.pumpAndSettle();

    expect(find.text('2026-08-09'), findsOneWidget);
  });

  testWidgets('year-month picker jumps to a specific month', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final source = _FakeAlmanacDataSource();
    await tester.pumpWidget(
      MaterialApp(
        home: AlmanacPage(
          dataSource: source,
          initialDate: DateTime(2026, 8, 5, 15),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('almanac-month-picker')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('year-month-picker-dialog')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('year-month-year-field')),
      '2031',
    );
    await tester.tap(find.byKey(const Key('year-month-month-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('12月').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('year-month-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('2031年12月'), findsOneWidget);
    expect(source.lastMonth, (year: 2031, month: 12));
  });

  testWidgets('uses the four-part product navigation without an agent tab', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final source = _FakeAlmanacDataSource();
    final castingSource = _FakeCastingDataSource();
    await tester.pumpWidget(
      LiuyaoArchiveApp(
        almanacDataSource: source,
        castingDataSource: castingSource,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('日历'), findsOneWidget);
    expect(find.text('六爻'), findsOneWidget);
    expect(find.text('档案'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('助手'), findsNothing);

    await tester.tap(find.text('六爻'));
    await tester.pumpAndSettle();
    expect(find.text('手动起卦'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('casting-question')), '保留这条草稿');
    await tester.tap(find.byKey(const Key('line-toggle-6')));
    await tester.tap(find.text('日历'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('六爻'));
    await tester.pumpAndSettle();

    final question = tester.widget<TextField>(
      find.byKey(const Key('casting-question')),
    );
    expect(question.controller?.text, '保留这条草稿');
    expect(find.text('7 · 7 · 7 · 7 · 7 · 8'), findsOneWidget);

    await tester.tap(find.text('自动铜钱'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('automatic-casting-title')), findsOneWidget);
    await tester.tap(find.text('手动'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('casting-question')))
          .controller
          ?.text,
      '保留这条草稿',
    );

    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-title')), findsOneWidget);
    expect(find.byKey(const Key('settings-local-data-card')), findsOneWidget);
    expect(find.text('档案保存在本机'), findsOneWidget);
  });

  testWidgets('manual editor serializes top-down edits bottom-to-top', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final source = _FakeCastingDataSource();
    final archive = _FakeArchiveDataSource();
    await tester.pumpWidget(
      MaterialApp(
        home: ManualCastingPage(
          dataSource: source,
          archiveDataSource: archive,
          initialDateTime: DateTime(2026, 8, 5, 15, 26),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('7 · 7 · 7 · 7 · 7 · 7'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('casting-question')),
      '此事后续如何？',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.byKey(const Key('line-toggle-6')),
      find.byKey(const Key('manual-casting-scroll')),
      const Offset(0, -150),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('line-toggle-6')));
    await tester.tap(find.byKey(const Key('line-moving-6')));
    await tester.dragUntilVisible(
      find.byKey(const Key('line-moving-1')),
      find.byKey(const Key('manual-casting-scroll')),
      const Offset(0, -150),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('line-moving-1')));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.byKey(const Key('review-cast')),
      find.byKey(const Key('manual-casting-scroll')),
      const Offset(0, -150),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('review-cast')));
    await tester.pumpAndSettle();

    expect(find.text('记录顺序：初爻 → 上爻'), findsOneWidget);
    expect(find.text('1 · 9'), findsOneWidget);
    expect(find.text('6 · 6'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-manual-cast')));
    await tester.pumpAndSettle();

    expect(source.callCount, 1);
    expect(source.lastQuestion, '此事后续如何？');
    expect(source.lastDateTime, DateTime(2026, 8, 5, 15, 26));
    expect(source.lastLineValues, [9, 7, 7, 7, 7, 6]);
    expect(archive.saveCount, 1);
    expect(archive.detail.chart.lineValues, [9, 7, 7, 7, 7, 6]);
    expect(find.byKey(const Key('case-result-title')), findsOneWidget);
    expect(find.byKey(const Key('auto-archive-banner')), findsOneWidget);
    expect(find.text('泽天夬 → 天风姤'), findsOneWidget);
    expect(find.byKey(const Key('liuyao-chart-table')), findsOneWidget);
    expect(find.byKey(const Key('base-hexagram-summary')), findsOneWidget);
    expect(find.byKey(const Key('changed-hexagram-summary')), findsOneWidget);
    expect(find.byKey(const Key('hidden-hexagram-summary')), findsOneWidget);
    expect(find.byKey(const Key('mansion-world-summary')), findsOneWidget);
    expect(find.text('坤为地'), findsOneWidget);
    expect(find.byKey(const Key('pillar-time-panel')), findsOneWidget);
    expect(find.byKey(const Key('time-year-stem')), findsOneWidget);
    expect(find.byKey(const Key('time-hour-void')), findsOneWidget);
    expect(find.text('白虎'), findsOneWidget);
    expect(find.text('妻财'), findsWidgets);
    expect(find.text('/ 坤宫·6'), findsOneWidget);
    expect(find.text('/ 乾宫·2'), findsOneWidget);
    expect(find.byKey(const Key('chart-line-6')), findsOneWidget);
    for (var position = 1; position <= 6; position++) {
      expect(find.byKey(Key('hidden-$position')), findsOneWidget);
      expect(find.byKey(Key('mansion-$position')), findsOneWidget);
    }
    expect(
      tester.widget<Text>(find.byKey(const Key('moving-marker-1'))).data,
      'Ｏ',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('moving-marker-6'))).data,
      'Χ',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('base-stem-1'))).style?.color,
      const Color(0xFF347445),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('base-branch-1'))).style?.color,
      const Color(0xFF216B9B),
    );
    expect(find.byKey(const Key('result-twelve-section')), findsOneWidget);
    expect(find.byKey(const Key('result-shensha-section')), findsOneWidget);
    expect(find.byKey(const Key('result-chart-card')), findsOneWidget);
  });

  testWidgets('manual editor validates question and confirms reset', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final source = _FakeCastingDataSource();
    await tester.pumpWidget(
      MaterialApp(
        home: ManualCastingPage(
          dataSource: source,
          initialDateTime: DateTime(2026, 8, 5, 15, 26),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.byKey(const Key('line-toggle-6')),
      find.byKey(const Key('manual-casting-scroll')),
      const Offset(0, -150),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('line-toggle-6')));
    await tester.dragUntilVisible(
      find.byKey(const Key('review-cast')),
      find.byKey(const Key('manual-casting-scroll')),
      const Offset(0, -150),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('review-cast')));
    await tester.pumpAndSettle();
    expect(find.text('请先填写占问事项'), findsOneWidget);
    expect(source.callCount, 0);

    await tester.dragUntilVisible(
      find.byKey(const Key('reset-lines')),
      find.byKey(const Key('manual-casting-scroll')),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reset-lines')));
    await tester.pumpAndSettle();
    expect(find.text('重置六爻？'), findsOneWidget);
    await tester.tap(find.text('确认重置'));
    await tester.pumpAndSettle();
    expect(find.text('7 · 7 · 7 · 7 · 7 · 7'), findsOneWidget);
  });

  testWidgets('automatic casting auto-archives and shows every raw coin', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final source = _FakeCastingDataSource();
    final archive = _FakeArchiveDataSource();
    await tester.pumpWidget(
      MaterialApp(
        home: AutomaticCastingPage(
          dataSource: source,
          archiveDataSource: archive,
          initialDateTime: DateTime(2026, 8, 5, 15, 26),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('automatic-question')),
      '自动铜钱如何记录？',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('automatic-cast')));
    await tester.pumpAndSettle();
    expect(find.text('开始自动起卦？'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-automatic-cast')));
    await tester.pumpAndSettle();

    expect(source.automaticCallCount, 1);
    expect(source.lastQuestion, '自动铜钱如何记录？');
    expect(archive.saveCount, 1);
    // 背景问念默认空白（2026-08-20 需求），不自动回填 question。
    expect(archive.detail.question, '自动铜钱如何记录？');
    expect(archive.detail.questionContext, '');
    expect(find.byKey(const Key('case-result-title')), findsOneWidget);
    expect(find.byKey(const Key('auto-archive-banner')), findsOneWidget);
    expect(find.byKey(const Key('liuyao-chart-table')), findsOneWidget);
    expect(
      find.byKey(const Key('result-casting-record-section')),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(const Key('result-casting-record-section')),
    );
    await tester.tap(find.byKey(const Key('result-casting-record-section')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('coin-line-1')), findsOneWidget);
    expect(find.text('2 + 3 + 3 = 8'), findsOneWidget);
    expect(find.textContaining('系统随机'), findsOneWidget);
  });

  testWidgets('time pillar casting auto-archives and records method', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final source = _FakeCastingDataSource();
    final archive = _FakeArchiveDataSource();
    await tester.pumpWidget(
      MaterialApp(
        home: TimePillarCastingPage(
          dataSource: source,
          archiveDataSource: archive,
          initialDateTime: DateTime(2026, 8, 5, 15, 26),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('time-pillar-casting-title')), findsOneWidget);
    // 附件《时刻起卦法详解》新口径：一时辰十二刻、每刻十分钟。
    expect(find.textContaining('一时辰十二刻'), findsOneWidget);
    expect(find.textContaining('内卦 = 时支后天八卦'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('time-pillar-question')),
      '此刻是否适合出行？',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('review-time-pillar-cast')));
    await tester.pumpAndSettle();
    expect(find.text('确认起卦'), findsOneWidget);
    expect(find.textContaining('时刻起卦法'), findsWidgets);
    await tester.tap(find.text('确认排盘'));
    await tester.pumpAndSettle();

    expect(source.callCount, 1);
    expect(source.lastQuestion, '此刻是否适合出行？');
    expect(archive.saveCount, 1);
    expect(find.byKey(const Key('case-result-title')), findsOneWidget);
    expect(archive.detail.castingMethod, 'time_pillar');
  });

  testWidgets(
    'manual casting with manual four pillars saves source and values',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final source = _FakeCastingDataSource();
      final archive = _FakeArchiveDataSource();
      await tester.pumpWidget(
        MaterialApp(
          home: ManualCastingPage(
            dataSource: source,
            archiveDataSource: archive,
            initialDateTime: DateTime(2026, 8, 5, 15, 26),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('casting-question')),
        '手动四柱测试',
      );
      tester.testTextInput.hide();
      await tester.pumpAndSettle();

      // 切到手动填写
      await tester.tap(find.text('手动填写'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('manual-four-pillars-editor')),
        findsOneWidget,
      );

      // 修改年柱天干为乙
      await tester.tap(find.byKey(const Key('manual-year-gan')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('乙').last);
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.byKey(const Key('review-cast')),
        find.byKey(const Key('manual-casting-scroll')),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('review-cast')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-manual-cast')));
      await tester.pumpAndSettle();

      expect(archive.saveCount, 1);
      expect(archive.detail.fourPillarsContext['source'], 'manual');
      expect(archive.detail.chart.yearPillar, '乙子');
      expect(
        (archive.detail.fourPillarsContext['calculated']
            as Map<String, dynamic>)['year'],
        '丙午',
      );
      expect(
        (archive.detail.fourPillarsContext['manual']
            as Map<String, dynamic>)['year_gan'],
        '乙',
      );
    },
  );

  testWidgets('manual casting passes selected calendar boundary policy', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final source = _FakeCastingDataSource();
    final archive = _FakeArchiveDataSource();
    await tester.pumpWidget(
      MaterialApp(
        home: ManualCastingPage(
          dataSource: source,
          archiveDataSource: archive,
          initialDateTime: DateTime(2026, 8, 5, 15, 26),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('casting-question')), '边界策略测试');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();

    // 交日切换为「子正0点换日」
    await tester.tap(find.byKey(const Key('day-boundary-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('子正0点换日'));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.byKey(const Key('review-cast')),
      find.byKey(const Key('manual-casting-scroll')),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('review-cast')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-manual-cast')));
    await tester.pumpAndSettle();

    expect(source.lastDayBoundary, 'astronomical_midnight');
    expect(source.lastMonthBoundary, 'solar_term_zi_hour');
  });

  testWidgets(
    'archive opens the frozen chart and edits analysis and feedback',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final archive = _FakeArchiveDataSource.withCase();
      await tester.pumpWidget(
        MaterialApp(home: ArchivePage(dataSource: archive)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('archive-title')), findsOneWidget);
      expect(find.text('工作是否顺利推进？'), findsOneWidget);
      expect(find.byKey(const Key('archive-seal-case-1')), findsOneWidget);
      expect(find.byKey(const Key('archive-question-case-1')), findsOneWidget);
      expect(find.byKey(const Key('archive-time-case-1')), findsOneWidget);
      expect(
        find.byKey(const Key('archive-transition-case-1')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('archive-transfer')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('transfer-export-all')), findsOneWidget);
      expect(find.byKey(const Key('transfer-import')), findsOneWidget);
      expect(find.textContaining('全部解读版本和反馈记录'), findsOneWidget);
      await tester.tap(find.byType(ModalBarrier).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('archive-case-case-1')));
      await tester.pumpAndSettle();

      expect(find.text('泽天夬 → 天风姤'), findsOneWidget);
      expect(find.byKey(const Key('result-chart-card')), findsOneWidget);
      expect(find.byKey(const Key('result-twelve-section')), findsOneWidget);
      expect(find.byKey(const Key('result-shensha-section')), findsOneWidget);
      expect(find.text('带此卦例询问 Agent'), findsNothing);
      expect(find.byKey(const Key('case-export')), findsOneWidget);
      await tester.tap(find.byKey(const Key('case-export')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('export-markdown')), findsOneWidget);
      expect(find.byKey(const Key('export-json')), findsOneWidget);
      expect(find.byKey(const Key('export-image')), findsOneWidget);
      await tester.tap(find.byType(ModalBarrier).last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('case-detail-scroll')), findsOneWidget);

      final detailScrollable = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(const Key('case-detail-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      detailScrollable.position.jumpTo(
        detailScrollable.position.maxScrollExtent,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('result-analysis-section')), findsOneWidget);
      expect(find.byKey(const Key('result-feedback-section')), findsOneWidget);
      await tester.tap(find.byKey(const Key('result-analysis-section')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('analysis-editor')));
      await tester.enterText(
        find.byKey(const Key('analysis-editor')),
        '先看世应，再结合动爻判断。',
      );
      await tester.ensureVisible(find.byKey(const Key('save-analysis')));
      await tester.tap(find.byKey(const Key('save-analysis')));
      await tester.pumpAndSettle();
      expect(archive.detail.analyses.single.revision, 1);

      detailScrollable.position.jumpTo(
        detailScrollable.position.maxScrollExtent,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('result-feedback-section')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('add-first-feedback')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-first-feedback')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('feedback-body')),
        '第一阶段已经按计划完成。',
      );
      await tester.tap(find.byKey(const Key('save-feedback')));
      await tester.pumpAndSettle();
      expect(archive.detail.feedbacks.single.body, '第一阶段已经按计划完成。');
      expect(find.text('第一阶段已经按计划完成。'), findsOneWidget);
    },
  );

  testWidgets(
    'detail page tapping line growth switches reference across three layers',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final detail = _engineCaseDetail();
      final archive = _FakeArchiveDataSource();
      await tester.pumpWidget(
        MaterialApp(
          home: CaseDetailPage(client: archive, initialDetail: detail),
        ),
      );
      await tester.pumpAndSettle();

      final preview = detail.chart;

      String layerStage(
        HexagramLayerAnnotations? layer,
        int position,
        String ref,
      ) {
        final stages = layer == null
            ? preview.annotations.fiveElementTwelveStages
            : layer.fiveElementTwelveStages;
        for (final result in stages.lineResults) {
          if (result.position != position) continue;
          for (final pillar in result.pillarResults) {
            if (pillar.reference == ref) return pillar.stage;
          }
        }
        return '';
      }

      String layerStar(HexagramLayerAnnotations? layer, int position) {
        final stars = layer == null
            ? preview.annotations.fiveStars
            : layer.fiveStars;
        final star = stars?.placementAt(position)?.star;
        return switch (star) {
          '镇土' => '镇',
          '岁木' => '岁',
          _ => star ?? '',
        };
      }

      // 滚动到本卦爻位标注（卦面卡片内）。
      await _scrollTo(tester, const Key('base-growth-tap-1'));

      // 默认参照为日柱。
      expect(
        tester.widget<Text>(find.byKey(const Key('base-growth-1'))).data,
        layerStage(null, 1, 'day'),
      );

      // 点击本卦爻位标注十二长生文字 → 弹出参照选择 → 选年柱。
      await tester.ensureVisible(find.byKey(const Key('base-growth-tap-1')));
      await tester.tap(find.byKey(const Key('base-growth-tap-1')));
      await tester.pumpAndSettle();
      expect(find.text('卦爻标注参照'), findsOneWidget);
      await tester.tap(find.byKey(const Key('growth-choice-year')));
      await tester.pumpAndSettle();

      // 伏神/本卦/变卦三层同步切换为年柱。
      expect(
        tester.widget<Text>(find.byKey(const Key('hidden-growth-1'))).data,
        layerStage(preview.annotations.hiddenHexagramAnnotations, 1, 'year'),
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('base-growth-1'))).data,
        layerStage(null, 1, 'year'),
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('changed-growth-1'))).data,
        layerStage(preview.annotations.changedHexagramAnnotations, 1, 'year'),
      );

      // 再次点击 → 选京房五星，三层标注切换为五星短名。
      await tester.ensureVisible(find.byKey(const Key('base-growth-tap-1')));
      await tester.tap(find.byKey(const Key('base-growth-tap-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('growth-choice-five_stars')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('base-growth-1'))).data,
        layerStar(null, 1),
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('hidden-growth-1'))).data,
        layerStar(preview.annotations.hiddenHexagramAnnotations, 1),
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('changed-growth-1'))).data,
        layerStar(preview.annotations.changedHexagramAnnotations, 1),
      );
    },
  );

  testWidgets('detail page line annotation toggle hides and shows segments', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final detail = _engineCaseDetail();
    final archive = _FakeArchiveDataSource();
    await tester.pumpWidget(
      MaterialApp(
        home: CaseDetailPage(client: archive, initialDetail: detail),
      ),
    );
    await tester.pumpAndSettle();

    // 滚动到卦面爻位标注，确认四段标注默认可见。
    await _scrollTo(tester, const Key('base-nayin-1'));
    expect(find.byKey(const Key('base-nayin-1')), findsOneWidget);
    expect(find.byKey(const Key('base-growth-1')), findsOneWidget);
    expect(find.byKey(const Key('base-fivestar-1')), findsOneWidget);
    expect(find.byKey(const Key('mansion-1')), findsOneWidget);

    // 滚动到开关面板。
    await _scrollTo(tester, const Key('line-annotations-toggle'));

    // 细分开关：关闭纳音。
    await tester.tap(find.byKey(const Key('show-nayin')));
    await tester.pumpAndSettle();
    await _scrollTo(tester, const Key('base-growth-1'));
    expect(find.byKey(const Key('base-nayin-1')), findsNothing);
    expect(find.byKey(const Key('base-growth-1')), findsOneWidget);

    // 总开关：关闭全部。
    await _scrollTo(tester, const Key('line-annotations-toggle'));
    await tester.tap(find.byKey(const Key('line-annotations-switch')));
    await tester.pumpAndSettle();
    await _scrollTo(tester, const Key('result-chart-card'));
    expect(find.byKey(const Key('base-nayin-1')), findsNothing);
    expect(find.byKey(const Key('base-growth-1')), findsNothing);
    expect(find.byKey(const Key('base-fivestar-1')), findsNothing);
    expect(find.byKey(const Key('mansion-1')), findsNothing);

    // 重新打开总开关：纳音细分仍为关闭，其余恢复。
    await _scrollTo(tester, const Key('line-annotations-toggle'));
    await tester.tap(find.byKey(const Key('line-annotations-switch')));
    await tester.pumpAndSettle();
    await _scrollTo(tester, const Key('base-fivestar-1'));
    expect(find.byKey(const Key('base-nayin-1')), findsNothing);
    expect(find.byKey(const Key('base-growth-1')), findsOneWidget);
    expect(find.byKey(const Key('base-fivestar-1')), findsOneWidget);
    expect(find.byKey(const Key('mansion-1')), findsOneWidget);
  });

  testWidgets('archive image export produces a complete PNG document', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final archive = _FakeArchiveDataSource.withCase();
    await archive.appendUserAnalysis(
      caseId: archive.detail.id,
      body: '图片中的完整解读',
      expectedRevision: 0,
    );
    await archive.appendFeedback(
      caseId: archive.detail.id,
      body: '图片中的反馈',
      status: 'partial',
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SizedBox(key: Key('anchor'))),
      ),
    );
    await tester.pumpAndSettle();

    final bytes = await tester.runAsync(() async {
      final image = await buildCaseArchivePng(
        tester.element(find.byKey(const Key('anchor'))),
        archive.detail,
      );
      return image;
    });
    expect(bytes, isNotNull);
    expect(bytes!.length, greaterThan(1000));
    expect(bytes.take(8).toList(), [137, 80, 78, 71, 13, 10, 26, 10]);
  });
}

class _FakeAlmanacDataSource implements AlmanacDataSource {
  ({int year, int month})? lastMonth;
  DateTime? lastDay;
  int? lastHour;

  @override
  Future<AlmanacMonth> loadMonth({
    required int year,
    required int month,
  }) async {
    lastMonth = (year: year, month: month);
    final first = DateTime(year, month);
    final start = first.subtract(Duration(days: first.weekday - 1));
    return AlmanacMonth(
      year: year,
      month: month,
      cells: List.generate(42, (index) {
        final date = start.add(Duration(days: index));
        final isFifth = date.day == 5;
        return AlmanacDayCell(
          date: date,
          solarDay: date.day,
          weekday: date.weekday,
          inCurrentMonth: date.month == month,
          available: true,
          lunar: AlmanacLunarDate(
            month: 6,
            day: isFifth ? 23 : 24,
            isLeapMonth: false,
            monthCn: '六月',
            dayCn: isFifth ? '廿三' : '廿四',
          ),
          dayPillar: const AlmanacPillar(
            position: 'day',
            ganzhi: '辛亥',
            stem: '辛',
            branch: '亥',
            nayin: '钗钏金',
          ),
          solarTerm: date.month == 8 && date.day == 7 ? '立秋' : null,
        );
      }),
    );
  }

  @override
  Future<AlmanacSnapshot> loadDay({
    required DateTime date,
    required int hour,
  }) async {
    lastDay = date;
    lastHour = hour;
    final selectedIndex = hour == 23 ? 12 : (hour + 1) ~/ 2;
    const branches = [
      '子',
      '丑',
      '寅',
      '卯',
      '辰',
      '巳',
      '午',
      '未',
      '申',
      '酉',
      '戌',
      '亥',
      '子',
    ];
    return AlmanacSnapshot(
      solarDate: date,
      weekday: '星期三',
      localDateTime: DateTime(date.year, date.month, date.day, hour),
      lunar: const AlmanacLunarDate(
        month: 6,
        day: 23,
        isLeapMonth: false,
        monthCn: '六月',
        dayCn: '廿三',
        yearCn: '二零二六',
        zodiac: '马',
      ),
      fourPillars: const [
        AlmanacPillar(
          position: 'year',
          ganzhi: '丙午',
          stem: '丙',
          branch: '午',
          nayin: '天河水',
        ),
        AlmanacPillar(
          position: 'month',
          ganzhi: '乙未',
          stem: '乙',
          branch: '未',
          nayin: '沙中金',
        ),
        AlmanacPillar(
          position: 'day',
          ganzhi: '辛亥',
          stem: '辛',
          branch: '亥',
          nayin: '钗钏金',
        ),
        AlmanacPillar(
          position: 'hour',
          ganzhi: '丙申',
          stem: '丙',
          branch: '申',
          nayin: '山下火',
        ),
      ],
      twoHourPillars: List.generate(
        13,
        (index) => AlmanacTwoHourPillar(
          index: index,
          ganzhi: '丙${branches[index]}',
          stem: '丙',
          branch: branches[index],
          selected: index == selectedIndex,
        ),
      ),
      currentTwoHourIndex: selectedIndex,
      wealthGodDirection: '正东',
    );
  }

  @override
  void close() {}
}

class _FakeCastingDataSource implements CastingDataSource {
  int callCount = 0;
  int automaticCallCount = 0;
  String? lastQuestion;
  DateTime? lastDateTime;
  List<int>? lastLineValues;
  String? lastDayBoundary;
  String? lastMonthBoundary;

  @override
  Future<CastPreview> previewManual({
    required String question,
    required DateTime dateTime,
    required List<int> lineValues,
    String dayBoundary = liuyao_engine.dayBoundaryCivil23NextDay,
    String monthBoundary = liuyao_engine.monthBoundarySolarTermZiHour,
  }) async {
    callCount += 1;
    lastQuestion = question;
    lastDateTime = dateTime;
    lastLineValues = List.of(lineValues);
    lastDayBoundary = dayBoundary;
    lastMonthBoundary = monthBoundary;
    return CastPreview.fromJson(
      _castJson(
        castAt: dateTime,
        values: lineValues,
        baseName: '泽天夬',
        changedName: '天风姤',
        method: 'manual',
      ),
    );
  }

  @override
  Future<CastPreview> previewTimePillar({
    required String question,
    required DateTime dateTime,
    String dayBoundary = liuyao_engine.dayBoundaryCivil23NextDay,
    String monthBoundary = liuyao_engine.monthBoundarySolarTermZiHour,
  }) async {
    callCount += 1;
    lastQuestion = question;
    lastDateTime = dateTime;
    lastDayBoundary = dayBoundary;
    lastMonthBoundary = monthBoundary;
    const values = [9, 7, 8, 7, 8, 7];
    lastLineValues = List.of(values);
    return CastPreview.fromJson(
      _castJson(
        castAt: dateTime,
        values: values,
        baseName: '天风姤',
        changedName: '泽风大过',
        method: 'time_pillar',
      ),
    );
  }

  @override
  Future<CastPreview> previewAutomatic({
    required String question,
    required DateTime dateTime,
    Object? seed,
    String dayBoundary = liuyao_engine.dayBoundaryCivil23NextDay,
    String monthBoundary = liuyao_engine.monthBoundarySolarTermZiHour,
  }) async {
    callCount += 1;
    automaticCallCount += 1;
    lastQuestion = question;
    lastDateTime = dateTime;
    const coinLines = [
      [2, 3, 3],
      [2, 3, 2],
      [2, 2, 2],
      [3, 3, 2],
      [3, 2, 3],
      [3, 2, 2],
    ];
    const values = [8, 7, 6, 8, 8, 7];
    lastLineValues = List.of(values);
    return CastPreview.fromJson(
      _castJson(
        castAt: dateTime,
        values: values,
        baseName: '雷水解',
        changedName: '雷风恒',
        method: 'three_coins',
        coinLines: coinLines,
        randomKind: 'system',
      ),
    );
  }

  @override
  void close() {}
}

class _FakeArchiveDataSource implements ArchiveDataSource {
  _FakeArchiveDataSource() : detail = _detailFrom();

  _FakeArchiveDataSource.withCase()
    : detail = _detailFrom(question: '工作是否顺利推进？');

  int saveCount = 0;
  late CaseDetail detail;
  final List<Map<String, dynamic>> _analyses = [];
  final List<Map<String, dynamic>> _feedbacks = [];

  static CaseDetail _detailFrom({String question = '此事后续如何？'}) {
    final now = DateTime(2026, 8, 5, 15, 26);
    return CaseDetail.fromJson({
      'id': 'case-1',
      'title': '测试档案',
      'question': question,
      'castAt': now.toIso8601String(),
      'castingMethod': 'manual',
      'baseHexagram': '泽天夬',
      'changedHexagram': '天风姤',
      'latestAnalysisRevision': 0,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'chart': _castJson(
        castAt: now,
        values: const [9, 7, 7, 7, 7, 6],
        baseName: '泽天夬',
        changedName: '天风姤',
        method: 'manual',
      ),
      'analyses': const [],
      'feedbacks': const [],
    });
  }

  void _rebuild({
    Map<String, dynamic>? chart,
    String? questionContext,
    List<String>? tags,
  }) {
    final json = <String, dynamic>{
      'id': detail.id,
      'title': detail.title,
      'question': detail.question,
      'castAt': detail.castAt.toIso8601String(),
      'castingMethod': detail.castingMethod,
      'baseHexagram': detail.baseHexagram,
      'changedHexagram': detail.changedHexagram,
      'latestAnalysisRevision': _analyses.length,
      'createdAt': detail.createdAt.toIso8601String(),
      'updatedAt': DateTime(2026, 8, 6).toIso8601String(),
      'questionContext': questionContext ?? detail.questionContext,
      'tags': tags ?? detail.tags,
      'chart': chart ?? detail.chartJson,
      'analyses': _analyses,
      'feedbacks': _feedbacks,
    };
    detail = CaseDetail.fromJson(json);
  }

  @override
  Future<List<CaseSummary>> listCases({
    String query = '',
    List<String> tags = const [],
  }) async {
    if (tags.isNotEmpty) {
      return detail.tags.toSet().containsAll(tags) ? [detail] : const [];
    }
    return [detail];
  }

  @override
  Future<void> updateTags({
    required String caseId,
    required List<String> tags,
  }) async {
    _rebuild(tags: tags);
  }

  @override
  Future<CaseDetail> saveCast({
    String title = '',
    required String question,
    required CastPreview preview,
  }) async {
    saveCount += 1;
    detail = CaseDetail.fromJson({
      'id': 'case-1',
      'title': title.isEmpty ? question : title,
      'question': question,
      'castAt': preview.castAt.toIso8601String(),
      'castingMethod': preview.castingRecord.method,
      'baseHexagram': preview.baseHexagram,
      'changedHexagram': preview.changedHexagram,
      'latestAnalysisRevision': 0,
      'createdAt': DateTime(2026, 8, 5).toIso8601String(),
      'updatedAt': DateTime(2026, 8, 5).toIso8601String(),
      'fourPillarsContext': <String, dynamic>{
        'source': preview.fourPillarsSource,
        'calculated': <String, String>{
          'year':
              (preview.rawJson['time'] as Map<String, dynamic>)['year']
                  as String? ??
              preview.yearPillar,
          'month':
              (preview.rawJson['time'] as Map<String, dynamic>)['month']
                  as String? ??
              preview.monthPillar,
          'day':
              (preview.rawJson['time'] as Map<String, dynamic>)['day']
                  as String? ??
              preview.dayPillar,
          'hour':
              (preview.rawJson['time'] as Map<String, dynamic>)['hour']
                  as String? ??
              preview.hourPillar,
        },
        'manual': preview.manualFourPillars?.toJson(),
      },
      'chart': preview.fourPillarsSource == 'manual'
          ? <String, dynamic>{
              ...preview.rawJson,
              'time': <String, dynamic>{
                ...preview.rawJson['time'] as Map<String, dynamic>,
                'year': preview.yearPillar,
                'month': preview.monthPillar,
                'day': preview.dayPillar,
                'hour': preview.hourPillar,
              },
            }
          : preview.rawJson,
      'analyses': const [],
      'feedbacks': const [],
    });
    return detail;
  }

  @override
  Future<CaseDetail> getCase(String id) async => detail;

  @override
  Future<void> updateQuestionContext({
    required String caseId,
    required String context,
  }) async {
    _rebuild(questionContext: context);
  }

  @override
  Future<void> appendUserAnalysis({
    required String caseId,
    required String body,
    required int expectedRevision,
  }) async {
    _analyses.add({
      'id': 'analysis-${_analyses.length + 1}',
      'author': 'user',
      'body': body,
      'revision': _analyses.length + 1,
      'createdAt': DateTime(2026, 8, 6).toIso8601String(),
    });
    _rebuild();
  }

  @override
  Future<void> appendFeedback({
    required String caseId,
    required String body,
    required String status,
    DateTime? occurredAt,
  }) async {
    _feedbacks.add({
      'id': 'feedback-${_feedbacks.length + 1}',
      'body': body,
      'status': status,
      'occurredAt': occurredAt?.toIso8601String(),
      'createdAt': DateTime(2026, 8, 6).toIso8601String(),
      'updatedAt': DateTime(2026, 8, 6).toIso8601String(),
    });
    _rebuild();
  }

  @override
  Future<void> updateFeedback({
    required String caseId,
    required String feedbackId,
    required String body,
    required String status,
    DateTime? occurredAt,
  }) async {
    final index = _feedbacks.indexWhere((item) => item['id'] == feedbackId);
    _feedbacks[index] = {
      ..._feedbacks[index],
      'body': body,
      'status': status,
      'occurredAt': occurredAt?.toIso8601String(),
    };
    _rebuild();
  }

  @override
  Future<CaseExportFile> exportCase(
    String id, {
    required String format,
  }) async => CaseExportFile(
    filename: 'case.$format',
    contentType: format == 'json' ? 'application/json' : 'text/markdown',
    content: 'export',
  );

  @override
  Future<CaseExportFile> exportAllCases() async => const CaseExportFile(
    filename: 'all.json',
    contentType: 'application/json',
    content: '{"cases":[]}',
  );

  @override
  Future<ArchiveImportPreview> inspectImport(String content) async =>
      const ArchiveImportPreview(
        totalCases: 1,
        newCases: 1,
        identicalCases: 0,
        conflictingCases: 0,
        analysisCount: 0,
        feedbackCount: 0,
        sourceLabel: '测试迁移包',
      );

  @override
  Future<ArchiveImportResult> importCases(
    String content, {
    required ArchiveImportMode mode,
  }) async => const ArchiveImportResult(
    importedCases: 1,
    skippedCases: 0,
    copiedConflicts: 0,
    replacedExistingCases: 0,
  );

  @override
  void close() {}
}

Map<String, dynamic> _legacyCastJson() {
  const values = [8, 9, 8, 6, 9, 8];
  const gods = ['白虎', '玄武', '青龙', '朱雀', '勾陈', '螣蛇'];
  const relations = ['子孙', '官鬼', '妻财', '父母', '官鬼', '兄弟'];
  const branches = ['戊寅', '戊辰', '戊午', '戊申', '戊戌', '戊子'];
  const elements = ['木', '土', '火', '金', '土', '水'];
  const changedRelations = ['官鬼', '妻财', '子孙', '妻财', '父母', '官鬼'];
  const changedBranches = ['乙未', '乙巳', '乙卯', '庚午', '庚申', '庚戌'];
  const changedElements = ['土', '火', '木', '火', '金', '土'];
  return {
    'schema_version': 1,
    'engine_version': '0.1.0+najia-2.0.1',
    'meta': {
      'cast_at': '2026-07-26T15:30:00+08:00',
      'casting_method': 'manual',
      'line_order': 'bottom_to_top',
      'line_values': values,
    },
    'time': {
      'year': '丙午',
      'month': '乙未',
      'day': '辛亥',
      'hour': '丙申',
      'day_void': '寅卯',
    },
    'hexagram': {
      'base': {
        'name': '坎为水',
        'palace_name': '坎',
        'palace_element': '水',
        'lines': List.generate(6, (index) {
          final position = index + 1;
          return {
            'position': position,
            'value': values[index],
            'yin_yang': values[index].isEven ? 'yin' : 'yang',
            'changing': values[index] == 6 || values[index] == 9,
            'six_god': gods[index],
            'relation': relations[index],
            'branch': branches[index],
            'element': elements[index],
            'role': position == 3
                ? '应'
                : position == 6
                ? '世'
                : null,
            'hidden': null,
          };
        }),
      },
      'changed': {
        'name': '雷地豫',
        'palace_name': '震',
        'palace_element': '木',
        'lines': List.generate(6, (index) {
          final position = index + 1;
          return {
            'position': position,
            'yin_yang': index < 3 ? 'yin' : 'yang',
            'relation': changedRelations[index],
            'branch': changedBranches[index],
            'element': changedElements[index],
          };
        }),
      },
    },
    'raw_najia': <String, dynamic>{},
  };
}

/// 在档案详情页 ListView 中滚动到指定 Key 可见。
Future<void> _scrollTo(WidgetTester tester, Key key) async {
  await tester.scrollUntilVisible(
    find.byKey(key),
    180,
    scrollable: find
        .descendant(
          of: find.byKey(const Key('case-detail-scroll')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

/// 使用真实引擎结果构造一个含完整三层标注与五星的档案。
CaseDetail _engineCaseDetail() {
  final preview = CastPreview.fromEngineResult(
    liuyao_engine.manualCast(DateTime(2026, 8, 5, 15, 26), [9, 7, 7, 7, 7, 6]),
    question: '工作是否顺利推进？',
  );
  return CaseDetail.fromJson({
    'id': 'case-1',
    'title': '测试档案',
    'question': '工作是否顺利推进？',
    'castAt': preview.castAt.toIso8601String(),
    'castingMethod': 'manual',
    'baseHexagram': preview.baseHexagram,
    'changedHexagram': preview.changedHexagram,
    'latestAnalysisRevision': 0,
    'createdAt': DateTime(2026, 8, 5).toIso8601String(),
    'updatedAt': DateTime(2026, 8, 5).toIso8601String(),
    'chart': preview.rawJson,
    'analyses': const [],
    'feedbacks': const [],
  });
}

Map<String, dynamic> _castJson({
  required DateTime castAt,
  required List<int> values,
  required String baseName,
  required String? changedName,
  required String method,
  List<List<int>>? coinLines,
  String? randomKind,
}) {
  const names = ['初爻', '二爻', '三爻', '四爻', '五爻', '上爻'];
  const gods = ['白虎', '玄武', '青龙', '朱雀', '勾陈', '螣蛇'];
  const relations = ['妻财', '官鬼', '兄弟', '妻财', '子孙', '兄弟'];
  const changedRelations = ['兄弟', '妻财', '子孙', '父母', '子孙', '兄弟'];
  const stems = ['甲', '甲', '甲', '丁', '丁', '丁'];
  const branches = ['子', '寅', '辰', '亥', '酉', '未'];
  const elements = ['水', '木', '土', '水', '金', '土'];
  const hiddenRelations = ['兄弟', '父母', '官鬼', '兄弟', '妻财', '子孙'];
  const hiddenStems = ['乙', '乙', '乙', '癸', '癸', '癸'];
  const hiddenBranches = ['未', '巳', '卯', '丑', '亥', '酉'];
  const hiddenElements = ['土', '火', '木', '土', '水', '金'];
  const changedStems = ['辛', '辛', '辛', '壬', '壬', '壬'];
  const changedBranches = ['丑', '亥', '酉', '午', '申', '戌'];
  const changedElements = ['土', '水', '金', '火', '金', '土'];
  const defaultCoins = [
    [2, 3, 3],
    [2, 3, 2],
    [2, 2, 2],
    [3, 3, 2],
    [3, 2, 3],
    [3, 2, 2],
  ];
  const traditional = {6: '老阴', 7: '少阳', 8: '少阴', 9: '老阳'};
  final actualCoins = coinLines ?? defaultCoins;

  Map<String, dynamic> najia(
    int index,
    List<String> sourceStems,
    List<String> sourceBranches,
    List<String> sourceElements,
  ) {
    return {
      'heavenly_stem': sourceStems[index],
      'earthly_branch': sourceBranches[index],
      'branch': sourceBranches[index],
      'gan_zhi': '${sourceStems[index]}${sourceBranches[index]}',
      'element': sourceElements[index],
    };
  }

  return {
    'schema_version': 13,
    'engine_version': '0.13.0+najia-2.0.1',
    'rule_package': {
      'id': 'liuyao.base.najia_2_0_1_compat.v1',
      'version': '1.3.0',
      'status': 'provisional_authority',
      'source_ids': ['SRC-008', 'SRC-009'],
      'upstream': {
        'name': 'najia',
        'installed_version': '2.0.1',
        'audited_tag': 'v2.0.1',
        'audited_commit': 'c67a5398632a80f368a17a884c1c71b203aab719',
      },
    },
    'meta': {
      'cast_at': castAt.toIso8601String(),
      'casting_method': method,
      'line_order': 'bottom_to_top',
      'line_values': values,
    },
    'casting_record': {
      'method': method,
      'method_version': method == 'manual'
          ? 'manual.yin_yang_moving.v1'
          : 'three_coins.sum_2_3.v1',
      'line_order': 'bottom_to_top',
      'line_values': values,
      'lines': List.generate(6, (index) {
        final coins = method == 'manual' ? <int>[] : actualCoins[index];
        return {
          'position': index + 1,
          'position_name': names[index],
          'source': method == 'manual' ? 'manual_input' : 'three_coins',
          'coins': coins,
          'total': coins.isEmpty
              ? values[index]
              : coins.reduce((first, second) => first + second),
          'value': values[index],
          'yin_yang': values[index] == 7 || values[index] == 9 ? 'yang' : 'yin',
          'changing': values[index] == 6 || values[index] == 9,
          'traditional_name': traditional[values[index]],
        };
      }),
      'random_source': method == 'manual'
          ? null
          : {
              'kind': randomKind ?? 'system',
              'generator': randomKind == 'seeded_test'
                  ? 'python.Random'
                  : 'python.SystemRandom',
              if (randomKind == 'seeded_test') 'seed': 'golden',
            },
    },
    'time': {
      'timezone': 'Asia/Shanghai',
      'rule_status': 'provisional',
      'source': 'cnlunar_adapter',
      'year': '丙午',
      'month': '乙未',
      'day': '辛亥',
      'hour': '丙申',
      'pillars': {
        'year': {'gan_zhi': '丙午', 'stem': '丙', 'branch': '午'},
        'month': {'gan_zhi': '乙未', 'stem': '乙', 'branch': '未'},
        'day': {'gan_zhi': '辛亥', 'stem': '辛', 'branch': '亥'},
        'hour': {'gan_zhi': '丙申', 'stem': '丙', 'branch': '申'},
      },
      'pillar_voids': {
        'year': {
          'void': '寅卯',
          'branches': ['寅', '卯'],
        },
        'month': {
          'void': '辰巳',
          'branches': ['辰', '巳'],
        },
        'day': {
          'void': '寅卯',
          'branches': ['寅', '卯'],
        },
        'hour': {
          'void': '辰巳',
          'branches': ['辰', '巳'],
        },
      },
      'day_void': '寅卯',
      'day_void_branches': ['寅', '卯'],
    },
    'hexagram': {
      'line_order': 'bottom_to_top',
      'display_order': 'top_to_bottom',
      'moving_positions': [
        for (var index = 0; index < values.length; index++)
          if (values[index] == 6 || values[index] == 9) index + 1,
      ],
      'base': {
        'id': 'base',
        'code': '111110',
        'name': baseName,
        'lower_trigram': {'code': '111', 'name': '乾', 'element': '金'},
        'upper_trigram': {'code': '110', 'name': '兑', 'element': '金'},
        'palace_name': '坤',
        'palace_element': '土',
        'palace': {'code': '000', 'name': '坤', 'element': '土'},
        'palace_sequence': 6,
        'hexagram_kind': 'regular',
        'shi_position': 5,
        'ying_position': 2,
        'moving_positions': [
          for (var index = 0; index < values.length; index++)
            if (values[index] == 6 || values[index] == 9) index + 1,
        ],
        'hidden_hexagram': {
          'id': 'hidden',
          'code': '000000',
          'name': '坤为地',
          'lower_trigram': {'code': '000', 'name': '坤', 'element': '土'},
          'upper_trigram': {'code': '000', 'name': '坤', 'element': '土'},
          'palace_basis': {'code': '000', 'name': '坤', 'element': '土'},
          'palace_opposite': {'code': '111', 'name': '乾', 'element': '金'},
          'inner_rule': {
            'scope': 'inner',
            'original_trigram': {'code': '111', 'name': '乾', 'element': '金'},
            'matches_palace_trigram': false,
            'selected_trigram': {'code': '000', 'name': '坤', 'element': '土'},
            'selection': 'palace_trigram',
          },
          'outer_rule': {
            'scope': 'outer',
            'original_trigram': {'code': '110', 'name': '兑', 'element': '金'},
            'matches_palace_trigram': false,
            'selected_trigram': {'code': '000', 'name': '坤', 'element': '土'},
            'selection': 'palace_trigram',
          },
        },
        'lines': List.generate(6, (index) {
          return {
            'id': 'base-${index + 1}',
            'position': index + 1,
            'position_name': names[index],
            'value': values[index],
            'yin_yang': values[index] == 7 || values[index] == 9
                ? 'yang'
                : 'yin',
            'changing': values[index] == 6 || values[index] == 9,
            'six_god': gods[index],
            'relation': relations[index],
            ...najia(index, stems, branches, elements),
            'role': index == 4
                ? '世'
                : index == 1
                ? '应'
                : null,
            'hidden': {
              'id': 'hidden-${index + 1}-${hiddenRelations[index]}',
              'position': index + 1,
              'position_name': names[index],
              'relation': hiddenRelations[index],
              ...najia(index, hiddenStems, hiddenBranches, hiddenElements),
              'source_hexagram': {'code': '000000', 'name': '坤为地'},
              'flying_line_id': 'base-${index + 1}',
              'relation_missing_from_base': !relations.contains(
                hiddenRelations[index],
              ),
              'note': '伏神',
            },
          };
        }),
      },
      'changed': changedName == null
          ? null
          : {
              'id': 'changed',
              'code': '011111',
              'name': changedName,
              'lower_trigram': {'code': '011', 'name': '巽', 'element': '木'},
              'upper_trigram': {'code': '111', 'name': '乾', 'element': '金'},
              'palace_name': '乾',
              'palace_element': '金',
              'palace': {'code': '111', 'name': '乾', 'element': '金'},
              'palace_sequence': 2,
              'hexagram_kind': 'regular',
              'relative_basis': 'base_palace',
              'relative_basis_element': '土',
              'lines': List.generate(6, (index) {
                return {
                  'id': 'changed-${index + 1}',
                  'position': index + 1,
                  'position_name': names[index],
                  'yin_yang': values[index] == 6
                      ? 'yang'
                      : values[index] == 9
                      ? 'yin'
                      : values[index] == 7
                      ? 'yang'
                      : 'yin',
                  'changed_from_base': values[index] == 6 || values[index] == 9,
                  'relation': changedRelations[index],
                  ...najia(
                    index,
                    changedStems,
                    changedBranches,
                    changedElements,
                  ),
                };
              }),
            },
    },
    'annotations': {
      'rule_packages': [
        {
          'id': 'liuyao.annotations.wuxing_changsheng.v1',
          'version': '1.0.0',
          'status': 'provisional_authority',
          'source_ids': ['SRC-011', 'SRC-012'],
          'system': 'five_elements_forward',
        },
        {
          'id': 'liuyao.shensha.lushen_day_stem.v1',
          'version': '1.0.0',
          'status': 'provisional_authority',
          'source_ids': ['SRC-011', 'SRC-012'],
          'system': 'day_stem_to_visible_base_line_branch',
        },
        {
          'id': 'liuyao.shensha.tianyi_day_stem.v1',
          'version': '1.0.0',
          'status': 'provisional_authority',
          'source_ids': ['SRC-011', 'SRC-012'],
          'system': 'day_stem_to_visible_base_line_branches',
        },
        {
          'id': 'liuyao.shensha.yima_day_branch.v1',
          'version': '1.0.0',
          'status': 'provisional_authority',
          'source_ids': ['SRC-011', 'SRC-012', 'SRC-016'],
          'system': 'day_branch_to_visible_base_line_branch',
        },
        {
          'id': 'liuyao.shensha.taohua_day_branch.v1',
          'version': '1.0.0',
          'status': 'provisional_authority',
          'source_ids': ['SRC-011', 'SRC-012', 'SRC-015', 'SRC-017'],
          'system': 'day_branch_to_visible_base_line_branch',
        },
        {
          'id': 'liuyao.shensha.jiangxing_day_branch.v1',
          'version': '1.0.0',
          'status': 'provisional_authority',
          'source_ids': ['SRC-011', 'SRC-012', 'SRC-015'],
          'system': 'day_branch_to_visible_base_line_branch',
        },
        {
          'id': 'liuyao.shensha.huagai_day_branch.v1',
          'version': '1.0.0',
          'status': 'provisional_authority',
          'source_ids': ['SRC-011', 'SRC-012', 'SRC-015'],
          'system': 'day_branch_to_visible_base_line_branch',
        },
        {
          'id': 'liuyao.mansions.jingfang_world_line.v1',
          'version': '1.0.0',
          'status': 'confirmed_user_rule',
          'source_ids': ['SRC-006'],
          'system': 'jingfang_64_hexagrams_world_line',
        },
      ],
      'five_element_twelve_stages': {
        'rule_id': 'annotation.wuxing_twelve_stages.forward.v1',
        'rule_version': '1.0.0',
        'system': 'five_elements_forward',
        'scope': 'base_lines',
        'reference_order': ['year', 'month', 'day', 'hour'],
        'stage_order': [
          '长生',
          '沐浴',
          '冠带',
          '临官',
          '帝旺',
          '衰',
          '病',
          '死',
          '墓',
          '绝',
          '胎',
          '养',
        ],
        'start_branches': {'木': '亥', '火': '寅', '土': '申', '金': '巳', '水': '申'},
        'line_results': List.generate(6, (index) {
          const stagesByElement = {
            '水': ['胎', '养', '临官', '长生'],
            '木': ['死', '墓', '长生', '绝'],
            '土': ['胎', '养', '临官', '长生'],
            '金': ['沐浴', '冠带', '病', '临官'],
          };
          final lineStages = stagesByElement[elements[index]]!;
          return {
            'line_id': 'base-${index + 1}',
            'position': index + 1,
            'position_name': names[index],
            'line_element': elements[index],
            'pillar_results': List.generate(4, (pillarIndex) {
              const references = ['year', 'month', 'day', 'hour'];
              const labels = ['年', '月', '日', '时'];
              const ganZhi = ['丙午', '乙未', '辛亥', '丙申'];
              const pillarBranches = ['午', '未', '亥', '申'];
              return {
                'reference': references[pillarIndex],
                'reference_label': labels[pillarIndex],
                'pillar_gan_zhi': ganZhi[pillarIndex],
                'reference_branch': pillarBranches[pillarIndex],
                'stage': lineStages[pillarIndex],
              };
            }),
          };
        }),
      },
      'shensha': {
        'catalog_version': '1.0.0',
        'results': [
          {
            'rule_id': 'shensha.lushen.day_stem.v1',
            'rule_version': '1.0.0',
            'display_name': '禄神',
            'canonical_name': '天元禄',
            'aliases': ['禄神', '天元禄'],
            'category': 'stem_shensha',
            'scope': 'base_visible_lines',
            'basis': {'type': 'day_stem', 'pillar_gan_zhi': '辛亥', 'value': '辛'},
            'target_branches': ['酉'],
            'status': 'computed_match',
            'matches': [
              {
                'line_id': 'base-5',
                'position': 5,
                'position_name': '五爻',
                'gan_zhi': '丁酉',
                'branch': '酉',
                'relation': '子孙',
              },
            ],
            'excluded_scopes': ['hidden', 'changed'],
          },
          {
            'rule_id': 'shensha.tianyi.day_stem.v1',
            'rule_version': '1.0.0',
            'display_name': '天乙',
            'canonical_name': '天乙贵人',
            'aliases': ['天乙', '天乙贵人'],
            'category': 'stem_shensha',
            'scope': 'base_visible_lines',
            'basis': {'type': 'day_stem', 'pillar_gan_zhi': '辛亥', 'value': '辛'},
            'target_branches': ['午', '寅'],
            'status': 'computed_match',
            'matches': [
              {
                'line_id': 'base-2',
                'position': 2,
                'position_name': '二爻',
                'gan_zhi': '甲寅',
                'branch': '寅',
                'relation': '官鬼',
                'target_index': 1,
              },
            ],
            'excluded_scopes': ['hidden', 'changed'],
          },
          {
            'rule_id': 'shensha.yima.day_branch.v1',
            'rule_version': '1.0.0',
            'display_name': '驿马',
            'canonical_name': '驿马',
            'aliases': ['驿马', '驛馬'],
            'category': 'branch_shensha',
            'scope': 'base_visible_lines',
            'basis': {
              'type': 'day_branch',
              'pillar_gan_zhi': '辛亥',
              'value': '亥',
            },
            'target_branches': ['巳'],
            'status': 'computed_no_match',
            'matches': <Map<String, dynamic>>[],
            'excluded_scopes': ['hidden', 'changed'],
          },
          {
            'rule_id': 'shensha.taohua.day_branch.v1',
            'rule_version': '1.0.0',
            'display_name': '桃花',
            'canonical_name': '咸池',
            'aliases': ['桃花', '桃花煞', '咸池', '咸池杀'],
            'category': 'branch_shensha',
            'scope': 'base_visible_lines',
            'basis': {
              'type': 'day_branch',
              'pillar_gan_zhi': '辛亥',
              'value': '亥',
            },
            'target_branches': ['子'],
            'status': 'computed_match',
            'matches': [
              {
                'line_id': 'base-1',
                'position': 1,
                'position_name': '初爻',
                'gan_zhi': '甲子',
                'branch': '子',
                'relation': '妻财',
              },
            ],
            'excluded_scopes': ['hidden', 'changed'],
          },
          {
            'rule_id': 'shensha.jiangxing.day_branch.v1',
            'rule_version': '1.0.0',
            'display_name': '将星',
            'canonical_name': '将星',
            'aliases': ['将星', '將星', '将曜', '將曜'],
            'category': 'branch_shensha',
            'scope': 'base_visible_lines',
            'basis': {
              'type': 'day_branch',
              'pillar_gan_zhi': '辛亥',
              'value': '亥',
            },
            'target_branches': ['卯'],
            'status': 'computed_no_match',
            'matches': <Map<String, dynamic>>[],
            'excluded_scopes': ['hidden', 'changed'],
          },
          {
            'rule_id': 'shensha.huagai.day_branch.v1',
            'rule_version': '1.0.0',
            'display_name': '华盖',
            'canonical_name': '华盖',
            'aliases': ['华盖', '華蓋'],
            'category': 'branch_shensha',
            'scope': 'base_visible_lines',
            'basis': {
              'type': 'day_branch',
              'pillar_gan_zhi': '辛亥',
              'value': '亥',
            },
            'target_branches': ['未'],
            'status': 'computed_match',
            'matches': [
              {
                'line_id': 'base-6',
                'position': 6,
                'position_name': '上爻',
                'gan_zhi': '丁未',
                'branch': '未',
                'relation': '兄弟',
              },
            ],
            'excluded_scopes': ['hidden', 'changed'],
          },
        ],
      },
      'twenty_eight_mansions': {
        'rule_id': 'mansion.jingfang.world_line_and_six_lines.v1',
        'rule_version': '1.0.0',
        'system': 'jingfang_64_hexagrams_world_line',
        'scope': 'base_lines',
        'mansion_order': [
          '角',
          '亢',
          '氐',
          '房',
          '心',
          '尾',
          '箕',
          '斗',
          '牛',
          '女',
          '虚',
          '危',
          '室',
          '壁',
          '奎',
          '娄',
          '胃',
          '昴',
          '毕',
          '觜',
          '参',
          '井',
          '鬼',
          '柳',
          '星',
          '张',
          '翼',
          '轸',
        ],
        'palace_order': ['乾', '震', '坎', '艮', '坤', '巽', '离', '兑'],
        'hexagram': {
          'code': '111110',
          'name': baseName,
          'palace_name': '坤',
          'palace_index': 4,
          'palace_sequence': 6,
          'global_index': 37,
        },
        'world_line': {
          'position': 5,
          'position_name': '五爻',
          'mansion_index': 1,
          'mansion': '亢',
        },
        'response_line': {'position': 2, 'position_name': '二爻'},
        'placement_position_order': [5, 2, 6, 1, 4, 3],
        'line_placements': [
          {
            'order': 1,
            'line_id': 'base-5',
            'position': 5,
            'position_name': '五爻',
            'placement_role': '世',
            'mansion_index': 1,
            'mansion': '亢',
          },
          {
            'order': 2,
            'line_id': 'base-2',
            'position': 2,
            'position_name': '二爻',
            'placement_role': '应',
            'mansion_index': 2,
            'mansion': '氐',
          },
          {
            'order': 3,
            'line_id': 'base-6',
            'position': 6,
            'position_name': '上爻',
            'placement_role': '世卦',
            'mansion_index': 3,
            'mansion': '房',
          },
          {
            'order': 4,
            'line_id': 'base-1',
            'position': 1,
            'position_name': '初爻',
            'placement_role': '应卦',
            'mansion_index': 4,
            'mansion': '心',
          },
          {
            'order': 5,
            'line_id': 'base-4',
            'position': 4,
            'position_name': '四爻',
            'placement_role': '世卦',
            'mansion_index': 5,
            'mansion': '尾',
          },
          {
            'order': 6,
            'line_id': 'base-3',
            'position': 3,
            'position_name': '三爻',
            'placement_role': '应卦',
            'mansion_index': 6,
            'mansion': '箕',
          },
        ],
      },
    },
    'calculation_trace': [
      {
        'rule_id': method == 'manual'
            ? 'casting.manual.normalize.v1'
            : 'casting.three_coins.sum_2_3.v1',
        'label': '起卦原始过程',
        'scope': 'casting',
        'inputs': values,
        'steps': ['初爻输入完成', '六爻按初爻至上爻记录'],
        'result': values,
        'rule_version': '1.0.0',
      },
      {
        'rule_id': 'chart.six_gods.day_stem.v1',
        'label': '六神',
        'scope': 'base_chart',
        'inputs': {'day_stem': '辛'},
        'steps': ['辛日起白虎', '从初爻至上爻顺排六神'],
        'result': gods,
        'rule_version': '1.0.0',
        'source_ids': ['SRC-008', 'SRC-009'],
      },
      {
        'rule_id': 'annotation.wuxing_twelve_stages.forward.v1',
        'label': '五行十二长生',
        'scope': 'rule_annotations',
        'inputs': {
          'start_branches': {'土': '申', '水': '申'},
        },
        'steps': ['采用五行顺行十二长生', '初爻水：日支亥 → 临官'],
        'result': const [],
        'rule_version': '1.0.0',
        'source_ids': ['SRC-011', 'SRC-012'],
      },
      {
        'rule_id': 'shensha.lushen.day_stem.v1',
        'label': '禄神',
        'scope': 'rule_annotations',
        'inputs': {
          'day_pillar': {'gan_zhi': '辛亥', 'stem': '辛', 'branch': '亥'},
        },
        'steps': ['读取日干辛', '辛干禄在酉', '五爻丁酉命中'],
        'result': {'status': 'computed_match'},
        'rule_version': '1.0.0',
        'source_ids': ['SRC-011', 'SRC-012'],
      },
      {
        'rule_id': 'shensha.tianyi.day_stem.v1',
        'label': '天乙贵人',
        'scope': 'rule_annotations',
        'inputs': {
          'day_pillar': {'gan_zhi': '辛亥', 'stem': '辛', 'branch': '亥'},
        },
        'steps': ['读取日干辛', '辛干天乙在午、寅', '二爻甲寅命中'],
        'result': {'status': 'computed_match'},
        'rule_version': '1.0.0',
        'source_ids': ['SRC-011', 'SRC-012'],
      },
      {
        'rule_id': 'shensha.yima.day_branch.v1',
        'label': '驿马',
        'scope': 'rule_annotations',
        'inputs': {
          'day_pillar': {'gan_zhi': '辛亥', 'stem': '辛', 'branch': '亥'},
        },
        'steps': ['读取日支亥', '亥日驿马在巳', '本卦明爻未命中'],
        'result': {'status': 'computed_no_match'},
        'rule_version': '1.0.0',
        'source_ids': ['SRC-011', 'SRC-012', 'SRC-016'],
      },
      {
        'rule_id': 'shensha.taohua.day_branch.v1',
        'label': '桃花（咸池）',
        'scope': 'rule_annotations',
        'inputs': {
          'day_pillar': {'gan_zhi': '辛亥', 'stem': '辛', 'branch': '亥'},
        },
        'steps': ['读取日支亥', '亥日桃花在子', '初爻甲子命中'],
        'result': {'status': 'computed_match'},
        'rule_version': '1.0.0',
        'source_ids': ['SRC-011', 'SRC-012', 'SRC-015', 'SRC-017'],
      },
      {
        'rule_id': 'shensha.jiangxing.day_branch.v1',
        'label': '将星',
        'scope': 'rule_annotations',
        'inputs': {
          'day_pillar': {'gan_zhi': '辛亥', 'stem': '辛', 'branch': '亥'},
        },
        'steps': ['读取日支亥', '亥日将星在卯', '本卦明爻未命中'],
        'result': {'status': 'computed_no_match'},
        'rule_version': '1.0.0',
        'source_ids': ['SRC-011', 'SRC-012', 'SRC-015'],
      },
      {
        'rule_id': 'shensha.huagai.day_branch.v1',
        'label': '华盖',
        'scope': 'rule_annotations',
        'inputs': {
          'day_pillar': {'gan_zhi': '辛亥', 'stem': '辛', 'branch': '亥'},
        },
        'steps': ['读取日支亥', '亥日华盖在未', '上爻丁未命中'],
        'result': {'status': 'computed_match'},
        'rule_version': '1.0.0',
        'source_ids': ['SRC-011', 'SRC-012', 'SRC-015'],
      },
      {
        'rule_id': 'mansion.jingfang.world_line_and_six_lines.v1',
        'label': '京房六十四卦配二十八宿',
        'scope': 'rule_annotations',
        'inputs': {'palace_name': '坤', 'palace_sequence': 6},
        'steps': ['坤宫第6卦全局序号为37', '五爻世配亢宿', '六爻完成装配'],
        'result': {'world_mansion': '亢'},
        'rule_version': '1.0.0',
        'source_ids': ['SRC-006'],
      },
    ],
  };
}
