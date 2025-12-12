# 🚀 MetaChat - AI-Powered Dating Platform

> **👉 Новый пользователь? Начните здесь: [START_HERE.md](START_HERE.md)**  
> **⚡ Быстрый старт: [QUICK_START.md](QUICK_START.md)**  
> **💻 Шпаргалка команд: [COMMANDS.md](COMMANDS.md)**

MetaChat - это современная платформа знакомств на основе микросервисной архитектуры с анализом настроения, психологическими профилями и умным подбором пар.

## ✨ Особенности

- 🎭 **Психологический анализ** - анализ личности на основе дневниковых записей
- 😊 **Анализ настроения** - AI-анализ эмоционального состояния
- 💓 **Биометрическая интеграция** - учет данных с фитнес-трекеров
- 🤝 **Умный матчинг** - подбор пар на основе совместимости
- 💬 **Реал-тайм чат** - мгновенный обмен сообщениями
- 📊 **Аналитика** - подробная статистика и инсайты
- 📈 **Мониторинг** - Grafana дашборды для всех метрик

## 🏗️ Архитектура

### Микросервисы

**Core Services (Go):**
- `api-gateway` - точка входа для всех запросов
- `user-service` - управление пользователями
- `diary-service` - личный дневник
- `matching-service` - алгоритмы подбора пар
- `match-request-service` - запросы на матчинг
- `chat-service` - система чата

**AI/ML Services (Python):**
- `mood-analysis-service` - анализ настроения из текста
- `analytics-service` - аналитика и статистика
- `archetype-service` - психологические архетипы (Big Five)
- `biometric-service` - обработка биометрических данных
- `correlation-service` - корреляция настроения и биометрии

### Инфраструктура

- **Kafka** - асинхронный обмен сообщениями
- **Cassandra** - хранение событий и временных рядов
- **PostgreSQL** - реляционные данные
- **EventStore** - event sourcing
- **NATS** - легковесный message broker
- **Prometheus + Grafana** - мониторинг
- **Loki + Promtail** - централизованные логи

## 🚀 Быстрый старт

### Требования

- Docker 20.10+
- Docker Compose 2.0+
- 8GB RAM (рекомендуется 16GB)
- 20GB свободного места на диске

### Установка и запуск

**Linux/Mac:**
```bash
git clone <repository-url>
cd metachat
cd docker
chmod +x deploy-full.sh
./deploy-full.sh
```

**Windows (PowerShell):**
```powershell
git clone <repository-url>
cd metachat
cd docker
.\deploy-full.ps1
```

Скрипт автоматически:
1. ✅ Проверит окружение
2. 🧹 Очистит старые контейнеры
3. 🌐 Создаст Docker сеть
4. 🔨 Соберет все Docker образы
5. 🚀 Запустит инфраструктуру
6. ⏳ Дождется готовности баз данных
7. 📝 Инициализирует схемы и топики
8. 🎯 Запустит все сервисы
9. 📊 Запустит мониторинг

**Время деплоя:** ~10-20 минут при первом запуске

### Доступ к сервисам

После запуска доступны:

**Приложение:**
- API Gateway: http://localhost:8080

**Мониторинг:**
- Grafana: http://localhost:3000 (admin / metachat2024)
- Prometheus: http://localhost:9090
- Kafka UI: http://localhost:8090

**Базы данных:**
- PostgreSQL: localhost:5432 (metachat / metachat_password)
- Cassandra: localhost:9042
- EventStore: http://localhost:2113

## 📖 Документация

- [📋 Quick Start Guide](QUICK_START.md) - подробное руководство по запуску
- [🐳 Docker Deployment](docker/README.md) - деплой и управление
- [🏛️ Architecture](docs/ARCHITECTURE.md) - архитектура системы
- [📊 Service Flow](docs/DETAILED_SERVICE_FLOW.md) - потоки данных
- [💻 Local Development](docs/LOCAL_DEVELOPMENT.md) - локальная разработка
- [📈 Flow Diagrams](docs/FLOW_DIAGRAMS.md) - диаграммы потоков

## 🛠️ Управление

### Просмотр логов

```bash
cd docker

./logs.sh all              # Все логи
./logs.sh infra            # Инфраструктура
./logs.sh services         # Приложения
./logs.sh api-gateway      # Конкретный сервис
```

### Проверка статуса

```bash
./status.sh                # Показать статус и URLs
```

### Остановка

```bash
./stop-all.sh              # Остановить все сервисы
```

### Перезапуск сервиса

```bash
cd docker
docker compose -f docker-compose.services.yml restart api-gateway
```

