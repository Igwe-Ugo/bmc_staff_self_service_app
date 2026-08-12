class TelemedRecording {
  final String? id;
  final String? url;
  final DateTime? recordedAt;

  TelemedRecording({this.id, this.url, this.recordedAt});

  factory TelemedRecording.fromJson(Map<String, dynamic> json) {
    return TelemedRecording(
      id: json['id'],
      url: json['url'],
      recordedAt: json['recordedAt'] != null
          ? DateTime.tryParse(json['recordedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'recordedAt': recordedAt?.toIso8601String(),
  };
}

class PatientCompleteness {
  final bool isComplete;
  final int missingCount;
  final List<String> missingFields;

  PatientCompleteness({
    required this.isComplete,
    required this.missingCount,
    required this.missingFields,
  });

  factory PatientCompleteness.fromJson(Map<String, dynamic> json) {
    return PatientCompleteness(
      isComplete: json['isComplete'] ?? false,
      missingCount: json['missingCount'] ?? 0,
      missingFields: List<String>.from(json['missingFields'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'isComplete': isComplete,
    'missingCount': missingCount,
    'missingFields': missingFields,
  };
}

class QryBookingVisits {
  final String? id;
  final int? medrecnum;
  final String? appmtDay;
  final DateTime? appmtStartDate;
  final DateTime? appmtEndDate;
  final String? billableId;
  final String? fstBillableId;
  final int? firstOrFollowUp;
  final String? patType;
  final String? location;
  final int? bookingPaid;
  final String? slotName;
  final int? checkedIn;
  final String? acl;
  final String? type;
  final double? owedGlobal;
  final double? owedBooking;
  final double? owedIOU;
  final String? walletId;
  final String? fullname;
  final String? gender;
  final String? picture;
  final DateTime? dob;
  final int? protectPatient;
  final int? isLegacy;
  final String? requestId;
  final String? requestStatus;
  final int? fundingRequested;
  final double? variability;
  final String? recipients;
  final DateTime? sentAt;
  final double? reqAmount;
  final String? reqByName;
  final DateTime? bookedDate;
  final String? bookedByName;
  final int? isTelemed;
  final int? telemedType;
  final String? status;
  final String? deptId;
  final String? sectionId;
  final String? facilityId;
  final String? facilityName;
  final int? callStarted;
  final DateTime? callStartTime;
  final int? callEnded;
  final DateTime? callEndTime;
  final int? hasRecordings;
  final List<TelemedRecording>? recordings;
  final int? roomReady;
  final int? patientReady;
  final String? telemedProviderId;
  final String? consultationId;
  final int? consultantReady;
  final int? patientCalledIn;
  final DateTime? patientCalledInTime;
  final String? telemedServiceUserId;
  final String? telemedServiceOwnerId;
  final String? visitId;
  final int? consultationCompleted;
  final DateTime? completedAt;
  final int? triageCompleted;
  final int? triageBypassed;
  final String? triageBypassReason;
  final String? triageBypassBy;
  final String? telemedProviderName;
  final String? specialistClinicType;
  final String? arrivalBy;
  final String? vitalsBy;
  final String? triageBy;
  final String? treatmentBy;
  final String? outcomeBy;
  final String? finalOutcome;
  final String? arrivalByName;
  final String? vitalsByName;
  final String? triageByName;
  final String? treatmentByName;
  final String? outcomeByName;
  final PatientCompleteness? completeness;

  QryBookingVisits({
    this.id,
    this.medrecnum,
    this.appmtDay,
    this.appmtStartDate,
    this.appmtEndDate,
    this.billableId,
    this.fstBillableId,
    this.firstOrFollowUp,
    this.patType,
    this.location,
    this.bookingPaid,
    this.slotName,
    this.checkedIn,
    this.acl,
    this.type,
    this.owedGlobal,
    this.owedBooking,
    this.owedIOU,
    this.walletId,
    this.fullname,
    this.gender,
    this.picture,
    this.dob,
    this.protectPatient,
    this.isLegacy,
    this.requestId,
    this.requestStatus,
    this.fundingRequested,
    this.variability,
    this.recipients,
    this.sentAt,
    this.reqAmount,
    this.reqByName,
    this.bookedDate,
    this.bookedByName,
    this.isTelemed,
    this.telemedType,
    this.status,
    this.deptId,
    this.sectionId,
    this.facilityId,
    this.facilityName,
    this.callStarted,
    this.callStartTime,
    this.callEnded,
    this.callEndTime,
    this.hasRecordings,
    this.recordings,
    this.roomReady,
    this.patientReady,
    this.telemedProviderId,
    this.consultationId,
    this.consultantReady,
    this.patientCalledIn,
    this.patientCalledInTime,
    this.telemedServiceUserId,
    this.telemedServiceOwnerId,
    this.visitId,
    this.consultationCompleted,
    this.completedAt,
    this.triageCompleted,
    this.triageBypassed,
    this.triageBypassReason,
    this.triageBypassBy,
    this.telemedProviderName,
    this.specialistClinicType,
    this.arrivalBy,
    this.vitalsBy,
    this.triageBy,
    this.treatmentBy,
    this.outcomeBy,
    this.finalOutcome,
    this.arrivalByName,
    this.vitalsByName,
    this.triageByName,
    this.treatmentByName,
    this.outcomeByName,
    this.completeness,
  });

  factory QryBookingVisits.fromJson(Map<String, dynamic> json) {
    num? _parseNum(dynamic value) {
      if (value == null) return null;
      if (value is num) return value;
      if (value is String) return num.tryParse(value);
      return null;
    }

    double? _parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    int? _parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return QryBookingVisits(
      id: json['id'] as String?,
      medrecnum: _parseInt(json['medrecnum']),
      appmtDay: json['appmtDay'],
      appmtStartDate: json['appmtStartDate'] != null
          ? DateTime.tryParse(json['appmtStartDate'])
          : null,
      appmtEndDate: json['appmtEndDate'] != null
          ? DateTime.tryParse(json['appmtEndDate'])
          : null,
      billableId: json['billableId'],
      fstBillableId: json['fstBillableId'],
      firstOrFollowUp: json['firstOrFollowUp'],
      patType: json['patType'],
      location: json['location'],
      slotName: json['slotName'],
      checkedIn: json['checkedIn'],
      acl: json['acl'],
      type: json['type'],
      owedGlobal: _parseDouble(json['owedGlobal']),
      owedBooking: _parseDouble(json['owedBooking']),
      owedIOU: _parseDouble(json['owedIOU']),
      bookingPaid: _parseInt(json['bookingPaid']),
      isTelemed: _parseInt(json['isTelemed']),
      telemedType: _parseInt(json['telemedType']),
      walletId: json['walletId'],
      fullname: json['fullname'],
      gender: json['gender'],
      picture: json['picture'],
      dob: json['dob'] != null ? DateTime.tryParse(json['dob']) : null,
      protectPatient: json['protectPatient'],
      isLegacy: json['isLegacy'],
      requestId: json['requestId'],
      requestStatus: json['requestStatus'],
      fundingRequested: json['fundingRequested'],
      variability: (json['variability'] as num?)?.toDouble(),
      recipients: json['recipients'],
      sentAt: json['sentAt'] != null ? DateTime.tryParse(json['sentAt']) : null,
      reqAmount: (json['reqAmount'] as num?)?.toDouble(),
      reqByName: json['reqByName'],
      bookedDate: json['bookedDate'] != null
          ? DateTime.tryParse(json['bookedDate'])
          : null,
      bookedByName: json['bookedByName'],
      status: json['status'],
      deptId: json['deptId'],
      sectionId: json['sectionId'],
      facilityId: json['facilityId'],
      facilityName: json['facilityName'],
      callStarted: json['callStarted'],
      callStartTime: json['callStartTime'] != null
          ? DateTime.tryParse(json['callStartTime'])
          : null,
      callEnded: json['callEnded'],
      callEndTime: json['callEndTime'] != null
          ? DateTime.tryParse(json['callEndTime'])
          : null,
      hasRecordings: json['hasRecordings'],
      recordings: json['recordings'] != null
          ? (json['recordings'] as List)
                .map((e) => TelemedRecording.fromJson(e))
                .toList()
          : null,
      roomReady: json['roomReady'],
      patientReady: json['patientReady'],
      telemedProviderId: json['telemedProviderId'],
      consultationId: json['consultationId'],
      consultantReady: json['consultantReady'],
      patientCalledIn: json['patientCalledIn'],
      patientCalledInTime: json['patientCalledInTime'] != null
          ? DateTime.tryParse(json['patientCalledInTime'])
          : null,
      telemedServiceUserId: json['telemedServiceUserId'],
      telemedServiceOwnerId: json['telemedServiceOwnerId'],
      visitId: json['visitId'],
      consultationCompleted: json['consultationCompleted'],
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'])
          : null,
      triageCompleted: json['triageCompleted'],
      triageBypassed: json['triageBypassed'],
      triageBypassReason: json['triageBypassReason'],
      triageBypassBy: json['triageBypassBy'],
      telemedProviderName: json['telemedProviderName'],
      specialistClinicType: json['specialistClinicType'],
      arrivalBy: json['arrivalBy'],
      vitalsBy: json['vitalsBy'],
      triageBy: json['triageBy'],
      treatmentBy: json['treatmentBy'],
      outcomeBy: json['outcomeBy'],
      finalOutcome: json['finalOutcome'],
      arrivalByName: json['arrivalByName'],
      vitalsByName: json['vitalsByName'],
      triageByName: json['triageByName'],
      treatmentByName: json['treatmentByName'],
      outcomeByName: json['outcomeByName'],
      completeness: json['completeness'] != null
          ? PatientCompleteness.fromJson(json['completeness'])
          : null,
    );
  }
}
