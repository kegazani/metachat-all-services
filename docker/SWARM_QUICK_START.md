# 🐝 Docker Swarm - Быстрый старт

## 🚀 Деплой в одну команду

```bash
cd docker
./deploy-swarm.sh
```

Скрипт автоматически:
1. ✅ Инициализирует Docker Swarm
2. ✅ Создаст overlay сеть
3. ✅ Соберет все Docker образы
4. ✅ Задеплоит инфраструктуру (БД, Kafka, мониторинг)
5. ✅ Задеплоит все микросервисы

---

## 📊 Проверка статуса

```bash
docker stack ls

docker service ls

docker stack ps metachat-services
```

---

## 🌐 URLs после деплоя

| Сервис | URL |
|--------|-----|
| API Gateway | http://77.95.201.100:8080 |
| Grafana | http://77.95.201.100:3000 |
| Prometheus | http://77.95.201.100:9090 |
| Kafka UI | http://77.95.201.100:8090 |

---

## ⚙️ Основные команды

### Просмотр логов
```bash
docker service logs metachat-services_api-gateway -f
```

### Масштабирование
```bash
docker service scale metachat-services_api-gateway=4
```

### Обновление сервиса
```bash
docker service update --image metachat/api-gateway:v2 metachat-services_api-gateway
```

### Откат обновления
```bash
docker service rollback metachat-services_api-gateway
```

---

## 🛑 Остановка

```bash
docker stack rm metachat-services
docker stack rm metachat-infra

docker swarm leave --force
```

---

## 📖 Подробная документация

См. `SWARM_DEPLOYMENT.md` для полного руководства

