import 'package:flutter/material.dart';
import 'package:liuyao_engine/liuyao_engine.dart' as engine;

import '../../ui/design_system/components/ds_segmented_control.dart';
import '../../ui/design_system/tokens/ds_theme_extension.dart';
import '../../ui/design_system/tokens/ds_typography.dart';
import '../../ui/liuyao_design.dart';
import 'casting_models.dart';

/// v1.1 信号配给制：动爻 / 世应标记统一朱红（线框图主强调）。
const _mansionInk = LiuyaoColors.metal;

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
  bool _showNaYin = true;
  bool _showTwelveGrowth = true;
  bool _showFiveStars = true;
  bool _show28Mansions = true;
  bool _showAlmanacCalendar = false;

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
            showNaYin: _showNaYin,
            showTwelveGrowth: _showTwelveGrowth,
            showFiveStars: _showFiveStars,
            show28Mansions: _show28Mansions,
          ),
          footer: Column(
            children: [
              LiuyaoLineAnnotationsToggle(
                showNaYin: _showNaYin,
                onChangedNaYin: (v) => setState(() => _showNaYin = v),
                showTwelveGrowth: _showTwelveGrowth,
                onChangedTwelveGrowth: (v) =>
                    setState(() => _showTwelveGrowth = v),
                showFiveStars: _showFiveStars,
                onChangedFiveStars: (v) => setState(() => _showFiveStars = v),
                show28Mansions: _show28Mansions,
                onChanged28Mansions: (v) => setState(() => _show28Mansions = v),
                showAlmanacCalendar: _showAlmanacCalendar,
                onToggleAlmanacCalendar: () => setState(
                  () => _showAlmanacCalendar = !_showAlmanacCalendar,
                ),
              ),
              if (_showAlmanacCalendar)
                LiuyaoMiniAlmanacCalendar(initialMonth: preview.castAt),
            ],
          ),
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
              minimumSize: const Size.fromHeight(44),
              backgroundColor: context.ds.celadon,
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
          style: TextStyle(
            color: context.lc.inkMuted,
            fontSize: 10,
            height: 1.45,
          ),
        ),
        Text(
          archived
              ? '此处展示的是起卦时保存的完整快照，后续规则升级不会改写本档案。'
              : '保存后将原样写入档案；时间边界与传统主来源仍按文档中的临时口径显示。',
          style: TextStyle(
            color: context.lc.inkMuted,
            fontSize: 10,
            height: 1.45,
          ),
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

/// 卦面爻位标注参照选择底部弹窗：年月日时柱 / 五行主体 / 京房五星。
class LiuyaoGrowthReferenceSheet extends StatelessWidget {
  const LiuyaoGrowthReferenceSheet({
    super.key,
    required this.currentReference,
    required this.currentMode,
  });

  final String currentReference;
  final String currentMode;

  static const _pillarChoices = [
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
  ];

  /// 五行主体：以所选五行为主体观察各爻支（木在亥长生、在卯帝旺…）。
  static const _elementChoices = [
    LiuyaoGrowthReferenceChoice(
      label: '木',
      reference: 'element:木',
      mode: 'twelve_growth',
    ),
    LiuyaoGrowthReferenceChoice(
      label: '火',
      reference: 'element:火',
      mode: 'twelve_growth',
    ),
    LiuyaoGrowthReferenceChoice(
      label: '土',
      reference: 'element:土',
      mode: 'twelve_growth',
    ),
    LiuyaoGrowthReferenceChoice(
      label: '金',
      reference: 'element:金',
      mode: 'twelve_growth',
    ),
    LiuyaoGrowthReferenceChoice(
      label: '水',
      reference: 'element:水',
      mode: 'twelve_growth',
    ),
  ];

  static const _starChoice = LiuyaoGrowthReferenceChoice(
    label: '京房五星',
    reference: 'five_stars',
    mode: 'five_stars',
  );

  Widget _choiceRow(BuildContext context, LiuyaoGrowthReferenceChoice choice) {
    final checked =
        choice.mode == currentMode &&
        (choice.mode == 'five_stars' || choice.reference == currentReference);
    return ListTile(
      key: Key('growth-choice-${choice.reference}'),
      dense: true,
      leading: Icon(
        choice.mode == 'five_stars' ? Icons.star_outline : Icons.grain,
        size: 18,
        color: context.ds.celadon,
      ),
      title: Text(
        choice.label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      trailing: checked
          ? Icon(Icons.check, size: 18, color: context.ds.celadon)
          : null,
      onTap: () => Navigator.pop(context, choice),
    );
  }

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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '年月日时柱以柱支为参照；五行以所选五行为主体观察各爻支；京房五星切换标注类型',
              style: TextStyle(
                color: context.lc.inkMuted,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 6, 20, 2),
            child: Text(
              '四柱参照',
              style: TextStyle(color: context.lc.inkMuted, fontSize: 11),
            ),
          ),
          for (final choice in _pillarChoices) _choiceRow(context, choice),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 6, 20, 2),
            child: Text(
              '五行主体（木在亥长生、在卯帝旺…）',
              style: TextStyle(color: context.lc.inkMuted, fontSize: 11),
            ),
          ),
          for (final choice in _elementChoices) _choiceRow(context, choice),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _choiceRow(context, _starChoice),
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

