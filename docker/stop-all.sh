#!/bin/bash

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          MetaChat - Stop All Services                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "🛑 Stopping application services..."
docker compose -f docker-compose.services.yml down

echo ""
echo "🛑 Stopping infrastructure services..."
docker compose -f docker-compose.infrastructure.yml down

echo ""
echo "✅ All services stopped!"
echo ""
echo "💡 To remove all data volumes, run:"
echo "   docker volume prune"
echo ""

