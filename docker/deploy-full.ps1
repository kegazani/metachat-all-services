$ErrorActionPreference = "Stop"

Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          MetaChat - Full Deployment Script                  ║" -ForegroundColor Cyan
Write-Host "║          Build & Deploy Everything from Scratch              ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$ROOT_DIR = Split-Path -Parent $SCRIPT_DIR

Set-Location $SCRIPT_DIR

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🔍 Step 1: Environment Check" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
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
    Write-Host "❌ Docker daemon is not running. Please start Docker." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🛑 Step 2: Cleanup Previous Deployment" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

Write-Host "⏳ Stopping and removing existing containers..." -ForegroundColor Yellow
docker compose -f docker-compose.infrastructure.yml down 2>$null
docker compose -f docker-compose.services.yml down 2>$null
Write-Host "✅ Cleanup complete" -ForegroundColor Green

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🌐 Step 3: Network Setup" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

$networkExists = docker network inspect metachat_network 2>$null
if ($networkExists) {
    Write-Host "⚠️  Network 'metachat_network' already exists" -ForegroundColor Yellow
    Write-Host "🔍 Checking if it has correct labels..." -ForegroundColor Cyan
    
    $networkLabel = docker network inspect metachat_network --format '{{.Labels}}' 2>$null
    
    if ($networkLabel -and $networkLabel -match "com.docker.compose" -and $networkLabel -notmatch "com.docker.compose.network=metachat_network") {
        Write-Host "⚠️  Network has incorrect compose labels, recreating..." -ForegroundColor Yellow
        Write-Host "🗑️  Removing old network..." -ForegroundColor Yellow
        docker network rm metachat_network 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Could not remove network. It may be in use." -ForegroundColor Red
            Write-Host "   Run: .\fix-network.ps1 to fix this issue" -ForegroundColor Yellow
            exit 1
        }
        Write-Host "⏳ Creating network 'metachat_network'..." -ForegroundColor Yellow
        docker network create --driver bridge --subnet 172.25.0.0/16 metachat_network
        Write-Host "✅ Network recreated" -ForegroundColor Green
    } else {
        Write-Host "ℹ️  Network 'metachat_network' is OK" -ForegroundColor Cyan
    }
} else {
    Write-Host "⏳ Creating network 'metachat_network'..." -ForegroundColor Yellow
    docker network create --driver bridge --subnet 172.25.0.0/16 metachat_network
    Write-Host "✅ Network created" -ForegroundColor Green
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🔨 Step 4: Building Docker Images" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

$SERVICES = @(
    "api-gateway",
    "user-service",
    "diary-service",
    "matching-service",
    "match-request-service",
    "chat-service",
    "mood-analysis-service",
    "analytics-service",
    "archetype-service",
    "biometric-service",
    "correlation-service"
)

$FAILED_BUILDS = @()
$BUILT_COUNT = 0

foreach ($service in $SERVICES) {
    Write-Host ""
    Write-Host "📦 Building metachat/$service..." -ForegroundColor Cyan
    
    $SERVICE_DIR = Join-Path $ROOT_DIR "metachat-all-services\metachat-$service"
    $DOCKERFILE = Join-Path $SERVICE_DIR "Dockerfile"
    
    if (-not (Test-Path $DOCKERFILE)) {
        Write-Host "⚠️  Dockerfile not found for $service, skipping..." -ForegroundColor Yellow
        $FAILED_BUILDS += "$service (no Dockerfile)"
        continue
    }
    
    $buildContext = Join-Path $ROOT_DIR "metachat-all-services"
    $result = docker build -t "metachat/$($service):latest" -f $DOCKERFILE $buildContext 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ $service built successfully" -ForegroundColor Green
        $BUILT_COUNT++
    } else {
        Write-Host "❌ Failed to build $service" -ForegroundColor Red
        $FAILED_BUILDS += $service
    }
}

Write-Host ""
if ($FAILED_BUILDS.Count -eq 0) {
    Write-Host "✅ All $BUILT_COUNT services built successfully!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Some services failed to build:" -ForegroundColor Yellow
    foreach ($failed in $FAILED_BUILDS) {
        Write-Host "   ❌ $failed" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🚀 Step 5: Starting Infrastructure Services" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

Write-Host "📦 Starting: Zookeeper, Kafka, Cassandra, PostgreSQL, EventStore, NATS..." -ForegroundColor Cyan
docker compose -f docker-compose.infrastructure.yml up -d zookeeper kafka cassandra postgres eventstore nats

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "⏳ Step 6: Waiting for Infrastructure to be Ready" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

Write-Host "⏳ Waiting for Kafka (60 seconds initial delay)..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

Write-Host ""
Write-Host "🔍 Checking Kafka..." -ForegroundColor Cyan
for ($i = 1; $i -le 30; $i++) {
    $result = docker exec kafka kafka-broker-api-versions --bootstrap-server localhost:29092 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Kafka is ready!" -ForegroundColor Green
        break
    }
    Write-Host "⏳ Attempt $i/30 - Kafka not ready, waiting..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
}

Write-Host ""
Write-Host "🔍 Checking Cassandra..." -ForegroundColor Cyan
for ($i = 1; $i -le 40; $i++) {
    $result = docker exec cassandra cqlsh -e "describe keyspaces" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Cassandra is ready!" -ForegroundColor Green
        break
    }
    Write-Host "⏳ Attempt $i/40 - Cassandra not ready, waiting..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
}

