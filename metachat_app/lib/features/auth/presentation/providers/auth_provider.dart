import 'package:flutter/foundation.dart';

import '../../domain/models/auth_result.dart';
import '../../domain/services/auth_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService authService;

  AuthProvider(this.authService);

  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  String? _userId;
  String? _token;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get userId => _userId;
  String? get token => _token;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  Future<void> initialize() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      final isAuth = await authService.isAuthenticated();
      if (isAuth) {
        _userId = await authService.getCurrentUserId();
        _token = await authService.getCurrentToken();
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Ошибка инициализации: ${e.toString()}';
    } finally {
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final result = await authService.login(email, password);
      
      _userId = result.userId;
      _token = result.token;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final result = await authService.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      
      _userId = result.userId;
      _token = result.token;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await authService.logout();
      _status = AuthStatus.unauthenticated;
      _userId = null;
      _token = null;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Ошибка выхода: ${e.toString()}';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}

