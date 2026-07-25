// ─── rota_screen.dart ─────────────────────────────────────────────────────────

// ignore_for_file: prefer_final_fields, no_leading_underscores_for_local_identifiers

import 'package:bmc_app/features/common/show_message.dart';
import 'package:bmc_app/features/rota/widget.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
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
      final rotaProvider = context.read<RotaProvider>();
      context.read<RotaProvider>().loadShiftsForMonth(
        context,
        _focusedDay,
        staffName: userProvider.displayName.isNotEmpty
            ? userProvider.displayName
            : 'You',
      );
      rotaProvider.loadSwapRequests(
        personnelId: userProvider.user?.personnelId,
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
    final match = context.read<RotaProvider>().rotaEvents.where(
      (e) => isSameDay(e.date, day),
    );
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
            fontFamily: 'Lexend',
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          // ── Swap shift quick-access button ───────────────────────────────────
          GestureDetector(
            onTap: rotaProvider.allCalendarEvents.isEmpty
                ? null
                : () => _openSwapShiftWorkflow(rotaProvider),
            child: Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(right: 16),
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    'Request shift swap',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Lexend',
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(Icons.swap_horiz_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () {
          final userProvider = context.read<UserProvider>();
          return rotaProvider.refreshRotaData(
            context,
            _focusedDay,
            staffName: userProvider.displayName.isNotEmpty
                ? userProvider.displayName
                : 'You',
            personnelId: userProvider.user?.personnelId,
          );
        },
        child: Column(
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
                  vertical: 12,
                  horizontal: 10,
                ),
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
                      lastDay: DateTime.utc(2030, 12, 31),
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
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });

                        final hasShift = rotaProvider.allCalendarEvents.any(
                          (e) => isSameDay(e.date, selectedDay),
                        );
                        final matchedEvent = rotaProvider.allCalendarEvents
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
                      // ─── Update inside TableCalendar -> calendarBuilders in rota_screen.dart ───
                      calendarBuilders: CalendarBuilders(
                        prioritizedBuilder: (context, date, _focusedDay) {
                          // 1. Find if there's a swap event for this date (from allCalendarEvents)
                          final matchingSwap = rotaProvider.allCalendarEvents
                              .cast<RotaEvent?>()
                              .firstWhere(
                                (e) => e != null && isSameDay(e.date, date),
                                orElse: () => null,
                              );

                          // 2. Find if there's a primary shift for this date
                          final primaryShift = rotaProvider.rotaEvents
                              .cast<RotaEvent?>()
                              .firstWhere(
                                (e) => e != null && isSameDay(e.date, date),
                                orElse: () => null,
                              );

                          // If there's no event at all, return the default cell
                          if (matchingSwap == null && primaryShift == null) {
                            return null; // Use default cell
                          }

                          // Swap record takes priority for display if one exists on this date
                          final isSwapEvent = matchingSwap?.swapStatus != null;
                          final displayEvent = isSwapEvent
                              ? matchingSwap
                              : primaryShift;
                          final event = displayEvent!;

                          final swapStatus = event.swapStatus;
                          bool isPendingSwap =
                              swapStatus == HrSwapStatus.pending;
                          bool isApprovedSwap =
                              swapStatus == HrSwapStatus.approved;
                          bool isRejectedSwap =
                              swapStatus == HrSwapStatus.rejected;
                          bool isCancelledSwap =
                              swapStatus == HrSwapStatus.cancelled;
                          bool isSelected = isSameDay(_selectedDay, date);
                          bool isToday = isSameDay(DateTime.now(), date);

                          // Default colors using the event's type
                          Color cellBgColor = event.type.color.withOpacity(
                            0.12,
                          );
                          Color textColor = event.type.color;
                          BoxBorder? cellBorder;
                          String? statusLabel;
                          Color? statusLabelColor;

                          // Override based on swap status
                          if (isPendingSwap) {
                            cellBgColor = const Color(
                              0xFFFFF3E0,
                            ); // Light orange background
                            cellBorder = Border.all(
                              color: const Color(0xFFF39C12),
                              width: 2,
                            );
                            textColor = const Color(0xFFE67E22);
                            statusLabel = 'PENDING';
                            statusLabelColor = const Color(0xFFF39C12);
                          } else if (isApprovedSwap) {
                            cellBgColor = const Color(
                              0xFFE8F5E9,
                            ); // Light green background
                            cellBorder = Border.all(
                              color: const Color(0xFF27AE60),
                              width: 1.5,
                            );
                            textColor = const Color(0xFF27AE60);
                            statusLabel = 'SWAPPED';
                            statusLabelColor = const Color(0xFF27AE60);
                          } else if (isRejectedSwap) {
                            cellBgColor = const Color(
                              0xFFFFEBEE,
                            ); // Light red background
                            cellBorder = Border.all(
                              color: const Color(0xFFE74C3C),
                              width: 1.5,
                            );
                            textColor = const Color(0xFFC0392B);
                            statusLabel = 'REJECTED';
                            statusLabelColor = const Color(0xFFE74C3C);
                          } else if (isCancelledSwap) {
                            cellBgColor = Colors.grey.shade200;
                            textColor = Colors.grey.shade500;
                            statusLabel = 'CANCELLED';
                            statusLabelColor = Colors.grey.shade500;
                          } else if (isSelected) {
                            cellBgColor = Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.2);
                            cellBorder = Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 1.5,
                            );
                          }

                          // Build the cell
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
                                // Day number
                                Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontWeight: (isToday || isSelected)
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: textColor,
                                    decoration: isCancelledSwap
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                // Status label for swaps
                                if (statusLabel != null)
                                  Text(
                                    statusLabel,
                                    style: TextStyle(
                                      fontSize: 7,
                                      fontWeight: FontWeight.bold,
                                      color: statusLabelColor,
                                    ),
                                  ),
                                // Small dot indicator for regular shifts (non-swap)
                                if (!isSwapEvent && primaryShift != null)
                                  Container(
                                    width: 4,
                                    height: 4,
                                    margin: const EdgeInsets.only(top: 2),
                                    decoration: BoxDecoration(
                                      color: primaryShift.type.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },

                        // We're handling everything in prioritizedBuilder, so return empty
                        markerBuilder: (context, date, events) {
                          return const SizedBox.shrink();
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
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
            if (mounted && success) {
              await provider.refreshRotaData(
                context,
                _focusedDay,
                staffName: userProvider.displayName.isNotEmpty
                    ? userProvider.displayName
                    : 'You',
                personnelId: userProvider.user?.personnelId,
              );
            }
            showMessage(
              success
                  ? 'Swap request submitted — awaiting admin approval.'
                  : provider.swapError ?? 'Failed to submit swap request.',
              context,
              status: MessageStatus.info,
            );
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
        final isPending = event.swapStatus == HrSwapStatus.pending;
        final isCancelled =
            event.swapStatus == HrSwapStatus.cancelled ||
            event.swapStatus == HrSwapStatus.rejected;

        return Container(
          padding: EdgeInsets.fromLTRB(
            12,
            24,
            12,
            MediaQuery.of(context).viewInsets.bottom + 100,
          ),
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
                  margin: const EdgeInsets.fromLTRB(0, 0, 0, 7),
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
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF38403)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFDA241E),
                        size: 17,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Pending Swap Approval",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDA241E),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "You requested to trade this shift. Awaiting response.",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 10,
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
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cancel_outlined,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
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

              const SizedBox(height: 2),

              // Main Shift Tile Content Card
              ShiftEventTile(
                event: event,
                cardBg: Theme.of(context).cardColor,
                userProvider: userProvider,
              ),
              const SizedBox(height: 7),
              // Action Buttons Structure Base
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  children: [
                    if (isPending) ...[
                      // 2. Destructive Delete Action Workflow inside the popup dialog
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);

                            final result = await rotaProvider.cancelSwapRequest(
                              event.swapId,
                            );

                            if (context.mounted) {
                              switch (result) {
                                case CancelSwapResult.success:
                                  showMessage(
                                    "Swap request successfully deleted",
                                    context,
                                    status: MessageStatus.success,
                                  );
                                  break;
                                case CancelSwapResult.alreadyResolved:
                                  showMessage(
                                    "This request was already handled — refreshing your rota.",
                                    context,
                                    status: MessageStatus.info,
                                  );
                                  break;
                                case CancelSwapResult.failed:
                                  showMessage(
                                    "Failed to delete swap request",
                                    context,
                                    status: MessageStatus.error,
                                  );
                                  break;
                              }

                              if (result != CancelSwapResult.failed) {
                                final userProvider = context
                                    .read<UserProvider>();
                                rotaProvider.refreshRotaData(
                                  context,
                                  _focusedDay,
                                  staffName: userProvider.displayName.isNotEmpty
                                      ? userProvider.displayName
                                      : 'You',
                                  personnelId: userProvider.user?.personnelId,
                                );
                              }
                            }
                          },
                          icon: const Icon(
                            Iconsax.trash,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Delete Swap Request',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFFDA1E28,
                            ), // Destructive Red
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 25),
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
                            side: BorderSide(
                              color: Theme.of(context).primaryColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 20),
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
