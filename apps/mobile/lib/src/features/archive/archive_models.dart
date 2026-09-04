import 'package:liuyao_engine/liuyao_engine.dart' as engine;

import '../casting/casting_models.dart';

class CaseSummary {
  const CaseSummary({
    required this.id,
    required this.title,
    required this.question,
    required this.castAt,
    required this.castingMethod,
    required this.baseHexagram,
    required this.changedHexagram,
    required this.latestAnalysisRevision,
    required this.createdAt,
    required this.updatedAt,
    this.questionContext = '',
    this.questionContextUpdatedAt,
    this.calendarPolicy = const <String, dynamic>{},
    this.fourPillarsContext = const <String, dynamic>{},
    this.displayContext = const <String, dynamic>{},
    this.castingContext = const <String, dynamic>{},
    this.tags = const [],
  });

  factory CaseSummary.fromJson(Map<String, dynamic> json) => CaseSummary(
    id: json['id'] as String,
    title: json['title'] as String,
    question: json['question'] as String,
    castAt: _parseWallClock(json['castAt'] as String),
    castingMethod: json['castingMethod'] as String,
    baseHexagram: json['baseHexagram'] as String,
    changedHexagram: json['changedHexagram'] as String?,
    latestAnalysisRevision: json['latestAnalysisRevision'] as int? ?? 0,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    questionContext:
        json['questionContext'] as String? ??
        json['question_context'] as String? ??
        '',
    questionContextUpdatedAt: _parseOptionalDate(
      json['questionContextUpdatedAt'] ?? json['question_context_updated_at'],
    ),
    calendarPolicy: _mapOrEmpty(
      json['calendarPolicy'] ?? json['calendar_policy'],
    ),
    fourPillarsContext: _mapOrEmpty(
      json['fourPillarsContext'] ?? json['four_pillars_context'],
    ),
    displayContext: _mapOrEmpty(
      json['displayContext'] ?? json['display_context'],
    ),
    castingContext: _mapOrEmpty(
      json['castingContext'] ?? json['casting_context'],
    ),
    tags: _stringList(json['tags']),
  );

  final String id;
  final String title;
  final String question;
  final DateTime castAt;
  final String castingMethod;
  final String baseHexagram;
  final String? changedHexagram;
  final int latestAnalysisRevision;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String questionContext;
  final DateTime? questionContextUpdatedAt;
  final Map<String, dynamic> calendarPolicy;
  final Map<String, dynamic> fourPillarsContext;
  final Map<String, dynamic> displayContext;
  final Map<String, dynamic> castingContext;
  final List<String> tags;
}

class CaseAnalysis {
  const CaseAnalysis({
    required this.id,
    required this.author,
    required this.body,
    required this.revision,
    required this.createdAt,
  });

