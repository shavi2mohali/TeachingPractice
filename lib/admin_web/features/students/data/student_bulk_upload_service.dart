import 'package:cloud_firestore/cloud_firestore.dart';

class StudentBulkUploadResult {
  final int uploadedCount;
  final int skippedDuplicateCount;
  final int skippedInvalidCount;

  const StudentBulkUploadResult({
    required this.uploadedCount,
    required this.skippedDuplicateCount,
    required this.skippedInvalidCount,
  });
}

class StudentBulkUploadService {
  StudentBulkUploadService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<StudentBulkUploadResult> uploadStudentsBatch(
    List<Map<String, dynamic>> students,
  ) async {
    const batchLimit = 500;

    var uploadedCount = 0;
    var skippedDuplicateCount = 0;
    var skippedInvalidCount = 0;
    var pendingWrites = 0;

    var batch = _firestore.batch();
    final studentsCollection = _firestore.collection('students');
    final seenRegistrationIds = <String>{};

    Future<void> commitBatchIfNeeded({bool force = false}) async {
      if (pendingWrites == 0) return;

      if (force || pendingWrites >= batchLimit) {
        await batch.commit();
        batch = _firestore.batch();
        pendingWrites = 0;
      }
    }

    for (final student in students) {
      final registrationId = _readRegistrationId(student);

      if (registrationId == null || registrationId.isEmpty) {
        skippedInvalidCount++;
        continue;
      }

      if (seenRegistrationIds.contains(registrationId)) {
        skippedDuplicateCount++;
        continue;
      }

      seenRegistrationIds.add(registrationId);

      final documentId = Uri.encodeComponent(registrationId);
      final studentRef = studentsCollection.doc(documentId);
      final existingStudent = await studentsCollection
          .where('registrationId', isEqualTo: registrationId)
          .limit(1)
          .get();

      if (existingStudent.docs.isNotEmpty) {
        skippedDuplicateCount++;
        continue;
      }

      batch.set(studentRef, {
        ...student,
        'registrationId': registrationId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      uploadedCount++;
      pendingWrites++;

      await commitBatchIfNeeded();
    }

    await commitBatchIfNeeded(force: true);

    return StudentBulkUploadResult(
      uploadedCount: uploadedCount,
      skippedDuplicateCount: skippedDuplicateCount,
      skippedInvalidCount: skippedInvalidCount,
    );
  }

  String? _readRegistrationId(Map<String, dynamic> student) {
    final value = student['registrationId'] ??
        student['Registration Id'] ??
        student['REGISTRATION ID'];

    if (value == null) return null;

    final registrationId = value.toString().trim();
    return registrationId.isEmpty ? null : registrationId;
  }
}
