import 'package:flutter/material.dart';

import '../../ui/design_system/tokens/ds_colors.dart';
import '../../ui/liuyao_design.dart';
import '../archive/archive_client.dart';
import '../archive/case_detail_page.dart';
import '../settings/app_preferences.dart';
import 'casting_client.dart';

const _ink = LiuyaoColors.ink;
const _mutedInk = LiuyaoColors.inkMuted;
const _cinnabar = LiuyaoColors.cinnabar;
const _paper = LiuyaoColors.paperRaised;
const _softPaper = LiuyaoColors.parchment;
const _rule = LiuyaoColors.inkFaint;

class AutomaticCastingPage extends StatefulWidget {
  const AutomaticCastingPage({
    super.key,
    this.dataSource,
    this.archiveDataSource,
    this.initialDateTime,
  });

  final CastingDataSource? dataSource;
  final ArchiveDataSource? archiveDataSource;
  final DateTime? initialDateTime;

  @override
  State<AutomaticCastingPage> createState() => _AutomaticCastingPageState();
}

class _AutomaticCastingPageState extends State<AutomaticCastingPage> {
  late final CastingDataSource _dataSource;
  late final bool _ownsDataSource;
  late final ArchiveDataSource _archiveClient;
  late final bool _ownsArchiveClient;
  late DateTime _dateTime;
  final _questionController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ownsDataSource = widget.dataSource == null;
    _dataSource = widget.dataSource ?? CastingClient();
    _ownsArchiveClient = widget.archiveDataSource == null;
    _archiveClient = widget.archiveDataSource ?? ArchiveClient();
    final initial = widget.initialDateTime ?? DateTime.now();
    _dateTime = DateTime(
      initial.year,
      initial.month,
      initial.day,
      initial.hour,
      initial.minute,
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(1901, 2, 19),
      lastDate: DateTime(2100, 2, 8),
      helpText: '选择起卦日期',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (selected == null || !mounted) return;
    setState(() {
      _dateTime = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _dateTime.hour,
        _dateTime.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
      helpText: '选择起卦时间',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (selected == null || !mounted) return;
    setState(() {
      _dateTime = DateTime(
        _dateTime.year,
        _dateTime.month,
        _dateTime.day,
        selected.hour,
        selected.minute,
      );
    });
  }

  Future<void> _reviewAndCast() async {
    // 问念可空（2026-09-01 需求）：留空时默认「暂无问念」。
    final rawQuestion = _questionController.text.trim();
    if (rawQuestion.length > 1000) {
      setState(() => _error = '占问事项不能超过 1000 字');
      return;
    }
    final question = rawQuestion.isEmpty ? '暂无问念' : rawQuestion;
    FocusScope.of(context).unfocus();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('开始自动起卦？'),
        content: const Text('系统将连续完成六次三枚铜钱投掷，保存每一枚 2/3 原值，并自动建立档案。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const Key('confirm-automatic-cast'),
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: LiuyaoColors.cinnabar),
            child: const Text('确认开始'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _cast(question);
  }

  Future<void> _cast(String question) async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final preview = await _dataSource.previewAutomatic(
        question: question,
        dateTime: _dateTime,
        dayBoundary: currentPreferences.dayBoundaryStrategy,
        monthBoundary: currentPreferences.monthBoundaryStrategy,
      );
      final detail = await _archiveClient.saveCast(
        question: question,
        preview: preview,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => CaseDetailPage(
            client: _archiveClient,
            initialDetail: detail,
            openedAfterCasting: true,
          ),
        ),
      );
    } on Object catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted && _submitting) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    if (_ownsArchiveClient) _archiveClient.close();
    if (_ownsDataSource) _dataSource.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListView(
        key: const Key('automatic-casting-scroll'),
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 28),
        children: [
          _buildQuestion(),
          const SizedBox(height: 12),
          _buildDateTime(),
          const SizedBox(height: 14),
          const _AutomaticMethodCard(),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _InlineError(message: _error!),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const Key('automatic-cast'),
            onPressed: _submitting ? null : _reviewAndCast,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              backgroundColor: LiuyaoColors.cinnabar,
            ),
            icon: _submitting
                ? const SizedBox.square(
                    dimension: 19,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.casino_outlined),
            label: Text(_submitting ? '正在排盘并存档…' : '开始摇卦'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: _cardDecoration(),
      child: TextField(
        key: const Key('automatic-question'),
        controller: _questionController,
        minLines: 2,
        maxLines: 4,
        maxLength: 1000,
        decoration: const InputDecoration(
          labelText: '占问事项',
          hintText: '可不填，留空记为「暂无问念」；写清楚对象与背景更好',
          border: InputBorder.none,
          counterText: '',
        ),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
      ),
    );
  }

  Widget _buildDateTime() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: _DateTimeButton(
              icon: Icons.calendar_today_outlined,
              label: '日期',
              value:
                  '${_dateTime.year}-${_two(_dateTime.month)}-${_two(_dateTime.day)}',
              onTap: _pickDate,
            ),
          ),
          Container(width: 1, height: 44, color: _rule),
          Expanded(
            child: _DateTimeButton(
              icon: Icons.schedule_outlined,
              label: '北京时间',
              value: '${_two(_dateTime.hour)}:${_two(_dateTime.minute)}',
              onTap: _pickTime,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: _paper,
      borderRadius: BorderRadius.circular(LiuyaoRadii.card),
      border: Border.all(color: _rule, width: .8),
    );
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  String _message(Object error) {
    return error.toString().replaceFirst(RegExp(r'^.*Exception: '), '');
  }
}

class _AutomaticMethodCard extends StatelessWidget {
  const _AutomaticMethodCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _softPaper,
        borderRadius: BorderRadius.circular(LiuyaoRadii.card),
        border: Border.all(color: _rule, width: .8),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              children: [
                Positioned(left: 0, top: 10, child: _MiniCoin(value: 2)),
                Positioned(left: 15, top: 0, child: _MiniCoin(value: 3)),
                Positioned(left: 23, top: 18, child: _MiniCoin(value: 2)),
              ],
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '三枚铜钱 × 六次',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  '每爻保存 2/3 原值、求和和动静；生产结果使用系统随机源。',
                  style: TextStyle(color: _mutedInk, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCoin extends StatelessWidget {
  const _MiniCoin({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 27,
      height: 27,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: value == 3 ? _ink : _softPaper,
        border: Border.all(color: _rule),
      ),
      child: Text(
        '$value',
        style: TextStyle(
          color: value == 3 ? Colors.white : _ink,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DateTimeButton extends StatelessWidget {
  const _DateTimeButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: _cinnabar),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: _mutedInk, fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('automatic-error'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DSColors.glowCinnabar,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: _cinnabar, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
