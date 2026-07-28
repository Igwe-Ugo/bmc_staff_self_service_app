// ─── leave_model.dart ─────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum HrLeaveRequestStatus { pending, approved, rejected, cancelled }

// ── Standardized Leave Types (used across the app) ───────────────────────────

const List<String> availableLeaveTypes = [
  'Annual',
  'Sick',
  'Study',
  'Maternity',
  'Paternity',
  'Compassionate',
  'Bereavement',
  'Unpaid',
];

// Optional: Helper extension for formatting
extension LeaveTypeExt on String {
  String get formatted => split('_')
      .map(
        (w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
            : '',
      )
      .join(' ');
}

extension HrLeaveRequestStatusExt on HrLeaveRequestStatus {
  String get value {
    switch (this) {
      case HrLeaveRequestStatus.pending:
        return 'PENDING';
      case HrLeaveRequestStatus.approved:
        return 'APPROVED';
      case HrLeaveRequestStatus.rejected:
        return 'REJECTED';
      case HrLeaveRequestStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String get label {
    switch (this) {
      case HrLeaveRequestStatus.pending:
        return 'Pending';
      case HrLeaveRequestStatus.approved:
        return 'Approved';
      case HrLeaveRequestStatus.rejected:
        return 'Rejected';
      case HrLeaveRequestStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case HrLeaveRequestStatus.pending:
        return const Color(0xFFF39C12);
      case HrLeaveRequestStatus.approved:
        return const Color(0xFF27AE60);
      case HrLeaveRequestStatus.rejected:
        return const Color(0xFFE74C3C);
      case HrLeaveRequestStatus.cancelled:
        return const Color(0xFF8E8E93);
    }
  }

  Color get bgColor {
    switch (this) {
      case HrLeaveRequestStatus.pending:
        return const Color(0xFFFFF3E0);
      case HrLeaveRequestStatus.approved:
        return const Color(0xFFE8F5E9);
      case HrLeaveRequestStatus.rejected:
        return const Color(0xFFFFEBEE);
      case HrLeaveRequestStatus.cancelled:
        return const Color(0xFFF2F2F7);
    }
  }

  static HrLeaveRequestStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'APPROVED':
        return HrLeaveRequestStatus.approved;
      case 'REJECTED':
        return HrLeaveRequestStatus.rejected;
      case 'CANCELLED':
        return HrLeaveRequestStatus.cancelled;
      default:
        return HrLeaveRequestStatus.pending;
    }
  }
}

// ── HrLeaveRequest ────────────────────────────────────────────────────────────

class HrLeaveRequest {
  final String id;
  final String personnelId;
  final String leaveType;
  final String startDate; // yyyy-MM-dd
  final String endDate; // yyyy-MM-dd
  final int totalDays;
  final String? reason;
  final HrLeaveRequestStatus status;
  final String? approvedBy;
  final String? approvedAt;
  final String? decisionNotes;
  final String createdBy;
  final String createdAt;
  final String? updatedBy;
  final String? updatedAt;

  // extended query fields (may be null for basic responses)
  final String? personnelName;
  final String? staffNumber;
  final String? personnelCategory;
  final String? approvedByName;
  final String? deptName;

  const HrLeaveRequest({
    required this.id,
    required this.personnelId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    this.reason,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    this.decisionNotes,
    required this.createdBy,
    required this.createdAt,
    this.updatedBy,
    this.updatedAt,
    this.personnelName,
    this.staffNumber,
    this.personnelCategory,
    this.approvedByName,
    this.deptName,
  });

  DateTime get startDateTime => DateTime.parse(startDate);
  DateTime get endDateTime => DateTime.parse(endDate);

  /// All calendar days covered by this request (inclusive).
  List<DateTime> get days {
    final result = <DateTime>[];
    var d = startDateTime;
    final end = endDateTime;
    while (!d.isAfter(end)) {
      result.add(d);
      d = d.add(const Duration(days: 1));
    }
    return result;
  }

  // In leave_model.dart - Update the HrLeaveRequest.fromJson factory

  factory HrLeaveRequest.fromJson(Map<String, dynamic> json) {
    // Helper to safely get string values
    String? safeString(dynamic value) => value?.toString();

    // Helper to safely get int values
    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed?.round() ?? 0;
      }
      return 0;
    }

