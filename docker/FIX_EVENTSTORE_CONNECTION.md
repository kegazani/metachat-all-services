# Исправление подключения к EventStoreDB

## Проблема
Сервисы не могут подключиться к EventStoreDB: `dial tcp: lookup eventstore: no such host`

## Решение

### 1. Убедитесь, что EventStoreDB запущен
```bash
cd /Users/kgz/Desktop/metachat/docker
docker-compose -f docker-compose.infrastructure.yml up -d eventstore
```

### 2. Убедитесь, что сеть создана
```bash
docker network ls | grep metachat_network
```

Если сети нет, создайте её:
```bash
docker network create metachat_network
```

### 3. Перезапустите сервисы с правильной сетью

**Вариант A: Использовать оба файла вместе**
```bash
cd /Users/kgz/Desktop/metachat/docker
docker-compose -f docker-compose.infrastructure.yml -f docker-compose.services.yml up -d
```

**Вариант B: Перезапустить только сервисы (если инфраструктура уже запущена)**
```bash
cd /Users/kgz/Desktop/metachat/docker
docker-compose -f docker-compose.services.yml down
docker-compose -f docker-compose.services.yml up -d
```

### 4. Проверьте подключение
```bash
docker exec -it diary-service ping -c 2 eventstore
docker exec -it user-service ping -c 2 eventstore
```

### 5. Проверьте логи
```bash
docker logs diary-service | grep -i eventstore
docker logs user-service | grep -i eventstore
```

## Изменения в конфигурации

В `docker-compose.services.yml` добавлено:
- `networks: - metachat_network` для всех сервисов (api-gateway, user-service, diary-service, matching-service)
- Исправлена конфигурация сети в секции `networks`

## Примечание

EventStoreDB использует:
- Порт **2113** для HTTP/gRPC клиентских подключений
- Порт **1113** для TCP подключений
- URL должен быть: `http://eventstore:2113`

