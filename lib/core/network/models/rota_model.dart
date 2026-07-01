// ─── rota_model.dart ──────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum HrRotaPeriodStatus { draft, published, archived }

extension HrRotaPeriodStatusExt on HrRotaPeriodStatus {
  String get value {
    switch (this) {
      case HrRotaPeriodStatus.draft:     return 'DRAFT';
      case HrRotaPeriodStatus.published: return 'PUBLISHED';
      case HrRotaPeriodStatus.archived:  return 'ARCHIVED';
    }
  }

  static HrRotaPeriodStatus fromString(String v) {
    switch (v.toUpperCase()) {
      case 'PUBLISHED': return HrRotaPeriodStatus.published;
      case 'ARCHIVED':  return HrRotaPeriodStatus.archived;
      default:          return HrRotaPeriodStatus.draft;
    }
  }
}

enum ShiftType { day, night, evening, onCall, custom }

extension ShiftTypeExt on ShiftType {
  String get value {
    switch (this) {
      case ShiftType.day:     return 'DAY';
      case ShiftType.night:   return 'NIGHT';
      case ShiftType.evening: return 'EVENING';
      case ShiftType.onCall:  return 'ON_CALL';
      case ShiftType.custom:  return 'CUSTOM';
    }
  }

  String get label {
    switch (this) {
      case ShiftType.day:     return 'Day';
      case ShiftType.night:   return 'Night';
      case ShiftType.evening: return 'Evening';
      case ShiftType.onCall:  return 'On Call';
      case ShiftType.custom:  return 'Custom';
    }
  }

  Color get color {
    switch (this) {
      case ShiftType.day:     return const Color(0xFF08F6EC);
      case ShiftType.night:   return const Color(0xFF2196F3);
      case ShiftType.evening: return const Color(0xFFF39C12);
      case ShiftType.onCall:  return const Color(0xFFE74C3C);
      case ShiftType.custom:  return const Color(0xFF009688);
    }
  }

  Color get bgColor {
    switch (this) {
      case ShiftType.day:     return const Color(0xFFE3F2FD);
      case ShiftType.night:   return const Color(0xFFEDE9FF);
      case ShiftType.evening: return const Color(0xFFFFF3E0);
      case ShiftType.onCall:  return const Color(0xFFFFEBEE);
      case ShiftType.custom:  return const Color(0xFFE0F2F1);
    }
  }

  static ShiftType fromString(String v) {
    switch (v.toUpperCase()) {
      case 'NIGHT':   return ShiftType.night;
      case 'EVENING': return ShiftType.evening;
      case 'ON_CALL': return ShiftType.onCall;
      case 'CUSTOM':  return ShiftType.custom;
      default:        return ShiftType.day;
    }
  }
}

enum HrAssignmentStatus {
  assigned, confirmed, swapped, voidedByLeave, completed, noShow
}

extension HrAssignmentStatusExt on HrAssignmentStatus {
  String get value {
    switch (this) {
      case HrAssignmentStatus.assigned:      return 'ASSIGNED';
      case HrAssignmentStatus.confirmed:     return 'CONFIRMED';
      case HrAssignmentStatus.swapped:       return 'SWAPPED';
      case HrAssignmentStatus.voidedByLeave: return 'VOIDED_BY_LEAVE';
      case HrAssignmentStatus.completed:     return 'COMPLETED';
      case HrAssignmentStatus.noShow:        return 'NO_SHOW';
    }
  }

  String get label {
    switch (this) {
      case HrAssignmentStatus.assigned:      return 'Assigned';
      case HrAssignmentStatus.confirmed:     return 'Confirmed';
      case HrAssignmentStatus.swapped:       return 'Swapped';
      case HrAssignmentStatus.voidedByLeave: return 'Voided (Leave)';
      case HrAssignmentStatus.completed:     return 'Completed';
      case HrAssignmentStatus.noShow:        return 'No Show';
    }
  }

  static HrAssignmentStatus fromString(String v) {
    switch (v.toUpperCase()) {
      case 'CONFIRMED':        return HrAssignmentStatus.confirmed;
      case 'SWAPPED':          return HrAssignmentStatus.swapped;
      case 'VOIDED_BY_LEAVE':  return HrAssignmentStatus.voidedByLeave;
      case 'COMPLETED':        return HrAssignmentStatus.completed;
      case 'NO_SHOW':          return HrAssignmentStatus.noShow;
      default:                 return HrAssignmentStatus.assigned;
    }
  }
}

