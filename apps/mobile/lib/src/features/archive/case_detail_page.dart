import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../casting/casting_models.dart';
import '../casting/chart_preview.dart';
import '../../ui/liuyao_design.dart';
import 'archive_client.dart';
import 'archive_image_export.dart';
import 'archive_models.dart';

const _mutedInk = LiuyaoColors.inkMuted;
const _cinnabar = LiuyaoColors.cinnabar;
const _paper = LiuyaoColors.paperRaised;
const _softPaper = LiuyaoColors.parchment;
const _rule = LiuyaoColors.inkFaint;

class CaseDetailPage extends StatefulWidget {
  const CaseDetailPage({
    required this.client,
    required this.initialDetail,
    this.openedAfterCasting = false,
    super.key,
  });

  final ArchiveDataSource client;
  final CaseDetail initialDetail;
  final bool openedAfterCasting;

  @override
  State<CaseDetailPage> createState() => _CaseDetailPageState();
}

class _CaseDetailPageState extends State<CaseDetailPage> {
  late CaseDetail _detail;
  final _analysisController = TextEditingController();
  bool _savingAnalysis = false;
  bool _exporting = false;
  String? _error;

  // 卦面标注显示状态（与十二长生表、卦面爻位标注联动）。
  String _growthReference = 'day';
  String _annotationMode = 'twelve_growth';
  bool _showLineAnnotations = true;
  bool _showNaYin = true;
  bool _showTwelveGrowth = true;
  bool _showFiveStars = true;
  bool _show28Mansions = true;

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

  @override
  void initState() {
    super.initState();
    _detail = widget.initialDetail;
    _analysisController.text = _latestUserAnalysis?.body ?? '';
  }

  CaseAnalysis? get _latestUserAnalysis {
    for (final analysis in _detail.analyses.reversed) {
      if (analysis.author == 'user') return analysis;
    }
    return null;
  }

  Future<void> _refresh() async {
    final refreshed = await widget.client.getCase(_detail.id);
    if (mounted) setState(() => _detail = refreshed);
  }

