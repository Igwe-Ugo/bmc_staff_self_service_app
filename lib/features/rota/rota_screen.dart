import 'package:bmc_app/features/rota/widget.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/network/models/widget.dart';

class RotaScreen extends StatefulWidget {
  const RotaScreen({super.key});

  @override
  State<RotaScreen> createState() => _RotaScreenState();
}

class _RotaScreenState extends State<RotaScreen> {
  RotaFilter  _filter      = RotaFilter.allStatus;
  DateTime    _focusedDay  = DateTime.now();
  DateTime?   _selectedDay;
  bool _dropdownOpen = false;

  // ── Sample data — replace with API ──────────────────────────────────────────
  final List<RotaEvent> _allEvents = [
    RotaEvent(
      id: '1', staffName: 'Ugochukwu Orji', role: 'Nurse', ward: 'Ward 1',
      type: ShiftType.onCall, date: DateTime.now().subtract(const Duration(days: 1)),
      startTime: '6:00pm', endTime: '8:00am',
    ),
    RotaEvent(
      id: '2', staffName: 'Ugochukwu Orji', role: 'Nurse', ward: 'Ward 1',
      type: ShiftType.noShift, date: DateTime.now(),
      startTime: 'All Day', endTime: '',
    ),
    RotaEvent(
      id: '3', staffName: 'Ugochukwu Orji', role: 'Nurse', ward: 'Ward 1',
      type: ShiftType.morning, date: DateTime.now().add(const Duration(days: 1)),
      startTime: '8:00am', endTime: '6:00pm',
    ),
    RotaEvent(
      id: '4', staffName: 'Ugochukwu Orji', role: 'Nurse', ward: 'Ward 1',
      type: ShiftType.night, date: DateTime(DateTime.now().year, DateTime.now().month, 17),
      startTime: '8:00pm', endTime: '6:00am',
    ),
    RotaEvent(
      id: '5', staffName: 'Ugochukwu Orji', role: 'Nurse', ward: 'Ward 1',
      type: ShiftType.morning, date: DateTime(DateTime.now().year, DateTime.now().month, 15),
      startTime: '8:00am', endTime: '6:00pm',
    ),
  ];

  final List<StaffMember> _staffMembers = const [
    StaffMember(id: '1', name: 'Emmanuella Amoah',  employeeId: 'HR-2026-00003'),
    StaffMember(id: '2', name: 'Olakunle Nurse Taiwo', employeeId: 'HR-2026-00003'),
    StaffMember(id: '3', name: 'Olakunle Taiwo',    employeeId: 'HR-2026-00004'),
    StaffMember(id: '4', name: 'Ugochukwu Orji',    employeeId: 'HR-2026-00005'),
    StaffMember(id: '5', name: 'Ugochukwu Igwe',    employeeId: 'HR-2026-00006'),
  ];

  // ── Filtering ────────────────────────────────────────────────────────────────
  List<RotaEvent> get _filtered {
    switch (_filter) {
      case RotaFilter.allStatus:
        return _allEvents;
      case RotaFilter.daily:
        return _allEvents.where((e) =>
            isSameDay(e.date, _selectedDay ?? DateTime.now())).toList();
      case RotaFilter.weekly:
        final now  = DateTime.now();
        final week = now.subtract(Duration(days: now.weekday - 1));
        return _allEvents.where((e) =>
        e.date.isAfter(week.subtract(const Duration(days: 1))) &&
            e.date.isBefore(week.add(const Duration(days: 7)))).toList();
      case RotaFilter.monthly:
        return _allEvents.where((e) =>
        e.date.month == _focusedDay.month &&
            e.date.year  == _focusedDay.year).toList();
      case RotaFilter.yearly:
        return _allEvents.where((e) =>
        e.date.year == _focusedDay.year).toList();
    }
  }

  Set<DateTime> get _markedDays => _filtered
      .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
      .toSet();

  bool _isMarked(DateTime day) =>
      _markedDays.contains(DateTime(day.year, day.month, day.day));

  ShiftType? _shiftTypeForDay(DateTime day) {
    final match = _filtered.where((e) => isSameDay(e.date, day));
    return match.isEmpty ? null : match.first.type;
  }

  // ── Yearly summary counts ─────────────────────────────────────────────────────
  Map<ShiftType, int> get _yearlyCounts {
    final counts = <ShiftType, int>{};
    for (final e in _filtered) {
      counts[e.type] = (counts[e.type] ?? 0) + 1;
    }
    return counts;
  }

