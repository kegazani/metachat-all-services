# Инструкция по деплою сервисов MetaChat

Этот документ описывает процесс настройки и деплоя всех сервисов MetaChat через GitHub Actions.

## 📋 Предварительная настройка

### 1. Настройка сервера

#### Установка Docker и Docker Swarm

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

docker swarm init
```

#### Создание Docker overlay сети

```bash
docker network create --driver overlay metachat_overlay
```

#### Примечание об инфраструктуре

⚠️ **Важно:** Инфраструктура (Kafka, Cassandra, PostgreSQL, EventStore) должна быть запущена на **отдельном сервере**. 

Если инфраструктура еще не настроена, запустите её на сервере инфраструктуры:

```bash
cd docker
docker-compose -f docker-compose.infrastructure.yml up -d
```

Убедитесь, что порты инфраструктуры доступны с сервера, где деплоятся сервисы:
- Cassandra: `9042`
- Kafka: `29092`
- PostgreSQL: `5432`
- EventStore: `2113`

### 2. Настройка SSH доступа

#### Создание SSH ключа для GitHub Actions

На вашем локальном компьютере:

```bash
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/github_actions_deploy
```

#### Копирование публичного ключа на сервер

```bash
ssh-copy-id -i ~/.ssh/github_actions_deploy.pub user@your-server-ip
```

Или вручную:

```bash
cat ~/.ssh/github_actions_deploy.pub | ssh user@your-server-ip "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

#### Проверка подключения

```bash
ssh -i ~/.ssh/github_actions_deploy user@your-server-ip
```

### 3. Настройка GitHub Secrets

Перейдите в ваш GitHub репозиторий:
**Settings → Secrets and variables → Actions → New repository secret**

#### Основные secrets для деплоя:

- **`SERVICES_SSH_KEY`** - Приватный SSH ключ (содержимое файла `~/.ssh/github_actions_deploy`)
  ```bash
  cat ~/.ssh/github_actions_deploy
  ```

- **`SERVICES_HOST`** - IP адрес или домен сервера, где деплоятся сервисы
  - Пример: `192.168.1.100` или `deploy.example.com`

- **`SERVICES_USER`** - Пользователь для SSH подключения к серверу сервисов
  - Пример: `ubuntu`, `deploy`, `root`

#### Secrets для инфраструктуры (на другом сервере):

- **`INFRA_CASSANDRA_HOST`** - Адрес Cassandra на сервере инфраструктуры
  - Пример: `infra-server:9042` или `192.168.1.200:9042`

- **`INFRA_KAFKA_HOST`** - Адрес Kafka на сервере инфраструктуры
  - Пример: `infra-server:29092` или `192.168.1.200:29092`

- **`INFRA_EVENTSTORE_URL`** - URL EventStore на сервере инфраструктуры
  - Пример: `http://infra-server:2113` или `http://192.168.1.200:2113`

- **`INFRA_EVENTSTORE_USERNAME`** - Имя пользователя EventStore
  - Пример: `admin`

- **`INFRA_EVENTSTORE_PASSWORD`** - Пароль EventStore
  - Пример: `changeit`

- **`INFRA_POSTGRES_HOST`** - Адрес PostgreSQL на сервере инфраструктуры
  - Пример: `infra-server:5432` или `192.168.1.200:5432`

- **`INFRA_POSTGRES_USER`** - Пользователь PostgreSQL
  - Пример: `postgres`

- **`INFRA_POSTGRES_PASSWORD`** - Пароль PostgreSQL
  - Пример: `postgres`

- **`INFRA_POSTGRES_DB`** - Имя базы данных
  - Пример: `metachat`

#### Secrets для API Gateway (адреса других сервисов):

- **`SERVICES_USER_SERVICE_ADDRESS`** - Адрес user-service
  - Пример: `user-service:50051` (если в одной сети) или `192.168.1.100:50051`

- **`SERVICES_DIARY_SERVICE_ADDRESS`** - Адрес diary-service
  - Пример: `diary-service:50052`

- **`SERVICES_MATCHING_SERVICE_ADDRESS`** - Адрес matching-service
  - Пример: `matching-service:50053`

- **`SERVICES_MATCH_REQUEST_SERVICE_ADDRESS`** - Адрес match-request-service
  - Пример: `match-request-service:50054`

- **`SERVICES_CHAT_SERVICE_ADDRESS`** - Адрес chat-service
  - Пример: `chat-service:50055`

## 🚀 Процесс деплоя

### Автоматический деплой

Каждый сервис имеет свой workflow файл в `.github/workflows/deploy.yml`. 

**Деплой происходит автоматически при push в ветку `main`:**

```bash
git add .
git commit -m "Update service"
git push origin main
```

### Что происходит при деплое

1. **GitHub Actions запускает workflow** для измененного сервиса
2. **Checkout кода** - Клонирование репозитория
3. **SSH подключение** - Подключение к серверу через SSH
4. **Копирование файлов** - Синхронизация кода через `rsync`
5. **Сборка Docker образа** - `docker build -t metachat/service-name:latest .`
6. **Обновление/создание Docker service** - Обновление существующего или создание нового сервиса в Docker Swarm

### Ручной запуск деплоя

1. Перейдите в **Actions** в GitHub
2. Выберите нужный workflow (например, "Deploy User Service")
3. Нажмите **Run workflow**
4. Выберите ветку и нажмите **Run workflow**

## 📦 Структура деплоя

### Расположение на сервере

