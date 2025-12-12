param(
    [Parameter(Position=0)]
    [string]$Service
)

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $SCRIPT_DIR

if (-not $Service) {
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          MetaChat - View Logs                                ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\logs.ps1 [service-name|all|infra|services]"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\logs.ps1 all                 # All logs"
    Write-Host "  .\logs.ps1 infra               # Infrastructure logs only"
    Write-Host "  .\logs.ps1 services            # Application services logs only"
    Write-Host "  .\logs.ps1 api-gateway         # Specific service logs"
    Write-Host "  .\logs.ps1 kafka               # Kafka logs"
    Write-Host ""
    Write-Host "Available services:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Infrastructure:" -ForegroundColor Cyan
    Write-Host "  - zookeeper, kafka, kafka-ui"
    Write-Host "  - cassandra, postgres, eventstore, nats"
    Write-Host "  - prometheus, grafana, loki, promtail"
    Write-Host ""
    Write-Host "Application:" -ForegroundColor Cyan
    Write-Host "  - api-gateway"
    Write-Host "  - user-service, diary-service"
    Write-Host "  - matching-service, match-request-service, chat-service"
    Write-Host "  - mood-analysis-service, analytics-service"
    Write-Host "  - archetype-service, biometric-service, correlation-service"
    Write-Host ""
    exit 0
}

switch ($Service.ToLower()) {
    "all" {
        Write-Host "📜 Showing all logs..." -ForegroundColor Cyan
        Write-Host ""
        Start-Job -ScriptBlock { 
            Set-Location $using:SCRIPT_DIR
            docker compose -f docker-compose.infrastructure.yml logs -f 
        } | Out-Null
        docker compose -f docker-compose.services.yml logs -f
    }
    {$_ -in "infra", "infrastructure"} {
        Write-Host "📜 Showing infrastructure logs..." -ForegroundColor Cyan
        Write-Host ""
        docker compose -f docker-compose.infrastructure.yml logs -f
    }
    {$_ -in "services", "app", "application"} {
        Write-Host "📜 Showing application logs..." -ForegroundColor Cyan
        Write-Host ""
        docker compose -f docker-compose.services.yml logs -f
    }
    {$_ -in "zookeeper", "kafka", "kafka-ui", "cassandra", "postgres", "eventstore", "nats", "prometheus", "grafana", "loki", "promtail"} {
        Write-Host "📜 Showing logs for $Service..." -ForegroundColor Cyan
        Write-Host ""
        docker compose -f docker-compose.infrastructure.yml logs -f $Service
    }
    default {
        Write-Host "📜 Showing logs for $Service..." -ForegroundColor Cyan
        Write-Host ""
        docker compose -f docker-compose.services.yml logs -f $Service
    }
}

