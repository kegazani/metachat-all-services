#!/bin/bash
set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║       MetaChat - Microservices Deployment (Swarm)           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$SCRIPT_DIR"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Step 1: Check Prerequisites"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if ! docker info | grep -q "Swarm: active"; then
    echo "❌ Docker Swarm is not active"
    echo "   Run './deploy-swarm.sh' first to initialize infrastructure"
    exit 1
fi

if ! docker network inspect metachat_network &> /dev/null; then
    echo "❌ Network 'metachat_network' not found"
    echo "   Run './deploy-swarm.sh' first to create infrastructure"
    exit 1
fi

echo "✅ Docker Swarm is active"
echo "✅ Network 'metachat_network' exists"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔨 Step 2: Building Docker Images"
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
    echo ""
    read -p "Continue with deployment anyway? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Step 3: Deploying Services Stack"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ ! -f "docker-compose.swarm-services.yml" ]; then
    echo "❌ File docker-compose.swarm-services.yml not found"
    exit 1
fi

echo "⏳ Deploying application services..."
docker stack deploy -c docker-compose.swarm-services.yml metachat-services

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⏳ Step 4: Waiting for Services to Start"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "⏳ Waiting 30 seconds for services to initialize..."
sleep 30

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Step 5: Service Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker service ls | grep "metachat-services_"

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
echo "📝 Useful Commands:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  View services:    docker service ls | grep metachat-services"
echo "  View logs:        docker service logs -f metachat-services_<service-name>"
echo "  Scale service:    docker service scale metachat-services_<service-name>=<replicas>"
echo "  Remove stack:     docker stack rm metachat-services"
echo "  Restart service:  docker service update --force metachat-services_<service-name>"
echo ""
echo "🎉 MetaChat Services are now running!"
echo ""

