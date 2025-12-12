import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

import 'package:metachat_app/core/network/api_client.dart';
import 'package:metachat_app/shared/widgets/glass_app_bar.dart';
import 'package:metachat_app/shared/widgets/glass_card.dart';
import 'package:metachat_app/features/biometric/presentation/pages/day_insights_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? user;
  Map<String, dynamic>? biometricProfile;
  bool loading = true;
  bool biometricLoading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final box = Hive.box('app');
    final id = box.get('userId')?.toString();
    if (id == null) {
      setState(() {
        loading = false;
        biometricLoading = false;
      });
      return;
    }
    try {
      final api = GetIt.instance<ApiClient>();
      final response = await api.get('/users/$id');
      setState(() {
        user = Map<String, dynamic>.from(response.data as Map);
        loading = false;
      });
      
      _loadBiometricProfile(id);
    } catch (_) {
      setState(() {
        loading = false;
        biometricLoading = false;
      });
    }
  }

  Future<void> _loadBiometricProfile(String userId) async {
    try {
      final api = GetIt.instance<ApiClient>();
      final response = await api.get('/biometric/profile/$userId');
      setState(() {
        biometricProfile = Map<String, dynamic>.from(response.data as Map);
        biometricLoading = false;
      });
    } catch (_) {
      setState(() {
        biometricLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = user?['full_name']?.toString() ?? 'Пользователь Metachat';
    final email = user?['email']?.toString() ?? '';

    return Scaffold(
      appBar: const GlassAppBar(
        title: 'Профиль',
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildUserCard(name, email),
                  const SizedBox(height: 16),
                  _buildHealthScoreCard(),
                  const SizedBox(height: 16),
                  _buildBiometricCards(),
                  const SizedBox(height: 16),
                  _buildWatchConnectionCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildUserCard(String name, String email) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Color(0xFF7DD3FC),
                  Color(0xFFC4B5FD),
                  Color(0xFF7DD3FC),
                ],
              ),
            ),
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.8),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard() {
    final healthScore = biometricProfile?['health_score'] as int?;
    final isConnected = biometricProfile?['last_sync'] != null;
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      onTap: isConnected ? () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DayInsightsPage()),
        );
      } : null,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Индекс здоровья',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isConnected 
                      ? const Color(0xFF22C55E).withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isConnected ? Icons.watch : Icons.watch_off,
                      size: 14,
                      color: isConnected ? const Color(0xFF22C55E) : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isConnected ? 'Подключено' : 'Не подключено',
                      style: TextStyle(
                        fontSize: 12,
                        color: isConnected ? const Color(0xFF22C55E) : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (biometricLoading)
            const CircularProgressIndicator()
          else if (healthScore != null)
            Column(
              children: [
                _buildHealthScoreIndicator(healthScore),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.psychology, size: 16, color: Colors.white54),
                    const SizedBox(width: 8),
                    Text(
                      'Нажмите для анализа эмоций',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 16, color: Colors.white54),
                  ],
                ),
              ],
            )
          else
            Text(
              'Подключите умные часы для отслеживания здоровья',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white54,
                  ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildHealthScoreIndicator(int score) {
    final color = _getScoreColor(score);
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 10,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$score',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
                Text(
                  _getScoreLabel(score),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBiometricCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.favorite,
                iconColor: const Color(0xFFEF4444),
                label: 'Пульс',
                value: biometricProfile?['current_heart_rate'] != null
                    ? '${(biometricProfile!['current_heart_rate'] as num).toInt()}'
                    : '--',
                unit: 'уд/мин',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.directions_walk,
                iconColor: const Color(0xFF3B82F6),
                label: 'Шаги',
                value: biometricProfile?['today_steps']?.toString() ?? '--',
                unit: 'сегодня',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.local_fire_department,
                iconColor: const Color(0xFFF97316),
                label: 'Калории',
                value: biometricProfile?['today_calories'] != null
                    ? '${(biometricProfile!['today_calories'] as num).toInt()}'
                    : '--',
                unit: 'ккал',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.bedtime,
                iconColor: const Color(0xFF8B5CF6),
                label: 'Сон',
                value: biometricProfile?['last_sleep_duration_hours'] != null
                    ? '${(biometricProfile!['last_sleep_duration_hours'] as num).toStringAsFixed(1)}'
                    : '--',
                unit: 'часов',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.psychology,
                iconColor: const Color(0xFFEC4899),
                label: 'Стресс',
                value: biometricProfile?['avg_stress_level'] != null
                    ? '${(biometricProfile!['avg_stress_level'] as num).toInt()}'
                    : '--',
                unit: '%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.air,
                iconColor: const Color(0xFF06B6D4),
                label: 'SpO₂',
                value: biometricProfile?['avg_blood_oxygen'] != null
                    ? '${(biometricProfile!['avg_blood_oxygen'] as num).toInt()}'
                    : '--',
                unit: '%',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWatchConnectionCard() {
    final deviceType = biometricProfile?['device_type'] as String?;
    final lastSync = biometricProfile?['last_sync'] as String?;
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.watch, color: Color(0xFF7DD3FC)),
              const SizedBox(width: 12),
              Text(
                'Подключение часов',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (deviceType != null) ...[
            _buildInfoRow('Устройство', _formatDeviceType(deviceType)),
            const SizedBox(height: 8),
          ],
          if (lastSync != null)
            _buildInfoRow('Последняя синхронизация', _formatLastSync(lastSync)),
          if (deviceType == null && lastSync == null)
            Column(
              children: [
                Text(
                  'Для отслеживания показателей здоровья подключите умные часы',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white54,
                      ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Подключить часы'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7DD3FC).withOpacity(0.2),
                    foregroundColor: const Color(0xFF7DD3FC),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white54,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF22C55E);
    if (score >= 60) return const Color(0xFFF59E0B);
    if (score >= 40) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return 'Отлично';
    if (score >= 60) return 'Хорошо';
    if (score >= 40) return 'Нормально';
    return 'Требует внимания';
  }

  String _formatDeviceType(String type) {
    switch (type) {
      case 'apple_watch':
        return 'Apple Watch';
      case 'wear_os':
        return 'Wear OS';
      case 'garmin':
        return 'Garmin';
      case 'fitbit':
        return 'Fitbit';
      case 'samsung':
        return 'Samsung Galaxy Watch';
      case 'xiaomi':
        return 'Xiaomi Mi Band';
      case 'huawei':
        return 'Huawei Watch';
      default:
        return type;
    }
  }

  String _formatLastSync(String lastSync) {
    try {
      final dt = DateTime.parse(lastSync);
      final now = DateTime.now();
      final diff = now.difference(dt);
      
      if (diff.inMinutes < 1) return 'Только что';
      if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
      if (diff.inHours < 24) return '${diff.inHours} ч назад';
      return '${diff.inDays} д назад';
    } catch (_) {
      return lastSync;
    }
  }
}

