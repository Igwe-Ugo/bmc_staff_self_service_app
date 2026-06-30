import 'package:bmc_app/features/common/router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/network/models/widget.dart';
import '../../core/network/provider/widget.dart';

class RotaSummary extends StatelessWidget {
  const RotaSummary({super.key});

  // Helper method to convert 24-hour time ranges to a clean 12-hour AM/PM format
  String _convertTo12Hour(String timeStr) {
    if (timeStr.isEmpty) return '';
    if (timeStr.contains('-')) {
      final parts = timeStr.split('-');
      if (parts.length == 2) {
        return '${_formatSingleTime(parts[0].trim())} - ${_formatSingleTime(parts[1].trim())}';
      }
    }
    return _formatSingleTime(timeStr);
  }

  String _formatSingleTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final tempDate = DateTime(2026, 1, 1, hour, minute);
        return DateFormat('h:mm a').format(tempDate).toLowerCase();
      }
    } catch (_) {}
    return time;
  }

  @override
  Widget build(BuildContext context) {
    final rotaProvider = context.watch<RotaProvider>();
    final userProvider = context.watch<UserProvider>();
    final now = DateTime.now();

    // Filter to isolate ONLY the current logged-in user's shifts for this current month
    final myMonthlyShifts = rotaProvider.rotaEvents.where((event) {
      final isCurrentMonth = event.date.month == now.month && event.date.year == now.year;
      return isCurrentMonth;
    }).toList();

    // Sort chronologically by day
    myMonthlyShifts.sort((a, b) => a.date.compareTo(b.date));

    final totalCount = myMonthlyShifts.length;
    final displayShifts = myMonthlyShifts.take(7).toList();
    final hasMore = totalCount > 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row: "This month (Count)"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).brightness == Brightness.light ? Colors.black87 : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lexend',
                    ),
                    children: [
                      const TextSpan(text: 'My Rota '),
                      const TextSpan(text: '| '),
                      const TextSpan(text: 'This month '),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    totalCount.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Lexend',
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            if (hasMore)
              GestureDetector(
                onTap: () => GoRouter.of(context).push(BMCRouter.rotaPath),
                child: Row(
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // If no shifts are assigned for this month
        if (displayShifts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Icon(Iconsax.calendar_1, size: 100, color: Colors.grey.shade400),
                const SizedBox(height: 20),
                const Text(
                  'No shifts scheduled for this month.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
        // ── FIX: Use a SingleChildScrollView with Row instead of ListView ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: displayShifts.map((event) {
                final baseColor = event.type.color;
                return Container(
                  width: 250, // Fixed width for each card
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: baseColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: baseColor.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date block
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DateFormat('EEE').format(event.date),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: baseColor.withOpacity(0.8),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd').format(event.date),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: baseColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Shift details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.type.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: baseColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Iconsax.hospital, size: 12, color: baseColor.withOpacity(0.7)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        userProvider.deptName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  event.endTime.isNotEmpty
                                      ? _convertTo12Hour(event.endTime)
                                      : _convertTo12Hour(event.startTime),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: baseColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

        // "View More" button placed right after the 7 shifts list if items remain
        if (hasMore) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => context.push('/rota'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                backgroundColor: Theme.of(context).cardColor,
              ),
              child: Text(
                'View ${totalCount - 7} More Shifts',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
        ]
      ],
    );
  }
}
