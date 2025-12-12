#!/bin/bash
set -e

REGISTRY_URL="${REGISTRY_URL:-localhost:5000}"
ADVERTISE_ADDR="${ADVERTISE_ADDR:-$(hostname -I | awk '{print $1}')}"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         MetaChat Docker Swarm Initialization                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker is not installed. Please install Docker first."
        exit 1
    fi
    echo "✅ Docker is installed"
}

init_swarm() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🐝 Initializing Docker Swarm..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if docker info 2>/dev/null | grep -q "Swarm: active"; then
        echo "ℹ️  Swarm is already initialized"
    else
        docker swarm init --advertise-addr "$ADVERTISE_ADDR"
        echo "✅ Swarm initialized successfully"
    fi
    
    echo ""
    echo "📋 Swarm join token for workers:"
    docker swarm join-token worker 2>/dev/null || true
}

create_network() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🌐 Creating overlay network..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if docker network ls | grep -q "metachat_network"; then
        echo "ℹ️  Network metachat_network already exists"
    else
        docker network create --driver overlay --attachable metachat_network
        echo "✅ Network created successfully"
    fi
}

deploy_registry() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 Deploying Docker Registry..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    docker service create \
        --name registry \
        --publish 5000:5000 \
        --constraint 'node.role == manager' \
        --mount type=volume,source=registry_data,target=/var/lib/registry \
        registry:2 2>/dev/null || echo "ℹ️  Registry service already exists"
    
    echo "✅ Registry deployed at $REGISTRY_URL"
}

deploy_infrastructure() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🏗️  Deploying Infrastructure Services..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    cd "$(dirname "$0")"
    docker compose -f docker-compose.infrastructure.yml up -d
    
    echo "✅ Infrastructure services deployed"
}

build_and_push_images() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔨 Building and pushing images to local registry..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    cd "$(dirname "$0")/.."
    
    services=(
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
    
    for service in "${services[@]}"; do
        echo ""
        echo "📦 Building metachat/$service..."
        
        docker build \
            -t "$REGISTRY_URL/metachat/$service:latest" \
            -f "metachat-all-services/metachat-$service/Dockerfile" \
            metachat-all-services/
        
        echo "📤 Pushing to registry..."
        docker push "$REGISTRY_URL/metachat/$service:latest"
        
        echo "✅ $service done"
    done
}

deploy_stack() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚀 Deploying MetaChat Stack..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    cd "$(dirname "$0")"
    
    export REGISTRY="$REGISTRY_URL"
    export TAG="latest"
    
    docker stack deploy -c docker-compose.swarm.yml metachat
    
    echo "✅ Stack deployed successfully"
}

show_status() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 Deployment Status"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    echo ""
    echo "🐝 Swarm Nodes:"
    docker node ls
    
    echo ""
    echo "📦 Services:"
    docker service ls
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🌐 Access URLs"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📊 Grafana:          http://localhost:3000"
    echo "   Login: admin / metachat2024"
    echo ""
    echo "📈 Prometheus:       http://localhost:9090"
    echo "📦 Registry UI:      http://localhost:5001"
    echo "🎯 Traefik:          http://localhost:8088"
    echo "👁️  Visualizer:       http://localhost:5002"
    echo "🌐 API Gateway:      http://localhost/api"
    echo ""
}

main() {
    check_docker
    init_swarm
    create_network
    deploy_registry
    
    echo ""
    read -p "Deploy infrastructure services? (y/n): " deploy_infra
    if [[ "$deploy_infra" =~ ^[Yy]$ ]]; then
        deploy_infrastructure
    fi
    
    echo ""
    read -p "Build and push images to local registry? (y/n): " build_images
    if [[ "$build_images" =~ ^[Yy]$ ]]; then
        build_and_push_images
    fi
    
    echo ""
    read -p "Deploy MetaChat stack? (y/n): " deploy
    if [[ "$deploy" =~ ^[Yy]$ ]]; then
        deploy_stack
    fi
    
    show_status
    
    echo ""
    echo "🎉 MetaChat Swarm setup complete!"
}

case "${1:-}" in
    "init")
        check_docker
        init_swarm
        create_network
        ;;
    "registry")
        deploy_registry
        ;;
    "build")
        build_and_push_images
        ;;
    "deploy")
        deploy_stack
        ;;
    "status")
        show_status
        ;;
    "all")
        check_docker
        init_swarm
        create_network
        deploy_registry
        deploy_infrastructure
        build_and_push_images
        deploy_stack
        show_status
        ;;
    *)
        main
        ;;
esac

