import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../ui/liuyao_design.dart';
import '../casting/casting_models.dart';
import 'archive_models.dart';

const _imageWidth = 1080.0;
const _imageMargin = 54.0;
const _imageContentWidth = _imageWidth - _imageMargin * 2;

/// 导出长图版式常量（2026-09-01 需求：删除左上角卦名行后整体放大字号）。
/// 行高、列位与字号联动，调整时需同步 measure()/paint() 两处。
///
/// 爻位标注行：与 App 卦面同规格「纳音·十二长生 / 五星·宿」两行小字，
/// 超宽整体等比缩放（等价 FittedBox.scaleDown），不做省略号截断——
/// 2026-09-01 用户反馈：字放大后十二长生等信息被省略号吃掉，不可接受。
typedef _AnnotSeg = (String, Color?, bool);

const _headerHeight = 84.0;
const _infoCardHeight = 176.0;
const _chartPillarZone = 292.0;
const _chartHeaderZone = 68.0;
const _lineRowHeight = 140.0;
const _chartCardHeight =
    _chartPillarZone + _chartHeaderZone + 6 * _lineRowHeight;

/// 长图导出的内容选项（2026-09-04 需求）：
/// - [includeAnalysis]/[includeFeedback] 关闭时整个区块不绘制（只分享卦本身）；
/// - [includeAnalysisHistory] 为 false 时解读区只画最新一个版本。
class ArchiveImageOptions {
  const ArchiveImageOptions({
    this.includeAnalysis = true,
    this.includeFeedback = true,
    this.includeAnalysisHistory = true,
  });

  final bool includeAnalysis;
  final bool includeFeedback;
  final bool includeAnalysisHistory;
}

Future<Uint8List> buildCaseArchivePng(
  BuildContext context,
  CaseDetail detail, {
  ArchiveImageOptions options = const ArchiveImageOptions(),
}) async {
  final layout = _ArchiveImageLayout(detail, options);
  final height = layout.measure();
  if (height > 30000) {
    throw const FormatException('解读与反馈内容过长，无法生成单张图片；请改用 Markdown 导出');
  }
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  layout.paint(canvas, height);
  final picture = recorder.endRecording();
  final image = await picture.toImage(_imageWidth.round(), height.ceil());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  if (data == null) throw StateError('图片编码失败');
  return data.buffer.asUint8List();
}

class _ArchiveImageLayout {
  _ArchiveImageLayout(this.detail, this.options);

  final CaseDetail detail;
  final ArchiveImageOptions options;
  final List<_MeasuredBlock> _analysisBlocks = [];
  final List<_MeasuredBlock> _feedbackBlocks = [];

  double measure() {
    _analysisBlocks.clear();
    _feedbackBlocks.clear();
    // includeAnalysisHistory=false 时只保留追加列表最后一项（最新版本；
    // 中间被删除的版本留洞不影响「最后一项=最新」）。
    final visibleAnalyses = options.includeAnalysisHistory
        ? detail.analyses
        : detail.analyses.isEmpty
        ? detail.analyses
        : detail.analyses.sublist(detail.analyses.length - 1);
    if (options.includeAnalysis) {
      for (final analysis in visibleAnalyses) {
        _analysisBlocks.add(
          _MeasuredBlock(
            heading:
                '版本 ${analysis.revision} · ${_dateTime(analysis.createdAt)}',
            body: analysis.body,
            badge: false,
          )..measure(_imageContentWidth - 56),
        );
      }
    }
    if (options.includeFeedback) {
      for (final feedback in detail.feedbacks) {
        _feedbackBlocks.add(
          _MeasuredBlock(
            heading:
                '${_feedbackStatus(feedback.status)} · ${_dateTime(feedback.occurredAt ?? feedback.createdAt)}',
            body: feedback.body,
            badge: true,
          )..measure(_imageContentWidth - 56),
        );
      }
    }
    final analysesHeight = _sectionBodyHeight(_analysisBlocks);
    final feedbackHeight = _sectionBodyHeight(_feedbackBlocks);
    // 2026-09-01 需求：左上角卦名与「卦档案」印章全部移除——头部只在
    // 用户自定义过标题（≠本卦名）时保留一行，其余情况不占空间。
    final headerZone = _hasCustomTitle ? _headerHeight + 28 : 0;
    return 54 +
        headerZone +
        _infoCardHeight +
        28 +
        _chartCardHeight +
        (options.includeAnalysis ? 34 + 64 + analysesHeight : 0) +
        (options.includeFeedback ? 34 + 64 + feedbackHeight : 0) +
        96;
  }

