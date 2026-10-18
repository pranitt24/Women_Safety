class SosAlert {
  const SosAlert({
    required this.id,
    required this.uid,
    required this.name,
    required this.zoneLat,
    required this.zoneLng,
    required this.reason,
    required this.via,
    required this.battery,
    required this.status,
    required this.createdAt,
    this.zoneId = 'D3',
    this.liveLat,
    this.liveLng,
    this.liveUpdatedAt,
  });

  final String id;
  final String uid;
  final String name;
  final double zoneLat;
  final double zoneLng;
  final String zoneId;
  final String reason;
  final String via; // "internet" | "ble"
  final int battery;
  final String status; // "new" | "ack" | "dispatched" | "resolved" | "cancelled"
  final DateTime createdAt;
  final double? liveLat;
  final double? liveLng;
  final DateTime? liveUpdatedAt;

  bool get isRelayed => via == 'ble';
  bool get isActive => status != 'resolved' && status != 'cancelled';

  SosAlert copyWith({
    String? status,
    double? liveLat,
    double? liveLng,
    DateTime? liveUpdatedAt,
  }) {
    return SosAlert(
      id: id,
      uid: uid,
      name: name,
      zoneLat: zoneLat,
      zoneLng: zoneLng,
      zoneId: zoneId,
      reason: reason,
      via: via,
      battery: battery,
      status: status ?? this.status,
      createdAt: createdAt,
      liveLat: liveLat ?? this.liveLat,
      liveLng: liveLng ?? this.liveLng,
      liveUpdatedAt: liveUpdatedAt ?? this.liveUpdatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'name': name,
      'zoneLat': double.parse(zoneLat.toStringAsFixed(4)),
      'zoneLng': double.parse(zoneLng.toStringAsFixed(4)),
      'zoneId': zoneId,
      'reason': reason,
      'via': via,
      'battery': battery,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      if (liveLat != null) 'liveLat': double.parse(liveLat!.toStringAsFixed(5)),
      if (liveLng != null) 'liveLng': double.parse(liveLng!.toStringAsFixed(5)),
      if (liveUpdatedAt != null) 'liveUpdatedAt': liveUpdatedAt!.toIso8601String(),
    };
  }

  factory SosAlert.fromMap(Map<String, dynamic> map, {String? docId}) {
    return SosAlert(
      id: docId ?? map['id']?.toString() ?? '',
      uid: map['uid']?.toString() ?? 'anonymous',
      name: map['name']?.toString() ?? 'Citizen',
      zoneLat: (map['zoneLat'] as num?)?.toDouble() ?? 19.0760,
      zoneLng: (map['zoneLng'] as num?)?.toDouble() ?? 72.8777,
      zoneId: map['zoneId']?.toString() ?? 'D3',
      reason: map['reason']?.toString() ?? 'SOS Pressed',
      via: map['via']?.toString() ?? 'internet',
      battery: (map['battery'] as num?)?.toInt() ?? 65,
      status: map['status']?.toString() ?? 'new',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      liveLat: (map['liveLat'] as num?)?.toDouble(),
      liveLng: (map['liveLng'] as num?)?.toDouble(),
      liveUpdatedAt: map['liveUpdatedAt'] != null
          ? DateTime.tryParse(map['liveUpdatedAt'].toString())
          : null,
    );
  }
}