Все сервисы деплоятся в:
```
/opt/metachat-services/
├── api-gateway/
├── user-service/
├── diary-service/
├── matching-service/
├── match-request-service/
├── chat-service/
├── mood-analysis-service/
├── analytics-service/
├── archetype-service/
├── biometric-service/
├── correlation-service/
└── event-sourcing/
```

### Docker Services

Каждый сервис создается как Docker Swarm service:

```bash
docker service ls
```

Вы увидите список всех сервисов:
- `metachat-services_api-gateway`
- `metachat-services_user-service`
- `metachat-services_diary-service`
- и т.д.

## 🔍 Проверка статуса деплоя

### Просмотр логов в GitHub Actions

1. Перейдите в **Actions** в GitHub
2. Выберите нужный workflow run
3. Просмотрите логи шага "Build and deploy"

### Проверка на сервере

#### Список всех сервисов

```bash
docker service ls
```

#### Статус конкретного сервиса

```bash
docker service ps metachat-services_user-service
```

#### Логи сервиса

```bash
docker service logs metachat-services_user-service
```

#### Проверка сети

```bash
docker network inspect metachat_overlay
```

## 🛠️ Управление сервисами

### Перезапуск сервиса

```bash
docker service update --force metachat-services_user-service
```

### Масштабирование сервиса

```bash
docker service scale metachat-services_user-service=3
```

### Удаление сервиса

```bash
docker service rm metachat-services_user-service
```

### Просмотр конфигурации сервиса

```bash
docker service inspect metachat-services_user-service
```

## 🐛 Troubleshooting

### Ошибка SSH подключения

**Проблема:** `Permission denied (publickey)`

**Решение:**
1. Проверьте, что приватный ключ правильно скопирован в GitHub Secrets
2. Убедитесь, что публичный ключ добавлен на сервер:
   ```bash
   ssh user@server "cat ~/.ssh/authorized_keys"
   ```
3. Проверьте права доступа на сервере:
   ```bash
   ssh user@server "chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"
   ```

### Ошибка при сборке Docker образа

**Проблема:** `docker build` завершается с ошибкой

**Решение:**
1. Подключитесь к серверу и проверьте вручную:
   ```bash
   ssh user@server
   cd /opt/metachat-services/user-service
   docker build -t metachat/user-service:latest .
   ```
2. Проверьте Dockerfile на наличие ошибок
3. Убедитесь, что все зависимости доступны

### Сервис не запускается

**Проблема:** Сервис создан, но не работает

**Решение:**
1. Проверьте логи:
   ```bash
   docker service logs metachat-services_user-service
   ```
2. Убедитесь, что сеть создана:
   ```bash
   docker network ls | grep metachat_overlay
   ```
3. Проверьте, что инфраструктура запущена (Kafka, Cassandra, PostgreSQL и т.д.)

### Ошибка "network metachat_overlay not found"

**Решение:**
```bash
docker network create --driver overlay metachat_overlay
```

### Сервис не может подключиться к другим сервисам

**Проблема:** Сервисы не видят друг друга в сети

**Решение:**
1. Убедитесь, что все сервисы в одной сети:
   ```bash
   docker service inspect metachat-services_user-service | grep Network
   ```
2. Проверьте DNS резолвинг:
   ```bash
   docker service exec metachat-services_user-service ping api-gateway
   ```

## 📊 Мониторинг

### Просмотр использования ресурсов

```bash
docker stats
```

### Просмотр событий Docker Swarm

```bash
docker service events
```

## 🔄 Обновление всех сервисов

Для обновления всех сервисов одновременно:

1. Сделайте push в main ветку для каждого сервиса
2. Или используйте скрипт на сервере:

```bash
#!/bin/bash
services=("api-gateway" "user-service" "diary-service" "matching-service" "match-request-service" "chat-service" "mood-analysis-service" "analytics-service" "archetype-service" "biometric-service" "correlation-service" "event-sourcing")

for service in "${services[@]}"; do
  echo "Updating $service..."
  docker service update --force metachat-services_${service//-/_}
done
```

## 🔐 Безопасность

### Рекомендации

1. **Используйте отдельный SSH ключ** только для CI/CD
2. **Ограничьте права доступа** пользователя на сервере
3. **Используйте firewall** для ограничения доступа к портам
4. **Регулярно обновляйте** Docker и систему
5. **Используйте secrets** для хранения паролей и ключей

### Настройка пользователя с ограниченными правами

```bash
sudo useradd -m -s /bin/bash deploy
sudo usermod -aG docker deploy
sudo mkdir -p /opt/metachat-services
sudo chown -R deploy:deploy /opt/metachat-services
```

## 📝 Список всех сервисов

Всего настроено **12 сервисов** с автоматическим деплоем:

1. ✅ `metachat-api-gateway`
2. ✅ `metachat-user-service`
3. ✅ `metachat-diary-service`
4. ✅ `metachat-matching-service`
5. ✅ `metachat-match-request-service`
6. ✅ `metachat-chat-service`
7. ✅ `metachat-mood-analysis-service`
8. ✅ `metachat-analytics-service`
9. ✅ `metachat-archetype-service`
10. ✅ `metachat-biometric-service`
11. ✅ `metachat-correlation-service`
12. ✅ `metachat-event-sourcing`

## 🎉 Готово!

После настройки каждый push в main ветку будет автоматически деплоить соответствующий сервис!

Для проверки работы:
1. Сделайте небольшое изменение в любом сервисе
2. Закоммитьте и запушьте в main
3. Перейдите в Actions и наблюдайте за деплоем
4. Проверьте статус на сервере: `docker service ls`

