#!/bin/bash
set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          MetaChat - Docker Swarm Deployment                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$SCRIPT_DIR"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Step 1: Check Docker Swarm"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if docker info | grep -q "Swarm: active"; then
    echo "✅ Docker Swarm is active"
else
    echo "⏳ Initializing Docker Swarm..."
    docker swarm init 2>/dev/null || docker swarm init --advertise-addr $(hostname -I | awk '{print $1}')
    echo "✅ Docker Swarm initialized"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 Step 2: Create Overlay Network"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if docker network inspect metachat_network &> /dev/null; then
    echo "ℹ️  Network 'metachat_network' already exists"
else
    echo "⏳ Creating overlay network..."
    docker network create --driver overlay --attachable metachat_network
    echo "✅ Network created"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔨 Step 3: Building Docker Images"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

SERVICES=(
    "api-gateway"
    "user-service"
    "diary-service"
    "matching-service"
    "match-request-service"
    "chat-service"
    "mood-analysis-service"
    "analytics-service"
    "archetype-service"
    "biometric-service"
    "correlation-service"
)

FAILED_BUILDS=()
BUILT_COUNT=0

for service in "${SERVICES[@]}"; do
    echo ""
    echo "📦 Building metachat/$service..."
    
    SERVICE_DIR=""
    BUILD_CONTEXT=""
    
    POSSIBLE_PATHS=(
        "$ROOT_DIR/metachat-$service"
        "$ROOT_DIR/metachat-all-services/metachat-$service"
        "$ROOT_DIR/../metachat-$service"
    )
    
    for path in "${POSSIBLE_PATHS[@]}"; do
        if [ -f "$path/Dockerfile" ]; then
            SERVICE_DIR="$path"
            BUILD_CONTEXT="$(dirname "$path")"
            break
        fi
    done
    
    if [ -z "$SERVICE_DIR" ]; then
        echo "⚠️  Dockerfile not found for $service, skipping..."
        FAILED_BUILDS+=("$service (no Dockerfile)")
        continue
    fi
    
    echo "   Building from: $SERVICE_DIR"
    if docker build \
        -t "metachat/$service:latest" \
        -f "$SERVICE_DIR/Dockerfile" \
        "$BUILD_CONTEXT" > /dev/null 2>&1; then
        echo "✅ $service built successfully"
        BUILT_COUNT=$((BUILT_COUNT + 1))
    else
        echo "❌ Failed to build $service"
        FAILED_BUILDS+=("$service")
    fi
done

echo ""
if [ ${#FAILED_BUILDS[@]} -eq 0 ]; then
    echo "✅ All $BUILT_COUNT services built successfully!"
else
    echo "⚠️  Some services failed to build:"
    for failed in "${FAILED_BUILDS[@]}"; do
        echo "   ❌ $failed"
    done
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Step 4: Deploying Infrastructure Stack"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "⏳ Deploying infrastructure..."
docker stack deploy -c docker-compose.infrastructure.yml metachat-infra

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⏳ Step 5: Waiting for Infrastructure (120 seconds)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "⏳ Waiting for services to start..."
sleep 120

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Step 6: Deploying Services Stack"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "⏳ Deploying application services..."
docker stack deploy -c docker-compose.services.yml metachat-services

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Deployment Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

SERVER_IP=$(hostname -I | awk '{print $1}')
if [ -z "$SERVER_IP" ]; then
    SERVER_IP="localhost"
fi

echo "🌐 Access URLs:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔌 API Gateway:        http://$SERVER_IP:8080"
echo ""
echo "📊 Management & Monitoring:"
echo "  🐳 Swarmpit:           http://$SERVER_IP:888 (Create account on first visit)"
echo "  📊 Grafana:            http://$SERVER_IP:3000 (admin/metachat2024)"
echo "  📉 Prometheus:         http://$SERVER_IP:9090"
echo "  📨 Kafka UI:           http://$SERVER_IP:8090"
echo ""
echo "📝 Useful Commands:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  View services:    docker service ls"
echo "  View logs:        docker service logs -f <service-name>"
echo "  Scale service:    docker service scale <service-name>=<replicas>"
echo "  Remove stack:     docker stack rm metachat-infra metachat-services"
echo "  Leave swarm:      docker swarm leave --force"
echo ""
echo "🎉 MetaChat Swarm is now running!"
echo ""
