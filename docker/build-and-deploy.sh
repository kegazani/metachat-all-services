#!/bin/bash
set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     MetaChat - Build and Deploy (Local Build)               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

cd "$(dirname "$0")/.."

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔨 Building Docker images locally..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

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

for service in "${SERVICES[@]}"; do
    echo ""
    echo "📦 Building metachat/$service..."
    
    SERVICE_DIR="metachat-all-services/metachat-$service"
    
    if [ ! -f "$SERVICE_DIR/Dockerfile" ]; then
        echo "⚠️  Dockerfile not found for $service, skipping..."
        continue
    fi
    
    docker build \
        -t "metachat/$service:latest" \
        -f "$SERVICE_DIR/Dockerfile" \
        metachat-all-services/ || {
            echo "❌ Failed to build $service"
            exit 1
        }
    
    echo "✅ $service built successfully"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Starting services..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd docker

echo ""
echo "📦 Step 1: Starting infrastructure..."
docker compose -f docker-compose.production-light.yml up -d \
    zookeeper kafka cassandra postgres eventstore nats

echo ""
echo "⏳ Waiting for databases (60 seconds)..."
sleep 60

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
echo "📊 Service Status:"
docker compose -f docker-compose.production-light.yml ps

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Deployment Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌐 API Gateway: http://$(hostname -I | awk '{print $1}'):8080"
echo ""
echo "📝 View logs: docker compose -f docker-compose.production-light.yml logs -f"
echo "🛑 Stop all:  docker compose -f docker-compose.production-light.yml down"
echo ""

