# MetaChat Deployment Guide

## Быстрый старт

### Полный деплой (сборка + развёртывание + инициализация БД)

```bash
cd docker
./deploy-full.sh
```

Этот скрипт выполнит:
1. Сборку всех Docker-образов (Python и Go сервисы)
2. Развёртывание в Docker Swarm
3. Создание keyspace в Cassandra
4. Создание баз данных в PostgreSQL

---

## Пошаговый деплой

### 1. Сборка образов

#### Собрать все сервисы
```bash
cd docker
./build-all.sh
```

#### Собрать только Python сервисы
```bash
cd docker
./build-python.sh
```

#### Собрать только Go сервисы
```bash
cd docker
./build-go.sh
```

### 2. Развёртывание

```bash
cd docker
./deploy.sh
```

Этот скрипт:
- Инициализирует Docker Swarm (если не инициализирован)
- Создаст overlay сеть `metachat_network`
- Развернёт все сервисы из `docker-stack.yml`

### 3. Инициализация баз данных

#### Cassandra - создать keyspace
```bash
CASSANDRA_CONTAINER=$(docker ps --filter "name=metachat_cassandra" --format "{{.Names}}" | head -1)
docker exec $CASSANDRA_CONTAINER cqlsh -e "CREATE KEYSPACE IF NOT EXISTS metachat WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};"
```

#### PostgreSQL - создать базы данных
```bash
POSTGRES_CONTAINER=$(docker ps --filter "name=metachat_postgres" --format "{{.Names}}" | head -1)
docker exec $POSTGRES_CONTAINER psql -U metachat -d postgres -c "CREATE DATABASE metachat_mood;"
docker exec $POSTGRES_CONTAINER psql -U metachat -d postgres -c "CREATE DATABASE metachat_analytics;"
docker exec $POSTGRES_CONTAINER psql -U metachat -d postgres -c "CREATE DATABASE metachat_personality;"
docker exec $POSTGRES_CONTAINER psql -U metachat -d postgres -c "CREATE DATABASE metachat_biometric;"
docker exec $POSTGRES_CONTAINER psql -U metachat -d postgres -c "CREATE DATABASE metachat_correlation;"
```

---

## Управление

### Проверить статус сервисов
```bash
docker service ls
```

### Посмотреть логи сервиса
```bash
docker service logs metachat_<service-name> --tail 100 -f
```

Например:
```bash
docker service logs metachat_mood-analysis-service --tail 100 -f
docker service logs metachat_user-service --tail 100 -f
```

### Обновить сервис после пересборки образа
```bash
docker service update --image metachat/<service-name>:latest metachat_<service-name> --force
```

### Масштабировать сервис
```bash
docker service scale metachat_<service-name>=3
```

### Удалить весь stack
```bash
docker stack rm metachat
```

### Удалить сеть
```bash
docker network rm metachat_network
```

---

## Доступ к сервисам

| Сервис | URL | Логин/Пароль |
|--------|-----|--------------|
| API Gateway | http://localhost:8080 | - |
| Grafana | http://localhost:3000 | admin/metachat2024 |
| Kafka UI | http://localhost:8090 | - |
| Prometheus | http://localhost:9090 | - |
| PostgreSQL | localhost:5432 | metachat/metachat_password |
| Cassandra | localhost:9042 | - |
| EventStore | http://localhost:2113 | admin/changeit |

---

## Архитектура

### Инфраструктура
- **PostgreSQL** - реляционная БД для mood-analysis, analytics, archetype, biometric, correlation сервисов
- **Cassandra** - NoSQL БД для user, diary, matching сервисов
- **Kafka + Zookeeper** - шина сообщений для событий
- **EventStore** - хранилище событий (event sourcing)
- **Prometheus + Grafana** - мониторинг
- **Kafka UI** - веб-интерфейс для Kafka

### Python сервисы (порты 8000-8004, 50056-50058)
- **mood-analysis-service** - анализ настроения из записей дневника
- **analytics-service** - аналитика и агрегация данных
- **archetype-service** - определение психологических архетипов
- **biometric-service** - обработка биометрических данных
- **correlation-service** - корреляция между настроением и биометрикой

### Go сервисы (порты 8080-8081, 50051-50055)
- **api-gateway** - основной API gateway
- **user-service** - управление пользователями
- **diary-service** - сервис дневника
- **matching-service** - алгоритмы подбора пар
- **match-request-service** - обработка запросов на совпадения
- **chat-service** - чат между пользователями

---

## Troubleshooting

### Сервис не запускается (0/1 replicas)
```bash
# Посмотреть детали задач
docker service ps metachat_<service-name> --no-trunc

# Посмотреть логи
docker service logs metachat_<service-name> --tail 100
```

### Проблемы с подключением к БД

#### PostgreSQL
```bash
# Проверить что PostgreSQL запущен
docker service ps metachat_postgres

# Проверить логи PostgreSQL
docker service logs metachat_postgres --tail 50

# Проверить что базы созданы
POSTGRES_CONTAINER=$(docker ps --filter "name=metachat_postgres" --format "{{.Names}}" | head -1)
docker exec $POSTGRES_CONTAINER psql -U metachat -d postgres -c "\l"
```

#### Cassandra
```bash
# Проверить что Cassandra запущена
docker service ps metachat_cassandra

# Проверить keyspace
CASSANDRA_CONTAINER=$(docker ps --filter "name=metachat_cassandra" --format "{{.Names}}" | head -1)
docker exec $CASSANDRA_CONTAINER cqlsh -e "DESCRIBE KEYSPACES;"
```

#### Kafka
```bash
# Проверить что Kafka запущена
docker service ps metachat_kafka
docker service ps metachat_zookeeper

# Посмотреть топики
docker exec $(docker ps --filter "name=metachat_kafka" --format "{{.Names}}" | head -1) \
  kafka-topics --bootstrap-server localhost:9092 --list
```

### Пересобрать и обновить конкретный сервис

#### Python сервис
```bash
cd metachat-all-services
docker build -t metachat/mood-analysis-service:latest \
  -f metachat-mood-analysis-service/Dockerfile .
docker service update --image metachat/mood-analysis-service:latest \
  metachat_mood-analysis-service --force
```

#### Go сервис
```bash
cd metachat-all-services
docker build -t metachat/user-service:latest \
  -f ../docker/Dockerfile.go-service \
  --build-arg SERVICE_DIR=metachat-user-service .
docker service update --image metachat/user-service:latest \
  metachat_user-service --force
```

---

## Требования

- Docker 20.10+
- Docker Compose 1.29+ (для локальной разработки)
- Docker Swarm (для production)
- Минимум 8GB RAM
- Минимум 20GB свободного места на диске

---

## Разработка

### Запуск в режиме разработки (docker-compose)

Для локальной разработки можно использовать docker-compose вместо Swarm:

```bash
# Только инфраструктура
docker-compose -f docker/docker-compose.infrastructure.yml up -d

# Инфраструктура + сервисы
docker-compose -f docker/docker-compose.infrastructure.yml \
               -f docker/docker-compose.services.yml up -d
```

### Остановка
```bash
docker-compose -f docker/docker-compose.infrastructure.yml \
               -f docker/docker-compose.services.yml down
```
