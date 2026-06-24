// ─── leave_screen.dart ────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/network/models/leave_model.dart';
import '../../../core/network/provider/leave_provider.dart';
import '../../../core/network/provider/user_provider.dart';
import '../common/widget.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  DateTime  _focusedDay  = DateTime.now();
  DateTime? _selectedDay;
  bool      _dropdownOpen = false;
  // Which leave type to highlight on the calendar
  String? _calendarFilter; // null = show all

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaveProvider>().init();
    });
  }

  // ── Calendar helpers ──────────────────────────────────────────────────────

  List<HrLeaveRequest> _requestsForDay(
      DateTime day, List<HrLeaveRequest> all) {
    final key = DateTime(day.year, day.month, day.day);
    return all.where((r) {
      if (_calendarFilter != null && r.leaveType != _calendarFilter) {
        return false;
      }
      return r.days.any((d) =>
      DateTime(d.year, d.month, d.day) == key);
    }).toList();
  }

  Color _leaveTypeColor(String leaveType) {
    final colors = {
      'ANNUAL':        const Color(0xFF6C47FF),
      'SICK':          const Color(0xFFE74C3C),
      'MATERNITY':     const Color(0xFFE91E8C),
      'PATERNITY':     const Color(0xFF2196F3),
      'COMPASSIONATE': const Color(0xFFF39C12),
      'EMERGENCY':     const Color(0xFFFF5722),
      'STUDY':         const Color(0xFF009688),
      'UNPAID':        const Color(0xFF8E8E93),
    };
    return colors[leaveType.toUpperCase()] ?? const Color(0xFF6C47FF);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<LeaveProvider>(
      builder: (context, leaveProvider, _) {
        final user        = context.read<UserProvider>().user;
        final personnelId = user?.personnelId ?? '';

        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 7),
                  child: Column(
                    children: [
                      _buildAppBar(leaveProvider),
                      if (leaveProvider.isLoading)
                        LinearProgressIndicator(color: Theme.of(context).primaryColor),
                      Expanded(
                        child: RefreshIndicator(
                          color: Theme.of(context).primaryColor,
                          onRefresh: leaveProvider.refresh,
                          child: SingleChildScrollView(
                            physics:
                            const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                _buildCalendarCard(leaveProvider),
                                const SizedBox(height: 20),
                                _buildFilterRow(leaveProvider),
                                const SizedBox(height: 16),
                                _buildRequestList(
                                    leaveProvider, personnelId),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton.extended(
                    elevation: 6,
                    backgroundColor: Theme.of(context).primaryColor,
                    onPressed: () => _openRequestSheet(
                        context, leaveProvider, personnelId),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Request Leave',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),

                // Leave-type dropdown overlay
                if (_dropdownOpen)
                  _buildDropdownOverlay(leaveProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────

  Widget _buildAppBar(LeaveProvider provider) {
    final uniqueTypes = provider.myRequests
        .map((r) => r.leaveType)
        .toSet()
        .toList();

    return Padding(
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text('Leave',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),

          // Pending badge
          if (provider.pendingRequests.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFF39C12), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.hourglass_top_outlined,
                      size: 12, color: Color(0xFFF39C12)),
                  const SizedBox(width: 4),
                  Text(
                    '${provider.pendingRequests.length} pending',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFF39C12),
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

          // Calendar type filter dropdown
          if (uniqueTypes.isNotEmpty)
            GestureDetector(
              onTap: () =>
                  setState(() => _dropdownOpen = !_dropdownOpen),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _calendarFilter ?? 'All types',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _dropdownOpen
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Type dropdown overlay ─────────────────────────────────────────────────

  Widget _buildDropdownOverlay(LeaveProvider provider) {
    final types = ['All', ...provider.myRequests
        .map((r) => r.leaveType)
        .toSet()
        .toList()];

    return Positioned(
      top: 52,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 180,
          decoration:
          BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: types.map((t) {
              final isAll = t == 'All';
              final isSelected = isAll
                  ? _calendarFilter == null
                  : _calendarFilter == t;
              return GestureDetector(
                onTap: () => setState(() {
                  _calendarFilter = isAll ? null : t;
                  _dropdownOpen   = false;
                }),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      if (!isAll)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _leaveTypeColor(t),
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (!isAll) const SizedBox(width: 8),
                      Text(
                        isAll ? 'All types' : _formatType(t),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ── Calendar Card ─────────────────────────────────────────────────────────

  Widget _buildCalendarCard(LeaveProvider provider) {
    final all = provider.calendarRequests;

    return Container(
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
        children: [
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
              final hits = _requestsForDay(selected, all);
              if (hits.isNotEmpty) _showDayRequests(hits);
            },
            onPageChanged: (focused) =>
                setState(() => _focusedDay = focused),
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month'
            },
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
              leftChevronIcon: _chevron(Icons.chevron_left),
              rightChevronIcon: _chevron(Icons.chevron_right),
              headerPadding:
              const EdgeInsets.symmetric(vertical: 12),
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
                    color: Theme.of(context).primaryColor,
                    width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              todayTextStyle: TextStyle(
                color: Theme.of(context).brightness ==
                    Brightness.dark
                    ? Colors.white
                    : Colors.black,
                fontWeight: FontWeight.bold,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              defaultTextStyle:
              const TextStyle(fontSize: 13),
              cellMargin: const EdgeInsets.all(3),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (ctx, day, _) {
                final hits = _requestsForDay(day, all);
                if (hits.isEmpty) return null;
                return _leaveCell(
                    day, hits, isToday: false, isSelected: false);
              },
              todayBuilder: (ctx, day, _) {
                final hits = _requestsForDay(day, all);
                return _leaveCell(
                    day, hits, isToday: true, isSelected: false);
              },
              selectedBuilder: (ctx, day, _) {
                final hits = _requestsForDay(day, all);
                return _leaveCell(
                    day, hits, isToday: false, isSelected: true);
              },
            ),
          ),

          // Legend
          if (all.isNotEmpty) _buildCalendarLegend(all),
        ],
      ),
    );
  }

  Widget _leaveCell(
      DateTime day,
      List<HrLeaveRequest> hits, {
        required bool isToday,
        required bool isSelected,
      }) {
    final hasLeave = hits.isNotEmpty;
    final firstColor = hasLeave
        ? _leaveTypeColor(hits.first.leaveType)
        : null;

    Color? bg;
    Color  textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF1C1C1E);
    Border? border;

    if (hasLeave && isSelected) {
      bg        = firstColor;
      textColor = Colors.white;
    } else if (hasLeave) {
      bg        = firstColor!.withOpacity(0.18);
      textColor = firstColor;
      if (isToday) border = Border.all(color: firstColor, width: 1.5);
    } else if (isSelected) {
      bg        = Theme.of(context).primaryColor;
      textColor = Colors.white;
    } else if (isToday) {
      border = Border.all(
          color: Theme.of(context).primaryColor, width: 1.5);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: bg,
            border: border,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            '${day.day}',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor),
          ),
        ),
        const SizedBox(height: 2),
        if (hasLeave && !isSelected)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: hits
                .take(3)
                .map((r) => Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: _leaveTypeColor(r.leaveType),
                shape: BoxShape.circle,
              ),
            ))
                .toList(),
          )
        else
          const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildCalendarLegend(List<HrLeaveRequest> all) {
    final types = all.map((r) => r.leaveType).toSet().toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Wrap(
        spacing: 12, runSpacing: 6,
        children: types.map((t) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                    color: _leaveTypeColor(t),
                    shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text(_formatType(t),
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF8E8E93))),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _chevron(IconData icon) => Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: Theme.of(context).primaryColor,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(icon, color: Colors.white, size: 18),
  );

  // ── Day-tap dialog ────────────────────────────────────────────────────────

  void _showDayRequests(List<HrLeaveRequest> hits) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Leave on this day',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...hits.map((r) => _requestTile(r,
                compact: true, onTap: () {
                  Navigator.pop(ctx);
                  _showRequestDetail(r);
                })),
          ],
        ),
      ),
    );
  }

  // ── Filter row ────────────────────────────────────────────────────────────

  Widget _buildFilterRow(LeaveProvider leaveProvider) {
    final statuses = [
      null,
      HrLeaveRequestStatus.pending,
      HrLeaveRequestStatus.approved,
      HrLeaveRequestStatus.rejected,
      HrLeaveRequestStatus.cancelled,
    ];

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: statuses.map((s) {
          final isAll      = s == null;
          final isSelected = leaveProvider.filterStatus == s;
          final label      = isAll ? 'All' : s!.label;
          final color      = isAll
              ? Theme.of(context).primaryColor
              : s!.color;

          return GestureDetector(
            onTap: () => leaveProvider.setStatusFilter(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : color.withOpacity(0.3),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Request list ──────────────────────────────────────────────────────────

  Widget _buildRequestList(LeaveProvider leaveProvider, String personnelId) {
    if (leaveProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (leaveProvider.state == LeaveState.error) {
      return Center(
        child: Column(
          children: [
            Text(leaveProvider.errorMessage ?? 'Something went wrong',
                style: const TextStyle(color: Color(0xFFE74C3C))),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: leaveProvider.refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final requests = leaveProvider.myRequests;

    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.event_busy_outlined,
                  size: 48,
                  color: Theme.of(context).hintColor),
              const SizedBox(height: 12),
              Text('No leave requests yet',
                  style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 14)),
              const SizedBox(height: 6),
              const Text('Tap the button below to request leave',
                  style: TextStyle(
                      color: Color(0xFF8E8E93), fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${requests.length} request${requests.length == 1 ? '' : 's'}',
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8E8E93)),
        ),
        const SizedBox(height: 12),
        ...requests.map((r) => _requestTile(r,
            onTap: () => _showRequestDetail(r))),
      ],
    );
  }

  Widget _requestTile(
      HrLeaveRequest r, {
        bool compact = false,
        VoidCallback? onTap,
      }) {
    final color = _leaveTypeColor(r.leaveType);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                _formatType(r.leaveType).characters.first
                    .toUpperCase(),
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_formatType(r.leaveType),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    '${_fmtDate(r.startDate)} → ${_fmtDate(r.endDate)}  ·  ${r.totalDays} day${r.totalDays == 1 ? '' : 's'}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8E8E93)),
                  ),
                  if (!compact && r.reason != null &&
                      r.reason!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(r.reason!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFAEAEB2))),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: r.status.bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(r.status.label,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: r.status.color)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Detail / edit sheet ───────────────────────────────────────────────────

  void _showRequestDetail(HrLeaveRequest r) {
    final provider = context.read<LeaveProvider>();
    final canModify = r.status == HrLeaveRequestStatus.pending;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20, 20, 20,
            120 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(2)
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Text(_formatType(r.leaveType),
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5
                    ),
                    decoration: BoxDecoration(
                      color: r.status.bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(r.status.label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: r.status.color
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _detailRow(Icons.calendar_today_outlined, 'Start',
                  _fmtDate(r.startDate)),
              const SizedBox(height: 8),
              _detailRow(Icons.event_outlined, 'End',
                  _fmtDate(r.endDate)),
              const SizedBox(height: 8),
              _detailRow(Icons.timelapse_outlined, 'Duration',
                  '${r.totalDays} day${r.totalDays == 1 ? '' : 's'}'),
              if (r.reason != null && r.reason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _detailRow(Icons.notes_outlined, 'Reason', r.reason!),
              ],
              if (r.decisionNotes != null &&
                  r.decisionNotes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _detailRow(Icons.comment_outlined, 'Decision note',
                    r.decisionNotes!),
              ],

              const SizedBox(height: 20),

              if (canModify)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openEditSheet(r, provider);
                        },
                        icon: const Icon(Icons.edit_outlined,
                            size: 16),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                          side: BorderSide(
                              color: Theme.of(context).primaryColor),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _confirmDelete(r, provider);
                        },
                        icon: const Icon(Icons.delete_outline,
                            size: 16),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE74C3C),
                          side: const BorderSide(
                              color: Color(0xFFE74C3C)),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
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
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF8E8E93))),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Delete confirm ────────────────────────────────────────────────────────

  Future<void> _confirmDelete(
      HrLeaveRequest r,
      LeaveProvider provider
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)
        ),
        title: const Text('Delete request?'),
        content: Text(
            'This will permanently remove your '
                '${_formatType(r.leaveType)} request '
                '(${_fmtDate(r.startDate)} – ${_fmtDate(r.endDate)}).'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF8E8E93))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
              style: TextStyle(
                  color: Color(0xFFE74C3C),
                  fontWeight: FontWeight.w600
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Delete the request - provider will auto-refresh internally
    final success = await provider.deleteRequest(r.id);

    final msg = success
        ? 'Leave request deleted.'
        : provider.errorMessage ?? 'Delete failed.';

    if (!mounted) return;
    showMessage(msg, context,
        status: success ? MessageStatus.success : MessageStatus.error,
        title: success ? 'Done' : 'Error');
  }

  // ── Request sheet ─────────────────────────────────────────────────────────

  void _openRequestSheet(
      BuildContext context,
      LeaveProvider provider,
      String personnelId
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))
      ),
      builder: (ctx) => _LeaveFormSheet(
        personnelId: personnelId,
        onSave: (data) async {
          // Close the bottom sheet first
          Navigator.pop(ctx);

          // Submit the request - provider will auto-refresh internally
          final success = await provider.createRequest(data);

          final msg = success
              ? 'Leave request submitted!'
              : provider.errorMessage ?? 'Submission failed.';

          if (!mounted) return;
          showMessage(msg, context,
              status: success ? MessageStatus.success : MessageStatus.error,
              title: success ? 'Done' : 'Error');
        },
      ),
    );
  }

