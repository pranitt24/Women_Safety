import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../state.dart';

class SosOverlay extends StatelessWidget {
  const SosOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return app.phase == SosPhase.countdown ? const _Countdown() : const _Sending();
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown();

  @override
  Widget build(BuildContext context) {
    const w = TextStyle(color: Colors.white);
    return Material(
      color: kSos,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const SizedBox(height: 24),
            const Text('Are you OK?',
                style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(app.reason, textAlign: TextAlign.center, style: w),
            const Spacer(),
            Text('${app.countdown}',
                style: const TextStyle(color: Colors.white, fontSize: 120, fontWeight: FontWeight.w800)),
            Text(
                'Alert goes to ${app.contacts.map((c) => c.name).join(', ')}'
                '${app.online ? '' : ' over Bluetooth relay'}.',
                textAlign: TextAlign.center,
                style: w),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: kSos),
                onPressed: app.cancel,
                child: const Padding(padding: EdgeInsets.all(14), child: Text("I'm safe, cancel")),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white, side: const BorderSide(color: Colors.white, width: 2)),
                onPressed: app.sendNow,
                child: const Padding(padding: EdgeInsets.all(14), child: Text('Send now')),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Sending extends StatelessWidget {
  const _Sending();

  @override
  Widget build(BuildContext context) {
    final online = !app.sentViaRelay;
    final lines = online
        ? const [
            'Location locked, accurate to 8 m',
            'Alert sent to Mom, Anita, Rohan',
            'Live tracking and audio started',
            'Police control room notified (pilot)',
          ]
        : const [
            'Network unavailable. Broadcasting over Bluetooth',
            'Nearby phone picked up the packet',
            'A phone with internet is uploading',
            'Alert delivered to Mom, Anita, Rohan',
            'SMS also queued until signal returns',
          ];
    final done = app.phase == SosPhase.done;
    return Material(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(done ? 'ALERT DELIVERED' : 'SENDING ALERT', style: Theme.of(context).textTheme.labelMedium),
            Text(online ? 'Alert on its way' : 'Offline relay',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            for (var i = 0; i < lines.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Opacity(
                  opacity: app.steps > i ? 1 : 0.35,
                  child: Row(children: [
                    Icon(app.steps > i ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: app.steps > i ? Colors.green : null),
                    const SizedBox(width: 10),
                    Expanded(child: Text(lines[i])),
                  ]),
                ),
              ),
            if (done)
              Card(
                margin: const EdgeInsets.only(top: 14),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('Asha may need help. Trigger: ${app.reason}. '
                      'Live location: sakhi.example/t/8f3k. Zone D3, battery 41%. Open the link or call 112.'),
                ),
              ),
            const Spacer(),
            if (done) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: kSos),
                  onPressed: () => launchUrl(Uri.parse('tel:112')),
                  child: const Padding(padding: EdgeInsets.all(12), child: Text('Call 112 now')),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: app.cancel,
                  child: const Padding(padding: EdgeInsets.all(12), child: Text("I'm safe, cancel alert")),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}
