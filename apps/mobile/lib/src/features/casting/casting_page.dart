import 'package:flutter/material.dart';

import '../../ui/liuyao_design.dart';
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
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<CastingMode>(
                  key: const Key('casting-mode-switch'),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? LiuyaoColors.ink
                          : LiuyaoColors.paperRaised,
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? LiuyaoColors.paperRaised
                          : LiuyaoColors.ink,
                    ),
                    side: const WidgetStatePropertyAll(
                      BorderSide(color: LiuyaoColors.ink, width: 1),
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(LiuyaoRadii.small),
                      ),
                    ),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: CastingMode.manual,
                      icon: Icon(Icons.edit_outlined),
                      label: Text('手动'),
                    ),
                    ButtonSegment(
                      value: CastingMode.automatic,
                      icon: Icon(Icons.casino_outlined),
                      label: Text('自动铜钱'),
                    ),
                    ButtonSegment(
                      value: CastingMode.timePillar,
                      icon: Icon(Icons.access_time_outlined),
                      label: Text('时刻起卦'),
                    ),
                  ],
                  selected: {_mode},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) {
                    setState(() => _mode = selection.first);
                  },
                ),
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
