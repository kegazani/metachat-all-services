#!/bin/bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          MetaChat - Full Deployment Script                  ║"
echo "║          Build & Deploy Everything from Scratch              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$SCRIPT_DIR"

echo "📂 Root directory: $ROOT_DIR"
echo "📂 Script directory: $SCRIPT_DIR"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Step 1: Environment Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker first."
    exit 1
fi
echo "✅ Docker found: $(docker --version)"

if ! docker info &> /dev/null; then
    echo "❌ Docker daemon is not running. Please start Docker."
    exit 1
fi
echo "✅ Docker daemon is running"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🛑 Step 2: Cleanup Previous Deployment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "⏳ Stopping and removing existing containers..."
docker compose -f docker-compose.infrastructure.yml down 2>/dev/null || true
docker compose -f docker-compose.services.yml down 2>/dev/null || true
echo "✅ Cleanup complete"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 Step 3: Network Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if docker network inspect metachat_network &> /dev/null; then
    echo "⚠️  Network 'metachat_network' already exists"
    echo "🔍 Checking if it has correct labels..."
    
    NETWORK_LABEL=$(docker network inspect metachat_network --format '{{.Labels}}' 2>/dev/null || echo "")
    
    if [[ "$NETWORK_LABEL" == *"com.docker.compose"* ]] && [[ "$NETWORK_LABEL" != *"com.docker.compose.network=metachat_network"* ]]; then
        echo "⚠️  Network has incorrect compose labels, recreating..."
        echo "🗑️  Removing old network..."
        docker network rm metachat_network 2>/dev/null || {
            echo "❌ Could not remove network. It may be in use."
            echo "   Run: ./fix-network.sh to fix this issue"
            exit 1
        }
        echo "⏳ Creating network 'metachat_network'..."
        docker network create --driver bridge --subnet 172.25.0.0/16 metachat_network
        echo "✅ Network recreated"
    else
        echo "ℹ️  Network 'metachat_network' is OK"
    fi
else
    echo "⏳ Creating network 'metachat_network'..."
    docker network create --driver bridge --subnet 172.25.0.0/16 metachat_network
    echo "✅ Network created"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔨 Step 4: Building Docker Images"
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
    
    SERVICE_DIR="$ROOT_DIR/metachat-$service"
    
    if [ ! -d "$SERVICE_DIR" ]; then
        SERVICE_DIR="$ROOT_DIR/metachat-all-services/metachat-$service"
    fi
    
    if [ ! -f "$SERVICE_DIR/Dockerfile" ]; then
        echo "⚠️  Dockerfile not found for $service"
        echo "   Tried: $SERVICE_DIR/Dockerfile"
        FAILED_BUILDS+=("$service (no Dockerfile)")
        continue
    fi
    
    BUILD_CONTEXT="$(dirname "$SERVICE_DIR")"
    
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
echo "🚀 Step 5: Starting Infrastructure Services"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "📦 Starting: Zookeeper, Kafka, Cassandra, PostgreSQL, EventStore, NATS..."
docker compose -f docker-compose.infrastructure.yml up -d \
    zookeeper kafka cassandra postgres eventstore nats

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⏳ Step 6: Waiting for Infrastructure to be Ready"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "⏳ Waiting for Kafka (60 seconds initial delay)..."
sleep 60

echo ""
echo "🔍 Checking Kafka..."
for i in {1..30}; do
    if docker exec kafka kafka-broker-api-versions --bootstrap-server localhost:29092 >/dev/null 2>&1; then
        echo "✅ Kafka is ready!"
        break
    fi
    echo "⏳ Attempt $i/30 - Kafka not ready, waiting..."
    sleep 5
done

echo ""
echo "🔍 Checking Cassandra..."
for i in {1..40}; do
    if docker exec cassandra cqlsh -e "describe keyspaces" >/dev/null 2>&1; then
        echo "✅ Cassandra is ready!"
        break
    fi
    echo "⏳ Attempt $i/40 - Cassandra not ready, waiting..."
    sleep 5
done

echo ""
echo "🔍 Checking PostgreSQL..."
for i in {1..20}; do
    if docker exec postgres pg_isready -U metachat -d metachat >/dev/null 2>&1; then
        echo "✅ PostgreSQL is ready!"
        break
    fi
    echo "⏳ Attempt $i/20 - PostgreSQL not ready, waiting..."
    sleep 3
done

