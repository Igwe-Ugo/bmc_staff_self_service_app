// ─── Enums ────────────────────────────────────────────────────────────────────

import 'dart:ui';

enum HrTimeSlot { am, pm, night, fullDay, /*onCall,*/ custom }

extension HrTimeSlotExt on HrTimeSlot {
  String get value {
    switch (this) {
      case HrTimeSlot.am:
        return 'AM';
      case HrTimeSlot.pm:
        return 'PM';
      case HrTimeSlot.night:
        return 'NIGHT';
      case HrTimeSlot.fullDay:
        return 'FULL_DAY';
      // case HrTimeSlot.onCall:  return 'ON_CALL';
      case HrTimeSlot.custom:
        return 'CUSTOM';
    }
  }

  String get label {
    switch (this) {
      case HrTimeSlot.am:
        return 'AM';
      case HrTimeSlot.pm:
        return 'PM';
      case HrTimeSlot.night:
        return 'Night';
      case HrTimeSlot.fullDay:
        return 'Full Day';
      // case HrTimeSlot.onCall:  return 'On Call';
      case HrTimeSlot.custom:
        return 'Custom';
    }
  }

  static HrTimeSlot fromString(String value) {
    switch (value.toUpperCase()) {
      case 'AM':
        return HrTimeSlot.am;
      case 'PM':
        return HrTimeSlot.pm;
      case 'NIGHT':
        return HrTimeSlot.night;
      case 'FULL_DAY':
        return HrTimeSlot.fullDay;
      //case 'ON_CALL':  return HrTimeSlot.onCall;
      case 'CUSTOM':
        return HrTimeSlot.custom;
      default:
        return HrTimeSlot.fullDay;
    }
  }

  /// Whether this slot requires startTime + endTime from the user
  bool get requiresCustomTime => this == HrTimeSlot.custom;
}

// ─────────────────────────────────────────────────────────────────────────────

enum HrAvailabilityStatus { available, unavailable, preferred, tentative }

extension HrAvailabilityStatusExt on HrAvailabilityStatus {
  String get value {
    switch (this) {
      case HrAvailabilityStatus.available:
        return 'AVAILABLE';
      case HrAvailabilityStatus.unavailable:
        return 'UNAVAILABLE';
      case HrAvailabilityStatus.preferred:
        return 'PREFERRED';
      case HrAvailabilityStatus.tentative:
        return 'TENTATIVE';
    }
  }

  String get label {
    switch (this) {
      case HrAvailabilityStatus.available:
        return 'Available';
      case HrAvailabilityStatus.unavailable:
        return 'Unavailable';
      case HrAvailabilityStatus.preferred:
        return 'Preferred';
      case HrAvailabilityStatus.tentative:
        return 'Tentative';
    }
  }

  Color get color {
    switch (this) {
      case HrAvailabilityStatus.available:
        return const Color(0xFF27AE60);
      case HrAvailabilityStatus.unavailable:
        return const Color(0xFFE74C3C);
      case HrAvailabilityStatus.preferred:
        return const Color(0xFF6C47FF);
      case HrAvailabilityStatus.tentative:
        return const Color(0xFFF39C12);
    }
  }

  Color get bgColor {
    switch (this) {
      case HrAvailabilityStatus.available:
        return const Color(0xFFE8F5E9);
      case HrAvailabilityStatus.unavailable:
        return const Color(0xFFFFEBEE);
      case HrAvailabilityStatus.preferred:
        return const Color(0xFFEDE9FF);
      case HrAvailabilityStatus.tentative:
        return const Color(0xFFFFF3E0);
    }
  }

  static HrAvailabilityStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'AVAILABLE':
        return HrAvailabilityStatus.available;
      case 'UNAVAILABLE':
        return HrAvailabilityStatus.unavailable;
      case 'PREFERRED':
        return HrAvailabilityStatus.preferred;
      case 'TENTATIVE':
        return HrAvailabilityStatus.tentative;
      default:
        return HrAvailabilityStatus.available;
    }
  }
}

// ─── HrAvailabilitySlot ───────────────────────────────────────────────────────

class HrAvailabilitySlot {
  final String id;
  final String personnelId;
  final DateTime date;
  final HrTimeSlot timeSlot;
  final String? startTime;
  final String? endTime;
  final HrAvailabilityStatus availability;
  final String? deptId;
  final String? notes;
  final DateTime submittedAt;
  final DateTime? lockedAt;
  final String createdBy;
  final DateTime createdAt;
  final String? updatedBy;
  final DateTime? updatedAt;

  const HrAvailabilitySlot({
    required this.id,
    required this.personnelId,
    required this.date,
    required this.timeSlot,
    this.startTime,
    this.endTime,
    required this.availability,
    this.deptId,
    this.notes,
    required this.submittedAt,
    this.lockedAt,
    required this.createdBy,
    required this.createdAt,
    this.updatedBy,
    this.updatedAt,
  });

  bool get isLocked => lockedAt != null;

  factory HrAvailabilitySlot.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse strings
    String? safeString(dynamic value) => value?.toString();