  double _sectionBodyHeight(List<_MeasuredBlock> blocks) {
    if (blocks.isEmpty) return 96;
    return 34 + blocks.fold<double>(0, (sum, item) => sum + item.height + 30);
  }

  void paint(Canvas canvas, double height) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, _imageWidth, height),
      Paint()..color = LiuyaoColors.paper,
    );
    _paintCornerLattice(canvas, height);
    var y = 54.0;
    if (_hasCustomTitle) {
      _paintHeader(canvas, y);
      y += _headerHeight + 28;
    }
    _paperCard(canvas, y, _infoCardHeight);
    _text(
      canvas,
      '占问：${detail.question}',
      Offset(_imageMargin + 28, y + 26),
      maxWidth: _imageContentWidth - 56,
      size: 40,
      weight: FontWeight.w400,
      color: LiuyaoColors.ink,
      maxLines: 2,
    );
    _text(
      canvas,
      '起卦：${_dateTime(detail.castAt)} · ${_castingMethodLabel(detail.castingMethod)}',
      Offset(_imageMargin + 28, y + 130),
      maxWidth: _imageContentWidth - 56,
      size: 28,
      color: LiuyaoColors.inkMuted,
    );
    y += _infoCardHeight + 28;
    y = _paintChart(canvas, y);
    if (options.includeAnalysis) {
      y += 34;
      y = _paintRecordSection(canvas, y, '解读信息', _analysisBlocks, '尚未填写解读');
    }
    if (options.includeFeedback) {
      y += 34;
      y = _paintRecordSection(canvas, y, '反馈信息', _feedbackBlocks, '尚未填写反馈');
    }
    _text(
      canvas,
      '— 卦面与记录来自本机档案 · 仅供整理与复盘 —',
      Offset(_imageMargin, y + 40),
      maxWidth: _imageContentWidth,
      size: 26,
      color: LiuyaoColors.inkMuted,
      align: TextAlign.center,
    );
  }

  /// 头部仅保留用户自定义标题行；默认标题（=本卦名）与「卦档案」印章
  /// 均不绘制（2026-09-01 用户要求移除左上角元素）。
  bool get _hasCustomTitle => detail.title.trim() != detail.baseHexagram;

  void _paintHeader(Canvas canvas, double y) {
    _text(
      canvas,
      detail.title,
      Offset(_imageMargin, y + 4),
      maxWidth: _imageContentWidth,
      size: 56,
      weight: FontWeight.w400,
      color: LiuyaoColors.ink,
      maxLines: 1,
    );
  }

  double _paintChart(Canvas canvas, double y) {
    final preview = detail.chart;
    final base = preview.chart.base;
    final changed = preview.chart.changed;
    const cardHeight = _chartCardHeight;
    _paperCard(canvas, y, cardHeight);
    final pillars = [
      ('年柱', preview.yearPillar, preview.yearVoid),
      ('月柱', preview.monthPillar, preview.monthVoid),
      ('日柱', preview.dayPillar, preview.dayVoid),
      ('时柱', preview.hourPillar, preview.hourVoid),
    ];
    final pillarWidth = _imageContentWidth / 4;
    for (var index = 0; index < pillars.length; index++) {
      final item = pillars[index];
      final x = _imageMargin + pillarWidth * index;
      _ganZhiText(
        canvas,
        '',
        item.$2,
        Offset(x, y + 28),
        size: 44,
        maxWidth: pillarWidth,
        align: TextAlign.center,
        weight: FontWeight.w400,
      );
      _text(
        canvas,
        '${item.$3}空',
        Offset(x, y + 92),
        maxWidth: pillarWidth,
        size: 26,
        color: LiuyaoColors.inkMuted,
        align: TextAlign.center,
      );
    }
    _text(
      canvas,
      '本卦',
      Offset(_imageMargin + 88, y + 140),
      maxWidth: 400,
      size: 28,
      color: LiuyaoColors.inkMuted,
      align: TextAlign.center,
    );
    _text(
      canvas,
      base.name,
      Offset(_imageMargin + 88, y + 174),
      maxWidth: 400,
      size: 54,
      weight: FontWeight.w400,
      color: LiuyaoColors.ink,
      align: TextAlign.center,
    );
    _text(
      canvas,
      '/ ${base.palace.name}宫·${base.palaceSequence}',
      Offset(_imageMargin + 88, y + 246),
      maxWidth: 400,
      size: 27,
      color: LiuyaoColors.cinnabar,
      align: TextAlign.center,
    );
    _text(
      canvas,
      '变卦',
      Offset(_imageMargin + 520, y + 140),
      maxWidth: 400,
      size: 28,
      color: LiuyaoColors.inkMuted,
      align: TextAlign.center,
    );
    _text(
      canvas,
      changed?.name ?? '静卦',
      Offset(_imageMargin + 520, y + 174),
      maxWidth: 400,
      size: 54,
      weight: FontWeight.w400,
      color: LiuyaoColors.ink,
      align: TextAlign.center,
    );
    _text(
      canvas,
      changed == null
          ? '/ 无变卦'
          : '/ ${changed.palace.name}宫·${changed.palaceSequence}',
      Offset(_imageMargin + 520, y + 246),
      maxWidth: 400,
      size: 27,
      color: LiuyaoColors.inkMuted,
      align: TextAlign.center,
    );

    final headerY = y + _chartPillarZone;
    canvas.drawLine(
      Offset(_imageMargin + 24, headerY + 54),
      Offset(_imageWidth - _imageMargin - 24, headerY + 54),
      Paint()
        ..color = LiuyaoColors.inkMuted
        ..strokeWidth = 1,
    );
    const headers = [
      ('六神', 24.0, 100.0),
      ('伏神', 142.0, 164.0),
      ('本卦', 318.0, 164.0),
      ('爻·世应', 498.0, 160.0),
      ('变卦', 662.0, 148.0),
      ('爻', 818.0, 100.0),
    ];
    for (final item in headers) {
      _text(
        canvas,
        item.$1,
        Offset(_imageMargin + item.$2, headerY + 10),
        maxWidth: item.$3,
        size: 25,
        weight: FontWeight.w400,
        color: LiuyaoColors.inkMuted,
        align: TextAlign.center,
      );
    }
    final baseLines = [...base.lines]
      ..sort((a, b) => b.position.compareTo(a.position));
    final changedByPosition = {
      for (final line in changed?.lines ?? const <ChangedChartLine>[])
        line.position: line,
    };
    var rowY = headerY + _chartHeaderZone;
    for (final line in baseLines) {
      _paintLineRow(canvas, rowY, line, changedByPosition[line.position]);
      rowY += _lineRowHeight;
    }
    return y + cardHeight;
  }

  void _paintLineRow(
    Canvas canvas,
    double y,
    BaseChartLine line,
    ChangedChartLine? changed,
  ) {
    if (line.changing) {
      canvas.drawRect(
        Rect.fromLTWH(
          _imageMargin + 12,
          y,
          _imageContentWidth - 24,
          _lineRowHeight,
        ),
        Paint()..color = LiuyaoColors.cinnabar.withValues(alpha: .045),
      );
    }
    canvas.drawLine(
      Offset(_imageMargin + 24, y + _lineRowHeight - 1),
      Offset(_imageWidth - _imageMargin - 24, y + _lineRowHeight - 1),
      Paint()
        ..color = LiuyaoColors.inkFaint
        ..strokeWidth = line.position == 4 ? 3 : 1,
    );
    _primarySecondary(
      canvas,
      line.sixGod,
      line.positionName.replaceAll('爻', ''),
      Offset(_imageMargin + 24, y + 26),
      100,
      LiuyaoColors.ink,
    );
    final hidden = line.hidden;
    _ganZhiSecondary(
      canvas,
      relation: hidden?.relation ?? '',
      ganZhi: hidden?.najia.ganZhi ?? '',
      annotationLines: hidden == null
          ? const []
          : _layerAnnotationLines('hidden', line.position, hidden.najia.nayin),
      offset: Offset(_imageMargin + 142, y + 26),
      width: 164,
    );
    _ganZhiSecondary(
      canvas,
      relation: line.relation,
      ganZhi: line.najia.ganZhi,
      annotationLines: _layerAnnotationLines(
        'base',
        line.position,
        line.najia.nayin,
      ),
      offset: Offset(_imageMargin + 318, y + 26),
      width: 164,
    );
    _drawLineGlyph(canvas, Offset(_imageMargin + 498, y + 44), line.yinYang);
    if (line.changing) {
      _text(
        canvas,
        line.value == 9 ? 'Ｏ' : 'Χ',
        Offset(_imageMargin + 604, y + 30),
        maxWidth: 50,
        size: 38,
        weight: FontWeight.w400,
        color: LiuyaoColors.cinnabar,
        align: TextAlign.center,
      );
    }
    if (line.role != null) {
      _text(
        canvas,
        line.role!,
        Offset(_imageMargin + 498, y + 98),
        maxWidth: 100,
        size: 28,
        weight: FontWeight.w400,
        color: LiuyaoColors.cinnabar,
        align: TextAlign.center,
      );
    }
    _ganZhiSecondary(
      canvas,
      relation: changed?.relation ?? '',
      ganZhi: changed?.najia.ganZhi ?? '',
      annotationLines: changed == null
          ? const []
          : _layerAnnotationLines(
              'changed',
              line.position,
              changed.najia.nayin,
            ),
      offset: Offset(_imageMargin + 662, y + 26),
      width: 148,
    );
    if (changed != null) {
      _drawLineGlyph(
        canvas,
        Offset(_imageMargin + 818, y + 44),
        changed.yinYang,
      );
      if (changed.role != null) {
        _text(
          canvas,
          changed.role!,
          Offset(_imageMargin + 818, y + 98),
          maxWidth: 100,
          size: 28,
          weight: FontWeight.w400,
          color: LiuyaoColors.cinnabar,
          align: TextAlign.center,
        );
      }
    }
  }

  /// 爻位标注两行（与 App 卦面同规格）：
  /// 行1「纳音·十二长生」、行2「五星·宿」。缺失片段整段省略，
  /// 宿名不带「宿」字（与 App 内 2026-08 需求一致）。
  List<List<_AnnotSeg>> _layerAnnotationLines(
    String layer,
    int position,
    String? nayin,
  ) {
    final annotations = detail.chart.annotations;
    final layerAnnotations = switch (layer) {
      'hidden' => annotations.hiddenHexagramAnnotations,
      'changed' => annotations.changedHexagramAnnotations,
      _ => null,
    };
    final stages = layer == 'base'
        ? annotations.fiveElementTwelveStages
        : layerAnnotations?.fiveElementTwelveStages;
    final mansion = layer == 'base'
        ? annotations.twentyEightMansions?.placementAt(position)
        : layerAnnotations?.twentyEightMansions.placementAt(position);
    final fiveStar = layer == 'base'
        ? annotations.fiveStars?.placementAt(position)
        : layerAnnotations?.fiveStars?.placementAt(position);
    String? dayStage;
    for (final line in stages?.lineResults ?? const <TwelveStageLineResult>[]) {
      if (line.position != position) continue;
      for (final pillar in line.pillarResults) {
        if (pillar.reference == 'day') {
          dayStage = pillar.stage;
          break;
        }
      }
    }
    final lineOne = <_AnnotSeg>[
      if (nayin != null && nayin.isNotEmpty)
        (nayin, _nayinElementColor(nayin), false),
      if (dayStage != null && dayStage.isNotEmpty)
        (dayStage, LiuyaoColors.ink, true),
    ];
    final placement = fiveStar;
    final lineTwo = <_AnnotSeg>[
      if (placement != null)
        (
          _fiveStarLabel(placement.star),
          _elementColor(placement.element),
          true,
        ),
      if (mansion != null) (mansion.mansion, LiuyaoColors.ink, true),
    ];
    return [lineOne, lineTwo];
  }

  void _primarySecondary(
    Canvas canvas,
    String primary,
    String secondary,
    Offset offset,
    double width,
    Color color,
  ) {
    _text(
      canvas,
      primary,
      offset,
      maxWidth: width,
      size: 36,
      weight: FontWeight.w400,
      color: color,
      maxLines: 1,
    );
    if (secondary.isNotEmpty) {
      _text(
        canvas,
        secondary,
        Offset(offset.dx, offset.dy + 46),
        maxWidth: width,
        size: 24,
        color: LiuyaoColors.inkMuted,
        maxLines: 1,
      );
    }
  }

  /// 干支分色列：六亲墨色、干支各按五行着色；缺层画「—」占位。
  /// 下方标注两行（纳音·长生 / 五星·宿），超宽整体等比缩放不截断。
  void _ganZhiSecondary(
    Canvas canvas, {
    required String relation,
    required String ganZhi,
    required List<List<_AnnotSeg>> annotationLines,
    required Offset offset,
    required double width,
  }) {
    if (ganZhi.isEmpty) {
      _text(
        canvas,
        '—',
        offset,
        maxWidth: width,
        size: 36,
        weight: FontWeight.w400,
        color: LiuyaoColors.inkFaint,
        maxLines: 1,
      );
    } else {
      _ganZhiText(canvas, relation, ganZhi, offset, size: 36, maxWidth: width);
    }
    var lineY = offset.dy + 46;
    for (final line in annotationLines) {
      if (line.isNotEmpty) {
        _segmentsText(canvas, line, Offset(offset.dx, lineY), width, 22);
        lineY += 30;
      }
    }
  }

  void _drawLineGlyph(Canvas canvas, Offset offset, String yinYang) {
    final paint = Paint()
      ..color = LiuyaoColors.ink
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;
    if (yinYang == '阳' || yinYang == 'yang') {
      canvas.drawLine(offset, Offset(offset.dx + 100, offset.dy), paint);
    } else {
      canvas.drawLine(offset, Offset(offset.dx + 38, offset.dy), paint);
      canvas.drawLine(
        Offset(offset.dx + 58, offset.dy),
        Offset(offset.dx + 100, offset.dy),
        paint,
      );
    }
  }

  double _paintRecordSection(
    Canvas canvas,
    double y,
    String title,
    List<_MeasuredBlock> blocks,
    String emptyText,
  ) {
    canvas.drawRect(
      Rect.fromLTWH(_imageMargin, y + 6, 8, 48),
      Paint()..color = LiuyaoColors.cinnabar,
    );
    _text(
      canvas,
      title,
      Offset(_imageMargin + 24, y),
      maxWidth: 400,
      size: 44,
      weight: FontWeight.w400,
      color: LiuyaoColors.ink,
    );
    _text(
      canvas,
      '${blocks.length} 条',
      Offset(_imageWidth - _imageMargin - 180, y + 10),
      maxWidth: 180,
      size: 28,
      color: LiuyaoColors.inkMuted,
      align: TextAlign.right,
    );
    y += 64;
    final cardHeight = _sectionBodyHeight(blocks);
    _paperCard(canvas, y, cardHeight);
    if (blocks.isEmpty) {
      _text(
        canvas,
        emptyText,
        Offset(_imageMargin + 28, y + 30),
        maxWidth: _imageContentWidth - 56,
        size: 32,
        color: LiuyaoColors.inkMuted,
      );
      return y + cardHeight;
    }
    var blockY = y + 26;
    for (var index = 0; index < blocks.length; index++) {
      final block = blocks[index];
      block.paint(canvas, Offset(_imageMargin + 28, blockY));
      blockY += block.height + 30;
      if (index != blocks.length - 1) {
        canvas.drawLine(
          Offset(_imageMargin + 28, blockY - 15),
          Offset(_imageWidth - _imageMargin - 28, blockY - 15),
          Paint()
            ..color = LiuyaoColors.inkFaint
            ..strokeWidth = 1,
        );
      }
    }
    return y + cardHeight;
  }

  void _paperCard(Canvas canvas, double y, double height) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(_imageMargin, y, _imageContentWidth, height),
      const Radius.circular(12),
    );
    canvas.drawRRect(rect, Paint()..color = LiuyaoColors.paperRaised);
    canvas.drawRRect(
      rect,
      Paint()
        ..color = LiuyaoColors.inkFaint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _paintCornerLattice(Canvas canvas, double height) {
    final paint = Paint()
      ..color = LiuyaoColors.inkMedium.withValues(alpha: .07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var index = 0; index < 4; index++) {
      final inset = index * 20.0;
      canvas.drawRect(
        Rect.fromLTWH(inset, inset, 180 - inset, 180 - inset),
        paint,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          _imageWidth - 180,
          height - 180,
          180 - inset,
          180 - inset,
        ).shift(Offset(inset, inset)),
        paint,
      );
    }
  }
}

