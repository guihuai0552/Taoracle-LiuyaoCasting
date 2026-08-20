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
}
