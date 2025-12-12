# MetaChat - Quick Start Guide

Это руководство поможет вам быстро развернуть MetaChat локально с помощью Docker.

## 📋 Требования

- **Docker** версии 20.10 или выше
- **Docker Compose** версии 2.0 или выше
- **Минимум 8GB RAM** (рекомендуется 16GB)
- **Минимум 20GB свободного места** на диске

## 🚀 Быстрый старт

### Для Linux/Mac:

```bash
cd docker
chmod +x deploy-full.sh
./deploy-full.sh
```

### Для Windows (PowerShell):

```powershell
cd docker
.\deploy-full.ps1
```

## 📦 Что делает скрипт деплоя?

1. **Проверяет окружение** - Docker установлен и запущен
2. **Очищает предыдущий деплой** - останавливает и удаляет старые контейнеры
3. **Создает Docker сеть** - `metachat_network` для связи сервисов
4. **Собирает все Docker образы** локально (без registry):
   - API Gateway (Go)
   - User Service (Go)
   - Diary Service (Go)
   - Matching Service (Go)
   - Match Request Service (Go)
   - Chat Service (Go)
   - Mood Analysis Service (Python)
   - Analytics Service (Python)
   - Archetype Service (Python)
   - Biometric Service (Python)
   - Correlation Service (Python)
5. **Запускает инфраструктуру**:
   - Zookeeper
   - Kafka + Kafka UI
   - Cassandra
   - PostgreSQL
   - EventStore
   - NATS
6. **Инициализирует данные**:
   - Создает топики Kafka
   - Создает схему Cassandra
   - Инициализирует PostgreSQL
7. **Запускает сервисы приложения**
8. **Запускает мониторинг**:
   - Prometheus
   - Grafana
   - Loki
   - Promtail

## 🌐 После деплоя доступны:

### Основные сервисы:
- **API Gateway**: http://localhost:8080
  
### Инфраструктура:
- **Kafka UI**: http://localhost:8090
- **PostgreSQL**: localhost:5432 (user: `metachat`, pass: `metachat_password`)
- **Cassandra**: localhost:9042
- **EventStore**: http://localhost:2113
- **NATS**: http://localhost:4222 (мониторинг: :8222)

### Мониторинг:
- **Grafana**: http://localhost:3000 (логин: `admin`, пароль: `metachat2024`)
- **Prometheus**: http://localhost:9090
- **Loki**: http://localhost:3100

## 📝 Полезные команды

### Просмотр логов всех сервисов:
```bash
docker compose -f docker/docker-compose.infrastructure.yml logs -f
docker compose -f docker/docker-compose.services.yml logs -f
```

### Просмотр логов конкретного сервиса:
```bash
docker compose -f docker/docker-compose.services.yml logs -f api-gateway
docker compose -f docker/docker-compose.services.yml logs -f user-service
```

### Проверка статуса:
```bash
docker compose -f docker/docker-compose.infrastructure.yml ps
docker compose -f docker/docker-compose.services.yml ps
```

### Перезапуск сервиса:
```bash
docker compose -f docker/docker-compose.services.yml restart api-gateway
```

### Остановка всех сервисов:

**Linux/Mac:**
```bash
./docker/stop-all.sh
```

**Windows:**
```powershell
.\docker\stop-all.ps1
```

### Подключение к базам данных:

**Cassandra:**
```bash
docker exec -it cassandra cqlsh
```

**PostgreSQL:**
```bash
docker exec -it postgres psql -U metachat -d metachat
```

## 🔧 Если что-то пошло не так

### Проверка Docker:
```bash
docker --version
docker compose version
docker info
```

### Очистка всех контейнеров и сетей:
```bash
docker compose -f docker/docker-compose.infrastructure.yml down -v
docker compose -f docker/docker-compose.services.yml down -v
docker network prune -f
docker volume prune -f
```

### Пересборка конкретного сервиса:
```bash
cd metachat-all-services
docker build -t metachat/api-gateway:latest -f metachat-api-gateway/Dockerfile .
```

### Проверка логов инфраструктуры:
```bash
docker logs kafka
docker logs cassandra
docker logs postgres
docker logs eventstore
```

## ⏱️ Время развертывания

- **Сборка образов**: 5-15 минут (зависит от мощности машины)
- **Запуск инфраструктуры**: 2-5 минут
- **Запуск сервисов**: 1-2 минуты
- **Общее время**: ~10-20 минут при первом запуске

## 📊 Использование ресурсов

При полном деплое:
- **RAM**: ~6-8 GB
- **CPU**: 4-8 ядер (рекомендуется)
- **Disk**: ~15-20 GB

## 🔍 Проверка работоспособности

После деплоя можно проверить:

1. **API Gateway Health**:
   ```bash
   curl http://localhost:8080/health
   ```

2. **Kafka Topics**:
   ```bash
   docker exec kafka kafka-topics --bootstrap-server localhost:29092 --list
   ```

3. **Cassandra Keyspace**:
   ```bash
   docker exec cassandra cqlsh -e "DESCRIBE KEYSPACE metachat;"
   ```

4. **PostgreSQL Tables**:
   ```bash
   docker exec postgres psql -U metachat -d metachat -c "\dt"
   ```

## 🎯 Тестирование API

После запуска можно импортировать Postman коллекцию:
- Файл: `MetaChat_API.postman_collection.json`
- Базовый URL: `http://localhost:8080`

## 📚 Дополнительная документация

- [Архитектура](docs/ARCHITECTURE.md)
- [Подробное описание сервисов](docs/DETAILED_SERVICE_FLOW.md)
- [Локальная разработка](docs/LOCAL_DEVELOPMENT.md)
- [Диаграммы потоков](docs/FLOW_DIAGRAMS.md)

## 🆘 Поддержка

Если возникли проблемы:
1. Проверьте логи сервисов
2. Убедитесь, что Docker имеет достаточно ресурсов
3. Проверьте, что все порты свободны
4. Попробуйте очистить и пересобрать всё заново

## 🎉 Готово!

После успешного деплоя вы можете начать использовать MetaChat API по адресу:
**http://localhost:8080**

Grafana дашборды доступны по адресу:
**http://localhost:3000** (admin / metachat2024)

