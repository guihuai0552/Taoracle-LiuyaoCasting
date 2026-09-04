import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:liuyao_engine/liuyao_engine.dart' as engine;
import 'package:path_provider/path_provider.dart';

import '../casting/casting_models.dart';
import 'archive_models.dart';

/// ============================================================================
/// 本地存档数据源（100% 纯 Dart，持久化到 App 私有目录，无需后端服务）
///
/// 持久化机制：
///   - 使用 path_provider 的 getApplicationDocumentsDirectory() 获取 App
///     私有目录（Android: `/data/data/<pkg>/files`；iOS: `Documents/`）。
///   - 全部案例以带版本号的 JSON 容器文件 liuyao_archive.json 存储。
///   - 启动首次访问时 _ensureLoaded 从磁盘加载到内存；
///     每次变更（保存/解读/反馈）后 _persist 落盘。
///   - 该目录由系统持久保留，退出/后台不丢失；卸载 App 才删除。
///   - 写入先落临时文件再原子替换，避免进程中断留下半份 JSON。
///   - 解析或落盘失败会显式抛错，禁止静默覆盖用户已有档案。
/// ============================================================================

const int archiveStoreSchemaVersion = 2;
const int archiveTransferSchemaVersion = 1;
const int archiveImportMaxBytes = 64 * 1024 * 1024;
const String archiveTransferFormat = 'liuyao_archive_transfer';

String decodeArchiveTransferBytes(List<int> bytes) {
  if (bytes.length > archiveImportMaxBytes) {
    throw const FormatException('迁移文件超过 64 MB 上限');
  }
  final decoded = utf8.decode(bytes, allowMalformed: false);
  return decoded.startsWith('\ufeff') ? decoded.substring(1) : decoded;
}

class ArchiveStorageException implements Exception {
  const ArchiveStorageException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'ArchiveStorageException: $message';
}

class ArchiveRevisionConflict implements Exception {
  const ArchiveRevisionConflict({required this.expected, required this.actual});

  final int expected;
  final int actual;

  @override
  String toString() => '档案版本冲突：期望 $expected，当前 $actual';
}

abstract class ArchiveDataSource {
  Future<List<CaseSummary>> listCases({
    String query = '',
    List<String> tags = const [],
  });
  Future<CaseDetail> saveCast({
    String title = '',
    required String question,
    required CastPreview preview,
  });
  Future<CaseDetail> getCase(String id);
  Future<void> deleteCase(String id);
  Future<void> updateQuestionContext({
    required String caseId,
    required String context,
  });
  Future<void> updateTags({required String caseId, required List<String> tags});
  Future<void> appendUserAnalysis({
    required String caseId,
    required String body,
    required int expectedRevision,
  });
  Future<void> appendFeedback({
    required String caseId,
    required String body,
    required String status,
    DateTime? occurredAt,
  });
  Future<void> updateFeedback({
    required String caseId,
    required String feedbackId,
    required String body,
    required String status,
    DateTime? occurredAt,
  });
  Future<CaseExportFile> exportCase(String id, {required String format});
  Future<CaseExportFile> exportAllCases();
  Future<ArchiveImportPreview> inspectImport(String content);
  Future<ArchiveImportResult> importCases(
    String content, {
    required ArchiveImportMode mode,
  });
  void close();
}

class _TransferBundle {
  const _TransferBundle({required this.cases, required this.sourceLabel});

  final List<Map<String, dynamic>> cases;
  final String sourceLabel;
}

/// 进程内内存缓存：id -> 完整案例 JSON
final Map<String, Map<String, dynamic>> _store =
    <String, Map<String, dynamic>>{};
int _idCounter = 0;

/// 持久化状态
bool _loaded = false;
String? _storeFilePath;
Future<void> _writeQueue = Future<void>.value();

/// 目录解析注入点：生产用 getApplicationDocumentsDirectory；
/// 测试时可覆盖为临时目录以隔离。
Future<Directory> Function()? directoryOverride;

class _ArchiveSnapshot {
  const _ArchiveSnapshot({
    required this.file,
    required this.updatedAt,
    required this.cases,
  });

  final File file;
  final DateTime updatedAt;
  final Map<String, Map<String, dynamic>> cases;
}

