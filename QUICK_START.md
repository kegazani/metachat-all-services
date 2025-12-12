# MetaChat - Quick Start Guide

Быстрый запуск MetaChat за 10-20 минут.

## 📋 Требования

- **Docker** 20.10+
- **Docker Compose** 2.0+
- **8GB RAM** минимум (16GB рекомендуется)
- **20GB** свободного места на диске

## 🚀 Выберите режим деплоя

### 🐳 Вариант 1: Docker Compose (для разработки)

Простой запуск для локальной разработки и тестирования.

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

### 🐝 Вариант 2: Docker Swarm (для продакшена)

Продвинутый режим с UI управлением, масштабированием и мониторингом.

```bash
cd docker
chmod +x *.sh
./deploy-swarm.sh
```

**Преимущества Swarm:**
- ✅ Swarmpit UI - веб-интерфейс управления
- ✅ Масштабирование сервисов
- ✅ Автоматический рестарт
- ✅ Rolling updates
- ✅ Load balancing

## ⏱️ Время деплоя

- **Первый запуск:** 10-20 минут (сборка образов)
- **Последующие:** 3-5 минут

## 🌐 После запуска доступны

### Основные сервисы

| Сервис | URL | Логин |
|--------|-----|-------|
| API Gateway | http://localhost:8080 | - |
| Swarmpit (Swarm UI) | http://localhost:888 | Создать при первом входе |
| Grafana | http://localhost:3000 | admin / metachat2024 |
| Prometheus | http://localhost:9090 | - |
| Kafka UI | http://localhost:8090 | - |

### Базы данных

| База | Адрес | Credentials |
|------|-------|-------------|
| PostgreSQL | localhost:5432 | metachat / metachat_password |
| Cassandra | localhost:9042 | - |
| EventStore | http://localhost:2113 | - |
| Kafka | localhost:9092 | - |

## 📝 Основные команды

### Docker Compose режим

```bash
cd docker

./deploy-full.sh      # Полный деплой
./stop-all.sh         # Остановка
./status.sh           # Статус
./logs.sh all         # Все логи
./logs.sh kafka       # Логи Kafka
```

### Docker Swarm режим

```bash
cd docker

./deploy-swarm.sh              # Первый деплой
./redeploy-swarm.sh all        # Редеплой всего
./redeploy-swarm.sh services   # Редеплой сервисов
./stop-swarm.sh all            # Остановка
./status-swarm.sh              # Статус и URLs
./logs-swarm.sh kafka -f       # Логи с follow
```

## ✅ Проверка работоспособности

### 1. Проверьте API

```bash
curl http://localhost:8080/health
```

### 2. Откройте мониторинг

- Grafana: http://localhost:3000
- Swarmpit (Swarm): http://localhost:888

### 3. Проверьте базы данных

```bash
# Cassandra
docker exec -it cassandra cqlsh -e "DESCRIBE KEYSPACES;"

# PostgreSQL
docker exec -it postgres psql -U metachat -d metachat -c "\dt"

# Kafka
docker exec kafka kafka-topics --bootstrap-server localhost:29092 --list
```

## 🐛 Если что-то пошло не так

### Проверьте логи

**Compose:**
```bash
./logs.sh all
```

**Swarm:**
```bash
./logs-swarm.sh kafka -f
docker service ls
```

### Перезапустите

**Compose:**
```bash
./stop-all.sh
./deploy-full.sh
```

**Swarm:**
```bash
./stop-swarm.sh all
./deploy-swarm.sh
```

### Полная очистка

**Compose:**
```bash
docker compose -f docker-compose.infrastructure.yml down -v
docker compose -f docker-compose.services.yml down -v
docker network prune -f
```

**Swarm:**
```bash
./stop-swarm.sh clean
```

## 📚 Дополнительная документация

- [Полное руководство по деплою](docs/DEPLOYMENT.md)
- [Docker управление](docker/README.md)
- [Swarmpit Guide](docker/SWARMPIT_GUIDE.md)
- [Шпаргалка команд](COMMANDS.md)
- [Архитектура](docs/ARCHITECTURE.md)

## 🎯 Следующие шаги

1. ✅ Откройте Grafana и изучите дашборды
2. ✅ Импортируйте Postman коллекцию
3. ✅ Попробуйте API через http://localhost:8080
4. ✅ Изучите [COMMANDS.md](COMMANDS.md) для всех команд
5. ✅ Настройте [локальную разработку](docs/LOCAL_DEVELOPMENT.md)

---

**🎉 Готово! MetaChat запущен и готов к работе!**
