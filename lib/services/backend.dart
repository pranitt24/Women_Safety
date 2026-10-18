import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/hotspot_engine.dart';
import '../models/alert_model.dart';
import '../models/incident.dart';
import '../models/trusted_contact.dart';

class Backend {
  static bool _hasFirebase = false;
  static FirebaseFirestore? _firestore;

  // Reactive in-memory fallback store ensuring instantaneous live sync and zero-crash demo
  static final StreamController<List<SosAlert>> _alertsController =
      StreamController<List<SosAlert>>.broadcast();
  static final StreamController<List<Incident>> _incidentsController =
      StreamController<List<Incident>>.broadcast();
  static final StreamController<Set<String>> _publishedZonesController =
      StreamController<Set<String>>.broadcast();

  static final List<SosAlert> _localAlerts = [];
  static final List<Incident> _localIncidents = HotspotEngine.seedSyntheticIncidents();
  static final Set<String> _publishedZones = {
    for (var r = 0; r < HotspotEngine.rows; r++)
      for (var c = 0; c < HotspotEngine.cols; c++)
        '${HotspotEngine.letters[c]}${r + 1}'
  };

  static List<SosAlert> get cachedAlerts => List.unmodifiable(_localAlerts);
  static List<Incident> get cachedIncidents => List.unmodifiable(_localIncidents);
  static Set<String> get cachedPublishedZones => Set.unmodifiable(_publishedZones);

