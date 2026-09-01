import 'package:flutter/material.dart';

import '../../ui/design_system/tokens/ds_colors.dart';
import '../../ui/liuyao_design.dart';
import 'almanac_client.dart';
import 'almanac_models.dart';

const _ink = LiuyaoColors.ink;
const _mutedInk = LiuyaoColors.inkMuted;
const _cinnabar = LiuyaoColors.cinnabar;
const _paper = LiuyaoColors.paperRaised;
const _rule = LiuyaoColors.inkFaint;

class AlmanacPage extends StatefulWidget {
  const AlmanacPage({
    super.key,
    this.dataSource,
    this.initialDate,
    this.onDateSelected,
  });

  final AlmanacDataSource? dataSource;
  final DateTime? initialDate;

  /// 用户点选某一天时回调，供外层导航共享给起卦页。
  final ValueChanged<DateTime>? onDateSelected;

  @override
  State<AlmanacPage> createState() => _AlmanacPageState();
}

class _AlmanacPageState extends State<AlmanacPage> {
  late final AlmanacDataSource _dataSource;
  late final bool _ownsDataSource;
  late DateTime _visibleMonth;
  late DateTime _selectedDate;
  late int _selectedHour;

  AlmanacMonth? _month;
  AlmanacSnapshot? _snapshot;
  bool _monthLoading = false;
  bool _dayLoading = false;
  String? _monthError;
  String? _dayError;
  int _monthRequest = 0;
  int _dayRequest = 0;

  @override
  void initState() {
    super.initState();
    _ownsDataSource = widget.dataSource == null;
    _dataSource = widget.dataSource ?? AlmanacClient();
    final initial = widget.initialDate ?? DateTime.now();
    _visibleMonth = DateTime(initial.year, initial.month);
    _selectedDate = DateTime(initial.year, initial.month, initial.day);
    _selectedHour = initial.hour;
    _loadMonth();
  }

  Future<void> _loadMonth() async {
    final request = ++_monthRequest;
    final target = _visibleMonth;
    setState(() {
      _monthLoading = true;
      _monthError = null;
    });
    try {
      final result = await _dataSource.loadMonth(
        year: target.year,
        month: target.month,
      );
      if (!mounted || request != _monthRequest) return;
      final selectedIsVisible =
          _selectedDate.year == target.year &&
          _selectedDate.month == target.month;
      final selected = selectedIsVisible
          ? result.cells.where((cell) => _sameDay(cell.date, _selectedDate))
          : const Iterable<AlmanacDayCell>.empty();
      final fallback = result.cells.firstWhere(
        (cell) => cell.inCurrentMonth && cell.available,
      );
      final nextSelection = selected.isNotEmpty && selected.first.available
          ? selected.first.date
          : fallback.date;
      setState(() {
        _month = result;
        _selectedDate = nextSelection;
      });
      await _loadDay();
    } on Object catch (error) {
      if (mounted && request == _monthRequest) {
        setState(() => _monthError = _message(error));
      }
    } finally {
      if (mounted && request == _monthRequest) {
        setState(() => _monthLoading = false);
      }
    }
  }

  Future<void> _loadDay() async {
    final request = ++_dayRequest;
    final date = _selectedDate;
    final hour = _selectedHour;
    setState(() {
      _dayLoading = true;
      _dayError = null;
    });
    try {
      final result = await _dataSource.loadDay(date: date, hour: hour);
      if (!mounted || request != _dayRequest) return;
      setState(() => _snapshot = result);
    } on Object catch (error) {
      if (mounted && request == _dayRequest) {
        setState(() => _dayError = _message(error));
      }
    } finally {
      if (mounted && request == _dayRequest) {
        setState(() => _dayLoading = false);
      }
    }
  }

