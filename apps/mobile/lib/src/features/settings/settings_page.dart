import 'package:flutter/material.dart';
import 'package:liuyao_engine/liuyao_engine.dart' as engine;
import 'package:url_launcher/url_launcher.dart';

import '../../ui/design_system/design_system.dart';
import '../../ui/liuyao_design.dart';
import 'app_preferences.dart';
import 'calendar_policy_sheet.dart';

/// 设置页：历法口径、卦面显示、本地数据与数据边界。
///
/// 偏好读写走 [AppPreferences]（settings.json），修改即时生效；
/// 历法口径修改只影响后续起卦，历史档案保留各自存档口径。
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AppPreferences _prefs = currentPreferences;

  @override
  void initState() {
    super.initState();
    _prefs = currentPreferences;
  }

  Future<void> _editCalendarPolicy() async {
    final selection = await showCalendarPolicySheet(
      context,
      initialDayBoundary: _prefs.dayBoundaryStrategy,
      initialMonthBoundary: _prefs.monthBoundaryStrategy,
      title: '历法口径',
    );
    if (selection == null || !mounted) return;
    await savePreferences(
      _prefs.copyWith(
        dayBoundaryStrategy: selection.dayBoundary,
        monthBoundaryStrategy: selection.monthBoundary,
        // 首次弹窗被跳过的用户在设置页完成口径后同样视为已完成。
        calendarPolicySetupCompleted: true,
      ),
    );
    if (!mounted) return;
    setState(() => _prefs = currentPreferences);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('历法口径已更新，仅影响后续起卦；历史档案不受影响'),
          duration: Duration(seconds: 3),
        ),
      );
  }

  Future<void> _toggle(String field, bool value) async {
    var next = _prefs;
    switch (field) {
      case 'showCastingRecord':
        next = _prefs.copyWith(showCastingRecord: value);
      case 'showCalculationBasis':
        next = _prefs.copyWith(showCalculationBasis: value);
      case 'showNayin':
        next = _prefs.copyWith(showNayin: value);
      case 'showFiveStarsAndMansions':
        next = _prefs.copyWith(showFiveStarsAndMansions: value);
      case 'showShenshaAndTwelveGrowth':
        next = _prefs.copyWith(showShenshaAndTwelveGrowth: value);
      case 'showAuxAlmanac':
        next = _prefs.copyWith(showAuxAlmanac: value);
    }
    setState(() => _prefs = next);
    await savePreferences(next);
  }

  @override
  Widget build(BuildContext context) {
    final dayLabel =
        _prefs.dayBoundaryStrategy == engine.dayBoundaryCivil23NextDay
        ? '过23点换日'
        : '子正0点换日';
    final monthLabel =
        _prefs.monthBoundaryStrategy == engine.monthBoundarySolarTermZiHour
        ? '节气子时换月'
        : '精确时刻换月';
    return SafeArea(
      child: ListView(
        key: const Key('settings-scroll'),
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 40),
        children: [
          DSReveal(
            child: Row(
              children: [
                const LiuyaoSealMark(character: '藏', label: '本机'),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 「道谕六爻」品牌标题统一组件（与档案页基准一致）。
                      const DaoyuBrandTitle(keyOverride: Key('settings-title')),
                      const SizedBox(height: 4),
                      const Text(
                        '设置 · 历法口径、卦面显示与本地档案说明',
                        style: TextStyle(color: DSColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          DSReveal(
            delay: const Duration(milliseconds: 60),
            child: const _SectionLabel('历法口径'),
          ),
          const SizedBox(height: 10),
          DSReveal(
            delay: const Duration(milliseconds: 90),
            child: DSGlassPanel(
              key: const Key('settings-calendar-policy-card'),
              padding: EdgeInsets.zero,
              color: DSColors.glass,
              child: Column(
                children: [
                  _PolicyRow(
                    icon: Icons.explore_outlined,
                    title: '交日',
                    value: dayLabel,
                  ),
                  Divider(
                    height: 1,
                    color: DSColors.hairline.withValues(alpha: .6),
                  ),
                  _PolicyRow(
                    icon: Icons.dark_mode_outlined,
                    title: '交月',
                    value: monthLabel,
                  ),
                  Divider(
                    height: 1,
                    color: DSColors.hairline.withValues(alpha: .6),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('settings-edit-policy'),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(DSRadius.lg),
                      ),
                      onTap: _editCalendarPolicy,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.tune_outlined,
                              size: 20,
                              color: DSColors.celadonDeep,
                            ),
                            const SizedBox(width: 13),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '更改历法口径',
                                    key: Key('settings-edit-policy-title'),
                                    style: TextStyle(
                                      color: DSColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '仅影响后续起卦，不改变已有档案',
                                    style: TextStyle(
                                      color: DSColors.textMuted,
                                      fontSize: 11,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: DSColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          DSReveal(
            delay: const Duration(milliseconds: 120),
            child: const _SectionLabel('卦面显示'),
          ),
          const SizedBox(height: 10),
          DSReveal(
            delay: const Duration(milliseconds: 150),
            child: DSGlassPanel(
              key: const Key('settings-chart-display-card'),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: DSColors.glass,
              child: Column(
                children: [
                  _DisplaySwitchRow(
                    key: const Key('settings-show-casting-record'),
                    icon: Icons.history_edu_outlined,
                    title: '显示起卦记录',
                    description: '在卦面详情中展示原始起卦方式与六次记录',
                    value: _prefs.showCastingRecord,
                    onChanged: (value) => _toggle('showCastingRecord', value),
                  ),
                  Divider(
                    height: 1,
                    color: DSColors.hairline.withValues(alpha: .6),
                  ),
                  _DisplaySwitchRow(
                    key: const Key('settings-show-calculation-basis'),
                    icon: Icons.calculate_outlined,
                    title: '显示计算依据',
                    description: '在卦面详情中展示规则计算过程与依据',
                    value: _prefs.showCalculationBasis,
                    onChanged: (value) =>
                        _toggle('showCalculationBasis', value),
                  ),
                  Divider(
                    height: 1,
                    color: DSColors.hairline.withValues(alpha: .6),
                  ),
                  _DisplaySwitchRow(
                    key: const Key('settings-show-nayin'),
                    icon: Icons.music_note_outlined,
                    title: '纳音五行',
                    description: '在爻位标注中显示纳音五行',
                    value: _prefs.showNayin,
                    onChanged: (value) => _toggle('showNayin', value),
                  ),
                  Divider(
                    height: 1,
                    color: DSColors.hairline.withValues(alpha: .6),
                  ),
                  _DisplaySwitchRow(
                    key: const Key('settings-show-five-stars-mansions'),
                    icon: Icons.auto_awesome_outlined,
                    title: '五星与二十八宿',
                    description: '在卦面与历法信息中显示京房五星与二十八宿',
                    value: _prefs.showFiveStarsAndMansions,
                    onChanged: (value) =>
                        _toggle('showFiveStarsAndMansions', value),
                  ),
                  Divider(
                    height: 1,
                    color: DSColors.hairline.withValues(alpha: .6),
                  ),
                  _DisplaySwitchRow(
                    key: const Key('settings-show-shensha-twelve'),
                    icon: Icons.schema_outlined,
                    title: '神煞与十二长生',
                    description: '显示神煞、十二长生与辅助黄历信息',
                    value: _prefs.showShenshaAndTwelveGrowth,
                    onChanged: (value) =>
                        _toggle('showShenshaAndTwelveGrowth', value),
                  ),
                  Divider(
                    height: 1,
                    color: DSColors.hairline.withValues(alpha: .6),
                  ),
                  _DisplaySwitchRow(
                    key: const Key('settings-show-aux-almanac'),
                    icon: Icons.event_note_outlined,
                    title: '辅助黄历字段',
                    description: '显示值神、冲煞、星宿、建除等黄历字段',
                    value: _prefs.showAuxAlmanac,
                    onChanged: (value) => _toggle('showAuxAlmanac', value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          DSReveal(
            delay: const Duration(milliseconds: 180),
            child: const _SectionLabel('本地数据'),
          ),
          const SizedBox(height: 10),
          DSReveal(
            delay: const Duration(milliseconds: 210),
            child: const DSGlassPanel(
              key: Key('settings-local-data-card'),
              padding: EdgeInsets.zero,
              color: DSColors.glass,
              child: Column(
                children: [
                  _SettingsRow(
                    icon: Icons.phonelink_lock_outlined,
                    title: '档案保存在本机',
                    description: '占问、卦面、解读与反馈写入应用私有空间，退出后台后不会清除。',
                  ),
                  Divider(color: DSColors.hairline),
                  _SettingsRow(
                    icon: Icons.cloud_off_outlined,
                    title: '离线可用',
                    description: '基础排盘与档案浏览无需登录，也不会自动上传到云端。',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          DSReveal(
            delay: const Duration(milliseconds: 240),
            child: const _SectionLabel('数据边界'),
          ),
          const SizedBox(height: 10),
          DSReveal(
            delay: const Duration(milliseconds: 270),
            child: const DSGlassPanel(
              padding: EdgeInsets.zero,
              color: DSColors.glass,
              child: Column(
                children: [
                  _SettingsRow(
                    icon: Icons.swap_horiz_rounded,
                    title: '支持跨设备迁移',
                    description: '在“档案”页打开迁移入口，可批量导出或导入全部卦面、解读与反馈。',
                  ),
                  Divider(color: DSColors.hairline),
                  _SettingsRow(
                    icon: Icons.info_outline_rounded,
                    title: '卸载前请先导出',
                    description: '清除应用数据或卸载应用会同时移除本地档案，请先生成迁移包并妥善保存。',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          DSReveal(
            delay: const Duration(milliseconds: 300),
            child: DSGlassPanel(
              padding: EdgeInsets.zero,
              color: DSColors.glass,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('settings-taoracle-entry'),
                  borderRadius: BorderRadius.circular(DSRadius.lg),
                  onTap: () async {
                    // 作者其他产品入口；失败静默（无浏览器环境极少见）。
                    final uri = Uri.parse('https://taoracle.com');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_outlined,
                          size: 20,
                          color: DSColors.jade,
                        ),
                        SizedBox(width: 13),
                        Expanded(
                          child: Text(
                            '道谕Taoracle',
                            key: Key('settings-taoracle-title'),
                            style: TextStyle(
                              color: DSColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '作者其他产品',
                          style: TextStyle(
                            color: DSColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 16,
                          color: DSColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '— 资料留于方寸之间 —',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: DSColors.textMuted,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 17,
          decoration: BoxDecoration(
            color: DSColors.celadon,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: DSColors.textPrimary,
            // v1.0 §3.3：层级靠字号与字距，字重克制（w700 → w500）。
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _PolicyRow extends StatelessWidget {
  const _PolicyRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: DSColors.celadonDeep),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: DSColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            key: Key('settings-policy-$title'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: DSColors.celadon.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(DSRadius.sm),
              border: Border.all(color: DSColors.metalLine, width: .7),
            ),
            child: Text(
              value,
              key: Key('settings-policy-value-$title'),
              style: const TextStyle(
                color: DSColors.celadonDeep,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisplaySwitchRow extends StatelessWidget {
  const _DisplaySwitchRow({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: DSColors.jade),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: DSColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: DSColors.textMuted,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(key: super.key, value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DSColors.glassWeak,
              border: Border.all(color: DSColors.hairlineStrong),
              borderRadius: BorderRadius.circular(DSRadius.sm),
            ),
            child: Icon(icon, size: 21, color: DSColors.celadonDeep),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: DSColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    color: DSColors.textMuted,
                    fontSize: 11.5,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