  Future<void> _saveAnalysis() async {
    final body = _analysisController.text.trim();
    if (body.isEmpty || _savingAnalysis) return;
    setState(() {
      _savingAnalysis = true;
      _error = null;
    });
    try {
      await widget.client.appendUserAnalysis(
        caseId: _detail.id,
        body: body,
        expectedRevision: _detail.latestAnalysisRevision,
      );
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('解读已保存为新版本')));
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _savingAnalysis = false);
    }
  }

  Future<void> _editQuestionContext() async {
    final controller = TextEditingController(text: _detail.questionContext);
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _paper,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '编辑背景问念',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              '可在起卦后补充背景，不会修改原卦、四柱或起卦时间。',
              style: TextStyle(color: _mutedInk, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('question-context-editor'),
              controller: controller,
              autofocus: true,
              minLines: 4,
              maxLines: 10,
              maxLength: 10000,
              decoration: const InputDecoration(
                labelText: '背景问念',
                hintText: '补充问题背景、已知条件和真正想确认的事情',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const Key('save-question-context'),
                  onPressed: () => Navigator.pop(sheetContext, controller.text),
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (value == null || !mounted) return;
    try {
      await widget.client.updateQuestionContext(
        caseId: _detail.id,
        context: value,
      );
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('背景问念已保存')));
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = _message(error));
    }
  }

  Future<void> _editTags() async {
    final tags = List<String>.from(_detail.tags);
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _paper,
      builder: (_) => _TagsEditor(initialTags: tags),
    );
    if (result == null || !mounted) return;
    try {
      await widget.client.updateTags(caseId: _detail.id, tags: result);
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('标签已保存')));
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = _message(error));
    }
  }

  Future<void> _editFeedback([CaseFeedback? existing]) async {
    final draft = await showModalBottomSheet<_FeedbackDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _paper,
      builder: (_) => _FeedbackEditor(existing: existing),
    );
    if (draft == null || !mounted) return;
    try {
      if (existing == null) {
        await widget.client.appendFeedback(
          caseId: _detail.id,
          body: draft.body,
          status: draft.status,
          occurredAt: draft.occurredAt,
        );
      } else {
        await widget.client.updateFeedback(
          caseId: _detail.id,
          feedbackId: existing.id,
          body: draft.body,
          status: draft.status,
          occurredAt: draft.occurredAt,
        );
      }
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(existing == null ? '反馈已添加' : '反馈已更新')),
        );
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = _message(error));
    }
  }

  Future<void> _chooseExport() async {
    final format = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _paper,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '导出完整档案',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  '文件包含占问、原始起卦、卦面快照、解读、反馈和计算依据。',
                  style: TextStyle(color: _mutedInk, height: 1.45),
                ),
                const SizedBox(height: 16),
                _ExportChoice(
                  key: const Key('export-markdown'),
                  onTap: () => Navigator.pop(context, 'markdown'),
                  icon: Icons.description_outlined,
                  title: '可读档案 · Markdown',
                  description: '适合阅读、打印或继续整理',
                ),
                const SizedBox(height: 10),
                _ExportChoice(
                  key: const Key('export-json'),
                  onTap: () => Navigator.pop(context, 'json'),
                  icon: Icons.data_object_rounded,
                  title: '完整数据 · JSON',
                  description: '保留稳定字段、版本和完整快照',
                ),
                const SizedBox(height: 10),
                _ExportChoice(
                  key: const Key('export-image'),
                  onTap: () => Navigator.pop(context, 'image'),
                  icon: Icons.image_outlined,
                  title: '卦面长图 · PNG',
                  description: '包含卦面、全部解读与反馈，适合分享',
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: _softPaper.withValues(alpha: .62),
                    borderRadius: BorderRadius.circular(LiuyaoRadii.small),
                    border: Border.all(color: _rule),
                  ),
                  child: const Text(
                    '将包含：占问 · 起卦时间 · 本卦与变卦 · 六亲六神 · 伏神 · 计算依据 · 解读 · 反馈',
                    style: TextStyle(color: _mutedInk, height: 1.55),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (format != null && mounted) await _export(format);
  }

  Future<void> _export(String format) async {
    setState(() => _exporting = true);
    try {
      if (format == 'image') {
        final bytes = await buildCaseArchivePng(context, _detail);
        final directory = await Directory.systemTemp.createTemp(
          'liuyao-export-',
        );
        final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
        final file = File('${directory.path}/liuyao-$stamp.png');
        await file.writeAsBytes(bytes, flush: true);
        if (!mounted) return;
        final box = context.findRenderObject() as RenderBox?;
        await SharePlus.instance.share(
          ShareParams(
            title: _detail.title,
            subject: '六爻档案图片：${_detail.title}',
            files: [XFile(file.path, mimeType: 'image/png')],
            sharePositionOrigin: box == null
                ? null
                : box.localToGlobal(Offset.zero) & box.size,
          ),
        );
        return;
      }
      final exported = await widget.client.exportCase(
        _detail.id,
        format: format,
      );
      final directory = await Directory.systemTemp.createTemp('liuyao-export-');
      final file = File('${directory.path}/${exported.filename}');
      await file.writeAsString(exported.content, encoding: utf8, flush: true);
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          title: _detail.title,
          subject: '六爻档案：${_detail.title}',
          files: [XFile(file.path, mimeType: exported.contentType)],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } on Object catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  void dispose() {
    _analysisController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _detail.chart;
    final twelveStages =
        preview.annotations.fiveElementTwelveStages.lineResults;
    final shensha = preview.annotations.shenshaResults;
    return Scaffold(
      appBar: AppBar(
        title: const Text('六爻卦面', key: Key('case-result-title')),
        actions: [
          if (widget.openedAfterCasting)
            const Padding(
              padding: EdgeInsets.only(right: 2),
              child: Tooltip(
                message: '已自动存档',
                child: Icon(Icons.cloud_done_outlined, color: _cinnabar),
              ),
            ),
          IconButton(
            key: const Key('case-export'),
            tooltip: '导出档案',
            onPressed: _exporting ? null : _chooseExport,
            icon: _exporting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        key: const Key('case-detail-scroll'),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 40),
        children: [
          if (widget.openedAfterCasting) ...[
            const _AutoArchiveBanner(),
            const SizedBox(height: 10),
          ],
          _QuestionCard(
            detail: _detail,
            onEdit: _editQuestionContext,
            onEditTags: _editTags,
          ),
          const SizedBox(height: 10),
          if (preview.castingRecord.method == 'three_coins') ...[
            _ResultExpansionCard(
              key: const Key('result-casting-record-section'),
              title: '起卦记录',
              summary: '自动铜钱 · 六次原始记录已存档',
              child: _CastingRecordPanel(record: preview.castingRecord),
            ),
            const SizedBox(height: 10),
          ],
          if (twelveStages.isNotEmpty) ...[
            _ResultExpansionCard(
              key: const Key('result-twelve-section'),
              title: '十二长生',
              summary: '五行体系 · ${twelveStages.length} 爻 × 四柱',
              child: LiuyaoTwelveStagesPanel(
                preview: preview,
                selectedReference: _growthReference,
                onReferenceChanged: (value) {
                  setState(() => _growthReference = value);
                },
                annotationMode: _annotationMode,
                onModeChanged: (value) {
                  setState(() => _annotationMode = value);
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (shensha.isNotEmpty) ...[
            _ResultExpansionCard(
              key: const Key('result-shensha-section'),
              title: '神煞',
              summary: _shenshaSummary(shensha),
              child: LiuyaoShenshaPanel(preview: preview),
            ),
            const SizedBox(height: 12),
          ],
          Container(
            key: const Key('result-chart-card'),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(LiuyaoRadii.large),
            ),
            child: LiuyaoCoreChart(
              preview: preview,
              lightHeader: true,
              showSummaryHeader: false,
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
          ),
          const SizedBox(height: 10),
          LiuyaoLineAnnotationsToggle(
            showLineAnnotations: _showLineAnnotations,
            onChangedLineAnnotations: (value) {
              setState(() => _showLineAnnotations = value);
            },
            showNaYin: _showNaYin,
            onChangedNaYin: (value) => setState(() => _showNaYin = value),
            showTwelveGrowth: _showTwelveGrowth,
            onChangedTwelveGrowth: (value) {
              setState(() => _showTwelveGrowth = value);
            },
            showFiveStars: _showFiveStars,
            onChangedFiveStars: (value) {
              setState(() => _showFiveStars = value);
            },
            show28Mansions: _show28Mansions,
            onChanged28Mansions: (value) {
              setState(() => _show28Mansions = value);
            },
          ),
          const SizedBox(height: 10),
          if (preview.calculationTrace.isNotEmpty) ...[
            _ResultExpansionCard(
              key: const Key('result-calculation-section'),
              title: '计算依据',
              summary: '${preview.calculationTrace.length} 组规则过程可核对',
              child: LiuyaoCalculationDetailsPanel(preview: preview),
            ),
            const SizedBox(height: 10),
          ],
          _ResultExpansionCard(
            key: const Key('result-analysis-section'),
            title: '解读信息',
            summary: _detail.analyses.isEmpty
                ? '暂未填写'
                : '已保存 ${_detail.analyses.length} 个版本',
            child: Column(
              children: [
                _AnalysisEditor(
                  controller: _analysisController,
                  saving: _savingAnalysis,
                  onSave: _saveAnalysis,
                ),
                if (_detail.analyses.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _AnalysisHistory(items: _detail.analyses),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          _ResultExpansionCard(
            key: const Key('result-feedback-section'),
            title: '反馈信息',
            summary: _detail.feedbacks.isEmpty
                ? '暂未填写'
                : '已记录 ${_detail.feedbacks.length} 条',
            child: Column(
              children: [
                if (_detail.feedbacks.isEmpty)
                  _EmptyFeedback(onAdd: () => _editFeedback())
                else ...[
                  ..._detail.feedbacks.reversed.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _FeedbackCard(
                        item: item,
                        onEdit: () => _editFeedback(item),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    key: const Key('add-feedback'),
                    onPressed: () => _editFeedback(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('添加一条反馈'),
                  ),
                ],
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDEA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(_error!, style: const TextStyle(color: _cinnabar)),
            ),
          ],
        ],
      ),
    );
  }

  String _shenshaSummary(List<ShenshaResult> results) => results
      .take(4)
      .map(
        (item) =>
            '${item.displayName}-${item.targetBranches.isEmpty ? '—' : item.targetBranches.join('、')}',
      )
      .join('  ');

  String _message(Object error) =>
      error.toString().replaceFirst(RegExp(r'^.*Exception: '), '');
}

class _ExportChoice extends StatelessWidget {
  const _ExportChoice({
    super.key,
    required this.onTap,
    required this.icon,
    required this.title,
    required this.description,
  });

  final VoidCallback onTap;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _softPaper.withValues(alpha: .45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LiuyaoRadii.card),
        side: const BorderSide(color: _rule),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LiuyaoRadii.card),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _paper,
                  borderRadius: BorderRadius.circular(LiuyaoRadii.small),
                  border: Border.all(color: _rule),
                ),
                child: Icon(icon, color: _cinnabar),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(color: _mutedInk, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _mutedInk),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.detail,
    required this.onEdit,
    required this.onEditTags,
  });

  final CaseDetail detail;
  final VoidCallback onEdit;
  final VoidCallback onEditTags;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 13),
    decoration: BoxDecoration(
      color: _paper,
      borderRadius: BorderRadius.circular(LiuyaoRadii.card),
      border: Border.all(color: _rule, width: .8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '日期：',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: _dateTime(detail.castAt)),
                  ],
                ),
                style: const TextStyle(fontSize: 13, height: 1.45),
              ),
            ),
            IconButton(
              key: const Key('edit-question-context'),
              tooltip: '编辑背景问念',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_note_outlined, color: _cinnabar),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: '占问：',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              TextSpan(text: detail.question),
            ],
          ),
          style: const TextStyle(
            color: LiuyaoColors.ink,
            fontSize: 16,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (detail.questionContext.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '背景问念：${detail.questionContext}',
            style: const TextStyle(
              color: _mutedInk,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
        if (detail.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final tag in detail.tags)
                Container(
                  key: Key('detail-tag-$tag'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _cinnabar.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _cinnabar.withValues(alpha: .35),
                    ),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: _cinnabar,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              detail.castingMethod == 'manual' ? '手动起卦' : '自动铜钱',
              style: const TextStyle(color: _cinnabar, fontSize: 11),
            ),
            const Text('  ·  ', style: TextStyle(color: _mutedInk)),
            Text(
              'schema v${detail.chart.schemaVersion}',
              style: const TextStyle(color: _mutedInk, fontSize: 11),
            ),
            const Spacer(),
            InkWell(
              key: const Key('edit-tags'),
              onTap: onEditTags,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sell_outlined,
                        color: _cinnabar, size: 14),
                    SizedBox(width: 4),
                    Text(
                      '标签',
                      style: TextStyle(color: _cinnabar, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  static String _dateTime(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} '
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _AutoArchiveBanner extends StatelessWidget {
  const _AutoArchiveBanner();

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('auto-archive-banner'),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF3EA),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0x334F7A54)),
    ),
    child: const Row(
      children: [
        Icon(Icons.inventory_2_outlined, size: 18, color: Color(0xFF4F7A54)),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            '排盘完成，当前原始起卦与完整卦面已自动存入档案',
            style: TextStyle(
              color: Color(0xFF365D3B),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ResultExpansionCard extends StatelessWidget {
  const _ResultExpansionCard({
    super.key,
    required this.title,
    required this.summary,
    required this.child,
  });

  final String title;
  final String summary;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: _paper,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(LiuyaoRadii.card),
      side: const BorderSide(color: _rule, width: .8),
    ),
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      maintainState: true,
      tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      shape: const Border(),
      collapsedShape: const Border(),
      title: Row(
        children: [
          Text(
            '$title：',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _mutedInk, fontSize: 12),
            ),
          ),
        ],
      ),
      children: [child],
    ),
  );
}

class _CastingRecordPanel extends StatelessWidget {
  const _CastingRecordPanel({required this.record});

  final CastingRecord record;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ...record.lines.reversed.map(
        (line) => Container(
          key: Key('coin-line-${line.position}'),
          margin: const EdgeInsets.only(top: 7),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: line.changing ? const Color(0xFFF8E8DF) : _softPaper,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  line.positionName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              ...line.coins.map(
                (coin) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _ResultCoin(value: coin),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${line.coins.join(' + ')} = ${line.total}',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              Text(
                '${line.value} · ${line.traditionalName}',
                style: TextStyle(
                  color: line.changing ? _cinnabar : _mutedInk,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        '规则 ${record.methodVersion} · ${record.randomSource?.kind == 'seeded_test' ? '固定测试源' : '系统随机'}',
        style: const TextStyle(color: _mutedInk, fontSize: 10),
      ),
    ],
  );
}

class _ResultCoin extends StatelessWidget {
  const _ResultCoin({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 24,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: value == 3 ? const Color(0xFF251D18) : const Color(0xFFE4D3BC),
    ),
    child: Text(
      '$value',
      style: TextStyle(
        color: value == 3 ? Colors.white : const Color(0xFF251D18),
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _AnalysisEditor extends StatelessWidget {
  const _AnalysisEditor({
    required this.controller,
    required this.saving,
    required this.onSave,
  });

  final TextEditingController controller;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _paper,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _rule),
    ),
    child: Column(
      children: [
        TextField(
          key: const Key('analysis-editor'),
          controller: controller,
          minLines: 6,
          maxLines: 16,
          maxLength: 50000,
          decoration: const InputDecoration(
            hintText: '记录取用神、旺衰、动变、应期与自己的判断…',
            border: InputBorder.none,
            counterText: '',
          ),
        ),
        const Divider(),
        Row(
          children: [
            const Expanded(
              child: Text(
                '每次保存都会保留上一版本',
                style: TextStyle(color: _mutedInk, fontSize: 10),
              ),
            ),
            FilledButton.icon(
              key: const Key('save-analysis'),
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: const Text('保存新版本'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _AnalysisHistory extends StatelessWidget {
  const _AnalysisHistory({required this.items});

  final List<CaseAnalysis> items;

  @override
  Widget build(BuildContext context) => Material(
    color: _softPaper,
    borderRadius: BorderRadius.circular(16),
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      key: const Key('analysis-history'),
      title: const Text('查看历史版本'),
      subtitle: Text('${items.length} 个不可变版本'),
      children: items.reversed
          .map(
            (item) => ListTile(
              title: Text(
                '版本 ${item.revision} · ${_shortDate(item.createdAt)}',
              ),
              subtitle: Text(item.body),
            ),
          )
          .toList(growable: false),
    ),
  );

  static String _shortDate(DateTime value) =>
      '${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} '
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _EmptyFeedback extends StatelessWidget {
  const _EmptyFeedback({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _paper,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _rule),
    ),
    child: Column(
      children: [
        const Icon(Icons.timeline_rounded, color: _cinnabar, size: 30),
        const SizedBox(height: 8),
        const Text('还没有事后反馈', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        const Text(
          '事情有进展时回来记录，用于长期复盘。',
          style: TextStyle(color: _mutedInk, fontSize: 12),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('add-first-feedback'),
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: const Text('添加反馈'),
        ),
      ],
    ),
  );
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.item, required this.onEdit});

  final CaseFeedback item;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Container(
    key: Key('feedback-${item.id}'),
    padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
    decoration: BoxDecoration(
      color: _paper,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: _rule),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: _cinnabar,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_statusLabel(item.status)} · ${_date(item.occurredAt ?? item.createdAt)}',
                style: const TextStyle(
                  color: _cinnabar,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(item.body, style: const TextStyle(height: 1.45)),
            ],
          ),
        ),
        IconButton(
          tooltip: '编辑反馈',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 19),
        ),
      ],
    ),
  );

  static String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

class _FeedbackDraft {
  const _FeedbackDraft({
    required this.body,
    required this.status,
    required this.occurredAt,
  });

  final String body;
  final String status;
  final DateTime occurredAt;
}

class _FeedbackEditor extends StatefulWidget {
  const _FeedbackEditor({this.existing});

  final CaseFeedback? existing;

  @override
  State<_FeedbackEditor> createState() => _FeedbackEditorState();
}

class _FeedbackEditorState extends State<_FeedbackEditor> {
  late final TextEditingController _controller;
  late String _status;
  late DateTime _date;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.existing?.body ?? '');
    _status = widget.existing?.status ?? 'pending';
    _date = widget.existing?.occurredAt ?? DateTime.now();
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1901),
      lastDate: DateTime(2100),
    );
    if (value != null && mounted) setState(() => _date = value);
  }

  void _submit() {
    final body = _controller.text.trim();
    if (body.isEmpty) {
      setState(() => _error = '请填写反馈内容');
      return;
    }
    Navigator.pop(
      context,
      _FeedbackDraft(body: body, status: _status, occurredAt: _date),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      4,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.existing == null ? '添加反馈' : '编辑反馈',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          key: const Key('feedback-status'),
          initialValue: _status,
          decoration: const InputDecoration(
            labelText: '验证状态',
            border: OutlineInputBorder(),
          ),
          items: const ['pending', 'matched', 'partial', 'not_matched']
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(_statusLabel(value)),
                ),
              )
              .toList(growable: false),
          onChanged: (value) => setState(() => _status = value ?? _status),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickDate,
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(
            '发生日期 ${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('feedback-body'),
          controller: _controller,
          autofocus: true,
          minLines: 4,
          maxLines: 8,
          maxLength: 20000,
          decoration: const InputDecoration(
            labelText: '反馈内容',
            hintText: '记录实际发生了什么，以及与原解读是否对应',
            border: OutlineInputBorder(),
            counterText: '',
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: _cinnabar)),
        ],
        const SizedBox(height: 14),
        FilledButton.icon(
          key: const Key('save-feedback'),
          onPressed: _submit,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          icon: const Icon(Icons.save_outlined),
          label: Text(widget.existing == null ? '保存反馈' : '保存修改'),
        ),
      ],
    ),
  );
}

