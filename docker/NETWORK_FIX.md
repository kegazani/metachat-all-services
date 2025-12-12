# Исправление проблемы с сетью metachat_network

## Проблема

```
WARN[0000] a network with name metachat_network exists but was not created by compose.
network metachat_network was found but has incorrect label
```

## Быстрое решение

### Вариант 1: Используйте скрипт fix-network

**Linux/Mac:**
```bash
cd docker
chmod +x fix-network.sh
./fix-network.sh
```

**Windows:**
```powershell
cd docker
.\fix-network.ps1
```

### Вариант 2: Вручную

**Шаг 1: Остановите все контейнеры**
```bash
cd docker
docker compose -f docker-compose.infrastructure.yml down
docker compose -f docker-compose.services.yml down
```

**Шаг 2: Удалите старую сеть**
```bash
docker network rm metachat_network
```

**Шаг 3: Запустите деплой заново**
```bash
./deploy-full.sh         # Linux/Mac
.\deploy-full.ps1        # Windows
```

## Обновленный deploy-full.sh

Скрипт `deploy-full.sh` теперь **автоматически исправляет** эту проблему!

Просто запустите его снова:
```bash
./deploy-full.sh
```

Он:
1. Обнаружит сеть с неправильными метками
2. Остановит контейнеры
3. Удалит старую сеть
4. Создаст новую с правильными метками
5. Продолжит деплой

## Почему это происходит?

Эта проблема возникает когда:
- Сеть была создана вручную (`docker network create`)
- Сеть была создана старой версией docker-compose
- Осталась сеть от Docker Swarm

## Предотвращение

В будущем используйте только:
- `./deploy-full.sh` - для запуска
- `./stop-all.sh` - для остановки

Эти скрипты правильно управляют сетью.

## Если проблема не решается

Если после всех шагов проблема остается:

```bash
# Посмотрите какие контейнеры используют сеть
docker network inspect metachat_network

# Остановите все контейнеры
docker ps -a | grep metachat | awk '{print $1}' | xargs docker rm -f

# Удалите сеть
docker network rm metachat_network

# Запустите деплой
./deploy-full.sh
```

## Помощь

Если ничего не помогло:
1. Сохраните вывод команды: `docker network inspect metachat_network > network-info.txt`
2. Создайте issue в GitHub с этим файлом

