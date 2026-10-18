import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/hotspot_engine.dart';
import '../../models/incident.dart';
import '../../theme/theme.dart';

class PoliceHourlyChart extends StatelessWidget {
  const PoliceHourlyChart({super.key, required this.incidents});

  final List<Incident> incidents;

  @override
  Widget build(BuildContext context) {
    // Bucket incidents into hours 18 to 26 (18=6PM..24=Midnight, 25=1AM, 26=2AM)
    final counts = <int, int>{};
    for (var h = 18; h <= 26; h++) {
      counts[h] = 0;
    }

    for (final inc in incidents) {
      final effective = inc.hourBucket < 6 ? inc.hourBucket + 24 : inc.hourBucket;
      if (counts.containsKey(effective)) {
        counts[effective] = counts[effective]! + 1;
      }
    }

    int maxCount = 1;
    for (final c in counts.values) {
      maxCount = max(maxCount, c);
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: kAccent),
                const SizedBox(width: 8),
                Text(
                  'Distress & Incident Frequency by Hour (Night Patrol Focus)',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Crime branch temporal analysis (18:00 to 02:00) indicates peak distress occurs between 21:00 and 23:30.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Histogram Bars
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var h = 18; h <= 26; h++) ...[
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${counts[h] ?? 0}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: (counts[h] ?? 0) >= (maxCount * 0.7) ? kSos : kAccent,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: max(6.0, ((counts[h] ?? 0) / maxCount) * 105),
                            decoration: BoxDecoration(
                              color: (counts[h] ?? 0) >= (maxCount * 0.7)
                                  ? kSos
                                  : kAccent.withAlpha(160),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            HotspotEngine.formatHour(h),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    if (h < 26) const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