  static Future<void> init() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _hasFirebase = true;
        _firestore = FirebaseFirestore.instance;
      } else {
        await Firebase.initializeApp();
        _hasFirebase = true;
        _firestore = FirebaseFirestore.instance;
      }
      debugPrint('[Backend] Firebase initialized successfully.');
    } catch (e) {
      _hasFirebase = false;
      debugPrint('[Backend] Firebase not configured for this device/platform ($e). Using in-memory reactive bridge.');
    }

    // Emit initial cached states
    _alertsController.add(_localAlerts);
    _incidentsController.add(_localIncidents);
    _publishedZonesController.add(_publishedZones);
  }

  // -------------------------------------------------------------
  // ALERTS (Distress events)
  // -------------------------------------------------------------

  /// Creates and dispatches distress alert to Firestore / Police console
  static Future<SosAlert> sendAlert({
    required int alertId,
    required String zoneId,
    required double zoneLat,
    required double zoneLng,
    required String reason,
    required bool viaRelay,
    int battery = 82,
    String citizenName = 'Asha Sharma',
    String citizenUid = 'user_asha_01',
    List<TrustedContact> contacts = const [],
  }) async {
    final alert = SosAlert(
      id: alertId.toString(),
      uid: citizenUid,
      name: citizenName,
      zoneLat: zoneLat,
      zoneLng: zoneLng,
      zoneId: zoneId,
      reason: reason,
      via: viaRelay ? 'ble' : 'internet',
      battery: battery,
      status: 'new',
      createdAt: DateTime.now(),
      liveLat: zoneLat,
      liveLng: zoneLng,
      liveUpdatedAt: DateTime.now(),
    );

    // Update local reactive store
    _localAlerts.removeWhere((a) => a.id == alert.id);
    _localAlerts.insert(0, alert);
    _alertsController.add(List.unmodifiable(_localAlerts));

    if (_hasFirebase && _firestore != null) {
      try {
        final alertData = alert.toMap();
        alertData['contactUids'] = contacts.where((c) => c.uid != null).map((c) => c.uid!).toList();
        await _firestore!.collection('alerts').doc(alert.id).set(alertData);

        // Record initial liveLocation breadcrumb
        await _firestore!
            .collection('alerts')
            .doc(alert.id)
            .collection('liveLocation')
            .add({
          'lat': zoneLat,
          'lng': zoneLng,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('[Backend] Error writing alert to Firestore: $e');
      }
    }

    return alert;
  }

  /// Updates live location breadcrumb for active SOS (written every 10s)
  static Future<void> updateLiveLocation({
    required String alertId,
    required double lat,
    required double lng,
  }) async {
    final now = DateTime.now();
    final idx = _localAlerts.indexWhere((a) => a.id == alertId);
    if (idx != -1) {
      final updated = _localAlerts[idx].copyWith(
        liveLat: lat,
        liveLng: lng,
        liveUpdatedAt: now,
      );
      _localAlerts[idx] = updated;
      _alertsController.add(List.unmodifiable(_localAlerts));
    }

    if (_hasFirebase && _firestore != null) {
      try {
        await _firestore!.collection('alerts').doc(alertId).update({
          'liveLat': lat,
          'liveLng': lng,
          'liveUpdatedAt': now.toIso8601String(),
        });

        await _firestore!
            .collection('alerts')
            .doc(alertId)
            .collection('liveLocation')
            .add({
          'lat': lat,
          'lng': lng,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('[Backend] Error writing live location to Firestore: $e');
      }
    }
  }

  /// Updates alert status (e.g. Police: "ack", "dispatched", "resolved" or Citizen: "cancelled")
  static Future<void> updateAlertStatus({
    required String alertId,
    required String newStatus,
  }) async {
    final idx = _localAlerts.indexWhere((a) => a.id == alertId);
    if (idx != -1) {
      _localAlerts[idx] = _localAlerts[idx].copyWith(status: newStatus);
      _alertsController.add(List.unmodifiable(_localAlerts));
    }

    if (_hasFirebase && _firestore != null) {
      try {
        await _firestore!.collection('alerts').doc(alertId).update({
          'status': newStatus,
          'statusUpdatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('[Backend] Error updating alert status in Firestore: $e');
      }
    }
  }

  /// Citizen app listens to its active alert document in real-time
  static Stream<SosAlert?> watchAlert(String alertId) {
    if (_hasFirebase && _firestore != null) {
      return _firestore!.collection('alerts').doc(alertId).snapshots().map((snap) {
        if (!snap.exists || snap.data() == null) {
          final local = _localAlerts.where((a) => a.id == alertId).firstOrNull;
          return local;
        }
        return SosAlert.fromMap(snap.data()!, docId: snap.id);
      }).handleError((_) {
        // Fallback to local stream on network error
        return _alertsController.stream
            .map((list) => list.where((a) => a.id == alertId).firstOrNull);
      });
    }

    return _alertsController.stream
        .map((list) => list.where((a) => a.id == alertId).firstOrNull);
  }

  /// Police console listens to all active and recent alerts
  static Stream<List<SosAlert>> watchActiveAlerts() {
    if (_hasFirebase && _firestore != null) {
      return _firestore!
          .collection('alerts')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map((snapshot) {
        final list = snapshot.docs
            .map((doc) => SosAlert.fromMap(doc.data(), docId: doc.id))
            .toList();
        return list.isNotEmpty ? list : _localAlerts;
      }).handleError((_) => _alertsController.stream);
    }

    return _alertsController.stream;
  }

  // -------------------------------------------------------------
  // INCIDENTS (Anonymous reports & aggregates)
  // -------------------------------------------------------------

  static Future<void> reportIncident({
    required double lat,
    required double lng,
    required String category,
    required int hourBucket,
    String source = 'user',
  }) async {
    final inc = Incident(
      id: 'inc_${DateTime.now().millisecondsSinceEpoch}',
      lat: lat,
      lng: lng,
      category: category,
      hourBucket: hourBucket,
      createdAt: DateTime.now(),
      source: source,
    );

    _localIncidents.insert(0, inc);
    _incidentsController.add(List.unmodifiable(_localIncidents));

    if (_hasFirebase && _firestore != null) {
      try {
        await _firestore!.collection('incidents').doc(inc.id).set(inc.toMap());
      } catch (e) {
        debugPrint('[Backend] Error writing incident: $e');
      }
    }
  }

  static Stream<List<Incident>> watchIncidents() {
    if (_hasFirebase && _firestore != null) {
      return _firestore!
          .collection('incidents')
          .orderBy('createdAt', descending: true)
          .limit(300)
          .snapshots()
          .map((snapshot) {
        final list = snapshot.docs
            .map((doc) => Incident.fromMap(doc.data(), id: doc.id))
            .toList();
        return list.isNotEmpty ? list : _localIncidents;
      }).handleError((_) => _incidentsController.stream);
    }

    return _incidentsController.stream;
  }

  // -------------------------------------------------------------
  // ZONES PUBLISHED (Police control)
  // -------------------------------------------------------------

  static Future<void> setZonePublished({
    required String cellId,
    required bool published,
  }) async {
    if (published) {
      _publishedZones.add(cellId);
    } else {
      _publishedZones.remove(cellId);
    }
    _publishedZonesController.add(Set.unmodifiable(_publishedZones));

    if (_hasFirebase && _firestore != null) {
      try {
        await _firestore!.collection('zonesPublished').doc(cellId).set({
          'published': published,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('[Backend] Error updating published zone: $e');
      }
    }
  }

  static Stream<Set<String>> watchPublishedZones() {
    if (_hasFirebase && _firestore != null) {
      return _firestore!.collection('zonesPublished').snapshots().map((snapshot) {
        final set = <String>{..._publishedZones};
        for (final doc in snapshot.docs) {
          final pub = doc.data()['published'] == true;
          if (pub) {
            set.add(doc.id);
          } else {
            set.remove(doc.id);
          }
        }
        return set;
      }).handleError((_) => _publishedZonesController.stream);
    }

    return _publishedZonesController.stream;
  }

  // -------------------------------------------------------------
  // FALLBACK CONTACT MESSAGING (SMS & WhatsApp URLs)
  // -------------------------------------------------------------

  static Future<bool> openSmsFallback({
    required String phone,
    required String message,
  }) async {
    final uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': message},
    );
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> openWhatsAppFallback({
    required String phone,
    required String message,
  }) async {
    final cleanedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final encodedMsg = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/$cleanedPhone?text=$encodedMsg');
    try {
      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }
}
