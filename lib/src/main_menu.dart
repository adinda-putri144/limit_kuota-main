import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'features/monitoring/network.dart';
import 'features/monitoring/history_page.dart';
import 'features/monitoring/limit_page.dart';

import 'package:limit_kuota/src/core/data/database_helper.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  static const platform = MethodChannel('limit_kuota/channel');

  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    Network(),
    HistoryPage(),
    LimitPage(),
  ];

  @override
  void initState() {
    super.initState();
    _collectTodayUsage(); // 🔥 INI YANG MEMPERBAIKI SEMUA
  }

  Future<void> _collectTodayUsage() async {
    try {
      final result = await platform.invokeMethod('getTodayUsage');

      String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await DatabaseHelper.instance.insertOrUpdate(
        todayDate,
        result['wifi'],
        result['mobile'],
      );
    } catch (e) {
      debugPrint("Collect usage error: $e");
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Limit',
          ),
        ],
      ),
    );
  }
}