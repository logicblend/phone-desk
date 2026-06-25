import 'package:flutter/material.dart';
import 'tabs/touchpad_tab.dart';
import 'tabs/screen_tab.dart';
import 'tabs/files_tab.dart';
import 'tabs/deck_tab.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_container.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../services/api_service.dart';

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

  void _showSettingsDialog(BuildContext context) {
    final pwdController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Ayarlar', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: pwdController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Yeni Şifre',
            labelStyle: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            onPressed: () async {
              if (pwdController.text.isNotEmpty) {
                await ApiService().updatePassword(pwdController.text);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Şifreyi Güncelle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AppBackground(
        child: LiquidGlassLayer(
          fake: true,
          settings: const LiquidGlassSettings(
            thickness: 10,
            blur: 15,
            glassColor: Color(0x22FFFFFF),
          ),
          child: Stack(
            children: [
              _tabs[_currentIndex],
              Positioned(
                top: 40,
                right: 16,
                child: GlassContainer(
                  borderRadius: 24,
                  child: IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white, size: 24),
                    onPressed: () => _showSettingsDialog(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _currentIndex == 1 ? null : GlassContainer(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        borderRadius: 30.0,
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