/// 卦面信息显示开关：纳音/十二长生/五星/二十八宿四个统一规格小开关，
/// 单行紧促排列，嵌在卦面卡片最底部一行（不再有独立大卡与总开关）。
/// 尾部附带「万年历」入口，点击在下方展开内嵌月历。
class LiuyaoLineAnnotationsToggle extends StatelessWidget {
  const LiuyaoLineAnnotationsToggle({
    super.key,
    required this.showNaYin,
    required this.onChangedNaYin,
    required this.showTwelveGrowth,
    required this.onChangedTwelveGrowth,
    required this.showFiveStars,
    required this.onChangedFiveStars,
    required this.show28Mansions,
    required this.onChanged28Mansions,
    this.showAlmanacCalendar = false,
    this.onToggleAlmanacCalendar,
  });

  final bool showNaYin;
  final ValueChanged<bool> onChangedNaYin;
  final bool showTwelveGrowth;
  final ValueChanged<bool> onChangedTwelveGrowth;
  final bool showFiveStars;
  final ValueChanged<bool> onChangedFiveStars;
  final bool show28Mansions;
  final ValueChanged<bool> onChanged28Mansions;
  final bool showAlmanacCalendar;
  final VoidCallback? onToggleAlmanacCalendar;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('line-annotations-toggle'),
      children: [
        Expanded(
          child: _annotationChip(
            context,
            label: '纳音',
            selected: showNaYin,
            onChanged: onChangedNaYin,
            key: const Key('show-nayin'),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _annotationChip(
            context,
            label: '长生',
            selected: showTwelveGrowth,
            onChanged: onChangedTwelveGrowth,
            key: const Key('show-twelve-growth'),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _annotationChip(
            context,
            label: '五星',
            selected: showFiveStars,
            onChanged: onChangedFiveStars,
            key: const Key('show-five-stars'),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _annotationChip(
            context,
            label: '星宿',
            selected: show28Mansions,
            onChanged: onChanged28Mansions,
            key: const Key('show-28-mansions'),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _annotationChip(
            context,
            label: '万年历',
            selected: showAlmanacCalendar,
            onChanged: onToggleAlmanacCalendar == null
                ? null
                : (_) => onToggleAlmanacCalendar!(),
            key: const Key('show-almanac-calendar'),
          ),
        ),
      ],
    );
  }

  Widget _annotationChip(
    BuildContext context, {
    required String label,
    required bool selected,
    ValueChanged<bool>? onChanged,
    required Key key,
  }) {
    return Material(
      color: selected ? context.ds.celadon : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        key: key,
        onTap: onChanged == null ? null : () => onChanged(!selected),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? context.ds.celadon : context.lc.inkFaint,
              width: .8,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 10,
              height: 1.0,
              color: selected ? Colors.white : context.lc.inkMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
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
    this.footer,
  });

  final CastPreview preview;
  final Widget? footer;
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
        growthReference: growthReference,
        onGrowthTap: onGrowthTap,
        annotationMode: annotationMode,
        visibility: visibility,
        footer: footer,
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
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: context.ds.glowCinnabar,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: context.ds.celadon.withValues(alpha: .25)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.history_rounded, color: context.ds.celadon),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '这是 schema v${preview.schemaVersion} 历史档案。当前按原始快照只读展示；'
            '旧合同未保存的卦码、上下卦、十二长生、神煞和计算明细不会补算。',
            style: TextStyle(color: context.lc.ink, fontSize: 11, height: 1.5),
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: context.ds.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.ds.hairline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '神煞与身命标注',
                style: DSTypography.body(
                  fontSize: 15,
                  weight: FontWeight.w600,
                  color: context.ds.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '逐项冻结 · 不作吉凶评分',
                  style: DSTypography.body(
                    fontSize: 10,
                    weight: FontWeight.w400,
                    color: context.ds.textMuted,
                  ),
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
        color: matched ? context.ds.glassWeak : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: matched ? context.ds.glowJade : context.ds.hairline,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: matched ? context.ds.celadon : context.ds.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.ds.hairline, width: 1),
            ),
            child: Text(
              label,
              style: DSTypography.body(
                fontSize: 11,
                weight: FontWeight.w600,
                color: matched ? Colors.white : context.ds.textMuted,
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
                  style: DSTypography.body(
                    fontSize: 12,
                    weight: FontWeight.w600,
                    color: context.ds.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: DSTypography.body(
                    fontSize: 10,
                    weight: FontWeight.w400,
                    color: matched
                        ? context.ds.textSecondary
                        : context.ds.textMuted,
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
        color: matched ? context.ds.glassWeak : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: matched ? context.ds.glowJade : context.ds.hairline,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: matched ? context.ds.celadon : context.ds.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.ds.hairline, width: 1),
            ),
            child: Text(
              result.displayName,
              style: DSTypography.body(
                fontSize: 11,
                weight: FontWeight.w600,
                color: matched ? Colors.white : context.ds.textMuted,
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
                  style: DSTypography.body(
                    fontSize: 12,
                    weight: FontWeight.w600,
                    color: context.ds.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  matchText,
                  style: DSTypography.body(
                    fontSize: 10,
                    weight: FontWeight.w400,
                    color: matched
                        ? context.ds.textSecondary
                        : context.ds.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            matched ? Icons.adjust_rounded : Icons.remove_circle_outline,
            color: matched ? context.ds.jade : context.ds.textFaint,
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

  /// 参照 chip：四柱排与五行排共用；等宽排布，选中青瓷底。
  static Widget _referenceChip(
    BuildContext context,
    MapEntry<String, String> entry,
    String selectedReference,
    ValueChanged<String> onReferenceChanged,
  ) {
    final selected = selectedReference == entry.key;
    return Center(
      child: ChoiceChip(
        key: Key('growth-reference-${entry.key}'),
        label: Text(entry.value),
        selected: selected,
        onSelected: (_) => onReferenceChanged(entry.key),
        labelStyle: TextStyle(
          fontSize: 10,
          color: selected ? Colors.white : context.ds.textSecondary,
        ),
        selectedColor: context.ds.celadon,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  final CastPreview preview;
  final String selectedReference;
  final ValueChanged<String> onReferenceChanged;
  final String annotationMode;
  final ValueChanged<String> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final rule = preview.annotations.fiveElementTwelveStages;
    final results = rule.lineResults.reversed.toList(growable: false);
    final baseByPosition = {
      for (final line in preview.chart.base.lines) line.position: line,
    };
    const pillarLabels = <String, String>{
      'year': '年柱',
      'month': '月柱',
      'day': '日柱',
      'hour': '时柱',
    };
    const elementLabels = <String, String>{
      'element:木': '木',
      'element:火': '火',
      'element:土': '土',
      'element:金': '金',
      'element:水': '水',
    };
    return Container(
      key: const Key('twelve-stages-ledger'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: context.ds.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.ds.hairline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '卦面标注',
            style: DSTypography.body(
              fontSize: 15,
              weight: FontWeight.w600,
              color: context.ds.textPrimary,
            ),
          ),
          Text(
            '切换标注类型，卦面小字同步刷新',
            style: DSTypography.body(
              fontSize: 10,
              weight: FontWeight.w400,
              color: context.ds.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          DSSegmentedControl<String>(
            keyOverride: const Key('annotation-mode-switch'),
            segments: const [
              DSSegmentItem(
                value: 'twelve_growth',
                label: '十二长生',
                icon: Icons.grain,
              ),
              DSSegmentItem(
                value: 'five_stars',
                label: '京房五星',
                icon: Icons.star_outline,
              ),
            ],
            selected: {annotationMode},
            onSelectionChanged: (selection) {
              onModeChanged(selection.first);
            },
          ),
          const SizedBox(height: 10),
          if (annotationMode == 'five_stars')
            _FiveStarsLedger(preview: preview)
          else ...[
            // 参照分两排：四柱一排、五行一排（2026-09-01 需求）。
            Row(
              children: [
                for (final entry in pillarLabels.entries)
                  Expanded(
                    child: _referenceChip(
                      context,
                      entry,
                      selectedReference,
                      onReferenceChanged,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (final entry in elementLabels.entries)
                  Expanded(
                    child: _referenceChip(
                      context,
                      entry,
                      selectedReference,
                      onReferenceChanged,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _TwelveStagesHeader(selectedReference: selectedReference),
            const SizedBox(height: 4),
            ...results.map((result) {
              final branch =
                  baseByPosition[result.position]?.najia.earthlyBranch ?? '';
              return _TwelveStagesRow(
                result: result,
                selectedReference: selectedReference,
                lineBranch: branch,
              );
            }),
            Padding(
              padding: EdgeInsets.fromLTRB(2, 8, 2, 0),
              child: Text(
                '受气与化绝：四土独立表中的受气对应绝位，详见计算明细。',
                style: TextStyle(
                  color: context.lc.inkMuted,
                  fontSize: 9,
                  height: 1.4,
                ),
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
          color: context.lc.parchment,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '该档案未保存京房五星数据。',
          style: TextStyle(color: context.lc.inkMuted, fontSize: 11),
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
            color: context.ds.glowCeladon,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.ds.metalLine),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${hexagram.name} · ${hexagram.palaceName}宫第${hexagram.palaceSequence}卦',
                style: DSTypography.body(
                  fontSize: 13,
                  weight: FontWeight.w600,
                  color: context.ds.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '世爻${world.positionName}起${world.starName}；应爻${response.positionName}为克制星'
                '${response.starName}',
                style: DSTypography.body(
                  fontSize: 10,
                  weight: FontWeight.w400,
                  color: context.ds.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: context.ds.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.ds.hairline, width: 1),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(12, 8, 12, 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: Text(
                        '爻位',
                        style: TextStyle(
                          color: context.lc.inkMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text('五星', style: _fiveStarsHeaderStyle(context)),
                    ),
                    Expanded(
                      child: Text('五行', style: _fiveStarsHeaderStyle(context)),
                    ),
                    SizedBox(
                      width: 44,
                      child: Text('角色', style: _fiveStarsHeaderStyle(context)),
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
                      top: BorderSide(
                        color: context.lc.inkFaint.withValues(alpha: .5),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        child: Text(
                          positionNames[placement.position - 1],
                          style: TextStyle(
                            color: context.lc.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          placement.starName,
                          style: TextStyle(
                            color: _elementStarColor(
                              context,
                              placement.element,
                            ),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          placement.element,
                          style: TextStyle(
                            color: context.lc.inkMuted,
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
                                ? context.ds.celadon
                                : context.lc.inkMuted,
                            fontSize: 11,
                            fontWeight:
                                placement.role == '世' || placement.role == '应'
                                ? FontWeight.w600
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

  static TextStyle _fiveStarsHeaderStyle(BuildContext context) => TextStyle(
    color: context.lc.inkMuted,
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
        SizedBox(
          width: 49,
          child: Text('爻 / 行', style: _stageHeaderStyle(context)),
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
    required this.lineBranch,
  });

  final TwelveStageLineResult result;
  final String selectedReference;

  /// 该爻地支：五行主体列按「主体=五行、观察支=爻支」现算，
  /// 旧档案冻结的反向语义数据读取时被校正。
  final String lineBranch;

  TwelveStagePillarResult _correctedElement(TwelveStagePillarResult item) {
    final element = item.reference.substring('element:'.length);
    final growth = engine.lookupElementGrowth(element, lineBranch);
    return TwelveStagePillarResult(
      reference: item.reference,
      referenceLabel: item.referenceLabel,
      pillarGanZhi: item.pillarGanZhi,
      referenceBranch: lineBranch,
      stage: (growth['display_phases'] as List).join('、'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fourPillars = result.pillarResults
        .where((item) => _fourPillarRefs.contains(item.reference))
        .toList(growable: false);
    final selectedElement = result.pillarResults
        .where((item) => item.reference == selectedReference)
        .where((item) => item.reference.startsWith('element:'))
        .map(_correctedElement)
        .firstOrNull;
    return Container(
      key: Key('twelve-stage-${result.lineId}'),
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.ds.hairline)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 49,
            child: Text(
              '${result.positionName.replaceAll('爻', '')} · ${result.lineElement}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
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
      color: emphasized ? context.ds.glowCinnabar : context.lc.parchment,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        Text(
          item.referenceBranch,
          style: TextStyle(
            color: emphasized ? context.ds.celadon : context.lc.inkMuted,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          item.stage,
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: TextStyle(
            color: context.lc.ink,
            fontSize: 10,
            fontWeight: FontWeight.w600,
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

TextStyle _stageHeaderStyle(BuildContext context) => TextStyle(
  color: context.lc.inkMuted,
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
      style: _stageHeaderStyle(
        context,
      ).copyWith(color: emphasized ? context.ds.celadon : context.lc.inkMuted),
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
    // 卦属性（六冲/六合/游魂/归魂）只在下方 MetaTag 行显示一次，宫位行不再重复。
    final palaceType = switch (base.palaceSequence) {
      7 => '游魂卦',
      8 => '归魂卦',
      _ => null,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: context.ds.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.ds.hairline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            changed == null
                ? '${base.name} · 静卦'
                : '${base.name} → ${changed.name}',
            style: DSTypography.displayLight(
              fontSize: 24,
              color: context.ds.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            preview.isLegacySnapshot
                ? '${base.palace.name}宫${base.palace.element} · $moving'
                : '${base.upperTrigram.name}上${base.lowerTrigram.name}下 · '
                      '${base.palace.name}宫${base.palace.element} · $moving',
            style: DSTypography.body(
              fontSize: 12,
              weight: FontWeight.w400,
              color: context.ds.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (base.hexagramProperty != null)
                _MetaTag(text: base.hexagramProperty!, emphasized: true),
              if (palaceType != null)
                _MetaTag(text: palaceType, emphasized: true),
              if (changed?.hexagramProperty != null)
                _MetaTag(
                  text: '变${changed!.hexagramProperty!}',
                  emphasized: true,
                ),
              if (base.shiPosition > 0)
                _MetaTag(text: '世在${_position(base.shiPosition)}'),
              if (base.yingPosition > 0)
                _MetaTag(text: '应在${_position(base.yingPosition)}'),
              if (base.code.isNotEmpty) _MetaTag(text: '卦码 ${base.code}'),
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

class _MetaTag extends StatelessWidget {
  const _MetaTag({required this.text, this.emphasized = false});

  final String text;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: emphasized ? context.ds.cinnabarSoft : context.ds.glassWeak,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: emphasized ? context.ds.cinnabar : context.ds.hairline,
          width: 1,
        ),
      ),
      child: Text(
        text,
        // 单汉字无等宽意义：等宽链缺中文字形，Android 会回退默认体
        // 造成基线漂移，统一走 sans 基准。
        style: DSTypography.body(
          fontSize: 10,
          weight: FontWeight.w600,
          height: 1.4,
          color: emphasized ? context.ds.cinnabar : context.ds.textSecondary,
        ),
      ),
    );
  }
}

class _ChartTable extends StatelessWidget {
  const _ChartTable({
    required this.preview,
    this.footer,
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
  final Widget? footer;
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
    Map<int, String> growthStages(
      FiveElementTwelveStages stages,
      String? Function(int position) branchOf,
    ) {
      final output = <int, String>{};
      // 五行主体参照（2026-09-01 语义修正）：展示层统一按
      // 「主体=所选五行、观察支=爻支」现算——旧档案冻结的是修正前的
      // 反向语义（火/土同值、土爻恒帝旺），读取时以引擎新表覆盖。
      final elementSubject = growthReference.startsWith('element:')
          ? growthReference.substring('element:'.length)
          : null;
      for (final result in stages.lineResults) {
        if (elementSubject != null) {
          final branch = branchOf(result.position);
          if (branch != null && branch.isNotEmpty) {
            output[result.position] =
                engine
                        .lookupElementGrowth(
                          elementSubject,
                          branch,
                        )['display_phases']
                        .join('、')
                    as String;
          }
          continue;
        }
        for (final pillar in result.pillarResults) {
          if (pillar.reference == growthReference) {
            output[result.position] = pillar.stage;
            break;
          }
        }
      }
      return output;
    }

    // 十二长生始终计算：五星不再挤占长生槽位，两者在爻位行并列独立显示，
    // annotationMode 只控制展开面板（长生账本 / 五星账本）的内容。
    final baseByPosition = {for (final line in base.lines) line.position: line};
    final hiddenByPosition = {
      for (final line in base.lines)
        if (line.hidden != null) line.position: line.hidden!,
    };

    Map<int, String> growthStagesOrEmpty(
      FiveElementTwelveStages stages,
      String? Function(int position) branchOf,
    ) => growthStages(stages, branchOf);

    final dayStageByPosition = growthStagesOrEmpty(
      preview.annotations.fiveElementTwelveStages,
      (position) => baseByPosition[position]?.najia.earthlyBranch,
    );
    final hiddenDayStageByPosition = hiddenAnnotations == null
        ? const <int, String>{}
        : growthStagesOrEmpty(
            hiddenAnnotations.fiveElementTwelveStages,
            (position) => hiddenByPosition[position]?.najia.earthlyBranch,
          );
    final changedDayStageByPosition = changedAnnotations == null
        ? const <int, String>{}
        : growthStagesOrEmpty(
            changedAnnotations.fiveElementTwelveStages,
            (position) => changedByPosition[position]?.najia.earthlyBranch,
          );
    return Container(
      key: const Key('liuyao-chart-table'),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 5),
      decoration: BoxDecoration(
        color: context.ds.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.ds.hairline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PillarContextPanel(preview: preview),
          const SizedBox(height: 8),
          _HexagramComparisonHeader(
            base: base,
            changed: preview.chart.changed,
            canonicalPalaceSequence: preview.hasCanonicalPalaceSequence,
          ),
          // 线框图卦面没有列头行：列含义由内容自明，删掉整行以贴近 29px 爻行。
          const SizedBox(height: 4),
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
          if (footer != null) ...[const SizedBox(height: 8), footer!],
        ],
      ),
    );
  }
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
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
      child: Column(
        children: [
          // 线框图四柱区只有两行居中文字：干支一行 + 旬空一行。
          // 「四柱/自动计算」标题行收进四柱首格的后缀提示，不再占独立行。
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
          const SizedBox(height: 2),
          Row(
            children: [
              for (final item in items)
                Expanded(
                  child: Text(
                    item.voidText == '未记录'
                        ? '未记录'
                        : '${_voidLabel(item.keyName)}:${item.voidText}',
                    key: Key('time-${item.keyName}-void'),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: DSTypography.body(
                      fontSize: 9,
                      weight: FontWeight.w400,
                      height: 1.4,
                      color: item.keyName == 'day'
                          ? context.ds.celadonDeep
                          : context.ds.textMuted,
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
      return Text(
        '未记录',
        textAlign: TextAlign.center,
        style: TextStyle(color: context.lc.inkMuted, fontSize: 10),
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
            style: DSTypography.body(
              fontSize: 13,
              weight: FontWeight.w400,
              height: 1.4,
              color: _stemColor(context, stem),
            ),
          ),
          Text(
            branch,
            key: Key('time-$keyName-branch'),
            style: DSTypography.body(
              fontSize: 13,
              weight: FontWeight.w400,
              height: 1.4,
              color: _branchColor(context, branch),
            ),
          ),
          Text(
            suffix,
            style: DSTypography.body(
              fontSize: 12,
              weight: FontWeight.w400,
              color: context.ds.textSecondary,
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
  });

  /// 卦属性合并标签：六冲/六合 + 游魂/归魂（京房八宫序 7/8），
  /// 各来源只取一次，null 自动跳过，不再重复拼接。
  static String? _propertyLabel(String? hexagramProperty, int palaceSequence) {
    final palaceType = switch (palaceSequence) {
      7 => '游魂',
      8 => '归魂',
      _ => null,
    };
    return [hexagramProperty, palaceType].whereType<String>().isEmpty
        ? null
        : [hexagramProperty, palaceType].whereType<String>().join(' · ');
  }

  final BaseHexagram base;
  final ChangedHexagram? changed;
  final bool canonicalPalaceSequence;

  @override
  Widget build(BuildContext context) {
    final changedHexagram = changed;
    return Column(
      children: [
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
                // 卦属性只在此显示一次：六冲/六合（引擎判定）+ 游魂/归魂（宫序 7/8）。
                property: _propertyLabel(
                  base.hexagramProperty,
                  base.palaceSequence,
                ),
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
                property: _propertyLabel(
                  changedHexagram?.hexagramProperty,
                  changedHexagram?.palaceSequence ?? 0,
                ),
              ),
            ),
          ],
        ),
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
    this.property,
  });

  final String label;
  final String name;
  final TrigramSummary? palace;
  final int palaceSequence;
  final String? property;

  @override
  Widget build(BuildContext context) {
    final propertySuffix = property == null ? '' : '（$property）';
    final palaceText = palace == null
        ? '卦宫未记录'
        : palaceSequence > 0
        ? '/ ${palace!.name}宫·$palaceSequence$propertySuffix'
        : '${palace!.name}宫 · 序位未记录$propertySuffix';
    // 线框图卦名区为紧凑两层结构：卦名（带「本卦/变卦」行内小字前缀）
    // 与宫位属性行，不再单独占一层标题，压缩卦面头部高度。
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                label,
                style: DSTypography.tableHeader(color: context.ds.textMuted),
              ),
              const SizedBox(width: 4),
              Text(
                name,
                maxLines: 1,
                style: DSTypography.displayLight(
                  fontSize: 13,
                  color: context.ds.textPrimary,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 1),
        Text(
          palaceText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DSTypography.body(
            fontSize: 9,
            weight: FontWeight.w500,
            color: palace == null
                ? context.ds.textMuted
                : _elementColor(context, palace!.element),
          ),
        ),
      ],
    );
  }
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
    // 线框图中的每一爻是短行：主信息与附加字段同一紧凑基线内展示。
    final hidden = line.hidden;
    return Container(
      key: Key('chart-line-${line.position}'),
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
      decoration: BoxDecoration(
        color: line.changing ? context.ds.glowCinnabar : Colors.transparent,
        border: line.changing
            ? Border(
                left: BorderSide(color: context.ds.celadon, width: 2),
                bottom: BorderSide(color: context.ds.hairline),
              )
            : Border(
                bottom: BorderSide(
                  color: line.position == 4
                      ? context.ds.hairlineStrong
                      : context.ds.hairline,
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Text(
                  _displaySixGod(line.sixGod),
                  key: Key('six-god-${line.position}'),
                  style: DSTypography.body(
                    fontSize: 11,
                    weight: FontWeight.w700,
                    color: _sixGodColor(context, line.sixGod),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _shortPosition(line.position),
                  style: DSTypography.body(
                    fontSize: 8,
                    weight: FontWeight.w400,
                    color: context.ds.textMuted,
                  ),
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
            width: 42,
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
                const SizedBox(height: 1),
                Text(
                  line.role ?? '',
                  textAlign: TextAlign.center,
                  style: DSTypography.body(
                    fontSize: 9,
                    weight: FontWeight.w600,
                    color: line.role == '世'
                        ? context.ds.celadonDeep
                        : line.role == '应'
                        ? context.ds.textFaint
                        : Colors.transparent,
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
            width: 42,
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
                      const SizedBox(height: 1),
                      Text(
                        changed!.role ?? '',
                        key: Key('changed-role-${line.position}'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: changed!.role == '世'
                              ? context.ds.celadonDeep
                              : changed!.role == '应'
                              ? context.ds.textFaint
                              : Colors.transparent,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
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
  Widget build(BuildContext context) => Text(
    '·',
    textAlign: TextAlign.center,
    style: TextStyle(color: context.lc.inkMuted, fontSize: 12),
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
              style: DSTypography.body(
                fontSize: 12,
                weight: FontWeight.w600,
                color: muted ? context.ds.textMuted : context.ds.textPrimary,
              ),
            ),
            const SizedBox(width: 1),
            Text(
              najia.heavenlyStem,
              key: Key('$prefix-stem-$position'),
              style: DSTypography.body(
                fontSize: 12,
                weight: FontWeight.w700,
                height: 1.4,
                color: _stemColor(context, najia.heavenlyStem),
              ),
            ),
            Text(
              najia.earthlyBranch,
              key: Key('$prefix-branch-$position'),
              style: DSTypography.body(
                fontSize: 12,
                weight: FontWeight.w700,
                height: 1.4,
                color: _branchColor(context, najia.earthlyBranch),
              ),
            ),
          ],
        ),
      ),
      ..._annotationRow(context),
    ],
  );

  /// 爻位标注行（纳音 · 十二长生 · 五星 · 二十八宿）；无任何可见片段时返回空。
  List<Widget> _annotationRow(BuildContext context) {
    final segments = _buildAnnotationSegments(context);
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
  /// 十二长生与五星并列独立显示（各自受开关控制），annotationMode
  /// 只决定点击弹窗与展开面板的默认参照，不再互相挤占槽位。
  List<Widget> _buildAnnotationSegments(BuildContext context) {
    final segments = <Widget>[];
    if (visibility.showNaYin) {
      final nayin = najia.nayin ?? '';
      final nayinColor = _nayinColor(context, nayin);
      segments.add(
        Text(
          nayin,
          key: Key('$prefix-nayin-$position'),
          style: _annotationTextStyle(
            color: muted ? nayinColor.withValues(alpha: .55) : nayinColor,
            bold: false,
          ),
        ),
      );
    }
    final growthSlotVisible = visibility.showTwelveGrowth;
    if (growthSlotVisible && growthStage != null) {
      segments.add(_segmentDot(context));
      final growthText = Text(
        growthStage!,
        key: Key('$prefix-growth-$position'),
        style: _annotationTextStyle(color: context.lc.inkMuted, bold: true),
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
                      color: muted ? context.lc.inkMuted : context.ds.celadon,
                      bold: true,
                      underline: true,
                    ),
                  ),
                ),
              ),
      );
    }
    if (visibility.showFiveStars && fiveStar != null) {
      segments.add(_segmentDot(context));
      segments.add(
        Text(
          _fiveStarDisplayName(fiveStar!.star),
          key: Key('$prefix-fivestar-$position'),
          style: _annotationTextStyle(
            color: _elementStarColor(context, fiveStar!.element),
            bold: true,
          ),
        ),
      );
    }
    if (visibility.show28Mansions && mansion != null) {
      segments.add(_segmentDot(context));
      segments.add(
        Semantics(
          label: '${mansion!.mansion}宿，${mansion!.placementRole}装配',
          child: Text(
            mansion!.mansion,
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

  static Widget _segmentDot(BuildContext context) =>
      Text('·', style: TextStyle(color: context.lc.inkMuted, fontSize: 7));

  static TextStyle _annotationTextStyle({
    required Color color,
    required bool bold,
    bool underline = false,
  }) => TextStyle(
    color: color,
    fontSize: 7.5,
    // 修复：原三元两分支同为 w600；爻位标注加粗段升至 w700，
    // 配合加深的五行色，保证小字号下依然清晰可辨。
    fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
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
Color _elementStarColor(BuildContext context, String element) =>
    switch (element) {
      '木' => LiuyaoColors.wood,
      '火' => LiuyaoColors.fire,
      '土' => LiuyaoColors.earth,
      '金' => LiuyaoColors.metal,
      '水' => LiuyaoColors.water,
      _ => context.lc.ink,
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
                  style: DSTypography.body(
                    fontSize: 11,
                    weight: FontWeight.w600,
                    color: context.ds.celadon,
                    height: 1.0,
                  ),
                ),
        ),
      ],
    );
  }
}

class _YaoLineShape extends StatelessWidget {
  const _YaoLineShape({required this.yang});

  final bool yang;

  /// 阴爻、阳爻、本卦、变卦使用同一线高与间隙，保证视觉粗细一致。
  static const double _lineHeight = 5;
  static const double _yinGap = 5;

  @override
  Widget build(BuildContext context) {
    final segment = Container(
      height: _lineHeight,
      decoration: BoxDecoration(
        color: context.lc.ink,
        borderRadius: BorderRadius.circular(1.5),
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

/// 旬空柱名前缀：年空 / 月空 / 日空 / 时空。
String _voidLabel(String keyName) => switch (keyName) {
  'year' => '年空',
  'month' => '月空',
  'day' => '日空',
  _ => '时空',
};

/// 六神按五行配色（线框图契约）：青龙木绿、朱雀火红、白虎金、玄武水蓝、
/// 勾陈/腾蛇（螣蛇）土褐。未识别值回退墨色。
Color _sixGodColor(BuildContext context, String value) => switch (value) {
  '青龙' => LiuyaoColors.wood,
  '朱雀' => LiuyaoColors.fire,
  '白虎' => LiuyaoColors.metal,
  '玄武' => LiuyaoColors.water,
  '勾陈' || '腾蛇' || '螣蛇' => LiuyaoColors.earth,
  _ => context.lc.ink,
};

String _shortPosition(int position) =>
    const ['初', '二', '三', '四', '五', '上'][position - 1];

Color _stemColor(BuildContext context, String stem) => _elementColor(
  context,
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

Color _branchColor(BuildContext context, String branch) => _elementColor(
  context,
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

Color _elementColor(BuildContext context, String element) => switch (element) {
  '木' => LiuyaoColors.wood,
  '火' => LiuyaoColors.fire,
  '土' => LiuyaoColors.earth,
  '金' => LiuyaoColors.metal,
  '水' => LiuyaoColors.water,
  _ => context.lc.inkMuted,
};

/// 纳音五行配色：纳音名（如「大海水」「炉中火」）以五行字结尾，
/// 取尾字映射五行色；无法识别时回退墨色。空值保持墨色以兼容旧数据。
Color _nayinColor(BuildContext context, String nayin) {
  if (nayin.isEmpty) return context.lc.inkMuted;
  final last = String.fromCharCode(nayin.runes.last);
  const elements = {'木', '火', '土', '金', '水'};
  return elements.contains(last)
      ? _elementColor(context, last)
      : context.lc.inkMuted;
}

class _CalculationDetails extends StatelessWidget {
  const _CalculationDetails({required this.preview});

  final CastPreview preview;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('chart-calculation-details'),
      color: context.ds.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.ds.hairline, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              '计算明细',
              style: DSTypography.body(
                fontSize: 15,
                weight: FontWeight.w600,
                color: context.ds.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 7),
            child: Text(
              '展开可核对输入、查表过程与逐爻结果',
              style: DSTypography.body(
                fontSize: 10,
                weight: FontWeight.w400,
                color: context.ds.textMuted,
              ),
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
                style: DSTypography.body(
                  fontSize: 13,
                  weight: FontWeight.w600,
                  color: context.ds.textPrimary,
                ),
              ),
              subtitle: Text(
                '${trace.ruleId} · v${trace.ruleVersion}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.lc.inkMuted, fontSize: 9),
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
                            style: TextStyle(
                              color: context.ds.celadon,
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
                        style: TextStyle(
                          color: context.lc.inkMuted,
                          fontSize: 9,
                        ),
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

/// 卦面内嵌万年历：点击「万年历」在开关行下方展开的轻量月历。
/// 每个日期格显示公历日 + 农历（初一显示月名，节气日优先显示节气）；
/// 选中日在网格下方给出农历全称、日柱干支（五行分色）、纳音与节气/值宿摘要。
class LiuyaoMiniAlmanacCalendar extends StatefulWidget {
  const LiuyaoMiniAlmanacCalendar({super.key, this.initialMonth});

  /// 展开时默认显示并选中的日期（默认为起卦时间，缺省为今天所在月）。
  final DateTime? initialMonth;

  @override
  State<LiuyaoMiniAlmanacCalendar> createState() =>
      _LiuyaoMiniAlmanacCalendarState();
}

class _LiuyaoMiniAlmanacCalendarState extends State<LiuyaoMiniAlmanacCalendar> {
  late DateTime _month;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMonth;
    if (initial == null) {
      final now = DateTime.now();
      _month = DateTime(now.year, now.month);
      _selectedDay = DateTime(now.year, now.month, now.day);
    } else {
      _month = DateTime(initial.year, initial.month);
      _selectedDay = DateTime(initial.year, initial.month, initial.day);
    }
  }

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isCurrentMonth =
        _month.year == today.year && _month.month == today.month;
    final firstDay = DateTime(_month.year, _month.month);
    // 周一为首列：周一=0 … 周日=6。
    final leading = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final trailing = (7 - (leading + daysInMonth) % 7) % 7;
    final cells = <DateTime?>[
      for (var i = 0; i < leading; i++) null,
      for (var day = 1; day <= daysInMonth; day++)
        DateTime(_month.year, _month.month, day),
      for (var i = 0; i < trailing; i++) null,
    ];
    return Container(
      key: const Key('mini-almanac-calendar'),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: context.lc.parchment,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.lc.inkFaint, width: .8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _monthArrow(Icons.chevron_left, -1, const Key('mini-cal-prev')),
              Expanded(
                child: Text(
                  '${_month.year}年${_month.month.toString().padLeft(2, '0')}月',
                  key: const Key('mini-cal-title'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.lc.ink,
                  ),
                ),
              ),
              _monthArrow(Icons.chevron_right, 1, const Key('mini-cal-next')),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              for (final label in const ['一', '二', '三', '四', '五', '六', '日'])
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: context.lc.inkMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          for (var week = 0; week < cells.length / 7; week++)
            Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: _dayCell(
                      cells[week * 7 + col],
                      isCurrentMonth: isCurrentMonth,
                      today: today,
                    ),
                  ),
              ],
            ),
          if (_selectedDay != null) ...[
            Divider(height: 14, thickness: .7, color: context.lc.inkFaint),
            _selectedDaySummary(_selectedDay!),
          ],
        ],
      ),
    );
  }

  Widget _monthArrow(IconData icon, int delta, Key key) => SizedBox.square(
    dimension: 30,
    child: IconButton(
      key: key,
      onPressed: () => _shiftMonth(delta),
      padding: EdgeInsets.zero,
      iconSize: 20,
      icon: Icon(icon, color: context.ds.celadon),
    ),
  );

  /// 格子副行文案：节气优先（朱红），其次农历日（初一显示月名，含闰月）。
  /// 引擎支持范围（1901-02-19 ~ 2100-02-08）之外返回 null，只显示公历数字。
  ({String label, bool isTerm})? _cellSubLabel(DateTime day) {
    if (!engine.isLunarSupported(day)) return null;
    final term = engine.getSolarTerm(day);
    if (term != null && term.isNotEmpty) {
      return (label: term, isTerm: true);
    }
    final lunar = engine.solarToLunar(day);
    return (label: lunar.day == 1 ? lunar.monthCn : lunar.dayCn, isTerm: false);
  }

  Widget _dayCell(
    DateTime? day, {
    required bool isCurrentMonth,
    required DateTime today,
  }) {
    if (day == null) {
      return const SizedBox(height: 36);
    }
    final isToday =
        isCurrentMonth &&
        day.year == today.year &&
        day.month == today.month &&
        day.day == today.day;
    final selected = _selectedDay == day;
    final sub = _cellSubLabel(day);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selectedDay = day),
      child: Container(
        height: 36,
        margin: const EdgeInsets.symmetric(vertical: 1),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? context.ds.celadon : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isToday && !selected
              ? Border.all(
                  color: context.ds.celadon.withValues(alpha: .6),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              key: Key('mini-cal-day-${day.year}-${day.month}-${day.day}'),
              style: TextStyle(
                fontSize: 10.5,
                height: 1.05,
                color: selected
                    ? Colors.white
                    : isToday
                    ? context.ds.celadon
                    : context.lc.ink,
                fontWeight: isToday || selected
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
            if (sub != null)
              Text(
                sub.label,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  fontSize: 7.5,
                  height: 1.1,
                  color: selected
                      ? Colors.white
                      : sub.isTerm
                      ? context.ds.celadon
                      : context.lc.inkMuted,
                  fontWeight: sub.isTerm || selected
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 选中日摘要：农历全称 + 生肖 ｜ 日柱干支（五行分色）+ 纳音，附节气/值宿。
  Widget _selectedDaySummary(DateTime day) {
    if (!engine.isLunarSupported(day)) {
      return Text(
        '超出万年历支持范围（1901-02-19 ~ 2100-02-08）',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 9.5, color: context.lc.inkMuted),
      );
    }
    final lunar = engine.solarToLunar(day);
    final pillar = engine.calculateDayGanzhi(day);
    final nayin = engine.getNayin(pillar);
    final term = engine.getSolarTerm(day);
    final mansion = engine.calculateDailyMansion(day);
    final leapPrefix = lunar.isLeapMonth ? '闰' : '';
    final extras = [
      if (term != null && term.isNotEmpty) '节气 $term',
      '值宿 $mansion',
    ];
    return Container(
      key: const Key('mini-cal-detail'),
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
      decoration: BoxDecoration(
        color: context.lc.parchment,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.lc.inkFaint, width: .7),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '农历',
                      style: TextStyle(
                        fontSize: 8.5,
                        color: context.lc.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      key: const Key('mini-cal-detail-lunar'),
                      '${lunar.yearCn ?? '${lunar.year}年'}年 $leapPrefix${lunar.monthCn}${lunar.dayCn}'
                      '${lunar.zodiac == null ? '' : ' · ${lunar.zodiac}年'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.lc.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: .7, height: 26, color: context.lc.inkFaint),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '日柱',
                      style: TextStyle(
                        fontSize: 8.5,
                        color: context.lc.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text.rich(
                          key: const Key('mini-cal-detail-pillar'),
                          TextSpan(
                            children: [
                              TextSpan(
                                text: pillar[0],
                                style: TextStyle(
                                  color: _stemColor(context, pillar[0]),
                                ),
                              ),
                              TextSpan(
                                text: pillar[1],
                                style: TextStyle(
                                  color: _branchColor(context, pillar[1]),
                                ),
                              ),
                            ],
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            nayin,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5,
                              color: _nayinColor(context, nayin),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (extras.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              extras.join('　·　'),
              key: const Key('mini-cal-detail-extras'),
              style: TextStyle(
                fontSize: 9,
                color: context.lc.inkMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
