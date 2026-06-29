import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../models/widget.dart';
import '../services/widget.dart';

enum RotaLoadState { idle, loading, loaded, error }
enum SwapSubmitState { idle, submitting, success, error }
enum RotaFilter { allStatus, daily, weekly, monthly, yearly }

class RotaProvider extends ChangeNotifier {
  final RotaService _service = RotaService();

  // ── State ───────────────────────────────────────────────────────────────
  String? _errorMessage;
  RotaLoadState _loadState = RotaLoadState.idle;
  List<RotaEvent> _rotaEvents = [];
  List<StaffMember> _staffMembers = [];
  List<RotaEvent> _theirAvailableShifts = [];

  SwapSubmitState _swapState = SwapSubmitState.idle;
  String? _swapError;

  RotaLoadState get loadState => _loadState;
  String? get errorMessage => _errorMessage;
  List<RotaEvent> get rotaEvents => _rotaEvents;
  List<StaffMember> get staffMembers => _staffMembers;
  List<RotaEvent> get theirAvailableShifts => _theirAvailableShifts;
  SwapSubmitState get swapState => _swapState;
  String? get swapError => _swapError;

  // ── Load Shifts ──────────────────────────────────────────────────────────

  Future<void> loadShiftsForMonth(BuildContext context, DateTime monthDate, {String? deptId}) async {
    _loadState = RotaLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final monthStr = DateFormat('yyyy-MM').format(monthDate);
      final shifts = await _service.fetchMyShifts(month: monthStr);
      _rotaEvents = shifts.map((s) => RotaEvent.fromMyShift(s)).toList();
      if (deptId != null) {
        _staffMembers = await _service.fetchDeptStaff(deptId);
      }
      _loadState = RotaLoadState.loaded;
    } catch (e) {
      _loadState = RotaLoadState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> loadDeptStaffShift(String personnelId, String periodId) async {
    _theirAvailableShifts = [];
    notifyListeners();
    try {
      _theirAvailableShifts = await _service.fetchDeptStaffShift(personnelId, periodId);
    } catch (e) {
      _theirAvailableShifts = [];
    }
    notifyListeners();
  }

  // ── Submit Swap ───────────────────────────────────────────────────────────

  Future<bool> submitSwap(HrSwapRequestPayload payload) async {
    _swapState = SwapSubmitState.submitting;
    _swapError = null;
    notifyListeners();

    try {
      final success = await _service.createSwapRequest(payload);
      if (success) {
        _swapState = SwapSubmitState.success;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _swapError = e.toString();
    }
    _swapState = SwapSubmitState.error;
    notifyListeners();
    return false;
  }

  void resetSwapState() {
    _swapState = SwapSubmitState.idle;
    _swapError = null;
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
        return _rotaEvents.where((e) => _isSameDay(e.date, target)).toList();

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

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Map<ShiftType, int> yearlyCounts(List<RotaEvent> events) {
    final counts = <ShiftType, int>{};
    for (final e in events) {
      counts[e.type] = (counts[e.type] ?? 0) + 1;
    }
    return counts;
  }

  void clearUserData() {
    _rotaEvents = [];
    _staffMembers = [];
    _theirAvailableShifts = [];
    notifyListeners();
  }
}
