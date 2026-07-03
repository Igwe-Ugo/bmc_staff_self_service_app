// ─── rota_provider.dart ───────────────────────────────────────────────────────

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../errors/api_exceptions.dart';
import '../models/widget.dart';
import '../services/widget.dart';

enum RotaLoadState { idle, loading, loaded, error }
enum SwapSubmitState { idle, submitting, success, error }
enum RotaFilter { allStatus, daily, weekly, monthly, yearly }
enum CancelSwapResult { success, alreadyResolved, failed }

class RotaProvider extends ChangeNotifier {
  final RotaService _service = RotaService();

  // ── My shifts state ──────────────────────────────────────────────────────
  RotaLoadState   _loadState    = RotaLoadState.idle;
  String?         _errorMessage;
  List<RotaEvent> _rotaEvents   = [];

  // Cache to avoid duplicate calls for the same month
  final Set<String> _fetchedMonths = {};

  RotaLoadState   get loadState     => _loadState;
  String?         get errorMessage  => _errorMessage;
  List<RotaEvent> get rotaEvents    => _rotaEvents;

  // ── Department staff state ───────────────────────────────────────────────
  List<StaffMember> _staffMembers = [];
  bool              _loadingStaff = false;

  List<StaffMember> get staffMembers   => _staffMembers;
  bool              get isLoadingStaff => _loadingStaff;

  // ── Selected staff member's shifts (for swap "their shift" picker) ───────
  List<RotaEvent> _theirAvailableShifts = [];
  bool            _loadingTheirShifts   = false;

  List<RotaEvent> get theirAvailableShifts => _theirAvailableShifts;
  bool            get isLoadingTheirShifts => _loadingTheirShifts;

  // ── Swap submit state ────────────────────────────────────────────────────
  SwapSubmitState _swapState = SwapSubmitState.idle;
  HrShiftSwap?    _lastSwap;
  String?         _swapError;

  SwapSubmitState get swapState => _swapState;
  HrShiftSwap?    get lastSwap  => _lastSwap;
  String?         get swapError => _swapError;

  // ── Swap requests lookup state ─────────────────────────────────────────────
  List<RotaEvent> _swapEvents = [];
  bool _isLoadingSwaps = false;
  bool get isLoadingSwaps => _isLoadingSwaps;

  // ── Full refresh — call after any action that can change what's on screen ──
  Future<void> refreshRotaData(
      BuildContext context,
      DateTime month, {
        String staffName = 'You',
        String? personnelId,
      }) async {
    await Future.wait([
      refreshShiftsForMonth(context, month, staffName: staffName), // clears cache, refetches
      loadSwapRequests(personnelId: personnelId),
    ]);
  }

  // ── 1. Load my shifts for a month ────────────────────────────────────────

  Future<void> loadShiftsForMonth(
      BuildContext context,
      DateTime month, {
        String staffName = 'You',
      }) async {
    final monthKey = DateFormat('yyyy-MM').format(month);
    if (_fetchedMonths.contains(monthKey)) return;

    _loadState    = RotaLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final shifts = await _service.fetchMyShifts(month: monthKey);
      _fetchedMonths.add(monthKey);

      // Merge + dedupe across months by assignmentId
      final existing = {for (var e in _rotaEvents) e.id: e};
      for (final s in shifts) {
        final event = RotaEvent.fromMyShift(s, staffName: staffName);
        existing[event.id] = event;
      }
      _rotaEvents = existing.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      _loadState = RotaLoadState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _loadState    = RotaLoadState.error;
    }

