#!/bin/bash

echo "Checking for Dockerfiles..."
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

echo "Current directory: $(pwd)"
echo ""

for service in "${SERVICES[@]}"; do
    DOCKERFILE="metachat-all-services/metachat-$service/Dockerfile"
    if [ -f "$DOCKERFILE" ]; then
        echo "✅ $service: $DOCKERFILE"
    else
        echo "❌ $service: NOT FOUND at $DOCKERFILE"
        
        ALT_PATH="metachat-$service/Dockerfile"
        if [ -f "$ALT_PATH" ]; then
            echo "   Found at: $ALT_PATH"
        fi
    fi
done

echo ""
echo "Listing metachat-all-services structure:"
ls -la metachat-all-services/ 2>/dev/null || echo "Directory not found!"

