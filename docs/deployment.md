# MetaChat - Deployment Guide

Это руководство описывает процесс деплоя MetaChat с использованием Docker Compose.

## 🎯 Деплой для разных окружений

### 🏠 Локальная разработка (Local Development)

Полный деплой всех сервисов на локальной машине для разработки и тестирования.

**Требования:**
- Docker 20.10+
- Docker Compose 2.0+
- 8GB RAM (рекомендуется 16GB)
- 20GB свободного места

**Запуск:**

Linux/Mac:
```bash
cd docker
./deploy-full.sh
```

Windows:
```powershell
cd docker
.\deploy-full.ps1
```

**Что включено:**
- Все 11 микросервисов
- Полная инфраструктура (Kafka, Cassandra, PostgreSQL, EventStore, NATS)
- Мониторинг (Prometheus, Grafana, Loki)
- Kafka UI для отладки

**Время развертывания:** ~10-20 минут при первом запуске

### 🌐 Деплой на сервер

Для деплоя на удаленный сервер (VPS, облако):

1. **Клонируйте репозиторий на сервер:**
```bash
git clone <repository-url>
cd metachat
```

2. **Запустите деплой:**
```bash
cd docker
chmod +x deploy-full.sh
./deploy-full.sh
```

3. **Откройте порты в firewall:**
```bash
sudo ufw allow 8080/tcp   # API Gateway
sudo ufw allow 3000/tcp   # Grafana
sudo ufw allow 9090/tcp   # Prometheus
sudo ufw allow 8090/tcp   # Kafka UI
```

## 📦 Структура деплоя

### Docker Compose файлы

#### `docker-compose.infrastructure.yml`
Инфраструктурные сервисы:
- **Zookeeper** - координация Kafka
- **Kafka** - брокер сообщений
- **Kafka UI** - веб-интерфейс для Kafka
- **Cassandra** - NoSQL база данных
- **PostgreSQL** - реляционная БД
- **EventStore** - event sourcing
- **NATS** - lightweight messaging
- **Prometheus** - сбор метрик
- **Grafana** - визуализация метрик
- **Loki** - сбор логов
- **Promtail** - агент для логов

#### `docker-compose.services.yml`
Микросервисы приложения:
- **API Gateway** - точка входа API
- **User Service** - управление пользователями
- **Diary Service** - личный дневник
- **Matching Service** - алгоритмы подбора
- **Match Request Service** - запросы на матчинг
- **Chat Service** - система чата
- **Mood Analysis Service** - анализ настроения (AI)
- **Analytics Service** - аналитика данных
- **Archetype Service** - психологические профили
- **Biometric Service** - биометрические данные
- **Correlation Service** - корреляции данных

## 🌐 Доступ к сервисам

После успешного деплоя доступны:

### Приложение
- **API Gateway**: http://localhost:8080

### Инфраструктура
- **Kafka UI**: http://localhost:8090
- **PostgreSQL**: localhost:5432
  - User: `metachat`
  - Password: `metachat_password`
  - Database: `metachat`
- **Cassandra**: localhost:9042
  - Keyspace: `metachat`
- **EventStore**: http://localhost:2113
- **NATS**: http://localhost:4222
  - Monitoring: http://localhost:8222

### Мониторинг
- **Grafana**: http://localhost:3000
  - User: `admin`
  - Password: `metachat2024`
- **Prometheus**: http://localhost:9090
- **Loki**: http://localhost:3100

## 🛠️ Управление деплоем

### Просмотр статуса

```bash
cd docker
./status.sh          # Linux/Mac
.\status.ps1         # Windows
```

### Просмотр логов

Все логи:
```bash
./logs.sh all        # Linux/Mac
.\logs.ps1 all       # Windows
```

Логи инфраструктуры:
```bash
./logs.sh infra
```

Логи приложений:
```bash
./logs.sh services
```

Логи конкретного сервиса:
```bash
./logs.sh api-gateway
./logs.sh user-service
./logs.sh kafka
```

### Остановка всех сервисов

```bash
./stop-all.sh        # Linux/Mac
.\stop-all.ps1       # Windows
```

### Перезапуск сервиса

Инфраструктура:
```bash
docker compose -f docker-compose.infrastructure.yml restart kafka
```

Приложение:
```bash
docker compose -f docker-compose.services.yml restart api-gateway
```

### Масштабирование сервиса

```bash
docker compose -f docker-compose.services.yml up -d --scale user-service=3
```

## 🔄 Обновление сервисов

### Обновление кода

1. Внесите изменения в код
2. Пересоберите сервис:
```bash
cd docker
docker compose -f docker-compose.services.yml build user-service
docker compose -f docker-compose.services.yml up -d user-service
```

