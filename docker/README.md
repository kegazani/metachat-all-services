# MetaChat Docker Deployment

Полная система деплоя MetaChat с использованием Docker и Docker Compose.

## 🎯 Основные скрипты

### ✅ Полный деплой (РЕКОМЕНДУЕТСЯ)

Запускает всё с нуля: сборка образов, инфраструктура, сервисы, мониторинг.

**Linux/Mac:**
```bash
./deploy-full.sh
```

**Windows:**
```powershell
.\deploy-full.ps1
```

### 🛑 Остановка всех сервисов

**Linux/Mac:**
```bash
./stop-all.sh
```

**Windows:**
```powershell
.\stop-all.ps1
```

### 🔨 Только сборка образов

**Linux/Mac:**
```bash
./build-images.sh
```

**Windows:**
```powershell
.\build-images.ps1
```

### 🚀 Деплой без сборки

Если образы уже собраны:

**Linux/Mac:**
```bash
./deploy-local.sh
```

**Windows:**
```powershell
.\deploy-local.ps1
```

## 📁 Структура файлов

```
docker/
├── deploy-full.sh          # Полный деплой для Linux/Mac
├── deploy-full.ps1         # Полный деплой для Windows
├── stop-all.sh             # Остановка всех сервисов (Linux/Mac)
├── stop-all.ps1            # Остановка всех сервисов (Windows)
├── build-images.sh         # Сборка образов (Linux/Mac)
├── deploy-local.sh         # Деплой готовых образов
│
├── docker-compose.infrastructure.yml   # Инфраструктурные сервисы
├── docker-compose.services.yml         # Приложения
│
├── cassandra-init.cql      # Инициализация Cassandra
├── postgres-init.sql       # Инициализация PostgreSQL
├── kafka-topics-config.yaml # Конфигурация топиков Kafka
│
└── monitoring/             # Конфигурация мониторинга
    ├── prometheus.yml
    ├── loki-config.yaml
    ├── promtail-config.yaml
    └── grafana/
```

## 🐳 Docker Compose файлы

### docker-compose.infrastructure.yml

Инфраструктурные сервисы:
- **Zookeeper** - координация Kafka
- **Kafka** + Kafka UI - брокер сообщений
- **Cassandra** - NoSQL база данных
- **PostgreSQL** - реляционная БД
- **EventStore** - event sourcing
- **NATS** - lightweight messaging
- **Prometheus** - метрики
- **Grafana** - дашборды
- **Loki** - логи
- **Promtail** - сборщик логов

### docker-compose.services.yml

Микросервисы приложения:
- **api-gateway** - точка входа API
- **user-service** - управление пользователями
- **diary-service** - дневник
- **matching-service** - подбор пар
- **match-request-service** - запросы на матчинг
- **chat-service** - чат
- **mood-analysis-service** - анализ настроения
- **analytics-service** - аналитика
- **archetype-service** - психологические архетипы
- **biometric-service** - биометрические данные
- **correlation-service** - корреляции

## 🔧 Управление сервисами

### Просмотр логов

Все логи инфраструктуры:
```bash
docker compose -f docker-compose.infrastructure.yml logs -f
```

Все логи приложений:
```bash
docker compose -f docker-compose.services.yml logs -f
```

Конкретный сервис:
```bash
docker compose -f docker-compose.services.yml logs -f api-gateway
```

### Статус сервисов

```bash
docker compose -f docker-compose.infrastructure.yml ps
docker compose -f docker-compose.services.yml ps
```

### Перезапуск сервиса

```bash
docker compose -f docker-compose.services.yml restart user-service
```

### Остановка конкретного сервиса

```bash
docker compose -f docker-compose.services.yml stop user-service
```

### Запуск конкретного сервиса

```bash
docker compose -f docker-compose.services.yml start user-service
```

## 🌐 Порты и доступ

### Приложение
- **8080** - API Gateway

### Инфраструктура
- **9092** - Kafka (внешний)
- **29092** - Kafka (внутренний)
- **2181** - Zookeeper
- **8090** - Kafka UI
- **9042** - Cassandra
- **5432** - PostgreSQL
- **2113** - EventStore HTTP
- **1113** - EventStore TCP
- **4222** - NATS
- **8222** - NATS Monitoring

