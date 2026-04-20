import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolModel {
  final String schoolId;
  final String name;
  final String code;
  final String districtId;
  final String districtName;
  final String address;
  final String block;
  final String cluster;
  final String? principalUserId;
  final int capacity;
  final int currentAssignedCount;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SchoolModel({
    required this.schoolId,
    required this.name,
    required this.code,
    required this.districtId,
    required this.districtName,
    required this.address,
    required this.block,
    required this.cluster,
    this.principalUserId,
    required this.capacity,
    required this.currentAssignedCount,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SchoolModel.fromMap(Map<String, dynamic> map) {
    return SchoolModel(
      schoolId: map['schoolId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      code: map['code'] as String? ?? '',
      districtId: map['districtId'] as String? ?? '',
      districtName: map['districtName'] as String? ?? '',
      address: map['address'] as String? ?? '',
      block: map['block'] as String? ?? '',
      cluster: map['cluster'] as String? ?? '',
      principalUserId: map['principalUserId'] as String?,
      capacity: _intFromValue(map['capacity']),
      currentAssignedCount: _intFromValue(map['currentAssignedCount']),
      isActive: map['isActive'] as bool? ?? true,
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: _dateTimeFromValue(map['createdAt']),
      updatedAt: _dateTimeFromValue(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'name': name,
      'code': code,
      'districtId': districtId,
      'districtName': districtName,
      'address': address,
      'block': block,
      'cluster': cluster,
      'principalUserId': principalUserId,
      'capacity': capacity,
      'currentAssignedCount': currentAssignedCount,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
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
}