  factory CaseAnalysis.fromJson(Map<String, dynamic> json) => CaseAnalysis(
    id: json['id'] as String,
    author: json['author'] as String,
    body: json['body'] as String,
    revision: json['revision'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  final String id;
  final String author;
  final String body;
  final int revision;
  final DateTime createdAt;
}

class CaseFeedback {
  const CaseFeedback({
    required this.id,
    required this.body,
    required this.status,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CaseFeedback.fromJson(Map<String, dynamic> json) => CaseFeedback(
    id: json['id'] as String,
    body: json['body'] as String,
    status: json['status'] as String,
    occurredAt: json['occurredAt'] == null
        ? null
        : DateTime.parse(json['occurredAt'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  final String id;
  final String body;
  final String status;
  final DateTime? occurredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class CaseDetail extends CaseSummary {
  CaseDetail({
    required super.id,
    required super.title,
    required super.question,
    required super.castAt,
    required super.castingMethod,
    required super.baseHexagram,
    required super.changedHexagram,
    required super.latestAnalysisRevision,
    required super.createdAt,
    required super.updatedAt,
    super.questionContext,
    super.questionContextUpdatedAt,
    super.calendarPolicy,
    super.fourPillarsContext,
    super.displayContext,
    super.castingContext,
    super.tags,
    required this.chart,
    required this.chartJson,
    required this.analyses,
    required this.feedbacks,
  });

  factory CaseDetail.fromJson(Map<String, dynamic> json) {
    final fourPillarsContext = _mapOrEmpty(
      json['fourPillarsContext'] ?? json['four_pillars_context'],
    );
    final calendarPolicy = _mapOrEmpty(
      json['calendarPolicy'] ?? json['calendar_policy'],
    );
    // 历史手动四柱档案的快照曾按自动日柱起六神/旬空（2026-09 修复的
    // bug）：读取时以手动四柱重排修正，保证详情与导出展示一致。
    final castAt = _parseWallClock(json['castAt'] as String);
    final chartJson =
        _rechartManualPillarsSnapshot(
          json['chart'] as Map<String, dynamic>,
          fourPillarsContext,
          calendarPolicy,
          castAt,
        ) ??
        json['chart'] as Map<String, dynamic>;
    return CaseDetail(
      id: json['id'] as String,
      title: json['title'] as String,
      question: json['question'] as String,
      castAt: castAt,
      castingMethod: json['castingMethod'] as String,
      baseHexagram: json['baseHexagram'] as String,
      changedHexagram: json['changedHexagram'] as String?,
      latestAnalysisRevision: json['latestAnalysisRevision'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      questionContext:
          json['questionContext'] as String? ??
          json['question_context'] as String? ??
          '',
      questionContextUpdatedAt: _parseOptionalDate(
        json['questionContextUpdatedAt'] ?? json['question_context_updated_at'],
      ),
      calendarPolicy: calendarPolicy,
      fourPillarsContext: fourPillarsContext,
      displayContext: _mapOrEmpty(
        json['displayContext'] ?? json['display_context'],
      ),
      castingContext: _mapOrEmpty(
        json['castingContext'] ?? json['casting_context'],
      ),
      tags: _stringList(json['tags']),
      chart: CastPreview.fromJson(chartJson),
      chartJson: Map<String, dynamic>.unmodifiable(chartJson),
      analyses: (json['analyses'] as List<dynamic>)
          .map((item) => CaseAnalysis.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      feedbacks: (json['feedbacks'] as List<dynamic>? ?? const [])
          .map((item) => CaseFeedback.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final CastPreview chart;
  final Map<String, dynamic> chartJson;
  final List<CaseAnalysis> analyses;
  final List<CaseFeedback> feedbacks;
}

class CaseExportFile {
  const CaseExportFile({
    required this.filename,
    required this.contentType,
    required this.content,
  });

  final String filename;
  final String contentType;
  final String content;
}

enum ArchiveImportMode { merge, replaceAll }

class ArchiveImportPreview {
  const ArchiveImportPreview({
    required this.totalCases,
    required this.newCases,
    required this.identicalCases,
    required this.conflictingCases,
    required this.analysisCount,
    required this.feedbackCount,
    required this.sourceLabel,
  });

  final int totalCases;
  final int newCases;
  final int identicalCases;
  final int conflictingCases;
  final int analysisCount;
  final int feedbackCount;
  final String sourceLabel;
}

class ArchiveImportResult {
  const ArchiveImportResult({
    required this.importedCases,
    required this.skippedCases,
    required this.copiedConflicts,
    required this.replacedExistingCases,
  });

  final int importedCases;
  final int skippedCases;
  final int copiedConflicts;
  final int replacedExistingCases;
}

DateTime? _parseOptionalDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

/// 旧手动四柱档案快照校正：以手动四柱重排卦面。
///
/// 2026-09 之前保存的手动四柱档案，快照中六神、旬空、十二长生等均按
/// 自动推算的日柱计算（手动四柱只覆盖了显示文本）。读取时按档案记录的
/// 手动四柱与原始爻值重排，修正六神（日干起）等全部日柱相关结果。
///
/// 返回 null 表示无需或无法校正（保持原快照）：非手动来源、非手动起卦
/// 方法、手动四柱不完整或含非法干支、缺少爻值，或快照已按手动四柱生成
/// （`time.source == 'manual_input'`）。
///
/// 注意：不能以"六神与手动日干匹配"作为跳过条件——旬空、十二长生与
/// 神煞取决于完整日柱（含地支），同干不同支（如自动庚辰 vs 手动庚寅）
/// 时六神相同而其余结果不同，必须重排。
Map<String, dynamic>? _rechartManualPillarsSnapshot(
  Map<String, dynamic> chartJson,
  Map<String, dynamic> fourPillarsContext,
  Map<String, dynamic> calendarPolicy,
  DateTime castAt,
) {
  if (fourPillarsContext['source'] != 'manual') return null;
  final manual = fourPillarsContext['manual'];
  if (manual is! Map) return null;

  String? pillarOf(String ganKey, String zhiKey) {
    final gan = manual[ganKey];
    final zhi = manual[zhiKey];
    if (gan is! String || zhi is! String || gan.isEmpty || zhi.isEmpty) {
      return null;
    }
    final value = '$gan$zhi';
    return engine.the60HeavenlyEarth.contains(value) ? value : null;
  }

  final year = pillarOf('year_gan', 'year_zhi');
  final month = pillarOf('month_gan', 'month_zhi');
  final day = pillarOf('day_gan', 'day_zhi');
  final hour = pillarOf('hour_gan', 'hour_zhi');
  if (year == null || month == null || day == null || hour == null) {
    return null;
  }

  final time = chartJson['time'];
  final meta = chartJson['meta'];
  if (time is! Map || meta is! Map) return null;

  // 快照已按手动四柱生成则无需重排。
  if (time['source'] == 'manual_input') return null;

  // 仅校正手动起卦的档案：其他方法的快照含铜钱记录等，
  // 重排为 manual 会丢失原始起卦过程。
  if (meta['casting_method'] != 'manual') return null;

  final rawValues = meta['line_values'];
  if (rawValues is! List || rawValues.length != 6) return null;
  final lineValues = <int>[];
  for (final value in rawValues) {
    if (value is! num || !const {6, 7, 8, 9}.contains(value.toInt())) {
      return null;
    }
    lineValues.add(value.toInt());
  }

  try {
    return engine.manualCast(
      castAt,
      lineValues,
      dayBoundary:
          calendarPolicy['dayBoundary'] as String? ??
          calendarPolicy['day_boundary'] as String? ??
          engine.dayBoundaryCivil23NextDay,
      monthBoundary:
          calendarPolicy['monthBoundary'] as String? ??
          calendarPolicy['month_boundary'] as String? ??
          engine.monthBoundarySolarTermZiHour,
      manualPillars: {'year': year, 'month': month, 'day': day, 'hour': hour},
    );
  } on Object {
    return null;
  }
}

/// 解析标签列表：去空白、去重、忽略空项；缺失按空数组处理。
List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  final seen = <String>{};
  for (final item in value) {
    if (item is! String) continue;
    final trimmed = item.trim();
    if (trimmed.isEmpty) continue;
    seen.add(trimmed);
  }
  return List.unmodifiable(seen);
}

Map<String, dynamic> _mapOrEmpty(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

DateTime _parseWallClock(String value) {
  final match = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})(?::(\d{2}))?',
  ).firstMatch(value);
  if (match == null) return DateTime.parse(value);
  return DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
    int.parse(match.group(4)!),
    int.parse(match.group(5)!),
    int.parse(match.group(6) ?? '0'),
  );
}
