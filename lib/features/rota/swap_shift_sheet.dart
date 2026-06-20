import 'package:flutter/material.dart';
import '../../core/network/models/widget.dart';

class SwapShiftSheet extends StatefulWidget {
  final List<RotaEvent>   myShifts;
  final List<StaffMember> staffMembers;
  final ValueChanged<Map<String, dynamic>> onSubmit;

  const SwapShiftSheet({
    super.key,
    required this.myShifts,
    required this.staffMembers,
    required this.onSubmit,
  });

  @override
  State<SwapShiftSheet> createState() => _SwapShiftSheetState();
}

class _SwapShiftSheetState extends State<SwapShiftSheet> {
  final _searchController  = TextEditingController();
  final _reasonController  = TextEditingController();

  StaffMember? _selectedStaff;
  RotaEvent?   _selectedTheirShift;
  bool         _showStaffList = false;
  String       _searchQuery   = '';

  // The user's own upcoming shift (pre-filled from their next shift)
  RotaEvent? get _myNextShift =>
      widget.myShifts.where((e) => !e.date.isBefore(DateTime.now())).isNotEmpty
          ? widget.myShifts.where((e) => !e.date.isBefore(DateTime.now())).first
          : widget.myShifts.isNotEmpty ? widget.myShifts.last : null;

