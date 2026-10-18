import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/hotspot_engine.dart';
import 'backend.dart';

/// Tiny distress packet carried in BLE manufacturer data (9 bytes).
/// [0]=0x53 magic ('S'), [1]=version, [2]=ttl, [3..6]=alert id, [7]=zone col, [8]=zone row
class DistressPacket {
  DistressPacket(this.alertId, this.col, this.row, this.ttl);
  final int alertId, col, row, ttl;

  static const int companyId = 0xFFFF; // test id; fine for prototype
  static const int magic = 0x53;

  Uint8List encode() => Uint8List.fromList([
        magic,
        1,
        ttl,
        (alertId >> 24) & 0xFF,
        (alertId >> 16) & 0xFF,
        (alertId >> 8) & 0xFF,
        alertId & 0xFF,
        col,
        row,
      ]);

  static DistressPacket? decode(List<int> d) {
    if (d.length < 9 || d[0] != magic) return null;
    final id = (d[3] << 24) | (d[4] << 16) | (d[5] << 8) | d[6];
    return DistressPacket(id, d[7], d[8], d[2]);
  }
}

/// Offline relay. Every phone with the app:
///  - listens for distress packets via BLE scanner,
///  - if it has internet, uploads them to Firestore (Backend) tagged as 'ble',
///  - if not, re-broadcasts them with ttl-1 (max 3 hops, rate-limited to 1 relay per alert id).
class BleMesh {
  BleMesh({required this.isOnline, required this.onEvent});

  final bool Function() isOnline;
  final void Function(String message) onEvent;

  final FlutterBlePeripheral _periph = FlutterBlePeripheral();
  final Set<int> _seen = {};
  final Set<int> _relayedAlerts = {}; // Rate limiting: max 1 relay per alert id
  StreamSubscription<List<ScanResult>>? _sub;
  Timer? _loop;

  Future<bool> ensurePermissions() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    try {
      final res = await [
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
      return res.values.every((s) => s.isGranted);
    } catch (_) {
      return false;
    }
  }

  Future<void> start() async {
    if (kIsWeb) return;

    if (!await ensurePermissions()) {
      onEvent('Bluetooth permissions not granted. Offline relay is idle.');
      return;
    }

    try {
      _sub = FlutterBluePlus.scanResults.listen(_onResults);
      await _scanOnce();
      // Periodically scan to catch beacon pulses from nearby phones
      _loop = Timer.periodic(const Duration(seconds: 15), (_) => _scanOnce());
    } catch (e) {
      debugPrint('[BleMesh] BLE scan start error: $e');
    }
  }

  Future<void> _scanOnce() async {
    try {
      if (await FlutterBluePlus.isSupported) {
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      }
    } catch (e) {
      debugPrint('[BleMesh] scan error: $e');
    }
  }

  void _onResults(List<ScanResult> results) {
    for (final r in results) {
      final data = r.advertisementData.manufacturerData[DistressPacket.companyId];
      if (data == null) continue;
      final p = DistressPacket.decode(data);
      if (p == null) continue;

      // Rate limiting: process each alert ID only once
      if (_seen.contains(p.alertId) || _relayedAlerts.contains(p.alertId)) continue;
      _seen.add(p.alertId);
      _relayedAlerts.add(p.alertId);

      final zoneId = '${HotspotEngine.letters[p.col.clamp(0, 7)]}${p.row.clamp(0, 6) + 1}';
      final zoneCenter = HotspotEngine.centerForCell(p.col.clamp(0, 7), p.row.clamp(0, 6));

      if (isOnline()) {
        onEvent('Relayed distress packet #${p.alertId} from nearby phone: uploading (online)');
        Backend.sendAlert(
          alertId: p.alertId,
          zoneId: zoneId,
          zoneLat: zoneCenter.latitude,
          zoneLng: zoneCenter.longitude,
          reason: 'Relayed by nearby phone over BLE',
          viaRelay: true,
        );
      } else if (p.ttl > 1) {
        // TTL hop decrement (TTL 3 -> 2 -> 1 -> stops)
        final nextTtl = p.ttl - 1;
        onEvent('Relayed distress packet #${p.alertId}: re-broadcasting (ttl $nextTtl)');
        broadcast(DistressPacket(p.alertId, p.col, p.row, nextTtl));
      }
    }
  }

  /// Broadcast distress packet over BLE manufacturer data
  Future<void> broadcast(DistressPacket p) async {
    _seen.add(p.alertId);
    if (kIsWeb) return;

    try {
      await _periph.start(
        advertiseData: AdvertiseData(
          manufacturerId: DistressPacket.companyId,
          manufacturerData: p.encode(),
          includeDeviceName: false,
        ),
      );
    } catch (e) {
      onEvent('Could not advertise BLE packet: $e');
    }
  }

  Future<void> stopBroadcast() async {
    if (kIsWeb) return;
    try {
      await _periph.stop();
    } catch (_) {}
  }

  void dispose() {
    _sub?.cancel();
    _loop?.cancel();
    stopBroadcast();
  }
}
