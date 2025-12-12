# Локальная разработка

## Проблема подключения к EventStoreDB

При локальном запуске сервисов (не в Docker) они не могут найти хост `eventstore`, так как это имя доступно только внутри Docker сети.

## Решение

### Вариант 1: Использовать localhost (рекомендуется для локальной разработки)

Конфигурация уже обновлена для использования `localhost:2113` по умолчанию.

**Для локального запуска:**
- EventStoreDB должен быть доступен на `localhost:2113`
- Убедитесь, что порт 2113 проброшен из Docker:
  ```bash
  docker port eventstore | grep 2113
  ```

### Вариант 2: Использовать переменные окружения

Вы можете переопределить URL через переменную окружения:

```bash
export EVENT_STORE_URL=http://localhost:2113
go run cmd/main.go
```

### Вариант 3: Добавить запись в /etc/hosts

Добавьте в `/etc/hosts`:
```
127.0.0.1 eventstore
```

Тогда можно использовать `eventstore:2113` и локально, и в Docker.

## Запуск в Docker

При запуске в Docker контейнере переменные окружения из `docker-compose.services.yml` автоматически переопределяют значения из конфига:

```yaml
environment:
  - EVENT_STORE_URL=http://eventstore:2113
```

Это означает, что:
- **Локально**: используется `localhost:2113` из config.yaml
- **В Docker**: используется `eventstore:2113` из переменной окружения

## Проверка подключения

### Локально:
```bash
curl http://localhost:2113/health/live
```

### В Docker:
```bash
docker exec -it diary-service curl http://eventstore:2113/health/live
```

## Текущая конфигурация

- **config.yaml**: `http://localhost:2113` (для локальной разработки)
- **docker-compose.services.yml**: `EVENT_STORE_URL=http://eventstore:2113` (для Docker)
- **Код**: проверяет переменную окружения `EVENT_STORE_URL`, затем config.yaml, затем дефолт `localhost:2113`

