import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../data/hotspot_engine.dart';
import '../models/zone_model.dart';
import '../state.dart';
import '../theme/theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final currentZone = app.currentZone;

    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        return Stack(
          children: [
            // 1. The Real OSM Interactive Map
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: app.userLocation,
                initialZoom: 15.0,
                minZoom: 13.0,
                maxZoom: 18.0,
                onLongPress: (tapPosition, point) {
                  _showReportIncidentDialog(context, initialPoint: point);
                },
              ),
              children: [
                // OpenStreetMap Tile Layer
                // NOTE: OpenStreetMap standard tiles are used for this demo.
                // For high-volume production, swap this URL to a paid provider (e.g. Mapbox, Stadia, Google Maps).
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'in.sakhi.sakhi_safety',
                ),

                // Hotspot Polygons Layer (150m cells coloured by dynamic risk)
                PolygonLayer(
                  polygons: app.zones.map((zone) {
                    final isSel = zone.id == app.selZone;
                    final isPub = app.published.contains(zone.id);
                    final heat = zone.heatAt(app.hour.toDouble());

                    // Published zones get red alpha gradient; unpublished are greyed out
                    final fillColor = isPub
                        ? kSos.withAlpha((heat * 0.85 * 255).round().clamp(25, 230))
                        : Colors.grey.withAlpha(80);

                    final strokeColor = isSel
                        ? Colors.black
                        : (isPub ? kSos.withAlpha(120) : Colors.grey);

                    return Polygon(
                      points: zone.polygon,
                      color: fillColor,
                      borderColor: strokeColor,
                      borderStrokeWidth: isSel ? 3.0 : 1.0,
                    );
                  }).toList(),
                ),

                // Dynamic Markers Layer (Police Booths, CCTV, Street lights, Live blue dot)
                MarkerLayer(
                  markers: [
                    // Police Booth Markers
                    if (app.showBooths)
                      ...HotspotEngine.getPoliceBooths().map((pb) {
                        return Marker(
                          point: pb['position'] as LatLng,
                          width: 32,
                          height: 32,
                          child: GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${pb['name']} (${pb['zone']})')),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                                ],
                              ),
                              child: const Center(
                                child: Text('P',
                                    style: TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ),
                          ),
                        );
                      }),

                    // CCTV Markers
                    if (app.showCctv)
                      ...HotspotEngine.getCctvCameras().take(30).map((cam) {
                        return Marker(
                          point: cam,
                          width: 20,
                          height: 20,
                          child: const Icon(Icons.videocam, size: 18, color: kAccent),
                        );
                      }),

                    // Street Lights Markers
                    if (app.showLights)
                      ...HotspotEngine.getStreetLights().take(40).map((light) {
                        return Marker(
                          point: light,
                          width: 18,
                          height: 18,
                          child: const Icon(Icons.lightbulb, size: 16, color: Colors.amber),
                        );
                      }),

                    // User Live Location Blue Dot with pulsing accuracy ring
                    Marker(
                      point: app.userLocation,
                      width: 48,
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kAccent.withAlpha(60),
                            ),
                          ),
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kAccent,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // 2. Top Header Controls (Title, "Demo data" Badge, Layer Chips)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Column(
                children: [
                  // App Bar / Top Card
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Text('Safety Heat Map',
                                        style: Theme.of(context).textTheme.titleMedium),
                                    const SizedBox(width: 8),
                                    // Hard rule: Label map "Demo data" in the UI
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.amber.shade700, width: 0.8),
                                      ),
                                      child: Text(
                                        'Demo data',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Aggregated zones (no personal data) • Mumbai',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'Report an incident',
                            icon: const Icon(Icons.add_alert_outlined, color: kSos),
                            onPressed: () => _showReportIncidentDialog(context),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Filter Chips for Layers
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          avatar: const Icon(Icons.local_police_outlined, size: 16),
                          label: const Text('Booths'),
                          selected: app.showBooths,
                          onSelected: (v) => app.update(() => app.showBooths = v),
                        ),
                        const SizedBox(width: 6),
                        FilterChip(
                          avatar: const Icon(Icons.videocam_outlined, size: 16),
                          label: const Text('CCTV'),
                          selected: app.showCctv,
                          onSelected: (v) => app.update(() => app.showCctv = v),
                        ),
                        const SizedBox(width: 6),
                        FilterChip(
                          avatar: const Icon(Icons.lightbulb_outline, size: 16),
                          label: const Text('Lights'),
                          selected: app.showLights,
                          onSelected: (v) => app.update(() => app.showLights = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. Floating "Locate Me" Button
            Positioned(
              right: 16,
              bottom: 270,
              child: FloatingActionButton.small(
                heroTag: 'locate_me_fab',
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: kAccent,
                onPressed: () async {
                  await app.locateUser();
                  _mapController.move(app.userLocation, 15.5);
                },
                child: const Icon(Icons.my_location),
              ),
            ),

            // 4. Bottom Controls: Time-of-night Slider & Zone Metric Card
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Time Slider Card
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.nightlight_round, size: 16, color: kAccent),
                              const SizedBox(width: 6),
                              Text('Time of night', style: Theme.of(context).textTheme.titleSmall),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  HotspotEngine.formatHour(app.hour),
                                  style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            min: 18,
                            max: 26,
                            divisions: 8,
                            value: app.hour.toDouble(),
                            activeColor: kAccent,
                            onChanged: (v) => app.setHour(v.round()),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Selected Zone Bottom Sheet Card
                  _ZoneDetailCard(
                    zone: currentZone,
                    onTapChangeZone: () => _showZonePickerModal(context),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showZonePickerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          builder: (_, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.all(16),
              children: [
                Text('Select Zone to Inspect', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text('Choose any ~150m grid cell in Mumbai to examine safety indicators.'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: app.zones.map((z) {
                    final isSel = z.id == app.selZone;
                    final isPub = app.published.contains(z.id);
                    return ActionChip(
                      backgroundColor: isSel
                          ? kAccent.withAlpha(50)
                          : (isPub ? null : Colors.grey.shade200),
                      label: Text(
                        '${z.id}${!isPub ? ' (Unreviewed)' : ''}',
                        style: TextStyle(
                          color: isPub ? null : Colors.grey.shade600,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onPressed: () {
                        app.update(() => app.selZone = z.id);
                        _mapController.move(z.center, 15.5);
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showReportIncidentDialog(BuildContext context, {LatLng? initialPoint}) {
    final targetPos = initialPoint ?? app.userLocation;
    String selectedCategory = 'unsafe_area';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.report_problem_outlined, color: kSos),
                      const SizedBox(width: 8),
                      Text('Report Unsafe Spot', style: Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Anonymous demo report. No offender data or names collected. '
                    'Locations are rounded to aggregate cells.',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  Text('Category', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'harassment', child: Text('Harassment / Catcalling')),
                      DropdownMenuItem(value: 'stalking', child: Text('Stalking / Following')),
                      DropdownMenuItem(value: 'poor_lighting', child: Text('Dark / Poor Street Lighting')),
                      DropdownMenuItem(value: 'unsafe_area', child: Text('Isolated / Unsafe Area')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: kAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.send),
                      label: const Text('Submit Anonymous Report'),
                      onPressed: () async {
                        await app.submitAnonymousReport(
                          lat: targetPos.latitude,
                          lng: targetPos.longitude,
                          category: selectedCategory,
                        );
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Report submitted anonymously. Heat map updated!'),
                              backgroundColor: kAccent,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ZoneDetailCard extends StatelessWidget {
  const _ZoneDetailCard({required this.zone, required this.onTapChangeZone});

  final GeoZone zone;
  final VoidCallback onTapChangeZone;

  @override
  Widget build(BuildContext context) {
    final isPublished = app.published.contains(zone.id);

    if (!isPublished) {
      return Card(
        elevation: 3,
        child: ListTile(
          leading: const Icon(Icons.lock_clock_outlined, color: Colors.orange),
          title: Text('Zone ${zone.id} · Pending Police Review'),
          subtitle: const Text(
            'The local crime branch has not published safety indicators for this zone yet.',
            style: TextStyle(fontSize: 12),
          ),
          trailing: TextButton(onPressed: onTapChangeZone, child: const Text('Change')),
        ),
      );
    }

    final heat = zone.heatAt(app.hour.toDouble());
    final level = heat >= 0.62 ? 'High' : (heat >= 0.32 ? 'Moderate' : 'Low');
    final levelColor = heat >= 0.62 ? kSos : (heat >= 0.32 ? kWarningOrange : kSafeGreen);

    final advice = heat >= 0.62
        ? 'Prefer main roads, share your journey and avoid walking alone at this hour.'
        : (heat >= 0.32
            ? 'Stay on lit streets and keep your trusted circle updated.'
            : 'Normal precautions apply in this zone.');

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zone ${zone.id}${zone.id == HotspotEngine.userZoneId ? ' · You are here' : ''}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '~150m grid cell • Mumbai',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: levelColor.withAlpha(35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: levelColor, width: 1.2),
                  ),
                  child: Text(
                    '$level Risk',
                    style: TextStyle(
                      color: levelColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onTapChangeZone,
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.grid_view, size: 20, color: kAccent),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _metric(context, 'Reports (90d)', '${zone.incidentsCount}'),
                _metric(context, 'Peak Hour', HotspotEngine.formatHour(zone.peakHour.round())),
                _metric(context, 'Street Lights', '${(zone.litRatio * 10).round()}/10'),
                _metric(context, 'CCTV Working', '${zone.cctvOk}/${zone.cctv}'),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: kAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      advice,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.jetBrainsMono(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            )),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }
}
