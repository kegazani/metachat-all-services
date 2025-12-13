#!/bin/bash

set -e

PYTHON_SERVICES=(
    "mood-analysis-service"
    "analytics-service"
    "archetype-service"
    "biometric-service"
    "correlation-service"
)

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)/metachat-all-services"

echo "🐍 Building Python services..."

cd "$BASE_DIR"

for service in "${PYTHON_SERVICES[@]}"; do
    image_name="metachat/${service}:latest"
    dockerfile_path="metachat-${service}/Dockerfile"
    
    echo ""
    echo "📦 Building ${service}..."
    
    if docker build -t "$image_name" -f "$dockerfile_path" .; then
        echo "✅ Successfully built: ${service}"
    else
        echo "❌ Failed to build ${service}"
        exit 1
    fi
done

echo ""
echo "✅ All Python services built successfully!"

