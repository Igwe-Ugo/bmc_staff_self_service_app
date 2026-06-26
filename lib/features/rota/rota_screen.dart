import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../core/network/models/widget.dart';
import '../../core/network/provider/widget.dart';
import 'shift_event_tile.dart';
import 'swap_shift_sheet.dart';
import 'yearly_summary_card.dart';

class RotaScreen extends StatefulWidget {
  const RotaScreen({super.key});

  @override
  State<RotaScreen> createState() => _RotaScreenState();
}

class _RotaScreenState extends State<RotaScreen> {
  RotaFilter _filter = RotaFilter.allStatus;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _dropdownOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RotaProvider>().loadShiftsForMonth(context, _focusedDay);
    });
  }

  List<RotaEvent> get _filtered {
    return context.watch<RotaProvider>().filteredEvents(
      filter: _filter,
      focusedDay: _focusedDay,
      selectedDay: _selectedDay,
    );
  }

  Map<ShiftType, int> get _yearlyCounts {
    final rotaProvider = context.read<RotaProvider>();
    return rotaProvider.yearlyCounts(_filtered);
  }

  ShiftType? _shiftTypeForDay(DateTime day) {
    final match = context.read<RotaProvider>().rotaEvents.where((e) => isSameDay(e.date, day));
    if (match.isNotEmpty) {
      return match.first.type;
    }
    return null;
  }

  void _updateFilter(String option) {
    setState(() {
      _dropdownOpen = false;
      if (option == 'All' || option == 'All types') _filter = RotaFilter.allStatus;
      if (option == 'Day') _filter = RotaFilter.daily;
      if (option == 'Night') _filter = RotaFilter.weekly;
      if (option == 'Evening') _filter = RotaFilter.monthly;
      if (option == 'On Call') _filter = RotaFilter.yearly;
    });
  }

  String _getFilterLabel(RotaFilter filter) {
    switch (filter) {
      case RotaFilter.allStatus: return 'All types';
      case RotaFilter.daily: return 'Day';
      case RotaFilter.weekly: return 'Night';
      case RotaFilter.monthly: return 'Evening';
      case RotaFilter.yearly: return 'On Call';
    }
  }

  @override
  Widget build(BuildContext context) {
    final rotaProvider = context.watch<RotaProvider>();
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Rota",
          style: TextStyle(fontFamily: 'Lexend', fontWeight: FontWeight.bold, fontSize: 15),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: GestureDetector(
              onTap: () => setState(() => _dropdownOpen = !_dropdownOpen),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getFilterLabel(_filter),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _dropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      YearlySummaryCard(counts: _yearlyCounts),
                      const SizedBox(height: 3),
                      TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        calendarFormat: CalendarFormat.month,
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: false,
                        ),
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                            _dropdownOpen = false;
                          });

                          // Requirement 1: Only trigger pop-up swap workflow if this calendar day actually contains an event
                          final hasShift = rotaProvider.rotaEvents.any((e) => isSameDay(e.date, selectedDay));
                          if (hasShift) {
                            _openSwapShiftWorkflow(rotaProvider);
                          }
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                          rotaProvider.loadShiftsForMonth(context, focusedDay);
                        },
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, date, events) {
                            final type = _shiftTypeForDay(date);
                            if (type == null) return const SizedBox.shrink();
                            return Positioned(
                              bottom: 4,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: type.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Scheduled Shifts",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Lexend'),
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) {
                    final event = _filtered[index];
                    return ShiftEventTile(
                      event: event,
                      cardBg: Theme.of(context).cardColor,
                      userProvider: userProvider,
                    );
                  },
                ),
              ],
            ),
          ),
          if (_dropdownOpen)
            Positioned(
              right: 16,
              top: 145,
              child: Container(
                width: 140,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: ['All types', 'Day', 'Night', 'Evening', 'On Call'].map((String val) {
                    return InkWell(
                      onTap: () => _updateFilter(val),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text(
                          val,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openSwapShiftWorkflow(RotaProvider provider) {
    final myShifts = provider.rotaEvents
        .where((e) => !e.date.isBefore(
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    ))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: SwapShiftSheet(
          myShifts: myShifts,
          staffMembers: provider.staffMembers,
          onSubmit: (payload) async {
            final success = await provider.submitSwap(payload as HrSwapRequestPayload);
            if (!mounted) return;
            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? 'Swap request submitted successfully!'
                      : provider.swapError ?? 'Failed to submit swap.',
                ),
                backgroundColor: success ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
              ),
            );

            if (success) {
              provider.loadShiftsForMonth(context, _focusedDay);
            }
          },
        ),
      ),
    );
  }
}
