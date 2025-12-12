# Flutter UI Implementation Guide

Руководство по реализации UI компонентов для новой функциональности MetaChat.

## 📔 Вкладка "Личный дневник" - обновления

### Текущее состояние
Вкладка уже существует с базовым функционалом дневника.

### Требуется добавить

#### 1. Profile Header Widget
**Файл:** `lib/features/diary/presentation/widgets/profile_header.dart`

```dart
class ProfileHeader extends StatelessWidget {
  final User user;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(user.avatar ?? ''),
              child: user.avatar == null ? Icon(Icons.person) : null,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? user.username,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (user.email != null)
                    Text(
                      user.email!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### 2. Profile Progress Card Widget
**Файл:** `lib/features/diary/presentation/widgets/profile_progress_card.dart`

```dart
class ProfileProgressCard extends StatelessWidget {
  final ProfileProgress progress;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Прогресс расчета личности',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            
            // Progress bar
            LinearProgressIndicator(
              value: progress.progressPercentage,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            SizedBox(height: 8),
            
            // Tokens info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Токены проанализированы'),
                Text(
                  '${progress.tokensAnalyzed} / ${progress.isFirstCalculation ? progress.tokensRequiredForFirst : progress.tokensRequiredForRecalc}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            
            if (!progress.isFirstCalculation) ...[
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('До следующего пересчета'),
                  Text(
                    '${progress.daysUntilRecalc} дней',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
            
            SizedBox(height: 12),
            
            // Status message
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: progress.isFirstCalculation
                    ? Colors.blue.shade50
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    progress.isFirstCalculation
                        ? Icons.pending
                        : Icons.check_circle,
                    size: 20,
                    color: progress.isFirstCalculation
                        ? Colors.blue
                        : Colors.green,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      progress.isFirstCalculation
                          ? 'Продолжайте писать для первого расчета'
                          : 'Личность определена, продолжайте для обновления',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### 3. User Statistics Card Widget
**Файл:** `lib/features/diary/presentation/widgets/user_statistics_card.dart`

```dart
class UserStatisticsCard extends StatelessWidget {
  final UserStatistics statistics;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Статистика',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            
            // Stats grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _StatItem(
                  icon: Icons.book,
                  label: 'Записей',
                  value: statistics.totalDiaryEntries.toString(),
                ),
                _StatItem(
                  icon: Icons.psychology,
                  label: 'Анализов',
                  value: statistics.totalMoodAnalyses.toString(),
                ),
                _StatItem(
                  icon: Icons.article,
                  label: 'Токенов',
                  value: statistics.totalTokens.toString(),
                ),
                _StatItem(
                  icon: Icons.emoji_emotions,
                  label: 'Эмоция',
                  value: _getEmotionEmoji(statistics.dominantEmotion),
                ),
              ],
            ),
            
            if (statistics.topTopics.isNotEmpty) ...[
              SizedBox(height: 16),
              Text(
                'Топ темы',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: statistics.topTopics.take(5).map((topic) {
                  return Chip(
                    label: Text(topic),
                    backgroundColor: Colors.blue.shade50,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  String _getEmotionEmoji(String emotion) {
    final map = {
      'joy': '😊',
      'trust': '🤝',
      'fear': '😰',
      'surprise': '😮',
      'sadness': '😢',
      'disgust': '😖',
      'anger': '😠',
      'anticipation': '🤔',
    };
    return map[emotion.toLowerCase()] ?? emotion;
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
```

#### 4. Обновленная Diary Page
**Файл:** `lib/features/diary/presentation/pages/diary_page.dart`

```dart
class DiaryPage extends StatefulWidget {
  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  late ProfileRemoteDataSource _profileDataSource;
  late DiaryRemoteDataSource _diaryDataSource;
  
  User? _currentUser;
  ProfileProgress? _progress;
  UserStatistics? _statistics;
  List<DiaryEntry>? _entries;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _profileDataSource = ProfileRemoteDataSource(context.read<ApiClient>());
    _diaryDataSource = DiaryRemoteDataSource(context.read<ApiClient>());
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = context.read<AuthProvider>().currentUserId;
      
      final results = await Future.wait([
        _profileDataSource.getProfileProgress(userId),
        _profileDataSource.getUserStatistics(userId),
        _diaryDataSource.getUserEntries(userId),
      ]);
      
      setState(() {
        _progress = results[0] as ProfileProgress;
        _statistics = results[1] as UserStatistics;
        _entries = results[2] as List<DiaryEntry>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки данных: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_currentUser != null)
                    ProfileHeader(user: _currentUser!),
                  SizedBox(height: 16),
                  if (_progress != null)
                    ProfileProgressCard(progress: _progress!),
                  SizedBox(height: 16),
                  if (_statistics != null)
                    UserStatisticsCard(statistics: _statistics!),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Мои записи',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          // Navigate to create entry
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (_entries != null && _entries!.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = _entries![index];
                  return DiaryEntryCard(entry: entry);
                },
                childCount: _entries!.length,
              ),
            )
          else
            SliverFillRemaining(
              child: Center(
                child: Text('Нет записей в дневнике'),
              ),
            ),
        ],
      ),
    );
  }
}
```

---

## 💑 Вкладка "Матчинг" - обновления

### Требуется добавить

#### 1. User Match Card Widget
**Файл:** `lib/features/matching/presentation/widgets/user_match_card.dart`

```dart
class UserMatchCard extends StatelessWidget {
  final UserMatch match;
  final VoidCallback? onMatchRequest;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: match.user.avatar != null
                      ? NetworkImage(match.user.avatar!)
                      : null,
                  child: match.user.avatar == null
                      ? Icon(Icons.person, size: 30)
                      : null,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.user.displayName ?? match.user.username,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 16,
                            color: _getSimilarityColor(match.similarity),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${(match.similarity * 100).toInt()}% совместимость',
                            style: TextStyle(
                              color: _getSimilarityColor(match.similarity),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (match.commonTopics.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                'Общие интересы:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: match.commonTopics.take(5).map((topic) {
                  return Chip(
                    label: Text(
                      topic,
                      style: TextStyle(fontSize: 11),
                    ),
                    backgroundColor: Colors.blue.shade50,
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
            
            SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onMatchRequest,
                icon: Icon(Icons.chat_bubble_outline),
                label: Text('Предложить общение'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getSimilarityColor(double similarity) {
    if (similarity >= 0.8) return Colors.green;
    if (similarity >= 0.6) return Colors.orange;
    return Colors.grey;
  }
}
```

#### 2. Match Request Item Widget
**Файл:** `lib/features/matching/presentation/widgets/match_request_item.dart`

```dart
class MatchRequestItem extends StatelessWidget {
  final MatchRequest request;
  final bool isOutgoing;
  final Function(String)? onAccept;
  final Function(String)? onReject;
  final Function(String)? onCancel;
  
  @override
  Widget build(BuildContext context) {
    final otherUserId = isOutgoing ? request.toUserId : request.fromUserId;
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  child: Icon(Icons.person),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOutgoing
                            ? 'Запрос отправлен'
                            : 'Входящий запрос',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'User ID: ${otherUserId.substring(0, 8)}...',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: request.status),
              ],
            ),
            
            if (request.commonTopics.isNotEmpty) ...[
              SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: request.commonTopics.map((topic) {
                  return Chip(
                    label: Text(topic, style: TextStyle(fontSize: 11)),
                    backgroundColor: Colors.blue.shade50,
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
            
            if (request.isPending) ...[
              SizedBox(height: 12),
              Row(
                children: [
                  if (!isOutgoing) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => onAccept?.call(request.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Принять'),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => onReject?.call(request.id),
                        child: Text('Отклонить'),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => onCancel?.call(request.id),
                        child: Text('Отменить'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  
  const _StatusBadge({required this.status});
  
  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    
    switch (status) {
      case 'accepted':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case 'cancelled':
        color = Colors.grey;
        icon = Icons.block;
        break;
      default:
        color = Colors.orange;
        icon = Icons.schedule;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
```

#### 3. Matching Page with Tabs
**Файл:** `lib/features/matching/presentation/pages/matching_page.dart`

```dart
class MatchingPage extends StatefulWidget {
  @override
  State<MatchingPage> createState() => _MatchingPageState();
}

class _MatchingPageState extends State<MatchingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MatchingRemoteDataSource _matchingDataSource;
  late MatchRequestRemoteDataSource _matchRequestDataSource;
  
  List<UserMatch>? _similarUsers;
  List<MatchRequest>? _receivedRequests;
  List<MatchRequest>? _sentRequests;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _matchingDataSource = MatchingRemoteDataSource(context.read<ApiClient>());
    _matchRequestDataSource = MatchRequestRemoteDataSource(context.read<ApiClient>());
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = context.read<AuthProvider>().currentUserId;
      
      final results = await Future.wait([
        _matchingDataSource.findSimilarUsers(userId),
        _matchRequestDataSource.getUserMatchRequests(userId),
      ]);
      
      final allRequests = results[1] as List<MatchRequest>;
      
      setState(() {
        _similarUsers = results[0] as List<UserMatch>;
        _receivedRequests = allRequests
            .where((r) => r.toUserId == userId && r.isPending)
            .toList();
        _sentRequests = allRequests
            .where((r) => r.fromUserId == userId)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки: $e')),
      );
    }
  }
  
  Future<void> _sendMatchRequest(UserMatch match) async {
    try {
      final userId = context.read<AuthProvider>().currentUserId;
      
      await _matchRequestDataSource.createMatchRequest(
        fromUserId: userId,
        toUserId: match.userId,
        commonTopics: match.commonTopics,
        similarity: match.similarity,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Запрос отправлен!')),
      );
      
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }
  
  Future<void> _acceptRequest(String requestId) async {
    try {
      final userId = context.read<AuthProvider>().currentUserId;
      await _matchRequestDataSource.acceptMatchRequest(requestId, userId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Запрос принят! Чат создан.')),
      );
      
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Поиск собеседников'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Похожие',
              icon: Badge(
                isLabelVisible: _similarUsers?.isNotEmpty ?? false,
                label: Text('${_similarUsers?.length ?? 0}'),
                child: Icon(Icons.people),
              ),
            ),
            Tab(
              text: 'Входящие',
              icon: Badge(
                isLabelVisible: _receivedRequests?.isNotEmpty ?? false,
                label: Text('${_receivedRequests?.length ?? 0}'),
                child: Icon(Icons.inbox),
              ),
            ),
            Tab(
              text: 'Отправленные',
              icon: Badge(
                isLabelVisible: _sentRequests?.isNotEmpty ?? false,
                label: Text('${_sentRequests?.length ?? 0}'),
                child: Icon(Icons.send),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Similar users
          RefreshIndicator(
            onRefresh: _loadData,
            child: _similarUsers == null
                ? Center(child: CircularProgressIndicator())
                : _similarUsers!.isEmpty
                    ? Center(child: Text('Нет подходящих пользователей'))
                    : ListView.builder(
                        itemCount: _similarUsers!.length,
                        itemBuilder: (context, index) {
                          final match = _similarUsers![index];
                          return UserMatchCard(
                            match: match,
                            onMatchRequest: () => _sendMatchRequest(match),
                          );
                        },
                      ),
          ),
          
          // Received requests
          RefreshIndicator(
            onRefresh: _loadData,
            child: _receivedRequests == null
                ? Center(child: CircularProgressIndicator())
                : _receivedRequests!.isEmpty
                    ? Center(child: Text('Нет входящих запросов'))
                    : ListView.builder(
                        itemCount: _receivedRequests!.length,
                        itemBuilder: (context, index) {
                          final request = _receivedRequests![index];
                          return MatchRequestItem(
                            request: request,
                            isOutgoing: false,
                            onAccept: _acceptRequest,
                            onReject: (id) {
                              // Implement reject
                            },
                          );
                        },
                      ),
          ),
          
          // Sent requests
          RefreshIndicator(
            onRefresh: _loadData,
            child: _sentRequests == null
                ? Center(child: CircularProgressIndicator())
                : _sentRequests!.isEmpty
                    ? Center(child: Text('Нет отправленных запросов'))
                    : ListView.builder(
                        itemCount: _sentRequests!.length,
                        itemBuilder: (context, index) {
                          final request = _sentRequests![index];
                          return MatchRequestItem(
                            request: request,
                            isOutgoing: true,
                            onCancel: (id) {
                              // Implement cancel
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
```

---

## 📝 Чеклист реализации

### Diary Tab
- [ ] Создать `ProfileHeader` widget
- [ ] Создать `ProfileProgressCard` widget
- [ ] Создать `UserStatisticsCard` widget
- [ ] Обновить `DiaryPage` с новыми виджетами
- [ ] Интегрировать `ProfileRemoteDataSource`
- [ ] Добавить обработку ошибок
- [ ] Добавить pull-to-refresh

### Matching Tab
- [ ] Создать `UserMatchCard` widget
- [ ] Создать `MatchRequestItem` widget
- [ ] Создать `MatchingPage` с табами
- [ ] Интегрировать `MatchRequestRemoteDataSource`
- [ ] Реализовать логику отправки запросов
- [ ] Реализовать логику принятия/отклонения запросов
- [ ] Добавить бейджи с количеством запросов
- [ ] Добавить обработку ошибок

### Chat Tab (Future)
- [ ] Создать `ChatListItem` widget
- [ ] Создать `MessageBubble` widget
- [ ] Создать `ChatConversationPage`
- [ ] Интегрировать `ChatRemoteDataSource`
- [ ] Реализовать отправку сообщений
- [ ] Добавить polling или WebSocket для новых сообщений
- [ ] Реализовать отметку как прочитанные

---

## 🎨 UI/UX рекомендации

1. **Анимации**: Используйте `AnimatedContainer` для плавных переходов
2. **Skeleton loading**: Добавьте скелетоны вместо простых индикаторов загрузки
3. **Empty states**: Красивые пустые состояния с призывом к действию
4. **Error handling**: Toast уведомления + возможность повторить
5. **Pull to refresh**: Везде где есть списки
6. **Shimmer effect**: Для карточек при загрузке
7. **Success animations**: Анимация при успешных действиях (принятие запроса)

---

## 🔌 Интеграция с Provider

```dart
// lib/features/diary/presentation/providers/diary_provider.dart
class DiaryProvider extends ChangeNotifier {
  final ProfileRemoteDataSource _profileDataSource;
  final DiaryRemoteDataSource _diaryDataSource;
  
  ProfileProgress? _progress;
  UserStatistics? _statistics;
  List<DiaryEntry> _entries = [];
  bool _isLoading = false;
  
  ProfileProgress? get progress => _progress;
  UserStatistics? get statistics => _statistics;
  List<DiaryEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  
  Future<void> loadDiaryData(String userId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _progress = await _profileDataSource.getProfileProgress(userId);
      _statistics = await _profileDataSource.getUserStatistics(userId);
      _entries = await _diaryDataSource.getUserEntries(userId);
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

---

## 🚀 Запуск и тестирование

```bash
# Генерация кода (если используется freezed/json_serializable)
flutter pub run build_runner build --delete-conflicting-outputs

# Запуск приложения
flutter run

# Тесты
flutter test

# Анализ кода
flutter analyze
```

