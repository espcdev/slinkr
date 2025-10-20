import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:percent_indicator/percent_indicator.dart';

import 'settings_screen.dart';
import 'about_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  runApp(const SlinkrApp());
}

class SlinkrApp extends StatefulWidget {
  const SlinkrApp({super.key});

  @override
  State<SlinkrApp> createState() => SlinkrAppState();

  static SlinkrAppState of(BuildContext context) =>
      context.findAncestorStateOfType<SlinkrAppState>()!;
}

class SlinkrAppState extends State<SlinkrApp> {
  String _currentFontFamily = 'FredokaOne';
  String _currentThemeColorName = 'Morado';
  final Map<String, Color> _themeColors = {
    'Morado': Colors.purple,
    'Verde': Colors.green,
    'Azul': Colors.blue,
    'Naranja': Colors.orange,
  };

  @override
  void initState() {
    super.initState();
    _loadThemeSettings();
  }

  Future<void> _loadThemeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentFontFamily = prefs.getString('fontFamily') ?? 'FredokaOne';
      _currentThemeColorName = prefs.getString('themeColor') ?? 'Morado';
    });
  }

  void updateTheme() {
    _loadThemeSettings();
  }

  @override
  Widget build(BuildContext context) {
    final Color currentThemeColor = _themeColors[_currentThemeColorName] ?? Colors.purple;
    return MaterialApp(
      title: 'Slinkr',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: _currentFontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: currentThemeColor,
          brightness: Brightness.dark,
          surface: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.black,
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        ),
        // --- NUEVO: Tema para los menús desplegables ---
        dropdownMenuTheme: DropdownMenuThemeData(
          menuStyle: MenuStyle(
            shape: WidgetStateProperty.all(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            )),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return currentThemeColor;
            return Colors.grey;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return currentThemeColor.withOpacity(0.5);
            return Colors.grey.withOpacity(0.5);
          }),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: currentThemeColor,
          thumbColor: currentThemeColor,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final Battery _battery = Battery();
  int _batteryLevel = 100;
  bool _isCharging = false;
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  Timer? _periodicTimer;

  late AnimationController _animationController;

  bool _serviceActive = false;
  double _lowAlertLevel1 = 20.0;
  double _lowAlertLevel2 = 10.0;
  double _fullChargeAlertLevel = 98.0;

  bool _lowAlert1Sent = false;
  bool _lowAlert2Sent = false;
  bool _fullChargeAlertSent = false;
  
  double _batteryHealth = 100.0;
  Duration? _estimatedTimeRemaining;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _requestPermissions();
    _checkInitialBatteryStatus();
    
    _batteryStateSubscription = _battery.onBatteryStateChanged.listen((BatteryState state) {
      if (!mounted) return;
      final isCurrentlyCharging = state == BatteryState.charging;
      if (_isCharging != isCurrentlyCharging) {
        setState(() {
          _isCharging = isCurrentlyCharging;
          if (_isCharging) _animationController.repeat(reverse: true);
          else _animationController.stop();
        });
      }
      _checkBatteryLevel();
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _lowAlertLevel1 = prefs.getDouble('lowAlert1') ?? 20.0;
      _lowAlertLevel2 = prefs.getDouble('lowAlert2') ?? 10.0;
      _fullChargeAlertLevel = prefs.getDouble('fullChargeAlert') ?? 98.0;
    });
    SlinkrApp.of(context).updateTheme();
  }
  
  void _checkInitialBatteryStatus() async {
    final status = await _battery.batteryState;
    if (!mounted) return;
    setState(() {
      _isCharging = status == BatteryState.charging;
      if (_isCharging) {
        _animationController.repeat(reverse: true);
      }
    });
    _checkBatteryLevel();
    _calculateBatteryHealth();
  }

  Future<void> _checkBatteryLevel() async {
    final level = await _battery.batteryLevel;
    if (!mounted) return;
    setState(() { _batteryLevel = level; });
    _calculateEstimatedTime();
    if (_serviceActive) {
      _handleNotifications(level);
    }
  }

  void _calculateBatteryHealth() {
    setState(() {
      _batteryHealth = 100.0 - ((100 - _batteryLevel) / 100 * 5);
      if (_batteryHealth < 80) _batteryHealth = 80;
    });
  }

  void _calculateEstimatedTime() {
    if (_isCharging) {
      int minutesToFull = (100 - _batteryLevel);
      if (minutesToFull < 0) minutesToFull = 0;
      setState(() => _estimatedTimeRemaining = Duration(minutes: minutesToFull));
    } else {
      int minutesRemaining = _batteryLevel * 3;
      setState(() => _estimatedTimeRemaining = Duration(minutes: minutesRemaining));
    }
  }

  void _handleNotifications(int level) {
    if (!_isCharging) {
      _fullChargeAlertSent = false;
      if (level <= _lowAlertLevel1 && !_lowAlert1Sent) {
        _showNotification("¡Batería Baja!", "Nivel al $level%. Considera conectar.", 1);
        _lowAlert1Sent = true;
      }
      if (level <= _lowAlertLevel2 && !_lowAlert2Sent) {
        _showNotification("¡Batería Crítica!", "Nivel al $level%. Conecta tu dispositivo.", 2);
        _lowAlert2Sent = true;
      }
      if (level > _lowAlertLevel1) _lowAlert1Sent = false;
      if (level > _lowAlertLevel2) _lowAlert2Sent = false;
    } else {
      _lowAlert1Sent = _lowAlert2Sent = false;
      if (level >= _fullChargeAlertLevel && !_fullChargeAlertSent) {
        _showNotification("¡Carga Completa!", "Batería al $level%. Puedes desconectar.", 3);
        _fullChargeAlertSent = true;
      }
      if (level < _fullChargeAlertLevel) _fullChargeAlertSent = false;
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.notification.request();
    await Permission.ignoreBatteryOptimizations.request();
  }

  void _toggleService() {
    setState(() {
      _serviceActive = !_serviceActive;
      if (_serviceActive) {
        _periodicTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
          _checkBatteryLevel();
        });
      } else {
        _periodicTimer?.cancel();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Servicio de Alertas ${_serviceActive ? "Activado" : "Desactivado"}.'))
      );
    });
  }

  Future<void> _showNotification(String title, String body, int id) async {
    final prefs = await SharedPreferences.getInstance();
    final bool soundEnabled = prefs.getBool('soundEnabled') ?? true;
    final bool vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'slinkr_channel_id',
      'Alertas de Batería',
      channelDescription: 'Canal para notificaciones de Slinkr.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: soundEnabled,
      sound: soundEnabled ? const RawResourceAndroidNotificationSound('notification') : null,
      vibrationPattern: vibrationEnabled ? Int64List.fromList([0, 1000, 500, 1000]) : null,
      ticker: 'ticker',
    );
    final NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    
    await flutterLocalNotificationsPlugin.show(id, title, body, platformDetails);
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return "Calculando...";
    if (duration.inMinutes < 1) return "< 1 min";
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return "$hours h $minutes min";
  }

  @override
  void dispose() {
    _batteryStateSubscription?.cancel();
    _periodicTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    final Color accentColor = currentTheme.colorScheme.primary;
    final Color percentColor = _isCharging ? accentColor : currentTheme.colorScheme.onSurface;
    final String titleText = _isCharging ? "Cargando..." : "Nivel de Batería Actual";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Slinkr'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              if (result == true) {
                _loadSettings();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(titleText, style: TextStyle(fontSize: 22, color: Colors.grey[400])),
              const SizedBox(height: 10),
              CircularPercentIndicator(
                radius: 90.0,
                lineWidth: 12.0,
                percent: _batteryLevel / 100,
                center: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1 + (_isCharging ? _animationController.value * 0.1 : 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isCharging) Icon(Icons.bolt, color: percentColor, size: 30),
                          Text(
                            '$_batteryLevel%',
                            style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: percentColor),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                footer: Column(
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      _isCharging ? "Para carga completa: ${_formatDuration(_estimatedTimeRemaining)}" : "Tiempo restante: ${_formatDuration(_estimatedTimeRemaining)}",
                      style: TextStyle(color: Colors.grey[500], fontSize: 16),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Salud estimada: ${_batteryHealth.toInt()}%',
                      style: TextStyle(color: Colors.grey[500], fontSize: 16),
                    ),
                  ],
                ),
                circularStrokeCap: CircularStrokeCap.round,
                backgroundColor: Colors.grey.withOpacity(0.3),
                progressColor: percentColor,
              ),
              const SizedBox(height: 40),
              Card(
                child: SwitchListTile(
                  title: const Text('Activar Alertas', style: TextStyle(fontSize: 18)),
                  value: _serviceActive,
                  onChanged: (value) => _toggleService(),
                  activeColor: accentColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
              ),
              const SizedBox(height: 10),
              if (_serviceActive)
                Text(
                  'Alertas activas para: ${_lowAlertLevel2.toInt()}% (crítico), ${_lowAlertLevel1.toInt()}% (bajo) y ${_fullChargeAlertLevel.toInt()}% (carga completa).',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
            ],
          ),
        ),
      ),
    );
  }
}