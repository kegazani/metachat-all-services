import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

import 'package:metachat_app/core/network/api_client.dart';
import 'package:metachat_app/shared/widgets/glass_app_bar.dart';
import 'package:metachat_app/shared/widgets/glass_button.dart';
import 'package:metachat_app/shared/widgets/glass_card.dart';
import 'package:metachat_app/shared/widgets/glass_text_field.dart';

class MoodPage extends StatefulWidget {
  const MoodPage({super.key});

  @override
  State<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends State<MoodPage> {
  final textController = TextEditingController();
  Map<String, dynamic>? result;
  bool loading = false;

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  Future<void> analyze() async {
    if (loading || !mounted) return;
    
    final text = textController.text.trim();
    if (text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Введите текст для анализа'),
          ),
        );
      }
      return;
    }
    
    setState(() {
      loading = true;
    });
    
    try {
      final box = Hive.box('app');
      final userId = box.get('userId')?.toString();
      if (userId == null || userId.isEmpty) {
        if (mounted) {
          setState(() {
            loading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ошибка: пользователь не найден'),
            ),
          );
        }
        return;
      }
      
      final api = GetIt.instance<ApiClient>();
      final response = await api.post(
        '/mood/analyze',
        body: {
          'text': text,
          'user_id': userId,
          'tokens_count': text.length,
        },
      );
      
      if (response.data is Map) {
        if (mounted) {
          setState(() {
            result = Map<String, dynamic>.from(response.data as Map);
            loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось проанализировать текст'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final emotions = (result?['emotion_vector'] as List?)?.cast<num>() ?? [];
    final dominant = result?['dominant_emotion']?.toString() ?? '';
    final valence = (result?['valence'] as num?)?.toDouble();
    final arousal = (result?['arousal'] as num?)?.toDouble();

    return Scaffold(
      appBar: const GlassAppBar(
        title: 'Настроение',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GlassTextField(
                    controller: textController,
                    hint: 'Опишите свое состояние',
                  ),
                  const SizedBox(height: 12),
                  GlassButton(
                    label: loading ? 'Анализ...' : 'Проанализировать',
                    onPressed: loading ? () {} : analyze,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (result != null)
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Результат',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      if (dominant.isNotEmpty)
                        Text(
                          'Доминирующая эмоция: $dominant',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                      if (valence != null && arousal != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Valence: ${valence.toStringAsFixed(2)}, Arousal: ${arousal.toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (emotions.isNotEmpty)
                        Expanded(
                          child: BarChart(
                            BarChartData(
                              borderData: FlBorderData(show: false),
                              gridData: const FlGridData(show: false),
                              titlesData: const FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              barGroups: [
                                for (var i = 0; i < emotions.length; i++)
                                  BarChartGroupData(
                                    x: i,
                                    barRods: [
                                      BarChartRodData(
                                        toY: emotions[i].toDouble(),
                                        color: const Color(0xFF7DD3FC),
                                        width: 8,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