### Мониторинг
- **3000** - Grafana (admin/metachat2024)
- **9090** - Prometheus
- **3100** - Loki

### Сервисы (для отладки)
- **50051** - User Service gRPC
- **50052** - Diary Service gRPC
- **50053** - Matching Service gRPC
- **50054** - Match Request Service
- **50055** - Chat Service
- **8000** - Mood Analysis Service HTTP
- **8001** - Analytics Service HTTP
- **8002** - Archetype Service HTTP
- **8003** - Biometric Service HTTP
- **8004** - Correlation Service HTTP

## 💾 Подключение к базам данных

### Cassandra

```bash
docker exec -it cassandra cqlsh

USE metachat;
DESCRIBE TABLES;
SELECT * FROM users LIMIT 10;
```

### PostgreSQL

```bash
docker exec -it postgres psql -U metachat -d metachat

\dt
\d+ users
SELECT * FROM users LIMIT 10;
```

### Kafka Topics

```bash
docker exec kafka kafka-topics --bootstrap-server localhost:29092 --list

docker exec kafka kafka-console-consumer \
  --bootstrap-server localhost:29092 \
  --topic metachat.user.events \
  --from-beginning
```

## 🔄 Полная очистка

Удалить все контейнеры, сети и volume:

```bash
docker compose -f docker-compose.infrastructure.yml down -v
docker compose -f docker-compose.services.yml down -v
docker network prune -f
docker volume prune -f
docker system prune -a -f
```

**⚠️ ВНИМАНИЕ: Это удалит ВСЕ данные!**

## 📊 Мониторинг

### Grafana

URL: http://localhost:3000
- Логин: `admin`
- Пароль: `metachat2024`

Дашборды предустановлены:
- MetaChat Services Overview
- Kafka Monitoring
- Database Performance
- System Resources

### Prometheus

URL: http://localhost:9090

Примеры запросов:
```promql
rate(http_requests_total[5m])
container_memory_usage_bytes
kafka_server_brokertopicmetrics_messagesin_total
```

### Kafka UI

URL: http://localhost:8090

Позволяет:
- Просматривать топики
- Читать сообщения
- Управлять consumer groups
- Мониторить брокеры

## 🐛 Отладка

### Проверка health-check

```bash
curl http://localhost:8080/health
```

### Проверка готовности инфраструктуры

Kafka:
```bash
docker exec kafka kafka-broker-api-versions --bootstrap-server localhost:29092
```

Cassandra:
```bash
docker exec cassandra cqlsh -e "SELECT release_version FROM system.local;"
```

PostgreSQL:
```bash
docker exec postgres pg_isready -U metachat
```

EventStore:
```bash
curl http://localhost:2113/health/live
```

### Проверка сети

```bash
docker network inspect metachat_network
```

### Использование ресурсов

```bash
docker stats
```

## 📝 Переменные окружения

Основные переменные можно переопределить через `.env` файл:

```env
CASSANDRA_HOSTS=cassandra:9042
KAFKA_BOOTSTRAP_SERVERS=kafka:29092
POSTGRES_USER=metachat
POSTGRES_PASSWORD=metachat_password
```

## 🔐 Безопасность

**Для продакшн окружения:**
1. Измените все пароли по умолчанию
2. Настройте SSL/TLS для всех сервисов
3. Ограничьте доступ к портам через firewall
4. Используйте Docker secrets для чувствительных данных
5. Настройте аутентификацию для Kafka и EventStore

## ⚡ Оптимизация производительности

### Для разработки (ограниченные ресурсы)

Закомментируйте в docker-compose файлах неиспользуемые сервисы:
- Biometric Service
- Correlation Service
- Analytics Service

### Для продакшна

1. Увеличьте лимиты ресурсов в deploy секциях
2. Настройте репликацию для Kafka и Cassandra
3. Используйте внешние managed базы данных
4. Настройте автоскейлинг

## 📚 Дополнительные ресурсы

- [Quick Start Guide](../QUICK_START.md)
- [Architecture Documentation](../docs/ARCHITECTURE.md)
- [API Documentation](../docs/API.md)
- [Troubleshooting Guide](../docs/TROUBLESHOOTING.md)

