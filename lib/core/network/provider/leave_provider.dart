// ─── leave_provider.dart ──────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../../core/errors/api_exceptions.dart';
import '../models/leave_model.dart';
import '../services/leave_service.dart';

enum LeaveState { idle, loading, success, error }

class LeaveProvider extends ChangeNotifier {
  final LeaveService _service = LeaveService();

  // ── State ─────────────────────────────────────────────────────────────────
  LeaveState _state        = LeaveState.idle;
  String?    _errorMessage;
  bool       _submitting   = false;

  // ── Data ──────────────────────────────────────────────────────────────────
  List<HrLeaveRequest> _myRequests = [];
  List<HrLeaveRequest> _searchResults = [];
  HrLeaveRequest?      _selectedRequest;

  // ── Filters ───────────────────────────────────────────────────────────────
  HrLeaveRequestStatus? _filterStatus;
  int                   _filterYear = DateTime.now().year;

  // ── Getters ───────────────────────────────────────────────────────────────
  LeaveState           get state          => _state;
  String?              get errorMessage   => _errorMessage;
  bool                 get isLoading      => _state == LeaveState.loading;
  bool                 get isSubmitting   => _submitting;
  List<HrLeaveRequest> get myRequests     => _myRequests;
  List<HrLeaveRequest> get searchResults  => _searchResults;
  HrLeaveRequest?      get selectedRequest => _selectedRequest;
  HrLeaveRequestStatus? get filterStatus  => _filterStatus;
  int                  get filterYear     => _filterYear;

  /// Requests for the current calendar view — all statuses, full list.
  List<HrLeaveRequest> get calendarRequests => _myRequests;

  /// Pending requests only (badge count, etc.).
  List<HrLeaveRequest> get pendingRequests =>
      _myRequests.where((r) => r.status == HrLeaveRequestStatus.pending).toList();

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    _setState(LeaveState.loading);
    await _loadMyRequests();
  }

  // ── 1. Load my requests ───────────────────────────────────────────────────
  Future<void> _loadMyRequests() async {
    try {
      _myRequests = await _service.getMyRequests(
        status: _filterStatus?.value,
        year:   _filterYear,
      );
      debugPrint('✅ ${_myRequests.length} leave request(s) loaded');
      _setState(LeaveState.success);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setState(LeaveState.error);
    }
  }

  Future<void> refresh() async {
    _setState(LeaveState.loading);
    await _loadMyRequests();
  }

  // ── 2. Filter controls ────────────────────────────────────────────────────
  Future<void> setStatusFilter(HrLeaveRequestStatus? status) async {
    _filterStatus = status;
    _setState(LeaveState.loading);
    await _loadMyRequests();
  }

  Future<void> setYearFilter(int year) async {
    _filterYear = year;
    _setState(LeaveState.loading);
    await _loadMyRequests();
  }

  // ── 3. Search ─────────────────────────────────────────────────────────────
  Future<void> search(HrLeaveRequestFilters filters) async {
    _setState(LeaveState.loading);
    try {
      _searchResults = await _service.searchRequests(filters);
      _setState(LeaveState.success);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setState(LeaveState.error);
    }
  }

  // ── 4. Get single request ─────────────────────────────────────────────────
  Future<HrLeaveRequest?> getById(String id) async {
    try {
      _selectedRequest = await _service.getRequestById(id);
      notifyListeners();
      return _selectedRequest;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return null;
    }
  }

  // ── 5. Create ─────────────────────────────────────────────────────────────
  Future<bool> createRequest(HrLeaveRequestFormData data) async {
    _submitting = true;
    notifyListeners();
    try {
      final created = await _service.createRequest(data);
      // Refresh the entire list to get the latest data from server
      await refresh();
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

  // ── 6. Update ─────────────────────────────────────────────────────────────
  Future<bool> updateRequest(String id, HrLeaveUpdateFormData data) async {
    _submitting = true;
    notifyListeners();
    try {
      final updated = await _service.updateRequest(id, data);
      // Refresh the entire list to get the latest data from server
      await refresh();
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

  // ── 7. Delete ─────────────────────────────────────────────────────────────
  Future<bool> deleteRequest(String id) async {
    _submitting = true;
    notifyListeners();
    try {
      await _service.deleteRequest(id);
      // Refresh the entire list to get the latest data from server
      await refresh();
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

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _setState(LeaveState s) {
    _state = s;
    if (s != LeaveState.error) _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
