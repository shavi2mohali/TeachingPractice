import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../features/auth/data/models/user_model.dart';

class FirebaseAuthService {
  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  Future<UserModel> registerUser({
    required String role,
    required String district,
    required String officerName,
    required String mobile,
    required String email,
    required String password,
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
    final userData = {
      'uid': firebaseUser.uid,
      'role': normalizedRole,
      'district': district.trim(),
      'districtId': district.trim(),
      'officerName': officerName.trim(),
      'name': officerName.trim(),
      'mobile': mobile.trim(),
      'phone': mobile.trim(),
      'email': email.trim(),
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(firebaseUser.uid).set(userData);

    return fetchCurrentUserProfile(firebaseUser.uid);
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

    return fetchCurrentUserProfile(firebaseUser.uid);
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
}
