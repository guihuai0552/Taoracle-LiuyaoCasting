import 'package:flutter/material.dart';

import '../../ui/liuyao_design.dart';
import 'casting_models.dart';

const _ink = LiuyaoColors.ink;
const _mutedInk = LiuyaoColors.inkMuted;
const _cinnabar = LiuyaoColors.cinnabar;
const _paper = LiuyaoColors.paperRaised;
const _softPaper = LiuyaoColors.parchment;
const _rule = LiuyaoColors.inkFaint;
const _mansionInk = LiuyaoColors.metal;
const _mansionPaper = Color(0x24D49A26);

class LiuyaoChartPreview extends StatefulWidget {
  const LiuyaoChartPreview({
    super.key,
    required this.preview,
    this.onSave,
    this.saving = false,
    this.archived = false,
  });

  final CastPreview preview;
  final VoidCallback? onSave;
  final bool saving;
  final bool archived;

  @override
  State<LiuyaoChartPreview> createState() => _LiuyaoChartPreviewState();
}

class _LiuyaoChartPreviewState extends State<LiuyaoChartPreview> {
  String _growthReference = 'day';
  String _annotationMode = 'twelve_growth';
  bool _showLineAnnotations = true;
  bool _showNaYin = true;
  bool _showTwelveGrowth = true;
  bool _showFiveStars = true;
  bool _show28Mansions = true;

  @override
  Widget build(BuildContext context) {
    final preview = widget.preview;
    final onSave = widget.onSave;
    final saving = widget.saving;
    final archived = widget.archived;
    return Column(
      key: const Key('cast-preview-result'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LiuyaoCoreChart(
          preview: preview,
          growthReference: _growthReference,
          annotationMode: _annotationMode,
          onGrowthTap: _openGrowthReferencePicker,
          visibility: LiuyaoLineAnnotationVisibility(
            showNaYin: _showLineAnnotations && _showNaYin,
            showTwelveGrowth: _showLineAnnotations && _showTwelveGrowth,
            showFiveStars: _showLineAnnotations && _showFiveStars,
            show28Mansions: _showLineAnnotations && _show28Mansions,
          ),
        ),
        const SizedBox(height: 12),
        LiuyaoLineAnnotationsToggle(
          showLineAnnotations: _showLineAnnotations,
          onChangedLineAnnotations: (v) =>
              setState(() => _showLineAnnotations = v),
          showNaYin: _showNaYin,
          onChangedNaYin: (v) => setState(() => _showNaYin = v),
          showTwelveGrowth: _showTwelveGrowth,
          onChangedTwelveGrowth: (v) => setState(() => _showTwelveGrowth = v),
          showFiveStars: _showFiveStars,
          onChangedFiveStars: (v) => setState(() => _showFiveStars = v),
          show28Mansions: _show28Mansions,
          onChanged28Mansions: (v) => setState(() => _show28Mansions = v),
        ),
        if (preview.annotations.shenshaResults.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ShenshaAnnotations(preview: preview),
        ],
        if (preview
            .annotations
            .fiveElementTwelveStages
            .lineResults
            .isNotEmpty) ...[
          const SizedBox(height: 12),
          _TwelveStagesLedger(
            preview: preview,
            selectedReference: _growthReference,
            onReferenceChanged: (reference) {
              setState(() => _growthReference = reference);
            },
            annotationMode: _annotationMode,
            onModeChanged: (mode) {
              setState(() => _annotationMode = mode);
            },
          ),
        ],
        if (preview.calculationTrace.isNotEmpty) ...[
          const SizedBox(height: 12),
          _CalculationDetails(preview: preview),
        ],
        if (onSave != null || archived) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('save-cast-to-archive'),
            onPressed: archived || saving ? null : onSave,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: _cinnabar,
            ),
            icon: saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(archived ? Icons.inventory_2 : Icons.archive_outlined),
            label: Text(
              archived
                  ? '已保存于档案'
                  : saving
                  ? '正在保存…'
                  : '保存到档案',
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          preview.isLegacySnapshot
              ? '历史合同 schema v${preview.schemaVersion} · 引擎 ${preview.engineVersion}'
              : '规则 ${preview.rulePackage.id} · v${preview.rulePackage.version} · '
                    'Najia ${preview.rulePackage.upstreamVersion} 兼容基线',
          key: const Key('chart-rule-package'),
          style: const TextStyle(color: _mutedInk, fontSize: 10, height: 1.45),
        ),
        Text(
          archived
              ? '此处展示的是起卦时保存的完整快照，后续规则升级不会改写本档案。'
              : '保存后将原样写入档案；时间边界与传统主来源仍按文档中的临时口径显示。',
          style: TextStyle(color: _mutedInk, fontSize: 10, height: 1.45),
        ),
      ],
    );
  }

  /// 点击卦面爻位标注的十二长生/五星文字时弹出的参照选择器。
  Future<void> _openGrowthReferencePicker() async {
    final choice = await showLiuyaoGrowthReferencePicker(
      context: context,
      currentReference: _growthReference,
      currentMode: _annotationMode,
    );
    if (choice == null || !mounted) return;
    setState(() {
      if (choice.mode == 'five_stars') {
        _annotationMode = 'five_stars';
      } else {
        _annotationMode = 'twelve_growth';
        _growthReference = choice.reference;
      }
    });
  }
}

/// 卦爻标注参照选择的单选项。
class LiuyaoGrowthReferenceChoice {
  const LiuyaoGrowthReferenceChoice({
    required this.label,
    required this.reference,
    required this.mode,
  });

  final String label;
  final String reference;
  final String mode;
}

/// 卦面爻位标注参照选择底部弹窗：年柱/月柱/日柱/时柱/京房五星。
class LiuyaoGrowthReferenceSheet extends StatelessWidget {
  const LiuyaoGrowthReferenceSheet({
    super.key,
    required this.currentReference,
    required this.currentMode,
  });

  final String currentReference;
  final String currentMode;

