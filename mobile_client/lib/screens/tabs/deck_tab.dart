import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/glass_container.dart';

class DeckTab extends StatefulWidget {
  const DeckTab({super.key});

  @override
  State<DeckTab> createState() => _DeckTabState();
}

class _DeckTabState extends State<DeckTab> {
  List<dynamic> _profiles = [];
  List<dynamic> _buttons = [];
  String? _activeProfileId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await ApiService().getDeckProfiles();
    _profiles = data['profiles'] ?? [];
    _activeProfileId = data['activeProfileId'];
    if (_activeProfileId != null) {
      _buttons = await ApiService().getDeckButtons(_activeProfileId!);
    }
    setState(() => _isLoading = false);
  }

  void _onProfileChanged(String? newId) async {
    if (newId == null) return;
    setState(() {
      _activeProfileId = newId;
      _isLoading = true;
    });
    _buttons = await ApiService().getDeckButtons(newId);
    setState(() => _isLoading = false);
  }

  void _onButtonTap(Map<String, dynamic> button) {
    ApiService().executeDeckButton(button);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        SafeArea(
          child: GlassContainer(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              value: _activeProfileId,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white, fontSize: 18),
              items: _profiles.map((p) => DropdownMenuItem<String>(
                value: p['id'],
                child: Text(p['name']),
              )).toList(),
              onChanged: _onProfileChanged,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _buttons.length,
            itemBuilder: (context, index) {
              final btn = _buttons[index];
              final label = btn['label'] ?? '';
              final colorHex = btn['color']?.replaceAll('#', 'FF') ?? 'FF3B82F6';
              final color = Color(int.parse(colorHex, radix: 16));

              return InkWell(
                onTap: () => _onButtonTap(btn),
                borderRadius: BorderRadius.circular(16),
                child: GlassContainer(
                  opacity: 0.2,
                  borderColor: color.withAlpha(128),
                  child: Center(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
