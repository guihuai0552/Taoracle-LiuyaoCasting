import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao_engine/liuyao_engine.dart';
import 'package:liuyao_archive/src/features/casting/casting_models.dart';
import 'package:liuyao_archive/src/features/archive/archive_client.dart';
import 'package:liuyao_archive/src/features/archive/archive_models.dart';

/// 存档离线测试：验证 saveCast / listCases / getCase / append* / exportCase
/// 全部在本地内存完成，绝不发起 HTTP 请求（之前崩溃的根因）。
void main() {
  late ArchiveClient client;
  late Directory tempDir;

  CastPreview makePreview() {
    final result = manualCast(DateTime(2024, 3, 15, 10, 30), [
      9,
      8,
      7,
      6,
      8,
      7,
    ]);
    return CastPreview.fromEngineResult(result, question: '测试问题');
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('liuyao_offline_test');
    directoryOverride = () async => tempDir;
    await ArchiveClient.resetForTesting();
    client = ArchiveClient();
  });

  tearDown(() async {
    await ArchiveClient.resetForTesting();
    directoryOverride = null;
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('saveCast 本地存档不触网，返回完整 CaseDetail', () async {
    final preview = makePreview();
    final detail = await client.saveCast(question: '占问财运', preview: preview);
    expect(detail.id, isNotEmpty);
    expect(detail.question, '占问财运');
    expect(detail.baseHexagram, isNotEmpty);
    expect(detail.chart.chart.base.lines.length, 6);
    expect(detail.analyses, isEmpty);
  });

  test('listCases 返回已存档案例', () async {
    final preview = makePreview();
    await client.saveCast(question: '第一次占问', preview: preview);
    await client.saveCast(question: '第二次占问', preview: preview);
    final list = await client.listCases();
    expect(list.length, greaterThanOrEqualTo(2));
  });

  test('listCases 搜索过滤生效', () async {
    final preview = makePreview();
    final finance = await client.saveCast(question: '财运如何', preview: preview);
    final relationship = await client.saveCast(
      question: '感情发展',
      preview: preview,
    );
    await client.appendUserAnalysis(
      caseId: finance.id,
      body: '解读中出现远行关键词',
      expectedRevision: 0,
    );
    await client.appendFeedback(
      caseId: relationship.id,
      body: '反馈中出现合作关键词',
      status: 'pending',
    );
    final filtered = await client.listCases(query: '财运');
    expect(filtered, isNotEmpty);
    expect(filtered.first.question, contains('财运'));
    expect((await client.listCases(query: '远行')).single.id, finance.id);
    expect((await client.listCases(query: '合作')).single.id, relationship.id);
  });

  test('getCase 取回完整案例', () async {
    final preview = makePreview();
    final saved = await client.saveCast(question: '读取测试', preview: preview);
    final fetched = await client.getCase(saved.id);
    expect(fetched.id, saved.id);
    expect(fetched.question, '读取测试');
  });

  test('appendUserAnalysis 累加版本号', () async {
    final preview = makePreview();
    final saved = await client.saveCast(question: '解读测试', preview: preview);
    await client.appendUserAnalysis(
      caseId: saved.id,
      body: '第一版解读',
      expectedRevision: 0,
    );
    final fetched = await client.getCase(saved.id);
    expect(fetched.analyses.length, 1);
    expect(fetched.analyses.first.body, '第一版解读');
    expect(fetched.analyses.first.revision, 1);
    expect(fetched.latestAnalysisRevision, 1);
  });

  test('appendFeedback / updateFeedback 正常', () async {
    final preview = makePreview();
    final saved = await client.saveCast(question: '反馈测试', preview: preview);
    await client.appendFeedback(
      caseId: saved.id,
      body: '事情应验了',
      status: 'matched',
    );
    var fetched = await client.getCase(saved.id);
    expect(fetched.feedbacks.length, 1);
    expect(fetched.feedbacks.first.status, 'matched');

    await client.updateFeedback(
      caseId: saved.id,
      feedbackId: fetched.feedbacks.first.id,
      body: '部分应验',
      status: 'partial',
    );
    fetched = await client.getCase(saved.id);
    expect(fetched.feedbacks.first.body, '部分应验');
    expect(fetched.feedbacks.first.status, 'partial');
  });

  test('exportCase 本地生成 markdown 与 json', () async {
    final preview = makePreview();
    final saved = await client.saveCast(question: '导出测试', preview: preview);
    final md = await client.exportCase(saved.id, format: 'markdown');
    expect(md.filename, endsWith('.md'));
    expect(md.content, contains('# '));
    expect(md.content, contains('导出测试'));

    final json = await client.exportCase(saved.id, format: 'json');
    expect(json.filename, endsWith('.json'));
    expect(json.content, contains('"id"'));
  });

  test('批量迁移包完整保留卦面、全部解读和反馈', () async {
    final saved = await client.saveCast(
      question: '跨设备迁移',
      preview: makePreview(),
    );
    await client.appendUserAnalysis(
      caseId: saved.id,
      body: '第一版完整解读',
      expectedRevision: 0,
    );
    await client.appendUserAnalysis(
      caseId: saved.id,
      body: '第二版完整解读',
      expectedRevision: 1,
    );
    await client.appendFeedback(
      caseId: saved.id,
      body: '迁移后的反馈',
      status: 'partial',
      occurredAt: DateTime(2026, 8, 7),
    );

    final exported = await client.exportAllCases();
    expect(exported.filename, contains('archive-transfer'));
    final root = jsonDecode(exported.content) as Map<String, dynamic>;
    expect(root['format'], archiveTransferFormat);
    expect(root['schema_version'], archiveTransferSchemaVersion);
    expect(root['case_count'], 1);
    final rawCase = (root['cases'] as List).single as Map<String, dynamic>;
    expect((rawCase['analyses'] as List).length, 2);
    expect((rawCase['feedbacks'] as List).length, 1);
    expect(rawCase['chart'], isA<Map>());

    final destination = await Directory.systemTemp.createTemp(
      'liuyao_import_test',
    );
    await ArchiveClient.resetForTesting();
    directoryOverride = () async => destination;
    final target = ArchiveClient();
    final preview = await target.inspectImport(exported.content);
    expect(preview.totalCases, 1);
    expect(preview.newCases, 1);
    expect(preview.analysisCount, 2);
    expect(preview.feedbackCount, 1);

    final result = await target.importCases(
      exported.content,
      mode: ArchiveImportMode.merge,
    );
    expect(result.importedCases, 1);
    final restored = await target.getCase(saved.id);
    expect(restored.question, '跨设备迁移');
    expect(restored.analyses.map((item) => item.body), ['第一版完整解读', '第二版完整解读']);
    expect(restored.feedbacks.single.body, '迁移后的反馈');
    expect(restored.chartJson, isNotEmpty);

    await ArchiveClient.resetForTesting();
    directoryOverride = () async => tempDir;
    await destination.delete(recursive: true);
  });

  test('安全合并跳过相同档案并把内容冲突保留为副本', () async {
    await client.saveCast(question: '本机版本', preview: makePreview());
    final exported = await client.exportAllCases();

    final identical = await client.inspectImport(exported.content);
    expect(identical.identicalCases, 1);
    final skipped = await client.importCases(
      exported.content,
      mode: ArchiveImportMode.merge,
    );
    expect(skipped.importedCases, 0);
    expect(skipped.skippedCases, 1);

    final changed = jsonDecode(exported.content) as Map<String, dynamic>;
    final changedCase =
        (changed['cases'] as List).single as Map<String, dynamic>;
    changedCase['question'] = '另一台设备的版本';
    final changedContent = jsonEncode(changed);
    final preview = await client.inspectImport(changedContent);
    expect(preview.conflictingCases, 1);

    final merged = await client.importCases(
      changedContent,
      mode: ArchiveImportMode.merge,
    );
    expect(merged.importedCases, 1);
    expect(merged.copiedConflicts, 1);
    final cases = await client.listCases();
    expect(cases.length, 2);
    expect(cases.map((item) => item.question), contains('本机版本'));
    expect(cases.map((item) => item.question), contains('另一台设备的版本'));
    expect(cases.any((item) => item.title.endsWith('（导入副本）')), isTrue);
  });

  test('清空后恢复会用迁移包完整替换本机档案', () async {
    await client.saveCast(question: '需要被替换', preview: makePreview());
    final source = await client.saveCast(
      question: '迁移包保留项',
      preview: makePreview(),
    );
    final all =
        jsonDecode((await client.exportAllCases()).content)
            as Map<String, dynamic>;
    all['cases'] = [
      (all['cases'] as List).firstWhere(
        (item) => (item as Map<String, dynamic>)['id'] == source.id,
      ),
    ];
    all['case_count'] = 1;

    final result = await client.importCases(
      jsonEncode(all),
      mode: ArchiveImportMode.replaceAll,
    );
    expect(result.replacedExistingCases, 2);
    expect(result.importedCases, 1);
    final cases = await client.listCases();
    expect(cases.single.question, '迁移包保留项');
  });

  test('无效迁移文件在写入前被拒绝', () async {
    await client.saveCast(question: '原档案不能丢', preview: makePreview());
    await expectLater(
      client.importCases(
        '{"format":"liuyao_archive_transfer","schema_version":99,"cases":[]}',
        mode: ArchiveImportMode.merge,
      ),
      throwsA(isA<FormatException>()),
    );
    expect((await client.listCases()).single.question, '原档案不能丢');
  });

  test('迁移文件按 UTF-8 字节读取且支持 BOM', () {
    const chinese = '{"title":"乾为天与水天需"}';
    expect(decodeArchiveTransferBytes(utf8.encode(chinese)), chinese);
    expect(
      decodeArchiveTransferBytes(<int>[
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode(chinese),
      ]),
      chinese,
    );
    expect(
      () => decodeArchiveTransferBytes(<int>[0xFF, 0xFE]),
      throwsA(isA<FormatException>()),
    );
  });

  test('迁移包声明数量不一致时拒绝导入', () async {
    final saved = await client.saveCast(
      question: '数量校验',
      preview: makePreview(),
    );
    final root =
        jsonDecode((await client.exportAllCases()).content)
            as Map<String, dynamic>;
    expect(saved.id, isNotEmpty);
    root['case_count'] = 99;
    await expectLater(
      client.inspectImport(jsonEncode(root)),
      throwsA(isA<FormatException>()),
    );
  });

  test('旧手动四柱档案读取时按手动日干重排六神与旬空', () async {
    // 复现 2026-09 修复前的存档形态：自动排盘快照（2026-09-03 庚辰日
    // -> 白虎起初爻）+ 手动四柱只覆盖显示文本，卦面六神仍为自动日干。
    final castAt = DateTime(2026, 9, 3, 10, 30);
    const lines = [7, 7, 7, 8, 8, 8];
    final autoSnapshot = manualCast(castAt, lines);
    const manualPillars = ManualFourPillars(
      yearGan: '丙',
      yearZhi: '午',
      monthGan: '丙',
      monthZhi: '申',
      dayGan: '甲',
      dayZhi: '子',
      hourGan: '己',
      hourZhi: '巳',
    );
    final saved = await client.saveCast(
      question: '旧手动档案',
      preview: CastPreview.fromEngineResult(
        autoSnapshot,
        question: '旧手动档案',
      ).applyManualFourPillars(manualPillars),
    );

    // 存档快照本身仍是旧形态（初爻白虎），但保存返回与读取均按手动
    // 甲子日重排为青龙起初爻：saveCast / getCase 都经过 CaseDetail
    // 解析层的旧档案校正。
    final savedGods = saved.chart.chart.base.lines
        .map((line) => line.sixGod)
        .toList(growable: false);
    expect(savedGods, ['青龙', '朱雀', '勾陈', '螣蛇', '白虎', '玄武']);

    // 读取时同样按手动甲子日重排：青龙起初爻、旬空戌亥。
    final reloaded = await client.getCase(saved.id);
    final gods = reloaded.chart.chart.base.lines
        .map((line) => line.sixGod)
        .toList(growable: false);
    expect(gods, ['青龙', '朱雀', '勾陈', '螣蛇', '白虎', '玄武']);
    expect(reloaded.chart.dayPillar, '甲子');
    expect(reloaded.chart.dayVoid, '戌亥');
    expect(reloaded.fourPillarsContext['source'], 'manual');
  });

  test('自动四柱档案读取时不做手动重排', () async {
    final saved = await client.saveCast(
      question: '自动档案',
      preview: makePreview(), // 2024-03-15 自动四柱
    );
    final reloaded = await client.getCase(saved.id);
    expect(reloaded.chart.chart.base.lines.first.sixGod, isNotNull);
    // 自动档案快照原样返回（time 段不被改写）。
    expect(reloaded.chartJson['time'], saved.chartJson['time']);
  });

  test('同干不同支旧档案仍重排（庚辰自动 vs 庚寅手动，旬空不同）', () async {
    // 2026-09-03 自动日柱庚辰（旬空申酉）；手动日柱庚寅与自动日干同为庚
    // （六神同为白虎起初爻），但庚寅旬空午未——六神相同不可作为跳过
    // 重排的依据，否则卦面自相矛盾。
    final castAt = DateTime(2026, 9, 3, 10, 30);
    const lines = [7, 7, 7, 8, 8, 8];
    final autoSnapshot = manualCast(castAt, lines);
    const manualPillars = ManualFourPillars(
      yearGan: '丙',
      yearZhi: '午',
      monthGan: '丙',
      monthZhi: '申',
      dayGan: '庚',
      dayZhi: '寅',
      hourGan: '壬',
      hourZhi: '午',
    );
    final saved = await client.saveCast(
      question: '同干不同支',
      preview: CastPreview.fromEngineResult(
        autoSnapshot,
        question: '同干不同支',
      ).applyManualFourPillars(manualPillars),
    );

    final reloaded = await client.getCase(saved.id);
    final gods = reloaded.chart.chart.base.lines
        .map((line) => line.sixGod)
        .toList(growable: false);
    expect(gods.first, '白虎'); // 庚日起白虎，与自动结果相同
    expect(reloaded.chart.dayPillar, '庚寅');
    expect(reloaded.chart.dayVoid, '午未'); // 而非自动庚辰的申酉
  });

  group('2026-09-04 需求：占问编辑与历史版本删除', () {
    test('updateQuestion 修改占问落盘，重启后仍保留且不触碰卦面', () async {
      final saved = await client.saveCast(
        question: '原占问',
        preview: makePreview(),
      );
      final chartBefore = jsonEncode(saved.chartJson);
      await client.updateQuestion(caseId: saved.id, question: '改后的占问');
      final fetched = await client.getCase(saved.id);
      expect(fetched.question, '改后的占问');
      expect(fetched.questionUpdatedAt, isNotNull);
      // 卦面快照不受占问编辑影响（FR-CAS-005）。
      expect(jsonEncode(fetched.chartJson), chartBefore);
      // 模拟重启。
      await ArchiveClient.resetForTesting();
      final reloaded = await client.getCase(saved.id);
      expect(reloaded.question, '改后的占问');
    });

    test('updateQuestion 空白回落「暂无问念」，超长拒绝', () async {
      final saved = await client.saveCast(
        question: '原占问',
        preview: makePreview(),
      );
      await client.updateQuestion(caseId: saved.id, question: '   ');
      expect((await client.getCase(saved.id)).question, '暂无问念');
      expect(
        () => client.updateQuestion(caseId: saved.id, question: '长' * 1001),
        throwsException,
      );
    });

    test('deleteAnalysis 删除指定版本，revision 不回退且后续新版本不冲突', () async {
      final saved = await client.saveCast(
        question: '版本删除',
        preview: makePreview(),
      );
      await client.appendUserAnalysis(
        caseId: saved.id,
        body: '版本一',
        expectedRevision: 0,
      );
      await client.appendUserAnalysis(
        caseId: saved.id,
        body: '版本二',
        expectedRevision: 1,
      );
      await client.appendUserAnalysis(
        caseId: saved.id,
        body: '版本三',
        expectedRevision: 2,
      );
      final detail = await client.getCase(saved.id);
      await client.deleteAnalysis(
        caseId: saved.id,
        analysisId: detail.analyses[1].id, // 删除「版本二」
      );
      final after = await client.getCase(saved.id);
      expect(after.analyses.map((a) => a.body), ['版本一', '版本三']);
      // latestAnalysisRevision 保持 3，不因删除回退。
      expect(after.latestAnalysisRevision, 3);
      // 删除留下的空洞不影响乐观锁与后续追加：revision 取 4。
      await client.appendUserAnalysis(
        caseId: saved.id,
        body: '版本四',
        expectedRevision: 3,
      );
      final afterAppend = await client.getCase(saved.id);
      expect(afterAppend.analyses.last.body, '版本四');
      expect(afterAppend.analyses.last.revision, 4);
      expect(afterAppend.latestAnalysisRevision, 4);
      // 模拟重启后删除结果仍保留。
      await ArchiveClient.resetForTesting();
      final reloaded = await client.getCase(saved.id);
      expect(reloaded.analyses.map((a) => a.body), ['版本一', '版本三', '版本四']);
    });

    test('deleteAnalysis 删除不存在的版本抛错且不改动数据', () async {
      final saved = await client.saveCast(
        question: '删除不存在',
        preview: makePreview(),
      );
      expect(
        () => client.deleteAnalysis(
          caseId: saved.id,
          analysisId: 'analysis-missing',
        ),
        throwsException,
      );
      expect((await client.getCase(saved.id)).analyses, isEmpty);
    });
  });

  group('2026-09-04 需求：导出内容裁剪选项', () {
    Future<String> seedCase() async {
      final saved = await client.saveCast(
        question: '导出裁剪',
        preview: makePreview(),
      );
      await client.appendUserAnalysis(
        caseId: saved.id,
        body: '解读一',
        expectedRevision: 0,
      );
      await client.appendUserAnalysis(
        caseId: saved.id,
        body: '解读二',
        expectedRevision: 1,
      );
      await client.appendFeedback(
        caseId: saved.id,
        body: '反馈一',
        status: 'matched',
      );
      return saved.id;
    }

    test('markdown 裁剪：不含解读/反馈，或仅最新解读版本', () async {
      final id = await seedCase();
      final full = await client.exportCase(id, format: 'markdown');
      expect(full.content, contains('解读一'));
      expect(full.content, contains('解读二'));
      expect(full.content, contains('反馈一'));

      final bare = await client.exportCase(
        id,
        format: 'markdown',
        includeAnalysis: false,
        includeFeedback: false,
      );
      expect(bare.content, isNot(contains('## 解读')));
      expect(bare.content, isNot(contains('解读一')));
      expect(bare.content, isNot(contains('## 反馈')));
      expect(bare.content, isNot(contains('反馈一')));
      // 卦面快照与占问仍在。
      expect(bare.content, contains('## 占问'));
      expect(bare.content, contains('完整卦面快照'));

      final latestOnly = await client.exportCase(
        id,
        format: 'markdown',
        includeAnalysisHistory: false,
      );
      expect(latestOnly.content, isNot(contains('解读一')));
      expect(latestOnly.content, contains('解读二'));
      expect(latestOnly.content, contains('反馈一'));
    });

    test('JSON 导出忽略裁剪参数，始终完整（备份语义）', () async {
      final id = await seedCase();
      final exported = await client.exportCase(
        id,
        format: 'json',
        includeAnalysis: false,
        includeFeedback: false,
        includeAnalysisHistory: false,
      );
      final decoded = jsonDecode(exported.content) as Map<String, dynamic>;
      expect((decoded['analyses'] as List).length, 2);
      expect((decoded['feedbacks'] as List).length, 1);
    });
  });
}
