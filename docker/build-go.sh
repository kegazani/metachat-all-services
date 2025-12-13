#!/bin/bash

set -e

GO_SERVICES=(
    "api-gateway"
    "user-service"
    "diary-service"
    "matching-service"
    "match-request-service"
    "chat-service"
)

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)/metachat-all-services"
DOCKERFILE="$(cd "$(dirname "$0")" && pwd)/Dockerfile.go-service"

echo "🐹 Building Go services..."

cd "$BASE_DIR"

for service in "${GO_SERVICES[@]}"; do
    service_dir="metachat-${service}"
    image_name="metachat/${service}:latest"
    
    echo ""
    echo "📦 Building ${service}..."
    
    if docker build -t "$image_name" \
        -f "$DOCKERFILE" \
        --build-arg SERVICE_DIR="$service_dir" \
        .; then
        echo "✅ Successfully built: ${service}"
    else
        echo "❌ Failed to build ${service}"
        exit 1
    fi
done

echo ""
echo "✅ All Go services built successfully!"

