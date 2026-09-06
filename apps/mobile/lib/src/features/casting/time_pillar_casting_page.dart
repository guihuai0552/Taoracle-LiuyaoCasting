import 'package:flutter/material.dart';

import '../../ui/design_system/tokens/ds_theme_extension.dart';
import '../../ui/liuyao_design.dart';
import '../archive/archive_client.dart';
import '../archive/case_detail_page.dart';
import '../settings/app_preferences.dart';
import 'casting_client.dart';

/// 时刻起卦法（时间起卦）页面。
///
/// 引擎 `time_pillar.ke_gan_najia.v2`（时刻起卦法 2.0，用户 2026-09-01 确认）：
/// 念头起时锁定时刻干支；一时辰 120 分钟均分 12 刻，每刻十分钟，
/// 时上起刻法推刻柱；刻干纳甲翻卦为内卦（甲壬乾乙癸坤丙艮丁兑戊坎己离庚震辛巽）、
/// 刻支后天方位翻卦为外卦；动爻取（日干序+时干序）mod 6，余 0 则上爻动。
/// 1.0 内卦取时支，人类活动集中于 7-23 点导致内卦分布偏斜，2.0 予以修正。
/// 本页只提供占问与时刻输入，计算与存档交由
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
    // 问念可空（2026-09-01 需求）：留空时默认「暂无问念」。
    final rawQuestion = _questionController.text.trim();
    if (rawQuestion.length > 1000) {
      setState(() => _error = '占问事项不能超过 1000 字');
      return;
    }
    final question = rawQuestion.isEmpty ? '暂无问念' : rawQuestion;
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.lc.paperRaised,
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
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: ListView(
          key: const Key('time-pillar-casting-scroll'),
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 28),
          children: [
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
              key: const Key('time-pillar-date'),
              icon: Icons.calendar_today_outlined,
              label: '日期',
              value:
                  '${_dateTime.year}-${_two(_dateTime.month)}-${_two(_dateTime.day)}',
              onTap: _pickDate,
            ),
          ),
          Container(width: 1, height: 44, color: context.lc.inkFaint),
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
              Icon(Icons.rule_outlined, color: context.lc.cinnabar, size: 18),
              const SizedBox(width: 8),
              const Text(
                '取数规则',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '刻干 · 刻支 · 日时干序',
                style: TextStyle(color: context.lc.inkMuted, fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '内卦 = 刻干纳甲翻卦（甲壬乾 乙癸坤 丙艮 丁兑 戊坎 己离 庚震 辛巽）\n'
            '外卦 = 刻支后天方位翻卦（子坎 丑寅艮 卯震 辰巳巽 午离 未申坤 酉兑 戌亥乾）\n'
            '动爻 =（日干序数 + 时干序数）mod 6，余 0 取上爻',
            style: TextStyle(
              color: context.lc.inkMuted,
              fontSize: 11,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '念头起时锁定时刻干支；一时辰 120 分钟均分 12 刻，每刻十分钟，\n'
            '时上起刻法推刻柱（时辰内 0-9 分为子刻、10-19 为丑刻，依此类推）。',
            style: TextStyle(
              color: context.lc.inkMuted,
              fontSize: 10,
              height: 1.6,
            ),
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
              minimumSize: const Size.fromHeight(44),
              side: BorderSide(color: context.lc.cinnabar),
              foregroundColor: context.lc.ink,
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
              minimumSize: const Size.fromHeight(44),
              backgroundColor: context.lc.cinnabar,
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
      color: context.lc.paperRaised,
      borderRadius: BorderRadius.circular(LiuyaoRadii.card),
      border: Border.all(color: context.lc.inkFaint, width: .8),
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
            Icon(icon, color: context.lc.cinnabar, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.lc.inkMuted, fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.lc.ink,
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
        // v1.0：警示卡走暗红族（glowWarning），不再借用动爻信号色。
        color: context.ds.glowWarning,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.ds.signalPlum.withValues(alpha: .33)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: context.lc.cinnabar, size: 18),
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
          Text(
            '将按「时刻起卦法 2.0」取数成卦：念头起时锁定时刻干支，'
            '以刻干纳甲为内卦、刻支方位为外卦，日干与时干序数定动爻，并保存为档案。',
            style: TextStyle(color: context.lc.inkMuted, fontSize: 11),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    side: BorderSide(color: context.lc.cinnabar),
                  ),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    backgroundColor: context.lc.cinnabar,
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
        color: context.lc.parchment,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.lc.inkMuted,
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
