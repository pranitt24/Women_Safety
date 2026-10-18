import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sakhi_safety/data/hotspot_engine.dart';
import 'package:sakhi_safety/models/alert_model.dart';
import 'package:sakhi_safety/models/incident.dart';
import 'package:sakhi_safety/services/ble_mesh.dart';
import 'package:sakhi_safety/services/location_service.dart';

void main() {
  group('BLE DistressPacket tests', () {
    test('Encodes and decodes 9-byte manufacturer data packet accurately', () {
      const alertId = 123456789;
      const col = 3; // D
      const row = 2; // 3 -> D3
      const ttl = 3;

      final packet = DistressPacket(alertId, col, row, ttl);
      final encoded = packet.encode();

      expect(encoded.length, 9);
      expect(encoded[0], DistressPacket.magic); // 0x53 ('S')
      expect(encoded[1], 1); // Version
      expect(encoded[2], ttl);

      final decoded = DistressPacket.decode(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.alertId, alertId);
      expect(decoded.col, col);
      expect(decoded.row, row);
      expect(decoded.ttl, ttl);
    });

    test('Rejects invalid packets', () {
      expect(DistressPacket.decode([0x00, 1, 2]), isNull);
      expect(DistressPacket.decode([0x99, 1, 3, 0, 0, 0, 1, 2, 3]), isNull);
    });
  });

  group('HotspotEngine tests', () {
    test('Seeds ~200 synthetic incident points clustered around hotspots', () {
      final incidents = HotspotEngine.seedSyntheticIncidents();
      expect(incidents.length, 200);
      expect(incidents.every((i) => i.source == 'synthetic'), isTrue);
      expect(incidents.any((i) => i.category == 'harassment'), isTrue);
      expect(incidents.any((i) => i.category == 'stalking'), isTrue);
    });

    test('Generates 56 geographic grid cells (8 cols x 7 rows)', () {
      final incidents = HotspotEngine.seedSyntheticIncidents();
      final publishedIds = {
        for (var r = 0; r < HotspotEngine.rows; r++)
          for (var c = 0; c < HotspotEngine.cols; c++)
            '${HotspotEngine.letters[c]}${r + 1}'
      };

      final zones = HotspotEngine.buildZones(
        incidents: incidents,
        hour: 22.0,
        publishedIds: publishedIds,
      );

      expect(zones.length, 56);
      expect(zones.first.id, 'A1');
      expect(zones.last.id, 'H7');

      // Verify D3 exists and has high risk at peak night hour
      final d3 = zones.firstWhere((z) => z.id == 'D3');
      expect(d3.polygon.length, 4);
      expect(d3.baseRisk, greaterThan(0.2));
      expect(d3.incidentsCount, greaterThan(0));
    });

    test('Time slider changes risk dynamically', () {
      final incidents = HotspotEngine.seedSyntheticIncidents();
      final publishedIds = {'D3'};

      final zonesAt22 = HotspotEngine.buildZones(
        incidents: incidents,
        hour: 22.0,
        publishedIds: publishedIds,
      );
      final zonesAt18 = HotspotEngine.buildZones(
        incidents: incidents,
        hour: 18.0,
        publishedIds: publishedIds,
      );

      final d3At22 = zonesAt22.firstWhere((z) => z.id == 'D3');
      final d3At18 = zonesAt18.firstWhere((z) => z.id == 'D3');

      // Risk at peak night hour (22:00) should be higher than early evening (18:00)
      expect(d3At22.baseRisk, greaterThan(d3At18.baseRisk));
    });

    test('Police booths are properly geolocated', () {
      final booths = HotspotEngine.getPoliceBooths();
      expect(booths.length, 4);
      expect(booths.any((b) => b['zone'] == 'C2'), isTrue);
      expect(booths.any((b) => b['zone'] == 'F2'), isTrue);
    });
  });

  group('Corridor & Navigation tests', () {
    test('Calculates corridor deviation threshold', () {
      const start = LatLng(19.0760, 72.8777);
      const destination = LatLng(19.0860, 72.8777); // 1.1 km directly north

      // Point directly on route line
      const onRoute = LatLng(19.0800, 72.8777);
      expect(LocationService.isOffCorridor(onRoute, start, destination, corridorMeters: 150), isFalse);

      // Point 50m east (still within 150m corridor)
      const slightlyOff = LatLng(19.0800, 72.8781);
      expect(LocationService.isOffCorridor(slightlyOff, start, destination, corridorMeters: 150), isFalse);

      // Point 400m east (deviated off corridor)
      const deviated = LatLng(19.0800, 72.8815);
      expect(LocationService.isOffCorridor(deviated, start, destination, corridorMeters: 150), isTrue);
    });
  });

  group('Model Serialization tests', () {
    test('SosAlert serialization preserves rounded coordinates and status', () {
      final alert = SosAlert(
        id: '849201',
        uid: 'user_01',
        name: 'Asha Sharma',
        zoneLat: 19.076012,
        zoneLng: 72.877734,
        zoneId: 'D3',
        reason: 'Manual SOS',
        via: 'ble',
        battery: 79,
        status: 'ack',
        createdAt: DateTime.now(),
      );

      final map = alert.toMap();
      expect(map['id'], '849201');
      expect(map['via'], 'ble');
      expect(map['status'], 'ack');
      expect(map['zoneLat'], 19.076); // Rounded
      expect(map['zoneLng'], 72.8777);

      final restored = SosAlert.fromMap(map, docId: '849201');
      expect(restored.isRelayed, isTrue);
      expect(restored.isActive, isTrue);
    });

    test('Incident serialization computes appropriate category weights', () {
      final incHarass = Incident(
        id: 'inc_1',
        lat: 19.076,
        lng: 72.877,
        category: 'harassment',
        hourBucket: 23,
        createdAt: DateTime.now(),
      );
      final incLight = Incident(
        id: 'inc_2',
        lat: 19.076,
        lng: 72.877,
        category: 'poor_lighting',
        hourBucket: 21,
        createdAt: DateTime.now(),
      );

      expect(incHarass.weight, 1.0);
      expect(incLight.weight, 0.5);
    });
  });
}