String _statusLabel(String status) => switch (status) {
  'matched' => '已应验',
  'partial' => '部分应验',
  'not_matched' => '未应验',
  _ => '待验证',
};

/// 档案标签管理弹窗：查看、添加、删除标签。
class _TagsEditor extends StatefulWidget {
  const _TagsEditor({required this.initialTags});

  final List<String> initialTags;

  @override
  State<_TagsEditor> createState() => _TagsEditorState();
}

class _TagsEditorState extends State<_TagsEditor> {
  late final List<String> _tags = List<String>.from(widget.initialTags);
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final tag = _controller.text.trim();
    if (tag.isEmpty) {
      setState(() => _error = '请输入标签文字');
      return;
    }
    if (tag.length > 20) {
      setState(() => _error = '标签最多 20 字');
      return;
    }
    if (_tags.contains(tag)) {
      setState(() => _error = '标签「$tag」已存在');
      return;
    }
    if (_tags.length >= 30) {
      setState(() => _error = '一个档案最多 30 个标签');
      return;
    }
    setState(() {
      _tags.add(tag);
      _error = null;
      _controller.clear();
    });
  }

  void _remove(String tag) {
    setState(() => _tags.remove(tag));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '编辑标签',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            '为这个卦例添加或删除标签，之后可在档案列表中按标签筛选。',
            style: TextStyle(color: _mutedInk, height: 1.4),
          ),
          const SizedBox(height: 12),
          if (_tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final tag in _tags)
                  InputChip(
                    key: Key('tag-chip-$tag'),
                    label: Text(tag),
                    onDeleted: () => _remove(tag),
                    deleteIconColor: _cinnabar,
                    backgroundColor: _cinnabar.withValues(alpha: .08),
                    side: BorderSide(
                      color: _cinnabar.withValues(alpha: .35),
                    ),
                    labelStyle: TextStyle(
                      color: LiuyaoColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            )
          else
            const Text(
              '暂无标签，输入标签后点击添加。',
              style: TextStyle(color: _mutedInk, fontSize: 12),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('tag-input'),
                  controller: _controller,
                  maxLength: 20,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _add(),
                  decoration: const InputDecoration(
                    labelText: '新标签',
                    hintText: '如：工作、婚姻、待复盘',
                    border: OutlineInputBorder(),
                    counterText: '',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                key: const Key('add-tag'),
                tooltip: '添加标签',
                onPressed: _add,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              style: const TextStyle(color: _cinnabar, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('save-tags'),
                onPressed: () => Navigator.pop(context, _tags),
                style: FilledButton.styleFrom(
                  backgroundColor: _cinnabar,
                ),
                child: const Text('保存'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
