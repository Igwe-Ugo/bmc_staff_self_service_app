// lib/features/stats/stats.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/network/models/widget.dart';
import '../../core/network/provider/widget.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final DateTime _currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Ensure data is loaded for the current month
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AvailabilityProvider>().changeMonth(_currentMonth);
      final rotaProvider = context.read<RotaProvider>();
      rotaProvider.loadShiftsForMonth(context, _currentMonth);
      final leaveProvider = context.read<LeaveProvider>();
      leaveProvider.loadRequestsForMonth(_currentMonth);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: context.read<AvailabilityProvider>(),
        ),
        ChangeNotifierProvider.value(value: context.read<LeaveProvider>()),
        ChangeNotifierProvider.value(value: context.read<RotaProvider>()),
      ],
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, size: 18),
          ),
          title: const Text(
            'Statistics',
            style: TextStyle(
              fontFamily: 'Lexend',
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMonthHeader(),
              const SizedBox(height: 20),
              _buildAvailabilityStats(context),
              const SizedBox(height: 24),
              _buildLeaveStats(context),
              const SizedBox(height: 24),
              _buildRotaStats(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── Month Header ──────────────────────────────────────────────────────────
  Widget _buildMonthHeader() {
    final monthFormat = DateFormat('MMMM yyyy');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.calendar,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            monthFormat.format(_currentMonth),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const Spacer(),
          Text(
            'Current Month',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Lexend',
              color: Theme.of(context).primaryColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ── AVAILABILITY STATS ───────────────────────────────────────────────────
  Widget _buildAvailabilityStats(BuildContext context) {
    final provider = context.watch<AvailabilityProvider>();

    // Filter slots belonging strictly to the displayed current month
    final currentMonthSlots = provider.slots.where((slot) {
      return slot.date.year == _currentMonth.year &&
          slot.date.month == _currentMonth.month;
    }).toList();

    // Count slots by status
    int countStatus(HrAvailabilityStatus status) {
      return currentMonthSlots.where((s) => s.availability == status).length;
    }

    final stats = [
      StatData(
        label: 'Available',
        shortLabel: 'Avail',
        value: countStatus(HrAvailabilityStatus.available),
        color: HrAvailabilityStatus.available.color,
        count: countStatus(HrAvailabilityStatus.available),
      ),
      StatData(
        label: 'Unavailable',
        shortLabel: 'Unavail',
        value: countStatus(HrAvailabilityStatus.unavailable),
        color: HrAvailabilityStatus.unavailable.color,
        count: countStatus(HrAvailabilityStatus.unavailable),
      ),
      StatData(
        label: 'Preferred',
        shortLabel: 'Pref',
        value: countStatus(HrAvailabilityStatus.preferred),
        color: HrAvailabilityStatus.preferred.color,
        count: countStatus(HrAvailabilityStatus.preferred),
      ),
      StatData(
        label: 'Tentative',
        shortLabel: 'Tent',
        value: countStatus(HrAvailabilityStatus.tentative),
        color: HrAvailabilityStatus.tentative.color,
        count: countStatus(HrAvailabilityStatus.tentative),
      ),
    ];

    final total = stats.fold(0, (sum, s) => sum + s.value);
    final maxValue = stats.fold(0, (max, s) => s.value > max ? s.value : max);

    return _buildStatCard(
      context: context,
      title: 'Availability',
      stats: stats,
      total: total,
      maxValue: maxValue,
      icon: Icons.check_circle_outline,
      color: Theme.of(context).primaryColor,
    );
  }

  // ── LEAVE STATS ───────────────────────────────────────────────────────────
  Widget _buildLeaveStats(BuildContext context) {
    final provider = context.watch<LeaveProvider>();
    final monthRequests = provider.requestsForMonth(_currentMonth);

    // Always show all four statuses, even at zero — matches the Rota stat card pattern
    final stats = HrLeaveRequestStatus.values.map((status) {
      final matching = monthRequests.where((r) => r.status == status).toList();
      final totalDays = matching.fold(0, (sum, r) => sum + r.totalDays);
      final label = status.label;
      return StatData(
        label: label,
        shortLabel: label.length >= 3
            ? label.substring(0, 3).toUpperCase()
            : label.toUpperCase(),
        value: totalDays,
        color: status.color,
        count: matching.length,
      );
    }).toList();

    final total = stats.fold(0, (sum, s) => sum + s.value);
    final maxValue = stats.fold(0, (max, s) => s.value > max ? s.value : max);

    return _buildStatCard(
      context: context,
      title: 'Leave',
      stats: stats,
      total: total,
      maxValue: maxValue,
      icon: Icons.event_note,
      color: const Color(0xFFF59E0B),
    );
  }

  // ── ROTA STATS ────────────────────────────────────────────────────────────
  Widget _buildRotaStats(BuildContext context) {
    final provider = context.watch<RotaProvider>();
    final events = provider.rotaEvents;

    // Filter only current month's events
    final monthEvents = events
        .where(
          (e) =>
              e.date.month == _currentMonth.month &&
              e.date.year == _currentMonth.year,
        )
        .toList();

    final Map<ShiftType, int> counts = {};
    for (final e in monthEvents) {
      counts[e.type] = (counts[e.type] ?? 0) + 1;
    }

    // Ensure all shift types are represented
    final allTypes = ShiftType.values;
    final stats = allTypes.map((type) {
      final count = counts[type] ?? 0;
      return StatData(
        label: type.label,
        shortLabel: type.label.substring(0, 3).toUpperCase(),
        value: count,
        color: type.color,
        count: count,
      );
    }).toList();

    final total = monthEvents.length;
    final maxValue = stats.fold(0, (max, s) => s.value > max ? s.value : max);

    return _buildStatCard(
      context: context,
      title: 'Rota',
      stats: stats,
      total: total,
      maxValue: maxValue,
      icon: Icons.schedule,
      color: const Color(0xFF22C55E),
    );
  }

  // ── Reusable Card ─────────────────────────────────────────────────────────
  Widget _buildStatCard({
    required String title,
    required List<StatData> stats,
    required int total,
    required int maxValue,
    required BuildContext context,
    required IconData icon,
    required Color color,
  }) {
    // Calculate percentages for circular progress
    final Map<String, double> percentages = {};
    if (total > 0) {
      for (final s in stats) {
        percentages[s.label] = (s.value / total) * 100;
      }
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lexend',
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Total: $total',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Circular Progress Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: stats.map((s) {
              final percentage = percentages[s.label] ?? 0;
              return _buildCircularProgress(
                label: s.shortLabel,
                value: s.value,
                total: total,
                color: s.color,
                percentage: percentage,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Bar Chart
          _buildBarChart(stats, maxValue),
          const SizedBox(height: 16),

          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: stats.map((s) => _legendItem(s)).toList(),
          ),
        ],
      ),
    );
  }

  // ── Circular Progress ─────────────────────────────────────────────────────
  Widget _buildCircularProgress({
    required String label,
    required int value,
    required int total,
    required Color color,
    required double percentage,
  }) {
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: total > 0 ? value / total : 0,
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 6,
              ),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8E8E93),
          ),
        ),
        Text(
          '${percentage.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // ── Bar Chart ─────────────────────────────────────────────────────────────
  Widget _buildBarChart(List<StatData> stats, int maxValue) {
    final barGroups = stats.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.value.toDouble(),
            color: data.color,
            width: 30,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxValue.toDouble(),
              color: data.color.withOpacity(0.1),
            ),
          ),
        ],
      );
    }).toList();

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue > 0 ? maxValue * 1.2 : 10,
          barGroups: barGroups,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= stats.length) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      stats[index].shortLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            horizontalInterval: maxValue > 0
                ? (maxValue / 5).ceilToDouble()
                : 2,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
              left: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.grey[800]!,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${stats[group.x].label}\n${rod.toY.toInt()}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ── Legend Item ───────────────────────────────────────────────────────────
  Widget _legendItem(StatData item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '${item.label} (${item.value})',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ── Data Model ──────────────────────────────────────────────────────────────
class StatData {
  final String label;
  final String shortLabel;
  final int value;
  final Color color;
  final int count;

  const StatData({
    required this.label,
    required this.shortLabel,
    required this.value,
    required this.color,
    this.count = 0,
  });
}