enum HrSwapStatus { pending, approved, rejected, cancelled }

extension HrSwapStatusExt on HrSwapStatus {
  String get value {
    switch (this) {
      case HrSwapStatus.pending:   return 'PENDING';
      case HrSwapStatus.approved:  return 'APPROVED';
      case HrSwapStatus.rejected:  return 'REJECTED';
      case HrSwapStatus.cancelled: return 'CANCELLED';
    }
  }

  String get label {
    switch (this) {
      case HrSwapStatus.pending:   return 'Pending';
      case HrSwapStatus.approved:  return 'Approved';
      case HrSwapStatus.rejected:  return 'Rejected';
      case HrSwapStatus.cancelled: return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case HrSwapStatus.pending:   return const Color(0xFFF39C12);
      case HrSwapStatus.approved:  return const Color(0xFF27AE60);
      case HrSwapStatus.rejected:  return const Color(0xFFE74C3C);
      case HrSwapStatus.cancelled: return const Color(0xFF8E8E93);
    }
  }

  static HrSwapStatus fromString(String v) {
    switch (v.toUpperCase()) {
      case 'APPROVED':  return HrSwapStatus.approved;
      case 'REJECTED':  return HrSwapStatus.rejected;
      case 'CANCELLED': return HrSwapStatus.cancelled;
      default:          return HrSwapStatus.pending;
    }
  }
}

// ── My Shifts (Self-Service View) ─────────────────────────────────────────────

class HrMyShift {
  final String              assignmentId;
  final String              shiftId;
  final DateTime             date;
  final ShiftType           shiftType;
  final String              startTime;
  final String              endTime;
  final String              requiredRole;
  final HrAssignmentStatus  assignmentStatus;
  final String              periodId;
  final HrRotaPeriodStatus  periodStatus;
  final String              deptId;
  final String?             deptName;
  final String              rotaType;
  final String?             swapId;
  final HrSwapStatus?       swapStatus;

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

  String get timeRange => '$startTime - $endTime';

