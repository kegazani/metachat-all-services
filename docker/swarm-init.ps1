$ErrorActionPreference = "Stop"

$REGISTRY_URL = if ($env:REGISTRY_URL) { $env:REGISTRY_URL } else { "localhost:5000" }

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         MetaChat Docker Swarm Initialization                ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

function Test-DockerInstalled {
    try {
        docker --version | Out-Null
        Write-Host "✅ Docker is installed" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ Docker is not installed" -ForegroundColor Red
        return $false
    }
}

function Initialize-Swarm {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "🐝 Initializing Docker Swarm..." -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    
    $swarmInfo = docker info 2>$null | Select-String "Swarm: active"
    if ($swarmInfo) {
        Write-Host "ℹ️  Swarm is already initialized" -ForegroundColor Cyan
    }
    else {
        docker swarm init
        Write-Host "✅ Swarm initialized successfully" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "📋 Swarm join token for workers:" -ForegroundColor Cyan
    docker swarm join-token worker 2>$null
}

function New-MetachatNetwork {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "🌐 Creating overlay network..." -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    
    $network = docker network ls | Select-String "metachat_network"
    if ($network) {
        Write-Host "ℹ️  Network metachat_network already exists" -ForegroundColor Cyan
    }
    else {
        docker network create --driver overlay --attachable metachat_network
        Write-Host "✅ Network created successfully" -ForegroundColor Green
    }
}

function Deploy-Registry {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "📦 Deploying Docker Registry..." -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    
    try {
        docker service create `
            --name registry `
            --publish 5000:5000 `
            --constraint 'node.role == manager' `
            --mount type=volume,source=registry_data,target=/var/lib/registry `
            registry:2 2>$null
        Write-Host "✅ Registry deployed at $REGISTRY_URL" -ForegroundColor Green
    }
    catch {
        Write-Host "ℹ️  Registry service already exists" -ForegroundColor Cyan
    }
}

function Deploy-Infrastructure {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "🏗️  Deploying Infrastructure Services..." -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    
    Push-Location $PSScriptRoot
    docker-compose -f docker-compose.infrastructure.yml up -d
    Pop-Location
    
    Write-Host "✅ Infrastructure services deployed" -ForegroundColor Green
}

function Build-AndPushImages {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "🔨 Building and pushing images to local registry..." -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    
    $projectRoot = Split-Path $PSScriptRoot -Parent
    
    $services = @(
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
    
    foreach ($service in $services) {
        Write-Host ""
        Write-Host "📦 Building metachat/$service..." -ForegroundColor Cyan
        
        $dockerfile = Join-Path $projectRoot "metachat-all-services/metachat-$service/Dockerfile"
        $context = Join-Path $projectRoot "metachat-all-services"
        
        docker build -t "$REGISTRY_URL/metachat/${service}:latest" -f $dockerfile $context
        
        Write-Host "📤 Pushing to registry..." -ForegroundColor Cyan
        docker push "$REGISTRY_URL/metachat/${service}:latest"
        
        Write-Host "✅ $service done" -ForegroundColor Green
    }
}

function Deploy-Stack {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "🚀 Deploying MetaChat Stack..." -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    
    $env:REGISTRY = $REGISTRY_URL
    $env:TAG = "latest"
    
    Push-Location $PSScriptRoot
    docker stack deploy -c docker-compose.swarm.yml metachat
    Pop-Location
    
    Write-Host "✅ Stack deployed successfully" -ForegroundColor Green
}

function Show-Status {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "📊 Deployment Status" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    
    Write-Host ""
    Write-Host "🐝 Swarm Nodes:" -ForegroundColor Cyan
    docker node ls
    
    Write-Host ""
    Write-Host "📦 Services:" -ForegroundColor Cyan
    docker service ls
    
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "🌐 Access URLs" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "📊 Grafana:          http://localhost:3000" -ForegroundColor White
    Write-Host "   Login: admin / metachat2024" -ForegroundColor Gray
    Write-Host ""
    Write-Host "📈 Prometheus:       http://localhost:9090" -ForegroundColor White
    Write-Host "📦 Registry UI:      http://localhost:5001" -ForegroundColor White
    Write-Host "🎯 Traefik:          http://localhost:8088" -ForegroundColor White
    Write-Host "👁️  Visualizer:       http://localhost:5002" -ForegroundColor White
    Write-Host "🌐 API Gateway:      http://localhost/api" -ForegroundColor White
    Write-Host ""
}

function Start-Interactive {
    if (-not (Test-DockerInstalled)) {
        exit 1
    }
    
    Initialize-Swarm
    New-MetachatNetwork
    Deploy-Registry
    
    Write-Host ""
    $deployInfra = Read-Host "Deploy infrastructure services? (y/n)"
    if ($deployInfra -eq "y") {
        Deploy-Infrastructure
    }
    
    Write-Host ""
    $buildImages = Read-Host "Build and push images to local registry? (y/n)"
    if ($buildImages -eq "y") {
        Build-AndPushImages
    }
    
    Write-Host ""
    $deployStack = Read-Host "Deploy MetaChat stack? (y/n)"
    if ($deployStack -eq "y") {
        Deploy-Stack
    }
    
    Show-Status
    
    Write-Host ""
    Write-Host "🎉 MetaChat Swarm setup complete!" -ForegroundColor Green
}

switch ($args[0]) {
    "init" {
        if (-not (Test-DockerInstalled)) { exit 1 }
        Initialize-Swarm
        New-MetachatNetwork
    }
    "registry" {
        Deploy-Registry
    }
    "build" {
        Build-AndPushImages
    }
    "deploy" {
        Deploy-Stack
    }
    "status" {
        Show-Status
    }
    "all" {
        if (-not (Test-DockerInstalled)) { exit 1 }
        Initialize-Swarm
        New-MetachatNetwork
        Deploy-Registry
        Deploy-Infrastructure
        Build-AndPushImages
        Deploy-Stack
        Show-Status
    }
    default {
        Start-Interactive
    }
}

