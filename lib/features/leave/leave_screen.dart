import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/network/models/widget.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  LeaveType _selectedType = LeaveType.compassionate;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _dropdownOpen = false;

  // Sample leave events — replace with real data
  final List<LeaveEvent> _allEvents = [
    LeaveEvent(
      title: 'Family bereavement',
      type: LeaveType.compassionate,
      from: DateTime(2026, 5, 18),
      to: DateTime(2026, 5, 20),
      description: 'Family matter',
    ),
    LeaveEvent(
      title: 'Flu recovery',
      type: LeaveType.sick,
      from: DateTime(2026, 5, 22),
      to: DateTime(2026, 5, 23),
      description: 'Sick',
    ),
  ];

  // Leave balances per type
  final Map<LeaveType, LeaveBalance> _balances = const {
    LeaveType.compassionate: LeaveBalance(type: LeaveType.compassionate, total: 3, used: 1),
    LeaveType.sick: LeaveBalance(type: LeaveType.sick, total: 5, used: 2),
    LeaveType.emergency: LeaveBalance(type: LeaveType.emergency, total: 3, used: 0),
    LeaveType.rest: LeaveBalance(type: LeaveType.rest, total: 6, used: 4),
  };

  LeaveBalance get _currentBalance => _balances[_selectedType]!;

  List<LeaveEvent> get _filteredEvents =>
      _allEvents.where((e) => e.type == _selectedType).toList();

  Set<DateTime> get _markedDays {
    final days = <DateTime>{};
    for (final e in _filteredEvents) {
      days.addAll(e.days);
    }
    return days;
  }

  bool _isMarked(DateTime day) =>
      _markedDays.contains(DateTime(day.year, day.month, day.day));

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
                        _buildCalendarCard(),
                        const SizedBox(height: 20),
                        _buildBalanceSection(),
                        const SizedBox(height: 20),
                        _buildLeaveRequestSection(),
                        const SizedBox(height: 20),
                        _buildRequestButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Dropdown overlay
            if (_dropdownOpen) _buildDropdownOverlay(),
          ],
        ),
      ),
    );
  }

  // ── App Bar ─────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text(
            'Leave',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          // Dropdown trigger
          GestureDetector(
            onTap: () => setState(() => _dropdownOpen = !_dropdownOpen),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E5EA)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedType.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C1E),
                    ),
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
        ],
      ),
    );
  }

  // ── Dropdown Overlay ────────────────────────────────────────────────────────

  Widget _buildDropdownOverlay() {
    return Positioned(
      top: 52,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: LeaveType.values.map((type) {
              final isSelected = type == _selectedType;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedType = type;
                  _dropdownOpen = false;
                }),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    type.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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

  // ── Calendar Card ───────────────────────────────────────────────────────────

  Widget _buildCalendarCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime(2020),
        lastDay: DateTime(2030),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
          });
        },
        onPageChanged: (focused) {
          setState(() => _focusedDay = focused);
        },
        calendarFormat: CalendarFormat.month,
        availableCalendarFormats: const {CalendarFormat.month: 'Month'},
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF1C1C1E),
          ),
          leftChevronIcon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF6C47FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.chevron_left, color: Colors.white, size: 18),
          ),
          rightChevronIcon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF6C47FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.chevron_right, color: Colors.white, size: 18),
          ),
          headerPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8E8E93),
          ),
          weekendStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8E8E93),
          ),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF6C47FF), width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          todayTextStyle: const TextStyle(
            color: Color(0xFF6C47FF),
            fontWeight: FontWeight.bold,
          ),
          selectedDecoration: BoxDecoration(
            color: const Color(0xFF6C47FF),
            borderRadius: BorderRadius.circular(8),
          ),
          defaultTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF1C1C1E)),
          weekendTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF1C1C1E)),
          cellMargin: const EdgeInsets.all(3),
        ),
        calendarBuilders: CalendarBuilders(
          // Custom builder to show leave-marked days
          defaultBuilder: (context, day, focusedDay) {
            if (_isMarked(day)) {
              return _buildMarkedDay(day, isToday: false, isSelected: false);
            }
            return null;
          },
          todayBuilder: (context, day, focusedDay) {
            if (_isMarked(day)) {
              return _buildMarkedDay(day, isToday: true, isSelected: false);
            }
            return null;
          },
          selectedBuilder: (context, day, focusedDay) {
            if (_isMarked(day)) {
              return _buildMarkedDay(day, isToday: false, isSelected: true);
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildMarkedDay(DateTime day, {required bool isToday, required bool isSelected}) {
    final color = _selectedType.color;
    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isSelected ? color : color.withOpacity(0.15),
        border: isToday ? Border.all(color: color, width: 1.5) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : color,
        ),
      ),
    );
  }

  // ── Balance Section ─────────────────────────────────────────────────────────

  Widget _buildBalanceSection() {
    final balance = _currentBalance;
    final ratio = '${balance.used}/${balance.total}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Leave Balance',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              // Label + ratio
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedType.label.replaceAll(' Leave', ''),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E)),
                  ),
                  Text(
                    ratio,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: balance.progressColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: balance.progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE5E5EA),
                  valueColor: AlwaysStoppedAnimation<Color>(balance.progressColor),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF2F2F7)),
              const SizedBox(height: 12),
              // Stats rows
              _buildBalanceRow('Estimated', balance.estimated),
              _buildBalanceRow('Used', balance.used),
              _buildBalanceRow('Carried over', balance.carriedOver),
              _buildBalanceRow('Pending', balance.pending),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
          Text('$value', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E))),
        ],
      ),
    );
  }

  // ── Leave Request Section ───────────────────────────────────────────────────

  Widget _buildLeaveRequestSection() {
    final requests = _filteredEvents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Leave Request',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
        ),
        const SizedBox(height: 12),
        if (requests.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('No leave requests yet', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13)),
            ),
          )
        else
          ...requests.map((e) => _buildRequestTile(e)),
      ],
    );
  }

  Widget _buildRequestTile(LeaveEvent event) {
    final color = event.type.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E))),
                const SizedBox(height: 4),
                Text(
                  '${_fmt(event.from)} → ${_fmt(event.to)}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${event.days.length}d',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  // ── Request Leave Button ────────────────────────────────────────────────────

  Widget _buildRequestButton() {
    return GestureDetector(
      onTap: () => _showRequestSheet(),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF6C47FF),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: const Color(0xFF6C47FF).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        alignment: Alignment.center,
        child: const Text(
          'Request Leave',
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── Request Leave Bottom Sheet ──────────────────────────────────────────────

  void _showRequestSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RequestLeaveSheet(
        leaveTypes: LeaveType.values,
        defaultType: _selectedType,
        onSave: (event) {
          setState(() => _allEvents.add(event));
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Leave request submitted!'),
              backgroundColor: Color(0xFF27AE60),
            ),
          );
        },
      ),
    );
  }
}

