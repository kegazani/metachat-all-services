#!/bin/bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║       MetaChat - Docker Swarm Deployment Script             ║"
echo "║       Production Deployment with High Availability          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$SCRIPT_DIR"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}🔍 Step 1: Environment Check${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker not found. Please install Docker first.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker found: $(docker --version)${NC}"

if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker daemon is not running.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker daemon is running${NC}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}🐝 Step 2: Initialize Docker Swarm${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if docker info | grep -q "Swarm: active"; then
    echo -e "${GREEN}✅ Docker Swarm is already active${NC}"
    echo ""
    echo "Swarm nodes:"
    docker node ls
else
    echo -e "${YELLOW}⏳ Initializing Docker Swarm...${NC}"
    docker swarm init --advertise-addr 77.95.201.100 || {
        echo -e "${YELLOW}ℹ️  Swarm already initialized or needs force init${NC}"
        docker swarm init --advertise-addr 77.95.201.100 --force-new-cluster || true
    }
    echo -e "${GREEN}✅ Docker Swarm initialized${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}🌐 Step 3: Create Overlay Network${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if docker network ls | grep -q "metachat_network"; then
    echo -e "${GREEN}✅ Network metachat_network already exists${NC}"
else
    echo -e "${YELLOW}⏳ Creating overlay network...${NC}"
    docker network create --driver=overlay --attachable metachat_network
    echo -e "${GREEN}✅ Network created${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}🏗️  Step 4: Build Docker Images${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${YELLOW}⏳ Building all service images...${NC}"
cd "$ROOT_DIR/metachat-all-services"

services=(
    "metachat-api-gateway"
    "metachat-user-service"
    "metachat-diary-service"
    "metachat-matching-service"
    "metachat-match-request-service"
    "metachat-chat-service"
    "metachat-mood-analysis-service"
    "metachat-analytics-service"
    "metachat-archetype-service"
    "metachat-biometric-service"
    "metachat-correlation-service"
)

for service in "${services[@]}"; do
    if [ -d "$service" ]; then
        echo ""
        echo -e "${BLUE}📦 Building $service...${NC}"
        service_name=$(echo $service | sed 's/metachat-//')
        docker build -t metachat/${service_name}:latest -f ${service}/Dockerfile . || {
            echo -e "${RED}❌ Failed to build $service${NC}"
            exit 1
        }
        echo -e "${GREEN}✅ Built $service${NC}"
    fi
done

cd "$SCRIPT_DIR"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}🚀 Step 5: Deploy Infrastructure Stack${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${YELLOW}⏳ Deploying infrastructure...${NC}"
docker stack deploy -c docker-stack-infrastructure.yml metachat-infra

echo -e "${GREEN}✅ Infrastructure stack deployed${NC}"
echo ""
echo -e "${YELLOW}⏳ Waiting for infrastructure to be ready (60 seconds)...${NC}"
sleep 60

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}🚀 Step 6: Deploy Services Stack${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${YELLOW}⏳ Deploying application services...${NC}"
docker stack deploy -c docker-stack-services.yml metachat-services

echo -e "${GREEN}✅ Services stack deployed${NC}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}📊 Step 7: Deployment Status${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Stacks:"
docker stack ls
echo ""

echo "Infrastructure services:"
docker stack services metachat-infra
echo ""

echo "Application services:"
docker stack services metachat-services
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ Deployment Complete!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}🌐 Service URLs:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  API Gateway:    http://77.95.201.100:8080"
echo "  Grafana:        http://77.95.201.100:3000 (admin/metachat2024)"
echo "  Prometheus:     http://77.95.201.100:9090"
echo "  Kafka UI:       http://77.95.201.100:8090"
echo "  EventStore:     http://77.95.201.100:2113"
echo ""
echo -e "${YELLOW}📝 Useful commands:${NC}"
echo "  docker stack ps metachat-infra        # Check infrastructure tasks"
echo "  docker stack ps metachat-services     # Check service tasks"
echo "  docker service logs <service_name>    # View service logs"
echo "  docker service scale <service>=N      # Scale service"
echo "  docker stack rm metachat-infra        # Remove infrastructure stack"
echo "  docker stack rm metachat-services     # Remove services stack"
echo ""

