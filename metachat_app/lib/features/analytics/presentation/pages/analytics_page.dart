import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

import 'package:metachat_app/core/network/api_client.dart';
import 'package:metachat_app/shared/widgets/glass_app_bar.dart';
import 'package:metachat_app/shared/widgets/glass_card.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  List<Map<String, dynamic>> points = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final box = Hive.box('app');
    final userId = box.get('userId')?.toString();
    if (userId == null) {
      setState(() {
        loading = false;
      });
      return;
    }
    try {
      final api = GetIt.instance<ApiClient>();
      final response = await api.get(
        '/analytics/users/$userId/mood/daily',
        query: {
          'start_date': DateTime.now()
              .subtract(const Duration(days: 7))
              .toIso8601String(),
          'end_date': DateTime.now().toIso8601String(),
        },
      );
      final list = List<Map<String, dynamic>>.from(
        (response.data as List).map((e) => Map<String, dynamic>.from(e)),
      );
      setState(() {
        points = list;
        loading = false;
      });
    } catch (_) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(
        title: 'Аналитика',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : GlassCard(
                padding: const EdgeInsets.all(16),
                child: points.isEmpty
                    ? Center(
                        child: Text(
                          'Недостаточно данных для аналитики',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
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
                          lineBarsData: [
                            LineChartBarData(
                              isCurved: true,
                              color: const Color(0xFF7DD3FC),
                              barWidth: 3,
                              spots: [
                                for (var i = 0; i < points.length; i++)
                                  FlSpot(
                                    i.toDouble(),
                                    (points[i]['average_valence'] as num?)
                                            ?.toDouble() ??
                                        0,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
      ),
    );
  }
}