  // ── Grouped list ─────────────────────────────────────────────────────────────
  Map<String, List<RotaEvent>> get _groupedEvents {
    final map = <String, List<RotaEvent>>{};
    for (final e in _filtered) {
      final label = e.dayLabel;
      if (label.isNotEmpty) {
        map.putIfAbsent(label, () => []).add(e);
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Yearly summary chips — only shown in yearly view
                        if (_filter == RotaFilter.yearly) ...[
                          YearlySummaryCard(counts: _yearlyCounts),
                          const SizedBox(height: 16),
                        ],

                        _buildCalendar(),
                        const SizedBox(height: 20),
                        _buildEventList(),
                        const SizedBox(height: 20),
                        _buildSwapButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Dropdown overlay
            if (_dropdownOpen) _buildDropdown(),
          ],
        ),
      ),
    );
  }

  Color _scaffoldBg(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.light
          ? Theme.of(ctx).hoverColor
          : Theme.of(ctx).scaffoldBackgroundColor;

  Color _cardBg(BuildContext ctx) =>
      Theme.of(context).cardColor;

  // ── App Bar ──────────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text('Rota', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _dropdownOpen = !_dropdownOpen),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E5EA)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _filter.label,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _dropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dropdown ─────────────────────────────────────────────────────────────────
  Widget _buildDropdown() {
    return Positioned(
      top: 52, right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 160,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: RotaFilter.values.map((f) {
              final selected = f == _filter;
              return GestureDetector(
                onTap: () => setState(() {
                  _filter      = f;
                  _dropdownOpen = false;
                }),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? Theme.of(context).primaryColor.withOpacity(0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    f.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? Theme.of(context).primaryColor : Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ── Calendar ─────────────────────────────────────────────────────────────────
  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay:  DateTime(2020),
        lastDay:   DateTime(2030),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selected, focused) =>
            setState(() { _selectedDay = selected; _focusedDay = focused; }),
        onPageChanged: (focused) => setState(() => _focusedDay = focused),
        calendarFormat: CalendarFormat.month,
        availableCalendarFormats: const {CalendarFormat.month: 'Month'},
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          leftChevronIcon: _chevron(Icons.chevron_left),
          rightChevronIcon: _chevron(Icons.chevron_right),
          headerPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8E8E93)),
          weekendStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8E8E93)),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF6C47FF), width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          todayTextStyle: const TextStyle(color: Color(0xFF6C47FF), fontWeight: FontWeight.bold),
          selectedDecoration: BoxDecoration(
            color: const Color(0xFF6C47FF),
            borderRadius: BorderRadius.circular(8),
          ),
          defaultTextStyle: const TextStyle(fontSize: 13),
          cellMargin: const EdgeInsets.all(3),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (ctx, day, focused) {
            final type = _shiftTypeForDay(day);
            if (type != null) return _markedCell(day, type, isToday: false, isSelected: false);
            return null;
          },
          todayBuilder: (ctx, day, focused) {
            final type = _shiftTypeForDay(day);
            if (type != null) return _markedCell(day, type, isToday: true,  isSelected: false);
            return null;
          },
          selectedBuilder: (ctx, day, focused) {
            final type = _shiftTypeForDay(day);
            return _markedCell(day, type, isToday: false, isSelected: true);
          },
        ),
      ),
    );
  }

  Widget _chevron(IconData icon) => Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: const Color(0xFF6C47FF),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(icon, color: Colors.white, size: 18),
  );

  Widget _markedCell(DateTime day, ShiftType? type, {
    required bool isToday,
    required bool isSelected,
  }) {
    final bg = isSelected
        ? const Color(0xFF6C47FF)
        : (type?.bgColor ?? Colors.transparent);
    final fg = isSelected
        ? Colors.white
        : (type?.color ?? const Color(0xFF1C1C1E));

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bg,
        border: isToday && !isSelected
            ? Border.all(color: const Color(0xFF6C47FF), width: 1.5)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  // ── Event List ───────────────────────────────────────────────────────────────
  Widget _buildEventList() {
    final groups  = _groupedEvents;
    final ordered = ['Yesterday', 'Today', 'Tomorrow'];

    if (groups.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('No shifts found', style: TextStyle(color: Color(0xFF8E8E93))),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ordered.where((g) => groups.containsKey(g)).map((group) {
        final events = groups[group]!;
        final date   = events.first.date;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(group,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text(_formatDate(date),
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            ...events.map((e) => ShiftEventTile(event: e, cardBg: _cardBg(context))),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  // ── Swap Button ───────────────────────────────────────────────────────────────
  Widget _buildSwapButton() {
    return GestureDetector(
      onTap: () => _showSwapSheet(),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.4),
              blurRadius: 12, offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text(
          'Swap Shifts',
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showSwapSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SwapShiftSheet(
        myShifts:     _allEvents.where((e) => e.staffName == 'Ugochukwu Orji').toList(),
        staffMembers: _staffMembers,
        onSubmit: (swap) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Swap request submitted!'),
              backgroundColor: Color(0xFF27AE60),
            ),
          );
        },
      ),
    );
  }
}
