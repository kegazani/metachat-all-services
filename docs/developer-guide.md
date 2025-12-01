# Руководство разработчика MetaChat

## Введение

MetaChat - это платформа для ведения дневника с анализом эмоционального состояния и рекомендациями на основе схожести пользователей. Система построена на микросервисной архитектуре с использованием event sourcing для обеспечения отказоустойчивости и масштабируемости.

Это руководство предназначено для разработчиков, которые хотят внести вклад в проект или лучше понять его архитектуру и принципы работы.

## Структура проекта

```
metachat/
├── services/                    # Микросервисы
│   ├── user-service/          # Сервис управления пользователями
│   │   ├── cmd/               # Точка входа приложения
│   │   ├── internal/          # Внутренние пакеты
│   │   │   ├── api/           # API обработчики
│   │   │   ├── repository/    # Репозитории для работы с данными
│   │   │   ├── service/       # Бизнес-логика
│   │   │   └── model/         # Модели данных
│   │   ├── config/            # Конфигурация
│   │   └── Dockerfile         # Dockerfile для сборки
│   ├── diary-service/        # Сервис управления дневником
│   ├── mood-analysis-service/ # Сервис анализа настроения
│   ├── matching-service/     # Сервис мэтчинга и рекомендаций
│   └── mobile-app/           # Мобильное приложение (iOS)
├── shared/                    # Общие библиотеки
│   ├── events/               # Определения событий
│   ├── eventstore/           # Клиент для EventStoreDB
│   └── kafka/                # Продюсеры и консьюмеры Kafka
├── infrastructure/            # Инфраструктурные компоненты
│   ├── docker-compose.yml    # Docker Compose для локальной разработки
│   └── k8s/                  # Kubernetes манифесты
├── docs/                     # Документация
├── tests/                    # Тесты
└── scripts/                  # Вспомогательные скрипты
```

## Технологический стек

### Backend
- **Go**: Основной язык для микросервисов
- **Python**: Для Mood Analysis Service (из-за использования предобученных моделей NLP)
- **gRPC**: Для внутренней коммуникации между сервисами
- **REST**: Для внешнего API
- **EventStoreDB**: Для хранения событий (event sourcing)
- **Cassandra**: Для хранения read-моделей
- **Apache Kafka**: Для асинхронной коммуникации между сервисами

### Frontend
- **Swift**: Для мобильного приложения (iOS)
- **SwiftUI**: Для создания пользовательского интерфейса

### Инфраструктура
- **Docker**: Для контейнеризации сервисов
- **Kubernetes**: Для оркестрации контейнеров в продакшн
- **Helm**: Для управления Kubernetes релизами
- **Kong/Traefik**: В качестве API Gateway
- **Prometheus & Grafana**: Для мониторинга
- **EFK Stack (Elasticsearch, Fluentd, Kibana)**: Для централизованного логирования

## Принципы разработки

### 1. Микросервисная архитектура
- Каждый сервис должен быть независимым и отвечать за свою область ответственности
- Сервисы должны общаться через четко определенные API (REST/gRPC) или события (Kafka)
- Избегайте прямого доступа к базе данных одного сервиса из другого

### 2. Event Sourcing
- Все изменения состояния системы должны быть представлены как последовательность событий
- События должны быть иммутабельными и храниться в хронологическом порядке
- Текущее состояние получается путем воспроизведения событий

### 3. CQRS (Command Query Responsibility Segregation)
- Разделение операций чтения (Query) и записи (Command)
- Использование разных моделей данных для чтения и записи
- Оптимизация моделей для чтения под конкретные сценарии использования

### 4. DDD (Domain-Driven Design)
- Фокусировка на бизнес-логике и предметной области
- Использование агрегатов для обеспечения консистентности данных
- Четкое определение границ контекста (Bounded Context)

## Разработка нового сервиса

### 1. Создание структуры сервиса

```bash
mkdir -p services/new-service/{cmd,internal/{api,repository,service,model},config}
touch services/new-service/go.mod
touch services/new-service/Dockerfile
```

### 2. Определение моделей

