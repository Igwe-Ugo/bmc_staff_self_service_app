import 'package:bmc_app/features/common/widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/network/models/availability_model.dart';
import '../../../core/network/provider/availability_provider.dart';
import '../../../core/network/provider/user_provider.dart';
import '../../../features/common/show_message.dart';

class WeeklyAvailabilityWidget extends StatefulWidget {
  const WeeklyAvailabilityWidget({super.key});

  @override
  State<WeeklyAvailabilityWidget> createState() => _WeeklyAvailabilityWidgetState();
}

class _WeeklyAvailabilityWidgetState extends State<WeeklyAvailabilityWidget> {
  DateTime _currentWeekStart = DateTime.now();

  // Get the start of the week (Monday)
  DateTime _getWeekStart(DateTime date) {
    final dayOfWeek = date.weekday;
    // If weekday is Monday (1), subtract 0 days, else subtract (weekday - 1) days
    final daysToSubtract = dayOfWeek - 1;
    return date.subtract(Duration(days: daysToSubtract));
  }

  // Get the week dates (Monday to Sunday)
  List<DateTime> _getWeekDates(DateTime weekStart) {
    return List.generate(7, (index) => weekStart.add(Duration(days: index)));
  }

  // Check if a date is in the current month
  bool _isInCurrentMonth(DateTime date, DateTime currentMonth) {
    return date.year == currentMonth.year && date.month == currentMonth.month;
  }

  // Format date for display
  String _formatDate(DateTime date) {
    return '${date.day}';
  }

  // Format month for header
  String _formatMonth(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AvailabilityProvider>(
      builder: (context, provider, _) {
        final user = context.read<UserProvider>().user;
        final personnelId = user?.personnelId;
        final now = DateTime.now();
        final currentMonth = DateTime(now.year, now.month);

        // Check if provider has slots for the current month
        final monthSlots = provider.slots.where(
                (slot) => slot.date.year == currentMonth.year &&
                slot.date.month == currentMonth.month
        ).toList();

        // Get week dates
        final weekDates = _getWeekDates(_currentWeekStart);

        // Check if any date in the week is in the current month
        final hasDatesInMonth = weekDates.any((date) => _isInCurrentMonth(date, currentMonth));

        // Count availability statuses for the week
        Map<HrAvailabilityStatus, int> weeklyStatusCount = {};
        for (final status in HrAvailabilityStatus.values) {
          weeklyStatusCount[status] = 0;
        }

        for (final date in weekDates) {
          if (_isInCurrentMonth(date, currentMonth)) {
            final slotsForDay = provider.slotsForDate(date);
            if (slotsForDay.isNotEmpty) {
              // Count each slot's status
              for (final slot in slotsForDay) {
                weeklyStatusCount[slot.availability] =
                    (weeklyStatusCount[slot.availability] ?? 0) + 1;
              }
            }
          }
        }

        // Get statuses that have counts
        final availableStatuses = weeklyStatusCount.entries
            .where((entry) => entry.value > 0)
            .map((entry) => entry.key)
            .toList();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with month and view all button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatMonth(currentMonth),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Navigation arrows
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
                          });
                        },
                        icon: const Icon(Icons.chevron_left),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 24,
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
                          });
                        },
                        icon: const Icon(Icons.chevron_right),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 24,
                      ),
                      const SizedBox(width: 8),
                      // View All button
                      TextButton(
                        onPressed: () => GoRouter.of(context).push(BMCRouter.availabilityPath),
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status indicators
              if (availableStatuses.isNotEmpty) ...[
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: availableStatuses.map((status) {
                    final count = weeklyStatusCount[status] ?? 0;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: status.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${status.label} ($count)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ] else ...[
                const Text(
                  'No availability set for this week',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8E8E93),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Days of week header
              Row(
                children: weekDates.map((date) {
                  final isCurrentMonth = _isInCurrentMonth(date, currentMonth);
                  final isToday = date.year == now.year &&
                      date.month == now.month &&
                      date.day == now.day;

                  return Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Text(
                            _getDayOfWeek(date),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isCurrentMonth
                                  ? (isToday ? Theme.of(context).primaryColor : const Color(0xFF8E8E93))
                                  : const Color(0xFFC7C7CC),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Day number with availability indicator
                          _buildDayCell(
                            date: date,
                            provider: provider,
                            isCurrentMonth: isCurrentMonth,
                            isToday: isToday,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayCell({
    required DateTime date,
    required AvailabilityProvider provider,
    required bool isCurrentMonth,
    required bool isToday,
  }) {
    final slots = provider.slotsForDate(date);
    final hasSlots = slots.isNotEmpty;
    Color? backgroundColor;
    Color textColor = isCurrentMonth ? Colors.black : const Color(0xFFC7C7CC);

    if (hasSlots && isCurrentMonth) {
      // Use the first slot's color for background
      final status = slots.first.availability;
      backgroundColor = status.color.withOpacity(0.2);
      textColor = status.color;
    }

    if (isToday) {
      backgroundColor = Theme.of(context).primaryColor;
      textColor = Colors.white;
    }

    return GestureDetector(
      onTap: () {
        if (!isCurrentMonth) {
          showMessage(
            'This date is not in the current month',
            context,
            status: MessageStatus.info,
            title: 'Info',
          );
          return;
        }
        _showDayAvailabilityDialog(date, slots, provider);
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: isToday ? Border.all(
            color: Theme.of(context).primaryColor,
            width: 2,
          ) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '${date.day}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }

  String _getDayOfWeek(DateTime date) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[date.weekday - 1];
  }

  void _showDayAvailabilityDialog(
      DateTime date,
      List<HrAvailabilitySlot> slots,
      AvailabilityProvider provider,
      ) {
    if (slots.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              _formatFullDate(date),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 48,
                  color: Color(0xFF8E8E93),
                ),
                SizedBox(height: 16),
                Text(
                  'No availability for this day.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
      return;
    }

    // Show availability details
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            _formatFullDate(date),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: slots.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (ctx, index) {
                final slot = slots[index];
                return ListTile(
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
                    ),
                  ),
                  subtitle: Text(slot.timeSlot.label),
                  trailing: const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: Color(0xFF8E8E93),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    // Navigate to slot detail or edit
                    // You can call your existing _showSlotDetailDialog here
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _formatFullDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
