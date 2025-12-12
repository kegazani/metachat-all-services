#!/bin/bash

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          MetaChat - Swarm Status                             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

cd "$(dirname "$0")"

SERVER_IP=$(hostname -I | awk '{print $1}')
if [ -z "$SERVER_IP" ]; then
    SERVER_IP="localhost"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🐳 Docker Swarm Info"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker info | grep -E "(Swarm|Managers|Nodes)" | head -5

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Stacks"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker stack ls

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 All Services"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker service ls

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 Access URLs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Application:"
echo "  🔌 API Gateway:        http://$SERVER_IP:8080"
echo ""
echo "Management & Monitoring:"
echo "  🐳 Swarmpit:           http://$SERVER_IP:888"
echo "  📊 Grafana:            http://$SERVER_IP:3000 (admin/metachat2024)"
echo "  📉 Prometheus:         http://$SERVER_IP:9090"
echo "  📨 Kafka UI:           http://$SERVER_IP:8090"
echo ""
echo "Infrastructure:"
echo "  🗄️  PostgreSQL:        $SERVER_IP:5432"
echo "  💾 Cassandra:          $SERVER_IP:9042"
echo "  📝 EventStore:         http://$SERVER_IP:2113"
echo "  📮 Kafka:              $SERVER_IP:9092"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Useful Commands"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Redeploy all:         ./redeploy-swarm.sh all"
echo "  Redeploy service:     ./redeploy-swarm.sh <service-name>"
echo "  Stop all:             ./stop-swarm.sh all"
echo "  View logs:            docker service logs -f <service-name>"
echo "  Scale service:        docker service scale <service>=<replicas>"
echo ""

