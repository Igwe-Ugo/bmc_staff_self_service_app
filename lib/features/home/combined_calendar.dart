import 'package:bmc_app/features/common/widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/network/models/widget.dart'; // RotaEvent, ShiftType
import '../../core/network/provider/widget.dart'; // RotaProvider

class CombinedCarouselCalendar extends StatefulWidget {
  const CombinedCarouselCalendar({super.key});

  @override
  State<CombinedCarouselCalendar> createState() =>
      _CombinedCarouselCalendarState();
}

class _CombinedCarouselCalendarState extends State<CombinedCarouselCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final rotaEvents = context.watch<RotaProvider>().rotaEvents;
    final leaveRequests = context.watch<LeaveProvider>().myRequests;
    final availabilitySlots = context.watch<AvailabilityProvider>().slots;

    final isCurrentMonth =
        _focusedDay.month == DateTime.now().month &&
        _focusedDay.year == DateTime.now().year;

    return Card(
      elevation: 0,
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height * 0.04,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "My Schedule Summary",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            const SizedBox(height: 8),
            _buildHeaderView(isCurrentMonth),
            const SizedBox(height: 8),
            _buildCalendarPage(
              targetMonth: _focusedDay,
              rotaEvents: rotaEvents,
              leaveRequests: leaveRequests,
              availabilitySlots: availabilitySlots,
              isCurrentMonth: isCurrentMonth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderView(bool isCurrentMonth) {
    final title = DateFormat('MMMM yyyy').format(_focusedDay);
    final workflowSubtitle = isCurrentMonth
        ? 'Rota & Approved Leave'
        : 'Availability & Leave';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.blueAccent),
          onPressed: () {
            setState(() {
              _focusedDay = DateTime(
                _focusedDay.year,
                _focusedDay.month - 1,
                1,
              );
            });
          },
        ),
        Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              workflowSubtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Colors.blueAccent),
          onPressed: () {
            setState(() {
              _focusedDay = DateTime(
                _focusedDay.year,
                _focusedDay.month + 1,
                1,
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildCalendarPage({
    required DateTime targetMonth,
    required List<RotaEvent> rotaEvents,
    required List<HrLeaveRequest> leaveRequests,
    required List<HrAvailabilitySlot> availabilitySlots,
    required bool isCurrentMonth,
  }) {
    final monthLeaves = leaveRequests.where((l) {
      if (l.status != HrLeaveRequestStatus.approved) return false;
      final start = DateTime.tryParse(l.startDate) ?? DateTime.now();
      return start.month == targetMonth.month && start.year == targetMonth.year;
    }).toList();

    final monthRotas = rotaEvents
        .where(
          (e) =>
              e.date.month == targetMonth.month &&
              e.date.year == targetMonth.year,
        )
        .toList();
    final monthAvailabilities = availabilitySlots
        .where(
          (s) =>
              s.date.month == targetMonth.month &&
              s.date.year == targetMonth.year,
        )
        .toList();

    final bool isEntireMonthEmpty = isCurrentMonth
        ? (monthLeaves.isEmpty && monthRotas.isEmpty)
        : (monthLeaves.isEmpty && monthAvailabilities.isEmpty);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2025, 1, 1),
          lastDay: DateTime.utc(2070, 1, 1),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarFormat: CalendarFormat.month,
          headerVisible: false, // Managed by custom header
          rowHeight: 54,
          calendarStyle: const CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
            ),
          ),
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            _handleDayTap(
              selectedDay: selectedDay,
              rotaEvents: rotaEvents,
              leaveRequests: leaveRequests,
              availabilitySlots: availabilitySlots,
              isCurrentMonth: isCurrentMonth,
            );
          },
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, _) {
              final List<Widget> chips = [];

              final matchedLeave = leaveRequests.any((leave) {
                if (leave.status != HrLeaveRequestStatus.approved) return false;
                final start =
                    DateTime.tryParse(leave.startDate) ?? DateTime.now();
                final end = DateTime.tryParse(leave.endDate) ?? DateTime.now();
                return !date.isBefore(
                      DateTime(start.year, start.month, start.day),
                    ) &&
                    !date.isAfter(DateTime(end.year, end.month, end.day));
              });

              if (matchedLeave) {
                final matchingLeave = leaveRequests.firstWhere((leave) {
                  if (leave.status != HrLeaveRequestStatus.approved) {
                    return false;
                  }
                  final start =
                      DateTime.tryParse(leave.startDate) ?? DateTime.now();
                  final end =
                      DateTime.tryParse(leave.endDate) ?? DateTime.now();
                  return !date.isBefore(
                        DateTime(start.year, start.month, start.day),
                      ) &&
                      !date.isAfter(DateTime(end.year, end.month, end.day));
                });

                chips.add(
                  _buildCellChip(
                    label: 'Leave',
                    textCol: Colors.white,
                    bgCol: matchingLeave.status.color,
                  ),
                );
              }

              if (isCurrentMonth) {
                final dayShifts = rotaEvents.where(
                  (e) => isSameDay(e.date, date),
                );
                if (dayShifts.isNotEmpty) {
                  final shift = dayShifts.first;
                  chips.add(
                    _buildCellChip(
                      label: shift.type.label,
                      textCol: shift.type.color,
                      bgCol: shift.type.color.withOpacity(0.1),
                    ),
                  );
                }
              } else {
                final dayAvailabilities = availabilitySlots.where(
                  (s) => isSameDay(s.date, date),
                );
                if (dayAvailabilities.isNotEmpty) {
                  final slot = dayAvailabilities.first;
                  chips.add(
                    _buildCellChip(
                      label: slot.availability.label,
                      textCol: Colors.white,
                      bgCol: slot.availability.color,
                    ),
                  );
                }
              }

              if (chips.isEmpty) return const SizedBox.shrink();

              return Positioned(
                bottom: 1,
                left: 1,
                right: 1,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 1.5,
                  runSpacing: 1,
                  children: chips,
                ),
              );
            },
          ),
        ),
        if (isEntireMonthEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            alignment: Alignment.center,
            child: Text(
              isCurrentMonth
                  ? 'No leaves or rota for this month.'
                  : 'No leaves or availability for this month.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCellChip({
    required String label,
    required Color textCol,
    required Color bgCol,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: bgCol,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 7.5,
          fontWeight: FontWeight.bold,
          color: textCol,
        ),
      ),
    );
  }

  void _handleDayTap({
    required DateTime selectedDay,
    required List<RotaEvent> rotaEvents,
    required List<HrLeaveRequest> leaveRequests,
    required List<HrAvailabilitySlot> availabilitySlots,
    required bool isCurrentMonth,
  }) {
    final activeShifts = rotaEvents
        .where((e) => isSameDay(e.date, selectedDay))
        .toList();
    final activeAvailabilities = availabilitySlots
        .where((s) => isSameDay(s.date, selectedDay))
        .toList();
    final activeLeaves = leaveRequests.where((leave) {
      if (leave.status != HrLeaveRequestStatus.approved) return false;
      final start = DateTime.tryParse(leave.startDate) ?? DateTime.now();
      final end = DateTime.tryParse(leave.endDate) ?? DateTime.now();
      return !selectedDay.isBefore(
            DateTime(start.year, start.month, start.day),
          ) &&
          !selectedDay.isAfter(DateTime(end.year, end.month, end.day));
    }).toList();

    final bool hasData =
        activeShifts.isNotEmpty ||
        activeAvailabilities.isNotEmpty ||
        activeLeaves.isNotEmpty;

    if (!hasData) {
      ScaffoldMessenger.of(context).clearSnackBars();
      showMessage(
        'No information for the day chosen',
        context,
        status: MessageStatus.info,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          DateFormat('EEEE, MMMM d, yyyy').format(selectedDay),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activeLeaves.isNotEmpty) ...[
              Text(
                'Leaves',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: activeLeaves.first.status.color,
                ),
              ),
              ...activeLeaves.map(
                (l) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '• ${l.leaveType.toUpperCase()} Leave (Approved)',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const Divider(),
            ],
            if (isCurrentMonth && activeShifts.isNotEmpty) ...[
              const Text(
                'Assigned Shifts',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              ...activeShifts.map(
                (s) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: CircleAvatar(
                    radius: 6,
                    backgroundColor: s.type.color,
                  ),
                  title: Text(
                    s.type.label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: s.type.color,
                    ),
                  ),
                  subtitle: Text(
                    '${s.ward} • ${s.endTime.isNotEmpty ? s.endTime : s.startTime}',
                  ),
                ),
              ),
            ],
            if (!isCurrentMonth && activeAvailabilities.isNotEmpty) ...[
              const Text(
                'Your Availability Slots',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              ...activeAvailabilities.map(
                (a) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: CircleAvatar(
                    radius: 6,
                    backgroundColor: a.availability.color,
                  ),
                  title: Text(
                    a.availability.label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: a.availability.color,
                    ),
                  ),
                  subtitle: Text('Time Frame Slot: ${a.timeSlot.label}'),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Close',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
