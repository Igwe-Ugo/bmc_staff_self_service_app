import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/network/models/availability_model.dart';

class AvailabilityChart extends StatelessWidget {
  final Map<HrAvailabilityStatus, Map<int, int>> chartData;

  const AvailabilityChart({super.key, required this.chartData});

  List<FlSpot> _spots(HrAvailabilityStatus status) {
    final map = chartData[status] ?? {};
    if (map.isEmpty) return [const FlSpot(0, 0)];
    return map.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  @override
  Widget build(BuildContext context) {
    // Only show the 3 main statuses in the chart legend
    final legendStatuses = [
      HrAvailabilityStatus.available,
      HrAvailabilityStatus.unavailable,
      HrAvailabilityStatus.preferred,
    ];

    return Column(
      children: [
        // ── Legend ────────────────────────────────────────────────────────────
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: legendStatuses.map((s) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24, height: 3,
                  decoration: BoxDecoration(
                    color: s.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  s.label,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF8E8E93)),
                ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // ── Chart ─────────────────────────────────────────────────────────────
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                const FlLine(color: Color(0xFFF2F2F7), strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 10,
                    getTitlesWidget: (v, _) => Text(
                      '${v.toInt()}',
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF8E8E93)),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 5,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString().padLeft(2, '0'),
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF8E8E93)),
                    ),
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minX: 1, maxX: 31,
              minY: 0, maxY: 50,
              lineBarsData: legendStatuses
                  .map((s) => _line(s))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  LineChartBarData _line(HrAvailabilityStatus status) => LineChartBarData(
    spots: _spots(status),
    isCurved: true,
    color: status.color,
    barWidth: 2,
    isStrokeCapRound: true,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(
      show: true,
      color: status.color.withOpacity(0.05),
    ),
  );
}
