// ─── rota_screen.dart ─────────────────────────────────────────────────────────

import 'package:bmc_app/features/common/show_message.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      context.read<RotaProvider>().loadShiftsForMonth(
        context,
        _focusedDay,
        staffName: userProvider.displayName.isNotEmpty
            ? userProvider.displayName
            : 'You',
      );
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
    final match = context
        .read<RotaProvider>()
        .rotaEvents
        .where((e) => isSameDay(e.date, day));
    if (match.isNotEmpty) {
      return match.first.type;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final rotaProvider = context.watch<RotaProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Rota",
          style: TextStyle(
              fontFamily: 'Lexend', fontWeight: FontWeight.bold, fontSize: 15),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          // ── Swap shift quick-access button ───────────────────────────────────
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Request shift swap',
            onPressed: rotaProvider.rotaEvents.isEmpty
                ? null
                : () => _openSwapShiftWorkflow(rotaProvider),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                child: YearlySummaryCard(counts: _yearlyCounts),
              ),
              const SizedBox(height: 12),

              // Expanded forces the calendar container to fill remaining space
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 100.0),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final calendarGridHeight = constraints.maxHeight * 0.88;
                      final dynamicRowHeight = (calendarGridHeight > 0)
                          ? (calendarGridHeight / 6.8)
                          : 52.0;

                      return TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay:  DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        calendarFormat: CalendarFormat.month,
                        rowHeight: dynamicRowHeight,
                        daysOfWeekHeight: dynamicRowHeight * 0.8,
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: false,
                        ),
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay  = selectedDay;
                            _focusedDay   = focusedDay;
                          });

                          final hasShift = rotaProvider.rotaEvents
                              .any((e) => isSameDay(e.date, selectedDay));
                          final matchedEvent = rotaProvider.rotaEvents
                              .cast<RotaEvent?>()
                              .firstWhere(
                                (e) =>
                            e != null && isSameDay(e.date, selectedDay),
                            orElse: () => null,
                          );
                          if (hasShift && matchedEvent != null) {
                            _showShiftDetailsSheet(context, matchedEvent);
                          }
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                          final userProvider = context.read<UserProvider>();
                          rotaProvider.loadShiftsForMonth(
                            context,
                            focusedDay,
                            staffName: userProvider.displayName.isNotEmpty
                                ? userProvider.displayName
                                : 'You',
                          );
                        },
                        calendarBuilders: CalendarBuilders(
                          prioritizedBuilder: (context, date, _focusedDay){
                            final match = rotaProvider.rotaEvents.cast<RotaEvent?>().firstWhere(
                                    (e) => e != null && isSameDay(e.date, date),
                              orElse: () => null
                            );
                            if (match != null) {
                              bool isPendingSwap = match.status == HrSwapStatus.pending;
                              bool isApprovedSwap = match.status == HrSwapStatus.approved;
                              bool isRejectedSwap = match.status == HrSwapStatus.rejected;
                              final isCancelledSwap = match.status == HrSwapStatus.cancelled;
                              bool isSelected = isSameDay(_selectedDay, date);
                              bool isToday = isSameDay(DateTime.now(), date);

                              Color? cellBgColor = match.type.color.withOpacity(0.12);
                              BoxBorder? cellBorder;
                              Color textColor = match.type.color;

                              if (isPendingSwap){
                                cellBgColor = Colors.orange.withOpacity(0.15);
                                cellBorder = Border.all(color: Colors.orange, width: 1.5);
                                textColor = Colors.orange.shade800;
                              } else if (isApprovedSwap){
                                cellBorder = Border.all(color: Colors.green, width: 1.2);
                              } else if (isRejectedSwap) {
                                cellBorder = Border.all(color: Colors.red, width: 1.2);
                              } else if (isCancelledSwap) {
                                cellBgColor = Colors.grey.shade200;
                                textColor = Colors.grey.shade500;
                              } else if (isSelected) {
                                cellBgColor = Theme.of(context).primaryColor.withOpacity(0.2);
                                cellBorder = Border.all(color: Theme.of(context).primaryColor, width: 1.5);
                              }
                              return Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: cellBgColor,
                                  border: cellBorder,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${date.day}',
                                      style: TextStyle(
                                        fontWeight: (isPendingSwap || isToday || isSelected) ? FontWeight.bold : FontWeight.normal,
                                        color: textColor,
                                        decoration: isCancelledSwap ? TextDecoration.lineThrough : null
                                      ),
                                    ),
                                    if (isPendingSwap)
                                      const Text(
                                        'PENDING',
                                        style: TextStyle(
                                          fontSize: 7,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      )
                                  ],
                                ),
                              );
                            }
                            return null;
                          },
                          markerBuilder: (context, date, events) {
                            final type = _shiftTypeForDay(date);
                            final match = rotaProvider.rotaEvents.cast<RotaEvent?>().firstWhere(
                                (e) => e != null && isSameDay(e.date, date),
                              orElse: () => null
                            );
                            if (type == null || match == null || match.status == HrSwapStatus.pending) return const SizedBox.shrink();
                            // if approved, match.type will naturally be the updated swapped ShiftType value from the backend
                            return Container(
                              decoration: BoxDecoration(
                                color: match.type.color.withOpacity(0.2),
                                shape: BoxShape.rectangle,
                              )
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
        ],
      ),
    );
  }

  // ── Swap workflow ────────────────────────────────────────────────────────────
  void _openSwapShiftWorkflow(RotaProvider provider) {
    final userProvider = context.read<UserProvider>();

    // Load this user's department colleagues for the coworker search.
    // defaultDept on UserModel is a deptId string.
    if (userProvider.defaultDept.isNotEmpty) {
      provider.loadDeptStaff(userProvider.defaultDept);
    }

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
            showMessage(success
                ? 'Swap request submitted — awaiting admin approval.'
                : provider.swapError ?? 'Failed to submit swap request.', context, status: MessageStatus.info);
            if (success){
              if (!mounted) return;
              context.read<RotaProvider>().loadShiftsForMonth(
                context,
                _focusedDay,
              );
            }
            provider.resetSwapState();
          },
        ),
      ),
    );
  }

  void _showShiftDetailsSheet(BuildContext context, RotaEvent event) {
    final userProvider = context.read<UserProvider>();
    final rotaProvider = context.read<RotaProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isPending = event.status == HrSwapStatus.pending;
        final isCancelled = event.status == HrSwapStatus.cancelled ||
            event.status == HrSwapStatus.rejected;

        return Container(
          padding: EdgeInsets.fromLTRB(12, 24, 12, MediaQuery.of(context).viewInsets.bottom + 30),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle Drag Indicator Bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Swap Status Alert Badge inside the Dialog
              if (isPending)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFB3C1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFDA1E28), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Pending Swap Approval",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDA1E28),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "You requested to trade this shift. Awaiting response.",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              if (isCancelled)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, color: Colors.grey.shade600, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "This swap request was cancelled/rejected",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // Main Shift Tile Content Card
              ShiftEventTile(
                event: event,
                cardBg: Theme.of(context).cardColor,
                userProvider: userProvider,
              ),

              const SizedBox(height: 24),

              // Action Buttons Structure Base
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    if (isPending) ...[
                      // 2. Destructive Delete Action Workflow inside the popup dialog
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context); // Dismiss bottom sheet dialog

                            // Triggers request cancel method via swap identifier
                            final success = await rotaProvider.cancelSwapRequest(event.id);

                            if (context.mounted) {
                              showMessage(
                                success ? "Swap request successfully deleted" : "Failed to delete swap request",
                                context,
                                status: success ? MessageStatus.success : MessageStatus.error,
                              );
                              if (success) {
                                final userProvider = context.read<UserProvider>();
                                rotaProvider.loadShiftsForMonth(
                                  context,
                                  _focusedDay,
                                  staffName: userProvider.displayName.isNotEmpty ? userProvider.displayName : 'You',
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.white),
                          label: const Text(
                            'Delete Swap Request',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDA1E28), // Destructive Red
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ] else if (!isCancelled) ...[
                      // Standard Workflow Swap Selector Trigger Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _openSwapShiftWorkflow(rotaProvider);
                          },
                          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                          label: const Text('Request swap for this shift'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                            side: BorderSide(color: Theme.of(context).primaryColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