## 🔧 Разработка

### Структура проекта

```
metachat/
├── metachat-all-services/     # Все микросервисы
│   ├── metachat-api-gateway/
│   ├── metachat-user-service/
│   ├── metachat-diary-service/
│   ├── metachat-matching-service/
│   ├── metachat-match-request-service/
│   ├── metachat-chat-service/
│   ├── metachat-mood-analysis-service/
│   ├── metachat-analytics-service/
│   ├── metachat-archetype-service/
│   ├── metachat-biometric-service/
│   └── metachat-correlation-service/
├── metachat-frontend/         # Vue.js фронтенд
├── metachat_app/              # Flutter mobile app
├── docker/                    # Docker конфигурация
│   ├── deploy-full.sh/ps1    # Полный деплой
│   ├── stop-all.sh/ps1       # Остановка
│   ├── logs.sh/ps1           # Просмотр логов
│   ├── status.sh/ps1         # Статус
│   └── monitoring/           # Prometheus, Grafana
└── docs/                      # Документация
```

### Пересборка сервиса

```bash
cd docker
docker compose -f docker-compose.services.yml build user-service
docker compose -f docker-compose.services.yml up -d user-service
```

### Подключение к базам

**Cassandra:**
```bash
docker exec -it cassandra cqlsh
USE metachat;
DESCRIBE TABLES;
```

**PostgreSQL:**
```bash
docker exec -it postgres psql -U metachat -d metachat
\dt
```

## 📊 API Examples

### Регистрация пользователя

```bash
curl -X POST http://localhost:8080/api/v1/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "securepass123",
    "name": "John Doe",
    "birth_date": "1990-01-01",
    "gender": "male"
  }'
```

### Создание дневниковой записи

```bash
curl -X POST http://localhost:8080/api/v1/diary/entries \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Great day!",
    "content": "Today was amazing, feeling very happy and energetic!",
    "mood": "happy"
  }'
```

### Получение рекомендаций

```bash
curl -X GET http://localhost:8080/api/v1/matching/recommendations \
  -H "Authorization: Bearer <token>"
```

## 🧪 Тестирование

### Postman Collection

Импортируйте коллекцию:
- Файл: `MetaChat_API.postman_collection.json`
- Базовый URL: `http://localhost:8080`

### Health Checks

```bash
curl http://localhost:8080/health
curl http://localhost:9090/-/healthy    # Prometheus
curl http://localhost:3100/ready        # Loki
```

## 📈 Мониторинг

### Grafana Dashboards

После запуска откройте http://localhost:3000:
- Логин: `admin`
- Пароль: `metachat2024`

Предустановленные дашборды:
- **MetaChat Services** - общий обзор сервисов
- **Kafka Monitoring** - метрики Kafka
- **Database Performance** - производительность БД
- **System Resources** - использование ресурсов

### Prometheus Metrics

Примеры запросов (http://localhost:9090):

```promql
rate(http_requests_total[5m])
container_memory_usage_bytes{name="api-gateway"}
kafka_server_brokertopicmetrics_messagesin_total
```

### Kafka UI

http://localhost:8090 - просмотр топиков и сообщений

## 🐛 Troubleshooting

### Проверка Docker

```bash
docker --version
docker compose version
docker info
```

### Очистка

```bash
cd docker
docker compose -f docker-compose.infrastructure.yml down -v
docker compose -f docker-compose.services.yml down -v
docker system prune -a -f
```

### Проблемы с портами

Проверьте, что порты свободны:
```bash
netstat -an | grep -E '8080|9092|5432|9042'
```

### Логи ошибок

```bash
cd docker
./logs.sh kafka
./logs.sh cassandra
./logs.sh api-gateway
```

## 📦 Технологии

**Backend:**
- Go 1.21+ (core services)
- Python 3.11+ (AI/ML services)
- gRPC для межсервисного взаимодействия
- REST API для клиентов

**Frontend:**
- Vue.js 3 (web)
- Flutter (mobile)

**Infrastructure:**
- Docker & Docker Compose
- Kafka для event streaming
- Cassandra для time-series данных
- PostgreSQL для реляционных данных
- EventStore для event sourcing
- NATS для lightweight messaging

**Monitoring:**
- Prometheus - метрики
- Grafana - визуализация
- Loki - логи
- Promtail - сборка логов

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License.

## 👥 Team

Разработано с ❤️ командой MetaChat

## 📞 Support

- 📧 Email: support@metachat.com
- 💬 Discord: [MetaChat Community]
- 📖 Docs: [docs.metachat.com]

---

**⭐ Если проект понравился, поставьте звезду!**

