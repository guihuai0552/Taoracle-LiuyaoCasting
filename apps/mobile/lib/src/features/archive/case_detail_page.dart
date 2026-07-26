import 'package:flutter/material.dart';

import '../agent/agent_page.dart';
import 'archive_client.dart';
import 'archive_models.dart';

class CaseDetailPage extends StatefulWidget {
  const CaseDetailPage({
    required this.client,
    required this.initialDetail,
    super.key,
  });

  final ArchiveClient client;
  final CaseDetail initialDetail;

  @override
  State<CaseDetailPage> createState() => _CaseDetailPageState();
}

class _CaseDetailPageState extends State<CaseDetailPage> {
  late CaseDetail _detail;
  final _analysisController = TextEditingController();
  bool _saving = false;
  String? _error;

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

  Future<void> _saveAnalysis() async {
    final body = _analysisController.text.trim();
    if (body.isEmpty || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.client.appendUserAnalysis(
        caseId: _detail.id,
        body: body,
        expectedRevision: _detail.latestAnalysisRevision,
      );
      final refreshed = await widget.client.getCase(_detail.id);
      if (mounted) {
        setState(() => _detail = refreshed);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('分析已保存为新版本')));
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _analysisController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chart = _detail.chart;
    return Scaffold(
      appBar: AppBar(
        title: Text(_detail.title),
        actions: [
          IconButton(
            tooltip: '带此卦例询问 Agent',
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => AgentPage(caseId: _detail.id)),
            ),
            icon: const Icon(Icons.auto_awesome),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          Text(_detail.question, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _MetaChip(label: '${chart.year}年 ${chart.month}月 ${chart.day}日'),
              _MetaChip(label: '${chart.hour}时'),
              _MetaChip(label: '空亡 ${chart.dayVoid}'),
            ],
          ),
          const SizedBox(height: 24),
          _ChartBoard(chart: chart),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: Text(
                  '我的分析',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text('当前版本 ${_detail.latestAnalysisRevision}'),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _analysisController,
            minLines: 8,
            maxLines: 20,
            decoration: const InputDecoration(
              hintText: '记录取用神、旺衰、动变、应期和自己的判断…',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _saving ? null : _saveAnalysis,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('保存新版本'),
          ),
          if (_detail.analyses.isNotEmpty) ...[
            const SizedBox(height: 28),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('分析历史'),
              subtitle: Text('${_detail.analyses.length} 个版本'),
              children: _detail.analyses.reversed
                  .map(
                    (analysis) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '版本 ${analysis.revision} · ${analysis.author == 'user' ? '我的分析' : 'Agent 分析'}',
                      ),
                      subtitle: Text(
                        analysis.body,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Chip(label: Text(label));
}

class _ChartBoard extends StatelessWidget {
  const _ChartBoard({required this.chart});

  final ChartSnapshot chart;

  @override
  Widget build(BuildContext context) {
    final changed = chart.changed;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _HexagramColumn(hexagram: chart.base, showFacts: true),
                ),
                if (changed != null) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(4, 50, 4, 0),
                    child: Icon(Icons.arrow_forward, size: 18),
                  ),
                  Expanded(
                    child: _HexagramColumn(hexagram: changed, showFacts: false),
                  ),
                ],
              ],
            ),
            const Divider(height: 28),
            Text(
              '原始爻值（初爻至上爻）：${chart.lineValues.join(' · ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _HexagramColumn extends StatelessWidget {
  const _HexagramColumn({required this.hexagram, required this.showFacts});

  final ChartHexagram hexagram;
  final bool showFacts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(hexagram.name, style: Theme.of(context).textTheme.titleLarge),
        Text('${hexagram.palaceName}宫 · ${hexagram.palaceElement}'),
        const SizedBox(height: 14),
        ...hexagram.lines.reversed.map(
          (line) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: _ChartLineRow(line: line, showFacts: showFacts),
          ),
        ),
      ],
    );
  }
}

class _ChartLineRow extends StatelessWidget {
  const _ChartLineRow({required this.line, required this.showFacts});

  final ChartLine line;
  final bool showFacts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            if (showFacts)
              SizedBox(
                width: 28,
                child: Text(
                  line.sixGod ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            Expanded(child: _YaoGlyph(yin: line.yinYang == 'yin')),
            SizedBox(
              width: 28,
              child: Text(
                line.changing
                    ? (line.yinYang == 'yin' ? '×' : '○')
                    : (line.role ?? ''),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${line.relation} ${line.branch}${line.element}${line.role == null ? '' : ' · ${line.role}'}',
          style: Theme.of(context).textTheme.bodySmall,
          overflow: TextOverflow.ellipsis,
        ),
        if (showFacts && line.hidden != null)
          Text(
            '伏 ${line.hidden!.relation} ${line.hidden!.branch}${line.hidden!.element}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
      ],
    );
  }
}

class _YaoGlyph extends StatelessWidget {
  const _YaoGlyph({required this.yin});

  final bool yin;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final segment = Container(height: 4, color: color);
    if (!yin) return segment;
    return Row(
      children: [
        Expanded(child: segment),
        const SizedBox(width: 7),
        Expanded(child: Container(height: 4, color: color)),
      ],
    );
  }
}
