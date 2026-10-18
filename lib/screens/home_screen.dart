import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../police/police_console_screen.dart';
import '../state.dart';
import '../theme/theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Status Card
            Card(
              child: ListTile(
                leading: Icon(
                  app.online ? Icons.verified_user : Icons.bluetooth_searching,
                  color: app.online ? kSafeGreen : Colors.orange,
                  size: 28,
                ),
                title: Text(
                  app.online ? 'You are protected' : 'Offline protection active',
                  style: GoogleFonts.bricolageGrotesque(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  app.online
                      ? '${app.contacts.length} trusted contacts & Mumbai Crime Branch linked'
                      : 'Distress packets relay over BLE through nearby Sakhi phones',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (app.online ? kSafeGreen : Colors.orange).withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    app.online ? 'ONLINE' : 'MESH BLE',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: app.online ? kSafeGreen : Colors.orange.shade800,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Large SOS Button with Hold Ring
            const Center(child: SosButton()),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Hold 1 second to start SOS countdown.\nEvery alert has a 10s cancel window before sending.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),

            const SizedBox(height: 20),

            // Discreet Safety Shortcuts: Fake Call, Night Mode, Police Console
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.phone_in_talk, size: 18, color: kAccent),
                    label: const Text('Fake Call', style: TextStyle(fontSize: 13)),
                    onPressed: () => app.triggerFakeCall(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(
                      app.isDiscreetMode ? Icons.light_mode : Icons.dark_mode,
                      size: 18,
                      color: kAccent,
                    ),
                    label: Text(
                      app.isDiscreetMode ? 'Normal' : 'Discreet',
                      style: const TextStyle(fontSize: 13),
                    ),
                    onPressed: () => app.toggleTheme(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.shield_outlined, size: 18, color: kAccent),
                    label: const Text('Police Console', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PoliceConsoleScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Safe Journey Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Safe Journey',
                        style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        app.journey
                            ? 'Heading to ${app.journeyDestinationName}. Monitoring 150m route corridor.'
                            : 'Share destination route and ETA with your trusted circle.',
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: app.journey,
                      onChanged: (v) => app.toggleJourney(v),
                    ),
                    if (app.journey) ...[
                      const Divider(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.navigation_outlined, size: 18, color: kAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Destination: ${app.journeyDestinationName}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showDestinationPicker(context),
                            child: const Text('Change', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Demo Network Switch
            Card(
              child: SwitchListTile(
                title: const Text('Demo: Phone cellular network'),
                subtitle: const Text('Turn off to simulate offline BLE mesh broadcast',
                    style: TextStyle(fontSize: 12)),
                value: !app.demoOffline,
                onChanged: (_) => app.toggleDemoOffline(),
              ),
            ),

            // Risk Score Right Now Card
            Card(
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (app.score >= alertThreshold ? kSos : Colors.orange).withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      app.score >= alertThreshold ? Icons.warning_amber : Icons.speed,
                      color: app.score >= alertThreshold ? kSos : Colors.orange,
                    ),
                  ),
                ),
                title: const Text('Sensor Risk Score right now'),
                subtitle: const Text('Alert countdown triggers automatically at 60/100',
                    style: TextStyle(fontSize: 12)),
                trailing: Text(
                  '${app.score}/100',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: app.score >= alertThreshold ? kSos : null,
                  ),
                ),
              ),
            ),

            // Relay Activity Log
            if (app.meshLog.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.hub_outlined, size: 16, color: kAccent),
                          SizedBox(width: 6),
                          Text('Bluetooth Mesh Relay Log',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (final m in app.meshLog.take(4))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            '• $m',
                            style: GoogleFonts.jetBrainsMono(fontSize: 11, color: Colors.black87),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showDestinationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Journey Destination', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.business, color: kAccent),
                  title: const Text('Bandra Kurla Complex (BKC)'),
                  subtitle: const Text('Corporate Park corridor'),
                  onTap: () {
                    app.journeyDestinationName = 'Bandra Kurla Complex';
                    app.toggleJourney(true);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.train, color: kAccent),
                  title: const Text('Dadar Central Station'),
                  subtitle: const Text('Transit hub corridor'),
                  onTap: () {
                    app.journeyDestinationName = 'Dadar Central Station';
                    app.toggleJourney(true);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.home, color: kAccent),
                  title: const Text('Home (Kurla West)'),
                  subtitle: const Text('Residential corridor'),
                  onTap: () {
                    app.journeyDestinationName = 'Home (Kurla West)';
                    app.toggleJourney(true);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Hold for 1 second to start the countdown.
class SosButton extends StatefulWidget {
  const SosButton({super.key});

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        app.startCountdown('Manual SOS Button Pressed');
        _c.reset();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) => _c.reset(),
      onTapCancel: () => _c.reset(),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Circular progress ring
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: _c.value,
                  strokeWidth: 8,
                  color: kSos,
                  backgroundColor: kSos.withAlpha(40),
                ),
              ),
              // Big red SOS central touch button
              Container(
                width: 192,
                height: 192,
                decoration: BoxDecoration(
                  color: kSos,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kSos.withAlpha((80 + (_c.value * 100)).toInt()),
                      blurRadius: 18,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SOS',
                      style: GoogleFonts.bricolageGrotesque(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      _c.value > 0 ? 'Hold...' : 'Hold 1 sec',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
