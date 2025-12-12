# Централизованное логирование MetaChat

## Компоненты

- **Loki** - система сбора и хранения логов
- **Promtail** - агент для отправки логов в Loki
- **Grafana** - визуализация логов

## Запуск

Для запуска инфраструктуры логирования используйте профиль `monitoring`:

```bash
docker-compose -f docker/docker-compose.infrastructure.yml --profile monitoring up -d
```

## Доступ

- **Grafana**: http://localhost:3000
  - Логин: `admin`
  - Пароль: `admin`
- **Loki**: http://localhost:3100

## Correlation ID

Все запросы теперь автоматически получают correlation ID, который передается через:
- HTTP заголовок `X-Correlation-ID`
- gRPC metadata `correlation_id`

Correlation ID позволяет отслеживать запросы через все сервисы в одном месте.

## Использование в Grafana

1. Откройте Grafana: http://localhost:3000
2. Перейдите в раздел "Explore"
3. Выберите datasource "Loki"
4. Используйте LogQL запросы для фильтрации логов:

### Примеры запросов

- Все логи: `{service=~".+"}`
- Логи конкретного сервиса: `{service="user-service"}`
- Логи по correlation ID: `{correlation_id="<id>"}`
- Ошибки: `{level="error"}`
- Комбинация: `{service="user-service", level="error"}`

### Дашборд

Дашборд "MetaChat Services Logs" автоматически загружается при первом запуске Grafana.

## Конфигурация

- `loki-config.yaml` - конфигурация Loki
- `promtail-config.yaml` - конфигурация Promtail
- `grafana/provisioning/` - автоматическая настройка Grafana

