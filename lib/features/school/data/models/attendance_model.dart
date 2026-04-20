import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String attendanceId;
  final String studentId;
  final String schoolId;
  final String allocationId;
  final DateTime date;
  final int dayNumber;
  final String status;
  final String markedBy;
  final DateTime markedAt;
  final String? updatedBy;
  final DateTime? updatedAt;

  const AttendanceModel({
    required this.attendanceId,
    required this.studentId,
    required this.schoolId,
    required this.allocationId,
    required this.date,
    required this.dayNumber,
    required this.status,
    required this.markedBy,
    required this.markedAt,
    this.updatedBy,
    this.updatedAt,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      attendanceId: map['attendanceId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      schoolId: map['schoolId'] as String? ?? '',
      allocationId: map['allocationId'] as String? ?? '',
      date: _dateTimeFromValue(map['date']),
      dayNumber: _intFromValue(map['dayNumber']),
      status: map['status'] as String? ?? 'absent',
      markedBy: map['markedBy'] as String? ?? '',
      markedAt: _dateTimeFromValue(map['markedAt']),
      updatedBy: map['updatedBy'] as String?,
      updatedAt: _nullableDateTimeFromValue(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'attendanceId': attendanceId,
      'studentId': studentId,
      'schoolId': schoolId,
      'allocationId': allocationId,
      'date': Timestamp.fromDate(date),
      'dayNumber': dayNumber,
      'status': status,
      'markedBy': markedBy,
      'markedAt': Timestamp.fromDate(markedAt),
      'updatedBy': updatedBy,
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  static int _intFromValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
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
