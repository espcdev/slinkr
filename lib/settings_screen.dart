import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;

  // Variables para los ajustes
  double _lowAlertLevel1 = 20.0;
  double _lowAlertLevel2 = 10.0;
  double _fullChargeAlertLevel = 98.0;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  int _repeatNotifications = 1;
  String _themeColorName = 'Morado';
  String _fontFamily = 'FredokaOne';

  final Map<String, Color> _themeColors = {
    'Morado': Colors.purple,
    'Verde': Colors.green,
    'Azul': Colors.blue,
    'Naranja': Colors.orange,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Simulamos una pequeña demora para que la animación se aprecie
    await Future.delayed(const Duration(milliseconds: 800));

    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _lowAlertLevel1 = prefs.getDouble('lowAlert1') ?? 20.0;
        _lowAlertLevel2 = prefs.getDouble('lowAlert2') ?? 10.0;
        _fullChargeAlertLevel = prefs.getDouble('fullChargeAlert') ?? 98.0;
        _soundEnabled = prefs.getBool('soundEnabled') ?? true;
        _vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
        _repeatNotifications = prefs.getInt('repeatNotifications') ?? 1;
        _themeColorName = prefs.getString('themeColor') ?? 'Morado';
        _fontFamily = prefs.getString('fontFamily') ?? 'FredokaOne';
        _isLoading = false; // Finaliza la carga
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('lowAlert1', _lowAlertLevel1);
    await prefs.setDouble('lowAlert2', _lowAlertLevel2);
    await prefs.setDouble('fullChargeAlert', _fullChargeAlertLevel);
    await prefs.setBool('soundEnabled', _soundEnabled);
    await prefs.setBool('vibrationEnabled', _vibrationEnabled);
    await prefs.setInt('repeatNotifications', _repeatNotifications);
    await prefs.setString('themeColor', _themeColorName);
    await prefs.setString('fontFamily', _fontFamily);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajustes guardados')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading ? _buildSkeletonView() : _buildSettingsView(),
    );
  }

  // Widget para la animación de carga "Skeleton"
  Widget _buildSkeletonView() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[900]!,
      highlightColor: Colors.grey[800]!,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: List.generate(7, (_) => _buildSkeletonCard()),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Card(
      child: Container(
        height: 80.0,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        alignment: Alignment.centerLeft,
        child: Container(
          height: 20.0,
          width: 150.0,
          color: Colors.white,
        ),
      ),
    );
  }

  // Widget con los ajustes reales una vez cargados
  Widget _buildSettingsView() {
    final Color currentThemeColor = _themeColors[_themeColorName] ?? Colors.purple;
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSliderCard(
          label: 'Alerta de Batería Baja (Nivel 1)',
          value: _lowAlertLevel1,
          min: 5, max: 50,
          activeColor: currentThemeColor,
          onChanged: (newValue) => setState(() => _lowAlertLevel1 = newValue),
        ),
        const SizedBox(height: 16),
        _buildSliderCard(
          label: 'Alerta de Batería Crítica (Nivel 2)',
          value: _lowAlertLevel2,
          min: 5, max: 30,
          activeColor: currentThemeColor,
          onChanged: (newValue) => setState(() => _lowAlertLevel2 = newValue),
        ),
        const SizedBox(height: 16),
        _buildSliderCard(
          label: 'Alerta de Carga Completa',
          value: _fullChargeAlertLevel,
          min: 80, max: 100,
          activeColor: currentThemeColor,
          onChanged: (newValue) => setState(() => _fullChargeAlertLevel = newValue),
        ),
        const SizedBox(height: 16),
        Card(
          child: SwitchListTile(
            title: const Text('Sonido de Notificación'),
            value: _soundEnabled,
            onChanged: (value) => setState(() => _soundEnabled = value),
            activeColor: currentThemeColor,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: SwitchListTile(
            title: const Text('Vibración'),
            value: _vibrationEnabled,
            onChanged: (value) => setState(() => _vibrationEnabled = value),
            activeColor: currentThemeColor,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            title: const Text('Color del Tema'),
            trailing: DropdownButton<String>(
              value: _themeColorName,
              dropdownColor: Theme.of(context).cardTheme.color,
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() => _themeColorName = newValue);
                }
              },
              items: _themeColors.keys.map((String colorName) {
                return DropdownMenuItem<String>(
                  value: colorName,
                  child: Text(colorName),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: currentThemeColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          onPressed: _saveSettings,
          child: const Text('Guardar Cambios', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildSliderCard({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required Color activeColor,
    double min = 5.0,
    double max = 50.0,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label: ${value.toInt()}%',
              style: const TextStyle(fontSize: 18),
            ),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: ((max - min) / 1).toInt(),
              label: '${value.toInt()}%',
              activeColor: activeColor,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}