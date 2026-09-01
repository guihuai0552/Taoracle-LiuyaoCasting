import 'package:flutter/material.dart';

import '../../ui/design_system/components/daoyu_brand_title.dart';
import '../../ui/design_system/components/ds_segmented_control.dart';
import '../../ui/design_system/tokens/ds_colors.dart';
import '../../ui/design_system/tokens/ds_typography.dart';
import 'automatic_casting_page.dart';
import 'casting_client.dart';
import 'manual_casting_page.dart';
import 'time_pillar_casting_page.dart';

enum CastingMode { manual, automatic, timePillar }

class CastingPage extends StatefulWidget {
  const CastingPage({super.key, this.dataSource, this.initialDateTime});

  final CastingDataSource? dataSource;

  /// 由万年历选中的日期草稿；进入起卦页时自动带入。
  final DateTime? initialDateTime;

  @override
  State<CastingPage> createState() => _CastingPageState();
}

class _CastingPageState extends State<CastingPage> {
  late final CastingDataSource _dataSource;
  late final bool _ownsDataSource;
  late final List<Widget> _pages;
  CastingMode _mode = CastingMode.manual;

  @override
  void initState() {
    super.initState();
    _ownsDataSource = widget.dataSource == null;
    _dataSource = widget.dataSource ?? CastingClient();
    final initial = widget.initialDateTime;
    _pages = [
      ManualCastingPage(dataSource: _dataSource, initialDateTime: initial),
      AutomaticCastingPage(dataSource: _dataSource, initialDateTime: initial),
      TimePillarCastingPage(dataSource: _dataSource, initialDateTime: initial),
    ];
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 「道谕六爻」品牌标题统一组件（与档案页基准一致）。
                        const DaoyuBrandTitle(
                          keyOverride: Key('casting-brand-title'),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '起卦台 · 问题 · 时间 · 摇卦',
                          style: DSTypography.body(
                            fontSize: 12,
                            color: DSColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: DSSegmentedControl<CastingMode>(
                keyOverride: const Key('casting-mode-switch'),
                segments: const [
                  DSSegmentItem(
                    value: CastingMode.manual,
                    label: '手动',
                    icon: Icons.edit_outlined,
                  ),
                  DSSegmentItem(
                    value: CastingMode.automatic,
                    label: '自动铜钱',
                    icon: Icons.casino_outlined,
                  ),
                  DSSegmentItem(
                    value: CastingMode.timePillar,
                    label: '时刻起卦',
                    icon: Icons.access_time_outlined,
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) {
                  setState(() => _mode = selection.first);
                },
              ),
            ),
            Expanded(
              child: IndexedStack(index: _mode.index, children: _pages),
            ),
          ],
        ),
      ),
    );
  }
}
