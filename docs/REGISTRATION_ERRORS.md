# Анализ ошибок регистрации - Три главных сервиса

## Обзор

При регистрации пользователя задействованы три основных сервиса, которые могут быть источниками ошибок:

## 1. API Gateway (`metachat-api-gateway`)

**Роль:** Принимает HTTP запросы на регистрацию и перенаправляет их в user-service через gRPC.

**Возможные ошибки:**

### 1.1 Ошибки декодирования запроса
```100:112:metachat-all-services/metachat-api-gateway/internal/handlers/gateway_handler.go
func (h *GatewayHandler) Register(w http.ResponseWriter, r *http.Request) {
	h.logger.WithFields(logrus.Fields{
		"method": r.Method,
		"path":   r.URL.Path,
		"remote": r.RemoteAddr,
	}).Info("Register request received")

	var req userPb.RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.logger.WithError(err).Error("Failed to decode register request")
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}
```

**Проблемы:**
- Невалидный JSON в теле запроса
- Отсутствие обязательных полей (username, email, password)
- Неправильный формат данных

### 1.2 Ошибки подключения к user-service
```114:119:metachat-all-services/metachat-api-gateway/internal/handlers/gateway_handler.go
	resp, err := h.userClient.Register(r.Context(), &req)
	if err != nil {
		h.logger.WithError(err).Error("Failed to register user")
		http.Error(w, "Failed to register user", http.StatusInternalServerError)
		return
	}
```

**Проблемы:**
- user-service недоступен
- Таймаут gRPC соединения
- Ошибки сетевого подключения

### 1.3 Ошибки обработки ответа
- Ошибки сериализации ответа в JSON
- Проблемы с заголовками HTTP

---

## 2. User Service (`metachat-user-service`)

**Роль:** Основной сервис регистрации - создает пользователя, сохраняет в Event Store и Cassandra.

**Возможные ошибки:**

### 2.1 Ошибки проверки существования пользователя
```89:98:metachat-all-services/metachat-user-service/internal/service/user_service.go
func (s *userService) createUser(ctx context.Context, username, email, firstName, lastName, dateOfBirth string) (*aggregates.UserAggregate, error) {
	// Check if user with username already exists
	if _, err := s.userRepository.GetUserByUsername(ctx, username); err == nil {
		return nil, ErrUsernameAlreadyExists
	}

	// Check if user with email already exists
	if _, err := s.userRepository.GetUserByEmail(ctx, email); err == nil {
		return nil, ErrEmailAlreadyExists
	}
```

**Проблемы:**
- Пользователь с таким username уже существует
- Пользователь с таким email уже существует
- Ошибки при проверке в Event Store

### 2.2 Ошибки сохранения в Event Store
```42:57:metachat-all-services/metachat-user-service/internal/repository/user_repository.go
// SaveUser saves a user aggregate to the event store
func (r *userRepository) SaveUser(ctx context.Context, user *aggregates.UserAggregate) error {
	// Get uncommitted events
	eventList := user.GetUncommittedEvents()
	if len(eventList) == 0 {
		return nil
	}

	// Save events to event store
	if err := r.eventStore.SaveEvents(ctx, eventList); err != nil {
		return err
	}

	// Clear uncommitted events
	user.ClearUncommittedEvents()
	return nil
}
```

**Проблемы:**
- EventStoreDB недоступен
- Ошибки подключения к EventStoreDB
- Конфликты версий (version conflict)
- Ошибки сериализации событий

### 2.3 Ошибки сохранения в Cassandra (Read Model)
```300:327:metachat-all-services/metachat-user-service/internal/service/user_service.go
// Register creates a new user with password
func (s *userService) Register(ctx context.Context, username, email, password, firstName, lastName string) (string, error) {
	user, err := s.createUser(ctx, username, email, firstName, lastName, "")
	if err != nil {
		return "", err
	}

	passwordHash, err := auth.HashPassword(password)
	if err != nil {
		return "", fmt.Errorf("failed to hash password: %w", err)
	}

	readModel := &models.UserReadModel{
		ID:           user.GetID(),
		Username:     username,
		Email:        email,
		FirstName:    firstName,
		LastName:     lastName,
		DateOfBirth:  "",
		PasswordHash: passwordHash,
		CreatedAt:    user.GetCreatedAt(),
		UpdatedAt:    user.GetUpdatedAt(),
		Version:      user.GetVersion(),
	}

	if err := s.userReadRepository.SaveUserWithIndexes(ctx, readModel); err != nil {
		return "", fmt.Errorf("failed to save user read model: %w", err)
	}
```

