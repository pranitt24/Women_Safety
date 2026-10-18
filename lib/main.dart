import 'package:flutter/material.dart';

import 'screens/circle_screen.dart';
import 'screens/detect_screen.dart';
import 'screens/fake_call_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/sos_overlay.dart';
import 'state.dart';
import 'theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SakhiApp());
  // Initialize permissions, sensors, geolocation, backend and BLE mesh without blocking first frame
  app.init();
}

class SakhiApp extends StatelessWidget {
  const SakhiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        return MaterialApp(
          title: 'Sakhi Safety',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: app.themeMode,
          home: const Shell(),
        );
      },
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _currentIndex = 0;

  static const _pages = <Widget>[
    HomeScreen(),
    MapScreen(),
    CircleScreen(),
    DetectScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        return Stack(
          children: [
            Scaffold(
              body: SafeArea(child: _pages[_currentIndex]),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (v) => setState(() => _currentIndex = v),
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
                  NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Safety map'),
                  NavigationDestination(icon: Icon(Icons.group_outlined), selectedIcon: Icon(Icons.group), label: 'Circle'),
                  NavigationDestination(icon: Icon(Icons.monitor_heart_outlined), selectedIcon: Icon(Icons.monitor_heart), label: 'Auto-detect'),
                ],
              ),
            ),

            // Active SOS Overlay (10s countdown or Live Transmission & Status)
            if (app.phase != SosPhase.idle)
              const Positioned.fill(child: SosOverlay()),

            // Discreet Fake Call Screen Overlay
            if (app.isFakeCallActive)
              const Positioned.fill(child: FakeCallScreen()),
          ],
        );
      },
    );
  }
}
