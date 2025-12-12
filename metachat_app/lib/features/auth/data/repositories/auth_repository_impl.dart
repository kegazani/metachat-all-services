import '../../domain/models/auth_result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/auth_local_data_source.dart';
import '../datasources/remote/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<AuthResult> login(String email, String password) async {
    return await remoteDataSource.login(email, password);
  }

  @override
  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    return await remoteDataSource.register(
      username: username,
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );
  }

  @override
  Future<void> logout() async {
    await clearAuthData();
  }

  @override
  Future<String?> getStoredToken() async {
    return await localDataSource.getToken();
  }

  @override
  Future<String?> getStoredUserId() async {
    return await localDataSource.getUserId();
  }

  @override
  Future<void> storeAuthData(String userId, String token) async {
    await localDataSource.storeUserId(userId);
    await localDataSource.storeToken(token);
  }

  @override
  Future<void> clearAuthData() async {
    await localDataSource.clearAll();
  }
}

