import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'archive_client.dart';
import 'archive_models.dart';
import 'case_detail_page.dart';
import '../settings/app_preferences.dart';
import '../../ui/design_system/components/daoyu_brand_title.dart';
import '../../ui/design_system/tokens/ds_theme_extension.dart';
import '../../ui/design_system/tokens/ds_typography.dart';
import '../../ui/liuyao_design.dart';

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key, this.dataSource});

  final ArchiveDataSource? dataSource;

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> with WidgetsBindingObserver {
  late final ArchiveDataSource _client;
  late final bool _ownsClient;
  final _searchController = TextEditingController();
  List<CaseSummary> _cases = const [];
  int _totalCount = 0;
  bool _loading = false;
  bool _transferring = false;
  String? _error;
  final Set<String> _activeTags = <String>{};
  List<String> _allTags = const [];
  Map<String, int> _tagCounts = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ownsClient = widget.dataSource == null;
    _client = widget.dataSource ?? ArchiveClient();
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_loading) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final query = _searchController.text.trim();
      final all = await _client.listCases();
      final cases = await _client.listCases(
        query: query,
        tags: _activeTags.toList(),
      );
      final allTags = <String>{};
      final tagCounts = <String, int>{};
      for (final item in all) {
        allTags.addAll(item.tags);
        for (final tag in item.tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }
      // 自定义标签（档案页「＋」新建）与档案标签合并，未挂载也参与筛选。
      allTags.addAll(currentPreferences.customTags);
      final total = all.length;
      if (mounted) {
        setState(() {
          _cases = cases;
          _totalCount = total;
          _allTags = allTags.toList()..sort((a, b) => a.compareTo(b));
          _tagCounts = tagCounts;
        });
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(CaseSummary summary) async {
    try {
      final detail = await _client.getCase(summary.id);
      if (!mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CaseDetailPage(client: _client, initialDetail: detail),
        ),
      );
      await _load();
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_message(error))));
      }
    }
  }

  void _selectTag(String tag) {
    setState(() => _activeTags.add(tag));
    _load();
  }

  /// 列表长按删除：二次确认后从本机档案移除（2026-09-01 需求）。
  /// 删除二次确认框（长按与滑动共用）：返回用户是否确认删除。
  Future<bool> _confirmDeleteDialog(CaseSummary summary) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除这份档案？'),
        content: Text('「${summary.question}」及其卦面、解读与反馈将被永久删除，且无法恢复。'),
        actions: [
          TextButton(
            key: const Key('archive-delete-cancel'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('再想想'),
          ),
          FilledButton(
            key: const Key('archive-delete-confirm'),
            style: FilledButton.styleFrom(backgroundColor: context.lc.cinnabar),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _confirmDelete(CaseSummary summary) async {
    if (!await _confirmDeleteDialog(summary)) return;
    await _deleteCase(summary);
  }

  /// 执行删除并刷新；失败时回拉列表（滑动入口的卡片已被移除，需要恢复）。
  Future<void> _deleteCase(CaseSummary summary) async {
    try {
      await _client.deleteCase(summary.id);
    } on Object catch (error) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_message(error))));
      }
      return;
    }
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('档案已删除')));
    }
  }

  Future<void> _showTransfer() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.lc.paperRaised,
      builder: (context) => _TransferSheet(caseCount: _totalCount),
    );
    if (!mounted || action == null) return;
    if (action == 'export') {
      await _exportAll();
    } else if (action == 'import') {
      await _pickAndImport();
    }
  }

  Future<void> _exportAll() async {
    if (_totalCount == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前没有可导出的档案')));
      return;
    }
    setState(() => _transferring = true);
    try {
      final exported = await _client.exportAllCases();
      final directory = await Directory.systemTemp.createTemp(
        'liuyao-transfer-',
      );
      final file = File('${directory.path}/${exported.filename}');
      await file.writeAsString(exported.content, encoding: utf8, flush: true);
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          title: '六爻档案迁移包',
          subject: '六爻档案批量迁移（$_totalCount 条）',
          text: '完整包含卦面、解读与反馈；请在另一台设备的“档案迁移”中导入。',
          files: [XFile(file.path, mimeType: exported.contentType)],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } on Object catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _transferring = false);
    }
  }

  Future<void> _pickAndImport() async {
    const jsonGroup = XTypeGroup(
      label: '六爻档案 JSON',
      extensions: ['json'],
      mimeTypes: ['application/json'],
    );
    try {
      final selected = await openFile(acceptedTypeGroups: [jsonGroup]);
      if (selected == null || !mounted) return;
      final length = await selected.length();
      if (length > archiveImportMaxBytes) {
        throw const FormatException('迁移文件超过 64 MB 上限');
      }
      final bytes = await selected.readAsBytes();
      final content = decodeArchiveTransferBytes(bytes);
      final preview = await _client.inspectImport(content);
      if (!mounted) return;
      final mode = await showModalBottomSheet<ArchiveImportMode>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: context.lc.paperRaised,
        builder: (context) => _ImportReviewSheet(preview: preview),
      );
      if (!mounted || mode == null) return;
      if (mode == ArchiveImportMode.replaceAll) {
        final confirmed = await _confirmReplace(preview.totalCases);
        if (!confirmed || !mounted) return;
      }
      setState(() => _transferring = true);
      final result = await _client.importCases(content, mode: mode);
      await _load();
      if (!mounted) return;
      final conflictNote = result.copiedConflicts == 0
          ? ''
          : '，${result.copiedConflicts} 条冲突保留为副本';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '已导入 ${result.importedCases} 条，跳过 ${result.skippedCases} 条$conflictNote',
          ),
        ),
      );
    } on Object catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _transferring = false);
    }
  }

  Future<bool> _confirmReplace(int incomingCount) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('清空本机档案并恢复？'),
          content: Text(
            '本机现有 ${_cases.length} 条档案将被迁移文件中的 $incomingCount 条完全替换。此操作无法撤销，建议先批量导出本机档案。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              key: const Key('import-replace-confirm'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认清空并恢复'),
            ),
          ],
        ),
      ) ??
      false;

  void _showError(Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_message(error))));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    if (_ownsClient) _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            key: const Key('archive-scroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
                sliver: SliverToBoxAdapter(child: _buildHeader()),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                sliver: SliverToBoxAdapter(child: _buildSearch()),
              ),
              if (_allTags.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  sliver: SliverToBoxAdapter(child: _buildTagFilter()),
                ),
              if (_loading)
                const SliverToBoxAdapter(
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              if (_error != null && _cases.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(14),
                  sliver: SliverToBoxAdapter(
                    child: _ErrorCard(message: _error!),
                  ),
                ),
              if (!_loading && _cases.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyArchive(error: _error, onRetry: _load),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
                  sliver: SliverList.separated(
                    itemCount: _cases.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    // 2026-09-01 需求：卡片支持滑动呼出删除（挂历式），
                    // confirmDismiss 内做二次确认；左右滑均可触发。
                    itemBuilder: (context, index) {
                      final summary = _cases[index];
                      return Dismissible(
                        key: Key('archive-swipe-${summary.id}'),
                        direction: DismissDirection.horizontal,
                        // 卡片已整体滑出屏，收拢动画交给下方同步 setState 移除；
                        // 保留默认 resize 动画会让已完成的 resize widget 在
                        // 列表刷新时被再 build 一次，触发树内残留断言。
                        resizeDuration: null,
                        background: _swipeDeleteBackground(
                          context: context,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 24),
                        ),
                        secondaryBackground: _swipeDeleteBackground(
                          context: context,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                        ),
                        confirmDismiss: (_) => _confirmDeleteDialog(summary),
                        onDismissed: (_) {
                          // 同步先移除，避免被滑走的 Dismissible 仍留在树里。
                          // 注意：必须用赋值新列表代替原地 removeWhere——
                          // 数据源返回的可能是固定长度/不可变列表，原地
                          // 修改会抛 UnsupportedError，导致 _deleteCase 不
                          // 执行、档案实际未删除（2026-09 左滑删除 bug）。
                          setState(
                            () => _cases = _cases
                                .where((item) => item.id != summary.id)
                                .toList(),
                          );
                          _deleteCase(summary);
                        },
                        child: _CaseCard(
                          item: summary,
                          onTap: () => _open(summary),
                          onLongPress: () => _confirmDelete(summary),
                          onTagSelected: _selectTag,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '案例库',
                style: TextStyle(
                  color: context.lc.inkMuted,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              // 「道谕六爻」品牌标题统一组件（本页为样式基准）。
              const DaoyuBrandTitle(keyOverride: Key('archive-title')),
              const SizedBox(height: 6),
              Text(
                '本机持久保存 · 退出后台或重启后仍会保留',
                style: TextStyle(color: context.lc.inkMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.filledTonal(
              key: const Key('archive-transfer'),
              tooltip: '批量导入与导出',
              onPressed: _loading || _transferring ? null : _showTransfer,
              icon: _transferring
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.swap_horiz_rounded),
            ),
            const SizedBox(width: 6),
            IconButton.filledTonal(
              tooltip: '刷新档案',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return Container(
      decoration: BoxDecoration(
        color: context.lc.paperRaised,
        borderRadius: BorderRadius.circular(LiuyaoRadii.card),
        border: Border.all(color: context.lc.inkFaint, width: .8),
      ),
      child: TextField(
        key: const Key('archive-search'),
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _load(),
        decoration: InputDecoration(
          hintText: '搜索占问、卦名、解读或反馈',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  tooltip: '清除搜索',
                  onPressed: () {
                    _searchController.clear();
                    _load();
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildTagFilter() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount:
            _allTags.length +
            (_activeTags.isNotEmpty ? 1 : 0) +
            1, // 尾部固定「＋」新增标签入口。
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final hasClear = _activeTags.isNotEmpty;
          // 首位为「清除筛选」入口（有活动筛选时）。
          if (hasClear && index == 0) {
            return FilterChip(
              key: const Key('tag-filter-clear'),
              label: const Text('清除筛选'),
              selected: false,
              onSelected: (_) {
                setState(_activeTags.clear);
                _load();
              },
              backgroundColor: context.lc.paperRaised,
              selectedColor: context.lc.paperRaised,
              side: BorderSide(color: context.lc.inkFaint),
            );
          }
          final tagIndex = index - (hasClear ? 1 : 0);
          if (tagIndex < _allTags.length) {
            return _tagChip(_allTags[tagIndex]);
          }
          return ActionChip(
            key: const Key('tag-filter-add'),
            label: const Text('＋ 标签'),
            onPressed: _manageTags,
            backgroundColor: context.lc.paperRaised,
            side: BorderSide(color: context.lc.inkFaint),
            labelStyle: TextStyle(
              color: context.lc.cinnabar,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          );
        },
      ),
    );
  }

  /// 档案页「＋」：新建自定义标签（持久化），供筛选与各档案快速选用。
  Future<void> _manageTags() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.lc.paperRaised,
      isScrollControlled: true,
      builder: (context) =>
          _TagManagerSheet(allTags: _allTags, caseCountByTag: _tagCounts),
    );
    if (mounted) _load();
  }

  Widget _tagChip(String tag) {
    final selected = _activeTags.contains(tag);
    return FilterChip(
      key: Key('tag-filter-$tag'),
      label: Text(tag),
      selected: selected,
      onSelected: (_) {
        setState(() {
          if (selected) {
            _activeTags.remove(tag);
          } else {
            _activeTags.add(tag);
          }
        });
        _load();
      },
      backgroundColor: context.lc.paperRaised,
      selectedColor: context.lc.cinnabar.withValues(alpha: .15),
      checkmarkColor: context.lc.cinnabar,
      labelStyle: TextStyle(
        color: selected ? context.lc.cinnabar : context.lc.inkMuted,
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: selected ? context.lc.cinnabar : context.lc.inkFaint,
      ),
    );
  }

  String _message(Object error) =>
      error.toString().replaceFirst(RegExp(r'^.*Exception: '), '');
}

class _TransferSheet extends StatelessWidget {
  const _TransferSheet({required this.caseCount});

  final int caseCount;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '档案迁移',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            '当前本机共 $caseCount 条档案。迁移包完整保留卦面快照、全部解读版本和反馈记录。',
            style: TextStyle(color: context.lc.inkMuted, height: 1.5),
          ),
          const SizedBox(height: 16),
          _TransferChoice(
            key: const Key('transfer-export-all'),
            icon: Icons.archive_outlined,
            title: '批量导出全部档案',
            description: '生成一个 JSON 迁移包，通过系统分享发送到其他设备',
            onTap: () => Navigator.pop(context, 'export'),
          ),
          const SizedBox(height: 10),
          _TransferChoice(
            key: const Key('transfer-import'),
            icon: Icons.unarchive_outlined,
            title: '导入档案迁移包',
            description: '先预检内容，再选择安全合并或清空后恢复',
            onTap: () => Navigator.pop(context, 'import'),
          ),
          const SizedBox(height: 14),
          const _MigrationNotice(),
        ],
      ),
    ),
  );
}

class _TransferChoice extends StatelessWidget {
  const _TransferChoice({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: context.lc.parchment.withValues(alpha: .48),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(LiuyaoRadii.card),
      side: BorderSide(color: context.lc.inkFaint),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LiuyaoRadii.card),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.lc.paperRaised,
                border: Border.all(color: context.lc.inkFaint),
                borderRadius: BorderRadius.circular(LiuyaoRadii.small),
              ),
              child: Icon(icon, color: context.lc.cinnabar),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      color: context.lc.inkMuted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.lc.inkMuted),
          ],
        ),
      ),
    ),
  );
}

