import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

enum ShiftType { DAY, NIGHT, EVENING, ON_CALL, CUSTOM }

extension ShiftTypeExtenstion on ShiftType {
    String get label {
      switch (this) {
        case ShiftType.DAY:     return 'Day';
        case ShiftType.NIGHT:   return 'Night';
        case ShiftType.EVENING: return 'Evening';
        case ShiftType.ON_CALL:  return 'On Call';
        case ShiftType.CUSTOM:  return 'Custom';
      }
    }

    Color get color {
      switch (this) {
        case ShiftType.DAY: return const Color(0xFFF2C94C);
        case ShiftType.NIGHT: return const Color(0xFF2F80ED);
        case ShiftType.EVENING: return const Color(0xFFBB6BD9);
        case ShiftType.ON_CALL: return const Color(0xFF27AE60);
        case ShiftType.CUSTOM: return const Color(0xFFEB5757);
      }
    }

  }

/// A calendar/list event item hydrated from [HrMyShift].
class RotaEvent {
  final String id;
  final ShiftType type;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String? notes;

  const RotaEvent({
    required this.id,
    required this.type,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.notes,
  });

  factory RotaEvent.fromMyShift(HrMyShift shift) {
    return RotaEvent(
      id:         shift.assignmentId,
      type:       _parseShiftType(shift.shiftType),
      date:       DateTime.parse(shift.date),
      startTime:  shift.startTime,
      endTime:    shift.endTime,
      notes:      shift.notes,
    );
  }

  static ShiftType _parseShiftType(String value){
    return ShiftType.values.firstWhere(
        (type) => type.name == value.toUpperCase(),
      orElse: () => ShiftType.CUSTOM,
    );
  }
}

class HrMyShift {
  final String assignmentId;
  final String date;
  final String shiftType;
  final String startTime;
  final String endTime;
  final String? notes;

  HrMyShift({
    required this.assignmentId,
    required this.date,
    required this.shiftType,
    required this.startTime,
    required this.endTime,
    this.notes,
  });

  factory HrMyShift.fromJson(Map<String, dynamic> json) {
    return HrMyShift(
      assignmentId: json['assignmentId'] ?? json['id'] ?? '',
      date: json['date'] ?? '',
      shiftType: json['shiftType'] ?? 'CUSTOM',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      notes: json['notes'],
    );
  }
}

class StaffMember {
  final String id;
  final String name;
  final String employeeId;

  StaffMember({
    required this.id,
    required this.name,
    required this.employeeId,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id'] ?? '',
      name: json['name'] ?? json['personnelName'] ?? '',
      employeeId: json['employeeId'] ?? '',
    );
  }
}

class HrSwapRequestPayload {
  final String fromAssignmentId;
  final String toAssignmentId;
  final String toPersonnelId;
  final String? reason;

  HrSwapRequestPayload({
    required this.fromAssignmentId,
    required this.toAssignmentId,
    required this.toPersonnelId,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'fromAssignmentId': fromAssignmentId,
      'toAssignmentId': toAssignmentId,
      'toPersonnelId': toPersonnelId,
      'reason': reason,
    };
  }
}