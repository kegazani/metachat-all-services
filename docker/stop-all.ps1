Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          MetaChat - Stop All Services                        ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $SCRIPT_DIR

Write-Host "🛑 Stopping application services..." -ForegroundColor Yellow
docker compose -f docker-compose.services.yml down

Write-Host ""
Write-Host "🛑 Stopping infrastructure services..." -ForegroundColor Yellow
docker compose -f docker-compose.infrastructure.yml down

Write-Host ""
Write-Host "✅ All services stopped!" -ForegroundColor Green
Write-Host ""
Write-Host "💡 To remove all data volumes, run:" -ForegroundColor Cyan
Write-Host "   docker volume prune" -ForegroundColor White
Write-Host ""

