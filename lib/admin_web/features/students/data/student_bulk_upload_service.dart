import 'package:cloud_firestore/cloud_firestore.dart';

typedef StudentUploadProgress = void Function(int, int);

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
    List<Map<String, dynamic>> students, {
    StudentUploadProgress? onProgress,
  }) async {
    const batchLimit = 500;

    var uploadedCount = 0;
    var skippedDuplicateCount = 0;
    var skippedInvalidCount = 0;
    var pendingWrites = 0;
    var processedCount = 0;

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
        processedCount++;
        onProgress?.call(processedCount, students.length);
        continue;
      }

      if (seenRegistrationIds.contains(registrationId)) {
        skippedDuplicateCount++;
        processedCount++;
        onProgress?.call(processedCount, students.length);
        continue;
      }

      seenRegistrationIds.add(registrationId);

      final studentRef = studentsCollection.doc(registrationId);
      final existingStudent = await studentRef.get();

      if (existingStudent.exists) {
        skippedDuplicateCount++;
        processedCount++;
        onProgress?.call(processedCount, students.length);
        continue;
      }

      batch.set(studentRef, {
        ...student,
        'studentId': student['studentId'] ?? registrationId,
        'registrationId': registrationId,
        'status': student['status'] ?? 'created',
        'createdAt': FieldValue.serverTimestamp(),
      });

      uploadedCount++;
      pendingWrites++;
      processedCount++;
      onProgress?.call(processedCount, students.length);

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
