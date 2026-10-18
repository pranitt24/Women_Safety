class Incident {
  const Incident({
    required this.id,
    required this.lat,
    required this.lng,
    required this.category,
    required this.hourBucket,
    required this.createdAt,
    this.source = 'synthetic',
  });

  final String id;
  final double lat;
  final double lng;
  /// One of: harassment, stalking, poor_lighting, unsafe_area
  final String category;
  /// 0..23
  final int hourBucket;
  final DateTime createdAt;
  /// 'user' | 'police' | 'synthetic'
  final String source;

  double get weight {
    switch (category.toLowerCase()) {
      case 'harassment':
        return 1.0;
      case 'stalking':
        return 0.9;
      case 'unsafe_area':
      case 'unsafe area':
        return 0.7;
      case 'poor_lighting':
      case 'poor lighting':
        return 0.5;
      default:
        return 0.6;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lat': double.parse(lat.toStringAsFixed(4)),
      'lng': double.parse(lng.toStringAsFixed(4)),
      'category': category,
      'hourBucket': hourBucket,
      'createdAt': createdAt.toIso8601String(),
      'source': source,
    };
  }

  factory Incident.fromMap(Map<String, dynamic> map, {String? id}) {
    return Incident(
      id: id ?? map['id']?.toString() ?? '',
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      category: map['category']?.toString() ?? 'unsafe_area',
      hourBucket: (map['hourBucket'] as num?)?.toInt() ?? 22,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      source: map['source']?.toString() ?? 'synthetic',
    );
  }
}
