import 'package:bmc_app/features/common/widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/network/models/availability_model.dart';
import '../../../core/network/provider/availability_provider.dart';
import '../../../features/common/show_message.dart';

class WeeklyAvailabilityWidget extends StatefulWidget {
  const WeeklyAvailabilityWidget({super.key});

  @override
  State<WeeklyAvailabilityWidget> createState() => _WeeklyAvailabilityWidgetState();
}

class _WeeklyAvailabilityWidgetState extends State<WeeklyAvailabilityWidget> {
  // Use simple final variables assigned immediately to avoid LateInitializationErrors
  final DateTime _today = DateTime.now();
  late final DateTime _currentWeekStart;

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _getWeekStart(_today);
  }

  // Helper to find the start of the current week (Monday)
  DateTime _getWeekStart(DateTime date) {
    final dayOfWeek = date.weekday;
    final daysToSubtract = dayOfWeek - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysToSubtract));
  }

  // Get the week dates (Monday to Sunday)
  List<DateTime> _getWeekDates(DateTime weekStart) {
    return List.generate(7, (index) => weekStart.add(Duration(days: index)));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final weekDates = _getWeekDates(_currentWeekStart);
    final currentMonthHeader = DateFormat('MMMM yyyy').format(_today);

    return Consumer<AvailabilityProvider>(
      builder: (context, provider, _) {
        final availabilitySlots = provider.slots;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Theme.of(context).cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                    child: Text("My Availability", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                const SizedBox(height: 10,),
                Text(
                  currentMonthHeader,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lexend',
                  ),
                ),
                const SizedBox(height: 16),

                // Inline static weekly row calendar representation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: weekDates.map((date) {
                    final isSelected = _isSameDay(_today, date);

                    // Filter down to get all matching availability records for this specific day block
                    final daySlots = availabilitySlots.where((s) => _isSameDay(s.date, date)).toList();
                    final hasAvailability = daySlots.isNotEmpty;

                    return GestureDetector(
                      onTap: () => _handleDayTap(date, daySlots),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('E').format(date).substring(0, 1), // M, T, W...
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.transparent,
                              border: hasAvailability && !isSelected
                                  ? Border.all(color: daySlots.first.availability.color, width: 1.5)
                                  : null,
                            ),
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Small availability status badge dot under the number cell
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hasAvailability
                                  ? daySlots.first.availability.color
                                  : Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleDayTap(DateTime selectedDay, List<HrAvailabilitySlot> daySlots) {
    // Condition 1: If no availability configuration is found for this day, flash the requested warning snackbar
    if (daySlots.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      showMessage(
        'No availability for this month',
        context,
        status: MessageStatus.warning,
        title: 'Empty Slot',
      );
      return;
    }

    // Condition 2: Bring up detailed structural pop-up container info
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            DateFormat('EEEE, MMMM d').format(selectedDay),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Lexend'),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: daySlots.length,
              itemBuilder: (context, index) {
                final slot = daySlots[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: slot.availability.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    slot.availability.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: slot.availability.color,
                      fontFamily: 'Lexend',
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    slot.timeSlot.label,
                    style: const TextStyle(fontFamily: 'Lexend', fontSize: 12),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Lexend')),
            ),
          ],
        );
      },
    );
  }
}
