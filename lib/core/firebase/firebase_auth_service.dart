import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    String? schoolId,
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
    final registrationNumber = _generateRegistrationNumber(
      uid: firebaseUser.uid,
      role: normalizedRole,
    );
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
      if (schoolId != null && schoolId.trim().isNotEmpty)
        'schoolId': schoolId.trim(),
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

    if (appUser.status == 'rejected') {
      await _firebaseAuth.signOut();
      throw FirebaseAuthException(
        code: 'registration-rejected',
        message: 'Your registration request has been rejected.',
      );
    }

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

    final data = snapshot.data()!;
    // Validate the stored values before UserModel trims collegeId. Rules compare
    // these fields exactly; client-side normalization cannot repair a profile.
    final storedRole = data['role'];
    if (storedRole is String && storedRole.trim().toLowerCase() == 'college') {
      final collegeId = data['collegeId'];
      final status = data['status'];
      if (storedRole != 'college' ||
          status is! String ||
          !['pending', 'approved', 'rejected'].contains(status) ||
          collegeId is! String ||
          collegeId.isEmpty ||
          collegeId != collegeId.trim() ||
          collegeId.contains('/')) {
        await _firebaseAuth.signOut();
        throw FirebaseAuthException(
          code: 'invalid-college-profile',
          message: 'Your college profile needs administrator correction: '
              'role must be college, status must be pending, approved or '
              'rejected, and collegeId must be the canonical college document '
              'ID without surrounding spaces. Only approved accounts can log in.',
        );
      }
    }
    // The authenticated document ID is authoritative, including legacy profiles
    // without a redundant uid field.
    final appUser = UserModel.fromMap({...data, 'uid': uid});

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

  String _generateRegistrationNumber({
    required String uid,
    required String role,
  }) {
    final roleCode = switch (role.trim().toLowerCase()) {
      'college' => 'COL',
      'school' => 'SCH',
      'deo' => 'DEO',
      'diet' => 'DIET',
      _ => 'GEN',
    };
    final digits = uid.replaceAll(RegExp(r'[^0-9]'), '');
    final numericValue = digits.isEmpty ? uid.hashCode.abs() : int.parse(digits);
    final suffix = (numericValue % 10000).toString().padLeft(4, '0');
    return 'TP25$roleCode$suffix';
  }
}
