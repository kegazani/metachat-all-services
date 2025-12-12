# 🐝 Docker Swarm Deployment для MetaChat

## Преимущества Docker Swarm над docker-compose

✅ **High Availability** - автоматический перезапуск упавших контейнеров  
✅ **Load Balancing** - встроенный балансировщик нагрузки  
✅ **Scaling** - легкое масштабирование сервисов  
✅ **Rolling Updates** - обновление без даунтайма  
✅ **Secrets Management** - безопасное хранение секретов  
✅ **Service Discovery** - автоматическое обнаружение сервисов  
✅ **Overlay Networks** - изолированные сети между узлами  

---

## 🚀 Быстрый старт

### 1. Инициализация Swarm

```bash
cd docker
chmod +x deploy-swarm.sh

./deploy-swarm.sh
```

Или для Windows:
```powershell
cd docker
.\deploy-swarm.ps1
```

### 2. Проверка статуса

```bash
docker stack ls
docker stack ps metachat-infra
docker stack ps metachat-services
```

---

## 📋 Основные команды

### Управление стеками

```bash
docker stack ls

docker stack deploy -c docker-stack-infrastructure.yml metachat-infra

docker stack deploy -c docker-stack-services.yml metachat-services

docker stack rm metachat-infra
docker stack rm metachat-services

docker stack ps metachat-infra --no-trunc

docker stack services metachat-services
```

### Управление сервисами

```bash
docker service ls

docker service ps metachat-services_api-gateway

docker service logs metachat-services_api-gateway --follow

docker service logs metachat-services_api-gateway --tail 100

docker service inspect metachat-services_api-gateway --pretty

docker service update --image metachat/api-gateway:v2 metachat-services_api-gateway

docker service scale metachat-services_api-gateway=4

docker service rollback metachat-services_api-gateway
```

### Мониторинг

```bash
docker stats

docker node ls

docker service ls --format "table {{.Name}}\t{{.Replicas}}\t{{.Ports}}"

watch -n 2 'docker service ls'
```

---

## ⚖️ Масштабирование сервисов

### Автоматическое масштабирование (рекомендуется)

Уже настроено в `docker-stack-services.yml`:

```yaml
deploy:
  mode: replicated
  replicas: 2
```

### Ручное масштабирование

```bash
docker service scale metachat-services_api-gateway=5

docker service scale \
  metachat-services_api-gateway=5 \
  metachat-services_user-service=4 \
  metachat-services_diary-service=4

docker service ps metachat-services_api-gateway
```

### Рекомендации по количеству реплик

| Сервис | Replicas | Причина |
|--------|----------|---------|
| api-gateway | 2-4 | Главная точка входа, высокая нагрузка |
| user-service | 2-3 | Частые запросы |
| diary-service | 2-3 | Частые запросы |
| matching-service | 2 | Среднее использование |
| mood-analysis | 2-3 | AI/ML, требует ресурсов |
| archetype | 2 | AI/ML, требует ресурсов |
| analytics | 1-2 | Низкая приоритетность |
| correlation | 1 | Фоновая обработка |

---

## 🔄 Rolling Updates (обновление без даунтайма)

### Обновить образ сервиса

```bash
docker build -t metachat/api-gateway:v2.0 .

docker service update \
  --image metachat/api-gateway:v2.0 \
  --update-parallelism 1 \
  --update-delay 10s \
  metachat-services_api-gateway
```

### Процесс обновления

1. **Parallelism**: обновляет 1 контейнер за раз
2. **Delay**: ждет 10 секунд между обновлениями
3. **Order**: `start-first` - запускает новый перед остановкой старого

### Откат на предыдущую версию

```bash
docker service rollback metachat-services_api-gateway
```

---

## 🔐 Secrets Management

### Создание секрета

```bash
echo "my_super_secret_password" | docker secret create postgres_password -

docker secret ls
```

### Использование в stack

```yaml
services:
  postgres:
    secrets:
      - postgres_password
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password

secrets:
  postgres_password:
    external: true
```

---

## 📊 Мониторинг и логи

### Логи сервиса

```bash
docker service logs metachat-services_api-gateway --follow --tail 100

docker service logs metachat-services_api-gateway --since 30m

docker service logs metachat-services_api-gateway 2>&1 | grep ERROR
```

