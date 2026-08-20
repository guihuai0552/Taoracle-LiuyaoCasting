import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../ui/liuyao_design.dart';
import '../casting/casting_models.dart';
import 'archive_models.dart';

const _imageWidth = 1080.0;
const _imageMargin = 54.0;
const _imageContentWidth = _imageWidth - _imageMargin * 2;

Future<Uint8List> buildCaseArchivePng(
  BuildContext context,
  CaseDetail detail,
) async {
  final layout = _ArchiveImageLayout(detail);
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
  _ArchiveImageLayout(this.detail);

  final CaseDetail detail;
  final List<_MeasuredBlock> _analysisBlocks = [];
  final List<_MeasuredBlock> _feedbackBlocks = [];

  double measure() {
    _analysisBlocks.clear();
    _feedbackBlocks.clear();
    for (final analysis in detail.analyses) {
      _analysisBlocks.add(
        _MeasuredBlock(
          heading: '版本 ${analysis.revision} · ${_dateTime(analysis.createdAt)}',
          body: analysis.body,
          badge: false,
        )..measure(_imageContentWidth - 56),
      );
    }
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
    final analysesHeight = _sectionBodyHeight(_analysisBlocks);
    final feedbackHeight = _sectionBodyHeight(_feedbackBlocks);
    return 54 +
        150 +
        28 +
        154 +
        28 +
        225 +
        72 +
        6 * 126 +
        34 +
        58 +
        analysesHeight +
        34 +
        58 +
        feedbackHeight +
        92;
  }

  double _sectionBodyHeight(List<_MeasuredBlock> blocks) {
    if (blocks.isEmpty) return 86;
    return 34 + blocks.fold<double>(0, (sum, item) => sum + item.height + 26);
  }

  void paint(Canvas canvas, double height) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, _imageWidth, height),
      Paint()..color = LiuyaoColors.paper,
    );
    _paintCornerLattice(canvas, height);
    var y = 54.0;
    _paintHeader(canvas, y);
    y += 178;
    _paperCard(canvas, y, 154);
    _text(
      canvas,
      '占问：${detail.question}',
      Offset(_imageMargin + 28, y + 25),
      maxWidth: _imageContentWidth - 56,
      size: 34,
      weight: FontWeight.w700,
      color: LiuyaoColors.ink,
      maxLines: 2,
    );
    _text(
      canvas,
      '起卦：${_dateTime(detail.castAt)} · ${detail.castingMethod == 'manual' ? '手动起卦' : '自动铜钱'}',
      Offset(_imageMargin + 28, y + 103),
      maxWidth: _imageContentWidth - 56,
      size: 24,
      color: LiuyaoColors.inkMuted,
    );
    y += 182;
    y = _paintChart(canvas, y);
    y += 34;
    y = _paintRecordSection(canvas, y, '解读信息', _analysisBlocks, '尚未填写解读');
    y += 34;
    y = _paintRecordSection(canvas, y, '反馈信息', _feedbackBlocks, '尚未填写反馈');
    _text(
      canvas,
      '— 卦面与记录来自本机档案 · 仅供整理与复盘 —',
      Offset(_imageMargin, y + 36),
      maxWidth: _imageContentWidth,
      size: 22,
      color: LiuyaoColors.inkMuted,
      align: TextAlign.center,
    );
  }

  void _paintHeader(Canvas canvas, double y) {
    final seal = RRect.fromRectAndRadius(
      Rect.fromLTWH(_imageMargin, y, 112, 112),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      seal,
      Paint()
        ..color = LiuyaoColors.cinnabar
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    canvas.drawRect(
      Rect.fromLTWH(_imageMargin + 14, y + 14, 84, 84),
      Paint()
        ..color = LiuyaoColors.cinnabar.withValues(alpha: .65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    _text(
      canvas,
      '卦',
      Offset(_imageMargin, y + 15),
      maxWidth: 112,
      size: 46,
      weight: FontWeight.w800,
      color: LiuyaoColors.cinnabar,
      align: TextAlign.center,
    );
    _text(
      canvas,
      '档案',
      Offset(_imageMargin, y + 78),
      maxWidth: 112,
      size: 20,
      weight: FontWeight.w700,
      color: LiuyaoColors.inkMuted,
      align: TextAlign.center,
    );
    _text(
      canvas,
      detail.title,
      Offset(_imageMargin + 142, y + 8),
      maxWidth: _imageContentWidth - 142,
      size: 52,
      weight: FontWeight.w800,
      color: LiuyaoColors.ink,
      maxLines: 1,
    );
    _text(
      canvas,
      '${detail.baseHexagram}${detail.changedHexagram == null ? ' · 静卦' : ' → ${detail.changedHexagram}'}',
      Offset(_imageMargin + 142, y + 78),
      maxWidth: _imageContentWidth - 142,
      size: 27,
      weight: FontWeight.w700,
      color: LiuyaoColors.cinnabar,
    );
  }

  double _paintChart(Canvas canvas, double y) {
    final preview = detail.chart;
    final base = preview.chart.base;
    final changed = preview.chart.changed;
    const cardHeight = 225.0 + 72.0 + 6 * 126.0;
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
      _text(
        canvas,
        item.$2,
        Offset(x, y + 25),
        maxWidth: pillarWidth,
        size: 36,
        weight: FontWeight.w800,
        color: _ganZhiColor(item.$2),
        align: TextAlign.center,
      );
      _text(
        canvas,
        '${item.$3}空',
        Offset(x, y + 75),
        maxWidth: pillarWidth,
        size: 22,
        color: LiuyaoColors.inkMuted,
        align: TextAlign.center,
      );
    }
    _text(
      canvas,
      '本卦',
      Offset(_imageMargin + 88, y + 126),
      maxWidth: 350,
      size: 23,
      color: LiuyaoColors.inkMuted,
      align: TextAlign.center,
    );
    _text(
      canvas,
      base.name,
      Offset(_imageMargin + 88, y + 158),
      maxWidth: 350,
      size: 43,
      weight: FontWeight.w800,
      color: LiuyaoColors.ink,
      align: TextAlign.center,
    );
    _text(
      canvas,
      '/ ${base.palace.name}宫·${base.palaceSequence}',
      Offset(_imageMargin + 88, y + 207),
      maxWidth: 350,
      size: 22,
      color: LiuyaoColors.cinnabar,
      align: TextAlign.center,
    );
    _text(
      canvas,
      '变卦',
      Offset(_imageMargin + 534, y + 126),
      maxWidth: 350,
      size: 23,
      color: LiuyaoColors.inkMuted,
      align: TextAlign.center,
    );
    _text(
      canvas,
      changed?.name ?? '静卦',
      Offset(_imageMargin + 534, y + 158),
      maxWidth: 350,
      size: 43,
      weight: FontWeight.w800,
      color: LiuyaoColors.ink,
      align: TextAlign.center,
    );
    _text(
      canvas,
      changed == null
          ? '/ 无变卦'
          : '/ ${changed.palace.name}宫·${changed.palaceSequence}',
      Offset(_imageMargin + 534, y + 207),
      maxWidth: 350,
      size: 22,
      color: LiuyaoColors.inkMuted,
      align: TextAlign.center,
    );

    final headerY = y + 258;
    canvas.drawLine(
      Offset(_imageMargin + 24, headerY + 48),
      Offset(_imageWidth - _imageMargin - 24, headerY + 48),
      Paint()
        ..color = LiuyaoColors.inkMuted
        ..strokeWidth = 1,
    );
    const headers = [
      ('六神', 35.0, 100.0),
      ('伏神', 142.0, 180.0),
      ('本卦', 324.0, 190.0),
      ('爻·世应', 520.0, 170.0),
      ('变卦', 710.0, 170.0),
      ('爻', 894.0, 60.0),
    ];
    for (final item in headers) {
      _text(
        canvas,
        item.$1,
        Offset(_imageMargin + item.$2, headerY + 8),
        maxWidth: item.$3,
        size: 20,
        weight: FontWeight.w700,
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
    var rowY = headerY + 60;
    for (final line in baseLines) {
      _paintLineRow(canvas, rowY, line, changedByPosition[line.position]);
      rowY += 126;
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
        Rect.fromLTWH(_imageMargin + 12, y, _imageContentWidth - 24, 126),
        Paint()..color = LiuyaoColors.cinnabar.withValues(alpha: .045),
      );
    }
    canvas.drawLine(
      Offset(_imageMargin + 24, y + 125),
      Offset(_imageWidth - _imageMargin - 24, y + 125),
      Paint()
        ..color = LiuyaoColors.inkFaint
        ..strokeWidth = line.position == 4 ? 3 : 1,
    );
    _primarySecondary(
      canvas,
      line.sixGod,
      line.positionName.replaceAll('爻', ''),
      Offset(_imageMargin + 20, y + 23),
      112,
      LiuyaoColors.ink,
    );
    final hidden = line.hidden;
    _primarySecondary(
      canvas,
      hidden == null ? '—' : '${hidden.relation}${hidden.najia.ganZhi}',
      hidden == null
          ? ''
          : _layerSecondary('hidden', line.position, hidden.najia.nayin),
      Offset(_imageMargin + 136, y + 23),
      190,
      hidden == null
          ? LiuyaoColors.inkFaint
          : _elementColor(hidden.najia.element),
    );
    _primarySecondary(
      canvas,
      '${line.relation}${line.najia.ganZhi}',
      _layerSecondary('base', line.position, line.najia.nayin),
      Offset(_imageMargin + 330, y + 23),
      190,
      _elementColor(line.najia.element),
    );
    _drawLineGlyph(canvas, Offset(_imageMargin + 535, y + 38), line.yinYang);
    if (line.changing) {
      _text(
        canvas,
        line.value == 9 ? 'Ｏ' : 'Χ',
        Offset(_imageMargin + 640, y + 28),
        maxWidth: 48,
        size: 33,
        weight: FontWeight.w800,
        color: LiuyaoColors.cinnabar,
        align: TextAlign.center,
      );
    }
    if (line.role != null) {
      _text(
        canvas,
        line.role!,
        Offset(_imageMargin + 615, y + 80),
        maxWidth: 80,
        size: 23,
        weight: FontWeight.w800,
        color: LiuyaoColors.cinnabar,
        align: TextAlign.center,
      );
    }
    _primarySecondary(
      canvas,
      changed == null ? '—' : '${changed.relation}${changed.najia.ganZhi}',
      changed == null
          ? ''
          : _layerSecondary('changed', line.position, changed.najia.nayin),
      Offset(_imageMargin + 704, y + 23),
      180,
      changed == null
          ? LiuyaoColors.inkFaint
          : _elementColor(changed.najia.element),
    );
    if (changed != null) {
      _drawLineGlyph(
        canvas,
        Offset(_imageMargin + 870, y + 38),
        changed.yinYang,
      );
      if (changed.role != null) {
        _text(
          canvas,
          changed.role!,
          Offset(_imageMargin + 846, y + 80),
          maxWidth: 80,
          size: 23,
          weight: FontWeight.w800,
          color: LiuyaoColors.cinnabar,
          align: TextAlign.center,
        );
      }
    }
  }

  String _layerSecondary(String layer, int position, String? nayin) {
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
    return [
      ?nayin,
      ?dayStage,
      if (mansion != null) '${mansion.mansion}宿',
    ].join('·');
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
      size: 28,
      weight: FontWeight.w700,
      color: color,
      maxLines: 1,
    );
    if (secondary.isNotEmpty) {
      _text(
        canvas,
        secondary,
        Offset(offset.dx, offset.dy + 48),
        maxWidth: width,
        size: 19,
        color: LiuyaoColors.inkMuted,
        maxLines: 1,
      );
    }
  }

  void _drawLineGlyph(Canvas canvas, Offset offset, String yinYang) {
    final paint = Paint()
      ..color = LiuyaoColors.ink
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    if (yinYang == '阳' || yinYang == 'yang') {
      canvas.drawLine(offset, Offset(offset.dx + 92, offset.dy), paint);
    } else {
      canvas.drawLine(offset, Offset(offset.dx + 36, offset.dy), paint);
      canvas.drawLine(
        Offset(offset.dx + 56, offset.dy),
        Offset(offset.dx + 92, offset.dy),
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
      Rect.fromLTWH(_imageMargin, y + 8, 7, 40),
      Paint()..color = LiuyaoColors.cinnabar,
    );
    _text(
      canvas,
      title,
      Offset(_imageMargin + 22, y),
      maxWidth: 400,
      size: 36,
      weight: FontWeight.w800,
      color: LiuyaoColors.ink,
    );
    _text(
      canvas,
      '${blocks.length} 条',
      Offset(_imageWidth - _imageMargin - 160, y + 7),
      maxWidth: 160,
      size: 23,
      color: LiuyaoColors.inkMuted,
      align: TextAlign.right,
    );
    y += 58;
    final cardHeight = _sectionBodyHeight(blocks);
    _paperCard(canvas, y, cardHeight);
    if (blocks.isEmpty) {
      _text(
        canvas,
        emptyText,
        Offset(_imageMargin + 28, y + 27),
        maxWidth: _imageContentWidth - 56,
        size: 26,
        color: LiuyaoColors.inkMuted,
      );
      return y + cardHeight;
    }
    var blockY = y + 24;
    for (var index = 0; index < blocks.length; index++) {
      final block = blocks[index];
      block.paint(canvas, Offset(_imageMargin + 28, blockY));
      blockY += block.height + 26;
      if (index != blocks.length - 1) {
        canvas.drawLine(
          Offset(_imageMargin + 28, blockY - 13),
          Offset(_imageWidth - _imageMargin - 28, blockY - 13),
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
      const Radius.circular(22),
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
      size: 24,
      weight: FontWeight.w700,
      color: badge ? LiuyaoColors.cinnabar : LiuyaoColors.water,
      maxWidth: width,
    );
    bodyPainter = _painter(
      body,
      size: 29,
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
  _painter(
    value,
    size: size,
    color: color,
    maxWidth: maxWidth,
    weight: weight,
    height: height,
    align: align,
    maxLines: maxLines,
  ).paint(canvas, offset);
}

Color _elementColor(String element) => switch (element) {
  '木' => LiuyaoColors.wood,
  '火' => LiuyaoColors.fire,
  '土' => LiuyaoColors.earth,
  '金' => LiuyaoColors.metal,
  '水' => LiuyaoColors.water,
  _ => LiuyaoColors.ink,
};

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

String _dateTime(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} '
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _feedbackStatus(String value) => switch (value) {
  'matched' || 'verified' => '已应验',
  'partial' => '部分应验',
  'unmatched' || 'unverified' => '未应验',
  _ => '待验证',
};
