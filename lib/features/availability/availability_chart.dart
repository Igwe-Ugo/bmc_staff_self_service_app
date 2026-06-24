import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/network/models/availability_model.dart';

class AvailabilityChart extends StatelessWidget {
  final Map<HrAvailabilityStatus, Map<int, int>> chartData;

  const AvailabilityChart({super.key, required this.chartData});

  // Aggregate total days per status for the current month
  Map<HrAvailabilityStatus, int> _getTotals() {
    final totals = <HrAvailabilityStatus, int>{};

    for (final status in HrAvailabilityStatus.values) {
      final dailyMap = chartData[status] ?? {};
      final totalDays = dailyMap.values.fold(0, (sum, count) => sum + count);
      totals[status] = totalDays;
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final totals = _getTotals();

    final statuses = [
      HrAvailabilityStatus.available,
      HrAvailabilityStatus.unavailable,
      HrAvailabilityStatus.preferred,
      HrAvailabilityStatus.tentative,
    ];

    final barGroups = statuses.asMap().entries.map((entry) {
      final index = entry.key;
      final status = entry.value;
      final value = totals[status] ?? 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value.toDouble(),
            color: status.color,
            width: 28,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();

    return Column(
      children: [
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: statuses.map((s) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 6,
                  decoration: BoxDecoration(
                    color: s.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  s.label,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Bar Chart
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (totals.values.fold(0, (a, b) => a + b) * 1.2).clamp(10.0, 100.0),
              barGroups: barGroups,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= statuses.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          statuses[index].label,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                    reservedSize: 40,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 5,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10, color: Color(0xFF8E8E93)),
                    ),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 5,
                getDrawingHorizontalLine: (value) => const FlLine(
                  color: Color(0xFFF2F2F7),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final status = statuses[group.x.toInt()];
                    return BarTooltipItem(
                      '${status.label}\n',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: '${rod.toY.toInt()} days',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
