import 'package:flutter/material.dart';
import '../../../core/network/models/availability_model.dart';

class AvailabilitySheet extends StatefulWidget {
  final String                                    personnelId;
  final DateTime?                                 preselectedDate;
  final ValueChanged<HrAvailabilityBulkSlot>      onSubmit;

  const AvailabilitySheet({
    super.key,
    required this.personnelId,
    this.preselectedDate,
    required this.onSubmit,
  });

  @override
  State<AvailabilitySheet> createState() => _AvailabilitySheetState();
}

class _AvailabilitySheetState extends State<AvailabilitySheet> {
  final _notesController     = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController   = TextEditingController();

  HrAvailabilityStatus? _status;
  DateTime?             _date;
  HrTimeSlot            _timeSlot = HrTimeSlot.fullDay;

  @override
  void initState() {
    super.initState();
    _date = widget.preselectedDate;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _status != null && _date != null;

  bool get _needsCustomTime => _timeSlot == HrTimeSlot.custom;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF6C47FF),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (!_canSubmit) return;

    final dateStr = '${_date!.year}-'
        '${_date!.month.toString().padLeft(2, '0')}-'
        '${_date!.day.toString().padLeft(2, '0')}';

    widget.onSubmit(
      HrAvailabilityBulkSlot(
        date:         dateStr,
        timeSlot:     _timeSlot,
        availability: _status!,
        startTime: _needsCustomTime && _startTimeController.text.trim().isNotEmpty
            ? _startTimeController.text.trim()
            : null,
        endTime: _needsCustomTime && _endTimeController.text.trim().isNotEmpty
            ? _endTimeController.text.trim()
            : null,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        deptId: null, // populated by backend from personnelId's dept
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle + Title ────────────────────────────────────────────────
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C47FF).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                        Icons.info_outline, size: 16, color: Color(0xFF6C47FF)),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Set your availability',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Choose Availability ───────────────────────────────────────────
            _label('Choose Availability'),
            _buildStatusDropdown(),
            const SizedBox(height: 16),

            // ── Date + Time Slot ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Select Date'),
                      _buildDatePicker(),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Time Slot'),
                      _buildTimeSlotDropdown(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Custom time fields (only shown for CUSTOM slot) ───────────────
            if (_needsCustomTime) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Start Time'),
                        _buildTimeField(_startTimeController, 'e.g. 08:00'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('End Time'),
                        _buildTimeField(_endTimeController, 'e.g. 17:00'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // ── Notes ─────────────────────────────────────────────────────────
            _label('Notes (optional)'),
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'eg: available after 2pm only',
                hintStyle: const TextStyle(
                    color: Color(0xFFAEAEB2), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF2F2F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),

            // ── Submit ────────────────────────────────────────────────────────
            GestureDetector(
              onTap: _canSubmit ? _submit : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity, height: 52,
                decoration: BoxDecoration(
                  color: _canSubmit
                      ? const Color(0xFF27AE60)
                      : const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Submit',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _canSubmit ? Colors.white : const Color(0xFF8E8E93),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── Cancel ────────────────────────────────────────────────────────
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity, height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE74C3C),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────────

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<HrAvailabilityStatus>(
          value: _status,
          isExpanded: true,
          hint: const Text(
            'Select availability',
            style: TextStyle(color: Color(0xFFAEAEB2), fontSize: 13),
          ),
          icon: const Icon(
              Icons.keyboard_arrow_down, color: Color(0xFF6C47FF)),
          items: HrAvailabilityStatus.values.map((s) {
            return DropdownMenuItem(
              value: s,
              child: Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                        color: s.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(s.label, style: const TextStyle(fontSize: 14)),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => _status = v),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    final label = _date == null
        ? 'dd/mm/yy'
        : '${_date!.day.toString().padLeft(2, '0')}/'
        '${_date!.month.toString().padLeft(2, '0')}/'
        '${_date!.year}';

    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: _date == null
                      ? const Color(0xFFAEAEB2)
                      : const Color(0xFF1C1C1E),
                ),
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              size: 15, color: Color(0xFF6C47FF),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<HrTimeSlot>(
          value: _timeSlot,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 18, color: Color(0xFF6C47FF),
          ),
          style: const TextStyle(fontSize: 13, color: Color(0xFF1C1C1E)),
          items: HrTimeSlot.values.map((t) {
            return DropdownMenuItem(value: t, child: Text(t.label));
          }).toList(),
          onChanged: (v) => setState(() => _timeSlot = v!),
        ),
      ),
    );
  }

  Widget _buildTimeField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(fontSize: 13),
      keyboardType: TextInputType.datetime,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFAEAEB2), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF8E8E93),
      ),
    ),
  );
}