### Обновление всех сервисов

```bash
cd docker
./deploy-full.sh     # Пересоберет и перезапустит всё
```

## 🔍 Диагностика

### Проверка здоровья сервисов

API Gateway:
```bash
curl http://localhost:8080/health
```

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

### Подключение к базам данных

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
SELECT * FROM users LIMIT 10;
```

### Просмотр Kafka топиков

```bash
docker exec kafka kafka-topics --bootstrap-server localhost:29092 --list
```

Чтение сообщений:
```bash
docker exec kafka kafka-console-consumer \
  --bootstrap-server localhost:29092 \
  --topic metachat.user.events \
  --from-beginning
```

## 🐛 Troubleshooting

### Порты заняты

Проверьте, какие порты заняты:
```bash
netstat -tulpn | grep -E '8080|9092|5432|9042'
```

Остановите конфликтующие сервисы или измените порты в docker-compose файлах.

### Недостаточно памяти

Убедитесь, что Docker имеет достаточно RAM:
- Docker Desktop: Settings → Resources → Memory (минимум 8GB)

Или уменьшите количество запущенных сервисов, закомментировав ненужные в docker-compose.

### Сервис не запускается

1. Проверьте логи:
```bash
./logs.sh <service-name>
```

2. Проверьте, что инфраструктура готова:
```bash
docker compose -f docker-compose.infrastructure.yml ps
```

3. Убедитесь, что сеть создана:
```bash
docker network inspect metachat_network
```

### Cassandra не стартует

Cassandra требует ~120 секунд для инициализации. Подождите и проверьте:
```bash
docker logs cassandra
```

### Ошибки подключения между сервисами

Убедитесь, что все сервисы в одной сети:
```bash
docker network inspect metachat_network
```

## 🔐 Безопасность для продакшна

### ⚠️ ВАЖНО: Перед деплоем в продакшн

1. **Измените все пароли по умолчанию:**
   - PostgreSQL: `POSTGRES_PASSWORD`
   - Grafana: `GF_SECURITY_ADMIN_PASSWORD`
   - EventStore: настройте аутентификацию

2. **Используйте SSL/TLS:**
   - Настройте HTTPS для API Gateway
   - Включите SSL для PostgreSQL
   - Настройте TLS для Kafka

3. **Ограничьте доступ к портам:**
   - Оставьте открытым только 8080 (API)
   - Закройте все порты баз данных извне
   - Используйте VPN для доступа к мониторингу

4. **Настройте резервное копирование:**
   - PostgreSQL: регулярные дампы
   - Cassandra: снапшоты
   - Kafka: настройте retention policy

5. **Используйте Docker secrets:**
```yaml
secrets:
  db_password:
    external: true
```

## 📊 Мониторинг в продакшне

### Grafana Dashboards

После входа в Grafana (http://localhost:3000) доступны:
- **MetaChat Services Overview** - общий обзор
- **Kafka Metrics** - метрики Kafka
- **Database Performance** - производительность БД
- **System Resources** - использование ресурсов

### Алерты

Настройте алерты в Grafana для:
- Высокая нагрузка на CPU/RAM
- Ошибки в сервисах
- Проблемы с доступностью баз данных
- Задержки в Kafka

### Логи

Все логи собираются в Loki и доступны через Grafana:
- **Explore** → выберите Loki
- Фильтр по сервису: `{container_name="api-gateway"}`
- Поиск ошибок: `{container_name=~".+"} |= "error"`

## 🔄 Backup & Restore

### PostgreSQL

Backup:
```bash
docker exec postgres pg_dump -U metachat metachat > backup.sql
```

Restore:
```bash
cat backup.sql | docker exec -i postgres psql -U metachat -d metachat
```

### Cassandra

Backup:
```bash
docker exec cassandra nodetool snapshot metachat
```

### Docker Volumes

Backup volumes:
```bash
docker run --rm -v postgres_data:/data -v $(pwd):/backup alpine \
  tar czf /backup/postgres_data.tar.gz -C /data .
```

## 📚 Дополнительные ресурсы

- [Quick Start Guide](../QUICK_START.md)
- [Architecture Documentation](ARCHITECTURE.md)
- [Local Development Guide](LOCAL_DEVELOPMENT.md)
- [Docker Management](../docker/README.md)

## 🆘 Получение помощи

Если возникли проблемы:
1. Проверьте логи: `./logs.sh all`
2. Проверьте статус: `./status.sh`
3. Проверьте документацию выше
4. Создайте issue в GitHub с логами
