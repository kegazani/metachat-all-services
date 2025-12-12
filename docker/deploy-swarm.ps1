$ErrorActionPreference = "Stop"

Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║       MetaChat - Docker Swarm Deployment Script             ║" -ForegroundColor Cyan
Write-Host "║       Production Deployment with High Availability          ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$ROOT_DIR = Split-Path -Parent $SCRIPT_DIR

Set-Location $SCRIPT_DIR

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "🔍 Step 1: Environment Check" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

try {
    $dockerVersion = docker --version
    Write-Host "✅ Docker found: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker not found. Please install Docker first." -ForegroundColor Red
    exit 1
}

try {
    docker info | Out-Null
    Write-Host "✅ Docker daemon is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker daemon is not running." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "🐝 Step 2: Initialize Docker Swarm" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

$swarmStatus = docker info | Select-String "Swarm: active"
if ($swarmStatus) {
    Write-Host "✅ Docker Swarm is already active" -ForegroundColor Green
    Write-Host ""
    Write-Host "Swarm nodes:"
    docker node ls
} else {
    Write-Host "⏳ Initializing Docker Swarm..." -ForegroundColor Yellow
    try {
        docker swarm init --advertise-addr 77.95.201.100
        Write-Host "✅ Docker Swarm initialized" -ForegroundColor Green
    } catch {
        Write-Host "ℹ️  Swarm already initialized or needs force init" -ForegroundColor Yellow
        docker swarm init --advertise-addr 77.95.201.100 --force-new-cluster
    }
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "🌐 Step 3: Create Overlay Network" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

$networkExists = docker network ls | Select-String "metachat_network"
if ($networkExists) {
    Write-Host "✅ Network metachat_network already exists" -ForegroundColor Green
} else {
    Write-Host "⏳ Creating overlay network..." -ForegroundColor Yellow
    docker network create --driver=overlay --attachable metachat_network
    Write-Host "✅ Network created" -ForegroundColor Green
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "🏗️  Step 4: Build Docker Images" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

Write-Host "⏳ Building all service images..." -ForegroundColor Yellow
Set-Location "$ROOT_DIR\metachat-all-services"

$services = @(
    "metachat-api-gateway",
    "metachat-user-service",
    "metachat-diary-service",
    "metachat-matching-service",
    "metachat-match-request-service",
    "metachat-chat-service",
    "metachat-mood-analysis-service",
    "metachat-analytics-service",
    "metachat-archetype-service",
    "metachat-biometric-service",
    "metachat-correlation-service"
)

foreach ($service in $services) {
    if (Test-Path $service) {
        Write-Host ""
        Write-Host "📦 Building $service..." -ForegroundColor Blue
        $serviceName = $service -replace "metachat-", ""
        docker build -t "metachat/${serviceName}:latest" -f "${service}\Dockerfile" .
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Failed to build $service" -ForegroundColor Red
            exit 1
        }
        Write-Host "✅ Built $service" -ForegroundColor Green
    }
}

Set-Location $SCRIPT_DIR

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "🚀 Step 5: Deploy Infrastructure Stack" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

Write-Host "⏳ Deploying infrastructure..." -ForegroundColor Yellow
docker stack deploy -c docker-stack-infrastructure.yml metachat-infra

Write-Host "✅ Infrastructure stack deployed" -ForegroundColor Green
Write-Host ""
Write-Host "⏳ Waiting for infrastructure to be ready (60 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "🚀 Step 6: Deploy Services Stack" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

Write-Host "⏳ Deploying application services..." -ForegroundColor Yellow
docker stack deploy -c docker-stack-services.yml metachat-services

Write-Host "✅ Services stack deployed" -ForegroundColor Green

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "📊 Step 7: Deployment Status" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

Write-Host "Stacks:"
docker stack ls
Write-Host ""

Write-Host "Infrastructure services:"
docker stack services metachat-infra
Write-Host ""

Write-Host "Application services:"
docker stack services metachat-services
Write-Host ""

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "✅ Deployment Complete!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Service URLs:" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "  API Gateway:    http://77.95.201.100:8080"
Write-Host "  Grafana:        http://77.95.201.100:3000 (admin/metachat2024)"
Write-Host "  Prometheus:     http://77.95.201.100:9090"
Write-Host "  Kafka UI:       http://77.95.201.100:8090"
Write-Host "  EventStore:     http://77.95.201.100:2113"
Write-Host ""
Write-Host "📝 Useful commands:" -ForegroundColor Yellow
Write-Host "  docker stack ps metachat-infra        # Check infrastructure tasks"
Write-Host "  docker stack ps metachat-services     # Check service tasks"
Write-Host "  docker service logs <service_name>    # View service logs"
Write-Host "  docker service scale <service>=N      # Scale service"
Write-Host "  docker stack rm metachat-infra        # Remove infrastructure stack"
Write-Host "  docker stack rm metachat-services     # Remove services stack"
Write-Host ""

