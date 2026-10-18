import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'data/zones.dart';
import 'services/backend.dart';
import 'services/ble_mesh.dart';

enum SosPhase { idle, countdown, sending, done }

class SignalDef {
  const SignalDef(this.key, this.title, this.desc, this.weight);
  final String key, title, desc;
  final int weight;
}

const signalDefs = <SignalDef>[
  SignalDef('net', 'Network drops suddenly', 'Phone loses signal with no tunnel or lift nearby', 25),
  SignalDef('impact', 'Sudden impact or fall', 'Accelerometer spike, then no movement', 40),
  SignalDef('route', 'Leaves the planned route', 'Only checked while Safe journey is on', 30),
  SignalDef('stop', 'Unusual long stop', 'Stationary 6 min away from saved places', 20),
  SignalDef('missed', 'Missed check-in', 'No reply to a "Reached safely?" prompt', 35),
];
const int alertThreshold = 60;

class Contact {
  const Contact(this.name, this.relation);
  final String name, relation;
}

/// One global app state for the prototype. Swap for Provider/Riverpod later.
class AppState extends ChangeNotifier {
  // --- connectivity / environment
  bool hasNet = true;
  bool demoOffline = false; // lets you simulate offline in the demo
  bool get online => hasNet && !demoOffline;

  // --- map
  int hour = 22;
  String selZone = ZoneData.userZone;
  bool showCctv = false, showLights = false, showBooths = true;
  // Zones the police chose to publish. In production this comes from the server.
  final Set<String> published = ZoneData.zones.map((z) => z.id).toSet();

  // --- circle
  final contacts = const [
    Contact('Mom', 'Family'),
    Contact('Anita', 'Friend'),
    Contact('Rohan', 'Brother'),
  ];
  bool shareLocation = true, shareAudio = true, shareBattery = true;
  bool journey = false;

  // --- detection
  final Map<String, bool> sig = {for (final s in signalDefs) s.key: false};
  int get score {
    var t = 0;
    for (final s in signalDefs) {
      if (sig[s.key]! && (s.key != 'route' || journey)) t += s.weight;
    }
    return min(100, t);
  }

  // --- SOS state machine
  SosPhase phase = SosPhase.idle;
  int countdown = 10;
  String reason = '';
  int steps = 0;
  int? alertId;
  bool sentViaRelay = false;
  final List<String> meshLog = [];
  Timer? _cd;
  final List<Timer> _stepTimers = [];

  late final BleMesh mesh = BleMesh(
    isOnline: () => online,
    onEvent: (m) {
      meshLog.insert(0, m);
      notifyListeners();
    },
  );
  StreamSubscription? _connSub, _accSub;

  Future<void> init() async {
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final now = !results.contains(ConnectivityResult.none);
      if (hasNet && !now) setSignal('net', true); // network just dropped
      hasNet = now;
      notifyListeners();
    });
    _accSub = accelerometerEventStream().listen((e) {
      final g = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      if (g > 28 && !sig['impact']!) {
        setSignal('impact', true);
        Timer(const Duration(seconds: 60), () => setSignal('impact', false));
      }
    });
    await mesh.start();
  }

  void setSignal(String key, bool on) {
    sig[key] = on;
    notifyListeners();
    if (score >= alertThreshold && phase == SosPhase.idle) {
      final active = signalDefs
          .where((s) => sig[s.key]! && (s.key != 'route' || journey))
          .map((s) => s.title.toLowerCase())
          .join(' + ');
      startCountdown('Detected: $active');
    }
  }

  /// Public helper so widgets can update state and rebuild.
  void update(void Function() change) {
    change();
    notifyListeners();
  }

  void toggleDemoOffline() {
    demoOffline = !demoOffline;
    notifyListeners();
  }

  void startCountdown(String why) {
    if (phase != SosPhase.idle) return;
    reason = why;
    countdown = 10;
    phase = SosPhase.countdown;
    HapticFeedback.heavyImpact();
    notifyListeners();
    _cd = Timer.periodic(const Duration(seconds: 1), (t) {
      countdown--;
      if (countdown <= 0) {
        t.cancel();
        sendNow();
      } else {
        notifyListeners();
      }
    });
  }

  void sendNow() {
    _cd?.cancel();
    sentViaRelay = !online;
    alertId = Random().nextInt(0x7FFFFFFF);
    phase = SosPhase.sending;
    steps = 0;
    notifyListeners();

    final z = ZoneData.byId(ZoneData.userZone);
    // Always broadcast over BLE: nearby phones can relay it even if we think we are online.
    mesh.broadcast(DistressPacket(alertId!, z.c, z.r, 3));
    if (online) {
      Backend.sendAlert(alertId: alertId!, zone: z.id, reason: reason, viaRelay: false);
    }

    final n = online ? 4 : 5;
    for (var i = 1; i <= n; i++) {
      _stepTimers.add(Timer(Duration(milliseconds: 700 * i), () {
        steps = i;
        if (i == n) phase = SosPhase.done;
        notifyListeners();
      }));
    }
  }

  void cancel() {
    _cd?.cancel();
    for (final t in _stepTimers) {
      t.cancel();
    }
    _stepTimers.clear();
    mesh.stopBroadcast();
    for (final k in sig.keys) {
      sig[k] = false;
    }
    phase = SosPhase.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _accSub?.cancel();
    mesh.dispose();
    super.dispose();
  }
}

final app = AppState();
