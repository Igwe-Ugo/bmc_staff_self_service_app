// lib/features/providers/tele_medicine_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/widget.dart';
import '../services/widget.dart';

class TeleMedicineProvider extends ChangeNotifier {
  final TeleMedicineService _service;

  List<QryBookingVisits> _visits = [];
  List<QryBookingVisits> _guestVisits = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  StreamSubscription? _socketSubscription;
  Timer? _refreshDebounce;

  /// True once the visit lists have been fetched at least once. Live refreshes
  /// are ignored before that: this provider is registered app-wide in main.dart,
  /// so without the guard every broadcast would fire two HTTP GETs even for a
  /// user who never opens the telemedicine screens.
  bool _hasLoadedOnce = false;

  TeleMedicineProvider({
    required TeleMedicineService service,
    SocketService? socket,
  }) : _service = service,
       _socket = socket ?? SocketService.instance {
    // Live refresh. The web app broadcasts `send-invalidate-queries` whenever a
    // visit changes — the clinic desk calling the patient in, triage being
    // completed or bypassed, another device toggling consultant-ready — and the
    // server rebroadcasts its own writes the same way. Mirrors the web app's
    // SocketListeners.tsx, which invalidates the matching TanStack Query keys.
    _socketSubscription = _socket.onInvalidation.listen(_onInvalidation);
  }

  final SocketService _socket;

  List<QryBookingVisits> get visits => _visits;
  List<QryBookingVisits> get guestVisits => _guestVisits;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _refreshDebounce?.cancel();
    super.dispose();
  }

  /// A broadcast landed. Reload only when it names one of the visit-list keys —
  /// the same stream carries HR keys this provider has no interest in.
  void _onInvalidation(InvalidationEvent event) {
    if (!_hasLoadedOnce) return;
    if (!event.keys.any(LiveRefreshKeys.telemedVisits.contains)) return;

    // One web action can broadcast several keys, and two actions can land back
    // to back (triage completed, then the patient called in). Coalesce them into
    // a single refetch.
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(
      const Duration(milliseconds: 400),
      () => loadVisits(silent: true),
    );
  }

  /// Fetch the consultant's own visits and the visits they are a guest on.
  ///
  /// [silent] keeps [isLoading] false, so a live refresh replaces the rows in
  /// place instead of flashing the screen back to its spinner. Use it for
  /// anything the user did not explicitly ask for.
  Future<void> loadVisits({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    _errorMessage = null;

    try {
      _visits = await _service.fetchBookingVisits();
      _guestVisits = await _service.fetchGuestVisits();
      _hasLoadedOnce = true;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle consultant ready status and reload visits from API
  Future<bool> toggleConsultantReady(QryBookingVisits data) async {
    final currentlyReady = data.consultantReady == 1;
    final markReady = QryBookingVisits(
      visitId: data.visitId,
      consultantReady: !currentlyReady,
    );
    try {
      await _service.setConsultantReady(data: markReady);
      // Silent: the row is already on screen and only its pill changes — no
      // reason to drop the whole list back to a spinner. The server also
      // broadcasts this toggle to every client (including us), which the
      // debounce in _onInvalidation collapses into this same refetch.
      await loadVisits(silent: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get link and join call
  Future<String?> joinTelemedicineRoom(JoinTeleMedLink data) async {
    try {
      return await _service.getTelemedicineLink(data: data);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // get link and join call for guests
  Future<String?> joinTeleMedGuestRoom(String visitId) async {
    try {
      return await _service.getTelemedicineLinkForGuest(visitId: visitId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  List<QryBookingVisits> get todayVisits {
    final now = DateTime.now();
    return _applyFilter(
      _visits.where((v) {
        if (v.appmtStartDate == null) return false;
        final date = v.appmtStartDate!;
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      }).toList(),
    );
  }

  List<QryBookingVisits> get upcomingVisits {
    final now = DateTime.now();
    final startOfTomorrow = DateTime(now.year, now.month, now.day + 1);
    return _applyFilter(
      _visits.where((v) {
        if (v.appmtStartDate == null) return false;
        return v.appmtStartDate!.isAtSameMomentAs(startOfTomorrow) ||
            v.appmtStartDate!.isAfter(startOfTomorrow);
      }).toList(),
    );
  }

  List<QryBookingVisits> get guestTodayVisits {
    final now = DateTime.now();
    return _applyFilter(
      _guestVisits.where((v) {
        if (v.appmtStartDate == null) return false;
        final date = v.appmtStartDate!;
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      }).toList(),
    );
  }

  List<QryBookingVisits> get guestUpcomingVisits {
    final now = DateTime.now();
    final startOfTomorrow = DateTime(now.year, now.month, now.day + 1);
    return _applyFilter(
      _guestVisits.where((v) {
        if (v.appmtStartDate == null) return false;
        return v.appmtStartDate!.isAtSameMomentAs(startOfTomorrow) ||
            v.appmtStartDate!.isAfter(startOfTomorrow);
      }).toList(),
    );
  }

  List<QryBookingVisits> _applyFilter(List<QryBookingVisits> list) {
    if (_searchQuery.isEmpty) return list;
    return list.where((v) {
      final name = v.fullname?.toLowerCase() ?? '';
      final mrn = v.medrecnum?.toString() ?? '';
      final slot = v.slotName?.toLowerCase() ?? '';
      final location = v.location?.toLowerCase() ?? '';
      return name.contains(_searchQuery) ||
          mrn.contains(_searchQuery) ||
          slot.contains(_searchQuery) ||
          location.contains(_searchQuery);
    }).toList();
  }
}
