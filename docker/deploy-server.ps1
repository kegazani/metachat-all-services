# PowerShell скрипт для деплоя на сервер
# Используется в CI/CD pipeline

param(
    [string]$Registry = "ghcr.io",
    [string]$ImagePrefix = "username/metachat",
    [string]$Tag = "latest"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Deploying MetaChat services..." -ForegroundColor Green
Write-Host "Registry: $Registry"
Write-Host "Image prefix: $ImagePrefix"
Write-Host "Tag: $Tag"
Write-Host ""

# Создание .env файла для production
@"
REGISTRY=$Registry
IMAGE_PREFIX=$ImagePrefix
TAG=$Tag
"@ | Out-File -FilePath .env -Encoding utf8

# Обновление образов
Write-Host "📥 Pulling latest images..." -ForegroundColor Yellow
docker compose -f docker-compose.production-light.yml pull

# Остановка старых контейнеров
Write-Host "🛑 Stopping old containers..." -ForegroundColor Yellow
docker compose -f docker-compose.production-light.yml down --remove-orphans

# Запуск новых контейнеров
Write-Host "▶️  Starting new containers..." -ForegroundColor Yellow
docker compose -f docker-compose.production-light.yml up -d

# Ожидание готовности
Write-Host "⏳ Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Проверка здоровья
Write-Host "🏥 Checking service health..." -ForegroundColor Yellow
docker compose -f docker-compose.production-light.yml ps

# Очистка старых образов
Write-Host "🧹 Cleaning up old images..." -ForegroundColor Yellow
docker image prune -f

Write-Host ""
Write-Host "✅ Deployment completed successfully!" -ForegroundColor Green

