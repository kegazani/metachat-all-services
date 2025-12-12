# MetaChat - Quick Commands Reference

Краткая шпаргалка по всем командам MetaChat.

## 🚀 Deployment

### Полный деплой (рекомендуется)

**Linux/Mac:**
```bash
cd docker
./deploy-full.sh
```

**Windows:**
```powershell
cd docker
.\deploy-full.ps1
```

### Остановка всех сервисов

**Linux/Mac:**
```bash
cd docker
./stop-all.sh
```

**Windows:**
```powershell
cd docker
.\stop-all.ps1
```

## 📊 Мониторинг

### Статус сервисов

**Linux/Mac:**
```bash
cd docker
./status.sh
```

**Windows:**
```powershell
cd docker
.\status.ps1
```

### Просмотр логов

**Все логи:**
```bash
./logs.sh all          # Linux/Mac
.\logs.ps1 all         # Windows
```

**Инфраструктура:**
```bash
./logs.sh infra
.\logs.ps1 infra
```

**Приложения:**
```bash
./logs.sh services
.\logs.ps1 services
```

**Конкретный сервис:**
```bash
./logs.sh api-gateway
./logs.sh kafka
./logs.sh cassandra
```

## 🐳 Docker Compose Commands

### Инфраструктура

```bash
cd docker

docker compose -f docker-compose.infrastructure.yml up -d
docker compose -f docker-compose.infrastructure.yml down
docker compose -f docker-compose.infrastructure.yml ps
docker compose -f docker-compose.infrastructure.yml logs -f
docker compose -f docker-compose.infrastructure.yml restart kafka
```

### Сервисы

```bash
cd docker

docker compose -f docker-compose.services.yml up -d
docker compose -f docker-compose.services.yml down
docker compose -f docker-compose.services.yml ps
docker compose -f docker-compose.services.yml logs -f api-gateway
docker compose -f docker-compose.services.yml restart user-service
```

### Rebuild сервиса

```bash
docker compose -f docker-compose.services.yml build user-service
docker compose -f docker-compose.services.yml up -d user-service
```

## 🗄️ Database Commands

### Cassandra

**Подключение:**
```bash
docker exec -it cassandra cqlsh
```

**Команды в cqlsh:**
```sql
USE metachat;
DESCRIBE TABLES;
DESCRIBE TABLE users;
SELECT * FROM users LIMIT 10;
SELECT COUNT(*) FROM users;
```

**Из командной строки:**
```bash
docker exec cassandra cqlsh -e "USE metachat; DESCRIBE TABLES;"
docker exec cassandra cqlsh -e "SELECT * FROM metachat.users LIMIT 10;"
```

**Статус кластера:**
```bash
docker exec cassandra nodetool status
```

### PostgreSQL

**Подключение:**
```bash
docker exec -it postgres psql -U metachat -d metachat
```

**Команды в psql:**
```sql
\dt                          -- список таблиц
\d+ users                    -- структура таблицы
SELECT * FROM users LIMIT 10;
SELECT COUNT(*) FROM users;
```

**Из командной строки:**
```bash
docker exec postgres psql -U metachat -d metachat -c "\dt"
docker exec postgres psql -U metachat -d metachat -c "SELECT * FROM users LIMIT 10;"
```

**Backup:**
```bash
docker exec postgres pg_dump -U metachat metachat > backup_$(date +%Y%m%d).sql
```

**Restore:**
```bash
cat backup.sql | docker exec -i postgres psql -U metachat -d metachat
```

## 📨 Kafka Commands

### Список топиков

```bash
docker exec kafka kafka-topics --bootstrap-server localhost:29092 --list
```

### Описание топика

```bash
docker exec kafka kafka-topics --describe \
  --bootstrap-server localhost:29092 \
  --topic metachat.user.events
```

### Создание топика

```bash
docker exec kafka kafka-topics --create \
  --bootstrap-server localhost:29092 \
  --topic test-topic \
  --partitions 3 \
  --replication-factor 1
```

### Удаление топика

```bash
docker exec kafka kafka-topics --delete \
  --bootstrap-server localhost:29092 \
  --topic test-topic
```

### Чтение сообщений

```bash
docker exec kafka kafka-console-consumer \
  --bootstrap-server localhost:29092 \
  --topic metachat.user.events \
  --from-beginning
```

### Отправка сообщения

```bash
docker exec -it kafka kafka-console-producer \
  --bootstrap-server localhost:29092 \
  --topic test-topic
```

### Consumer groups

```bash
docker exec kafka kafka-consumer-groups --list \
  --bootstrap-server localhost:29092

docker exec kafka kafka-consumer-groups --describe \
  --bootstrap-server localhost:29092 \
  --group mood-analysis-consumer
```

## 📝 EventStore Commands

**Health check:**
```bash
curl http://localhost:2113/health/live
```

**Статистика:**
```bash
curl http://localhost:2113/stats
```

