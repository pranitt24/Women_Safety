import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import 'data/hotspot_engine.dart';
import 'models/incident.dart';
import 'models/trusted_contact.dart';
import 'models/zone_model.dart';
import 'services/backend.dart';
import 'services/ble_mesh.dart';
import 'services/foreground_service.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'services/sensor_detector.dart';

enum SosPhase { idle, countdown, sending, done }

class SignalDef {
  const SignalDef(this.key, this.title, this.desc, this.weight);
  final String key, title, desc;
  final int weight;
}

const signalDefs = <SignalDef>[
  SignalDef('net', 'Network drops suddenly', 'Phone loses signal with no tunnel or lift nearby', 25),
  SignalDef('impact', 'Sudden impact or fall', 'Accelerometer spike, then 3s of stillness', 40),
  SignalDef('route', 'Leaves planned route', 'Off the 150m corridor while Safe journey is on', 30),
  SignalDef('stop', 'Unusual long stop', 'Stationary > 6 min away from saved places', 20),
  SignalDef('missed', 'Missed check-in', 'No reply to a "Reached safely?" prompt', 35),
];

const int alertThreshold = 60;

class AppState extends ChangeNotifier {
  // --- Connectivity & Environment
  bool hasNet = true;
  bool demoOffline = false; // Demo toggle for offline BLE relay testing
  bool get online => hasNet && !demoOffline;
  int batteryLevel = 84;

  // --- Theme & Discreet Mode
  ThemeMode themeMode = ThemeMode.light;
  bool get isDiscreetMode => themeMode == ThemeMode.dark;
  void toggleTheme() {
    themeMode = themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // --- User Geolocation & Map
  LatLng userLocation = kCityCenter;
  int hour = 22; // 18..26 (18=6PM, 24=Midnight, 26=2AM)
  String selZone = HotspotEngine.userZoneId;
  bool showCctv = false;
  bool showLights = false;
  bool showBooths = true;

  List<Incident> incidents = [];
  Set<String> published = {};
  List<GeoZone> zones = [];

  GeoZone get currentZone {
    return zones.firstWhere(
      (z) => z.id == selZone,
      orElse: () => zones.isNotEmpty
          ? zones.first
          : GeoZone(
              id: 'D3',
              c: 3,
              r: 2,
              center: kCityCenter,
              polygon: HotspotEngine.polygonForCell(3, 2),
              baseRisk: 0.45,
              peakHour: 22.0,
              incidentsCount: 32,
              litRatio: 0.8,
              cctv: 2,
              cctvOk: 2,
              isPublished: true,
            ),
    );
  }

  // --- Safe Journey Corridor
  bool journey = false;
  LatLng journeyDestination = const LatLng(19.0650, 72.8680); // BKC Commercial Hub
  String journeyDestinationName = 'Bandra Kurla Complex';
  DateTime? journeyEta;
  Timer? _etaCheckInTimer;

  // --- Trusted Circle
  final List<TrustedContact> contacts = [
    const TrustedContact(name: 'Mom', phone: '+919820011223', relation: 'Family', hasApp: true, uid: 'mom_uid_01'),
    const TrustedContact(name: 'Anita', phone: '+919820044556', relation: 'Friend', hasApp: true, uid: 'anita_uid_02'),
    const TrustedContact(name: 'Rohan', phone: '+919820077889', relation: 'Brother', hasApp: false),
  ];
  bool shareLocation = true;
  bool shareAudio = true;
  bool shareBattery = true;

  // --- Detection signals & scoring
  final Map<String, bool> sig = {for (final s in signalDefs) s.key: false};

  int get score {
    var t = 0;
    for (final s in signalDefs) {
      if (sig[s.key]! && (s.key != 'route' || journey)) t += s.weight;
    }
    return min(100, t);
  }

  // --- SOS State Machine
  SosPhase phase = SosPhase.idle;
  int countdown = 10;
  String reason = '';
  int steps = 0;
  int? alertId;
  String? activeAlertStatus = 'new'; // 'new' | 'ack' | 'dispatched' | 'resolved'
  bool sentViaRelay = false;
  final List<String> meshLog = [];
  Timer? _cd;
  final List<Timer> _stepTimers = [];
  Timer? _liveLocationTimer;
  StreamSubscription? _alertDocSub;

  // --- Fake Call feature
  bool isFakeCallActive = false;

  late final BleMesh mesh = BleMesh(
    isOnline: () => online,
    onEvent: (m) {
      meshLog.insert(0, m);
      notifyListeners();
    },
  );

  late final SensorDetector sensorDetector = SensorDetector(
    onImpactConfirmed: () {
      setSignal('impact', true);
      // Keep impact flag active for 90s unless cancelled
      Timer(const Duration(seconds: 90), () => setSignal('impact', false));
    },
  );

  StreamSubscription? _connSub;
  StreamSubscription? _incidentsSub;
  StreamSubscription? _publishedSub;

  Future<void> init() async {
    // 1. Initialize Backend
    await Backend.init();

    // 2. Setup initial incidents and published zones
    incidents = Backend.cachedIncidents;
    published = Backend.cachedPublishedZones;
    _recalculateZones();

    // 3. Listen to realtime incidents and published zone streams
    _incidentsSub = Backend.watchIncidents().listen((updatedList) {
      incidents = updatedList;
      _recalculateZones();
      notifyListeners();
    });

    _publishedSub = Backend.watchPublishedZones().listen((updatedPublished) {
      published = updatedPublished;
      _recalculateZones();
      notifyListeners();
    });

    // 4. Geolocation setup
    await locateUser();
    LocationService.startTracking(
      onRouteDeviation: (isOff) {
        if (journey && isOff != sig['route']) {
          setSignal('route', isOff);
        }
      },
      onLongStopDetected: () {
        setSignal('stop', true);
      },
    );

    // 5. Connectivity detection
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final now = !results.contains(ConnectivityResult.none);
      // Sudden network loss requires a second signal before alerting (threshold 60)
      if (hasNet && !now) {
        setSignal('net', true);
      }
      hasNet = now;
      notifyListeners();
    });