/// 解析持久化文件路径（缓存）
Future<String> _resolveStoreFile() async {
  if (_storeFilePath != null) return _storeFilePath!;
  final dir = directoryOverride != null
      ? await directoryOverride!()
      : await getApplicationDocumentsDirectory();
  _storeFilePath = '${dir.path}/liuyao_archive.json';
  return _storeFilePath!;
}

Future<_ArchiveSnapshot?> _readSnapshot(File file) async {
  if (!await file.exists()) return null;
  final raw = await file.readAsString();
  if (raw.trim().isEmpty) {
    throw const FormatException('档案文件为空');
  }
  final decoded = jsonDecode(raw);
  if (decoded is! Map) {
    throw const FormatException('档案根节点必须是对象');
  }
  final root = Map<String, dynamic>.from(decoded);
  final Object? rawCases;
  DateTime? updatedAt;
  if (root.containsKey('schema_version')) {
    final version = root['schema_version'];
    if (version is! num || version.toInt() > archiveStoreSchemaVersion) {
      throw FormatException('不支持的档案版本：$version');
    }
    rawCases = root['cases'];
    final rawUpdatedAt = root['updated_at'];
    if (rawUpdatedAt is String) updatedAt = DateTime.tryParse(rawUpdatedAt);
  } else {
    // v0：早期文件直接以 case id -> case JSON 作为根对象。
    rawCases = root;
  }
  if (rawCases is! Map) {
    throw const FormatException('档案 cases 节点必须是对象');
  }
  final cases = <String, Map<String, dynamic>>{};
  for (final entry in rawCases.entries) {
    if (entry.key is! String || entry.value is! Map) {
      throw const FormatException('档案案例条目格式无效');
    }
    final caseJson = Map<String, dynamic>.from(entry.value as Map);
    _migrateCaseJson(caseJson);
    cases[entry.key as String] = caseJson;
  }
  return _ArchiveSnapshot(
    file: file,
    updatedAt: updatedAt ?? await file.lastModified(),
    cases: cases,
  );
}

/// 启动首次访问时从磁盘加载存档到内存
Future<void> _ensureLoaded() async {
  if (_loaded) return;
  await _writeQueue;
  try {
    final path = await _resolveStoreFile();
    final file = File(path);
    final temporary = File('$path.tmp');
    _ArchiveSnapshot? committed;
    _ArchiveSnapshot? staged;
    Object? committedError;
    Object? stagedError;
    try {
      committed = await _readSnapshot(file);
    } on Object catch (error) {
      committedError = error;
    }
    try {
      staged = await _readSnapshot(temporary);
    } on Object catch (error) {
      stagedError = error;
    }

    if (committed == null && staged == null) {
      if (committedError != null || stagedError != null) {
        throw FormatException(
          '主档案与临时恢复文件均不可读取：'
          '${committedError ?? '主档案不存在'}；${stagedError ?? '临时文件不存在'}',
        );
      }
      _loaded = true;
      return;
    }

    final selected =
        staged != null &&
            (committed == null || staged.updatedAt.isAfter(committed.updatedAt))
        ? staged
        : committed!;

    if (selected.file.path == temporary.path) {
      if (await file.exists()) {
        if (committedError != null) {
          final suffix = DateTime.now().microsecondsSinceEpoch;
          await file.rename('$path.corrupt-$suffix');
        } else {
          await file.delete();
        }
      }
      await temporary.rename(path);
    } else if (await temporary.exists()) {
      // 主档案更新或临时文件无效时，清理不再需要的写入中间文件。
      await temporary.delete();
    }

    _store
      ..clear()
      ..addAll(selected.cases);
    _loaded = true;
  } on ArchiveStorageException {
    rethrow;
  } on Object catch (error) {
    _store.clear();
    _loaded = false;
    throw ArchiveStorageException('无法读取本地档案；原文件未被覆盖', error);
  }
}

/// 将内存存档落盘
Future<void> _persist() async {
  final encoded = const JsonEncoder.withIndent('  ').convert({
    'schema_version': archiveStoreSchemaVersion,
    'updated_at': DateTime.now().toUtc().toIso8601String(),
    'cases': _store,
  });
  final operation = _writeQueue.then((_) async {
    try {
      final path = await _resolveStoreFile();
      final file = File(path);
      await file.parent.create(recursive: true);
      final temporary = File('$path.tmp');
      await temporary.writeAsString(encoded, flush: true);
      await temporary.rename(path);
    } on Object catch (error) {
      throw ArchiveStorageException('无法写入本地档案', error);
    }
  });
  _writeQueue = operation.catchError((Object _) {});
  await operation;
}

