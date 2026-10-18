import 'package:flutter/material.dart';

import '../state.dart';

class CircleScreen extends StatelessWidget {
  const CircleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Trusted circle', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Card(
          child: Column(children: [
            for (final c in app.contacts)
              ListTile(
                leading: CircleAvatar(child: Text(c.name[0])),
                title: Text(c.name),
                subtitle: Text('${c.relation} · gets SOS alerts'),
                trailing: const Chip(label: Text('Verified')),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: OutlinedButton(onPressed: () {}, child: const Text('Add a trusted contact')),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(children: [
            const ListTile(title: Text('What they receive in an emergency')),
            SwitchListTile(
              title: const Text('Live location'),
              subtitle: const Text('Updates every 10 seconds'),
              value: app.shareLocation,
              onChanged: (v) => app.update(() => app.shareLocation = v),
            ),
            SwitchListTile(
              title: const Text('Audio recording'),
              subtitle: const Text('Stored encrypted, shared with police only'),
              value: app.shareAudio,
              onChanged: (v) => app.update(() => app.shareAudio = v),
            ),
            SwitchListTile(
              title: const Text('Battery and network status'),
              value: app.shareBattery,
              onChanged: (v) => app.update(() => app.shareBattery = v),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        const Text('Contacts do not need the app. They get an SMS with a tracking link.'),
      ],
    );
  }
}
