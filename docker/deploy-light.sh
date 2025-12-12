#!/bin/bash
set -e

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     MetaChat Light Deployment (4 cores / 8GB RAM)           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

check_resources() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 System Resources"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    CPU_CORES=$(nproc)
    TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
    FREE_MEM=$(free -m | awk '/^Mem:/{print $4}')
    
    echo "  CPU Cores:    $CPU_CORES"
    echo "  Total RAM:    ${TOTAL_MEM}MB"
    echo "  Free RAM:     ${FREE_MEM}MB"
    echo ""
    
    if [ "$TOTAL_MEM" -lt 7000 ]; then
        echo "⚠️  Warning: Less than 7GB RAM available!"
        echo "   Some services may not start properly."
        echo ""
    fi
}

setup_swap() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "💾 Checking Swap..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    SWAP_SIZE=$(free -m | awk '/^Swap:/{print $2}')
    
    if [ "$SWAP_SIZE" -lt 2000 ]; then
        echo "  Current swap: ${SWAP_SIZE}MB"
        echo "  Recommended:  4096MB"
        echo ""
        read -p "  Create 4GB swap file? (y/n): " create_swap
        
        if [[ "$create_swap" =~ ^[Yy]$ ]]; then
            sudo fallocate -l 4G /swapfile
            sudo chmod 600 /swapfile
            sudo mkswap /swapfile
            sudo swapon /swapfile
            echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
            echo "  ✅ Swap created"
        fi
    else
        echo "  ✅ Swap is sufficient: ${SWAP_SIZE}MB"
    fi
    echo ""
}

optimize_docker() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🐳 Optimizing Docker..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    docker system prune -f 2>/dev/null || true
    echo "  ✅ Docker cleaned"
    echo ""
}

deploy() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚀 Starting Deployment..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    cd "$(dirname "$0")"
    
    echo ""
    echo "📦 Step 1: Starting infrastructure (Kafka, Cassandra, PostgreSQL)..."
    docker-compose -f docker-compose.production-light.yml up -d \
        zookeeper kafka cassandra postgres eventstore nats
    
    echo ""
    echo "⏳ Waiting for databases to be ready (this may take 2-3 minutes)..."
    sleep 60
    
    echo ""
    echo "🔍 Checking database health..."
    
    for i in {1..30}; do
        if docker-compose -f docker-compose.production-light.yml exec -T cassandra cqlsh -e "describe keyspaces" >/dev/null 2>&1; then
            echo "  ✅ Cassandra is ready"
            break
        fi
        echo "  ⏳ Waiting for Cassandra... ($i/30)"
        sleep 10
    done
    
    if docker-compose -f docker-compose.production-light.yml exec -T postgres pg_isready -U metachat >/dev/null 2>&1; then
        echo "  ✅ PostgreSQL is ready"
    fi
    
    echo ""
    echo "📦 Step 2: Starting application services..."
    docker-compose -f docker-compose.production-light.yml up -d \
        user-service diary-service matching-service \
        match-request-service chat-service
    
    sleep 20
    
    echo ""
    echo "📦 Step 3: Starting AI/ML services..."
    docker-compose -f docker-compose.production-light.yml up -d \
        mood-analysis-service analytics-service \
        archetype-service biometric-service correlation-service
    
    sleep 10
    
    echo ""
    echo "📦 Step 4: Starting API Gateway..."
    docker-compose -f docker-compose.production-light.yml up -d api-gateway
    
    echo ""
    echo "📦 Step 5: Starting Monitoring..."
    docker-compose -f docker-compose.production-light.yml up -d prometheus grafana
    
    echo ""
    echo "✅ Deployment complete!"
}

show_status() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 Services Status"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    cd "$(dirname "$0")"
    docker-compose -f docker-compose.production-light.yml ps
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "💾 Memory Usage"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}" 2>/dev/null | head -20
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🌐 Access URLs"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo ""
    echo "  🌐 API Gateway:   http://$SERVER_IP:8080"
    echo "  📊 Grafana:       http://$SERVER_IP:3000"
    echo "     Login: admin / metachat2024"
    echo "  📈 Prometheus:    http://$SERVER_IP:9090"
    echo ""
}

case "${1:-}" in
    "deploy")
        check_resources
        deploy
        show_status
        ;;
    "status")
        show_status
        ;;
    "stop")
        cd "$(dirname "$0")"
        docker-compose -f docker-compose.production-light.yml down
        echo "✅ All services stopped"
        ;;
    "logs")
        cd "$(dirname "$0")"
        docker-compose -f docker-compose.production-light.yml logs -f --tail=100 ${2:-}
        ;;
    "restart")
        cd "$(dirname "$0")"
        docker-compose -f docker-compose.production-light.yml restart ${2:-}
        ;;
    *)
        check_resources
        setup_swap
        optimize_docker
        deploy
        show_status
        ;;
esac

