import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

enum HrShiftType { day, night, evening, onCall, custom }

extension HrShiftTypeX on HrShiftType {
  String get apiValue {
    switch (this) {
      case HrShiftType.day:     return 'DAY';
      case HrShiftType.night:   return 'NIGHT';
      case HrShiftType.evening: return 'EVENING';
      case HrShiftType.onCall:  return 'ON_CALL';
      case HrShiftType.custom:  return 'CUSTOM';
    }
  }

  static HrShiftType fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'DAY':     return HrShiftType.day;
      case 'NIGHT':   return HrShiftType.night;
      case 'EVENING': return HrShiftType.evening;
      case 'ON_CALL': return HrShiftType.onCall;
      case 'CUSTOM':  return HrShiftType.custom;
      default:        return HrShiftType.custom;
    }
  }

  String get label {
    switch (this) {
      case HrShiftType.day:     return 'Day';
      case HrShiftType.night:   return 'Night';
      case HrShiftType.evening: return 'Evening';
      case HrShiftType.onCall:  return 'On Call';
      case HrShiftType.custom:  return 'Custom';
    }
  }

  Color get color {
    switch (this) {
      case HrShiftType.day:     return const Color(0xFF1A7F5A);
      case HrShiftType.night:   return const Color(0xFF5856D6);
      case HrShiftType.evening: return const Color(0xFFFF9500);
      case HrShiftType.onCall:  return const Color(0xFFFF3B30);
      case HrShiftType.custom:  return const Color(0xFF007AFF);
    }
  }

  Color get bgColor {
    switch (this) {
      case HrShiftType.day:     return const Color(0xFFDFF4EC);
      case HrShiftType.night:   return const Color(0xFFEAEAFF);
      case HrShiftType.evening: return const Color(0xFFFFF3E0);
      case HrShiftType.onCall:  return const Color(0xFFFFECEB);
      case HrShiftType.custom:  return const Color(0xFFE5F0FF);
    }
  }
}

enum HrAssignmentStatus { assigned, confirmed, swapped, voidedByLeave, completed, noShow }

extension HrAssignmentStatusX on HrAssignmentStatus {
  static HrAssignmentStatus fromApi(String v) {
    switch (v.toUpperCase()) {
      case 'ASSIGNED':       return HrAssignmentStatus.assigned;
      case 'CONFIRMED':      return HrAssignmentStatus.confirmed;
      case 'SWAPPED':        return HrAssignmentStatus.swapped;
      case 'VOIDED_BY_LEAVE':return HrAssignmentStatus.voidedByLeave;
      case 'COMPLETED':      return HrAssignmentStatus.completed;
      case 'NO_SHOW':        return HrAssignmentStatus.noShow;
      default:               return HrAssignmentStatus.assigned;
    }
  }

  String get label {
    switch (this) {
      case HrAssignmentStatus.assigned:      return 'Assigned';
      case HrAssignmentStatus.confirmed:     return 'Confirmed';
      case HrAssignmentStatus.swapped:       return 'Swapped';
      case HrAssignmentStatus.voidedByLeave: return 'Voided';
      case HrAssignmentStatus.completed:     return 'Completed';
      case HrAssignmentStatus.noShow:        return 'No Show';
    }
  }
}

enum HrSwapStatus { pending, approved, rejected, cancelled }

extension HrSwapStatusX on HrSwapStatus {
  static HrSwapStatus fromApi(String v) {
    switch (v.toUpperCase()) {
      case 'PENDING':   return HrSwapStatus.pending;
      case 'APPROVED':  return HrSwapStatus.approved;
      case 'REJECTED':  return HrSwapStatus.rejected;
      case 'CANCELLED': return HrSwapStatus.cancelled;
      default:          return HrSwapStatus.pending;
    }
  }
}

enum HrRotaPeriodStatus { draft, published, archived }