  List<StaffMember> get _filteredStaff => _searchQuery.isEmpty
      ? widget.staffMembers
      : widget.staffMembers.where((s) =>
  s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      s.employeeId.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

  // Sample shifts for selected staff member — replace with API call
  List<RotaEvent> get _theirShifts => _selectedStaff == null ? [] : [
    RotaEvent(id: 'a', staffName: _selectedStaff!.name, role: 'Nurse', ward: 'Ward 1',
        type: ShiftType.morning,
        date: DateTime.now().add(const Duration(days: 2)),
        startTime: '08:00', endTime: '17:00'),
    RotaEvent(id: 'b', staffName: _selectedStaff!.name, role: 'Nurse', ward: 'Ward 1',
        type: ShiftType.morning,
        date: DateTime.now().add(const Duration(days: 3)),
        startTime: '08:00', endTime: '17:00'),
    RotaEvent(id: 'c', staffName: _selectedStaff!.name, role: 'Nurse', ward: 'Ward 1',
        type: ShiftType.night,
        date: DateTime.now().add(const Duration(days: 4)),
        startTime: '20:00', endTime: '06:00'),
    RotaEvent(id: 'd', staffName: _selectedStaff!.name, role: 'Nurse', ward: 'Ward 1',
        type: ShiftType.morning,
        date: DateTime.now().add(const Duration(days: 5)),
        startTime: '08:00', endTime: '17:00'),
    RotaEvent(id: 'e', staffName: _selectedStaff!.name, role: 'Nurse', ward: 'Ward 1',
        type: ShiftType.morning,
        date: DateTime.now().add(const Duration(days: 6)),
        startTime: '08:00', endTime: '17:00'),
  ];

  String get _swapSummary {
    if (_myNextShift == null || _selectedStaff == null || _selectedTheirShift == null) {
      return '';
    }
    return 'You are requesting to swap your ${_myNextShift!.type.label} shift '
        'on ${_formatDate(_myNextShift!.date)} (${_myNextShift!.startTime} - ${_myNextShift!.endTime}) '
        'with ${_selectedStaff!.name}\'s ${_selectedTheirShift!.type.label} shift '
        'on ${_formatDate(_selectedTheirShift!.date)} '
        '(${_selectedTheirShift!.startTime} - ${_selectedTheirShift!.endTime}).';
  }

  bool get _canSubmit =>
      _selectedStaff != null && _selectedTheirShift != null;

  void _submit() {
    if (!_canSubmit) return;
    widget.onSubmit({
      'myShift':      _myNextShift?.id,
      'theirShift':   _selectedTheirShift?.id,
      'staffId':      _selectedStaff?.id,
      'reason':       _reasonController.text.trim(),
      'summary':      _swapSummary,
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 100 + bottom),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.black12, borderRadius: BorderRadius.circular(2)),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Your shift banner ──────────────────────────────────────
                  if (_myNextShift != null) _buildMyShiftBanner(),
                  const SizedBox(height: 20),

                  // ── Select who to swap with ────────────────────────────────
                  _label('Select who to swap with'),
                  _buildStaffSearch(),
                  if (_showStaffList) _buildStaffList(),
                  const SizedBox(height: 16),

                  // ── Select their shift ─────────────────────────────────────
                  if (_selectedStaff != null) ...[
                    _label("Select the person's shift you want to take"),
                    const SizedBox(height: 8),
                    _buildTheirShiftList(),
                    const SizedBox(height: 16),
                  ],

                  // ── Reason ─────────────────────────────────────────────────
                  _label('Reason (optional)'),
                  const SizedBox(height: 8),
                  _buildTextField(_reasonController, 'Enter reason...', maxLines: 3),
                  const SizedBox(height: 16),

                  // ── Swap summary ───────────────────────────────────────────
                  if (_swapSummary.isNotEmpty) ...[
                    _label('Swap Summary'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _swapSummary,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF3C3C43), height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else
                    const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Buttons ────────────────────────────────────────────────────────
          _buildSubmitButton(),
          const SizedBox(height: 10),
          _buildCancelButton(),
        ],
      ),
    );
  }

  // ── My shift banner ──────────────────────────────────────────────────────────
  Widget _buildMyShiftBanner() {
    final shift = _myNextShift!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
                color: shift.type.bgColor, shape: BoxShape.circle),
            child: Icon(Icons.info_outline, size: 16, color: shift.type.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your Shift : ${_fullDateLabel(shift.date)} - '
                  '${shift.type.label} (${shift.startTime} - ${shift.endTime})',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close, size: 18, color: Color(0xFF8E8E93)),
          ),
        ],
      ),
    );
  }

  // ── Staff search ─────────────────────────────────────────────────────────────
  Widget _buildStaffSearch() {
    return GestureDetector(
      onTap: () => setState(() => _showStaffList = !_showStaffList),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 18, color: Color(0xFF8E8E93)),
            const SizedBox(width: 10),
            Expanded(
              child: _selectedStaff != null
                  ? Text(_selectedStaff!.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))
                  : TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                onTap: () => setState(() => _showStaffList = true),
                decoration: const InputDecoration(
                  hintText: 'Search by name or call number',
                  hintStyle: TextStyle(color: Color(0xFFAEAEB2), fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_selectedStaff != null)
              GestureDetector(
                onTap: () => setState(() {
                  _selectedStaff     = null;
                  _selectedTheirShift = null;
                  _searchController.clear();
                }),
                child: const Icon(Icons.close, size: 16, color: Color(0xFF8E8E93)),
              ),
          ],
        ),
      ),
    );
  }

  // ── Staff list ───────────────────────────────────────────────────────────────
  Widget _buildStaffList() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5EA)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: _filteredStaff.map((staff) {
          final isSelected = _selectedStaff?.id == staff.id;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedStaff      = staff;
              _selectedTheirShift = null;
              _showStaffList      = false;
              _searchController.clear();
              _searchQuery        = '';
            }),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6C47FF) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${staff.name}  ${staff.employeeId}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : const Color(0xFF1C1C1E),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Their shift list ─────────────────────────────────────────────────────────
  Widget _buildTheirShiftList() {
    return Column(
      children: _theirShifts.map((shift) {
        final isSelected = _selectedTheirShift?.id == shift.id;
        return GestureDetector(
          onTap: () => setState(() => _selectedTheirShift = shift),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? shift.type.color.withOpacity(0.12)
                  : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: shift.type.color, width: 1.5)
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: shift.type.bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    shift.type.label,
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: shift.type.color),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_fullDateLabel(shift.date)} ${shift.startTime} - ${shift.endTime}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF3C3C43)),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
  );

  Widget _buildTextField(TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFAEAEB2), fontSize: 13),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildSubmitButton() => GestureDetector(
    onTap: _canSubmit ? _submit : null,
    child: Container(
      width: double.infinity, height: 52,
      decoration: BoxDecoration(
        color: _canSubmit ? const Color(0xFF27AE60) : const Color(0xFFE5E5EA),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text('Submit',
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600,
              color: _canSubmit ? Colors.white : const Color(0xFF8E8E93))),
    ),
  );

  Widget _buildCancelButton() => GestureDetector(
    onTap: () => Navigator.pop(context),
    child: Container(
      width: double.infinity, height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEB),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: const Text('Cancel',
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFE74C3C))),
    ),
  );

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _fullDateLabel(DateTime d) {
    const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
  }
}
