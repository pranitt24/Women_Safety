import 'package:flutter/material.dart';

import '../data/zones.dart';
import '../main.dart';
import '../state.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final z = ZoneData.byId(app.selZone);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Safety map', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Zones only, with no names or addresses. The police decide which zones are published.'),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 352 / 324,
          child: LayoutBuilder(builder: (context, box) {
            return GestureDetector(
              onTapDown: (d) {
                // Map pixel -> cell. Painter reserves a 16/352 margin.
                final sx = box.maxWidth / 352, sy = box.maxHeight / 324;
                final x = d.localPosition.dx / sx - 16, y = d.localPosition.dy / sy - 16;
                final c = (x / HeatMapPainter.cw).floor(), r = (y / HeatMapPainter.ch).floor();
                if (c >= 0 && c < ZoneData.cols && r >= 0 && r < ZoneData.rows) {
                  app.update(() => app.selZone = 'ABCDEFGH'[c] + '${r + 1}');
                }
              },
              child: CustomPaint(painter: HeatMapPainter(Theme.of(context).colorScheme)),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Text('Time of night', style: Theme.of(context).textTheme.titleSmall),
          const Spacer(),
          Text(hourLabel(app.hour)),
        ]),
        Slider(
          min: 18,
          max: 26,
          divisions: 8,
          value: app.hour.toDouble(),
          onChanged: (v) => app.update(() => app.hour = v.round()),
        ),
        Wrap(spacing: 8, children: [
          FilterChip(
              label: const Text('Police booths'),
              selected: app.showBooths,
              onSelected: (v) => app.update(() => app.showBooths = v)),
          FilterChip(
              label: const Text('CCTV'),
              selected: app.showCctv,
              onSelected: (v) => app.update(() => app.showCctv = v)),
          FilterChip(
              label: const Text('Street lights'),
              selected: app.showLights,
              onSelected: (v) => app.update(() => app.showLights = v)),
        ]),
        const SizedBox(height: 12),
        _ZoneCard(zone: z),
      ],
    );
  }
}

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({required this.zone});
  final Zone zone;

  @override
  Widget build(BuildContext context) {
    if (!app.published.contains(zone.id)) {
      return Card(
        child: ListTile(
          title: Text('Zone ${zone.id}'),
          subtitle: const Text(
              'Pending police review. The local police have not published details for this zone yet.'),
        ),
      );
    }
    final v = zone.heatAt(app.hour.toDouble());
    final level = v >= .62 ? 'High' : v >= .32 ? 'Moderate' : 'Low';
    final advice = v >= .62
        ? 'Prefer main roads, share your journey and avoid walking alone at this hour.'
        : v >= .32
            ? 'Stay on lit streets and keep your trusted circle updated.'
            : 'Usual precautions apply.';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(
                    'Zone ${zone.id}${zone.id == ZoneData.userZone ? ' · you are here' : ''}',
                    style: Theme.of(context).textTheme.titleMedium)),
            Chip(label: Text('$level at ${hourLabel(app.hour)}')),
          ]),
          _kv('Reports, last 90 days', '${zone.incidents}'),
          _kv('Busiest hour', hourLabel(zone.peak.round())),
          _kv('Street lights working', '${(zone.lit * 10).round()} of 10'),
          _kv('CCTV working', '${zone.cctvOk} of ${zone.cctv}'),
          const SizedBox(height: 8),
          Text(advice),
        ]),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [Text(k), const Spacer(), Text(v)]),
      );
}

class HeatMapPainter extends CustomPainter {
  HeatMapPainter(this.scheme);
  final ColorScheme scheme;
  static const double cw = 42, ch = 44;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 352, sy = size.height / 324;
    canvas.scale(sx, sy);
    canvas.translate(16, 16);

    final land = Paint()..color = scheme.surfaceContainerHighest.withAlpha(110);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 336, 308), const Radius.circular(6)), land);
    // park and river for orientation
    canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(210, 0, 84, 88), const Radius.circular(8)),
        Paint()..color = const Color(0x4D4CAF50));
    final river = Path()
      ..moveTo(0, 262)
      ..cubicTo(70, 240, 130, 298, 210, 270)
      ..cubicTo(260, 255, 316, 244, 336, 254);
    canvas.drawPath(
        river,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11
          ..color = const Color(0x6690CAF9));

    for (final z in ZoneData.zones) {
      final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(z.c * cw + 1, z.r * ch + 1, cw - 2, ch - 2), const Radius.circular(4));
      final published = app.published.contains(z.id);
      final v = z.heatAt(app.hour.toDouble());
      canvas.drawRRect(
          rect,
          Paint()
            ..color = published
                ? kSos.withAlpha((v * 0.88 * 255).round())
                : scheme.outline.withAlpha(90));
      if (z.id == app.selZone) {
        canvas.drawRRect(
            rect,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.2
              ..color = scheme.onSurface);
      }
    }

    final road = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = scheme.outline.withAlpha(150);
    canvas.drawLine(const Offset(0, 88), const Offset(336, 88), road);
    canvas.drawLine(const Offset(0, 176), const Offset(336, 176), road);
    canvas.drawLine(const Offset(126, 0), const Offset(126, 308), road);
    canvas.drawLine(const Offset(252, 0), const Offset(252, 308), road);

    if (app.showCctv) {
      for (final z in ZoneData.zones) {
        for (var i = 0; i < z.cctv; i++) {
          final ok = i < z.cctvOk;
          final r = Rect.fromLTWH(z.c * cw + cw - 14 - i * 11, z.r * ch + ch - 14, 8, 8);
          canvas.drawRect(r, Paint()..color = ok ? kAccent : scheme.surface);
          canvas.drawRect(
              r,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.5
                ..color = ok ? kAccent : kSos);
        }
      }
    }
    if (app.showBooths) {
      for (final id in ZoneData.booths) {
        final z = ZoneData.byId(id);
        final c = Offset(z.c * cw + cw / 2, z.r * ch + ch / 2);
        canvas.drawCircle(c, 9, Paint()..color = scheme.onSurface);
        final tp = TextPainter(
          text: TextSpan(text: 'P', style: TextStyle(color: scheme.surface, fontSize: 11, fontWeight: FontWeight.w700)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
      }
    }

    final u = ZoneData.byId(ZoneData.userZone);
    final uc = Offset(u.c * cw + cw / 2, u.r * ch + ch / 2);
    canvas.drawCircle(uc, 11, Paint()..color = kAccent.withAlpha(70));
    canvas.drawCircle(uc, 5.5, Paint()..color = kAccent);
    canvas.drawCircle(
        uc,
        5.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant HeatMapPainter old) => true; // cheap; repaints on state change
}
