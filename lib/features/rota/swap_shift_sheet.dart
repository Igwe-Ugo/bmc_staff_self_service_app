import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/network/models/widget.dart';

class SwapShiftSheet extends StatefulWidget {
  final List<RotaEvent> myShifts;
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
  final _searchController = TextEditingController();
  final _reasonController = TextEditingController();

  RotaEvent? _selectedMyShift;
  StaffMember? _selectedStaff;
  RotaEvent? _selectedTheirShift;
  bool _showStaffList = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.myShifts.isNotEmpty) {
      _selectedMyShift = widget.myShifts.first;
    }
  }

  List<StaffMember> get _filteredStaff => _searchQuery.isEmpty
      ? widget.staffMembers
      : widget.staffMembers
      .where((s) =>
  s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      s.employeeId.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  // Requirement 3: Only extract roster entries associated specifically with the chosen partner
  List<RotaEvent> get _theirAvailableShifts {
    if (_selectedStaff == null) return [];
    // If your RotaEvent schema maps partner links or references, filter here.
    // Assuming staffName or coworker logic match or fallback to unassigned slots for demo:
    return widget.myShifts.where((e) => e.staffName.toLowerCase() == _selectedStaff!.name.toLowerCase()).toList();
  }

  bool get _canSubmit =>
      _selectedMyShift != null &&
          _selectedStaff != null &&
          _selectedTheirShift != null &&
          _reasonController.text.trim().isNotEmpty;

  void _submit() {
    if (!_canSubmit) return;
    widget.onSubmit({
      'myShiftId': _selectedMyShift!.id,
      'targetStaffId': _selectedStaff!.id,
      'targetShiftId': _selectedTheirShift!.id,
      'reason': _reasonController.text.trim(),
    });
  }

  String _formatShiftText(RotaEvent? shift) {
    if (shift == null) return '';
    return '${DateFormat('EEE, MMM d').format(shift.date)} — ${shift.type.label} (${shift.startTime})';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
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
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Request Shift Swap',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Lexend',
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Swap an assigned timeline slot securely with an authorized team coworker.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            // SECTION 1: Your Selected Shift Card[cite: 14]
            const Text(
              'YOUR SHIFT TO SWAP',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            _buildMyShiftDropdown(),
            const SizedBox(height: 20),

            // Requirement 3: Coworker search field comes first before their shift selection
            const Text(
              'SWAP WITH COWORKER',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            _buildCoworkerSearchField(),
            const SizedBox(height: 20),

            // Requirement 3: Dropdown displaying only chosen partner's shift days
            const Text(
              'THEIR SHIFT TO RECEIVE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            _buildTheirShiftDropdown(),
            const SizedBox(height: 20),

            // SECTION 4: Contextual Reason text area[cite: 14]
            const Text(
              'REASON FOR SWAP',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 2,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Provide context for this switch request...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.all(14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Requirement 4: On-sheet swap breakdown summary widget visualization
            if (_selectedStaff != null && _selectedMyShift != null && _selectedTheirShift != null) ...[
              _buildSwapSummaryCard(),
              const SizedBox(height: 20),
            ],

            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildMyShiftDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<RotaEvent>(
          value: _selectedMyShift,
          isExpanded: true,
          hint: const Text('Select one of your shifts', style: TextStyle(fontSize: 13)),
          items: widget.myShifts.map((shift) {
            return DropdownMenuItem<RotaEvent>(
              value: shift,
              child: Text(
                _formatShiftText(shift),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedMyShift = val),
        ),
      ),
    );
  }

  // Requirement 2: Textfield tracking interactive real-time dropdown results overlay
  Widget _buildCoworkerSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
              _showStaffList = true;
            });
          },
          onTap: () => setState(() => _showStaffList = true),
          decoration: InputDecoration(
            hintText: 'Search partner name or identifier ID...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _selectedStaff != null
                ? IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () {
                setState(() {
                  _selectedStaff = null;
                  _selectedTheirShift = null;
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
            )
                : null,
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blueAccent),
            ),
          ),
        ),
        if (_showStaffList && _filteredStaff.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 160),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredStaff.length,
              itemBuilder: (context, idx) {
                final staff = _filteredStaff[idx];
                return ListTile(
                  dense: true,
                  title: Text(staff.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text(staff.employeeId, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                  onTap: () {
                    setState(() {
                      _selectedStaff = staff;
                      _searchController.text = staff.name;
                      _showStaffList = false;
                      _selectedTheirShift = null; // Flush stale allocations
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTheirShiftDropdown() {
    final available = _theirAvailableShifts;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: _selectedStaff == null ? Colors.grey.shade100 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<RotaEvent>(
          value: _selectedTheirShift,
          isExpanded: true,
          disabledHint: Text(
            _selectedStaff == null ? 'Choose a coworker first' : 'No available shifts found',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          hint: const Text('Select target replacement shift', style: TextStyle(fontSize: 13)),
          items: available.map((shift) {
            return DropdownMenuItem<RotaEvent>(
              value: shift,
              child: Text(
                _formatShiftText(shift),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
          onChanged: _selectedStaff == null ? null : (val) => setState(() => _selectedTheirShift = val),
        ),
      ),
    );
  }

  // Requirement 4: Explicit pre-flight layout summarizing parameters
  Widget _buildSwapSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF27AE60).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.swap_horiz, color: Color(0xFF27AE60), size: 18),
              SizedBox(width: 6),
              Text(
                'Swap Summary',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF27AE60), letterSpacing: 0.3),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
              children: [
                const TextSpan(text: 'You get: ', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: '${_formatShiftText(_selectedTheirShift)}\n'),
                const TextSpan(text: 'You give: ', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: '${_formatShiftText(_selectedMyShift)}\n'),
                const TextSpan(text: 'With: ', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: _selectedStaff?.name ?? ''),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _canSubmit ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
              disabledBackgroundColor: Colors.grey.shade200,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              'Submit Request',
              style: TextStyle(
                color: _canSubmit ? Colors.white : Colors.grey.shade400,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
