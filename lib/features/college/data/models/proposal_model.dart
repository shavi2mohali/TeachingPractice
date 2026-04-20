import 'package:cloud_firestore/cloud_firestore.dart';

class ProposalModel {
  final String proposalId;
  final String studentId;
  final String collegeId;
  final String proposedSchoolId;
  final String districtId;
  final String status;
  final String proposedBy;
  final DateTime proposedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final String? finalAssignedBy;
  final DateTime? finalAssignedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProposalModel({
    required this.proposalId,
    required this.studentId,
    required this.collegeId,
    required this.proposedSchoolId,
    required this.districtId,
    required this.status,
    required this.proposedBy,
    required this.proposedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
    this.finalAssignedBy,
    this.finalAssignedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProposalModel.fromMap(Map<String, dynamic> map) {
    return ProposalModel(
      proposalId: map['proposalId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      collegeId: map['collegeId'] as String? ?? '',
      proposedSchoolId: map['proposedSchoolId'] as String? ?? '',
      districtId: map['districtId'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      proposedBy: map['proposedBy'] as String? ?? '',
      proposedAt: _dateTimeFromValue(map['proposedAt']),
      reviewedBy: map['reviewedBy'] as String?,
      reviewedAt: _nullableDateTimeFromValue(map['reviewedAt']),
      rejectionReason: map['rejectionReason'] as String?,
      finalAssignedBy: map['finalAssignedBy'] as String?,
      finalAssignedAt: _nullableDateTimeFromValue(map['finalAssignedAt']),
      createdAt: _dateTimeFromValue(map['createdAt']),
      updatedAt: _dateTimeFromValue(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'proposalId': proposalId,
      'studentId': studentId,
      'collegeId': collegeId,
      'proposedSchoolId': proposedSchoolId,
      'districtId': districtId,
      'status': status,
      'proposedBy': proposedBy,
      'proposedAt': Timestamp.fromDate(proposedAt),
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt == null ? null : Timestamp.fromDate(reviewedAt!),
      'rejectionReason': rejectionReason,
      'finalAssignedBy': finalAssignedBy,
      'finalAssignedAt':
          finalAssignedAt == null ? null : Timestamp.fromDate(finalAssignedAt!),
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
