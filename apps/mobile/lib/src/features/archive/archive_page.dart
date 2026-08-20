import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'archive_client.dart';
import 'archive_models.dart';
import 'case_detail_page.dart';
import '../../ui/liuyao_design.dart';

const _ink = LiuyaoColors.ink;
const _mutedInk = LiuyaoColors.inkMuted;
const _cinnabar = LiuyaoColors.cinnabar;
const _paper = LiuyaoColors.paperRaised;
const _rule = LiuyaoColors.inkFaint;

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
      for (final item in all) {
        allTags.addAll(item.tags);
      }
      final total = all.length;
      if (mounted) {
        setState(() {
          _cases = cases;
          _totalCount = total;
          _allTags = allTags.toList()
            ..sort((a, b) => a.compareTo(b));
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

  Future<void> _showTransfer() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: _paper,
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
        backgroundColor: _paper,
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
                    itemBuilder: (context, index) => _CaseCard(
                      item: _cases[index],
                      onTap: () => _open(_cases[index]),
                      onTagSelected: _selectTag,
                    ),
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
              const Text(
                '案例库',
                style: TextStyle(
                  color: _cinnabar,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '六爻档案',
                key: const Key('archive-title'),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '本机持久保存 · 退出后台或重启后仍会保留',
                style: TextStyle(color: _mutedInk, fontSize: 12),
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
        color: _paper,
        borderRadius: BorderRadius.circular(LiuyaoRadii.card),
        border: Border.all(color: _rule, width: .8),
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
        itemCount: _allTags.length + (_activeTags.isNotEmpty ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          // 首位为「清除筛选」入口（有活动筛选时）。
          if (_activeTags.isNotEmpty) {
            if (index == 0) {
              return FilterChip(
                key: const Key('tag-filter-clear'),
                label: const Text('清除筛选'),
                selected: false,
                onSelected: (_) {
                  setState(_activeTags.clear);
                  _load();
                },
                backgroundColor: _paper,
                selectedColor: _paper,
                side: const BorderSide(color: _rule),
              );
            }
            final tag = _allTags[index - 1];
            return _tagChip(tag);
          }
          final tag = _allTags[index];
          return _tagChip(tag);
        },
      ),
    );
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
      backgroundColor: _paper,
      selectedColor: _cinnabar.withValues(alpha: .15),
      checkmarkColor: _cinnabar,
      labelStyle: TextStyle(
        color: selected ? _cinnabar : _mutedInk,
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: selected ? _cinnabar : _rule,
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
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '当前本机共 $caseCount 条档案。迁移包完整保留卦面快照、全部解读版本和反馈记录。',
            style: const TextStyle(color: _mutedInk, height: 1.5),
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
    color: LiuyaoColors.parchment.withValues(alpha: .48),
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _paper,
                border: Border.all(color: _rule),
                borderRadius: BorderRadius.circular(LiuyaoRadii.small),
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
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      color: _mutedInk,
                      fontSize: 12,
                      height: 1.4,
                    ),
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

class _MigrationNotice extends StatelessWidget {
  const _MigrationNotice();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(LiuyaoRadii.small),
      border: Border.all(color: _rule),
    ),
    child: const Text(
      '迁移文件可能包含私人占问内容，请使用可信渠道传输并妥善保管。',
      style: TextStyle(color: _mutedInk, height: 1.45, fontSize: 12),
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
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            preview.sourceLabel,
            style: const TextStyle(
              color: _cinnabar,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: LiuyaoColors.parchment.withValues(alpha: .45),
              borderRadius: BorderRadius.circular(LiuyaoRadii.card),
              border: Border.all(color: _rule),
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
          const Text(
            '相同档案自动跳过；同 ID 但内容不同的档案保留为“导入副本”，不覆盖本机记录。',
            style: TextStyle(color: _mutedInk, height: 1.4, fontSize: 12),
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
          style: const TextStyle(
            color: _ink,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(label, style: const TextStyle(color: _mutedInk, fontSize: 11)),
      ],
    ),
  );
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({
    required this.item,
    required this.onTap,
    required this.onTagSelected,
  });

  final CaseSummary item;
  final VoidCallback onTap;
  final ValueChanged<String> onTagSelected;

  @override
  Widget build(BuildContext context) {
    final transition = item.changedHexagram == null
        ? '${item.baseHexagram} · 静卦'
        : '${item.baseHexagram} → ${item.changedHexagram}';
    return Material(
      color: _paper,
      borderRadius: BorderRadius.circular(LiuyaoRadii.card),
      child: InkWell(
        key: Key('archive-case-${item.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(LiuyaoRadii.card),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LiuyaoRadii.card),
            border: Border.all(color: _rule, width: .8),
          ),
          child: Row(
            children: [
              LiuyaoSealMark(
                key: Key('archive-seal-${item.id}'),
                character: '卦',
                label: '卦例',
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
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 15,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Divider(height: 12, thickness: .8),
                    SizedBox(
                      height: 34,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              _dateTime(item.castAt),
                              key: Key('archive-time-${item.id}'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _mutedInk,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(width: .8, height: 18, color: _rule),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: Text(
                              transition,
                              key: Key('archive-transition-${item.id}'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _cinnabar,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item.tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 26,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: item.tags.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: 4),
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
                                  color: _cinnabar.withValues(alpha: .08),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: _cinnabar.withValues(alpha: .3),
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    color: _cinnabar,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
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
            decoration: const BoxDecoration(
              color: _ink,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            error == null ? '还没有保存的卦例' : '暂时无法读取档案',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            error ?? '完成起卦后会自动写入本机；只有卸载应用或主动清除应用数据才会删除。',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _mutedInk, height: 1.5),
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
      color: const Color(0xFFFFEDEA),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(message, style: const TextStyle(color: _cinnabar)),
  );
}
