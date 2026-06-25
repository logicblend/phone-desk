import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';
import '../widgets/glass_container.dart';
import '../widgets/app_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '8080');
  final _pwdController = TextEditingController();
  bool _isScanning = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  Future<void> _loadSavedConfig() async {
    await ApiService().loadConfig();
    setState(() {
      _ipController.text = ApiService().ipAddress;
      if (ApiService().port != 0) {
        _portController.text = ApiService().port.toString();
      }
      _pwdController.text = ApiService().password;
    });
  }

  Future<void> _connect() async {
    setState(() => _isLoading = true);
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 8080;
    final pwd = _pwdController.text.trim();

    await ApiService().saveConfig(ip, port, pwd);
    
    String deviceName = 'MobileClient';
    int? batteryLevel;
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        deviceName = (await deviceInfo.androidInfo).model;
      } else if (Platform.isIOS) {
        deviceName = (await deviceInfo.iosInfo).name;
      }
      batteryLevel = await Battery().batteryLevel;
    } catch (_) {}

    final success = await ApiService().connect({
      'name': deviceName,
      'battery': batteryLevel,
    });
    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bağlantı kurulamadı veya şifre hatalı.')),
      );
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return;
    final String code = capture.barcodes.first.rawValue ?? '';
    if (code.startsWith('http://')) {
      final uri = Uri.tryParse(code);
      if (uri != null) {
        setState(() {
          _ipController.text = uri.host;
          _portController.text = uri.port.toString();
          _isScanning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isScanning) {
      return Scaffold(
        appBar: AppBar(title: const Text('QR Kodu Okutun')),
        body: Stack(
          children: [
            MobileScanner(onDetect: _onDetect),
            Positioned(
              bottom: 40, left: 0, right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: () => setState(() => _isScanning = false),
                  child: const Text('İptal'),
                ),
              ),
            )
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: LiquidGlassLayer(
          fake: true,
          settings: const LiquidGlassSettings(
            thickness: 15,
            blur: 20,
            glassColor: Color(0x33FFFFFF),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: GlassContainer(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                    const Icon(Icons.settings_remote, size: 80, color: Colors.blueAccent),
                    const SizedBox(height: 24),
                    const Text('Phone Desk', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    const Text('Bilgisayarınıza Bağlanın', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 48),
                    TextField(
                controller: _ipController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'IP Adresi',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _portController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Port',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withAlpha(13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pwdController,
                style: const TextStyle(color: Colors.white),
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Güvenlik Şifresi',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withAlpha(13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _connect,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Bağlan', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => setState(() => _isScanning = true),
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white70),
                label: const Text('QR Kod ile Bağlan', style: TextStyle(color: Colors.white70)),
              ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
