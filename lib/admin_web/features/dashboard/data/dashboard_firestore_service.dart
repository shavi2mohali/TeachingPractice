import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardFirestoreService {
  DashboardFirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<int> watchTotalStudents() => _watchCollectionCount('students');

  Stream<int> watchTotalSchools() => _watchCollectionCount('schools');

  Stream<int> watchTotalProposals() => _watchCollectionCount('proposals');

  Stream<int> watchTotalCertificates() => _watchCollectionCount('certificates');

  Stream<int> _watchCollectionCount(String collectionPath) {
    return _firestore
        .collection(collectionPath)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }
}
