import 'package:bmc_app/features/rota/widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/network/models/widget.dart';
import '../../core/network/provider/widget.dart';

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

  // Layer link to anchor the floating filter dropdown menu exactly below the action button
  final LayerLink _dropdownLayerLink = LayerLink();

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
            // Anchor target around the filter button
            child: CompositedTransformTarget(
              link: _dropdownLayerLink,
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
          ),
        ],
      ),
      body: Stack(
        children: [
          // Using a layout architecture that expands the calendar dynamically to fill screen space
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                child: YearlySummaryCard(counts: _yearlyCounts),
              ),
              const SizedBox(height: 12),

              // Expanded forces the Calendar container box to fill out all viewport screen space remaining
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 100.0),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Dynamically subtract calendar header offset (approx 54px) and split remaining height into 6 calendar rows
                      final calendarGridHeight = constraints.maxHeight - 54;
                      final dynamicRowHeight = (calendarGridHeight > 0) ? (calendarGridHeight / 6.8) : 52.0;

                      return TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        calendarFormat: CalendarFormat.month,
                        rowHeight: dynamicRowHeight, // 👈 Fits rows to screen
                        daysOfWeekHeight: dynamicRowHeight * 0.8,
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

                          final hasShift = rotaProvider.rotaEvents.any((e) => isSameDay(e.date, selectedDay));
                          final matchedEvent = rotaProvider.rotaEvents.cast<RotaEvent?>().firstWhere(
                                (e) => e != null && isSameDay(e.date, selectedDay),
                            orElse: () => null,
                          );
                          if (hasShift && matchedEvent != null) {
                            _showShiftDetailsSheet(context, matchedEvent);
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
                            return Container(
                              decoration: BoxDecoration(
                                color: type.color.withOpacity(0.2),
                                shape: BoxShape.rectangle,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          // Fixed Floating filter menu using CompositedTransformFollower to stick accurately to the appbar target
          if (_dropdownOpen)
            CompositedTransformFollower(
              link: _dropdownLayerLink,
              showWhenUnlinked: false,
              offset: const Offset(-80, 40), // Pulls dropdown perfectly aligned directly below the appbar button
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: Colors.transparent,
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
              ),
            ),
        ],
      ),
    );
  }

  void _openSwapShiftWorkflow(RotaProvider provider) {
    final userProvider = context.read<UserProvider>();
    provider.loadShiftsForMonth(context, _focusedDay, deptId: userProvider.defaultDept);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: SwapShiftSheet(
          myShifts: provider.rotaEvents,
          staffMembers: provider.staffMembers,
          defaultSelectedDate: _selectedDay ?? _focusedDay,
          onSubmit: (payload) async {
            final success = await provider.submitSwap(payload);
            if (!mounted) return;
            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success ? 'Swap request submitted!' : provider.swapError ?? 'Error occurring.'),
                backgroundColor: success ? Colors.green : Colors.red,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showShiftDetailsSheet(BuildContext context, RotaEvent event) {
    final userProvider = context.read<UserProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.fromLTRB(7, 24, 7, MediaQuery.of(context).viewInsets.bottom + 100),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShiftEventTile(
                event: event,
                cardBg: Theme.of(context).cardColor,
                userProvider: userProvider,
              ),
            ],
          ),
        );
      },
    );
  }
}
