import 'dart:math';

/// Synthetic demo data. Zones only: no names, no addresses, no offender data.
class Zone {
  Zone({
    required this.id,
    required this.c,
    required this.r,
    required this.base,
    required this.peak,
    required this.incidents,
    required this.lit,
    required this.cctv,
    required this.cctvOk,
  });

  final String id;
  final int c, r;
  final double base; // 0..1 overall risk
  final double peak; // busiest hour (21..24)
  final int incidents; // reports in last 90 days
  final double lit; // fraction of street lights working
  final int cctv, cctvOk;

  /// Risk at a given hour (18..26, where 24 = midnight).
  double heatAt(double hour) =>
      base * (0.3 + 0.7 * exp(-pow((hour - peak) / 2.6, 2)));
}

String hourLabel(int h) {
  final x = h % 24;
  final suffix = x >= 12 ? 'PM' : 'AM';
  final y = x % 12 == 0 ? 12 : x % 12;
  return '$y $suffix';
}

class ZoneData {
  static const int cols = 8, rows = 7;
  static const String userZone = 'D3';
  static const List<String> booths = ['C2', 'F2', 'B6', 'G7'];
  static const String _letters = 'ABCDEFGH';

  static final List<Zone> zones = _generate();

  static Zone byId(String id) => zones.firstWhere((z) => z.id == id);

  static List<Zone> _generate() {
    final rnd = Random(11);
    const hot = <List<double>>[
      [3, 2, 1.0],
      [6, 4, 0.9],
      [1, 5, 0.7],
      [4, 5, 0.45],
    ];
    final out = <Zone>[];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        var b = rnd.nextDouble() * 0.18;
        for (final h in hot) {
          final d = pow(c - h[0], 2) + pow(r - h[1], 2);
          b += h[2] * exp(-d / 2.4);
        }
        b = min(1.0, b);
        final cctv = (rnd.nextDouble() * 2 + 1).round();
        var ok = (cctv * (1 - b * 0.5 * rnd.nextDouble() * 1.6)).round();
        if (ok > cctv) ok = cctv;
        out.add(Zone(
          id: '${_letters[c]}${r + 1}',
          c: c,
          r: r,
          base: b,
          peak: 21 + rnd.nextDouble() * 3,
          incidents: (b * 46 + rnd.nextDouble() * 3).round(),
          lit: max(0.2, min(1.0, 1 - b * 0.65 + (rnd.nextDouble() - 0.5) * 0.25)),
          cctv: cctv,
          cctvOk: ok,
        ));
      }
    }
    return out;
  }
}
