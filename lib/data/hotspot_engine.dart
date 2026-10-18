import 'dart:math';
import 'package:latlong2/latlong.dart';

import '../models/incident.dart';
import '../models/zone_model.dart';

/// Central anchor for demo safety map (Default: Mumbai, can be configured)
const LatLng kCityCenter = LatLng(19.0760, 72.8777);

class HotspotEngine {
  static const int cols = 8;
  static const int rows = 7;
  static const String letters = 'ABCDEFGH';
  static const String userZoneId = 'D3';

  // ~160m cells in latitude and longitude
  static const double cellLatSpan = 0.00145; // ~161 meters
  static const double cellLngSpan = 0.00155; // ~162 meters

  static const List<String> boothZoneIds = ['C2', 'F2', 'B6', 'G7'];

  /// Converts hour (18..26) to human readable label
  static String formatHour(int hour) {
    final normalized = hour % 24;
    final suffix = (hour >= 12 && hour < 24) ? 'PM' : 'AM';
    final display = normalized == 0 ? 12 : (normalized > 12 ? normalized - 12 : normalized);
    return '$display $suffix';
  }

  /// Calculates top-left anchor so that zone D3 (c=3, r=2) aligns with kCityCenter
  static LatLng get gridOrigin {
    final originLat = kCityCenter.latitude + (2.5 * cellLatSpan);
    final originLng = kCityCenter.longitude - (3.5 * cellLngSpan);
    return LatLng(originLat, originLng);
  }

  /// Returns 4 polygon corner points for cell (col, row)
  static List<LatLng> polygonForCell(int col, int row) {
    final origin = gridOrigin;
    final north = origin.latitude - (row * cellLatSpan);
    final south = north - cellLatSpan;
    final west = origin.longitude + (col * cellLngSpan);
    final east = west + cellLngSpan;

    return [
      LatLng(north, west),
      LatLng(north, east),
      LatLng(south, east),
      LatLng(south, west),
    ];
  }

  /// Returns geographic center of a cell
  static LatLng centerForCell(int col, int row) {
    final origin = gridOrigin;
    final lat = origin.latitude - (row * cellLatSpan) - (cellLatSpan / 2.0);
    final lng = origin.longitude + (col * cellLngSpan) + (cellLngSpan / 2.0);
    return LatLng(lat, lng);
  }

  /// Seed ~200 synthetic incidents clustered around 4 hotspots near kCityCenter
  static List<Incident> seedSyntheticIncidents() {
    final rnd = Random(42);
    final incidents = <Incident>[];

    // 4 Hotspot anchor cells (col, row, weight, peakHour)
    const hotspots = [
      {'c': 3, 'r': 2, 'count': 65, 'peak': 22}, // D3 - Near central transit
      {'c': 6, 'r': 4, 'count': 55, 'peak': 23}, // G5 - Commercial / dim corridor
      {'c': 1, 'r': 5, 'count': 45, 'peak': 21}, // B6 - Isolated sub-road
      {'c': 4, 'r': 5, 'count': 35, 'peak': 24}, // E6 - Construction edge
    ];

    final categories = ['harassment', 'stalking', 'poor_lighting', 'unsafe_area'];
    final categoryWeights = [0.35, 0.20, 0.25, 0.20];

    int idCounter = 1;
    final now = DateTime.now();

    for (final h in hotspots) {
      final hc = h['c'] as int;
      final hr = h['r'] as int;
      final count = h['count'] as int;
      final peak = h['peak'] as int;
      final center = centerForCell(hc, hr);

      for (var i = 0; i < count; i++) {
        // Gaussian offset around hotspot center (within ~250m)
        final u1 = max(0.0001, rnd.nextDouble());
        final u2 = rnd.nextDouble();
        final radius = sqrt(-2.0 * log(u1)) * 0.0009; // std dev ~100m
        final angle = 2.0 * pi * u2;

        final lat = center.latitude + radius * cos(angle);
        final lng = center.longitude + radius * sin(angle);

        // Pick category by weight
        final catRoll = rnd.nextDouble();
        String cat = categories[0];
        double cumulative = 0.0;
        for (var c = 0; c < categories.length; c++) {
          cumulative += categoryWeights[c];
          if (catRoll <= cumulative) {
            cat = categories[c];
            break;
          }
        }

        // Hour bucket clustered around peak
        final hourOffset = ((rnd.nextDouble() - 0.5) * 4).round();
        final hour = (peak + hourOffset) % 24;

        // Days ago (0..90)
        final daysAgo = rnd.nextInt(90);
        final createdAt = now.subtract(Duration(days: daysAgo, hours: rnd.nextInt(24)));

        incidents.add(Incident(
          id: 'synth_${idCounter.toString().padLeft(3, '0')}',
          lat: lat,
          lng: lng,
          category: cat,
          hourBucket: hour,
          createdAt: createdAt,
          source: 'synthetic',
        ));
        idCounter++;
      }
    }

    return incidents;
  }

