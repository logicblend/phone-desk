import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/glass_container.dart';

class TouchpadTab extends StatelessWidget {
  const TouchpadTab({super.key});

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount == 1) {
      ApiService().sendMouse('move', dx: details.focalPointDelta.dx.toInt(), dy: details.focalPointDelta.dy.toInt());
    } else if (details.pointerCount == 2) {
      ApiService().sendMouse('scroll', dy: details.focalPointDelta.dy.toInt());
    }
  }

  void _onTap() {
    ApiService().sendMouse('left_click', click: true);
  }

  void _onSecondaryTap() {
    ApiService().sendMouse('right_click');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleUpdate: _onScaleUpdate,
      onTap: _onTap,
      onSecondaryTap: _onSecondaryTap,
      onDoubleTap: () => ApiService().sendMouse('left_click', click: true),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: GlassContainer(
            width: double.infinity,
            height: 400,
            child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app, size: 80, color: Colors.white24),
              SizedBox(height: 16),
              Text('Touchpad Alanı', style: TextStyle(color: Colors.white54, fontSize: 18)),
              Text('Fareyi hareket ettirmek için sürükleyin', style: TextStyle(color: Colors.white38)),
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
