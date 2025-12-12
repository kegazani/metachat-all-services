#!/bin/bash

cd "$(dirname "$0")"

if [ -z "$1" ]; then
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║          MetaChat - Swarm Logs                               ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Usage: ./logs-swarm.sh <service-name> [options]"
    echo ""
    echo "Options:"
    echo "  -f, --follow    Follow log output"
    echo "  --tail N        Show last N lines"
    echo ""
    echo "Examples:"
    echo "  ./logs-swarm.sh kafka"
    echo "  ./logs-swarm.sh mood-analysis-service -f"
    echo "  ./logs-swarm.sh grafana --tail 100"
    echo ""
    echo "Available services:"
    echo ""
    echo "Infrastructure:"
    docker service ls --filter "name=metachat-infra" --format "  {{.Name}}" 2>/dev/null | sed 's/metachat-infra_/  /'
    echo ""
    echo "Application:"
    docker service ls --filter "name=metachat-services" --format "  {{.Name}}" 2>/dev/null | sed 's/metachat-services_/  /'
    echo ""
    exit 0
fi

SERVICE=$1
shift

FULL_SERVICE="metachat-services_$SERVICE"
if ! docker service inspect "$FULL_SERVICE" &>/dev/null; then
    FULL_SERVICE="metachat-infra_$SERVICE"
fi

if ! docker service inspect "$FULL_SERVICE" &>/dev/null; then
    echo "❌ Service '$SERVICE' not found"
    echo ""
    echo "Try one of these:"
    docker service ls --format "  {{.Name}}"
    exit 1
fi

echo "📜 Showing logs for: $FULL_SERVICE"
echo ""
docker service logs "$FULL_SERVICE" "$@"

