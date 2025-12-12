import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

import 'package:metachat_app/core/network/api_client.dart';
import 'package:metachat_app/shared/widgets/glass_app_bar.dart';
import 'package:metachat_app/shared/widgets/glass_card.dart';

class MatchingPage extends StatefulWidget {
  const MatchingPage({super.key});

  @override
  State<MatchingPage> createState() => _MatchingPageState();
}

class _MatchingPageState extends State<MatchingPage> {
  List<Map<String, dynamic>> matches = [];
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
      final response = await api.get('/users/$userId/similar');
      final list = List<Map<String, dynamic>>.from(
        (response.data as List).map((e) => Map<String, dynamic>.from(e)),
      );
      setState(() {
        matches = list;
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
        title: 'Матчинг',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : PageView.builder(
                itemCount: matches.length,
                controller: PageController(viewportFraction: 0.82),
                itemBuilder: (context, index) {
                  final item = matches[index];
                  final name = item['full_name']?.toString() ??
                      item['username']?.toString() ??
                      'Пользователь';
                  final score = (item['similarity'] as num?)?.toDouble();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          if (score != null)
                            Column(
                              children: [
                                SizedBox(
                                  width: 120,
                                  height: 120,
                                  child: CircularProgressIndicator(
                                    value: score,
                                    strokeWidth: 10,
                                    color: const Color(0xFF7DD3FC),
                                    backgroundColor:
                                        Colors.white.withOpacity(0.08),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Совместимость ${(score * 100).round()}%',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.white70),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}


