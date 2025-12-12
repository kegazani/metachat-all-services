#!/bin/bash

set -e

ZOOKEEPER_CONTAINER="zookeeper"

echo "🧹 Cleaning up Zookeeper ephemeral nodes..."

if ! docker ps | grep -q "$ZOOKEEPER_CONTAINER"; then
    echo "❌ Zookeeper container is not running"
    exit 1
fi

echo "📋 Current broker nodes in Zookeeper:"
docker exec $ZOOKEEPER_CONTAINER zookeeper-shell localhost:2181 <<EOF
ls /brokers/ids
quit
EOF

echo ""
echo "🗑️  Removing old broker nodes..."
docker exec $ZOOKEEPER_CONTAINER zookeeper-shell localhost:2181 <<EOF
rmr /brokers/ids/1 2>/dev/null || true
quit
EOF

echo "✅ Cleanup completed!"
echo ""
echo "💡 You can now restart Kafka container"