class _MigrationNotice extends StatelessWidget {
  const _MigrationNotice();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(LiuyaoRadii.small),
      border: Border.all(color: context.lc.inkFaint),
    ),
    child: Text(
      '迁移文件可能包含私人占问内容，请使用可信渠道传输并妥善保管。',
      style: TextStyle(color: context.lc.inkMuted, height: 1.45, fontSize: 12),
    ),
  );
}

class _ImportReviewSheet extends StatelessWidget {
  const _ImportReviewSheet({required this.preview});

  final ArchiveImportPreview preview;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '检查迁移文件',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 5),
          Text(
            preview.sourceLabel,
            style: TextStyle(
              color: context.lc.cinnabar,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.lc.parchment.withValues(alpha: .45),
              borderRadius: BorderRadius.circular(LiuyaoRadii.card),
              border: Border.all(color: context.lc.inkFaint),
            ),
            child: Wrap(
              spacing: 22,
              runSpacing: 12,
              children: [
                _ImportMetric(label: '档案', value: preview.totalCases),
                _ImportMetric(label: '新增', value: preview.newCases),
                _ImportMetric(label: '相同', value: preview.identicalCases),
                _ImportMetric(label: '冲突', value: preview.conflictingCases),
                _ImportMetric(label: '解读', value: preview.analysisCount),
                _ImportMetric(label: '反馈', value: preview.feedbackCount),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('import-merge'),
            onPressed: () => Navigator.pop(context, ArchiveImportMode.merge),
            icon: const Icon(Icons.call_merge_rounded),
            label: const Text('安全合并（推荐）'),
          ),
          const SizedBox(height: 8),
          Text(
            '相同档案自动跳过；同 ID 但内容不同的档案保留为“导入副本”，不覆盖本机记录。',
            style: TextStyle(
              color: context.lc.inkMuted,
              height: 1.4,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            key: const Key('import-replace'),
            onPressed: () =>
                Navigator.pop(context, ArchiveImportMode.replaceAll),
            icon: const Icon(Icons.restore_rounded),
            label: const Text('清空本机并从迁移包恢复'),
          ),
        ],
      ),
    ),
  );
}

