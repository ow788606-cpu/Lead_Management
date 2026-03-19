import 'package:flutter/material.dart';
import '../main.dart';

class MainWrapper extends StatelessWidget {
  final Widget child;
  final int? selectedIndex;

  const MainWrapper({
    super.key,
    required this.child,
    this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex ?? 0,
        onTap: (index) => _onBottomNavTap(context, index),
        selectedItemColor: const Color(0xFF0B5CFF),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Apps',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.call_outlined),
            activeIcon: Icon(Icons.call),
            label: 'Leads',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_outlined),
            activeIcon: Icon(Icons.task),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _onBottomNavTap(BuildContext context, int index) {
    // Navigate back to MainScreen with the selected index
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(initialIndex: _mapToScreenIndex(index)),
      ),
      (route) => false,
    );
  }

  int _mapToScreenIndex(int bottomNavIndex) {
    switch (bottomNavIndex) {
      case 0: // Apps -> Dashboard
        return 0;
      case 1: // Leads
        return 1;
      case 2: // Home -> Contacts
        return 3;
      case 3: // Tasks
        return 4;
      case 4: // Settings
        return 0; // Default to dashboard
      default:
        return 0;
    }
  }
}