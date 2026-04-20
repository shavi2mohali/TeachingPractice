import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../constants/registration_constants.dart';
import '../../features/auth/data/models/user_model.dart';

class RegistrationResult {
  final String registrationNumber;

  const RegistrationResult({
    required this.registrationNumber,
  });
}

class FirebaseAuthService {
  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  static const String _adminEmail = 'admin@test.com';

  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  Future<RegistrationResult> registerUser({
    required String role,
    required String district,
    required String officerName,
    required String mobile,
    required String email,
    required String password,
    String? collegeId,
    String? dietId,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'missing-user',
        message: 'Registration completed but no Firebase user was returned.',
      );
    }

    final normalizedRole = role.trim().toLowerCase();
    final registrationNumber = _generateRegistrationNumber(firebaseUser.uid);
    final userData = {
      'uid': firebaseUser.uid,
      'status': 'pending',
      'registrationNumber': registrationNumber,
      'role': normalizedRole,
      'districtId': district.trim(),
      'officerName': officerName.trim(),
      'mobile': mobile.trim(),
      'email': email.trim(),
      if (collegeId != null && collegeId.trim().isNotEmpty)
        'collegeId': collegeId.trim(),
      if (dietId != null && dietId.trim().isNotEmpty) 'dietId': dietId.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(firebaseUser.uid).set(userData);
    await _firebaseAuth.signOut();

    return RegistrationResult(registrationNumber: registrationNumber);
  }

  Future<UserModel> loginAndFetchUserRole({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'missing-user',
        message: 'Login completed but no Firebase user was returned.',
      );
    }

    await _ensureAdminProfileIfNeeded(firebaseUser);

    final appUser = await fetchCurrentUserProfile(firebaseUser.uid);

    if (appUser.status != 'approved') {
      await _firebaseAuth.signOut();
      throw FirebaseAuthException(
        code: 'approval-pending',
        message: RegistrationConstants.loginPendingMessage,
      );
    }

    return appUser;
  }

  Future<UserModel> fetchCurrentUserProfile(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();

    if (!snapshot.exists || snapshot.data() == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'user-profile-not-found',
        message: 'No Firestore user profile found for this account.',
      );
    }

    final appUser = UserModel.fromMap({...snapshot.data()!, 'uid': uid});

    if (appUser.role.trim().isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'user-role-missing',
        message: 'This user does not have an assigned role.',
      );
    }

    return appUser;
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  Future<void> _ensureAdminProfileIfNeeded(User firebaseUser) async {
    if ((firebaseUser.email ?? '').trim().toLowerCase() != _adminEmail) {
      return;
    }

    final userRef = _firestore.collection('users').doc(firebaseUser.uid);
    final snapshot = await userRef.get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      await userRef.set({
        'uid': firebaseUser.uid,
        'status': 'approved',
        'role': 'admin',
        'districtId': '',
        'officerName': 'Admin',
        'mobile': '',
        'email': _adminEmail,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    if (data['status'] != 'approved' || data['role'] != 'admin') {
      await userRef.update({
        'status': 'approved',
        'role': 'admin',
      });
    }
  }

  String _generateRegistrationNumber(String uid) {
    final suffix = uid.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    return 'TP2025-$suffix';
  }
}