class _ImportMetric extends StatelessWidget {
  const _ImportMetric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 72,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: context.lc.ink,
            fontSize: 21,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(label, style: TextStyle(color: context.lc.inkMuted, fontSize: 11)),
      ],
    ),
  );
}

/// 滑动删除背景（挂历式）：朱砂底 + 删除图标与文字，圆角与卡片一致。
Widget _swipeDeleteBackground({
  required BuildContext context,
  required Alignment alignment,
  required EdgeInsets padding,
}) {
  return Container(
    decoration: BoxDecoration(
      color: context.lc.cinnabar.withValues(alpha: .92),
      borderRadius: BorderRadius.circular(12),
    ),
    alignment: alignment,
    padding: padding,
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.delete_outline, color: Colors.white, size: 22),
        SizedBox(width: 6),
        Text(
          '删除',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({
    required this.item,
    required this.onTap,
    required this.onTagSelected,
    this.onLongPress,
  });

  final CaseSummary item;
  final VoidCallback onTap;
  final ValueChanged<String> onTagSelected;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final transition = item.changedHexagram == null
        ? '${item.baseHexagram} · 静卦'
        : '${item.baseHexagram} 之 ${item.changedHexagram}';
    return Material(
      color: context.lc.paperRaised,
      borderRadius: BorderRadius.circular(LiuyaoRadii.card),
      child: InkWell(
        key: Key('archive-case-${item.id}'),
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(LiuyaoRadii.card),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.ds.hairline, width: 1),
          ),
          child: Row(
            children: [
              SizedBox(
                key: Key('archive-seal-${item.id}'),
                width: 44,
                height: 44,
                child: Center(
                  child: Text(
                    '卦',
                    // 印章字：用打包的道谕宋（双端一致），不再依赖
                    // Android 上落空的系统衬线链。
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: context.ds.cinnabar,
                      fontFamily: 'DaoyuSong',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.question,
                      key: Key('archive-question-${item.id}'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.lc.ink,
                        fontSize: 15,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(
                      height: 22,
                      child: Row(
                        children: [
                          Text(
                            _dateTime(item.castAt),
                            key: Key('archive-time-${item.id}'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DSTypography.body(
                              fontSize: 11,
                              weight: FontWeight.w400,
                              color: context.ds.textMuted,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              transition,
                              key: Key('archive-transition-${item.id}'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DSTypography.body(
                                fontSize: 11,
                                weight: FontWeight.w400,
                                color: context.ds.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 14, thickness: .8),
                    if (item.tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 26,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: item.tags.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 4),
                          itemBuilder: (context, index) {
                            final tag = item.tags[index];
                            return InkWell(
                              key: Key('card-tag-${item.id}-$tag'),
                              onTap: () => onTagSelected(tag),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: context.ds.paper,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: context.ds.amber.withValues(
                                      alpha: .55,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    color: context.ds.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _dateTime(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} '
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _EmptyArchive extends StatelessWidget {
  const _EmptyArchive({required this.error, required this.onRetry});

  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: context.lc.ink,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: context.lc.paper,
              size: 34,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            error == null ? '还没有保存的卦例' : '暂时无法读取档案',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            error ?? '完成起卦后会自动写入本机；只有卸载应用或主动清除应用数据才会删除。',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.lc.inkMuted, height: 1.5),
          ),
          if (error != null) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重新连接'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.ds.glowCinnabar,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(message, style: TextStyle(color: context.lc.cinnabar)),
  );
}

/// 标签管理底部弹窗：新建自定义标签（持久化到偏好）、查看使用数量、
/// 删除未挂载的自定义标签；已挂档案的标签随档案数据存在，不在此删除。
class _TagManagerSheet extends StatefulWidget {
  const _TagManagerSheet({required this.allTags, required this.caseCountByTag});

  final List<String> allTags;
  final Map<String, int> caseCountByTag;

  @override
  State<_TagManagerSheet> createState() => _TagManagerSheetState();
}

class _TagManagerSheetState extends State<_TagManagerSheet> {
  final _controller = TextEditingController();
  String? _error;
  late List<String> _customTags = List.from(currentPreferences.customTags);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _persist(List<String> tags) async {
    setState(() => _customTags = tags);
    await savePreferences(currentPreferences.copyWith(customTags: tags));
  }

  Future<void> _add() async {
    final tag = _controller.text.trim();
    if (tag.isEmpty) {
      setState(() => _error = '请输入标签文字');
      return;
    }
    if (tag.length > 20) {
      setState(() => _error = '标签最多 20 字');
      return;
    }
    if (widget.allTags.contains(tag) || _customTags.contains(tag)) {
      setState(() => _error = '标签「$tag」已存在');
      return;
    }
    if (_customTags.length + widget.allTags.length >= 60) {
      setState(() => _error = '标签总数最多 60 个');
      return;
    }
    await _persist([..._customTags, tag]);
    setState(() {
      _error = null;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final customSet = _customTags.toSet();
    final archivedTags = widget.allTags
        .where((tag) => !customSet.contains(tag))
        .toList();
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
            '标签分组',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            '新建标签后会出现在筛选行；在卦面详情「编辑标签」中可快速选用。',
            style: TextStyle(
              color: context.lc.inkMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('tag-new-input'),
                  controller: _controller,
                  maxLength: 20,
                  onSubmitted: (_) => _add(),
                  decoration: InputDecoration(
                    hintText: '新标签名',
                    counterText: '',
                    isDense: true,
                    filled: true,
                    fillColor: context.lc.paperRaised,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: context.lc.inkFaint),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: context.lc.cinnabar),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('tag-new-add'),
                onPressed: _add,
                style: FilledButton.styleFrom(
                  backgroundColor: context.lc.cinnabar,
                  minimumSize: const Size(72, 42),
                ),
                child: const Text('添加'),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              style: TextStyle(color: context.lc.cinnabar, fontSize: 12),
            ),
          ],
          const SizedBox(height: 14),
          if (archivedTags.isNotEmpty) ...[
            const Text(
              '已有标签（来自档案）',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final tag in archivedTags)
                  InputChip(
                    key: Key('tag-manage-archived-$tag'),
                    label: Text(
                      '$tag · ${widget.caseCountByTag[tag] ?? 0}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: null,
                    backgroundColor: context.lc.paperRaised,
                    side: BorderSide(color: context.lc.inkFaint),
                  ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          if (_customTags.isNotEmpty) ...[
            const Text(
              '自定义标签',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final tag in _customTags)
                  InputChip(
                    key: Key('tag-manage-custom-$tag'),
                    label: Text(tag, style: const TextStyle(fontSize: 12)),
                    onDeleted: () => _persist(
                      _customTags.where((item) => item != tag).toList(),
                    ),
                    deleteIconColor: context.lc.inkMuted,
                    backgroundColor: context.lc.paperRaised,
                    side: BorderSide(color: context.lc.inkFaint),
                  ),
              ],
            ),
          ] else ...[
            Text(
              '还没有自定义标签；输入名称后点「添加」创建。',
              style: TextStyle(
                color: context.lc.inkMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
