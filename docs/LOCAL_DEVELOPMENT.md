# Локальная разработка MetaChat

Это руководство описывает настройку окружения для локальной разработки MetaChat.

## 🎯 Два режима разработки

### 1. Полный Docker деплой (Рекомендуется)

Все сервисы и инфраструктура запущены в Docker.

**Преимущества:**
- Простая настройка
- Изолированное окружение
- Близко к продакшн окружению
- Не нужно настраивать базы данных

**Запуск:**
```bash
cd docker
./deploy-full.sh         # Linux/Mac
.\deploy-full.ps1        # Windows
```

### 2. Гибридный режим (Advanced)

Инфраструктура в Docker, один или несколько сервисов запущены локально для отладки.

**Преимущества:**
- Быстрая перекомпиляция
- Прямая отладка в IDE
- Горячая перезагрузка

**Настройка:** см. раздел "Гибридный режим" ниже

## 🚀 Быстрый старт (Full Docker)

### 1. Клонирование репозитория

```bash
git clone <repository-url>
cd metachat
```

### 2. Запуск всех сервисов

```bash
cd docker
./deploy-full.sh         # Linux/Mac
.\deploy-full.ps1        # Windows
```

### 3. Проверка

Откройте в браузере:
- API Gateway: http://localhost:8080
- Grafana: http://localhost:3000 (admin/metachat2024)
- Kafka UI: http://localhost:8090

### 4. Просмотр логов

```bash
./logs.sh all            # Все логи
./logs.sh api-gateway    # Конкретный сервис
```

## 🔧 Гибридный режим разработки

### Настройка

#### Шаг 1: Запустите инфраструктуру

```bash
cd docker
docker compose -f docker-compose.infrastructure.yml up -d
```

Это запустит:
- Zookeeper, Kafka
- Cassandra
- PostgreSQL
- EventStore
- NATS
- Prometheus, Grafana, Loki

#### Шаг 2: Дождитесь готовности инфраструктуры

```bash
# Проверка Kafka
docker exec kafka kafka-broker-api-versions --bootstrap-server localhost:29092

# Проверка Cassandra
docker exec cassandra cqlsh -e "DESCRIBE KEYSPACE metachat;"

# Проверка PostgreSQL
docker exec postgres pg_isready -U metachat
```

#### Шаг 3: Инициализация данных

```bash
# Создание Kafka топиков
docker compose -f docker-compose.infrastructure.yml up -d kafka-topics-init

# Инициализация Cassandra
docker compose -f docker-compose.infrastructure.yml up -d cassandra-init
```

#### Шаг 4: Настройте сервисы, которые хотите запустить в Docker

Например, запустите все сервисы кроме того, который разрабатываете:

  ```bash
# Запустить все сервисы
docker compose -f docker-compose.services.yml up -d

# Остановить сервис для локальной разработки
docker compose -f docker-compose.services.yml stop user-service
  ```

### Запуск Go сервиса локально

#### User Service (Go)

```bash
cd metachat-all-services/metachat-user-service

# Установка зависимостей
go mod download

# Настройка переменных окружения
export CASSANDRA_HOSTS=localhost:9042
export CASSANDRA_KEYSPACE=metachat
export KAFKA_BOOTSTRAP_SERVERS=localhost:9092
export EVENT_STORE_URL=http://localhost:2113
export GRPC_PORT=50051
export SERVER_PORT=8080

# Запуск
go run cmd/main.go
```

#### Diary Service (Go)

```bash
cd metachat-all-services/metachat-diary-service

export CASSANDRA_HOSTS=localhost:9042
export CASSANDRA_KEYSPACE=metachat
export KAFKA_BOOTSTRAP_SERVERS=localhost:9092
export EVENT_STORE_URL=http://localhost:2113
export GRPC_PORT=50052
export SERVER_PORT=8080

go run cmd/main.go
```

#### API Gateway (Go)

```bash
cd metachat-all-services/metachat-api-gateway

export SERVICES_USER_SERVICE_ADDRESS=localhost:50051
export SERVICES_DIARY_SERVICE_ADDRESS=localhost:50052
export SERVICES_MATCHING_SERVICE_ADDRESS=localhost:50053
export SERVICES_MATCH_REQUEST_SERVICE_ADDRESS=localhost:50054
export SERVICES_CHAT_SERVICE_ADDRESS=localhost:50055
export SERVER_PORT=8080

go run cmd/main.go
```

