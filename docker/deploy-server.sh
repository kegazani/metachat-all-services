#!/bin/bash

# Скрипт для деплоя на сервер
# Используется в CI/CD pipeline

set -e

REGISTRY=${REGISTRY:-ghcr.io}
IMAGE_PREFIX=${IMAGE_PREFIX:-username/metachat}
TAG=${TAG:-latest}

echo "🚀 Deploying MetaChat services..."
echo "Registry: $REGISTRY"
echo "Image prefix: $IMAGE_PREFIX"
echo "Tag: $TAG"
echo ""

# Создание .env файла для production
cat > .env << EOF
REGISTRY=$REGISTRY
IMAGE_PREFIX=$IMAGE_PREFIX
TAG=$TAG
EOF

# Обновление образов
echo "📥 Pulling latest images..."
docker-compose -f docker-compose.production.yml pull

# Остановка старых контейнеров
echo "🛑 Stopping old containers..."
docker-compose -f docker-compose.production.yml down

# Запуск новых контейнеров
echo "▶️  Starting new containers..."
docker-compose -f docker-compose.production.yml up -d

# Ожидание готовности
echo "⏳ Waiting for services to be ready..."
sleep 30

# Проверка здоровья
echo "🏥 Checking service health..."
docker-compose -f docker-compose.production.yml ps

# Очистка старых образов
echo "🧹 Cleaning up old images..."
docker image prune -f

echo ""
echo "✅ Deployment completed successfully!"

