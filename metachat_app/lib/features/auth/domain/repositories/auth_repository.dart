import '../models/auth_result.dart';

abstract class AuthRepository {
  Future<AuthResult> login(String email, String password);
  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  });
  Future<void> logout();
  Future<String?> getStoredToken();
  Future<String?> getStoredUserId();
  Future<void> storeAuthData(String userId, String token);
  Future<void> clearAuthData();
}