  factory HrMyShift.fromJson(Map<String, dynamic> json) {
    return HrMyShift(
      // Use fallback string if null or missing
      assignmentId:     (json['assignmentId'] ?? '').toString(),
      shiftId:          (json['shiftId'] ?? '').toString(),
      date:             DateTime.parse((json['date'] as String? ?? DateTime.now().toIso8601String()).split('T').first),
      shiftType:        ShiftTypeExt.fromString(json['shiftType'] as String? ?? 'DAY'),
      startTime:        json['startTime']     as String? ?? '',
      endTime:          json['endTime']       as String? ?? '',
      requiredRole:     json['requiredRole']  as String? ?? '',
      assignmentStatus: HrAssignmentStatusExt.fromString(json['assignmentStatus'] as String? ?? 'ASSIGNED'),
      periodId:         (json['periodId'] ?? '').toString(),
      deptId:           (json['deptId'] ?? '').toString(),
      periodStatus:     HrRotaPeriodStatusExt.fromString(json['periodStatus'] as String? ?? 'DRAFT'),
      deptName:         json['deptName']      as String?,
      rotaType:         json['rotaType']      as String? ?? '',
      swapId:           json['swapId']        as String?,
      swapStatus:       json['swapStatus'] != null
          ? HrSwapStatusExt.fromString(json['swapStatus'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'assignmentId':     assignmentId,
    'shiftId':          shiftId,
    'date':             date.toIso8601String().split('T').first,
    'shiftType':        shiftType.value,
    'startTime':        startTime,
    'endTime':          endTime,
    'requiredRole':     requiredRole,
    'assignmentStatus': assignmentStatus.value,
    'periodId':         periodId,
    'periodStatus':     periodStatus.value,
    'deptId':           deptId,
    'deptName':         deptName,
    'rotaType':         rotaType,
    'swapId':           swapId,
    'swapStatus':       swapStatus?.value,
  };
}

// ── RotaEvent — UI-friendly wrapper used by the calendar/list widgets ────────

class RotaEvent {
  final String             id;            // assignmentId
  final String             shiftId;
  final DateTime            date;
  final ShiftType          type;
  final String             startTime;
  final String             endTime;
  final String             role;
  final String             ward;          // deptName fallback
  final String             staffName;
  final HrAssignmentStatus status;
  final String             periodId;

  const RotaEvent({
    required this.id,
    required this.shiftId,
    required this.date,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.role,
    required this.ward,
    required this.staffName,
    required this.status,
    required this.periodId,
  });

  String get timeRange => '$startTime - $endTime';

  factory RotaEvent.fromMyShift(HrMyShift s, {String staffName = 'You'}) {
    return RotaEvent(
      id:        s.assignmentId,
      shiftId:   s.shiftId,
      date:      s.date,
      type:      s.shiftType,
      startTime: s.startTime,
      endTime:   s.endTime,
      role:      s.requiredRole,
      ward:      s.deptName ?? '',
      staffName: staffName,
      status:    s.assignmentStatus,
      periodId:  s.periodId,
    );
  }
}

// ── Staff Member (department personnel) ───────────────────────────────────────

class StaffMember {
  final String  id;            // personnelId
  final String  employeeId;    // staffNumber
  final String  name;
  final String? category;
  final String? grade;
  final String? status;
  final String? deptId;
  final String? deptName;
  final String? image;

  const StaffMember({
    required this.id,
    required this.employeeId,
    required this.name,
    this.category,
    this.grade,
    this.status,
    this.deptId,
    this.deptName,
    this.image,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    final first = json['firstName'] as String? ?? json['firstname'] as String? ?? '';
    final last  = json['lastName']  as String? ?? json['lastname']  as String? ?? '';
    final fullName = json['name'] as String? ??
        json['fullname'] as String? ??
        '$first $last'.trim();

    return StaffMember(
      id:         json['id']?.toString() ?? json['personnelId']?.toString() ?? '',
      employeeId: json['staffNumber'] as String? ?? json['employeeId'] as String? ?? '',
      name:       fullName,
      category:   json['category']  as String?,
      grade:      json['grade']     as String?,
      status:     json['status']    as String?,
      deptId:     json['deptId']    as String?,
      deptName:   json['deptName']  as String?,
      image:      json['image']     as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':         id,
    'staffNumber': employeeId,
    'name':       name,
    'category':   category,
    'grade':      grade,
    'status':     status,
    'deptId':     deptId,
    'deptName':   deptName,
    'image':      image,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is StaffMember && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ── Shift Swap (request + response) ───────────────────────────────────────────

/// POST body for /api/hr/rota/swaps
/// { fromAssignmentId, toAssignmentId, toPersonnelId, reason }
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

/// Full swap record returned by the API once created.
class HrShiftSwap {
  final String       id;
  final String       fromAssignmentId;
  final String       toAssignmentId;
  final String       toPersonnelId;
  final String?      reason;
  final HrSwapStatus status;
  final String       requestedBy;
  final String       requestedAt;
  final String?      decidedBy;
  final String?      approvedAt;

  const HrShiftSwap({
    required this.id,
    required this.fromAssignmentId,
    required this.toAssignmentId,
    required this.toPersonnelId,
    this.reason,
    required this.status,
    required this.requestedBy,
    required this.requestedAt,
    this.decidedBy,
    this.approvedAt,
  });

  factory HrShiftSwap.fromJson(Map<String, dynamic> json) {
    return HrShiftSwap(
      id:               (json['id'] ?? '').toString(),
      fromAssignmentId: (json['fromAssignmentId'] ?? '').toString(),
      toAssignmentId:   (json['toAssignmentId'] ?? '').toString(),
      toPersonnelId:    (json['toPersonnelId'] ?? '').toString(),
      reason:           (json['reason'] ?? '').toString(),
      status:           HrSwapStatusExt.fromString(json['status'] as String? ?? 'PENDING'),
      requestedBy:      (json['requestedBy'] ?? '').toString(),
      requestedAt:      (json['requestedAt'] ?? '').toString(),
      decidedBy:        json['decidedBy']         as String?,
      approvedAt:       json['approvedAt']        as String?,
    );
  }
}
