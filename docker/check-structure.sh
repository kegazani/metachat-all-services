#!/bin/bash

echo "Checking project structure on server..."
echo ""

cd /root/metachat-all-services

echo "📂 Current location: $(pwd)"
echo ""

echo "📋 Looking for Dockerfile's..."
find . -name "Dockerfile" -type f | sort

echo ""
echo "📊 Summary:"
echo "   Total Dockerfiles found: $(find . -name "Dockerfile" -type f | wc -l)"
echo ""

echo "🔍 Checking for Go services..."
for service in api-gateway user-service diary-service matching-service match-request-service chat-service; do
    if find . -path "*/metachat-$service/Dockerfile" 2>/dev/null | grep -q .; then
        echo "   ✅ $service"
    else
        echo "   ❌ $service - MISSING!"
    fi
done

echo ""
echo "🔍 Checking for Python services..."
for service in mood-analysis-service analytics-service archetype-service biometric-service correlation-service; do
    if find . -path "*/metachat-$service/Dockerfile" 2>/dev/null | grep -q .; then
        echo "   ✅ $service"
    else
        echo "   ❌ $service - MISSING!"
    fi
done

