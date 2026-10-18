import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/hotspot_engine.dart';
import '../../models/zone_model.dart';
import '../../services/backend.dart';
import '../../theme/theme.dart';

class PoliceHotspotTable extends StatelessWidget {
  const PoliceHotspotTable({
    super.key,
    required this.zones,
    required this.publishedSet,
    required this.onSelectZone,
  });

  final List<GeoZone> zones;
  final Set<String> publishedSet;
  final void Function(GeoZone) onSelectZone;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.table_chart_outlined, color: kAccent),
                const SizedBox(width: 8),
                Text(
                  'Zone Aggregates & Public Publication Control',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${zones.length} Zones Monitored',
                  style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Crime branch controls which zones are published to the citizen heat map. '
              'Toggling "Publish" immediately reflects on citizen devices in real-time.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 44,
                dataRowMaxHeight: 52,
                columns: const [
                  DataColumn(label: Text('Zone ID')),
                  DataColumn(label: Text('Risk Score')),
                  DataColumn(label: Text('Peak Hour')),
                  DataColumn(label: Text('Incidents (90d)')),
                  DataColumn(label: Text('Lighting')),
                  DataColumn(label: Text('CCTV')),
                  DataColumn(label: Text('Publish to Public')),
                  DataColumn(label: Text('Inspect')),
                ],
                rows: zones.map((zone) {
                  final isPub = publishedSet.contains(zone.id);
                  final heat = zone.baseRisk;
                  final riskColor = heat >= 0.62 ? kSos : (heat >= 0.32 ? kWarningOrange : kSafeGreen);

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          zone.id,
                          style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: riskColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              heat.toStringAsFixed(2),
                              style: GoogleFonts.jetBrainsMono(
                                fontWeight: FontWeight.bold,
                                color: riskColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(Text(HotspotEngine.formatHour(zone.peakHour.round()))),
                      DataCell(Text('${zone.incidentsCount}')),
                      DataCell(Text('${(zone.litRatio * 10).round()}/10 working')),
                      DataCell(Text('${zone.cctvOk}/${zone.cctv} operational')),
                      DataCell(
                        Switch(
                          value: isPub,
                          activeThumbColor: kAccent,
                          onChanged: (val) {
                            Backend.setZonePublished(cellId: zone.id, published: val);
                          },
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.map, size: 18, color: kAccent),
                          tooltip: 'Focus on Map',
                          onPressed: () => onSelectZone(zone),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
