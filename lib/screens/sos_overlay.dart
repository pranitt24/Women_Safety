import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/backend.dart';
import '../state.dart';
import '../theme/theme.dart';

class SosOverlay extends StatelessWidget {
  const SosOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        return app.phase == SosPhase.countdown ? const _Countdown() : const _Sending();
      },
    );
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                'Are you OK?',
                style: GoogleFonts.bricolageGrotesque(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  app.reason.isNotEmpty ? app.reason : 'Distress triggered',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
              const Spacer(),
              // Big countdown number
              Text(
                '${app.countdown}',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 130,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Alert will be dispatched to ${app.contacts.map((c) => c.name).join(', ')}'
                '${app.online ? ' and Mumbai Police Control' : ' over Bluetooth offline mesh'}.',
                textAlign: TextAlign.center,
                style: w.copyWith(fontSize: 14),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: kSos,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: app.cancel,
                  child: Text(
                    "I'm safe, cancel countdown",
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: app.sendNow,
                  child: const Text('Send Immediately', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
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
            'Location locked, accurate to 5 m',
            'Alert written to Crime Branch Control (pilot)',
            'Distress dispatched to Mom, Anita, Rohan',
            'Live GPS location streaming every 10s',
          ]
        : const [
            'Network unavailable. Broadcasting over Bluetooth mesh',
            'Nearby Sakhi phone detected beacon packet',
            'Relay node with internet uploading to Crime Branch',
            'Distress delivered to trusted contacts via relay',
            'SMS queued to send immediately once signal returns',
          ];

    final done = app.phase == SosPhase.done;
    final status = app.activeAlertStatus ?? 'new';

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (done ? kSafeGreen : kSos).withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      done ? 'ALERT TRANSMITTED' : 'SENDING DISTRESS...',
                      style: GoogleFonts.jetBrainsMono(
                        color: done ? kSafeGreen : kSos,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Battery level chip
                  Text(
                    'Battery: ${app.batteryLevel}%',
                    style: GoogleFonts.jetBrainsMono(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                online ? 'Alert on its way' : 'Offline Bluetooth Relay',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),

              // Step Progress Checkmarks
              for (var i = 0; i < lines.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Opacity(
                    opacity: app.steps > i ? 1.0 : 0.35,
                    child: Row(
                      children: [
                        Icon(
                          app.steps > i ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: app.steps > i ? kSafeGreen : null,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            lines[i],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: app.steps > i ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Live Status Sync from Police Crime Branch
              if (done) ...[
                const SizedBox(height: 12),
                Card(
                  color: _statusBgColor(status),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: _statusBorderColor(status)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(_statusIcon(status), color: _statusBorderColor(status)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _statusTitle(status),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _statusBorderColor(status),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _statusDesc(status),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Alert details card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Alert #${app.alertId ?? "849201"}',
                              style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Text(
                              'Zone ${app.selZone}',
                              style: GoogleFonts.jetBrainsMono(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Asha may need urgent help. Trigger: ${app.reason}. '
                          'Live GPS updates transmitting to Crime Branch.',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        // Quick SMS / WhatsApp Fallback trigger
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.share, size: 16, color: kAccent),
                          label: const Text('Open WhatsApp / SMS Fallback Link',
                              style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            final msg = 'EMERGENCY: Asha triggered Sakhi SOS at Zone ${app.selZone}. '
                                'Location: https://maps.google.com/?q=${app.userLocation.latitude},${app.userLocation.longitude}. '
                                'Call 112.';
                            Backend.openWhatsAppFallback(phone: '+919820011223', message: msg);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const Spacer(),

              // Action buttons
              if (done) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: kSos,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.phone),
                    label: const Text('Call 112 Emergency Police Now',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    onPressed: () => launchUrl(Uri.parse('tel:112')),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: app.cancel,
                    child: const Text("I'm safe, cancel alert"),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _statusBgColor(String status) {
    switch (status) {
      case 'ack':
        return Colors.blue.shade50;
      case 'dispatched':
        return Colors.orange.shade50;
      case 'resolved':
        return Colors.green.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _statusBorderColor(String status) {
    switch (status) {
      case 'ack':
        return Colors.blue.shade800;
      case 'dispatched':
        return Colors.orange.shade800;
      case 'resolved':
        return Colors.green.shade800;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'ack':
        return Icons.mark_email_read;
      case 'dispatched':
        return Icons.local_police;
      case 'resolved':
        return Icons.check_circle_outline;
      default:
        return Icons.radio_button_checked;
    }
  }

  String _statusTitle(String status) {
    switch (status) {
      case 'ack':
        return 'Police Acknowledged';
      case 'dispatched':
        return 'Patrol Unit Dispatched';
      case 'resolved':
        return 'Alert Resolved';
      default:
        return 'Alert Queued in Control Room';
    }
  }

  String _statusDesc(String status) {
    switch (status) {
      case 'ack':
        return 'Crime branch operator has reviewed your alert and assigned response.';
      case 'dispatched':
        return 'Emergency PCR Van #14 has been dispatched to your current zone.';
      case 'resolved':
        return 'Crime branch control has marked this emergency as safely resolved.';
      default:
        return 'Operator is reviewing incoming location and telemetry.';
    }
  }
}
