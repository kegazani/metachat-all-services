#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🏗️  MetaChat - Full Build and Deploy"
echo ""

# Step 1: Build all services
echo "======================================"
echo "Step 1: Building all services"
echo "======================================"
bash "$SCRIPT_DIR/build-all.sh"

echo ""
echo "======================================"
echo "Step 2: Deploying to Docker Swarm"
echo "======================================"
bash "$SCRIPT_DIR/deploy.sh"

echo ""
echo "======================================"
echo "Step 3: Initialize databases"
echo "======================================"

echo "⏳ Waiting for databases to be ready..."
sleep 30

# Create Cassandra keyspace
echo "📊 Creating Cassandra keyspace..."
CASSANDRA_CONTAINER=$(docker ps --filter "name=metachat_cassandra" --format "{{.Names}}" | head -1)
if [ -n "$CASSANDRA_CONTAINER" ]; then
    docker exec "$CASSANDRA_CONTAINER" cqlsh -e "CREATE KEYSPACE IF NOT EXISTS metachat WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};" 2>/dev/null || echo "⚠️  Cassandra keyspace might already exist or Cassandra is not ready yet"
fi

# Create PostgreSQL databases
echo "📊 Creating PostgreSQL databases..."
POSTGRES_CONTAINER=$(docker ps --filter "name=metachat_postgres" --format "{{.Names}}" | head -1)
if [ -n "$POSTGRES_CONTAINER" ]; then
    docker exec "$POSTGRES_CONTAINER" psql -U metachat -d postgres -c "CREATE DATABASE metachat_mood;" 2>/dev/null || echo "⚠️  Database metachat_mood might already exist"
    docker exec "$POSTGRES_CONTAINER" psql -U metachat -d postgres -c "CREATE DATABASE metachat_analytics;" 2>/dev/null || echo "⚠️  Database metachat_analytics might already exist"
    docker exec "$POSTGRES_CONTAINER" psql -U metachat -d postgres -c "CREATE DATABASE metachat_personality;" 2>/dev/null || echo "⚠️  Database metachat_personality might already exist"
    docker exec "$POSTGRES_CONTAINER" psql -U metachat -d postgres -c "CREATE DATABASE metachat_biometric;" 2>/dev/null || echo "⚠️  Database metachat_biometric might already exist"
    docker exec "$POSTGRES_CONTAINER" psql -U metachat -d postgres -c "CREATE DATABASE metachat_correlation;" 2>/dev/null || echo "⚠️  Database metachat_correlation might already exist"
fi

echo ""
echo "======================================"
echo "✅ All done!"
echo "======================================"
echo ""
echo "📊 Final service status:"
docker service ls

echo ""
echo "🌐 Access points:"
echo "  - API Gateway: http://localhost:8080"
echo "  - Grafana: http://localhost:3000 (admin/metachat2024)"
echo "  - Kafka UI: http://localhost:8090"
echo "  - Prometheus: http://localhost:9090"