class _MeasuredBlock {
  _MeasuredBlock({
    required this.heading,
    required this.body,
    required this.badge,
  });

  final String heading;
  final String body;
  final bool badge;
  late TextPainter headingPainter;
  late TextPainter bodyPainter;
  double height = 0;

  void measure(double width) {
    headingPainter = _painter(
      heading,
      size: 28,
      weight: FontWeight.w400,
      color: badge ? LiuyaoColors.cinnabar : LiuyaoColors.water,
      maxWidth: width,
    );
    bodyPainter = _painter(
      body,
      size: 34,
      color: LiuyaoColors.inkMedium,
      height: 1.5,
      maxWidth: width,
    );
    height = headingPainter.height + 14 + bodyPainter.height;
  }

  void paint(Canvas canvas, Offset offset) {
    headingPainter.paint(canvas, offset);
    bodyPainter.paint(
      canvas,
      Offset(offset.dx, offset.dy + headingPainter.height + 14),
    );
  }
}

TextPainter _painter(
  String value, {
  required double size,
  required Color color,
  required double maxWidth,
  FontWeight weight = FontWeight.w400,
  double height = 1.2,
  TextAlign align = TextAlign.left,
  int? maxLines,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: value,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: weight,
        height: height,
        fontFamily: 'DaoyuSong',
        // 系统链仅兜底：子集外生僻字（问念人名等）回退无衬线。
        fontFamilyFallback: const [
          'PingFang SC',
          'Noto Sans CJK SC',
          'Noto Sans SC',
        ],
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: align,
    maxLines: maxLines,
    ellipsis: maxLines == null ? null : '…',
  )..layout(maxWidth: maxWidth);
  return painter;
}