### Статус всех сервисов

```bash
#!/bin/bash
for service in $(docker service ls --format "{{.Name}}"); do
  echo "=== $service ==="
  docker service ps $service --filter "desired-state=running" --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}"
  echo ""
done
```

### Метрики

```bash
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
```

---

## 🌐 Networking

### Проверка сетей

```bash
docker network ls --filter driver=overlay

docker network inspect metachat_network

docker network inspect metachat_network --format='{{range .Containers}}{{.Name}} {{end}}'
```

### Подключить сервис к сети

```bash
docker service update --network-add metachat_network myservice
```

---

## 🔧 Troubleshooting

### Сервис не запускается

```bash
docker service ps metachat-services_api-gateway --no-trunc

docker service logs metachat-services_api-gateway --tail 200

docker service inspect metachat-services_api-gateway --pretty
```

### Узел недоступен

```bash
docker node ls

docker node inspect node-name --pretty

docker node update --availability drain node-name

docker node update --availability active node-name
```

### Сброс Swarm

```bash
docker stack rm metachat-services
docker stack rm metachat-infra

docker swarm leave --force

docker network rm metachat_network
```

---

## 🎯 Портирование с docker-compose на Swarm

### Основные отличия

| docker-compose | Docker Swarm |
|----------------|--------------|
| `restart: unless-stopped` | `deploy.restart_policy` |
| `depends_on` | Не поддерживается (используйте healthchecks) |
| `container_name` | Игнорируется (используется service name) |
| `build` | Не поддерживается (нужен готовый образ) |
| `links` | Не нужен (service discovery автоматический) |

### Пример миграции

**docker-compose.yml:**
```yaml
services:
  api:
    build: .
    restart: unless-stopped
    ports:
      - "8080:8080"
```

**docker-stack.yml:**
```yaml
services:
  api:
    image: metachat/api:latest
    ports:
      - "8080:8080"
    deploy:
      replicas: 2
      restart_policy:
        condition: on-failure
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
```

---

## 📈 Production Best Practices

### 1. Ресурсные лимиты

```yaml
deploy:
  resources:
    limits:
      cpus: '1.0'
      memory: 1024M
    reservations:
      cpus: '0.5'
      memory: 512M
```

### 2. Health checks

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

### 3. Placement constraints

```yaml
deploy:
  placement:
    constraints:
      - node.role == manager
      - node.labels.type == database
```

### 4. Update config

```yaml
deploy:
  update_config:
    parallelism: 2
    delay: 10s
    failure_action: rollback
    monitor: 30s
    order: start-first
```

---

## 🚨 Мониторинг производительности

### Prometheus метрики для Swarm

В `prometheus.yml` уже настроено:

```yaml
- job_name: 'docker-swarm'
  dockerswarm_sd_configs:
    - host: unix:///var/run/docker.sock
      role: tasks
```

### Алерты в Grafana

Настроены в `alerting-rules.yml`:
- SwarmNodeDown
- ServiceReplicasNotRunning
- HighCPUUsage
- HighMemoryUsage

---

## 🔗 Полезные ссылки

- [Docker Swarm Documentation](https://docs.docker.com/engine/swarm/)
- [Docker Stack Deploy](https://docs.docker.com/engine/reference/commandline/stack_deploy/)
- [Swarm Service Options](https://docs.docker.com/compose/compose-file/deploy/)
- [Production Ready Swarm](https://github.com/docker/swarm-microservice-demo-v1)

---

## ✅ Checklist перед продакшн деплоем

- [ ] Swarm инициализирован на всех узлах
- [ ] Overlay сеть создана
- [ ] Все образы собраны и protegированы
- [ ] Secrets настроены для паролей
- [ ] Ресурсные лимиты установлены
- [ ] Health checks работают
- [ ] Backup volumes настроен
- [ ] Мониторинг (Prometheus + Grafana) запущен
- [ ] Логирование (Loki) настроено
- [ ] Тестовый rolling update выполнен
- [ ] Rollback протестирован
- [ ] Firewall правила настроены
- [ ] SSL сертификаты установлены (если HTTPS)

---

**Deployment**: 77.95.201.100  
**Updated**: December 2025  
**Maintainer**: MetaChat DevOps Team

