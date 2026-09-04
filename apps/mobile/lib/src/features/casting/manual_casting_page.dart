import 'package:flutter/material.dart';
import 'package:liuyao_engine/liuyao_engine.dart' as engine;

import '../../ui/design_system/tokens/ds_colors.dart';
import '../../ui/liuyao_design.dart';
import '../archive/archive_client.dart';
import '../archive/case_detail_page.dart';
import '../settings/app_preferences.dart';
import 'casting_client.dart';
import 'casting_models.dart';

const _ink = LiuyaoColors.ink;
const _mutedInk = LiuyaoColors.inkMuted;
const _cinnabar = LiuyaoColors.cinnabar;
const _paper = LiuyaoColors.paperRaised;
const _softPaper = LiuyaoColors.parchment;
const _rule = LiuyaoColors.inkFaint;

class ManualCastingPage extends StatefulWidget {
  const ManualCastingPage({
    super.key,
    this.dataSource,
    this.archiveDataSource,
    this.initialDateTime,
  });

  final CastingDataSource? dataSource;
  final ArchiveDataSource? archiveDataSource;
  final DateTime? initialDateTime;

  @override
  State<ManualCastingPage> createState() => _ManualCastingPageState();
}

class _ManualCastingPageState extends State<ManualCastingPage> {
  late final CastingDataSource _dataSource;
  late final bool _ownsDataSource;
  late final ArchiveDataSource _archiveClient;
  late final bool _ownsArchiveClient;
  late DateTime _dateTime;
  final _questionController = TextEditingController();
  List<_LineDraft> _lines = List.generate(
    6,
    (_) => const _LineDraft(yang: true, moving: false),
  );
  bool _submitting = false;
  String? _error;
  String _dayBoundary = engine.dayBoundaryCivil23NextDay;
  String _monthBoundary = engine.monthBoundarySolarTermZiHour;

  /// 全局历法口径：进入页面时从偏好读取（首次弹窗 / 设置页统一维护）。
  void _syncCalendarPolicyFromPreferences() {
    final prefs = currentPreferences;
    _dayBoundary = prefs.dayBoundaryStrategy;
    _monthBoundary = prefs.monthBoundaryStrategy;
  }

