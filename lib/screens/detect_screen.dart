import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../state.dart';
import '../theme/theme.dart';

class DetectScreen extends StatelessWidget {
  const DetectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final sc = app.score;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Auto-Detect Engine', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            const Text(
              'Real hardware sensors monitor for falls and network drops. '
              'A single weak signal never sends an alert: multiple signals must combine to reach the threshold.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Combined Score Gauge Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Combined Risk Score', style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        Text(
                          '$sc/100',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: sc >= alertThreshold ? kSos : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: sc / 100,
                        minHeight: 12,
                        color: sc >= alertThreshold ? kSos : Colors.orange,
                        backgroundColor: Colors.grey.withAlpha(40),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          sc >= alertThreshold ? Icons.warning : Icons.info_outline,
                          size: 16,
                          color: sc >= alertThreshold ? kSos : Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Alert countdown starts automatically at $alertThreshold.',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Signals List Card
            Card(
              child: Column(
                children: [
                  for (final s in signalDefs)
                    SwitchListTile(
                      title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${s.desc}  (+${s.weight} pts)'),
                      value: app.sig[s.key]!,
                      activeTrackColor: kSos,
                      onChanged: (v) => app.setSignal(s.key, v),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Quick Demo Simulation Card
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(50),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.touch_app_outlined, size: 20, color: kAccent),
                        const SizedBox(width: 8),
                        Text(
                          'Demo Simulation for Crime Branch',
                          style: GoogleFonts.bricolageGrotesque(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Trigger Network Loss (25) + Impact (40) = 65 pts. '
                      'This crosses the 60 threshold and starts the 10-second cancel countdown.',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          app.setSignal('net', true);
                          app.setSignal('impact', true);
                        },
                        child: const Text('Simulate: Network Loss + Sudden Fall (Score 65)'),
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
}