void _migrateCaseJson(Map<String, dynamic> json) {
  // v1 案例没有上下文字段；迁移只补默认值，不重算历史卦象。
  // 背景问念不回填 question（保持空白，由用户后续补充，2026-08-20 需求）。
  json.putIfAbsent('questionContext', () => '');
  json.putIfAbsent('questionContextUpdatedAt', () => null);
  json.putIfAbsent(
    'calendarPolicy',
    () => <String, dynamic>{
      'dayBoundary': 'civil_23_next_day',
      'monthBoundary': 'solar_term_zi_hour',
      'timezone': 'Asia/Shanghai',
    },
  );
  json.putIfAbsent(
    'fourPillarsContext',
    () => <String, dynamic>{
      'source': 'calculated',
      'calculated': null,
      'manual': null,
    },
  );
  json.putIfAbsent(
    'displayContext',
    () => <String, dynamic>{
      'annotationMode': 'twelve_growth',
      'growthReference': 'day_pillar',
    },
  );
  json.putIfAbsent(
    'castingContext',
    () => <String, dynamic>{
      'method': json['castingMethod'] as String? ?? 'manual',
      'rawInput': null,
    },
  );
  json.putIfAbsent('tags', () => <String>[]);
}

class ArchiveClient implements ArchiveDataSource {
  ArchiveClient();

  /// 自增 ID
  String _nextId() {
    _idCounter += 1;
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return 'case-$stamp-$_idCounter';
  }

  @override
  Future<List<CaseSummary>> listCases({
    String query = '',
    List<String> tags = const [],
  }) async {
    await _ensureLoaded();

    final items = _store.values.toList()
      ..sort((a, b) {
        final ua = DateTime.parse(a['updatedAt'] as String);
        final ub = DateTime.parse(b['updatedAt'] as String);
        return ub.compareTo(ua);
      });

    final q = query.trim();
    final activeTags = tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet();
    final filtered = items
        .where((json) {
          final textMatches =
              q.isEmpty ||
              [
                json['title'] as String? ?? '',
                json['question'] as String? ?? '',
                json['baseHexagram'] as String? ?? '',
                json['changedHexagram'] as String? ?? '',
                for (final analysis in json['analyses'] as List? ?? const [])
                  (analysis as Map)['body'] as String? ?? '',
                for (final feedback in json['feedbacks'] as List? ?? const [])
                  (feedback as Map)['body'] as String? ?? '',
              ].join('\n').contains(q);
          if (!textMatches) return false;
          // 标签筛选：档案必须包含全部已选 Tag。
          if (activeTags.isEmpty) return true;
          final caseTags = _stringTags(json['tags']).toSet();
          return activeTags.every(caseTags.contains);
        })
        .toList(growable: false);
    return filtered
        .map((json) => CaseSummary.fromJson(json))
        .toList(growable: false);
  }

