import 'package:latlong2/latlong.dart';

class GeoZone {
  GeoZone({
    required this.id,
    required this.c,
    required this.r,
    required this.center,
    required this.polygon,
    required this.baseRisk,
    required this.peakHour,
    required this.incidentsCount,
    required this.litRatio,
    required this.cctv,
    required this.cctvOk,
    this.isPublished = true,
  });

  final String id;
  final int c;
  final int r;
  final LatLng center;
  final List<LatLng> polygon;
  final double baseRisk;
  final double peakHour; // e.g. 22.5 (10:30 PM)
  final int incidentsCount;
  final double litRatio; // 0.0 to 1.0
  final int cctv;
  final int cctvOk;
  bool isPublished;

  /// Risk at a given hour (18..26, where 24 = midnight, 25 = 1 AM, 26 = 2 AM)
  double heatAt(double hour) {
    // Matches the prototype exponential peak decay
    final distFromPeak = (hour - peakHour) / 2.6;
    final curve = 0.3 + 0.7 * (1.0 / (1.0 + (distFromPeak * distFromPeak)));
    return (baseRisk * curve).clamp(0.0, 1.0);
  }

  GeoZone copyWith({bool? isPublished, double? baseRisk, int? incidentsCount}) {
    return GeoZone(
      id: id,
      c: c,
      r: r,
      center: center,
      polygon: polygon,
      baseRisk: baseRisk ?? this.baseRisk,
      peakHour: peakHour,
      incidentsCount: incidentsCount ?? this.incidentsCount,
      litRatio: litRatio,
      cctv: cctv,
      cctvOk: cctvOk,
      isPublished: isPublished ?? this.isPublished,
    );
  }
}