### Запуск Python сервиса локально

#### Mood Analysis Service (Python)

```bash
cd metachat-all-services/metachat-mood-analysis-service

# Создание виртуального окружения
python -m venv venv
source venv/bin/activate  # Linux/Mac
.\venv\Scripts\activate   # Windows

# Установка зависимостей
pip install -r requirements.txt

# Настройка переменных окружения
export KAFKA_BOOTSTRAP_SERVERS=localhost:9092
export CASSANDRA_HOSTS=localhost:9042
export CASSANDRA_KEYSPACE=metachat
export SERVER_PORT=8000
export GRPC_PORT=50056

# Запуск
python src/main.py
```

#### Analytics Service (Python)

```bash
cd metachat-all-services/metachat-analytics-service

python -m venv venv
source venv/bin/activate

pip install -r requirements.txt

export KAFKA_BOOTSTRAP_SERVERS=localhost:9092
export CASSANDRA_HOSTS=localhost:9042
export CASSANDRA_KEYSPACE=metachat
export SERVER_PORT=8000
export GRPC_PORT=50057

python src/main.py
```

## 🔌 Подключение к инфраструктуре

### Переменные окружения

Используйте следующие адреса при локальном запуске:

```bash
# Kafka
KAFKA_BOOTSTRAP_SERVERS=localhost:9092

# Cassandra
CASSANDRA_HOSTS=localhost:9042
CASSANDRA_KEYSPACE=metachat

# PostgreSQL
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USER=metachat
DATABASE_PASSWORD=metachat_password
DATABASE_NAME=metachat

# EventStore
EVENT_STORE_URL=http://localhost:2113
EVENT_STORE_USERNAME=admin
EVENT_STORE_PASSWORD=changeit

# NATS
NATS_URL=nats://localhost:4222
```

### Проверка подключения

**Kafka:**
```bash
# Список топиков
docker exec kafka kafka-topics --bootstrap-server localhost:29092 --list

# Отправка тестового сообщения
docker exec -it kafka kafka-console-producer \
  --bootstrap-server localhost:29092 \
  --topic test-topic

# Чтение сообщений
docker exec kafka kafka-console-consumer \
  --bootstrap-server localhost:29092 \
  --topic metachat.user.events \
  --from-beginning
```

**Cassandra:**
```bash
docker exec -it cassandra cqlsh

USE metachat;
DESCRIBE TABLES;
SELECT * FROM users LIMIT 10;
```

**PostgreSQL:**
```bash
docker exec -it postgres psql -U metachat -d metachat

\dt
\d+ users
SELECT * FROM users;
```

**EventStore:**
```bash
curl http://localhost:2113/health/live
```

## 🛠️ IDE настройка

### Visual Studio Code

#### Go сервисы

1. Установите расширение "Go"
2. Создайте `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Launch User Service",
      "type": "go",
      "request": "launch",
      "mode": "auto",
      "program": "${workspaceFolder}/metachat-all-services/metachat-user-service/cmd/main.go",
      "env": {
        "CASSANDRA_HOSTS": "localhost:9042",
        "CASSANDRA_KEYSPACE": "metachat",
        "KAFKA_BOOTSTRAP_SERVERS": "localhost:9092",
        "EVENT_STORE_URL": "http://localhost:2113",
        "GRPC_PORT": "50051",
        "SERVER_PORT": "8080"
      }
    }
  ]
}
```

#### Python сервисы

1. Установите расширение "Python"
2. Создайте `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Launch Mood Analysis Service",
      "type": "python",
      "request": "launch",
      "program": "${workspaceFolder}/metachat-all-services/metachat-mood-analysis-service/src/main.py",
      "console": "integratedTerminal",
      "env": {
        "KAFKA_BOOTSTRAP_SERVERS": "localhost:9092",
        "CASSANDRA_HOSTS": "localhost:9042",
        "CASSANDRA_KEYSPACE": "metachat",
        "SERVER_PORT": "8000",
        "GRPC_PORT": "50056"
      }
    }
  ]
}
```

### GoLand / IntelliJ IDEA

1. Откройте проект
2. Run → Edit Configurations
3. Добавьте Go Build Configuration
4. Установите Environment variables
5. Укажите Working directory