    // 6. Impact sensor detection
    sensorDetector.start();

    // 7. Bluetooth mesh
    await mesh.start();

    // 8. Foreground task on Android
    await ForegroundServiceManager.init();

    // 9. Local notifications
    await NotificationService.init(
      onSelectNotification: (payload) {
        if (payload == 'check_in') {
          // User confirmed safe
          setSignal('missed', false);
        }
      },
    );
  }

  void _recalculateZones() {
    zones = HotspotEngine.buildZones(
      incidents: incidents,
      hour: hour.toDouble(),
      publishedIds: published,
    );
  }

  Future<void> locateUser() async {
    final pos = await LocationService.getCurrentPosition();
    userLocation = pos;
    notifyListeners();
  }

  void setHour(int newHour) {
    hour = newHour;
    _recalculateZones();
    notifyListeners();
  }

  void setSignal(String key, bool on) {
    sig[key] = on;
    notifyListeners();

    // If combined score reaches alertThreshold (60), start 10s countdown
    if (score >= alertThreshold && phase == SosPhase.idle) {
      final active = signalDefs
          .where((s) => sig[s.key]! && (s.key != 'route' || journey))
          .map((s) => s.title.toLowerCase())
          .join(' + ');
      startCountdown('Auto-detected: $active');
    }
  }

  void update(void Function() change) {
    change();
    _recalculateZones();
    notifyListeners();
  }

  void toggleDemoOffline() {
    demoOffline = !demoOffline;
    notifyListeners();
  }

  void toggleJourney(bool enabled) {
    journey = enabled;
    LocationService.journeyActive = enabled;
    if (enabled) {
      LocationService.journeyStart = userLocation;
      LocationService.journeyDestination = journeyDestination;
      journeyEta = DateTime.now().add(const Duration(minutes: 25));

      // Schedule missed check-in prompt simulation (e.g. in 45s for demo)
      _etaCheckInTimer?.cancel();
      _etaCheckInTimer = Timer(const Duration(seconds: 45), () {
        NotificationService.showCheckInNotification(
          title: 'Reached safely?',
          body: 'You should be near $journeyDestinationName. Tap to confirm safe arrival.',
        );
      });
    } else {
      LocationService.journeyStart = null;
      LocationService.journeyDestination = null;
      journeyEta = null;
      _etaCheckInTimer?.cancel();
      sig['route'] = false;
    }
    notifyListeners();
  }

  // --- SOS State Machine

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
    activeAlertStatus = 'new';
    phase = SosPhase.sending;
    steps = 0;
    HapticFeedback.heavyImpact();
    notifyListeners();

    // Determine current zone coordinates
    final z = currentZone;

    // 1. Broadcast over BLE Mesh (nearby phones relay it if offline)
    mesh.broadcast(DistressPacket(alertId!, z.c, z.r, 3));

    // 2. Upload to Backend if online
    if (online) {
      Backend.sendAlert(
        alertId: alertId!,
        zoneId: z.id,
        zoneLat: userLocation.latitude,
        zoneLng: userLocation.longitude,
        reason: reason,
        viaRelay: false,
        battery: batteryLevel,
        contacts: contacts,
      );
    }

    // 3. Keep foreground service awake
    ForegroundServiceManager.start();

    // 4. Start periodic live location updates every 10 seconds
    _liveLocationTimer?.cancel();
    _liveLocationTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final pos = await LocationService.getCurrentPosition();
      userLocation = pos;
      if (alertId != null) {
        await Backend.updateLiveLocation(
          alertId: alertId!.toString(),
          lat: pos.latitude,
          lng: pos.longitude,
        );
      }
    });

    // 5. Listen to alert document so police actions (ack, dispatched, resolved) sync live!
    _alertDocSub?.cancel();
    _alertDocSub = Backend.watchAlert(alertId!.toString()).listen((alert) {
      if (alert != null) {
        activeAlertStatus = alert.status;
        notifyListeners();
      }
    });

    // Simulated transmission progress steps
    final n = online ? 4 : 5;
    for (var i = 1; i <= n; i++) {
      _stepTimers.add(Timer(Duration(milliseconds: 650 * i), () {
        steps = i;
        if (i == n) {
          phase = SosPhase.done;
          NotificationService.showDistressNotification(
            title: 'Distress Alert Active',
            body: 'Live tracking & police notification initiated. Tap for options.',
          );
        }
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
    _liveLocationTimer?.cancel();
    _alertDocSub?.cancel();

    if (alertId != null) {
      Backend.updateAlertStatus(alertId: alertId!.toString(), newStatus: 'cancelled');
    }

    mesh.stopBroadcast();
    ForegroundServiceManager.stop();

    for (final k in sig.keys) {
      sig[k] = false;
    }
    phase = SosPhase.idle;
    activeAlertStatus = null;
    notifyListeners();
  }

  // --- Anonymous incident reporting
  Future<void> submitAnonymousReport({
    required double lat,
    required double lng,
    required String category,
  }) async {
    await Backend.reportIncident(
      lat: lat,
      lng: lng,
      category: category,
      hourBucket: hour % 24,
      source: 'user',
    );
  }

  // --- Fake Call screen
  void triggerFakeCall() {
    isFakeCallActive = true;
    notifyListeners();
  }

  void dismissFakeCall() {
    isFakeCallActive = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _incidentsSub?.cancel();
    _publishedSub?.cancel();
    _alertDocSub?.cancel();
    _liveLocationTimer?.cancel();
    _etaCheckInTimer?.cancel();
    sensorDetector.stop();
    LocationService.stopTracking();
    mesh.dispose();
    super.dispose();
  }
}

final app = AppState();
