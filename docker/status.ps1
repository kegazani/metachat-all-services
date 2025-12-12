$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $SCRIPT_DIR

Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          MetaChat - Service Status                           ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
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

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "📦 Infrastructure Services" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
docker compose -f docker-compose.infrastructure.yml ps

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🚀 Application Services" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
docker compose -f docker-compose.services.yml ps

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🌐 Access URLs" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "Application:" -ForegroundColor Green
Write-Host "  🔌 API Gateway:        http://$($SERVER_IP):8080"
Write-Host ""
Write-Host "Infrastructure:" -ForegroundColor Green
Write-Host "  📨 Kafka UI:           http://$($SERVER_IP):8090"
Write-Host "  🗄️  PostgreSQL:        $($SERVER_IP):5432"
Write-Host "  💾 Cassandra:          $($SERVER_IP):9042"
Write-Host "  📝 EventStore:         http://$($SERVER_IP):2113"
Write-Host ""
Write-Host "Monitoring:" -ForegroundColor Green
Write-Host "  📊 Grafana:            http://$($SERVER_IP):3000"
Write-Host "  📉 Prometheus:         http://$($SERVER_IP):9090"
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "💻 Resource Usage" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
docker stats --no-stream --format "table {{.Name}}`t{{.CPUPerc}}`t{{.MemUsage}}`t{{.NetIO}}"
Write-Host ""