  static const _choices = [
    LiuyaoGrowthReferenceChoice(
      label: '年柱',
      reference: 'year',
      mode: 'twelve_growth',
    ),
    LiuyaoGrowthReferenceChoice(
      label: '月柱',
      reference: 'month',
      mode: 'twelve_growth',
    ),
    LiuyaoGrowthReferenceChoice(
      label: '日柱',
      reference: 'day',
      mode: 'twelve_growth',
    ),
    LiuyaoGrowthReferenceChoice(
      label: '时柱',
      reference: 'hour',
      mode: 'twelve_growth',
    ),
    LiuyaoGrowthReferenceChoice(
      label: '京房五星',
      reference: 'five_stars',
      mode: 'five_stars',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 6, 20, 4),
            child: Text(
              '卦爻标注参照',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '选择年柱/月柱/日柱/时柱切换十二长生计算依据；选择京房五星切换标注类型',
              style: TextStyle(color: _mutedInk, fontSize: 10, height: 1.4),
            ),
          ),
          const SizedBox(height: 6),
          for (final choice in _choices)
            ListTile(
              key: Key('growth-choice-${choice.reference}'),
              dense: true,
              leading: Icon(
                choice.mode == 'five_stars' ? Icons.star_outline : Icons.grain,
                size: 18,
                color: _cinnabar,
              ),
              title: Text(
                choice.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              trailing:
                  choice.mode == currentMode &&
                      (choice.mode == 'five_stars' ||
                          choice.reference == currentReference)
                  ? const Icon(Icons.check, size: 18, color: _cinnabar)
                  : null,
              onTap: () => Navigator.pop(context, choice),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// 爻位下方标注信息的可见性（总开关关闭时全部为 false）。
class LiuyaoLineAnnotationVisibility {
  const LiuyaoLineAnnotationVisibility({
    required this.showNaYin,
    required this.showTwelveGrowth,
    required this.showFiveStars,
    required this.show28Mansions,
  });

  final bool showNaYin;
  final bool showTwelveGrowth;
  final bool showFiveStars;
  final bool show28Mansions;

  bool get anyVisible =>
      showNaYin || showTwelveGrowth || showFiveStars || show28Mansions;
}

/// 卦面信息显示开关：总开关 + 纳音/十二长生/五星/二十八宿细分开关。
class LiuyaoLineAnnotationsToggle extends StatelessWidget {
  const LiuyaoLineAnnotationsToggle({
    super.key,
    required this.showLineAnnotations,
    required this.onChangedLineAnnotations,
    required this.showNaYin,
    required this.onChangedNaYin,
    required this.showTwelveGrowth,
    required this.onChangedTwelveGrowth,
    required this.showFiveStars,
    required this.onChangedFiveStars,
    required this.show28Mansions,
    required this.onChanged28Mansions,
  });

  final bool showLineAnnotations;
  final ValueChanged<bool> onChangedLineAnnotations;
  final bool showNaYin;
  final ValueChanged<bool> onChangedNaYin;
  final bool showTwelveGrowth;
  final ValueChanged<bool> onChangedTwelveGrowth;
  final bool showFiveStars;
  final ValueChanged<bool> onChangedFiveStars;
  final bool show28Mansions;
  final ValueChanged<bool> onChanged28Mansions;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('line-annotations-toggle'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: _softPaper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _rule, width: .8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '显示卦爻信息',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '控制爻位下方纳音、十二长生、五星、二十八宿的显示',
                      style: TextStyle(color: _mutedInk, fontSize: 9),
                    ),
                  ],
                ),
              ),
              Switch(
                key: const Key('line-annotations-switch'),
                value: showLineAnnotations,
                onChanged: onChangedLineAnnotations,
                activeColor: _cinnabar,
              ),
            ],
          ),
          if (showLineAnnotations) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _annotationChip(
                  label: '纳音',
                  selected: showNaYin,
                  onChanged: onChangedNaYin,
                  key: const Key('show-nayin'),
                ),
                _annotationChip(
                  label: '十二长生',
                  selected: showTwelveGrowth,
                  onChanged: onChangedTwelveGrowth,
                  key: const Key('show-twelve-growth'),
                ),
                _annotationChip(
                  label: '五星',
                  selected: showFiveStars,
                  onChanged: onChangedFiveStars,
                  key: const Key('show-five-stars'),
                ),
                _annotationChip(
                  label: '二十八宿',
                  selected: show28Mansions,
                  onChanged: onChanged28Mansions,
                  key: const Key('show-28-mansions'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _annotationChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onChanged,
    required Key key,
  }) {
    return FilterChip(
      key: key,
      label: Text(
        label,
        style: TextStyle(fontSize: 11, color: selected ? Colors.white : _ink),
      ),
      selected: selected,
      onSelected: onChanged,
      selectedColor: _cinnabar,
      checkmarkColor: Colors.white,
      visualDensity: VisualDensity.compact,
    );
  }
}

class LiuyaoCoreChart extends StatelessWidget {
  const LiuyaoCoreChart({
    super.key,
    required this.preview,
    this.lightHeader = false,
    this.showSummaryHeader = true,
    this.growthReference = 'day',
    this.onGrowthTap,
    this.annotationMode = 'twelve_growth',
    this.visibility = const LiuyaoLineAnnotationVisibility(
      showNaYin: true,
      showTwelveGrowth: true,
      showFiveStars: true,
      show28Mansions: true,
    ),
  });

  final CastPreview preview;
  final bool lightHeader;
  final bool showSummaryHeader;
  final String growthReference;
  final VoidCallback? onGrowthTap;
  final String annotationMode;
  final LiuyaoLineAnnotationVisibility visibility;

  @override
  Widget build(BuildContext context) => Column(
    key: const Key('liuyao-core-chart'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (preview.isLegacySnapshot) ...[
        _LegacySnapshotNotice(preview: preview),
        const SizedBox(height: 12),
      ],
      if (showSummaryHeader) ...[
        _ChartHeader(preview: preview, light: lightHeader),
        const SizedBox(height: 12),
      ],
      _ChartTable(
        preview: preview,
        showFlowSummary: !showSummaryHeader,
        growthReference: growthReference,
        onGrowthTap: onGrowthTap,
        annotationMode: annotationMode,
        visibility: visibility,
      ),
    ],
  );
}

class LiuyaoShenshaPanel extends StatelessWidget {
  const LiuyaoShenshaPanel({super.key, required this.preview});

  final CastPreview preview;

  @override
  Widget build(BuildContext context) => _ShenshaAnnotations(preview: preview);
}

class LiuyaoTwelveStagesPanel extends StatefulWidget {
  const LiuyaoTwelveStagesPanel({
    super.key,
    required this.preview,
    this.selectedReference,
    this.onReferenceChanged,
    this.annotationMode,
    this.onModeChanged,
  });

  final CastPreview preview;

  /// 外部受控参照；为 null 时组件自管理。
  final String? selectedReference;
  final ValueChanged<String>? onReferenceChanged;

  /// 外部受控标注模式；为 null 时组件自管理。
  final String? annotationMode;
  final ValueChanged<String>? onModeChanged;

  @override
  State<LiuyaoTwelveStagesPanel> createState() =>
      _LiuyaoTwelveStagesPanelState();
}

class _LiuyaoTwelveStagesPanelState extends State<LiuyaoTwelveStagesPanel> {
  String _reference = 'day';
  String _mode = 'twelve_growth';

  @override
  Widget build(BuildContext context) {
    final selectedReference = widget.selectedReference ?? _reference;
    final annotationMode = widget.annotationMode ?? _mode;
    return _TwelveStagesLedger(
      preview: widget.preview,
      selectedReference: selectedReference,
      onReferenceChanged: (value) {
        final external = widget.onReferenceChanged;
        if (external != null) {
          external(value);
        } else {
          setState(() => _reference = value);
        }
      },
      annotationMode: annotationMode,
      onModeChanged: (value) {
        final external = widget.onModeChanged;
        if (external != null) {
          external(value);
        } else {
          setState(() => _mode = value);
        }
      },
    );
  }
}

