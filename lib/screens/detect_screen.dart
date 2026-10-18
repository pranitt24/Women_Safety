import 'package:flutter/material.dart';

import '../main.dart';
import '../state.dart';

class DetectScreen extends StatelessWidget {
  const DetectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sc = app.score;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Auto-detect', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Network loss and impact are read from the phone. The other signals are simulated here. '
            'A single weak signal never sends an alert.'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Combined risk score', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                Text('$sc/100'),
              ]),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: sc / 100,
                minHeight: 10,
                color: sc >= alertThreshold ? kSos : Colors.orange,
              ),
              const SizedBox(height: 6),
              const Text('Alert countdown starts at $alertThreshold.'),
            ]),
          ),
        ),
        Card(
          child: Column(children: [
            for (final s in signalDefs)
              SwitchListTile(
                title: Text(s.title),
                subtitle: Text('${s.desc}  (+${s.weight})'),
                value: app.sig[s.key]!,
                onChanged: (v) => app.setSignal(s.key, v),
              ),
          ]),
        ),
      ],
    );
  }
}
