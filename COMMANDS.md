# MetaChat - Quick Commands Reference

Шпаргалка по всем командам MetaChat.

## 🐳 Docker Compose (Разработка)

### Деплой

```bash
cd docker

./deploy-full.sh              # Полный деплой
./deploy-full.sh --swarm      # Использовать Swarm mode
```

### Управление

```bash
./stop-all.sh                 # Остановить всё
./status.sh                   # Статус и URLs
./logs.sh all                 # Все логи
./logs.sh infra               # Логи инфраструктуры
./logs.sh services            # Логи сервисов
./logs.sh api-gateway         # Конкретный сервис
```

### Docker Compose напрямую

```bash
# Инфраструктура
docker compose -f docker-compose.infrastructure.yml up -d
docker compose -f docker-compose.infrastructure.yml down
docker compose -f docker-compose.infrastructure.yml ps
docker compose -f docker-compose.infrastructure.yml logs -f kafka

# Сервисы
docker compose -f docker-compose.services.yml up -d
docker compose -f docker-compose.services.yml down
docker compose -f docker-compose.services.yml restart user-service
```

---

## 🐝 Docker Swarm (Продакшн)

### Первый деплой

```bash
cd docker
chmod +x *.sh
./deploy-swarm.sh
```

### Редеплой (обновление)

```bash
./redeploy-swarm.sh all                    # Всё
./redeploy-swarm.sh infra                  # Инфраструктура
./redeploy-swarm.sh services               # Сервисы приложения
./redeploy-swarm.sh kafka                  # Конкретный сервис
./redeploy-swarm.sh mood-analysis-service  # Python сервис
```

### Остановка

```bash
./stop-swarm.sh all            # Остановить всё
./stop-swarm.sh services       # Только сервисы
./stop-swarm.sh infra          # Только инфраструктуру
./stop-swarm.sh clean          # Полная очистка (+ volumes!)
```

### Статус и мониторинг

```bash
./status-swarm.sh              # Статус и URLs
docker service ls              # Список сервисов
docker stack ls                # Список стеков
docker node ls                 # Ноды кластера
```

### Логи

```bash
./logs-swarm.sh kafka                  # Логи Kafka
./logs-swarm.sh mood-analysis-service  # Логи Python сервиса
./logs-swarm.sh kafka -f               # Follow mode
./logs-swarm.sh grafana --tail 100     # Последние 100 строк
```

### Масштабирование

```bash
docker service scale metachat-services_mood-analysis-service=3
docker service scale metachat-infra_kafka=1
```

### Swarm команды напрямую

```bash
# Стеки
docker stack deploy -c docker-compose.swarm.yml metachat-infra
docker stack rm metachat-infra

# Сервисы
docker service ls
docker service ps metachat-infra_kafka
docker service logs -f metachat-infra_kafka
docker service update --force metachat-services_api-gateway

# Swarm
docker swarm init
docker swarm leave --force
docker node ls
```

---

## 🗄️ Базы данных

### Cassandra

```bash
# Подключение
docker exec -it cassandra cqlsh

# Команды в cqlsh
USE metachat;
DESCRIBE TABLES;
SELECT * FROM users LIMIT 10;

# Из командной строки
docker exec cassandra cqlsh -e "USE metachat; DESCRIBE TABLES;"
docker exec cassandra nodetool status
```

### PostgreSQL

```bash
# Подключение
docker exec -it postgres psql -U metachat -d metachat

# Команды в psql
\dt
\d+ users
SELECT * FROM users LIMIT 10;

# Из командной строки
docker exec postgres psql -U metachat -d metachat -c "\dt"

# Backup
docker exec postgres pg_dump -U metachat metachat > backup.sql

# Restore
cat backup.sql | docker exec -i postgres psql -U metachat -d metachat
```

### Kafka

```bash
# Список топиков
docker exec kafka kafka-topics --bootstrap-server localhost:29092 --list

# Описание топика
docker exec kafka kafka-topics --describe \
  --bootstrap-server localhost:29092 \
  --topic metachat.user.events

# Создание топика
docker exec kafka kafka-topics --create \
  --bootstrap-server localhost:29092 \
  --topic test-topic \
  --partitions 3

# Чтение сообщений
docker exec kafka kafka-console-consumer \
  --bootstrap-server localhost:29092 \
  --topic metachat.user.events \
  --from-beginning

# Отправка сообщения
docker exec -it kafka kafka-console-producer \
  --bootstrap-server localhost:29092 \
  --topic test-topic
```

### EventStore

```bash
curl http://localhost:2113/health/live
curl http://localhost:2113/stats
```

---

## 🌐 URLs

### Приложение
- **API Gateway:** http://localhost:8080
- **API Health:** http://localhost:8080/health

### Мониторинг
- **Swarmpit:** http://localhost:888 (только Swarm)
- **Grafana:** http://localhost:3000 (admin/metachat2024)
- **Prometheus:** http://localhost:9090
- **Kafka UI:** http://localhost:8090

### Инфраструктура
- **PostgreSQL:** localhost:5432
- **Cassandra:** localhost:9042
- **EventStore:** http://localhost:2113
- **Kafka:** localhost:9092
- **NATS:** http://localhost:4222

---

## 🧹 Очистка

### Docker Compose

```bash
# Остановить
./stop-all.sh

# С удалением volumes
docker compose -f docker-compose.infrastructure.yml down -v
docker compose -f docker-compose.services.yml down -v

# Полная очистка
docker system prune -a -f
docker volume prune -f
docker network prune -f
```

### Docker Swarm

```bash
# Остановить
./stop-swarm.sh all

# Полная очистка
./stop-swarm.sh clean

# Выйти из Swarm
docker swarm leave --force
```

---

## 🔧 Отладка

### Проверка здоровья

```bash
# API
curl http://localhost:8080/health

# Kafka
docker exec kafka kafka-broker-api-versions --bootstrap-server localhost:29092

# Cassandra
docker exec cassandra cqlsh -e "SELECT release_version FROM system.local;"

# PostgreSQL
docker exec postgres pg_isready -U metachat

# EventStore
curl http://localhost:2113/health/live
```

### Ресурсы

```bash
docker stats                    # Использование ресурсов
docker stats --no-stream        # Однократно
docker system df               # Использование диска
```

### Сеть

```bash
docker network ls
docker network inspect metachat_network
```

---

## 📁 Структура скриптов

```
docker/
├── # Docker Compose
├── deploy-full.sh          # Деплой
├── deploy-full.ps1         # Windows
├── stop-all.sh/ps1         # Остановка
├── status.sh/ps1           # Статус
├── logs.sh/ps1             # Логи
│
├── # Docker Swarm
├── deploy-swarm.sh         # Первый деплой
├── redeploy-swarm.sh       # Редеплой
├── stop-swarm.sh           # Остановка
├── status-swarm.sh         # Статус
├── logs-swarm.sh           # Логи
│
├── # Compose файлы
├── docker-compose.infrastructure.yml
├── docker-compose.services.yml
├── docker-compose.swarm.yml
└── docker-compose.swarm-services.yml
```

---

## 💡 Советы

### Быстрый рестарт сервиса

**Compose:**
```bash
docker compose -f docker-compose.services.yml restart api-gateway
```

**Swarm:**
```bash
./redeploy-swarm.sh api-gateway
```

### Мониторинг в реальном времени

```bash
watch -n 2 "docker service ls"
```

### Проверка всех health endpoints

```bash
for port in 8080 3000 9090; do
  curl -s http://localhost:$port/health 2>/dev/null && echo " :$port OK" || echo " :$port FAIL"
done
```

---

**💡 Сохраните этот файл в закладки!**
