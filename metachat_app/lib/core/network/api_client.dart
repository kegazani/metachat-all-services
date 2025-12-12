import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;

  ApiClient(this.dio);

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    try {
      return await dio.get(path, queryParameters: query);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Превышено время ожидания. Проверьте подключение к интернету');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Ошибка подключения. Проверьте подключение к интернету');
      } else if (e.response != null) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          throw Exception('Неверные учетные данные');
        } else if (statusCode == 404) {
          throw Exception('Ресурс не найден');
        } else if (statusCode != null && statusCode >= 500) {
          throw Exception('Ошибка сервера. Попробуйте позже');
        }
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response<dynamic>> post(String path, {Object? body}) async {
    try {
      return await dio.post(path, data: body);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Превышено время ожидания. Проверьте подключение к интернету');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Ошибка подключения. Проверьте подключение к интернету');
      } else if (e.response != null) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          throw Exception('Неверные учетные данные');
        } else if (statusCode == 400) {
          throw Exception('Неверные данные запроса');
        } else if (statusCode == 404) {
          throw Exception('Ресурс не найден');
        } else if (statusCode != null && statusCode >= 500) {
          throw Exception('Ошибка сервера. Попробуйте позже');
        }
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}