/// 弹出卦爻标注参照选择底部弹窗（年柱/月柱/日柱/时柱/京房五星）。
/// 返回 null 表示用户取消。
Future<LiuyaoGrowthReferenceChoice?> showLiuyaoGrowthReferencePicker({
  required BuildContext context,
  required String currentReference,
  required String currentMode,
}) {
  return showModalBottomSheet<LiuyaoGrowthReferenceChoice>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => LiuyaoGrowthReferenceSheet(
      currentReference: currentReference,
      currentMode: currentMode,
    ),
  );
}

class LiuyaoCalculationDetailsPanel extends StatelessWidget {
  const LiuyaoCalculationDetailsPanel({super.key, required this.preview});

  final CastPreview preview;

  @override
  Widget build(BuildContext context) => _CalculationDetails(preview: preview);
}

class _LegacySnapshotNotice extends StatelessWidget {
  const _LegacySnapshotNotice({required this.preview});

  final CastPreview preview;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('legacy-snapshot-notice'),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEDEA),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0x33B3261E)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.history_rounded, color: _cinnabar),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '这是 schema v${preview.schemaVersion} 历史档案。当前按原始快照只读展示；'
            '旧合同未保存的卦码、上下卦、十二长生、神煞和计算明细不会补算。',
            style: const TextStyle(color: _ink, fontSize: 11, height: 1.5),
          ),
        ),
      ],
    ),
  );
}

class _ShenshaAnnotations extends StatelessWidget {
  const _ShenshaAnnotations({required this.preview});

  final CastPreview preview;

  @override
  Widget build(BuildContext context) {
    final results = preview.annotations.shenshaResults;
    final bodyMarkers = preview.annotations.bodyMarkers;
    return Container(
      key: const Key('shensha-annotations'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF31251F),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16251D18),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                '神煞与身命标注',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '逐项冻结 · 不作吉凶评分',
                  style: TextStyle(color: Color(0xFFBEB3AA), fontSize: 9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...results.map((result) => _ShenshaResultRow(result: result)),
          if (bodyMarkers != null) ...[
            _BodyMarkerResultRow.guaShen(marker: bodyMarkers.guaShen),
            _BodyMarkerResultRow.mingYao(marker: bodyMarkers.mingYao),
          ],
        ],
      ),
    );
  }
}

class _BodyMarkerResultRow extends StatelessWidget {
  const _BodyMarkerResultRow.guaShen({required GuaShenMarker marker})
    : _guaShen = marker,
      _mingYao = null;

  const _BodyMarkerResultRow.mingYao({required MingYaoMarker marker})
    : _guaShen = null,
      _mingYao = marker;

  final GuaShenMarker? _guaShen;
  final MingYaoMarker? _mingYao;

