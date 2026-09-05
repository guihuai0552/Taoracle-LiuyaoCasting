import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:liuyao_engine/liuyao_engine.dart';
import 'package:liuyao_archive/src/features/casting/casting_models.dart';
import 'package:liuyao_archive/src/features/archive/archive_client.dart';

/// 持久化测试：验证存档真实写入 App 私有目录的磁盘文件，
/// 且「退出重开」后（reloadFromDisk 模拟）数据仍然存在。
void main() {
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
    return CastPreview.fromEngineResult(result, question: '测试');
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('liuyao_persist_test');
    // 把目录解析重定向到隔离的临时目录
    directoryOverride = () async => tempDir;
    // 清空内存缓存，确保从干净状态开始
    await ArchiveClient.reloadFromDisk();
  });

  tearDown(() async {
    await ArchiveClient.resetForTesting();
    directoryOverride = null;
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('存档后磁盘文件真实生成且含数据', () async {
    final client = ArchiveClient();
    await client.saveCast(question: '磁盘持久化测试', preview: makePreview());

    final file = File('${tempDir.path}/liuyao_archive.json');
    expect(await file.exists(), isTrue, reason: '存档文件应已生成');
    final content = await file.readAsString();
    final root = jsonDecode(content) as Map<String, dynamic>;
    expect(root['schema_version'], archiveStoreSchemaVersion);
    expect(root['cases'], isA<Map>());
    expect(content, contains('磁盘持久化测试'));
    expect(content, contains('"id"'));
    expect(await File('${file.path}.tmp').exists(), isFalse);
  });

  test('删除档案后立即落盘且重启后不复活', () async {
    final client = ArchiveClient();
    final keep = await client.saveCast(
      question: '保留案例',
      preview: makePreview(),
    );
    final doomed = await client.saveCast(
      question: '待删除案例',
      preview: makePreview(),
    );

    await client.deleteCase(doomed.id);

    // 立即落盘：磁盘内容已不含被删案例，保留案例仍在。
    final file = File('${tempDir.path}/liuyao_archive.json');
    final content = await file.readAsString();
    expect(content, isNot(contains('待删除案例')));
    expect(content, contains('保留案例'));

    // 模拟重启：仅靠磁盘重建后，被删案例不复活。
    await ArchiveClient.reloadFromDisk();
    final remaining = await client.listCases();
    expect(remaining.map((item) => item.id), contains(keep.id));
    expect(remaining.map((item) => item.id), isNot(contains(doomed.id)));

    // 删除不存在的案例应显式报错而非静默成功。
    expect(() => client.deleteCase(doomed.id), throwsException);
  });

  test('退出重开后数据保留（模拟重启）', () async {
    final client = ArchiveClient();
    final saved = await client.saveCast(
      question: '重启后应在',
      preview: makePreview(),
    );
    await client.appendUserAnalysis(
      caseId: saved.id,
      body: '重启前的解读',
      expectedRevision: 0,
    );

    // 模拟退出 App：内存清空，仅靠磁盘
    await ArchiveClient.reloadFromDisk();

    // 模拟重开 App：新建客户端读取
    final reopened = ArchiveClient();
    final list = await reopened.listCases();
    expect(
      list.any((c) => c.question == '重启后应在'),
      isTrue,
      reason: '退出重开后应仍能列出该案例',
    );

    final detail = await reopened.getCase(saved.id);
    expect(detail.question, '重启后应在');
    expect(detail.analyses.length, 1);
    expect(detail.analyses.first.body, '重启前的解读');
    expect(detail.latestAnalysisRevision, 1);
  });

  test('多次存档累积且全部持久', () async {
    final client = ArchiveClient();
    await client.saveCast(question: '案例A', preview: makePreview());
    await client.saveCast(question: '案例B', preview: makePreview());
    await client.saveCast(question: '案例C', preview: makePreview());

    await ArchiveClient.reloadFromDisk();
    final list = await ArchiveClient().listCases();
    expect(list.length, 3);
    final questions = list.map((c) => c.question).toSet();
    expect(questions, containsAll(['案例A', '案例B', '案例C']));
  });

  test('反馈增改也持久', () async {
    final client = ArchiveClient();
    final saved = await client.saveCast(
      question: '反馈持久',
      preview: makePreview(),
    );
    await client.appendFeedback(
      caseId: saved.id,
      body: '应验了',
      status: 'matched',
    );

    await ArchiveClient.reloadFromDisk();
    final detail = await ArchiveClient().getCase(saved.id);
    expect(detail.feedbacks.length, 1);
    expect(detail.feedbacks.first.body, '应验了');
    expect(detail.feedbacks.first.status, 'matched');
  });

  test('旧版无容器 JSON 自动读取并在下次写入迁移', () async {
    final client = ArchiveClient();
    final saved = await client.saveCast(
      question: '旧版迁移',
      preview: makePreview(),
    );
    final file = File('${tempDir.path}/liuyao_archive.json');
    final current =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    await file.writeAsString(jsonEncode(current['cases']), flush: true);

    await ArchiveClient.reloadFromDisk();
    expect((await ArchiveClient().getCase(saved.id)).question, '旧版迁移');
    await ArchiveClient().appendFeedback(
      caseId: saved.id,
      body: '触发迁移写入',
      status: 'pending',
    );
    final migrated =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    expect(migrated['schema_version'], archiveStoreSchemaVersion);
  });

  test('损坏文件显式报错且不会被静默覆盖', () async {
    final file = File('${tempDir.path}/liuyao_archive.json');
    await file.writeAsString('{broken', flush: true);

    await expectLater(
      ArchiveClient.reloadFromDisk(),
      throwsA(isA<ArchiveStorageException>()),
    );
    expect(await file.readAsString(), '{broken');
  });

  test('进程中断后优先恢复更新且完整的临时文件', () async {
    final client = ArchiveClient();
    await client.saveCast(question: '旧主档案', preview: makePreview());
    final file = File('${tempDir.path}/liuyao_archive.json');
    final oldRoot =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;

    await client.saveCast(question: '临时文件中的新案例', preview: makePreview());
    final newRoot =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    oldRoot['updated_at'] = '2026-08-06T00:00:00Z';
    newRoot['updated_at'] = '2026-08-06T00:00:01Z';
    await file.writeAsString(jsonEncode(oldRoot), flush: true);
    await File(
      '${file.path}.tmp',
    ).writeAsString(jsonEncode(newRoot), flush: true);

    await ArchiveClient.reloadFromDisk();
    final list = await ArchiveClient().listCases();
    expect(list.map((item) => item.question), contains('临时文件中的新案例'));
    expect(list.length, 2);
    expect(await File('${file.path}.tmp').exists(), isFalse);
  });

  test('主档案损坏时使用完整临时文件恢复并保留损坏副本', () async {
    final client = ArchiveClient();
    await client.saveCast(question: '可恢复案例', preview: makePreview());
    final file = File('${tempDir.path}/liuyao_archive.json');
    final valid = await file.readAsString();
    await file.writeAsString('{broken', flush: true);
    await File('${file.path}.tmp').writeAsString(valid, flush: true);

    await ArchiveClient.reloadFromDisk();
    expect((await ArchiveClient().listCases()).single.question, '可恢复案例');
    final corruptCopies = file.parent.listSync().whereType<File>().where(
      (item) => item.path.startsWith('${file.path}.corrupt-'),
    );
    expect(corruptCopies, isNotEmpty);
  });

  test('解读使用乐观锁拒绝过期版本', () async {
    final client = ArchiveClient();
    final saved = await client.saveCast(
      question: '版本冲突',
      preview: makePreview(),
    );
    await client.appendUserAnalysis(
      caseId: saved.id,
      body: '第一版',
      expectedRevision: 0,
    );

    await expectLater(
      client.appendUserAnalysis(
        caseId: saved.id,
        body: '基于过期版本的覆盖',
        expectedRevision: 0,
      ),
      throwsA(isA<ArchiveRevisionConflict>()),
    );
    final detail = await client.getCase(saved.id);
    expect(detail.analyses.map((item) => item.body), ['第一版']);
  });

  test('新档案背景问念默认为空且不与占问回填', () async {
    final client = ArchiveClient();
    final saved = await client.saveCast(
      question: '问背景是否回填',
      preview: makePreview(),
    );
    expect(saved.question, '问背景是否回填');
    expect(saved.questionContext, '');
  });

  test('标签保存后退出重开仍然存在', () async {
    final client = ArchiveClient();
    final saved = await client.saveCast(
      question: '标签持久化',
      preview: makePreview(),
    );
    await client.updateTags(caseId: saved.id, tags: ['工作', '待复盘']);
    await ArchiveClient.reloadFromDisk();

    final detail = await ArchiveClient().getCase(saved.id);
    expect(detail.tags, containsAll(['工作', '待复盘']));
  });

  test('标签筛选包含全部已选标签', () async {
    final client = ArchiveClient();
    final work = await client.saveCast(
      question: '工作卦例',
      preview: makePreview(),
    );
    final life = await client.saveCast(
      question: '生活卦例',
      preview: makePreview(),
    );
    await client.updateTags(caseId: work.id, tags: ['工作', '待复盘']);
    await client.updateTags(caseId: life.id, tags: ['生活']);

    final all = await client.listCases(tags: const ['工作']);
    expect(all.map((item) => item.id), [work.id]);

    final both = await client.listCases(tags: const ['工作', '待复盘']);
    expect(both.map((item) => item.id), [work.id]);

    final none = await client.listCases(tags: const ['不存在']);
    expect(none, isEmpty);

    final empty = await client.listCases();
    expect(empty.length, 2);
  });

  test('旧档案迁移为标签补空数组', () async {
    final client = ArchiveClient();
    final saved = await client.saveCast(
      question: '旧档案',
      preview: makePreview(),
    );
    final file = File('${tempDir.path}/liuyao_archive.json');
    final root = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final cases = (root['cases'] as Map).cast<String, dynamic>();
    (cases[saved.id] as Map<String, dynamic>).remove('tags');
    await file.writeAsString(jsonEncode(root), flush: true);

    await ArchiveClient.reloadFromDisk();
    final detail = await ArchiveClient().getCase(saved.id);
    expect(detail.tags, isEmpty);
  });
}
