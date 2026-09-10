import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';

import '../../features/admin/data/models/school_model.dart';
import '../../features/admin/data/models/student_model.dart';
import '../../features/college/data/models/proposal_model.dart';
import '../../features/school/data/models/attendance_model.dart';
import '../../features/school/data/models/certificate_model.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const int _totalTrainingDays = 28;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _students =>
      _firestore.collection('students');

  CollectionReference<Map<String, dynamic>> get _schools =>
      _firestore.collection('schools');

  CollectionReference<Map<String, dynamic>> get _colleges =>
      _firestore.collection('colleges');

  CollectionReference<Map<String, dynamic>> get _diets =>
      _firestore.collection('diets');

  CollectionReference<Map<String, dynamic>> get _proposals =>
      _firestore.collection('proposals');

  CollectionReference<Map<String, dynamic>> get _allocations =>
      _firestore.collection('allocations');

  CollectionReference<Map<String, dynamic>> get _attendance =>
      _firestore.collection('attendance');

  CollectionReference<Map<String, dynamic>> get _certificates =>
      _firestore.collection('certificates');

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _correctionRequests =>
      _firestore.collection('correction_requests');

  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollegeCorrectionStudents(
    String collegeId,
  ) async* {
    final id = collegeId.trim();
    final aliases = <String>{id};
    // Resolve legacy college names only through the college directory.
    final matches = await Future.wait([
      _colleges.doc(id).get(),
      ...['collegeId', 'name', 'shortName'].map((field) async {
        final result = await _colleges
            .where(field, isEqualTo: id)
            .limit(1)
            .get();
        return result.docs.isEmpty ? null : result.docs.first;
      }),
    ]);
    for (final college in matches) {
      final data = college?.data();
      if (college == null || data == null) continue;
      aliases.add(college.id);
      for (final field in ['collegeId', 'name', 'shortName']) {
        final value = data[field];
        if (value is String && value.trim().isNotEmpty) {
          aliases.add(value.trim());
        }
      }
    }
    yield* (aliases.length == 1
            ? _students.where('collegeId', isEqualTo: id)
            : _students.where('collegeId', whereIn: aliases.toList()))
        .snapshots();
  }

  Stream<List<PendingRegistration>> streamPendingRegistrations() {
    return _users
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .asyncMap(_mapRegistrationsWithEntityNames);
  }

  Stream<List<PendingRegistration>> streamRegistrationHistory() {
    return _users
        .where('status', whereIn: ['approved', 'rejected'])
        .snapshots()
        .asyncMap(_mapRegistrationsWithEntityNames);
  }

  Future<List<PendingRegistration>> getRegistrationHistory() async {
    final snapshot = await _users
        .where('status', whereIn: ['approved', 'rejected'])
        .get();

    return _mapRegistrationsWithEntityNames(snapshot);
  }

  Future<void> approveRegistration(String uid) async {
    await _users.doc(uid).update({
      'status': 'approved',
      'actionedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectRegistration(String uid) async {
    await _users.doc(uid).update({
      'status': 'rejected',
      'actionedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> addStudent(StudentModel student) async {
    final docRef = student.studentId.isEmpty
        ? _students.doc()
        : _students.doc(student.studentId);

    final data = student.toMap()
      ..['studentId'] = docRef.id
      ..['updatedAt'] = Timestamp.now();

    await docRef.set(data);
    return docRef.id;
  }

  Future<String> addSchool(SchoolModel school) async {
    final docRef = school.schoolId.isEmpty
        ? _schools.doc()
        : _schools.doc(school.schoolId);

    final data = school.toMap()
      ..['schoolId'] = docRef.id
      ..['updatedAt'] = Timestamp.now();

    await docRef.set(data);
    return docRef.id;
  }

  Future<List<SchoolModel>> getSchoolsByDistrict(String districtId) async {
    final snapshot = await _schools
        .where('districtId', isEqualTo: districtId.trim())
        .get();

    return snapshot.docs
        .map((doc) => SchoolModel.fromMap({...doc.data(), 'schoolId': doc.id}))
        .toList();
  }

  Stream<List<SchoolModel>> streamSchoolsByDistrict(String districtId) {
    return _schools
        .where('districtId', isEqualTo: districtId.trim())
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    SchoolModel.fromMap({...doc.data(), 'schoolId': doc.id}),
              )
              .toList(),
        );
  }

  Stream<List<SchoolModel>> streamSchools({String? districtId}) {
    Query<Map<String, dynamic>> query = _schools;

    final filter = districtId?.trim();
    if (filter != null && filter.isNotEmpty) {
      query = query.where('districtId', isEqualTo: filter);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => SchoolModel.fromMap({...doc.data(), 'schoolId': doc.id}),
          )
          .toList(),
    );
  }

  Stream<List<StudentModel>> streamStudentsByCollege(String collegeId) {
    return _students
        .where('collegeId', isEqualTo: collegeId)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    StudentModel.fromMap({...doc.data(), 'studentId': doc.id}),
              )
              .toList(),
        );
  }

  Stream<List<StudentModel>> streamStudents() {
    return _students.snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => StudentModel.fromMap({...doc.data(), 'studentId': doc.id}),
          )
          .toList(),
    );
  }

  Stream<List<AttendanceModel>> streamAttendanceByStudent(String studentId) {
    return _attendance
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => AttendanceModel.fromMap({
                  ...doc.data(),
                  'attendanceId': doc.id,
                }),
              )
              .toList(),
        );
  }

  Stream<List<ProposalModel>> streamPendingProposalsByDistrict(
    String districtId,
  ) {
    return _proposals
        .where('districtId', isEqualTo: districtId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ProposalModel.fromMap({
                  ...doc.data(),
                  'proposalId': doc.id,
                }),
              )
              .toList(),
        );
  }

  Stream<List<ProposalModel>> streamApprovedProposalsByDistrict(
    String districtId,
  ) {
    return _proposals
        .where('districtId', isEqualTo: districtId)
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ProposalModel.fromMap({
                  ...doc.data(),
                  'proposalId': doc.id,
                }),
              )
              .toList(),
        );
  }

  Stream<List<ProposalModel>> streamProposals({String? status}) {
    Query<Map<String, dynamic>> query = _proposals;

    final filter = status?.trim();
    if (filter != null && filter.isNotEmpty) {
      query = query.where('status', isEqualTo: filter);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) =>
                ProposalModel.fromMap({...doc.data(), 'proposalId': doc.id}),
          )
          .toList(),
    );
  }

  Future<StudentModel?> getStudentById(String studentId) async {
    final snapshot = await _students.doc(studentId).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return StudentModel.fromMap({...data, 'studentId': snapshot.id});
  }

  Future<SchoolModel?> getSchoolById(String schoolId) async {
    final snapshot = await _schools.doc(schoolId).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return SchoolModel.fromMap({...data, 'schoolId': snapshot.id});
  }

  Stream<List<AssignedStudentRecord>> streamAssignedStudentsBySchool(
    String schoolId,
  ) {
    return _allocations
        .where('schoolId', isEqualTo: schoolId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .asyncMap((snapshot) async {
          final records = <AssignedStudentRecord>[];

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final studentId = data['studentId'] as String? ?? '';

            if (studentId.isEmpty) {
              continue;
            }

            final student = await getStudentById(studentId);

            if (student == null) {
              continue;
            }

            records.add(
              AssignedStudentRecord(
                allocationId: data['allocationId'] as String? ?? doc.id,
                student: student,
                schoolId: data['schoolId'] as String? ?? schoolId,
                assignedAt: _dateTimeFromValue(data['assignedAt']),
              ),
            );
          }

          return records;
        });
  }

  Future<String> createProposal(ProposalModel proposal) async {
    final proposalRef = proposal.proposalId.isEmpty
        ? _proposals.doc()
        : _proposals.doc(proposal.proposalId);
    final studentRef = _students.doc(proposal.studentId);

    await _firestore.runTransaction((transaction) async {
      final proposalData = proposal.toMap()
        ..['proposalId'] = proposalRef.id
        ..['status'] = 'pending'
        ..['updatedAt'] = Timestamp.now();

      transaction.set(proposalRef, proposalData);
      transaction.update(studentRef, {
        'status': 'proposed',
        'proposedSchoolId': proposal.proposedSchoolId,
        'submittedOn': Timestamp.fromDate(proposal.proposedAt),
        'updatedAt': Timestamp.now(),
      });
    });

    return proposalRef.id;
  }

  Future<String> createCorrectionRequest({
    required String studentId,
    required String registrationId,
    required String collegeId,
    required String districtId,
    required String requestedBy,
    required String studentName,
    required String fatherName,
    required String motherName,
    required String nameCorrectionEnglish,
    required String namePunjabi,
    required String fatherNameCorrectionEnglish,
    required String fatherNamePunjabi,
    required String motherNameCorrectionEnglish,
    required String motherNamePunjabi,
    required Uint8List certificateBytes,
    required String certificateFileName,
    required String certificateMimeType,
  }) async {
    final requestRef = _correctionRequests.doc();
    final studentRef = _students.doc(studentId);
    final now = Timestamp.now();
    final normalizedCollegeId = collegeId.trim();
    if (normalizedCollegeId.isEmpty) {
      throw StateError('College details not found');
    }

    await _firestore.runTransaction((transaction) async {
      transaction.set(requestRef, {
        'requestId': requestRef.id,
        'studentId': studentId,
        'registrationId': registrationId,
        'collegeId': normalizedCollegeId,
        'districtId': districtId,
        'requestedBy': requestedBy,
        'studentName': studentName,
        'fatherName': fatherName,
        'motherName': motherName,
        'nameCorrectionEnglish': nameCorrectionEnglish,
        'namePunjabi': namePunjabi,
        'fatherNameCorrectionEnglish': fatherNameCorrectionEnglish,
        'fatherNamePunjabi': fatherNamePunjabi,
        'motherNameCorrectionEnglish': motherNameCorrectionEnglish,
        'motherNamePunjabi': motherNamePunjabi,
        'certificateFileName': certificateFileName,
        'certificateMimeType': certificateMimeType,
        'certificatePdf': Blob(certificateBytes),
        'status': 'pending',
        'createdAt': now,
        'updatedAt': now,
      });

      transaction.update(studentRef, {
        'correctionRequestStatus': 'pending',
        'correctionRequestedAt': now,
        'correctionRejectedAt': FieldValue.delete(),
        'correctionRejectedRemarks': FieldValue.delete(),
        'correctionApprovedAt': FieldValue.delete(),
        'updatedAt': now,
      });
    });

    return requestRef.id;
  }

  Future<void> approveCorrectionRequest({
    required String requestId,
    required String studentId,
    required String reviewedBy,
    required String nameCorrectionEnglish,
    required String namePunjabi,
    required String fatherNameCorrectionEnglish,
    required String fatherNamePunjabi,
    required String motherNameCorrectionEnglish,
    required String motherNamePunjabi,
  }) async {
    final requestRef = _correctionRequests.doc(requestId);
    final studentRef = _students.doc(studentId);
    final now = Timestamp.now();

    await _firestore.runTransaction((transaction) async {
      transaction.update(requestRef, {
        'status': 'approved',
        'reviewedBy': reviewedBy,
        'reviewedAt': now,
        'updatedAt': now,
      });

      transaction.update(studentRef, {
        if (nameCorrectionEnglish.trim().isNotEmpty) ...{
          'name': nameCorrectionEnglish.trim(),
          'nameCorrectionEnglish': nameCorrectionEnglish.trim(),
        },
        if (namePunjabi.trim().isNotEmpty) 'namePunjabi': namePunjabi.trim(),
        if (fatherNameCorrectionEnglish.trim().isNotEmpty) ...{
          'fatherName': fatherNameCorrectionEnglish.trim(),
          'fatherNameCorrectionEnglish': fatherNameCorrectionEnglish.trim(),
        },
        if (fatherNamePunjabi.trim().isNotEmpty)
          'fatherNamePunjabi': fatherNamePunjabi.trim(),
        if (motherNameCorrectionEnglish.trim().isNotEmpty) ...{
          'motherName': motherNameCorrectionEnglish.trim(),
          'motherNameCorrectionEnglish': motherNameCorrectionEnglish.trim(),
        },
        if (motherNamePunjabi.trim().isNotEmpty)
          'motherNamePunjabi': motherNamePunjabi.trim(),
        'correctionRequestStatus': 'approved',
        'correctionApprovedAt': now,
        'correctionRejectedAt': FieldValue.delete(),
        'correctionRejectedRemarks': FieldValue.delete(),
        'updatedAt': now,
      });
    });
  }

  Future<void> rejectCorrectionRequest({
    required String requestId,
    required String studentId,
    required String reviewedBy,
    required String remarks,
  }) async {
    final requestRef = _correctionRequests.doc(requestId);
    final studentRef = _students.doc(studentId);
    final now = Timestamp.now();

    await _firestore.runTransaction((transaction) async {
      transaction.update(requestRef, {
        'status': 'rejected',
        'reviewedBy': reviewedBy,
        'reviewedAt': now,
        'rejectionRemarks': remarks.trim(),
        'updatedAt': now,
      });

      transaction.update(studentRef, {
        'correctionRequestStatus': 'rejected',
        'correctionRejectedAt': now,
        'correctionRejectedRemarks': remarks.trim(),
        'updatedAt': now,
      });
    });
  }

  Future<void> approveProposal({
    required String proposalId,
    required String studentId,
    required String reviewedBy,
    String? schoolId,
  }) async {
    final proposalRef = _proposals.doc(proposalId);
    final studentRef = _students.doc(studentId);

    await _firestore.runTransaction((transaction) async {
      transaction.update(proposalRef, {
        'status': 'approved',
        'reviewedBy': reviewedBy,
        'reviewedAt': Timestamp.now(),
        'rejectionReason': null,
        if (schoolId != null && schoolId.isNotEmpty)
          'proposedSchoolId': schoolId,
        'updatedAt': Timestamp.now(),
      });

      transaction.update(studentRef, {
        'status': 'deoApproved',
        if (schoolId != null && schoolId.isNotEmpty)
          'proposedSchoolId': schoolId,
        'updatedAt': Timestamp.now(),
      });
    });
  }

  Future<void> rejectProposal({
    required String proposalId,
    required String studentId,
    required String reviewedBy,
    String? rejectionReason,
  }) async {
    final proposalRef = _proposals.doc(proposalId);
    final studentRef = _students.doc(studentId);

    await _firestore.runTransaction((transaction) async {
      transaction.update(proposalRef, {
        'status': 'rejected',
        'reviewedBy': reviewedBy,
        'reviewedAt': Timestamp.now(),
        'rejectionReason': rejectionReason,
        'updatedAt': Timestamp.now(),
      });

      transaction.update(studentRef, {
        'status': 'deoRejected',
        'proposedSchoolId': null,
        'updatedAt': Timestamp.now(),
      });
    });
  }

  Future<String> assignSchool({
    required String proposalId,
    required String studentId,
    required String collegeId,
    required String districtId,
    required String schoolId,
    required String assignedBy,
  }) async {
    final proposalRef = _proposals.doc(proposalId);
    final studentRef = _students.doc(studentId);
    final schoolRef = _schools.doc(schoolId);
    final allocationRef = _allocations.doc();

    await _firestore.runTransaction((transaction) async {
      final now = Timestamp.now();

      transaction.set(allocationRef, {
        'allocationId': allocationRef.id,
        'studentId': studentId,
        'proposalId': proposalId,
        'collegeId': collegeId,
        'districtId': districtId,
        'schoolId': schoolId,
        'assignedBy': assignedBy,
        'assignedAt': now,
        'status': 'active',
        'createdAt': now,
        'updatedAt': now,
      });

      transaction.update(proposalRef, {
        'status': 'assigned_by_diet',
        'finalAssignedBy': assignedBy,
        'finalAssignedAt': now,
        'updatedAt': now,
      });

      transaction.update(studentRef, {
        'status': 'assigned_by_diet',
        'finalSchoolId': schoolId,
        'updatedAt': now,
      });

      transaction.update(schoolRef, {
        'currentAssignedCount': FieldValue.increment(1),
        'updatedAt': now,
      });
    });

    return allocationRef.id;
  }

  Future<void> markAttendance(AttendanceModel attendance) async {
    final docId = attendance.attendanceId.isEmpty
        ? _attendanceDocumentId(attendance.studentId, attendance.date)
        : attendance.attendanceId;
    final docRef = _attendance.doc(docId);

    final data = attendance.toMap()
      ..['attendanceId'] = docId
      ..['updatedAt'] = Timestamp.now();

    await docRef.set(data, SetOptions(merge: true));
  }

  Future<AttendanceCalculation> calculateAttendance({
    required String studentId,
    String? allocationId,
  }) async {
    Query<Map<String, dynamic>> query = _attendance.where(
      'studentId',
      isEqualTo: studentId,
    );

    if (allocationId != null && allocationId.isNotEmpty) {
      query = query.where('allocationId', isEqualTo: allocationId);
    }

    final snapshot = await query.get();
    final markedDayNumbers = <int>{};
    final presentDayNumbers = <int>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final dayNumber = data['dayNumber'];

      if (dayNumber is! num || dayNumber < 1 || dayNumber > 28) {
        continue;
      }

      final normalizedDayNumber = dayNumber.toInt();
      markedDayNumbers.add(normalizedDayNumber);

      if (data['status'] == 'present') {
        presentDayNumbers.add(normalizedDayNumber);
      }
    }

    final markedDays = markedDayNumbers.length;
    final presentDays = presentDayNumbers.length;
    final percentage = (presentDays / _totalTrainingDays) * 100;

    return AttendanceCalculation(
      totalDays: _totalTrainingDays,
      markedDays: markedDays,
      presentDays: presentDays,
      attendancePercentage: percentage,
      isEligible: presentDays >= 26,
    );
  }

  Future<CertificateModel?> generateCertificateIfEligible({
    required String studentId,
    required String schoolId,
    required String allocationId,
    required String generatedBy,
    String? certificateNumber,
  }) async {
    final calculation = await calculateAttendance(
      studentId: studentId,
      allocationId: allocationId,
    );

    if (!calculation.isEligible) {
      return null;
    }

    final certificateRef = _certificates.doc(allocationId);
    final now = DateTime.now();
    final certificate = CertificateModel(
      certificateId: certificateRef.id,
      studentId: studentId,
      schoolId: schoolId,
      allocationId: allocationId,
      totalDays: calculation.totalDays,
      presentDays: calculation.presentDays,
      attendancePercentage: calculation.attendancePercentage,
      isEligible: calculation.isEligible,
      status: 'eligible',
      certificateNumber: certificateNumber,
      certificateUrl: null,
      generatedBy: generatedBy,
      generatedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    await certificateRef.set(certificate.toMap(), SetOptions(merge: true));
    return certificate;
  }

  Future<String> generateCertificate({
    required String studentId,
    required String schoolId,
    required String allocationId,
    required String generatedBy,
    String? certificateNumber,
  }) async {
    final certificate = await generateCertificateIfEligible(
      studentId: studentId,
      schoolId: schoolId,
      allocationId: allocationId,
      generatedBy: generatedBy,
      certificateNumber: certificateNumber,
    );

    if (certificate == null) {
      throw StateError('Attendance is below 90%. Certificate not generated.');
    }

    return certificate.certificateId;
  }

  String _attendanceDocumentId(String studentId, DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${studentId}_$year$month$day';
  }

  Future<List<PendingRegistration>> _mapRegistrationsWithEntityNames(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    final registrations = await Future.wait(
      snapshot.docs.map((doc) async {
        final data = <String, dynamic>{...doc.data(), 'uid': doc.id};

        data['entityName'] = await _resolveEntityName(data);
        return PendingRegistration.fromMap(data);
      }),
    );

    registrations.sort(
      (first, second) => second.actionedAt.compareTo(first.actionedAt),
    );

    return registrations;
  }

  Future<String> _resolveEntityName(Map<String, dynamic> data) async {
    final role = (data['role'] as String? ?? '').trim().toLowerCase();

    switch (role) {
      case 'college':
        final collegeId = (data['collegeId'] as String? ?? '').trim();
        if (collegeId.isEmpty) return '';

        final collegeSnapshot = await _colleges.doc(collegeId).get();
        final collegeData = collegeSnapshot.data();
        return collegeData?['name'] as String? ??
            collegeData?['shortName'] as String? ??
            collegeId;
      case 'school':
        final schoolId = (data['schoolId'] as String? ?? '').trim();
        if (schoolId.isEmpty) return '';

        final schoolSnapshot = await _schools.doc(schoolId).get();
        final schoolData = schoolSnapshot.data();
        return schoolData?['name'] as String? ?? schoolId;
      case 'diet':
        final dietId = (data['dietId'] as String? ?? '').trim();
        if (dietId.isEmpty) return '';

        final dietSnapshot = await _diets.doc(dietId).get();
        final dietData = dietSnapshot.data();
        return dietData?['name'] as String? ??
            dietData?['shortName'] as String? ??
            dietId;
      case 'deo':
        return data['deoName'] as String? ??
            data['officerName'] as String? ??
            '';
      default:
        return '';
    }
  }

  DateTime _dateTimeFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class PendingRegistration {
  final String uid;
  final String registrationNumber;
  final String role;
  final String status;
  final String districtId;
  final String officerName;
  final String entityName;
  final String mobile;
  final String email;
  final DateTime createdAt;
  final DateTime actionedAt;

  const PendingRegistration({
    required this.uid,
    required this.registrationNumber,
    required this.role,
    required this.status,
    required this.districtId,
    required this.officerName,
    required this.entityName,
    required this.mobile,
    required this.email,
    required this.createdAt,
    required this.actionedAt,
  });

  factory PendingRegistration.fromMap(Map<String, dynamic> map) {
    final role = map['role'] as String? ?? '';

    return PendingRegistration(
      uid: map['uid'] as String? ?? '',
      registrationNumber: map['registrationNumber'] as String? ?? '',
      role: role,
      status: map['status'] as String? ?? '',
      districtId: map['districtId'] as String? ?? '',
      officerName:
          map['officerName'] as String? ?? map['name'] as String? ?? '',
      entityName: _entityNameFromMap(map, role),
      mobile: map['mobile'] as String? ?? map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      createdAt: _dateTimeFromValue(map['createdAt']),
      actionedAt: _dateTimeFromValue(map['actionedAt'] ?? map['updatedAt']),
    );
  }

  static DateTime _dateTimeFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String _entityNameFromMap(Map<String, dynamic> map, String role) {
    final entityName = map['entityName'] as String?;
    if (entityName != null && entityName.trim().isNotEmpty) {
      return entityName.trim();
    }

    switch (role.toLowerCase()) {
      case 'college':
        return map['collegeName'] as String? ??
            map['collegeId'] as String? ??
            map['officerName'] as String? ??
            '';
      case 'school':
        return map['schoolName'] as String? ??
            map['schoolId'] as String? ??
            map['officerName'] as String? ??
            '';
      case 'diet':
        return map['dietName'] as String? ??
            map['dietId'] as String? ??
            map['officerName'] as String? ??
            '';
      case 'deo':
        return map['deoName'] as String? ?? map['officerName'] as String? ?? '';
      default:
        return map['officerName'] as String? ?? map['name'] as String? ?? '';
    }
  }
}

class AssignedStudentRecord {
  final String allocationId;
  final StudentModel student;
  final String schoolId;
  final DateTime assignedAt;

  const AssignedStudentRecord({
    required this.allocationId,
    required this.student,
    required this.schoolId,
    required this.assignedAt,
  });

  int dayNumberFor(DateTime date) {
    final selectedDate = DateTime(date.year, date.month, date.day);
    final startDate = DateTime(
      assignedAt.year,
      assignedAt.month,
      assignedAt.day,
    );
    final dayNumber = selectedDate.difference(startDate).inDays + 1;

    if (dayNumber < 1) return 1;
    if (dayNumber > 28) return 28;
    return dayNumber;
  }
}

class AttendanceCalculation {
  final int totalDays;
  final int markedDays;
  final int presentDays;
  final double attendancePercentage;
  final bool isEligible;

  const AttendanceCalculation({
    required this.totalDays,
    required this.markedDays,
    required this.presentDays,
    required this.attendancePercentage,
    required this.isEligible,
  });

  int get absentDays => totalDays - presentDays;

  int get unmarkedDays => totalDays - markedDays;
}
