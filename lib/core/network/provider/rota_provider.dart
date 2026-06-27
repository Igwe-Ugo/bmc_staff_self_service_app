// lib/features/rota/providers/rota_provider.dart
import 'package:bmc_app/core/network/provider/widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/widget.dart';
import '../services/widget.dart';

enum RotaLoadState { idle, loading, loaded, error }
enum SwapSubmitState { idle, submitting, success, error }

class RotaProvider extends ChangeNotifier {
  final RotaService _service = RotaService();

  // ── State ───────────────────────────────────────────────────────────────

  RotaLoadState _loadState = RotaLoadState.idle;
  String? _errorMessage;

  List<HrMyShift> _myShifts = [];
  List<RotaEvent> _rotaEvents = [];
  List<StaffMember> _staffMembers = [];

  // Cache to avoid duplicate API calls for the same month
  final Set<String> _fetchedMonths = {};

  RotaLoadState get loadState => _loadState;
  String? get errorMessage => _errorMessage;
  List<RotaEvent> get rotaEvents => _rotaEvents;
  List<StaffMember> get staffMembers => _staffMembers;

  // ── Swap State ───────────────────────────────────────────────────────────

  SwapSubmitState _swapState = SwapSubmitState.idle;
  HrShiftSwapResponse? _lastSwap;
  String? _swapError;

  SwapSubmitState get swapState => _swapState;
  HrShiftSwapResponse? get lastSwap => _lastSwap;
  String? get swapError => _swapError;

  // ── Helper to get user info from UserProvider ────────────────────────────

  String _getCurrentUserName(BuildContext context) {
    try {
      final userProvider = context.read<UserProvider>();
      final user = userProvider.user;
      return user?.username ?? 'User';
    } catch (e) {
      return 'User';
    }
  }

  String _getCurrentUserId(BuildContext context) {
    try {
      final userProvider = context.read<UserProvider>();
      final user = userProvider.user;
      return user?.id ?? '';
    } catch (e) {
      return '';
    }
  }

  // ── Load Shifts ──────────────────────────────────────────────────────────

  Future<void> loadShiftsForMonth(BuildContext context, DateTime month) async {
    final monthKey = DateFormat('yyyy-MM').format(month);
    if (_fetchedMonths.contains(monthKey)) return;

    _loadState = RotaLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final shifts = await _service.fetchMyShifts(month: monthKey);
      _fetchedMonths.add(monthKey);

      // Merge and deduplicate
      final existing = {for (var s in _myShifts) s.assignmentId: s};
      for (var s in shifts) {
        existing[s.assignmentId] = s;
      }

      _myShifts = existing.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      _rebuildRotaEvents(context);
      _loadState = RotaLoadState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _loadState = RotaLoadState.error;
    }

    notifyListeners();
  }

  Future<void> refreshShiftsForMonth(BuildContext context, DateTime month) async {
    final key = DateFormat('yyyy-MM').format(month);
    _fetchedMonths.remove(key);
    await loadShiftsForMonth(context, month);
  }

  void _rebuildRotaEvents(BuildContext context) {
    final userName = _getCurrentUserName(context);
    _rotaEvents = _myShifts.map((shift) => shift.toRotaEvent(
      staffName: userName,
    )).toList();
  }

  // ── Eligible Staff for Swap ───────────────────────────────────────────────

  Future<void> loadEligibleStaff(String shiftId) async {
    try {
      _staffMembers = await _service.fetchEligibleStaff(shiftId);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load eligible staff: $e');
      // Non-critical, keep existing list
    }
  }

  // ── Submit Swap ───────────────────────────────────────────────────────────

  Future<bool> submitSwap(HrSwapRequestPayload payload) async {
    _swapState = SwapSubmitState.submitting;
    _swapError = null;
    _lastSwap = null;
    notifyListeners();

    try {
      final result = await _service.submitSwapRequest(payload);
      _lastSwap = result;
      _swapState = SwapSubmitState.success;

      // Refresh current month data
      _fetchedMonths.clear();
      notifyListeners();
      return true;
    } catch (e) {
      _swapError = e.toString();
      _swapState = SwapSubmitState.error;
      notifyListeners();
      return false;
    }
  }

  void resetSwapState() {
    _swapState = SwapSubmitState.idle;
    _swapError = null;
    _lastSwap = null;
    notifyListeners();
  }

  // ── Filtered Events (Used by RotaScreen) ──────────────────────────────────

  List<RotaEvent> filteredEvents({
    required RotaFilter filter,
    required DateTime focusedDay,
    DateTime? selectedDay,
  }) {
    switch (filter) {
      case RotaFilter.allStatus:
        return _rotaEvents;

      case RotaFilter.daily:
        final target = selectedDay ?? DateTime.now();
        return _rotaEvents.where((e) => _sameDay(e.date, target)).toList();

      case RotaFilter.weekly:
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        return _rotaEvents
            .where((e) => !e.date.isBefore(startOfWeek) && e.date.isBefore(endOfWeek))
            .toList();

      case RotaFilter.monthly:
        return _rotaEvents
            .where((e) =>
        e.date.month == focusedDay.month && e.date.year == focusedDay.year)
            .toList();

      case RotaFilter.yearly:
        return _rotaEvents.where((e) => e.date.year == focusedDay.year).toList();
    }
  }

  Map<ShiftType, int> yearlyCounts(List<RotaEvent> events) {
    final counts = <ShiftType, int>{};
    for (final e in events) {
      counts[e.type] = (counts[e.type] ?? 0) + 1;
    }
    return counts;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void clearUserData() {
    _myShifts = [];
    _rotaEvents = [];
    _fetchedMonths.clear();
    notifyListeners();
  }
}
