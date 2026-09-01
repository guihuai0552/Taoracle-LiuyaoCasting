import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/almanac/almanac_client.dart';
import 'features/almanac/almanac_page.dart';
import 'features/archive/archive_page.dart';
import 'features/casting/casting_client.dart';
import 'features/casting/casting_page.dart';
import 'features/settings/app_preferences.dart';
import 'features/settings/calendar_policy_sheet.dart';
import 'features/settings/settings_page.dart';
import 'ui/design_system/components/ds_bottom_navigation.dart';
import 'ui/design_system/components/liuyao_icon.dart';
import 'ui/liuyao_design.dart';

class LiuyaoArchiveApp extends StatelessWidget {
  const LiuyaoArchiveApp({
    super.key,
    this.almanacDataSource,
    this.castingDataSource,
  });

  final AlmanacDataSource? almanacDataSource;
  final CastingDataSource? castingDataSource;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '道谕六爻',
      theme: buildLiuyaoTheme(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
      locale: const Locale('zh', 'CN'),
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: child ?? const SizedBox.shrink(),
      ),
      home: HomeShell(
        almanacDataSource: almanacDataSource,
        castingDataSource: castingDataSource,
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.almanacDataSource, this.castingDataSource});

  final AlmanacDataSource? almanacDataSource;
  final CastingDataSource? castingDataSource;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  late final List<Widget?> _pages;

  /// 万年历选中的日期草稿，切换至起卦页时自动带入。
  DateTime? _sharedCastingDate;

  /// 首次口径弹窗守卫：避免重复触发。
  bool _policyPromptInFlight = false;

  @override
  void initState() {
    super.initState();
    _pages = [
      AlmanacPage(
        dataSource: widget.almanacDataSource,
        onDateSelected: _onAlmanacDateSelected,
      ),
      null,
      null,
      null,
    ];
    // 启动即加载偏好（幂等）；首次进入六爻前完成口径确认。
    loadPreferences();
  }

  void _onAlmanacDateSelected(DateTime date) {
    _sharedCastingDate = date;
  }

  Widget _createPage(int index) {
    return switch (index) {
      0 => AlmanacPage(
        dataSource: widget.almanacDataSource,
        onDateSelected: _onAlmanacDateSelected,
      ),
      1 => CastingPage(
        dataSource: widget.castingDataSource,
        initialDateTime: _sharedCastingDate,
      ),
      2 => ArchivePage(key: UniqueKey()),
      _ => const SettingsPage(),
    };
  }

  Future<void> _maybePromptCalendarPolicy() async {
    if (_policyPromptInFlight) return;
    final prefs = currentPreferences;
    if (prefs.calendarPolicySetupCompleted) return;
    _policyPromptInFlight = true;
    try {
      final selection = await showCalendarPolicySheet(
        context,
        initialDayBoundary: prefs.dayBoundaryStrategy,
        initialMonthBoundary: prefs.monthBoundaryStrategy,
        title: '先选择历法口径',
        // 首次为强制选择：不允许点外部关闭。
        barrierDismissible: false,
      );
      if (selection == null) {
        // 首次不允许跳过：回退日历页等待下次进入。
        if (!mounted) return;
        setState(() => _index = 0);
        return;
      }
      await savePreferences(
        prefs.copyWith(
          calendarPolicySetupCompleted: true,
          dayBoundaryStrategy: selection.dayBoundary,
          monthBoundaryStrategy: selection.monthBoundary,
        ),
      );
    } finally {
      _policyPromptInFlight = false;
    }
  }

  void _selectDestination(int value) {
    setState(() {
      _index = value;
      if (value == 2) {
        _pages[value] = _createPage(value);
      } else {
        _pages[value] ??= _createPage(value);
      }
    });
    if (value == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybePromptCalendarPolicy();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiuyaoPaperBackground(
        child: IndexedStack(
          index: _index,
          children: _pages
              .map((page) => page ?? const SizedBox.shrink())
              .toList(growable: false),
        ),
      ),
      bottomNavigationBar: DSBottomNavigation(
        selectedIndex: _index,
        onDestinationSelected: _selectDestination,
        destinations: [
          DSDestinationItem(
            label: '日历',
            icon: Icons.calendar_month_outlined,
            selectedIcon: Icons.calendar_month_rounded,
            svgIcon: LiuyaoIconType.calendar,
          ),
          DSDestinationItem(
            label: '六爻',
            icon: Icons.view_agenda_outlined,
            selectedIcon: Icons.view_agenda_rounded,
            svgIcon: LiuyaoIconType.divination,
            itemKey: const Key('nav-liuyao'),
          ),
          DSDestinationItem(
            label: '档案',
            icon: Icons.inventory_2_outlined,
            selectedIcon: Icons.inventory_2,
            svgIcon: LiuyaoIconType.archive,
          ),
          DSDestinationItem(
            label: '设置',
            icon: Icons.tune_outlined,
            selectedIcon: Icons.tune_rounded,
            svgIcon: LiuyaoIconType.settings,
          ),
        ],
      ),
    );
  }
}