echo ""
echo "🔍 Checking EventStore..."
for i in {1..20}; do
    if docker exec eventstore curl -f http://localhost:2113/health/live >/dev/null 2>&1; then
        echo "✅ EventStore is ready!"
        break
    fi
    echo "⏳ Attempt $i/20 - EventStore not ready, waiting..."
    sleep 3
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Step 7: Initializing Infrastructure"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "📝 Creating Kafka Topics..."
docker compose -f docker-compose.infrastructure.yml up -d kafka-topics-init
sleep 5

echo ""
echo "📝 Initializing Cassandra Schema..."
docker compose -f docker-compose.infrastructure.yml up -d cassandra-init
sleep 10

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Step 8: Starting Application Services"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "📦 Starting core services..."
docker compose -f docker-compose.services.yml up -d \
    user-service diary-service matching-service \
    match-request-service chat-service

echo "⏳ Waiting for core services to initialize (30 seconds)..."
sleep 30

echo ""
echo "📦 Starting AI/ML services..."
docker compose -f docker-compose.services.yml up -d \
    mood-analysis-service analytics-service \
    archetype-service biometric-service correlation-service

echo "⏳ Waiting for AI/ML services (20 seconds)..."
sleep 20

echo ""
echo "📦 Starting API Gateway..."
docker compose -f docker-compose.services.yml up -d api-gateway

echo "⏳ Waiting for API Gateway (10 seconds)..."
sleep 10

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Step 9: Starting Monitoring Services"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "📈 Starting Prometheus, Grafana, Loki, Promtail..."
docker compose -f docker-compose.infrastructure.yml up -d \
    prometheus grafana loki promtail

echo "⏳ Waiting for monitoring services (15 seconds)..."
sleep 15

echo ""
echo "📈 Starting Kafka UI..."
docker compose -f docker-compose.infrastructure.yml up -d kafka-ui

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Step 10: Deployment Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

SERVER_IP=$(hostname -I | awk '{print $1}')
if [ -z "$SERVER_IP" ]; then
    SERVER_IP="localhost"
fi

echo "🌐 MetaChat Services:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔌 API Gateway:        http://$SERVER_IP:8080"
echo ""
echo "📊 Infrastructure Services:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📨 Kafka UI:           http://$SERVER_IP:8090"
echo "  🗄️  PostgreSQL:        $SERVER_IP:5432 (user: metachat, pass: metachat_password)"
echo "  💾 Cassandra:          $SERVER_IP:9042"
echo "  📝 EventStore:         http://$SERVER_IP:2113"
echo "  📮 NATS:               http://$SERVER_IP:4222 (monitoring: :8222)"
echo ""
echo "📈 Monitoring Services:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📊 Grafana:            http://$SERVER_IP:3000 (admin/metachat2024)"
echo "  📉 Prometheus:         http://$SERVER_IP:9090"
echo "  📜 Loki:               http://$SERVER_IP:3100"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Useful Commands:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  View all logs:"
echo "    docker compose -f docker/docker-compose.infrastructure.yml logs -f"
echo "    docker compose -f docker/docker-compose.services.yml logs -f"
echo ""
echo "  View specific service logs:"
echo "    docker compose -f docker/docker-compose.services.yml logs -f api-gateway"
echo "    docker compose -f docker/docker-compose.services.yml logs -f user-service"
echo ""
echo "  Check service status:"
echo "    docker compose -f docker/docker-compose.infrastructure.yml ps"
echo "    docker compose -f docker/docker-compose.services.yml ps"
echo ""
echo "  Restart a service:"
echo "    docker compose -f docker/docker-compose.services.yml restart api-gateway"
echo ""
echo "  Stop all services:"
echo "    docker compose -f docker/docker-compose.infrastructure.yml down"
echo "    docker compose -f docker/docker-compose.services.yml down"
echo ""
echo "  Connect to Cassandra:"
echo "    docker exec -it cassandra cqlsh"
echo ""
echo "  Connect to PostgreSQL:"
echo "    docker exec -it postgres psql -U metachat -d metachat"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Current Status:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Infrastructure Services:"
docker compose -f docker-compose.infrastructure.yml ps

echo ""
echo "Application Services:"
docker compose -f docker-compose.services.yml ps

echo ""
echo "🎉 MetaChat is now running!"
echo "🚀 You can start using the API at http://$SERVER_IP:8080"
echo ""