  static Set<String> _stringTags(Object? value) {
    if (value is! List) return <String>{};
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  @override
  Future<CaseDetail> saveCast({
    String title = '',
    required String question,
    required CastPreview preview,
  }) async {
    await _ensureLoaded();

    final id = _nextId();
    final now = DateTime.now();
    final resolvedTitle = title.trim().isEmpty
        ? preview.baseHexagram
        : title.trim();

    // 手动四柱模式下引擎已直接按手动四柱排盘（chart 的 time 段即手动值，
    // source=manual_input）；自动推算的四柱单独重算一份保留在
    // fourPillarsContext.calculated 供追溯。
    final calendarPolicy =
        preview.rawJson['calendar_policy'] as Map<String, dynamic>? ??
        <String, dynamic>{
          'dayBoundary': 'civil_23_next_day',
          'monthBoundary': 'solar_term_zi_hour',
          'timezone': 'Asia/Shanghai',
        };
    final calculatedPillars = preview.fourPillarsSource == 'manual'
        ? _calculateAutoPillars(preview.castAt, calendarPolicy)
        : () {
            final autoTime =
                preview.rawJson['time'] as Map<String, dynamic>? ??
                const <String, dynamic>{};
            return <String, String>{
              'year': autoTime['year'] as String? ?? preview.yearPillar,
              'month': autoTime['month'] as String? ?? preview.monthPillar,
              'day': autoTime['day'] as String? ?? preview.dayPillar,
              'hour': autoTime['hour'] as String? ?? preview.hourPillar,
            };
          }();

    final json = <String, dynamic>{
      'id': id,
      'title': resolvedTitle,
      'question': question,
      // 背景问念默认空白，由用户在档案详情中后续补充（2026-08-20 需求）。
      'questionContext': '',
      'questionContextUpdatedAt': null,
      'castAt': preview.castAt.toIso8601String(),
      'castingMethod': preview.castingRecord.method,
      'calendarPolicy': calendarPolicy,
      'fourPillarsContext': <String, dynamic>{
        'source': preview.fourPillarsSource,
        'calculated': calculatedPillars,
        'manual': preview.manualFourPillars?.toJson(),
      },
      'displayContext': <String, dynamic>{
        'annotationMode': 'twelve_growth',
        'growthReference': 'day_pillar',
      },
      'castingContext': <String, dynamic>{
        'method': preview.castingRecord.method,
        'rawInput': preview.castingRecord.lineValues,
      },
      'tags': <String>[],
      'baseHexagram': preview.baseHexagram,
      'changedHexagram': preview.changedHexagram,
      'latestAnalysisRevision': 0,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      // 手动四柱模式下，引擎排盘结果（rawJson）的 time 段即手动四柱
      // （source=manual_input），六神/旬空等已按手动日柱计算。
      'chart': preview.rawJson,
      'analyses': <Map<String, dynamic>>[],
      'feedbacks': <Map<String, dynamic>>[],
    };

    _store[id] = json;
    await _persist();
    return CaseDetail.fromJson(json);
  }

  /// 按起卦时间与历法口径自动推算四柱（用于手动四柱档案的
  /// fourPillarsContext.calculated 溯源记录；失败时回退空表）。
  static Map<String, String> _calculateAutoPillars(
    DateTime castAt,
    Map<String, dynamic> calendarPolicy,
  ) {
    try {
      final almanac = engine.calculateAlmanac(
        castAt,
        timezoneName: 'Asia/Shanghai',
        dayBoundary:
            calendarPolicy['dayBoundary'] as String? ??
            engine.dayBoundaryCivil23NextDay,
        monthBoundary:
            calendarPolicy['monthBoundary'] as String? ??
            engine.monthBoundarySolarTermZiHour,
      );
      final pillars = <String, String>{};
      for (final p in almanac['four_pillars'] as List) {
        final entry = p as Map<String, dynamic>;
        pillars[entry['position'] as String] = entry['ganzhi'] as String;
      }
      if (pillars.length == 4) return pillars;
    } on Object {
      // 推算失败时保留空溯源，不影响档案主数据。
    }
    return const <String, String>{};
  }

  @override
  Future<CaseDetail> getCase(String id) async {
    await _ensureLoaded();
    final json = _store[id];
    if (json == null) {
      throw Exception('找不到案例：$id');
    }
    return CaseDetail.fromJson(json);
  }

  @override
  Future<void> deleteCase(String id) async {
    await _ensureLoaded();
    final json = _store[id];
    if (json == null) throw Exception('找不到案例：$id');
    _store.remove(id);
    await _persist();
  }

  @override
  Future<void> updateQuestionContext({
    required String caseId,
    required String context,
  }) async {
    await _ensureLoaded();
    final json = _store[caseId];
    if (json == null) throw Exception('找不到案例：$caseId');
    final normalized = context.trim();
    if (normalized.length > 10_000) {
      throw Exception('背景问念不能超过 10000 字');
    }
    final now = DateTime.now().toIso8601String();
    json['questionContext'] = normalized;
    json['questionContextUpdatedAt'] = now;
    json['updatedAt'] = now;
    await _persist();
  }

  @override
  Future<void> updateTags({
    required String caseId,
    required List<String> tags,
  }) async {
    await _ensureLoaded();
    final json = _store[caseId];
    if (json == null) throw Exception('找不到案例：$caseId');
    final normalized = <String>[];
    final seen = <String>{};
    for (final tag in tags) {
      final trimmed = tag.trim();
      if (trimmed.isEmpty || !seen.add(trimmed)) continue;
      if (trimmed.length > 20) {
        throw Exception('标签「$trimmed」过长，最多 20 字');
      }
      normalized.add(trimmed);
    }
    if (normalized.length > 30) {
      throw Exception('一个档案最多 30 个标签');
    }
    final now = DateTime.now().toIso8601String();
    json['tags'] = normalized;
    json['updatedAt'] = now;
    await _persist();
  }

  @override
  Future<void> appendUserAnalysis({
    required String caseId,
    required String body,
    required int expectedRevision,
  }) async {
    await _ensureLoaded();
    final json = _store[caseId];
    if (json == null) throw Exception('找不到案例：$caseId');

    final actualRevision = json['latestAnalysisRevision'] as int? ?? 0;
    if (actualRevision != expectedRevision) {
      throw ArchiveRevisionConflict(
        expected: expectedRevision,
        actual: actualRevision,
      );
    }

    final now = DateTime.now().toIso8601String();
    final revision = expectedRevision + 1;
    (json['analyses'] as List).add({
      'id': 'analysis-$caseId-$revision',
      'author': 'user',
      'body': body,
      'revision': revision,
      'createdAt': now,
    });
    json['latestAnalysisRevision'] = revision;
    json['updatedAt'] = now;
    await _persist();
  }

  @override
  Future<void> appendFeedback({
    required String caseId,
    required String body,
    required String status,
    DateTime? occurredAt,
  }) async {
    await _ensureLoaded();
    final json = _store[caseId];
    if (json == null) throw Exception('找不到案例：$caseId');

    final now = DateTime.now().toIso8601String();
    final fbId = 'feedback-$caseId-${(json['feedbacks'] as List).length + 1}';
    (json['feedbacks'] as List).add({
      'id': fbId,
      'body': body,
      'status': status,
      'occurredAt': occurredAt?.toIso8601String(),
      'createdAt': now,
      'updatedAt': now,
    });
    json['updatedAt'] = now;
    await _persist();
  }

  @override
  Future<void> updateFeedback({
    required String caseId,
    required String feedbackId,
    required String body,
    required String status,
    DateTime? occurredAt,
  }) async {
    await _ensureLoaded();
    final json = _store[caseId];
    if (json == null) throw Exception('找不到案例：$caseId');

    final now = DateTime.now().toIso8601String();
    final list = json['feedbacks'] as List;
    var found = false;
    for (int i = 0; i < list.length; i++) {
      final fb = list[i] as Map<String, dynamic>;
      if (fb['id'] == feedbackId) {
        found = true;
        fb['body'] = body;
        fb['status'] = status;
        fb['occurredAt'] = occurredAt?.toIso8601String();
        fb['updatedAt'] = now;
        break;
      }
    }
    if (!found) throw Exception('找不到反馈：$feedbackId');
    json['updatedAt'] = now;
    await _persist();
  }

  @override
  Future<CaseExportFile> exportCase(String id, {required String format}) async {
    await _ensureLoaded();
    if (format != 'json' && format != 'markdown') {
      throw ArgumentError.value(format, 'format', '必须是 json 或 markdown');
    }
    final stored = _store[id];
    if (stored == null) throw Exception('找不到案例：$id');

    // 旧手动四柱档案的快照经解析层校正后再导出，保证与详情页、
    // 图片导出展示一致。
    final correctedChart = CaseDetail.fromJson(stored).chartJson;
    final json = _deepCopy(stored)..['chart'] = correctedChart;

    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    if (format == 'json') {
      return CaseExportFile(
        filename: 'liuyao-$stamp.json',
        contentType: 'application/json',
        content: const JsonEncoder.withIndent('  ').convert(json),
      );
    }

    return CaseExportFile(
      filename: 'liuyao-$stamp.md',
      contentType: 'text/markdown',
      content: _toMarkdown(json),
    );
  }

  @override
  Future<CaseExportFile> exportAllCases() async {
    await _ensureLoaded();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final cases = _store.values.map(_deepCopy).toList(growable: false)
      ..sort((a, b) {
        final left = DateTime.parse(a['createdAt'] as String);
        final right = DateTime.parse(b['createdAt'] as String);
        return left.compareTo(right);
      });
    return CaseExportFile(
      filename: 'liuyao-archive-transfer-$stamp.json',
      contentType: 'application/json',
      content: const JsonEncoder.withIndent('  ').convert({
        'format': archiveTransferFormat,
        'schema_version': archiveTransferSchemaVersion,
        'exported_at': DateTime.now().toUtc().toIso8601String(),
        'case_count': cases.length,
        'includes': const ['chart', 'analyses', 'feedbacks'],
        'cases': cases,
      }),
    );
  }

  @override
  Future<ArchiveImportPreview> inspectImport(String content) async {
    await _ensureLoaded();
    final bundle = _parseTransfer(content);
    var newCases = 0;
    var identicalCases = 0;
    var conflictingCases = 0;
    var analysisCount = 0;
    var feedbackCount = 0;
    for (final incoming in bundle.cases) {
      analysisCount += (incoming['analyses'] as List).length;
      feedbackCount += (incoming['feedbacks'] as List).length;
      final existing = _store[incoming['id'] as String];
      if (existing == null) {
        newCases += 1;
      } else if (_sameJson(existing, incoming)) {
        identicalCases += 1;
      } else {
        conflictingCases += 1;
      }
    }
    return ArchiveImportPreview(
      totalCases: bundle.cases.length,
      newCases: newCases,
      identicalCases: identicalCases,
      conflictingCases: conflictingCases,
      analysisCount: analysisCount,
      feedbackCount: feedbackCount,
      sourceLabel: bundle.sourceLabel,
    );
  }

  @override
  Future<ArchiveImportResult> importCases(
    String content, {
    required ArchiveImportMode mode,
  }) async {
    await _ensureLoaded();
    final bundle = _parseTransfer(content);
    final before = _store.map((key, value) => MapEntry(key, _deepCopy(value)));
    var imported = 0;
    var skipped = 0;
    var copiedConflicts = 0;
    final replacedExisting = mode == ArchiveImportMode.replaceAll
        ? _store.length
        : 0;
    try {
      if (mode == ArchiveImportMode.replaceAll) _store.clear();
      for (final rawIncoming in bundle.cases) {
        final incoming = _deepCopy(rawIncoming);
        final id = incoming['id'] as String;
        final existing = _store[id];
        if (existing == null) {
          _store[id] = incoming;
          imported += 1;
          continue;
        }
        if (_sameJson(existing, incoming)) {
          skipped += 1;
          continue;
        }
        final copiedId = _nextId();
        incoming['id'] = copiedId;
        incoming['title'] = '${incoming['title']}（导入副本）';
        incoming['updatedAt'] = DateTime.now().toIso8601String();
        _store[copiedId] = incoming;
        imported += 1;
        copiedConflicts += 1;
      }
      await _persist();
    } on Object {
      _store
        ..clear()
        ..addAll(before);
      rethrow;
    }
    return ArchiveImportResult(
      importedCases: imported,
      skippedCases: skipped,
      copiedConflicts: copiedConflicts,
      replacedExistingCases: replacedExisting,
    );
  }

  _TransferBundle _parseTransfer(String content) {
    if (utf8.encode(content).length > archiveImportMaxBytes) {
      throw const FormatException('迁移文件超过 64 MB 上限');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(content);
    } on Object catch (error) {
      throw FormatException('迁移文件不是有效 JSON：$error');
    }
    if (decoded is! Map) {
      throw const FormatException('迁移文件根节点必须是对象');
    }
    final root = Map<String, dynamic>.from(decoded);
    late final Iterable<dynamic> rawCases;
    late final String sourceLabel;
    if (root['format'] == archiveTransferFormat) {
      if (root['schema_version'] != archiveTransferSchemaVersion) {
        throw FormatException('不支持的迁移文件版本：${root['schema_version']}');
      }
      if (root['cases'] is! List) {
        throw const FormatException('迁移文件 cases 必须是数组');
      }
      rawCases = root['cases'] as List;
      final declaredCount = root['case_count'];
      if (declaredCount is! int || declaredCount != rawCases.length) {
        throw const FormatException('迁移文件 case_count 与实际档案数量不一致');
      }
      sourceLabel = '批量迁移包 v${root['schema_version']}';
    } else if (root.containsKey('id') && root.containsKey('chart')) {
      rawCases = [root];
      sourceLabel = '单档 JSON';
    } else if (root['cases'] is Map) {
      final version = root['schema_version'];
      if (version != null && version != archiveStoreSchemaVersion) {
        throw FormatException('不支持的本地档案容器版本：$version');
      }
      rawCases = (root['cases'] as Map).values;
      sourceLabel = '本地档案容器';
    } else {
      throw const FormatException('无法识别该 JSON；请选择六爻档案迁移文件');
    }

    final cases = <Map<String, dynamic>>[];
    final ids = <String>{};
    var index = 0;
    for (final raw in rawCases) {
      index += 1;
      if (raw is! Map) throw FormatException('第 $index 条案例不是对象');
      final item = Map<String, dynamic>.from(raw);
      try {
        CaseDetail.fromJson(item);
      } on Object catch (error) {
        throw FormatException('第 $index 条案例不完整：$error');
      }
      final id = item['id'] as String;
      if (id.trim().isEmpty) throw FormatException('第 $index 条案例缺少 id');
      if (!ids.add(id)) throw FormatException('迁移文件包含重复案例 id：$id');
      cases.add(_deepCopy(item));
    }
    return _TransferBundle(cases: cases, sourceLabel: sourceLabel);
  }

  static Map<String, dynamic> _deepCopy(Map<String, dynamic> source) =>
      Map<String, dynamic>.from(jsonDecode(jsonEncode(source)) as Map);

  static bool _sameJson(
    Map<String, dynamic> left,
    Map<String, dynamic> right,
  ) => jsonEncode(left) == jsonEncode(right);

  /// 生成可读 Markdown 档案
  String _toMarkdown(Map<String, dynamic> json) {
    final title = json['title'] as String? ?? '未命名';
    final question = json['question'] as String? ?? '';
    final castAt = json['castAt'] as String? ?? '';
    final method = json['castingMethod'] as String? ?? '';
    final base = json['baseHexagram'] as String? ?? '';
    final changed = json['changedHexagram'] as String?;
    final buf = StringBuffer();

    buf.writeln('# $title');
    buf.writeln();
    buf.writeln('- 起卦时间：$castAt');
    buf.writeln('- 起卦方式：${method == 'manual' ? '手动起卦' : '自动铜钱'}');
    buf.writeln('- 本卦：$base');
    if (changed != null) buf.writeln('- 变卦：$changed');
    buf.writeln();
    buf.writeln('## 占问');
    buf.writeln(question);
    buf.writeln();

    final analyses = json['analyses'] as List? ?? const [];
    if (analyses.isNotEmpty) {
      buf.writeln('## 解读');
      for (final a in analyses) {
        final m = a as Map<String, dynamic>;
        buf.writeln('### 版本 ${m['revision']}（${m['createdAt']}）');
        buf.writeln(m['body'] as String? ?? '');
        buf.writeln();
      }
    }

    final feedbacks = json['feedbacks'] as List? ?? const [];
    if (feedbacks.isNotEmpty) {
      buf.writeln('## 反馈');
      for (final f in feedbacks) {
        final m = f as Map<String, dynamic>;
        buf.writeln(
          '- [${m['status']}] ${m['occurredAt'] ?? m['createdAt']}：${m['body']}',
        );
      }
      buf.writeln();
    }

    final chart = json['chart'];
    if (chart != null) {
      buf.writeln('## 完整卦面快照');
      buf.writeln('```json');
      buf.writeln(const JsonEncoder.withIndent('  ').convert(chart));
      buf.writeln('```');
    }
    return buf.toString();
  }

  @override
  void close() {
    // 纯内存 + 文件，无需关闭
  }

  /// 仅测试用：重置内存缓存与加载状态，强制下次访问重新从磁盘读取，
  /// 用以模拟「退出后重新打开 App」。
  @visibleForTesting
  static Future<void> reloadFromDisk() async {
    await _writeQueue;
    _store.clear();
    _loaded = false;
    _storeFilePath = null;
    await _ensureLoaded();
  }

  /// 仅测试用：清空进程状态但不读取任何目录。
  @visibleForTesting
  static Future<void> resetForTesting() async {
    await _writeQueue;
    _store.clear();
    _loaded = false;
    _storeFilePath = null;
  }
}
