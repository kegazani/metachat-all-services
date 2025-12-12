import 'package:dio/dio.dart';

import 'package:metachat_app/core/network/api_client.dart';
import 'package:metachat_app/features/auth/domain/models/auth_result.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResult> login(String email, String password);
  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl(this.apiClient);

  @override
  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await apiClient.post(
        '/auth/login',
        body: {
          'email': email,
          'password': password,
        },
      );

      if (response.data == null) {
        throw Exception('Пустой ответ от сервера');
      }

      final data = response.data as Map<String, dynamic>;
      return AuthResult.fromJson(data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Превышено время ожидания. Проверьте подключение к интернету');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Ошибка подключения. Проверьте подключение к интернету');
      } else if (e.response != null) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          throw Exception('Неверные email или пароль');
        } else if (statusCode == 400) {
          throw Exception('Неверные данные запроса');
        } else if (statusCode != null && statusCode >= 500) {
          throw Exception('Ошибка сервера. Попробуйте позже');
        }
      }
      throw Exception('Ошибка подключения к серверу');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Неожиданная ошибка: ${e.toString()}');
    }
  }

  @override
  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await apiClient.post(
        '/auth/register',
        body: {
          'username': username,
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
        },
      );

      if (response.data == null) {
        throw Exception('Пустой ответ от сервера');
      }

      final data = response.data as Map<String, dynamic>;
      return AuthResult.fromJson(data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Превышено время ожидания. Проверьте подключение к интернету');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Ошибка подключения. Проверьте подключение к интернету');
      } else if (e.response != null) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 400) {
          throw Exception('Неверные данные регистрации');
        } else if (statusCode == 409) {
          throw Exception('Пользователь с таким email уже существует');
        } else if (statusCode != null && statusCode >= 500) {
          throw Exception('Ошибка сервера. Попробуйте позже');
        }
      }
      throw Exception('Ошибка подключения к серверу');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Неожиданная ошибка: ${e.toString()}');
    }
  }
}

