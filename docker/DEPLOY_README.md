# MetaChat Deployment Guide

## Проблема: "pull access denied" 

Если вы получаете ошибку `pull access denied for metachat/...`, это значит что Docker пытается загрузить образы из Docker Hub, но их там нет.

## Решение: Сборка образов локально

### Вариант 1: Быстрый деплой (Build + Deploy в одном скрипте)

```bash
cd ~/metachat/docker
chmod +x build-and-deploy.sh
./build-and-deploy.sh
```

Этот скрипт:
1. Соберет все Docker образы из исходников
2. Запустит инфраструктуру (Kafka, PostgreSQL, Cassandra)
3. Запустит все сервисы приложения

---

### Вариант 2: Раздельная сборка и деплой (рекомендуется)

#### Шаг 1: Собрать образы

```bash
cd ~/metachat/docker
chmod +x build-images.sh
./build-images.sh
```

Скрипт соберет все необходимые Docker образы локально.

#### Шаг 2: Задеплоить сервисы

```bash
chmod +x deploy-local.sh
./deploy-local.sh
```

---

## Структура скриптов

### `build-images.sh`
- Собирает все Docker образы из `metachat-all-services/`
- Тегирует образы как `metachat/<service>:latest`
- Показывает список собранных образов

### `deploy-local.sh`
- Проверяет наличие собранных образов
- Запускает сервисы в правильном порядке:
  1. Infrastructure (Kafka, PostgreSQL, Cassandra)
  2. Application Services (User, Diary, Matching, Chat)
  3. AI/ML Services (Mood Analysis, Analytics, etc.)
  4. API Gateway

### `build-and-deploy.sh`
- Комбинация двух предыдущих скриптов
- Удобно для первого запуска

---

## Полезные команды

### Просмотр логов

```bash
cd ~/metachat/docker

# Все сервисы
docker compose -f docker-compose.production-light.yml logs -f

# Конкретный сервис
docker compose -f docker-compose.production-light.yml logs -f user-service
```

### Перезапуск сервиса

```bash
docker compose -f docker-compose.production-light.yml restart user-service
```

### Остановка всех сервисов

```bash
docker compose -f docker-compose.production-light.yml down
```

### Проверка статуса

```bash
docker compose -f docker-compose.production-light.yml ps
```

### Пересборка образа конкретного сервиса

```bash
cd ~/metachat

docker build \
    -t metachat/user-service:latest \
    -f metachat-all-services/metachat-user-service/Dockerfile \
    metachat-all-services/

# Перезапустить сервис
cd docker
docker compose -f docker-compose.production-light.yml up -d user-service
```

---

## Требования к системе

- **RAM**: минимум 8GB (рекомендуется 16GB)
- **CPU**: минимум 4 cores
- **Disk**: минимум 50GB свободного места
- **Docker**: версия 20.10+
- **Docker Compose**: V2 (команда `docker compose`)

---

## Устранение проблем

### Проблема: "Cannot connect to the Docker daemon"

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

### Проблема: Недостаточно памяти

Остановите ненужные сервисы или добавьте swap:

```bash
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### Проблема: Порты заняты

Проверьте какие порты используются:

```bash
sudo netstat -tulpn | grep LISTEN
```

Измените порты в `docker-compose.production-light.yml` если нужно.

### Проблема: Контейнер не запускается

Посмотрите логи:

```bash
docker compose -f docker-compose.production-light.yml logs <service-name>
```

---

## CI/CD: Автоматическая сборка и деплой

Для продакшена рекомендуется настроить CI/CD pipeline:

1. **GitHub Actions / GitLab CI**: автоматическая сборка образов
2. **Container Registry**: публикация образов (ghcr.io, Docker Hub, или приватный)
3. **Deployment**: использование готовых образов из registry

См. также: `docs/CI-CD-SETUP.md`

