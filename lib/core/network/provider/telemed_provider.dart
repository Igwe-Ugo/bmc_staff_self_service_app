// lib/features/providers/tele_medicine_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/widget.dart';
import '../services/widget.dart';

class TeleMedicineProvider extends ChangeNotifier {
  final TeleMedicineService _service;

  List<QryBookingVisits> _visits = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  StreamSubscription? _socketSubscription;

  TeleMedicineProvider({required TeleMedicineService service})
      : _service = service;

  List<QryBookingVisits> get visits => _visits;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  /// Listens to WebSocket events and refetches visits when real-time updates occur
  void listenToSocketEvents(Stream<dynamic> socketStream) {
    _socketSubscription?.cancel();
    _socketSubscription = socketStream.listen((event) {
      if (event is Map<String, dynamic> && event['type'] == 'VISIT_UPDATE') {
        loadVisits(); // Refetch visits to ensure all model properties are synced
      }
    });
  }

  Future<void> loadVisits() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _visits = await _service.fetchBookingVisits();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle consultant ready status and reload visits from API
  Future<bool> toggleConsultantReady(String visitId, bool consultantReady) async {
    try {
      await _service.setConsultantReady(
        visitId: visitId,
        consultantReady: !consultantReady,
      );
      await loadVisits(); // Reload list directly without needing copyWith
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get link and join call
  Future<String?> joinTelemedicineRoom(String visitId, String userId) async {
    try {
      return await _service.getTelemedicineLink(visitId: visitId, userId: userId);
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
