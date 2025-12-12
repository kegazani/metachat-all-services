# MetaChat - Deployment Guide

Полное руководство по деплою MetaChat.

## 🎯 Выбор режима деплоя

| Режим | Использование | Особенности |
|-------|---------------|-------------|
| **Docker Compose** | Разработка, тестирование | Простой, быстрый старт |
| **Docker Swarm** | Продакшн, staging | UI управление, масштабирование |

---

## 🐳 Docker Compose (Разработка)

### Требования

- Docker 20.10+
- Docker Compose 2.0+
- 8GB RAM (16GB рекомендуется)
- 20GB свободного места

### Запуск

**Linux/Mac:**
```bash
cd docker
chmod +x *.sh
./deploy-full.sh
```

**Windows:**
```powershell
cd docker
.\deploy-full.ps1
```

### Что происходит

1. ✅ Проверка Docker
2. ✅ Создание сети
3. ✅ Сборка образов (11 сервисов)
4. ✅ Запуск инфраструктуры
5. ✅ Ожидание готовности БД
6. ✅ Инициализация Kafka топиков
7. ✅ Инициализация Cassandra схемы
8. ✅ Запуск сервисов
9. ✅ Запуск мониторинга

### Управление

```bash
./stop-all.sh              # Остановить
./status.sh                # Статус
./logs.sh all              # Логи
./logs.sh <service>        # Логи сервиса
```

### Перезапуск сервиса

```bash
docker compose -f docker-compose.services.yml restart api-gateway
```

---

## 🐝 Docker Swarm (Продакшн)

### Требования

- Docker 20.10+ с Swarm mode
- 8GB RAM (16GB+ рекомендуется)
- 30GB свободного места
- Открытые порты: 2377, 7946, 4789 (для кластера)

### Первый деплой

```bash
cd docker
chmod +x *.sh
./deploy-swarm.sh
```

### Что происходит

1. ✅ Инициализация Docker Swarm
2. ✅ Создание overlay сети
3. ✅ Сборка образов
4. ✅ Деплой инфраструктуры (stack)
5. ✅ Ожидание готовности
6. ✅ Деплой сервисов (stack)
7. ✅ Запуск Swarmpit UI

### Управление

```bash
./status-swarm.sh                    # Статус и URLs
./redeploy-swarm.sh all              # Редеплой всего
./redeploy-swarm.sh services         # Редеплой сервисов
./redeploy-swarm.sh kafka            # Редеплой Kafka
./stop-swarm.sh all                  # Остановить
./logs-swarm.sh kafka -f             # Логи
```

### Масштабирование

```bash
docker service scale metachat-services_mood-analysis-service=3
docker service scale metachat-services_api-gateway=2
```

### Swarmpit UI

После деплоя откройте: **http://your-server:888**

Возможности:
- 📊 Dashboard со всеми сервисами
- 📜 Логи в реальном времени
- 🔄 Масштабирование через UI
- 📈 Мониторинг ресурсов
- 🛠️ Управление стеками

---

## 🌐 Доступ к сервисам

### После Docker Compose

| Сервис | URL |
|--------|-----|
| API Gateway | http://localhost:8080 |
| Grafana | http://localhost:3000 |
| Prometheus | http://localhost:9090 |
| Kafka UI | http://localhost:8090 |

### После Docker Swarm

| Сервис | URL |
|--------|-----|
| API Gateway | http://server:8080 |
| **Swarmpit** | http://server:888 |
| Grafana | http://server:3000 |
| Prometheus | http://server:9090 |
| Kafka UI | http://server:8090 |

### Credentials

| Сервис | Логин | Пароль |
|--------|-------|--------|
| Grafana | admin | metachat2024 |
| PostgreSQL | metachat | metachat_password |
| Swarmpit | создать | при первом входе |

---

## 🔄 Обновление сервисов

### Docker Compose

```bash
# Пересобрать и перезапустить
cd docker
./deploy-full.sh

# Или конкретный сервис
docker compose -f docker-compose.services.yml build user-service
docker compose -f docker-compose.services.yml up -d user-service
```

