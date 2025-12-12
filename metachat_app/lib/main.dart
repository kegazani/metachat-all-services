import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/welcome_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/home/presentation/pages/home_shell_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");
    
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      if (kDebugMode) {
        print('Flutter Error: ${details.exception}');
        print('Stack trace: ${details.stack}');
      }
    };
    
    PlatformDispatcher.instance.onError = (error, stack) {
      if (kDebugMode) {
        print('Platform Error: $error');
        print('Stack trace: $stack');
      }
      return true;
    };
    
    try {
      await configureDependencies();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Ошибка инициализации: $e');
        print('Stack trace: $stackTrace');
      }
      runApp(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Ошибка инициализации: $e'),
            ),
          ),
        ),
      );
      return;
    }
    
    runApp(const MetachatApp());
  }, (error, stack) {
    if (kDebugMode) {
      print('Uncaught error: $error');
      print('Stack trace: $stack');
    }
  });
}

class MetachatApp extends StatelessWidget {
  const MetachatApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) => const WelcomePage(),
        ),
        GoRoute(
          path: '/auth/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/auth/register',
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: '/app',
          builder: (context, state) => const HomeShellPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => getIt<AuthProvider>()..initialize(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Metachat',
        theme: buildMetachatTheme(),
        debugShowCheckedModeBanner: false,
        routerConfig: router,
      ),
    );
  }
}



