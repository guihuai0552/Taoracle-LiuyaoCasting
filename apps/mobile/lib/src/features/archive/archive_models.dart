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
    final chartJson = json['chart'] as Map<String, dynamic>;
    return CaseDetail(
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
