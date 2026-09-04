import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao_archive/src/features/archive/archive_client.dart';
import 'package:liuyao_archive/src/features/archive/archive_models.dart';
import 'package:liuyao_archive/src/features/archive/archive_page.dart';
import 'package:liuyao_archive/src/features/casting/casting_models.dart';
import 'package:liuyao_engine/liuyao_engine.dart';

/// 滑动删除回归测试（2026-09-04 bug：左滑删除不了）。
///
/// 根因：真实 ArchiveClient.listCases 返回 `growable: false` 的固定长度
/// 列表，onDismissed 里 `_cases.removeWhere` 抛 UnsupportedError，异常被
/// Dismissible 的 async 链吞掉，_deleteCase 从未执行——用户确认删除后
/// 档案仍在、卡片滞留滑出位置。fake 数据源返回 growable 列表，因此
/// 既有 widget 测试全绿、长按删除（不修改 _cases）也正常。
///
/// 本文件从三个角度锁定回归（不混合 FakeAsync 与 dart:io，规避
/// flutter_test 已知的沙箱死锁）：
///   1. 纯数据层：真实 ArchiveClient 落盘的 save→list→delete 全链路；
///   2. 纯数据层：listCases 返回可增长列表（onDismissed 原地修改的前提）；
///   3. 纯 widget：故意返回固定长度列表的 fake，验证滑动删除端到端无异常。
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('liuyao_swipe_delete');
    directoryOverride = () async => tempDir;
    await ArchiveClient.resetForTesting();
  });

  tearDown(() async {
    await ArchiveClient.resetForTesting();
    directoryOverride = null;
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('真实 client：save→delete 落盘链路，重开进程后档案不复活', () async {
    final client = ArchiveClient();
    final result = manualCast(DateTime(2026, 9, 4, 10, 30), [7, 8, 8, 7, 8, 8]);
    final saved = await client.saveCast(
      question: '左滑删除回归',
      preview: CastPreview.fromEngineResult(result, question: '左滑删除回归'),
    );
    client.close();

    expect(
      await File('${tempDir.path}/liuyao_archive.json').readAsString(),
      contains(saved.id),
      reason: '保存后应已落盘',
    );

    // 删除（等价于左滑确认后 _deleteCase 的调用）并校验落盘与重载。
    final second = ArchiveClient();
    await second.deleteCase(saved.id);
    final raw = await File(
      '${tempDir.path}/liuyao_archive.json',
    ).readAsString();
    expect(raw.contains(saved.id), isFalse, reason: '档案应已从磁盘删除');
    second.close();

    // 模拟进程重启（全新加载路径，绕过内存缓存）。
    await ArchiveClient.resetForTesting();
    final reopened = ArchiveClient();
    addTearDown(reopened.close);
    expect(await reopened.listCases(), isEmpty, reason: '重开进程后档案不得复活');
  });

  test('真实 client listCases 返回可增长列表（页面原地修改依赖）', () async {
    final client = ArchiveClient();
    final result = manualCast(DateTime(2026, 9, 4, 10, 30), [7, 8, 8, 7, 8, 8]);
    final saved = await client.saveCast(
      question: '列表可增长',
      preview: CastPreview.fromEngineResult(result, question: '列表可增长'),
    );
    final cases = await client.listCases();
    // 等价于 onDismissed 的 removeWhere；固定长度列表会在此抛异常。
    expect(
      () => cases.removeWhere((item) => item.id == saved.id),
      returnsNormally,
    );
    expect(cases, isEmpty);
  });

  testWidgets('固定长度列表数据源：滑动删除不再抛 UnsupportedError', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final archive = _FixedListArchive();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ArchivePage(dataSource: archive)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('archive-case-case-1')), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('archive-case-case-1')),
      const Offset(-360, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('archive-delete-confirm')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull, reason: '滑动删除不得抛出未处理异常');
    expect(archive.deleteCount, 1);
    expect(find.byKey(const Key('archive-case-case-1')), findsNothing);
    expect(find.text('档案已删除'), findsOneWidget);
  });
}

/// 故意让 listCases 返回固定长度列表（bug 触发条件），其余行为极简。
class _FixedListArchive implements ArchiveDataSource {
  final Map<String, Map<String, dynamic>> _cases = {
    'case-1': {
      'id': 'case-1',
      'title': '固定列表',
      'question': '固定列表',
      'castAt': '2026-09-04T10:30:00',
      'castingMethod': 'manual',
      'baseHexagram': '乾为天',
      'changedHexagram': null,
      'latestAnalysisRevision': 0,
      'createdAt': '2026-09-04T10:30:00',
      'updatedAt': '2026-09-04T10:30:00',
      'questionContext': '',
      'questionContextUpdatedAt': null,
      'calendarPolicy': const <String, dynamic>{},
      'fourPillarsContext': const <String, dynamic>{},
      'displayContext': const <String, dynamic>{},
      'castingContext': const <String, dynamic>{},
      'tags': const <String>[],
      'chart': _chartJson,
      'analyses': <Map<String, dynamic>>[],
      'feedbacks': <Map<String, dynamic>>[],
    },
  };

  int deleteCount = 0;

  static const _chartJson = <String, dynamic>{
    'hexagram': <String, dynamic>{},
    'meta': <String, dynamic>{
      'casting_method': 'manual',
      'line_values': [7, 8, 8, 7, 8, 8],
    },
    'time': <String, dynamic>{},
  };

  @override
  Future<List<CaseSummary>> listCases({
    String query = '',
    List<String> tags = const [],
  }) async {
    // List.of(...) 默认 growable:false → 严格复现 bug 触发条件。
    final summaries = _cases.values.map(CaseSummary.fromJson).toList();
    return List<CaseSummary>.of(summaries, growable: false);
  }

  @override
  Future<void> deleteCase(String id) async {
    deleteCount += 1;
    _cases.remove(id);
  }

  @override
  Future<CaseDetail> getCase(String id) async =>
      CaseDetail.fromJson(_cases[id]!);

  @override
  Future<CaseDetail> saveCast({
    String title = '',
    required String question,
    required CastPreview preview,
  }) async => throw UnimplementedError();

  @override
  Future<void> updateQuestion({
    required String caseId,
    required String question,
  }) async {}

  @override
  Future<void> updateQuestionContext({
    required String caseId,
    required String context,
  }) async {}

  @override
  Future<void> deleteAnalysis({
    required String caseId,
    required String analysisId,
  }) async {}

  @override
  Future<void> updateTags({
    required String caseId,
    required List<String> tags,
  }) async {}

  @override
  Future<void> appendUserAnalysis({
    required String caseId,
    required String body,
    required int expectedRevision,
  }) async {}

  @override
  Future<void> appendFeedback({
    required String caseId,
    required String body,
    required String status,
    DateTime? occurredAt,
  }) async {}

  @override
  Future<void> updateFeedback({
    required String caseId,
    required String feedbackId,
    required String body,
    required String status,
    DateTime? occurredAt,
  }) async {}

  @override
  Future<CaseExportFile> exportCase(
    String id, {
    required String format,
    bool includeAnalysis = true,
    bool includeFeedback = true,
    bool includeAnalysisHistory = true,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<CaseExportFile> exportAllCases() async => throw UnimplementedError();

  @override
  Future<ArchiveImportPreview> inspectImport(String content) async {
    throw UnimplementedError();
  }

  @override
  Future<ArchiveImportResult> importCases(
    String content, {
    required ArchiveImportMode mode,
  }) async => throw UnimplementedError();

  @override
  void close() {}
}
