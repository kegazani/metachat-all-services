#!/bin/bash
set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     MetaChat - Deploy (Using Local Images)                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

cd "$(dirname "$0")"

echo "🔍 Checking for local images..."
echo ""

REQUIRED_IMAGES=(
    "metachat/api-gateway:latest"
    "metachat/user-service:latest"
    "metachat/diary-service:latest"
    "metachat/matching-service:latest"
    "metachat/match-request-service:latest"
    "metachat/chat-service:latest"
)

MISSING_IMAGES=()

for image in "${REQUIRED_IMAGES[@]}"; do
    if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${image}$"; then
        echo "✅ Found: $image"
    else
        echo "❌ Missing: $image"
        MISSING_IMAGES+=("$image")
    fi
done

if [ ${#MISSING_IMAGES[@]} -gt 0 ]; then
    echo ""
    echo "⚠️  Some required images are missing!"
    echo "Please run: ./build-images.sh first"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Deploying services..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "🛑 Stopping old containers..."
docker compose -f docker-compose.production-light.yml down

echo ""
echo "📦 Step 1: Starting infrastructure..."
docker compose -f docker-compose.production-light.yml up -d \
    zookeeper kafka cassandra postgres eventstore nats

echo ""
echo "⏳ Waiting for databases (60 seconds)..."
sleep 60

echo ""
echo "🔍 Checking database health..."

for i in {1..30}; do
    if docker compose -f docker-compose.production-light.yml exec -T cassandra cqlsh -e "describe keyspaces" >/dev/null 2>&1; then
        echo "✅ Cassandra is ready"
        break
    fi
    echo "⏳ Waiting for Cassandra... ($i/30)"
    sleep 10
done

if docker compose -f docker-compose.production-light.yml exec -T postgres pg_isready -U metachat >/dev/null 2>&1; then
    echo "✅ PostgreSQL is ready"
fi

echo ""
echo "📦 Step 2: Starting application services..."
docker compose -f docker-compose.production-light.yml up -d \
    user-service diary-service matching-service \
    match-request-service chat-service

sleep 20

echo ""
echo "📦 Step 3: Starting AI/ML services..."
docker compose -f docker-compose.production-light.yml up -d \
    mood-analysis-service analytics-service \
    archetype-service biometric-service correlation-service

sleep 10

echo ""
echo "📦 Step 4: Starting API Gateway..."
docker compose -f docker-compose.production-light.yml up -d api-gateway

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Service Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker compose -f docker-compose.production-light.yml ps

SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 Access URLs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  🌐 API Gateway:   http://$SERVER_IP:8080"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Useful commands:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  View logs:     docker compose -f docker-compose.production-light.yml logs -f [service]"
echo "  Restart:       docker compose -f docker-compose.production-light.yml restart [service]"
echo "  Stop all:      docker compose -f docker-compose.production-light.yml down"
echo "  Check status:  docker compose -f docker-compose.production-light.yml ps"
echo ""
echo "✅ Deployment complete!"
echo ""