    return HrLeaveRequest(
      id: safeString(json['id']) ?? '',
      personnelId: safeString(json['personnelId']) ?? '',
      leaveType: safeString(json['leaveType']) ?? '',
      startDate: (safeString(json['startDate']) ?? '').split('T').first,
      endDate: (safeString(json['endDate']) ?? '').split('T').first,
      totalDays: safeInt(json['totalDays']),
      reason: safeString(json['reason']),
      status: json['status'] != null
          ? HrLeaveRequestStatusExt.fromString(json['status'].toString())
          : HrLeaveRequestStatus.pending,
      approvedBy: safeString(json['approvedBy']),
      approvedAt: safeString(json['approvedAt']),
      decisionNotes: safeString(json['decisionNotes']),
      createdBy: safeString(json['createdBy']) ?? '',
      createdAt:
          safeString(json['createdAt']) ?? DateTime.now().toIso8601String(),
      updatedBy: safeString(json['updatedBy']),
      updatedAt: safeString(json['updatedAt']),
      personnelName: safeString(json['personnelName']),
      staffNumber: safeString(json['staffNumber']),
      personnelCategory: safeString(json['personnelCategory']),
      approvedByName: safeString(json['approvedByName']),
      deptName: safeString(json['deptName']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'personnelId': personnelId,
    'leaveType': leaveType,
    'startDate': startDate,
    'endDate': endDate,
    'totalDays': totalDays,
    'reason': reason,
    'status': status.value,
    'approvedBy': approvedBy,
    'approvedAt': approvedAt,
    'decisionNotes': decisionNotes,
    'createdBy': createdBy,
    'createdAt': createdAt,
    'updatedBy': updatedBy,
    'updatedAt': updatedAt,
  };
}

// ── Form data ─────────────────────────────────────────────────────────────────

class HrLeaveRequestFormData {
  final String personnelId;
  final String leaveType;
  final String startDate;
  final String endDate;
  final int totalDays;
  final String? reason;

  const HrLeaveRequestFormData({
    required this.personnelId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
    'personnelId': personnelId,
    'leaveType': leaveType,
    'startDate': startDate,
    'endDate': endDate,
    'totalDays': totalDays,
    if (reason != null && reason!.isNotEmpty) 'reason': reason,
  };
}

class HrLeaveUpdateFormData {
  final String leaveType;
  final String startDate;
  final String endDate;
  final int totalDays;
  final String? reason;

  const HrLeaveUpdateFormData({
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
    'leaveType': leaveType,
    'startDate': startDate,
    'endDate': endDate,
    'totalDays': totalDays,
    if (reason != null && reason!.isNotEmpty) 'reason': reason,
  };
}

class HrLeaveDecisionFormData {
  final String status; // 'APPROVED' | 'REJECTED'
  final String? decisionNotes;

  const HrLeaveDecisionFormData({required this.status, this.decisionNotes});

  Map<String, dynamic> toJson() => {
    'status': status,
    if (decisionNotes != null) 'decisionNotes': decisionNotes,
  };
}

// ── HrLeaveBalance ────────────────────────────────────────────────────────────

class HrLeaveBalance {
  final String id;
  final String personnelId;
  final int year;
  final String leaveType;
  final int entitlement;
  final int carriedOver;
  final int used;
  final int pending;
  final String createdBy;
  final String createdAt;

  const HrLeaveBalance({
    required this.id,
    required this.personnelId,
    required this.year,
    required this.leaveType,
    required this.entitlement,
    required this.carriedOver,
    required this.used,
    required this.pending,
    required this.createdBy,
    required this.createdAt,
  });

  int get available => entitlement + carriedOver - used - pending;

  factory HrLeaveBalance.fromJson(Map<String, dynamic> json) {
    int i(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
    return HrLeaveBalance(
      id: json['id'] as String,
      personnelId: json['personnelId'] as String,
      year: i(json['year']),
      leaveType: json['leaveType'] as String,
      entitlement: i(json['entitlement']),
      carriedOver: i(json['carriedOver']),
      used: i(json['used']),
      pending: i(json['pending']),
      createdBy: json['createdBy'] as String,
      createdAt: json['createdAt'] as String,
    );
  }
}

// ── Filter query ──────────────────────────────────────────────────────────────

class HrLeaveRequestFilters {
  final String? personnelId;
  final String? deptId;
  final HrLeaveRequestStatus? status;
  final String? leaveType;
  final String? startDate;
  final String? endDate;

  const HrLeaveRequestFilters({
    this.personnelId,
    this.deptId,
    this.status,
    this.leaveType,
    this.startDate,
    this.endDate,
  });

  Map<String, String> toQueryParams() {
    final m = <String, String>{};
    if (personnelId != null) m['personnelId'] = personnelId!;
    if (deptId != null) m['deptId'] = deptId!;
    if (status != null) m['status'] = status!.value;
    if (leaveType != null) m['leaveType'] = leaveType!;
    if (startDate != null) m['startDate'] = startDate!;
    if (endDate != null) m['endDate'] = endDate!;
    return m;
  }
}