void _text(
  Canvas canvas,
  String value,
  Offset offset, {
  required double maxWidth,
  required double size,
  required Color color,
  FontWeight weight = FontWeight.w400,
  double height = 1.2,
  TextAlign align = TextAlign.left,
  int? maxLines,
}) {
  final painter = _painter(
    value,
    size: size,
    color: color,
    maxWidth: maxWidth,
    weight: weight,
    height: height,
    align: align,
    maxLines: maxLines,
  );
  // TextPainter.paint 总以 offset 为左上角，textAlign 只作用于多行内部行对齐；
  // 单行元素的居中/居右必须手动平移，否则印章字、四柱、世应会整体左歪。
  var dx = offset.dx;
  if (align == TextAlign.center) {
    dx += (maxWidth - painter.width) / 2;
  } else if (align == TextAlign.right) {
    dx += maxWidth - painter.width;
  }
  painter.paint(canvas, Offset(dx, offset.dy));
}

Color _elementColor(String element) => switch (element) {
  '木' => LiuyaoColors.wood,
  '火' => LiuyaoColors.fire,
  '土' => LiuyaoColors.earth,
  '金' => LiuyaoColors.metal,
  '水' => LiuyaoColors.water,
  _ => LiuyaoColors.ink,
};

/// 纳音五行色：纳音名末字即五行（海中金→金、炉中火→火…）。
Color _nayinElementColor(String nayin) {
  if (nayin.isEmpty) return LiuyaoColors.inkMuted;
  return _elementColor(nayin.substring(nayin.length - 1));
}

