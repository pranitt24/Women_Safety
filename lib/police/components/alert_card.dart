import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/alert_model.dart';
import '../../services/backend.dart';
import '../../theme/theme.dart';

class PoliceAlertCard extends StatelessWidget {
  const PoliceAlertCard({
    super.key,
    required this.alert,
    required this.isSelected,
    required this.onSelect,
  });

  final SosAlert alert;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final isRelayed = alert.isRelayed;
    final timeStr = DateFormat('hh:mm:ss a').format(alert.createdAt);

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected ? kAccent : _statusBorderColor(alert.status),
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Alert ID, Relayed badge, Status badge
            Row(
              children: [
                Text(
                  'Alert #${alert.id}',
                  style: GoogleFonts.jetBrainsMono(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                if (isRelayed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.deepPurple.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bluetooth, size: 12, color: Colors.deepPurple.shade700),
                        const SizedBox(width: 3),
                        Text(
                          'Relayed by Nearby Phone',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple.shade800,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Text(
                      'Direct Cellular',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusBgColor(alert.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    alert.status.toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _statusBorderColor(alert.status),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Citizen name & Reason
            Row(
              children: [
                const Icon(Icons.person_pin, size: 18, color: kAccent),
                const SizedBox(width: 6),
                Text(
                  alert.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(width: 12),
                Text('Zone ${alert.zoneId}', style: GoogleFonts.jetBrainsMono(fontSize: 12)),
                const Spacer(),
                Text(timeStr, style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),

            const SizedBox(height: 4),
            Text(
              'Reason: ${alert.reason}',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),

            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.battery_charging_full, size: 14, color: Colors.grey.shade700),
                const SizedBox(width: 4),
                Text('${alert.battery}%', style: GoogleFonts.jetBrainsMono(fontSize: 11)),
                const SizedBox(width: 12),
                Icon(Icons.gps_fixed, size: 14, color: Colors.grey.shade700),
                const SizedBox(width: 4),
                Text(
                  '${(alert.liveLat ?? alert.zoneLat).toStringAsFixed(4)}, ${(alert.liveLng ?? alert.zoneLng).toStringAsFixed(4)}',
                  style: GoogleFonts.jetBrainsMono(fontSize: 11),
                ),
              ],
            ),

            const Divider(height: 16),

            // Action Buttons for Police Crime Branch Dispatcher
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.my_location, size: 16),
                  label: const Text('Track Live Pin', style: TextStyle(fontSize: 12)),
                  onPressed: onSelect,
                ),
                const Spacer(),
                if (alert.status == 'new')
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onPressed: () => Backend.updateAlertStatus(alertId: alert.id, newStatus: 'ack'),
                    child: const Text('Acknowledge', style: TextStyle(fontSize: 12)),
                  ),
                if (alert.status == 'ack' || alert.status == 'new') ...[
                  const SizedBox(width: 6),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: kAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onPressed: () => Backend.updateAlertStatus(alertId: alert.id, newStatus: 'dispatched'),
                    child: const Text('Dispatch PCR Van', style: TextStyle(fontSize: 12)),
                  ),
                ],
                if (alert.status == 'dispatched') ...[
                  const SizedBox(width: 6),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: kSafeGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onPressed: () => Backend.updateAlertStatus(alertId: alert.id, newStatus: 'resolved'),
                    child: const Text('Resolve Incident', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusBgColor(String status) {
    switch (status) {
      case 'new':
        return Colors.red.shade50;
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
      case 'new':
        return kSos;
      case 'ack':
        return Colors.blue.shade800;
      case 'dispatched':
        return Colors.orange.shade800;
      case 'resolved':
        return kSafeGreen;
      default:
        return Colors.grey.shade700;
    }
  }
}
