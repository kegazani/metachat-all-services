import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:metachat_app/core/network/api_client.dart';
import 'package:metachat_app/features/auth/data/datasources/local/auth_local_data_source.dart';
import 'package:metachat_app/features/auth/data/datasources/remote/auth_remote_data_source.dart';
import 'package:metachat_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:metachat_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:metachat_app/features/auth/domain/services/auth_service.dart';
import 'package:metachat_app/features/auth/presentation/providers/auth_provider.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  try {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen('app')) {
      await Hive.openBox('app');
    }
  } catch (e) {
    throw Exception('Failed to initialize Hive: $e');
  }

  final baseUrl = dotenv.get('API_BASE_URL', fallback: 'http://localhost:8080');

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    error: true,
  ));

  getIt.registerLazySingleton<Dio>(() => dio);
  getIt.registerLazySingleton<ApiClient>(() => ApiClient(getIt<Dio>()));

  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(),
  );

  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
      localDataSource: getIt<AuthLocalDataSource>(),
    ),
  );

  getIt.registerLazySingleton<AuthService>(
    () => AuthService(getIt<AuthRepository>()),
  );

  getIt.registerFactory<AuthProvider>(
    () => AuthProvider(getIt<AuthService>()),
  );
}

