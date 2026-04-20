import 'package:flutter/foundation.dart';

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
      _errorMessage = error.toString();
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
}