**Проблемы:**
- Cassandra недоступна
- Ошибки подключения к Cassandra
- Ошибки записи в таблицы (users_read_model, users_by_username_read_model, users_by_email_read_model)
- Проблемы с индексами

### 2.4 Ошибки публикации событий в Kafka
```117:119:metachat-all-services/metachat-user-service/internal/service/user_service.go
	// Publish event to Kafka
	if err := s.publishUserEvents(ctx, user); err != nil {
		logrus.WithError(err).Error("Failed to publish user events to Kafka")
	}
```

**Проблемы:**
- Kafka недоступен
- Ошибки подключения к Kafka
- Топик не существует
- Ошибки сериализации сообщений

### 2.5 Ошибки генерации JWT токена
```329:332:metachat-all-services/metachat-user-service/internal/service/user_service.go
	token, err := s.jwtManager.GenerateToken(user.GetID(), username, email)
	if err != nil {
		return "", fmt.Errorf("failed to generate token: %w", err)
	}
```

**Проблемы:**
- Ошибки генерации JWT
- Проблемы с секретным ключом

---

## 3. Event Store (через `metachat-event-sourcing`)

**Роль:** Сохраняет события регистрации для event sourcing.

**Возможные ошибки:**

### 3.1 Ошибки подключения к EventStoreDB
```94:98:metachat-all-services/metachat-user-service/cmd/main.go
		esdbStore, err := store.NewEventStoreDBEventStoreFromConfig(eventStoreURL, eventStoreUsername, eventStorePassword, streamPrefix)
		if err != nil {
			logger.WithError(err).Fatal("Failed to create EventStoreDB client")
		}
		eventStore = esdbStore
```

**Проблемы:**
- EventStoreDB недоступен
- Неправильные учетные данные
- Ошибки сетевого подключения
- Таймауты подключения

### 3.2 Ошибки сохранения событий
```50:51:metachat-all-services/metachat-user-service/internal/repository/user_repository.go
	if err := r.eventStore.SaveEvents(ctx, eventList); err != nil {
		return err
```

**Проблемы:**
- Конфликты версий (version conflict)
- Ошибки сериализации событий
- Проблемы с потоком (stream) в EventStoreDB
- Ошибки записи на диск

### 3.3 Типы ошибок Event Store
```57:64:metachat-all-services/metachat-event-sourcing/store/event_store.go
const (
	ErrCodeConnectionFailed = "CONNECTION_FAILED"
	ErrCodeEventNotFound    = "EVENT_NOT_FOUND"
	ErrCodeVersionConflict  = "VERSION_CONFLICT"
	ErrCodeSerialization    = "SERIALIZATION_ERROR"
	ErrCodeStorage          = "STORAGE_ERROR"
)
```

---

## Резюме: Три главных сервиса с ошибками регистрации

1. **API Gateway** - проблемы с HTTP запросами и gRPC соединением
2. **User Service** - проблемы с бизнес-логикой, Event Store, Cassandra и Kafka
3. **Event Store** - проблемы с сохранением событий регистрации

## Рекомендации по диагностике

1. Проверить логи API Gateway на ошибки декодирования и gRPC
2. Проверить логи User Service на ошибки Event Store и Cassandra
3. Проверить доступность EventStoreDB, Cassandra и Kafka
4. Проверить конфигурацию подключений в docker-compose
5. Проверить health checks всех сервисов

---

## Исправления ошибок (выполнено)

### 1. API Gateway (`metachat-api-gateway`)
✅ Добавлена валидация обязательных полей (username, email, password)
✅ Улучшена обработка ошибок с детальными сообщениями
✅ Добавлена обработка специфичных ошибок (AlreadyExists, Unavailable)
✅ Улучшена обработка ошибок кодирования ответа

### 2. User Service - gRPC Server
✅ Добавлена валидация входных данных
✅ Улучшена обработка ошибок с использованием gRPC status codes
✅ Добавлена правильная обработка ошибок AlreadyExists через errors.Is
✅ Улучшено логирование с дополнительными полями

### 3. User Service - Service Layer
✅ Улучшена валидация входных данных в createUser
✅ Исправлена обработка ошибок проверки существования пользователя
✅ Добавлена правильная обработка ошибок Event Store (ErrEventNotFound)
✅ Улучшена обработка ошибок сохранения в Cassandra с детальными сообщениями
✅ Добавлена валидация пароля

### 4. Repository Layer
✅ Улучшена обработка ошибок Event Store (version conflict, connection failed)
✅ Добавлена обработка контекста в запросах Cassandra
✅ Улучшена обработка ошибок сохранения индексов с детальными сообщениями
✅ Добавлены информативные сообщения об ошибках для всех операций