### Docker Swarm

```bash
# Редеплой всего
./redeploy-swarm.sh all

# Редеплой одного сервиса
./redeploy-swarm.sh mood-analysis-service

# С пересборкой образа
docker build -t metachat/mood-analysis-service:latest \
  -f ../metachat-all-services/metachat-mood-analysis-service/Dockerfile \
  ../metachat-all-services
./redeploy-swarm.sh mood-analysis-service
```

---

## 📊 Мониторинг

### Grafana (оба режима)

URL: http://localhost:3000

Предустановленные дашборды:
- MetaChat Services Overview
- Database Performance
- Kafka Metrics
- System Resources

### Swarmpit (только Swarm)

URL: http://localhost:888

Возможности:
- Обзор всех сервисов
- Логи в реальном времени
- Масштабирование
- Метрики ресурсов
- Управление стеками

### Prometheus

URL: http://localhost:9090

Запросы:
```promql
up
container_memory_usage_bytes
rate(http_requests_total[5m])
```

---

## 🐛 Troubleshooting

### Сервис не запускается

**Compose:**
```bash
./logs.sh <service>
docker compose -f docker-compose.services.yml logs <service>
```

**Swarm:**
```bash
./logs-swarm.sh <service> -f
docker service ps metachat-services_<service>
```

### Проблемы с сетью

**Compose:**
```bash
docker network inspect metachat_network
```

**Swarm:**
```bash
docker network inspect metachat_network
# Должен быть driver: overlay
```

### Cassandra не стартует

Подождите 2-3 минуты, проверьте:
```bash
docker logs cassandra
docker exec cassandra nodetool status
```

### Kafka не готов

```bash
docker exec kafka kafka-broker-api-versions --bootstrap-server localhost:29092
```

### Полный сброс

**Compose:**
```bash
./stop-all.sh
docker compose -f docker-compose.infrastructure.yml down -v
docker compose -f docker-compose.services.yml down -v
docker network rm metachat_network
./deploy-full.sh
```

**Swarm:**
```bash
./stop-swarm.sh clean
./deploy-swarm.sh
```

---

## 🔐 Безопасность для продакшена

### 1. Измените пароли

```yaml
# docker-compose файлы
POSTGRES_PASSWORD: "сложный_пароль"
GF_SECURITY_ADMIN_PASSWORD: "сложный_пароль"
```

### 2. Ограничьте порты

```bash
# Firewall
ufw allow 8080/tcp    # API только
ufw deny 5432/tcp     # PostgreSQL закрыть
ufw deny 9042/tcp     # Cassandra закрыть
```

### 3. HTTPS

Настройте reverse proxy (nginx):
```nginx
server {
    listen 443 ssl;
    ssl_certificate /path/to/cert;
    
    location / {
        proxy_pass http://localhost:8080;
    }
}
```

### 4. Swarmpit безопасность

- Смените порт с 888
- Используйте сложный пароль
- Ограничьте доступ по IP
- Настройте HTTPS

---

## 📁 Файлы конфигурации

### Docker Compose

```
docker/
├── docker-compose.infrastructure.yml  # Kafka, Cassandra, PostgreSQL...
├── docker-compose.services.yml        # API Gateway, сервисы...
├── cassandra-init.cql                 # Схема Cassandra
├── postgres-init.sql                  # Схема PostgreSQL
└── monitoring/                        # Prometheus, Grafana
```

### Docker Swarm

```
docker/
├── docker-compose.swarm.yml           # Инфраструктура для Swarm
├── docker-compose.swarm-services.yml  # Сервисы для Swarm
└── monitoring/                        # Конфиги мониторинга
```

---

## 📚 Дополнительно

- [Quick Start](../QUICK_START.md)
- [Команды](../COMMANDS.md)
- [Docker README](../docker/README.md)
- [Swarmpit Guide](../docker/SWARMPIT_GUIDE.md)
- [Local Development](LOCAL_DEVELOPMENT.md)
- [Architecture](ARCHITECTURE.md)