/// 京房五星短名（与 App 卦面同一口径）：镇土→镇、岁木→岁，余原样。
String _fiveStarLabel(String star) => switch (star) {
  '镇土' => '镇',
  '岁木' => '岁',
  _ => star,
};

/// 多段着色标注行：段间自动插「·」分隔；整行超宽时等比缩放（等价
/// FittedBox.scaleDown），保证纳音·长生·五星·宿信息完整不被截断。
void _segmentsText(
  Canvas canvas,
  List<_AnnotSeg> segments,
  Offset offset,
  double maxWidth,
  double size,
) {
  if (segments.isEmpty) return;
  final base = TextStyle(
    fontSize: size,
    height: 1.2,
    fontFamily: 'DaoyuSong',
    // 系统链仅兜底：子集外生僻字（问念人名等）回退无衬线。
    fontFamilyFallback: const [
      'PingFang SC',
      'Noto Sans CJK SC',
      'Noto Sans SC',
    ],
  );
  final spans = <TextSpan>[];
  for (var index = 0; index < segments.length; index++) {
    if (index > 0) {
      spans.add(
        TextSpan(
          text: '·',
          style: base.copyWith(color: LiuyaoColors.inkMuted),
        ),
      );
    }
    final seg = segments[index];
    spans.add(
      TextSpan(
        text: seg.$1,
        style: base.copyWith(
          color: seg.$2 ?? LiuyaoColors.inkMuted,
          fontWeight: FontWeight.w400, // 道谕宋单字重，不加粗
        ),
      ),
    );
  }
  final painter = TextPainter(
    text: TextSpan(children: spans),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  if (painter.width <= maxWidth) {
    painter.paint(canvas, offset);
    return;
  }
  final scale = maxWidth / painter.width;
  canvas.save();
  canvas.translate(offset.dx, offset.dy);
  canvas.scale(scale, scale);
  painter.paint(canvas, Offset.zero);
  canvas.restore();
}

Color _ganZhiColor(String value) {
  if (value.isEmpty) return LiuyaoColors.ink;
  const stemElements = {
    '甲': '木',
    '乙': '木',
    '丙': '火',
    '丁': '火',
    '戊': '土',
    '己': '土',
    '庚': '金',
    '辛': '金',
    '壬': '水',
    '癸': '水',
  };
  return _elementColor(stemElements[value.substring(0, 1)] ?? '');
}

Color _branchColor(String value) {
  if (value.isEmpty) return LiuyaoColors.ink;
  const branchElements = {
    '子': '水',
    '亥': '水',
    '寅': '木',
    '卯': '木',
    '巳': '火',
    '午': '火',
    '申': '金',
    '酉': '金',
    '辰': '土',
    '戌': '土',
    '丑': '土',
    '未': '土',
  };
  return _elementColor(branchElements[value.substring(0, 1)] ?? '');
}

/// 干支分色文本：颜色用于识别天干、地支五行——
/// 六亲墨色、天干按干五行、地支按支五行（与 App 内卦面同一契约）。
TextPainter _ganZhiPainter(
  String relation,
  String ganZhi, {
  required double size,
  required double maxWidth,
  FontWeight weight = FontWeight.w400,
}) {
  final base = TextStyle(
    fontSize: size,
    fontWeight: weight,
    height: 1.2,
    fontFamily: 'DaoyuSong',
    // 系统链仅兜底：子集外生僻字（问念人名等）回退无衬线。
    fontFamilyFallback: const [
      'PingFang SC',
      'Noto Sans CJK SC',
      'Noto Sans SC',
    ],
  );
  final spans = <TextSpan>[];
  if (relation.isNotEmpty) {
    spans.add(
      TextSpan(
        text: relation,
        style: base.copyWith(color: LiuyaoColors.ink),
      ),
    );
  }
  if (ganZhi.length >= 2) {
    spans.add(
      TextSpan(
        text: ganZhi.substring(0, 1),
        style: base.copyWith(color: _ganZhiColor(ganZhi.substring(0, 1))),
      ),
    );
    spans.add(
      TextSpan(
        text: ganZhi.substring(1),
        style: base.copyWith(color: _branchColor(ganZhi.substring(1, 2))),
      ),
    );
  } else if (ganZhi.isNotEmpty) {
    spans.add(
      TextSpan(
        text: ganZhi,
        style: base.copyWith(color: _ganZhiColor(ganZhi)),
      ),
    );
  }
  final painter = TextPainter(
    text: TextSpan(children: spans),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth);
  return painter;
}

void _ganZhiText(
  Canvas canvas,
  String relation,
  String ganZhi,
  Offset offset, {
  required double size,
  required double maxWidth,
  TextAlign align = TextAlign.left,
  FontWeight weight = FontWeight.w400,
}) {
  final painter = _ganZhiPainter(
    relation,
    ganZhi,
    size: size,
    maxWidth: maxWidth,
    weight: weight,
  );
  var dx = offset.dx;
  if (align == TextAlign.center) {
    dx += (maxWidth - painter.width) / 2;
  } else if (align == TextAlign.right) {
    dx += maxWidth - painter.width;
  }
  painter.paint(canvas, Offset(dx, offset.dy));
}

String _dateTime(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} '
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

/// 起卦方式标签：引擎 method 取值 manual / three_coins / time_pillar。
String _castingMethodLabel(String method) => switch (method) {
  'manual' => '手动起卦',
  'time_pillar' => '时刻起卦',
  _ => '自动铜钱',
};

String _feedbackStatus(String value) => switch (value) {
  'matched' || 'verified' => '已应验',
  'partial' => '部分应验',
  'unmatched' || 'unverified' => '未应验',
  _ => '待验证',
};
