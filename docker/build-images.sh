#!/bin/bash
set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔨 Building MetaChat Docker Images"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cd "$(dirname "$0")/.."

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

FAILED_SERVICES=()

for service in "${SERVICES[@]}"; do
    echo ""
    echo "📦 Building metachat/$service..."
    
    SERVICE_DIR="metachat-all-services/metachat-$service"
    
    if [ ! -f "$SERVICE_DIR/Dockerfile" ]; then
        echo "⚠️  Dockerfile not found for $service, skipping..."
        FAILED_SERVICES+=("$service (no Dockerfile)")
        continue
    fi
    
    if docker build \
        -t "metachat/$service:latest" \
        -f "$SERVICE_DIR/Dockerfile" \
        metachat-all-services/; then
        echo "✅ $service built successfully"
    else
        echo "❌ Failed to build $service"
        FAILED_SERVICES+=("$service")
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Build Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ ${#FAILED_SERVICES[@]} -eq 0 ]; then
    echo "✅ All services built successfully!"
    echo ""
    echo "📋 Built images:"
    docker images | grep "metachat/"
else
    echo "⚠️  Some services failed to build:"
    for failed in "${FAILED_SERVICES[@]}"; do
        echo "   ❌ $failed"
    done
    exit 1
fi

echo ""
echo "Next step: Run './docker/deploy-local.sh' to start services"
echo ""

