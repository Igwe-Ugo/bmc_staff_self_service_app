import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import '../../core/network/models/widget.dart'; // RotaEvent, StaffMember, HrSwapRequestPayload
import '../../core/network/provider/widget.dart'; // RotaProvider

class SwapShiftSheet extends StatefulWidget {
  final List<RotaEvent> myShifts;
  final List<StaffMember> staffMembers;
  final DateTime? defaultSelectedDate; // Passed from the tapped calendar date
  final ValueChanged<HrSwapRequestPayload> onSubmit;

  const SwapShiftSheet({
    super.key,
    required this.myShifts,
    required this.staffMembers,
    this.defaultSelectedDate,
    required this.onSubmit,
  });

  @override
  State<SwapShiftSheet> createState() => _SwapShiftSheetState();
}

class _SwapShiftSheetState extends State<SwapShiftSheet> {
  final _reasonController = TextEditingController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  RotaEvent? _selectedMyShift;
  StaffMember? _selectedStaff;
  RotaEvent? _selectedTheirShift;

  bool _isSearchingStaff = false;
  String _searchQuery = '';

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _initializeDefaultShift();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _initializeDefaultShift() {
    if (widget.defaultSelectedDate != null && widget.myShifts.isNotEmpty) {
      final match = widget.myShifts.firstWhere(
            (s) => _isSameDay(s.date, widget.defaultSelectedDate!),
        orElse: () => widget.myShifts.first,
      );
      _selectedMyShift = match;
    } else if (widget.myShifts.isNotEmpty) {
      _selectedMyShift = widget.myShifts.first;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<StaffMember> get _filteredStaff {
    if (_searchQuery.isEmpty) return widget.staffMembers;
    return widget.staffMembers
        .where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rotaProvider = context.watch<RotaProvider>();

    bool showSummary = _selectedMyShift != null && _selectedStaff != null && _selectedTheirShift != null;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(context).viewInsets.bottom + 120),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Request Shift Swap',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Lexend'),
            ),
            const SizedBox(height: 20),

            // 1. Select Your Shift Dropdown
            _buildFieldLabel('Your Shift to Swap'),
            DropdownButtonFormField<RotaEvent>(
              // safely find the exact instance matching by ID within the current list
              value: widget.myShifts.any((s) => s.id == _selectedMyShift?.id)
                  ? widget.myShifts.firstWhere((s) => s.id == _selectedMyShift?.id)
                  : null,
              dropdownColor: theme.cardColor,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.primaryColor),
              decoration: _inputDecoration(prefixIcon: Iconsax.calendar),
              style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w500),
              items: widget.myShifts.map((s) => DropdownMenuItem(
                value: s,
                child: Text('${s.type.label} (${DateFormat('dd MMM yyyy').format(s.date)})'),
              )).toList(),
              onChanged: (val) => setState(() => _selectedMyShift = val),
            ),
            const SizedBox(height: 16),

            // 2. Searchable Colleague Selection Field
            _buildFieldLabel('Select who to swap with'),
            TextFormField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: _inputDecoration(
                prefixIcon: Iconsax.search_normal,
                hintText: _selectedStaff?.name ?? 'Search staff member...',
                suffixIcon: _selectedStaff != null
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() {
                    _selectedStaff = null;
                    _selectedTheirShift = null;
                    _searchController.clear();
                    _searchQuery = '';
                  }),
                )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
              onTap: () => setState(() => _isSearchingStaff = true),
            ),

            // Interactive Dropdown Results overlay
            if (_isSearchingStaff) ...[
              Container(
                height: 180,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredStaff.length,
                  itemBuilder: (context, index) {
                    final staff = _filteredStaff[index];
                    return ListTile(
                      dense: true,
                      title: Text(staff.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(staff.employeeId, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                      onTap: () {
                        setState(() {
                          _selectedStaff = staff;
                          _selectedTheirShift = null;
                          _searchController.text = staff.name;
                          _isSearchingStaff = false;
                        });
                        _searchFocusNode.unfocus();
                        rotaProvider.loadDeptStaffShift(staff.id, DateFormat('yyyy-MM').format(_selectedMyShift?.date ?? DateTime.now()));
                      },
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),

            // 3. Select Partner Shift Dropdown
            if (_selectedStaff != null) ...[
              _buildFieldLabel("Select the persons shift you want to take"),
              DropdownButtonFormField<RotaEvent>(
                value: rotaProvider.theirAvailableShifts.any((s) => s.id == _selectedTheirShift?.id)
                    ? rotaProvider.theirAvailableShifts.firstWhere((s) => s.id == _selectedTheirShift?.id)
                    : null,
                dropdownColor: theme.cardColor,
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.primaryColor),
                decoration: _inputDecoration(prefixIcon: Icons.swap_horiz_rounded),
                style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w500),
                hint: const Text('Choose target shift slot'),
                items: rotaProvider.theirAvailableShifts.map((s) => DropdownMenuItem(
                  value: s,
                  child: Text('${s.type.label} (${DateFormat('dd MMM').format(s.date)} • ${s.startTime}-${s.endTime})'),
                )).toList(),
                onChanged: (val) => setState(() => _selectedTheirShift = val),
              ),
              const SizedBox(height: 16),
            ],

            // 4. Input Open Reason (Optional)
            _buildFieldLabel('Reason (Optional)'),
            TextField(
              controller: _reasonController,
              maxLines: 2,
              decoration: _inputDecoration(prefixIcon: Icons.notes_rounded, hintText: 'Enter reason for exchange...'),
            ),
            const SizedBox(height: 24),

            // 5. Shift Swap Summary Section
            if (showSummary) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.primaryColor.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: theme.primaryColor, size: 18),
                        const SizedBox(width: 8),
                        Text('Swap Summary', style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor, fontSize: 13)),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildSummaryRow('You Give:', '${_selectedMyShift!.type.label} (${DateFormat('dd MMM').format(_selectedMyShift!.date)})'),
                    const SizedBox(height: 6),
                    _buildSummaryRow('Partner:', _selectedStaff!.name),
                    const SizedBox(height: 6),
                    _buildSummaryRow('You Receive:', '${_selectedTheirShift!.type.label} (${DateFormat('dd MMM').format(_selectedTheirShift!.date)})'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Submit Buttons Action Row
            GestureDetector(
              // Disable tap trigger if saving OR if there's an active calendar overlap conflict
              onTap: showSummary
                ? () {
                setState(() {
                  _saving = true;
                });
                    widget.onSubmit(HrSwapRequestPayload(
                      fromAssignmentId: _selectedMyShift!.id,
                      toAssignmentId: _selectedTheirShift!.id,
                      toPersonnelId: _selectedStaff!.id,
                      reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
                    ));
                  }
                    : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: _saving
                      ? Colors.grey.withOpacity(0.5) // Grayed out if disabled
                      : Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: _saving
                    ? SizedBox(
                  width: 22, height: 22,
                  child: LoadingAnimationWidget.staggeredDotsWave(color: Colors.white, size: 40),
                )
                    : Text(
                  'Submit Request',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 10,),
            GestureDetector(
              // Disable tap trigger if saving OR if there's an active calendar overlap conflict
              onTap: () => Navigator.pop(context),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: Color(0xFFFBE3E3),
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Cancel Request',
                  style: TextStyle(
                      color: Colors.red,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSummaryRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  InputDecoration _inputDecoration({required IconData prefixIcon, String? hintText, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, size: 18, color: Colors.grey.shade500),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: Theme.of(context).scaffoldBackgroundColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5)),
    );
  }
}

extension on Color {
  Color replaceWithNoOpIfNull(Color fallback) => this;
}