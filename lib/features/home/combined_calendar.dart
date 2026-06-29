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
  State<CombinedCarouselCalendar> createState() => _CombinedCarouselCalendarState();
}

class _CombinedCarouselCalendarState extends State<CombinedCarouselCalendar> {
  // Explicitly initialize the PageController to maintain robust state management across hot reloads
  final PageController _pageController = PageController(initialPage: 0);
  int _currentIndex = 0;

  late DateTime _currentMonthAnchor;
  late DateTime _nextMonthAnchor;

  @override
  void initState() {
    super.initState();
    _computeAnchorMonths();
  }

  @override
  void dispose() {
    // Safely dispose to avoid framework lookup issues during widget tree unmounting
    _pageController.dispose();
    super.dispose();
  }

  void _computeAnchorMonths() {
    final now = DateTime.now();
    _currentMonthAnchor = DateTime(now.year, now.month, 1);
    _nextMonthAnchor = DateTime(now.year, now.month + 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    _computeAnchorMonths();

    final rotaEvents = context.watch<RotaProvider>().rotaEvents;
    final leaveRequests = context.watch<LeaveProvider>().myRequests;
    final availabilitySlots = context.watch<AvailabilityProvider>().slots;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
                child: Text("My Schedule Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
            const SizedBox(height: 10,),
            // 1. Dynamic Carousel Slider Control Header
            _buildHeaderView(),
            const SizedBox(height: 10),

            // 2. Carousel Window Containment
            SizedBox(
              height: 350, // Expanded height allowance for calendar rows + trailing status labels
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                children: [
                  _buildCalendarPage(
                    targetMonth: _currentMonthAnchor,
                    rotaEvents: rotaEvents,
                    leaveRequests: leaveRequests,
                    availabilitySlots: [],
                    isCurrentMonth: true,
                  ),
                  _buildCalendarPage(
                    targetMonth: _nextMonthAnchor,
                    rotaEvents: [],
                    leaveRequests: leaveRequests,
                    availabilitySlots: availabilitySlots,
                    isCurrentMonth: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderView() {
    final activeMonth = _currentIndex == 0 ? _currentMonthAnchor : _nextMonthAnchor;
    final title = DateFormat('MMMM yyyy').format(activeMonth);
    final workflowSubtitle = _currentIndex == 0 ? 'Rota & Approved Leave' : 'Availability & Leave';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _currentIndex == 1
            ? IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.blueAccent),
          onPressed: () {
            if (_pageController.hasClients) {
              _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            }
          },
        )
            : const SizedBox(width: 48),
        Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Lexend')),
            const SizedBox(height: 2),
            Text(workflowSubtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          ],
        ),
        _currentIndex == 0
            ? IconButton(
          icon: const Icon(Icons.chevron_right, color: Colors.blueAccent),
          onPressed: () {
            if (_pageController.hasClients) {
              _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            }
          },
        )
            : const SizedBox(width: 48),
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
    final startDay = DateTime(targetMonth.year, targetMonth.month, 1);
    final endDay = DateTime(targetMonth.year, targetMonth.month + 1, 0);

    // Compute month analytics to determine if data exists
    final monthLeaves = leaveRequests.where((l) {
      if (l.status != HrLeaveRequestStatus.approved) return false;
      final start = DateTime.tryParse(l.startDate) ?? DateTime.now();
      return start.month == targetMonth.month && start.year == targetMonth.year;
    }).toList();

    final monthRotas = rotaEvents.where((e) => e.date.month == targetMonth.month && e.date.year == targetMonth.year).toList();
    final monthAvailabilities = availabilitySlots.where((s) => s.date.month == targetMonth.month && s.date.year == targetMonth.year).toList();

    final bool isEntireMonthEmpty = isCurrentMonth
        ? (monthLeaves.isEmpty && monthRotas.isEmpty)
        : (monthLeaves.isEmpty && monthAvailabilities.isEmpty);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The calendar always remains rendered and interactive
        TableCalendar(
          firstDay: startDay,
          lastDay: endDay,
          focusedDay: targetMonth,
          calendarFormat: CalendarFormat.month,
          headerVisible: false,
          availableGestures: AvailableGestures.horizontalSwipe,
          rowHeight: 54,
          calendarStyle: const CalendarStyle(
            todayDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
          ),
          onDaySelected: (selectedDay, focusedDay) {
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

              // 1. Leave Check (Approved)
              final matchedLeave = leaveRequests.any((leave) {
                if (leave.status != HrLeaveRequestStatus.approved) return false;
                final start = DateTime.tryParse(leave.startDate) ?? DateTime.now();
                final end = DateTime.tryParse(leave.endDate) ?? DateTime.now();
                return !date.isBefore(DateTime(start.year, start.month, start.day)) &&
                    !date.isAfter(DateTime(end.year, end.month, end.day));
              });

              if (matchedLeave) {
                chips.add(_buildCellChip(label: 'Leave', textCol: Colors.white, bgCol: Colors.orange.shade700));
              }

              // 2. Rota or Availability Check
              if (isCurrentMonth) {
                final dayShifts = rotaEvents.where((e) => isSameDay(e.date, date));
                if (dayShifts.isNotEmpty) {
                  final shift = dayShifts.first;
                  chips.add(_buildCellChip(label: shift.type.label, textCol: shift.type.color, bgCol: shift.type.bgColor));
                }
              } else {
                final dayAvailabilities = availabilitySlots.where((s) => isSameDay(s.date, date));
                if (dayAvailabilities.isNotEmpty) {
                  final slot = dayAvailabilities.first;
                  chips.add(_buildCellChip(label: slot.availability.label, textCol: Colors.white, bgCol: slot.availability.color));
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

        // Bottom Write-up section (only shown if the month has no schedules)
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

  Widget _buildCellChip({required String label, required Color textCol, required Color bgCol}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(color: bgCol, borderRadius: BorderRadius.circular(4)),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: textCol),
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
    final activeShifts = rotaEvents.where((e) => isSameDay(e.date, selectedDay)).toList();
    final activeAvailabilities = availabilitySlots.where((s) => isSameDay(s.date, selectedDay)).toList();
    final activeLeaves = leaveRequests.where((leave) {
      if (leave.status != HrLeaveRequestStatus.approved) return false;
      final start = DateTime.tryParse(leave.startDate) ?? DateTime.now();
      final end = DateTime.tryParse(leave.endDate) ?? DateTime.now();
      return !selectedDay.isBefore(DateTime(start.year, start.month, start.day)) &&
          !selectedDay.isAfter(DateTime(end.year, end.month, end.day));
    }).toList();

    final bool hasData = activeShifts.isNotEmpty || activeAvailabilities.isNotEmpty || activeLeaves.isNotEmpty;

    if (!hasData) {
      ScaffoldMessenger.of(context).clearSnackBars();
      showMessage('No information for the day chosen', context, status: MessageStatus.info);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(DateFormat('EEEE, MMMM d, yyyy').format(selectedDay), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activeLeaves.isNotEmpty) ...[
              const Text('Leaves', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange)),
              ...activeLeaves.map((l) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('• ${l.leaveType.toUpperCase()} Leave (Approved)', style: const TextStyle(fontSize: 13)),
              )),
              const Divider(),
            ],
            if (isCurrentMonth && activeShifts.isNotEmpty) ...[
              const Text('Assigned Shifts', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ...activeShifts.map((s) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: CircleAvatar(radius: 6, backgroundColor: s.type.color),
                title: Text(s.type.label, style: TextStyle(fontWeight: FontWeight.bold, color: s.type.color)),
                subtitle: Text('${s.ward} • ${s.timeRange.isNotEmpty ? s.timeRange : s.startTime}'),
              )),
            ],
            if (!isCurrentMonth && activeAvailabilities.isNotEmpty) ...[
              const Text('Your Availability Slots', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ...activeAvailabilities.map((a) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: CircleAvatar(radius: 6, backgroundColor: a.availability.color),
                title: Text(a.availability.label, style: TextStyle(fontWeight: FontWeight.bold, color: a.availability.color)),
                subtitle: Text('Time Frame Slot: ${a.timeSlot.label}'),
              )),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
