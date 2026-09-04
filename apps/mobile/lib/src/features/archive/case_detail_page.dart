import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:liuyao_engine/liuyao_engine.dart';
import 'package:share_plus/share_plus.dart';

import '../casting/casting_models.dart';
import '../casting/chart_preview.dart';
import '../../ui/design_system/design_system.dart';
import '../../ui/liuyao_design.dart';
import '../settings/app_preferences.dart';
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
  bool _showNaYin = true;
  bool _showTwelveGrowth = true;
  bool _showFiveStars = true;
  bool _show28Mansions = true;
  bool _showAlmanacCalendar = false;

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
    // 按设置页「卦面显示」偏好初始化标注默认值（卦面信息极大保留）。
    final prefs = currentPreferences;
    _showNaYin = prefs.showNayin;
    _showFiveStars = prefs.showFiveStarsAndMansions;
    _show28Mansions = prefs.showFiveStarsAndMansions;
    _showTwelveGrowth = prefs.showShenshaAndTwelveGrowth;
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

  /// 删除档案：必须二次确认，防误删（2026-09-01 需求）。
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除这份档案？'),
        content: Text('「${_detail.title}」及其卦面、解读与反馈将被永久删除，且无法恢复。'),
        actions: [
          TextButton(
            key: const Key('case-delete-cancel'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('再想想'),
          ),
          FilledButton(
            key: const Key('case-delete-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: LiuyaoColors.cinnabar,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.client.deleteCase(_detail.id);
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('删除失败：$error')));
      }
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('档案已删除')));
    Navigator.pop(context);
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

  Future<void> _confirmDeleteAnalysis(CaseAnalysis item) async {
    // 2026-09-04 需求：历史解读版本可删除（写得不好或有误的版本不必保留）。
    // 按档案删除惯例做二次确认（FR-CAS-008）。
    final preview = item.body.length > 40
        ? '${item.body.substring(0, 40)}…'
        : item.body;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除这个解读版本？'),
        content: Text(
          '将删除「版本 ${item.revision} · $preview」。\n'
          '删除后不可恢复；其余版本与反馈不受影响。',
        ),
        actions: [
          TextButton(
            key: const Key('delete-analysis-cancel'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('再想想'),
          ),
          TextButton(
            key: const Key('delete-analysis-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('删除', style: TextStyle(color: _cinnabar)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.client.deleteAnalysis(
        caseId: _detail.id,
        analysisId: item.id,
      );
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('该解读版本已删除')));
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = _message(error));
    }
  }

  Future<void> _editQuestion() async {
    // 2026-09-04 需求：占问文本本身可修改（起卦时输入的内容写错可纠正），
    // 背景问念仍作为独立补充入口保留。修改不触碰卦面与起卦记录。
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _paper,
      builder: (sheetContext) => _TextSheetEditor(
        title: '编辑占问',
        note: '修改占问内容不会改动卦面、四柱与起卦时间；更详细的补充请用「编辑背景问念」。',
        label: '占问事项',
        hint: '这次想问什么',
        initialText: _detail.question == '暂无问念' ? '' : _detail.question,
        minLines: 2,
        maxLines: 6,
        maxLength: 1000,
        editorKey: const Key('question-editor'),
        saveKey: const Key('save-question'),
      ),
    );
    if (value == null || !mounted) return;
    try {
      await widget.client.updateQuestion(caseId: _detail.id, question: value);
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('占问已保存')));
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = _message(error));
    }
  }

  Future<void> _editQuestionContext() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _paper,
      builder: (sheetContext) => _TextSheetEditor(
        title: '编辑背景问念',
        note: '可在起卦后补充背景，不会修改原卦、四柱或起卦时间。',
        label: '背景问念',
        hint: '补充问题背景、已知条件和真正想确认的事情',
        initialText: _detail.questionContext,
        minLines: 4,
        maxLines: 10,
        maxLength: 10000,
        editorKey: const Key('question-context-editor'),
        saveKey: const Key('save-question-context'),
      ),
    );
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
    // 打通档案页标签：聚合全部档案标签 + 自定义标签作为快速选用建议。
    var suggestions = currentPreferences.customTags.toList();
    try {
      final summaries = await widget.client.listCases();
      suggestions = {
        ...suggestions,
        for (final item in summaries) ...item.tags,
      }.toList()..sort((a, b) => a.compareTo(b));
    } on Object {
      // 聚合失败仅意味着没有建议，不影响编辑。
    }
    if (!mounted) return;
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _paper,
      builder: (_) => _TagsEditor(initialTags: tags, suggestions: suggestions),
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

  /// 首次导出前让用户选择「解读历史版本」的默认导出口径（2026-09-04
  /// 需求 1）；之后可在设置中修改，导出面板上也随时可切。
  Future<void> _maybePromptExportDefault() async {
    if (currentPreferences.exportSetupCompleted) return;
    final includeHistory = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('export-setup-dialog'),
        title: const Text('导出解读时默认包含历史版本吗？'),
        content: const Text(
          '解读会随每次保存追加新版本。你可以选择导出时默认带上全部历史版本，'
          '或只导出最新一版；每次导出时也可临时切换。',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            key: const Key('export-setup-latest'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('仅最新版本'),
          ),
          FilledButton(
            key: const Key('export-setup-history'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('包含全部历史版本'),
          ),
        ],
      ),
    );
    if (includeHistory == null) return;
    // savePreferences 首行同步更新内存缓存（立即驱动导出面板初始值），
    // 写盘异步进行；不 await——与历法口径首启流程一致，避免在
    // FakeAsync 测试环境中真实 IO 挂起整个调用链。
    unawaited(
      savePreferences(
        currentPreferences.copyWith(
          exportSetupCompleted: true,
          exportAnalysisHistoryDefault: includeHistory,
        ),
      ),
    );
  }

  Future<void> _chooseExport() async {
    await _maybePromptExportDefault();
    if (!mounted) return;
    final selection = await showModalBottomSheet<_ExportSelection>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _paper,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            // 2026-09-04 需求 1+2：面板内两个内容开关（包含解读与反馈 /
            // 包含历史版本），历史版本开关初始值来自首启选择或设置页。
            child: _ExportSheet(
              key: const Key('export-sheet'),
              detail: _detail,
            ),
          ),
        ),
      ),
    );
    if (selection == null || !mounted) return;
    await _export(
      selection.format,
      includeAnalysis: selection.includeAnalysis,
      includeFeedback: selection.includeFeedback,
      includeAnalysisHistory: selection.includeAnalysisHistory,
    );
  }

  Future<void> _export(
    String format, {
    bool includeAnalysis = true,
    bool includeFeedback = true,
    bool includeAnalysisHistory = true,
  }) async {
    setState(() => _exporting = true);
    try {
      if (format == 'image') {
        final bytes = await buildCaseArchivePng(
          context,
          _detail,
          options: ArchiveImageOptions(
            includeAnalysis: includeAnalysis,
            includeFeedback: includeFeedback,
            includeAnalysisHistory: includeAnalysisHistory,
          ),
        );
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
        // JSON 是完整数据格式，导出端忽略裁剪参数；Markdown 按选项裁剪。
        includeAnalysis: includeAnalysis,
        includeFeedback: includeFeedback,
        includeAnalysisHistory: includeAnalysisHistory,
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
        // 「道谕六爻」品牌标题统一组件（字体与档案页基准一致，AppBar 内字号略缩）。
        title: const DaoyuBrandTitle(
          keyOverride: Key('case-result-title'),
          fontSize: 20,
        ),
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
          IconButton(
            key: const Key('case-delete'),
            tooltip: '删除档案',
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline_rounded),
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
            onEditQuestion: _editQuestion,
          ),
          const SizedBox(height: 10),
          if (currentPreferences.showCastingRecord &&
              preview.castingRecord.method == 'three_coins') ...[
            DSReveal(
              delay: const Duration(milliseconds: 60),
              child: _ResultExpansionCard(
                key: const Key('result-casting-record-section'),
                title: '起卦记录',
                summary: '自动铜钱 · 六次原始记录已存档',
                child: _CastingRecordPanel(record: preview.castingRecord),
              ),
            ),
            const SizedBox(height: 10),
          ],
          // 2026-09-04 需求：十二长生与神煞卡片移至卦例下方，
          // 保证截图分享时卦面信息居中、长生与神煞在下方完整可见。
          DSScaleIn(
            child: Container(
              key: const Key('result-chart-card'),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(LiuyaoRadii.card),
              ),
              child: LiuyaoCoreChart(
                preview: preview,
                lightHeader: true,
                showSummaryHeader: false,
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
                      onChangedNaYin: (value) =>
                          setState(() => _showNaYin = value),
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
                      showAlmanacCalendar: _showAlmanacCalendar,
                      onToggleAlmanacCalendar: () => setState(
                        () => _showAlmanacCalendar = !_showAlmanacCalendar,
                      ),
                    ),
                    if (_showAlmanacCalendar)
                      LiuyaoMiniAlmanacCalendar(initialMonth: _detail.castAt),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (twelveStages.isNotEmpty) ...[
            _ResultExpansionCard(
              key: const Key('result-twelve-section'),
              title: '十二长生',
              summary: _twelveStageSummary(preview.dayPillar),
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
          if (currentPreferences.showCalculationBasis &&
              preview.calculationTrace.isNotEmpty) ...[
            DSReveal(
              delay: const Duration(milliseconds: 120),
              child: _ResultExpansionCard(
                key: const Key('result-calculation-section'),
                title: '计算依据',
                summary: '${preview.calculationTrace.length} 组规则过程可核对',
                child: LiuyaoCalculationDetailsPanel(preview: preview),
              ),
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
                  _AnalysisHistory(
                    items: _detail.analyses,
                    onDelete: _confirmDeleteAnalysis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 20),
          Center(
            child: Text(
              '— 仅供娱乐 —',
              key: const Key('case-entertainment-note'),
              style: const TextStyle(
                color: _mutedInk,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: DSColors.glowCinnabar,
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

  /// 十二长生折叠摘要：以日支为主体列四阶段（长生/帝旺/墓/绝）所在支，
  /// 对齐线框图「十二：长生-寅 帝旺-午 墓-戌 绝-亥」形态。
  /// 日支为辰戌丑未时走《五行大义》四土独立表（受气→绝），否则走五行顺行表。
  String _twelveStageSummary(String dayPillar) {
    const branches = '子丑寅卯辰巳午未申酉戌亥';
    if (dayPillar.length < 2) return '五行体系 · 无记录';
    final dayBranch = dayPillar[1];
    const wanted = ['长生', '帝旺', '墓', '绝'];
    final parts = <String>[];
    for (final stage in wanted) {
      final hits = <String>[];
      for (final branch in branches.split('')) {
        final growth = lookupPrivateBranchGrowth(dayBranch, branch);
        final display = (growth['display_phases'] as List).cast<String>();
        if (display.contains(stage)) hits.add(branch);
      }
      if (hits.isEmpty) continue;
      // 四土「受气」跨两支（主体+4 / 主体+5），按《五行大义》原文先列主体+4 支。
      final dayIndex = branches.indexOf(dayBranch);
      final first = hits.length == 1
          ? hits.first
          : hits.firstWhere(
              (b) => (branches.indexOf(b) - dayIndex + 12) % 12 == 4,
              orElse: () => hits.first,
            );
      parts.add('$stage-$first');
    }
    if (parts.isEmpty) return '五行体系 · 日支$dayBranch';
    return '十二：${parts.join('  ')}';
  }

  String _message(Object error) =>
      error.toString().replaceFirst(RegExp(r'^.*Exception: '), '');
}

/// 导出面板的选择结果：格式 + 本次内容裁剪选项。
class _ExportSelection {
  const _ExportSelection({
    required this.format,
    required this.includeAnalysis,
    required this.includeFeedback,
    required this.includeAnalysisHistory,
  });

  final String format;
  final bool includeAnalysis;
  final bool includeFeedback;
  final bool includeAnalysisHistory;
}

/// 导出面板：格式三选一 + 两个内容开关（2026-09-04 需求 1/2）。
class _ExportSheet extends StatefulWidget {
  const _ExportSheet({super.key, required this.detail});

  final CaseDetail detail;

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  late bool _includeRecords = true;
  late bool _includeHistory = currentPreferences.exportAnalysisHistoryDefault;

  void _pop(String format) => Navigator.pop(
    context,
    _ExportSelection(
      format: format,
      includeAnalysis: _includeRecords,
      includeFeedback: _includeRecords,
      includeAnalysisHistory: _includeHistory,
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '导出完整档案',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 6),
      const Text(
        '文件包含占问、原始起卦、卦面快照、解读、反馈和计算依据。',
        style: TextStyle(color: _mutedInk, height: 1.45),
      ),
      const SizedBox(height: 14),
      _ExportOptionRow(
        key: const Key('export-include-records'),
        title: '包含解读与反馈',
        description: '关闭后只导出卦面与占问，适合只分享卦本身',
        value: _includeRecords,
        onChanged: (value) => setState(() => _includeRecords = value),
      ),
      const SizedBox(height: 8),
      _ExportOptionRow(
        key: const Key('export-include-history'),
        title: '包含解读历史版本',
        description: _includeRecords ? '关闭后解读只保留最新一版' : '需先开启「包含解读与反馈」',
        value: _includeHistory,
        enabled: _includeRecords,
        onChanged: (value) => setState(() => _includeHistory = value),
      ),
      const SizedBox(height: 14),
      _ExportChoice(
        key: const Key('export-markdown'),
        onTap: () => _pop('markdown'),
        icon: Icons.description_outlined,
        title: '可读档案 · Markdown',
        description: _includeRecords ? '适合阅读、打印或继续整理' : '仅卦面与占问，适合只分享卦本身',
      ),
      const SizedBox(height: 10),
      _ExportChoice(
        key: const Key('export-json'),
        onTap: () => _pop('json'),
        icon: Icons.data_object_rounded,
        title: '完整数据 · JSON',
        description: '备份与迁移用，始终包含全部解读与反馈',
      ),
      const SizedBox(height: 10),
      _ExportChoice(
        key: const Key('export-image'),
        onTap: () => _pop('image'),
        icon: Icons.image_outlined,
        title: '卦面长图 · PNG',
        description: _includeRecords
            ? (_includeHistory ? '包含卦面、全部解读与反馈' : '包含卦面、最新解读与反馈')
            : '仅卦面与占问，适合分享',
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
        child: Text(
          _includeRecords
              ? '将包含：占问 · 起卦时间 · 本卦与变卦 · 六亲六神 · 伏神 · 计算依据 · 解读${_includeHistory ? '（全部版本）' : '（最新一版）'} · 反馈'
              : '将包含：占问 · 起卦时间 · 本卦与变卦 · 六亲六神 · 伏神',
          style: const TextStyle(color: _mutedInk, height: 1.55),
        ),
      ),
    ],
  );
}

class _ExportOptionRow extends StatelessWidget {
  const _ExportOptionRow({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: enabled ? 1 : .55,
    child: Material(
      color: _softPaper.withValues(alpha: .45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LiuyaoRadii.small),
        side: const BorderSide(color: _rule),
      ),
      child: InkWell(
        // 整行可点切换（与设置页开关行为一致）。
        onTap: enabled ? () => onChanged(!value) : null,
        borderRadius: BorderRadius.circular(LiuyaoRadii.small),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(color: _mutedInk, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              Switch(value: value, onChanged: enabled ? onChanged : null),
            ],
          ),
        ),
      ),
    ),
  );
}

/// 底部弹层文本编辑器：controller 由 State 持有并在 sheet 真正移除时释放。
/// （此前在 await showModalBottomSheet 后立即 dispose 会命中「controller
/// used after disposed」——pop 返回时关闭动画仍在使用 TextField。）
class _TextSheetEditor extends StatefulWidget {
  const _TextSheetEditor({
    required this.title,
    required this.note,
    required this.label,
    required this.hint,
    required this.initialText,
    required this.minLines,
    required this.maxLines,
    required this.maxLength,
    required this.editorKey,
    required this.saveKey,
  });

  final String title;
  final String note;
  final String label;
  final String hint;
  final String initialText;
  final int minLines;
  final int maxLines;
  final int maxLength;
  final Key editorKey;
  final Key saveKey;

  @override
  State<_TextSheetEditor> createState() => _TextSheetEditorState();
}

class _TextSheetEditorState extends State<_TextSheetEditor> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
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
        Text(
          widget.title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          widget.note,
          style: const TextStyle(color: _mutedInk, height: 1.4),
        ),
        const SizedBox(height: 12),
        TextField(
          key: widget.editorKey,
          controller: _controller,
          autofocus: true,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              key: widget.saveKey,
              onPressed: () => Navigator.pop(context, _controller.text),
              child: const Text('保存'),
            ),
          ],
        ),
      ],
    ),
  );
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
    this.onEditQuestion,
  });

  final CaseDetail detail;
  final VoidCallback onEdit;
  final VoidCallback onEditTags;
  final VoidCallback? onEditQuestion;

  @override
  Widget build(BuildContext context) => Container(
    // 与线框图 CaseInfo 对齐：整卡压成两行主信息（日期 / 占问），
    // 问念与标签折叠为第三行小字；取卦方式与编辑入口全部行内化，
    // 不再单独占层，schema 版本仅保留在导出与持久化数据中。
    padding: const EdgeInsets.fromLTRB(9, 4, 5, 4),
    decoration: BoxDecoration(
      color: _paper,
      borderRadius: BorderRadius.circular(LiuyaoRadii.card),
      border: Border.all(color: _rule, width: .8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '日期：',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: _dateTime(detail.castAt)),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, height: 1.15),
              ),
            ),
            Text(
              switch (detail.castingMethod) {
                'manual' => '手动起卦',
                'time_pillar' => '时刻起卦',
                _ => '自动铜钱',
              },
              style: const TextStyle(
                color: _cinnabar,
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              key: const Key('edit-tags'),
              tooltip: '编辑标签',
              onPressed: onEditTags,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 20, height: 20),
              padding: EdgeInsets.zero,
              iconSize: 13,
              icon: const Icon(Icons.sell_outlined, color: _cinnabar),
            ),
            IconButton(
              key: const Key('edit-question-context'),
              tooltip: '编辑背景问念',
              onPressed: onEdit,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 20, height: 20),
              padding: EdgeInsets.zero,
              iconSize: 14,
              icon: const Icon(Icons.edit_note_outlined, color: _cinnabar),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '占问：',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: detail.question),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: LiuyaoColors.ink,
                  fontSize: 12,
                  height: 1.18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onEditQuestion != null) ...[
              const SizedBox(width: 4),
              IconButton(
                key: const Key('edit-question'),
                tooltip: '编辑占问',
                onPressed: onEditQuestion,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 22,
                  height: 22,
                ),
                padding: EdgeInsets.zero,
                iconSize: 14,
                icon: const Icon(
                  Icons.drive_file_rename_outline,
                  color: _cinnabar,
                ),
              ),
            ],
          ],
        ),
        if (detail.questionContext.trim().isNotEmpty ||
            detail.tags.isNotEmpty) ...[
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (detail.questionContext.trim().isNotEmpty)
                Expanded(
                  child: Text(
                    '背景问念：${detail.questionContext}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _mutedInk,
                      fontSize: 9,
                      height: 1.15,
                    ),
                  ),
                )
              else
                const Spacer(),
              if (detail.tags.isNotEmpty) ...[
                if (detail.questionContext.trim().isNotEmpty)
                  const SizedBox(width: 5),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 128),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final tag in detail.tags)
                          Container(
                            key: Key('detail-tag-$tag'),
                            margin: const EdgeInsets.only(left: 3),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: _cinnabar.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: _cinnabar.withValues(alpha: .28),
                              ),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                color: _cinnabar,
                                fontSize: 9,
                                height: 1.15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    ),
  );

  static String _dateTime(DateTime value) =>
      '${value.year}年${value.month.toString().padLeft(2, '0')}月'
      '${value.day.toString().padLeft(2, '0')}日 '
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:'
      '${value.second.toString().padLeft(2, '0')}';
}

