import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import '../../services/api_service.dart';

class ScreenTab extends StatefulWidget {
  const ScreenTab({super.key});

  @override
  State<ScreenTab> createState() => _ScreenTabState();
}

class _ScreenTabState extends State<ScreenTab> {
  @override
  void dispose() {
    ApiService().stopScreenStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 5.0,
          child: Mjpeg(
            isLive: true,
            stream: ApiService().screenStreamUrl,
            error: (context, error, stack) => Center(child: Text('Yayın Hatası: $error', style: const TextStyle(color: Colors.red))),
            ),
          ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () {
                final dashboardState = context.findAncestorStateOfType<State<StatefulWidget>>();
                if (dashboardState != null && dashboardState.mounted) {
                   // ignore: invalid_use_of_protected_member
                   dashboardState.setState(() {
                      // We know _currentIndex is 0
                      // This is a hacky way without explicit callbacks but works since Dashboard is ancestor
                      (dashboardState as dynamic)._currentIndex = 0;
                   });
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
