#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

if [ -z "$1" ]; then
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║          MetaChat - View Logs                                ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Usage: ./logs.sh [service-name|all|infra|services]"
    echo ""
    echo "Examples:"
    echo "  ./logs.sh all                 # All logs"
    echo "  ./logs.sh infra               # Infrastructure logs only"
    echo "  ./logs.sh services            # Application services logs only"
    echo "  ./logs.sh api-gateway         # Specific service logs"
    echo "  ./logs.sh kafka               # Kafka logs"
    echo ""
    echo "Available services:"
    echo ""
    echo "Infrastructure:"
    echo "  - zookeeper, kafka, kafka-ui"
    echo "  - cassandra, postgres, eventstore, nats"
    echo "  - prometheus, grafana, loki, promtail"
    echo ""
    echo "Application:"
    echo "  - api-gateway"
    echo "  - user-service, diary-service"
    echo "  - matching-service, match-request-service, chat-service"
    echo "  - mood-analysis-service, analytics-service"
    echo "  - archetype-service, biometric-service, correlation-service"
    echo ""
    exit 0
fi

case "$1" in
    all)
        echo "📜 Showing all logs..."
        echo ""
        docker compose -f docker-compose.infrastructure.yml logs -f &
        docker compose -f docker-compose.services.yml logs -f
        ;;
    infra|infrastructure)
        echo "📜 Showing infrastructure logs..."
        echo ""
        docker compose -f docker-compose.infrastructure.yml logs -f
        ;;
    services|app|application)
        echo "📜 Showing application logs..."
        echo ""
        docker compose -f docker-compose.services.yml logs -f
        ;;
    zookeeper|kafka|kafka-ui|cassandra|postgres|eventstore|nats|prometheus|grafana|loki|promtail)
        echo "📜 Showing logs for $1..."
        echo ""
        docker compose -f docker-compose.infrastructure.yml logs -f "$1"
        ;;
    *)
        echo "📜 Showing logs for $1..."
        echo ""
        docker compose -f docker-compose.services.yml logs -f "$1"
        ;;
esac

