# MetaChat Resource Usage (4 cores / 8GB RAM)

Оптимизированная конфигурация для сервера с ограниченными ресурсами.

## 📊 Распределение ресурсов

### Инфраструктура (~3.2 GB)

| Сервис | CPU Limit | RAM Limit | RAM Reserved |
|--------|-----------|-----------|--------------|
| Kafka | 0.4 | 512MB | 384MB |
| Cassandra | 0.5 | 768MB | 512MB |
| Zookeeper | 0.15 | 192MB | 128MB |
| PostgreSQL | 0.25 | 256MB | 128MB |
| EventStore | 0.25 | 384MB | 256MB |
| NATS | 0.1 | 96MB | 64MB |
| **Итого** | **1.65** | **2.2GB** | **1.5GB** |

### Сервисы приложения (~1.5 GB)

| Сервис | CPU Limit | RAM Limit | RAM Reserved |
|--------|-----------|-----------|--------------|
| API Gateway | 0.15 | 96MB | 64MB |
| User Service | 0.15 | 96MB | 64MB |
| Diary Service | 0.15 | 96MB | 64MB |
| Matching Service | 0.15 | 96MB | 64MB |
| Match Request | 0.1 | 64MB | 32MB |
| Chat Service | 0.1 | 64MB | 32MB |
| Mood Analysis | 0.2 | 192MB | 128MB |
| Analytics | 0.15 | 128MB | 96MB |
| Archetype | 0.15 | 128MB | 96MB |
| Biometric | 0.1 | 96MB | 64MB |
| Correlation | 0.15 | 128MB | 96MB |
| **Итого** | **1.55** | **1.2GB** | **800MB** |

### Мониторинг (~450 MB)

| Сервис | CPU Limit | RAM Limit | RAM Reserved |
|--------|-----------|-----------|--------------|
| Prometheus | 0.15 | 256MB | 128MB |
| Grafana | 0.15 | 192MB | 128MB |
| **Итого** | **0.3** | **450MB** | **256MB** |

## 📈 Общий расход

| Категория | CPU | RAM Limit | RAM Reserved |
|-----------|-----|-----------|--------------|
| Инфраструктура | 1.65 | 2.2GB | 1.5GB |
| Сервисы | 1.55 | 1.2GB | 800MB |
| Мониторинг | 0.3 | 450MB | 256MB |
| **ВСЕГО** | **3.5** | **~3.9GB** | **~2.6GB** |
| Система + буфер | 0.5 | ~4GB | - |
| **Доступно** | **4** | **8GB** | - |

✅ **Вписываемся в лимиты с запасом!**

## 🚀 Быстрый старт

```bash
cd docker
chmod +x deploy-light.sh
./deploy-light.sh
```

## 📋 Команды управления

```bash
./deploy-light.sh deploy
./deploy-light.sh status
./deploy-light.sh stop
./deploy-light.sh logs api-gateway
./deploy-light.sh restart mood-analysis-service
```

## ⚙️ Оптимизации

### 1. Kafka
- 1 партиция вместо 3
- Retention 12 часов вместо 24
- Heap 384MB

### 2. Cassandra  
- 128 tokens вместо 256
- Heap 512MB
- SimpleSnitch

### 3. PostgreSQL
- max_connections: 50
- shared_buffers: 128MB

### 4. EventStore
- Projections отключены
- Heap limit 256MB

### 5. Prometheus
- Retention 3 дня
- Storage limit 1GB

## 💾 Рекомендации

### Добавить Swap (обязательно!)

```bash
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### Настройки системы

```bash
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
echo 'vm.overcommit_memory=1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

## ⚠️ Если не хватает памяти

### Вариант 1: Отключить мониторинг
```bash
docker-compose -f docker-compose.production-light.yml stop prometheus grafana
```
Экономия: ~450MB

### Вариант 2: Отключить неиспользуемые сервисы
```bash
docker-compose -f docker-compose.production-light.yml stop \
  archetype-service biometric-service correlation-service
```
Экономия: ~350MB

### Вариант 3: Использовать SQLite вместо PostgreSQL
Для небольших проектов можно упростить архитектуру.

## 🔍 Мониторинг ресурсов

```bash
docker stats --format "table {{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}"
```

```bash
htop
free -h
```

