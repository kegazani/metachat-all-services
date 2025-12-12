# 🚀 MetaChat - AI-Powered Dating Platform

> **👉 Новый пользователь? Начните здесь: [QUICK_START.md](QUICK_START.md)**  
> **💻 Шпаргалка команд: [COMMANDS.md](COMMANDS.md)**

MetaChat - современная платформа знакомств с AI-анализом личности, настроения и умным подбором пар.

## ✨ Особенности

- 🎭 **Психологический анализ** - профили на основе Big Five
- 😊 **Анализ настроения** - AI-анализ эмоций из текста
- 💓 **Биометрическая интеграция** - данные с фитнес-трекеров
- 🤝 **Умный матчинг** - подбор на основе совместимости
- 💬 **Реал-тайм чат** - мгновенные сообщения
- 📊 **Мониторинг** - Grafana, Prometheus, Swarmpit

## 🚀 Быстрый старт

### Docker Compose (для разработки)

```bash
cd docker
./deploy-full.sh
```

### Docker Swarm (для продакшена)

```bash
cd docker
./deploy-swarm.sh
```

**Время:** 10-20 минут | **Результат:** Все сервисы запущены!

## 🌐 После запуска

| Сервис | URL | Credentials |
|--------|-----|-------------|
| API Gateway | http://localhost:8080 | - |
| Swarmpit (Swarm UI) | http://localhost:888 | Создать при входе |
| Grafana | http://localhost:3000 | admin / metachat2024 |
| Prometheus | http://localhost:9090 | - |
| Kafka UI | http://localhost:8090 | - |

## 📝 Основные команды

### Docker Compose

```bash
./deploy-full.sh      # Деплой
./stop-all.sh         # Остановка
./status.sh           # Статус
./logs.sh kafka       # Логи
```

### Docker Swarm

```bash
./deploy-swarm.sh              # Первый деплой
./redeploy-swarm.sh all        # Редеплой
./stop-swarm.sh all            # Остановка
./status-swarm.sh              # Статус
./logs-swarm.sh kafka -f       # Логи
```

## 🏗️ Архитектура

### Микросервисы

**Go сервисы:**
- `api-gateway` - точка входа API
- `user-service` - пользователи
- `diary-service` - дневник
- `matching-service` - подбор пар
- `chat-service` - чат

**Python AI/ML сервисы:**
- `mood-analysis-service` - анализ настроения
- `archetype-service` - психологические профили
- `analytics-service` - аналитика
- `biometric-service` - биометрия
- `correlation-service` - корреляции

### Инфраструктура

- **Kafka** - event streaming
- **Cassandra** - time-series данные
- **PostgreSQL** - реляционные данные
- **EventStore** - event sourcing
- **Prometheus + Grafana** - мониторинг
- **Swarmpit** - UI для Swarm

## 📖 Документация

| Документ | Описание |
|----------|----------|
| [QUICK_START.md](QUICK_START.md) | Быстрый старт |
| [COMMANDS.md](COMMANDS.md) | Все команды |
| [docker/README.md](docker/README.md) | Docker деплой |
| [docker/SWARMPIT_GUIDE.md](docker/SWARMPIT_GUIDE.md) | Swarmpit UI |
| [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) | Полный гайд деплоя |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Архитектура |
| [docs/LOCAL_DEVELOPMENT.md](docs/LOCAL_DEVELOPMENT.md) | Локальная разработка |

## 🔧 Разработка

### Структура проекта

```
metachat/
├── docker/                    # Docker конфигурации и скрипты
├── metachat-all-services/     # Все микросервисы
│   ├── metachat-api-gateway/
│   ├── metachat-user-service/
│   ├── metachat-mood-analysis-service/
│   └── ...
├── metachat-frontend/         # Vue.js web
├── metachat_app/              # Flutter mobile
└── docs/                      # Документация
```

### Локальная разработка

```bash
# Запустить инфраструктуру
cd docker
docker compose -f docker-compose.infrastructure.yml up -d

# Запустить сервис локально
cd metachat-all-services/metachat-user-service
go run cmd/main.go
```

## 📊 API

### Health Check

```bash
curl http://localhost:8080/health
```

### Postman Collection

Импортируйте `MetaChat_API.postman_collection.json`

## 🐛 Troubleshooting

```bash
# Логи
./logs.sh all              # Compose
./logs-swarm.sh kafka -f   # Swarm

# Статус
./status.sh                # Compose
./status-swarm.sh          # Swarm

# Перезапуск
./stop-all.sh && ./deploy-full.sh              # Compose
./stop-swarm.sh all && ./deploy-swarm.sh       # Swarm
```

## 🤝 Contributing

1. Fork репозитория
2. Создайте feature branch
3. Commit изменения
4. Push и создайте PR

## 📄 License

MIT License

---

**⭐ Поставьте звезду если проект понравился!**
