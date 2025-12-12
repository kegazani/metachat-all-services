import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:metachat_app/shared/widgets/glass_button.dart';
import 'package:metachat_app/shared/widgets/glass_card.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Логотип приложения
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFF7DD3FC),
                        Color(0xFF0A0A0F),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7DD3FC).withOpacity(0.6),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Metachat',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Заголовок и описание
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        'Добро пожаловать',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Ваш личный дневник настроения и эмоций. Отслеживайте свои чувства, находите поддержку и общайтесь с единомышленниками.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.white70, height: 1.5),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Кнопки входа и регистрации
                GlassButton(
                  label: 'Войти',
                  onPressed: () {
                    context.go('/auth/login');
                  },
                ),
                
                const SizedBox(height: 16),
                
                GlassButton(
                  label: 'Создать аккаунт',
                  onPressed: () {
                    context.go('/auth/register');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}