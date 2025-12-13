# MetaChat - Деплой на Linux

## 🚀 Быстрый старт

### Полный деплой одной командой

```bash
cd docker
./deploy-full.sh
```

Этот скрипт автоматически:
✅ Соберёт все Docker-образы  
✅ Развернёт в Docker Swarm  
✅ Создаст базы данных  

### Проверить статус

```bash
docker service ls
```

Все сервисы должны показывать `1/1` в колонке REPLICAS.

---

## 📋 Пошаговый деплой

### 1. Собрать образы

```bash
cd docker
./build-all.sh
```

### 2. Развернуть

```bash
./deploy.sh
```

### 3. Инициализировать БД

```bash
# Cassandra
CASSANDRA=$(docker ps --filter "name=metachat_cassandra" -q | head -1)
docker exec $CASSANDRA cqlsh -e "CREATE KEYSPACE IF NOT EXISTS metachat WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};"

# PostgreSQL
POSTGRES=$(docker ps --filter "name=metachat_postgres" -q | head -1)
docker exec $POSTGRES psql -U metachat -d postgres -c "CREATE DATABASE metachat_mood;"
docker exec $POSTGRES psql -U metachat -d postgres -c "CREATE DATABASE metachat_analytics;"
docker exec $POSTGRES psql -U metachat -d postgres -c "CREATE DATABASE metachat_personality;"
docker exec $POSTGRES psql -U metachat -d postgres -c "CREATE DATABASE metachat_biometric;"
docker exec $POSTGRES psql -U metachat -d postgres -c "CREATE DATABASE metachat_correlation;"
```

---

## 🌐 Доступ к сервисам

| Сервис | URL |
|--------|-----|
| API Gateway | http://localhost:8080 |
| Grafana | http://localhost:3000 (admin/metachat2024) |
| Kafka UI | http://localhost:8090 |
| Prometheus | http://localhost:9090 |

---

## 🔧 Управление

```bash
# Статус сервисов
docker service ls

# Логи сервиса
docker service logs metachat_<service-name> -f

# Обновить сервис
docker service update --image metachat/<service>:latest metachat_<service> --force

# Удалить всё
docker stack rm metachat
```

---

## 📚 Подробная документация

См. [docker/README.md](docker/README.md)

---

## ⚙️ Требования

- Docker 20.10+
- Docker Swarm
- 8GB RAM minimum
- 20GB disk space

