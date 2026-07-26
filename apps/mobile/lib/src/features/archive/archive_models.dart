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
  });

  factory CaseSummary.fromJson(Map<String, dynamic> json) => CaseSummary(
    id: json['id'] as String,
    title: json['title'] as String,
    question: json['question'] as String,
    castAt: DateTime.parse(json['castAt'] as String),
    castingMethod: json['castingMethod'] as String,
    baseHexagram: json['baseHexagram'] as String,
    changedHexagram: json['changedHexagram'] as String?,
    latestAnalysisRevision: json['latestAnalysisRevision'] as int? ?? 0,
  );

  final String id;
  final String title;
  final String question;
  final DateTime castAt;
  final String castingMethod;
  final String baseHexagram;
  final String? changedHexagram;
  final int latestAnalysisRevision;
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

class ChartLine {
  const ChartLine({
    required this.position,
    required this.yinYang,
    required this.relation,
    required this.branch,
    required this.element,
    this.value,
    this.changing = false,
    this.sixGod,
    this.role,
    this.hidden,
  });

  factory ChartLine.fromJson(Map<String, dynamic> json) => ChartLine(
    position: json['position'] as int,
    value: json['value'] as int?,
    yinYang: json['yin_yang'] as String,
    changing: json['changing'] as bool? ?? false,
    sixGod: json['six_god'] as String?,
    relation: json['relation'] as String,
    branch: json['branch'] as String,
    element: json['element'] as String,
    role: json['role'] as String?,
    hidden: json['hidden'] is Map<String, dynamic>
        ? ChartHidden.fromJson(json['hidden'] as Map<String, dynamic>)
        : null,
  );

  final int position;
  final int? value;
  final String yinYang;
  final bool changing;
  final String? sixGod;
  final String relation;
  final String branch;
  final String element;
  final String? role;
  final ChartHidden? hidden;
}

class ChartHidden {
  const ChartHidden({
    required this.relation,
    required this.branch,
    required this.element,
  });

  factory ChartHidden.fromJson(Map<String, dynamic> json) => ChartHidden(
    relation: json['relation'] as String,
    branch: json['branch'] as String,
    element: json['element'] as String,
  );

  final String relation;
  final String branch;
  final String element;
}

class ChartHexagram {
  const ChartHexagram({
    required this.name,
    required this.palaceName,
    required this.palaceElement,
    required this.lines,
  });

  factory ChartHexagram.fromJson(Map<String, dynamic> json) => ChartHexagram(
    name: json['name'] as String,
    palaceName: json['palace_name'] as String,
    palaceElement: json['palace_element'] as String? ?? '',
    lines: (json['lines'] as List<dynamic>)
        .map((item) => ChartLine.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
  );

  final String name;
  final String palaceName;
  final String palaceElement;
  final List<ChartLine> lines;
}

class ChartSnapshot {
  const ChartSnapshot({
    required this.schemaVersion,
    required this.engineVersion,
    required this.castAt,
    required this.lineValues,
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.dayVoid,
    required this.base,
    required this.changed,
  });

  factory ChartSnapshot.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>;
    final time = json['time'] as Map<String, dynamic>;
    final hexagram = json['hexagram'] as Map<String, dynamic>;
    return ChartSnapshot(
      schemaVersion: json['schema_version'] as int,
      engineVersion: json['engine_version'] as String,
      castAt: DateTime.parse(meta['cast_at'] as String),
      lineValues: (meta['line_values'] as List<dynamic>).cast<int>(),
      year: time['year'] as String,
      month: time['month'] as String,
      day: time['day'] as String,
      hour: time['hour'] as String,
      dayVoid: time['day_void'] as String,
      base: ChartHexagram.fromJson(hexagram['base'] as Map<String, dynamic>),
      changed: hexagram['changed'] is Map<String, dynamic>
          ? ChartHexagram.fromJson(hexagram['changed'] as Map<String, dynamic>)
          : null,
    );
  }

  final int schemaVersion;
  final String engineVersion;
  final DateTime castAt;
  final List<int> lineValues;
  final String year;
  final String month;
  final String day;
  final String hour;
  final String dayVoid;
  final ChartHexagram base;
  final ChartHexagram? changed;
}

class CaseDetail extends CaseSummary {
  const CaseDetail({
    required super.id,
    required super.title,
    required super.question,
    required super.castAt,
    required super.castingMethod,
    required super.baseHexagram,
    required super.changedHexagram,
    required super.latestAnalysisRevision,
    required this.chart,
    required this.analyses,
  });

  factory CaseDetail.fromJson(Map<String, dynamic> json) => CaseDetail(
    id: json['id'] as String,
    title: json['title'] as String,
    question: json['question'] as String,
    castAt: DateTime.parse(json['castAt'] as String),
    castingMethod: json['castingMethod'] as String,
    baseHexagram: json['baseHexagram'] as String,
    changedHexagram: json['changedHexagram'] as String?,
    latestAnalysisRevision: json['latestAnalysisRevision'] as int? ?? 0,
    chart: ChartSnapshot.fromJson(json['chart'] as Map<String, dynamic>),
    analyses: (json['analyses'] as List<dynamic>)
        .map((item) => CaseAnalysis.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
  );

  final ChartSnapshot chart;
  final List<CaseAnalysis> analyses;
}
