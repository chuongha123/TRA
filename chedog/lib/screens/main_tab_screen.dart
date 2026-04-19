import 'package:flutter/material.dart';
import 'home_dashboard.dart';
import 'sensor_history_screen.dart';
import 'schedule_screen.dart';
import 'irrigation_history_screen.dart';
import 'weather_screen.dart';

/// Main tab shell with persistent bottom navigation.
class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = const [
    HomeDashboard(showBottomNav: false),
    SensorHistoryScreen(showBackButton: false, showBottomNav: false),
    ScheduleScreen(showBackButton: false, showBottomNav: false),
    IrrigationHistoryScreen(showBackButton: false, showBottomNav: false),
    WeatherScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sensors_outlined),
            activeIcon: Icon(Icons.sensors),
            label: 'Cảm biến',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule_outlined),
            activeIcon: Icon(Icons.schedule),
            label: 'Lịch tưới',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.water_drop_outlined),
            activeIcon: Icon(Icons.water_drop),
            label: 'Lịch sử tưới',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_outlined),
            activeIcon: Icon(Icons.cloud),
            label: 'Thời tiết',
          ),
        ],
      ),
    );
  }
}
