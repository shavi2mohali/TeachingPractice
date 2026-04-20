import 'package:cloud_firestore/cloud_firestore.dart';

typedef SchoolUploadProgress = void Function(int, int);

class SchoolBulkUploadResult {
  final int uploadedCount;
  final int skippedInvalidCount;

  const SchoolBulkUploadResult({
    required this.uploadedCount,
    required this.skippedInvalidCount,
  });
}

class SchoolBulkUploadService {
  SchoolBulkUploadService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<SchoolBulkUploadResult> uploadSchoolsBatch(
    List<Map<String, dynamic>> schools, {
    SchoolUploadProgress? onProgress,
  }) async {
    const batchLimit = 500;

    var uploadedCount = 0;
    var skippedInvalidCount = 0;
    var pendingWrites = 0;
    var processedCount = 0;

    var batch = _firestore.batch();
    final schoolsCollection = _firestore.collection('schools');

    Future<void> commitBatchIfNeeded({bool force = false}) async {
      if (pendingWrites == 0) return;

      if (force || pendingWrites >= batchLimit) {
        await batch.commit();
        batch = _firestore.batch();
        pendingWrites = 0;
      }
    }

    for (final school in schools) {
      final udise = _stringValue(school['udise']);
      final name = _stringValue(school['name']);
      final districtId = _stringValue(school['districtId']).toUpperCase();

      if (name.isEmpty || districtId.isEmpty) {
        skippedInvalidCount++;
        processedCount++;
        onProgress?.call(processedCount, schools.length);
        continue;
      }

      final schoolRef =
          udise.isEmpty ? schoolsCollection.doc() : schoolsCollection.doc(udise);

      batch.set(
        schoolRef,
        {
          'schoolId': schoolRef.id,
          'udise': udise.isEmpty ? schoolRef.id : udise,
          'districtId': districtId,
          'name': name,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      uploadedCount++;
      pendingWrites++;
      processedCount++;
      onProgress?.call(processedCount, schools.length);

      await commitBatchIfNeeded();
    }

    await commitBatchIfNeeded(force: true);

    return SchoolBulkUploadResult(
      uploadedCount: uploadedCount,
      skippedInvalidCount: skippedInvalidCount,
    );
  }

  String _stringValue(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }
}
