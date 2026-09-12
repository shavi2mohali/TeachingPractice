import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

class ExamEligibilityStatus {
  static const String draft = 'draft';
  static const String submittedToDiet = 'submitted_to_diet';
  static const String needsCorrection = 'needs_correction';
  static const String eligible = 'eligible';
  static const String notEligible = 'not_eligible';

  static const Set<String> values = {
    draft,
    submittedToDiet,
    needsCorrection,
    eligible,
    notEligible,
  };

  const ExamEligibilityStatus._();
}

class ExamEligibilitySubmission {
  static const String examCycle = 'october_2026';
  static const int requiredWorkingDays = 200;
  static const double eligibilityThreshold = 75;
  static const int minimumAttendedWorkingDays = 150;

  final String submissionId;
  final String studentId;
  final String registrationId;
  final String studentName;
  final String collegeId;
  final String districtId;
  final String? dietId;
  final int totalWorkingDays;
  final int attendedWorkingDays;
  final double attendancePercentage;
  final String tpCertificateFileName;
  final String tpCertificateMimeType;
  final Uint8List tpCertificatePdf;
  final String collegeRemarks;
  final String status;
  final String submittedBy;
  final DateTime submittedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? dietRemarks;
  final bool? eligible;
  final List<Map<String, dynamic>> reviewHistory;
  final DateTime updatedAt;

  ExamEligibilitySubmission({
    required this.submissionId,
    required this.studentId,
    required this.registrationId,
    required this.studentName,
    required this.collegeId,
    required this.districtId,
    this.dietId,
    this.totalWorkingDays = requiredWorkingDays,
    required this.attendedWorkingDays,
    required this.tpCertificateFileName,
    required this.tpCertificateMimeType,
    required this.tpCertificatePdf,
    required this.collegeRemarks,
    required this.status,
    required this.submittedBy,
    required this.submittedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.dietRemarks,
    this.eligible,
    this.reviewHistory = const [],
    required this.updatedAt,
  }) : attendancePercentage = calculateAttendancePercentage(
         attendedWorkingDays,
       );

  factory ExamEligibilitySubmission.fromMap(Map<String, dynamic> map) {
    final certificate = map['tpCertificatePdf'];
    return ExamEligibilitySubmission(
      submissionId: map['submissionId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      registrationId: map['registrationId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      collegeId: map['collegeId'] as String? ?? '',
      districtId: map['districtId'] as String? ?? '',
      dietId: map['dietId'] as String?,
      totalWorkingDays: _intFromValue(
        map['totalWorkingDays'],
        fallback: requiredWorkingDays,
      ),
      attendedWorkingDays: _intFromValue(map['attendedWorkingDays']),
      tpCertificateFileName: map['tpCertificateFileName'] as String? ?? '',
      tpCertificateMimeType: map['tpCertificateMimeType'] as String? ?? '',
      tpCertificatePdf: certificate is Blob ? certificate.bytes : Uint8List(0),
      collegeRemarks: map['collegeRemarks'] as String? ?? '',
      status: map['status'] as String? ?? ExamEligibilityStatus.draft,
      submittedBy: map['submittedBy'] as String? ?? '',
      submittedAt: _dateTimeFromValue(map['submittedAt']),
      reviewedBy: map['reviewedBy'] as String?,
      reviewedAt: _nullableDateTimeFromValue(map['reviewedAt']),
      dietRemarks: map['dietRemarks'] as String?,
      eligible: map['eligible'] as bool?,
      reviewHistory: _reviewHistoryFromValue(map['reviewHistory']),
      updatedAt: _dateTimeFromValue(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'submissionId': submissionId,
      'examCycle': examCycle,
      'studentId': studentId,
      'registrationId': registrationId,
      'studentName': studentName,
      'collegeId': collegeId,
      'districtId': districtId,
      'dietId': dietId,
      'totalWorkingDays': totalWorkingDays,
      'attendedWorkingDays': attendedWorkingDays,
      'attendancePercentage': attendancePercentage,
      'tpCertificateFileName': tpCertificateFileName,
      'tpCertificateMimeType': tpCertificateMimeType,
      'tpCertificatePdf': Blob(tpCertificatePdf),
      'collegeRemarks': collegeRemarks,
      'status': status,
      'submittedBy': submittedBy,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt == null ? null : Timestamp.fromDate(reviewedAt!),
      'dietRemarks': dietRemarks,
      'eligible': eligible,
      'reviewHistory': reviewHistory,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  String? get latestDietRemarks {
    final activeRemarks = dietRemarks?.trim();
    if (activeRemarks != null && activeRemarks.isNotEmpty) {
      return activeRemarks;
    }
    for (final review in reviewHistory.reversed) {
      final remarks = review['dietRemarks'];
      if (remarks is String && remarks.trim().isNotEmpty) {
        return remarks.trim();
      }
    }
    return null;
  }

  static String documentIdForStudent(String studentId) {
    return '${examCycle}_${studentId.trim()}';
  }

  static double calculateAttendancePercentage(int attendedWorkingDays) {
    return attendedWorkingDays / requiredWorkingDays * 100;
  }

  static int _intFromValue(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }

  static DateTime _dateTimeFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _nullableDateTimeFromValue(dynamic value) {
    if (value == null) return null;
    return _dateTimeFromValue(value);
  }

  static List<Map<String, dynamic>> _reviewHistoryFromValue(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
}