// Updated _openEditSheet
  void _openEditSheet(HrLeaveRequest r, LeaveProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))
      ),
      builder: (ctx) => _LeaveFormSheet(
        personnelId: r.personnelId,
        existing: r,
        onSave: (data) async {
          // Close the bottom sheet first
          Navigator.pop(ctx);

          final updateData = HrLeaveUpdateFormData(
            leaveType: data.leaveType,
            startDate: data.startDate,
            endDate: data.endDate,
            totalDays: data.totalDays,
            reason: data.reason,
          );

          // Update the request - provider will auto-refresh internally
          final success = await provider.updateRequest(r.id, updateData);

          final msg = success
              ? 'Leave request updated!'
              : provider.errorMessage ?? 'Update failed.';

          if (!mounted) return;
          showMessage(msg, context,
              status: success ? MessageStatus.success : MessageStatus.error,
              title: success ? 'Done' : 'Error');
        },
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatType(String raw) =>
      raw.split('_').map((w) =>
      w.isEmpty ? '' : '${w[0]}${w.substring(1).toLowerCase()}')
          .join(' ');

  String _fmtDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _LeaveFormSheet — shared by create & edit
// ═════════════════════════════════════════════════════════════════════════════

class _LeaveFormSheet extends StatefulWidget {
  final String               personnelId;
  final HrLeaveRequest?      existing;   // null → create mode
  final void Function(HrLeaveRequestFormData) onSave;

  const _LeaveFormSheet({
    required this.personnelId,
    required this.onSave,
    this.existing,
  });

  @override
  State<_LeaveFormSheet> createState() => _LeaveFormSheetState();
}

class _LeaveFormSheetState extends State<_LeaveFormSheet> {
  String? _selectedLeaveType;
  final _reasonCtrl = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  bool      _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final r = widget.existing!;
      _selectedLeaveType   = r.leaveType;
      _reasonCtrl.text = r.reason ?? '';
      _fromDate        = DateTime.parse(r.startDate);
      _toDate          = DateTime.parse(r.endDate);
    }
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  int get _totalDays {
    if (_fromDate == null || _toDate == null) return 0;
    return _toDate!.difference(_fromDate!).inDays + 1;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _fromDate : _toDate) ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate:  DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: (isDark
                ? const ColorScheme.dark()
                : const ColorScheme.light())
                .copyWith(
              primary:   Theme.of(context).primaryColor,
              surface:   Theme.of(context).cardColor,
              onSurface: isDark ? Colors.white : Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = picked;
        if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
          _toDate = null;
        }
      } else {
        if (_fromDate != null && picked.isBefore(_fromDate!)) {
          showMessage('End date cannot be before start date', context,
              status: MessageStatus.error);
          return;
        }
        _toDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedLeaveType == null) {
      showMessage('Please select a leave type', context,
          status: MessageStatus.error);
      return;
    }
    if (_fromDate == null || _toDate == null) {
      showMessage('Please select start and end dates', context,
          status: MessageStatus.error);
      return;
    }

    setState(() => _saving = true);

    final data = HrLeaveRequestFormData(
      personnelId: widget.personnelId,
      leaveType:   _selectedLeaveType!.toUpperCase(),
      startDate:   _isoDate(_fromDate!),
      endDate:     _isoDate(_toDate!),
      totalDays:   _totalDays,
      reason:      _reasonCtrl.text.trim().isEmpty
          ? null
          : _reasonCtrl.text.trim(),
    );

    widget.onSave(data);
    // onSave pops the sheet so no setState needed after
  }

  String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}'
          '-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 150 + bottomInset),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            _isEdit ? 'Edit Leave Request' : 'Request Leave',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Leave type text field
          _label('Leave Type'),
          DropdownButtonFormField<String>(
            value: _selectedLeaveType,
            hint: const Text('Select leave type'),
            items: availableLeaveTypes.map((type) {
              return DropdownMenuItem(value: type, child: Text(type));
            }).toList(),
            onChanged: (value) => setState(() => _selectedLeaveType = value),
            decoration: InputDecoration(
              hintStyle:
              const TextStyle(color: Color(0xFFAEAEB2), fontSize: 13),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),

          // Date pickers
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('From'),
                    _dateTile(
                        _fromDate, () => _pickDate(isFrom: true)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('To'),
                    _dateTile(
                        _toDate, () => _pickDate(isFrom: false)),
                  ],
                ),
              ),
            ],
          ),

          // Total days badge
          if (_totalDays > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_totalDays day${_totalDays == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Reason
          _label('Reason (optional)'),
          _field(_reasonCtrl, 'Brief reason for leave…',
              maxLines: 3),
          const SizedBox(height: 24),

          // Save button
          GestureDetector(
            onTap: _saving ? null : _submit,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity, height: 52,
              decoration: BoxDecoration(
                color: _saving
                    ? Theme.of(context).primaryColor.withOpacity(0.6)
                    : Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: _saving
                  ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
                  : Text(
                _isEdit ? 'Update Request' : 'Submit Request',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600)),
  );

  Widget _field(TextEditingController ctrl, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.characters,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
        const TextStyle(color: Color(0xFFAEAEB2), fontSize: 13),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _dateTile(DateTime? date, VoidCallback onTap) {
    final label = date == null
        ? 'Select date'
        : '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 15, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: date == null
                      ? Theme.of(context).hintColor
                      : Theme.of(context).brightness ==
                      Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  fontWeight: date == null
                      ? FontWeight.normal
                      : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