```go
// internal/model/entity.go
package model

type Entity struct {
    ID      string
    Version int
    // другие поля
}

// internal/model/event.go
package model

type Event interface {
    GetAggregateID() string
    GetEventType() string
    GetTimestamp() time.Time
}

type EntityCreated struct {
    EntityID string
    Timestamp time.Time
    // другие поля
}

func (e EntityCreated) GetAggregateID() string {
    return e.EntityID
}

func (e EntityCreated) GetEventType() string {
    return "entity_created"
}

func (e EntityCreated) GetTimestamp() time.Time {
    return e.Timestamp
}
```

### 3. Реализация репозитория

```go
// internal/repository/repository.go
package repository

import (
    "context"
    
    "metachat/shared/eventstore"
    "metachat/new-service/internal/model"
)

type Repository interface {
    Save(ctx context.Context, events []model.Event) error
    Load(ctx context.Context, id string) ([]model.Event, error)
}

type EventStoreRepository struct {
    client *eventstore.Client
}

func NewEventStoreRepository(client *eventstore.Client) Repository {
    return &EventStoreRepository{client: client}
}

func (r *EventStoreRepository) Save(ctx context.Context, events []model.Event) error {
    return r.client.AppendEvents(ctx, events)
}

func (r *EventStoreRepository) Load(ctx context.Context, id string) ([]model.Event, error) {
    return r.client.LoadEvents(ctx, id)
}
```

### 4. Реализация сервиса

```go
// internal/service/service.go
package service

import (
    "context"
    
    "metachat/new-service/internal/model"
    "metachat/new-service/internal/repository"
)

type Service interface {
    CreateEntity(ctx context.Context, cmd CreateEntityCommand) (*model.Entity, error)
    GetEntity(ctx context.Context, id string) (*model.Entity, error)
}

type service struct {
    repo   repository.Repository
    kafka  *kafka.Producer
}

func NewService(repo repository.Repository, kafka *kafka.Producer) Service {
    return &service{repo: repo, kafka: kafka}
}

func (s *service) CreateEntity(ctx context.Context, cmd CreateEntityCommand) (*model.Entity, error) {
    // Бизнес-логика создания сущности
    entity := model.NewEntity(cmd.ID)
    
    // Создание событий
    events := []model.Event{
        model.EntityCreated{
            EntityID: entity.ID,
            Timestamp: time.Now(),
        },
    }
    
    // Сохранение событий
    if err := s.repo.Save(ctx, events); err != nil {
        return nil, err
    }
    
    // Публикация событий в Kafka
    if err := s.kafka.Publish(ctx, events); err != nil {
        return nil, err
    }
    
    return entity, nil
}

func (s *service) GetEntity(ctx context.Context, id string) (*model.Entity, error) {
    // Загрузка событий
    events, err := s.repo.Load(ctx, id)
    if err != nil {
        return nil, err
    }
    
    // Восстановление состояния сущности из событий
    entity := model.NewEntity(id)
    for _, event := range events {
        entity.Apply(event)
    }
    
    return entity, nil
}
```

### 5. Реализация API

```go
// internal/api/handler.go
package api

import (
    "encoding/json"
    "net/http"
    
    "github.com/gorilla/mux"
    
    "metachat/new-service/internal/service"
)

type Handler struct {
    service service.Service
}

func NewHandler(service service.Service) *Handler {
    return &Handler{service: service}
}

func (h *Handler) RegisterRoutes(router *mux.Router) {
    router.HandleFunc("/entities", h.CreateEntity).Methods("POST")
    router.HandleFunc("/entities/{id}", h.GetEntity).Methods("GET")
}

func (h *Handler) CreateEntity(w http.ResponseWriter, r *http.Request) {
    var cmd service.CreateEntityCommand
    if err := json.NewDecoder(r.Body).Decode(&cmd); err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    
    entity, err := h.service.CreateEntity(r.Context(), cmd)
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(entity)
}

func (h *Handler) GetEntity(w http.ResponseWriter, r *http.Request) {
    vars := mux.Vars(r)
    id := vars["id"]
    
    entity, err := h.service.GetEntity(r.Context(), id)
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(entity)
}
```

