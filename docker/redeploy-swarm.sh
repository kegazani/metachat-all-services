#!/bin/bash

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          MetaChat - Redeploy Swarm Services                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

cd "$(dirname "$0")"

case "$1" in
    all)
        echo "🔄 Redeploying ALL stacks..."
        docker stack deploy -c docker-compose.swarm.yml metachat-infra
        docker stack deploy -c docker-compose.swarm-services.yml metachat-services
        echo "✅ All stacks redeployed!"
        ;;
    infra)
        echo "🔄 Redeploying infrastructure stack..."
        docker stack deploy -c docker-compose.swarm.yml metachat-infra
        echo "✅ Infrastructure redeployed!"
        ;;
    services)
        echo "🔄 Redeploying services stack..."
        docker stack deploy -c docker-compose.swarm-services.yml metachat-services
        echo "✅ Services redeployed!"
        ;;
    *)
        if [ -n "$1" ]; then
            echo "🔄 Redeploying service: $1..."
            docker service update --force "metachat-services_$1" 2>/dev/null || \
            docker service update --force "metachat-infra_$1" 2>/dev/null || \
            echo "❌ Service '$1' not found"
            echo ""
        else
            echo "Usage: ./redeploy-swarm.sh [option]"
            echo ""
            echo "Options:"
            echo "  all                - Redeploy everything"
            echo "  infra              - Redeploy infrastructure only"
            echo "  services           - Redeploy application services only"
            echo "  <service-name>     - Redeploy specific service"
            echo ""
            echo "Examples:"
            echo "  ./redeploy-swarm.sh all"
            echo "  ./redeploy-swarm.sh services"
            echo "  ./redeploy-swarm.sh mood-analysis-service"
            echo "  ./redeploy-swarm.sh kafka"
            echo ""
            echo "Available services:"
            echo ""
            echo "Infrastructure (metachat-infra):"
            docker service ls --filter "name=metachat-infra" --format "  - {{.Name}}" 2>/dev/null || echo "  (stack not deployed)"
            echo ""
            echo "Application (metachat-services):"
            docker service ls --filter "name=metachat-services" --format "  - {{.Name}}" 2>/dev/null || echo "  (stack not deployed)"
        fi
        ;;
esac

echo ""

