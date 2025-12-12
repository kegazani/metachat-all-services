#!/bin/bash

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          MetaChat - Stop Swarm Services                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

cd "$(dirname "$0")"

case "$1" in
    all)
        echo "🛑 Removing ALL stacks..."
        docker stack rm metachat-services 2>/dev/null
        docker stack rm metachat-infra 2>/dev/null
        echo "⏳ Waiting for services to stop..."
        sleep 10
        echo "✅ All stacks removed!"
        ;;
    infra)
        echo "🛑 Removing infrastructure stack..."
        docker stack rm metachat-infra
        echo "✅ Infrastructure removed!"
        ;;
    services)
        echo "🛑 Removing services stack..."
        docker stack rm metachat-services
        echo "✅ Services removed!"
        ;;
    clean)
        echo "🧹 Full cleanup..."
        echo ""
        echo "🛑 Removing stacks..."
        docker stack rm metachat-services 2>/dev/null
        docker stack rm metachat-infra 2>/dev/null
        echo "⏳ Waiting for services to stop..."
        sleep 15
        echo ""
        echo "🗑️  Removing network..."
        docker network rm metachat_network 2>/dev/null || true
        echo ""
        echo "🗑️  Removing volumes (DATA WILL BE LOST!)..."
        docker volume prune -f
        echo ""
        echo "✅ Full cleanup complete!"
        ;;
    *)
        echo "Usage: ./stop-swarm.sh [option]"
        echo ""
        echo "Options:"
        echo "  all       - Remove all stacks"
        echo "  infra     - Remove infrastructure stack only"
        echo "  services  - Remove application services only"
        echo "  clean     - Full cleanup (stacks + network + volumes)"
        echo ""
        echo "Examples:"
        echo "  ./stop-swarm.sh all"
        echo "  ./stop-swarm.sh services"
        echo "  ./stop-swarm.sh clean    # WARNING: Deletes all data!"
        echo ""
        ;;
esac

echo ""

