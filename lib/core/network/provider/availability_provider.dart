import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/errors/api_exceptions.dart';
import '../models/availability_model.dart';
import '../services/widget.dart';

enum AvailabilityState { idle, loading, success, error }

class AvailabilityProvider extends ChangeNotifier {
  final AvailabilityServices _services = AvailabilityServices();

  // ── State ─────────────────────────────────────────────────────────────────
  AvailabilityState        _state        = AvailabilityState.idle;
  String?                  _errorMessage;
  bool                     _submitting   = false;

  // ── Data ──────────────────────────────────────────────────────────────────
  List<HrAvailabilitySlot> _slots        = [];
  HrAvailabilityWindow?    _window;
  String                   _currentMonth = _monthKey(DateTime.now());

  // ── Countdown timer ───────────────────────────────────────────────────────
  Timer?   _timer;
  Duration _remaining = Duration.zero;

  // ── Getters ───────────────────────────────────────────────────────────────
  AvailabilityState        get state        => _state;
  String?                  get errorMessage => _errorMessage;
  bool                     get isLoading    => _state == AvailabilityState.loading;
  bool                     get isSubmitting => _submitting;
  List<HrAvailabilitySlot> get slots        => _slots;
  HrAvailabilityWindow?    get window       => _window;
  String                   get currentMonth => _currentMonth;
  Duration                 get remaining    => _remaining;

  bool get isWindowOpen    => _window?.isOpen    ?? false;
  bool get isWindowClosed  => _window?.hasClosed ?? true;
  bool get isWindowPending => _window != null && !_window!.hasOpened;
  bool get hasWindow       => _window != null;

  String get timerLabel {
    if (_remaining.inSeconds <= 0) return '00:00:00';
    final d = _remaining.inDays.toString().padLeft(2, '0');
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$d:$h:$m:$s days left';
  }

  String get timerPrefix {
    if (isWindowOpen)    return 'Closing: ';
    if (isWindowPending) return 'Opening: ';
    return '';
  }

  String get adminBannerMessage {
    if (!hasWindow)       return 'No availability window has been set by admin yet.';
    if (isWindowPending) {
      return 'Availability Window for ${_window!.month} is not yet open. '
        'Opens in $timerLabel.';
    }
    if (isWindowOpen) {
      return 'Availability Window open for ${_window!.month}\nCloses ${_window!.month} at ${_window!.closesAt.hour}:${_window!.closesAt.minute.toString().padLeft(2, '0')}';
    }
    return 'Admin: Availability is currently closed for ${_window!.month}. '
        'Check back next month.';
  }

  // ── Slot helpers ──────────────────────────────────────────────────────────

  HrAvailabilitySlot? slotForDate(DateTime date) {
    final key = _dateKey(date);
    try {
      return _slots.firstWhere(
            (s) => _dateKey(s.date) == key,
      );
    } catch (_) {
      return null;
    }
  }

  Map<HrAvailabilityStatus, Map<int, int>> get chartData {
    final data = <HrAvailabilityStatus, Map<int, int>>{
      HrAvailabilityStatus.available:   {},
      HrAvailabilityStatus.unavailable: {},
      HrAvailabilityStatus.preferred:   {},
      HrAvailabilityStatus.tentative:   {},
    };
    for (final s in _slots) {
      final day = s.date.day;
      data[s.availability]![day] = (data[s.availability]![day] ?? 0) + 1;
    }
    return data;
  }

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    _setState(AvailabilityState.loading);
    // Always fetch window + current month calendar in parallel
    await Future.wait([
      _fetchCurrentWindow(),
      _fetchMyCalendar(_currentMonth),
    ]);
  }

  // ── 1. Fetch current window ───────────────────────────────────────────────
  Future<void> _fetchCurrentWindow() async {
    try {
      _window = await _services.getCurrentWindow();
      debugPrint('✅ Window fetched: ${_window?.toJson()}');  // Nice formatted output
      _startTimer();
    } on ApiException catch (e) {
      debugPrint('Window fetch failed: ${e.message}');
    }
  }

  // Add this getter
  String get windowMonthKey {
    if (_window == null) return '';
    final raw = _window!.month;
    // Handle both "2026-07-01" and "2026-07" formats
    if (raw.contains('-') && raw.split('-').length >= 2) {
      final parts = raw.split('-');
      return "${parts[0]}-${parts[1].padLeft(2, '0')}";
    }
    return raw;
  }

// Also add this for convenience
  bool get isWindowOpenForMonth {
    if (!hasWindow) return false;
    final currentMonthKey = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";
    return isWindowOpen && windowMonthKey == currentMonthKey;
  }

  // Expose for manual refresh
  Future<void> refreshWindow() async {
    await _fetchCurrentWindow();
    notifyListeners();
  }

  // ── 2. Fetch my calendar ──────────────────────────────────────────────────
  Future<void> _fetchMyCalendar(String month) async {
    try {
      _slots = await _services.getMyCalendar(month);
      debugPrint('✅ Slots fetched for $month: ${_slots.length} slots');
      for (var slot in _slots) {
        debugPrint('   - ${slot.date} → ${slot.availability.label}');
      }
      _currentMonth = month;
      _setState(AvailabilityState.success);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setState(AvailabilityState.error);
    }
  }

  Future<void> changeMonth(DateTime month) async {
    final key = _monthKey(month);
    _setState(AvailabilityState.loading);
    await _fetchMyCalendar(key);
  }

  // ── 3. Submit bulk (single or multiple slots) ─────────────────────────────
  /// For a single slot, pass one item in [slots].
  /// For multiple dates at once, pass multiple items.
  Future<bool> submitAvailability({
    required String personnelId,
    required List<HrAvailabilityBulkSlot> slots,
  }) async {
    _submitting = true;
    notifyListeners();

    try {
      final results = await _services.submitBulk(
        HrAvailabilityBulkFormData(
          personnelId: personnelId,
          slots:       slots,
        ),
      );

      // Merge results into local list
      for (final result in results) {
        final idx = _slots.indexWhere((s) => _dateKey(s.date) == _dateKey(result.date));
        if (idx >= 0) {
          _slots[idx] = result;   // update existing
        } else {
          _slots = [..._slots, result]; // append new
        }
      }

      _submitting = false;
      notifyListeners();
      return true;

    } on ApiException catch (e) {
      _errorMessage = e.message;
      _submitting   = false;
      notifyListeners();
      return false;
    }
  }

  // ── ADD THIS METHOD to AvailabilityProvider ───────────────────────────────
// Place it after submitAvailability()

  Future<bool> deleteSlot(String slotId) async {
    _submitting = true;
    notifyListeners();

    try {
      await _services.deleteAvailability(slotId);
      _slots = _slots.where((s) => s.id != slotId).toList();
      _submitting = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _submitting = false;  // Make sure to reset on error
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _submitting = false;  // Make sure to reset on any error
      notifyListeners();
      return false;
    }
  }

  // ── Timer ─────────────────────────────────────────────────────────────────
  void _startTimer() {
    _timer?.cancel();
    if (_window == null) return;
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    if (_window == null) return;
    if (_window!.isOpen) {
      _remaining = _window!.closesAt.difference(DateTime.now());
    } else if (!_window!.hasOpened) {
      _remaining = _window!.opensAt.difference(DateTime.now());
    } else {
      _remaining = Duration.zero;
      _timer?.cancel();
    }
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static String _monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-'
          '${d.day.toString().padLeft(2,'0')}';

  void _setState(AvailabilityState state) {
    _state = state;
    if (state != AvailabilityState.error) _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
