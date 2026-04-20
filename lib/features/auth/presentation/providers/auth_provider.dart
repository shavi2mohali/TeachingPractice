import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/firebase/firebase_auth_service.dart';
import '../../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({FirebaseAuthService? authService})
      : _authService = authService ?? FirebaseAuthService();

  final FirebaseAuthService _authService;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<RegistrationResult> register({
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
    _setLoading(true);
    _errorMessage = null;

    try {
      final result = await _authService.registerUser(
        role: role,
        district: district,
        officerName: officerName,
        mobile: mobile,
        email: email,
        password: password,
        collegeId: collegeId,
        schoolId: schoolId,
        dietId: dietId,
      );
      _currentUser = null;
      return result;
    } catch (error) {
      _errorMessage = _messageFromError(error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final user = await _authService.loginAndFetchUserRole(
        email: email,
        password: password,
      );
      _currentUser = user;
      return user;
    } catch (error) {
      _errorMessage = _messageFromError(error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _messageFromError(Object error) {
    if (error is FirebaseAuthException && error.message != null) {
      return error.message!;
    }

    return error.toString();
  }
}
