import 'package:flutter/material.dart';

import 'features/agent/agent_page.dart';
import 'features/archive/archive_page.dart';

class LiuyaoArchiveApp extends StatelessWidget {
  const LiuyaoArchiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF251D18);
    const cinnabar = Color(0xFF9C3427);
    const paper = Color(0xFFF7F1E7);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '六爻存档',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: cinnabar,
          brightness: Brightness.light,
          surface: paper,
        ),
        scaffoldBackgroundColor: const Color(0xFFF2EBDD),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: ink,
          displayColor: ink,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: paper,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0x1A251D18)),
          ),
        ),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [ArchivePage(), AgentPage()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: '存档',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: '助手',
          ),
        ],
      ),
    );
  }
}