### 6. Точка входа приложения

```go
// cmd/main.go
package main

import (
    "log"
    "net/http"
    "os"
    
    "github.com/gorilla/mux"
    
    "metachat/shared/eventstore"
    "metachat/shared/kafka"
    "metachat/new-service/internal/api"
    "metachat/new-service/internal/repository"
    "metachat/new-service/internal/service"
)

func main() {
    // Загрузка конфигурации
    cfg := loadConfig()
    
    // Инициализация зависимостей
    eventStoreClient := eventstore.NewClient(cfg.EventStoreDB)
    kafkaProducer := kafka.NewProducer(cfg.Kafka)
    
    // Создание репозитория
    repo := repository.NewEventStoreRepository(eventStoreClient)
    
    // Создание сервиса
    svc := service.NewService(repo, kafkaProducer)
    
    // Создание API обработчика
    handler := api.NewHandler(svc)
    
    // Настройка роутера
    router := mux.NewRouter()
    handler.RegisterRoutes(router)
    
    // Запуск сервера
    server := &http.Server{
        Addr:    ":" + cfg.Port,
        Handler: router,
    }
    
    log.Printf("Starting server on %s", server.Addr)
    if err := server.ListenAndServe(); err != nil {
        log.Fatalf("Failed to start server: %v", err)
    }
}

func loadConfig() *Config {
    // Загрузка конфигурации из переменных окружения или файла
    return &Config{
        EventStoreDB: eventstore.Config{
            Host:     os.Getenv("EVENTSTOREDB_HOST"),
            Port:     os.Getenv("EVENTSTOREDB_PORT"),
            User:     os.Getenv("EVENTSTOREDB_USER"),
            Password: os.Getenv("EVENTSTOREDB_PASSWORD"),
        },
        Kafka: kafka.Config{
            Brokers: []string{os.Getenv("KAFKA_BROKERS")},
            Topic:   os.Getenv("KAFKA_TOPIC"),
        },
        Port: os.Getenv("SERVICE_PORT"),
    }
}

type Config struct {
    EventStoreDB eventstore.Config
    Kafka        kafka.Config
    Port         string
}
```

### 7. Dockerfile

```dockerfile
# Build stage
FROM golang:1.19-alpine AS builder

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main ./cmd/main.go

# Final stage
FROM alpine:latest

WORKDIR /root/

# Copy binary from build stage
COPY --from=builder /app/main .

# Expose port
EXPOSE 8080

# Run the application
CMD ["./main"]
```

## Работа с событиями

### 1. Определение событий

```go
// shared/events/events.go
package events

import "time"

type Event interface {
    GetAggregateID() string
    GetEventType() string
    GetTimestamp() time.Time
}

type UserRegistered struct {
    UserID    string
    Email     string
    Name      string
    Timestamp time.Time
}

func (e UserRegistered) GetAggregateID() string {
    return e.UserID
}

func (e UserRegistered) GetEventType() string {
    return "user_registered"
}

func (e UserRegistered) GetTimestamp() time.Time {
    return e.Timestamp
}

type DiaryEntryCreated struct {
    EntryID   string
    UserID    string
    Title     string
    Content   string
    Mood      string
    Timestamp time.Time
}

func (e DiaryEntryCreated) GetAggregateID() string {
    return e.EntryID
}

func (e DiaryEntryCreated) GetEventType() string {
    return "diary_entry_created"
}

func (e DiaryEntryCreated) GetTimestamp() time.Time {
    return e.Timestamp
}
```

### 2. Сериализация и десериализация событий

```go
// shared/events/serializer.go
package events

import (
    "bytes"
    "encoding/json"
    "fmt"
    "reflect"
)

type Serializer interface {
    Serialize(event Event) ([]byte, error)
    Deserialize(data []byte, eventType string) (Event, error)
}

type JSONSerializer struct{}

func NewJSONSerializer() *JSONSerializer {
    return &JSONSerializer{}
}

func (s *JSONSerializer) Serialize(event Event) ([]byte, error) {
    return json.Marshal(event)
}

func (s *JSONSerializer) Deserialize(data []byte, eventType string) (Event, error) {
    var event Event
    switch eventType {
    case "user_registered":
        event = &UserRegistered{}
    case "diary_entry_created":
        event = &DiaryEntryCreated{}
    default:
        return nil, fmt.Errorf("unknown event type: %s", eventType)
    }
    
    if err := json.Unmarshal(data, &event); err != nil {
        return nil, err
    }
    
    return event, nil
}
```

