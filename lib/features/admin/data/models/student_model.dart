import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String studentId;
  final String name;
  final String registrationNumber;
  final String rollNumber;
  final String gender;
  final DateTime? dateOfBirth;
  final String collegeId;
  final String collegeName;
  final String course;
  final String semester;
  final String districtId;
  final String status;
  final String? proposedSchoolId;
  final String? finalSchoolId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudentModel({
    required this.studentId,
    required this.name,
    required this.registrationNumber,
    required this.rollNumber,
    required this.gender,
    this.dateOfBirth,
    required this.collegeId,
    required this.collegeName,
    required this.course,
    required this.semester,
    required this.districtId,
    required this.status,
    this.proposedSchoolId,
    this.finalSchoolId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      studentId: map['studentId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      registrationNumber: map['registrationNumber'] as String? ?? '',
      rollNumber: map['rollNumber'] as String? ?? '',
      gender: map['gender'] as String? ?? '',
      dateOfBirth: _nullableDateTimeFromValue(map['dateOfBirth']),
      collegeId: map['collegeId'] as String? ?? '',
      collegeName: map['collegeName'] as String? ?? '',
      course: map['course'] as String? ?? '',
      semester: map['semester'] as String? ?? '',
      districtId: map['districtId'] as String? ?? '',
      status: map['status'] as String? ?? 'created',
      proposedSchoolId: map['proposedSchoolId'] as String?,
      finalSchoolId: map['finalSchoolId'] as String?,
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: _dateTimeFromValue(map['createdAt']),
      updatedAt: _dateTimeFromValue(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'name': name,
      'registrationNumber': registrationNumber,
      'rollNumber': rollNumber,
      'gender': gender,
      'dateOfBirth':
          dateOfBirth == null ? null : Timestamp.fromDate(dateOfBirth!),
      'collegeId': collegeId,
      'collegeName': collegeName,
      'course': course,
      'semester': semester,
      'districtId': districtId,
      'status': status,
      'proposedSchoolId': proposedSchoolId,
      'finalSchoolId': finalSchoolId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
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
