import 'package:flutter/material.dart';

import 'archive_client.dart';
import 'archive_models.dart';
import 'case_detail_page.dart';
import 'new_case_page.dart';

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key});

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  final ArchiveClient _client = ArchiveClient();
  List<CaseSummary> _cases = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cases = await _client.listCases();
      if (mounted) setState(() => _cases = cases);
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final detail = await Navigator.push<CaseDetail>(
      context,
      MaterialPageRoute(builder: (_) => NewCasePage(client: _client)),
    );
    if (detail == null || !mounted) return;
    setState(() => _cases = [detail, ..._cases]);
    await _open(detail);
  }

  Future<void> _open(CaseSummary summary) async {
    try {
      final detail = summary is CaseDetail
          ? summary
          : await _client.getCase(summary.id);
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
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              title: const Text('六爻存档'),
              actions: [
                IconButton.filledTonal(
                  tooltip: '新建卦例',
                  onPressed: _create,
                  icon: const Icon(Icons.add),
                ),
                const SizedBox(width: 12),
              ],
              bottom: _loading
                  ? const PreferredSize(
                      preferredSize: Size.fromHeight(2),
                      child: LinearProgressIndicator(minHeight: 2),
                    )
                  : null,
            ),
            if (_cases.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyArchive(onCreate: _create, error: _error),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList.separated(
                  itemCount: _cases.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _cases[index];
                    return Card(
                      child: ListTile(
                        onTap: () => _open(item),
                        contentPadding: const EdgeInsets.all(18),
                        leading: const CircleAvatar(child: Text('卦')),
                        title: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${item.baseHexagram}${item.changedHexagram == null ? '' : ' → ${item.changedHexagram}'}\n${item.question}',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        trailing: item.latestAnalysisRevision > 0
                            ? Badge(
                                label: Text('${item.latestAnalysisRevision}'),
                                child: const Icon(Icons.chevron_right),
                              )
                            : const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyArchive extends StatelessWidget {
  const _EmptyArchive({required this.onCreate, required this.error});

  final VoidCallback onCreate;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text('把每一次占问留下来', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            error == null
                ? '记录问题、起卦时间、卦象与后续验证，逐渐形成自己的案例库。'
                : '本地服务尚未连接。启动排盘引擎和 Agent 服务后即可建档。',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('新建第一条记录'),
          ),
        ],
      ),
    );
  }
}
