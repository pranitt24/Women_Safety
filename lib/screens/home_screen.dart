import 'package:flutter/material.dart';

import '../main.dart';
import '../state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.verified_user_outlined, color: kAccent),
            title: Text(app.online ? 'You are protected' : 'Offline protection active'),
            subtitle: Text(app.online
                ? '3 trusted contacts can see an alert'
                : 'Alerts relay through nearby Sakhi phones over Bluetooth'),
          ),
        ),
        const SizedBox(height: 24),
        const Center(child: SosButton()),
        const SizedBox(height: 8),
        const Center(
            child: Text('A 10 second countdown lets you cancel before anything is sent.',
                textAlign: TextAlign.center)),
        const SizedBox(height: 24),
        Card(
          child: SwitchListTile(
            title: const Text('Safe journey'),
            subtitle: Text(app.journey
                ? 'Route shared with Mom. We alert if you leave it.'
                : 'Share your route and ETA'),
            value: app.journey,
            onChanged: (v) => app.update(() => app.journey = v),
          ),
        ),
        Card(
          child: SwitchListTile(
            title: const Text('Demo: phone network'),
            subtitle: const Text('Turn off to see offline BLE relay'),
            value: !app.demoOffline,
            onChanged: (_) => app.toggleDemoOffline(),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Risk score right now'),
            trailing: Text('${app.score}/100'),
          ),
        ),
        if (app.meshLog.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Relay activity', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                for (final m in app.meshLog.take(5)) Text(m, style: const TextStyle(fontSize: 12)),
              ]),
            ),
          ),
      ],
    );
  }
}

/// Hold for 1.2 seconds to start the countdown.
class SosButton extends StatefulWidget {
  const SosButton({super.key});
  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        app.startCountdown('Manual SOS pressed');
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
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 220,
              height: 220,
              child: CircularProgressIndicator(
                value: _c.value,
                strokeWidth: 6,
                color: kSos,
                backgroundColor: kSos.withAlpha(40),
              ),
            ),
            Container(
              width: 192,
              height: 192,
              decoration: const BoxDecoration(color: kSos, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Column(mainAxisSize: MainAxisSize.min, children: [
                Text('SOS',
                    style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800)),
                Text('Hold 1 second', style: TextStyle(color: Colors.white70)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
