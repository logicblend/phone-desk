import 'package:flutter/material.dart';
import 'tabs/touchpad_tab.dart';
import 'tabs/screen_tab.dart';
import 'tabs/files_tab.dart';
import 'tabs/deck_tab.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_container.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    TouchpadTab(),
    ScreenTab(),
    FilesTab(),
    DeckTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AppBackground(
        child: _tabs[_currentIndex],
      ),
      bottomNavigationBar: _currentIndex == 1 ? null : GlassContainer(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        borderRadius: BorderRadius.circular(30),
        child: BottomNavigationBar(
          elevation: 0,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.touch_app), label: 'Touchpad'),
          BottomNavigationBarItem(icon: Icon(Icons.desktop_windows), label: 'Ekran'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Dosyalar'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Deck'),
          ],
        ),
      ),
    );
  }
}
