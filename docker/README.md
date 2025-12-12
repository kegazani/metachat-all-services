# MetaChat Docker Deployment

Полное руководство по деплою MetaChat через Docker.

## 🎯 Два режима деплоя

### 🐳 Docker Compose (для разработки)

Простой режим для локальной разработки.

```bash
./deploy-full.sh
```

### 🐝 Docker Swarm (для продакшена)

Продвинутый режим с UI, масштабированием и мониторингом.

```bash
./deploy-swarm.sh
```

---

## 📁 Структура файлов

```
docker/
├── # === ОСНОВНЫЕ СКРИПТЫ ===
│
├── # Docker Compose режим
├── deploy-full.sh/ps1      # Полный деплой
├── stop-all.sh/ps1         # Остановка
├── status.sh/ps1           # Статус
├── logs.sh/ps1             # Логи
│
├── # Docker Swarm режим
├── deploy-swarm.sh         # Первый деплой
├── redeploy-swarm.sh       # Редеплой/обновление
├── stop-swarm.sh           # Остановка
├── status-swarm.sh         # Статус
├── logs-swarm.sh           # Логи
│
├── # === КОНФИГУРАЦИИ ===
│
├── # Docker Compose
├── docker-compose.infrastructure.yml   # Инфраструктура
├── docker-compose.services.yml         # Сервисы
│
├── # Docker Swarm
├── docker-compose.swarm.yml            # Инфраструктура для Swarm
├── docker-compose.swarm-services.yml   # Сервисы для Swarm
│
├── # === ДАННЫЕ ===
├── cassandra-init.cql      # Схема Cassandra
├── postgres-init.sql       # Схема PostgreSQL
├── kafka-topics-config.yaml
│
├── # === МОНИТОРИНГ ===
└── monitoring/
    ├── prometheus.yml
    ├── grafana/
    └── ...
```

---

## 🐳 Docker Compose режим

### Деплой

```bash
cd docker
./deploy-full.sh         # Linux/Mac
.\deploy-full.ps1        # Windows
```

### Команды

| Команда | Описание |
|---------|----------|
| `./deploy-full.sh` | Полный деплой |
| `./stop-all.sh` | Остановить всё |
| `./status.sh` | Показать статус и URLs |
| `./logs.sh all` | Все логи |
| `./logs.sh <service>` | Логи конкретного сервиса |

### Примеры

```bash
./logs.sh kafka              # Логи Kafka
./logs.sh api-gateway        # Логи API Gateway
./logs.sh infra              # Вся инфраструктура
./logs.sh services           # Все сервисы
```

---

## 🐝 Docker Swarm режим

### Первый деплой

```bash
cd docker
chmod +x *.sh
./deploy-swarm.sh
```

### Команды управления

| Команда | Описание |
|---------|----------|
| `./deploy-swarm.sh` | Первый деплой |
| `./redeploy-swarm.sh all` | Редеплой всего |
| `./redeploy-swarm.sh services` | Редеплой сервисов |
| `./redeploy-swarm.sh <service>` | Редеплой одного сервиса |
| `./stop-swarm.sh all` | Остановить всё |
| `./stop-swarm.sh clean` | Полная очистка |
| `./status-swarm.sh` | Статус и URLs |
| `./logs-swarm.sh <service>` | Логи сервиса |

### Примеры

```bash
# Редеплой
./redeploy-swarm.sh all
./redeploy-swarm.sh mood-analysis-service
./redeploy-swarm.sh kafka

# Логи
./logs-swarm.sh kafka -f
./logs-swarm.sh grafana --tail 100

# Масштабирование
docker service scale metachat-services_mood-analysis-service=3
```

### Portainer UI

После деплоя доступен веб-интерфейс:

```
http://your-server:888
```

Возможности:
- Мониторинг всех сервисов
- Просмотр логов в реальном времени
- Масштабирование через UI
- Управление стеками и контейнерами

---

## 🌐 Доступ к сервисам