  String _fourPillarsSource = 'calculated';
  ManualFourPillars _manualFourPillars = const ManualFourPillars(
    yearGan: '甲',
    yearZhi: '子',
    monthGan: '甲',
    monthZhi: '子',
    dayGan: '甲',
    dayZhi: '子',
    hourGan: '甲',
    hourZhi: '子',
  );

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
    _syncCalendarPolicyFromPreferences();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 从档案详情/设置页返回时刷新全局口径。
    _syncCalendarPolicyFromPreferences();
  }

  List<int> get _lineValues =>
      _lines.map((line) => line.value).toList(growable: false);

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

  void _toggleYinYang(int index) {
    final line = _lines[index];
    setState(() {
      _lines = [..._lines]..[index] = line.copyWith(yang: !line.yang);
    });
  }

  void _toggleMoving(int index) {
    final line = _lines[index];
    setState(() {
      _lines = [..._lines]..[index] = line.copyWith(moving: !line.moving);
    });
  }

  Future<void> _reset() async {
    final hasChanges = _lines.any((line) => line.value != 7);
    if (!hasChanges) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置六爻？'),
        content: const Text('六个爻位将恢复为少阳静爻，占问和时间不会改变。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认重置'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _lines = List.generate(
        6,
        (_) => const _LineDraft(yang: true, moving: false),
      );
      _error = null;
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
    if (_fourPillarsSource == 'manual') {
      if (!_manualFourPillars.isComplete) {
        setState(() => _error = '手动四柱需填齐四柱的天干地支');
        return;
      }
      final invalid = _manualFourPillars.invalidPillarNames();
      if (invalid.isNotEmpty) {
        setState(() => _error = '${invalid.join('、')}的干支组合不在六十甲子内，请重新选择');
        return;
      }
    }
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _paper,
      builder: (context) => _CastingConfirmation(
        question: question,
        dateTime: _dateTime,
        lines: _lines,
      ),
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
      // 手动四柱直接交引擎排盘：六神、旬空、十二长生等全部按手动日柱
      // （六神按日干）计算，而不是先自动排盘再覆盖显示文本。
      final isManual = _fourPillarsSource == 'manual';
      var preview = await _dataSource.previewManual(
        question: question,
        dateTime: _dateTime,
        lineValues: _lineValues,
        dayBoundary: _dayBoundary,
        monthBoundary: _monthBoundary,
        manualPillars: isManual ? _manualFourPillars.toPillarsMap() : null,
      );
      if (isManual) {
        preview = preview.applyManualFourPillars(_manualFourPillars);
      }
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
      child: SafeArea(
        child: ListView(
          key: const Key('manual-casting-scroll'),
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 28),
          children: [
            _buildQuestion(),
            const SizedBox(height: 12),
            _buildDateTime(),
            // 历法口径首次选择完成后由设置页统一管理，起卦页不再显示该卡片。
            if (!currentPreferences.calendarPolicySetupCompleted) ...[
              const SizedBox(height: 12),
              _buildCalendarPolicy(),
            ],
            const SizedBox(height: 18),
            _buildEditorHeader(),
            const SizedBox(height: 10),
            _buildLineEditor(),
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
        key: const Key('casting-question'),
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
    // 与四柱来源合并为一张卡：自动计算时显示日期时间，手动填写时只显示四柱编辑器。
    final isCalculated = _fourPillarsSource == 'calculated';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '起卦时间',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              SegmentedButton<String>(
                key: const Key('four-pillars-source'),
                segments: const [
                  ButtonSegment(
                    value: 'calculated',
                    icon: Icon(Icons.auto_awesome_outlined, size: 14),
                    label: Text('自动计算', style: TextStyle(fontSize: 11)),
                  ),
                  ButtonSegment(
                    value: 'manual',
                    icon: Icon(Icons.edit_outlined, size: 14),
                    label: Text('手动填写', style: TextStyle(fontSize: 11)),
                  ),
                ],
                selected: {_fourPillarsSource},
                showSelectedIcon: false,
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: const WidgetStatePropertyAll(
                    BorderSide(color: _cinnabar),
                  ),
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? _cinnabar
                        : _softPaper,
                  ),
                  foregroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? Colors.white
                        : _ink,
                  ),
                ),
                onSelectionChanged: (selection) {
                  setState(() => _fourPillarsSource = selection.first);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isCalculated)
            Row(
              children: [
                Expanded(
                  child: _DateTimeButton(
                    key: const Key('casting-date'),
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
                    key: const Key('casting-time'),
                    icon: Icons.schedule_outlined,
                    label: '北京时间',
                    value: '${_two(_dateTime.hour)}:${_two(_dateTime.minute)}',
                    onTap: _pickTime,
                  ),
                ),
              ],
            )
          else ...[
            const Text(
              '手动填写覆盖自动计算，仅保存到本次档案',
              style: TextStyle(color: _mutedInk, fontSize: 10),
            ),
            const SizedBox(height: 10),
            _ManualPillarsEditor(
              value: _manualFourPillars,
              onChanged: (value) => setState(() => _manualFourPillars = value),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendarPolicy() {
    final dayLabel = _dayBoundary == engine.dayBoundaryCivil23NextDay
        ? '过23点换日'
        : '子正0点换日';
    final dayHint = _dayBoundary == engine.dayBoundaryCivil23NextDay
        ? '23:00:00.001 起进入当日子时，日柱按次日算'
        : '0 点换日，23:00–23:59 夜子时用当日日柱';
    final monthLabel = _monthBoundary == engine.monthBoundarySolarTermZiHour
        ? '节气子时换月'
        : '精确时刻换月';
    final monthHint = _monthBoundary == engine.monthBoundarySolarTermZiHour
        ? '进入当月节气的子时即换月柱'
        : '按节气天文精确时刻切换月柱';
    return Container(
      key: const Key('calendar-policy-summary'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.explore_outlined, size: 17, color: _cinnabar),
              const SizedBox(width: 7),
              const Text(
                '历法口径',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '在设置中更改',
                key: const Key('calendar-policy-hint'),
                style: TextStyle(color: _mutedInk, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Text(
            '口径随本次起卦存档，历史档案不受影响',
            style: TextStyle(color: _mutedInk, fontSize: 10),
          ),
          const SizedBox(height: 10),
          Text('交日', style: const TextStyle(color: _mutedInk, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            dayLabel,
            key: const Key('day-boundary-value'),
            style: const TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            dayHint,
            style: const TextStyle(color: _mutedInk, fontSize: 9, height: 1.4),
          ),
          const SizedBox(height: 10),
          Text('交月', style: const TextStyle(color: _mutedInk, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            monthLabel,
            key: const Key('month-boundary-value'),
            style: const TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            monthHint,
            style: const TextStyle(color: _mutedInk, fontSize: 9, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '六爻编辑',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 3),
              Text(
                '界面上爻在上；提交按初爻到上爻记录',
                style: TextStyle(color: _mutedInk, fontSize: 12),
              ),
            ],
          ),
        ),
        Text(
          _lineValues.join(' · '),
          key: const Key('line-value-summary'),
          style: const TextStyle(
            color: _cinnabar,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildLineEditor() {
    const positionLabels = ['初爻', '二爻', '三爻', '四爻', '五爻', '上爻'];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _cardDecoration(),
      child: Column(
        children: List.generate(6, (uiIndex) {
          final index = 5 - uiIndex;
          final line = _lines[index];
          return Padding(
            padding: EdgeInsets.only(bottom: uiIndex == 5 ? 0 : 7),
            child: _LineEditorRow(
              position: index + 1,
              label: positionLabels[index],
              line: line,
              onToggleYinYang: () => _toggleYinYang(index),
              onToggleMoving: () => _toggleMoving(index),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            key: const Key('reset-lines'),
            onPressed: _submitting ? null : _reset,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              side: const BorderSide(color: _cinnabar),
              foregroundColor: _ink,
            ),
            child: const Text('重置'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            key: const Key('review-cast'),
            onPressed: _submitting ? null : _reviewAndSubmit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              backgroundColor: LiuyaoColors.cinnabar,
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

class _LineDraft {
  const _LineDraft({required this.yang, required this.moving});

  final bool yang;
  final bool moving;

  int get value => yang
      ? moving
            ? 9
            : 7
      : moving
      ? 6
      : 8;

  String get name => switch (value) {
    6 => '老阴',
    7 => '少阳',
    8 => '少阴',
    9 => '老阳',
    _ => '',
  };

  _LineDraft copyWith({bool? yang, bool? moving}) {
    return _LineDraft(yang: yang ?? this.yang, moving: moving ?? this.moving);
  }
}

class _LineEditorRow extends StatelessWidget {
  const _LineEditorRow({
    required this.position,
    required this.label,
    required this.line,
    required this.onToggleYinYang,
    required this.onToggleMoving,
  });

  final int position;
  final String label;
  final _LineDraft line;
  final VoidCallback onToggleYinYang;
  final VoidCallback onToggleMoving;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
      decoration: BoxDecoration(
        color: line.moving ? DSColors.glowCinnabar : _softPaper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: line.moving ? DSColors.accentLine : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Semantics(
              button: true,
              label: '$label，${line.yang ? '阳爻' : '阴爻'}，点击切换阴阳',
              child: InkWell(
                key: Key('line-toggle-$position'),
                onTap: onToggleYinYang,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _paper,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _YaoGlyph(yang: line.yang),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            key: Key('line-moving-$position'),
            label: const Text('动'),
            selected: line.moving,
            onSelected: (_) => onToggleMoving(),
            showCheckmark: false,
            selectedColor: _cinnabar,
            backgroundColor: _paper,
            labelStyle: TextStyle(
              color: line.moving ? Colors.white : _mutedInk,
              fontWeight: FontWeight.w700,
            ),
            side: BorderSide(color: line.moving ? _cinnabar : _rule),
          ),
          const SizedBox(width: 7),
          SizedBox(
            width: 34,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${line.value}',
                  style: const TextStyle(
                    color: _cinnabar,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  line.name,
                  style: const TextStyle(color: _mutedInk, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _YaoGlyph extends StatelessWidget {
  const _YaoGlyph({required this.yang});

  final bool yang;

  @override
  Widget build(BuildContext context) {
    final segment = Container(
      height: 7,
      decoration: BoxDecoration(
        color: _cinnabar,
        borderRadius: BorderRadius.circular(5),
      ),
    );
    if (yang) return SizedBox(width: double.infinity, child: segment);
    return Row(
      children: [
        Expanded(child: segment),
        const SizedBox(width: 12),
        Expanded(child: segment),
      ],
    );
  }
}

class _DateTimeButton extends StatelessWidget {
  const _DateTimeButton({
    required super.key,
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

class _CastingConfirmation extends StatelessWidget {
  const _CastingConfirmation({
    required this.question,
    required this.dateTime,
    required this.lines,
  });

  final String question;
  final DateTime dateTime;
  final List<_LineDraft> lines;

  @override
  Widget build(BuildContext context) {
    final values = lines.map((line) => line.value).toList(growable: false);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '确认起卦输入',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              '排盘成功后将自动存入档案，并打开独立卦面。',
              style: TextStyle(color: _mutedInk),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _softPaper,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${dateTime.year}-${_two(dateTime.month)}-${_two(dateTime.day)} '
                    '${_two(dateTime.hour)}:${_two(dateTime.minute)} · 北京时间',
                    style: const TextStyle(color: _mutedInk, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '记录顺序：初爻 → 上爻',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              children: List.generate(
                6,
                (index) => Chip(
                  key: Key('confirm-line-${index + 1}'),
                  label: Text('${index + 1} · ${values[index]}'),
                  backgroundColor: _paper,
                  side: const BorderSide(color: _rule),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('返回修改'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('confirm-manual-cast'),
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: LiuyaoColors.cinnabar,
                    ),
                    child: const Text('确认并排盘'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('casting-error'),
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

class _ManualPillarsEditor extends StatelessWidget {
  const _ManualPillarsEditor({required this.value, required this.onChanged});

  final ManualFourPillars value;
  final ValueChanged<ManualFourPillars> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = [
      ('年柱', 'year'),
      ('月柱', 'month'),
      ('日柱', 'day'),
      ('时柱', 'hour'),
    ];
    return Container(
      key: const Key('manual-four-pillars-editor'),
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: _softPaper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _rule, width: .8),
      ),
      child: Column(
        children: labels
            .map((item) {
              final label = item.$1;
              final position = item.$2;
              final gan = _ganOf(position);
              final zhi = _zhiOf(position);
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  8,
                  12,
                  position == 'hour' ? 12 : 8,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _PillarDropdown<String>(
                        key: Key('manual-$position-gan'),
                        value: gan,
                        values: ManualFourPillars.heavenlyStems,
                        label: '天干',
                        onChanged: (next) =>
                            onChanged(_copyWith(position, gan: next)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PillarDropdown<String>(
                        key: Key('manual-$position-zhi'),
                        value: zhi,
                        values: ManualFourPillars.earthlyBranches,
                        label: '地支',
                        onChanged: (next) =>
                            onChanged(_copyWith(position, zhi: next)),
                      ),
                    ),
                  ],
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }

  String _ganOf(String position) => switch (position) {
    'year' => value.yearGan,
    'month' => value.monthGan,
    'day' => value.dayGan,
    'hour' => value.hourGan,
    _ => '',
  };

  String _zhiOf(String position) => switch (position) {
    'year' => value.yearZhi,
    'month' => value.monthZhi,
    'day' => value.dayZhi,
    'hour' => value.hourZhi,
    _ => '',
  };

  ManualFourPillars _copyWith(String position, {String? gan, String? zhi}) {
    final nextGan = gan ?? _ganOf(position);
    final nextZhi = zhi ?? _zhiOf(position);
    return switch (position) {
      'year' => ManualFourPillars(
        yearGan: nextGan,
        yearZhi: nextZhi,
        monthGan: value.monthGan,
        monthZhi: value.monthZhi,
        dayGan: value.dayGan,
        dayZhi: value.dayZhi,
        hourGan: value.hourGan,
        hourZhi: value.hourZhi,
      ),
      'month' => ManualFourPillars(
        yearGan: value.yearGan,
        yearZhi: value.yearZhi,
        monthGan: nextGan,
        monthZhi: nextZhi,
        dayGan: value.dayGan,
        dayZhi: value.dayZhi,
        hourGan: value.hourGan,
        hourZhi: value.hourZhi,
      ),
      'day' => ManualFourPillars(
        yearGan: value.yearGan,
        yearZhi: value.yearZhi,
        monthGan: value.monthGan,
        monthZhi: value.monthZhi,
        dayGan: nextGan,
        dayZhi: nextZhi,
        hourGan: value.hourGan,
        hourZhi: value.hourZhi,
      ),
      _ => ManualFourPillars(
        yearGan: value.yearGan,
        yearZhi: value.yearZhi,
        monthGan: value.monthGan,
        monthZhi: value.monthZhi,
        dayGan: value.dayGan,
        dayZhi: value.dayZhi,
        hourGan: nextGan,
        hourZhi: nextZhi,
      ),
    };
  }
}

class _PillarDropdown<T> extends StatelessWidget {
  const _PillarDropdown({
    super.key,
    required this.value,
    required this.values,
    required this.label,
    required this.onChanged,
  });

  final T value;
  final List<T> values;
  final String label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      style: const TextStyle(color: _ink, fontSize: 14),
      items: values
          .map((item) => DropdownMenuItem<T>(value: item, child: Text('$item')))
          .toList(growable: false),
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}
