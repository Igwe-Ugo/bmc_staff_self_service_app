import 'package:flutter/material.dart';
import '../models/widget.dart';
import '../services/widget.dart';

class TeleMedicineProvider extends ChangeNotifier {
  final TeleMedicineService _service;

  List<QryBookingVisits> _visits = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  TeleMedicineProvider({required TeleMedicineService service})
    : _service = service;

  List<QryBookingVisits> get visits => _visits;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
        return v.appmtStartDate!.isAfter(startOfTomorrow);
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