class _AutoArchiveBanner extends StatelessWidget {
  const _AutoArchiveBanner();

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('auto-archive-banner'),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: DSColors.glowJade,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: DSColors.jade.withValues(alpha: .3)),
    ),
    child: const Row(
      children: [
        Icon(Icons.inventory_2_outlined, size: 18, color: DSColors.jade),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            '排盘完成，当前原始起卦与完整卦面已自动存入档案',
            style: TextStyle(
              color: DSColors.jade,
              fontSize: 11,
              fontWeight: FontWeight.w500,
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
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return DSGlassPanel(
      padding: EdgeInsets.zero,
      color: DSColors.glass,
      child: ExpansionTile(
        maintainState: true,
        expansionAnimationStyle: reduceMotion
            ? const AnimationStyle(duration: Duration.zero)
            : const AnimationStyle(duration: Duration(milliseconds: 220)),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: DSColors.celadonDeep,
        collapsedIconColor: DSColors.textMuted,
        title: Row(
          children: [
            Text(
              '$title：',
              style: DSTypography.displayLight(
                fontSize: 14,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                summary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _mutedInk, fontSize: 11),
              ),
            ),
          ],
        ),
        children: [child],
      ),
    );
  }
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
            color: line.changing
                ? DSColors.cinnabar.withValues(alpha: .12)
                : _softPaper,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  line.positionName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
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
                  fontWeight: FontWeight.w600,
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
      color: value == 3 ? LiuyaoColors.ink : LiuyaoColors.parchment,
    ),
    child: Text(
      '$value',
      style: TextStyle(
        color: value == 3 ? LiuyaoColors.paper : LiuyaoColors.ink,
        fontSize: 10,
        fontWeight: FontWeight.w600,
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
      borderRadius: BorderRadius.circular(12),
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
  const _AnalysisHistory({required this.items, this.onDelete});

  final List<CaseAnalysis> items;
  final void Function(CaseAnalysis item)? onDelete;

  @override
  Widget build(BuildContext context) => Material(
    color: _softPaper,
    borderRadius: BorderRadius.circular(12),
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      key: const Key('analysis-history'),
      title: const Text('查看历史版本'),
      subtitle: Text('${items.length} 个版本'),
      children: items.reversed
          .map(
            (item) => ListTile(
              key: Key('analysis-history-${item.revision}'),
              title: Text(
                '版本 ${item.revision} · ${_shortDate(item.createdAt)}',
              ),
              subtitle: Text(item.body),
              trailing: onDelete == null
                  ? null
                  : IconButton(
                      key: Key('delete-analysis-${item.revision}'),
                      tooltip: '删除该版本',
                      onPressed: () => onDelete!(item),
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: _cinnabar,
                      ),
                    ),
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
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _rule),
    ),
    child: Column(
      children: [
        const Icon(Icons.timeline_rounded, color: _cinnabar, size: 30),
        const SizedBox(height: 8),
        const Text('还没有事后反馈', style: TextStyle(fontWeight: FontWeight.w600)),
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
      borderRadius: BorderRadius.circular(12),
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
                  fontWeight: FontWeight.w600,
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
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
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
  const _TagsEditor({required this.initialTags, this.suggestions = const []});

  final List<String> initialTags;

  /// 快速选用建议：全部档案标签 + 档案页「＋」新建的自定义标签。
  final List<String> suggestions;

  @override
  State<_TagsEditor> createState() => _TagsEditorState();
}

class _TagsEditorState extends State<_TagsEditor> {
  late final List<String> _tags = List<String>.from(widget.initialTags);
  final _controller = TextEditingController();
  String? _error;

  /// 未选用的建议（已选中的不再重复出现）。
  late List<String> _suggestions = widget.suggestions
      .where((tag) => !_tags.contains(tag))
      .toList();

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
    setState(() {
      _tags.remove(tag);
      if (widget.suggestions.contains(tag)) {
        _suggestions = [..._suggestions, tag]..sort();
      }
    });
  }

  /// 快速选用：点选建议标签直接加入当前卦例。
  void _addSuggestion(String tag) {
    setState(() {
      if (_tags.contains(tag)) return;
      _tags.add(tag);
      _suggestions.remove(tag);
      _error = null;
    });
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
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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
                    deleteButtonTooltipMessage: '删除',
                    deleteIconColor: _cinnabar,
                    backgroundColor: LiuyaoColors.jade.withValues(alpha: .08),
                    side: BorderSide(color: _cinnabar.withValues(alpha: .35)),
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
          // 快速选用：档案页「＋」新建的自定义标签与已有档案标签，
          // 点选即加入当前卦例，免去重复输入。
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              '快速选用',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final tag in _suggestions)
                  ActionChip(
                    key: Key('tag-suggest-$tag'),
                    label: Text(tag, style: const TextStyle(fontSize: 12)),
                    onPressed: () => _addSuggestion(tag),
                    backgroundColor: _paper,
                    side: const BorderSide(color: _rule),
                  ),
              ],
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
                  backgroundColor: LiuyaoColors.jade,
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