extension HrRotaPeriodStatusX on HrRotaPeriodStatus {
  static HrRotaPeriodStatus fromApi(String v) {
    switch (v.toUpperCase()) {
      case 'DRAFT':     return HrRotaPeriodStatus.draft;
      case 'PUBLISHED': return HrRotaPeriodStatus.published;
      case 'ARCHIVED':  return HrRotaPeriodStatus.archived;
      default:          return HrRotaPeriodStatus.draft;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HrMyShift — API response model for GET /api/hr/rota/my-shifts
// ─────────────────────────────────────────────────────────────────────────────

class HrMyShift {
  final String             assignmentId;
  final String             shiftId;
  final DateTime           date;
  final HrShiftType        shiftType;
  final String             startTime;
  final String             endTime;
  final String             requiredRole;
  final HrAssignmentStatus assignmentStatus;
  final String             periodId;
  final HrRotaPeriodStatus periodStatus;
  final String             deptId;
  final String?            deptName;
  final String             rotaType;
  final String?            swapId;
  final HrSwapStatus?      swapStatus;

  const HrMyShift({
    required this.assignmentId,
    required this.shiftId,
    required this.date,
    required this.shiftType,
    required this.startTime,
    required this.endTime,
    required this.requiredRole,
    required this.assignmentStatus,
    required this.periodId,
    required this.periodStatus,
    required this.deptId,
    this.deptName,
    required this.rotaType,
    this.swapId,
    this.swapStatus,
  });

  factory HrMyShift.fromJson(Map<String, dynamic> json) {
    return HrMyShift(
      assignmentId:     json['assignmentId'] as String,
      shiftId:          json['shiftId'] as String,
      date:             DateTime.parse(json['date'] as String),
      shiftType:        HrShiftTypeX.fromApi(json['shiftType'] as String),
      startTime:        json['startTime'] as String,
      endTime:          json['endTime'] as String,
      requiredRole:     json['requiredRole'] as String,
      assignmentStatus: HrAssignmentStatusX.fromApi(json['assignmentStatus'] as String),
      periodId:         json['periodId'] as String,
      periodStatus:     HrRotaPeriodStatusX.fromApi(json['periodStatus'] as String),
      deptId:           json['deptId'] as String,
      deptName:         json['deptName'] as String?,
      rotaType:         json['rotaType'] as String,
      swapId:           json['swapId'] as String?,
      swapStatus:       json['swapStatus'] != null
          ? HrSwapStatusX.fromApi(json['swapStatus'] as String)
          : null,
    );
  }

  /// Converts this API model into the UI-level [RotaEvent] used by widgets.
  RotaEvent toRotaEvent({required String staffName}) {
    return RotaEvent(
      id:         assignmentId,
      staffName:  staffName,
      role:       requiredRole,
      ward:       deptName ?? deptId,
      type:       _toShiftType(shiftType),
      date:       date,
      startTime:  startTime,
      endTime:    endTime,
      assignmentStatus: assignmentStatus,
      swapStatus:       swapStatus,
    );
  }

  static ShiftType _toShiftType(HrShiftType t) {
    switch (t) {
      case HrShiftType.day:     return ShiftType.morning;
      case HrShiftType.night:   return ShiftType.night;
      case HrShiftType.evening: return ShiftType.evening;
      case HrShiftType.onCall:  return ShiftType.onCall;
      case HrShiftType.custom:  return ShiftType.morning;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Swap request / response models
// ─────────────────────────────────────────────────────────────────────────────

class HrSwapRequestPayload {
  final String  fromAssignmentId;
  final String  toAssignmentId;
  final String  toPersonnelId;
  final String? reason;

  const HrSwapRequestPayload({
    required this.fromAssignmentId,
    required this.toAssignmentId,
    required this.toPersonnelId,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
    'fromAssignmentId': fromAssignmentId,
    'toAssignmentId':   toAssignmentId,
    'toPersonnelId':    toPersonnelId,
    if (reason != null && reason!.isNotEmpty) 'reason': reason,
  };
}

class HrShiftSwapResponse {
  final String        id;
  final HrSwapStatus  status;
  final String        requestedAt;
  final String?       fromPersonnelName;
  final String?       toPersonnelName;

  const HrShiftSwapResponse({
    required this.id,
    required this.status,
    required this.requestedAt,
    this.fromPersonnelName,
    this.toPersonnelName,
  });

  factory HrShiftSwapResponse.fromJson(Map<String, dynamic> json) {
    return HrShiftSwapResponse(
      id:               json['id'] as String,
      status:           HrSwapStatusX.fromApi(json['status'] as String),
      requestedAt:      json['requestedAt'] as String,
      fromPersonnelName: json['fromPersonnelName'] as String?,
      toPersonnelName:   json['toPersonnelName'] as String?,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UI-level models (used by existing widgets — extended for API integration)
// ─────────────────────────────────────────────────────────────────────────────

/// UI-facing shift type used by calendar cells and tiles.
/// Maps 1-to-1 with [HrShiftType] via [HrMyShift.toRotaEvent].
enum ShiftType { morning, night, evening, onCall, noShift }

extension ShiftTypeX on ShiftType {
  String get label {
    switch (this) {
      case ShiftType.morning:  return 'Day';
      case ShiftType.night:    return 'Night';
      case ShiftType.evening:  return 'Evening';
      case ShiftType.onCall:   return 'On Call';
      case ShiftType.noShift:  return 'Off';
    }
  }

  Color get color {
    switch (this) {
      case ShiftType.morning:  return const Color(0xFF1A7F5A);
      case ShiftType.night:    return const Color(0xFF5856D6);
      case ShiftType.evening:  return const Color(0xFFFF9500);
      case ShiftType.onCall:   return const Color(0xFFFF3B30);
      case ShiftType.noShift:  return const Color(0xFF8E8E93);
    }
  }

  Color get bgColor {
    switch (this) {
      case ShiftType.morning:  return const Color(0xFFDFF4EC);
      case ShiftType.night:    return const Color(0xFFEAEAFF);
      case ShiftType.evening:  return const Color(0xFFFFF3E0);
      case ShiftType.onCall:   return const Color(0xFFFFECEB);
      case ShiftType.noShift:  return const Color(0xFFF2F2F7);
    }
  }
}

/// A calendar/list event item hydrated from [HrMyShift].
class RotaEvent {
  final String             id;
  final String             staffName;
  final String             role;
  final String             ward;
  final ShiftType          type;
  final DateTime           date;
  final String             startTime;
  final String             endTime;
  final HrAssignmentStatus? assignmentStatus;
  final HrSwapStatus?       swapStatus;

  const RotaEvent({
    required this.id,
    required this.staffName,
    required this.role,
    required this.ward,
    required this.type,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.assignmentStatus,
    this.swapStatus,
  });

  String get timeRange => '$startTime - $endTime';

  String get dayLabel {
    final now       = DateTime.now();
    final today     = DateTime(now.year, now.month, now.day);
    final eventDay  = DateTime(date.year, date.month, date.day);
    final diff      = eventDay.difference(today).inDays;
    if (diff == -1) return 'Yesterday';
    if (diff ==  0) return 'Today';
    if (diff ==  1) return 'Tomorrow';
    // For all other days return the formatted date as a group label
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${date.day} ${months[date.month - 1]}';
  }

  /// Whether this event has a pending swap in progress.
  bool get hasPendingSwap => swapStatus == HrSwapStatus.pending;
}

/// Lightweight staff member for swap-sheet search list.
class StaffMember {
  final String id;
  final String name;
  final String employeeId;

  const StaffMember({
    required this.id,
    required this.name,
    required this.employeeId,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    final firstName = json['firstName'] as String? ?? '';
    final lastName  = json['lastName']  as String? ?? '';
    return StaffMember(
      id:         json['id'] as String,
      name:       '$firstName $lastName'.trim(),
      employeeId: json['staffNumber'] as String? ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rota filter used by the screen header dropdown
// ─────────────────────────────────────────────────────────────────────────────

enum RotaFilter { allStatus, daily, weekly, monthly, yearly }

extension RotaFilterX on RotaFilter {
  String get label {
    switch (this) {
      case RotaFilter.allStatus: return 'All';
      case RotaFilter.daily:     return 'Daily';
      case RotaFilter.weekly:    return 'Weekly';
      case RotaFilter.monthly:   return 'Monthly';
      case RotaFilter.yearly:    return 'Yearly';
    }
  }
}
