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
      // ✅ Uses personnelId from UserModel — null-safe
      final user = context.read<UserProvider>().user;
      final personnelId = user?.personnelId;
      debugPrint('🔍 USER DEBUG IN AVAILABILITY SCREEN:');
      debugPrint('   personnelID: ${user?.personnelId}');
      debugPrint('   Full user: ${user?.toJson()}');   // This will show everything

      if (personnelId == null) {
        debugPrint('❌ personnelId is null → Button will be disabled');
        // personnelId not yet assigned by HR — fetch window only
        context.read<AvailabilityProvider>().refreshWindow();
      } else {
        context.read<AvailabilityProvider>().init();
      }
    });
  }

  // ── Status lookup from provider slots ────────────────────────────────────────
  HrAvailabilityStatus? _statusForDay(
      DateTime day, AvailabilityProvider provider) {
    return provider.slotForDate(day)?.availability;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AvailabilityProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).brightness == Brightness.light ? Theme.of(context).hoverColor : Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).brightness == Brightness.light ? Theme.of(context).hoverColor : Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            title: const Text(
              'Availability',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

          ),
          body: Column(
            children: [
              // Loading bar
              if (provider.isLoading)
                const LinearProgressIndicator(color: Color(0xFF6C47FF)),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAdminBanner(provider),
                      const SizedBox(height: 16),
                      _buildCalendar(provider),
                      const SizedBox(height: 20),
                      _buildChartSection(provider),
                      const SizedBox(height: 20),
                      _buildBottomBar(provider),
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

  // ── Admin Banner ─────────────────────────────────────────────────────────────
  Widget _buildAdminBanner(AvailabilityProvider provider) {
    final isOpen = provider.isWindowOpen;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOpen
              ? const Color(0xFF6C47FF).withOpacity(0.3)
              : const Color(0xFFE5E5EA),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: isOpen
                  ? const Color(0xFF6C47FF).withOpacity(0.1)
                  : const Color(0xFFF2F2F7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOpen ? Icons.info_outline : Icons.lock_outline,
              size: 16,
              color: isOpen
                  ? const Color(0xFF6C47FF)
                  : const Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              // ✅ Message comes from provider — driven by real window data
              provider.adminBannerMessage,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF3C3C43), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Calendar ──────────────────────────────────────────────────────────────────
  Widget _buildCalendar(AvailabilityProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light ? Theme.of(context).hoverColor : Theme.of(context).scaffoldBackgroundColor.withOpacity(0.3),
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
        onDaySelected: (selected, focused) => setState(() {
          _selectedDay = selected;
          _focusedDay  = focused;
        }),
        onPageChanged: (focused) {
          setState(() => _focusedDay = focused);
          // ✅ Reload slots when user swipes to a new month
          final user = context.read<UserProvider>().user;
          if (user?.personnelId != null) {
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
          leftChevronIcon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.chevron_left, color: Colors.white, size: 18),
          ),
          rightChevronIcon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.chevron_right, color: Colors.white, size: 18),
          ),
          headerPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600),
          weekendStyle: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(
            border: Border.all(
                color: Theme.of(context).primaryColor, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          todayTextStyle: TextStyle(color: Theme.of(context).primaryColor.withOpacity(0.2), fontWeight: FontWeight.bold),
          selectedDecoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          defaultTextStyle: const TextStyle(fontSize: 13),
          cellMargin: const EdgeInsets.all(3),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (ctx, day, _) {
            final status = _statusForDay(day, provider);
            if (status != null) {
              return _dotCell(day, status, false, false);
            }
            return null;
          },
          todayBuilder: (ctx, day, _) {
            final status = _statusForDay(day, provider);
            return _dotCell(day, status, true, false);
          },
          selectedBuilder: (ctx, day, _) {
            final status = _statusForDay(day, provider);
            return _dotCell(day, status, false, true);
          },
        ),
      ),
    );
  }

  Widget _dotCell(
      DateTime day,
      HrAvailabilityStatus? status,
      bool isToday,
      bool isSelected,
      ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            border: isToday && !isSelected
                ? Border.all(color: Theme.of(context).primaryColor, width: 1.5)
                : null,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF1C1C1E),
            ),
          ),
        ),
        const SizedBox(height: 2),
        if (status != null)
          Container(
            width: 5, height: 5,
            decoration: BoxDecoration(
                color: status.color, shape: BoxShape.circle),
          )
        else
          const SizedBox(height: 5),
      ],
    );
  }

  // ── Chart Section ─────────────────────────────────────────────────────────────
  Widget _buildChartSection(AvailabilityProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chart Summary',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light ? Theme.of(context).hoverColor : Theme.of(context).scaffoldBackgroundColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8, offset: const Offset(0, 2),
              ),
            ],
          ),
          // ✅ chartData comes from provider, typed to HrAvailabilityStatus
          child: AvailabilityChart(chartData: provider.chartData),
        ),
      ],
    );
  }

  // ── Bottom Bar ───────────────────────────────────────────────────────────────
  Widget _buildBottomBar(AvailabilityProvider provider) {
    final isOpen    = provider.isWindowOpen;
    final hasClosed = provider.isWindowClosed;
    final isPending = provider.isWindowPending;

    // ✅ personnelId null check — button disabled if HR hasn't assigned one
    final user        = context.read<UserProvider>().user;
    final personnelId = user?.personnelId;
    // Change to (temporary for testing):
    final canSchedule = isOpen;   // Allow even if personnelId is null

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light ? Theme.of(context).hoverColor : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12, offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer — shown while open or pending
          if (isOpen || isPending) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    provider.timerPrefix,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF8E8E93),
                        fontWeight: FontWeight.w500),
                  ),
                  Text(
                    provider.timerLabel,
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold,
                      color: isOpen
                          ? const Color(0xFFE74C3C)
                          : const Color(0xFF27AE60),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Disabled hint when personnelId is not yet assigned
          if (isOpen && personnelId == null) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Your personnel ID has not been assigned yet. '
                    'Please contact HR.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11, color: Color(0xFF8E8E93)),
              ),
            ),
          ],

          // Schedule button
          GestureDetector(
            onTap: canSchedule
                ? () => _showAvailabilitySheet(provider, personnelId ?? "demo-placeholder")
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity, height: 52,
              decoration: BoxDecoration(
                color: canSchedule
                    ? Theme.of(context).primaryColor
                    : const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(35),
                boxShadow: canSchedule
                    ? [BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.35),
                  blurRadius: 12, offset: const Offset(0, 4),
                )]
                    : [],
              ),
              alignment: Alignment.center,
              child: provider.isSubmitting
                  ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
                  : Text(
                'Schedule',
                style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600,
                  color: canSchedule
                      ? Colors.white
                      : const Color(0xFF8E8E93),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Show Sheet ───────────────────────────────────────────────────────────────
  void _showAvailabilitySheet(
      AvailabilityProvider provider, String personnelId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AvailabilitySheet(
        personnelId:     personnelId,   // ✅ HR-assigned personnelId, not userId
        preselectedDate: _selectedDay,
        onSubmit: (bulkSlot) async {
          final success = await provider.submitAvailability(
            personnelId: personnelId,
            slots: [bulkSlot],
          );
          if (!mounted) return;
          Navigator.pop(context);
          showMessage(
            success
                ? 'Availability submitted!'
                : provider.errorMessage ?? 'Submission failed.',
            context,
            status: success ? MessageStatus.success : MessageStatus.error,
            title:  success ? 'Done' : 'Error',
          );
        },
      ),
    );
  }
}
