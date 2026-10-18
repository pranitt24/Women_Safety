import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../data/hotspot_engine.dart';

class LocationService {
  static LatLng _lastKnown = kCityCenter;
  static LatLng get lastKnown => _lastKnown;

  static StreamSubscription<Position>? _posSub;
  static final StreamController<LatLng> _posController = StreamController<LatLng>.broadcast();
  static Stream<LatLng> get stream => _posController.stream;

  // Route corridor tracking
  static LatLng? journeyStart;
  static LatLng? journeyDestination;
  static bool journeyActive = false;

  // Stationary long stop tracking
  static LatLng? _stationaryAnchor;
  static DateTime? _stationaryStartTime;
  static const int stopThresholdMinutes = 6;

  static Future<bool> ensurePermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('[LocationService] Permission check error: $e');
      return false;
    }
  }

  static Future<LatLng> getCurrentPosition() async {
    final hasPerm = await ensurePermission();
    if (!hasPerm) return _lastKnown;

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(timeLimit: Duration(seconds: 5)),
      );
      _lastKnown = LatLng(pos.latitude, pos.longitude);
      return _lastKnown;
    } catch (_) {
      return _lastKnown;
    }
  }

  static void startTracking({
    void Function(bool isOffCorridor)? onRouteDeviation,
    void Function()? onLongStopDetected,
  }) {
    _posSub?.cancel();

    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      final current = LatLng(pos.latitude, pos.longitude);
      _lastKnown = current;
      _posController.add(current);

      // Check route corridor deviation
      if (journeyActive && journeyStart != null && journeyDestination != null) {
        final off = isOffCorridor(current, journeyStart!, journeyDestination!, corridorMeters: 150);
        onRouteDeviation?.call(off);
      }

      // Check stationary long stop (> 6 minutes outside saved places)
      _checkLongStop(current, onLongStopDetected);
    }, onError: (e) {
      debugPrint('[LocationService] Position stream error: $e');
    });
  }

  /// Calculates perpendicular cross-track distance in meters from point to route line segment
  static bool isOffCorridor(
    LatLng point,
    LatLng start,
    LatLng end, {
    double corridorMeters = 150.0,
  }) {
    const distCalc = Distance();
    final dStartEnd = distCalc.as(LengthUnit.Meter, start, end);
    if (dStartEnd < 10) return false;

    // Perpendicular cross-track approximation using projected distance
    final pLat = point.latitude;
    final pLng = point.longitude;
    final sLat = start.latitude;
    final sLng = start.longitude;
    final eLat = end.latitude;
    final eLng = end.longitude;

    final dx = (eLng - sLng) * 104950;
    final dy = (eLat - sLat) * 111000;
    final lengthSq = dx * dx + dy * dy;

    if (lengthSq == 0) return false;

    final px = (pLng - sLng) * 104950;
    final py = (pLat - sLat) * 111000;

    // Projection factor t clamped between 0 and 1
    final t = max(0.0, min(1.0, (px * dx + py * dy) / lengthSq));
    final projX = sLng * 104950 + t * dx;
    final projY = sLat * 111000 + t * dy;

    final distToLineMeters = sqrt(pow(px - (projX - sLng * 104950), 2) + pow(py - (projY - sLat * 111000), 2));

    return distToLineMeters > corridorMeters;
  }

  static void _checkLongStop(LatLng current, VoidCallback? onLongStopDetected) {
    const distCalc = Distance();
    if (_stationaryAnchor == null) {
      _stationaryAnchor = current;
      _stationaryStartTime = DateTime.now();
      return;
    }

    final metersFromAnchor = distCalc.as(LengthUnit.Meter, _stationaryAnchor!, current);
    if (metersFromAnchor > 30) {
      // User moved noticeably; reset anchor
      _stationaryAnchor = current;
      _stationaryStartTime = DateTime.now();
    } else {
      // User is still around anchor
      final elapsed = DateTime.now().difference(_stationaryStartTime!);
      if (elapsed.inMinutes >= stopThresholdMinutes) {
        onLongStopDetected?.call();
      }
    }
  }

  static void stopTracking() {
    _posSub?.cancel();
    _stationaryAnchor = null;
    _stationaryStartTime = null;
  }
}