  @override
  Widget build(BuildContext context) {
    final guaShen = _guaShen;
    final matched = guaShen == null || guaShen.status == 'computed_match';
    final label = guaShen?.displayName ?? _mingYao!.displayName;
    final heading = guaShen == null
        ? '世爻支取命爻 · ${_mingYao!.line.positionName}'
        : '月卦身取 ${guaShen.targetBranch} 支';
    final detail = guaShen == null
        ? '${_mingYao!.line.ganZhi} · ${_mingYao.line.relation}'
        : guaShen.matches.isEmpty
        ? '本卦明爻未现 · 卦身不上卦'
        : guaShen.matches
              .map(
                (line) =>
                    '${line.positionName} ${line.ganZhi} · ${line.relation}',
              )
              .join(' / ');
    return Container(
      key: Key('body-marker-$label'),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: matched ? const Color(0xFF4A3028) : const Color(0xFF3A302B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: matched ? const Color(0x66DFA58E) : const Color(0x224D4039),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: matched ? _cinnabar : const Color(0xFF594D47),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heading,
                  style: const TextStyle(
                    color: Color(0xFFFFD7C7),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: TextStyle(
                    color: matched
                        ? const Color(0xFFF4E8DF)
                        : const Color(0xFFBEB3AA),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShenshaResultRow extends StatelessWidget {
  const _ShenshaResultRow({required this.result});

  final ShenshaResult result;

  @override
  Widget build(BuildContext context) {
    final matched = result.status == 'computed_match';
    final basisUnit = switch (result.basisType) {
      'day_stem' => '干',
      'day_branch' => '支',
      _ => '',
    };
    final matchText = matched
        ? result.matches
              .map(
                (item) =>
                    '${item.positionName} ${item.ganZhi} · ${item.relation}',
              )
              .join(' / ')
        : '本卦明爻未现';
    return Container(
      key: Key('shensha-${result.ruleId}'),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: matched ? const Color(0xFF4A3028) : const Color(0xFF3A302B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: matched ? const Color(0x66DFA58E) : const Color(0x224D4039),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: matched ? _cinnabar : const Color(0xFF594D47),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              result.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${result.basisPillarGanZhi}日 · ${result.basisValue}$basisUnit取${result.targetBranches.join('、')}',
                  style: const TextStyle(
                    color: Color(0xFFFFD7C7),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  matchText,
                  style: TextStyle(
                    color: matched
                        ? const Color(0xFFF4E8DF)
                        : const Color(0xFFBEB3AA),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            matched ? Icons.adjust_rounded : Icons.remove_circle_outline,
            color: matched ? const Color(0xFFFFB59B) : const Color(0xFF8E827A),
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _TwelveStagesLedger extends StatelessWidget {
  const _TwelveStagesLedger({
    required this.preview,
    required this.selectedReference,
    required this.onReferenceChanged,
    required this.annotationMode,
    required this.onModeChanged,
  });

  final CastPreview preview;
  final String selectedReference;
  final ValueChanged<String> onReferenceChanged;
  final String annotationMode;
  final ValueChanged<String> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final rule = preview.annotations.fiveElementTwelveStages;
    final results = rule.lineResults.reversed.toList(growable: false);
    final labels = const <String, String>{
      'year': '年柱',
      'month': '月柱',
      'day': '日柱',
      'hour': '时柱',
      'element:木': '木',
      'element:火': '火',
      'element:土': '土',
      'element:金': '金',
      'element:水': '水',
    };
    return Container(
      key: const Key('twelve-stages-ledger'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '卦面标注',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const Text(
            '切换标注类型，卦面小字同步刷新',
            style: TextStyle(color: _mutedInk, fontSize: 9),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            key: const Key('annotation-mode-switch'),
            segments: const [
              ButtonSegment(
                value: 'twelve_growth',
                icon: Icon(Icons.grain, size: 15),
                label: Text('十二长生'),
              ),
              ButtonSegment(
                value: 'five_stars',
                icon: Icon(Icons.star_outline, size: 15),
                label: Text('京房五星'),
              ),
            ],
            selected: {annotationMode},
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              side: const WidgetStatePropertyAll(BorderSide(color: _cinnabar)),
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? _cinnabar
                    : _softPaper,
              ),
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) =>
                    states.contains(WidgetState.selected) ? Colors.white : _ink,
              ),
            ),
            onSelectionChanged: (selection) {
              onModeChanged(selection.first);
            },
          ),
          const SizedBox(height: 10),
          if (annotationMode == 'five_stars')
            _FiveStarsLedger(preview: preview)
          else ...[
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: labels.entries
                  .map((entry) {
                    final selected = selectedReference == entry.key;
                    return ChoiceChip(
                      key: Key('growth-reference-${entry.key}'),
                      label: Text(entry.value),
                      selected: selected,
                      onSelected: (_) => onReferenceChanged(entry.key),
                      labelStyle: TextStyle(
                        fontSize: 10,
                        color: selected ? Colors.white : _ink,
                      ),
                      selectedColor: _cinnabar,
                      visualDensity: VisualDensity.compact,
                    );
                  })
                  .toList(growable: false),
            ),
            const SizedBox(height: 8),
            _TwelveStagesHeader(selectedReference: selectedReference),
            const SizedBox(height: 4),
            ...results.map(
              (result) => _TwelveStagesRow(
                result: result,
                selectedReference: selectedReference,
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(2, 8, 2, 0),
              child: Text(
                '受气与化绝：四土独立表中的受气对应绝位，详见计算明细。',
                style: TextStyle(color: _mutedInk, fontSize: 9, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FiveStarsLedger extends StatelessWidget {
  const _FiveStarsLedger({required this.preview});

  final CastPreview preview;

  @override
  Widget build(BuildContext context) {
    final fiveStars = preview.annotations.fiveStars;
    if (fiveStars == null) {
      return Container(
        key: const Key('five-stars-empty'),
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _softPaper,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          '该档案未保存京房五星数据。',
          style: TextStyle(color: _mutedInk, fontSize: 11),
        ),
      );
    }
    final hexagram = fiveStars.hexagram;
    final world = fiveStars.worldLine;
    final response = fiveStars.responseLine;
    // 爻位视觉方向：上爻在上、初爻在下（与卦面爻线 reversed 一致）。
    final placements = [...fiveStars.linePlacements]
      ..sort((a, b) => b.position.compareTo(a.position));
    const positionNames = ['初爻', '二爻', '三爻', '四爻', '五爻', '上爻'];

    return Column(
      key: const Key('five-stars-ledger'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: _mansionPaper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x55D49A26)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${hexagram.name} · ${hexagram.palaceName}宫第${hexagram.palaceSequence}卦',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '世爻${world.positionName}起${world.starName}；应爻${response.positionName}为克制星'
                '${response.starName}',
                style: const TextStyle(color: _mutedInk, fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _softPaper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _rule, width: .8),
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 8, 12, 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: Text(
                        '爻位',
                        style: TextStyle(
                          color: _mutedInk,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(child: Text('五星', style: _fiveStarsHeaderStyle)),
                    Expanded(child: Text('五行', style: _fiveStarsHeaderStyle)),
                    SizedBox(
                      width: 44,
                      child: Text('角色', style: _fiveStarsHeaderStyle),
                    ),
                  ],
                ),
              ),
              for (final placement in placements)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: _rule.withValues(alpha: .5)),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        child: Text(
                          positionNames[placement.position - 1],
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          placement.starName,
                          style: TextStyle(
                            color: _elementStarColor(placement.element),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          placement.element,
                          style: const TextStyle(
                            color: _mutedInk,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(
                          placement.role,
                          style: TextStyle(
                            color:
                                placement.role == '世' || placement.role == '应'
                                ? _cinnabar
                                : _mutedInk,
                            fontSize: 11,
                            fontWeight:
                                placement.role == '世' || placement.role == '应'
                                ? FontWeight.w800
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static const _fiveStarsHeaderStyle = TextStyle(
    color: _mutedInk,
    fontSize: 10,
    fontWeight: FontWeight.w700,
  );
}

class _TwelveStagesHeader extends StatelessWidget {
  const _TwelveStagesHeader({required this.selectedReference});

  final String selectedReference;

  @override
  Widget build(BuildContext context) {
    final labels = const {'year': '年', 'month': '月', 'day': '日', 'hour': '时'};
    final elementName = _elementReferenceName(selectedReference);
    return Row(
      children: [
        const SizedBox(
          width: 49,
          child: Text('爻 / 行', style: _stageHeaderStyle),
        ),
        ...labels.entries.map(
          (entry) => _StageHeaderCell(
            label: entry.value,
            emphasized: selectedReference == entry.key,
          ),
        ),
        if (elementName != null)
          _StageHeaderCell(label: '五行·$elementName', emphasized: true),
      ],
    );
  }
}

class _TwelveStagesRow extends StatelessWidget {
  const _TwelveStagesRow({
    required this.result,
    required this.selectedReference,
  });

  final TwelveStageLineResult result;
  final String selectedReference;

  @override
  Widget build(BuildContext context) {
    final fourPillars = result.pillarResults
        .where((item) => _fourPillarRefs.contains(item.reference))
        .toList(growable: false);
    final selectedElement = result.pillarResults
        .where((item) => item.reference == selectedReference)
        .where((item) => item.reference.startsWith('element:'))
        .firstOrNull;
    return Container(
      key: Key('twelve-stage-${result.lineId}'),
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x12251D18))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 49,
            child: Text(
              '${result.positionName.replaceAll('爻', '')} · ${result.lineElement}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ),
          ...fourPillars.map(
            (item) => Expanded(
              child: _StageCell(
                item: item,
                emphasized: item.reference == selectedReference,
              ),
            ),
          ),
          if (selectedElement != null)
            Expanded(
              child: _StageCell(item: selectedElement, emphasized: true),
            ),
        ],
      ),
    );
  }
}

class _StageCell extends StatelessWidget {
  const _StageCell({required this.item, required this.emphasized});

  final TwelveStagePillarResult item;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 2),
    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 1),
    decoration: BoxDecoration(
      color: emphasized ? const Color(0xFFF8E8DF) : _softPaper,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        Text(
          item.referenceBranch,
          style: TextStyle(
            color: emphasized ? _cinnabar : _mutedInk,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          item.stage,
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: const TextStyle(
            color: _ink,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

/// 五行参照 key（element:木 等）中提取五行名；非五行参照返回 null。
String? _elementReferenceName(String reference) =>
    reference.startsWith('element:')
    ? reference.substring('element:'.length)
    : null;

const _fourPillarRefs = {'year', 'month', 'day', 'hour'};

const _stageHeaderStyle = TextStyle(
  color: _mutedInk,
  fontSize: 9,
  fontWeight: FontWeight.w700,
);

class _StageHeaderCell extends StatelessWidget {
  const _StageHeaderCell({required this.label, this.emphasized = false});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: _stageHeaderStyle.copyWith(
        color: emphasized ? _cinnabar : _mutedInk,
      ),
    ),
  );
}

class _ChartHeader extends StatelessWidget {
  const _ChartHeader({required this.preview, this.light = false});

  final CastPreview preview;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final base = preview.chart.base;
    final changed = preview.chart.changed;
    final moving = base.movingPositions.isEmpty
        ? '静卦'
        : '动爻 ${base.movingPositions.join('、')}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 18),
      decoration: BoxDecoration(
        color: light ? _paper : _ink,
        borderRadius: BorderRadius.circular(22),
        border: light ? Border.all(color: _rule) : null,
        boxShadow: light
            ? null
            : const [
                BoxShadow(
                  color: Color(0x20251D18),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: _cinnabar,
                size: 18,
              ),
              const SizedBox(width: 7),
              Text(
                preview.isLegacySnapshot ? '历史卦面快照' : '基础卦面已生成',
                style: const TextStyle(
                  color: _cinnabar,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            changed == null
                ? '${base.name} · 静卦'
                : '${base.name} → ${changed.name}',
            style: TextStyle(
              color: light ? _ink : Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            preview.isLegacySnapshot
                ? '${base.palace.name}宫${base.palace.element} · $moving'
                : '${base.upperTrigram.name}上${base.lowerTrigram.name}下 · '
                      '${base.palace.name}宫${base.palace.element} · $moving',
            style: TextStyle(
              color: light ? _mutedInk : const Color(0xFFDDD2C8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (base.shiPosition > 0)
                _DarkTag(
                  text: '世在${_position(base.shiPosition)}',
                  light: light,
                ),
              if (base.yingPosition > 0)
                _DarkTag(
                  text: '应在${_position(base.yingPosition)}',
                  light: light,
                ),
              if (base.code.isNotEmpty)
                _DarkTag(text: '卦码 ${base.code}', light: light),
            ],
          ),
        ],
      ),
    );
  }

  static String _position(int value) {
    return const ['初爻', '二爻', '三爻', '四爻', '五爻', '上爻'][value - 1];
  }
}

class _DarkTag extends StatelessWidget {
  const _DarkTag({required this.text, this.light = false});

  final String text;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: light ? _softPaper : const Color(0xFF3A302B),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x334D4039)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: light ? _ink : const Color(0xFFF3E8DE),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ChartTable extends StatelessWidget {
  const _ChartTable({
    required this.preview,
    required this.showFlowSummary,
    this.growthReference = 'day',
    this.onGrowthTap,
    this.annotationMode = 'twelve_growth',
    this.visibility = const LiuyaoLineAnnotationVisibility(
      showNaYin: true,
      showTwelveGrowth: true,
      showFiveStars: true,
      show28Mansions: true,
    ),
  });

  final CastPreview preview;
  final bool showFlowSummary;
  final String growthReference;
  final VoidCallback? onGrowthTap;
  final String annotationMode;
  final LiuyaoLineAnnotationVisibility visibility;

  @override
  Widget build(BuildContext context) {
    final base = preview.chart.base;
    final mansions = preview.annotations.twentyEightMansions;
    final hiddenAnnotations = preview.annotations.hiddenHexagramAnnotations;
    final changedAnnotations = preview.annotations.changedHexagramAnnotations;
    final mansionByPosition = {
      for (final placement
          in mansions?.linePlacements ?? const <MansionLinePlacement>[])
        placement.position: placement,
    };
    final hiddenMansionByPosition = {
      for (final placement
          in hiddenAnnotations?.twentyEightMansions.linePlacements ??
              const <MansionLinePlacement>[])
        placement.position: placement,
    };
    final changedMansionByPosition = {
      for (final placement
          in changedAnnotations?.twentyEightMansions.linePlacements ??
              const <MansionLinePlacement>[])
        placement.position: placement,
    };
    final fiveStarByPosition = {
      for (final placement
          in preview.annotations.fiveStars?.linePlacements ??
              const <FiveStarPlacement>[])
        placement.position: placement,
    };
    final hiddenFiveStarByPosition = {
      for (final placement
          in hiddenAnnotations?.fiveStars?.linePlacements ??
              const <FiveStarPlacement>[])
        placement.position: placement,
    };
    final changedFiveStarByPosition = {
      for (final placement
          in changedAnnotations?.fiveStars?.linePlacements ??
              const <FiveStarPlacement>[])
        placement.position: placement,
    };
    final changedByPosition = {
      for (final line
          in preview.chart.changed?.lines ?? const <ChangedChartLine>[])
        line.position: line,
    };
    Map<int, String> growthStages(FiveElementTwelveStages stages) {
      final output = <int, String>{};
      for (final result in stages.lineResults) {
        for (final pillar in result.pillarResults) {
          if (pillar.reference == growthReference) {
            output[result.position] = pillar.stage;
            break;
          }
        }
      }
      return output;
    }

    // 五星模式下十二长生槽位让位给五星，不计算长生阶段。
    Map<int, String> growthStagesOrEmpty(FiveElementTwelveStages stages) =>
        annotationMode == 'five_stars'
        ? const <int, String>{}
        : growthStages(stages);

    final dayStageByPosition = growthStagesOrEmpty(
      preview.annotations.fiveElementTwelveStages,
    );
    final hiddenDayStageByPosition = hiddenAnnotations == null
        ? const <int, String>{}
        : growthStagesOrEmpty(hiddenAnnotations.fiveElementTwelveStages);
    final changedDayStageByPosition = changedAnnotations == null
        ? const <int, String>{}
        : growthStagesOrEmpty(changedAnnotations.fiveElementTwelveStages);
    return Container(
      key: const Key('liuyao-chart-table'),
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _rule, width: .8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PillarContextPanel(preview: preview),
          const SizedBox(height: 12),
          _HexagramComparisonHeader(
            base: base,
            changed: preview.chart.changed,
            canonicalPalaceSequence: preview.hasCanonicalPalaceSequence,
            showFlowSummary: showFlowSummary,
          ),
          if (mansions != null) ...[
            const SizedBox(height: 8),
            _MansionWorldSummary(mansions: mansions),
          ],
          const SizedBox(height: 10),
          const _ChartColumnHeader(),
          const Divider(height: 12, thickness: .8),
          ...base.lines.reversed.map(
            (line) => _ChartLineRow(
              line: line,
              changed: changedByPosition[line.position],
              mansion: mansionByPosition[line.position],
              dayStage: dayStageByPosition[line.position],
              hiddenMansion: hiddenMansionByPosition[line.position],
              hiddenDayStage: hiddenDayStageByPosition[line.position],
              changedMansion: changedMansionByPosition[line.position],
              changedDayStage: changedDayStageByPosition[line.position],
              fiveStar: fiveStarByPosition[line.position],
              hiddenFiveStar: hiddenFiveStarByPosition[line.position],
              changedFiveStar: changedFiveStarByPosition[line.position],
              onGrowthTap: onGrowthTap,
              annotationMode: annotationMode,
              visibility: visibility,
            ),
          ),
        ],
      ),
    );
  }
}

class _MansionWorldSummary extends StatelessWidget {
  const _MansionWorldSummary({required this.mansions});

  final TwentyEightMansions mansions;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('mansion-world-summary'),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: _mansionPaper.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _mansionInk.withValues(alpha: 0.18)),
    ),
    child: Row(
      children: [
        const Text(
          '京房宿：',
          style: TextStyle(
            color: _mutedInk,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '世爻${mansions.worldMansion}宿',
          style: const TextStyle(
            color: _mansionInk,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        Text(
          '64卦序·${mansions.hexagramGlobalIndex + 1}',
          style: const TextStyle(
            color: _mutedInk,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _PillarContextPanel extends StatelessWidget {
  const _PillarContextPanel({required this.preview});

  final CastPreview preview;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        keyName: 'year',
        suffix: '年',
        pillar: preview.yearPillar,
        voidText: preview.yearVoid,
      ),
      (
        keyName: 'month',
        suffix: '月',
        pillar: preview.monthPillar,
        voidText: preview.monthVoid,
      ),
      (
        keyName: 'day',
        suffix: '日',
        pillar: preview.dayPillar,
        voidText: preview.dayVoid,
      ),
      (
        keyName: 'hour',
        suffix: '时',
        pillar: preview.hourPillar,
        voidText: preview.hourVoid,
      ),
    ];
    return Container(
      key: const Key('pillar-time-panel'),
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 6),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                '四柱',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                preview.fourPillarsSource == 'manual' ? '手动填写' : '自动计算',
                key: const Key('four-pillars-source-label'),
                style: TextStyle(
                  color: preview.fourPillarsSource == 'manual'
                      ? _cinnabar
                      : _mutedInk,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              for (final item in items)
                Expanded(
                  child: _PillarCell(
                    keyName: item.keyName,
                    pillar: item.pillar,
                    suffix: item.suffix,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              for (final item in items)
                Expanded(
                  child: Text(
                    item.voidText == '未记录' ? '未记录' : '${item.voidText}空',
                    key: Key('time-${item.keyName}-void'),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: const TextStyle(
                      color: _mutedInk,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillarCell extends StatelessWidget {
  const _PillarCell({
    required this.keyName,
    required this.pillar,
    required this.suffix,
  });

  final String keyName;
  final String pillar;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    if (pillar.length < 2 || pillar == '未记录') {
      return const Text(
        '未记录',
        textAlign: TextAlign.center,
        style: TextStyle(color: _mutedInk, fontSize: 10),
      );
    }
    final stem = pillar.substring(0, 1);
    final branch = pillar.substring(1, 2);
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            stem,
            key: Key('time-$keyName-stem'),
            style: TextStyle(
              color: _stemColor(stem),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            branch,
            key: Key('time-$keyName-branch'),
            style: TextStyle(
              color: _branchColor(branch),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            suffix,
            style: const TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HexagramComparisonHeader extends StatelessWidget {
  const _HexagramComparisonHeader({
    required this.base,
    required this.changed,
    required this.canonicalPalaceSequence,
    required this.showFlowSummary,
  });

  final BaseHexagram base;
  final ChangedHexagram? changed;
  final bool canonicalPalaceSequence;
  final bool showFlowSummary;

  @override
  Widget build(BuildContext context) {
    final changedHexagram = changed;
    return Column(
      children: [
        if (showFlowSummary) ...[
          Text(
            changedHexagram == null
                ? '${base.name} · 静卦'
                : '${base.name} → ${changedHexagram.name}',
            style: const TextStyle(
              color: _mutedInk,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _HexagramTitleBlock(
                key: const Key('base-hexagram-summary'),
                label: '本卦',
                name: base.name,
                palace: base.palace,
                palaceSequence: canonicalPalaceSequence
                    ? base.palaceSequence
                    : 0,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _HexagramTitleBlock(
                key: const Key('changed-hexagram-summary'),
                label: changedHexagram == null ? '变卦·静' : '变卦',
                name: changedHexagram?.name ?? '无变卦',
                palace: changedHexagram?.palace,
                palaceSequence: canonicalPalaceSequence
                    ? changedHexagram?.palaceSequence ?? 0
                    : 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _HiddenHexagramIdentityLine(hidden: base.hiddenHexagram),
      ],
    );
  }
}

class _HexagramTitleBlock extends StatelessWidget {
  const _HexagramTitleBlock({
    super.key,
    required this.label,
    required this.name,
    required this.palace,
    required this.palaceSequence,
  });

  final String label;
  final String name;
  final TrigramSummary? palace;
  final int palaceSequence;

  @override
  Widget build(BuildContext context) {
    final palaceText = palace == null
        ? '卦宫未记录'
        : palaceSequence > 0
        ? '/ ${palace!.name}宫·$palaceSequence'
        : '/ ${palace!.name}宫·序位未记录';
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _mutedInk,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            name,
            maxLines: 1,
            style: const TextStyle(
              color: _ink,
              fontFamily: 'Songti SC',
              fontFamilyFallback: ['Noto Serif CJK SC', 'Noto Serif SC'],
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          palaceText,
          maxLines: 1,
          style: TextStyle(
            color: palace == null ? _mutedInk : _elementColor(palace!.element),
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _HiddenHexagramIdentityLine extends StatelessWidget {
  const _HiddenHexagramIdentityLine({required this.hidden});

  final HiddenHexagram? hidden;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('hidden-hexagram-summary'),
      children: [
        const Text(
          '伏卦：',
          style: TextStyle(
            color: _mutedInk,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        Expanded(
          child: Text(
            hidden?.name ?? '旧档案未记录',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (hidden != null)
          Text(
            '/ ${hidden!.palaceBasis.name}宫规则',
            style: TextStyle(
              color: _elementColor(hidden!.palaceBasis.element),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}

class _ChartColumnHeader extends StatelessWidget {
  const _ChartColumnHeader();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: Row(
      children: [
        const SizedBox(width: 36, child: _ColumnLabel('六神')),
        const Expanded(flex: 2, child: _ColumnLabel('伏神')),
        const Expanded(flex: 2, child: _ColumnLabel('本卦')),
        const SizedBox(width: 46, child: _ColumnLabel('爻·世应')),
        const Expanded(flex: 2, child: _ColumnLabel('变卦')),
        const SizedBox(width: 46, child: _ColumnLabel('爻·世应')),
      ],
    ),
  );
}

class _ColumnLabel extends StatelessWidget {
  const _ColumnLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    maxLines: 1,
    style: const TextStyle(
      color: _mutedInk,
      fontSize: 8,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _ChartLineRow extends StatelessWidget {
  const _ChartLineRow({
    required this.line,
    required this.changed,
    required this.mansion,
    required this.dayStage,
    required this.hiddenMansion,
    required this.hiddenDayStage,
    required this.changedMansion,
    required this.changedDayStage,
    this.fiveStar,
    this.hiddenFiveStar,
    this.changedFiveStar,
    this.onGrowthTap,
    this.annotationMode = 'twelve_growth',
    this.visibility = const LiuyaoLineAnnotationVisibility(
      showNaYin: true,
      showTwelveGrowth: true,
      showFiveStars: true,
      show28Mansions: true,
    ),
  });

  final BaseChartLine line;
  final ChangedChartLine? changed;
  final MansionLinePlacement? mansion;
  final String? dayStage;
  final MansionLinePlacement? hiddenMansion;
  final String? hiddenDayStage;
  final MansionLinePlacement? changedMansion;
  final String? changedDayStage;
  final FiveStarPlacement? fiveStar;
  final FiveStarPlacement? hiddenFiveStar;
  final FiveStarPlacement? changedFiveStar;
  final VoidCallback? onGrowthTap;
  final String annotationMode;
  final LiuyaoLineAnnotationVisibility visibility;

  @override
  Widget build(BuildContext context) {
    final hidden = line.hidden;
    return Container(
      key: Key('chart-line-${line.position}'),
      padding: const EdgeInsets.fromLTRB(5, 8, 5, 7),
      decoration: BoxDecoration(
        color: line.changing
            ? _cinnabar.withValues(alpha: .045)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: line.position == 4 ? LiuyaoColors.inkMedium : _rule,
            width: line.position == 4 ? 1.1 : .8,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Text(
                  _displaySixGod(line.sixGod),
                  key: Key('six-god-${line.position}'),
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  _shortPosition(line.position),
                  style: const TextStyle(color: _mutedInk, fontSize: 7),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: hidden == null
                ? const _EmptyNajiaCell()
                : _NajiaCell(
                    key: Key('hidden-${line.position}'),
                    prefix: 'hidden',
                    position: line.position,
                    relation: hidden.relation,
                    najia: hidden.najia,
                    muted: true,
                    growthStage: hiddenDayStage,
                    fiveStar: hiddenFiveStar,
                    mansion: hiddenMansion,
                    onGrowthTap: onGrowthTap,
                    annotationMode: annotationMode,
                    visibility: visibility,
                  ),
          ),
          Expanded(
            flex: 2,
            child: _NajiaCell(
              prefix: 'base',
              position: line.position,
              relation: line.relation,
              najia: line.najia,
              growthStage: dayStage,
              fiveStar: fiveStar,
              mansion: mansion,
              onGrowthTap: onGrowthTap,
              annotationMode: annotationMode,
              visibility: visibility,
            ),
          ),
          SizedBox(
            width: 46,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 12,
                  child: _TraditionalYaoGlyph(
                    key: Key('base-glyph-${line.position}'),
                    yang: line.yinYang == 'yang',
                    movingMarker: line.changing
                        ? line.value == 9
                              ? 'Ｏ'
                              : 'Χ'
                        : null,
                    position: line.position,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  line.role ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _cinnabar,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: changed == null
                ? const _EmptyNajiaCell()
                : _NajiaCell(
                    prefix: 'changed',
                    position: line.position,
                    relation: changed!.relation,
                    najia: changed!.najia,
                    growthStage: changedDayStage,
                    fiveStar: changedFiveStar,
                    mansion: changedMansion,
                    onGrowthTap: onGrowthTap,
                    annotationMode: annotationMode,
                    visibility: visibility,
                  ),
          ),
          SizedBox(
            width: 46,
            child: changed == null
                ? const Center(child: Text('·'))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 12,
                        child: _TraditionalYaoGlyph(
                          key: Key('changed-glyph-${line.position}'),
                          yang: changed!.yinYang == 'yang',
                          position: line.position,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        changed!.role ?? '',
                        key: Key('changed-role-${line.position}'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _cinnabar,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNajiaCell extends StatelessWidget {
  const _EmptyNajiaCell();

  @override
  Widget build(BuildContext context) => const Text(
    '·',
    textAlign: TextAlign.center,
    style: TextStyle(color: Color(0x55251D18), fontSize: 12),
  );
}

class _NajiaCell extends StatelessWidget {
  const _NajiaCell({
    super.key,
    required this.prefix,
    required this.position,
    required this.relation,
    required this.najia,
    this.muted = false,
    this.growthStage,
    this.fiveStar,
    this.mansion,
    this.onGrowthTap,
    this.annotationMode = 'twelve_growth',
    this.visibility = const LiuyaoLineAnnotationVisibility(
      showNaYin: true,
      showTwelveGrowth: true,
      showFiveStars: true,
      show28Mansions: true,
    ),
  });

  final String prefix;
  final int position;
  final String relation;
  final NajiaFields najia;
  final bool muted;
  final String? growthStage;
  final FiveStarPlacement? fiveStar;
  final MansionLinePlacement? mansion;
  final VoidCallback? onGrowthTap;
  final String annotationMode;
  final LiuyaoLineAnnotationVisibility visibility;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              relation,
              style: TextStyle(
                color: muted ? _mutedInk : _ink,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              najia.heavenlyStem,
              key: Key('$prefix-stem-$position'),
              style: TextStyle(
                color: _stemColor(najia.heavenlyStem),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              najia.earthlyBranch,
              key: Key('$prefix-branch-$position'),
              style: TextStyle(
                color: _branchColor(najia.earthlyBranch),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
      ..._annotationRow(),
    ],
  );

  /// 爻位标注行（纳音 · 十二长生 · 五星 · 二十八宿）；无任何可见片段时返回空。
  List<Widget> _annotationRow() {
    final segments = _buildAnnotationSegments();
    if (segments.isEmpty) return const [];
    return [
      const SizedBox(height: 2),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(mainAxisSize: MainAxisSize.min, children: segments),
      ),
    ];
  }

  /// 爻位标注行：纳音 · 十二长生 · 五星 · 二十八宿。
  /// 缺失片段不渲染分隔符，避免出现多余的「··」。
  ///
  /// 五星模式（annotationMode == 'five_stars'）下，十二长生槽位改为显示
  /// 该爻五星短名，并隐藏独立五星段，避免同一信息重复出现。
  List<Widget> _buildAnnotationSegments() {
    final segments = <Widget>[];
    if (visibility.showNaYin) {
      segments.add(
        Text(
          najia.nayin ?? '',
          key: Key('$prefix-nayin-$position'),
          style: _annotationTextStyle(
            color: muted ? _mutedInk : LiuyaoColors.inkMuted,
            bold: false,
          ),
        ),
      );
    }
    final growthSlotVisible = visibility.showTwelveGrowth;
    if (annotationMode == 'five_stars') {
      if (growthSlotVisible && fiveStar != null) {
        segments.add(_segmentDot());
        final starText = Text(
          _fiveStarDisplayName(fiveStar!.star),
          key: Key('$prefix-growth-$position'),
          style: _annotationTextStyle(
            color: _elementStarColor(fiveStar!.element),
            bold: true,
          ),
        );
        segments.add(
          onGrowthTap == null
              ? starText
              : InkWell(
                  key: Key('$prefix-growth-tap-$position'),
                  onTap: onGrowthTap,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Text(
                      _fiveStarDisplayName(fiveStar!.star),
                      key: Key('$prefix-growth-$position'),
                      style: _annotationTextStyle(
                        color: _elementStarColor(fiveStar!.element),
                        bold: true,
                        underline: true,
                      ),
                    ),
                  ),
                ),
        );
      }
    } else {
      if (growthSlotVisible && growthStage != null) {
        segments.add(_segmentDot());
        final growthText = Text(
          growthStage!,
          key: Key('$prefix-growth-$position'),
          style: _annotationTextStyle(
            color: muted ? _mutedInk : LiuyaoColors.inkMuted,
            bold: true,
          ),
        );
        segments.add(
          onGrowthTap == null
              ? growthText
              : InkWell(
                  key: Key('$prefix-growth-tap-$position'),
                  onTap: onGrowthTap,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Text(
                      growthStage!,
                      key: Key('$prefix-growth-$position'),
                      style: _annotationTextStyle(
                        color: muted ? _mutedInk : _cinnabar,
                        bold: true,
                        underline: true,
                      ),
                    ),
                  ),
                ),
        );
      }
      if (visibility.showFiveStars && fiveStar != null) {
        segments.add(_segmentDot());
        segments.add(
          Text(
            _fiveStarDisplayName(fiveStar!.star),
            key: Key('$prefix-fivestar-$position'),
            style: _annotationTextStyle(
              color: _elementStarColor(fiveStar!.element),
              bold: true,
            ),
          ),
        );
      }
    }
    if (visibility.show28Mansions && mansion != null) {
      segments.add(_segmentDot());
      segments.add(
        Semantics(
          label: '${mansion!.mansion}宿，${mansion!.placementRole}装配',
          child: Text(
            '${mansion!.mansion}宿',
            key: Key(
              prefix == 'base'
                  ? 'mansion-${mansion!.position}'
                  : '$prefix-mansion-${mansion!.position}',
            ),
            style: _annotationTextStyle(color: _mansionInk, bold: true),
          ),
        ),
      );
    }
    return segments;
  }

  static Widget _segmentDot() =>
      const Text('·', style: TextStyle(color: _mutedInk, fontSize: 7));

  static TextStyle _annotationTextStyle({
    required Color color,
    required bool bold,
    bool underline = false,
  }) => TextStyle(
    color: color,
    fontSize: 7,
    fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
    decoration: underline ? TextDecoration.underline : null,
    decorationColor: color.withValues(alpha: .6),
  );
}

/// 京房五星在爻位标注行使用的极短名。
String _fiveStarDisplayName(String star) => switch (star) {
  '镇土' => '镇',
  '岁木' => '岁',
  _ => star,
};

/// 京房五星五行配色。
Color _elementStarColor(String element) => switch (element) {
  '木' => const Color(0xFF2E7D32),
  '火' => _cinnabar,
  '土' => const Color(0xFF795548),
  '金' => const Color(0xFF8D6E63),
  '水' => const Color(0xFF1565C0),
  _ => _ink,
};

class _TraditionalYaoGlyph extends StatelessWidget {
  const _TraditionalYaoGlyph({
    super.key,
    required this.yang,
    required this.position,
    this.movingMarker,
  });

  final bool yang;
  final int position;
  final String? movingMarker;

  @override
  Widget build(BuildContext context) {
    // 爻线绘制区与动爻标志区分离：爻线占左侧 Expanded，动爻 X/O 占右侧固定列，
    // 标志不与爻线重叠；无标志时仍保留占位，保证静爻与动爻整体布局一致。
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _YaoLineShape(yang: yang)),
        const SizedBox(width: 3),
        SizedBox(
          width: 15,
          height: double.infinity,
          child: movingMarker == null
              ? null
              : Text(
                  movingMarker!,
                  key: Key('moving-marker-$position'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _cinnabar,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
        ),
      ],
    );
  }
}

class _YaoLineShape extends StatelessWidget {
  const _YaoLineShape({super.key, required this.yang});

  final bool yang;

  /// 阴爻、阳爻、本卦、变卦使用同一线高与间隙，保证视觉粗细一致。
  static const double _lineHeight = 4;
  static const double _yinGap = 5;

  @override
  Widget build(BuildContext context) {
    final segment = Container(
      height: _lineHeight,
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(2),
      ),
    );
    if (yang) return Center(child: segment);
    return Row(
      children: [
        Expanded(child: segment),
        const SizedBox(width: _yinGap),
        Expanded(child: segment),
      ],
    );
  }
}

String _displaySixGod(String value) => value == '腾蛇' ? '螣蛇' : value;

String _shortPosition(int position) =>
    const ['初', '二', '三', '四', '五', '上'][position - 1];

Color _stemColor(String stem) => _elementColor(
  const {
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
      }[stem] ??
      '',
);

Color _branchColor(String branch) => _elementColor(
  const {
        '亥': '水',
        '子': '水',
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
      }[branch] ??
      '',
);

Color _elementColor(String element) => switch (element) {
  '木' => LiuyaoColors.wood,
  '火' => LiuyaoColors.fire,
  '土' => LiuyaoColors.earth,
  '金' => LiuyaoColors.metal,
  '水' => LiuyaoColors.water,
  _ => _mutedInk,
};

class _CalculationDetails extends StatelessWidget {
  const _CalculationDetails({required this.preview});

  final CastPreview preview;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('chart-calculation-details'),
      color: _paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _rule),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 14, 14, 4),
            child: Text(
              '计算明细',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, 7),
            child: Text(
              '展开可核对输入、查表过程与逐爻结果',
              style: TextStyle(color: _mutedInk, fontSize: 10),
            ),
          ),
          ...preview.calculationTrace.map(
            (trace) => ExpansionTile(
              key: Key('trace-${trace.ruleId}-${trace.label}'),
              dense: true,
              tilePadding: const EdgeInsets.symmetric(horizontal: 14),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 13),
              title: Text(
                trace.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                '${trace.ruleId} · v${trace.ruleVersion}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _mutedInk, fontSize: 9),
              ),
              children: [
                ...List.generate(
                  trace.steps.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 20,
                          child: Text(
                            '${index + 1}.',
                            style: const TextStyle(
                              color: _cinnabar,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            trace.steps[index],
                            style: const TextStyle(fontSize: 11, height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (trace.sourceIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '来源 ${trace.sourceIds.join(' / ')}',
                        style: const TextStyle(color: _mutedInk, fontSize: 9),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
