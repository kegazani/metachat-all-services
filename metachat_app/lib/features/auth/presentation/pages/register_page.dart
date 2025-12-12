import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

import 'package:metachat_app/core/network/api_client.dart';
import 'package:metachat_app/shared/widgets/glass_button.dart';
import 'package:metachat_app/shared/widgets/glass_card.dart';
import 'package:metachat_app/shared/widgets/glass_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool loading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  void dispose() {
    emailController.dispose();
    usernameController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (loading || !mounted) return;
    
    final email = emailController.text.trim();
    final username = usernameController.text.trim();
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    
    if (email.isEmpty || username.isEmpty || firstName.isEmpty || lastName.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заполните все поля'),
          ),
        );
      }
      return;
    }
    
    if (password != confirmPassword) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Пароли не совпадают'),
          ),
        );
      }
      return;
    }
    
    setState(() {
      loading = true;
    });
    
    try {
      final api = GetIt.instance<ApiClient>();
      final response = await api.post(
        '/auth/register',
        body: {
          'username': username,
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'password': password,
        },
      );
      
      if (response.data is Map) {
        final data = response.data as Map;
        final id = data['id']?.toString();
        if (id != null && id.isNotEmpty) {
          try {
            final box = Hive.box('app');
            await box.put('userId', id);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ошибка сохранения данных'),
                ),
              );
            }
            return;
          }
        }
      }
      
      if (!mounted) return;
      context.go('/app');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось создать пользователя'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Регистрация в Metachat',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Создайте профиль, чтобы начать вести дневник и отслеживать настроение',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  GlassTextField(
                    controller: emailController,
                    hint: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: usernameController,
                    hint: 'Имя пользователя',
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: firstNameController,
                    hint: 'Имя',
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: lastNameController,
                    hint: 'Фамилия',
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: passwordController,
                    hint: 'Пароль',
                    obscure: obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: confirmPasswordController,
                    hint: 'Подтвердите пароль',
                    obscure: obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  GlassButton(
                    label: loading ? 'Создание...' : 'Создать профиль',
                    onPressed: loading ? () {} : register,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      context.go('/auth/login');
                    },
                    child: Text(
                      'Уже есть аккаунт? Войти',
                      style: TextStyle(
                        color: Colors.blue[300],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}