import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../data/hotspot_engine.dart';
import '../models/alert_model.dart';
import '../models/incident.dart';
import '../services/backend.dart';
import '../theme/theme.dart';
import 'components/alert_card.dart';
import 'components/csv_import_dialog.dart';
import 'components/hotspot_table.dart';
import 'components/hourly_chart.dart';
import 'components/kpi_tiles.dart';

class PoliceConsoleScreen extends StatefulWidget {
  const PoliceConsoleScreen({super.key});

  @override
  State<PoliceConsoleScreen> createState() => _PoliceConsoleScreenState();
}

class _PoliceConsoleScreenState extends State<PoliceConsoleScreen> {
  final MapController _mapController = MapController();
  SosAlert? _selectedAlert;
  int _activeTab = 0; // 0 = Live Dispatch, 1 = Zones & Hotspots, 2 = Analytics

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SosAlert>>(
      stream: Backend.watchActiveAlerts(),
      initialData: Backend.cachedAlerts,
      builder: (context, alertsSnap) {
        final alerts = alertsSnap.data ?? [];

        return StreamBuilder<List<Incident>>(
          stream: Backend.watchIncidents(),
          initialData: Backend.cachedIncidents,
          builder: (context, incidentsSnap) {
            final incidents = incidentsSnap.data ?? [];

            return StreamBuilder<Set<String>>(
              stream: Backend.watchPublishedZones(),
              initialData: Backend.cachedPublishedZones,
              builder: (context, publishedSnap) {
                final published = publishedSnap.data ?? {};
                final zones = HotspotEngine.buildZones(
                  incidents: incidents,
                  hour: 22.0,
                  publishedIds: published,
                );
                final highRiskCount = zones.where((z) => z.baseRisk >= 0.60).length;

                // Pick currently focused coordinate (selected alert live position or kCityCenter)
                final focusPoint = _selectedAlert != null
                    ? LatLng(
                        _selectedAlert!.liveLat ?? _selectedAlert!.zoneLat,
                        _selectedAlert!.liveLng ?? _selectedAlert!.zoneLng,
                      )
                    : kCityCenter;

                return Scaffold(
                  backgroundColor: const Color(0xFFF4F6F5),
                  appBar: AppBar(
                    backgroundColor: const Color(0xFF111918),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: kAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.shield, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MAHARASHTRA POLICE • CRIME BRANCH',
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Sakhi Safety Emergency Response Console • Mumbai Command Center (asia-south1)',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    actions: [
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: kAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        icon: const Icon(Icons.upload_file, size: 16),
                        label: const Text('Import Incidents (CSV)', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => const CsvImportDialog(),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      // Hard rules badge
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade900.withAlpha(50),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.shade400, width: 0.8),
                        ),
                        child: Center(
                          child: Text(
                            'Demo Data • Aggregates Only',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade300,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  body: Column(
                    children: [
                      // Sub-header navigation tabs
                      Container(
                        color: const Color(0xFF1E2826),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            _navTab(0, 'Live Dispatch Feed (${alerts.where((a) => a.isActive).length})', Icons.notifications_active),
                            _navTab(1, 'Hotspot Zones & Public Policy', Icons.grid_on),
                            _navTab(2, 'Temporal Incident Analytics', Icons.analytics),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(40),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Real-time Firestore Sync Active',
                                    style: GoogleFonts.jetBrainsMono(fontSize: 11, color: Colors.greenAccent),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Main Console Content
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // KPI Tiles
                            PoliceKpiTiles(
                              alerts: alerts,
                              totalIncidents: incidents.length,
                              highRiskCount: highRiskCount,
                            ),
                            const SizedBox(height: 16),

                            if (_activeTab == 0) ...[
                              // Tab 0: Split screen Live Dispatch Feed + Real-time Interactive Map
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth > 900;
                                  return Flex(
                                    direction: isWide ? Axis.horizontal : Axis.vertical,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Alerts Stream Column
                                      SizedBox(
                                        width: isWide ? 440 : double.infinity,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.flash_on, color: kSos, size: 20),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Incoming Distress Alerts',
                                                  style: GoogleFonts.bricolageGrotesque(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            if (alerts.isEmpty)
                                              Card(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(32),
                                                  child: Center(
                                                    child: Column(
                                                      children: [
                                                        const Icon(Icons.verified, color: kSafeGreen, size: 36),
                                                        const SizedBox(height: 8),
                                                        Text('No active distress calls at this moment.',
                                                            style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.bold)),
                                                        const SizedBox(height: 4),
                                                        const Text('Citizen alerts will appear here in < 3s.',
                                                            style: TextStyle(fontSize: 12, color: Colors.black54)),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              )
                                            else
                                              for (final a in alerts)
                                                Padding(
                                                  padding: const EdgeInsets.only(bottom: 10),
                                                  child: PoliceAlertCard(
                                                    alert: a,
                                                    isSelected: _selectedAlert?.id == a.id,
                                                    onSelect: () {
                                                      setState(() => _selectedAlert = a);
                                                      final lat = a.liveLat ?? a.zoneLat;
                                                      final lng = a.liveLng ?? a.zoneLng;
                                                      _mapController.move(LatLng(lat, lng), 16.0);
                                                    },
                                                  ),
                                                ),
                                          ],
                                        ),
                                      ),

                                      if (isWide) const SizedBox(width: 16) else const SizedBox(height: 16),

                                      // Real-time Map Column
                                      Expanded(
                                        flex: isWide ? 1 : 0,
                                        child: Card(
                                          clipBehavior: Clip.antiAlias,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            side: const BorderSide(color: Color(0x1F000000)),
                                          ),
                                          child: SizedBox(
                                            height: 520,
                                            child: Stack(
                                              children: [
                                                FlutterMap(
                                                  mapController: _mapController,
                                                  options: MapOptions(
                                                    initialCenter: focusPoint,
                                                    initialZoom: 15.0,
                                                    minZoom: 12.0,
                                                    maxZoom: 18.0,
                                                  ),
                                                  children: [
                                                    TileLayer(
                                                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                                      userAgentPackageName: 'in.sakhi.sakhi_safety',
                                                    ),
                                                    // Zone Risk Polygons
                                                    PolygonLayer(
                                                      polygons: zones.map((z) {
                                                        final isPub = published.contains(z.id);
                                                        return Polygon(
                                                          points: z.polygon,
                                                          color: isPub
                                                              ? kSos.withAlpha((z.baseRisk * 0.7 * 255).round().clamp(20, 200))
                                                              : Colors.grey.withAlpha(60),
                                                          borderColor: isPub ? kSos.withAlpha(80) : Colors.grey,
                                                          borderStrokeWidth: 1.0,
                                                        );
                                                      }).toList(),
                                                    ),
                                                    // Markers: Police booths + Active alert live pin
                                                    MarkerLayer(
                                                      markers: [
                                                        // Police Booths
                                                        ...HotspotEngine.getPoliceBooths().map((pb) {
                                                          return Marker(
                                                            point: pb['position'] as LatLng,
                                                            width: 32,
                                                            height: 32,
                                                            child: Container(
                                                              decoration: BoxDecoration(
                                                                color: const Color(0xFF111918),
                                                                shape: BoxShape.circle,
                                                                border: Border.all(color: Colors.white, width: 2),
                                                              ),
                                                              child: const Center(
                                                                child: Text('P',
                                                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                                              ),
                                                            ),
                                                          );
                                                        }),

                                                        // Selected Alert Live Moving Pin
                                                        if (_selectedAlert != null)
                                                          Marker(
                                                            point: LatLng(
                                                              _selectedAlert!.liveLat ?? _selectedAlert!.zoneLat,
                                                              _selectedAlert!.liveLng ?? _selectedAlert!.zoneLng,
                                                            ),
                                                            width: 54,
                                                            height: 54,
                                                            child: Stack(
                                                              alignment: Alignment.center,
                                                              children: [
                                                                Container(
                                                                  width: 52,
                                                                  height: 52,
                                                                  decoration: BoxDecoration(
                                                                    shape: BoxShape.circle,
                                                                    color: kSos.withAlpha(70),
                                                                  ),
                                                                ),
                                                                Container(
                                                                  width: 22,
                                                                  height: 22,
                                                                  decoration: BoxDecoration(
                                                                    shape: BoxShape.circle,
                                                                    color: kSos,
                                                                    border: Border.all(color: Colors.white, width: 3),
                                                                  ),
                                                                  child: const Icon(Icons.person, size: 12, color: Colors.white),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ],
                                                ),

                                                // Overlay Map badge
                                                Positioned(
                                                  top: 12,
                                                  left: 12,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black87,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      _selectedAlert != null
                                                          ? 'Tracking Live Pin: Alert #${_selectedAlert!.id} (${_selectedAlert!.name})'
                                                          : 'Mumbai Crime Branch Tactical Map Overview',
                                                      style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 12),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ] else if (_activeTab == 1) ...[
                              // Tab 1: Hotspot Zones Table & Police Public Policy
                              PoliceHotspotTable(
                                zones: zones,
                                publishedSet: published,
                                onSelectZone: (z) {
                                  setState(() => _activeTab = 0);
                                  _mapController.move(z.center, 16.0);
                                },
                              ),
                            ] else if (_activeTab == 2) ...[
                              // Tab 2: Hourly Chart & Temporal Analytics
                              PoliceHourlyChart(incidents: incidents),
                              const SizedBox(height: 16),
                              PoliceHotspotTable(
                                zones: zones,
                                publishedSet: published,
                                onSelectZone: (z) {
                                  setState(() => _activeTab = 0);
                                  _mapController.move(z.center, 16.0);
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _navTab(int index, String title, IconData icon) {
    final isSel = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSel ? kAccent : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSel ? Colors.white : Colors.white60),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSel ? Colors.white : Colors.white60,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
