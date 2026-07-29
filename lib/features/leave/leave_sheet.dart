import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import '../../core/network/models/widget.dart';
import '../../core/network/provider/widget.dart';
import '../common/widget.dart';

class LeaveFormSheet extends StatefulWidget {
  final String personnelId;
  final HrLeaveRequest? existing; // null → create mode
  final Future<bool> Function(HrLeaveRequestFormData) onSave;

  const LeaveFormSheet({
    super.key,
    required this.personnelId,
    required this.onSave,
    this.existing,
  });

  @override
  State<LeaveFormSheet> createState() => _LeaveFormSheetState();
}

class _LeaveFormSheetState extends State<LeaveFormSheet> {
  String? _selectedLeaveType;
  final _reasonCtrl = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _saving = false;
  bool _localOverlapError =
      false; // 💡 Tracks overlap state dynamically to force immediate UI re-rendering

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final r = widget.existing!;
      _selectedLeaveType = r.leaveType;
      _reasonCtrl.text = r.reason ?? '';
      _fromDate = DateTime.parse(r.startDate);
      _toDate = DateTime.parse(r.endDate);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _checkOverlapOnSelection(),
      );
    }
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  bool _hasOverlap() {
    if (_fromDate == null || _toDate == null) return false;

    final provider = context.read<LeaveProvider>();

    // Only PENDING and APPROVED requests actually occupy calendar days.
    final blockingRequests = provider.myRequests.where(
      (r) =>
          r.status == HrLeaveRequestStatus.pending ||
          r.status == HrLeaveRequestStatus.approved,
    );

    for (final request in blockingRequests) {
      if (_isEdit && request.id == widget.existing!.id) continue;

      final existingStart = DateTime.parse(request.startDate);
      final existingEnd = DateTime.parse(request.endDate);

      final isOverlapping =
          !_fromDate!.isAfter(existingEnd) && !_toDate!.isBefore(existingStart);
      if (isOverlapping) return true;
    }
    return false;
  }

  void _checkOverlapOnSelection() {
    final overlap = _hasOverlap();
    if (!mounted) return;
    setState(() {
      _localOverlapError = overlap;
    });
  }

  int get _totalDays {
    if (_fromDate == null || _toDate == null) return 0;
    return _toDate!.difference(_fromDate!).inDays + 1;
  }

  Future<void> _pickDate({
    required bool isFrom,
    required LeaveProvider leaveProvider,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _fromDate : _toDate) ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                (isDark ? const ColorScheme.dark() : const ColorScheme.light())
                    .copyWith(
                      primary: Theme.of(context).primaryColor,
                      surface: Theme.of(context).cardColor,
                      onSurface: isDark ? Colors.white : Colors.black87,
                    ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;

    // 💡 1. Unconditionally clear the provider error state right away on new picker action
    leaveProvider.clearError();

    setState(() {
      if (isFrom) {
        _fromDate = picked;
        if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
          _toDate = null;
        }
      } else {
        if (_fromDate != null && picked.isBefore(_fromDate!)) {
          showMessage(
            'End date cannot be before start date',
            context,
            status: MessageStatus.error,
          );
          return;
        }
        _toDate = picked;
      }
    });

    // 💡 2. Recalculate overlap instantly to refresh text dynamically or drop the error away
    _checkOverlapOnSelection();
  }

  Future<void> _submit() async {
    if (_selectedLeaveType == null) {
      showMessage(
        'Please select a leave type',
        context,
        status: MessageStatus.error,
      );
      return;
    }
    if (_fromDate == null || _toDate == null) {
      showMessage(
        'Please select start and end dates',
        context,
        status: MessageStatus.error,
      );
      return;
    }

    // Prevent submissions if overlapping dates are selected
    if (_localOverlapError) {
      showMessage(
        'Selected dates overlap with an existing leave request.',
        context,
        status: MessageStatus.error,
      );
      return;
    }

    setState(() => _saving = true);
    final data = HrLeaveRequestFormData(
      personnelId: widget.personnelId,
      leaveType: _selectedLeaveType!.toUpperCase(),
      startDate: _isoDate(_fromDate!),
      endDate: _isoDate(_toDate!),
      totalDays: _totalDays,
      reason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
    );
    final success = await widget.onSave(data);
    if (!mounted) return;
    if (!success) {
      setState(() {
        _saving = false;
      });
    }
  }

  String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}'
      '-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 100 + bottomInset),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isEdit ? 'Edit Leave Request' : 'New Leave Request',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // ... [Keep your Type Dropdown Selection and Reason Field layout unchanged here] ...
            _label('Leave Type'),
            DropdownButtonFormField<String>(
              value:
                  availableLeaveTypes.any(
                    (type) =>
                        type.toUpperCase() == _selectedLeaveType?.toUpperCase(),
                  )
                  ? availableLeaveTypes.firstWhere(
                      (type) =>
                          type.toUpperCase() ==
                          _selectedLeaveType?.toUpperCase(),
                    )
                  : null,
              hint: const Text('Select leave type'),
              items: availableLeaveTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) => setState(() => _selectedLeaveType = value),
              decoration: InputDecoration(
                hintStyle: const TextStyle(
                  color: Color(0xFFAEAEB2),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
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
                        _fromDate,
                        () => _pickDate(
                          isFrom: true,
                          leaveProvider: context.read<LeaveProvider>(),
                        ),
                      ),
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
                        _toDate,
                        () => _pickDate(
                          isFrom: false,
                          leaveProvider: context.read<LeaveProvider>(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // ── Display Error Message Dynamically based on the reactive state check ──
            if (_localOverlapError) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Selected dates overlap with an existing leave request. Please choose another date.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_totalDays > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
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
            _field(_reasonCtrl, 'Brief reason for leave…', maxLines: 3),
            const SizedBox(height: 24),

            // Submit Button
            GestureDetector(
              // Disable tap trigger if saving OR if there's an active calendar overlap conflict
              onTap: (_saving || _localOverlapError) ? null : _submit,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: (_saving || _localOverlapError)
                      ? Colors.grey.withOpacity(0.5) // Grayed out if disabled
                      : Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: _saving
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: LoadingAnimationWidget.staggeredDotsWave(
                          color: Colors.white,
                          size: 20,
                        ),
                      )
                    : Text(
                        _isEdit ? 'Update Request' : 'Submit Request',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );

  Widget _field(TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.characters,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFAEAEB2), fontSize: 13),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 15,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: date == null
                      ? Theme.of(context).hintColor
                      : Theme.of(context).brightness == Brightness.dark
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
