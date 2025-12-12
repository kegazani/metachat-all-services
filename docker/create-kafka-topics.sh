#!/bin/bash

set -e

KAFKA_CONTAINER="kafka"
KAFKA_BOOTSTRAP="localhost:9092"
REPLICATION_FACTOR=1
PARTITIONS=3

echo "🚀 Creating Kafka topics for MetaChat services..."

wait_for_kafka() {
    echo "⏳ Waiting for Kafka to be ready..."
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if docker exec $KAFKA_CONTAINER kafka-broker-api-versions \
            --bootstrap-server $KAFKA_BOOTSTRAP >/dev/null 2>&1; then
            echo "✅ Kafka is ready!"
            echo ""
            return 0
        fi
        attempt=$((attempt + 1))
        echo "   Attempt $attempt/$max_attempts - Kafka not ready yet, waiting 2 seconds..."
        sleep 2
    done
    
    echo "❌ Kafka did not become ready after $max_attempts attempts"
    exit 1
}

wait_for_kafka

topics=(
    "metachat-user-events"
    "diary-events"
    "session-events"
    "metachat.diary.entry.created"
    "metachat.diary.entry.updated"
    "metachat.diary.entry.deleted"
    "metachat.mood.analyzed"
    "metachat.mood.analysis.failed"
    "metachat.archetype.assigned"
    "metachat.archetype.updated"
    "metachat.archetype.calculation.triggered"
    "metachat.biometric.data.received"
    "metachat.correlation.discovered"
)

for topic in "${topics[@]}"; do
    echo "📝 Creating topic: $topic"
    
    docker exec $KAFKA_CONTAINER kafka-topics \
        --bootstrap-server $KAFKA_BOOTSTRAP \
        --create \
        --if-not-exists \
        --topic "$topic" \
        --partitions $PARTITIONS \
        --replication-factor $REPLICATION_FACTOR \
        --config retention.ms=604800000 \
        --config cleanup.policy=delete || {
        echo "⚠️  Topic $topic might already exist or creation failed"
    }
done

echo ""
echo "✅ All topics created successfully!"
echo ""
echo "📋 Listing all topics:"
docker exec $KAFKA_CONTAINER kafka-topics \
    --bootstrap-server $KAFKA_BOOTSTRAP \
    --list

echo ""
echo "🎉 Done!"