### 3. Работа с EventStoreDB

```go
// shared/eventstore/client.go
package eventstore

import (
    "context"
    "fmt"
    
    "github.com/EventStore/EventStore-Client-Go/esdb"
    
    "metachat/shared/events"
)

type Client struct {
    client       *esdb.Client
    serializer  events.Serializer
}

type Config struct {
    Host     string
    Port     string
    User     string
    Password string
}

func NewClient(cfg Config) (*Client, error) {
    connectionString := fmt.Sprintf("esdb://%s:%s@%s:%s?tls=false", cfg.User, cfg.Password, cfg.Host, cfg.Port)
    
    client, err := esdb.NewClient(connectionString)
    if err != nil {
        return nil, fmt.Errorf("failed to create EventStoreDB client: %w", err)
    }
    
    return &Client{
        client:      client,
        serializer: events.NewJSONSerializer(),
    }, nil
}

func (c *Client) AppendEvents(ctx context.Context, events []events.Event) error {
    if len(events) == 0 {
        return nil
    }
    
    aggregateID := events[0].GetAggregateID()
    streamID := esdb.StreamName(aggregateID)
    
    var eventData []esdb.EventData
    for _, event := range events {
        data, err := c.serializer.Serialize(event)
        if err != nil {
            return fmt.Errorf("failed to serialize event: %w", err)
        }
        
        eventData = append(eventData, esdb.EventData{
            EventType: event.GetEventType(),
            Data:      data,
        })
    }
    
    _, err := c.client.AppendToStream(ctx, streamID, esdb.AppendToStreamOptions{
        Events: eventData,
    })
    
    if err != nil {
        return fmt.Errorf("failed to append events to stream: %w", err)
    }
    
    return nil
}

func (c *Client) LoadEvents(ctx context.Context, aggregateID string) ([]events.Event, error) {
    streamID := esdb.StreamName(aggregateID)
    
    stream, err := c.client.ReadStream(ctx, streamID, esdb.ReadStreamOptions{
        Direction: esdb.Forwards,
        From:     esdb.StreamPositionStart,
    })
    
    if err != nil {
        return nil, fmt.Errorf("failed to read stream: %w", err)
    }
    defer stream.Close()
    
    var events []events.Event
    for {
        event, err := stream.Recv()
        if err != nil {
            break
        }
        
        deserializedEvent, err := c.serializer.Deserialize(event.Event.Data, string(event.Event.EventType))
        if err != nil {
            return nil, fmt.Errorf("failed to deserialize event: %w", err)
        }
        
        events = append(events, deserializedEvent)
    }
    
    return events, nil
}
```

## Работа с Kafka

### 1. Продюсер

