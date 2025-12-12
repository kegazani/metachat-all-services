import 'package:flutter/material.dart';

import 'package:metachat_app/shared/widgets/glass_nav_bar.dart';
import 'package:metachat_app/features/diary/presentation/pages/diary_page.dart';
import 'package:metachat_app/features/mood/presentation/pages/mood_page.dart';
import 'package:metachat_app/features/matching/presentation/pages/matching_page.dart';
import 'package:metachat_app/features/analytics/presentation/pages/analytics_page.dart';
import 'package:metachat_app/features/chat/presentation/pages/chat_page.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DiaryPage(),
      const MoodPage(),
      const MatchingPage(),
      const AnalyticsPage(),
      const ChatPage(),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: index,
          children: pages,
        ),
      ),
      bottomNavigationBar: GlassNavBar(
        currentIndex: index,
        onTap: (value) {
          setState(() {
            index = value;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            label: 'Дневник',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mood),
            label: 'Настроение',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            label: 'Матчинг',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: 'Аналитика',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Чат',
          ),
        ],
      ),
    );
  }
}


