import 'package:cloud_firestore/cloud_firestore.dart';

class CertificateModel {
  final String certificateId;
  final String studentId;
  final String schoolId;
  final String allocationId;
  final int totalDays;
  final int presentDays;
  final double attendancePercentage;
  final bool isEligible;
  final String status;
  final String? certificateNumber;
  final String? certificateUrl;
  final String? generatedBy;
  final DateTime? generatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CertificateModel({
    required this.certificateId,
    required this.studentId,
    required this.schoolId,
    required this.allocationId,
    required this.totalDays,
    required this.presentDays,
    required this.attendancePercentage,
    required this.isEligible,
    required this.status,
    this.certificateNumber,
    this.certificateUrl,
    this.generatedBy,
    this.generatedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CertificateModel.fromMap(Map<String, dynamic> map) {
    return CertificateModel(
      certificateId: map['certificateId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      schoolId: map['schoolId'] as String? ?? '',
      allocationId: map['allocationId'] as String? ?? '',
      totalDays: _intFromValue(map['totalDays']),
      presentDays: _intFromValue(map['presentDays']),
      attendancePercentage: _doubleFromValue(map['attendancePercentage']),
      isEligible: map['isEligible'] as bool? ?? false,
      status: map['status'] as String? ?? 'notEligible',
      certificateNumber: map['certificateNumber'] as String?,
      certificateUrl: map['certificateUrl'] as String?,
      generatedBy: map['generatedBy'] as String?,
      generatedAt: _nullableDateTimeFromValue(map['generatedAt']),
      createdAt: _dateTimeFromValue(map['createdAt']),
      updatedAt: _dateTimeFromValue(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'certificateId': certificateId,
      'studentId': studentId,
      'schoolId': schoolId,
      'allocationId': allocationId,
      'totalDays': totalDays,
      'presentDays': presentDays,
      'attendancePercentage': attendancePercentage,
      'isEligible': isEligible,
      'status': status,
      'certificateNumber': certificateNumber,
      'certificateUrl': certificateUrl,
      'generatedBy': generatedBy,
      'generatedAt':
          generatedAt == null ? null : Timestamp.fromDate(generatedAt!),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static int _intFromValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  static double _doubleFromValue(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return 0;
  }

  static DateTime _dateTimeFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _nullableDateTimeFromValue(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
