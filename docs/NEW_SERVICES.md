# Новые сервисы MetaChat

Этот документ описывает недавно добавленные сервисы и функциональность.

## 🆕 Match Request Service (gRPC :50054)

### Описание
Управление запросами на общение между пользователями. Реализует систему взаимного подтверждения перед началом общения.

### Функции
- Создание запроса на общение (с общими темами и процентом совместимости)
- Получение входящих/исходящих запросов пользователя
- Принятие запроса (автоматически создает чат)
- Отклонение запроса
- Отмена отправленного запроса

### API (через API Gateway)

```bash
# Создать запрос
POST /match-requests
{
  "from_user_id": "uuid",
  "to_user_id": "uuid",
  "common_topics": ["музыка", "книги"],
  "similarity": 0.87
}

# Получить запросы пользователя
GET /match-requests/user/{user_id}?status=pending

# Принять запрос
PUT /match-requests/{request_id}/accept?user_id={user_id}

# Отклонить запрос
PUT /match-requests/{request_id}/reject?user_id={user_id}

# Отменить запрос
DELETE /match-requests/{request_id}?user_id={user_id}
```

### База данных (PostgreSQL)

```sql
CREATE TABLE match_requests (
    id UUID PRIMARY KEY,
    from_user_id UUID NOT NULL,
    to_user_id UUID NOT NULL,
    common_topics TEXT[],
    similarity FLOAT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(from_user_id, to_user_id, status)
);
```

### Kafka Events
- `metachat.match.request.created` - Запрос создан
- `metachat.match.request.accepted` - Запрос принят → триггер для Chat Service
- `metachat.match.request.rejected` - Запрос отклонен
- `metachat.match.request.cancelled` - Запрос отменен

---

## 🆕 Chat Service (gRPC :50055)

### Описание
Управление чатами и сообщениями между пользователями. Чат создается автоматически при принятии match request.

### Функции
- Автоматическое создание чата при принятии match request
- Отправка сообщений
- Получение истории сообщений
- Отметка сообщений как прочитанных
- Список чатов пользователя

### API (через API Gateway)

```bash
# Создать чат (обычно автоматически)
POST /chats
{
  "user_id1": "uuid",
  "user_id2": "uuid"
}

# Получить чат
GET /chats/{chat_id}

# Чаты пользователя
GET /chats/user/{user_id}

# Отправить сообщение
POST /chats/{chat_id}/messages
{
  "sender_id": "uuid",
  "content": "Привет! Как дела?"
}

# История сообщений
GET /chats/{chat_id}/messages?limit=50&before_message_id=uuid

# Отметить как прочитанные
PUT /chats/{chat_id}/messages/read?user_id=uuid
```

### База данных (PostgreSQL)

```sql
CREATE TABLE chats (
    id UUID PRIMARY KEY,
    user_id1 UUID NOT NULL,
    user_id2 UUID NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(user_id1, user_id2)
);

CREATE TABLE messages (
    id UUID PRIMARY KEY,
    chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    read_at TIMESTAMP
);
```

### Kafka Events
- `metachat.chat.created` - Чат создан
- `metachat.message.sent` - Сообщение отправлено

---

## 🔄 Обновленные сервисы

### User Service - новые методы

#### GetUserProfileProgress (gRPC)
Возвращает прогресс расчета личности:
```json
{
  "tokens_analyzed": 30,
  "tokens_required_for_first": 50,
  "tokens_required_for_recalc": 100,
  "days_since_last_calc": 0,
  "days_until_recalc": 7,
  "is_first_calculation": true,
  "progress_percentage": 0.6
}
```

**Вызывает:** `Archetype Service (gRPC :50056) → GetProfileProgress`

#### GetUserStatistics (gRPC)
Возвращает статистику пользователя:
```json
{
  "total_diary_entries": 15,
  "total_mood_analyses": 15,
  "total_tokens": 450,
  "dominant_emotion": "joy",
  "top_topics": ["работа", "семья", "музыка"],
  "profile_created_at": "2024-01-15T10:00:00Z",
  "last_personality_update": "2024-01-20T15:30:00Z"
}
```

**Вызывает:** `Analytics Service (gRPC :50057) → GetUserStatistics`

---

### Matching Service - новые методы

#### GetCommonTopics (gRPC)
Извлекает общие темы/интересы между двумя пользователями:
```bash
GET /users/{user_id1}/common-topics/{user_id2}

Response:
{
  "common_topics": ["музыка", "путешествия", "книги", "спорт"]
}
```

**Источник данных:** User Portraits из Cassandra

---

### Archetype Service - новые методы

#### GetProfileProgress (gRPC :50056)
Добавлен gRPC сервер для получения прогресса расчета личности.

**Repository метод:**
```python
async def get_profile_progress(session: AsyncSession, user_id: str):
    # Вычисляет прогресс на основе:
    # - accumulated_tokens
    # - last_calculation_date
    # - thresholds (50/100 токенов, 7 дней)
```

---

### Analytics Service - новые методы

#### GetUserStatistics (gRPC :50057)
Добавлен gRPC сервер для получения агрегированной статистики.

**Repository метод:**
```python
async def get_user_statistics(session: AsyncSession, user_id: str):
    # Агрегирует данные из:
    # - daily_mood_summary (записи, токены, эмоции)
    # - user_topics_summary (топ темы)
    # - archetype_history (обновления личности)
```

---

## 🔄 Полный flow: Матчинг → Запрос → Чат

