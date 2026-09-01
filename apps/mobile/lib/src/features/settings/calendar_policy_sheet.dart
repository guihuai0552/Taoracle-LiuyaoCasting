import 'package:flutter/material.dart';
import 'package:liuyao_engine/liuyao_engine.dart' as engine;

import '../../ui/design_system/design_system.dart';

/// 历法口径选择结果。
@immutable
class CalendarPolicySelection {
  const CalendarPolicySelection({
    required this.dayBoundary,
    required this.monthBoundary,
  });

  final String dayBoundary;
  final String monthBoundary;
}

/// 历法口径玻璃选择弹窗（首次进入六爻 / 设置页修改共用）。
///
/// 返回 null 表示用户取消；确认返回所选口径。视觉采用
/// DSGlassPanel 强玻璃 + RuleChoice 选择卡 + 即时摘要。
Future<CalendarPolicySelection?> showCalendarPolicySheet(
  BuildContext context, {
  required String initialDayBoundary,
  required String initialMonthBoundary,
  required String title,
  bool barrierDismissible = true,
}) {
  return showDialog<CalendarPolicySelection>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: .55),
    builder: (context) => _CalendarPolicyDialog(
      initialDayBoundary: initialDayBoundary,
      initialMonthBoundary: initialMonthBoundary,
      title: title,
      barrierDismissible: barrierDismissible,
    ),
  );
}

class _CalendarPolicyDialog extends StatefulWidget {
  const _CalendarPolicyDialog({
    required this.initialDayBoundary,
    required this.initialMonthBoundary,
    required this.title,
    required this.barrierDismissible,
  });

  final String initialDayBoundary;
  final String initialMonthBoundary;
  final String title;
  final bool barrierDismissible;

  @override
  State<_CalendarPolicyDialog> createState() => _CalendarPolicyDialogState();
}

class _CalendarPolicyDialogState extends State<_CalendarPolicyDialog> {
  late String _dayBoundary;
  late String _monthBoundary;

  @override
  void initState() {
    super.initState();
    _dayBoundary = widget.initialDayBoundary;
    _monthBoundary = widget.initialMonthBoundary;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.barrierDismissible,
      child: DSScaleIn(
        duration: DSMotion.normal,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: DSGlassPanel(
              color: DSColors.glassStrong,
              enableBlur: true,
              blurSigma: 18,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.explore_outlined,
                          size: 20,
                          color: DSColors.celadonDeep,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.title,
                            key: const Key('calendar-policy-title'),
                            style: DSTypography.displayLight(
                              fontSize: 19,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '交日、交月口径决定四柱计算边界，随每次起卦存档；历史档案不受影响。',
                      style: TextStyle(
                        color: DSColors.textSecondary,
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '交日',
                      style: TextStyle(
                        color: DSColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _RuleChoiceCard(
                      key: const Key('day-choice-23'),
                      group: 'day',
                      selected:
                          _dayBoundary == engine.dayBoundaryCivil23NextDay,
                      title: '过23点换日',
                      hint: '23:00:00.001 起进入当日子时，日柱按次日算',
                      recommended: true,
                      onTap: () => setState(() {
                        _dayBoundary = engine.dayBoundaryCivil23NextDay;
                      }),
                    ),
                    const SizedBox(height: 8),
                    _RuleChoiceCard(
                      key: const Key('day-choice-midnight'),
                      group: 'day',
                      selected:
                          _dayBoundary ==
                          engine.dayBoundaryAstronomicalMidnight,
                      title: '子正0点换日',
                      hint: '0 点换日，23:00–23:59 夜子时用当日日柱',
                      onTap: () => setState(() {
                        _dayBoundary = engine.dayBoundaryAstronomicalMidnight;
                      }),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '交月',
                      style: TextStyle(
                        color: DSColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _RuleChoiceCard(
                      key: const Key('month-choice-zi'),
                      group: 'month',
                      selected:
                          _monthBoundary == engine.monthBoundarySolarTermZiHour,
                      title: '节气子时换月',
                      hint: '进入当月节气的子时即换月柱',
                      recommended: true,
                      onTap: () => setState(() {
                        _monthBoundary = engine.monthBoundarySolarTermZiHour;
                      }),
                    ),
                    const SizedBox(height: 8),
                    _RuleChoiceCard(
                      key: const Key('month-choice-exact'),
                      group: 'month',
                      selected:
                          _monthBoundary ==
                          engine.monthBoundaryAstronomicalMoment,
                      title: '精确时刻换月',
                      hint: '按节气天文精确时刻切换月柱',
                      onTap: () => setState(() {
                        _monthBoundary = engine.monthBoundaryAstronomicalMoment;
                      }),
                    ),
                    const SizedBox(height: 14),
                    // 当前选择摘要卡。
                    Container(
                      key: const Key('calendar-policy-summary-card'),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: DSColors.glassWeak,
                        borderRadius: BorderRadius.circular(DSRadius.sm),
                        border: Border.all(
                          color: DSColors.metalLine,
                          width: .8,
                        ),
                      ),
                      child: Text(
                        '当前口径：交日 $_dayLabel · 交月 $_monthLabel',
                        key: const Key('calendar-policy-current'),
                        style: const TextStyle(
                          color: DSColors.celadonDeep,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (widget.barrierDismissible)
                          Expanded(
                            child: OutlinedButton(
                              key: const Key('calendar-policy-cancel'),
                              onPressed: () => Navigator.pop(context, null),
                              child: const Text('稍后设置'),
                            ),
                          ),
                        if (widget.barrierDismissible)
                          const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            key: const Key('calendar-policy-confirm'),
                            onPressed: () => Navigator.pop(
                              context,
                              CalendarPolicySelection(
                                dayBoundary: _dayBoundary,
                                monthBoundary: _monthBoundary,
                              ),
                            ),
                            child: const Text('确认口径'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _dayLabel =>
      _dayBoundary == engine.dayBoundaryCivil23NextDay ? '过23点换日' : '子正0点换日';

  String get _monthLabel =>
      _monthBoundary == engine.monthBoundarySolarTermZiHour
      ? '节气子时换月'
      : '精确时刻换月';
}

/// 口径选择卡：选中态青铜描边 + 玉青高亮，未选中发丝线。
class _RuleChoiceCard extends StatelessWidget {
  const _RuleChoiceCard({
    super.key,
    required this.group,
    required this.selected,
    required this.title,
    required this.hint,
    required this.onTap,
    this.recommended = false,
  });

  final String group;
  final bool selected;
  final String title;
  final String hint;
  final bool recommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DSRadius.md),
        child: AnimatedContainer(
          key: super.key,
          duration: DSMotion.fast,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? DSColors.celadon.withValues(alpha: .12)
                : DSColors.glassWeak,
            borderRadius: BorderRadius.circular(DSRadius.md),
            border: Border.all(
              color: selected ? DSColors.celadon : DSColors.hairlineStrong,
              width: selected ? 1.2 : .8,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 17,
                color: selected ? DSColors.celadonDeep : DSColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: selected
                                ? DSColors.textPrimary
                                : DSColors.textSecondary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (recommended) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: DSColors.jade.withValues(alpha: .16),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: DSColors.jade.withValues(alpha: .4),
                                width: .6,
                              ),
                            ),
                            child: const Text(
                              '推荐',
                              style: TextStyle(
                                color: DSColors.jade,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hint,
                      style: const TextStyle(
                        color: DSColors.textMuted,
                        fontSize: 10,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
