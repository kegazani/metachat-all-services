# 🎉 START HERE - MetaChat

## 👋 Добро пожаловать!

MetaChat - AI-powered платформа знакомств. Запуск занимает **10-20 минут**.

---

## ⚡ Быстрый старт

### 🐳 Вариант 1: Docker Compose (простой)

```bash
cd docker
./deploy-full.sh         # Linux/Mac
.\deploy-full.ps1        # Windows
```

### 🐝 Вариант 2: Docker Swarm (продвинутый)

```bash
cd docker
./deploy-swarm.sh
```

**Swarm дает:**
- ✅ Веб UI (Swarmpit) на http://localhost:888
- ✅ Масштабирование сервисов
- ✅ Автоматический рестарт

---

## 🌐 После запуска

| Сервис | URL | Credentials |
|--------|-----|-------------|
| **API** | http://localhost:8080 | - |
| **Swarmpit** | http://localhost:888 | Создать |
| **Grafana** | http://localhost:3000 | admin / metachat2024 |
| **Kafka UI** | http://localhost:8090 | - |

---

## 📝 Команды

### Docker Compose

```bash
./deploy-full.sh      # Запуск
./stop-all.sh         # Остановка
./status.sh           # Статус
./logs.sh all         # Логи
```

### Docker Swarm

```bash
./deploy-swarm.sh              # Первый деплой
./redeploy-swarm.sh all        # Редеплой
./stop-swarm.sh all            # Остановка
./status-swarm.sh              # Статус
./logs-swarm.sh kafka -f       # Логи
```

---

## 📖 Документация

| Что нужно | Документ |
|-----------|----------|
| Быстрый старт | [QUICK_START.md](QUICK_START.md) |
| Все команды | [COMMANDS.md](COMMANDS.md) |
| Docker деплой | [docker/README.md](docker/README.md) |
| Swarmpit UI | [docker/SWARMPIT_GUIDE.md](docker/SWARMPIT_GUIDE.md) |
| Локальная разработка | [docs/LOCAL_DEVELOPMENT.md](docs/LOCAL_DEVELOPMENT.md) |

---

## ❓ Проблемы?

```bash
# Логи
./logs.sh all              # Compose
./logs-swarm.sh kafka -f   # Swarm

# Перезапуск
./stop-all.sh && ./deploy-full.sh        # Compose
./stop-swarm.sh all && ./deploy-swarm.sh # Swarm
```

---

## 🎯 Что дальше

1. ✅ Откройте Grafana: http://localhost:3000
2. ✅ Откройте Swarmpit: http://localhost:888 (если Swarm)
3. ✅ Попробуйте API: `curl http://localhost:8080/health`
4. ✅ Изучите [COMMANDS.md](COMMANDS.md)

---

**🚀 Готово! MetaChat запущен!**
