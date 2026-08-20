import 'package:flutter/material.dart';

import '../../ui/liuyao_design.dart';
import '../archive/archive_client.dart';
import '../archive/case_detail_page.dart';
import 'casting_client.dart';

const _ink = LiuyaoColors.ink;
const _mutedInk = LiuyaoColors.inkMuted;
const _cinnabar = LiuyaoColors.cinnabar;
const _paper = LiuyaoColors.paperRaised;
const _rule = LiuyaoColors.inkFaint;

/// 时刻起卦法（时间起卦）页面。
///
/// 引擎 `time_pillar.shichen_ke_houtian.v1`（附件《时刻起卦法详解(1)》）：
/// 一时辰 120 分钟均分 12 刻，每刻十分钟；五鼠遁推时柱/刻柱天干；
/// 时支后天八卦为内卦、刻支后天八卦为外卦；动爻取（时干序+刻干序）mod 6，
/// 余 0 则上爻动。本页只提供占问与时刻输入，计算与存档交由
/// [CastingDataSource.previewTimePillar] 与 [ArchiveDataSource.saveCast]。
class TimePillarCastingPage extends StatefulWidget {
  const TimePillarCastingPage({
    super.key,
    this.dataSource,
    this.archiveDataSource,
    this.initialDateTime,
  });

  final CastingDataSource? dataSource;
  final ArchiveDataSource? archiveDataSource;
  final DateTime? initialDateTime;

  @override
  State<TimePillarCastingPage> createState() => _TimePillarCastingPageState();
}

class _TimePillarCastingPageState extends State<TimePillarCastingPage> {
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

  @override
  void dispose() {
    _questionController.dispose();
    if (_ownsArchiveClient) _archiveClient.close();
    if (_ownsDataSource) _dataSource.close();
    super.dispose();
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

  Future<void> _reviewAndSubmit() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      setState(() => _error = '请先填写占问事项');
      return;
    }
    if (question.length > 1000) {
      setState(() => _error = '占问事项不能超过 1000 字');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _paper,
      builder: (context) =>
          _TimePillarConfirmation(question: question, dateTime: _dateTime),
    );
    if (confirmed != true || !mounted) return;
    await _submit(question);
  }

  Future<void> _submit(String question) async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final preview = await _dataSource.previewTimePillar(
        question: question,
        dateTime: _dateTime,
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
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: ListView(
          key: const Key('time-pillar-casting-scroll'),
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 28),
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            _buildQuestion(),
            const SizedBox(height: 12),
            _buildDateTime(),
            const SizedBox(height: 14),
            _buildMethodCard(),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _InlineError(message: _error!),
            ],
            const SizedBox(height: 18),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '六爻',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: _cinnabar,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '时刻起卦',
                key: const Key('time-pillar-casting-title'),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '一时辰十二刻·每刻十分钟，按时辰与刻柱起卦',
                style: TextStyle(color: _mutedInk),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _ink,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            '时刻模式',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: _cardDecoration(),
      child: TextField(
        key: const Key('time-pillar-question'),
        controller: _questionController,
        minLines: 2,
        maxLines: 4,
        maxLength: 1000,
        decoration: const InputDecoration(
          labelText: '占问事项',
          hintText: '写清楚对象、背景和想确认的问题',
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
              key: const Key('time-pillar-date'),
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
              key: const Key('time-pillar-time'),
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

  Widget _buildMethodCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rule_outlined, color: _cinnabar, size: 18),
              const SizedBox(width: 8),
              const Text(
                '取数规则',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '时支 · 刻支 · 天干序数',
                style: TextStyle(color: _mutedInk, fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '内卦 = 时支后天八卦（下卦）\n'
            '外卦 = 刻支后天八卦（上卦）\n'
            '动爻 =（时干序数 + 刻干序数）mod 6，余 0 取上爻',
            style: const TextStyle(color: _mutedInk, fontSize: 11, height: 1.7),
          ),
          const SizedBox(height: 6),
          Text(
            '一时辰 120 分钟均分 12 刻，每刻十分钟；\n'
            '时辰内 0-9 分为子刻、10-19 为丑刻，依此类推。',
            style: const TextStyle(color: _mutedInk, fontSize: 10, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            key: const Key('reset-time-pillar'),
            onPressed: _submitting ? null : _resetDateTime,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              side: const BorderSide(color: _cinnabar),
              foregroundColor: _ink,
            ),
            child: const Text('重置'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            key: const Key('review-time-pillar-cast'),
            onPressed: _submitting ? null : _reviewAndSubmit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: _cinnabar,
            ),
            child: _submitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('排盘'),
          ),
        ),
      ],
    );
  }

  void _resetDateTime() {
    final now = DateTime.now();
    setState(() {
      _dateTime = DateTime(now.year, now.month, now.day, now.hour, now.minute);
      _error = null;
    });
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

class _DateTimeButton extends StatelessWidget {
  const _DateTimeButton({
    super.key,
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
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: _cinnabar, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _mutedInk, fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8E8DF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x55B3261E)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: _cinnabar, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _TimePillarConfirmation extends StatelessWidget {
  const _TimePillarConfirmation({
    required this.question,
    required this.dateTime,
  });

  final String question;
  final DateTime dateTime;

  String _two(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '确认起卦',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _ConfirmationRow(label: '占问事项', value: question),
          const SizedBox(height: 8),
          _ConfirmationRow(
            label: '起卦时刻',
            value:
                '${dateTime.year}-${_two(dateTime.month)}-${_two(dateTime.day)} '
                '${_two(dateTime.hour)}:${_two(dateTime.minute)}',
          ),
          const SizedBox(height: 8),
          const Text(
            '将按「时刻起卦法」取数成卦：一时辰十二刻、每刻十分钟，'
            '按时辰与刻柱推定本卦与动爻，并保存为档案。',
            style: TextStyle(color: _mutedInk, fontSize: 11),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    side: const BorderSide(color: _cinnabar),
                  ),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: _cinnabar,
                  ),
                  child: const Text('确认排盘'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfirmationRow extends StatelessWidget {
  const _ConfirmationRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: LiuyaoColors.parchment,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _mutedInk,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
