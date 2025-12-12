import '../models/auth_result.dart';
import '../repositories/auth_repository.dart';

class AuthService {
  final AuthRepository repository;

  AuthService(this.repository);

  Future<AuthResult> login(String email, String password) async {
    if (email.trim().isEmpty) {
      throw Exception('Email не может быть пустым');
    }
    if (password.isEmpty) {
      throw Exception('Пароль не может быть пустым');
    }

    try {
      final result = await repository.login(email.trim(), password);
      await repository.storeAuthData(result.userId, result.token);
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    if (username.trim().isEmpty) {
      throw Exception('Имя пользователя не может быть пустым');
    }
    if (email.trim().isEmpty) {
      throw Exception('Email не может быть пустым');
    }
    if (password.isEmpty) {
      throw Exception('Пароль не может быть пустым');
    }
    if (firstName.trim().isEmpty) {
      throw Exception('Имя не может быть пустым');
    }
    if (lastName.trim().isEmpty) {
      throw Exception('Фамилия не может быть пустым');
    }

    try {
      final result = await repository.register(
        username: username.trim(),
        email: email.trim(),
        password: password,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
      );
      await repository.storeAuthData(result.userId, result.token);
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await repository.logout();
    await repository.clearAuthData();
  }

  Future<bool> isAuthenticated() async {
    final token = await repository.getStoredToken();
    final userId = await repository.getStoredUserId();
    return token != null && token.isNotEmpty && userId != null && userId.isNotEmpty;
  }

  Future<String?> getCurrentUserId() {
    return repository.getStoredUserId();
  }

  Future<String?> getCurrentToken() {
    return repository.getStoredToken();
  }
}