```go
// shared/kafka/producer.go
package kafka

import (
    "context"
    "fmt"
    
    "github.com/confluentinc/confluent-kafka-go/kafka"
    
    "metachat/shared/events"
)

type Producer struct {
    producer   *kafka.Producer
    serializer events.Serializer
}

type Config struct {
    Brokers []string
    Topic   string
}

func NewProducer(cfg Config) (*Producer, error) {
    producer, err := kafka.NewProducer(&kafka.ConfigMap{
        "bootstrap.servers": cfg.Brokers[0],
    })
    
    if err != nil {
        return nil, fmt.Errorf("failed to create Kafka producer: %w", err)
    }
    
    return &Producer{
        producer:   producer,
        serializer: events.NewJSONSerializer(),
    }, nil
}

func (p *Producer) Publish(ctx context.Context, events []events.Event) error {
    for _, event := range events {
        data, err := p.serializer.Serialize(event)
        if err != nil {
            return fmt.Errorf("failed to serialize event: %w", err)
        }
        
        message := &kafka.Message{
            TopicPartition: kafka.TopicPartition{Topic: &p.topic, Partition: kafka.PartitionAny},
            Key:            []byte(event.GetAggregateID()),
            Value:          data,
            Headers: []kafka.Header{
                {
                    Key:   "event_type",
                    Value: []byte(event.GetEventType()),
                },
            },
        }
        
        deliveryChan := make(chan kafka.Event)
        err := p.producer.Produce(message, deliveryChan)
        if err != nil {
            return fmt.Errorf("failed to produce message: %w", err)
        }
        
        e := <-deliveryChan
        m := e.(*kafka.Message)
        
        if m.TopicPartition.Error != nil {
            return fmt.Errorf("delivery failed: %w", m.TopicPartition.Error)
        }
    }
    
    return nil
}

func (p *Producer) Close() {
    p.producer.Flush(15 * 1000)
    p.producer.Close()
}
```

### 2. Консьюмер

```go
// shared/kafka/consumer.go
package kafka

import (
    "context"
    "fmt"
    "log"
    
    "github.com/confluentinc/confluent-kafka-go/kafka"
    
    "metachat/shared/events"
)

type Consumer struct {
    consumer   *kafka.Consumer
    handler    EventHandler
    serializer events.Serializer
}

type EventHandler interface {
    Handle(ctx context.Context, event events.Event) error
}

func NewConsumer(cfg Config, handler EventHandler) (*Consumer, error) {
    consumer, err := kafka.NewConsumer(&kafka.ConfigMap{
        "bootstrap.servers": cfg.Brokers[0],
        "group.id":          "metachat-group",
        "auto.offset.reset": "earliest",
    })
    
    if err != nil {
        return nil, fmt.Errorf("failed to create Kafka consumer: %w", err)
    }
    
    return &Consumer{
        consumer:   consumer,
        handler:    handler,
        serializer: events.NewJSONSerializer(),
    }, nil
}

func (c *Consumer) Consume(ctx context.Context, topics []string) error {
    err := c.consumer.SubscribeTopics(topics, nil)
    if err != nil {
        return fmt.Errorf("failed to subscribe to topics: %w", err)
    }
    
    run := true
    for run {
        select {
        case <-ctx.Done():
            run = false
        default:
            msg, err := c.consumer.ReadMessage(100)
            if err != nil {
                // Временные ошибки, такие как таймаут, можно игнорировать
                if err.(kafka.Error).Code() == kafka.ErrTimedOut {
                    continue
                }
                return fmt.Errorf("failed to read message: %w", err)
            }
            
            // Получение типа события из заголовков
            var eventType string
            for _, header := range msg.Headers {
                if header.Key == "event_type" {
                    eventType = string(header.Value)
                    break
                }
            }
            
            // Десериализация события
            event, err := c.serializer.Deserialize(msg.Value, eventType)
            if err != nil {
                log.Printf("Failed to deserialize event: %v", err)
                continue
            }
            
            // Обработка события
            if err := c.handler.Handle(ctx, event); err != nil {
                log.Printf("Failed to handle event: %v", err)
            }
        }
    }
    
    c.consumer.Close()
    return nil
}
```

## Тестирование

### 1. Юнит-тесты

```go
// internal/service/service_test.go
package service

import (
    "context"
    "testing"
    
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"
    
    "metachat/new-service/internal/model"
    "metachat/new-service/internal/repository"
)

type MockRepository struct {
    mock.Mock
}

func (m *MockRepository) Save(ctx context.Context, events []model.Event) error {
    args := m.Called(ctx, events)
    return args.Error(0)
}

func (m *MockRepository) Load(ctx context.Context, id string) ([]model.Event, error) {
    args := m.Called(ctx, id)
    return args.Get(0).([]model.Event), args.Error(1)
}

func TestService_CreateEntity(t *testing.T) {
    // Создание мока репозитория
    mockRepo := new(MockRepository)
    
    // Настройка ожиданий
    mockRepo.On("Save", mock.Anything, mock.Anything).Return(nil)
    
    // Создание сервиса с моком
    service := NewService(mockRepo, nil)
    
    // Вызов тестируемого метода
    cmd := CreateEntityCommand{
        ID: "test-id",
    }
    
    entity, err := service.CreateEntity(context.Background(), cmd)
    
    // Проверка результатов
    assert.NoError(t, err)
    assert.NotNil(t, entity)
    assert.Equal(t, "test-id", entity.ID)
    
    // Проверка вызовов мока
    mockRepo.AssertExpectations(t)
}
```

