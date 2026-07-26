import 'package:flutter/material.dart';

import 'archive_client.dart';
import 'archive_models.dart';

class NewCasePage extends StatefulWidget {
  const NewCasePage({required this.client, super.key});

  final ArchiveClient client;

  @override
  State<NewCasePage> createState() => _NewCasePageState();
}

class _NewCasePageState extends State<NewCasePage> {
  final _titleController = TextEditingController();
  final _questionController = TextEditingController();
  final _lineValues = List<int>.filled(6, 8);
  bool _manual = false;
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || _submitting) {
      setState(() => _error = question.isEmpty ? '请先填写占问事项' : null);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final detail = await widget.client.createCase(
        title: _titleController.text.trim(),
        question: question,
        timestamp: DateTime.now(),
        manual: _manual,
        lineValues: _manual ? _lineValues : null,
      );
      if (mounted) Navigator.pop<CaseDetail>(context, detail);
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新建卦例')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '标题（可选）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _questionController,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: '占问事项',
              hintText: '尽量写清楚对象、背景和想确认的问题',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.casino_outlined),
                label: Text('自动铜钱'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.edit_outlined),
                label: Text('手工录入'),
              ),
            ],
            selected: {_manual},
            onSelectionChanged: (value) =>
                setState(() => _manual = value.first),
          ),
          if (_manual) ...[
            const SizedBox(height: 20),
            Text('按初爻到上爻录入', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...List.generate(6, (index) {
              final label = ['初爻', '二爻', '三爻', '四爻', '五爻', '上爻'][index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(label),
                trailing: DropdownButton<int>(
                  value: _lineValues[index],
                  items: const [6, 7, 8, 9]
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text('$value  ${_lineDescription(value)}'),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _lineValues[index] = value);
                    }
                  },
                ),
              );
            }),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_submitting ? '正在排盘…' : '排盘并存档'),
          ),
        ],
      ),
    );
  }
}

String _lineDescription(int value) => switch (value) {
  6 => '老阴',
  7 => '少阳',
  8 => '少阴',
  9 => '老阳',
  _ => '',
};
