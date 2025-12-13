#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🚀 Building all MetaChat services..."
echo ""

# Build Python services
echo "======================================"
echo "Building Python services..."
echo "======================================"
bash "$SCRIPT_DIR/build-python.sh"

echo ""
echo "======================================"
echo "Building Go services..."
echo "======================================"
bash "$SCRIPT_DIR/build-go.sh"

echo ""
echo "======================================"
echo "✅ All services built successfully!"
echo "======================================"
echo ""
echo "📋 Built images:"
docker images | grep "metachat/"

