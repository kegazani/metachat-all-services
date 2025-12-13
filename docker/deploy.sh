#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STACK_FILE="$SCRIPT_DIR/docker-stack.yml"

echo "🚀 Deploying MetaChat to Docker Swarm..."
echo ""

# Check if Docker Swarm is initialized
if ! docker info | grep -q "Swarm: active"; then
    echo "⚠️  Docker Swarm is not initialized. Initializing..."
    docker swarm init
    echo "✅ Docker Swarm initialized"
fi

# Create network if it doesn't exist
if ! docker network ls | grep -q "metachat_network"; then
    echo "📡 Creating metachat_network..."
    docker network create --driver overlay --attachable metachat_network
    echo "✅ Network created"
fi

# Deploy stack
echo ""
echo "📦 Deploying stack..."
docker stack deploy -c "$STACK_FILE" metachat

echo ""
echo "⏳ Waiting for services to start..."
sleep 10

echo ""
echo "📊 Service status:"
docker service ls

echo ""
echo "✅ Deployment complete!"
echo ""
echo "🔧 Useful commands:"
echo "  - Check services: docker service ls"
echo "  - View logs: docker service logs metachat_<service-name>"
echo "  - Remove stack: docker stack rm metachat"