// ─── Request Leave Bottom Sheet Widget ────────────────────────────────────────

class _RequestLeaveSheet extends StatefulWidget {
  final List<LeaveType> leaveTypes;
  final LeaveType defaultType;
  final ValueChanged<LeaveEvent> onSave;

  const _RequestLeaveSheet({
    required this.leaveTypes,
    required this.defaultType,
    required this.onSave,
  });

  @override
  State<_RequestLeaveSheet> createState() => _RequestLeaveSheetState();
}

class _RequestLeaveSheetState extends State<_RequestLeaveSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  late LeaveType _type;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _type = widget.defaultType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6C47FF),
              onPrimary: Colors.white,
              surface: Colors.white,
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
        if (_toDate != null && _toDate!.isBefore(_fromDate!)) _toDate = null;
      } else {
        _toDate = picked;
      }
    });
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty) {
      _snack('Please enter a title');
      return;
    }
    if (_fromDate == null || _toDate == null) {
      _snack('Please select from and to dates');
      return;
    }
    widget.onSave(LeaveEvent(
      title: _titleController.text.trim(),
      type: _type,
      from: _fromDate!,
      to: _toDate!,
      description: _descController.text.trim(),
    ));
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFE74C3C)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          const Text('Request Leave', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
          const SizedBox(height: 20),

          // Title
          _sheetLabel('Title'),
          _sheetTextField(_titleController, 'e.g. Family bereavement'),
          const SizedBox(height: 14),

          // Leave type dropdown
          _sheetLabel('Leave Type'),
          _buildTypeDropdown(),
          const SizedBox(height: 14),

          // From / To date pickers
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sheetLabel('From'),
                    _dateTile(_fromDate, () => _pickDate(isFrom: true)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sheetLabel('To'),
                    _dateTile(_toDate, () => _pickDate(isFrom: false)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Description
          _sheetLabel('Description'),
          _sheetTextField(_descController, 'Optional details...', maxLines: 3),
          const SizedBox(height: 24),

          // Save button
          GestureDetector(
            onTap: _submit,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF6C47FF),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Text('Save Request', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8E8E93))),
    );
  }

  Widget _sheetTextField(TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C1E)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFAEAEB2), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LeaveType>(
          value: _type,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6C47FF)),
          style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C1E), fontWeight: FontWeight.w500),
          items: widget.leaveTypes.map((t) {
            return DropdownMenuItem(
              value: t,
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: t.color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(t.label),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => _type = v!),
        ),
      ),
    );
  }

  Widget _dateTile(DateTime? date, VoidCallback onTap) {
    final label = date == null ? 'Select date' : '${date.day}/${date.month}/${date.year}';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF6C47FF)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: date == null ? const Color(0xFFAEAEB2) : const Color(0xFF1C1C1E),
                  fontWeight: date == null ? FontWeight.normal : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
