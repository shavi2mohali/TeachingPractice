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
      final name = _toTitleCase(_stringValue(school['name']));
      final districtId = _toTitleCase(_stringValue(school['districtId']));

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

  String _toTitleCase(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return '';

    const lowerCaseWords = {
      'a',
      'an',
      'and',
      'as',
      'at',
      'by',
      'for',
      'from',
      'in',
      'of',
      'on',
      'or',
      'the',
      'to',
      'with',
    };

    final words = normalized.split(' ');

    return words.asMap().entries.map((entry) {
      final index = entry.key;
      final word = entry.value.toLowerCase();

      if (word.isEmpty) return '';

      final isFirst = index == 0;
      final isLast = index == words.length - 1;
      if (!isFirst && !isLast && lowerCaseWords.contains(word)) {
        return word;
      }

      return word
          .split('-')
          .map((segment) {
            if (segment.isEmpty) return '';
            return '${segment[0].toUpperCase()}${segment.substring(1)}';
          })
          .join('-');
    }).join(' ');
  }
}
