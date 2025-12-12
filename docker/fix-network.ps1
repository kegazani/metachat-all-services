Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          MetaChat - Fix Network Issue                        ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $SCRIPT_DIR

Write-Host "🔍 Checking network status..." -ForegroundColor Yellow
$networkExists = docker network inspect metachat_network 2>$null

if ($networkExists) {
    Write-Host "⚠️  Network 'metachat_network' exists with incorrect labels" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "🛑 Stopping all containers using this network..." -ForegroundColor Yellow
    
    docker compose -f docker-compose.infrastructure.yml down 2>$null
    docker compose -f docker-compose.services.yml down 2>$null
    
    Write-Host ""
    Write-Host "🗑️  Removing old network..." -ForegroundColor Yellow
    docker network rm metachat_network
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Old network removed successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to remove network. Checking for connected containers..." -ForegroundColor Red
        Write-Host ""
        docker network inspect metachat_network
        Write-Host ""
        Write-Host "Please stop these containers manually and try again." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "ℹ️  Network doesn't exist or already removed" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "🌐 Creating new network with correct labels..." -ForegroundColor Yellow
docker network create --driver bridge --subnet 172.25.0.0/16 metachat_network

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Network created successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to create network" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "✅ Network issue fixed!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "Now you can run:" -ForegroundColor Yellow
Write-Host "  .\deploy-full.ps1" -ForegroundColor White
Write-Host ""

