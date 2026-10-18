import 'package:flutter/material.dart';

import 'screens/circle_screen.dart';
import 'screens/detect_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/sos_overlay.dart';
import 'state.dart';

const kAccent = Color(0xFF0B7A6A);
const kSos = Color(0xFFC8202F);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SakhiApp());
  app.init(); // permissions + sensors; do not block first frame
}

class SakhiApp extends StatelessWidget {
  const SakhiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sakhi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kAccent),
        scaffoldBackgroundColor: const Color(0xFFE9EEEC),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: kAccent, brightness: Brightness.dark),
      ),
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;
  static const _pages = <Widget>[HomeScreen(), MapScreen(), CircleScreen(), DetectScreen()];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        return Stack(children: [
          Scaffold(
            body: SafeArea(child: _pages[_i]),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _i,
              onDestinationSelected: (v) => setState(() => _i = v),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Safety map'),
                NavigationDestination(icon: Icon(Icons.group_outlined), label: 'Circle'),
                NavigationDestination(icon: Icon(Icons.monitor_heart_outlined), label: 'Auto-detect'),
              ],
            ),
          ),
          if (app.phase != SosPhase.idle) const Positioned.fill(child: SosOverlay()),
        ]);
      },
    );
  }
}
