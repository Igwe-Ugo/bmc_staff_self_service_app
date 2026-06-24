import 'package:bmc_app/features/availability/widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/network/models/availability_model.dart';
import '../../../core/network/provider/availability_provider.dart';
import '../../../core/network/provider/user_provider.dart';
import '../../../features/common/show_message.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  DateTime  _focusedDay  = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user        = context.read<UserProvider>().user;
      final personnelId = user?.personnelId;

      debugPrint('🔍 USER DEBUG IN AVAILABILITY SCREEN:');
      debugPrint('   personnelID: ${user?.personnelId}');
      debugPrint('   Full user: ${user?.toJson()}');

      if (personnelId == null) {
        debugPrint('❌ personnelId is null → fetching window only');
        context.read<AvailabilityProvider>().refreshWindow();
      } else {
        context.read<AvailabilityProvider>().init();
      }
    });
  }

  // 1. Update this validation method to check the tapped day's month accurately
  bool _isCurrentMonthOpen(AvailabilityProvider provider, DateTime targetDay) {
    if (!provider.hasWindow) return false;
    final windowMonthKey = provider.windowMonthKey; // Use the new getter
    final targetMonthKey = "${targetDay.year}-${targetDay.month.toString().padLeft(2, '0')}";
    return windowMonthKey == targetMonthKey;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  HrAvailabilitySlot? _slotForDay(DateTime day, AvailabilityProvider p) =>
      p.slotForDate(day);

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<AvailabilityProvider>(
      builder: (context, provider, _) {
        final user        = context.read<UserProvider>().user;
        final personnelId = user?.personnelId;
        final canSchedule = provider.isWindowOpen && _isCurrentMonthOpen(provider, _focusedDay);

        return Scaffold(
          backgroundColor: _scaffoldBg(context),
          appBar: AppBar(
            backgroundColor: _scaffoldBg(context),
            elevation: 0,
            title: const Text(
              'Availability',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          body: Column(
            children: [
              if (provider.isLoading)
                LinearProgressIndicator(color: Theme.of(context).primaryColor),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.bottomCenter,
                        child: Text(
                          "Submit and manage your availability for upcoming months",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w300),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildWindowBanner(provider),
                      const SizedBox(height: 16),
                      _buildCalendar(provider, canSchedule, personnelId),
                      const SizedBox(height: 40),
                      _buildChartSection(provider, canSchedule),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Admin Banner ──────────────────────────────────────────────────────────

  Widget _buildWindowBanner(AvailabilityProvider provider) {
    if (!provider.hasWindow) return const SizedBox.shrink();

    final window   = provider.window!;
    final isOpen   = provider.isWindowOpen;
    final isPending = provider.isWindowPending;

    // ── Colours ────────────────────────────────────────────────────────────────
    final Color borderColor = isOpen
        ? const Color(0xFF27AE60)
        : isPending
        ? const Color(0xFFF39C12)
        : const Color(0xFF8E8E93);

    final Color iconBg = isOpen
        ? const Color(0xFF27AE60).withOpacity(0.15)
        : isPending
        ? const Color(0xFFF39C12).withOpacity(0.15)
        : const Color(0xFF8E8E93).withOpacity(0.1);

    final Color iconColor = isOpen
        ? const Color(0xFF27AE60)
        : isPending
        ? const Color(0xFFF39C12)
        : const Color(0xFF8E8E93);

    // ── Title & subtitle ────────────────────────────────────────────────────────
    final String title = isOpen
        ? 'Availability window open for ${_fullMonthName(window.month)}'
        : isPending
        ? 'Availability window pending for ${_fullMonthName(window.month)}'
        : 'Availability window closed for ${_fullMonthName(window.month)}';

    final String subtitle = isOpen
        ? 'Closes ${_formatDateTime(window.closesAt)}'
        : isPending
        ? 'Opens ${_formatDateTime(window.opensAt)}'
        : 'Closed on ${_formatDateTime(window.closesAt)}';

    final String pillLabel = _pillLabel(provider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.calendar_month_outlined,
                color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (pillLabel.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, size: 12, color: borderColor),
                  const SizedBox(width: 4),
                  Text(
                    pillLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: borderColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _pillLabel(AvailabilityProvider provider) {
    if (!provider.hasWindow) return '';
    final remaining = provider.remaining;

    if (provider.isWindowOpen || provider.isWindowPending) {
      if (remaining.inSeconds <= 0) return '';
      final days    = remaining.inDays;
      final hours   = remaining.inHours % 24;
      final minutes = remaining.inMinutes % 60;

      if (days > 0)    return '$days day${days == 1 ? '' : 's'} left';
      if (hours > 0)   return '$hours hr${hours == 1 ? '' : 's'} left';
      if (minutes > 0) return '$minutes min left';
      return '< 1 min left';
    }
    return '';
  }

  // ── Calendar ──────────────────────────────────────────────────────────────

  Widget _buildCalendar(
      AvailabilityProvider provider,
      bool canSchedule,
      String? personnelId,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
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
      child: Column(
        children: [
          Wrap(
            spacing: 8, runSpacing: 8,
            children: HrAvailabilityStatus.values.map((status) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: status.bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: status.color),
                ),
                child: Text(
                  status.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: status.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
          TableCalendar(
            firstDay:  DateTime(2020),
            lastDay:   DateTime(2030),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay  = focused;
              });
              // Evaluate if the newly selected day belongs to the admin's open window
              final dayCanSchedule = provider.hasWindow && _isCurrentMonthOpen(provider, selected);
              _onDayTapped(selected, provider, personnelId ?? 'demo-placeholder', dayCanSchedule);
            },
            onPageChanged: (focused) {
              setState(() => _focusedDay = focused);
              if (personnelId != null) {
                provider.changeMonth(focused);
              }
            },
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: 'Month'},
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              leftChevronIcon: _chevron(Icons.chevron_left, context),
              rightChevronIcon: _chevron(Icons.chevron_right, context),
              headerPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              weekendStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              todayDecoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).primaryColor, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              todayTextStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              defaultTextStyle: const TextStyle(fontSize: 13),
              cellMargin: const EdgeInsets.all(3),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (ctx, day, _) {
                final slot = _slotForDay(day, provider);
                if (slot != null) {
                  return _coloredCell(day, slot, isToday: false, isSelected: false);
                }
                return null;
              },
              todayBuilder: (ctx, day, _) {
                final slot = _slotForDay(day, provider);
                return _coloredCell(day, slot, isToday: true, isSelected: false);
              },
              selectedBuilder: (ctx, day, _) {
                final slot = _slotForDay(day, provider);
                return _coloredCell(day, slot, isToday: false, isSelected: true);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _coloredCell(
      DateTime day,
      HrAvailabilitySlot? slot, {
        required bool isToday,
        required bool isSelected,
      }) {
    final hasSlot   = slot != null;
    final slotColor = hasSlot ? slot.availability.color : null;
    final slotBg    = hasSlot ? slot.availability.bgColor : null;

    Color? bg;
    Color  textColor = const Color(0xFF1C1C1E);
    Border? border;

    if (hasSlot && isSelected) {
      bg        = slotColor;
      textColor = Colors.white;
    } else if (hasSlot) {
      bg        = slotBg;
      textColor = slotColor!;
      if (isToday) border = Border.all(color: slotColor, width: 1.5);
    } else if (isSelected) {
      bg        = Theme.of(context).primaryColor;
      textColor = Colors.white;
    } else if (isToday) {
      border    = Border.all(color: Theme.of(context).primaryColor, width: 1.5);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color:        bg,
            border:       border,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(height: 2),
        if (hasSlot && !isSelected)
          Container(
            width: 5, height: 5,
            decoration: BoxDecoration(
              color: slotColor, shape: BoxShape.circle,
            ),
          )
        else
          const SizedBox(height: 5),
      ],
    );
  }

  Widget _chevron(IconData icon, BuildContext ctx) => Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: Theme.of(ctx).primaryColor,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(icon, color: Colors.white, size: 18),
  );

  // ── Day tap → dialog ──────────────────────────────────────────────────────

  // 3. Clean up the parameters for _onDayTapped to honor the contextual check
  void _onDayTapped(
      DateTime day,
      AvailabilityProvider provider,
      String personnelId,
      bool canSchedule,
      ) {
    final existing = _slotForDay(day, provider);

    if (existing != null) {
      _showSlotDetailDialog(existing, provider, canSchedule);
    } else {
      if (!canSchedule) {
        // Optionally show a message to the user
        showMessage(
          'Availability window is closed for this month',
          context,
          status: MessageStatus.info,
          title: 'Read Only',
        );
        return;
      }
      _showSetAvailabilityDialog(day, provider, personnelId);
    }
  }

  // ── Dialog: view & delete existing slot ──────────────────────────────────

  void _showSlotDetailDialog(
      HrAvailabilitySlot slot,
      AvailabilityProvider provider,
      bool canSchedule,
      ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          title: Row(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: slot.availability.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                slot.availability.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: slot.availability.color,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(Icons.calendar_today_outlined, 'Date',
                  _friendlyDate(slot.date)),
              const SizedBox(height: 10),
              _detailRow(Icons.access_time_outlined, 'Shift',
                  slot.timeSlot.label),
              if (slot.startTime != null && slot.endTime != null) ...[
                const SizedBox(height: 10),
                _detailRow(Icons.timelapse_outlined, 'Time',
                    '${slot.startTime} – ${slot.endTime}'),
              ],
              if (slot.notes != null && slot.notes!.isNotEmpty) ...[
                const SizedBox(height: 10),
                _detailRow(Icons.notes_outlined, 'Notes', slot.notes!),
              ],
              if (slot.isLocked || !canSchedule) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline,
                          size: 14, color: Color(0xFFF39C12)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          !canSchedule
                              ? 'This month window is closed. Read-only.'
                              : 'This slot is locked and cannot be deleted.',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFFF39C12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close',
                  style: TextStyle(color: Color(0xFF8E8E93))),
            ),
            // ── ADD THIS BUTTON ──────────────────────────────────────────────
            if (!slot.isLocked && canSchedule)
              TextButton(
                onPressed: () {
                  // Close current dialog
                  Navigator.pop(ctx);
                  // Open the set availability dialog for the same date
                  // Get the personnelId from the provider
                  final user = context.read<UserProvider>().user;
                  final personnelId = user?.personnelId ?? '';
                  _showSetAvailabilityDialog(slot.date, provider, personnelId);
                },
                child: const Text(
                  'Add Another',
                  style: TextStyle(
                    color: Color(0xFF6C47FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (!slot.isLocked && canSchedule)
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _deleteSlot(slot, provider);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    color: Color(0xFFE74C3C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF8E8E93)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _deleteSlot(
      HrAvailabilitySlot slot,
      AvailabilityProvider provider,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Remove availability?'),
        content: Text(
          'This will remove your ${slot.availability.label.toLowerCase()} '
              'entry for ${_friendlyDate(slot.date)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF8E8E93))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Remove',
              style: TextStyle(
                color: Color(0xFFE74C3C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await provider.deleteSlot(slot.id);
    if (!mounted) return;

    if (success) {
      await provider.init(); // Realtime state sync
    }

    showMessage(
      success ? 'Availability removed.' : provider.errorMessage ?? 'Delete failed.',
      context,
      status: success ? MessageStatus.success : MessageStatus.error,
      title:  success ? 'Done' : 'Error',
    );
  }

  // ── Dialog: set new availability ─────────────────────────────────────────

  void _showSetAvailabilityDialog(
      DateTime day,
      AvailabilityProvider provider,
      String personnelId,
      ) {
    HrAvailabilityStatus _selectedStatus = HrAvailabilityStatus.available;
    HrTimeSlot _selectedSlot = HrTimeSlot.fullDay;
    final _notesCtrl = TextEditingController();
    final _startCtrl = TextEditingController();
    final _endCtrl = TextEditingController();

    // Local state for dialog-specific loading
    bool _isDialogSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Set Availability',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    _friendlyDate(day),
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF8E8E93)),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 4),
                    const Text('Status',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8E8E93))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: HrAvailabilityStatus.values.map((status) {
                        final selected = _selectedStatus == status;
                        return GestureDetector(
                          onTap: () =>
                              setDlgState(() => _selectedStatus = status),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: selected
                                  ? status.color
                                  : status.bgColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? status.color
                                    : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              status.label,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? Colors.white : status.color),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),
                    const Text('Shift',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8E8E93))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: HrTimeSlot.values.map((ts) {
                        final selected = _selectedSlot == ts;
                        return GestureDetector(
                          onTap: () =>
                              setDlgState(() => _selectedSlot = ts),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Theme.of(context).primaryColor
                                  : const Color(0xFFF2F2F7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              ts.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF3C3C43),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    if (_selectedSlot.requiresCustomTime) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _timeField(
                                _startCtrl, 'Start (HH:mm)', ctx),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _timeField(
                                _endCtrl, 'End (HH:mm)', ctx),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Text('Notes (optional)',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8E8E93))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesCtrl,
                      minLines: 2,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Any additional notes…',
                        hintStyle: const TextStyle(
                            fontSize: 13, color: Color(0xFFAEAEB2)),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFFE5E5EA)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFFE5E5EA)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: Theme.of(context).primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isDialogSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel',
                      style: TextStyle(color: Color(0xFF8E8E93))),
                ),
                TextButton(
                  onPressed: _isDialogSubmitting
                      ? null
                      : () async {
                    // Set local loading state
                    setDlgState(() => _isDialogSubmitting = true);

                    try {
                      final dateKey = _isoDate(day);
                      final success = await provider.submitAvailability(
                        personnelId: personnelId,
                        slots: [
                          HrAvailabilityBulkSlot(
                            date: dateKey,
                            timeSlot: _selectedSlot,
                            startTime: _selectedSlot.requiresCustomTime
                                ? _startCtrl.text.trim()
                                : null,
                            endTime: _selectedSlot.requiresCustomTime
                                ? _endCtrl.text.trim()
                                : null,
                            availability: _selectedStatus,
                            notes: _notesCtrl.text.trim().isEmpty
                                ? null
                                : _notesCtrl.text.trim(),
                          ),
                        ],
                      );
                      if (success) {
                        await provider.init(); // Sync layout immediately on success
                        // Dismiss dialog first, then show message
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }

                        if (mounted) {
                          showMessage(
                            'Availability saved!',
                            context,
                            status: MessageStatus.success,
                            title: 'Done',
                          );
                        }
                      } else {
                        // Reset loading state on error
                        setDlgState(() => _isDialogSubmitting = false);
                        if (mounted) {
                          showMessage(
                            provider.errorMessage ?? 'Submission failed.',
                            context,
                            status: MessageStatus.error,
                            title: 'Error',
                          );
                        }
                      }
                    } catch (e) {
                      // Reset loading state on exception
                      setDlgState(() => _isDialogSubmitting = false);

                      if (mounted) {
                        showMessage(
                          'An unexpected error occurred: $e',
                          context,
                          status: MessageStatus.error,
                          title: 'Error',
                        );
                      }
                    }
                  },
                  child: _isDialogSubmitting
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(
                    'Save',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _timeField(
      TextEditingController ctrl,
      String hint,
      BuildContext ctx,
      ) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.datetime,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
        const TextStyle(fontSize: 12, color: Color(0xFFAEAEB2)),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
      ),
    );
  }

  // ── Chart Section ─────────────────────────────────────────────────────────

  Widget _buildChartSection(AvailabilityProvider provider, bool canSchedule) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Chart Summary',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(
              provider.currentMonth,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Wrap(
          spacing: 12, runSpacing: 6,
          children: HrAvailabilityStatus.values.map((s) {
            final count = provider.chartData[s]?.values.fold(
              0,
                  (prev, v) => prev + v,
            ) ??
                0;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                      color: s.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(
                  '${s.label} ($count)',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            );
          }).toList(),
        ),

        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardBg(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8, offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AvailabilityChart(chartData: provider.chartData),
        ),
      ],
    );
  }

  // ── Theming helpers ───────────────────────────────────────────────────────

  Color _scaffoldBg(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.light
          ? Theme.of(ctx).hoverColor
          : Theme.of(ctx).scaffoldBackgroundColor;

  Color _cardBg(BuildContext ctx) =>
      Theme.of(context).cardColor;

  // ── Date helpers ──────────────────────────────────────────────────────────

  String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  String _friendlyDate(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final wd = days[d.weekday - 1];
    return '$wd, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _fullMonthName(String monthKey) {
    // Handle both "2026-07-01" and "2026-07" formats
    String cleanMonthKey = monthKey;
    if (monthKey.contains('-') && monthKey.split('-').length >= 2) {
      final parts = monthKey.split('-');
      cleanMonthKey = "${parts[0]}-${parts[1].padLeft(2, '0')}";
    }

    final parts = cleanMonthKey.split('-');
    if (parts.length < 2) return monthKey;
    final year = parts[0];
    final month = int.tryParse(parts[1]) ?? 0;
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${names[month]} $year';
  }

  String _formatDateTime(DateTime dt) {
    final d  = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final y  = dt.year.toString();
    final h  = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$d/$mo/$y at $h:$mi';
  }
}