    // Helper to safely parse DateTime
    DateTime? safeDateTime(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        return null;
      }
    }

    return HrAvailabilitySlot(
      id: safeString(json['id']) ?? '',
      personnelId: safeString(json['personnelId']) ?? '',
      date: safeDateTime(json['date']) ?? DateTime.now(),
      timeSlot: json['timeSlot'] != null
          ? HrTimeSlotExt.fromString(json['timeSlot'].toString())
          : HrTimeSlot.fullDay,
      startTime: safeString(json['startTime']),
      endTime: safeString(json['endTime']),
      availability: json['availability'] != null
          ? HrAvailabilityStatusExt.fromString(json['availability'].toString())
          : HrAvailabilityStatus.available,
      deptId: safeString(json['deptId']),
      notes: safeString(json['notes']),
      submittedAt: safeDateTime(json['submittedAt']) ?? DateTime.now(),
      lockedAt: safeDateTime(json['lockedAt']),
      createdBy: safeString(json['createdBy']) ?? '',
      createdAt: safeDateTime(json['createdAt']) ?? DateTime.now(),
      updatedBy: safeString(json['updatedBy']),
      updatedAt: safeDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'personnelId': personnelId,
    'date': date.toIso8601String().split('T').first,
    'timeSlot': timeSlot.value,
    'startTime': startTime,
    'endTime': endTime,
    'availability': availability.value,
    'deptId': deptId,
    'notes': notes,
    'submittedAt': submittedAt.toIso8601String(),
    'lockedAt': lockedAt?.toIso8601String(),
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
    'updatedBy': updatedBy,
    'updatedAt': updatedAt?.toIso8601String(),
  };
}

// ─── HrAvailabilitySlotFormData ───────────────────────────────────────────────

class HrAvailabilitySlotFormData {
  final String personnelId;
  final String date; // yyyy-MM-dd
  final HrTimeSlot timeSlot;
  final String? startTime;
  final String? endTime;
  final HrAvailabilityStatus availability;
  final String? deptId;
  final String? notes;

  const HrAvailabilitySlotFormData({
    required this.personnelId,
    required this.date,
    required this.timeSlot,
    this.startTime,
    this.endTime,
    required this.availability,
    this.deptId,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'personnelId': personnelId,
    'date': date,
    'timeSlot': timeSlot.value,
    if (startTime != null) 'startTime': startTime,
    if (endTime != null) 'endTime': endTime,
    'availability': availability.value,
    if (deptId != null) 'deptId': deptId,
    if (notes != null) 'notes': notes,
  };
}

// ─── HrAvailabilityBulkFormData ───────────────────────────────────────────────

class HrAvailabilityBulkSlot {
  final String date;
  final HrTimeSlot timeSlot;
  final String? startTime;
  final String? endTime;
  final HrAvailabilityStatus availability;
  final String? deptId;
  final String? notes;

  const HrAvailabilityBulkSlot({
    required this.date,
    required this.timeSlot,
    this.startTime,
    this.endTime,
    required this.availability,
    this.deptId,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'date': date,
    'timeSlot': timeSlot.value,
    if (startTime != null) 'startTime': startTime,
    if (endTime != null) 'endTime': endTime,
    'availability': availability.value,
    if (deptId != null) 'deptId': deptId,
    if (notes != null) 'notes': notes,
  };
}

class HrAvailabilityBulkFormData {
  final String personnelId;
  final List<HrAvailabilityBulkSlot> slots;

  const HrAvailabilityBulkFormData({
    required this.personnelId,
    required this.slots,
  });

  Map<String, dynamic> toJson() => {
    'personnelId': personnelId,
    'slots': slots.map((s) => s.toJson()).toList(),
  };
}

// ─── HrAvailabilityWindow ─────────────────────────────────────────────────────

class HrAvailabilityWindow {
  final String id;
  final String month; // e.g. "2026-05"
  final DateTime opensAt;
  final DateTime closesAt;
  final DateTime? reminderSentAt;
  final String createdBy;
  final DateTime createdAt;

  const HrAvailabilityWindow({
    required this.id,
    required this.month,
    required this.opensAt,
    required this.closesAt,
    this.reminderSentAt,
    required this.createdBy,
    required this.createdAt,
  });

  // ── Computed state ────────────────────────────────────────────────────────
  bool get isOpen {
    final now = DateTime.now().toUtc();
    return now.isAfter(opensAt.toUtc()) && now.isBefore(closesAt.toUtc());
  }

  bool get hasOpened => DateTime.now().isAfter(opensAt);
  bool get hasClosed => DateTime.now().isAfter(closesAt);

  Duration get timeUntilOpen => opensAt.difference(DateTime.now());
  Duration get timeUntilClose => closesAt.difference(DateTime.now());

  factory HrAvailabilityWindow.fromJson(Map<String, dynamic> json) {
    return HrAvailabilityWindow(
      id: json['id'] as String,
      month: json['month'] as String,
      opensAt: DateTime.parse(json['opensAt'] as String),
      closesAt: DateTime.parse(json['closesAt'] as String),
      reminderSentAt: json['reminderSentAt'] != null
          ? DateTime.parse(json['reminderSentAt'] as String)
          : null,
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'month': month,
    'opensAt': opensAt.toIso8601String(),
    'closesAt': closesAt.toIso8601String(),
    'reminderSentAt': reminderSentAt?.toIso8601String(),
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
  };
}

// ─── HrAvailabilityWindowFormData ────────────────────────────────────────────

class HrAvailabilityWindowFormData {
  final String month;
  final String opensAt;
  final String closesAt;

  const HrAvailabilityWindowFormData({
    required this.month,
    required this.opensAt,
    required this.closesAt,
  });

  Map<String, dynamic> toJson() => {
    'month': month,
    'opensAt': opensAt,
    'closesAt': closesAt,
  };
}