    notifyListeners();
  }

  // We expose a unified list combining normal shifts and swap records
  List<RotaEvent> get allCalendarEvents {
    // Merge standard month shifts with the tracked swap event states
    final combined = List<RotaEvent>.from(_rotaEvents); // Assuming your normal shifts list is _rotaEvents

    for (var swap in _swapEvents) {
      // Avoid duplicate assignments if it exists in both lists
      combined.removeWhere((element) => element.id == swap.id);
      combined.add(swap);
    }
    return combined;
  }

  Future<void> loadSwapRequests({String? periodId, String? personnelId, String? status}) async {
    _isLoadingSwaps = true;
    _swapError = null;
    notifyListeners();

    try {
      final shiftsData = await _service.fetchSwapRequests(
        periodId: periodId,
        personnelId: personnelId,
        status: status,
      );

      // Maps using your working factory constructor seamlessly!
      _swapEvents = shiftsData
          .map((shift) => RotaEvent.fromMyShift(shift))
          .toList();

      _isLoadingSwaps = false;
    } catch (e) {
      _swapError = e.toString();
      _isLoadingSwaps = false;
    }
    notifyListeners();
  }

  Future<void> refreshShiftsForMonth(
      BuildContext context,
      DateTime month, {
        String staffName = 'You',
      }) async {
    final key = DateFormat('yyyy-MM').format(month);
    _fetchedMonths.remove(key);
    await loadShiftsForMonth(context, month, staffName: staffName);
  }

  // ── 2. Load department staff (for swap coworker search) ─────────────────

  Future<void> loadDeptStaff(String deptId) async {
    _loadingStaff = true;
    notifyListeners();
    try {
      _staffMembers = await _service.fetchDeptStaff(deptId);
    } catch (e) {
      debugPrint('Failed to load department staff: $e');
      _staffMembers = [];
    }
    _loadingStaff = false;
    notifyListeners();
  }

  // ── 3. Load a chosen staff member's shifts for a rota period ────────────

  Future<void> loadPersonnelShifts({
    required String personnelId,
    required String periodId,
  }) async {
    _theirAvailableShifts = [];
    _loadingTheirShifts   = true;
    notifyListeners();
    try {
      _theirAvailableShifts = await _service.fetchPersonnelShifts(
        personnelId: personnelId,
        periodId:    periodId,
      );
    } catch (e) {
      debugPrint('Failed to load personnel shifts: $e');
      _theirAvailableShifts = [];
    }
    _loadingTheirShifts = false;
    notifyListeners();
  }

  void clearTheirShifts() {
    _theirAvailableShifts = [];
    notifyListeners();
  }

  // ── 4. Submit a swap request ─────────────────────────────────────────────
  /// Goes to admin for approval. Does NOT immediately change the roster.

  Future<bool> submitSwap(HrSwapRequestPayload payload) async {
    _swapState = SwapSubmitState.submitting;
    _swapError = null;
    _lastSwap  = null;
    notifyListeners();

    try {
      final result = await _service.createSwapRequest(payload);
      _lastSwap  = result;
      _swapState = SwapSubmitState.success;
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
    _lastSwap  = null;
    notifyListeners();
  }

  // ── Filtered events (used by RotaScreen) ─────────────────────────────────

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
        final endOfWeek   = startOfWeek.add(const Duration(days: 7));
        return _rotaEvents
            .where((e) =>
        !e.date.isBefore(startOfWeek) && e.date.isBefore(endOfWeek))
            .toList();

      case RotaFilter.monthly:
        return _rotaEvents
            .where((e) =>
        e.date.month == focusedDay.month &&
            e.date.year  == focusedDay.year)
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

  // ── Reset / logout ────────────────────────────────────────────────────────

  void clearUserData() {
    _rotaEvents            = [];
    _staffMembers          = [];
    _theirAvailableShifts  = [];
    _fetchedMonths.clear();
    _loadState = RotaLoadState.idle;
    _swapState = SwapSubmitState.idle;
    notifyListeners();
  }

  Future<CancelSwapResult> cancelSwapRequest(String? swapId) async {
    if (swapId == null || swapId.isEmpty) return CancelSwapResult.failed;
    try {
      final ok = await _service.deleteSwapRequest(swapId);
      return ok ? CancelSwapResult.success : CancelSwapResult.failed;
    } on SwapAlreadyResolvedException {
      return CancelSwapResult.alreadyResolved;
    } catch (e) {
      debugPrint("❌ FAILED TO DELETE SWAP REQUEST: $e");
      return CancelSwapResult.failed;
    }
  }
}
