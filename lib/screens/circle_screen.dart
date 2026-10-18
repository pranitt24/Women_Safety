import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/trusted_contact.dart';
import '../services/backend.dart';
import '../state.dart';
import '../theme/theme.dart';

class CircleScreen extends StatelessWidget {
  const CircleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Trusted Circle', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            const Text(
              'Your circle gets distress alerts with your live location. '
              'Contacts without the app receive an SMS/WhatsApp tracking link.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Contacts List Card
            Card(
              child: Column(
                children: [
                  for (final c in app.contacts)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: kAccent.withAlpha(35),
                        foregroundColor: kAccent,
                        child: Text(c.name[0], style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${c.relation} • ${c.phone}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Chip(
                            label: Text(c.hasApp ? 'In App' : 'SMS Link'),
                            labelStyle: GoogleFonts.jetBrainsMono(fontSize: 10),
                            backgroundColor: c.hasApp ? kSafeGreen.withAlpha(25) : Colors.grey.withAlpha(30),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send_to_mobile, size: 20, color: kAccent),
                            tooltip: 'Send Test Link',
                            onPressed: () {
                              const msg = 'Sakhi Safety test from Asha: Everything is fine. '
                                  'In an emergency, live tracking link appears here. https://sakhi.safety/demo';
                              Backend.openWhatsAppFallback(phone: c.phone, message: msg);
                            },
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.person_add_outlined),
                      label: const Text('Add a trusted contact'),
                      onPressed: () => _showAddContactDialog(context),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Emergency Payload Preferences
            Card(
              child: Column(
                children: [
                  const ListTile(
                    title: Text('Emergency Payload Sharing', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Data shared with trusted contacts during active SOS'),
                  ),
                  SwitchListTile(
                    title: const Text('Live location stream'),
                    subtitle: const Text('Sends GPS coordinates every 10 seconds to contacts and police'),
                    value: app.shareLocation,
                    onChanged: (v) => app.update(() => app.shareLocation = v),
                  ),
                  SwitchListTile(
                    title: const Text('Encrypted audio snippet'),
                    subtitle: const Text('Captures ambient audio, shared with Crime Branch upon request'),
                    value: app.shareAudio,
                    onChanged: (v) => app.update(() => app.shareAudio = v),
                  ),
                  SwitchListTile(
                    title: const Text('Battery & network telemetry'),
                    subtitle: const Text('Shares battery level and whether alert is direct or BLE relayed'),
                    value: app.shareBattery,
                    onChanged: (v) => app.update(() => app.shareBattery = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(60),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, color: kAccent, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'India DLT SMS fallback: If recipients do not have internet, '
                        'Sakhi queues pre-filled SMS for one-tap dispatch.',
                        style: TextStyle(fontSize: 12),
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

  void _showAddContactDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String relation = 'Family';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Trusted Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone (+91 ...)'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: relation,
                decoration: const InputDecoration(labelText: 'Relation'),
                items: const [
                  DropdownMenuItem(value: 'Family', child: Text('Family')),
                  DropdownMenuItem(value: 'Friend', child: Text('Friend')),
                  DropdownMenuItem(value: 'Colleague', child: Text('Colleague')),
                  DropdownMenuItem(value: 'Neighbor', child: Text('Neighbor')),
                ],
                onChanged: (v) {
                  if (v != null) relation = v;
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kAccent),
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty && phoneCtrl.text.trim().isNotEmpty) {
                  app.update(() {
                    app.contacts.add(
                      TrustedContact(
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        relation: relation,
                        hasApp: false,
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
