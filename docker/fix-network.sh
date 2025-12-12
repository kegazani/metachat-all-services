#!/bin/bash

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          MetaChat - Fix Network Issue                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

echo "🔍 Checking network status..."
if docker network inspect metachat_network &> /dev/null; then
    echo "⚠️  Network 'metachat_network' exists with incorrect labels"
    echo ""
    echo "🛑 Stopping all containers using this network..."
    
    docker compose -f docker-compose.infrastructure.yml down 2>/dev/null || true
    docker compose -f docker-compose.services.yml down 2>/dev/null || true
    
    echo ""
    echo "🗑️  Removing old network..."
    docker network rm metachat_network
    
    if [ $? -eq 0 ]; then
        echo "✅ Old network removed successfully"
    else
        echo "❌ Failed to remove network. Checking for connected containers..."
        echo ""
        docker network inspect metachat_network --format '{{range .Containers}}{{.Name}} {{end}}'
        echo ""
        echo "Please stop these containers manually and try again."
        exit 1
    fi
else
    echo "ℹ️  Network doesn't exist or already removed"
fi

echo ""
echo "🌐 Creating new network with correct labels..."
docker network create --driver bridge --subnet 172.25.0.0/16 metachat_network

if [ $? -eq 0 ]; then
    echo "✅ Network created successfully"
else
    echo "❌ Failed to create network"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Network issue fixed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Now you can run:"
echo "  ./deploy-full.sh"
echo ""