  void _moveMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
      _selectedDate = DateTime(_visibleMonth.year, _visibleMonth.month);
      _snapshot = null;
    });
    _loadMonth();
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _visibleMonth = DateTime(now.year, now.month);
      _selectedDate = DateTime(now.year, now.month, now.day);
      _selectedHour = now.hour;
      _snapshot = null;
    });
    _loadMonth();
  }

  Future<void> _pickYearMonth() async {
    final yearController = TextEditingController(text: '${_visibleMonth.year}');
    var selectedMonth = _visibleMonth.month;
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            key: const Key('year-month-picker-dialog'),
            title: const Text('跳转到指定年月'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('year-month-year-field'),
                        controller: yearController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '年份',
                          hintText: '1901 – 2100',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        key: const Key('year-month-month-field'),
                        initialValue: selectedMonth,
                        decoration: const InputDecoration(
                          labelText: '月份',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (var month = 1; month <= 12; month++)
                            DropdownMenuItem<int>(
                              value: month,
                              child: Text('$month月'),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedMonth = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '跳转后农历、干支与节气随所选年月刷新。',
                  style: TextStyle(color: _mutedInk, fontSize: 10),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('取消'),
              ),
              FilledButton(
                key: const Key('year-month-confirm'),
                onPressed: () {
                  final year = int.tryParse(yearController.text.trim());
                  if (year == null || year < 1901 || year > 2100) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请输入 1901 – 2100 之间的年份')),
                    );
                    return;
                  }
                  Navigator.pop(dialogContext, DateTime(year, selectedMonth));
                },
                child: const Text('确定'),
              ),
            ],
          );
        },
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _visibleMonth = DateTime(picked.year, picked.month);
        _selectedDate = DateTime(picked.year, picked.month);
        _snapshot = null;
      });
      _loadMonth();
    }
  }

  void _selectDay(AlmanacDayCell cell) {
    if (!cell.available) return;
    if (!cell.inCurrentMonth) {
      setState(() {
        _visibleMonth = DateTime(cell.date.year, cell.date.month);
        _selectedDate = cell.date;
        _snapshot = null;
      });
      _loadMonth();
      widget.onDateSelected?.call(cell.date);
      return;
    }
    setState(() {
      _selectedDate = cell.date;
      _snapshot = null;
    });
    _loadDay();
    widget.onDateSelected?.call(cell.date);
  }

  void _selectTwoHour(int index) {
    final hour = switch (index) {
      0 => 0,
      12 => 23,
      _ => index * 2,
    };
    if (hour == _selectedHour) return;
    setState(() => _selectedHour = hour);
    _loadDay();
  }

  @override
  void dispose() {
    if (_ownsDataSource) _dataSource.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadMonth,
          color: _cinnabar,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                sliver: SliverToBoxAdapter(child: _buildCalendar()),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
                sliver: SliverToBoxAdapter(child: _buildDayDetail()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final month = _visibleMonth.month.toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 14, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '万年历',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: _mutedInk,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: InkWell(
                    key: const Key('almanac-month-picker'),
                    onTap: _monthLoading ? null : _pickYearMonth,
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_visibleMonth.year}年$month月',
                          key: const Key('almanac-month-title'),
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                color: _ink,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -1,
                              ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: _cinnabar,
                          size: 26,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _MonthArrow(
            tooltip: '上个月',
            icon: Icons.arrow_back_ios_new_rounded,
            onPressed: _monthLoading ? null : () => _moveMonth(-1),
          ),
          const SizedBox(width: 8),
          _MonthArrow(
            tooltip: '回到今天',
            icon: Icons.today_rounded,
            onPressed: _monthLoading ? null : _goToday,
          ),
          const SizedBox(width: 8),
          _MonthArrow(
            tooltip: '下个月',
            icon: Icons.arrow_forward_ios_rounded,
            onPressed: _monthLoading ? null : () => _moveMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(LiuyaoRadii.card),
        border: Border.all(color: _rule, width: .8),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
        child: Column(
          children: [
            const _WeekHeader(),
            const SizedBox(height: 8),
            if (_monthLoading && _month == null)
              const SizedBox(
                height: 408,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_monthError != null && _month == null)
              _ErrorPanel(
                message: _monthError!,
                onRetry: _loadMonth,
                height: 408,
              )
            else if (_month != null)
              GridView.builder(
                key: const Key('almanac-month-grid'),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 0.70,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                ),
                itemCount: _month!.cells.length,
                itemBuilder: (context, index) {
                  final cell = _month!.cells[index];
                  return _CalendarDay(
                    cell: cell,
                    selected: _sameDay(cell.date, _selectedDate),
                    today: _sameDay(cell.date, DateTime.now()),
                    onTap: () => _selectDay(cell),
                  );
                },
              ),
            if (_monthLoading && _month != null)
              const LinearProgressIndicator(minHeight: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildDayDetail() {
    if (_dayLoading && _snapshot == null) {
      return const _DetailSkeleton();
    }
    if (_dayError != null && _snapshot == null) {
      return _ErrorPanel(message: _dayError!, onRetry: _loadDay, height: 240);
    }
    final snapshot = _snapshot;
    if (snapshot == null) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(LiuyaoRadii.card),
        border: Border.all(color: _rule, width: .8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _cinnabar,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        snapshot.lunar.fullLabel,
                        key: const Key('selected-lunar-date'),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_solarDate(snapshot.solarDate)} · ${snapshot.weekday}'
                        '${snapshot.solarTerm == null ? '' : ' · ${snapshot.solarTerm}'}',
                        style: const TextStyle(color: _mutedInk),
                      ),
                    ],
                  ),
                ),
                if (_dayLoading)
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: _rule),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel(number: '壹', title: '四柱与纳音'),
                const SizedBox(height: 14),
                _PillarGrid(pillars: snapshot.fourPillars),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(
                      child: _SectionLabel(number: '贰', title: '时辰干支'),
                    ),
                    Text(
                      '北京时间',
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(color: _mutedInk),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _TwoHourStrip(
                  pillars: snapshot.twoHourPillars,
                  selectedIndex: snapshot.currentTwoHourIndex,
                  onSelected: _selectTwoHour,
                ),
                const SizedBox(height: 20),
                _WealthGod(
                  direction: snapshot.wealthGodDirection,
                  mansion: snapshot.twentyEightMansion,
                ),
                if (_dayError != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    '更新失败：$_dayError',
                    style: const TextStyle(color: _cinnabar, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _solarDate(DateTime value) {
    return '${value.year}年${value.month}月${value.day}日';
  }

  String _message(Object error) {
    return error.toString().replaceFirst(RegExp(r'^.*Exception: '), '');
  }

  bool _sameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}

class _MonthArrow extends StatelessWidget {
  const _MonthArrow({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: _cinnabar,
        foregroundColor: Colors.white,
        disabledBackgroundColor: DSColors.celadonDim.withValues(alpha: .4),
      ),
      icon: Icon(icon, size: 18),
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const ['一', '二', '三', '四', '五', '六', '日']
          .map(
            (label) => Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _mutedInk,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.cell,
    required this.selected,
    required this.today,
    required this.onTap,
  });

  final AlmanacDayCell cell;
  final bool selected;
  final bool today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? DSColors.moonWhite
        : !cell.available || !cell.inCurrentMonth
        ? DSColors.textFaint
        : _ink;
    final secondary = selected
        ? DSColors.moonWhite
        : cell.solarTerm != null
        ? _cinnabar
        : _mutedInk;

    return Semantics(
      button: cell.available,
      selected: selected,
      label:
          '${today ? '今天，' : ''}${cell.date.month}月${cell.solarDay}日 ${cell.lunarLabel}',
      child: InkWell(
        key: Key(
          'calendar-day-${cell.date.toIso8601String().split('T').first}',
        ),
        onTap: cell.available ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
          decoration: BoxDecoration(
            color: selected ? _cinnabar : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: today
                  ? selected
                        ? Colors.white
                        : _cinnabar
                  : Colors.transparent,
              width: today ? 1.5 : 0,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${cell.solarDay}',
                  style: TextStyle(
                    color: foreground,
                    fontSize: 18,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  cell.lunarLabel,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    color: secondary,
                    fontSize: 9,
                    height: 1.1,
                    fontWeight: cell.solarTerm == null
                        ? FontWeight.w400
                        : FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cell.dayPillar?.ganzhi ?? '',
                  style: TextStyle(color: secondary, fontSize: 9, height: 1.1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.number, required this.title});

  final String number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          number,
          style: const TextStyle(
            color: _cinnabar,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _PillarGrid extends StatelessWidget {
  const _PillarGrid({required this.pillars});

  final List<AlmanacPillar> pillars;

  @override
  Widget build(BuildContext context) {
    const labels = {'year': '年柱', 'month': '月柱', 'day': '日柱', 'hour': '时柱'};
    return Row(
      children: pillars
          .map((pillar) {
            final isLast = pillar == pillars.last;
            return Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    right: isLast
                        ? BorderSide.none
                        : const BorderSide(color: _rule),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      labels[pillar.position] ?? pillar.position,
                      style: const TextStyle(color: _mutedInk, fontSize: 11),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      pillar.ganzhi,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pillar.nayin,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _cinnabar, fontSize: 11),
                    ),
                  ],
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _TwoHourStrip extends StatelessWidget {
  const _TwoHourStrip({
    required this.pillars,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<AlmanacTwoHourPillar> pillars;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: pillars.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final pillar = pillars[index];
          final selected = pillar.index == selectedIndex;
          // index 语义与 cnlunar 一致：0 = 0 点子正，12 = 23 点子初。
          final branch = switch (pillar.index) {
            0 => '子正',
            12 => '子初',
            _ => pillar.branch,
          };
          return InkWell(
            key: Key('two-hour-${pillar.index}'),
            onTap: () => onSelected(pillar.index),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                // 线框图：选中时辰为「红框圈出」——淡朱红底 + 1.2px 红描边 + 红字。
                color: selected
                    ? DSColors.glowCinnabar
                    : DSColors.surfaceLightSunken,
                borderRadius: BorderRadius.circular(10),
                border: selected
                    ? Border.all(color: _cinnabar, width: 1.2)
                    : Border.all(color: Colors.transparent),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    branch,
                    style: TextStyle(
                      color: selected ? _cinnabar : _mutedInk,
                      fontSize: 11,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    pillar.ganzhi,
                    style: TextStyle(
                      color: selected ? _cinnabar : _ink,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WealthGod extends StatelessWidget {
  const _WealthGod({required this.direction, this.mansion});

  final String direction;

  /// 当值二十八宿（如「室宿」）；为空时保持原单栏财神样式。
  final String? mansion;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('wealth-god-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DSColors.glassWeak,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DSColors.hairline, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.explore_outlined, color: _cinnabar),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('财神方位', style: TextStyle(color: _cinnabar, fontSize: 12)),
                SizedBox(height: 2),
                Text(
                  '依据所选日期与时辰计算',
                  style: TextStyle(color: _mutedInk, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            direction,
            style: const TextStyle(
              color: _ink,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (mansion != null) ...[
            Container(
              width: 1,
              height: 34,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: DSColors.hairline,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '当值星宿',
                  style: TextStyle(color: _cinnabar, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  mansion!,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(LiuyaoRadii.card),
        border: Border.all(color: _rule, width: .8),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({
    required this.message,
    required this.onRetry,
    required this.height,
  });

  final String message;
  final VoidCallback onRetry;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, color: _cinnabar, size: 34),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('重新加载'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