  /// Computes dynamic risk for all cells using incident points and current hour (18..26)
  /// Formula: risk(cell, hour) = sum over incidents within 300 m of weight * time_decay(hour)
  static List<GeoZone> buildZones({
    required List<Incident> incidents,
    required double hour,
    required Set<String> publishedIds,
  }) {
    const distanceCalc = Distance();
    final zones = <GeoZone>[];
    final rnd = Random(11);

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final id = '${letters[c]}${r + 1}';
        final center = centerForCell(c, r);
        final polygon = polygonForCell(c, r);

        // Sum over incidents within 300m
        double totalWeightedRisk = 0.0;
        int incidentsNear = 0;

        for (final inc in incidents) {
          final incPos = LatLng(inc.lat, inc.lng);
          final meters = distanceCalc.as(LengthUnit.Meter, center, incPos);

          if (meters <= 300.0) {
            incidentsNear++;

            // Map incident hour (0..23) to night slider coordinate (18..26)
            final incHourEffective = inc.hourBucket < 6 ? inc.hourBucket + 24.0 : inc.hourBucket.toDouble();
            final hourDiff = (hour - incHourEffective).abs();
            // Gaussian time decay with 2.8 hr scale
            final timeDecay = exp(-pow(hourDiff / 2.8, 2));
            final distanceWeight = max(0.1, 1.0 - (meters / 350.0));

            totalWeightedRisk += inc.weight * distanceWeight * timeDecay;
          }
        }

        // Normalize base risk between 0.08 and 1.0
        final normalizedRisk = min(1.0, max(0.08, totalWeightedRisk / 8.5));

        // Street lights working (inversely correlated with risk + slight noise)
        final litRatio = (1.0 - normalizedRisk * 0.7 + (rnd.nextDouble() - 0.5) * 0.15).clamp(0.2, 1.0);
        final cctvCount = (rnd.nextDouble() * 2 + 1).round();
        final cctvWorking = (cctvCount * (1.0 - normalizedRisk * 0.5)).round().clamp(0, cctvCount);

        zones.add(GeoZone(
          id: id,
          c: c,
          r: r,
          center: center,
          polygon: polygon,
          baseRisk: normalizedRisk,
          peakHour: 21.0 + (rnd.nextDouble() * 3.0),
          incidentsCount: max(incidentsNear, (normalizedRisk * 45).round()),
          litRatio: litRatio,
          cctv: cctvCount,
          cctvOk: cctvWorking,
          isPublished: publishedIds.contains(id),
        ));
      }
    }

    return zones;
  }

  /// Precomputed synthetic Police Booths with geographic coordinates
  static List<Map<String, dynamic>> getPoliceBooths() {
    return [
      {
        'id': 'PB-01',
        'zone': 'C2',
        'name': 'Dharavi Police Chowki',
        'position': centerForCell(2, 1),
      },
      {
        'id': 'PB-02',
        'zone': 'F2',
        'name': 'Bandra Kurla Beat Booth',
        'position': centerForCell(5, 1),
      },
      {
        'id': 'PB-03',
        'zone': 'B6',
        'name': 'Western Express Beat House',
        'position': centerForCell(1, 5),
      },
      {
        'id': 'PB-04',
        'zone': 'G7',
        'name': 'Mahim Bay Police Post',
        'position': centerForCell(6, 6),
      },
    ];
  }

  /// Precomputed synthetic CCTV cameras
  static List<LatLng> getCctvCameras() {
    final list = <LatLng>[];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final center = centerForCell(c, r);
        // Put a camera slightly offset towards cell edge
        list.add(LatLng(center.latitude + 0.0004, center.longitude + 0.0004));
      }
    }
    return list;
  }

  /// Precomputed synthetic street lights along main grid axes
  static List<LatLng> getStreetLights() {
    final list = <LatLng>[];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final center = centerForCell(c, r);
        list.add(LatLng(center.latitude - 0.0003, center.longitude));
        list.add(LatLng(center.latitude, center.longitude - 0.0003));
      }
    }
    return list;
  }
}