Write-Host ""
Write-Host "🔍 Checking PostgreSQL..." -ForegroundColor Cyan
for ($i = 1; $i -le 20; $i++) {
    $result = docker exec postgres pg_isready -U metachat -d metachat 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ PostgreSQL is ready!" -ForegroundColor Green
        break
    }
    Write-Host "⏳ Attempt $i/20 - PostgreSQL not ready, waiting..." -ForegroundColor Yellow
    Start-Sleep -Seconds 3
}

Write-Host ""
Write-Host "🔍 Checking EventStore..." -ForegroundColor Cyan
for ($i = 1; $i -le 20; $i++) {
    try {
        $result = docker exec eventstore curl -f http://localhost:2113/health/live 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ EventStore is ready!" -ForegroundColor Green
            break
        }
    } catch {}
    Write-Host "⏳ Attempt $i/20 - EventStore not ready, waiting..." -ForegroundColor Yellow
    Start-Sleep -Seconds 3
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🔧 Step 7: Initializing Infrastructure" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

Write-Host "📝 Creating Kafka Topics..." -ForegroundColor Cyan
docker compose -f docker-compose.infrastructure.yml up -d kafka-topics-init
Start-Sleep -Seconds 5

Write-Host ""
Write-Host "📝 Initializing Cassandra Schema..." -ForegroundColor Cyan
docker compose -f docker-compose.infrastructure.yml up -d cassandra-init
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🚀 Step 8: Starting Application Services" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

Write-Host "📦 Starting core services..." -ForegroundColor Cyan
docker compose -f docker-compose.services.yml up -d user-service diary-service matching-service match-request-service chat-service

Write-Host "⏳ Waiting for core services to initialize (30 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host ""
Write-Host "📦 Starting AI/ML services..." -ForegroundColor Cyan
docker compose -f docker-compose.services.yml up -d mood-analysis-service analytics-service archetype-service biometric-service correlation-service

Write-Host "⏳ Waiting for AI/ML services (20 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 20

Write-Host ""
Write-Host "📦 Starting API Gateway..." -ForegroundColor Cyan
docker compose -f docker-compose.services.yml up -d api-gateway

Write-Host "⏳ Waiting for API Gateway (10 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "📊 Step 9: Starting Monitoring Services" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

Write-Host "📈 Starting Prometheus, Grafana, Loki, Promtail..." -ForegroundColor Cyan
docker compose -f docker-compose.infrastructure.yml up -d prometheus grafana loki promtail

Write-Host "⏳ Waiting for monitoring services (15 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

Write-Host ""
Write-Host "📈 Starting Kafka UI..." -ForegroundColor Cyan
docker compose -f docker-compose.infrastructure.yml up -d kafka-ui

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "✅ Step 10: Deployment Complete!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

$SERVER_IP = "localhost"
try {
    $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*" -and $_.IPAddress -notlike "169.254.*"} | Select-Object -First 1).IPAddress
    if ($ipAddress) {
        $SERVER_IP = $ipAddress
    }
} catch {
    $SERVER_IP = "localhost"
}

Write-Host "🌐 MetaChat Services:" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  🔌 API Gateway:        http://$($SERVER_IP):8080"
Write-Host ""
Write-Host "📊 Infrastructure Services:" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  📨 Kafka UI:           http://$($SERVER_IP):8090"
Write-Host "  🗄️  PostgreSQL:        $($SERVER_IP):5432 (user: metachat, pass: metachat_password)"
Write-Host "  💾 Cassandra:          $($SERVER_IP):9042"
Write-Host "  📝 EventStore:         http://$($SERVER_IP):2113"
Write-Host "  📮 NATS:               http://$($SERVER_IP):4222 (monitoring: :8222)"
Write-Host ""
Write-Host "📈 Monitoring Services:" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  📊 Grafana:            http://$($SERVER_IP):3000 (admin/metachat2024)"
Write-Host "  📉 Prometheus:         http://$($SERVER_IP):9090"
Write-Host "  📜 Loki:               http://$($SERVER_IP):3100"
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "📝 Useful Commands:" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "  View all logs:"
Write-Host "    docker compose -f docker/docker-compose.infrastructure.yml logs -f"
Write-Host "    docker compose -f docker/docker-compose.services.yml logs -f"
Write-Host ""
Write-Host "  View specific service logs:"
Write-Host "    docker compose -f docker/docker-compose.services.yml logs -f api-gateway"
Write-Host "    docker compose -f docker/docker-compose.services.yml logs -f user-service"
Write-Host ""
Write-Host "  Check service status:"
Write-Host "    docker compose -f docker/docker-compose.infrastructure.yml ps"
Write-Host "    docker compose -f docker/docker-compose.services.yml ps"
Write-Host ""
Write-Host "  Restart a service:"
Write-Host "    docker compose -f docker/docker-compose.services.yml restart api-gateway"
Write-Host ""
Write-Host "  Stop all services:"
Write-Host "    docker compose -f docker/docker-compose.infrastructure.yml down"
Write-Host "    docker compose -f docker/docker-compose.services.yml down"
Write-Host ""
Write-Host "  Connect to Cassandra:"
Write-Host "    docker exec -it cassandra cqlsh"
Write-Host ""
Write-Host "  Connect to PostgreSQL:"
Write-Host "    docker exec -it postgres psql -U metachat -d metachat"
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "📊 Current Status:" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

Write-Host "Infrastructure Services:" -ForegroundColor Cyan
docker compose -f docker-compose.infrastructure.yml ps

Write-Host ""
Write-Host "Application Services:" -ForegroundColor Cyan
docker compose -f docker-compose.services.yml ps

Write-Host ""
Write-Host "🎉 MetaChat is now running!" -ForegroundColor Green
Write-Host "🚀 You can start using the API at http://$($SERVER_IP):8080" -ForegroundColor Green
Write-Host ""

