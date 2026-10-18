import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/alert_model.dart';
import '../../theme/theme.dart';

class PoliceKpiTiles extends StatelessWidget {
  const PoliceKpiTiles({
    super.key,
    required this.alerts,
    required this.totalIncidents,
    required this.highRiskCount,
  });

  final List<SosAlert> alerts;
  final int totalIncidents;
  final int highRiskCount;

  @override
  Widget build(BuildContext context) {
    final activeAlerts = alerts.where((a) => a.isActive).length;
    final dispatchedUnits = alerts.where((a) => a.status == 'dispatched').length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _kpiCard(
              context,
              title: 'Active Alerts',
              value: '$activeAlerts',
              subtitle: activeAlerts > 0 ? 'Requires immediate response' : 'No active distress calls',
              color: activeAlerts > 0 ? kSos : kSafeGreen,
              icon: Icons.notifications_active_outlined,
              isWide: isWide,
            ),
            _kpiCard(
              context,
              title: 'Patrol Units Dispatched',
              value: '$dispatchedUnits',
              subtitle: 'PCR vans on active intercept',
              color: kAccent,
              icon: Icons.local_police_outlined,
              isWide: isWide,
            ),
            _kpiCard(
              context,
              title: 'Avg. Response Time',
              value: '3.8 min',
              subtitle: 'Control room target: < 5 min',
              color: Colors.blue.shade700,
              icon: Icons.timer_outlined,
              isWide: isWide,
            ),
            _kpiCard(
              context,
              title: 'High Risk Zones',
              value: '$highRiskCount',
              subtitle: 'Zones > 0.60 composite risk',
              color: Colors.deepOrange,
              icon: Icons.warning_amber_outlined,
              isWide: isWide,
            ),
            _kpiCard(
              context,
              title: 'Total Demo Reports',
              value: '$totalIncidents',
              subtitle: '90d aggregate crowd data',
              color: Colors.purple.shade700,
              icon: Icons.analytics_outlined,
              isWide: isWide,
            ),
          ],
        );
      },
    );
  }

  Widget _kpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
    required bool isWide,
  }) {
    return Container(
      width: isWide ? 220 : 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(50), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.bricolageGrotesque(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