**Streams:**
```bash
curl http://localhost:2113/streams
```

## 🔧 Local Development

### Запуск только инфраструктуры

```bash
cd docker
docker compose -f docker-compose.infrastructure.yml up -d
```

### Запуск Go сервиса локально

```bash
cd metachat-all-services/metachat-user-service

export CASSANDRA_HOSTS=localhost:9042
export CASSANDRA_KEYSPACE=metachat
export KAFKA_BOOTSTRAP_SERVERS=localhost:9092
export EVENT_STORE_URL=http://localhost:2113
export GRPC_PORT=50051

go run cmd/main.go
```

### Запуск Python сервиса локально

```bash
cd metachat-all-services/metachat-mood-analysis-service

python -m venv venv
source venv/bin/activate  # Linux/Mac
.\venv\Scripts\activate   # Windows

pip install -r requirements.txt

export KAFKA_BOOTSTRAP_SERVERS=localhost:9092
export CASSANDRA_HOSTS=localhost:9042
export CASSANDRA_KEYSPACE=metachat

python src/main.py
```

## 🧪 Testing

### Unit tests (Go)

```bash
cd metachat-all-services/metachat-user-service
go test ./...
go test -v ./internal/service/
```

### Unit tests (Python)

```bash
cd metachat-all-services/metachat-mood-analysis-service
pytest tests/
pytest tests/ -v
pytest tests/unit/test_mood_analyzer.py
```

### API тесты

```bash
curl http://localhost:8080/health
curl http://localhost:8080/api/v1/users
```

## 🔍 Debugging

### Container logs

```bash
docker logs api-gateway
docker logs kafka -f
docker logs cassandra --tail 100
```

### Container shell

```bash
docker exec -it api-gateway /bin/sh
docker exec -it kafka /bin/bash
```

### Network inspection

```bash
docker network ls
docker network inspect metachat_network
```

### Resource usage

```bash
docker stats
docker stats --no-stream
docker system df
```

## 🧹 Cleanup

### Остановка и удаление контейнеров

```bash
cd docker
docker compose -f docker-compose.infrastructure.yml down
docker compose -f docker-compose.services.yml down
```

### Удаление с volumes (⚠️ удалит все данные!)

```bash
docker compose -f docker-compose.infrastructure.yml down -v
docker compose -f docker-compose.services.yml down -v
```

### Полная очистка Docker

```bash
docker system prune -a
docker volume prune
docker network prune
```

### Удаление всех MetaChat контейнеров и образов

```bash
docker ps -a | grep metachat | awk '{print $1}' | xargs docker rm -f
docker images | grep metachat | awk '{print $3}' | xargs docker rmi -f
```

## 🌐 URLs

### Application
- API Gateway: http://localhost:8080
- API Health: http://localhost:8080/health

### Monitoring
- Grafana: http://localhost:3000 (admin/metachat2024)
- Prometheus: http://localhost:9090
- Prometheus Targets: http://localhost:9090/targets
- Loki: http://localhost:3100

### Infrastructure
- Kafka UI: http://localhost:8090
- EventStore: http://localhost:2113
- NATS Monitoring: http://localhost:8222

### Databases
- PostgreSQL: localhost:5432 (metachat/metachat_password)
- Cassandra: localhost:9042
- Kafka: localhost:9092

## 📦 Build Commands

### Build все образы

**Linux/Mac:**
```bash
cd docker
./build-images.sh
```

### Build конкретный сервис

```bash
cd metachat-all-services

docker build -t metachat/user-service:latest \
  -f metachat-user-service/Dockerfile .

docker build -t metachat/mood-analysis-service:latest \
  -f metachat-mood-analysis-service/Dockerfile .
```

## 🔐 Security Commands

### Проверка открытых портов

```bash
netstat -tulpn | grep LISTEN
ss -tulpn | grep LISTEN
```

### Firewall (Linux)

```bash
sudo ufw status
sudo ufw allow 8080/tcp
sudo ufw allow 3000/tcp
```

## 💡 Tips

### Быстрый рестарт после изменений

```bash
cd docker
docker compose -f docker-compose.services.yml build user-service && \
docker compose -f docker-compose.services.yml up -d user-service && \
docker compose -f docker-compose.services.yml logs -f user-service
```

### Мониторинг в реальном времени

```bash
watch -n 2 "docker compose -f docker/docker-compose.services.yml ps"
```

### Проверка всех health endpoints

```bash
curl -s http://localhost:8080/health && echo " - API Gateway OK" || echo " - API Gateway FAILED"
curl -s http://localhost:2113/health/live && echo " - EventStore OK" || echo " - EventStore FAILED"
curl -s http://localhost:9090/-/healthy && echo " - Prometheus OK" || echo " - Prometheus FAILED"
```

---

**💡 Совет:** Сохраните этот файл в закладки для быстрого доступа к командам!

