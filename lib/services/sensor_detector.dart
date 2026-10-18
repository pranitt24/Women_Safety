import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Monitors accelerometer for impact spikes followed by 3 seconds of stillness.
class SensorDetector {
  SensorDetector({required this.onImpactConfirmed});

  final VoidCallback onImpactConfirmed;

  StreamSubscription? _accSub;
  bool _spikeDetected = false;
  final List<double> _postSpikeMagnitudes = [];
  Timer? _stillnessCheckTimer;

  void start() {
    _accSub?.cancel();
    _accSub = accelerometerEventStream().listen((event) {
      final g = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      if (!_spikeDetected) {
        // Impact spike threshold (> 28 m/s² ~ almost 3g)
        if (g > 28.0) {
          _spikeDetected = true;
          _postSpikeMagnitudes.clear();
          debugPrint('[SensorDetector] Impact spike detected: ${g.toStringAsFixed(1)} m/s²');

          // Check after 3 seconds if phone remained still
          _stillnessCheckTimer?.cancel();
          _stillnessCheckTimer = Timer(const Duration(seconds: 3), () {
            _evaluateStillness();
          });
        }
      } else {
        // Collect magnitudes during the 3-second stillness window
        _postSpikeMagnitudes.add(g);
      }
    }, onError: (e) {
      debugPrint('[SensorDetector] Sensor error: $e');
    });
  }

  void _evaluateStillness() {
    if (_postSpikeMagnitudes.isEmpty) {
      _reset();
      return;
    }

    // Normal gravity on stationary phone is ~9.8 m/s².
    // Stillness means low variance from earth gravity (no violent shaking/walking).
    double sum = 0;
    for (final m in _postSpikeMagnitudes) {
      sum += (m - 9.8).abs();
    }
    final avgDev = sum / _postSpikeMagnitudes.length;

    // If average deviation is under 3.5 m/s², person/phone is motionless after fall
    if (avgDev < 3.5) {
      debugPrint('[SensorDetector] Impact followed by 3s stillness confirmed! Triggering impact alert.');
      onImpactConfirmed();
    } else {
      debugPrint('[SensorDetector] Motion continued after spike, fall discarded.');
    }

    _reset();
  }

  void _reset() {
    _spikeDetected = false;
    _postSpikeMagnitudes.clear();
    _stillnessCheckTimer?.cancel();
    _stillnessCheckTimer = null;
  }

  void stop() {
    _accSub?.cancel();
    _stillnessCheckTimer?.cancel();
    _reset();
  }
}
