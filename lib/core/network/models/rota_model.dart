import 'dart:ui';

enum ShiftType { morning, night, onCall, noShift, swapped }

extension ShiftTypeExtension on ShiftType {
  String get label {
    switch (this) {
      case ShiftType.morning:  return 'Morning';
      case ShiftType.night:    return 'Night';
      case ShiftType.onCall:   return 'On Call';
      case ShiftType.noShift:  return 'No Shift';
      case ShiftType.swapped:  return 'Swapped';
    }
  }

  Color get color {
    switch (this) {
      case ShiftType.morning:  return const Color(0xFF6C47FF);
      case ShiftType.night:    return const Color(0xFFFF6B6B);
      case ShiftType.onCall:   return const Color(0xFFF39C12);
      case ShiftType.noShift:  return const Color(0xFF8E8E93);
      case ShiftType.swapped:  return const Color(0xFF27AE60);
    }
  }

  Color get bgColor {
    switch (this) {
      case ShiftType.morning:  return const Color(0xFFEDE9FF);
      case ShiftType.night:    return const Color(0xFFFFEBEB);
      case ShiftType.onCall:   return const Color(0xFFFFF3E0);
      case ShiftType.noShift:  return const Color(0xFFF2F2F7);
      case ShiftType.swapped:  return const Color(0xFFE8F5E9);
    }
  }
}

class RotaEvent {
  final String   id;
  final String   staffName;
  final String   role;
  final String   ward;
  final ShiftType type;
  final DateTime date;
  final String   startTime;
  final String   endTime;

  const RotaEvent({
    required this.id,
    required this.staffName,
    required this.role,
    required this.ward,
    required this.type,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  String get timeRange => '$startTime - $endTime';
  String get dayLabel  => _dayLabel(date);

  static String _dayLabel(DateTime date) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d     = DateTime(date.year, date.month, date.day);
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (d == today)                                   return 'Today';
    if (d == today.add(const Duration(days: 1)))      return 'Tomorrow';
    return '';
  }
}

enum RotaFilter { allStatus, daily, weekly, monthly, yearly }

extension RotaFilterExtension on RotaFilter {
  String get label {
    switch (this) {
      case RotaFilter.allStatus: return 'All Status';
      case RotaFilter.daily:     return 'Daily';
      case RotaFilter.weekly:    return 'Weekly';
      case RotaFilter.monthly:   return 'Monthly';
      case RotaFilter.yearly:    return 'Yearly';
    }
  }
}

class StaffMember {
  final String id;
  final String name;
  final String employeeId;

  const StaffMember({
    required this.id,
    required this.name,
    required this.employeeId,
  });
}
