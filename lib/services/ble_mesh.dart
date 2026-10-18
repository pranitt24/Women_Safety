import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'backend.dart';

/// Tiny distress packet carried in BLE manufacturer data (9 bytes).
/// [0]=0x53 magic, [1]=version, [2]=ttl, [3..6]=alert id, [7]=zone col, [8]=zone row
class DistressPacket {
  DistressPacket(this.alertId, this.col, this.row, this.ttl);
  final int alertId, col, row, ttl;

  static const int companyId = 0xFFFF; // test id; fine for a prototype
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
///  - listens for distress packets,
///  - if it has internet, uploads them (Backend),
///  - if not, re-broadcasts them with ttl-1.
class BleMesh {
  BleMesh({required this.isOnline, required this.onEvent});

  final bool Function() isOnline;
  final void Function(String message) onEvent;

  final FlutterBlePeripheral _periph = FlutterBlePeripheral();
  final Set<int> _seen = {};
  StreamSubscription<List<ScanResult>>? _sub;
  Timer? _loop;

  Future<bool> ensurePermissions() async {
    final res = await [
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    return res.values.every((s) => s.isGranted);
  }

  Future<void> start() async {
    if (!await ensurePermissions()) {
      onEvent('Bluetooth permissions denied. Offline relay is off.');
      return;
    }
    _sub = FlutterBluePlus.scanResults.listen(_onResults);
    await _scanOnce();
    // Restart scan periodically so repeated advertisements are re-reported.
    _loop = Timer.periodic(const Duration(seconds: 20), (_) => _scanOnce());
  }

  Future<void> _scanOnce() async {
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      debugPrint('scan error: $e');
    }
  }

  void _onResults(List<ScanResult> results) {
    for (final r in results) {
      final data = r.advertisementData.manufacturerData[DistressPacket.companyId];
      if (data == null) continue;
      final p = DistressPacket.decode(data);
      if (p == null || _seen.contains(p.alertId)) continue;
      _seen.add(p.alertId);
      if (isOnline()) {
        onEvent('Relayed distress packet #${p.alertId}: uploading (we have internet)');
        Backend.sendAlert(
          alertId: p.alertId,
          zone: '${'ABCDEFGH'[p.col]}${p.row + 1}',
          reason: 'Relayed over BLE',
          viaRelay: true,
        );
      } else if (p.ttl > 0) {
        onEvent('Relayed distress packet #${p.alertId}: re-broadcasting (ttl ${p.ttl - 1})');
        broadcast(DistressPacket(p.alertId, p.col, p.row, p.ttl - 1));
      }
    }
  }

  /// Broadcast our own (or a relayed) distress packet.
  Future<void> broadcast(DistressPacket p) async {
    _seen.add(p.alertId);
    try {
      await _periph.start(
        advertiseData: AdvertiseData(
          manufacturerId: DistressPacket.companyId,
          manufacturerData: p.encode(),
          includeDeviceName: false,
        ),
      );
    } catch (e) {
      onEvent('Could not advertise: $e');
    }
  }

  Future<void> stopBroadcast() async {
    try {
      await _periph.stop();
    } catch (_) {}
  }

  void dispose() {
    _sub?.cancel();
    _loop?.cancel();
  }
}