```mermaid
sequenceDiagram
    participant U1 as User 1 (App)
    participant GW as API Gateway
    participant MS as Matching Service
    participant MRS as Match Request Service
    participant K as Kafka
    participant CS as Chat Service
    participant U2 as User 2 (App)

    U1->>GW: GET /users/{u1}/common-topics/{u2}
    GW->>MS: gRPC GetCommonTopics
    MS-->>GW: ["музыка", "книги"]
    GW-->>U1: common_topics
    
    U1->>GW: POST /match-requests
    GW->>MRS: gRPC CreateMatchRequest
    MRS->>MRS: Save to PostgreSQL
    MRS->>K: publish match.request.created
    MRS-->>GW: match_request (status: pending)
    GW-->>U1: Request created
    
    Note over U2: Gets notification
    U2->>GW: PUT /match-requests/{id}/accept
    GW->>MRS: gRPC AcceptMatchRequest
    MRS->>MRS: Update status
    MRS->>K: publish match.request.accepted
    MRS-->>GW: match_request (status: accepted)
    
    K->>CS: consume match.request.accepted
    CS->>CS: Create Chat (auto)
    CS->>K: publish chat.created
    CS-->>U1: Chat available
    CS-->>U2: Chat available
    
    U1->>GW: POST /chats/{chat_id}/messages
    GW->>CS: gRPC SendMessage
    CS->>CS: Save message
    CS->>K: publish message.sent
    CS-->>GW: message
    GW-->>U2: New message notification
```

---

## 📱 Flutter App Integration

### Data Models

```dart
// lib/features/diary/domain/models/profile_progress.dart
class ProfileProgress {
  final int tokensAnalyzed;
  final int tokensRequiredForFirst;
  final int tokensRequiredForRecalc;
  final int daysSinceLastCalc;
  final int daysUntilRecalc;
  final bool isFirstCalculation;
  final double progressPercentage;
}

// lib/features/diary/domain/models/user_statistics.dart
class UserStatistics {
  final int totalDiaryEntries;
  final int totalMoodAnalyses;
  final int totalTokens;
  final String dominantEmotion;
  final List<String> topTopics;
  final DateTime profileCreatedAt;
  final DateTime lastPersonalityUpdate;
}

// lib/features/matching/domain/models/match_request.dart
class MatchRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final List<String> commonTopics;
  final double similarity;
  final String status; // pending/accepted/rejected/cancelled
  final DateTime createdAt;
  final DateTime updatedAt;
}

// lib/features/chat/domain/models/chat.dart & message.dart
class Chat {
  final String id;
  final String userId1;
  final String userId2;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final DateTime? readAt;
}
```

### Data Sources

```dart
// lib/features/diary/data/datasources/remote/profile_remote_data_source.dart
class ProfileRemoteDataSource {
  Future<ProfileProgress> getProfileProgress(String userId);
  Future<UserStatistics> getUserStatistics(String userId);
}

// lib/features/matching/data/datasources/remote/match_request_remote_data_source.dart
class MatchRequestRemoteDataSource {
  Future<MatchRequest> createMatchRequest(...);
  Future<List<MatchRequest>> getUserMatchRequests(String userId, {String? status});
  Future<MatchRequest> acceptMatchRequest(String requestId, String userId);
  Future<MatchRequest> rejectMatchRequest(String requestId, String userId);
  Future<List<String>> getCommonTopics(String userId1, String userId2);
}

// lib/features/chat/data/datasources/remote/chat_remote_data_source.dart
class ChatRemoteDataSource {
  Future<Chat> createChat(String userId1, String userId2);
  Future<List<Chat>> getUserChats(String userId);
  Future<Message> sendMessage({required String chatId, required String senderId, required String content});
  Future<List<Message>> getChatMessages(String chatId, {int? limit, String? beforeMessageId});
  Future<int> markMessagesAsRead(String chatId, String userId);
}
```

---

## 🚀 Deployment

### Docker Compose

Добавить в `docker-compose.services.yml`:

```yaml
  match-request-service:
    build:
      context: ./metachat-all-services/metachat-match-request-service
    ports:
      - "50054:50054"
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@postgres:5432/metachat_match_requests
    depends_on:
      - postgres
      - kafka

  chat-service:
    build:
      context: ./metachat-all-services/metachat-chat-service
    ports:
      - "50055:50055"
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@postgres:5432/metachat_chat
    depends_on:
      - postgres
      - kafka
```

### Migrations

```bash
# Match Request Service
psql -U postgres -d metachat_match_requests -f \
  ./metachat-all-services/metachat-match-request-service/migrations/001_create_match_requests.sql

# Chat Service
psql -U postgres -d metachat_chat -f \
  ./metachat-all-services/metachat-chat-service/migrations/001_create_chats_and_messages.sql
```

---

## 📊 Мониторинг

### Health Checks

```bash
# Match Request Service
grpcurl -plaintext localhost:50054 grpc.health.v1.Health/Check

# Chat Service
grpcurl -plaintext localhost:50055 grpc.health.v1.Health/Check
```

### Kafka Topics

```bash
# Проверить новые топики
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list | grep -E '(match|chat)'

# Слушать события
docker exec kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic metachat.match.request.accepted \
  --from-beginning
```

---

## 🔐 Security Considerations

- **Match Requests**: Проверка что user_id в запросе соответствует аутентифицированному пользователю
- **Chats**: Доступ только для участников чата
- **Messages**: Валидация sender_id и членства в чате

---

## 🎯 Future Enhancements

1. **Push Notifications** при новых match requests и сообщениях
2. **WebSocket** для real-time чата
3. **Read receipts** с временными метками
4. **Typing indicators** в чатах
5. **Block/Report** функциональность
6. **Match request expiration** (автоотмена через N дней)
7. **Message attachments** (фото, файлы)
8. **Voice messages**
9. **Reactions** на сообщения
10. **Group chats** (будущее)

