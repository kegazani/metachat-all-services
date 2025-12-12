#!/bin/bash

set -e

KAFKA_CONTAINER="kafka"
KAFKA_BOOTSTRAP="localhost:9092"
DEFAULT_PARTITIONS=3
DEFAULT_REPLICATION_FACTOR=1
DEFAULT_RETENTION_MS=604800000
DEFAULT_CLEANUP_POLICY="delete"

echo "🚀 Creating Kafka topics for MetaChat services..."
echo ""

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

declare -A topics_created
declare -A topics_failed

create_topic() {
    local topic_name=$1
    local partitions=${2:-$DEFAULT_PARTITIONS}
    local replication_factor=${3:-$DEFAULT_REPLICATION_FACTOR}
    local retention_ms=${4:-$DEFAULT_RETENTION_MS}
    local cleanup_policy=${5:-$DEFAULT_CLEANUP_POLICY}
    
    echo "📝 Creating topic: $topic_name"
    echo "   Partitions: $partitions, Replication: $replication_factor"
    
    if docker exec $KAFKA_CONTAINER kafka-topics \
        --bootstrap-server $KAFKA_BOOTSTRAP \
        --create \
        --if-not-exists \
        --topic "$topic_name" \
        --partitions $partitions \
        --replication-factor $replication_factor \
        --config retention.ms=$retention_ms \
        --config cleanup.policy=$cleanup_policy 2>/dev/null; then
        topics_created["$topic_name"]=1
        echo "   ✅ Created successfully"
    else
        if docker exec $KAFKA_CONTAINER kafka-topics \
            --bootstrap-server $KAFKA_BOOTSTRAP \
            --list | grep -q "^${topic_name}$"; then
            echo "   ℹ️  Topic already exists"
            topics_created["$topic_name"]=1
        else
            echo "   ❌ Failed to create topic"
            topics_failed["$topic_name"]=1
        fi
    fi
    echo ""
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 User Service Topics"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
create_topic "metachat-user-events"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📔 Diary Service Topics"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
create_topic "diary-events"
create_topic "session-events"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "😊 Mood Analysis Service Topics"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
create_topic "metachat.diary.entry.created"
create_topic "metachat.diary.entry.updated"
create_topic "metachat.mood.analyzed"
create_topic "metachat.mood.analysis.failed"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Analytics Service Topics"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
create_topic "metachat.diary.entry.deleted"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎭 Archetype Service Topics"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
create_topic "metachat.archetype.assigned"
create_topic "metachat.archetype.updated"
create_topic "metachat.archetype.calculation.triggered"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💓 Biometric Service Topics"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
create_topic "metachat.biometric.data.received"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔗 Correlation Service Topics"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
create_topic "metachat.correlation.discovered"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Successfully created/existing topics: ${#topics_created[@]}"
if [ ${#topics_failed[@]} -gt 0 ]; then
    echo "❌ Failed topics: ${#topics_failed[@]}"
    for topic in "${!topics_failed[@]}"; do
        echo "   - $topic"
    done
fi
echo ""

echo "📋 All Kafka topics:"
docker exec $KAFKA_CONTAINER kafka-topics \
    --bootstrap-server $KAFKA_BOOTSTRAP \
    --list | grep -E "^metachat|^diary|^session" | sort

echo ""
echo "🎉 Done!"

