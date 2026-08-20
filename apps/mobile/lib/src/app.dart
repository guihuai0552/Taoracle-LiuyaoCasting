import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/almanac/almanac_client.dart';
import 'features/almanac/almanac_page.dart';
import 'features/archive/archive_page.dart';
import 'features/casting/casting_client.dart';
import 'features/casting/casting_page.dart';
import 'features/settings/settings_page.dart';
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
      title: '六爻工具',
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

  void _selectDestination(int value) {
    setState(() {
      _index = value;
      if (value == 2) {
        _pages[value] = _createPage(value);
      } else {
        _pages[value] ??= _createPage(value);
      }
    });
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _selectDestination,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: '日历',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_agenda_outlined),
            selectedIcon: Icon(Icons.view_agenda_rounded),
            label: '六爻',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: '档案',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
