# MetaChat Docker Swarm & Monitoring Setup

Полное руководство по настройке Docker Swarm с приватным registry, мониторингом в реальном времени и CI/CD от GitHub.

## 🎯 Обзор системы

### Компоненты

1. **Docker Swarm** - оркестрация контейнеров с автоматическим восстановлением
2. **Private Registry** - локальный Docker registry для хранения образов
3. **Prometheus** - сбор метрик в реальном времени
4. **Grafana** - визуализация метрик и дашборды
5. **Traefik** - reverse proxy и балансировка нагрузки
6. **GitHub Actions** - CI/CD pipeline

## 🚀 Быстрый старт

### Windows (PowerShell)

```powershell
cd docker
.\swarm-init.ps1 all
```

### Linux/Mac

```bash
cd docker
chmod +x swarm-init.sh
./swarm-init.sh all
```

## 📦 Компоненты по шагам

### 1. Инициализация Swarm

```bash
docker swarm init --advertise-addr <YOUR_IP>

docker network create --driver overlay --attachable metachat_network
```

### 2. Запуск Private Registry

```bash
docker service create \
    --name registry \
    --publish 5000:5000 \
    --constraint 'node.role == manager' \
    --mount type=volume,source=registry_data,target=/var/lib/registry \
    registry:2
```

### 3. Сборка и загрузка образов

```bash
docker build -t localhost:5000/metachat/api-gateway:latest \
    -f metachat-all-services/metachat-api-gateway/Dockerfile \
    metachat-all-services/

docker push localhost:5000/metachat/api-gateway:latest
```

### 4. Деплой стека

```bash
export REGISTRY=localhost:5000
export TAG=latest
docker stack deploy -c docker/docker-compose.swarm.yml metachat
```

## 📊 Мониторинг

### Доступ к интерфейсам

| Сервис | URL | Логин |
|--------|-----|-------|
| Grafana | http://localhost:3000 | admin / metachat2024 |
| Prometheus | http://localhost:9090 | - |
| Registry UI | http://localhost:5001 | - |
| Traefik Dashboard | http://localhost:8088 | - |
| Swarm Visualizer | http://localhost:5002 | - |

### Grafana Dashboard

После входа в Grafana перейдите в **Dashboards → MetaChat → MetaChat Services Health**

Дашборд показывает:
- Статус каждого сервиса (UP/DOWN)
- Общий процент доступности
- История uptime
- Статус инфраструктуры (Kafka, Cassandra, PostgreSQL, etc.)

### Prometheus Метрики

Доступные метрики:
- `up{job="<service-name>"}` - статус сервиса
- `http_requests_total` - количество HTTP запросов
- `http_request_duration_seconds` - время ответа

## 🔄 CI/CD Pipeline

### GitHub Secrets

Настройте следующие secrets в GitHub:

**Для staging:**
- `STAGING_HOST` - IP/hostname staging сервера
- `STAGING_USER` - SSH пользователь
- `STAGING_SSH_KEY` - SSH приватный ключ
- `STAGING_PATH` - путь к проекту на сервере

**Для production:**
- `PRODUCTION_HOST` - IP/hostname production сервера
- `PRODUCTION_USER` - SSH пользователь
- `PRODUCTION_SSH_KEY` - SSH приватный ключ
- `PRODUCTION_PATH` - путь к проекту на сервере

**Для приватного registry (опционально):**
- `PRIVATE_REGISTRY_URL` - URL приватного registry
- `PRIVATE_REGISTRY_USER` - пользователь registry
- `PRIVATE_REGISTRY_PASSWORD` - пароль registry

### Workflow триггеры

| Ветка | Действие |
|-------|----------|
| `develop` | Build → Push → Deploy to Staging |
| `main/master` | Build → Push → Deploy to Production |
| Pull Request | Build only (no push) |
| Manual | Choose environment |

### Ручной запуск

1. Перейдите в **Actions** → **CI/CD Pipeline**
2. Нажмите **Run workflow**
3. Выберите окружение (staging/production)

## 🐝 Управление Swarm

### Просмотр сервисов

```bash
docker service ls
```

### Масштабирование сервиса

```bash
docker service scale metachat_api-gateway=3
```

### Обновление сервиса

```bash
docker service update --image localhost:5000/metachat/api-gateway:v2 metachat_api-gateway
```

### Просмотр логов

```bash
docker service logs -f metachat_api-gateway
```

### Откат обновления

```bash
docker service rollback metachat_api-gateway
```

## 🔧 Конфигурация

### Переменные окружения

```bash
REGISTRY=localhost:5000
TAG=latest
GRAFANA_PASSWORD=metachat2024
```

### Репликация сервисов

В `docker-compose.swarm.yml` настройте количество реплик:

```yaml
deploy:
  mode: replicated
  replicas: 2
```

### Health checks

Каждый сервис имеет health check:

```yaml
healthcheck:
  test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8080/health"]
  interval: 15s
  timeout: 5s
  retries: 3
```

## 🔒 Безопасность

### Registry с авторизацией

```bash
docker run -d \
  --name registry \
  -v auth:/auth \
  -e REGISTRY_AUTH=htpasswd \
  -e REGISTRY_AUTH_HTPASSWD_REALM="Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
  -p 5000:5000 \
  registry:2
```

### TLS для Traefik

Добавьте сертификаты в конфигурацию Traefik для HTTPS.

## 🐛 Troubleshooting

### Сервис не запускается

```bash
docker service ps <service_name> --no-trunc
```

### Проблемы с сетью

```bash
docker network inspect metachat_network
```

### Registry недоступен

```bash
docker service logs registry
curl -X GET http://localhost:5000/v2/_catalog
```

### Prometheus не собирает метрики

1. Проверьте targets: http://localhost:9090/targets
2. Проверьте конфиг: `docker/monitoring/prometheus.yml`

## 📈 Рекомендации по продакшену

1. **Используйте минимум 3 manager nodes** для отказоустойчивости
2. **Настройте backup** для volumes
3. **Включите TLS** для всех сервисов
4. **Настройте alerting** в Grafana/Prometheus
5. **Используйте secrets** для паролей:

```bash
echo "password" | docker secret create db_password -
```

## 📚 Полезные ссылки

- [Docker Swarm Documentation](https://docs.docker.com/engine/swarm/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

