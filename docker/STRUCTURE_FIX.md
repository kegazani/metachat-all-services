# Исправление структуры проекта

## Проблема

Скрипт не может найти Dockerfile'ы для Go сервисов.

## Вероятная причина

Вы находитесь в директории `~/metachat-all-services/docker` вместо `~/metachat/docker`.

## Проверьте структуру

Выполните:

```bash
pwd
ls -la ../
```

### Ожидаемая структура:

```
~/metachat/                              # ИЛИ ~/metachat-all-services/
├── docker/
│   ├── deploy-full.sh
│   ├── docker-compose.*.yml
│   └── ...
├── metachat-api-gateway/                # или metachat-all-services/metachat-api-gateway/
│   └── Dockerfile
├── metachat-user-service/
│   └── Dockerfile
├── metachat-diary-service/
│   └── Dockerfile
└── ...
```

## Решение 1: Правильная структура

Если у вас структура:
```
~/metachat/
├── docker/
├── metachat-all-services/
│   ├── metachat-api-gateway/
│   ├── metachat-user-service/
│   └── ...
```

**Обновленный `deploy-full.sh` уже исправлен и будет работать!**

Просто запустите:
```bash
cd ~/metachat/docker
./deploy-full.sh
```

## Решение 2: Неправильная структура

Если вы находитесь в `~/metachat-all-services/docker` и сервисы лежат в `~/metachat-all-services/`:

```
~/metachat-all-services/
├── docker/                    # ← Вы здесь
├── metachat-api-gateway/      # ← Сервисы здесь
├── metachat-user-service/
└── ...
```

**Обновленный `deploy-full.sh` теперь поддерживает эту структуру!**

Просто запустите:
```bash
cd ~/metachat-all-services/docker
./deploy-full.sh
```

## Решение 3: Если все еще не работает

Проверьте наличие Dockerfile'ов:

```bash
# Перейдите в родительскую директорию
cd ..
pwd

# Проверьте Dockerfile'ы
find . -name "Dockerfile" -type f | grep -E "(api-gateway|user-service|diary-service)"
```

Если Dockerfile'ы не найдены, возможно они не были скопированы из репозитория.

## Быстрая проверка

Запустите этот скрипт:

```bash
cd docker
chmod +x check-dockerfiles.sh
./check-dockerfiles.sh
```

Он покажет где находятся (или не находятся) Dockerfile'ы.

## После исправления

Запустите деплой:

```bash
cd docker
./deploy-full.sh
```

Скрипт теперь:
- ✅ Автоматически определяет структуру директорий
- ✅ Ищет Dockerfile'ы в правильных местах
- ✅ Показывает где искал файлы если не нашел
- ✅ Работает с обеими структурами проекта

