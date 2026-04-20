import 'package:cloud_firestore/cloud_firestore.dart';

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

  Stream<List<PendingRegistration>> streamPendingRegistrations() {
    return _users.where('status', isEqualTo: 'pending').snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => PendingRegistration.fromMap({
                  ...doc.data(),
                  'uid': doc.id,
                }),
              )
              .toList(),
        );
  }

  Future<void> approveRegistration(String uid) async {
    await _users.doc(uid).update({
      'status': 'approved',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectRegistration(String uid) async {
    await _users.doc(uid).delete();
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
        .where('districtId', isEqualTo: districtId)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();

    return snapshot.docs
        .map((doc) => SchoolModel.fromMap({...doc.data(), 'schoolId': doc.id}))
        .toList();
  }

  Stream<List<SchoolModel>> streamSchoolsByDistrict(String districtId) {
    return _schools
        .where('districtId', isEqualTo: districtId)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => SchoolModel.fromMap({
                  ...doc.data(),
                  'schoolId': doc.id,
                }),
              )
              .toList(),
        );
  }

  Stream<List<SchoolModel>> streamSchools({String? districtId}) {
    Query<Map<String, dynamic>> query =
        _schools.where('isActive', isEqualTo: true);

    final filter = districtId?.trim();
    if (filter != null && filter.isNotEmpty) {
      query = query.where('districtId', isEqualTo: filter);
    }

    return query.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => SchoolModel.fromMap({
                  ...doc.data(),
                  'schoolId': doc.id,
                }),
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
                (doc) => StudentModel.fromMap({
                  ...doc.data(),
                  'studentId': doc.id,
                }),
              )
              .toList(),
        );
  }

  Stream<List<StudentModel>> streamStudents() {
    return _students.snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => StudentModel.fromMap({
                  ...doc.data(),
                  'studentId': doc.id,
                }),
              )
              .toList(),
        );
  }

  Stream<List<AttendanceModel>> streamAttendanceByStudent(String studentId) {
    return _attendance.where('studentId', isEqualTo: studentId).snapshots().map(
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
                (doc) => ProposalModel.fromMap({
                  ...doc.data(),
                  'proposalId': doc.id,
                }),
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
        'updatedAt': Timestamp.now(),
      });
    });

    return proposalRef.id;
  }

  Future<void> approveProposal({
    required String proposalId,
    required String studentId,
    required String reviewedBy,
  }) async {
    final proposalRef = _proposals.doc(proposalId);
    final studentRef = _students.doc(studentId);

    await _firestore.runTransaction((transaction) async {
      transaction.update(proposalRef, {
        'status': 'approved',
        'reviewedBy': reviewedBy,
        'reviewedAt': Timestamp.now(),
        'rejectionReason': null,
        'updatedAt': Timestamp.now(),
      });

      transaction.update(studentRef, {
        'status': 'deoApproved',
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
    Query<Map<String, dynamic>> query =
        _attendance.where('studentId', isEqualTo: studentId);

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
  final String districtId;
  final String officerName;
  final String mobile;
  final String email;
  final DateTime createdAt;

  const PendingRegistration({
    required this.uid,
    required this.registrationNumber,
    required this.role,
    required this.districtId,
    required this.officerName,
    required this.mobile,
    required this.email,
    required this.createdAt,
  });

  factory PendingRegistration.fromMap(Map<String, dynamic> map) {
    return PendingRegistration(
      uid: map['uid'] as String? ?? '',
      registrationNumber: map['registrationNumber'] as String? ?? '',
      role: map['role'] as String? ?? '',
      districtId: map['districtId'] as String? ?? '',
      officerName: map['officerName'] as String? ?? map['name'] as String? ?? '',
      mobile: map['mobile'] as String? ?? map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      createdAt: _dateTimeFromValue(map['createdAt']),
    );
  }

  static DateTime _dateTimeFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
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
