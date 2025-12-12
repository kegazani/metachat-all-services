import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:metachat_app/core/network/api_client.dart';
import 'package:metachat_app/shared/widgets/glass_app_bar.dart';
import 'package:metachat_app/shared/widgets/glass_card.dart';

class DayInsightsPage extends StatefulWidget {
  final String? date;
  
  const DayInsightsPage({super.key, this.date});

  @override
  State<DayInsightsPage> createState() => _DayInsightsPageState();
}

class _DayInsightsPageState extends State<DayInsightsPage> {
  Map<String, dynamic>? emotionalSummary;
  Map<String, dynamic>? dayInsights;
  Map<String, dynamic>? currentState;
  bool loading = true;
  String? error;
  late String selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.date ?? _formatDate(DateTime.now());
    _loadData();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadData() async {
    setState(() {
      loading = true;
      error = null;
    });

    final box = Hive.box('app');
    final userId = box.get('userId')?.toString();
    
    if (userId == null) {
      setState(() {
        loading = false;
        error = 'User not logged in';
      });
      return;
    }

    try {
      final api = GetIt.instance<ApiClient>();
      
      final currentResponse = await api.get('/biometric/emotional-state/$userId/current');
      currentState = Map<String, dynamic>.from(currentResponse.data as Map);
      
      final emotionalResponse = await api.get('/biometric/emotional-state/$userId/day/$selectedDate');
      emotionalSummary = Map<String, dynamic>.from(emotionalResponse.data as Map);
      
      final insightsResponse = await api.get('/biometric/insights/$userId/day/$selectedDate');
      dayInsights = Map<String, dynamic>.from(insightsResponse.data as Map);
      
      setState(() {
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(title: 'Эмоциональное состояние'),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!, style: const TextStyle(color: Colors.white54)))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCurrentStateCard(),
                        const SizedBox(height: 16),
                        _buildDailyStoryCard(),
                        const SizedBox(height: 16),
                        _buildEnergyCurveCard(),
                        const SizedBox(height: 16),
                        _buildEmotionalJourneyCard(),
                        const SizedBox(height: 16),
                        _buildInsightsCard(),
                        const SizedBox(height: 16),
                        _buildKeyMomentsCard(),
                        const SizedBox(height: 16),
                        _buildRecommendationsCard(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildCurrentStateCard() {
    final state = currentState?['state'] as String? ?? 'unknown';
    final confidence = (currentState?['confidence'] as num?)?.toDouble() ?? 0;
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStateColor(state).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getStateIcon(state),
                  color: _getStateColor(state),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Сейчас вы',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white54,
                          ),
                    ),
                    Text(
                      _translateState(state),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getStateColor(state),
                          ),
                    ),
                  ],
                ),
              ),
              CircularProgressIndicator(
                value: confidence,
                strokeWidth: 4,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(_getStateColor(state)),
              ),
            ],
          ),
          if (currentState?['metrics'] != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniMetric(
                  Icons.favorite,
                  '${currentState!['metrics']['heart_rate']?.toInt() ?? '--'}',
                  'уд/мин',
                ),
                _buildMiniMetric(
                  Icons.psychology,
                  '${currentState!['metrics']['stress_level'] ?? '--'}',
                  '% стресс',
                ),
                _buildMiniMetric(
                  Icons.air,
                  '${currentState!['metrics']['blood_oxygen']?.toInt() ?? '--'}',
                  '% SpO₂',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniMetric(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }

  Widget _buildDailyStoryCard() {
    final story = dayInsights?['daily_story'] as String?;
    if (story == null || story.isEmpty) return const SizedBox.shrink();
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories, color: Color(0xFF7DD3FC)),
              const SizedBox(width: 8),
              Text('История дня', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            story,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyCurveCard() {
    final energyCurve = emotionalSummary?['energy_curve'] as List?;
    if (energyCurve == null || energyCurve.isEmpty) return const SizedBox.shrink();
    
    final spots = <FlSpot>[];
    for (final point in energyCurve) {
      final hour = point['hour'] as int;
      final energy = point['energy_level'] as double?;
      if (energy != null) {
        spots.add(FlSpot(hour.toDouble(), energy * 100));
      }
    }
    
    if (spots.isEmpty) return const SizedBox.shrink();
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, color: Color(0xFFF97316)),
              const SizedBox(width: 8),
              Text('Кривая энергии', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 6,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}:00',
                          style: const TextStyle(color: Colors.white54, fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFFF97316),
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFF97316).withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionalJourneyCard() {
    final journey = dayInsights?['emotional_journey'] as List?;
    if (journey == null || journey.isEmpty) return const SizedBox.shrink();
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 8),
              Text('Эмоциональный путь', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: journey.length > 12 ? 12 : journey.length,
              itemBuilder: (context, index) {
                final point = journey[index] as Map<String, dynamic>;
                final state = point['emotional_state'] as String;
                final hour = point['hour'] as int;
                
                return Container(
                  width: 50,
                  margin: const EdgeInsets.only(right: 8),
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _getStateColor(state).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getStateIcon(state),
                          color: _getStateColor(state),
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$hour:00',
                        style: const TextStyle(fontSize: 10, color: Colors.white54),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard() {
    final insights = emotionalSummary?['insights'] as List?;
    if (insights == null || insights.isEmpty) return const SizedBox.shrink();
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Color(0xFFEAB308)),
              const SizedBox(width: 8),
              Text('Инсайты', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          ...insights.map((insight) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  ', style: TextStyle(color: Color(0xFFEAB308))),
                Expanded(
                  child: Text(
                    insight as String,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildKeyMomentsCard() {
    final moments = dayInsights?['key_moments'] as List?;
    if (moments == null || moments.isEmpty) return const SizedBox.shrink();
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFEC4899)),
              const SizedBox(width: 8),
              Text('Ключевые моменты', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          ...moments.map((moment) {
            final m = moment as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _getMomentIcon(m['type'] as String?),
                    color: const Color(0xFFEC4899),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      m['description'] as String? ?? '',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    final recommendations = emotionalSummary?['recommendations'] as List?;
    if (recommendations == null || recommendations.isEmpty) return const SizedBox.shrink();
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates, color: Color(0xFF22C55E)),
              const SizedBox(width: 8),
              Text('Рекомендации', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          ...recommendations.map((rec) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rec as String,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Color _getStateColor(String state) {
    switch (state) {
      case 'calm':
      case 'relaxed':
        return const Color(0xFF22C55E);
      case 'energized':
      case 'excited':
        return const Color(0xFFF97316);
      case 'focused':
        return const Color(0xFF3B82F6);
      case 'stressed':
      case 'anxious':
      case 'agitated':
        return const Color(0xFFEF4444);
      case 'tired':
        return const Color(0xFF8B5CF6);
      default:
        return Colors.grey;
    }
  }

  IconData _getStateIcon(String state) {
    switch (state) {
      case 'calm':
        return Icons.spa;
      case 'relaxed':
        return Icons.self_improvement;
      case 'energized':
        return Icons.bolt;
      case 'excited':
        return Icons.celebration;
      case 'focused':
        return Icons.center_focus_strong;
      case 'stressed':
        return Icons.warning;
      case 'anxious':
        return Icons.psychology_alt;
      case 'agitated':
        return Icons.sentiment_very_dissatisfied;
      case 'tired':
        return Icons.bedtime;
      default:
        return Icons.help_outline;
    }
  }

  String _translateState(String state) {
    switch (state) {
      case 'calm':
        return 'Спокойны';
      case 'relaxed':
        return 'Расслаблены';
      case 'energized':
        return 'Энергичны';
      case 'excited':
        return 'Возбуждены';
      case 'focused':
        return 'Сфокусированы';
      case 'stressed':
        return 'Напряжены';
      case 'anxious':
        return 'Тревожны';
      case 'agitated':
        return 'Раздражены';
      case 'tired':
        return 'Устали';
      default:
        return 'Неизвестно';
    }
  }

  IconData _getMomentIcon(String? type) {
    switch (type) {
      case 'peak_heart_rate':
        return Icons.favorite;
      case 'high_stress':
        return Icons.warning;
      case 'peak_activity':
        return Icons.directions_run;
      default:
        return Icons.stars;
    }
  }
}