> 📄 **Полный список учётных данных:** [CREDENTIALS.md](CREDENTIALS.md)

### Приложение

| Сервис | Порт | URL |
|--------|------|-----|
| API Gateway | 8080 | http://77.95.201.100:8080 |

### Мониторинг

| Сервис | Порт | Credentials |
|--------|------|-------------|
| Portainer | 888 | Создать при первом входе |
| Grafana | 3000 | `admin` / `metachat2024` |
| Prometheus | 9090 | - |
| Kafka UI | 8090 | - |

### Инфраструктура

| Сервис | Порт | Credentials |
|--------|------|-------------|
| PostgreSQL | 5432 | `metachat` / `metachat_password` |
| Cassandra | 9042 | - |
| EventStore | 2113 | `admin` / `changeit` |
| Kafka | 9092 | - |
| NATS | 4222 | - |

---

## 🔧 Подключение к базам

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
SELECT * FROM users;
```

### Kafka

```bash
# Список топиков
docker exec kafka kafka-topics --bootstrap-server localhost:29092 --list

# Чтение сообщений
docker exec kafka kafka-console-consumer \
  --bootstrap-server localhost:29092 \
  --topic metachat.user.events \
  --from-beginning
```

---

## 📊 Мониторинг

### Grafana

1. Откройте http://77.95.201.100:3000
2. Логин: `admin` / `metachat2024`
3. Импортируйте дашборд:
   - Меню → Dashboards → Import
   - Upload JSON: `monitoring/dashboards/metachat-services-status.json`
   - Выберите datasource: Prometheus
   - Нажмите Import

**Доступные дашборды:**
- **MetaChat Services Status** - статус всех сервисов (UP/DOWN)

### Prometheus

1. Откройте http://localhost:9090
2. Примеры запросов:
   - `up` - статус сервисов
   - `container_memory_usage_bytes` - память
   - `rate(http_requests_total[5m])` - запросы

### Portainer (только Swarm)

1. Откройте http://localhost:888
2. Создайте аккаунт администратора
3. Управляйте всеми сервисами через UI

---

## 🐛 Troubleshooting

### Проверка статуса

**Compose:**
```bash
./status.sh
docker compose -f docker-compose.infrastructure.yml ps
```

**Swarm:**
```bash
./status-swarm.sh
docker service ls
docker stack ls
```

### Логи ошибок

**Compose:**
```bash
./logs.sh kafka
docker compose -f docker-compose.infrastructure.yml logs kafka
```

**Swarm:**
```bash
./logs-swarm.sh kafka -f
docker service logs metachat-infra_kafka
```

### Перезапуск

**Compose:**
```bash
./stop-all.sh
./deploy-full.sh
```

**Swarm:**
```bash
./redeploy-swarm.sh all
# или полностью:
./stop-swarm.sh all
./deploy-swarm.sh
```

### Полная очистка

**Compose:**
```bash
docker compose -f docker-compose.infrastructure.yml down -v
docker compose -f docker-compose.services.yml down -v
docker system prune -a -f
```

**Swarm:**
```bash
./stop-swarm.sh clean
docker swarm leave --force
```

---

## 🔐 Безопасность для продакшена

1. **Измените пароли:**
   - PostgreSQL: `POSTGRES_PASSWORD`
   - Grafana: `GF_SECURITY_ADMIN_PASSWORD`

2. **Используйте HTTPS:**
   - Настройте reverse proxy (nginx/traefik)
   - SSL сертификаты

3. **Ограничьте порты:**
   - Закройте все кроме 8080 (API)
   - Используйте VPN для мониторинга

4. **Portainer:**
   - Измените порт 888
   - Настройте сложный пароль
   - Ограничьте доступ по IP

---

## 📚 Дополнительно

- [Quick Start](../QUICK_START.md)
- [Все команды](../COMMANDS.md)
- [Portainer Guide](https://docs.portainer.io/)
- [Deployment Guide](../docs/DEPLOYMENT.md)
- [Architecture](../docs/ARCHITECTURE.md)