### PyCharm

1. Откройте проект
2. Создайте Python configuration
3. Установите Environment variables
4. Выберите Python interpreter (venv)

## 📝 Работа с протобуф файлами

### Генерация Go кода

```bash
cd metachat-all-services/metachat-proto

# Linux/Mac
./generate.sh

# Windows
.\generate.ps1
```

### Генерация Python кода

```bash
python -m grpc_tools.protoc \
  -I. \
  --python_out=. \
  --grpc_python_out=. \
  *.proto
```

## 🧪 Тестирование

### Unit тесты

**Go:**
```bash
cd metachat-all-services/metachat-user-service
go test ./...
```

**Python:**
```bash
cd metachat-all-services/metachat-mood-analysis-service
pytest tests/
```

### Integration тесты

Убедитесь, что инфраструктура запущена:
```bash
cd docker
docker compose -f docker-compose.infrastructure.yml ps
```

Запустите тесты:
```bash
go test -tags=integration ./tests/integration/
```

### API тесты

Используйте Postman коллекцию:
- Импортируйте `MetaChat_API.postman_collection.json`
- Установите environment variable: `base_url = http://localhost:8080`

## 🔄 Hot reload

### Go - Air

```bash
# Установка
go install github.com/cosmtrek/air@latest

# Запуск с hot reload
cd metachat-all-services/metachat-user-service
air
```

### Python - watchdog

```bash
pip install watchdog

watchmedo auto-restart \
  --directory=./src \
  --pattern=*.py \
  --recursive \
  -- python src/main.py
```

## 🐛 Отладка

### Проблемы с подключением

Если сервис не может подключиться к инфраструктуре:

1. Проверьте, что инфраструктура запущена:
```bash
docker compose -f docker-compose.infrastructure.yml ps
```

2. Проверьте логи:
```bash
docker compose -f docker-compose.infrastructure.yml logs kafka
docker compose -f docker-compose.infrastructure.yml logs cassandra
```

3. Проверьте сеть:
```bash
docker network inspect metachat_network
```

### Проблемы с портами

Убедитесь, что порты не заняты:
```bash
netstat -tulpn | grep -E '9092|9042|5432|2113'
```

### Очистка данных

Для начала с чистого листа:
```bash
cd docker
docker compose -f docker-compose.infrastructure.yml down -v
docker compose -f docker-compose.services.yml down -v
./deploy-full.sh
```

## 📚 Полезные команды

### Docker

```bash
# Перезапуск инфраструктуры
docker compose -f docker-compose.infrastructure.yml restart

# Просмотр логов
docker compose -f docker-compose.infrastructure.yml logs -f kafka

# Очистка
docker system prune -a
docker volume prune
```

### Kafka

```bash
# Создание топика
docker exec kafka kafka-topics --create \
  --bootstrap-server localhost:29092 \
  --topic test-topic \
  --partitions 3 \
  --replication-factor 1

# Удаление топика
docker exec kafka kafka-topics --delete \
  --bootstrap-server localhost:29092 \
  --topic test-topic
```

### Cassandra

```bash
# Пересоздание keyspace
docker exec -it cassandra cqlsh -e "DROP KEYSPACE IF EXISTS metachat;"
docker compose -f docker-compose.infrastructure.yml up -d cassandra-init
```

### PostgreSQL

```bash
# Пересоздание базы
docker exec -it postgres psql -U postgres -c "DROP DATABASE IF EXISTS metachat;"
docker exec -it postgres psql -U postgres -c "CREATE DATABASE metachat;"
docker exec -it postgres psql -U postgres -d metachat -f /docker-entrypoint-initdb.d/init.sql
```

## 🎓 Лучшие практики

1. **Всегда запускайте инфраструктуру первой** перед локальными сервисами
2. **Используйте переменные окружения** вместо хардкода конфигурации
3. **Проверяйте логи** при возникновении проблем
4. **Пишите тесты** для нового функционала
5. **Используйте hot reload** для ускорения разработки
6. **Делайте коммиты часто** с понятными сообщениями

## 📖 Дополнительная документация

- [Deployment Guide](DEPLOYMENT.md)
- [Architecture](ARCHITECTURE.md)
- [Service Flow](DETAILED_SERVICE_FLOW.md)
- [Quick Start](../QUICK_START.md)