### 2. Интеграционные тесты

```go
// tests/integration/service_test.go
package integration

import (
    "context"
    "testing"
    "time"
    
    "github.com/stretchr/testify/assert"
    "github.com/testcontainers/testcontainers-go"
    "github.com/testcontainers/testcontainers-go/modules/eventstoredb"
    
    "metachat/new-service/internal/model"
    "metachat/new-service/internal/repository"
    "metachat/new-service/internal/service"
)

func TestService_CreateEntity_Integration(t *testing.T) {
    // Запуск EventStoreDB в контейнере
    ctx := context.Background()
    eventstoreContainer, err := eventstoredb.RunContainer(ctx, testcontainers.WithImage("eventstore/eventstore:latest"))
    if err != nil {
        t.Fatalf("Failed to start EventStoreDB container: %v", err)
    }
    defer eventstoreContainer.Terminate(ctx)
    
    // Получение строки подключения
    connectionString, err := eventstoreContainer.ConnectionString(ctx)
    if err != nil {
        t.Fatalf("Failed to get connection string: %v", err)
    }
    
    // Создание клиента EventStoreDB
    eventStoreClient, err := eventstore.NewClient(eventstore.Config{
        Host:     eventstoreContainer.Host,
        Port:     eventstoreContainer.MappedPort(ctx, "2113/tcp"),
        User:     "admin",
        Password: "changeit",
    })
    if err != nil {
        t.Fatalf("Failed to create EventStoreDB client: %v", err)
    }
    
    // Создание репозитория
    repo := repository.NewEventStoreRepository(eventStoreClient)
    
    // Создание сервиса
    svc := service.NewService(repo, nil)
    
    // Вызов тестируемого метода
    cmd := service.CreateEntityCommand{
        ID: "test-id",
    }
    
    entity, err := svc.CreateEntity(ctx, cmd)
    
    // Проверка результатов
    assert.NoError(t, err)
    assert.NotNil(t, entity)
    assert.Equal(t, "test-id", entity.ID)
    
    // Проверка, что событие было сохранено в EventStoreDB
    events, err := repo.Load(ctx, "test-id")
    assert.NoError(t, err)
    assert.Len(t, events, 1)
    assert.Equal(t, "entity_created", events[0].GetEventType())
}
```

## Рекомендации по разработке

### 1. Кодирование
- Следуйте стандартам кодирования Go (gofmt, govet, golint)
- Используйте интерфейсы для определения контрактов между компонентами
- Избегайте глобальных переменных и состояний
- Обрабатывайте ошибки явно и не игнорируйте их

### 2. Тестирование
- Пишите тесты для всего нового кода
- Стремитесь к покрытию кода тестами не менее 80%
- Используйте моки для изоляции зависимостей в юнит-тестах
- Пишите интеграционные тесты для проверки взаимодействия между компонентами

### 3. Документация
- Документируйте все публичные API и функции
- Используйте примеры кода в документации
- Обновляйте документацию при изменении кода

### 4. Версионирование
- Используйте семантическое версионирование (SemVer)
- Следуйте принципам совместимости версий
- Используйте теги Git для маркировки релизов

### 5. CI/CD
- Настраивайте автоматическую сборку и тестирование при каждом коммите
- Используйте автоматическое развертывание для тестовых сред
- Проводите ручное тестирование перед развертыванием в продакшн

## Заключение

Это руководство охватывает основные аспекты разработки для проекта MetaChat. Если у вас есть дополнительные вопросы или предложения по улучшению, пожалуйста, создайте issue или pull request в репозитории проекта.