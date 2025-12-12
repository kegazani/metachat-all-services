# Kafka Topics для MetaChat

Этот документ содержит полный список всех топиков Kafka, используемых в системе MetaChat.

## Список всех топиков

### User Service
- `metachat-user-events` - События пользователей (регистрация, обновление профиля и т.д.)

### Diary Service
- `diary-events` - Общие события дневника
- `session-events` - События сессий дневника
- `metachat.diary.entry.created` - Создана запись в дневнике
- `metachat.diary.entry.updated` - Обновлена запись в дневнике
- `metachat.diary.entry.deleted` - Удалена запись в дневнике

### Match Request Service (NEW)
- `metachat.match.request.created` - Запрос на общение создан
- `metachat.match.request.accepted` - Запрос на общение принят
- `metachat.match.request.rejected` - Запрос на общение отклонен
- `metachat.match.request.cancelled` - Запрос отменен

### Chat Service (NEW)
- `metachat.chat.created` - Чат создан
- `metachat.message.sent` - Сообщение отправлено

### Mood Analysis Service
- `metachat.diary.entry.created` (consumer) - Потребляет события создания записей
- `metachat.diary.entry.updated` (consumer) - Потребляет события обновления записей
- `metachat.mood.analyzed` (producer) - Результаты анализа настроения
- `metachat.mood.analysis.failed` (producer) - Ошибки анализа настроения

### Analytics Service
- `metachat.mood.analyzed` (consumer) - Потребляет результаты анализа настроения
- `metachat.diary.entry.created` (consumer) - Потребляет события создания записей
- `metachat.diary.entry.deleted` (consumer) - Потребляет события удаления записей
- `metachat.archetype.updated` (consumer) - Потребляет события обновления архетипа

### Archetype Service
- `metachat.mood.analyzed` (consumer) - Потребляет результаты анализа настроения
- `metachat.diary.entry.created` (consumer) - Потребляет события создания записей
- `metachat.archetype.assigned` (producer) - Архетип назначен пользователю
- `metachat.archetype.updated` (producer) - Архетип обновлен для пользователя
- `metachat.archetype.calculation.triggered` (producer) - Запущен расчет архетипа

### Biometric Service
- `metachat.biometric.data.received` (producer) - Получены биометрические данные с устройств
  - **API**: `POST /biometric/data` - прием данных от устройств
  - **Payload**: user_id, heart_rate, sleep_data, activity, device_id, timestamp
  - **Реализация**: Полностью реализован, сохраняет данные в PostgreSQL и публикует события в Kafka

### Correlation Service
- `metachat.mood.analyzed` (consumer) - Потребляет результаты анализа настроения
- `metachat.biometric.data.received` (consumer) - Потребляет биометрические данные
- `metachat.correlation.discovered` (producer) - Обнаружены корреляции между настроением и биометрическими данными
  - **Типы корреляций**: heart_rate_valence, sleep_arousal, activity_valence
  - **Метод**: Pearson correlation coefficient
  - **Требования**: минимум 14 дней данных, 10+ записей, p-value < 0.05, |r| > 0.3
  - **Реализация**: Полностью реализован, использует кэширование данных и статистический анализ

### Match Request Service (NEW)
- `metachat.match.request.created` (producer) - Создан запрос на общение
  - **Payload**: match_request_id, from_user_id, to_user_id, common_topics, similarity, timestamp
- `metachat.match.request.accepted` (producer) - Запрос на общение принят
  - **Payload**: match_request_id, from_user_id, to_user_id, accepted_by, timestamp
  - **Trigger**: Создание чата автоматически
- `metachat.match.request.rejected` (producer) - Запрос на общение отклонен
  - **Payload**: match_request_id, from_user_id, to_user_id, rejected_by, timestamp
- `metachat.match.request.cancelled` (producer) - Запрос отменен отправителем
  - **Payload**: match_request_id, from_user_id, to_user_id, timestamp

### Chat Service (NEW)
- `metachat.match.request.accepted` (consumer) - Слушает принятые запросы для создания чата
- `metachat.chat.created` (producer) - Чат создан между пользователями
  - **Payload**: chat_id, user_id1, user_id2, created_at
- `metachat.message.sent` (producer) - Сообщение отправлено в чате
  - **Payload**: message_id, chat_id, sender_id, content, sent_at
  - **Future**: Триггер для push-уведомлений

## Создание топиков

Для создания всех топиков используйте скрипт:

```bash
./docker/create-kafka-topics.sh
```

Или расширенную версию с подробным выводом:

```bash
./docker/create-kafka-topics-advanced.sh
```

## Конфигурация топиков

Все топики создаются со следующими параметрами по умолчанию:
- **Partitions**: 3
- **Replication Factor**: 1 (для development)
- **Retention**: 7 дней (604800000 ms)
- **Cleanup Policy**: delete

## Проверка топиков

Для проверки созданных топиков:

```bash
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list
```

Для просмотра деталей конкретного топика:

```bash
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --describe --topic <topic-name>
```

## Kafka UI

Для визуального управления топиками используйте Kafka UI:
- URL: http://localhost:8090
- Подключение к кластеру: kafka:29092

